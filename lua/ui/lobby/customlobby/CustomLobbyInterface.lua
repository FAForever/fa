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

-- Composition root for the custom-games lobby. It builds the area children and lays them out; each
-- child component subscribes to the model itself (see /lua/ui/lobby/TARGET_ARCHITECTURE.md). The
-- only model it reads directly is IsHost (for the action-bar buttons) and SlotCount (to size the
-- slot area); the slot rows + their drag coordination live in CustomLobbySlotsInterface.
--
-- Layout is organised into labelled *areas* (Group containers), like the dialogs — flip the
-- module-level `Debug` flag to tint each so the regions are visible while iterating. Targeted at
-- the 1024x768 minimum resolution:
--
--   ┌ TitleArea ─ title ─────────────────────────────────────────────────────────┐
--   ├──────────────────────────────────────┬─────────────────────────────────────┤
--   │ SlotsArea (slots — one or two team    │ RightArea (the map preview + facts  │
--   │   columns, top-left, up to 16)        │   line + read-only options summary) │
--   ├──────────────────────────────────────┤                                     │
--   │ BottomLeftArea (Chat / Observers      │                                     │
--   │   — tabs)                             │                                     │
--   ├──────────────────────────────────────┴─────────────────────────────────────┤
--   │ ActionArea (Leave · status · … · Launch) ─ full width                       │
--   └────────────────────────────────────────────────────────────────────────────┘
--
-- The LEFT column splits vertically: the slots on top (CustomLobbySlotsInterface — one column, or
-- two team columns for the binary auto-team modes, with the team-rating indicator atop the cards),
-- the chat/observers tabs (CustomLobbyTabs) below. The RIGHT column is the map + options
-- (CustomLobbyConfigInterface — a bound map preview, a name/size/players/version facts line, and the
-- read-only options summary). A full-width action bar at the bottom holds the global actions: Leave
-- + status on the left, the host-only Launch on the right. The title bar is just the title.
--
-- Options/mods are edited from the per-tab config gears in the right column; the action bar's old
-- generic Settings button (and the per-domain change-map / mod-select buttons) are gone.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Combo = import("/lua/ui/controls/combo.lua").Combo
local CustomLobbyBackground = import("/lua/ui/lobby/customlobby/customlobbybackground.lua")
local CustomLobbyBackgrounds = import("/lua/ui/lobby/customlobby/customlobbybackgrounds.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")
local CustomLobbySessionModel = import("/lua/ui/lobby/customlobby/models/customlobbysessionmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/models/customlobbylocalmodel.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbySlotsInterface = import("/lua/ui/lobby/customlobby/slots/customlobbyslotsinterface.lua")
local CustomLobbyConfigInterface = import("/lua/ui/lobby/customlobby/config/customlobbyconfiginterface.lua")
local CustomLobbyTabs = import("/lua/ui/lobby/customlobby/customlobbytabs.lua")
local CustomLobbyChatPanel = import("/lua/ui/lobby/customlobby/social/customlobbychatpanel.lua")
local CustomLobbyChatModel = import("/lua/ui/lobby/customlobby/social/customlobbychatmodel.lua")
local CustomLobbyObserversPanel = import("/lua/ui/lobby/customlobby/social/customlobbyobserverspanel.lua")
local CustomLobbyLogsPanel = import("/lua/ui/lobby/customlobby/social/customlobbylogspanel.lua")
local CustomLobbyPresetSelect = import("/lua/ui/lobby/customlobby/presetselect/customlobbypresetselect.lua")

local LazyVarCreate = import("/lua/lazyvar.lua").Create
local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- the per-tab config gear (inside the tab, left of the label) — skinned button (up/down/over/dis).
-- Local copy of the config column's gear (drift-is-fine; see ../CLAUDE.md "On sharing").
local GearTextures = {
    up = UIUtil.SkinnableFile('/game/menu-btns/config_btn_up.dds'),
    down = UIUtil.SkinnableFile('/game/menu-btns/config_btn_down.dds'),
    over = UIUtil.SkinnableFile('/game/menu-btns/config_btn_over.dds'),
    dis = UIUtil.SkinnableFile('/game/menu-btns/config_btn_dis.dds'),
}

-- the icon for the compact Logs tab (the game's "log" button glyph; a plain UIFile path like the
-- config column's PreviewTool icons, not a skinnable callable — CreateBitmap resolves it via UIFile)
local LogsIcon = '/BUTTON/log/_btn_up.dds'

--- Builds a tab `Action` (a config gear) for `CustomLobbyTabs`: a skinned button that runs `onOpen`
--- on click, with a tooltip. (The chat/observer settings dialogs don't exist yet — these are
--- placeholders, so `onOpen` is a no-op for now.)
---@param onOpen fun()
---@param title string
---@param body string
---@return UICustomLobbyTabAction
local function GearAction(onOpen, title, body)
    return {
        Create = function(parent)
            local gear = Button(parent, GearTextures.up, GearTextures.down, GearTextures.over, GearTextures.dis)
            gear.OnClick = function(button, modifiers)
                onOpen()
            end
            Tooltip.AddControlTooltipManual(gear, title, body)
            return gear
        end,
    }
end

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

-- the lobby content is designed for the 1024x768 floor; the root fills the frame (full-screen
-- backdrop) but the content is centered and capped to this size, so it never stretches on a
-- larger screen
local LobbyWidth = 1024
local LobbyHeight = 768

local Pad = 8
local TitleHeight = 48
local RightWidth = 360           -- the right column (map preview + options summary); the left fills the rest
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

---@class UICustomLobbyInterface : Group
---@field Trash TrashBag
---@field Background UICustomLobbyBackground
---@field Content Group
---@field TitleArea Group
---@field Title Text
---@field BackgroundCombo Combo
---@field BackgroundPaths (FileName | false)[]   # parallel to the combo items; [1] is "(None)"
---@field LeaveButton Button
---@field SlotsArea Group
---@field Slots UICustomLobbySlotsInterface
---@field BottomLeftArea Group
---@field BottomLeftTabs UICustomLobbyTabs
---@field ChatBadge LazyVar        # dummy count pill for the Chat tab (until the chat slice lands)
---@field ObserversBadge LazyVar   # observer count pill for the Observers tab
---@field RightArea Group
---@field Config UICustomLobbyConfigInterface
---@field ActionArea Group
---@field StatusLabel Text
---@field LaunchButton Button
---@field PresetsButton Button   # host-only: opens the setup-presets dialog
---@field IsHostObserver LazyVar
local CustomLobbyInterface = Class(Group) {

    ---@param self UICustomLobbyInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyInterface")

        self.Trash = TrashBag()

        -- full-window background image (cover-fit, keeps aspect ratio); subscribes to the per-peer
        -- selection itself. A solid backdrop shows through when no image is chosen.
        self.Background = CustomLobbyBackground.Create(self)

        -- everything below lives in a centered, size-capped content group (see __post_init)
        self.Content = Group(self, "CustomLobbyContent")

        --#region areas
        self.TitleArea = CreateArea(self.Content, "TitleArea", 'ffcc4040')
        self.SlotsArea = CreateArea(self.Content, "SlotsArea", 'ffcccc40')
        self.BottomLeftArea = CreateArea(self.Content, "BottomLeftArea", 'ff40cc60')
        self.RightArea = CreateArea(self.Content, "RightArea", 'ff4060cc')
        self.ActionArea = CreateArea(self.Content, "ActionArea", 'ff808080')
        --#endregion

        --#region title bar (title + background picker)
        self.Title = UIUtil.CreateText(self.TitleArea, "Custom game", 20, UIUtil.titleFont)
        self.Title:DisableHitTest()

        -- a basic background picker: a combo of every *.png in the backgrounds folder (plus a
        -- leading "(None)"). The choice is local + cosmetic, persisted via CustomLobbyBackgrounds.
        self.BackgroundCombo = Combo(self.TitleArea, 14, 8, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        self:PopulateBackgrounds()
        Tooltip.AddControlTooltipManual(self.BackgroundCombo, "Background",
            "Choose the lobby background image (a local, cosmetic choice).")
        --#endregion

        -- Leave lives in the action bar (bottom-left, beside the status text); created here so it's
        -- always available regardless of host status
        self.LeaveButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Leave")
        self.LeaveButton.OnClick = function(button, modifiers)
            -- leaving disconnects + returns to the menu via the escape handler lobby.lua
            -- registered (one teardown, shared with the Esc key)
            EscapeHandler.HandleEsc(false)
        end

        --#region slots (top-left region — a single column of rows, owns its own drag coordination)
        self.Slots = CustomLobbySlotsInterface.Create(self.SlotsArea)
        --#endregion

        --#region bottom-left: chat / observers tabs
        -- each tab gets a config gear (left) + a count pill (right), mirroring the config column.
        -- Chat's count is a dummy until the chat slice lands; Observers shows the live observer count.
        -- unread chat count (lines since the Chat tab was last viewed; the panel marks the feed seen
        -- while it's open). Empty when nothing is unread or while the Chat tab is active.
        self.ChatBadge = self.Trash:Add(LazyVarCreate())
        self.ChatBadge:Set(function()
            local model = CustomLobbyChatModel.GetSingleton()
            local unread = model.TotalCount() - model.SeenTotal()
            return unread > 0 and tostring(unread) or ""
        end)
        self.ObserversBadge = self.Trash:Add(LazyVarCreate())
        self.ObserversBadge:Set(function()
            return tostring(table.getn(CustomLobbyLaunchModel.GetSingleton().Observers()))
        end)

        self.BottomLeftTabs = CustomLobbyTabs.Create(self.BottomLeftArea, {
            Tabs = {
                -- a compact, icon-only tab: a live feed of this peer's network traffic (host and
                -- clients each see their own broadcasts / sends / receives)
                { Label = "Logs", Create = CustomLobbyLogsPanel.Create, Icon = LogsIcon, Compact = true },
                {
                    Label = "Chat", Create = CustomLobbyChatPanel.Create, Badge = self.ChatBadge,
                    Action = GearAction(function() end, "Chat settings", "Chat settings — coming soon."),
                },
                {
                    Label = "Observers", Create = CustomLobbyObserversPanel.Create, Badge = self.ObserversBadge,
                    Action = GearAction(function() end, "Observer settings", "Observer settings — coming soon."),
                },
            },
        })
        --#endregion

        --#region right column: the map preview + facts line + read-only options summary
        self.Config = CustomLobbyConfigInterface.Create(self.RightArea)
        --#endregion

        --#region action bar (full-width, bottom): status + launch
        self.StatusLabel = UIUtil.CreateText(self.ActionArea, "", 13, UIUtil.bodyFont)
        self.StatusLabel:SetColor('ff9aa0a8')
        self.StatusLabel:DisableHitTest()

        self.LaunchButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/large/', "Launch")
        self.LaunchButton.OnClick = function(button, modifiers)
            CustomLobbyController.RequestLaunch()
        end

        -- host-only: save / load named setup presets (map, options, mods, restrictions)
        self.PresetsButton = UIUtil.CreateButtonWithDropshadow(self.ActionArea, '/BUTTON/medium/', "Presets")
        self.PresetsButton.OnClick = function(button, modifiers)
            CustomLobbyPresetSelect.Open(GetFrame(0))
        end
        Tooltip.AddControlTooltipManual(self.PresetsButton, "Presets",
            "Save the current setup as a named preset, or load a saved one (host only).")
        Tooltip.AddControlTooltipManual(self.LaunchButton, "Launch", "Start the game with the current setup (host only). Everyone else must be ready.")
        --#endregion

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
        -- self.Background lays itself out cover-fit against this root (see CustomLobbyBackground)

        -- centred content, capped at the 1024x768 design size (fills the frame at the minimum
        -- resolution; centred with a backdrop border on anything larger)
        self.Content.Width:Set(function() return math.min(self.Width(), LayoutHelpers.ScaleNumber(LobbyWidth)) end)
        self.Content.Height:Set(function() return math.min(self.Height(), LayoutHelpers.ScaleNumber(LobbyHeight)) end)
        Layouter(self.Content):AtCenterIn(self):End()

        --#region areas
        -- the title and the action bar span the full width, top and bottom
        Layouter(self.TitleArea):AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad):AtTopIn(self.Content, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea)
            :AtLeftIn(self.Content, Pad):AtRightIn(self.Content, Pad):AtBottomIn(self.Content, Pad)
            :Height(ActionHeight)
            :End()

        -- the right column (map + options) is a fixed width filling the height between them
        Layouter(self.RightArea)
            :AtRightIn(self.Content, Pad):Width(RightWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()

        -- the left column splits vertically: slots on top, chat/observers below. The slots region
        -- is sized to its visible rows (one column) so chat/observers grows for smaller games; both
        -- stop at the left edge of the right column
        Layouter(self.SlotsArea):AtLeftIn(self.Content, Pad):AnchorToBottom(self.TitleArea, Pad):End()
        self.SlotsArea.Right:Set(function() return self.RightArea.Left() - LayoutHelpers.ScaleNumber(Pad) end)
        self.SlotsArea.Height:Set(function() return self.Slots:PreferredHeight() end)

        Layouter(self.BottomLeftArea)
            :AtLeftIn(self.Content, Pad):AnchorToBottom(self.SlotsArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        self.BottomLeftArea.Right:Set(function() return self.RightArea.Left() - LayoutHelpers.ScaleNumber(Pad) end)
        --#endregion

        --#region title bar (title + background picker)
        Layouter(self.Title):AtLeftIn(self.TitleArea, 8):AtVerticalCenterIn(self.TitleArea):End()
        Layouter(self.BackgroundCombo)
            :AtRightIn(self.TitleArea, 8):AtVerticalCenterIn(self.TitleArea):Width(180)
            :End()
        --#endregion

        --#region slots fill their area (the component stacks the rows + coordinates dragging)
        Layouter(self.Slots):Fill(self.SlotsArea):End()
        --#endregion

        --#region bottom-left tabs (chat / observers)
        Layouter(self.BottomLeftTabs):Fill(self.BottomLeftArea):End()
        --#endregion

        --#region right column: map preview + options summary fill the panel
        Layouter(self.Config):Fill(self.RightArea):End()
        --#endregion

        --#region action bar: Leave + status on the left, launch on the right
        Layouter(self.LeaveButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.StatusLabel):AnchorToRight(self.LeaveButton, 8):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.LaunchButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.PresetsButton):AnchorToLeft(self.LaunchButton, 8):AtVerticalCenterIn(self.LaunchButton):End()
        --#endregion

        -- size-dependent children build their scrollbars / first render now that they're sized
        -- (three-phase init)
        self.BottomLeftTabs:Initialize()
        self.Config:Initialize()
    end,

    --- Tracks host status: updates the status line and shows the host-only Launch button only to the
    --- host. (Options editing lives on the right-column config gears, host-gated there; the
    --- right-column options summary stays read-only-visible to everyone.)
    ---@param self UICustomLobbyInterface
    ---@param isHost boolean
    OnIsHostChanged = function(self, isHost)
        self.StatusLabel:SetText(isHost and "You are the host." or "The host controls the game.")
        if isHost then
            self.LaunchButton:Show()
            self.PresetsButton:Show()
        else
            self.LaunchButton:Hide()
            self.PresetsButton:Hide()
        end
    end,

    --- Fills the background picker from the *.png files on disk, with a leading "(None)" entry, and
    --- selects the one currently chosen. The combo writes the choice back through
    --- CustomLobbyBackgrounds.Select; the Background surface reacts on its own.
    ---@param self UICustomLobbyInterface
    PopulateBackgrounds = function(self)
        local labels = { "(None)" }
        local paths = { false }
        for _, background in CustomLobbyBackgrounds.Discover() do
            table.insert(labels, background.Name)
            table.insert(paths, background.Path)
        end
        self.BackgroundPaths = paths

        local selected = CustomLobbyBackgrounds.GetSelected()
        local selectedIndex = 1
        for index, path in paths do
            if path == selected then
                selectedIndex = index
                break
            end
        end

        self.BackgroundCombo:ClearItems()
        self.BackgroundCombo:AddItems(labels, selectedIndex)
        self.BackgroundCombo.OnClick = function(combo, index, text)
            CustomLobbyBackgrounds.Select(self.BackgroundPaths[index] or false)
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
