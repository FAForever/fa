
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")

-------------------------------------------------------------------------------
-- Window visibility

--- Shows the chat window.
function OpenWindow()
    ChatModel.GetSingleton().WindowVisible:Set(true)
end

--- Hides the chat window.
function CloseWindow()
    ChatModel.GetSingleton().WindowVisible:Set(false)
end

--- Toggles the chat window open or closed.
function ToggleWindow()
    local lv = ChatModel.GetSingleton().WindowVisible
    lv:Set(not lv())
end

-------------------------------------------------------------------------------
-- Recipient

--- Sets the current send target.
---@param target UIChatRecipient
function SetRecipient(target)
    ChatModel.GetSingleton().Recipient:Set(target)
end

-------------------------------------------------------------------------------
-- Messages

--- Appends an entry to the history log. Called by the receive path as well as
--- by locally-echoed outgoing messages.
---@param entry UIChatEntry
function AppendEntry(entry)
    local model = ChatModel.GetSingleton()
    local history = table.copy(model.History())
    table.insert(history, entry)
    model.History:Set(history)
end

--- Appends a synthetic, local-only system line to the history. Used by the
--- slash-command dispatcher to surface parse/accept errors in the chat feed
--- without sending anything over the network.
---@param text string
function AppendLocalSystemMessage(text)
    AppendEntry {
        name      = "System:",
        text      = text,
        color     = 'ffff6666',
        armyID    = 0,
        recipient = ChatModel.RecipientAll,
    }
end

-------------------------------------------------------------------------------
-- Slash commands

local BuiltinsRegistered = false

--- Registers every built-in chat command with the registry. Idempotent, so
--- it is safe to call from multiple init paths. External callers that want
--- their own commands registered alongside the built-ins should call this
--- once at startup before the first message is sent.
function RegisterBuiltinCommands()
    if BuiltinsRegistered then return end
    BuiltinsRegistered = true

    local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")
    local Builtins = import("/lua/ui/game/chat/commands/BuiltinCommands.lua")

    Registry.Register(Builtins.All)
    Registry.Register(Builtins.Allies)
    Registry.Register(Builtins.Whisper)
    Registry.Register(Builtins.Help)
end

--- Sends a message to the current recipient.
--- Stubbed — the network layer will be wired up in a follow-up step.
---@param text string
function Send(text)
    if text and string.sub(text, 1, 1) == '/' then
        RegisterBuiltinCommands()

        local Registry = import("/lua/ui/game/chat/commands/ChatCommandRegistry.lua")
        local handled, err = Registry.Dispatch(text)
        if handled then return end
        if err then
            AppendLocalSystemMessage(err)
            return
        end
        -- Lone '/' or whitespace-only body falls through to the normal path.
    end

    WARN("ChatController.Send not yet implemented: " .. tostring(text))
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
