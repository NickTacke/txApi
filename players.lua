-- players.lua
_players = {}
_players.__index = _players

function _players.new()
    local self = setmetatable({}, _players)

    function self:search()
        API:request(
            "GET",
            "/player/search" ..
            "?sortingKey=tsJoined",
            {},
            function(data)
                print(json.encode(data))
            end
        )
    end

    return self
end