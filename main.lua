-- main.lua
local txApi = {}
txApi.__index = txApi

function txApi.new(hostname, username, password)
    local self = setmetatable({}, txApi)

    -- Log in to txAdmin for use of the API
    API:login(hostname, username, password)
    self.isReady = function() return API:validate() end
    
    -- Initialise sub-components
    self.actions = _actions:new()
    self.players = _players:new()

    return self
end

exports('new', txApi.new)