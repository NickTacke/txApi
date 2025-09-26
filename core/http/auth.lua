---@class AuthState
---@field configured boolean
---@field isAuthenticated boolean
---@field hostname string?
---@field username string?
---@field password string?
---@field sessionCookie string?
---@field csrfToken string?

local authState ---@type AuthState
authState = {
	configured = false,
	isAuthenticated = false,
	hostname = nil,
	username = nil,
	password = nil,
	sessionCookie = nil,
	csrfToken = nil,
}

---@return AuthState
function txApi.getAuthState()
    return authState
end

---@return boolean
function txApi.isAuthenticated()
    return authState.isAuthenticated
end

---@param hostname string
---@param username string
---@param password string
function txApi.authenticate(hostname, username, password)
    -- Check if all required parameters are present
    if not hostname or not username or not password then
        return false
    end
    
    -- Set the authentication state
    authState.configured = true
    authState.hostname = hostname
    authState.username = username
    authState.password = password
    
    -- Attempt to authenticate
    local response = exports['txApi'].sendHTTPRequest(nil, hostname .. '/auth/password', {
        method = 'POST',
        body = json.encode({
            username = username,
            password = password
        }),
        headers = {
            ['Content-Type'] = 'application/json'
        }
    })

    -- Check if the authentication was successful
    if response.ok then
        -- Set the session cookie and CSRF token
        authState.sessionCookie = response.headers['Set-Cookie']
        local csrfToken
        if response.data then
            local success, decoded = pcall(json.decode, response.data)
            if success and decoded then
                csrfToken = decoded.csrfToken
            end
        end
        authState.csrfToken = csrfToken
        -- Check if the session cookie and CSRF token are set
        if authState.sessionCookie and authState.csrfToken then
            authState.isAuthenticated = true
            return true
        else
            print("Authentication succeeded but missing required tokens")
            return false
        end
    else
        print("Failed to authenticate:", response.status, response.errorText or "Unknown error")
        return false
    end
end

---@param endpoint string
---@param options? HTTPOptions
---@return HTTPResponse
function txApi.txRequest(endpoint, options)
    -- Check if resource is in the whitelist
    local cfg = txApi.getConfig()
    local isWhitelisted = false
    
    -- Loop through the whitelist
    for _, resource in pairs(cfg.Whitelist) do
        if resource == GetInvokingResource() then
            isWhitelisted = true
            break
        end
    end

    -- Show the user that the resource is not whitelisted
    if not isWhitelisted then
        return {
            ok = false,
            status = 403,
            errorText = "Resource not whitelisted"
        }
    end
    
    -- Show the user that the resource is not authenticated (yet)
    if not authState.isAuthenticated then
        return {
            ok = false,
            status = 401,
            errorText = "Not authenticated"
        }
    end

    -- Set the default options
    options = options or {}
    options.method = options.method or 'GET'
    options.headers = options.headers or {}
    options.headers['Cookie'] = authState.sessionCookie
    options.headers['X-TxAdmin-CsrfToken'] = authState.csrfToken
    options.headers['Content-Type'] = 'application/json'

    -- Attempt to encode the body
    if options.body then
        local success, encoded = pcall(json.encode, options.body)
        if success then
            options.body = encoded
        end
    else
        options.body = ''
    end
    
    -- Send the request to the endpoint
    return exports['txApi'].sendHTTPRequest(nil, ('%s/%s'):format(authState.hostname, endpoint), options)
end