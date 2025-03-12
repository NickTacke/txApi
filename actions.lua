-- actions.lua
_actions = {}
_actions.__index = _actions

function _actions.new()
    local self = setmetatable({}, _actions)

    function self:search()
        API:request(
            "GET",
            "/history/search" ..
            "?sortingKey=timestamp",
            {},
            function(data)
                print(json.encode(data))
            end
        )
    end

    return self
end