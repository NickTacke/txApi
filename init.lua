if _ENV.txApi then return _ENV.txApi end
local resourceName = GetCurrentResourceName()
local txExports = exports['txApi']

local txApi = {}
txApi.version = "1.5.3"

-- Load the module loader
local loaderFile = LoadResourceFile('txApi', "core/loader.lua")
local loader, err = load(loaderFile)
if not loader or err then
    return error(('%s: Failed to load loader: %s'):format(resourceName, err))
end
loader()

-- index / call metatable helper
local function index_call_helper(self, index, ...)
    local module = rawget(self, index)
    -- If the module is not found, load it
    if not module then
        self[index] = function() end
        module = load_module(self, index)
        -- Check for proxy modules
        if not module then
            local function method(...)
                return exports['txApi'][index](nil, ...)
            end
            if not ... then
                self[index] = method
            end
            return method
        end
    end
    return module
end

txApi = setmetatable({
    resourceName = resourceName,
    version = txApi.version,
}, {
    __index = index_call_helper,
    __call = index_call_helper
})

-- Auto-attempt authentication on resource start if credentials are present
CreateThread(function()
    -- Wait for config & http methods to be loaded
    while not txApi.getConfig or not txApi.authenticate or not txApi.sendHTTPRequest or not txApi.getAuthState do
        Wait(100)
    end
    -- Check if not already authenticated
    if txApi.getAuthState().isAuthenticated then return end
    -- Check if config is loaded
    local cfg = txApi.getConfig()
    if not cfg then return end
    if (cfg.Hostname and cfg.Hostname ~= '') and 
       (cfg.Username and cfg.Username ~= '') and 
       (cfg.Password and cfg.Password ~= '') then
        -- Log in to txAdmin
        txApi.authenticate(cfg.Hostname, cfg.Username, cfg.Password)
    end
end)

-- Export the txApi table
_ENV.txApi = txApi
return txApi