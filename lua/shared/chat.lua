
---@param message UIMessage
---@return boolean
---@return string?
ValidateMessage = function(message)
    if not message.From then
        return false, "Malformed message: missing field 'From'"
    end

    if not message.To then
        return false, "Malformed message: missing field 'To'"
    end

    if not message.Text then
        return false, "Malformed message: missing field 'To'"
    end

    return true
end