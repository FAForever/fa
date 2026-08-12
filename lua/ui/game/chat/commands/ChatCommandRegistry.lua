local Types = import("/lua/ui/game/chat/commands/ChatCommandTypes.lua")

-------------------------------------------------------------------------------
-- Registry + parser + dispatcher for chat slash-commands. See design.md.

--- One declared parameter slot in a command's signature. Resolver is picked by `Type`.
---@class UIChatCommandParam
---@field Name     string
---@field Type     UIChatCommandParamType
---@field Optional boolean?

--- Per-invocation context handed to `Accept` and `Execute`. Holds model + controller + raw input.
---@class UIChatCommandContext
---@field Model      UIChatModel
---@field Controller table
---@field SourceText string

--- A registered slash-command: name, optional aliases/params/gates, and the dispatcher's hooks.
---@class UIChatCommand
---@field Name        string
---@field Aliases?    string[]
---@field Description string
---@field Params?     UIChatCommandParam[]
---@field ShouldRegister? fun(): boolean                                      # optional gate evaluated at `Register` time; false drops the command from the registry (and the hint / `/help` listing) for this session
---@field Accept?     fun(args: table, ctx: UIChatCommandContext): boolean, string?
---@field Execute     fun(args: table, ctx: UIChatCommandContext)

--- Registered commands by lower-cased canonical name.
---@type table<string, UIChatCommand>
local Commands = {}

--- Lower-cased alias to canonical command name. Merged into lookup so `/w` resolves to `/whisper`.
---@type table<string, string>
local Aliases = {}

-------------------------------------------------------------------------------
-- Registration

--- Removes a command and its aliases from the registry.
---@param name string
function Unregister(name)
    local key = string.lower(name)
    local cmd = Commands[key]
    if not cmd then return end
    if cmd.Aliases then
        for _, alias in ipairs(cmd.Aliases) do
            Aliases[string.lower(alias)] = nil
        end
    end
    Commands[key] = nil
end

--- Registers a command in the registry.
---@param cmd UIChatCommand
function Register(cmd)
    -- Overwrites any previous registration with the same canonical name.
    -- Aliases from the previous registration are cleared first. A
    -- `ShouldRegister` returning false drops the command for this
    -- session.
    assert(cmd and cmd.Name, "Chat command requires a name.")
    assert(cmd.Execute, "Chat command requires an execute function.")

    if cmd.ShouldRegister and not cmd.ShouldRegister() then
        return
    end

    local key = string.lower(cmd.Name)

    local previous = Commands[key]
    if previous and previous.Aliases then
        for _, alias in ipairs(previous.Aliases) do
            Aliases[string.lower(alias)] = nil
        end
    end

    Commands[key] = cmd
    if cmd.Aliases then
        for _, alias in ipairs(cmd.Aliases) do
            Aliases[string.lower(alias)] = key
        end
    end
end

--- Loads a command file at `path` and registers its `Command` export.
--- Every failure is logged and swallowed.
---@param path string
function RegisterFromPath(path)
    -- Wrapped in pcalls so one broken file can't take down the
    -- registration pass.
    if not DiskGetFileInfo(path) then
        WARN(string.format("Chat command skipped: file not found '%s'.", tostring(path)))
        return
    end

    local ok, module = pcall(import, path)
    if not ok then
        WARN(string.format("Chat command skipped: failed to import '%s' (%s).",
            tostring(path), tostring(module)))
        return
    end

    local cmd = module and module.Command
    if type(cmd) ~= 'table' then
        WARN(string.format("Chat command skipped: '%s' does not export a `Command` table.",
            tostring(path)))
        return
    end

    if type(cmd.Name) ~= 'string' or cmd.Name == '' then
        WARN(string.format("Chat command skipped: '%s' has an invalid `Command.Name`.",
            tostring(path)))
        return
    end

    if type(cmd.Execute) ~= 'function' then
        WARN(string.format("Chat command skipped: '%s' has no `Command.Execute` function.",
            tostring(path)))
        return
    end

    local registered, err = pcall(Register, cmd)
    if not registered then
        WARN(string.format("Chat command skipped: Register('%s') threw (%s).",
            tostring(path), tostring(err)))
    end
end

--- Canonical entries only.
---@return UIChatCommand[]
function GetAll()
    local result = {}
    for _, cmd in Commands do
        table.insert(result, cmd)
    end
    return result
end

--- Returns the command matching `name` (canonical or alias), case-insensitive.
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

--- Commands whose canonical name or any alias begins with `prefix`
--- (case-insensitive, deduped, sorted by name).
---@param prefix string
---@return UIChatCommand[]
function FindMatching(prefix)
    local lower = string.lower(prefix or '')
    local len = string.len(lower)
    local seen = {}
    local result = {}

    for name, cmd in Commands do
        if string.sub(name, 1, len) == lower then
            seen[cmd] = true
            table.insert(result, cmd)
        end
    end

    for alias, canonical in Aliases do
        if string.sub(alias, 1, len) == lower then
            local cmd = Commands[canonical]
            if cmd and not seen[cmd] then
                seen[cmd] = true
                table.insert(result, cmd)
            end
        end
    end

    table.sort(result, function(a, b) return a.Name < b.Name end)
    return result
end

-------------------------------------------------------------------------------
-- Parsing

--- "whisper Jip hello" -> "whisper", {"Jip", "hello"}
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

---@param cmd UIChatCommand
---@param tokens string[]
---@return table?, string?
local function ParseArgs(cmd, tokens)
    ---@type table<string, any>
    local args = { _Raw = tokens }
    if not cmd.Params then return args, nil end

    local idx = 1
    for _, param in ipairs(cmd.Params) do
        if param.Type == 'Rest' then
            local remaining = {}
            while tokens[idx] do
                table.insert(remaining, tokens[idx])
                idx = idx + 1
            end
            if table.getn(remaining) == 0 then
                if not param.Optional then
                    return nil, string.format("/%s: missing argument <%s>.", cmd.Name, param.Name)
                end
            else
                args[param.Name] = table.concat(remaining, ' ')
            end
        else
            local token = tokens[idx]
            if not token then
                if param.Optional then
                    idx = idx + 1
                else
                    return nil, string.format("/%s: missing argument <%s>.", cmd.Name, param.Name)
                end
            else
                local resolver = Types.Resolvers[param.Type]
                if not resolver then
                    return nil, string.format("/%s: unknown parameter type '%s'.", cmd.Name, tostring(param.Type))
                end
                local ok, value = resolver(token)
                if not ok then
                    return nil, string.format("/%s: %s", cmd.Name, value or ("invalid <" .. param.Name .. ">."))
                end
                args[param.Name] = value
                idx = idx + 1
            end
        end
    end

    return args, nil
end

-------------------------------------------------------------------------------
-- Dispatch

--- Fall-through to legacy `RunChatCommand` for pre-MVC commands
--- registered via Notify's `AddChatCommand` (`/enablenotify`, etc.).
--- New commands should live under `commands/builtin/`.
---@param name string         # the slash-stripped command word, original case
---@param tokens string[]     # remaining tokens (after the command word)
---@return boolean handled
local function DispatchLegacy(name, tokens)
    -- Args shape matches the legacy dispatcher: lowercased name in slot
    -- 1, lowercased remaining tokens after. Wrapped in pcall for the
    -- same reason as Accept/Execute. Third-party commands throwing must
    -- not leak up through the chat send path.
    local args = { string.lower(name) }
    for _, tok in ipairs(tokens) do
        table.insert(args, string.lower(tok))
    end
    local pcallOk, handled = pcall(
        import("/lua/ui/notify/commands.lua").RunChatCommand,
        args)
    if not pcallOk then
        WARN(string.format(
            "/%s: legacy command fallback errored (%s).",
            name, tostring(handled)))
        return false
    end
    return handled and true or false
end

--- Parses a chat line that starts with '/' and invokes the matching command.
--- Return values:
---   (true,  nil)     -> command ran (or was accept-rejected and already reported)
---   (false, errText) -> slash-prefixed but failed. Caller should surface errText.
---   (false, nil)     -> lone '/' or whitespace. Caller may treat as normal text.
---@param text string
---@return boolean handled
---@return string? errorText
function Dispatch(text)
    if not text or string.sub(text, 1, 1) ~= '/' then
        return false, nil
    end

    local body = string.sub(text, 2)
    local name, tokens = Tokenize(body)
    if not name then
        return false, nil
    end

    local cmd = Lookup(name)
    if not cmd then
        if DispatchLegacy(name, tokens) then
            return true, nil
        end
        return false, string.format("Invalid command: /%s. Type /help for a list.", name)
    end

    local args, parseErr = ParseArgs(cmd, tokens)
    if not args then
        return false, parseErr
    end

    local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
    local ChatController = import("/lua/ui/game/chat/ChatController.lua")
    local ctx = {
        Model      = ChatModel.GetSingleton(),
        Controller = ChatController,
        SourceText = text,
    }

    if cmd.Accept then
        -- Accept is user code. Treat a throw as a soft failure so it
        -- doesn't propagate up through the edit-box event handler.
        local pcallOk, ok, reason = pcall(cmd.Accept, args, ctx)
        if not pcallOk then
            WARN(string.format("/%s: Accept threw (%s).", cmd.Name, tostring(ok)))
            return false, string.format(
                "/%s: command errored while validating. See the log for details.",
                cmd.Name)
        end
        if not ok then
            return false, reason or string.format("/%s: command rejected.", cmd.Name)
        end
    end

    -- Same pcall as Accept. Side effects before the throw aren't rolled
    -- back. This just keeps the chat input usable.
    local executeOk, err = pcall(cmd.Execute, args, ctx)
    if not executeOk then
        WARN(string.format("/%s: Execute threw (%s).", cmd.Name, tostring(err)))
        return false, string.format(
            "/%s: command errored while running. See the log for details.",
            cmd.Name)
    end
    return true, nil
end
