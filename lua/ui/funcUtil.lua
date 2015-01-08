-- Get a number of entries in a table
function tableLength(Table)
    local count = 0
    for _ in pairs(Table) do count = count + 1 end
    return count
end

-- Find the key for the given value in a table.
-- Nil keys are not supported.
function indexOf(table, needle)
    for k, v in table do
        if v == needle then
            return k
        end
    end
    return nil
end
