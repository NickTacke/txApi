-- players.lua
_players = {}
_players.__index = _players

function _players.new()
    local self = setmetatable({}, _players)

    function self:search(options)
        options = options or {}

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

        -- Let txAdmin search for the players and return the response
        return API:request("GET", "/player/search?" .. queryString, {})
    end

    function self:action(action, license, body)
        -- Make sure arguments are provided
        if not license then
            print("^1No license provided for player action!^7")
            return
        end

        -- Check if license has license: prefix, if so remove it
        if license:sub(1, 8) == "license:" then
            license = license:sub(9)
        end

        -- Ask txAdmin to perform the action
        return API:request("POST", "/player/" .. action .. "?license=".. license, body)
    end

    -- TODO: Research if possible with netId (mutex?)
    function self:message(license, message)
        return self:action("message", license, { message = message or "No message provided" })
    end

    function self:kick(license, reason)
        return self:action("kick", license, { reason = reason or "No reason provided" })
    end

    function self:warn(license, reason)
        return self:action("warn", license, { reason = reason or "No reason provided" })
    end

    -- TODO: test/research
    function self:ban(license, reason, duration)
        return self:action("ban", license, { reason = reason or "No reason provided", duration = duration or 0 })
    end

    return self
end