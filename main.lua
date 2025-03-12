-- api.lua
local txApi = {}
txApi.__index = txApi

-- Constructor
function txApi.new(hostname, username, password)
    local self = {}

    self.players = _Players.new()

    function self:Test()
        print("Test")
    end
    
    return self
end

exports('new', txApi.new)