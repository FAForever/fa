
-------------------------------------------------------------------------------
-- Parameter-type resolvers for chat commands. Each resolver takes a raw
-- token and returns (ok, value_or_error). Resolvers are pure (read from
-- the session but don't write).

--- Looks up an army by nickname or numeric ID. Civilian armies excluded
--- to match the recipient picker. A leading `@` is stripped so `@Jip`
--- works the same as `Jip`, mirroring the `@nick` autocomplete.
---@param token string
---@return boolean ok
---@return number | string armyIDOrError
local function ResolveArmy(token)
    local armies = GetArmiesTable()
    if not armies or not armies.armiesTable then
        return false, "no army table available."
    end

    if string.sub(token, 1, 1) == '@' then
        token = string.sub(token, 2)
    end

    local asNum = tonumber(token)
    if asNum then
        local army = armies.armiesTable[asNum]
        if army and not army.civilian then
            return true, asNum
        end
        return false, string.format("no army with ID %s.", tostring(asNum))
    end

    for armyID, army in armies.armiesTable do
        if army.nickname == token and not army.civilian then
            return true, armyID
        end
    end
    return false, string.format("no player named '%s'.", token)
end

--- Tag identifying which `Resolvers` entry parses a parameter token. One tag per supported type.
---@alias UIChatCommandParamType 'Recipient' | 'Player' | 'Int' | 'String' | 'Rest'

--- Param-type to resolver table. Each resolver returns `(true, value)` on success or `(false, errMsg)`.
---@type table<UIChatCommandParamType, fun(token: string): boolean, any>
Resolvers = {}

--- Resolves "all", "allies"/"team", nickname, or army ID into a `UIChatRecipient`.
Resolvers.Recipient = function(token)
    local lower = string.lower(token)
    if lower == 'all' then
        return true, 'all'
    elseif lower == 'allies' or lower == 'team' then
        return true, 'allies'
    end
    return ResolveArmy(token)
end

--- Resolves a nickname or army ID into a numeric army ID. Rejects "all"/"allies".
Resolvers.Player = function(token)
    return ResolveArmy(token)
end

--- Parses a token as an integer. Rejects fractional or non-numeric input.
Resolvers.Int = function(token)
    local n = tonumber(token)
    if not n or math.floor(n) ~= n then
        return false, string.format("'%s' is not an integer.", token)
    end
    return true, n
end

--- Passthrough: accepts any token as a string.
Resolvers.String = function(token)
    return true, token
end
