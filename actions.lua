-- actions.lua
_actions = {}
_actions.__index = _actions

function _actions.new()
    local self = setmetatable({}, _actions)

    function self:search(options, callback)
        options = options or {}

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
                -- Probably better to move this up but whatever
                if not callback then
                    print("^1No callback provided for actions search!^7")
                    return
                end
                callback(data)
            end
        )
    end

    function self:stats(callback)
        API:request(
            "GET",
            "/history/stats",
            {},
            function(data)
                if not callback then
                    print("^1No callback provided for actions stats!^7")
                    return
                end
                callback(data)
            end
        )
    end

    return self
end