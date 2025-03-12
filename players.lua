-- players.lua
_players = {}
_players.__index = _players

function _players.new()
    local self = setmetatable({}, _players)

    function self:search(options, callback)
        options = options or {}

        -- Make sure arguments are provided
        if not callback then
            print("^1No callback provided for player search!^7")
            return
        end

        -- Create the query params
        local queryParams = {
            "sortingKey=" .. (options.sortingKey or "tsJoined"),
            "sortingDesc=" .. (options.sortingDesc or "true"),

            -- TODO: Add other sorting/search/filter methods
        }

        -- Convert the query params to a single string
        local queryString = table.concat(queryParams, "&")

        API:request(
            "GET",
            "/player/search?" .. queryString,
            {},
            function(data)
                callback(data)
            end
        )
    end

    return self
end