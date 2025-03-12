# txApi

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
2. Make sure the resource is in an ensured repository, or add `ensure txApi` to your server.cfg
3. Configure your scripts to use the txApi exports

## Usage

### Basic Setup

```lua
-- In your own server script
local api = exports.txApi:new("http://your-server-ip:port", "adminUsername", "adminPassword")

-- Wait for API to be ready
CreateThread(function()
    while not api:isReady() do
        Wait(1000)
    end
    print("txAdmin API is ready to use!")
    
    -- Your code using the API here
end)
```

### Searching Players

```lua
-- Get all players sorted by join time (newest first)
txAdminApi.players:search({
    sortingKey = "tsJoined", -- Field to sort by
    sortingDesc = "true"     -- Descending order
}, function(data)
    print(json.encode(data))
end)
```

### Searching Admin Actions

```lua
-- Get action history sorted by timestamp (newest first)
txAdminApi.actions:search({
    sortingKey = "timestamp", -- Field to sort by
    sortingDesc = "true"     -- Descending order
}, function(data)
    print(json.encode(data))
end)
```

## API Reference

### Main Module

- `exports.txApi:new(hostname, username, password)` - Creates a new txApi instance
- `txAdminApi.isReady()` - Returns true when authenticated and ready to use

### Players Module

- `txAdminApi.players:search(options, callback)` - Search player data
  - Options:
    - `sortingKey` - Field to sort by (default: "tsJoined")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")

### Actions Module

- `txAdminApi.actions:search(options, callback)` - Search actions (warns/bans)
  - Options:
    - `sortingKey` - Field to sort by (default: "timestamp")
    - `sortingDesc` - "true" for descending, "false" for ascending (default: "true")
- `txAdminApi.actions:stats(callback)` - Get statistics for warns/bans

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