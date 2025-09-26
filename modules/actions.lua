txApi.actions = {}

---@class ActionSearchOptions
---@field sortingKey 'timestamp' | 'playerName' | 'playerLicense' | 'playerNetId'
---@field sortingDesc 'true' | 'false'
---@field actionId? string
---@field reason? string
---@field identifier? string
---@field filter? 'warn' | 'ban'

---@param options ActionSearchOptions
---@return table
function txApi.actions.search(options)
    txApi.log('debug', 'Searching for actions with options: ' .. json.encode(options))
    options = options or {}

    -- Set the default query params
    local queryParams = {
        "sortingKey=" .. (options.sortingKey or 'timestamp'),
        "sortingDesc=" .. (options.sortingDesc or 'true'),
    }

    -- Ability to search by action id
    if options.actionId then
        table.insert(queryParams, 'searchType=actionId')
        table.insert(queryParams, 'searchValue=' .. options.actionId)
    end

    -- Ability to search by reason
    if options.reason then
        table.insert(queryParams, 'searchType=reason')
        table.insert(queryParams, 'searchValue=' .. options.reason)
    end

    -- Ability to search by identifier(s)
    if options.identifier then
        table.insert(queryParams, 'searchType=identifiers')
        table.insert(queryParams, 'searchValue=' .. options.identifier)
    end

    -- Ability to filter by warn or ban
    if options.filter then
        table.insert(queryParams, 'filterbyType=' .. options.filter)
    end

    -- Check if multiple search types are provided
    if #queryParams > 4 then
        return {
            ok = false,
            status = 400,
            errorText = 'Multiple search types are not allowed'
        }
    end

    -- Convert the query params to a single string
    local queryString = table.concat(queryParams, '&')

    -- Send the request
    local response = txApi.txRequest('history/search' .. '?' .. queryString, {
        method = 'GET'
    })

    if not response.ok then
        txApi.log('error', 'Failed to search actions: ' .. response.errorText)
        return {}
    end

    -- Decode the response
    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode actions response: ' .. response.errorText)
        return {}
    end
end

---@return table
function txApi.actions.stats()
    -- Request the stats from the history/stats endpoint
    local response = txApi.txRequest('history/stats', {
        method = 'GET'
    })

    if not response.ok then
        txApi.log('error', 'Failed to get actions stats: ' .. response.errorText)
        return {}
    end

    -- Decode the response
    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode actions stats response: ' .. response.errorText)
        return {}
    end
end

---@param actionId string
---@return table
function txApi.actions.revoke(actionId)
    -- Request the revoke from the history/revoke endpoint
    local response = txApi.txRequest('history/revokeAction', {
        method = 'POST',
        body = {
            actionId = actionId
        }
    })

    if not response.ok then
        txApi.log('error', 'Failed to revoke action: ' .. response.errorText)
        return {}
    end

    -- Decode the response
    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode actions revoke response: ' .. response.errorText)
        return {}
    end
end

return txApi.actions