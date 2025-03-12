-- actions.lua
_actions = {}
_actions.__index = _actions

function _actions.new()
    local self = setmetatable({}, _actions)

    function self:search(options, callback)
        options = options or {}

        -- Make sure arguments are provided
        if not callback then
            print("^1No callback provided for actions search!^7")
            return
        end
        
        -- Create the query params
        local queryParams = {
            "sortingKey=" .. (options.sortingKey or "timestamp"),
            "sortingDesc=" .. (options.sortingDesc or "true"),

            -- TODO: Add other sorting/search/filter methods
        }

        -- Convert the query params to a single string
        local queryString = table.concat(queryParams, "&")

        API:request(
            "GET",
            "/history/search?" .. queryString,
            {},
            function(data)
                callback(data)
            end
        )
    end

    function self:stats(callback)
        -- Make sure arguments are provided
        if not callback then
            print("^1No callback provided for actions stats!^7")
            return
        end

        API:request(
            "GET",
            "/history/stats",
            {},
            function(data)
                callback(data)
            end
        )
    end

    function self:revoke(actionId, callback)
        -- Make sure arguments are provided
        if not actionId then
            print("^1No actionId provided for action revoke!^7")
            return
        end

        if not callback then
            print("^1No callback provided for action revoke!^7")
            return
        end

        -- Request txAdmin to revoke the action
        API:request(
            "POST",
            "/history/revokeAction",
            { actionId = actionId },
            function(data)
                callback(data)
            end
        )
    end

    return self
end