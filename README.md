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
4. Make sure to change the login variables in settings/config.lua

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
    api.actions:search({}, function(data)
        print(json.encode(data))
    end)
end)
```

### Searching Players

```lua
-- Get all players sorted by join time (newest first)
api.players:search({
    sortingKey = "tsJoined", -- Field to sort by
    sortingDesc = "true"     -- Descending order
}, function(data)
    print(json.encode(data))
end)
```

### Sending Direct Message to Players

```lua
api.players:message("74309af47c7f34f51d74631e717d5d72d9bd277a", "Hello!", function(response)
    print(json.encode(response))
end)
```

### Kicking Players

```lua
api.players:kick("74309af47c7f34f51d74631e717d5d72d9bd277a", "Breaking rules!", function(response)
    print(json.encode(response))
end)
```

### Warning Players

```lua
api.players:warn("74309af47c7f34f51d74631e717d5d72d9bd277a", "Breaking rules!", function(response)
    print(json.encode(response))
end)
```

### Searching Ban/Warn Actions

```lua
-- Get action history sorted by timestamp (newest first)
api.actions:search({
    sortingKey = "timestamp", -- Field to sort by
    sortingDesc = "true"     -- Descending order
}, function(data)
    print(json.encode(data))
end)
```

### Getting Ban/Warn Statistics

```lua
api.actions:stats(function(data)
    print(json.encode(data))
end)
```

### Revoking a Ban/Warn

```lua
api.actions:revoke("WEUE-LL51", function(response)
    print(json.encode(response))
end)
```

## API Reference

### Main Module

- `api:get()` - Returns the instance made in the txApi resource
- `api:new(hostname, username, password)` - Creates a new txApi instance (shouldn't be used tbh)
- `api:isReady()` - Returns true when authenticated and ready to use

### Players Module

- `api.players:search(options, callback)` - Search player data
  - options:
    - `sortingKey` - Field to sort by (default: "tsJoined")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")
    - `name` - Search for specific player(s) by name (default: nil)
    - `license` - Search for a specific player by license (default: nil)
    - `notes` - Search for specific player(s) by something in their notes (default: nil)
- `api.players:message(license, message, callback)` - Send an ingame direct message
- `api.players:kick(license, reason, callback)` - Kick the player using txAdmin
- `api.players:warn(license, reason, callback)` - Warn the player using txAdmin

### Actions Module

- `api.actions:search(options, callback)` - Search actions (warns/bans)
  - options:
    - `sortingKey` - Field to sort by (default: "timestamp")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")
    - `actionId` - Search for a specific action by actionId (default: nil)
    - `reason` - Search for specific action(s) by reason (default: nil)
    - `identifier` - Search for actions of a specific player with identifier (default: nil)
- `api.actions:stats(callback)` - Get statistics for warns/bans
- `api.actions:revoke(actionId, callback)` - Get statistics for warns/bans
  - actionId: string id for the action id (example: BG5N-STDV)

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
