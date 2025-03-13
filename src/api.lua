-- api.lua
_api = {}
_api.__index = _api

function _api.new()
    local self = setmetatable({}, _api)
    return self
end

function _api:login(hostname, username, password)
    -- Check if the login details were provided
    if not hostname or not username or not password then
        print("^1No login details provided for txAdmin!^7")
        return
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
    
    local promise = promise.new()
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
            else
                print("^1Failed to extract CSRF token!^7")
            end

            -- Set standard headers for future api calls
            self.standardHeaders = {
                ["Cookie"] = self.session,
                ["X-TxAdmin-CsrfToken"] = self.csrfToken,
                ["Content-Type"] = "application/json"
            }

            -- Resolve the promise
            promise:resolve({
                session = self.session,
                csrfToken = self.csrfToken,
                standardHeaders = self.standardHeaders
            })
        end,
        "POST",
        loginData,
        { ["Content-Type"] = "application/json" }
    )
    return Citizen.Await(promise)
end

function _api:validate()
    local sessionValid = self.session and self.session ~= nil
    local csrfValid = self.csrfToken and self.csrfToken ~= nil
    local standardHeadersValid = self.standardHeaders and self.standardHeaders ~= nil

    -- TODO: check with endpoint call, maybe retrieve stats

    return sessionValid and csrfValid and standardHeadersValid
end

function _api:request(method, path, body)
    -- Check if the api class was created successfuly
    if not self:validate() then
        print("^1Failed to validate connection to txAdmin!^7")
        return
    end

    -- Print debug information
    -- print("^2Requesting endpoint: ^7", path)
    -- print("^2Method: ^7", method)
    -- print("^2Body: ^7", json.encode(body))

    local promise = promise.new()
    -- Do the request to the endpoint
    PerformHttpRequest(
        self.hostname .. path,
        function(statusCode, responseData, responseHeaders, statusText)
            -- Since the standard headers normally contain json content type
            -- We can assume that the response is json and decode it
            local success, data = pcall(json.decode, response)
            if not success then print("^1Failed to decode json response!^7") return end

            -- Response object to pass to promise
            local response = {
                statusCode = statusCode,
                data = responseData,
                headers = responseHeaders,
                errorText = statusText,
                ok = statusCode >= 200 and statusCode < 300
            }

            -- Resolve the promise with the response object
            promise:resolve(response)
        end,
        method,
        json.encode(body),
        self.standardHeaders
    )
    return Citizen.Await(promise)
end

-- Instance of api to use in this resource
API = _api.new()