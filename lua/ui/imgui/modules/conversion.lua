
--- Retrieves the label from the identifier. E.g., everything after the first # is removed.
-- @param identifier The identifier to turn into a label.
function ToLabel(identifier)
    return string.gsub(identifier, "(#.*)", "")
end

--- Formats a float.
-- @param f The float to format
function FormatFloat(f)
    return string.format("%01g", f)
end

--- Formats a vector.
-- @param v The vector to format.
function FormatVector(v)
    local x = FormatFloat(v.x)
    local y = FormatFloat(v.y)
    local z = FormatFloat(v.z)

    return "(" .. x .. ", " .. y .. ", " .. z .. ")"
end

--- Formats a vector.
-- @param v The vector to format.
function FormatBoolean(v)
    if v then 
        return "true"
    else
        return "false"
    end
end