-- api.lua
_api = {}
_api.__index = _api

function _api.new()
    local self = setmetatable({}, _api)
    return self
end

function _api:login(hostname, username, password)
    -- Check if the url to txAdmin is provided
    if not hostname then
        error("txAdmin hostname is required!")
    end

    -- Remove trailing / from hostname
    if hostname:sub(-1) == "/" then
        hostname = hostname:sub(1, -2)
    end

    -- Set variables for later use
    self.hostname = hostname
    self.username = username

    -- Json object to send to auth endpoint
    local loginData = json.encode({
        username = username,
        password = password
    })
    
    -- Send the login request to the auth endpoint
    PerformHttpRequest(
        hostname .. "/auth/password",
        function(statusCode, response, headers)
            -- Nicely coloured output :)
            print("^2Attempting to authenticate to txAdmin!^7")

            -- Check if the request was successful
            if statusCode ~= 200 then
                print("^1Failed to authenticate to txAdmin!^7", statusCode)
                return
            end

            -- Extract the session cookie
            if headers and headers["Set-Cookie"] then
                self.session = headers["Set-Cookie"]
                print("^2Session cookie extracted!^7")
                print(self.session)
            else
                print("^1Failed to extract session cookie!^7")
            end

            -- Check response data
            if not response or response == "" then
                print("^1Invalid response received when authenticating!^7")
                return
            end

            -- And attempt to decode the json response
            local success, data = pcall(json.decode, response)
            if not success then print("^1Failed to decode json response!^7") return end

            -- Extract the CSRF token from the json response
            if data and data.csrfToken then
                self.csrfToken = data.csrfToken
                print("^2CSRF token extracted!^7")
                print(data.csrfToken)
            else
                print("^1Failed to extract CSRF token!^7")
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
        { ["Content-Type"] = "application/json" }
    )
end

function _api:validate()
    print(self.session, self.csrfToken, self.standardHeaders)
    local sessionValid = self.session and self.session ~= nil
    local csrfValid = self.csrfToken and self.csrfToken ~= nil
    local standardHeadersValid = self.standardHeaders and self.standardHeaders ~= nil

    -- TODO: check with endpoint call, maybe retrieve stats

    return sessionValid and csrfValid and standardHeadersValid
end

function _api:request(method, path, body, callback)
    -- Check if the api class was created successfuly
    if not self:validate() then
        print("^1Failed to validate connection to txAdmin!^7")
        return
    end

    print("^2Requesting to endpoint!^7")
    -- Show data
    print(self.hostname .. path)
    print(method)
    print(body)
    print(self.standardHeaders)

    -- Do the request to the endpoint
    PerformHttpRequest(
        self.hostname .. path,
        function(statusCode, response, headers)
            -- Check if the request was successful
            if statusCode ~= 200 then
                print("^1Endpoint didn't return 200!^7", statusCode)
                print(response)
                return
            end

            -- Since the standard headers normally contain json content type
            -- We can assume that the response is json and decode it
            local success, data = pcall(json.decode, response)
            if not success then print("^1Failed to decode json response!^7") return end

            -- Give the response back to the caller
            if callback then
                callback(data)
            end
        end,
        method,
        json.encode(body),
        self.standardHeaders
    )
end

-- Instance of api to use in this resource
API = _api.new()