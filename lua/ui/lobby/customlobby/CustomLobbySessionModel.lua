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

-- The **session** state: host-dictated lobby-room management that is shared with everyone
-- but is NOT part of the launched game. A closed slot just means "no army there" at launch
-- and the slot count is map-derived presentation — neither reaches the scenario, so they
-- live here rather than in the launch payload.
--
-- One of three lobby models — see /lua/ui/lobby/customlobby/CLAUDE.md:
--   * LaunchModel   — shared, launched.
--   * SessionModel  (this) — shared, lobby-room only.
--   * LocalModel    — per-peer, never synced.
--
-- Synced host -> clients as a whole snapshot (CustomLobbyController.BroadcastSessionState).

local Create = import("/lua/lazyvar.lua").Create

-------------------------------------------------------------------------------
--#region Reactive model

--- Reactive session-state singleton (shared, host-dictated, not launched).
---@class UICustomLobbySessionModel
---@field SlotCount   LazyVar<number>                    # player slots the current map supports
---@field ClosedSlots LazyVar<table<number, boolean>>

---@type UICustomLobbySessionModel | nil
local ModelInstance = nil

--- Allocates a fresh session-model singleton, replacing any existing instance.
---@param slotCount? number
---@return UICustomLobbySessionModel
function SetupSingleton(slotCount)
    ---@type UICustomLobbySessionModel
    local model = {
        SlotCount   = Create(slotCount or 8),
        ClosedSlots = Create({}),
    }

    ModelInstance = model
    return model
end

--- Returns the session-model singleton, creating it on first access.
---@return UICustomLobbySessionModel
function GetSingleton()
    if not ModelInstance then
        SetupSingleton()
    end
    return ModelInstance --[[@as UICustomLobbySessionModel]]
end

--#endregion

-------------------------------------------------------------------------------
--#region Write helpers

--- Sets the number of active slots.
---@param model UICustomLobbySessionModel
---@param slotCount number
function SetSlotCount(model, slotCount)
    model.SlotCount:Set(slotCount)
end

--- Sets the closed flag for a slot (copy-then-Set).
---@param model UICustomLobbySessionModel
---@param slot number
---@param closed boolean
function SetClosed(model, slot, closed)
    local closedSlots = table.copy(model.ClosedSlots())
    closedSlots[slot] = closed
    model.ClosedSlots:Set(closedSlots)
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: rebuilds the singleton and copies the current values across.
---
--- NOTE: maintained by hand — add a field to the model, add a copy line here too.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if ModelInstance then
        local handle = newModule.SetupSingleton(ModelInstance.SlotCount())
        handle.ClosedSlots:Set(ModelInstance.ClosedSlots())
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
