--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The lobby chat **send pipeline** — the edit box's entry point. It decides command-vs-chat and writes
-- the chat model (CustomLobbyChatModel); it never touches the wire itself. Mirrors the in-game
-- ChatController.Send split (/lua/ui/game/chat/ChatController.lua):
--
--   Send(text)
--     ├─ '/' prefix? → a chat command — handled locally, NOTHING goes on the wire
--     │                 (the command registry lands in slice 2; for now a stub system line)
--     └─ plain text → append an optimistic `Pending` echo, then hand to the controller's RequestChat
--
-- The optimistic echo is shown immediately; when the host's authoritative `ChatMessage` echo returns
-- (carrying the same id), CustomLobbyChatModel.Receive reconciles it to `Confirmed`. The host's own
-- send reconciles in the same frame (the broadcast doesn't loop back, so ProcessRequestChat displays
-- it locally) — same mechanism, see CustomLobbyController.
--
-- The *wire* half (RequestChat / ProcessRequestChat / ProcessChatMessage) lives in CustomLobbyController
-- for consistency with every other Request*/Process* intent and the host-authority rule.

local CustomLobbyChatModel = import("/lua/ui/lobby/customlobby/social/customlobbychatmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")

--- Appends a local-only system line (command feedback). Local to this peer; nothing is sent.
---@param text string
function AppendLocalSystem(text)
    CustomLobbyChatModel.Append(CustomLobbyChatModel.GetSingleton(), {
        Id = false,
        SenderId = false,
        SenderName = "System",
        Text = text,
        Status = 'Confirmed',
        Kind = 'system',
        Time = GetSystemTimeSeconds(),
    })
end

--- Sends a chat line. A slash line is a command (handled locally, never broadcast); anything else is
--- echoed optimistically and routed to the host through the controller.
---@param text string
function Send(text)
    if not text or text == '' then
        return
    end

    -- a slash line is a chat command, never broadcast. The command registry arrives in slice 2; for now
    -- just surface a local notice so the split is visible and nothing goes on the wire.
    if string.sub(text, 1, 1) == '/' then
        AppendLocalSystem("Chat commands are coming soon.")
        return
    end

    -- drop an all-whitespace body
    if not string.find(text, "%S") then
        return
    end

    local localModel = CustomLobbyLocalModel.GetSingleton()
    local peerId = localModel.LocalPeerId()
    local id = CustomLobbyChatModel.NextId(peerId)

    -- shown immediately as Pending; the host's echo reconciles it to Confirmed (see the model's Receive)
    CustomLobbyChatModel.Append(CustomLobbyChatModel.GetSingleton(), {
        Id = id,
        SenderId = peerId,
        SenderName = CustomLobbyController.FindNameForOwner(peerId),
        Text = text,
        Status = 'Pending',
        Kind = 'chat',
        Time = GetSystemTimeSeconds(),
    })

    CustomLobbyController.RequestChat(text, id)
end

--- Sets the current send target. Reserved for whisper (slice 3); 'all' for now.
---@param recipient 'all'
function SetRecipient(recipient)
    CustomLobbyChatModel.GetSingleton().Recipient:Set(recipient)
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module after a couple of frames (no state of its own).
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
