txApi.whitelist = {}

--- URL encoding helper for identifiers
---@param str string
---@return string
local function encodeURIComponent(str)
    if str then
        str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    end
    return str
end

--- Get all approved whitelist entries (raw identifiers)
---@return table[]
function txApi.whitelist.getApprovals()
    txApi.log('debug', 'Fetching whitelist approvals')
    
    local response = txApi.txRequest('whitelist/approvals', { method = 'GET' })
    if not response.ok then
        txApi.log('error', 'Failed to get whitelist approvals: ' .. (response.errorText or 'Unknown error'))
        return {}
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode whitelist approvals response')
        return {}
    end
end

--- Get all whitelisted players (players who joined AND are whitelisted)
---@param options? { sortingKey?: string, sortingDesc?: string }
---@return table[]
function txApi.whitelist.getWhitelistedPlayers(options)
    options = options or {}
    txApi.log('debug', 'Fetching whitelisted players')
    
    local queryParams = {
        'sortingKey=' .. (options.sortingKey or 'tsJoined'),
        'sortingDesc=' .. (options.sortingDesc or 'true'),
        'filters=isWhitelisted'
    }
    
    local response = txApi.txRequest('player/search?' .. table.concat(queryParams, '&'), { method = 'GET' })
    if not response.ok then
        txApi.log('error', 'Failed to get whitelisted players: ' .. (response.errorText or 'Unknown error'))
        return {}
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode whitelisted players response')
        return {}
    end
end

--- Get all pending whitelist requests
---@return table[]
function txApi.whitelist.getRequests()
    txApi.log('debug', 'Fetching whitelist requests')
    
    local response = txApi.txRequest('whitelist/requests', { method = 'GET' })
    if not response.ok then
        txApi.log('error', 'Failed to get whitelist requests: ' .. (response.errorText or 'Unknown error'))
        return {}
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        txApi.log('error', 'Failed to decode whitelist requests response')
        return {}
    end
end

--- Add an identifier to the whitelist (pre-approve before they join)
--- Supports: discord, steam, license, live, xbl, fivem identifiers
---@param identifier string e.g., "discord:123456", "steam:110000...", "license:abc..."
---@return table
function txApi.whitelist.add(identifier)
    if not identifier or identifier == '' then
        return { ok = false, status = 400, errorText = 'Identifier is required' }
    end

    txApi.log('info', 'Adding identifier to whitelist: ' .. identifier)
    
    local response = txApi.txRequest('whitelist/approvals/add', {
        method = 'POST',
        body = 'identifier=' .. encodeURIComponent(identifier),
        headers = { ['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8' }
    })

    if not response.ok then
        txApi.log('error', 'Failed to add to whitelist: ' .. (response.errorText or 'Unknown error'))
        return { ok = false, status = response.status, errorText = response.errorText }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        return { ok = true }
    end
end

--- Set whitelist status for a player (add/remove from whitelist)
---@param playerId string|number Net ID or license identifier
---@param status boolean true = whitelist, false = remove
---@return table
function txApi.whitelist.setStatus(playerId, status)
    if not playerId then
        return { ok = false, status = 400, errorText = 'Player ID is required' }
    end

    -- Convert to string and strip prefix if needed
    if type(playerId) == 'number' then
        playerId = tostring(playerId)
    end
    
    local cleanId = playerId
    if playerId:find(':') then
        cleanId = playerId:sub(playerId:find(':') + 1)
    end

    txApi.log('info', ('Setting whitelist status for %s to %s'):format(playerId, tostring(status)))
    
    -- Build query string based on ID type (license is longer than net IDs)
    local queryString = #cleanId > 10 
        and ('license=' .. cleanId) 
        or ('mutex=current&netid=' .. cleanId)
    
    local response = txApi.txRequest('player/whitelist?' .. queryString, {
        method = 'POST',
        body = { status = status }
    })

    if not response.ok then
        txApi.log('error', 'Failed to set whitelist status: ' .. (response.errorText or 'Unknown error'))
        return { ok = false, status = response.status, errorText = response.errorText }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        return { ok = true }
    end
end

--- Approve a pending whitelist request
---@param reqId string The request ID to approve
---@return table
function txApi.whitelist.approveRequest(reqId)
    if not reqId or reqId == '' then
        return { ok = false, status = 400, errorText = 'Request ID is required' }
    end

    txApi.log('info', 'Approving whitelist request: ' .. reqId)
    
    local response = txApi.txRequest('whitelist/requests/approve', {
        method = 'POST',
        body = { reqId = reqId }
    })

    if not response.ok then
        txApi.log('error', 'Failed to approve whitelist request: ' .. (response.errorText or 'Unknown error'))
        return { ok = false, status = response.status, errorText = response.errorText }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        return { ok = true }
    end
end

--- Deny a pending whitelist request
---@param reqId string The request ID to deny
---@return table
function txApi.whitelist.denyRequest(reqId)
    if not reqId or reqId == '' then
        return { ok = false, status = 400, errorText = 'Request ID is required' }
    end

    txApi.log('info', 'Denying whitelist request: ' .. reqId)
    
    local response = txApi.txRequest('whitelist/requests/deny', {
        method = 'POST',
        body = { reqId = reqId }
    })

    if not response.ok then
        txApi.log('error', 'Failed to deny whitelist request: ' .. (response.errorText or 'Unknown error'))
        return { ok = false, status = response.status, errorText = response.errorText }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        return { ok = true }
    end
end

--- Deny all pending whitelist requests
---@param newestVisible string The ID of the newest visible request (for pagination safety)
---@return table
function txApi.whitelist.denyAllRequests(newestVisible)
    if not newestVisible or newestVisible == '' then
        return { ok = false, status = 400, errorText = 'newestVisible parameter is required' }
    end

    txApi.log('warn', 'Denying all whitelist requests up to: ' .. newestVisible)
    
    local response = txApi.txRequest('whitelist/requests/deny_all', {
        method = 'POST',
        body = { newestVisible = newestVisible }
    })

    if not response.ok then
        txApi.log('error', 'Failed to deny all whitelist requests: ' .. (response.errorText or 'Unknown error'))
        return { ok = false, status = response.status, errorText = response.errorText }
    end

    local success, decoded = pcall(json.decode, response.data)
    if success and decoded then
        return decoded
    else
        return { ok = true }
    end
end

return txApi.whitelist
