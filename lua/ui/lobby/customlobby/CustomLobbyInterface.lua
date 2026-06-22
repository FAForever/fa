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

-- Composition root for the custom-games lobby. It builds and lays out the children
-- and holds NO model subscriptions of its own — each child subscribes to the model
-- itself (see /lua/ui/lobby/TARGET_ARCHITECTURE.md). For now it lays out the slot
-- rows; the options panel, map preview, observer list, footer and chat are added in
-- later slices.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbySlotInterface = import("/lua/ui/lobby/customlobby/customlobbyslotinterface.lua")
local CustomLobbyObserversInterface = import("/lua/ui/lobby/customlobby/customlobbyobserversinterface.lua")
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local SlotHeight = 24
local PanelWidth = 520

---@class UICustomLobbyInterface : Group, UICustomLobbySlotCoordinator
---@field Trash TrashBag
---@field Background Bitmap
---@field Title Text
---@field SlotsPanel Group
---@field Slots UICustomLobbySlotInterface[]
---@field ObserversPanel UICustomLobbyObserversInterface
---@field MapPreview UICustomLobbyMapPreview
---@field LeaveButton Button
---@field SlotCountObserver LazyVar
---@field HighlightedSlot number | false   # slot currently shown as a drop target
---@field DragGhost Group | false          # floating label following the cursor mid-drag
local CustomLobbyInterface = Class(Group) {

    ---@param self UICustomLobbyInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyInterface")

        self.Trash = TrashBag()
        self.HighlightedSlot = false
        self.DragGhost = false

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('ff0a0a0a')
        self.Background:DisableHitTest()

        self.Title = UIUtil.CreateText(self, "Custom Lobby (barebones)", 20, UIUtil.titleFont)

        self.SlotsPanel = Group(self, "CustomLobbySlotsPanel")

        -- One row per possible slot; the SlotCount observer reveals the active ones.
        self.Slots = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Slots[slot] = CustomLobbySlotInterface.Create(self.SlotsPanel, slot, self)
        end

        self.ObserversPanel = CustomLobbyObserversInterface.Create(self)
        self.MapPreview = CustomLobbyMapPreview.Create(self)

        -- leaving disconnects + returns to the menu via the escape handler that
        -- lobby.lua registered (one teardown definition, shared with the Esc key)
        self.LeaveButton = UIUtil.CreateButtonStd(self, '/scx_menu/small-btn/small', "Leave", 16, 2)
        self.LeaveButton.OnClick = function(button, modifiers)
            EscapeHandler.HandleEsc(false)
        end

        local session = CustomLobbySessionModel.GetSingleton()
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(session.SlotCount, function(slotCountLazy)
                self:OnSlotCountChanged(slotCountLazy())
            end))
    end,

    ---@param self UICustomLobbyInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self):Fill(parent):End()
        Layouter(self.Background):Fill(self):End()

        Layouter(self.Title):AtLeftTopIn(self, 40, 36):End()

        Layouter(self.SlotsPanel)
            :AtLeftTopIn(self, 40, 80)
            :Width(PanelWidth)
            :Height(CustomLobbyLaunchModel.MaxSlots * SlotHeight)
            :End()

        -- map preview to the right of the slots; hides itself until a scenario is set
        Layouter(self.MapPreview)
            :AnchorToRight(self.SlotsPanel, 24)
            :AtTopIn(self, 80)
            :Width(320)
            :Height(320)
            :End()

        -- stack the rows top-to-bottom inside the panel via sibling anchoring
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local row = self.Slots[slot]
            local builder = Layouter(row)
                :AtLeftIn(self.SlotsPanel)
                :AtRightIn(self.SlotsPanel)
                :Height(SlotHeight)
            if slot == 1 then
                builder:AtTopIn(self.SlotsPanel)
            else
                builder:AnchorToBottom(self.Slots[slot - 1], 0)
            end
            builder:End()
        end

        Layouter(self.ObserversPanel)
            :AtLeftIn(self, 40):AnchorToBottom(self.SlotsPanel, 16):Width(PanelWidth):Height(44)
            :End()
        Layouter(self.LeaveButton):AtLeftIn(self, 40):AnchorToBottom(self.ObserversPanel, 16):End()
    end,

    --- Shows the active slots (1..count) and hides the rest.
    ---@param self UICustomLobbyInterface
    ---@param count number
    OnSlotCountChanged = function(self, count)
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            if slot <= count then
                self.Slots[slot]:Show()
            else
                self.Slots[slot]:Hide()
            end
        end
    end,

    ---------------------------------------------------------------------------
    --#region Slot drag coordination (UICustomLobbySlotCoordinator)
    --
    -- The slot rows raise the gesture; this container owns it because it's the only
    -- thing that knows every row's rect. The "what's grabbed / where" state here is
    -- purely visual — a drop resolves to the RequestSwapSlots intent, host-authoritative.

    --- Only the host can drag, and only a slot that holds a player (you grab a token).
    ---@param self UICustomLobbyInterface
    ---@param slot number
    ---@return boolean
    CanDrag = function(self, slot)
        if not CustomLobbyLocalModel.GetSingleton().IsHost() then
            return false
        end
        return CustomLobbyLaunchModel.GetSingleton().Players[slot]() ~= false
    end,

    --- The active slot whose row contains the screen point, or nil.
    ---@param self UICustomLobbyInterface
    ---@param x number
    ---@param y number
    ---@return number | nil
    SlotIndexAt = function(self, x, y)
        local count = CustomLobbySessionModel.GetSingleton().SlotCount()
        for slot = 1, count do
            local row = self.Slots[slot]
            if row and x >= row.Left() and x <= row.Right() and y >= row.Top() and y <= row.Bottom() then
                return slot
            end
        end
        return nil
    end,

    --- Mid-drag: follow the cursor with the ghost and highlight the row under it.
    ---@param self UICustomLobbyInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDragMove = function(self, source, x, y)
        if not self.DragGhost then
            self.DragGhost = self:CreateDragGhost(source)
        end
        self.DragGhost.Left:Set(x + LayoutHelpers.ScaleNumber(12))
        self.DragGhost.Top:Set(y + LayoutHelpers.ScaleNumber(8))
        self:HighlightSlot(self:SlotIndexAt(x, y))
    end,

    --- Drop: swap the source slot with whatever row the cursor is over (a move if it's
    --- empty). Dropping outside any row is a no-op.
    ---@param self UICustomLobbyInterface
    ---@param source number
    ---@param x number
    ---@param y number
    OnSlotDrop = function(self, source, x, y)
        local target = self:SlotIndexAt(x, y)
        if target and target ~= source then
            CustomLobbyController.RequestSwapSlots(source, target)
        end
    end,

    --- Clears the transient drag visuals.
    ---@param self UICustomLobbyInterface
    OnSlotDragEnd = function(self)
        self:HighlightSlot(nil)
        if self.DragGhost then
            self.DragGhost:Destroy()
            self.DragGhost = false
        end
    end,

    --- Moves the drop-target highlight to `slot` (nil clears it).
    ---@param self UICustomLobbyInterface
    ---@param slot number | nil
    HighlightSlot = function(self, slot)
        slot = slot or false
        if self.HighlightedSlot == slot then
            return
        end
        if self.HighlightedSlot and self.Slots[self.HighlightedSlot] then
            self.Slots[self.HighlightedSlot]:SetDropHighlight(false)
        end
        self.HighlightedSlot = slot
        if slot and self.Slots[slot] then
            self.Slots[slot]:SetDropHighlight(true)
        end
    end,

    --- Builds the floating drag label (the grabbed player's name) on the interface so
    --- it draws above the rows. Destroyed in OnSlotDragEnd.
    ---@param self UICustomLobbyInterface
    ---@param source number
    ---@return Group
    CreateDragGhost = function(self, source)
        local player = CustomLobbyLaunchModel.GetSingleton().Players[source]()
        local name = (player and player.PlayerName) or ("Slot " .. tostring(source))

        local ghost = Group(self, "CustomLobbyDragGhost")
        ghost:DisableHitTest()

        local bg = Bitmap(ghost)
        bg:SetSolidColor('cc101418')
        bg:DisableHitTest()

        local label = UIUtil.CreateText(ghost, name, 14, UIUtil.bodyFont)
        label:DisableHitTest()

        Layouter(label):AtLeftTopIn(ghost, 6, 3):End()
        Layouter(bg):Fill(ghost):End()
        ghost.Width:Set(function() return label.Width() + LayoutHelpers.ScaleNumber(12) end)
        ghost.Height:Set(function() return label.Height() + LayoutHelpers.ScaleNumber(6) end)
        return ghost
    end,

    --#endregion

    ---@param self UICustomLobbyInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton

--- A trashbag destroyed on reload.
local ModuleTrash = TrashBag()

---@type UICustomLobbyInterface | false
local Instance = false

--- Returns the interface singleton, creating it on first access.
---@return UICustomLobbyInterface
function GetSingleton()
    if Instance then
        return Instance
    end
    Instance = CustomLobbyInterface(GetFrame(0))
    ModuleTrash:Add(Instance)
    return Instance
end

--- Allocates a fresh interface singleton, replacing any existing one.
---@return UICustomLobbyInterface
function SetupSingleton()
    if Instance then
        Instance:Destroy()
    end
    Instance = CustomLobbyInterface(GetFrame(0))
    ModuleTrash:Add(Instance)
    return Instance
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

--- Standalone entry point: mounts the lobby against a model populated with fake
--- players so the UI can be inspected without networking. From the console:
---   `UI_Lua import("/lua/ui/lobby/customlobby/customlobbyinterface.lua").OpenDebug()`
function OpenDebug()
    local slotCount = 6
    local launch = CustomLobbyLaunchModel.SetupSingleton()
    CustomLobbySessionModel.SetupSingleton(slotCount)

    local localModel = CustomLobbyLocalModel.SetupSingleton()
    localModel.LocalPeerId:Set("1")
    localModel.IsHost:Set(true)

    -- four players in the first four slots, last two left open
    for slot = 1, 4 do
        CustomLobbyLaunchModel.SetPlayer(launch, slot, {
            PlayerName  = "Player " .. slot,
            OwnerID     = tostring(slot),
            Human       = slot ~= 4,                       -- slot 4 is an AI, to show the AI colour
            Faction     = math.mod(slot - 1, 4) + 1,
            PlayerColor = slot,
            ArmyColor   = slot,
            Team        = math.mod(slot - 1, 2) + 2,       -- alternating teams 1/2
            StartSpot   = slot,
            Ready       = slot <= 2,
            PL          = 1000 + slot * 100,
            AIPersonality = slot == 4 and "rush" or nil,
        })
    end

    -- a couple of observers so the observer strip shows something
    launch.Observers:Set({
        { PlayerName = "Zock",  OwnerID = "10", Human = true },
        { PlayerName = "Spag",  OwnerID = "11", Human = true },
    })

    -- a stock map so the preview renders; swap to any installed scenario if this
    -- one isn't present (an unknown path just leaves the preview frame empty)
    CustomLobbyLaunchModel.SetScenario(launch, "/maps/scmp_009/scmp_009_scenario.lua")

    SetupSingleton()
end

--- Tears down the debug lobby.
function CloseDebug()
    ModuleTrash:Destroy()
    Instance = false
end

--- Called by the module manager when this module is reloaded.
---@param newModule any
function __moduleinfo.OnReload(newModule)
    if Instance then
        newModule.SetupSingleton()
    end
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()
    import(__moduleinfo.name)
end

--#endregion
