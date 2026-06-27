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

-- What goes in each context menu, declaratively. A `Build*` function gathers a small
-- context table (slot, role, lobby state) and filters the entry list by each entry's
-- `when(ctx)` predicate, so the same definition produces a different menu for a host
-- vs a regular player, an open vs occupied slot, etc.
--
-- TO ADD AN ITEM: append `{ label, when, action }` to the relevant list. `when(ctx)`
-- decides visibility for the current state; `action(ctx)` runs on click and should
-- call a CustomLobbyController intent (never touch the model directly). `enabled(ctx)`
-- is optional (default true) to show an item greyed-out instead of hiding it.
--
-- The result feeds CustomLobbyContextMenu.Show (a list of { label, action, enabled }).

local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")

-------------------------------------------------------------------------------
-- Slot menu

--- The state a slot-menu entry is evaluated against.
---@class UICustomLobbySlotMenuContext
---@field slot number
---@field player UICustomLobbyPlayer | false
---@field isHost boolean
---@field isYou boolean
---@field isOpen boolean
---@field localIsObserver boolean   # the local player is currently spectating (no slot)
---@field locked boolean            # this seat is pinned in place for auto-balance

--- A declarative slot-menu entry.
---@class UICustomLobbySlotMenuEntry
---@field label string
---@field when fun(ctx: UICustomLobbySlotMenuContext): boolean
---@field action fun(ctx: UICustomLobbySlotMenuContext)
---@field enabled? fun(ctx: UICustomLobbySlotMenuContext): boolean

---@type UICustomLobbySlotMenuEntry[]
local SlotMenu = {
    {
        -- an observer joining a slot is "playing" it
        label = "Play this slot",
        when = function(ctx) return ctx.isOpen and ctx.localIsObserver end,
        action = function(ctx) CustomLobbyController.RequestTakeSlot(ctx.slot) end,
    },
    {
        -- a seated player relocating to another open slot
        label = "Take this slot",
        when = function(ctx) return ctx.isOpen and not ctx.localIsObserver end,
        action = function(ctx) CustomLobbyController.RequestTakeSlot(ctx.slot) end,
    },
    {
        label = "Ready up",
        when = function(ctx) return ctx.isYou and ctx.player and not ctx.player.Ready end,
        action = function(ctx) CustomLobbyController.RequestSetReady(true) end,
    },
    {
        label = "Cancel ready",
        when = function(ctx) return ctx.isYou and ctx.player and ctx.player.Ready end,
        action = function(ctx) CustomLobbyController.RequestSetReady(false) end,
    },

    -- Host actions:
    {
        -- pin a seated player so auto-balance keeps them where they are (e.g. to hold a premade
        -- pair on the same team); only the unlocked players are rearranged
        label = "Lock in slot",
        when = function(ctx) return ctx.isHost and ctx.player and not ctx.locked end,
        action = function(ctx) CustomLobbyController.RequestSetSlotLocked(ctx.slot, true) end,
    },
    {
        label = "Unlock slot",
        when = function(ctx) return ctx.isHost and ctx.player and ctx.locked end,
        action = function(ctx) CustomLobbyController.RequestSetSlotLocked(ctx.slot, false) end,
    },
    {
        label = "Move to observers",
        when = function(ctx) return ctx.isHost and ctx.player and ctx.player.Human end,
        action = function(ctx) CustomLobbyController.RequestMoveToObserver(ctx.slot) end,
    },
    {
        label = "Eject",
        when = function(ctx) return ctx.isHost and ctx.player and not ctx.isYou end,
        action = function(ctx) CustomLobbyController.RequestEject(ctx.slot) end,
    },
}

--- Whether `ownerId` is in the observer list.
---@param launch UICustomLobbyLaunchModel
---@param ownerId UILobbyPeerId
---@return boolean
local function IsObserver(launch, ownerId)
    local observers = launch.Observers()
    for i = 1, table.getn(observers) do
        if observers[i].OwnerID == ownerId then
            return true
        end
    end
    return false
end

--- Snapshots the state a slot menu is built from.
---@param slot number
---@return UICustomLobbySlotMenuContext
local function SlotContext(slot)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local localModel = CustomLobbyLocalModel.GetSingleton()
    local player = launch.Players[slot]()
    local localId = localModel.LocalPeerId()
    return {
        slot = slot,
        player = player,
        isHost = localModel.IsHost(),
        isYou = (player and player.OwnerID == localId) and true or false,
        isOpen = not player,
        localIsObserver = IsObserver(launch, localId),
        locked = CustomLobbySessionModel.GetSingleton().LockedSlots()[slot] and true or false,
    }
end

--- Filters a declarative entry list against a context into concrete menu items.
---@generic T
---@param entries table[]
---@param ctx T
---@return UICustomLobbyContextMenuItem[]
local function Resolve(entries, ctx)
    local items = {}
    for i = 1, table.getn(entries) do
        local entry = entries[i]
        if entry.when(ctx) then
            local entryAction = entry.action
            local entryEnabled = entry.enabled
            table.insert(items, {
                label = entry.label,
                enabled = entryEnabled == nil or entryEnabled(ctx),
                action = function() entryAction(ctx) end,
            })
        end
    end
    return items
end

--- The context-menu items for a slot, given the current lobby state.
---@param slot number
---@return UICustomLobbyContextMenuItem[]
function BuildSlotMenu(slot)
    return Resolve(SlotMenu, SlotContext(slot))
end

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    ForkThread(
        function()
            WaitFrames(2)
            import(__moduleinfo.name)
        end
    )
end

--#endregion
