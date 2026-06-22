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

-- The map-select dialog: a searchable list of scenarios with a preview + info, and
-- Select / Cancel. It is a transient picker, NOT a persistent model component:
--
--   * it reads the catalog (CustomLobbyMapCatalog) for the scenario list — reference data,
--   * it previews the *highlighted candidate*, which is decoupled from the launch model
--     (you're browsing, not committing), so it drives the shared MapPreview control directly
--     rather than the model-bound CustomLobbyMapPreview, and
--   * on Select it calls the controller intent `RequestSetScenario(file)` — the host sets the
--     scenario in the launch model and broadcasts it, the same path a `/map <name>` chat
--     command would use. It owns no synced state of its own.
--
-- This is the first of the sub-dialogs that the legacy `dialogs/mapselect.lua` god-dialog is
-- being split into: it does map selection ONLY. Game options, mods and unit restrictions —
-- which the legacy dialog also bundled — become their own components (the options panel loads
-- its schema from the selected map + mods; see CLAUDE.md "Next slices").

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local MapPreview = import("/lua/ui/controls/mappreview.lua").MapPreview
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup

local CustomLobbyMapCatalog = import("/lua/ui/lobby/customlobby/customlobbymapcatalog.lua")
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/customlobbylaunchmodel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor

local DialogWidth = 740
local DialogHeight = 520
local ListWidth = 300
local PreviewSize = 300

---@class UICustomLobbyMapSelect : Group
---@field Trash TrashBag
---@field Title Text
---@field Search Edit
---@field MapList ItemList
---@field Preview MapPreview
---@field PreviewBg Bitmap
---@field InfoTitle Text
---@field InfoName Text
---@field InfoSize Text
---@field InfoPlayers Text
---@field SelectButton Button
---@field CancelButton Button
---@field OnConfirmCb fun(scenarioFile: FileName)
---@field OnCancelCb fun()
---@field Scenarios UILobbyScenarioInfo[]
---@field Filtered UILobbyScenarioInfo[]       # the currently-listed (filtered) subset, 1-based by row
---@field Selected? UILobbyScenarioInfo        # the highlighted candidate
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

        self.Scenarios = CustomLobbyMapCatalog.GetScenarios()
        self.Filtered = {}
        -- default the highlight to whatever map is currently set (read-only model peek)
        self.Selected = CustomLobbyMapCatalog.FindByFile(CustomLobbyLaunchModel.GetSingleton().ScenarioFile())

        self.Title = UIUtil.CreateText(self, "<LOC map_sel_0000>Select Map", 22, UIUtil.titleFont)

        self.Search = Edit(self)
        -- An Edit reads its own bounds when the font is set, which is circular before the
        -- control is anchored — give it placeholder dimensions first (see /lua/ui/CLAUDE.md
        -- § 1); __post_init lays it out for real.
        Layouter(self.Search):Left(0):Top(0):Width(ListWidth):Height(22):End()
        self.Search:SetFont(UIUtil.bodyFont, 16)
        self.Search:SetForegroundColor(UIUtil.fontColor)
        self.Search:ShowBackground(true)
        self.Search:SetBackgroundColor('77778888')
        self.Search:SetText("")
        self.Search.OnTextChanged = function(control, newText, oldText)
            self:Populate()
        end

        -- ItemList is legacy (see /lua/ui/CLAUDE.md §6.1) but fine for a flat string list;
        -- swap for a pooled Group list if rows ever need richer content (thumbnails, badges).
        self.MapList = ItemList(self, "customlobby:maplist")
        self.MapList:SetFont(UIUtil.bodyFont, 14)
        self.MapList:SetColors(UIUtil.fontColor, "00000000", "FF000000", UIUtil.highlightColor, "ffbcfffe")
        self.MapList:ShowMouseoverItem(true)
        self.MapList.OnClick = function(control, row)
            self:OnMapHighlighted(row)
        end
        self.MapList.OnKeySelect = function(control, row)
            self:OnMapHighlighted(row)
        end
        self.MapList.OnDoubleClick = function(control, row)
            self:OnMapHighlighted(row)
            self:Confirm()
        end

        -- preview of the highlighted candidate (decoupled from the launch model)
        self.PreviewBg = Bitmap(self)
        self.PreviewBg:SetSolidColor('ff000000')
        self.PreviewBg:DisableHitTest()
        self.Preview = MapPreview(self)

        self.InfoTitle = UIUtil.CreateText(self, "<LOC sel_map_0000>Map Info", 16, UIUtil.titleFont)
        self.InfoName = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.InfoSize = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.InfoPlayers = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)

        self.SelectButton = UIUtil.CreateButtonStd(self, '/scx_menu/small-btn/small', "<LOC _Select>Select", 16, 2)
        self.SelectButton.OnClick = function(button, modifiers)
            self:Confirm()
        end

        self.CancelButton = UIUtil.CreateButtonStd(self, '/scx_menu/small-btn/small', "<LOC _Cancel>Cancel", 16, 2)
        self.CancelButton.OnClick = function(button, modifiers)
            self.OnCancelCb()
        end
    end,

    ---@param self UICustomLobbyMapSelect
    __post_init = function(self)
        self.Width:Set(LayoutHelpers.ScaleNumber(DialogWidth))
        self.Height:Set(LayoutHelpers.ScaleNumber(DialogHeight))

        Layouter(self.Title):AtTopIn(self, 14):AtHorizontalCenterIn(self):End()

        Layouter(self.Search)
            :AtLeftIn(self, 18):AtTopIn(self, 54):Width(ListWidth):Height(22)
            :End()

        Layouter(self.CancelButton):AtRightIn(self, 18):AtBottomIn(self, 14):End()
        Layouter(self.SelectButton):AnchorToLeft(self.CancelButton, 16):AtVerticalCenterIn(self.CancelButton):End()

        -- list fills the left column between the search box and the buttons
        Layouter(self.MapList)
            :AtLeftIn(self, 18)
            :Width(ListWidth - 16)            -- leave room for the scrollbar
            :AnchorToBottom(self.Search, 10)
            :AnchorToTop(self.SelectButton, 14)
            :End()
        UIUtil.CreateVertScrollbarFor(self.MapList)

        -- preview + info in the right column
        Layouter(self.Preview)
            :AtRightIn(self, 18):AtTopIn(self, 54):Width(PreviewSize):Height(PreviewSize)
            :End()
        Layouter(self.PreviewBg):Fill(self.Preview):End()
        self.PreviewBg.Depth:Set(function() return self.Preview.Depth() - 1 end)

        Layouter(self.InfoTitle):AtLeftIn(self.Preview):AnchorToBottom(self.Preview, 14):End()
        Layouter(self.InfoName):AtLeftIn(self.Preview):AnchorToBottom(self.InfoTitle, 6):End()
        Layouter(self.InfoSize):AtLeftIn(self.Preview):AnchorToBottom(self.InfoName, 4):End()
        Layouter(self.InfoPlayers):AtLeftIn(self.Preview):AnchorToBottom(self.InfoSize, 4):End()

        self.MapList:AcquireKeyboardFocus(true)
    end,

    --- Populates the list. The opener calls this AFTER the dialog is mounted + centred by
    --- Popup: `Populate` scrolls the list (`ShowItem`), which forces a concrete geometry
    --- read, and the dialog's own rect isn't settled during __post_init (Popup re-parents
    --- and re-centres it afterwards). This is the three-phase init pattern — see
    --- /lua/ui/CLAUDE.md § 1.
    ---@param self UICustomLobbyMapSelect
    Initialize = function(self)
        self:Populate()
    end,

    --- Rebuilds the list from the catalog, applying the name filter and keeping the current
    --- highlight selected (falling back to the first row).
    ---@param self UICustomLobbyMapSelect
    Populate = function(self)
        self.MapList:DeleteAllItems()

        local search = string.lower(self.Search:GetText() or "")
        self.Filtered = {}
        local selectedRow = 0

        for _, scenario in self.Scenarios do
            if search == "" or string.find(string.lower(scenario.name), search, 1, true) then
                table.insert(self.Filtered, scenario)
                self.MapList:AddItem(LOC(scenario.name))
                if self.Selected and string.lower(scenario.file) == string.lower(self.Selected.file) then
                    selectedRow = table.getn(self.Filtered) - 1
                end
            end
        end

        if table.getn(self.Filtered) > 0 then
            self.MapList:SetSelection(selectedRow)
            self.MapList:ShowItem(selectedRow)
            self:OnMapHighlighted(selectedRow)
        else
            self.Selected = nil
            self.Preview:ClearTexture()
            self:UpdateInfo(nil)
            self.SelectButton:Disable()
        end
    end,

    --- A row was highlighted: make it the candidate and refresh the preview + info.
    ---@param self UICustomLobbyMapSelect
    ---@param row number   # 0-based ItemList row
    OnMapHighlighted = function(self, row)
        local scenario = self.Filtered[row + 1]
        if not scenario then
            return
        end
        self.Selected = scenario
        self.MapList:SetSelection(row)
        self:UpdatePreview(scenario)
        self:UpdateInfo(scenario)
        self.SelectButton:Enable()
    end,

    --- Sets the preview texture for a scenario (preview image, falling back to the heightmap).
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo
    UpdatePreview = function(self, scenario)
        if not self.Preview:SetTexture(scenario.preview) then
            self.Preview:SetTextureFromMap(scenario.map)
        end
    end,

    --- Fills the info lines for a scenario (nil clears them).
    ---@param self UICustomLobbyMapSelect
    ---@param scenario UILobbyScenarioInfo | nil
    UpdateInfo = function(self, scenario)
        if not scenario then
            self.InfoName:SetText("")
            self.InfoSize:SetText("")
            self.InfoPlayers:SetText("")
            return
        end

        self.InfoName:SetText(LOC(scenario.name) or "?")

        if scenario.size then
            self.InfoSize:SetText(LOCF("<LOC map_select_0000>Map Size: %dkm x %dkm", scenario.size[1] / 50, scenario.size[2] / 50))
        else
            self.InfoSize:SetText("")
        end

        local armies = scenario.Configurations
            and scenario.Configurations.standard
            and scenario.Configurations.standard.teams
            and scenario.Configurations.standard.teams[1]
            and scenario.Configurations.standard.teams[1].armies
        if armies then
            self.InfoPlayers:SetText(LOCF("<LOC map_select_0001>Max Players: %d", table.getsize(armies)))
        else
            self.InfoPlayers:SetText("")
        end
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
        self.MapList:AbandonKeyboardFocus()
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

    -- now that Popup has mounted + centred the content, it's safe to populate (the list
    -- scroll reads concrete geometry)
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
