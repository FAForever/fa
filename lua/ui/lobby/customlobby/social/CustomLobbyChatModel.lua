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

-- The lobby **chat feed**: a per-peer, never-synced record of the chat lines this peer has seen. Like
-- CustomLobbyLog it is a reactive `Entries` ring buffer, but it carries chat (not diagnostics) and is
-- *written by the controller* — so, unlike the Log, it is a `ClassSimple : Destroyable` registered in
-- the session trash (CustomLobbySession), freed on `Teardown()` so a session's chat doesn't leak into
-- the persistent front-end state for the whole match.
--
-- Chat is host-authoritative: the host relays every accepted message (CustomLobbyController's
-- `ProcessRequestChat` is the single filter chokepoint), and every peer accumulates what it receives.
-- A line you send is shown to you **immediately** as `Pending`, then reconciled to `Confirmed` when the
-- host's authoritative echo (carrying the same client-stamped `Id`) comes back — see `Receive`. That is
-- why an entry has a mutable `Status` and a stable `Id`.
--
-- This is *not* one of the three lobby models (no launch/session/local game state) and never goes on
-- the wire — it is the chat equivalent of CustomLobbyLog. The wire half (the `RequestChat` /
-- `ChatMessage` messages and their handlers) lives in CustomLobbyController; the edit-box send pipeline
-- lives in CustomLobbyChatController. Both write this model through the helpers below.

local Create = import("/lua/lazyvar.lua").Create
local CustomLobbySession = import("/lua/ui/lobby/customlobby/customlobbysession.lua")

--- Most recent lines kept; older ones drop off the front (matches CustomLobbyLog's cap).
local MaxEntries = 200

--- Monotonic counter behind `NextId`. Module-local so it survives a model teardown (ids only have to
--- be unique within this peer's session; the peer-id prefix keeps them unique across peers).
local SendCounter = 0

--- The baseline for the relative clock (set when the feed is created). Entries store absolute
--- `GetSystemTimeSeconds()`; subtract this to render a `mm:ss` stamp like the traffic log.
---@type number | nil
local StartTime = nil

---@alias UICustomLobbyChatStatus
---| 'Pending'   # an outgoing line shown optimistically, awaiting the host's echo
---| 'Confirmed' # the host broadcast it (authoritative)
---| 'Rejected'  # the host dropped/filtered it (shown greyed, for the sender only)

---@alias UICustomLobbyChatKind
---| 'chat'   # a player message
---| 'system' # a local-only notice (command feedback, later: join/leave)

---@class UICustomLobbyChatEntry
---@field Id         string | false              # client-stamped id (peerId:counter); false for local system lines
---@field SenderId   UILobbyPeerId | false       # the sender's peer id; false for system lines
---@field SenderName string                       # display name (resolved authoritatively by the host)
---@field Text       string
---@field Status     UICustomLobbyChatStatus
---@field Kind       UICustomLobbyChatKind
---@field Time       number                        # GetSystemTimeSeconds() when this entry was added

-------------------------------------------------------------------------------
--#region Reactive model

-- The singleton, forward-declared above the class so `Destroy` captures it as an upvalue. Assigned in
-- `SetupSingleton`, cleared in `Destroy`.
---@type UICustomLobbyChatModel | nil
local Instance = nil

--- Reactive per-peer chat feed — a `ClassSimple` implementing `Destroyable`, registered in the session
--- trash so one `CustomLobbySession.Teardown()` frees it. Written by the controller (the wire half) and
--- the chat controller (the send pipeline) through the free-function helpers below; views only read it.
---@class UICustomLobbyChatModel : Destroyable
---@field Trash     TrashBag                                # owns the LazyVars (freed on Destroy)
---@field Entries   LazyVar<UICustomLobbyChatEntry[]>       # the feed, capped to MaxEntries
---@field Recipient LazyVar<string>                         # current send target ('all') — reserved for whisper (slice 3)
---@field Destroyed boolean
local ChatModel = ClassSimple {

    ---@param self UICustomLobbyChatModel
    __init = function(self)
        self.Trash = TrashBag()
        self.Entries = self.Trash:Add(Create({}))
        self.Recipient = self.Trash:Add(Create('all'))
        self.Destroyed = false
    end,

    --- `Destroyable`: frees the LazyVars and clears the module singleton, so the next access rebuilds a
    --- fresh feed and re-registers it in the next session's trash. Idempotent. Called by the session
    --- trash on `Teardown()`.
    ---@param self UICustomLobbyChatModel
    Destroy = function(self)
        if self.Destroyed then
            return
        end
        self.Destroyed = true
        self.Trash:Destroy()
        if Instance == self then
            Instance = nil
        end
    end,
}

--- Allocates a fresh chat-model singleton and registers it in the session trash.
---@return UICustomLobbyChatModel
function SetupSingleton()
    Instance = ChatModel()
    StartTime = GetSystemTimeSeconds()
    CustomLobbySession.GetTrash():Add(Instance)
    return Instance
end

--- The relative-clock baseline (when this feed started). Subtract from an entry's `Time` to render a
--- `mm:ss` stamp, the same way the traffic log does.
---@return number
function GetStartTime()
    return StartTime or GetSystemTimeSeconds()
end

--- Returns the chat-model singleton, creating (and registering) it on first access — including after a
--- teardown, so it is reusable across lobby sessions.
---@return UICustomLobbyChatModel
function GetSingleton()
    if not Instance then
        SetupSingleton()
    end
    return Instance --[[@as UICustomLobbyChatModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Write helpers
--
-- Entries is a LazyVar value, so a write builds a NEW array and `:Set`s it (mutating in place never
-- marks dependents dirty — see /lua/ui/CLAUDE.md § 2).

--- A fresh, per-session-unique id for an outgoing line. The peer-id prefix keeps it unique across peers
--- so the host's echo reconciles only the sender's own optimistic entry.
---@param peerId UILobbyPeerId
---@return string
function NextId(peerId)
    SendCounter = SendCounter + 1
    return tostring(peerId) .. ":" .. tostring(SendCounter)
end

--- Appends one entry (copy-then-Set), trimming the oldest beyond the cap. Used for an optimistic
--- outgoing line (`Pending`) and for local system notices.
---@param model UICustomLobbyChatModel
---@param entry UICustomLobbyChatEntry
function Append(model, entry)
    local entries = table.copy(model.Entries())
    table.insert(entries, entry)
    while table.getn(entries) > MaxEntries do
        table.remove(entries, 1)
    end
    model.Entries:Set(entries)
end

--- Appends a system notice (a senderless `Confirmed` line — command feedback, join/leave, …). The one
--- place the system-entry shape is built, so the chat controller (local notices) and the lobby
--- controller (host-broadcast join/leave) stay in step.
---@param model UICustomLobbyChatModel
---@param text string
function AppendSystem(model, text)
    Append(model, {
        Id = false,
        SenderId = false,
        SenderName = "System",
        Text = text,
        Status = 'Confirmed',
        Kind = 'system',
        Time = GetSystemTimeSeconds(),
    })
end

--- Applies an authoritative chat message from the host. If we already hold a `Pending` entry with the
--- same `Id` (our own optimistic echo), reconcile it to `Confirmed`; otherwise append a new `Confirmed`
--- entry (someone else's message, or our own when we are not the originator). Ids are unique per peer,
--- so this never reconciles the wrong line.
---@param model UICustomLobbyChatModel
---@param fields { Id: string, SenderId: UILobbyPeerId, SenderName: string, Text: string }
function Receive(model, fields)
    local entries = model.Entries()
    for index, entry in entries do
        if entry.Id and entry.Id == fields.Id then
            -- reconcile in a fresh array (replace the entry object, then Set so dependents go dirty)
            local copy = table.copy(entries)
            copy[index] = {
                Id = entry.Id,
                SenderId = entry.SenderId,
                SenderName = fields.SenderName,
                Text = entry.Text,
                Status = 'Confirmed',
                Kind = entry.Kind,
                Time = entry.Time,
            }
            model.Entries:Set(copy)
            return
        end
    end
    Append(model, {
        Id = fields.Id,
        SenderId = fields.SenderId,
        SenderName = fields.SenderName,
        Text = fields.Text,
        Status = 'Confirmed',
        Kind = 'chat',
        Time = GetSystemTimeSeconds(),
    })
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the current feed across so chat survives an edit.
--- (Maintained by hand — add a field to the model, add a copy line here too.)
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        local handle = newModule.SetupSingleton()
        handle.Entries:Set(Instance.Entries())
        handle.Recipient:Set(Instance.Recipient())
    end
end

--- Hot-reload hook: re-imports this module after a couple of frames.
function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
