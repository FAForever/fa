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

-- The map-select dialog: a searchable, filterable list of scenarios with a preview + info, and
-- Random / Select / Cancel.
--
-- Layout is organised into labelled *areas* (Group containers) — title, left (filters +
-- selection + stats), preview (right), and actions (bottom). Flip the module-level `Debug` flag
-- to tint each area so the regions are visible while iterating on layout.
--
-- It is a transient picker, NOT a persistent model component:
--   * it subscribes to the catalog (CustomLobbyMapCatalog), which streams maps in across frames,
--   * it previews the *highlighted candidate* (decoupled from the launch model) via the shared
--     MapPreview control, and
--   * on Select it calls the controller intent `RequestSetScenario(file)` — the same path a
--     `/map <name>` chat command would use. It owns no synced state.
--
-- This is the first sub-dialog split out of the legacy `dialogs/mapselect.lua` god-dialog: map
-- selection ONLY (options / mods / units become their own components).
--
-- The selection list is text-only — per-row map-preview thumbnails leaked GPU/CPU memory the
-- game needs in-match (the engine never frees MapPreview textures), so only the single candidate
-- preview on the right renders one.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Prefs = import("/lua/user/prefs.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local Combo = import("/lua/ui/controls/combo.lua").Combo
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

-- still borrowed from MapUtil: the save-file loader + start-position extraction (file/geometry
-- primitives, same category as the catalog's LoadScenarioInfoFile)
local MapUtil = import("/lua/ui/maputil.lua")

local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/mapselect/customlobbymapcatalog.lua")
local CustomLobbyMapList = import("/lua/ui/lobby/customlobby/mapselect/customlobbymaplist.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

local DialogWidth = 720
local DialogHeight = 620
local Pad = 12
local ColumnGap = 30      -- whitespace separating the left column from the preview column
local LeftWidth = 300
local PreviewSize = 300
local TitleHeight = 32
local ActionHeight = 48
local FilterHeight = 134
local StatsHeight = 22

-- the same resource/wreck icons the in-lobby map preview uses (CustomLobbyMapPreview)
local MassIcon = "/game/build-ui/icon-mass_bmp.dds"
local EnergyIcon = "/game/build-ui/icon-energy_bmp.dds"
local WreckIcon = "/scx_menu/lan-game-lobby/mappreview/wreckage.dds"

local PrefsKey = "customlobby_mapselect"

-- Filter dropdowns. The first entry is the "no filter" option; `value` matches the scenario
-- (size = `scenarioInfo.size[1]` ogrids; players = number of start spots).
local SizeFilters = {
    { label = "Any size", value = false },
    { label = "5 km",  value = 256 },
    { label = "10 km", value = 512 },
    { label = "20 km", value = 1024 },
    { label = "40 km", value = 2048 },
    { label = "81 km", value = 4096 },
}

local PlayerFilters = { { label = "Any", value = false } }
for n = 2, 16 do
    table.insert(PlayerFilters, { label = tostring(n), value = n })
end

-- comparison operators applied to the size / player filters
local Operators = { "=", ">=", "<=" }

-- Map web pages we'll open in a browser (some scenarios carry a `url`). Matched against the
-- URL's host — exact or as a subdomain — so "faforever.com" also covers "forums.faforever.com".
-- Add a line to extend.
local AllowedUrlDomains = {
    "github.com",
    "githubusercontent.com",
    "gitlab.com",
    "github.io",
    "faforever.com",
}

--- The lowercased host of a URL (between the scheme and the first `/` or `:`), or "".
---@param url string
---@return string
local function UrlHost(url)
    local rest = string.gsub(string.lower(url), "^https?://", "")
    return (string.gsub(rest, "[/:].*$", ""))
end

--- Whether `url` is an http(s) link to an allowed domain (or a subdomain of one). Guards
--- against look-alikes ("github.com.evil.com" is rejected) by matching the host suffix.
---@param url any
---@return boolean
local function IsAllowedUrl(url)
    if type(url) ~= 'string' or not string.find(string.lower(url), "^https?://") then
        return false
    end
    local host = UrlHost(url)
    for _, domain in AllowedUrlDomains do
        local escaped = string.gsub(domain, "%.", "%%.")
        if host == domain or string.find(host, "%." .. escaped .. "$") then
            return true
        end
    end
    return false
end

--- Pulls the `.label` column out of a filter table for `Combo:AddItems`.
---@param filters table[]
---@return string[]
local function FilterLabels(filters)
    local labels = {}
    for i, filter in filters do
        labels[i] = filter.label
    end
    return labels
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

--- Applies a comparison operator. A nil/false target means "no filter" → always passes.
---@param value number
---@param op string
---@param target number | false
---@return boolean
local function PassesComparison(value, op, target)
    if not target then
        return true
    end
    if op == ">=" then
        return value >= target
    elseif op == "<=" then
        return value <= target
    end
    return value == target
end

--- Clamps a stored combo index to a table's range (defaults to 1).
---@param index any
---@param options table[]
---@return number
local function ClampIndex(index, options)
    if type(index) ~= 'number' or index < 1 or index > table.getn(options) then
        return 1
    end
    return index
end

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

---@class UICustomLobbyMapSelect : Group
---@field Trash TrashBag
---@field OverlayTrash TrashBag
---@field TitleArea Group
---@field LeftArea Group
---@field FilterArea Group
---@field SelectionArea Group
---@field StatsArea Group
---@field PreviewArea Group
---@field ActionArea Group
---@field Title Text
---@field FilterTitle Text
---@field Search Edit
---@field SizeLabel Text
---@field SizeCombo Combo
---@field SizeOpCombo Combo
---@field PlayersLabel Text
---@field PlayersCombo Combo
---@field PlayersOpCombo Combo
---@field SizeFilter number | false
---@field SizeOp string
---@field PlayerFilter number | false
---@field PlayerOp string
---@field SizeIndex number
---@field SizeOpIndex number
---@field PlayerIndex number
---@field PlayerOpIndex number
---@field MapList UICustomLobbyMapList
---@field EmptyLabel Text
---@field SpawnsToggle Checkbox
---@field ResourcesToggle Checkbox
---@field WrecksToggle Checkbox
---@field ShowSpawns boolean
---@field ShowResources boolean
---@field ShowWrecks boolean
---@field SpawnIcons Control[]
---@field ResourceIcons Control[]
---@field WreckIcons Control[]
---@field Preview MapPreview
---@field PreviewBg Bitmap
---@field MassTemplate Bitmap                  # hidden; overlay icons share its texture (loaded once)
---@field EnergyTemplate Bitmap
---@field WreckTemplate Bitmap
---@field PreviewTitleBar Bitmap
---@field PreviewTitle Text
---@field InfoMeta Text
---@field Warning Text
---@field Description TextArea
---@field UrlButton Text
---@field CurrentUrl string | false
---@field RandomButton Button
---@field SelectButton Button
---@field CancelButton Button
---@field CountLabel Text
---@field Spinner Text
---@field OnConfirmCb fun(scenarioFile: FileName)
---@field OnCancelCb fun()
---@field ScenariosObserver LazyVar
---@field Scenarios UILobbyScenarioInfo[]
---@field Filtered UILobbyScenarioInfo[]
---@field Selected? UILobbyScenarioInfo
---@field LastInspected? UILobbyScenarioInfo
---@field CurrentFile FileName | false
---@field Ready boolean
local CustomLobbyMapSelect = ClassUI(Group) {

    ---@param self UICustomLobbyMapSelect
    ---@param parent Control
    ---@param onConfirm fun(scenarioFile: FileName)
    ---@param onCancel fun()
    __init = function(self, parent, onConfirm, onCancel)
        Group.__init(self, parent, "CustomLobbyMapSelect")

        self.Trash = TrashBag()
        self.OverlayTrash = self.Trash:Add(TrashBag())
        self.OnConfirmCb = onConfirm
        self.OnCancelCb = onCancel

        self.Ready = false
        self.Filtered = {}
        self.Selected = nil
        self.ShowSpawns = true
        self.ShowResources = false
        self.ShowWrecks = false
        self.SpawnIcons = {}
        self.ResourceIcons = {}
        self.WreckIcons = {}
        self.CurrentFile = CustomLobbyLaunchModel.GetSingleton().ScenarioFile()
        self.Scenarios = CustomLobbyMapCatalog.GetScenarios()

        -- restore the last-used filters + search (persisted across opens)
        local saved = Prefs.GetFromCurrentProfile(PrefsKey) or {}
        self.SizeIndex = ClampIndex(saved.sizeIndex, SizeFilters)
        self.SizeOpIndex = ClampIndex(saved.sizeOpIndex, Operators)
        self.PlayerIndex = ClampIndex(saved.playersIndex, PlayerFilters)
        self.PlayerOpIndex = ClampIndex(saved.playersOpIndex, Operators)
        self.SizeFilter = SizeFilters[self.SizeIndex].value
        self.SizeOp = Operators[self.SizeOpIndex]
        self.PlayerFilter = PlayerFilters[self.PlayerIndex].value
        self.PlayerOp = Operators[self.PlayerOpIndex]

        -- areas
        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.LeftArea = CreateArea(self, "LeftArea", 'ff4060cc')
        self.FilterArea = CreateArea(self.LeftArea, "FilterArea", 'ff40cc60')
        self.SelectionArea = CreateArea(self.LeftArea, "SelectionArea", 'ffcccc40')
        self.StatsArea = CreateArea(self.LeftArea, "StatsArea", 'ff40cccc')
        self.PreviewArea = CreateArea(self, "PreviewArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Select scenario", 22, UIUtil.titleFont)

        --#region filters (in FilterArea)
        self.FilterTitle = UIUtil.CreateText(self.FilterArea, "Filter", 14, UIUtil.titleFont)

        self.Search = Edit(self.FilterArea)
        Layouter(self.Search):Left(0):Top(0):Width(96):Height(22):End()
        self.Search:SetFont(UIUtil.bodyFont, 16)
        self.Search:SetForegroundColor(UIUtil.fontColor)
        self.Search:ShowBackground(true)
        self.Search:SetBackgroundColor('77778888')
        self.Search:SetText(saved.search or "")
        self.Search.OnTextChanged = function(control, newText, oldText)
            self:Populate()
            self:SavePrefs()
        end
        self.Search.OnEnterPressed = function(control, text)
            self:Confirm()
            return true
        end
        Tooltip.AddControlTooltipManual(self.Search, "Search", "Filter the list by map name.")

        self.SizeLabel = UIUtil.CreateText(self.FilterArea, "Size", 13, UIUtil.bodyFont)
        self.SizeLabel:SetColor('ff9aa0a8')
        self.SizeCombo, self.SizeOpCombo = self:CreateFilterRow(
            SizeFilters, self.SizeIndex, self.SizeOpIndex,
            function(index) self.SizeIndex = index; self.SizeFilter = SizeFilters[index].value end,
            function(index) self.SizeOpIndex = index; self.SizeOp = Operators[index] end,
            "Map size", "Filter by map dimensions, with a comparison operator.")

        self.PlayersLabel = UIUtil.CreateText(self.FilterArea, "Players", 13, UIUtil.bodyFont)
        self.PlayersLabel:SetColor('ff9aa0a8')
        self.PlayersCombo, self.PlayersOpCombo = self:CreateFilterRow(
            PlayerFilters, self.PlayerIndex, self.PlayerOpIndex,
            function(index) self.PlayerIndex = index; self.PlayerFilter = PlayerFilters[index].value end,
            function(index) self.PlayerOpIndex = index; self.PlayerOp = Operators[index] end,
            "Player count", "Filter by number of start positions, with a comparison operator.")
        --#endregion

        --#region selection list + stats
        self.MapList = CustomLobbyMapList.Create(self.SelectionArea)
        self.MapList.OnSelect = function(scenario, index)
            self:OnMapSelected(scenario)
        end
        self.MapList.OnConfirm = function(scenario)
            self:OnMapSelected(scenario)
            self:Confirm()
        end

        self.EmptyLabel = UIUtil.CreateText(self.SelectionArea, "No maps match", 14, UIUtil.bodyFont)
        self.EmptyLabel:SetColor('ff8a909a')
        self.EmptyLabel:DisableHitTest()
        self.EmptyLabel:Hide()

        self.CountLabel = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.CountLabel:SetColor('ff9aa0a8')
        self.Spinner = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.Spinner:SetColor('ff9aa0a8')
        --#endregion

        --#region preview area (toggles, preview, info, description)
        self.SpawnsToggle = self:CreateToggle("Spawns", self.ShowSpawns,
            function(checked) self.ShowSpawns = checked; self:ApplyOverlayVisibility() end,
            "Spawns", "Show the start positions.")
        self.ResourcesToggle = self:CreateToggle("Resources", self.ShowResources,
            function(checked) self.ShowResources = checked; self:ApplyOverlayVisibility() end,
            "Resources", "Show mass and hydrocarbon deposits.")
        self.WrecksToggle = self:CreateToggle("Wrecks", self.ShowWrecks,
            function(checked) self.ShowWrecks = checked; self:ApplyOverlayVisibility() end,
            "Wrecks", "Show prebuilt wreckage (if the map defines any).")

        self.PreviewBg = Bitmap(self.PreviewArea)
        self.PreviewBg:SetSolidColor('ff000000')
        self.PreviewBg:DisableHitTest()
        self.Preview = MapPreview(self.PreviewArea)

        -- hidden template bitmaps: each overlay texture is loaded ONCE here, then every marker
        -- shares it via ShareTextures (see CreateMarkerIcon) rather than re-loading per icon.
        -- They still need a concrete (dummy) position — an unanchored control's Left/Right
        -- reference each other and trip the circular-evaluation guard (see /lua/ui/CLAUDE.md § 1).
        self.MassTemplate = self:CreateTemplateBitmap(MassIcon)
        self.EnergyTemplate = self:CreateTemplateBitmap(EnergyIcon)
        self.WreckTemplate = self:CreateTemplateBitmap(WreckIcon)

        self.PreviewTitleBar = Bitmap(self.PreviewArea)
        self.PreviewTitleBar:SetSolidColor('aa0a0e12')
        self.PreviewTitleBar:DisableHitTest()
        self.PreviewTitle = UIUtil.CreateText(self.PreviewArea, "", 16, UIUtil.titleFont)
        self.PreviewTitle:DisableHitTest()

        -- clickable "open page" link in the title bar; shown only when the map has an allowed url
        self.CurrentUrl = false
        self.UrlButton = UIUtil.CreateText(self.PreviewArea, "Open page", 12, UIUtil.bodyFont)
        self.UrlButton:SetColor('ff7fb3ff')
        self.UrlButton:Hide()
        self.UrlButton.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.CurrentUrl then
                    OpenURL(self.CurrentUrl)
                end
                return true
            elseif event.Type == 'MouseEnter' then
                control:SetColor('ffaecbff')
                return true
            elseif event.Type == 'MouseExit' then
                control:SetColor('ff7fb3ff')
                return true
            end
            return false
        end
        Tooltip.AddControlTooltipManual(self.UrlButton, "Map page", "Open the map's web page in your browser.")

        self.InfoMeta = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.InfoMeta:SetColor('ffc8ccd0')
        self.Warning = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.Warning:SetColor('ffff6b6b')

        self.Description = TextArea(self.PreviewArea, 200, 80)
        self.Description:SetFont(UIUtil.bodyFont, 12)
        self.Description:SetColors('ff8a909a', "00000000", 'ff8a909a', "00000000")
        self.Description:SetTextAlignment(0.5)   -- centre each line, matching the info above
        --#endregion

        --#region actions
        self.RandomButton = UIUtil.CreateButtonStd(self, '/scx_menu/small-btn/small', "<LOC lobui_0501>Random", 16, 2)
        self.RandomButton.OnClick = function(button, modifiers)
            self:PickRandom()
        end
        Tooltip.AddControlTooltipManual(self.RandomButton, "Random", "Pick a random map from the current filtered list.")

        self.SelectButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Select>Select", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers)
            self:Confirm()
        end

        self.CancelButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Cancel>Cancel", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers)
            self.OnCancelCb()
        end
        --#endregion

        self.ScenariosObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyMapCatalog.GetScenariosVar(), function(scenariosLazy)
                self:OnScenariosChanged(scenariosLazy())
            end))

        CustomLobbyMapCatalog.EnsureLoaded()

        -- spin a small throbber beside the count while the catalog is still streaming
        self.Trash:Add(ForkThread(function()
            local frames = { "|", "/", "-", "\\" }
            local i = 1
            while not CustomLobbyMapCatalog.IsLoaded() do
                if IsDestroyed(self) then
                    return
                end
                self.Spinner:SetText(frames[i])
                i = math.mod(i, 4) + 1
                WaitSeconds(0.12)
            end
            if not IsDestroyed(self) then
                self.Spinner:SetText("")
            end
        end))
    end,

    ---@param self UICustomLobbyMapSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        --#region areas
        Layouter(self.TitleArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtTopIn(self, Pad):Height(TitleHeight):End()
        Layouter(self.ActionArea):AtLeftIn(self, Pad):AtRightIn(self, Pad):AtBottomIn(self, Pad):Height(ActionHeight):End()
        Layouter(self.LeftArea)
            :AtLeftIn(self, Pad):Width(LeftWidth)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()
        Layouter(self.PreviewArea)
            :AnchorToRight(self.LeftArea, ColumnGap):AtRightIn(self, Pad)
            :AnchorToBottom(self.TitleArea, Pad):AnchorToTop(self.ActionArea, Pad)
            :End()

        Layouter(self.FilterArea):AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea):AtTopIn(self.LeftArea):Height(FilterHeight):End()
        Layouter(self.StatsArea):AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea):AtBottomIn(self.LeftArea):Height(StatsHeight):End()
        Layouter(self.SelectionArea)
            :AtLeftIn(self.LeftArea):AtRightIn(self.LeftArea)
            :AnchorToBottom(self.FilterArea, Pad):AnchorToTop(self.StatsArea, Pad)
            :End()
        --#endregion

        Layouter(self.Title):AtHorizontalCenterIn(self.TitleArea):AtVerticalCenterIn(self.TitleArea):End()

        --#region filters
        Layouter(self.FilterTitle):AtLeftIn(self.FilterArea):AtTopIn(self.FilterArea):End()
        Layouter(self.Search):AtLeftIn(self.FilterArea):AtRightIn(self.FilterArea):AnchorToBottom(self.FilterTitle, 8):Height(22):End()

        Layouter(self.SizeCombo):AtLeftIn(self.FilterArea, 56):AnchorToBottom(self.Search, 12):Width(110):End()
        Layouter(self.SizeLabel):AtLeftIn(self.FilterArea):AtVerticalCenterIn(self.SizeCombo):End()
        Layouter(self.SizeOpCombo):AnchorToRight(self.SizeCombo, 8):AtVerticalCenterIn(self.SizeCombo):Width(56):End()

        Layouter(self.PlayersCombo):AtLeftIn(self.FilterArea, 56):AnchorToBottom(self.SizeCombo, 10):Width(110):End()
        Layouter(self.PlayersLabel):AtLeftIn(self.FilterArea):AtVerticalCenterIn(self.PlayersCombo):End()
        Layouter(self.PlayersOpCombo):AnchorToRight(self.PlayersCombo, 8):AtVerticalCenterIn(self.PlayersCombo):Width(56):End()
        --#endregion

        --#region selection list + stats
        Layouter(self.MapList):AtLeftIn(self.SelectionArea):AtTopIn(self.SelectionArea):AtBottomIn(self.SelectionArea):End()
        self.MapList.Right:Set(function() return self.SelectionArea.Right() - LayoutHelpers.ScaleNumber(32) end)
        Layouter(self.EmptyLabel):AtHorizontalCenterIn(self.SelectionArea):AtVerticalCenterIn(self.SelectionArea):End()

        Layouter(self.CountLabel):AtLeftIn(self.StatsArea):AtVerticalCenterIn(self.StatsArea):End()
        Layouter(self.Spinner):AnchorToRight(self.CountLabel, 8):AtVerticalCenterIn(self.StatsArea):End()
        --#endregion

        --#region preview area
        -- overlay toggles centred above the preview
        Layouter(self.ResourcesToggle):AtHorizontalCenterIn(self.PreviewArea):AtTopIn(self.PreviewArea):End()
        Layouter(self.SpawnsToggle):AnchorToLeft(self.ResourcesToggle, 16):AtVerticalCenterIn(self.ResourcesToggle):End()
        Layouter(self.WrecksToggle):AnchorToRight(self.ResourcesToggle, 16):AtVerticalCenterIn(self.ResourcesToggle):End()

        Layouter(self.Preview)
            :AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.ResourcesToggle, 10)
            :Width(PreviewSize):Height(PreviewSize)
            :End()
        Layouter(self.PreviewBg):Fill(self.Preview):End()
        self.PreviewBg.Depth:Set(function() return self.Preview.Depth() - 1 end)

        -- map name overlaid across the top of the preview
        Layouter(self.PreviewTitleBar):AtLeftIn(self.Preview):AtRightIn(self.Preview):AtTopIn(self.Preview):Height(26):End()
        self.PreviewTitleBar.Depth:Set(function() return self.Preview.Depth() + 20 end)
        Layouter(self.PreviewTitle):AtHorizontalCenterIn(self.Preview):AtVerticalCenterIn(self.PreviewTitleBar):End()
        self.PreviewTitle.Depth:Set(function() return self.PreviewTitleBar.Depth() + 1 end)

        -- url link on the right of the title bar (shown only when the map has an allowed url)
        Layouter(self.UrlButton):AtRightIn(self.Preview, 8):AtVerticalCenterIn(self.PreviewTitleBar):End()
        self.UrlButton.Depth:Set(function() return self.PreviewTitleBar.Depth() + 2 end)

        -- info centred under the preview
        Layouter(self.InfoMeta):AtHorizontalCenterIn(self.Preview):AnchorToBottom(self.Preview, 12):End()
        Layouter(self.Warning):AtHorizontalCenterIn(self.Preview):AnchorToBottom(self.InfoMeta, 4):End()

        -- description sits under the preview, exactly as wide as the map (so it reads as
        -- centred, since the preview is centred in its column); scrolls when it overflows
        Layouter(self.Description)
            :AtLeftIn(self.Preview):AnchorToBottom(self.Warning, 10):AtBottomIn(self.PreviewArea)
            :End()
        self.Description.Right:Set(function() return self.Preview.Right() end)
        UIUtil.CreateVertScrollbarFor(self.Description)
        --#endregion

        --#region actions
        Layouter(self.CancelButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.SelectButton):AnchorToLeft(self.CancelButton, 12):AtVerticalCenterIn(self.ActionArea):End()
        -- Random: horizontally centred under the left area, vertically centred in the actions
        Layouter(self.RandomButton):AtHorizontalCenterIn(self.LeftArea):AtVerticalCenterIn(self.ActionArea):End()
        --#endregion

        self.MapList:AcquireKeyboardFocus(true)
    end,

    --- Builds a value-combo + comparison-operator-combo pair in the filter area. Returns both.
    ---@param self UICustomLobbyMapSelect
    ---@param values table[]
    ---@param valueIndex number
    ---@param opIndex number
    ---@param onValue fun(index: number)
    ---@param onOp fun(index: number)
    ---@param tooltipTitle string
    ---@param tooltipBody string
    ---@return Combo valueCombo
    ---@return Combo opCombo
    CreateFilterRow = function(self, values, valueIndex, opIndex, onValue, onOp, tooltipTitle, tooltipBody)
        local valueCombo = Combo(self.FilterArea, 14, 8, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        valueCombo:AddItems(FilterLabels(values), valueIndex)
        valueCombo.OnClick = function(combo, index, text)
            onValue(index)
            self:Populate()
            self:SavePrefs()
        end
        Tooltip.AddControlTooltipManual(valueCombo, tooltipTitle, tooltipBody)

        local opCombo = Combo(self.FilterArea, 14, 3, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        opCombo:AddItems(Operators, opIndex)
        opCombo.OnClick = function(combo, index, text)
            onOp(index)
            self:Populate()
            self:SavePrefs()
        end
        Tooltip.AddControlTooltipManual(opCombo, tooltipTitle, "Comparison operator (=, at least, at most).")

        return valueCombo, opCombo
    end,

    --- Builds a labelled checkbox "switch" wired to `onChange(checked)`, with a tooltip.
    ---@param self UICustomLobbyMapSelect
    ---@param label string
    ---@param initial boolean
    ---@param onChange fun(checked: boolean)
    ---@param tooltipTitle string
    ---@param tooltipBody string
    ---@return Checkbox
    CreateToggle = function(self, label, initial, onChange, tooltipTitle, tooltipBody)
        local checkbox = UIUtil.CreateCheckbox(self.PreviewArea, '/CHECKBOX/', label, true, 13)
        checkbox:SetCheck(initial, true)
        checkbox.OnCheck = function(control, checked)
            onChange(checked)
        end
        Tooltip.AddControlTooltipManual(checkbox, tooltipTitle, tooltipBody)
        return checkbox
    end,

    --- Builds the list pool + populates. Called by the opener after the dialog is mounted +
    --- centred by Popup (three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyMapSelect
    Initialize = function(self)
        self.Ready = true
        self.MapList:Initialize()
        self:Populate()
    end,

    --- The catalog published a new (possibly larger) map list: recount always, and re-list
    --- once we're mounted.
    ---@param self UICustomLobbyMapSelect
    ---@param scenarios UILobbyScenarioInfo[]
    OnScenariosChanged = function(self, scenarios)
        self.Scenarios = scenarios
        if self.Ready then
            self:Populate()
        else
            self:UpdateCount()
        end
    end,

    --- Updates the footer: "X of Y maps" when a filter/search narrows it, else "Y maps".
    ---@param self UICustomLobbyMapSelect
    UpdateCount = function(self)
        local total = table.getn(self.Scenarios)
        local shown = table.getn(self.Filtered)
        if self.Ready and shown < total then
            self.CountLabel:SetText(LOCF("%d of %d maps", shown, total))
        else
            self.CountLabel:SetText(LOCF("%d maps", total))
        end
    end,

    --- Persists the current filters + search for next time.
    ---@param self UICustomLobbyMapSelect
    SavePrefs = function(self)
        Prefs.SetToCurrentProfile(PrefsKey, {
            sizeIndex = self.SizeIndex,
            sizeOpIndex = self.SizeOpIndex,
            playersIndex = self.PlayerIndex,
            playersOpIndex = self.PlayerOpIndex,
            search = self.Search:GetText() or "",
        })
    end,

    --- Rebuilds the list from the catalog, applying the name search + size/player filters and
    --- keeping the current highlight selected (falling back to the lobby's active map).
    ---@param self UICustomLobbyMapSelect
    Populate = function(self)
        local search = string.lower(self.Search:GetText() or "")
        local targetFile = (self.Selected and self.Selected.file) or self.CurrentFile
        local target = targetFile and string.lower(targetFile)

        self.Filtered = {}
        local selectedRow = 0

        for _, scenario in self.Scenarios do
            local matchesName = search == "" or string.find(string.lower(scenario.name), search, 1, true)
            if matchesName and self:PassesFilters(scenario) then
                table.insert(self.Filtered, scenario)
                if target and string.lower(scenario.file) == target then
                    selectedRow = table.getn(self.Filtered)
                end
            end
        end

        self.MapList:SetItems(self.Filtered)

        if table.getn(self.Filtered) > 0 then
            self.EmptyLabel:Hide()
            local row = selectedRow > 0 and selectedRow or 1
            self.MapList:SetSelection(row)
            self.MapList:ShowItem(row)
            self:OnMapSelected(self.Filtered[row])
        else
            self.EmptyLabel:Show()
            self.Selected = nil
            self:ClearDetails()
            self.SelectButton:Disable()
            self.RandomButton:Disable()
        end

        self:UpdateCount()
    end,

    --- Whether a scenario passes the size + player-count filters (with their comparators).
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    ---@return boolean
    PassesFilters = function(self, scenario)
        local size = scenario.size and scenario.size[1] or 0
        if not PassesComparison(size, self.SizeOp, self.SizeFilter) then
            return false
        end
        if not PassesComparison(ArmyCount(scenario), self.PlayerOp, self.PlayerFilter) then
            return false
        end
        return true
    end,

    --- Highlights a random map from the current filtered set (leaves confirming to the user).
    ---@param self UICustomLobbyMapSelect
    PickRandom = function(self)
        local count = table.getn(self.Filtered)
        if count == 0 then
            return
        end
        local row = math.random(1, count)
        self.MapList:SetSelection(row)
        self.MapList:ShowItem(row)
        self:OnMapSelected(self.Filtered[row])
    end,

    --- A map was selected: make it the candidate and refresh the preview + info.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    OnMapSelected = function(self, scenario)
        if not scenario then
            return
        end
        self.Selected = scenario
        if self.LastInspected ~= scenario then
            self.LastInspected = scenario
            self:Inspect(scenario)
        end
    end,

    --- Loads what's needed to show a candidate: preview texture + overlays, info, and a
    --- file-health check that gates Select.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    Inspect = function(self, scenario)
        self.OverlayTrash:Destroy()
        self.SpawnIcons = {}
        self.ResourceIcons = {}
        self.WreckIcons = {}

        if not self.Preview:SetTexture(scenario.preview) then
            self.Preview:SetTextureFromMap(scenario.map)
        end

        local problems = {}
        if not DiskGetFileInfo(scenario.map) then
            table.insert(problems, "map missing")
        end
        if not DiskGetFileInfo(scenario.script) then
            table.insert(problems, "script missing")
        end

        local save = nil
        if DiskGetFileInfo(scenario.save) then
            save = MapUtil.LoadScenarioSaveFile(scenario.save)
        else
            table.insert(problems, "save missing")
        end

        if save and scenario.size then
            self:BuildSpawns(scenario, save)
            self:BuildResources(scenario, save)
            self:BuildWrecks(scenario, save)
            self:ApplyOverlayVisibility()
        end

        self:UpdateInfo(scenario)
        self.RandomButton:Enable()

        if table.getn(problems) > 0 then
            self.Warning:SetText("! " .. table.concat(problems, ", "))
            self.SelectButton:Disable()
        else
            self.Warning:SetText("")
            self.SelectButton:Enable()
        end
    end,

    --- Fills the title overlay + info line (size · players · version), the url link, and the
    --- description.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    UpdateInfo = function(self, scenario)
        self.PreviewTitle:SetText(LOC(scenario.name) or "?")

        local parts = {}
        if scenario.size then
            table.insert(parts, string.format("%dkm x %dkm",
                math.floor(scenario.size[1] / 50), math.floor(scenario.size[2] / 50)))
        end
        local players = ArmyCount(scenario)
        if players > 0 then
            table.insert(parts, players .. " players")
        end
        if scenario.map_version then
            table.insert(parts, "v" .. scenario.map_version)
        end
        self.InfoMeta:SetText(table.concat(parts, "   ·   "))

        -- some scenarios carry a `url` to their source/page; offer to open allowed ones
        if scenario.url and IsAllowedUrl(scenario.url) then
            self.CurrentUrl = scenario.url
            self.UrlButton:Show()
        else
            self.CurrentUrl = false
            self.UrlButton:Hide()
        end

        self.Description:SetText(scenario.description and LOC(scenario.description) or "")
    end,

    --- Places numbered start-spot markers on the preview from the save's start positions.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    ---@param save UIScenarioSaveFile
    BuildSpawns = function(self, scenario, save)
        local positions = MapUtil.GetStartPositionsFromScenario(scenario, save)
        if not positions then
            return
        end
        for index, position in positions do
            local dot = self.OverlayTrash:Add(self:CreateSpawnDot(index))
            self:PositionMarker(dot, scenario.size[1], scenario.size[2], position[1], position[2])
            table.insert(self.SpawnIcons, dot)
        end
    end,

    --- Places mass + hydrocarbon icons from the save's master-chain markers.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    ---@param save UIScenarioSaveFile
    BuildResources = function(self, scenario, save)
        for _, marker in self:Markers(save) do
            local template = (marker.type == "Mass" and self.MassTemplate)
                or (marker.type == "Hydrocarbon" and self.EnergyTemplate)
                or false
            if template and marker.position then
                local dot = self.OverlayTrash:Add(self:CreateMarkerIcon(template, 10))
                self:PositionMarker(dot, scenario.size[1], scenario.size[2], marker.position[1], marker.position[3])
                table.insert(self.ResourceIcons, dot)
            end
        end
    end,

    --- Best-effort wreck icons: maps that expose prebuilt wreckage as save markers.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    ---@param save UIScenarioSaveFile
    BuildWrecks = function(self, scenario, save)
        for _, marker in self:Markers(save) do
            if marker.type and marker.position and string.find(string.lower(marker.type), 'wreck') then
                local dot = self.OverlayTrash:Add(self:CreateMarkerIcon(self.WreckTemplate, 11))
                self:PositionMarker(dot, scenario.size[1], scenario.size[2], marker.position[1], marker.position[3])
                table.insert(self.WreckIcons, dot)
            end
        end
    end,

    --- Shows/hides each overlay group according to its toggle.
    ---@param self UICustomLobbyMapSelect
    ApplyOverlayVisibility = function(self)
        local function setVisible(icons, visible)
            for _, icon in icons do
                if visible then
                    icon:Show()
                else
                    icon:Hide()
                end
            end
        end
        setVisible(self.SpawnIcons, self.ShowSpawns)
        setVisible(self.ResourceIcons, self.ShowResources)
        setVisible(self.WreckIcons, self.ShowWrecks)
    end,

    --- The save's master-chain markers, or an empty table.
    ---@param self UICustomLobbyMapSelect
    ---@param save UIScenarioSaveFile
    ---@return table
    Markers = function(self, save)
        local masterChain = save.MasterChain and save.MasterChain['_MASTERCHAIN_']
        return (masterChain and masterChain.Markers) or {}
    end,

    --- Builds a small numbered start-spot marker. Private.
    ---@param self UICustomLobbyMapSelect
    ---@param index number
    ---@return Group
    CreateSpawnDot = function(self, index)
        local dot = Group(self.PreviewArea)
        dot:DisableHitTest()
        dot.Depth:Set(function() return self.Preview.Depth() + 10 end)

        local bg = Bitmap(dot)
        bg:SetSolidColor('cc1c2228')
        bg:DisableHitTest()

        local label = UIUtil.CreateText(dot, tostring(index), 12, UIUtil.bodyFont)
        label:DisableHitTest()

        Layouter(dot):Width(18):Height(18):End()
        Layouter(bg):Fill(dot):End()
        Layouter(label):AtCenterIn(dot):End()
        return dot
    end,

    --- Loads an overlay texture once into a hidden template bitmap that markers share from.
    --- Given a dummy position because an unanchored control's Left/Right are circular. Private.
    ---@param self UICustomLobbyMapSelect
    ---@param texture FileName
    ---@return Bitmap
    CreateTemplateBitmap = function(self, texture)
        local template = UIUtil.CreateBitmap(self.PreviewArea, texture)
        template:DisableHitTest()
        Layouter(template):Left(0):Top(0):Width(8):Height(8):End()
        template:Hide()
        -- lock it hidden: a parent Show() (Popup mounting the dialog) would otherwise reveal
        -- this never-positioned-for-display bitmap. Same trick TexturePool uses for pooled
        -- bitmaps — OnHide returning true keeps it hidden regardless of the parent.
        template.OnHide = function(control, hidden)
            return true
        end
        return template
    end,

    --- Builds a small resource/wreck marker that SHARES its texture with a hidden template
    --- bitmap (allocated once in __init), so the texture is loaded once and reused for every
    --- marker — not re-loaded per icon. Private.
    ---@param self UICustomLobbyMapSelect
    ---@param template Bitmap
    ---@param size number
    ---@return Bitmap
    CreateMarkerIcon = function(self, template, size)
        local icon = UIUtil.CreateBitmapColor(self.PreviewArea, 'ffffff')
        icon:DisableHitTest()
        -- size only (matches CustomLobbyMapPreview's working pattern); PositionMarker pins
        -- Left/Top afterwards, so the size must be set so its centring maths has a real Width
        Layouter(icon):Width(size):Height(size):End()
        icon:ShareTextures(template)
        icon.Depth:Set(function() return self.Preview.Depth() + 5 end)
        return icon
    end,

    --- Positions a marker over the preview at a map coordinate (mirrors the preview's own
    --- aspect-correct placement). Private.
    ---@param self UICustomLobbyMapSelect
    ---@param icon Control
    ---@param mapWidth number
    ---@param mapHeight number
    ---@param px number
    ---@param pz number
    PositionMarker = function(self, icon, mapWidth, mapHeight, px, pz)
        local size = self.Preview.Width()
        local xOffset, xFactor, yOffset, yFactor = 0, 1, 0, 1
        if mapWidth > mapHeight then
            local ratio = mapHeight / mapWidth
            yOffset = ((size / ratio) - size) / 4
            yFactor = ratio
        else
            local ratio = mapWidth / mapHeight
            xOffset = ((size / ratio) - size) / 4
            xFactor = ratio
        end

        local x = xOffset + (px / mapWidth) * (size - 2) * xFactor
        local z = yOffset + (pz / mapHeight) * (size - 2) * yFactor

        icon.Left:Set(function() return self.Preview.Left() + x - 0.5 * icon.Width() end)
        icon.Top:Set(function() return self.Preview.Top() + z - 0.5 * icon.Height() end)
    end,

    --- Clears the preview + info (no candidate / empty list).
    ---@param self UICustomLobbyMapSelect
    ClearDetails = function(self)
        self.LastInspected = nil
        self.OverlayTrash:Destroy()
        self.SpawnIcons = {}
        self.ResourceIcons = {}
        self.WreckIcons = {}
        self.Preview:ClearTexture()
        self.PreviewTitle:SetText("")
        self.InfoMeta:SetText("")
        self.Warning:SetText("")
        self.Description:SetText("")
        self.CurrentUrl = false
        self.UrlButton:Hide()
    end,

    --- Commits the highlighted candidate via the controller intent.
    ---@param self UICustomLobbyMapSelect
    Confirm = function(self)
        if not self.Selected then
            return
        end
        self.OnConfirmCb(self.Selected.file)
    end,

    ---@param self UICustomLobbyMapSelect
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Opens the map-select dialog over `parent` (defaults to the root frame). Confirming sets
--- the scenario through the host-authoritative `RequestSetScenario` intent. Replaces any
--- dialog already open.
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)
    if Instance then
        Instance:Close()
    end

    local popup
    local content = CustomLobbyMapSelect(parent,
        function(scenarioFile)
            CustomLobbyController.RequestSetScenario(scenarioFile)
            if popup then
                popup:Close()
            end
        end,
        function()
            if popup then
                popup:Close()
            end
        end)

    popup = Popup(parent, content)
    local baseOnClosed = popup.OnClosed
    popup.OnClosed = function(self)
        baseOnClosed(self)
        Instance = false
    end
    Instance = popup

    -- now that Popup has mounted + centred the content, it's safe to build the list pool +
    -- populate (both read concrete geometry)
    content:Initialize()
end

--- Closes the dialog if open.
function Close()
    if Instance then
        Instance:Close()
        Instance = false
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Close()
end

--#endregion
