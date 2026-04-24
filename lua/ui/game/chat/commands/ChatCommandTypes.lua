
-------------------------------------------------------------------------------
-- Parameter-type resolvers for chat commands. Each resolver takes a raw token
-- (string) and returns (ok, value_or_error):
--   true,  value       → successfully coerced/validated
--   false, errorString → rejected; errorString is user-facing
--
-- Resolvers are intentionally pure: they read from the session (armies table)
-- but never write state. Adding a new type means adding one function to the
-- `Resolvers` table.

--- Looks up an army by nickname or by numeric army ID. Civilian armies are
--- excluded to match the behaviour of the recipient picker.
---
--- A leading `@` is stripped before matching so `@Jip` and `Jip` are
--- equivalent — this lets the chat-edit `@nick` autocomplete (see
--- ChatCompletion) feed straight into commands like `/whisper @Jip` without
--- the user having to delete the `@` first.
---@param token string
---@return boolean ok
---@return number | string armyIDOrError
local function ResolveArmy(token)
    local armies = GetArmiesTable()
    if not armies or not armies.armiesTable then
        return false, "no army table available."
    end

    -- do not include '@' of '@nick' when matching against army nicknames or IDs; this allows the user to quickly find usernames
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

---@alias UIChatCommandParamType 'Recipient' | 'Player' | 'Int' | 'String' | 'Rest'

---@type table<UIChatCommandParamType, fun(token: string): boolean, any>
Resolvers = {}

--- Accepts "all", "allies"/"team", a nickname, or an army ID.
--- Resolves to a `UIChatRecipient` (the same type the model stores).
Resolvers.Recipient = function(token)
    local lower = string.lower(token)
    if lower == 'all' then
        return true, 'all'
    elseif lower == 'allies' or lower == 'team' then
        return true, 'allies'
    end
    return ResolveArmy(token)
end

--- Accepts a nickname or army ID. Rejects "all"/"allies".
--- Resolves to a numeric army ID.
Resolvers.Player = function(token)
    return ResolveArmy(token)
end

--- Integer literal.
Resolvers.Int = function(token)
    local n = tonumber(token)
    if not n or math.floor(n) ~= n then
        return false, string.format("'%s' is not an integer.", token)
    end
    return true, n
end

--- Single whitespace-delimited token.
Resolvers.String = function(token)
    return true, token
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
