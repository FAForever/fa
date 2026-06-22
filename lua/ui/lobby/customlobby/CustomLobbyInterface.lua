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
local CustomLobbyAuthoritativeModel = import("/lua/ui/lobby/customlobby/customlobbyauthoritativemodel.lua")
local CustomLobbySlotInterface = import("/lua/ui/lobby/customlobby/customlobbyslotinterface.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

local SlotHeight = 24
local PanelWidth = 520

---@class UICustomLobbyInterface : Group
---@field Trash TrashBag
---@field Background Bitmap
---@field Title Text
---@field SlotsPanel Group
---@field Slots UICustomLobbySlotInterface[]
---@field LeaveButton Button
---@field SlotCountObserver LazyVar
local CustomLobbyInterface = Class(Group) {

    ---@param self UICustomLobbyInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyInterface")

        self.Trash = TrashBag()

        self.Background = Bitmap(self)
        self.Background:SetSolidColor('ff0a0a0a')
        self.Background:DisableHitTest()

        self.Title = UIUtil.CreateText(self, "Custom Lobby (barebones)", 20, UIUtil.titleFont)

        self.SlotsPanel = Group(self, "CustomLobbySlotsPanel")

        -- One row per possible slot; the SlotCount observer reveals the active ones.
        self.Slots = {}
        for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
            self.Slots[slot] = CustomLobbySlotInterface.Create(self.SlotsPanel, slot)
        end

        -- leaving disconnects + returns to the menu via the escape handler that
        -- lobby.lua registered (one teardown definition, shared with the Esc key)
        self.LeaveButton = UIUtil.CreateButtonStd(self, '/scx_menu/small-btn/small', "Leave", 16, 2)
        self.LeaveButton.OnClick = function(button, modifiers)
            EscapeHandler.HandleEsc(false)
        end

        local model = CustomLobbyAuthoritativeModel.GetSingleton()
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(model.SlotCount, function(slotCountLazy)
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
            :Height(CustomLobbyAuthoritativeModel.MaxSlots * SlotHeight)
            :End()

        -- stack the rows top-to-bottom inside the panel via sibling anchoring
        for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
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

        Layouter(self.LeaveButton):AtLeftIn(self, 40):AnchorToBottom(self.SlotsPanel, 24):End()
    end,

    --- Shows the active slots (1..count) and hides the rest.
    ---@param self UICustomLobbyInterface
    ---@param count number
    OnSlotCountChanged = function(self, count)
        for slot = 1, CustomLobbyAuthoritativeModel.MaxSlots do
            if slot <= count then
                self.Slots[slot]:Show()
            else
                self.Slots[slot]:Hide()
            end
        end
    end,

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
    local model = CustomLobbyAuthoritativeModel.SetupSingleton(slotCount)
    model.LocalPeerId:Set("1")
    model.IsHost:Set(true)

    -- four players in the first four slots, last two left open
    for slot = 1, 4 do
        CustomLobbyAuthoritativeModel.SetPlayer(model, slot, {
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
