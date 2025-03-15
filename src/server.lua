-- server.lua
_server = {}
_server.__index = _server

function _server.new()
    local self = setmetatable({}, _server)

    function self:restart()
        return API:request("POST", "/fxserver/controls", {action = 'restart'}).data
    end

    function self:stop()
        return API:request("POST", "/fxserver/controls", {action = 'stop'}).data
    end

    return self
end