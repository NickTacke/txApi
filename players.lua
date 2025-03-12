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
            "sortingKey=" .. (options.sortingKey or "tsJoined"), -- playTime, tsJoined, tsLastConnection
            "sortingDesc=" .. (options.sortingDesc or "true"), -- true, false
        }

        -- Ability to search by name
        if options.name then
            table.insert(queryParams, "searchType=playerName")
            table.insert(queryParams, "searchValue=" .. options.name)
        end

        -- Ability to search by license
        if options.license then
            table.insert(queryParams, "searchType=playerIds")
            table.insert(queryParams, "searchValue=" .. options.license)
        end

        -- Ability to search by notes
        if options.notes then
            table.insert(queryParams, "searchType=playerNotes")
            table.insert(queryParams, "searchValue=" .. options.notes)
        end

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

        -- Check if license has license: prefix, if so remove it
        if license:sub(1, 8) == "license:" then
            license = license:sub(9)
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

        -- Check if license has license: prefix, if so remove it
        if license:sub(1, 8) == "license:" then
            license = license:sub(9)
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

        -- Check if license has license: prefix, if so remove it
        if license:sub(1, 8) == "license:" then
            license = license:sub(9)
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