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
-- the presentation observers it needs (slot count, is-host); each child subscribes to the model
-- itself (see /lua/ui/lobby/TARGET_ARCHITECTURE.md).
--
-- Layout is organised into labelled *areas* (Group containers), like the dialogs — flip the
-- module-level `Debug` flag to tint each so the regions are visible while iterating. Targeted at
-- the 1024x768 minimum resolution:
--
--   ┌ TitleArea ─ title · TEAM SCORE · leave ─────────────────────────────┐
--   │ SlotsArea (slots ONLY — up to 16, two columns)                       │
--   ├──────────────────────────────┬───────────────────────────────────────┤
--   │ BottomLeftArea (Chat /        │ BottomRightArea (Map / Mods / Options │
--   │   Observers — tabs)           │   / Restrictions — tabs)              │
--   ├──────────────────────────────┴───────────────────────────────────────┤
--   │ ActionArea (status · … · launch) ─ full width                        │
--   └──────────────────────────────────────────────────────────────────────┘
--
-- The top is dedicated to the slot rows (we expect up to 16). The middle splits in two tabbed
-- panels: the left is chat/observers (CustomLobbyTabs), the right is the config tab panel
-- (CustomLobbyConfigInterface — Map / Mods / Options / Restrictions). A full-width action bar at
-- the bottom holds the global actions (status + launch, and the like). The accumulated team rating
-- (CustomLobbyTeamScore) sits in the title, shown only for the binary auto-team formations.

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
local CustomLobbyConfigInterface = import("/lua/ui/lobby/customlobby/config/customlobbyconfiginterface.lua")
local CustomLobbyTeamScore = import("/lua/ui/lobby/customlobby/customlobbyteamscore.lua")
local CustomLobbyTabs = import("/lua/ui/lobby/customlobby/customlobbytabs.lua")
local CustomLobbyChatPanel = import("/lua/ui/lobby/customlobby/social/customlobbychatpanel.lua")
local CustomLobbyObserversPanel = import("/lua/ui/lobby/customlobby/social/customlobbyobserverspanel.lua")

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
local SlotsHeaderHeight = 24     -- the "Players" header + gap above the two slot columns
local TitleHeight = 48
local BottomRightWidth = 560     -- config (map/mods/options/restrictions); the chat/obs panel fills the rest
local ActionHeight = 52          -- the full-width action bar at the very bottom (status + launch)

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
---@field TeamScore UICustomLobbyTeamScore
---@field LeaveButton Button
---@field SlotsArea Group
---@field SlotsHeader Text
---@field SlotsPanel Group
---@field SlotColumns Group[]               # [1] = left column, [2] = right column
---@field Slots UICustomLobbySlotInterface[]
---@field BottomLeftArea Group
---@field BottomLeftTabs UICustomLobbyTabs
---@field BottomRightArea Group
---@field Config UICustomLobbyTabs
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
        self.SlotsArea = CreateArea(self.Content, "SlotsArea", 'ffcccc40')
        self.BottomLeftArea = CreateArea(self.Content, "BottomLeftArea", 'ff40cc60')
        self.BottomRightArea = CreateArea(self.Content, "BottomRightArea", 'ff4060cc')
        self.ActionArea = CreateArea(self.Content, "ActionArea", 'ff808080')
        --#endregion

        --#region title bar (title · team score · leave)
        self.Title = UIUtil.CreateText(self.TitleArea, "Custom game", 20, UIUtil.titleFont)
        self.Title:DisableHitTest()

        self.TeamScore = CustomLobbyTeamScore.Create(self.TitleArea)

        self.LeaveButton = UIUtil.CreateButtonWithDropshadow(self.TitleArea, '/BUTTON/medium/', "Leave")
        self.LeaveButton.OnClick = function(button, modifiers)
            -- leaving disconnects + returns to the menu via the escape handler lobby.lua
            -- registered (one teardown, shared with the Esc key)
            EscapeHandler.HandleEsc(false)
        end
        --#endregion

        --#region slots (top region — two columns; odd slots left, even right)
        self.SlotsHeader = UIUtil.CreateText(self.SlotsArea, "Players", 14, UIUtil.titleFont)
        self.SlotsHeader:SetColor('ff9aa0a8')
        self.SlotsHeader:DisableHitTest()

        self.SlotsPanel = Group(self.SlotsArea, "CustomLobbySlotsPanel")
        self.SlotColumns = {
            Group(self.SlotsPanel, "CustomLobbySlotsLeft"),
            Group(self.SlotsPanel, "CustomLobbySlotsRight"),
        }

        -- One row per possible slot, placed in the left (odd) or right (even) column; the
        -- SlotCount observer reveals the active ones.
        self.Slots = {}
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local column = self.SlotColumns[math.mod(slot, 2) == 1 and 1 or 2]
            self.Slots[slot] = CustomLobbySlotInterface.Create(column, slot, self)
        end
        --#endregion

        --#region bottom-left: chat / observers tabs
        self.BottomLeftTabs = CustomLobbyTabs.Create(self.BottomLeftArea, {
            Tabs = {
                { Label = "Chat",      Create = CustomLobbyChatPanel.Create },
                { Label = "Observers", Create = CustomLobbyObserversPanel.Create },
            },
        })
        --#endregion

        --#region bottom-right: config tabs (map / mods / options / restrictions)
        self.Config = CustomLobbyConfigInterface.Create(self.BottomRightArea)
        --#endregion

        --#region action bar (full-width, bottom): status + launch and other global actions
        self.StatusLabel = UIUtil.CreateText(self.ActionArea, "", 13, UIUtil.bodyFont)
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

        -- the slots region is sized to exactly fit its rows (two columns of MaxSlots/2 = 8); the
        -- bottom row of tabbed panels then fills ALL the remaining vertical room below it
        local slotRows = math.ceil(CustomLobbyLaunchModel.MaxSlots / 2)
        Layouter(self.SlotsArea)
            :AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad)
            :AnchorToBottom(self.TitleArea, Pad):Height(SlotsHeaderHeight + slotRows * SlotHeight)
            :End()

        -- the action bar spans the full width at the very bottom; the two tabbed panels fill the
        -- room between the slots and it. The right (config) panel is a fixed width; the left
        -- (chat/observers) fills the rest
        Layouter(self.ActionArea)
            :AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad):AtBottomIn(self.Content, Pad)
            :Height(ActionHeight)
            :End()
        Layouter(self.BottomRightArea)
            :AtRightIn(self.Content, Pad):Width(BottomRightWidth)
            :AnchorToBottom(self.SlotsArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        Layouter(self.BottomLeftArea)
            :AtLeftIn(self.Content, Pad):AnchorToBottom(self.SlotsArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        self.BottomLeftArea.Right:Set(function() return self.BottomRightArea.Left() - LayoutHelpers.ScaleNumber(Pad) end)
        --#endregion

        --#region title bar (title · team score · leave)
        Layouter(self.Title):AtLeftIn(self.TitleArea, 8):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.LeaveButton):AtRightIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.TeamScore)
            :AnchorToRight(self.Title, Pad):AnchorToLeft(self.LeaveButton, Pad)
            :AtTopIn(self.TitleArea):AtBottomIn(self.TitleArea)
            :End()
        --#endregion

        --#region slots (two columns; rows stack within each)
        Layouter(self.SlotsHeader):AtLeftIn(self.SlotsArea, 4):AtTopIn(self.SlotsArea):End()
        Layouter(self.SlotsPanel)
            :AtLeftIn(self.SlotsArea):AtRightIn(self.SlotsArea)
            :AnchorToBottom(self.SlotsHeader, 4):AtBottomIn(self.SlotsArea)
            :End()

        -- two columns split down the middle of the panel (a small gutter between)
        Layouter(self.SlotColumns[1]):AtLeftIn(self.SlotsPanel):AtTopIn(self.SlotsPanel):AtBottomIn(self.SlotsPanel):End()
        self.SlotColumns[1].Right:Set(function() return self.SlotsPanel.Left() + 0.5 * self.SlotsPanel.Width() - LayoutHelpers.ScaleNumber(6) end)
        Layouter(self.SlotColumns[2]):AtRightIn(self.SlotsPanel):AtTopIn(self.SlotsPanel):AtBottomIn(self.SlotsPanel):End()
        self.SlotColumns[2].Left:Set(function() return self.SlotsPanel.Left() + 0.5 * self.SlotsPanel.Width() + LayoutHelpers.ScaleNumber(6) end)

        -- stack each column's rows top-to-bottom (slot i sits under slot i-2, its column-mate)
        for slot = 1, CustomLobbyLaunchModel.MaxSlots do
            local row = self.Slots[slot]
            local column = self.SlotColumns[math.mod(slot, 2) == 1 and 1 or 2]
            local builder = Layouter(row):AtLeftIn(column):AtRightIn(column):Height(SlotHeight)
            if slot <= 2 then
                builder:AtTopIn(column)
            else
                builder:AnchorToBottom(self.Slots[slot - 2], 0)
            end
            builder:End()
        end
        --#endregion

        --#region bottom-left tabs (chat / observers)
        Layouter(self.BottomLeftTabs):Fill(self.BottomLeftArea):End()
        --#endregion

        --#region bottom-right: config tabs fill the panel
        Layouter(self.Config):Fill(self.BottomRightArea):End()
        --#endregion

        --#region action bar: status on the left, launch on the right
        Layouter(self.StatusLabel):AtLeftIn(self.ActionArea, 8):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.LaunchButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        --#endregion

        -- size-dependent children build their scrollbars / first render now that they're sized
        -- (three-phase init)
        self.TeamScore:Initialize()
        self.BottomLeftTabs:Initialize()
        self.Config:Initialize()
    end,

    --- Shows the active slots (1..count) and hides the rest. The two columns are full-height, so
    --- the rows simply stack from the top of each — no area resizing needed (the slots own the
    --- whole top region regardless of count).
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

    -- an auto-team mode so the title's team score shows (pvsi splits by start-spot parity, so it
    -- needs no map); the four debug players already carry a PL rating + StartSpot
    launch.GameOptions:Set({ AutoTeams = 'pvsi' })

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
