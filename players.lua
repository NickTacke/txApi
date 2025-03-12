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

    -- TODO: Research if possible with netId (mutex?)
    function self:message(license, message, callback)
        -- Make sure arguments are provided
        if not license then
            print("^1No license provided for player message!^7")
            return
        end

        -- Ask txAdmin to message the player
        API:request(
            "POST",
            "/player/message?license=" .. license,
            { message = message or "No message provided" },
            function(data)
                callback(data)
            end
        )
    end

    function self:kick(license, reason, callback)
        -- Make sure arguments are provided
        if not license then
            print("^1No license provided for player kick!^7")
            return
        end

        -- Ask txAdmin to kick the player
        API:request(
            "POST",
            "/player/kick?license=" .. license,
            { reason = reason or "No reason provided" },
            function(data)
                callback(data)
            end
        )
    end

    function self:warn(license, reason, callback)
        -- Make sure arguments are provided
        if not license then
            print("^1No license provided for player warn!^7")
            return
        end

        -- Ask txAdmin to warn the player
        API:request(
            "POST",
            "/player/warn?license=" .. license,
            { reason = reason or "No reason provided"},
            function(data)
                callback(data)
            end
        )
    end

    return self
end