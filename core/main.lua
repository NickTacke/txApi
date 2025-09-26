---@param self table
---@param key string
---@param fn function
local function exports_proxy(self, key, fn)
    -- Set the function in the metatable
    rawset(self, key, fn)
    
    -- If the function is being called from a subfile of the resource directory, export it
    local src = debug.getinfo(2, 'S').short_src or ''
    if src:find('@txApi/core', 1, true) then
        exports(key, fn)
    end
end

txApi = setmetatable({
    name = GetCurrentResourceName(),
    config = Config
}, {
    __index = load_module,
    __newindex = exports_proxy,
})

function txApi.getConfig()
    return Config
end