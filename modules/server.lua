txApi.server = {}

local startTsMs = os.time() * 1000

---@param name any
---@return string|nil, string|nil
local function normalizeResourceName(name)
    if type(name) ~= 'string' then
        return nil, 'resourceName must be a string'
    end
    name = name:match('^%s*(.-)%s*$')
    if not name or name == '' then
        return nil, 'resourceName is required'
    end
    return name, nil
end

---@param resourceName string
---@param desiredState string
---@param timeoutMs number
---@return boolean
local function waitForResourceState(resourceName, desiredState, timeoutMs)
    if type(GetResourceState) ~= 'function' or type(Wait) ~= 'function' then
        return false
    end

    local startMs
    if type(GetGameTimer) == 'function' then
        startMs = GetGameTimer()
    else
        startMs = os.time() * 1000
    end

    while true do
        if GetResourceState(resourceName) == desiredState then
            return true
        end

        local nowMs
        if type(GetGameTimer) == 'function' then
            nowMs = GetGameTimer()
        else
            nowMs = os.time() * 1000
        end

        if (nowMs - startMs) >= timeoutMs then
            return false
        end

        Wait(0)
    end
end

---@return { ok: boolean, uptimeMs: number, uptimeSeconds: number }
function txApi.server.uptime()
    local uptimeMs
    if type(GetGameTimer) == 'function' then
        uptimeMs = GetGameTimer()
    else
        uptimeMs = (os.time() * 1000) - startTsMs
    end
    return {
        ok = true,
        uptimeMs = uptimeMs,
        uptimeSeconds = math.floor(uptimeMs / 1000),
    }
end

---@return { ok: boolean, count?: number, resources?: { name: string, state: string }[], error?: string }
function txApi.server.getResourceList()
    if type(GetNumResources) ~= 'function'
        or type(GetResourceByFindIndex) ~= 'function'
        or type(GetResourceState) ~= 'function'
    then
        return { ok = false, error = 'Resource listing natives are not available in this runtime.' }
    end

    local resources = {}
    local count = GetNumResources()

    for i = 0, (count - 1) do
        local name = GetResourceByFindIndex(i)
        if name and name ~= '' then
            resources[#resources + 1] = {
                name = name,
                state = GetResourceState(name) or 'unknown',
            }
        end
    end

    return {
        ok = true,
        count = #resources,
        resources = resources,
    }
end

---@param resourceName string
---@return { ok: boolean, name?: string, previousState?: string, state?: string, changed?: boolean, error?: string }
function txApi.server.startResource(resourceName)
    local name, err = normalizeResourceName(resourceName)
    if not name then return { ok = false, error = err } end

    if type(GetResourceState) ~= 'function' or type(StartResource) ~= 'function' then
        return { ok = false, error = 'StartResource/GetResourceState natives are not available in this runtime.' }
    end

    local previousState = GetResourceState(name)
    if previousState == 'started' then
        return { ok = true, name = name, previousState = previousState, state = previousState, changed = false }
    end

    local startedOk = StartResource(name)
    waitForResourceState(name, 'started', 2000)
    local state = GetResourceState(name)

    return {
        ok = startedOk == true,
        name = name,
        previousState = previousState,
        state = state,
        changed = (startedOk == true and state == 'started'),
        error = (startedOk == true) and nil or 'StartResource returned false',
    }
end

---@param resourceName string
---@return { ok: boolean, name?: string, previousState?: string, state?: string, changed?: boolean, error?: string }
function txApi.server.stopResource(resourceName)
    local name, err = normalizeResourceName(resourceName)
    if not name then return { ok = false, error = err } end

    if type(GetResourceState) ~= 'function' or type(StopResource) ~= 'function' then
        return { ok = false, error = 'StopResource/GetResourceState natives are not available in this runtime.' }
    end

    local previousState = GetResourceState(name)
    if previousState ~= 'started' then
        return { ok = true, name = name, previousState = previousState, state = previousState, changed = false }
    end

    local stoppedOk = StopResource(name)
    waitForResourceState(name, 'stopped', 2000)
    local state = GetResourceState(name)

    return {
        ok = stoppedOk == true,
        name = name,
        previousState = previousState,
        state = state,
        changed = (stoppedOk == true and state ~= 'started'),
        error = (stoppedOk == true) and nil or 'StopResource returned false',
    }
end

---@param resourceName string
---@return { ok: boolean, name?: string, previousState?: string, state?: string, error?: string }
function txApi.server.restartResource(resourceName)
    local name, err = normalizeResourceName(resourceName)
    if not name then return { ok = false, error = err } end

    if type(GetResourceState) ~= 'function' then
        return { ok = false, error = 'GetResourceState native is not available in this runtime.' }
    end

    local previousState = GetResourceState(name)

    if type(RestartResource) == 'function' then
        local restartedOk = RestartResource(name)
        waitForResourceState(name, 'started', 3000)
        return {
            ok = restartedOk == true,
            name = name,
            previousState = previousState,
            state = GetResourceState(name),
            error = (restartedOk == true) and nil or 'RestartResource returned false',
        }
    end

    if previousState == 'started' then
        if type(StopResource) == 'function' then
            StopResource(name)
            waitForResourceState(name, 'stopped', 3000)
        end
    end

    if type(StartResource) ~= 'function' then
        return { ok = false, name = name, previousState = previousState, state = GetResourceState(name), error = 'StartResource native is not available in this runtime.' }
    end

    local startedOk = StartResource(name)
    waitForResourceState(name, 'started', 3000)
    return {
        ok = startedOk == true,
        name = name,
        previousState = previousState,
        state = GetResourceState(name),
        error = (startedOk == true) and nil or 'StartResource returned false',
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

---@param str any
---@return string
local function decodeHtmlEntities(str)
    if type(str) ~= 'string' or str == '' then return '' end

    if type(utf8) == 'table' and type(utf8.char) == 'function' then
        str = str:gsub('&#x([0-9a-fA-F]+);', function(hex)
            local code = tonumber(hex, 16)
            if not code then return '' end
            local ok, ch = pcall(utf8.char, code)
            return ok and ch or ''
        end)
        str = str:gsub('&#(%d+);', function(dec)
            local code = tonumber(dec, 10)
            if not code then return '' end
            local ok, ch = pcall(utf8.char, code)
            return ok and ch or ''
        end)
    end

    str = str:gsub('&quot;', '"')
    str = str:gsub('&#39;', "'")
    str = str:gsub('&lt;', '<')
    str = str:gsub('&gt;', '>')
    str = str:gsub('&amp;', '&')

    return str
end

---@return { ok: boolean, cfgData?: string, status?: number, errorText?: string }
function txApi.server.getCfgEditorFile()
    local function fetch(path)
        return txApi.txRequest(path, {
            method = 'GET',
            headers = {
                ['Accept'] = 'text/html',
            }
        })
    end

    local response = fetch('legacy/cfgEditor')
    if not response.ok and response.status == 404 then
        response = fetch('cfgEditor')
    end

    if not response.ok then
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or 'Failed to fetch cfg editor page',
        }
    end

    local html = response.data or ''
    if type(html) ~= 'string' or html == '' then
        return { ok = false, status = response.status, errorText = 'Empty response from cfg editor page' }
    end

    local raw = html:match('<textarea[^>]-id=["\']codeMirrorTarget["\'][^>]*>(.-)</textarea>')
    if not raw then
        return { ok = false, status = response.status, errorText = 'Could not find cfg editor textarea in HTML' }
    end

    return {
        ok = true,
        cfgData = decodeHtmlEntities(raw),
    }
end

---@param cfgData string
---@return { ok: boolean, type?: string, markdown?: boolean, message?: string, status?: number, errorText?: string, raw?: any }
function txApi.server.saveCfgEditorFile(cfgData)
    if type(cfgData) ~= 'string' then
        return { ok = false, errorText = 'cfgData must be a string' }
    end

    local response = txApi.txRequest('cfgEditor/save', {
        method = 'POST',
        body = {
            cfgData = cfgData,
        },
    })

    if not response.ok then
        return {
            ok = false,
            status = response.status,
            errorText = response.errorText or 'Failed to save cfg',
            raw = response.data,
        }
    end

    if type(response.data) == 'string' and response.data ~= '' then
        local okDecode, decoded = pcall(json.decode, response.data)
        if okDecode and type(decoded) == 'table' then
            local isOk = decoded.type == 'success'
            return {
                ok = isOk,
                type = decoded.type,
                markdown = decoded.markdown == true,
                message = decoded.message,
                status = response.status,
                raw = decoded,
            }
        end
    end

    return {
        ok = true,
        status = response.status,
        raw = response.data,
    }
end

return txApi.server