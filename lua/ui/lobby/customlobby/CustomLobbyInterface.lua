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

-- Composition root for the custom-games lobby. It builds and lays out the children and holds only
-- the two presentation observers it needs (slot count, is-host); each child subscribes to the
-- model itself (see /lua/ui/lobby/TARGET_ARCHITECTURE.md).
--
-- Layout is organised into labelled *areas* (Group containers), like the dialogs — flip the
-- module-level `Debug` flag to tint each so the regions are visible while iterating. Targeted at
-- the 1024x768 minimum resolution:
--
--   ┌ TitleArea ─────────────────────────────────────────────┐
--   │ LeftArea (slots / observers / chat) │ ConfigInterface   │
--   └ ActionArea ────────────────────────────────────────────┘
--
-- The right column is the CustomLobbyConfigInterface component (the Map / Options / Mods / Units
-- tab panel); it owns its own tabs + host-gating. The interface keeps the slot grid, observer
-- strip, chat, and the action bar (status + launch).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbySlotInterface = import("/lua/ui/lobby/customlobby/customlobbyslotinterface.lua")
local CustomLobbyObserversInterface = import("/lua/ui/lobby/customlobby/customlobbyobserversinterface.lua")
local CustomLobbyConfigInterface = import("/lua/ui/lobby/customlobby/config/customlobbyconfiginterface.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = true

-- the lobby content is designed for the 1024x768 floor; the root fills the frame (full-screen
-- backdrop) but the content is centered and capped to this size, so it never stretches on a
-- larger screen
local LobbyWidth = 1024
local LobbyHeight = 768

local Pad = 8
local SlotHeight = 24
local RightWidth = 360
local TitleHeight = 44
local ActionHeight = 60
local ObserverHeight = 44

--- Creates a layout area (an invisible Group with an optional debug tint).
---@param parent Control
---@param name string
---@param color string
---@return Group
local function CreateArea(parent, name, color)
    local area = Group(parent, name)
    local bg = Bitmap(area)
    bg:SetSolidColor(color)
    bg:SetAlpha(Debug and 0.18 or 0.0)
    bg:DisableHitTest()
    Layouter(bg):Fill(area):End()
    area.Bg = bg
    return area
end

---@class UICustomLobbyInterface : Group, UICustomLobbySlotCoordinator
---@field Trash TrashBag
---@field Background Bitmap
---@field Content Group
---@field TitleArea Group
---@field Title Text
---@field LeaveButton Button
---@field LeftArea Group
---@field SlotsArea Group
---@field SlotsHeader Text
---@field SlotsPanel Group
---@field Slots UICustomLobbySlotInterface[]
---@field ObserversArea Group
---@field ObserversPanel UICustomLobbyObserversInterface
---@field SpectateButton Button
---@field ChatArea Group
---@field ChatPlaceholder Text
---@field Config UICustomLobbyConfigInterface
---@field ActionArea Group
---@field StatusLabel Text
---@field LaunchButton Button
---@field SlotCountObserver LazyVar
---@field IsHostObserver LazyVar
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

        -- everything below lives in a centered, size-capped content group (see __post_init)
        self.Content = Group(self, "CustomLobbyContent")

        --#region areas
        self.TitleArea = CreateArea(self.Content, "TitleArea", 'ffcc4040')
        self.ActionArea = CreateArea(self.Content, "ActionArea", 'ff808080')
        self.LeftArea = CreateArea(self.Content, "LeftArea", 'ff4060cc')
        self.SlotsArea = CreateArea(self.LeftArea, "SlotsArea", 'ffcccc40')
        self.ObserversArea = CreateArea(self.LeftArea, "ObserversArea", 'ff40cccc')
        self.ChatArea = CreateArea(self.LeftArea, "ChatArea", 'ff40cc60')
        --#endregion

        -- the right column: the Map / Options / Mods / Units tab panel (owns its own tabs + gating)
        self.Config = CustomLobbyConfigInterface.Create(self.Content)

        --#region title bar
        self.Title = UIUtil.CreateText(self.TitleArea, "Custom game", 20, UIUtil.titleFont)
        self.Title:DisableHitTest()

        self.LeaveButton = UIUtil.CreateButtonWithDropshadow(self.TitleArea, '/BUTTON/medium/', "Leave")
        self.LeaveButton.OnClick = function(button, modifiers)
            -- leaving disconnects + returns to the menu via the escape handler lobby.lua
            -- registered (one teardown, shared with the Esc key)
            EscapeHandler.HandleEsc(false)
        end
        --#endregion

        --#region slots
        self.SlotsHeader = UIUtil.CreateText(self.SlotsArea, "Players", 14, UIUtil.titleFont)
        self.SlotsHeader:SetColor('ff9aa0a8')
        self.SlotsHeader:DisableHitTest()

        self.SlotsPanel = Group(self.SlotsArea, "CustomLobbySlotsPanel")

        -- One row per possible slot; the SlotCount observer reveals the active ones.
        self.Slots = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            self.Slots[slot] = CustomLobbySlotInterface.Create(self.SlotsPanel, slot, self)
        end
        --#endregion

        --#region observers
        self.ObserversPanel = CustomLobbyObserversInterface.Create(self.ObserversArea)

        -- everyone can drop to the observers; the move is host-authoritative (a client's click
        -- asks the host through the intent)
        self.SpectateButton = UIUtil.CreateButtonWithDropshadow(self.ObserversArea, '/BUTTON/medium/', "Observe")
        self.SpectateButton.OnClick = function(button, modifiers)
            local slot = self:FindLocalSlot()
            if slot then
                CustomLobbyController.RequestMoveToObserver(slot)
            end
        end
        Tooltip.AddControlTooltipManual(self.SpectateButton, "Become observer", "Leave your slot and watch as an observer.")
        --#endregion

        --#region chat (placeholder until the lobby-chat slice lands)
        self.ChatPlaceholder = UIUtil.CreateText(self.ChatArea, "Chat — coming soon", 14, UIUtil.bodyFont)
        self.ChatPlaceholder:SetColor('ff5a606a')
        self.ChatPlaceholder:DisableHitTest()
        --#endregion

        --#region action bar
        self.StatusLabel = UIUtil.CreateText(self.ActionArea, "", 14, UIUtil.bodyFont)
        self.StatusLabel:SetColor('ff9aa0a8')
        self.StatusLabel:DisableHitTest()

        self.LaunchButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/large/', "Launch")
        self.LaunchButton.OnClick = function(button, modifiers)
            -- launch flow isn't wired up yet
        end
        self.LaunchButton:Disable()
        Tooltip.AddControlTooltipManual(self.LaunchButton, "Launch", "Launching isn't wired up yet.")
        --#endregion

        local session = CustomLobbySessionModel.GetSingleton()
        self.SlotCountObserver = self.Trash:Add(
            LazyVarDerive(session.SlotCount, function(slotCountLazy)
                self:OnSlotCountChanged(slotCountLazy())
            end))

        local localModel = CustomLobbyLocalModel.GetSingleton()
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(localModel.IsHost, function(isHostLazy)
                self:OnIsHostChanged(isHostLazy())
            end))
    end,

    ---@param self UICustomLobbyInterface
    ---@param parent Control
    __post_init = function(self, parent)
        Layouter(self):Fill(parent):End()
        Layouter(self.Background):Fill(self):End()

        -- centred content, capped at the 1024x768 design size (fills the frame at the minimum
        -- resolution; centred with a backdrop border on anything larger)
        self.Content.Width:Set(function() return math.min(self.Width(), LayoutHelpers.ScaleNumber(LobbyWidth)) end)
        self.Content.Height:Set(function() return math.min(self.Height(), LayoutHelpers.ScaleNumber(LobbyHeight)) end)
        Layouter(self.Content):AtCenterIn(self):End()

        --#region areas
        Layouter(self.TitleArea):AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad):AtTopIn(self.Content, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad):AtBottomIn(self.Content, Pad):Height(ActionHeight):End()
        Layouter(self.Config)
            :AtRightIn(self.Content, Pad):Width(RightWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        Layouter(self.LeftArea)
            :AtLeftIn(self.Content, Pad):AnchorToLeft(self.Config, Pad)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()

        -- the slots area sizes to the *active* slot count (map-derived, 1..MaxSlots) so the
        -- observers + chat below it reflow up on smaller maps; OnSlotCountChanged keeps it in sync
        local slotCount = CustomLobbySessionModel.GetSingleton().SlotCount()
        Layouter(self.SlotsArea)
            :AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea):AtTopIn(self.LeftArea)
            :Height(20 + slotCount * SlotHeight)
            :End()
        Layouter(self.ObserversArea)
            :AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea)
            :AnchorToBottom(self.SlotsArea, Pad):Height(ObserverHeight)
            :End()
        Layouter(self.ChatArea)
            :AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea)
            :AnchorToBottom(self.ObserversArea, Pad):AtBottomIn(self.LeftArea)
            :End()
        --#endregion

        --#region title bar
        Layouter(self.Title):AtLeftIn(self.TitleArea, 8):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.LeaveButton):AtRightIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()
        --#endregion

        --#region slots
        Layouter(self.SlotsHeader):AtLeftIn(self.SlotsArea, 4):AtTopIn(self.SlotsArea):End()
        Layouter(self.SlotsPanel)
            :AtLeftIn(self.SlotsArea):AtRightIn(self.SlotsArea)
            :AnchorToBottom(self.SlotsHeader, 4)
            :Height(slotCount * SlotHeight)
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
        --#endregion

        --#region observers
        Layouter(self.SpectateButton):AtRightIn(self.ObserversArea):AtVerticalCenterIn(self.ObserversArea):End()
        Layouter(self.ObserversPanel)
            :AtLeftIn(self.ObserversArea):AnchorToLeft(self.SpectateButton, Pad)
            :AtTopIn(self.ObserversArea):AtBottomIn(self.ObserversArea)
            :End()
        --#endregion

        Layouter(self.ChatPlaceholder):AtHorizontalCenterIn(self.ChatArea):AtVerticalCenterIn(self.ChatArea):End()

        --#region action bar
        Layouter(self.StatusLabel):AtLeftIn(self.ActionArea, 8):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.LaunchButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        --#endregion

        -- the config panel is now sized; let it build its grids' scrollbars + first render
        -- (three-phase init — its Grids need a concrete height)
        self.Config:Initialize()
    end,

    --- Shows the active slots (1..count), hides the rest, and resizes the slots area to fit them
    --- (so the observers + chat below reflow to the map's actual slot count, up to MaxSlots).
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
        self.SlotsPanel.Height:Set(LayoutHelpers.ScaleNumber(count * SlotHeight))
        self.SlotsArea.Height:Set(LayoutHelpers.ScaleNumber(20 + count * SlotHeight))
    end,

    --- Tracks host status: updates the status line and shows the launch button only to the host.
    --- (The right-column config panel gates its own host-only buttons.)
    ---@param self UICustomLobbyInterface
    ---@param isHost boolean
    OnIsHostChanged = function(self, isHost)
        self.StatusLabel:SetText(isHost and "You are the host." or "The host controls the game.")
        if isHost then
            self.LaunchButton:Show()
        else
            self.LaunchButton:Hide()
        end
    end,

    --- The local player's slot (the one this peer owns), or nil if they're an observer / unseated.
    ---@param self UICustomLobbyInterface
    ---@return number | nil
    FindLocalSlot = function(self)
        local launch = CustomLobbyLaunchModel.GetSingleton()
        local localId = CustomLobbyLocalModel.GetSingleton().LocalPeerId()
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local player = launch.Players[slot]()
            if player and player.OwnerID == localId then
                return slot
            end
        end
        return nil
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

--- Called by the module manager when this module is reloaded. The rebuild is driven by
--- OnDirty's deferred thread (below), so there's nothing to do here.
---@param newModule any
function __moduleinfo.OnReload(newModule)
end

--- Called by the module manager when this module becomes dirty.
---
--- Two things matter here:
---  * the re-import is DEFERRED a couple of frames — a synchronous `import` re-enters the
---    module manager mid-reload (e.g. when an edit to a `mapselect/` file cascades up to this
---    importer), the reload never finishes, and the torn-down lobby is left as a black frame;
---  * the rebuild is done HERE (in the deferred thread, against the freshly imported module),
---    not in OnReload — OnReload isn't reliably called for a module reloaded *transitively*,
---    which is exactly the cascade case. We only rebuild if a lobby was actually mounted, so
---    editing a lobby file while in the menu doesn't spawn a phantom lobby.
function __moduleinfo.OnDirty()
    local wasMounted = Instance ~= false
    ModuleTrash:Destroy()
    Instance = false
    ForkThread(
        function()
            WaitFrames(2)
            local newModule = import(__moduleinfo.name)
            if wasMounted then
                newModule.SetupSingleton()
            end
        end
    )
end

--#endregion
