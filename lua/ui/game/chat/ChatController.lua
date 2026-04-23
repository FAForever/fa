
local ChatModel = import("/lua/ui/game/chat/ChatModel.lua")
local ChatConfigModel = import("/lua/ui/game/chat/config/ChatConfigModel.lua")

-------------------------------------------------------------------------------
-- Window visibility

--- Applies the `send_type` default-recipient option when the chat window
--- opens. If the user has already selected a specific player for a private
--- message, their choice is left alone.
local function ApplyDefaultRecipient()
    local model = ChatModel.GetSingleton()
    if type(model.Recipient()) == 'number' then
        return
    end
    local options = ChatConfigModel.GetSingleton().Committed()
    local target = options.send_type and ChatModel.RecipientAllies or ChatModel.RecipientAll
    model.Recipient:Set(target)
end

--- Shows the chat window.
function OpenWindow()
    ApplyDefaultRecipient()
    ChatModel.GetSingleton().WindowVisible:Set(true)
end

--- Hides the chat window.
function CloseWindow()
    ChatModel.GetSingleton().WindowVisible:Set(false)
end

--- Toggles the chat window open or closed.
function ToggleWindow()
    local lv = ChatModel.GetSingleton().WindowVisible
    local willOpen = not lv()
    if willOpen then
        ApplyDefaultRecipient()
    end
    lv:Set(willOpen)
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
        Name      = "System:",
        Text      = text,
        Color     = 'ffff6666',
        ArmyID    = 0,
        Recipient = ChatModel.RecipientAll,
    }
end

-------------------------------------------------------------------------------
-- Slash commands

--- (Re-)registers every built-in chat command with the registry. `Register`
--- overwrites, so calling this repeatedly is safe and cheap — we do so on
--- every slash-entry path so hot-reloading `ChatCommandRegistry.lua` (which
--- resets its internal tables) doesn't leave us with an empty registry.
function RegisterBuiltinCommands()
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

-- Register at load time so the registry is populated before the first hint
-- opens or the first slash command is sent. The function is idempotent, so
-- re-imports and the belt-and-suspenders calls from `Send` / `OpenCommandHint`
-- all converge on the same state.
RegisterBuiltinCommands()

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
