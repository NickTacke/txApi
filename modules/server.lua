txApi.server = {}

---@return { ok: boolean, uptimeMs: number, uptimeSeconds: number }
function txApi.server.uptime()
    local uptimeMs
    if type(GetGameTimer) == 'function' then
        uptimeMs = GetGameTimer()
    else
        -- Fallback: coarse uptime since unix epoch start. Not accurate but better than nothing.
        uptimeMs = os.time() * 1000
    end
    return {
        ok = true,
        uptimeMs = uptimeMs,
        uptimeSeconds = math.floor(uptimeMs / 1000),
    }
end

---@return HTTPResponse
function txApi.server.restart()
    txApi.log('warn', 'Restarting server')
    return txApi.txRequest('fxserver/controls', {
        method = 'POST',
        body = {
            action = 'restart'
        }
    })
end

---@return HTTPResponse
function txApi.server.stop()
    txApi.log('warn', 'Stopping server')
    return txApi.txRequest('fxserver/controls', {
        method = 'POST',
        body = {
            action = 'stop'
        }
    })
end

return txApi.server