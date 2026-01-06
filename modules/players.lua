txApi.players = {}

---@class PlayerSearchOptions
---@field name? string
---@field identifier? string
---@field notes? string
---@field sortingKey? 'playTime' | 'tsJoined' | 'tsLastConnection'
---@field sortingDesc? 'true' | 'false'
---@field offsetLicense? string

---@param options PlayerSearchOptions
---@return table
function txApi.players.search(options)
    txApi.log('debug', 'Searching for players with options: ' .. json.encode(options))
    options = options or {}

    -- Set the default query params
    local queryParams = {
        "sortingKey=" .. (options.sortingKey or 'tsJoined'),
        "sortingDesc=" .. (options.sortingDesc or 'true'),
    }

    -- Add the name query param if it is provided
    if options.name then
        table.insert(queryParams, 'searchType=playerName')
        table.insert(queryParams, 'searchValue=' .. options.name)
    end

    -- Add the license query param if it is provided
    if options.identifier then
        table.insert(queryParams, 'searchType=playerIds')
        table.insert(queryParams, 'searchValue=' .. options.identifier)
    end

    -- Add the notes query param if it is provided
    if options.notes then
        table.insert(queryParams, 'searchType=playerNotes')
        table.insert(queryParams, 'searchValue=' .. options.notes)
    end

    -- Check if multiple search types are provided
    if #queryParams > 4 then
        return {
            ok = false,
            status = 400,
            errorText = 'Multiple search types are not allowed'
        }
    end

    -- Add the offset license query param if it is provided
    if options.offsetLicense then
        table.insert(queryParams, 'offsetLicense=' .. options.offsetLicense)
    end

    -- Build the query string
    local queryString = table.concat(queryParams, '&')

    -- Send the request
    local response = txApi.txRequest('player/search' .. '?' .. queryString, {
        method = 'GET'
    })

    if not response.ok then
        txApi.log('error', 'Failed to search players: ' .. response.errorText)
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or 'Failed to search players'
        }
    end

    -- Decode the response
    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode players response')
        return {
            ok = false,
            status = response.status,
            errorText = 'Failed to decode players response'
        }
    end
end

---@return table
function txApi.players.stats()
    txApi.log('debug', 'Fetching player stats')
    local response = txApi.txRequest('player/stats', {
        method = 'GET'
    })

    if not response.ok then
        txApi.log('error', 'Failed to get players stats: ' .. response.errorText)
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or 'Failed to get players stats'
        }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode players stats response')
        return {
            ok = false,
            status = response.status,
            errorText = 'Failed to decode players stats response'
        }
    end
end

---@param playerId string | number
---@return table
function txApi.players.get(playerId)
    txApi.log('debug', 'Fetching player info: ' .. tostring(playerId))

    if playerId == nil then
        return {
            ok = false,
            status = 400,
            errorText = 'Player id or license is required'
        }
    end

    local endpoint
    if type(playerId) == 'number' then
        endpoint = 'player?mutex=current&netid=' .. tostring(playerId)
    else
        local idStr = tostring(playerId)

        if idStr:find(':') then
            local prefix = idStr:sub(1, idStr:find(':') - 1)
            if prefix == 'license' or prefix == 'license2' then
                idStr = idStr:sub(idStr:find(':') + 1)
            else
                return {
                    ok = false,
                    status = 400,
                    errorText = 'Unsupported identifier type. Use netid (number) or license/license2.'
                }
            end
        end

        endpoint = 'player?license=' .. idStr
    end

    local response = txApi.txRequest(endpoint, {
        method = 'GET'
    })

    if not response.ok then
        txApi.log('error', 'Failed to get player info: ' .. response.errorText)
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or 'Failed to get player info'
        }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode player info response')
        return {
            ok = false,
            status = response.status,
            errorText = 'Failed to decode player info response'
        }
    end
end

---@param action 'message' | 'warn' | 'kick' | 'ban'
---@param playerId string | number
---@param body? any
function txApi.players.action(action, playerId, body)
    -- Check if a player id or license is provided
    if not playerId then
        return {
            ok = false,
            status = 400,
            errorText = 'Player id or license is required'
        }
    end

    txApi.log('info', 'Executing player action: ' .. action .. ' for player id: ' .. tostring(playerId) .. ' with body: ' .. json.encode(body or {}))

    -- Check if the player id is a number and convert it to a string
    if type(playerId) == 'number' then
        playerId = tostring(playerId)
    end

    -- Remove suffix from player id if it is provided
    if playerId:find(':') then
        playerId = playerId:sub(playerId:find(':') + 1)
    end

    -- Send the request
    local response = txApi.txRequest('player/' .. action .. '?' .. 
      (#playerId > 10 and ('license=' .. playerId) or ('mutex=current&netid=' .. playerId)), {
        method = 'POST',
        body = body
    })

    if not response.ok then
        txApi.log('error', 'Failed to ' .. action .. ' player: ' .. response.errorText)
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or ('Failed to ' .. action .. ' player')
        }
    end

    -- Decode the response
    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode players response')
        return {
            ok = false,
            status = response.status,
            errorText = 'Failed to decode players response'
        }
    end
end

---@param playerId string | number
---@param message string
---@return table
function txApi.players.message(playerId, message)
    return txApi.players.action('message', playerId, {
        message = message or 'No message provided'
    })
end

---@param playerId string | number
---@param reason string
---@return table
function txApi.players.warn(playerId, reason)
    return txApi.players.action('warn', playerId, {
        reason = reason or 'No reason provided'
    })
end

---@param playerId string | number
---@param reason string
---@return table
function txApi.players.kick(playerId, reason)
    return txApi.players.action('kick', playerId, {
        reason = reason or 'No reason provided'
    })
end

---@param playerId string | number
---@param reason string
---@param duration string | 'permanent'
---@return table
function txApi.players.ban(playerId, reason, duration)
    return txApi.players.action('ban', playerId, {
        reason = reason or 'No reason provided',
        duration = duration or 'permanent'
    })
end

return txApi.players