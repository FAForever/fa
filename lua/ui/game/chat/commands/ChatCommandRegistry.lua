
local Types = import("/lua/ui/game/chat/commands/ChatCommandTypes.lua")

-------------------------------------------------------------------------------
-- Registry + parser + dispatcher for chat slash-commands.
--
-- See design.md for the full shape. The short version:
--   Register(cmd)  adds a UIChatCommand to the registry
--   Dispatch(text) parses and runs a "/…" line, returning (handled, errorText)

---@class UIChatCommandParam
---@field name     string
---@field type     UIChatCommandParamType
---@field optional boolean?

---@class UIChatCommandContext
---@field model      UIChatModel
---@field controller table
---@field sourceText string

---@class UIChatCommand
---@field name        string
---@field aliases?    string[]
---@field description string
---@field params?     UIChatCommandParam[]
---@field accept?     fun(args: table, ctx: UIChatCommandContext): boolean, string?
---@field execute     fun(args: table, ctx: UIChatCommandContext)

---@type table<string, UIChatCommand>
local Commands = {}

---@type table<string, string>
local Aliases = {}

local BuiltinsLoaded = false

-------------------------------------------------------------------------------
-- Registration

--- Registers a command. Overwrites any previous registration with the same
--- canonical name; aliases from the previous registration are cleared first.
---@param cmd UIChatCommand
function Register(cmd)
    assert(cmd and cmd.name, "Chat command requires a name.")
    assert(cmd.execute, "Chat command requires an execute function.")

    local key = string.lower(cmd.name)

    local previous = Commands[key]
    if previous and previous.aliases then
        for _, alias in ipairs(previous.aliases) do
            Aliases[string.lower(alias)] = nil
        end
    end

    Commands[key] = cmd
    if cmd.aliases then
        for _, alias in ipairs(cmd.aliases) do
            Aliases[string.lower(alias)] = key
        end
    end
end

--- Removes a command and its aliases.
---@param name string
function Unregister(name)
    local key = string.lower(name)
    local cmd = Commands[key]
    if not cmd then return end
    if cmd.aliases then
        for _, alias in ipairs(cmd.aliases) do
            Aliases[string.lower(alias)] = nil
        end
    end
    Commands[key] = nil
end

--- Returns a flat list of every registered command (canonical entries only).
---@return UIChatCommand[]
function GetAll()
    local result = {}
    for _, cmd in Commands do
        table.insert(result, cmd)
    end
    return result
end

--- Looks up a command by name or alias. Case-insensitive.
---@param name string
---@return UIChatCommand?
function Lookup(name)
    local key = string.lower(name)
    local cmd = Commands[key]
    if cmd then return cmd end
    local canonical = Aliases[key]
    if canonical then return Commands[canonical] end
    return nil
end

-------------------------------------------------------------------------------
-- Parsing

--- Splits the body of a slash-command into (name, remainingTokens).
--- "whisper Jip hello" → "whisper", {"Jip", "hello"}
---@param body string
---@return string?, string[]
local function Tokenize(body)
    local tokens = {}
    for word in string.gfind(body, "%S+") do
        table.insert(tokens, word)
    end
    if table.getn(tokens) == 0 then
        return nil, {}
    end
    local name = table.remove(tokens, 1)
    return name, tokens
end

--- Walks a command's declared parameters, pulling tokens and invoking the
--- matching resolver. Returns the populated args table or a user-facing error.
---@param cmd UIChatCommand
---@param tokens string[]
---@return table?, string?
local function ParseArgs(cmd, tokens)
    local args = { _raw = tokens }
    if not cmd.params then return args, nil end

    local idx = 1
    for _, param in ipairs(cmd.params) do
        if param.type == 'rest' then
            local remaining = {}
            while tokens[idx] do
                table.insert(remaining, tokens[idx])
                idx = idx + 1
            end
            if table.getn(remaining) == 0 then
                if not param.optional then
                    return nil, string.format("/%s: missing argument <%s>.", cmd.name, param.name)
                end
            else
                args[param.name] = table.concat(remaining, ' ')
            end
        else
            local token = tokens[idx]
            if not token then
                if param.optional then
                    idx = idx + 1
                else
                    return nil, string.format("/%s: missing argument <%s>.", cmd.name, param.name)
                end
            else
                local resolver = Types.Resolvers[param.type]
                if not resolver then
                    return nil, string.format("/%s: unknown parameter type '%s'.", cmd.name, tostring(param.type))
                end
                local ok, value = resolver(token)
                if not ok then
                    return nil, string.format("/%s: %s", cmd.name, value or ("invalid <" .. param.name .. ">."))
                end
                args[param.name] = value
                idx = idx + 1
            end
        end
    end

    return args, nil
end

-------------------------------------------------------------------------------
-- Dispatch

--- Parses a chat line that starts with '/' and invokes the matching command.
--- Return values:
---   (true,  nil)     → command ran (or was accept-rejected and already reported)
---   (false, errText) → slash-prefixed but failed; caller should surface errText
---   (false, nil)     → lone '/' or whitespace; caller may treat as normal text
---@param text string
---@return boolean handled
---@return string? errorText
function Dispatch(text)
    if not text or string.sub(text, 1, 1) ~= '/' then
        return false, nil
    end

    if not BuiltinsLoaded then
        BuiltinsLoaded = true
        import("/lua/ui/game/chat/commands/BuiltinCommands.lua")
    end

    local body = string.sub(text, 2)
    local name, tokens = Tokenize(body)
    if not name then
        return false, nil
    end

    local cmd = Lookup(name)
    if not cmd then
        return false, string.format("Invalid command: /%s. Type /help for a list.", name)
    end

    local args, parseErr = ParseArgs(cmd, tokens)
    if parseErr then
        return false, parseErr
    end

    local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
    local ChatController = import("/lua/ui/game/chat/ChatController.lua")
    local ctx = {
        model      = ChatModel.GetSingleton(),
        controller = ChatController,
        sourceText = text,
    }

    if cmd.accept then
        local ok, reason = cmd.accept(args, ctx)
        if not ok then
            return false, reason or string.format("/%s: command rejected.", cmd.name)
        end
    end

    cmd.execute(args, ctx)
    return true, nil
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
