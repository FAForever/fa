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

-- The mod-select dialog: a searchable, type-filterable list of mods you tick on the left, with
-- the highlighted mod's details on the right, plus named presets. The sibling of the map-select
-- dialog (CustomLobbyMapSelect) — same areas/three-phase-init/Prefs shape — but for mods.
--
-- It is a transient picker, NOT a model component: it owns no synced state. It works off the
-- CustomLobbyModCatalog (reference data, streamed in) and a *working selection set*, and on OK
-- it just hands that set to an `onConfirm` callback. Where the selection goes is the opener's
-- decision (the MVC boundary):
--   * `Open` (in-lobby)   — sim mods route through the host-authoritative `RequestSetGameMods`
--     intent (synced via the launch model's `GameMods`); UI mods are this peer's own choice and
--     persist locally via `ModUtilities.SetSelectedUIMods`.
--   * `OpenStandalone`    — no lobby; the whole selection persists to the preference file via
--     `ModUtilities.SetSelectedMods` (the main-menu mod-manager use case).
--
-- Sim-mod checkboxes are read-only for a non-host (`canEditGameMods`); blacklisted / missing-
-- dependency mods can't be enabled. Selection edits run through `ModUtilities.ResolveEnable` /
-- `ResolveDisable`, which pull in requirements and drop conflicts.
--
-- Like the map dialog, the list is text-only; only the detail panel shows a mod icon, one at a
-- time (the engine never frees mod-icon textures — see mapselect/CLAUDE.md).

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

local ModUtilities = import("/lua/ui/modutilities.lua")
local CustomLobbyModCatalog = import("/lua/ui/lobby/customlobby/modselect/customlobbymodcatalog.lua")
local CustomLobbyModList = import("/lua/ui/lobby/customlobby/modselect/customlobbymodlist.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")
local CustomLobbyLocalModel = import("/lua/ui/lobby/customlobby/customlobbylocalmodel.lua")

local LazyVarDerive = import("/lua/lazyvar.lua").Derive

local Layouter = LayoutHelpers.ReusedLayoutFor

-- flip to tint each layout area so the regions are visible while iterating
local Debug = false

local DialogWidth = 760
local DialogHeight = 620
local Pad = 12
local ColumnGap = 24
local LeftWidth = 320
local IconSize = 64
local TitleHeight = 32
local ActionHeight = 120  -- two stacked rows: presets on top, OK / Cancel at the bottom
local FilterHeight = 120
local StatsHeight = 22

local PrefsKey = "customlobby_modselect"

-- Mod web pages we'll open in a browser (mods carry `url` / `github`). Matched against the URL's
-- host — exact or as a subdomain — so look-alikes ("github.com.evil.com") are rejected. Mirrors
-- the map dialog's allowlist; add a line to extend.
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

--- Whether `url` is an http(s) link to an allowed domain (or a subdomain of one).
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

-- the detail title is single-line Text (which doesn't clip), so cap it with an ellipsis so a long
-- mod name doesn't run off the panel. Char-based (the engine's Text has no width-measure).
local TitleMaxChars = 32

--- Truncates `text` to `maxChars`, appending "…" when it had to cut.
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

--- Joins a uid set's display names (looked up in the catalog) into "A, B, C", or "" if empty.
---@param uidSet table<string, true> | nil
---@return string
local function NamesOf(uidSet)
    if not uidSet then
        return ""
    end
    local names = {}
    for uid in uidSet do
        local mod = CustomLobbyModCatalog.FindByUid(uid)
        table.insert(names, mod and mod.title or uid)
    end
    table.sort(names)
    return table.concat(names, ", ")
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

---@class UICustomLobbyModSelect : Group
---@field Trash TrashBag
---@field CanEditGameMods boolean
---@field Selection UIModSelection
---@field OnConfirmCb fun(selection: UIModSelection)
---@field OnCancelCb fun()
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
---@field GameToggle Checkbox
---@field UIToggle Checkbox
---@field UnavailableToggle Checkbox
---@field ShowGame boolean
---@field ShowUI boolean
---@field ShowUnavailable boolean
---@field ModList UICustomLobbyModList
---@field EmptyLabel Text
---@field CountLabel Text
---@field SelectedLabel Text
---@field Spinner Text
---@field Icon Bitmap
---@field DetailTitle Text
---@field DetailMeta Text
---@field UrlButton Text
---@field GithubButton Text
---@field CurrentUrl string | false
---@field CurrentGithub string | false
---@field Description TextArea
---@field DescriptionScrollbar Scrollbar | false
---@field DepsText TextArea
---@field DepsScrollbar Scrollbar | false
---@field Note Text
---@field PresetLabel Text
---@field PresetCombo Combo
---@field SavePresetButton Button
---@field DeletePresetButton Button
---@field SelectButton Button
---@field CancelButton Button
---@field ClearButton Button
---@field PresetNames string[]
---@field ModsObserver LazyVar
---@field Mods UILobbyModInfo[]
---@field Filtered UILobbyModInfo[]
---@field Highlighted? UILobbyModInfo
---@field Ready boolean
local CustomLobbyModSelect = ClassUI(Group) {

    ---@param self UICustomLobbyModSelect
    ---@param parent Control
    ---@param options { initial: UIModSelection, canEditGameMods: boolean, onConfirm: fun(selection: UIModSelection), onCancel: fun() }
    __init = function(self, parent, options)
        Group.__init(self, parent, "CustomLobbyModSelect")

        self.Trash = TrashBag()
        self.OnConfirmCb = options.onConfirm
        self.OnCancelCb = options.onCancel
        self.CanEditGameMods = options.canEditGameMods ~= false
        self.Selection = table.copy(options.initial or {})

        self.Ready = false
        self.Filtered = {}
        self.Highlighted = nil
        self.Mods = CustomLobbyModCatalog.GetMods()
        self.PresetNames = {}

        -- restore the last-used filters + search (persisted across opens)
        local saved = Prefs.GetFromCurrentProfile(PrefsKey) or {}
        self.ShowGame = saved.showGame ~= false
        self.ShowUI = saved.showUI ~= false
        self.ShowUnavailable = saved.showUnavailable == true

        -- areas
        self.TitleArea = CreateArea(self, "TitleArea", 'ffcc4040')
        self.LeftArea = CreateArea(self, "LeftArea", 'ff4060cc')
        self.FilterArea = CreateArea(self.LeftArea, "FilterArea", 'ff40cc60')
        self.SelectionArea = CreateArea(self.LeftArea, "SelectionArea", 'ffcccc40')
        self.StatsArea = CreateArea(self.LeftArea, "StatsArea", 'ff40cccc')
        self.PreviewArea = CreateArea(self, "PreviewArea", 'ffcc40cc')
        self.ActionArea = CreateArea(self, "ActionArea", 'ff808080')

        self.Title = UIUtil.CreateText(self.TitleArea, "Select mods", 22, UIUtil.titleFont)

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
        Tooltip.AddControlTooltipManual(self.Search, "Search", "Filter the list by mod name or author.")

        self.GameToggle = self:CreateToggle("Game", self.ShowGame,
            function(checked) self.ShowGame = checked; self:Populate() end,
            "Game mods", "Show mods that change the simulation (all players need them).")
        self.UIToggle = self:CreateToggle("UI", self.ShowUI,
            function(checked) self.ShowUI = checked; self:Populate() end,
            "UI mods", "Show mods that change only your interface (per-player).")
        self.UnavailableToggle = self:CreateToggle("Deprecated", self.ShowUnavailable,
            function(checked) self.ShowUnavailable = checked; self:Populate() end,
            "Deprecated mods", "Show blacklisted mods and mods missing a dependency.")
        --#endregion

        --#region selection list + stats
        self.ModList = CustomLobbyModList.Create(self.SelectionArea)
        self.ModList.OnSelect = function(mod, index)
            self:OnModHighlighted(mod)
        end
        self.ModList.OnToggle = function(mod, checked)
            self:ToggleMod(mod, checked)
        end
        self.ModList.OnConfirm = function(mod)
            self:Confirm()
        end

        self.EmptyLabel = UIUtil.CreateText(self.SelectionArea, "No mods match", 14, UIUtil.bodyFont)
        self.EmptyLabel:SetColor('ff8a909a')
        self.EmptyLabel:DisableHitTest()
        self.EmptyLabel:Hide()

        self.CountLabel = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.CountLabel:SetColor('ff9aa0a8')
        self.SelectedLabel = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.SelectedLabel:SetColor('ff9aa0a8')
        self.Spinner = UIUtil.CreateText(self.StatsArea, "", 13, UIUtil.bodyFont)
        self.Spinner:SetColor('ff9aa0a8')
        --#endregion

        --#region detail panel (right)
        self.Icon = Bitmap(self.PreviewArea)
        self.Icon:DisableHitTest()
        self.Icon:Hide()

        self.DetailTitle = UIUtil.CreateText(self.PreviewArea, "", 18, UIUtil.titleFont)
        self.DetailTitle:DisableHitTest()
        self.DetailMeta = UIUtil.CreateText(self.PreviewArea, "", 13, UIUtil.bodyFont)
        self.DetailMeta:SetColor('ffc8ccd0')
        self.DetailMeta:DisableHitTest()

        self.CurrentUrl = false
        self.UrlButton = self:CreateLink("Website", "Open the mod's web page in your browser.",
            function() return self.CurrentUrl end)
        self.CurrentGithub = false
        self.GithubButton = self:CreateLink("Source", "Open the mod's source repository in your browser.",
            function() return self.CurrentGithub end)

        self.Description = TextArea(self.PreviewArea, 200, 80)
        self.Description:SetFont(UIUtil.bodyFont, 12)
        self.Description:SetColors('ffc8ccd0', "00000000", 'ffc8ccd0', "00000000")

        self.DepsText = TextArea(self.PreviewArea, 200, 60)
        self.DepsText:SetFont(UIUtil.bodyFont, 12)
        self.DepsText:SetColors('ff9aa0a8', "00000000", 'ff9aa0a8', "00000000")

        self.Note = UIUtil.CreateText(self.PreviewArea, "", 12, UIUtil.bodyFont)
        self.Note:SetColor('ffd0a24c')
        self.Note:DisableHitTest()
        --#endregion

        --#region actions (presets + ok/cancel)
        self.PresetLabel = UIUtil.CreateText(self.ActionArea, "Preset", 13, UIUtil.bodyFont)
        self.PresetLabel:SetColor('ff9aa0a8')

        self.PresetCombo = Combo(self.ActionArea, 14, 8, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        self.PresetCombo.OnClick = function(combo, index, text)
            self:LoadPreset(text)
        end
        Tooltip.AddControlTooltipManual(self.PresetCombo, "Presets", "Load a saved selection of mods.")

        self.SavePresetButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Save", 14, 2)
        self.SavePresetButton.OnClick = function(button, modifiers)
            self:PromptSavePreset()
        end
        Tooltip.AddControlTooltipManual(self.SavePresetButton, "Save preset", "Save the current selection as a named preset.")

        self.DeletePresetButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Delete", 14, 2)
        self.DeletePresetButton.OnClick = function(button, modifiers)
            self:DeleteSelectedPreset()
        end
        Tooltip.AddControlTooltipManual(self.DeletePresetButton, "Delete preset", "Delete the selected preset.")

        self.SelectButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Ok>OK", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers)
            self:Confirm()
        end

        self.CancelButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "<LOC _Cancel>Cancel", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers)
            self.OnCancelCb()
        end

        self.ClearButton = UIUtil.CreateButtonStd(self.ActionArea, '/scx_menu/small-btn/small', "Clear", 14, 2)
        self.ClearButton.OnClick = function(button, modifiers)
            self:ClearSelection()
        end
        Tooltip.AddControlTooltipManual(self.ClearButton, "Clear",
            "Deselect every mod you can change (UI mods, plus game mods when you're the host).")
        --#endregion

        self.ModsObserver = self.Trash:Add(
            LazyVarDerive(CustomLobbyModCatalog.GetModsVar(), function(modsLazy)
                self:OnModsChanged(modsLazy())
            end))

        CustomLobbyModCatalog.EnsureLoaded()

        -- spin a small throbber beside the count while the catalog is still streaming
        self.Trash:Add(ForkThread(function()
            local frames = { "|", "/", "-", "\\" }
            local i = 1
            while not CustomLobbyModCatalog.IsLoaded() do
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

    ---@param self UICustomLobbyModSelect
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
        Layouter(self.GameToggle):AtLeftIn(self.FilterArea):AnchorToBottom(self.Search, 12):End()
        Layouter(self.UIToggle):AnchorToRight(self.GameToggle, 16):AtVerticalCenterIn(self.GameToggle):End()
        Layouter(self.UnavailableToggle):AnchorToRight(self.UIToggle, 16):AtVerticalCenterIn(self.UIToggle):End()
        --#endregion

        --#region selection list + stats
        Layouter(self.ModList):AtLeftIn(self.SelectionArea):AtTopIn(self.SelectionArea):AtBottomIn(self.SelectionArea):End()
        self.ModList.Right:Set(function() return self.SelectionArea.Right() - LayoutHelpers.ScaleNumber(32) end)
        Layouter(self.EmptyLabel):AtHorizontalCenterIn(self.SelectionArea):AtVerticalCenterIn(self.SelectionArea):End()

        Layouter(self.CountLabel):AtLeftIn(self.StatsArea):AtVerticalCenterIn(self.StatsArea):End()
        Layouter(self.Spinner):AnchorToRight(self.CountLabel, 8):AtVerticalCenterIn(self.StatsArea):End()
        Layouter(self.SelectedLabel):AtRightIn(self.StatsArea):AtVerticalCenterIn(self.StatsArea):End()
        --#endregion

        --#region detail panel
        Layouter(self.Icon):AtLeftIn(self.PreviewArea):AtTopIn(self.PreviewArea):Width(IconSize):Height(IconSize):End()
        Layouter(self.DetailTitle):AnchorToRight(self.Icon, 12):AtTopIn(self.PreviewArea, 2):End()
        Layouter(self.DetailMeta):AnchorToRight(self.Icon, 12):AnchorToBottom(self.DetailTitle, 6):End()
        Layouter(self.UrlButton):AnchorToRight(self.Icon, 12):AnchorToBottom(self.DetailMeta, 8):End()
        Layouter(self.GithubButton):AnchorToRight(self.UrlButton, 16):AtVerticalCenterIn(self.UrlButton):End()

        Layouter(self.Description)
            :AtLeftIn(self.PreviewArea):AtRightIn(self.PreviewArea, 32)
            :AnchorToBottom(self.Icon, 14):Height(160)
            :End()
        self.DescriptionScrollbar = UIUtil.CreateVertScrollbarFor(self.Description)

        Layouter(self.Note):AtLeftIn(self.PreviewArea):AtBottomIn(self.PreviewArea):End()

        -- dependency summary fills the gap between the description and the note line; scrolls if a
        -- mod lists many requirements / conflicts
        Layouter(self.DepsText)
            :AtLeftIn(self.PreviewArea):AtRightIn(self.PreviewArea, 32)
            :AnchorToBottom(self.Description, 12):AnchorToTop(self.Note, 8)
            :End()
        self.DepsScrollbar = UIUtil.CreateVertScrollbarFor(self.DepsText)
        --#endregion

        --#region actions
        -- presets on the top row, OK / Cancel on the bottom row — the gap between them is the
        -- vertical space the tall action area buys
        -- top row: pin the (tall) combo + buttons to the area's top edge, and centre the short
        -- label on the combo — centring the tall controls on a top-aligned label would clip them
        Layouter(self.PresetCombo):AtLeftIn(self.ActionArea, 48):AtTopIn(self.ActionArea):Width(150):End()
        Layouter(self.PresetLabel):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.PresetCombo):End()
        Layouter(self.SavePresetButton):AnchorToRight(self.PresetCombo, 8):AtVerticalCenterIn(self.PresetCombo):End()
        Layouter(self.DeletePresetButton):AnchorToRight(self.SavePresetButton, 4):AtVerticalCenterIn(self.PresetCombo):End()

        -- bottom row: Clear on the left, Cancel / OK on the right
        Layouter(self.SelectButton):AtRightIn(self.ActionArea):AtBottomIn(self.ActionArea):End()
        Layouter(self.CancelButton):AnchorToLeft(self.SelectButton, 12):AtVerticalCenterIn(self.SelectButton):End()
        Layouter(self.ClearButton):AtLeftIn(self.ActionArea):AtVerticalCenterIn(self.SelectButton):End()
        --#endregion
    end,

    --- Builds a labelled checkbox filter wired to `onChange(checked)`, with a tooltip.
    ---@param self UICustomLobbyModSelect
    ---@param label string
    ---@param initial boolean
    ---@param onChange fun(checked: boolean)
    ---@param tooltipTitle string
    ---@param tooltipBody string
    ---@return Checkbox
    CreateToggle = function(self, label, initial, onChange, tooltipTitle, tooltipBody)
        local checkbox = UIUtil.CreateCheckbox(self.FilterArea, '/CHECKBOX/', label, true, 13)
        checkbox:SetCheck(initial, true)
        checkbox.OnCheck = function(control, checked)
            onChange(checked)
        end
        Tooltip.AddControlTooltipManual(checkbox, tooltipTitle, tooltipBody)
        return checkbox
    end,

    --- Builds a clickable text link whose target comes from `getUrl()` (so it can change as the
    --- highlighted mod changes). Hidden until shown by UpdateDetail.
    ---@param self UICustomLobbyModSelect
    ---@param label string
    ---@param tooltipBody string
    ---@param getUrl fun(): string | false
    ---@return Text
    CreateLink = function(self, label, tooltipBody, getUrl)
        local link = UIUtil.CreateText(self.PreviewArea, label, 12, UIUtil.bodyFont)
        link:SetColor('ff7fb3ff')
        link:Hide()
        link.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' then
                local url = getUrl()
                if url then
                    OpenURL(ToOpenableUrl(url))
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
        Tooltip.AddControlTooltipManual(link, "Open link", tooltipBody)
        return link
    end,

    --- Builds the list pool + populates + wires the selection. Called by the opener after the
    --- dialog is mounted + centred by Popup (three-phase init, /lua/ui/CLAUDE.md § 1).
    ---@param self UICustomLobbyModSelect
    Initialize = function(self)
        self.Ready = true

        -- TextArea pins Width to its constructor value and wraps to Width(), not Left..Right.
        -- Bind it to the laid-out span so text wraps at the real panel width — but only now (the
        -- opener calls Initialize after Popup mounts): the bind eagerly fires Width.OnDirty →
        -- ReflowText, which reads the parent geometry, circular until we're mounted.
        self.Description.Width:Set(function() return self.Description.Right() - self.Description.Left() end)
        self.DepsText.Width:Set(function() return self.DepsText.Right() - self.DepsText.Left() end)

        self.ModList:Initialize()
        self.ModList:SetCanToggle(function(mod)
            if mod.type == 'BLACKLISTED' or mod.type == 'NO_DEPENDENCY' then
                return false
            end
            if not mod.ui_only and not self.CanEditGameMods then
                return false
            end
            return true
        end)
        self.ModList:SetChecked(self.Selection)
        self:RefreshPresets()
        self:Populate()
    end,

    --- The catalog published a new (possibly larger) mod list: recount always, re-list once
    --- we're mounted.
    ---@param self UICustomLobbyModSelect
    ---@param mods UILobbyModInfo[]
    OnModsChanged = function(self, mods)
        self.Mods = mods
        if self.Ready then
            self:Populate()
        else
            self:UpdateStats()
        end
    end,

    --- Persists the current filters + search for next time.
    ---@param self UICustomLobbyModSelect
    SavePrefs = function(self)
        Prefs.SetToCurrentProfile(PrefsKey, {
            showGame = self.ShowGame,
            showUI = self.ShowUI,
            showUnavailable = self.ShowUnavailable,
            search = self.Search:GetText() or "",
        })
    end,

    --- Rebuilds the list from the catalog, applying the name/author search + type filters, and
    --- keeps the current highlight.
    ---@param self UICustomLobbyModSelect
    Populate = function(self)
        local search = string.lower(self.Search:GetText() or "")
        local targetUid = self.Highlighted and self.Highlighted.uid

        self.Filtered = {}
        local highlightRow = 0

        for _, mod in self.Mods do
            if self:PassesFilters(mod, search) then
                table.insert(self.Filtered, mod)
                if targetUid and mod.uid == targetUid then
                    highlightRow = table.getn(self.Filtered)
                end
            end
        end

        self.ModList:SetItems(self.Filtered)
        self.ModList:SetChecked(self.Selection)

        if table.getn(self.Filtered) > 0 then
            self.EmptyLabel:Hide()
            local row = highlightRow > 0 and highlightRow or 1
            self.ModList:SetSelection(row)
            self.ModList:ShowItem(row)
            self:OnModHighlighted(self.Filtered[row])
        else
            self.EmptyLabel:Show()
            self.Highlighted = nil
            self:ClearDetail()
        end

        self:UpdateStats()
    end,

    --- Whether a mod passes the type filters + name/author search.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    ---@param search string                # already lowercased
    ---@return boolean
    PassesFilters = function(self, mod, search)
        local unavailable = mod.type == 'BLACKLISTED' or mod.type == 'NO_DEPENDENCY'
        if unavailable then
            if not self.ShowUnavailable then
                return false
            end
        elseif mod.ui_only then
            if not self.ShowUI then
                return false
            end
        else
            if not self.ShowGame then
                return false
            end
        end

        if search ~= "" then
            local haystack = string.lower((mod.title or "") .. " " .. (mod.author or ""))
            if not string.find(haystack, search, 1, true) then
                return false
            end
        end
        return true
    end,

    --- A mod was highlighted (row click): show its details.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    OnModHighlighted = function(self, mod)
        if not mod then
            return
        end
        self.Highlighted = mod
        self:UpdateDetail(mod)
    end,

    --- Toggles a mod's membership in the working selection (with dependency / conflict
    --- resolution), repaints the list, and refreshes the stats.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    ---@param checked boolean
    ToggleMod = function(self, mod, checked)
        local disabled = {}
        if checked then
            self.Selection, disabled = ModUtilities.ResolveEnable(self.Selection, mod.uid)
        else
            self.Selection = ModUtilities.ResolveDisable(self.Selection, mod.uid)
        end

        self.ModList:SetChecked(self.Selection)
        self:UpdateStats()

        if table.getn(disabled) > 0 then
            local conflictSet = {}
            for _, uid in disabled do
                conflictSet[uid] = true
            end
            self.Note:SetText("Disabled conflicting: " .. NamesOf(conflictSet))
        else
            self.Note:SetText("")
        end
    end,

    --- Fills the detail panel for `mod`: icon, title, author/version/type, links, description,
    --- and the dependency summary.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    UpdateDetail = function(self, mod)
        -- one re-textured icon for the whole dialog (never one per row — see the header note)
        self.Icon:SetTexture(mod.icon)
        self.Icon:Show()

        self.DetailTitle:SetText(Truncate(mod.title or mod.name or "?", TitleMaxChars))

        local parts = {}
        table.insert(parts, "by " .. (mod.author or "UNKNOWN"))
        if mod.versionText ~= "" then
            table.insert(parts, mod.versionText)
        end
        table.insert(parts, mod.ui_only and "UI mod" or "Game mod")
        self.DetailMeta:SetText(table.concat(parts, "   ·   "))

        self.CurrentUrl = IsAllowedUrl(mod.url) and mod.url or false
        if self.CurrentUrl then self.UrlButton:Show() else self.UrlButton:Hide() end
        self.CurrentGithub = IsAllowedUrl(mod.github) and mod.github or false
        if self.CurrentGithub then self.GithubButton:Show() else self.GithubButton:Hide() end

        self.Description:SetText(mod.description and LOC(mod.description) or "")

        -- dependency summary, then the minor identity fields (uid / copyright / location)
        local deps = self:DependencySummary(mod)
        local info = self:ModInfoLines(mod)
        if deps ~= "" and info ~= "" then
            self.DepsText:SetText(deps .. "\n\n" .. info)
        else
            self.DepsText:SetText(deps ~= "" and deps or info)
        end
        self.Note:SetText("")

        UpdateTextAreaScrollbar(self.Description, self.DescriptionScrollbar)
        UpdateTextAreaScrollbar(self.DepsText, self.DepsScrollbar)
    end,

    --- The minor identity fields shown at the bottom of the detail block: copyright, uid, and the
    --- mod's location on disk.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    ---@return string
    ModInfoLines = function(self, mod)
        -- always show all three labels; a missing field reads "omitted" rather than vanishing
        local function value(v)
            return (v and v ~= "") and v or "omitted"
        end
        return table.concat({
            "Copyright: " .. value(mod.copyright),
            "UID: " .. value(mod.uid),
            "Location: " .. value(mod.location),
        }, "\n")
    end,

    --- A one-or-more-line summary of a mod's requirements / conflicts / missing dependencies.
    ---@param self UICustomLobbyModSelect
    ---@param mod UILobbyModInfo
    ---@return string
    DependencySummary = function(self, mod)
        local lines = {}
        if mod.blacklistReason then
            table.insert(lines, "Blacklisted: " .. LOC(mod.blacklistReason))
        end
        if mod.missing then
            table.insert(lines, "Missing dependencies: " .. NamesOf(mod.missing))
        end
        if mod.requires then
            table.insert(lines, "Requires: " .. NamesOf(mod.requires))
        end
        if mod.conflicts then
            table.insert(lines, "Conflicts with: " .. NamesOf(mod.conflicts))
        end
        return table.concat(lines, "\n")
    end,

    --- Clears the detail panel (no highlight / empty list).
    ---@param self UICustomLobbyModSelect
    ClearDetail = function(self)
        self.Icon:Hide()
        self.DetailTitle:SetText("")
        self.DetailMeta:SetText("")
        self.Description:SetText("")
        self.DepsText:SetText("")
        self.Note:SetText("")
        self.CurrentUrl = false
        self.CurrentGithub = false
        self.UrlButton:Hide()
        self.GithubButton:Hide()
        UpdateTextAreaScrollbar(self.Description, self.DescriptionScrollbar)
        UpdateTextAreaScrollbar(self.DepsText, self.DepsScrollbar)
    end,

    --- Updates the footer: "X of Y mods" + the selected breakdown ("G game · U UI"), so the host
    --- can see what actually syncs (game) vs. stays local (UI).
    ---@param self UICustomLobbyModSelect
    UpdateStats = function(self)
        local total = table.getn(self.Mods)
        local shown = table.getn(self.Filtered)
        if self.Ready and shown < total then
            self.CountLabel:SetText(LOCF("%d of %d mods", shown, total))
        else
            self.CountLabel:SetText(LOCF("%d mods", total))
        end

        local game = table.getsize(ModUtilities.FilterSimMods(self.Selection))
        local ui = table.getsize(ModUtilities.FilterUIMods(self.Selection))
        self.SelectedLabel:SetText(LOCF("%d game · %d UI", game, ui))
    end,

    ---------------------------------------------------------------------------
    --#region Presets

    --- Reloads the preset dropdown from stored presets.
    ---@param self UICustomLobbyModSelect
    RefreshPresets = function(self)
        self.PresetNames = {}
        for _, preset in ModUtilities.GetPresets() do
            table.insert(self.PresetNames, preset.Name)
        end
        self.PresetCombo:ClearItems()
        if table.getn(self.PresetNames) > 0 then
            self.PresetCombo:AddItems(self.PresetNames)
            self.DeletePresetButton:Enable()
        else
            self.PresetCombo:AddItems({ "(no presets)" })
            self.DeletePresetButton:Disable()
        end
    end,

    --- Loads a preset's selection into the working set (pruned to installed mods; sim mods are
    --- dropped for a non-host who can't change them).
    ---@param self UICustomLobbyModSelect
    ---@param name string
    LoadPreset = function(self, name)
        local stored = ModUtilities.GetPreset(name)
        if not stored then
            return
        end
        local selection = ModUtilities.PruneMissing(stored)
        if not self.CanEditGameMods then
            selection = ModUtilities.FilterUIMods(selection)
        end
        self.Selection = selection
        self.ModList:SetChecked(self.Selection)
        self:UpdateStats()
        self.Note:SetText("Loaded preset '" .. name .. "'")
    end,

    --- Prompts for a name and saves the current selection as a preset.
    ---@param self UICustomLobbyModSelect
    PromptSavePreset = function(self)
        UIUtil.CreateInputDialog(GetFrame(0), "Name this preset", function(dialog, name)
            if not name or name == "" then
                return
            end
            ModUtilities.SavePreset(name, self.Selection)
            self:RefreshPresets()
            self.Note:SetText("Saved preset '" .. name .. "'")
        end)
    end,

    --- Deletes the preset currently shown in the dropdown.
    ---@param self UICustomLobbyModSelect
    DeleteSelectedPreset = function(self)
        local index = self.PresetCombo:GetItem()
        local name = self.PresetNames[index]
        if not name then
            return
        end
        ModUtilities.DeletePreset(name)
        self:RefreshPresets()
        self.Note:SetText("Deleted preset '" .. name .. "'")
    end,

    --#endregion

    --- Deselects everything the user is allowed to change: all mods for the host, only UI mods for
    --- a non-host (their sim mods are the host's choice and stay put).
    ---@param self UICustomLobbyModSelect
    ClearSelection = function(self)
        if self.CanEditGameMods then
            self.Selection = {}
        else
            self.Selection = ModUtilities.FilterSimMods(self.Selection)
        end
        self.ModList:SetChecked(self.Selection)
        self:UpdateStats()
        self.Note:SetText("Cleared selection")
    end,

    --- Commits the working selection via the opener's callback.
    ---@param self UICustomLobbyModSelect
    Confirm = function(self)
        self.OnConfirmCb(self.Selection)
    end,

    ---@param self UICustomLobbyModSelect
    OnDestroy = function(self)
        self:SavePrefs()
        self.Trash:Destroy()
    end,
}

-------------------------------------------------------------------------------
--#region Singleton + open / close

---@type Popup | false
local Instance = false

--- Internal: builds the dialog over `parent` with the given options and wires the Popup.
---@param parent Control
---@param options { initial: UIModSelection, canEditGameMods: boolean, onConfirm: fun(selection: UIModSelection) }
local function OpenWith(parent, options)
    if Instance then
        Instance:Close()
    end

    local popup
    local content = CustomLobbyModSelect(parent, {
        initial = options.initial,
        canEditGameMods = options.canEditGameMods,
        onConfirm = function(selection)
            options.onConfirm(selection)
            if popup then
                popup:Close()
            end
        end,
        onCancel = function()
            if popup then
                popup:Close()
            end
        end,
    })

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

--- Opens the mod-select dialog for the **lobby**. Sim mods route through the host-authoritative
--- `RequestSetGameMods` intent (a non-host sees them read-only); UI mods persist locally. Starts
--- from the launch model's sim mods + this peer's UI mods.
---@param parent? Control
function Open(parent)
    parent = parent or GetFrame(0)

    local launch = CustomLobbyLaunchModel.GetSingleton()
    local isHost = CustomLobbyLocalModel.GetSingleton().IsHost()

    -- seed: host-dictated sim mods (synced) + this peer's own UI mods (local)
    local initial = table.copy(launch.GameMods() or {})
    for uid in ModUtilities.GetSelectedUIMods() do
        initial[uid] = true
    end

    OpenWith(parent, {
        initial = initial,
        canEditGameMods = isHost,
        onConfirm = function(selection)
            ModUtilities.SetSelectedUIMods(selection)   -- this peer's UI mods, applied + persisted
            if isHost then
                CustomLobbyController.RequestSetGameMods(ModUtilities.FilterSimMods(selection))
            end
        end,
    })
end

--- Opens the mod-select dialog **standalone** (no lobby — the main-menu mod manager). The whole
--- selection persists to the preference file. `onClosed` (optional) runs after it closes.
---@param parent? Control
---@param onClosed? fun()
function OpenStandalone(parent, onClosed)
    parent = parent or GetFrame(0)

    OpenWith(parent, {
        initial = ModUtilities.GetSelectedMods(),
        canEditGameMods = true,
        onConfirm = function(selection)
            ModUtilities.SetSelectedMods(selection)
        end,
    })

    if onClosed then
        local popup = Instance
        if popup then
            local baseOnClosed = popup.OnClosed
            popup.OnClosed = function(self)
                baseOnClosed(self)
                onClosed()
            end
        end
    end
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
