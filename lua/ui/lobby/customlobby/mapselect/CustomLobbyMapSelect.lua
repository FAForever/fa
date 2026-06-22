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
--     CustomLobbyMapPreview, created unbound so this dialog drives it (vs. the in-lobby preview's
--     model binding), here with numbered-dot spawns + a title bar / url link layered on top, and
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
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local Combo = import("/lua/ui/controls/combo.lua").Combo
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local CustomLobbyMapPreview = import("/lua/ui/lobby/customlobby/customlobbymappreview.lua")
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
local PreviewSize = 220   -- square; kept small enough that the title + sections + description fit
                          -- under it in the preview column (DialogHeight) without overflowing
local TitleHeight = 32
local ActionHeight = 48
local FilterHeight = 134
local StatsHeight = 22

-- map-detail presentation (mirrors the in-lobby Map tab — see config/CustomLobbyMapPanel.lua)
local IconSize = 14
local LabelColor = 'ff8a909a'        -- the section labels (Author / Reclaim / Description)
local ValueColor = 'ffc8ccd0'
local MassIcon = "/game/build-ui/icon-mass_bmp.dds"
local EnergyIcon = "/game/build-ui/icon-energy_bmp.dds"

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

--- Downgrades an `https://` URL to `http://` — the engine's `OpenURL` only handles `http://`.
---@param url string
---@return string
local function ToOpenableUrl(url)
    return (string.gsub(url, "^https://", "http://"))
end

--- Shows `scrollbar` only when the TextArea's content is taller than the box it sits in.
---@param textArea TextArea
---@param scrollbar Scrollbar | false
local function UpdateTextAreaScrollbar(textArea, scrollbar)
    if not scrollbar then
        return
    end
    if textArea:GetTextHeight() > textArea.Height() then
        scrollbar:Show()
    else
        scrollbar:Hide()
    end
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

--- Formats a resource amount compactly: 1016424 -> "1.0M", 119858 -> "120k", 950 -> "950".
---@param amount number
---@return string
local function FormatAmount(amount)
    if amount >= 1000000 then
        return string.format("%.1fM", amount / 1000000)
    elseif amount >= 1000 then
        return string.format("%.0fk", amount / 1000)
    end
    return string.format("%d", amount)
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
---@field TitleArea Group
---@field LeftArea Group
---@field FilterArea Group
---@field SelectionArea Group
---@field StatsArea Group
---@field PreviewArea Group
---@field ActionArea Group
---@field Title Text
---@field FilterTitle Text
---@field SearchLabel Text
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
---@field Preview UICustomLobbyMapPreview
---@field Surface UICustomLobbyScenarioPreview
---@field PreviewTitle Text
---@field InfoMeta Text
---@field AuthorLabel Text
---@field AuthorValue Text
---@field ReclaimLabel Text
---@field ReclaimValue Group
---@field ReclaimMass Text
---@field ReclaimMassIcon Bitmap
---@field ReclaimEnergy Text
---@field ReclaimEnergyIcon Bitmap
---@field DescriptionLabel Text
---@field Description TextArea
---@field DescriptionScrollbar Scrollbar | false
---@field Warning Text
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
        self.OnConfirmCb = onConfirm
        self.OnCancelCb = onCancel

        self.Ready = false
        self.Filtered = {}
        self.Selected = nil
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

        self.SearchLabel = UIUtil.CreateText(self.FilterArea, "Search", 13, UIUtil.bodyFont)
        self.SearchLabel:SetColor('ff9aa0a8')

        self.Search = Edit(self.FilterArea)
        Layouter(self.Search):Left(0):Top(0):Width(96):Height(22):End()
        self.Search:SetFont(UIUtil.bodyFont, 16)
        self.Search:SetForegroundColor(UIUtil.fontColor)
        self.Search:ShowBackground(true)
        self.Search:SetBackgroundColor('77778888')
        self.Search:SetText(saved.search or "")
        self.Search.OnTextChanged = function(control, newText, oldText)
            self:Populate()
        end
        self.Search.OnEnterPressed = function(control, text)
            self:Confirm()
            return true
        end
        Tooltip.AddControlTooltipManual(self.Search, "Search", "Filter the list by map name or author.")

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
        -- the candidate preview — the same component as the in-lobby preview, created unbound so we
        -- drive it ourselves (no model wiring); spawns render as numbered dots (the surface default).
        -- Resources/wrecks start hidden — the toggles flip them; spawns start shown.
        self.Preview = CustomLobbyMapPreview.Create(self.PreviewArea)
        self.Surface = self.Preview.Surface
        self.Surface:SetOverlayVisible('resources', false)
        self.Surface:SetOverlayVisible('wrecks', false)

        self.SpawnsToggle = self:CreateToggle("Spawns", true,
            function(checked) self.Surface:SetOverlayVisible('spawns', checked) end,
            "Spawns", "Show the start positions.")
        self.ResourcesToggle = self:CreateToggle("Resources", false,
            function(checked) self.Surface:SetOverlayVisible('resources', checked) end,
            "Resources", "Show mass and hydrocarbon deposits.")
        self.WrecksToggle = self:CreateToggle("Wrecks", false,
            function(checked) self.Surface:SetOverlayVisible('wrecks', checked) end,
            "Wrecks", "Show prebuilt wreckage (if the map defines any).")

        -- map title + info line, centred below the preview (mirrors the in-lobby Map header)
        self.PreviewTitle = UIUtil.CreateText(self.PreviewArea, "", 16, UIUtil.titleFont)
        self.PreviewTitle:DisableHitTest()
        self.InfoMeta = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.InfoMeta:SetColor('ff9aa0a8')
        self.InfoMeta:DisableHitTest()

        -- labelled detail sections below, exactly as the Map tab (config/CustomLobbyMapPanel.lua):
        --#region Author section
        self.AuthorLabel = self:CreateSectionLabel("Author")
        self.AuthorValue = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.AuthorValue:SetColor(ValueColor)
        self.AuthorValue:DisableHitTest()
        --#endregion

        --#region Reclaim section (amount + mass icon, amount + energy icon)
        self.ReclaimLabel = self:CreateSectionLabel("Reclaim")
        self.ReclaimValue = Group(self.PreviewArea, "CustomLobbyMapSelectReclaim")
        self.ReclaimValue:DisableHitTest()
        self.ReclaimMass = UIUtil.CreateText(self.ReclaimValue, "", 13, UIUtil.bodyFont)
        self.ReclaimMass:SetColor(ValueColor)
        self.ReclaimMass:DisableHitTest()
        self.ReclaimMassIcon = Bitmap(self.ReclaimValue)
        self.ReclaimMassIcon:SetTexture(UIUtil.UIFile(MassIcon))
        self.ReclaimMassIcon:DisableHitTest()
        self.ReclaimEnergy = UIUtil.CreateText(self.ReclaimValue, "", 13, UIUtil.bodyFont)
        self.ReclaimEnergy:SetColor(ValueColor)
        self.ReclaimEnergy:DisableHitTest()
        self.ReclaimEnergyIcon = Bitmap(self.ReclaimValue)
        self.ReclaimEnergyIcon:SetTexture(UIUtil.UIFile(EnergyIcon))
        self.ReclaimEnergyIcon:DisableHitTest()
        --#endregion

        --#region Description section
        self.DescriptionLabel = self:CreateSectionLabel("Description")
        self.Description = TextArea(self.PreviewArea, 200, 80)
        self.Description:SetFont(UIUtil.bodyFont, 12)
        self.Description:SetColors(ValueColor, "00000000", ValueColor, "00000000")
        --#endregion

        -- file-health warning (dialog-only); pinned to the bottom of the preview column
        self.Warning = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.Warning:SetColor('ffff6b6b')
        self.Warning:DisableHitTest()

        -- "Open page" link → opens an allowed map url; secondary action, bottom-left (like the tab)
        self.CurrentUrl = false
        self.UrlButton = UIUtil.CreateText(self.ActionArea, "Open page", 12, UIUtil.bodyFont)
        self.UrlButton:SetColor('ff7fb3ff')
        self.UrlButton:Hide()
        self.UrlButton.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                if self.CurrentUrl then
                    OpenURL(ToOpenableUrl(self.CurrentUrl))
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
        Layouter(self.SearchLabel):AtLeftIn(self.FilterArea):AtVerticalCenterIn(self.Search):End()
        Layouter(self.Search):AnchorToRight(self.SearchLabel, 8):AtRightIn(self.FilterArea):AnchorToBottom(self.FilterTitle, 8):Height(22):End()

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

        -- size the preview (glow + backdrop); the surface (the map) is inset within it. Overlays
        -- below anchor to self.Surface, so they land on the map, not the glow margin.
        Layouter(self.Preview)
            :AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.ResourcesToggle, 10)
            :Width(PreviewSize):Height(PreviewSize)
            :End()

        -- title + info line, centred under the preview (the labelled sections below are placed
        -- dynamically by LayoutSections so empty ones collapse)
        Layouter(self.PreviewTitle):AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.Preview, 8):End()
        Layouter(self.InfoMeta):AtHorizontalCenterIn(self.PreviewArea):AnchorToBottom(self.PreviewTitle, 2):End()

        -- the reclaim value row: amount + mass icon, amount + energy icon (fixed internal layout;
        -- the group's position is set by LayoutSections)
        LayoutHelpers.SetHeight(self.ReclaimValue, IconSize + 4)
        Layouter(self.ReclaimMass):AtLeftIn(self.ReclaimValue):AtVerticalCenterIn(self.ReclaimValue):End()
        Layouter(self.ReclaimMassIcon):AnchorToRight(self.ReclaimMass, 3):AtVerticalCenterIn(self.ReclaimValue):Width(IconSize):Height(IconSize):End()
        Layouter(self.ReclaimEnergy):AnchorToRight(self.ReclaimMassIcon, 10):AtVerticalCenterIn(self.ReclaimValue):End()
        Layouter(self.ReclaimEnergyIcon):AnchorToRight(self.ReclaimEnergy, 3):AtVerticalCenterIn(self.ReclaimValue):Width(IconSize):Height(IconSize):End()

        -- file-health warning pinned to the bottom-left; the description floats above it
        Layouter(self.Warning):AtLeftIn(self.PreviewArea, 6):AtBottomIn(self.PreviewArea):End()

        -- the description's left/right are fixed here so its Width can be bound in Initialize (the
        -- TextArea reflows on the Width bind, which reads Left/Right); top/bottom set by LayoutSections
        Layouter(self.Description):AtLeftIn(self.PreviewArea, 6):AtRightIn(self.PreviewArea, 24):End()
        self.DescriptionScrollbar = UIUtil.CreateVertScrollbarFor(self.Description)
        --#endregion

        --#region actions
        Layouter(self.CancelButton):AtRightIn(self.ActionArea):AtVerticalCenterIn(self.ActionArea):End()
        Layouter(self.SelectButton):AnchorToLeft(self.CancelButton, 12):AtVerticalCenterIn(self.ActionArea):End()
        -- Random: horizontally centred under the left area, vertically centred in the actions
        Layouter(self.RandomButton):AtHorizontalCenterIn(self.LeftArea):AtVerticalCenterIn(self.ActionArea):End()
        -- "Open page" link: secondary action, bottom-left
        Layouter(self.UrlButton):AtLeftIn(self.ActionArea, 6):AtVerticalCenterIn(self.ActionArea):End()
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
        end
        Tooltip.AddControlTooltipManual(valueCombo, tooltipTitle, tooltipBody)

        local opCombo = Combo(self.FilterArea, 14, 3, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        opCombo:AddItems(Operators, opIndex)
        opCombo.OnClick = function(combo, index, text)
            onOp(index)
            self:Populate()
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

        -- TextArea pins Width to its constructor value and wraps to Width(), not Left..Right. Bind
        -- it to the laid-out (map-wide) span now — not in __post_init: the bind eagerly fires
        -- Width.OnDirty → ReflowText, which reads parent geometry that's circular until mounted.
        self.Description.Width:Set(function() return self.Description.Right() - self.Description.Left() end)

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
            -- search matches the map name or (when the scenario provides one) its author
            local haystack = string.lower(scenario.name or "")
            if scenario.author then
                haystack = haystack .. " " .. string.lower(scenario.author)
            end
            local matchesName = search == "" or string.find(haystack, search, 1, true)
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
        self:OnMapSelected(self.Filtered[ ow])
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

    --- Shows a candidate: hands the scenario to the preview surface, fills the info, and runs a
    --- file-health check that gates Select.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    Inspect = function(self, scenario)
        local problems = {}
        if not DiskGetFileInfo(scenario.map) then
            table.insert(problems, "map missing")
        end
        if not DiskGetFileInfo(scenario.script) then
            table.insert(problems, "script missing")
        end

        if not DiskGetFileInfo(scenario.save) then
            table.insert(problems, "save missing")
        end

        -- the catalog owns scenario loading + caching (the save doscript is expensive and we
        -- re-inspect the same maps as you browse)
        self.Surface:SetScenario(scenario, CustomLobbyMapCatalog.LoadSave(scenario))
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

    --- Builds a dim section label (Author / Reclaim / Description). Private.
    ---@param self UICustomLobbyMapSelect
    ---@param text string
    ---@return Text
    CreateSectionLabel = function(self, text)
        local label = UIUtil.CreateText(self.PreviewArea, text, 12, UIUtil.titleFont)
        label:SetColor(LabelColor)
        label:DisableHitTest()
        return label
    end,

    --- Stacks the visible sections under the info line (collapsing absent ones) and floats the
    --- description into the space above the warning. Mirrors the Map tab's LayoutSections.
    ---@param self UICustomLobbyMapSelect
    ---@param hasAuthor boolean
    ---@param hasReclaim boolean
    LayoutSections = function(self, hasAuthor, hasReclaim)
        local prev = self.InfoMeta   -- the sections begin under the info line

        -- places a label + value pair under `prev`, or hides both
        local function place(label, value, visible)
            if visible then
                label:Show()
                value:Show()
                Layouter(label):AtLeftIn(self.PreviewArea, 6):AnchorToBottom(prev, 8):End()
                Layouter(value):AtLeftIn(self.PreviewArea, 6):AnchorToBottom(label, 2):End()
                prev = value
            else
                label:Hide()
                value:Hide()
            end
        end

        place(self.AuthorLabel, self.AuthorValue, hasAuthor)
        place(self.ReclaimLabel, self.ReclaimValue, hasReclaim)

        -- description always shows; its label sits under the last visible section
        Layouter(self.DescriptionLabel):AtLeftIn(self.PreviewArea, 6):AnchorToBottom(prev, 8):End()
        Layouter(self.Description)
            :AtLeftIn(self.PreviewArea, 6):AtRightIn(self.PreviewArea, 24)
            :AnchorToBottom(self.DescriptionLabel, 4):AnchorToTop(self.Warning, 8)
            :End()
    end,

    --- Fills the title + info line (size · players · version), the labelled sections (author /
    --- reclaim / description) and the url link — collapsing sections the map doesn't provide.
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    UpdateInfo = function(self, scenario)
        self.PreviewTitle:SetText(LOC(scenario.name) or "?")

        local parts = {}
        if scenario.size then
            table.insert(parts, string.format("%dkm", math.floor(scenario.size[1] / 50)))
        end
        local players = ArmyCount(scenario)
        if players > 0 then
            table.insert(parts, players .. " players")
        end
        if scenario.map_version then
            table.insert(parts, "v" .. scenario.map_version)
        end
        self.InfoMeta:SetText(table.concat(parts, "   ·   "))

        local author = scenario.author
        local reclaim = scenario.reclaim
        local hasAuthor = type(author) == "string" and author ~= ""
        local hasReclaim = type(reclaim) == "table" and reclaim[1] ~= nil and reclaim[2] ~= nil
        if hasAuthor then
            self.AuthorValue:SetText(author)
        end
        if hasReclaim then
            self.ReclaimMass:SetText(FormatAmount(reclaim[1]))
            self.ReclaimEnergy:SetText(FormatAmount(reclaim[2]))
        end
        self.Description:SetText(scenario.description and LOC(scenario.description) or "")

        -- some scenarios carry a `url` to their source/page; offer to open allowed ones
        if scenario.url and IsAllowedUrl(scenario.url) then
            self.CurrentUrl = scenario.url
            self.UrlButton:Show()
        else
            self.CurrentUrl = false
            self.UrlButton:Hide()
        end

        self:LayoutSections(hasAuthor, hasReclaim)
        UpdateTextAreaScrollbar(self.Description, self.DescriptionScrollbar)
    end,

    --- Clears the preview + info (no candidate / empty list).
    ---@param self UICustomLobbyMapSelect
    ClearDetails = function(self)
        self.LastInspected = nil
        self.Surface:Clear()
        self.PreviewTitle:SetText("")
        self.InfoMeta:SetText("")
        self.Warning:SetText("")
        self.Description:SetText("")
        self.CurrentUrl = false
        self.UrlButton:Hide()
        self:LayoutSections(false, false)
        UpdateTextAreaScrollbar(self.Description, self.DescriptionScrollbar)
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
        self:SavePrefs()
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
