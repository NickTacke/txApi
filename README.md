# txApi
### **DISCLAIMER: This is not made by txAdmin! It's fully made, and maintained by a third party**

A FiveM resource that provides Lua access to txAdmin web-endpoints, allowing you to interact with player data and admin actions through your server scripts.

## Description

txApi creates a simple wrapper around txAdmin's web API endpoints, letting you programmatically access player information and admin actions directly from your FiveM server scripts. This can be useful for creating custom admin panels, statistics tracking, or integrating txAdmin data with other server systems.

## Features

- Simple authentication with txAdmin
- Search player data with customizable sorting
- Search actions (warns/bans) with filtering options
- (Maybe a bit weird, but I kinda suck at lua) OOP/callback based

## Installation

1. Download or clone this repository to your FiveM server's resources folder
2. Make sure the resource is in an ensured directory, or add `ensure txApi` to your server.cfg
3. Configure your scripts to use the txApi exports
4. Make sure to remove .example from the config in the settings folder
5. Change your account details in the config.lua file

## Usage

### Basic Setup

```lua
-- In your own server script
local api = exports.txApi:get()

-- Wait for API to be ready
CreateThread(function()
    while not api:isReady() do
        Wait(1000)
    end
    print("txAdmin API is ready to use!")
    
    -- Your code using the API here
    local result = api.actions:search({})
    print(json.encode(result, { indent = true }))
end)
```

### Searching Players

```lua
-- Get all players sorted by join time (newest first)
local response = api.players:search({
    sortingKey = "tsJoined",
    sortingDesc = "true"
})
print(json.encode(response, { indent = true }))
```

### Sending Direct Message to Players

```lua
local response = api.players:message("74309af47c7f34f51d74631e717d5d72d9bd277a", "Hello!")
print(response.success and "Messaged player!" or response.error)
```

### Kicking Players

```lua
local response = api.players:kick("74309af47c7f34f51d74631e717d5d72d9bd277a", "Breaking rules!")
print(response.success and "Kicked player!" or response.error)
```

### Warning Players

```lua
local response = api.players:warn("74309af47c7f34f51d74631e717d5d72d9bd277a", "Breaking rules!")
print(response.success and "Warned player!" or response.error)
```

### Searching Ban/Warn Actions

```lua
-- Get action history sorted by timestamp (newest first)
local response = api.actions:search({
    sortingKey = "timestamp",
    sortingDesc = "true"
})
print(json.encode(response, { indent = true }))
```

### Getting Ban/Warn Statistics

```lua
local response = api.actions:stats()
print(json.encode(response, { indent = true }))
```

### Revoking a Ban/Warn

```lua
local response = api.actions:revoke("WX7M-CVPD")
print(response.success and "Action revoked!" or response.error)
```

## API Reference

### Main Module

- `api:get()` - Returns the instance made in the txApi resource
- `api:new(hostname, username, password)` - Creates a new txApi instance (shouldn't be used tbh)
- `api:isReady()` - Returns true when authenticated and ready to use

### Players Module

- `api.players:search(options)` - Search player data
  - options:
    - `sortingKey` - Field to sort by (default: "tsJoined")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")
    - `name` - Search for specific player(s) by name (default: nil)
    - `license` - Search for a specific player by license (default: nil)
    - `notes` - Search for specific player(s) by something in their notes (default: nil)
- `api.players:message(license, message)` - Send an ingame direct message
- `api.players:kick(license, reason)` - Kick the player using txAdmin
- `api.players:warn(license, reason)` - Warn the player using txAdmin

### Actions Module

- `api.actions:search(options)` - Search actions (warns/bans)
  - options:
    - `sortingKey` - Field to sort by (default: "timestamp")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")
    - `actionId` - Search for a specific action by actionId (default: nil)
    - `reason` - Search for specific action(s) by reason (default: nil)
    - `identifier` - Search for actions of a specific player with identifier (default: nil)
- `api.actions:stats()` - Get statistics for warns/bans
- `api.actions:revoke(actionId)` - Get statistics for warns/bans
  - actionId: string id for the action id (example: BG5N-STDV)

### Server Module

- `api.server:restart()` - Restart the server
- `api.server:stop()` - Stop the server

## Security Note

This resource provides direct access to txAdmin functions. Use with caution and ensure:
1. You store your txAdmin credentials securely
2. You limit which server resources can access this API
3. You validate all inputs before passing them to the API

## Author

Arceas (https://github.com/NickTacke)

## Links
- [txAdmin Github Repository](https://github.com/tabarra/txAdmin)
- [txAdmin Discord](https://discord.gg/txAdmin)
- [GitHub Repository](https://github.com/NickTacke/txApi)
