-- api.lua
_api = {}
_api.__index = _api

function _api.new(hostname, username, password)
    local self = setmetatable({}, _api)
    self.hostname = hostname

    
    
    return self
end