
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

--- Sends a message to the current recipient.
--- Stubbed — the network layer will be wired up in a follow-up step.
---@param text string
function Send(text)
    WARN("ChatController.Send not yet implemented: " .. tostring(text))
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
