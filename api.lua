-- api.lua
_api = {}
_api.__index = _api

function _api.new(hostname, username, password)
    local self = setmetatable({}, _api)

    -- Check if required parameters are provided
    if not hostname or not username or not password then
        error("Hostname, username and password are required")
    end

    -- Remove trailing / from hostname
    if hostname:sub(-1) == "/" then
        hostname = hostname:sub(1, -2)
    end
    
    -- Store variables for later use
    self.hostname = hostname
    self.username = username

    -- Json object to send to auth endpoint
    local loginData = json.encode({
        username = username,
        password = password
    })
    
    
    
    return self
end