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

-- The **network traffic log**: a per-peer, never-synced record of every lobby message this peer
-- broadcasts, sends or receives. The instance ([CustomLobbyInstance.lua]) feeds it from its three
-- network choke points (BroadcastData / SendData / DataReceived); the Logs tab
-- ([social/CustomLobbyLogsPanel.lua]) renders it. Because each peer logs only its *own* traffic, the
-- host's log (lots of authoritative broadcasts) and a client's log (its requests + received
-- snapshots) naturally differ — no special host/client branching here.
--
-- It is reactive (an `Entries` LazyVar) like the lobby models, but it is *not* one of the three
-- lobby models: it carries no launch/session/local game state, just a diagnostic feed. Capped to a
-- ring of the most recent `MaxEntries` so it can't grow without bound across a long session.

local Create = import("/lua/lazyvar.lua").Create

--- Most recent entries kept; older ones drop off the front.
local MaxEntries = 200

---@alias UICustomLobbyLogKind
---| 'broadcast' # an outgoing broadcast to every peer
---| 'send'      # an outgoing send to a single peer
---| 'recv'      # an incoming message from a peer

---@class UICustomLobbyLogEntry
---@field Kind UICustomLobbyLogKind
---@field Type string                 # the message Type (e.g. "SetPlayers")
---@field Peer? UILobbyPeerId          # the other peer (send target / receive sender); nil for a broadcast
---@field Time number                  # seconds since the log started (for a relative clock)

-------------------------------------------------------------------------------
--#region Reactive store

---@class UICustomLobbyLog
---@field Entries LazyVar<UICustomLobbyLogEntry[]>

---@type UICustomLobbyLog | nil
local ModelInstance = nil

--- The baseline for relative timestamps (set when the store is created).
---@type number | nil
local StartTime = nil

--- Allocates a fresh log singleton, replacing any existing one.
---@return UICustomLobbyLog
function SetupSingleton()
    ---@type UICustomLobbyLog
    local model = {
        Entries = Create({}),
    }
    ModelInstance = model
    StartTime = GetSystemTimeSeconds()
    return model
end

--- Returns the log singleton, creating it on first access.
---@return UICustomLobbyLog
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbyLog]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Write helpers
--
-- Entries is a LazyVar value, so a write builds a NEW array and `:Set`s it (mutating in place never
-- marks dependents dirty — see /lua/ui/CLAUDE.md § 2).

--- Appends one entry (copy-then-Set), trimming the oldest beyond the cap.
---@param kind UICustomLobbyLogKind
---@param messageType? string
---@param peer? UILobbyPeerId
local function Append(kind, messageType, peer)
    local model = GetSingleton()
    local entries = table.copy(model.Entries())
    table.insert(entries, {
        Kind = kind,
        Type = messageType or "?",
        Peer = peer,
        Time = GetSystemTimeSeconds() - (StartTime or GetSystemTimeSeconds()),
    })
    while table.getn(entries) > MaxEntries do
        table.remove(entries, 1)
    end
    model.Entries:Set(entries)
end

--- Logs an outgoing broadcast to every peer.
---@param data table # the message ({ Type = ... })
function Broadcast(data)
    Append('broadcast', data and data.Type, nil)
end

--- Logs an outgoing send to a single peer.
---@param peerId UILobbyPeerId
---@param data table
function Send(peerId, data)
    Append('send', data and data.Type, peerId)
end

--- Logs an incoming message (its sender is `data.SenderID`).
---@param data table
function Received(data)
    Append('recv', data and data.Type, data and data.SenderID)
end

--- Empties the log entirely and restarts the relative clock (called when a lobby is exited, so the
--- next lobby starts with a clean feed timed from its own start).
function Clear()
    GetSingleton().Entries:Set({})
    StartTime = GetSystemTimeSeconds()
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the entries across.
---
--- NOTE: the instance ([CustomLobbyInstance.lua]) holds its import of this module from load time and
--- does not hot-reload, so after reloading *this* file new traffic logs into the previous singleton
--- until the lobby is recreated. Dev-only; restart the lobby if the feed goes quiet after an edit.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton()
        handle.Entries:Set(ModelInstance.Entries())
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
