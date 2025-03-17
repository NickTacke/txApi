-- config.lua
Config = {}

-- Authentication details
Config.Hostname = "http://localhost:40120"
Config.Username = "txAdmin" -- txAdmin user - username
Config.Password = "txPassword" -- txAdmin user - password

-- Whitelisted resources
Config.Whitelist = {
    "txApiExample",
}

-- Settings
Config.Debug = false -- Set to true to enable debug messages