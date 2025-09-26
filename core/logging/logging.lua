---@type table<string, number>
local logLevels = {
    error = 0,
    warn = 1,
    info = 2,
    debug = 3,
    trace = 4,
}

---@type table<string, string>
local logColors = {
    error = '^1',
    warn = '^3',
    info = '^5',
    debug = '^9',
    trace = '^6',
}

---@param logLevel "error" | "warn" | "info" | "debug" | "trace"
---@param ... any
function txApi.log(logLevel, ...)
    if not logLevels[logLevel] then
        print(('[^1error^7] Invalid log level: %s'):format(logLevel))
        return
    end
    if logLevels[txApi.getConfig().LogLevel] < logLevels[logLevel] then
        return
    end
    print(('[%s%s^7] %s'):format(logColors[logLevel], string.upper(logLevel), table.concat({...}, ' ')))
end