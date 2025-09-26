Config = {}

-- Authentication details
Config.Hostname = "http://localhost:40120"
Config.Username = "txapi" -- txAdmin username
Config.Password = "SuperStrongPassword" -- txAdmin password

-- Whitelisted resources
Config.Whitelist = {
    "txApi-testing",
}

-- Settings
-- LogLevel: Set to "error", "warn", "info", "debug", or "trace"
Config.LogLevel = "info"