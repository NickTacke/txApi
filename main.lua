-- api.lua
local txApi = {}
txApi.__index = txApi

-- Constructor
function txApi.new(hostname, username, password)
    local self = setmetatable({}, txApi)

    print(hostname, username, password)
    self.api = _api.new(hostname, username, password)
    self.players = _players.new()
    
    while not self.api:validate() do
        Citizen.Wait(100)
    end

    return self
end

exports('new', function(hostname, username, password)
    print(hostname, username, password)
    return txApi.new(hostname, username, password)
end)