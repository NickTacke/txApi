---@class HTTPResponse
---@field status number
---@field ok boolean
---@field data? table
---@field errorText? string
---@field headers? table<string, any>

---@class HTTPOptions
---@field method? "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "OPTIONS" | "HEAD"
---@field body? any
---@field headers? table<string, any>

---@param url string
---@param options? HTTPOptions
---@return HTTPResponse
function txApi.sendHTTPRequest(url, options)
    local promise = promise.new()
    if not options then options = {} end
    local method = options.method or 'GET'
    local body = options.body or ''

    PerformHttpRequest(url, function(status, result, headers, err)
        ---@type HTTPResponse
        local response = {
            status = status,
            ok = status >= 200 and status < 300,
            data = result,
            errorText = err,
            headers = headers
        }
        promise:resolve(response)
    end, method, body, options.headers or {})

    return Citizen.Await(promise)
end