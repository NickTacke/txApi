# txApi

A less sketchy FiveM server resource that authenticates with txAdmin, exposes helper methods for actions, players, server controls, and (soon) utilities like noclip/repair/heal through imported functions.

## Quick Start

1. Drop the folder into your server resources, e.g. `resources/[local]/txApi`.
2. Add `ensure txApi` to `server.cfg`.
3. Reference the bootstrapper in dependent resources:
   ```lua
   -- fxmanifest.lua
   server_scripts {
       '@txApi/init.lua'
   }
   ```
4. Configure credentials and behaviour in `settings/config.lua`.

## Configuration

| Key | Type | Purpose | Notes |
| --- | --- | --- | --- |
| `Config.Hostname` | string | Base URL for txAdmin | Example: `http://127.0.0.1:40120` |
| `Config.Username` / `Config.Password` | string | txAdmin credentials for API login | Use a service account; keep secrets out of git |
| `Config.Whitelist` | string[] | Resource names allowed to call `txApi` exports | Requests from others return `403` |
| `Config.LogLevel` | `LogLevel` alias (`error` · `warn` · `info` · `debug` · `trace`) | Minimum log verbosity | Default `info` |

## Runtime Overview

- `init.lua` lazy-loads modules, hydrates the `txApi` table, and spawns a thread that auto-authenticates when credentials exist.
- Authentication state (cookie + CSRF token) lives in `core/http/auth.lua`; helpers read from the shared `AuthState` table.
- All HTTP calls funnel through `txApi.txRequest`, which enforces whitelisting, injects auth headers, and JSON-encodes bodies.
- Logging is centralised in `core/logging/logging.lua`; module helpers emit at sensible levels.

## Usage Example

```lua
-- server.lua
while not txApi.isAuthenticated() do
    Citizen.Wait(1000)
end

-- Most helpers accept either a net ID or a license identifier
txApi.players.message(12, 'Server restart in 5 minutes')

txApi.actions.revoke('WACF-2SF1')

txApi.server.restart()
```

## API Reference

### Core Helpers

| Function | Returns | Notes |
| --- | --- | --- |
| `txApi.authenticate(host, user, pass)` | boolean | Stores session cookie + CSRF token on success, not necessary when credentials added to config.lua |
| `txApi.isAuthenticated()` | boolean | Convenience flag |
| `txApi.sendHTTPRequest(url, opts)` | `HTTPResponse` | Thin wrapper around `PerformHttpRequest` |
| `txApi.txRequest(endpoint, opts)` | `HTTPResponse` | Authenticated request to `<hostname>/<endpoint>` using whitelist + headers |
| `txApi.log(level, ...)` | nil | Colourised console output respecting `Config.LogLevel` |

**`HTTPOptions`** (used by `sendHTTPRequest`, `txRequest`):
- `method`: `GET` | `POST` | `PUT` | `DELETE` | `PATCH` | `OPTIONS` | `HEAD` (defaults to `GET`).
- `body`: string or table payload (tables are JSON-encoded automatically by `txRequest`).
- `headers`: table<string, any> of additional headers.

All helpers return decoded tables when possible; on failure they log and return `{ ok = false, status = <code>, errorText = <message> }` or `{}`.

### Modules

<details>
  <summary><code>txApi.actions</code> — History endpoints</summary>

  **Functions**
  
  | Function | Description |
  | --- | --- |
  | `actions.search(options)` | Query history by timestamp, player info, reason, or action ID |
  | `actions.stats()` | Fetch aggregated history statistics |
  | `actions.revoke(actionId)` | Revoke a recorded warn/ban |

  **`ActionSearchOptions`**
  
  | Field | Type / Allowed Values | Notes |
  | --- | --- | --- |
  | `sortingKey` | `timestamp` · `playerName` · `playerLicense` · `playerNetId` | Defaults to `timestamp` |
  | `sortingDesc` | `'true'` · `'false'` | Defaults to `'true'` |
  | `actionId` | string | Uses `searchType=actionId` |
  | `reason` | string | Uses `searchType=reason` |
  | `identifier` | string | Uses `searchType=identifiers` |
  | `filter` | `'warn'` · `'ban'` | Adds `filterbyType` |

  <details>
    <summary>Examples</summary>

```lua
-- Most recent bans (descending)
txApi.actions.search({ filter = 'ban' })

-- Search using a specific player identifier and sort by name
txApi.actions.search({ identifier = 'license:1234', sortingKey = 'playerName', sortingDesc = 'false' })

-- Snapshot the current totals
local totals = txApi.actions.stats()
print(('Warns: %s, Bans: %s'):format(totals.warnCount, totals.banCount))

-- Compare against a previous run
local current = txApi.actions.stats()
if previousStats and current.banCount > previousStats.banCount then
    txApi.log('warn', 'New bans detected since last check')
end

-- Revoke a known action id
txApi.actions.revoke('action-id-123')

-- Revoke the first result from a search
local results = txApi.actions.search({ actionId = 'action-id-987' })
if results[1] then
    txApi.actions.revoke(results[1].actionId)
end
```
  </details>
</details>

<details>
  <summary><code>txApi.players</code> — Player endpoints</summary>

  **Functions**
  
  | Function | Description |
  | --- | --- |
  | `players.search(options)` | Find players by name, identifiers, or notes |
  | `players.action(action, playerId, body)` | Low-level helper backing the wrappers |
  | `players.message(playerId, message)` | Send a message to a player |
  | `players.warn(playerId, reason)` | Issue a warning |
  | `players.kick(playerId, reason)` | Disconnect a player |
  | `players.ban(playerId, reason, duration)` | Apply temporary or permanent bans |

  **`PlayerSearchOptions`**
  
  | Field | Type / Allowed Values | Notes |
  | --- | --- | --- |
  | `name` | string | Uses `searchType=playerName` |
  | `identifier` | string | Uses `searchType=playerIds` |
  | `notes` | string | Uses `searchType=playerNotes` |
  | `sortingKey` | `playTime` · `tsJoined` · `tsLastConnection` | Defaults to `tsJoined` |
  | `sortingDesc` | `'true'` · `'false'` | Defaults to `'true'` |
  | `offsetLicense` | string | Continue pagination from a license value |

  **`players.action` parameters**
  - `action`: `message` | `warn` | `kick` | `ban`.
  - `playerId`: server net ID or identifier string (e.g. `license:abcdef...`). Colon-prefixed identifiers are normalised automatically.
  - `body`: request payload; wrapper helpers populate sensible defaults.

  **`players.ban` helper**
  - `playerId`: net ID or identifier string.
  - `reason`: optional string (defaults to `No reason provided`).
  - `duration`: string duration (e.g. `6h`, `3d`) or `permanent` (default).

  <details>
    <summary>Examples</summary>

```lua
-- Find players whose name starts with "Riley"
txApi.players.search({ name = 'Riley', sortingKey = 'playTime' })

-- Continue pagination using an offset license
txApi.players.search({ sortingKey = 'tsJoined', offsetLicense = 'license:abcdef1234567890' })

-- Send a custom message payload to a net ID
txApi.players.action('message', 12, { message = 'Event starting soon!' })

-- Issue a temporary ban using a license identifier
txApi.players.action('ban', 'license:abc123', { reason = 'Exploits', duration = '6h' })

-- Notify a connected player by net ID
txApi.players.message(21, 'Server restart in 10 minutes!')

-- DM an offline player by license
txApi.players.message('license:9876abcd', 'Please check the rules channel when you return')

-- Warn a player for RDM via net ID
txApi.players.warn(34, 'Random deathmatching is not allowed')

-- Warn by license for next login
txApi.players.warn('license:9876abcd', 'You were reported for harassment; final warning')

-- Kick a player immediately
txApi.players.kick(7, 'AFK farming is prohibited')

-- Kick by license extracted from identifiers
txApi.players.kick('license:abcdef1234', 'Cheating detected')

-- Temporary ban with explicit duration
txApi.players.ban(19, 'Repeat RDM', '12h')

-- Permanent ban using license identifier
txApi.players.ban('license:abcdefabcdef', 'Cheating with injected menu', 'permanent')
```
  </details>
</details>

<details>
  <summary><code>txApi.server</code> — FXServer controls</summary>

  **Functions**
  
  | Function | Description |
  | --- | --- |
  | `server.restart()` | Issue an FXServer restart |
  | `server.stop()` | Stop the FXServer instance |

  <details>
    <summary>Examples</summary>

```lua
-- Immediate restart
txApi.server.restart()

-- Schedule a restart in five minutes
Citizen.SetTimeout(5 * 60 * 1000, function()
    txApi.server.restart()
end)

-- Stop the server after all players leave
if #GetPlayers() == 0 then
    txApi.server.stop()
end

-- Emergency stop workflow
txApi.players.message(-1, 'Server stopping due to maintenance')
txApi.server.stop()
```
  </details>
</details>

## Support

Feel free to tag me in the official txAdmin discord <@!527236638041047050> or send a friend request to `arceas` and slide into my DMs.

## Extending

- Place new modules under `modules/` and return the table that should attach to `txApi.<name>`.
- Reuse `txApi.txRequest` for new txAdmin endpoints so whitelist and auth headers stay consistent.
- Keep the `AuthState` fields in sync if you adjust the authentication flow.
