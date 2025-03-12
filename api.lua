-- api.lua
_api = {}
_api.__index = _api

function _api.new(hostname, username, password)
    local self = setmetatable({}, _api)

    -- Check if required parameters are provided
    if not hostname or not username or not password then
        error("Hostname, username and password are required")
    end

    -- Remove trailing / from hostname
    if hostname:sub(-1) == "/" then
        hostname = hostname:sub(1, -2)
    end
    
    -- Store variables for later use
    self.hostname = hostname
    self.username = username

    -- Json object to send to auth endpoint
    local loginData = json.encode({
        username = username,
        password = password
    })
    
    -- Send the login request to the auth endpoint
    PerformHttpRequest(
        hostname .. "/auth/login",
        function(statusCode, response, headers)
            -- Nicely coloured output :)
            print("^2[txApi]^7 Attempting to authenticate to txAdmin!")

            -- Check if the request was successful
            if statusCode == 200 then
                print("^2[txApi]^7 Successfully authenticated to txAdmin!")
            else
                print("^1[txApi]^7 Failed to authenticate to txAdmin!")
            end

            -- Extract the session cookie
            if headers and headers["Set-Cookie"] then
                self.session = headers["Set-Cookie"]
                print("^2[txApi]^7 Session cookie extracted!")
            else
                print("^1[txApi]^7 Failed to extract session cookie!")
            end

            -- Check response data
            if not response or response == "" then
                print("^1[txApi]^7 Invalid response received when authenticating!")
                return
            end
            
            -- And attempt to decode the json response
            local success, data = pcall(json.decode, response)
            if not success then print("^1[txApi]^7 Failed to decode json response!") return end

            -- Extract the CSRF token from the json response
            if data and data.csrfToken then
                self.csrfToken = data.csrfToken
                print("^2[txApi]^7 CSRF token extracted!")
            else
                print("^1[txApi]^7 Failed to extract CSRF token!")
            end

            -- Set standard headers for future api calls
            self.standardHeaders = {
                ["Cookie"] = self.session,
                ["X-TxAdmin-CsrfToken"] = self.csrfToken,
                ["Content-Type"] = "application/json"
            }
        end,
        "POST",
        loginData,
        {} -- Empty headers, might add content-type to check for success
    )
    return self
end

function _api:validate()
    local sessionValid = self.session and self.session ~= nil
    local csrfValid = self.csrfToken and self.csrfToken ~= nil
    local standardHeadersValid = self.standardHeaders and self.standardHeaders ~= nil

    -- TODO: check with endpoint call, maybe retrieve stats

    return sessionValid and csrfValid and standardHeadersValid
end

function _api:GET()
    
end