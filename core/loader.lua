---@param root string
---@param module string
---@return string, string?
function load_resource_file(root, module)
    -- Load and return the contents of the module files 
    local chunk = LoadResourceFile('txApi', ("%s/%s.lua"):format(root, module))
    return root, chunk
end

---@param self table
---@param module string
---@return any
function load_module(self, module)
    local dir, chunk = load_resource_file("modules", module)
    -- Check if there is any contents to load
    if chunk then
        -- Load the chunk
        local fn, err = load(chunk, ('@@%s/%s/%s.lua'):format('txApi', dir, module))

        -- Check for any errors that occur
        if not fn or err then
            return error(('%s: Failed to load module %s: %s'):format('txApi', module, err))
        end

        -- Execute the chunk and add it to the module table
        local result = fn()
        self[module] = result or function() end
        return self[module]
    end
end