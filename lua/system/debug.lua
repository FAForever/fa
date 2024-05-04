---@meta

-- upvalue globals for performance
local type = type

--- Determines the size in bytes of the given element
---@param element any
---@param ignore? table<string, boolean>     # List of key names to ignore of all (referenced) tables
---@return number
debug.allocatedrsize = function(element, ignore)
    ignore = ignore or { }

    -- has no allocated bytes
    if element == nil then
        return 0
    end

    -- applies to tables and strings, to prevent counting them multiple times
    local seen = {}

    -- prepare stack to prevent recursion
    local allocatedSize = 0
    local stack = { element }
    local head = 2

    while head > 1 do

        head = head - 1
        local value = stack[head]
        stack[head] = nil

        local size = debug.allocatedsize(value)

        -- size of usual value
        if size == 0 then
            allocatedSize = allocatedSize + 8

            -- size of string
        elseif type(value) ~= 'table' then
            if not seen[value] then
                seen[value] = true
                allocatedSize = allocatedSize + size
            end

            -- size of table
        else
            if not seen[value] then
                allocatedSize = allocatedSize + size
                seen[value] = true
                for k, v in value do
                    if not ignore[k] then
                        stack[head] = v
                        head = head + 1
                    end
                end
            end
        end
    end

    return allocatedSize
end
