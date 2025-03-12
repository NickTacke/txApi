-- main.lua
_txApi = {}
_txApi.__index = _txApi

function _txApi.new(hostname, username, password)
    local self = setmetatable({}, _txApi)

    -- Log in to txAdmin for use of the API
    API:login(hostname, username, password)
    self.isReady = function() return API:validate() end
    
    -- Initialise sub-components
    self.actions = _actions:new()
    self.players = _players:new()

    return self
end

local txApi = _txApi.new(
    Config.Hostname, 
    Config.Username, 
    Config.Password
)

exports('get', function()
    return txApi    
end)