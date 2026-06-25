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

-- The lobby's right column: the map preview pinned on top, three tabs below —
--
--   ┌ map preview (square, bound) ─┐
--   │                              │
--   └──────────────────────────────┘
--   Seton's Clutch
--   20km · 8 players · v3
--   [ Options | Mods | Restrictions ]
--   ┌ active tab's panel ──────────┐
--   │ …                            │
--   └──────────────────────────────┘
--
-- The preview is the shared bound `CustomLobbyMapPreview` (subscribes to `ScenarioFile`, renders
-- faction spawns; the engine caches the single current map's texture, so churn is free). It is
-- pinned above the tabs — only the panel below churns on tab switch — with a short name +
-- size/players/version facts line between them. The three tab panels are all read-only: their own
-- per-domain action buttons are gone (the interface's action-bar Settings button opens the options
-- editor); the change-map / mod-select entry points return when the config rework resumes.
--
-- This used to be a four-tab strip including a Map tab; the Map preview is now the pinned header.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
local CustomLobbyTabs = import("/lua/ui/lobby/customlobby/customlobbytabs.lua")
local CustomLobbyOptionsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyoptionspanel.lua")
local CustomLobbyModsPanel = import("/lua/ui/lobby/customlobby/config/customlobbymodspanel.lua")
local CustomLobbyUnitsPanel = import("/lua/ui/lobby/customlobby/config/customlobbyunitspanel.lua")
local CustomLobbyMapSelect = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapselect.lua")
local CustomLobbyOptionSelect = import("/lua/ui/lobby/customlobby/optionselect/customlobbyoptionselect.lua")
local CustomLobbyModSelect = import("/lua/ui/lobby/customlobby/modselect/customlobbymodselect.lua")
local CustomLobbyUnitSelect = import("/lua/ui/lobby/customlobby/unitselect/customlobbyunitselect.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")
local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local OptionUtil = import("/lua/ui/optionutil.lua")
local ModUtilities = import("/lua/ui/modutilities.lua")

local LazyVarCreate = import("/lua/lazyvar.lua").Create
local LazyVarDerive = import("/lua/lazyvar.lua").Derive
local Layouter = LayoutHelpers.ReusedLayoutFor

local Inset = 6
local NameMaxChars = 30
local FactsColor = 'ff9aa0a8'

-- the preview tool strip (to the right of the map): square icon buttons
local ToolSize = 28
local ToolGap = 6
local ToolIconInset = 5
local ToolIdle = 'ff141a20'
local ToolHover = 'ff1f262e'
local ToolActive = 'ff2c4a5e'        -- a lit toggle's background
local ToolIconDim = 0.40             -- icon alpha when a toggle is off

-- icon textures (skin-relative; resolved through UIFile). The army icon reuses the start-position
-- commander silhouette; resources the mass icon; water a map pin; config an edit glyph.
local ArmyIcon = '/dialogs/mapselect02/commander_alpha.dds'
local ResourceIcon = '/game/build-ui/icon-mass_bmp.dds'
local WaterIcon = '/game/camera-btn/pinned_btn_up.dds'
local ConfigIcon = '/game/menu-btns/config_btn_up.dds'

-- the per-tab config gear (inside the tab, left of the label): a fully-skinned button
-- (up/down/over/dis) that opens that tab's editor dialog
local GearTextures = {
    up = UIUtil.SkinnableFile('/game/menu-btns/config_btn_up.dds'),
    down = UIUtil.SkinnableFile('/game/menu-btns/config_btn_down.dds'),
    over = UIUtil.SkinnableFile('/game/menu-btns/config_btn_over.dds'),
    dis = UIUtil.SkinnableFile('/game/menu-btns/config_btn_dis.dds'),
}

--- Builds a tab `Action` (a config gear) for `CustomLobbyTabs`: a skinned button that opens
--- `onOpen` on click, with a tooltip. `visibleLazy` (optional) hides the gear when it doesn't apply
--- — e.g. the host-only Options gear is hidden for clients (the tab's label re-centres).
---@param onOpen fun()
---@param title string
---@param body string
---@param visibleLazy? LazyVar
---@return UICustomLobbyTabAction
local function GearAction(onOpen, title, body, visibleLazy)
    return {
        Create = function(parent)
            local gear = Button(parent, GearTextures.up, GearTextures.down, GearTextures.over, GearTextures.dis)
            gear.OnClick = function(button, modifiers)
                onOpen()
            end
            Tooltip.AddControlTooltipManual(gear, title, body)
            return gear
        end,
        Visible = visibleLazy,
    }
end

-- A small square icon button used in the preview tool strip. A toggle flips Active on click and
-- calls `OnToggle(active)`; an action button (isToggle = false) just calls `OnPress`. The look is
-- the tab convention: idle / hover / lit-when-active background, with the icon dimmed when off.
---@class UICustomLobbyPreviewTool : Group
---@field Bg Bitmap
---@field Icon Bitmap
---@field IsToggle boolean
---@field Active boolean
---@field Hovered boolean
---@field OnToggle? fun(active: boolean)
---@field OnPress? fun()
local PreviewTool = ClassUI(Group) {

    ---@param self UICustomLobbyPreviewTool
    ---@param parent Control
    ---@param texture FileName
    ---@param isToggle boolean
    __init = function(self, parent, texture, isToggle)
        Group.__init(self, parent, "CustomLobbyPreviewTool")

        self.IsToggle = isToggle or false
        self.Active = true
        self.Hovered = false

        self.Bg = Bitmap(self)
        self.Bg:SetSolidColor(ToolIdle)

        self.Icon = UIUtil.CreateBitmap(self, texture)
        self.Icon:DisableHitTest()

        self.Bg.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.IsToggle then
                    self.Active = not self.Active
                    self:ApplyVisual()
                    if self.OnToggle then
                        self.OnToggle(self.Active)
                    end
                elseif self.OnPress then
                    self.OnPress()
                end
                return true
            elseif event.Type == 'MouseEnter' then
                self.Hovered = true
                self:ApplyVisual()
                return true
            elseif event.Type == 'MouseExit' then
                self.Hovered = false
                self:ApplyVisual()
                return true
            end
            return false
        end
    end,

    ---@param self UICustomLobbyPreviewTool
    __post_init = function(self)
        Layouter(self.Bg):Fill(self):End()
        Layouter(self.Icon):AtCenterIn(self):Width(ToolSize - 2 * ToolIconInset):Height(ToolSize - 2 * ToolIconInset):End()
        self:ApplyVisual()
    end,

    --- Repaints the background + icon for the current active/hover state.
    ---@param self UICustomLobbyPreviewTool
    ApplyVisual = function(self)
        local bg = ToolIdle
        if self.IsToggle and self.Active then
            bg = ToolActive
        elseif self.Hovered then
            bg = ToolHover
        end
        self.Bg:SetSolidColor(bg)
        local lit = (not self.IsToggle) or self.Active
        self.Icon:SetAlpha(lit and 1.0 or ToolIconDim)
    end,

    --- Sets the toggle state without firing `OnToggle` (for syncing the initial visual).
    ---@param self UICustomLobbyPreviewTool
    ---@param active boolean
    SetActive = function(self, active)
        self.Active = active
        self:ApplyVisual()
    end,
}

--- Truncates `text` to `maxChars`, appending "…" when it had to cut. (Local copy — drift-fine, see
--- ../CLAUDE.md "On sharing".)
---@param text string
---@param maxChars number
---@return string
local function Truncate(text, maxChars)
    text = text or ""
    if string.len(text) > maxChars then
        return string.sub(text, 1, maxChars - 1) .. "…"
    end
    return text
end

--- Number of start spots a scenario declares, or 0.
---@param scenario UILobbyScenarioInfo
---@return number
local function ArmyCount(scenario)
    local armies = scenario.Configurations
        and scenario.Configurations.standard
        and scenario.Configurations.standard.teams
        and scenario.Configurations.standard.teams[1]
        and scenario.Configurations.standard.teams[1].armies
    return armies and table.getsize(armies) or 0
end

---@class UICustomLobbyConfigInterface : Group
---@field Trash TrashBag
---@field Preview UICustomLobbyMapPreview
---@field Name Text
---@field Info Text
---@field ArmyToggle UICustomLobbyPreviewTool
---@field ResourceToggle UICustomLobbyPreviewTool
---@field WaterToggle UICustomLobbyPreviewTool
---@field ConfigButton UICustomLobbyPreviewTool
---@field Tabs UICustomLobbyTabs
---@field OptionsBadge LazyVar    # count of non-default options (Options tab pill)
---@field ModsBadge LazyVar       # "sim / ui" mod counts (Mods tab pill)
---@field RestrictionsBadge LazyVar # restriction count (Restrictions tab pill)
---@field ScenarioObserver LazyVar
---@field IsHostObserver LazyVar
local CustomLobbyConfigInterface = ClassUI(Group) {

    ---@param self UICustomLobbyConfigInterface
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, "CustomLobbyConfigInterface")

        self.Trash = TrashBag()

        self.Preview = CustomLobbyMapPreview.Create(self, { Bound = true })

        self.Name = UIUtil.CreateText(self, "", 15, UIUtil.titleFont)
        self.Name:DisableHitTest()
        self.Info = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Info:SetColor(FactsColor)
        self.Info:DisableHitTest()

        --#region preview tool strip (to the right of the map): overlay toggles + change-scenario
        local surface = self.Preview.Surface

        self.ArmyToggle = PreviewTool(self, ArmyIcon, true)
        self.ArmyToggle.OnToggle = function(active) surface:SetOverlayVisible('spawns', active) end
        Tooltip.AddControlTooltipManual(self.ArmyToggle.Bg, "Army icons", "Show or hide the start-position army icons.")

        self.ResourceToggle = PreviewTool(self, ResourceIcon, true)
        self.ResourceToggle.OnToggle = function(active) surface:SetOverlayVisible('resources', active) end
        Tooltip.AddControlTooltipManual(self.ResourceToggle.Bg, "Mass & hydrocarbon", "Show or hide the mass and hydrocarbon deposit icons.")

        -- water defaults OFF (the surface's dummy mask starts hidden); sync the toggle's look
        self.WaterToggle = PreviewTool(self, WaterIcon, true)
        self.WaterToggle:SetActive(false)
        self.WaterToggle.OnToggle = function(active) surface:SetOverlayVisible('water', active) end
        Tooltip.AddControlTooltipManual(self.WaterToggle.Bg, "Water", "Show or hide the water (placeholder).")

        -- host-only action: open the map-select dialog to change the scenario
        self.ConfigButton = PreviewTool(self, ConfigIcon, false)
        self.ConfigButton.OnPress = function() CustomLobbyMapSelect.Open(GetFrame(0)) end
        Tooltip.AddControlTooltipManual(self.ConfigButton.Bg, "Change map", "Pick a different scenario (host only).")
        --#endregion

        -- count badges for the tab strip: computed LazyVars over the launch model (the tabs
        -- container observes them and renders the grey pills). Built before the tabs so each
        -- button can subscribe at creation.
        local launch = CustomLobbyLaunchModel.GetSingleton()

        self.OptionsBadge = self.Trash:Add(LazyVarCreate())
        self.OptionsBadge:Set(function()
            local count = OptionUtil.CountNonDefault(launch.ScenarioFile(), launch.GameMods(), launch.GameOptions())
            return count > 0 and tostring(count) or ""
        end)

        -- "sim / ui" — sim mods are the synced GameMods; UI mods are this peer's prefs (not a
        -- reactive field, so the count refreshes whenever the sim mods change, which is good enough
        -- until the mod-select dialog is rewired).
        self.ModsBadge = self.Trash:Add(LazyVarCreate())
        self.ModsBadge:Set(function()
            local sim = table.getsize(launch.GameMods())
            local ui = table.getsize(ModUtilities.GetSelectedUIMods())
            if sim == 0 and ui == 0 then
                return ""
            end
            return sim .. " / " .. ui
        end)

        -- the count of active unit restrictions (preset keys in the launch model's Restrictions)
        self.RestrictionsBadge = self.Trash:Add(LazyVarCreate())
        self.RestrictionsBadge:Set(function()
            local count = table.getn(launch.Restrictions())
            return count > 0 and tostring(count) or ""
        end)

        -- the read-only config tabs below the preview (created-on-select / destroyed-on-switch),
        -- each with a config gear (inside the tab, left of the label) opening that tab's editor.
        -- Options + Restrictions are host-only — their gears hide for clients (the host gate is the
        -- IsHost LazyVar); Mods is open to everyone (UI mods are local, the sim portion is host-gated
        -- in the dialog).
        local isHost = CustomLobbyLocalModel.GetSingleton().IsHost
        self.Tabs = CustomLobbyTabs.Create(self, {
            Tabs = {
                {
                    Label = "Options", Create = CustomLobbyOptionsPanel.Create, Badge = self.OptionsBadge,
                    Action = GearAction(function() CustomLobbyOptionSelect.Open(GetFrame(0)) end,
                        "Edit options", "Open the game options editor (host only).", isHost),
                },
                {
                    Label = "Mods", Create = CustomLobbyModsPanel.Create, Badge = self.ModsBadge,
                    Action = GearAction(function() CustomLobbyModSelect.Open(GetFrame(0)) end,
                        "Manage mods", "Pick the game's sim mods (host) and your own UI mods."),
                },
                {
                    Label = "Restrictions", Create = CustomLobbyUnitsPanel.Create, Badge = self.RestrictionsBadge,
                    Action = GearAction(function() CustomLobbyUnitSelect.Open(GetFrame(0)) end,
                        "Edit restrictions", "Pick the units and presets to restrict (host only).", isHost),
                },
            },
        })

        self.ScenarioObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLaunchModel.GetSingleton().ScenarioFile, function(scenarioFileLazy)
                scenarioFileLazy()
                self:RefreshFacts()
            end))
        -- the change-map button is host-only (the gears are gated per-tab via their Visible LazyVar)
        self.IsHostObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyLocalModel.GetSingleton().IsHost, function(isHostLazy)
                if isHostLazy() then
                    self.ConfigButton:Show()
                else
                    self.ConfigButton:Hide()
                end
            end))
    end,

    ---@param self UICustomLobbyConfigInterface
    __post_init = function(self)
        -- the tool strip: a right-aligned vertical column of square buttons; the three toggles stack
        -- from the top, the config button is pinned at the bottom (aligned with the preview's base)
        local function placeTool(tool)
            return Layouter(tool):AtRightIn(self, Inset):Width(ToolSize):Height(ToolSize)
        end
        placeTool(self.ArmyToggle):AtTopIn(self, Inset):End()
        placeTool(self.ResourceToggle):AnchorToBottom(self.ArmyToggle, ToolGap):End()
        placeTool(self.WaterToggle):AnchorToBottom(self.ResourceToggle, ToolGap):End()
        placeTool(self.ConfigButton):End()
        self.ConfigButton.Top:Set(function() return self.Preview.Bottom() - LayoutHelpers.ScaleNumber(ToolSize) end)

        -- the square preview fills the column from the left inset up to the tool strip
        Layouter(self.Preview):AtLeftIn(self, Inset):AtTopIn(self, Inset):End()
        self.Preview.Right:Set(function() return self.ArmyToggle.Left() - LayoutHelpers.ScaleNumber(ToolGap) end)
        self.Preview.Height:Set(function() return self.Preview.Width() end)

        Layouter(self.Name):AtHorizontalCenterIn(self.Preview):AnchorToBottom(self.Preview, 8):End()
        Layouter(self.Info):AtHorizontalCenterIn(self.Preview):AnchorToBottom(self.Name, 2):End()

        -- the tabs fill the rest of the column below the facts line
        Layouter(self.Tabs)
            :AtLeftIn(self):AtRightIn(self)
            :AnchorToBottom(self.Info, 8):AtBottomIn(self)
            :End()
    end,

    --- Three-phase init: the interface calls this after sizing the column. Forwards to the tabs
    --- container (its first panel's grid needs a concrete height) and renders the first facts line.
    ---@param self UICustomLobbyConfigInterface
    Initialize = function(self)
        self:RefreshFacts()
        self.Tabs:Initialize()
    end,

    --- Renders the map name + the size · players · version facts line for the current scenario.
    ---@param self UICustomLobbyConfigInterface
    RefreshFacts = function(self)
        local scenarioFile = CustomLobbyLaunchModel.GetSingleton().ScenarioFile()
        local info = scenarioFile and CustomLobbyMapCatalog.LoadInfo(scenarioFile)
        if type(info) == "table" then
            self.Name:SetText(Truncate(LOC(info.name) or "?", NameMaxChars))
            local parts = {}
            if info.size then
                table.insert(parts, string.format("%dkm", math.floor(info.size[1] / 50)))
            end
            local players = ArmyCount(info)
            if players > 0 then
                table.insert(parts, players .. " players")
            end
            if info.map_version then
                table.insert(parts, "v" .. tostring(info.map_version))
            end
            self.Info:SetText(table.concat(parts, "   ·   "))
        else
            self.Name:SetText(scenarioFile and "Unknown map" or "No map selected")
            self.Info:SetText("")
        end
    end,

    ---@param self UICustomLobbyConfigInterface
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

--- Builds the right-column config composition. The parent sizes it and calls `Initialize()` after
--- mounting (three-phase init).
---@param parent Control
---@return UICustomLobbyConfigInterface
Create = function(parent)
    return CustomLobbyConfigInterface(parent)
end
