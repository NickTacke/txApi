# txApi

FiveM server-side resource that wraps the txAdmin HTTP API, exposing helper methods for authentication, player management, action history, and server controls. The resource bootstraps itself, handles token storage, and re-exports convenience functions so other whitelisted resources can interact with txAdmin safely.

## Contents

- Overview
- Requirements
- Installation
- Configuration
- Runtime Behaviour
- Public API Reference
- Logging
- Development Notes

## Overview

`txApi` loads core helpers on resource start, attempts authentication when credentials are present, and exposes the resulting API through both the Lua environment and FiveM exports. Consumers gain access to:

- HTTP helpers that include authentication cookies and CSRF headers.
- High-level wrappers for txAdmin history (`actions`) and player endpoints (`players`).
- Server management helpers (`server`).
- Centralised logging with adjustable verbosity.

The resource version is tracked in `init.lua` and `fxmanifest.lua` (`1.5.3` at the time of writing).

## Requirements

- FiveM server running the Cerulean build (Lua 5.4 enabled).
- txAdmin configured and reachable from the FiveM host (`Config.Hostname`).
- Valid txAdmin credentials with the required permissions for the actions you intend to call.

## Installation

1. Copy this resource folder into your FiveM server resource directory (e.g. `resources/[local]/txApi`).
2. Ensure the resource in your server configuration:
   ```
   ensure txApi
   ```
3. If other resources need to call `txApi`, add them to `Config.Whitelist`.

## Configuration

Edit `settings/config.lua` to match your environment:

- `Config.Hostname`: Base URL for your txAdmin instance (e.g. `http://127.0.0.1:40120`).
- `Config.Username` / `Config.Password`: txAdmin credentials used for API authentication.
- `Config.Whitelist`: Array of resource names allowed to call exported API functions via `txApi.txRequest`.
- `Config.LogLevel`: Minimum log level to display (`error`, `warn`, `info`, `debug`, `trace`).

> **Security Tip:** Do not commit real credentials. Use server-specific secrets management when possible.

## Runtime Behaviour

- `init.lua` loads `core/loader.lua`, which sets up a lazy module loader (`load_module`) bound to the `txApi` metatable. Modules under `modules/` are fetched on first access.
- Once core modules are loaded, a background thread waits for critical functions (`getConfig`, `authenticate`, `sendHTTPRequest`, `getAuthState`) to exist and automatically authenticates if credentials are configured.
- `core/main.lua` seeds the exported `txApi` table, providing shared state (`Config`) and controlling how new functions are exported.
- `core/http/auth.lua` maintains authentication state: session cookie, CSRF token, and status flags. Successful authentication updates this state and enables `txApi.txRequest`.
- Requests from non-whitelisted resources, or before authentication succeeds, return standardised error responses.

## Public API Reference

Unless noted otherwise, functions return decoded tables on success or an empty table / error response structure on failure. All functions live on the `txApi` table, which can be accessed via Lua requires or FiveM exports.

### Initialisation Helpers

- `txApi.getConfig()` → `table`: Returns the resolved `Config` table.
- `txApi.authenticate(hostname, username, password)` → `boolean`: Authenticates against txAdmin; stores cookies and CSRF token internally.
- `txApi.getAuthState()` → `AuthState`: Returns the current authentication state (configured, isAuthenticated, hostname, credentials, tokens).
- `txApi.isAuthenticated()` → `boolean`: Convenience flag.

### HTTP Utilities

- `txApi.sendHTTPRequest(url, options)` → `HTTPResponse`: Thin wrapper around `PerformHttpRequest`. `options` supports `method`, `body`, and `headers`. Returns `{ status, ok, data, errorText, headers }`.
- `txApi.txRequest(endpoint, options)` → `HTTPResponse`: Applies whitelist checks, injects session cookie and CSRF headers, JSON-encodes the body when present, and calls `sendHTTPRequest` using the configured hostname.

### Logging

- `txApi.log(level, ...)`: Logs messages when `Config.LogLevel` is at least `level` (colour-coded output).

### Module: `txApi.actions`

- `txApi.actions.search(options)` → `table`: Queries `history/search` with sorting and search filters. Only one search type (`actionId`, `reason`, `identifier`) is allowed per call.
- `txApi.actions.stats()` → `table`: Fetches aggregated history stats from `history/stats`.
- `txApi.actions.revoke(actionId)` → `table`: Revokes an action via `history/revokeAction`.

All responses are JSON-decoded. Failures log an error and return `{}`.

### Module: `txApi.players`

- `txApi.players.search(options)` → `table`: Searches players via `player/search`. Supports name, identifier, or notes filters, sorting options, and pagination using `offsetLicense`.
- `txApi.players.action(action, playerId, body)` → `table`: Low-level helper that submits a POST to `player/<action>` (message, warn, kick, ban). Handles net ID vs license formats automatically.
- `txApi.players.message(playerId, message)` → `table`: Sends a message to a connected player.
- `txApi.players.warn(playerId, reason)` → `table`: Issues a warning.
- `txApi.players.kick(playerId, reason)` → `table`: Kicks a player.
- `txApi.players.ban(playerId, reason, duration)` → `table`: Bans a player (defaults to permanent duration).

Each helper logs intent and returns decoded JSON or `{}` on failure.

### Module: `txApi.server`

- `txApi.server.restart()` → `HTTPResponse`: Sends a restart command to `fxserver/controls`.
- `txApi.server.stop()` → `HTTPResponse`: Sends a stop command to `fxserver/controls`.

Both methods log with level `warn` before dispatching the request.

## Usage Examples

```lua
local txApi = exports['txApi']

-- Authenticate manually (optional when credentials are in Config)
local ok = txApi.authenticate('http://127.0.0.1:40120', 'api-user', 'strong-pass')
if not ok then
    txApi.log('error', 'Authentication failed')
    return
end

-- Fetch recent actions
local actions = txApi.actions.search({ sortingKey = 'timestamp', sortingDesc = 'true' })

-- Message a player by net ID
txApi.players.message(12, 'Server restart in 5 minutes')

-- Kick a player using license identifier
txApi.players.kick('license:1234567890abcdef', 'Cheating detected')

-- Restart the server
txApi.server.restart()
```

## Logging

`txApi.log` outputs coloured messages in the server console. Adjust `Config.LogLevel` to control verbosity. All modules reuse this helper for consistent messaging.

## Development Notes

- Modules under `modules/` should return a table that is assigned to `txApi.<moduleName>` by the loader. When adding new modules, follow the existing pattern to keep lazy-loading intact.
- To add additional txAdmin endpoints, implement new helpers in `modules/` and ensure they rely on `txApi.txRequest` for authentication and whitelisting.
- If you modify authentication logic, keep `AuthState` in sync to avoid stale cookies or CSRF tokens.


