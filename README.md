# txApi

A less sketchy FiveM server resource that, authenticates with txAdmin, exposes helper methods for actions, players, and server controls and soon actions like noclip/repair/heal through imported functions.

## Quick Start

1. Drop the folder into your server resources, e.g. `resources/[local]/txApi`.
2. Add `ensure txApi` to `server.cfg`.
3. Edit `settings/config.lua`:
   - `Hostname`: Base URL for txAdmin.
   - `Username` / `Password`: Credentials used for API login (txAdmin account).
   - `Whitelist`: Resource names allowed to use `txApi` functions.
   - `LogLevel`: One of `error`, `warn`, `info`, `debug`, `trace`.
4. Avoid committing real credentials—use secrets management instead.

On start, `txApi` lazy-loads modules, attempts authentication when credentials exist, and keeps session cookie + CSRF token in a shared state.

## Using the API

```lua
-- fxmanifest.lua
server_scripts {
    '@txApi/init.lua'
}
```

```lua
-- server.lua
while not txApi.isAuthenticated() do
    Citizen.Wait(1000)
end

-- Most functions are usable by netId and license
txApi.players.message(12, 'Server restart in 5 minutes')

-- You can revoke warns / bans by their action id "WACF-2SF1"
txApi.actions.revoke('action-id')

-- In rare cases, can be used to stop or restart the server itself
txApi.server.restart()
```

Key helpers (all return decoded JSON tables when possible):

- `isAuthenticated()` – inspect auth status.
- `sendHTTPRequest(url, opts)` – raw HTTP wrapper returning `{ status, ok, data, errorText, headers }`.
  - `opts.method`: one of `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `OPTIONS`, `HEAD` (defaults to `GET`).
  - `opts.body`: string/any payload (pass table for JSON).
  - `opts.headers`: table of header key/value pairs.
- `txRequest(endpoint, opts)` – authenticated request to `<hostname>/<endpoint>` with whitelist + JSON handling.
  - Inherits `opts` from `sendHTTPRequest`; JSON-encodes `opts.body` automatically.
  - Adds `Cookie` and `X-TxAdmin-CsrfToken` headers from the auth state and enforces whitelist.
- `log(level, ...)` – colourised console logging.

Modules:

<details>
  <summary><code>txApi.actions</code></summary>

  - `actions.search(opts)` – query history by timestamp, reason, action ID, or identifier.

  **`ActionSearchOptions` fields**
  - `sortingKey`: `timestamp` | `playerName` | `playerLicense` | `playerNetId` (default `timestamp`).
  - `sortingDesc`: `true` | `false` (default `true`).
  - `actionId`: string action identifier (`searchType=actionId`).
  - `reason`: string reason filter (`searchType=reason`).
  - `identifier`: string license/identifier (`searchType=identifiers`).
  - `filter`: `warn` | `ban` (`filterbyType`).

```lua
-- Most recent bans (descending)
txApi.actions.search({ filter = 'ban' })

-- Search using a specific player identifier and sort by name
txApi.actions.search({ identifier = 'license:1234', sortingKey = 'playerName', sortingDesc = 'false' })
```

  - `actions.stats()` – fetch aggregated history stats.

```lua
-- Snapshot the current totals
local totals = txApi.actions.stats()
print(('Warns: %s, Bans: %s'):format(totals.warnCount, totals.banCount))

-- Compare against a previous run
local current = txApi.actions.stats()
if previousStats and current.banCount > previousStats.banCount then
    txApi.log('warn', 'New bans detected since last check')
end
```

  - `actions.revoke(actionId)` – revoke a recorded action.

```lua
-- Revoke a known action id
txApi.actions.revoke('action-id-123')

-- Revoke the first result from a search
local results = txApi.actions.search({ actionId = 'action-id-987' })
if results[1] then
    txApi.actions.revoke(results[1].actionId)
end
```
</details>

<details>
  <summary><code>txApi.players</code></summary>

  - `players.search(opts)` – look up players by name, identifier, or notes.

  **`PlayerSearchOptions` fields**
  - `name`: player name substring (`searchType=playerName`).
  - `identifier`: license/identifier string (`searchType=playerIds`).
  - `notes`: note substring (`searchType=playerNotes`).
  - `sortingKey`: `playTime` | `tsJoined` | `tsLastConnection` (default `tsJoined`).
  - `sortingDesc`: `true` | `false` (default `true`).
  - `offsetLicense`: resume pagination using a license value.

```lua
-- Find players whose name starts with "Riley"
txApi.players.search({ name = 'Riley', sortingKey = 'playTime' })

-- Continue pagination using an offset license
txApi.players.search({ sortingKey = 'tsJoined', offsetLicense = 'license:abcdef1234567890' })
```

  - `players.action(action, playerId, body)` – low-level helper powering the wrappers.

  **Parameters**
  - `action`: `message` | `warn` | `kick` | `ban`.
  - `playerId`: server net ID or identifier string (`license:...`). Colon-prefixed identifiers are normalised automatically.
  - `body`: request payload table; wrapper helpers populate defaults.

```lua
-- Send a custom message payload to a net ID
txApi.players.action('message', 12, { message = 'Event starting soon!' })

-- Issue a temporary ban using a license identifier
txApi.players.action('ban', 'license:abc123', { reason = 'Exploits', duration = '6h' })
```

  - `players.message(playerId, message)` – convenient wrapper for messages.

```lua
-- Notify a connected player by net ID
txApi.players.message(21, 'Server restart in 10 minutes!')

-- DM an offline player by license so they see it next login
txApi.players.message('license:9876abcd', 'Please check the rules channel when you return')
```

  - `players.warn(playerId, reason)` – issue warnings.

```lua
-- Warn a player for RDM via net ID
txApi.players.warn(34, 'Random deathmatching is not allowed')

-- Warn by license when the player reconnects
txApi.players.warn('license:9876abcd', 'You were reported for harassment; final warning')
```

  - `players.kick(playerId, reason)` – disconnect players.

```lua
-- Kick a player immediately
txApi.players.kick(7, 'AFK farming is prohibited')

-- Kick by license after extracting from identifiers
txApi.players.kick('license:abcdef1234', 'Cheating detected')
```

  - `players.ban(playerId, reason, duration)` – apply bans.

  **Parameters**
  - `playerId`: net ID or identifier string.
  - `reason`: optional string (defaults to `No reason provided`).
  - `duration`: string duration (e.g. `6h`, `3d`) or `permanent` (default).

```lua
-- Temporary ban with explicit duration
txApi.players.ban(19, 'Repeat RDM', '12h')

-- Permanent ban using license identifier
txApi.players.ban('license:abcdefabcdef', 'Cheating with injected menu', 'permanent')
```
</details>

<details>
  <summary><code>txApi.server</code></summary>

  - `server.restart()` – issue an FXServer restart.

```lua
-- Immediate restart
txApi.server.restart()

-- Schedule a restart in five minutes
Citizen.SetTimeout(5 * 60 * 1000, function()
    txApi.server.restart()
end)
```

  - `server.stop()` – shut down the FXServer instance.

```lua
-- Stop the server after all players leave
if #GetPlayers() == 0 then
    txApi.server.stop()
end

-- Stop as part of an emergency workflow
txApi.players.message(-1, 'Server stopping due to maintenance')
txApi.server.stop()
```
</details>

Each helper logs at the appropriate level; failures return an empty table or `{ ok = false, status = <code>, errorText = <message> }`.

## Support

Feel free to tag me in the official txAdmin discord <@!527236638041047050>,
or send a friend request to `arceas` and approach me in my DMs.

## Extending

- New modules belong in `modules/` and should return a table assigned to `txApi.<name>`.
- Reuse `txApi.txRequest` for any txAdmin endpoints to inherit authentication and whitelist checks.
- Keep `AuthState` fields in sync if you modify login or cookie behaviour.
