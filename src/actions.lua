-- actions.lua
_actions = {}
_actions.__index = _actions

function _actions.new()
    local self = setmetatable({}, _actions)

    function self:search(options)
        options = options or {}
        
        -- Create the query params
        local queryParams = {
            "sortingKey=" .. (options.sortingKey or "timestamp"),
            "sortingDesc=" .. (options.sortingDesc or "true"),

            -- TODO: Add other sorting/search/filter methods
        }

        -- Ability to search by action id
        if options.actionId then
            table.insert(queryParams, "searchType=actionId")
            table.insert(queryParams, "searchValue=" .. options.actionId) -- action id, example: W2V7-D8Y6
        end

        -- Ability to search by ban/warn reason
        if options.reason then
            table.insert(queryParams, "searchType=reason")
            table.insert(queryParams, "searchValue=" .. options.reason) -- any reason
        end

        -- Ability to search by player identifier
        if options.identifier then
            table.insert(queryParams, "searchType=identifiers")
            table.insert(queryParams, "searchValue=" .. options.identifier) -- any identifier
        end

        -- Filter by ban/warn
        if options.filter then
            table.insert(queryParams, "filterbyType=" .. options.filter) -- ban/warn
        end

        -- Convert the query params to a single string
        local queryString = table.concat(queryParams, "&")

        -- Let txAdmin search for the actions and return the response
        return API:request("GET", "/history/search?" .. queryString, {}).data
    end

    function self:stats()
        -- Request txAdmin to return the stats
        return API:request("GET", "/history/stats", {}).data
    end

    function self:revoke(actionId)
        -- Make sure arguments are provided
        if not actionId then
            print("^1No actionId provided for action revoke!^7")
            return
        end

        -- Request txAdmin to revoke the action
        return API:request("POST", "/history/revokeAction", { actionId = actionId }).data
    end

    return self
end