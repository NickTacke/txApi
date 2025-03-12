-- api.lua
local txApi = {}
txApi.__index = txApi

--session: tx:bcb93507953c=b554e701-f6fe-472e-ad28-183606f56c38; path=/; expires=Thu, 13 Mar 2025 12:53:45 GMT; samesite=lax; httponly
--csrf: BOnvpqYSC4G_c_Mb8_6n7

-- Constructor
function txApi.new(hostname, username, password)
    local self = setmetatable({}, txApi)

    -- Log in to txAdmin for use of the API
    API:login(hostname, username, password)
    self.isReady = function() return API:validate() end
    
    -- Initialise sub-components
    self.players = _players:new()

    return self
end

exports('new', txApi.new)