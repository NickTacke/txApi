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
print(('Warns: %s, Bans: %s'):format(totals.totalWarns, totals.totalBans))

-- Compare against a previous run
local current = txApi.actions.stats()
if previousStats and current.totalBans > previousStats.totalBans then
    txApi.log('warn', 'New bans detected since last check')
end

-- Revoke a known action id
txApi.actions.revoke('WACS-12GF')

-- Revoke the first result from a search
local results = txApi.actions.search({ identifier = 'license:1234' })
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
txApi.players.search({ name = 'Riley', sortingKey = 'tsLastConnection' })

-- Continue pagination using an offset license
txApi.players.search({ sortingKey = 'playTime' })

-- Send a custom message payload to a net ID
txApi.players.action('message', 12, { message = 'Event starting soon!' })

-- Issue a temporary ban using a license identifier
txApi.players.action('ban', 'license:abc123', { reason = 'Exploits', duration = '2 weeks' })

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
txApi.players.ban(19, 'Repeat RDM', '12 hours')

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
  | `server.uptime()` | Returns the current server uptime (`uptimeMs`, `uptimeSeconds`) |
  | `server.getResourceList()` | Returns the current FXServer resource list (`name`, `state`) |
  | `server.startResource(resourceName)` | Start a resource by name |
  | `server.stopResource(resourceName)` | Stop a resource by name |
  | `server.restartResource(resourceName)` | Restart a resource by name (starts it if stopped) |
  | `server.getCfgEditorFile()` | Fetch the current `server.cfg` contents via txAdmin’s CFG Editor page |
  | `server.saveCfgEditorFile(cfgData)` | Save `server.cfg` contents via txAdmin’s CFG Editor API |
  | `server.restart()` | Issue an FXServer restart |
  | `server.stop()` | Stop the FXServer instance |

  <details>
    <summary>Examples</summary>

```lua
-- Get current server uptime (ms/seconds)
local up = txApi.server.uptime()
print(('Uptime: %d seconds'):format(up.uptimeSeconds))

-- List resources + their states
local res = txApi.server.getResourceList()
if res.ok then
  print(('Resources: %d'):format(res.count))
  -- Example: print first 5
  for i = 1, math.min(5, res.count) do
    print(('%s (%s)'):format(res.resources[i].name, res.resources[i].state))
  end
end

-- Resource controls
txApi.server.restartResource('my_resource')
txApi.server.stopResource('my_resource')
txApi.server.startResource('my_resource')

-- Read txAdmin CFG Editor contents (server.cfg)
local cfg = txApi.server.getCfgEditorFile()
if cfg.ok then
  print(cfg.cfgData)
else
  print(('Failed to get cfg: %s'):format(cfg.errorText or 'unknown'))
end

-- Save txAdmin CFG Editor contents (server.cfg)
-- Example: append a comment and save
if cfg.ok then
  local edited = cfg.cfgData .. "\n# edited via txApi\n"
  local saved = txApi.server.saveCfgEditorFile(edited)
  if not saved.ok then
    print(('Save failed (%s): %s'):format(saved.type or 'error', saved.message or saved.errorText or 'unknown'))
  else
    print('CFG saved successfully')
  end
end

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


<details>
  <summary><code>txApi.whitelist</code> — Whitelist management</summary>

  **Functions**
  
  | Function | Description |
  | --- | --- |
  | `whitelist.getApprovals()` | List all approved whitelist identifiers |
  | `whitelist.getWhitelistedPlayers(options)` | Search players who are whitelisted |
  | `whitelist.getRequests()` | List all pending whitelist requests |
  | `whitelist.add(identifier)` | Pre-approve an identifier (discord, steam, license, etc.) |
  | `whitelist.removeApproval(identifier)` | Remove a pre-approved identifier (removes from “Pending Join” table) |
  | `whitelist.setStatus(playerId, status)` | If `playerId` is a net ID or license, toggles player whitelist; for non-license identifiers (eg `discord:...`), `true` adds approval and `false` removes approval |
  | `whitelist.approveRequest(reqId)` | Approve a pending whitelist request |
  | `whitelist.denyRequest(reqId)` | Deny a pending whitelist request |
  | `whitelist.denyAllRequests(newestVisible)` | Deny all visible pending requests |

  **`whitelist.getWhitelistedPlayers` options**
  
  | Field | Type / Allowed Values | Notes |
  | --- | --- | --- |
  | `sortingKey` | `playTime` · `tsJoined` · `tsLastConnection` | Defaults to `tsJoined` |
  | `sortingDesc` | `'true'` · `'false'` | Defaults to `'true'` |

  **`whitelist.add` identifier formats**
  - `discord:1234567890` — Discord user ID
  - `steam:110000112345678` — Steam hex ID
  - `license:abc123def456` — Rockstar license
  - `live:1234567890` — Xbox Live ID
  - `fivem:123456` — FiveM ID

  **`whitelist.setStatus` parameters**
  - `playerId`: net ID or identifier string (e.g. `license:abcdef...`)
  - `status`: `true` to whitelist, `false` to remove

  <details>
    <summary>Examples</summary>

```lua
-- Pre-whitelist a Discord user before they join
txApi.whitelist.add('discord:1160439375176405062')

-- Remove a Discord user from the "Approved Whitelists Pending Join" table
txApi.whitelist.removeApproval('discord:1160439375176405062')

-- Same as above (for non-license identifiers, setStatus routes to approvals add/remove)
txApi.whitelist.setStatus('discord:1160439375176405062', false)

-- Pre-whitelist by Steam ID
txApi.whitelist.add('steam:110000112345678')

-- Pre-whitelist by Rockstar license
txApi.whitelist.add('license:abc123def456789')

-- Get all approved identifiers
local approvals = txApi.whitelist.getApprovals()
for _, entry in ipairs(approvals) do
    print(('Approved: %s by %s'):format(entry.identifier, entry.addedBy))
end

-- Get all whitelisted players who have joined
local players = txApi.whitelist.getWhitelistedPlayers()
for _, player in ipairs(players) do
    print(('Player: %s'):format(player.displayName))
end

-- Remove whitelist from a player by net ID
txApi.whitelist.setStatus(12, false)

-- Re-whitelist a player by license
txApi.whitelist.setStatus('license:abc123', true)

-- Get pending whitelist requests
local requests = txApi.whitelist.getRequests()
for _, req in ipairs(requests) do
    print(('Request: %s - Discord: %s'):format(req.id, req.discordTag or 'N/A'))
end

-- Approve a pending request
txApi.whitelist.approveRequest('ABC123')

-- Deny a pending request
txApi.whitelist.denyRequest('XYZ789')

-- Deny all pending requests (use the newest request ID from getRequests)
local requests = txApi.whitelist.getRequests()
if requests[1] then
    txApi.whitelist.denyAllRequests(requests[1].id)
end
```
  </details>
</details>

## Support

Feel free to tag me in the official txAdmin discord <@!527236638041047050> or send a friend request to `arceas` and slide into my DMs.

## Extending

- Place new modules under `modules/` and return the table that should attach to `txApi.<name>`.
- Reuse `txApi.txRequest` for new txAdmin endpoints so whitelist and auth headers stay consistent.
- Keep the `AuthState` fields in sync if you adjust the authentication flow.
