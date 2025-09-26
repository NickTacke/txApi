txApi.server = {}

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