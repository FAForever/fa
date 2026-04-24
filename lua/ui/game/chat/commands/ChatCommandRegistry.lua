
local Types = import("/lua/ui/game/chat/commands/ChatCommandTypes.lua")

-------------------------------------------------------------------------------
-- Registry + parser + dispatcher for chat slash-commands.
--
-- See design.md for the full shape. The short version:
--   Register(cmd)  adds a UIChatCommand to the registry
--   Dispatch(text) parses and runs a "/…" line, returning (handled, errorText)

---@class UIChatCommandParam
---@field Name     string
---@field Type     UIChatCommandParamType
---@field Optional boolean?

---@class UIChatCommandContext
---@field Model      UIChatModel
---@field Controller table
---@field SourceText string

---@class UIChatCommand
---@field Name        string
---@field Aliases?    string[]
---@field Description string
---@field Params?     UIChatCommandParam[]
---@field ShouldRegister? fun(): boolean                                      # optional gate evaluated at `Register` time; false drops the command from the registry (and the hint / `/help` listing) for this session
---@field Accept?     fun(args: table, ctx: UIChatCommandContext): boolean, string?
---@field Execute     fun(args: table, ctx: UIChatCommandContext)

---@type table<string, UIChatCommand>
local Commands = {}

---@type table<string, string>
local Aliases = {}

-------------------------------------------------------------------------------
-- Registration

--- Removes a command and its aliases.
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

--- Registers a command. Overwrites any previous registration with the same
--- canonical name; aliases from the previous registration are cleared first.
---
--- A command can opt out of registration entirely by returning `false` from
--- its optional `ShouldRegister` hook — used for session-conditional commands
--- (observer-only, replay-only, single-player-only, etc.). We still call
--- `Unregister` first so a reload that newly disqualifies a command can't
--- leave its previous entry in the registry.
---@param cmd UIChatCommand
function Register(cmd)
    assert(cmd and cmd.Name, "Chat command requires a name.")
    assert(cmd.Execute, "Chat command requires an execute function.")

    -- some commands are game state specific
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

--- Defensive wrapper around `Register`: takes a module path, loads it, and
--- registers its `Command` export — all inside pcalls so one broken file
--- can't take down the entire registration pass (and with it the chat
--- system + anything that depends on `ChatController.Init`).
---
--- Every failure — missing file, import error, missing or malformed
--- `Command` export, Register throwing — is logged and swallowed.
---@param path string
function RegisterFromPath(path)
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

--- Returns every registered command whose canonical name or any alias begins
--- with the given prefix (case-insensitive). Each command appears at most
--- once even if multiple of its aliases match. Results are sorted by name.
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
        -- Accept is user code — a crash here is a bug, not a rejection. Treat
        -- it as a soft failure so the chat send path doesn't propagate the
        -- throw up through the edit box's event handler. The full stack goes
        -- to the log; chat only gets the "check the log" hint.
        local pcallOk, ok, reason = pcall(cmd.Accept, args, ctx)
        if not pcallOk then
            WARN(string.format("/%s: Accept threw (%s).", cmd.Name, tostring(ok)))
            return false, string.format(
                "/%s: command errored while validating — see the log for details.",
                cmd.Name)
        end
        if not ok then
            return false, reason or string.format("/%s: command rejected.", cmd.Name)
        end
    end

    -- Same pcall treatment for Execute. Side effects that ran before the
    -- throw aren't rolled back — this just keeps the chat input usable.
    local executeOk, err = pcall(cmd.Execute, args, ctx)
    if not executeOk then
        WARN(string.format("/%s: Execute threw (%s).", cmd.Name, tostring(err)))
        return false, string.format(
            "/%s: command errored while running — see the log for details.",
            cmd.Name)
    end
    return true, nil
end
