--*****************************************************************************
--* File: lua/modules/ui/dialogs/mapselect.lua
--* Author: Chris Blackwell
--* Summary: Dialog to facilitate map selection
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Scrollbar = import('/lua/maui/scrollbar.lua').Scrollbar
local Text = import('/lua/maui/text.lua').Text
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Button = import('/lua/maui/button.lua').Button
local Group = import('/lua/maui/group.lua').Group
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local ResourceMapPreview = import('/lua/ui/controls/resmappreview.lua').ResourceMapPreview
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local MainMenu = import('/lua/ui/menus/main.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local Mods = import('/lua/mods.lua')
local Combo = import('/lua/ui/controls/combo.lua').Combo
local Tooltip = import('/lua/ui/game/tooltip.lua')
local ModManager = import('/lua/ui/lobby/ModsManager.lua')

local scenarios = nil
local selectedScenario = false
local description = false
local descText = false
local posGroup = false
local mapList = false
local filters = {}
local filterTitle = false
local mapListTitle = false
local mapsize = false
local mapplayers = false
local mapInfo = false
local selectButton = false

-- Table contianing filter functions to apply to the map list.
local currentFilters = {}

local scenarioKeymap = {}
local Options = {}
local OptionSource = {}
local OptionContainer = false
local advOptions = false
local changedOptions = {}
local restrictedCategories = nil

local popup = nil
local dialogContent = nil

-- Maps the names of all official maps to the value "true".
local OFFICAL_MAPS = {
    ['Burial Mounds'] = true,
    ['Concord Lake'] = true,
    ["Drake's Ravine"] = true,
    ['Emerald Crater'] = true,
    ["Gentleman's Reef"] = true,
    ["Ian's Cross"] = true,
    ['Open Palms'] = true,
    ['Seraphim Glaciers'] = true,
    ["Seton's Clutch"] = true,
    ['Sung Island'] = true,
    ['The Great Void'] = true,
    ['Theta Passage'] = true,
    ['Winter Duel'] = true,
    ['The Bermuda Locket'] = true,
    ['Fields of Isis'] = true,
    ['Canis River'] = true,
    ['Syrtis Major'] = true,
    ['Sentry Point'] = true,
    ["Finn's Revenge"] = true,
    ['Roanoke Abyss'] = true,
    ['Alpha 7 Quarantine'] = true,
    ['Arctic Refuge'] = true,
    ['Varga Pass'] = true,
    ['Crossfire Canal'] = true,
    ['Saltrock Colony'] = true,
    ['Vya-3 Protectorate'] = true,
    ['The Scar'] = true,
    ['Hanna Oasis'] = true,
    ['Betrayal Ocean'] = true,
    ['Frostmill Ruins'] = true,
    ['Four-Leaf Clover'] = true,
    ['The Wilderness'] = true,
    ['White Fire'] = true,
    ['High Noon'] = true,
    ['Paradise'] = true,
    ['Blasted Rock'] = true,
    ['Sludge'] = true,
    ['Ambush Pass'] = true,
    ['Four-Corners'] = true,
    ['The Ditch'] = true,
    ['Crag Dunes'] = true,
    ["Williamson's Bridge"] = true,
    ['Snoey Triangle'] = true,
    ['Haven Reef'] = true,
    ['The Dark Heart'] = true,
    ["Daroza's Sanctuary"] = true,
    ['Strip Mine'] = true,
    ['Thawing Glacier'] = true,
    ['Liberiam Battles'] = true,
    ['Shards'] = true,
    ['Shuriken Island'] = true,
    ['Debris'] = true,
    ['Flooded Strip Mine'] = true,
    ['Eye of the Storm'] = true
}

function CheckMapIsOfficial(scenario)
    return OFFICAL_MAPS[scenario.name] == true
end

-- Maps dropdown labels to comparator functions. Used by filter factories.
local comparatorMap = {
    function(a, b) return a == b end,
    function(a, b) return a >= b end,
    function(a, b) return a <= b end
}
mapFilters = {
    {
        FilterName = "<LOC MAPSEL_0009>Supported Players",
        FilterKey = 'map_select_supportedplayers',
        Options = {
            {text = "<LOC MAPSEL_0010>All", key = 0},
            {text = "<LOC MAPSEL_0011>2", key = 2},
            {text = "<LOC MAPSEL_0012>3", key = 3},
            {text = "<LOC MAPSEL_0013>4", key = 4},
            {text = "<LOC MAPSEL_0014>5", key = 5},
            {text = "<LOC MAPSEL_0015>6", key = 6},
            {text = "<LOC MAPSEL_0016>7", key = 7},
            {text = "<LOC MAPSEL_0017>8", key = 8},
            {text = "<LOC lobui_0714>9",  key = 9},
            {text = "<LOC lobui_0715>10", key = 10},
            {text = "<LOC lobui_0716>11", key = 11},
            {text = "<LOC lobui_0717>12", key = 12},
        },
        -- Builds specialised filtering closures for the given filter configuration.
        FilterFactory = {
            SelectedKey = 0,
            SelectedComparator = 1,
            Build = function(self)
                -- Closure copy.
                local compareFunc = comparatorMap[self.SelectedComparator]
                local targetValue = self.SelectedKey
                return function(scenInfo)
                    local startPositions = table.getsize(scenInfo.Configurations.standard.teams[1].armies)
                    return compareFunc(startPositions, targetValue)
                end
            end
        }
    },
    {
        FilterName = "<LOC MAPSEL_0024>Map Size",
        FilterKey = 'map_select_size',
        Options = {
            {text = "<LOC MAPSEL_0025>All", key = 0},
            {text = "<LOC MAPSEL_0026>5km", key = 256},
            {text = "<LOC MAPSEL_0027>10km", key = 512},
            {text = "<LOC MAPSEL_0028>20km", key = 1024},
            {text = "<LOC MAPSEL_0029>40km", key = 2048},
            {text = "<LOC MAPSEL_0030>81km", key = 4096},
        },
        FilterFactory = {
            SelectedKey = 0,
            SelectedComparator = 1,
            Build = function(self)
                local compareFunc = comparatorMap[self.SelectedComparator]
                local targetValue = self.SelectedKey
                return function(scenInfo)
                    return compareFunc(scenInfo.size[1], targetValue)
                end
            end
        }
    },
    {
        FilterName = "<LOC lobui_0575>Map Type",
        FilterKey = 'map_type',
        NoDelimiter = true,
        Options = {
            {text = "<LOC MAPSEL_0025>All", key = 0},
            {text = "<LOC lobui_0576>Official", key = 1},
            {text = "<LOC lobui_0577>Custom", key = 2},
        },
        FilterFactory = {
            SelectedKey = 0,
            Filters = {
                CheckMapIsOfficial,
                function(scenInfo) return not CheckMapIsOfficial(scenInfo) end
            },
            Build = function(self)
                return self.Filters[self.SelectedKey]
            end
        },
    },
    {
        FilterName = "<LOC lobui_0585>AI Markers",
        FilterKey = 'map_ai_markers',
        NoDelimiter = true,
        Options = {
            {text = "<LOC MAPSEL_0025>All", key = 0},
            {text = "<LOC _Yes>Yes", key = 1},
            {text = "<LOC _No>No", key = 2},
        },
        FilterFactory = {
            SelectedKey = 0,
            Filters = {
                MapUtil.CheckMapHasMarkers,
                function(scenInfo) return not MapUtil.CheckMapHasMarkers(scenInfo) end
            },
            Build = function(self)
                return self.Filters[self.SelectedKey]
            end
        },
    },
}

-- Create a filter dropdown and title from the table above
function CreateFilter(parent, filterData)
    local group = Group(parent)
    group.Width:Set(286)

    group.title = UIUtil.CreateText(group, filterData.FilterName, 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(group.title, group, 2)
    Tooltip.AddControlTooltip(group.title, filterData.FilterKey)
    group.Height:Set(function() return group.title.Height() + 4 end)

    group.combo = Combo(group, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.AtVerticalCenterIn(group.combo, group.title)
    group.combo.Right:Set(function() return group.Right() - 10 end)
    group.combo.Width:Set(80)

    local comboBg = Bitmap(group)
    comboBg.Depth:Set(group.Depth)
    comboBg.Width:Set(group.Width() + 4)
    comboBg.Height:Set(group.Height() + 4)
    LayoutHelpers.AtLeftTopIn(comboBg, group, -2, -4)
    comboBg:SetTexture(UIUtil.UIFile('/dialogs/mapselect03/options-panel-bar_bmp.dds'))

    local itemArray = {}
    local keyMap = {}
    for index, val in filterData.Options do
        itemArray[index] = val.text
        keyMap[index] = val.key
    end

    local filterKey = filterData.FilterKey
    local filterEntry = filterData -- Closure copy.
    group.combo:AddItems(itemArray, 1)

    group.combo.OnClick = function(self, index, text)
        local factory = filterEntry.FilterFactory
        factory.SelectedKey = keyMap[index]

        -- Key zero represents the null filter.
        if keyMap[index] == 0 then
            currentFilters[filterKey] = nil
        else
            currentFilters[filterKey] = factory:Build()
        end

        PopulateMapList()
    end

    if not filterData.NoDelimiter then
        group.comboFilter = Combo(group, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.AtVerticalCenterIn(group.comboFilter, group.title)
        group.comboFilter.Right:Set(function() return group.combo.Left() - 5 end)
        group.comboFilter.Width:Set(60)

        group.comboFilter:AddItems({"=", ">=", "<="}, 1)

        group.comboFilter.OnClick = function(self, index, text)
            local factory = filterEntry.FilterFactory
            factory.SelectedComparator = index

            -- Don't activate the filter if the other dropdown has turned it off.
            if factory.SelectedKey ~= 0 then
                currentFilters[filterKey] = factory:Build()
            end

            PopulateMapList()
        end
    end

    group.Height:Set(group.title.Height())

    return group
end

local function ResetFilters()
    currentFilters = {}
    changedOptions = {}
    selectedScenario = nil
    restrictedCategories = nil
end

--- Ensure that scenarios have been loaded from disk
--
-- @param force Reload the scenario files from disk even if we have a cached copy (use if you've
-- caused map files to change on disk and want the results reflected)
function LoadScenarios(force)
    if not scenarios or force then
        scenarios = MapUtil.EnumerateSkirmishScenarios()
    end

    return scenarios
end

function CreateDialog(selectBehavior, exitBehavior, over, singlePlayer, defaultScenarioName, curOptions, availableMods, OnModsChanged)
    LoadScenarios()

    -- control layout
    dialogContent = Group(over)
    dialogContent.Width:Set(956)
    dialogContent.Height:Set(692)

    popup = Popup(over, dialogContent)

    local title = UIUtil.CreateText(dialogContent, "<LOC map_sel_0000>", 24)
    LayoutHelpers.AtTopIn(title, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
    dialogContent.title = title

    local cancelButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Cancel>")
    LayoutHelpers.AtRightIn(cancelButton, dialogContent, -2)
    LayoutHelpers.AtBottomIn(cancelButton, dialogContent, 10)
    dialogContent.cancelButton = cancelButton

    selectButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _OK>")
    LayoutHelpers.LeftOf(selectButton, cancelButton, 72)
    dialogContent.selectButton = selectButton

    local doNotRepeatMap
    local randomMapButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC lobui_0503>Random Map")
    LayoutHelpers.AtHorizontalCenterIn(randomMapButton, dialogContent)
    LayoutHelpers.AtVerticalCenterIn(randomMapButton, selectButton)
    Tooltip.AddButtonTooltip(randomMapButton, 'lob_click_randmap')
    dialogContent.randomMapButton = randomMapButton

    randomMapButton.OnClick = function(self, modifiers)
        local randomMapIndex
        repeat
            randomMapIndex = math.random(0, mapList:GetItemCount() - 1)
        until randomMapIndex ~= mapList:GetSelection()

        mapList:OnClick(randomMapIndex)
    end
    function randomAutoMap(official)
        local nummapa
        nummapa = math.random(1, randMapList)
        if randMapList >= 2 and nummapa == doNotRepeatMap then
            repeat
                nummapa = math.random(1, randMapList)
            until nummapa ~= doNotRepeatMap
        end
        doNotRepeatMap = nummapa
        local scen = scenarios[scenarioKeymap[nummapa]]
        if official then
            if not CheckMapIsOfficial(scen) then
                return randomAutoMap(true)
            end
        end
        selectedScenario = scen
        selectBehavior(selectedScenario, changedOptions, restrictedCategories)
        ResetFilters()
    end

    local restrictedUnitsButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC sel_map_0006>Unit Manager")
    LayoutHelpers.LeftOf(restrictedUnitsButton, randomMapButton, 81)
    Tooltip.AddButtonTooltip(restrictedUnitsButton, "lob_RestrictedUnits")
    dialogContent.restrictedUnitsButton = restrictedUnitsButton

    if not restrictedCategories then
        restrictedCategories = curOptions.RestrictedCategories
    end
    restrictedUnitsButton.OnClick = function(self, modifiers)
        mapList:AbandonKeyboardFocus()
        import('/lua/ui/lobby/restrictedUnitsDlg.lua').CreateDialog(dialogContent,
            restrictedCategories,
            function(rc)
                restrictedCategories = rc
                mapList:AcquireKeyboardFocus(true)
            end,
            function()
                mapList:AcquireKeyboardFocus(true)
            end,
            true)
    end

    local modButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC tooltipui0145>")
    LayoutHelpers.LeftOf(modButton, restrictedUnitsButton, 74)
    Tooltip.AddButtonTooltip(modButton, "Lobby_Mods")
    modButton.OnClick = function(self, modifiers)
        ModManager.CreateDialog(dialogContent, availableMods)
    end
    dialogContent.modButton = modButton

    UIUtil.MakeInputModal(dialogContent)

    local MAP_PREVIEW_SIZE = 292
    local preview = ResourceMapPreview(dialogContent, MAP_PREVIEW_SIZE, 5, 8, true)
    UIUtil.SurroundWithBorder(preview, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.AtLeftTopIn(preview, dialogContent, 19, 50)
    dialogContent.preview = preview

    local nopreviewtext = UIUtil.CreateText(dialogContent, "<LOC _No_Preview>No Preview", 24)
    LayoutHelpers.AtCenterIn(nopreviewtext, preview)
    nopreviewtext:Hide()
    dialogContent.nopreviewtext = nopreviewtext

    -- A Group to enclose the map info elements.
    local mapInfoGroup = Group(dialogContent)
    mapInfoGroup.Width:Set(MAP_PREVIEW_SIZE)
    LayoutHelpers.Below(mapInfoGroup, preview, 23)
    dialogContent.mapInfoGroup = mapInfoGroup
    local descriptionTitle = UIUtil.CreateText(dialogContent, "<LOC sel_map_0000>Map Info", 18)
    LayoutHelpers.AtLeftTopIn(descriptionTitle, mapInfoGroup, 4, 2)
    mapInfoGroup.title = descriptionTitle

    description = ItemList(mapInfoGroup, "mapselect:description")
    description:SetFont(UIUtil.bodyFont, 14)
    description:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
    description.Width:Set(271)
    description.Height:Set(234)
    LayoutHelpers.Below(description, descriptionTitle)
    UIUtil.CreateLobbyVertScrollbar(description, 2, -1, -25)
    mapInfoGroup.Bottom:Set(description.Bottom)
    UIUtil.SurroundWithBorder(mapInfoGroup, '/scx_menu/lan-game-lobby/frame/')
    mapInfoGroup.description = description

    -- A Group to contain the filter UI elements.
    local filterGroup = Group(dialogContent)
    UIUtil.SurroundWithBorder(filterGroup, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.RightOf(filterGroup, preview, 23)
    dialogContent.filterGroup = filterGroup

    filterTitle = UIUtil.CreateText(filterGroup, "<LOC sel_map_0003>Filters", 18)
    LayoutHelpers.AtLeftTopIn(filterTitle, filterGroup, 4, 2)
    filterGroup.title = filterTitle

    for i, filterData in mapFilters do
        filters[i] = CreateFilter(filterTitle, filterData)
        if i == 1 then
            LayoutHelpers.Below(filters[1], filterTitle)
            LayoutHelpers.AtLeftIn(filters[1], filterTitle, 1)
        else
            LayoutHelpers.Below(filters[i], filters[i - 1], 10)
        end
    end

    -- Expand the group to encompass all the filter controls
    filterGroup.Bottom:Set(function() return filters[table.getn(filters)].Bottom() + 3 end)
    filterGroup.Right:Set(function() return filters[table.getn(filters)].Right() + 1 end)

    local mapSelectGroup = Group(dialogContent)
    dialogContent.mapSelectGroup = mapSelectGroup
    UIUtil.SurroundWithBorder(mapSelectGroup, '/scx_menu/lan-game-lobby/frame/')
    mapSelectGroup.Right:Set(filterGroup.Right)
    LayoutHelpers.Below(mapSelectGroup, filterGroup, 23)
    mapListTitle = UIUtil.CreateText(dialogContent, "<LOC sel_map_0005>Maps", 18)
    LayoutHelpers.AtLeftTopIn(mapListTitle, mapSelectGroup, 4, 2)
    mapSelectGroup.title = mapListTitle

    mapList = ItemList(dialogContent, "mapselect:mapList")
    mapSelectGroup.mapList = mapList
    mapList:SetFont(UIUtil.bodyFont, 14)
    mapList:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    mapList:ShowMouseoverItem(true)
    --TODO what is this getting under when it's in over state?
    mapList.Depth:Set(function() return dialogContent.Depth() + 10 end)
    -- Allocating space for the scrollbar.
    mapList.Width:Set(function() return mapSelectGroup.Width() - 21 end)
    mapList.Bottom:Set(mapInfoGroup.Bottom)
    LayoutHelpers.Below(mapList, mapListTitle)
    mapList:AcquireKeyboardFocus(true)
    mapList.OnDestroy = function(control)
        mapList:AbandonKeyboardFocus()
        ItemList.OnDestroy(control)
    end
    mapSelectGroup.Bottom:Set(mapList.Bottom)

    mapList.HandleEvent = function(self,event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE then
                cancelButton:OnClick()
                return true
            elseif event.KeyCode == UIUtil.VK_ENTER then
                selectButton:OnClick()
                return true
            end
        end

        return ItemList.HandleEvent(self,event)
    end

    UIUtil.CreateLobbyVertScrollbar(mapList, 2, -1, -25)

    -- initialize controls
    PopulateMapList()

    local OptionGroup = Group(dialogContent)
    dialogContent.OptionGroup = OptionGroup
    UIUtil.SurroundWithBorder(OptionGroup, '/scx_menu/lan-game-lobby/frame/')
    OptionGroup.Width:Set(290)
    OptionGroup.Bottom:Set(mapSelectGroup.Bottom)
    LayoutHelpers.RightOf(OptionGroup, filterGroup, 23)
    SetupOptionsPanel(OptionGroup, singlePlayer, curOptions)

    selectButton.OnClick = function(self, modifiers)
        selectBehavior(selectedScenario, changedOptions, restrictedCategories)
        ResetFilters()
    end

    cancelButton.OnClick = function(self, modifiers)
        exitBehavior()
        ResetFilters()
    end

    function PreloadMap(row)
        local scen = scenarios[scenarioKeymap[row+1]]
        if scen == selectedScenario then
            return
        end
        selectedScenario = scen
        local mapfile = scen.map
        if DiskGetFileInfo(mapfile) then
            advOptions = scen.options
            MapUtil.ValidateScenarioOptions(advOptions)
            RefreshOptions(false, singlePlayer)
            preview:SetScenario(scen)
            nopreviewtext:Hide()
            SetDescription(scen)
        else
            WARN("No scenario map file defined")
            nopreviewtext:Show()
            description:DeleteAllItems()
            description:AddItem(LOC("<LOC MAPSEL_0000>No description available."))
            mapplayers:SetText(LOCF("<LOC map_select_0002>NO START SPOTS DEFINED"))
            mapsize:SetText(LOCF("<LOC map_select_0003>NO MAP SIZE INFORMATION"))
            selectButton:Disable()
        end
    end

    -- Called when the selected map is changed.
    local onItemChanged = function(self, row, noSound)
        mapList:SetSelection(row)
        PreloadMap(row)
        local sound = Sound({Cue = "UI_Skirmish_Map_Select", Bank = "Interface"})
        if not noSound then
            PlaySound(sound)
        end
    end

    mapList.OnKeySelect = onItemChanged
    mapList.OnClick = onItemChanged
    mapList.OnDoubleClick = function(self, row)
        mapList:SetSelection(row)
        PreloadMap(row)
        local scen = scenarios[scenarioKeymap[row+1]]
        selectedScenario = scen
        selectBehavior(selectedScenario, changedOptions, restrictedCategories)
        ResetFilters()
    end

    -- set list to first item or default
    defaultRow = 0
    if defaultScenarioName then
        for i, scenario in scenarios do
            if string.lower(scenario.file) == string.lower(defaultScenarioName) then
                defaultRow = i - 1
                break
            end
        end
    end

    mapList:OnClick(defaultRow, true)
    mapList:ShowItem(defaultRow)

    return popup
end

function RefreshOptions(skipRefresh, singlePlayer)
    -- a little weird, but the "skip refresh" is set to prevent calc visible from being called before the control is properly setup
    -- it also means it's a flag that tells you this is the first time the dialog has been opened
    -- so we'll use this flag to reset the options sources so they can set up for multiplayer
    if skipRefresh then
        OptionSource[1] = {title = "<LOC uilobby_0001>Team Options", options = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions}
        OptionSource[2] = {title = "<LOC uilobby_0002>Game Options", options = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts}
        OptionSource[3] = {title = "AI Options", options = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts}
    end
    OptionSource[4] = {title = "<LOC lobui_0164>Advanced", options = advOptions or {}}

    Options = {}

    --- Check that the given option source has at least one option with at least 2 possibilities, or
    -- there's no need to draw the UI. Maps/mods can cause whole categories to vanish, and we don't
    -- want to leave a dangling title.
    local function ShouldShowOptionCategory(options)
        for k, optionData in options do
            if table.getn(optionData.values) > 1 then
                return true
            end
        end

        return false
    end

    for _, OptionTable in OptionSource do
        if ShouldShowOptionCategory(OptionTable.options) then
            table.insert(Options, {type = 'title', text = OptionTable.title})
            for optionIndex, optionData in OptionTable.options do
                if not(singlePlayer and optionData.mponly == true) and table.getn(optionData.values) > 1 then
                    table.insert(Options, {type = 'option', text = optionData.label, data = optionData, default = optionData.default}) -- option1 for teamOptions for exemple
                end
            end
        end
    end
    if not skipRefresh then
        OptionContainer:CalcVisible()
    end
end

function SetupOptionsPanel(parent, singlePlayer, curOptions)
    local title = UIUtil.CreateText(parent, '<LOC PROFILE_0012>', 18)
    LayoutHelpers.AtLeftTopIn(title, parent, 4, 2)
    parent.title = title

    OptionContainer = Group(parent)
    OptionContainer.Height:Set(function() return parent.Height() - title.Height() end)
    OptionContainer.Width:Set(function() return parent.Width() - 18 end)
    OptionContainer.top = 0
    LayoutHelpers.Below(OptionContainer, title, 2)

    local OptionDisplay = {}
    RefreshOptions(true, singlePlayer)

    local function CreateOptionCombo(parent)
        local combo = Combo(parent, nil, nil, nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        combo.Width:Set(266)
        local itemArray = {}
        combo.keyMap = {}
        local tooltipTable = {}
        Tooltip.AddComboTooltip(combo, tooltipTable, combo._list)
        combo.UpdateValue = function(key)
            combo:SetItem(combo.keyMap[key])
        end

        return combo
    end

    local function CreateOptionElements()
        local function CreateElement(index)
            local optionGroup = Group(OptionContainer)
            optionGroup.Height:Set(46)
            optionGroup.Width:Set(function() return OptionContainer.Width() + 4 end)

            optionGroup.bg = Bitmap(optionGroup)
            optionGroup.bg.Depth:Set(optionGroup.Depth)
            LayoutHelpers.FillParent(optionGroup.bg, optionGroup)
            optionGroup.bg.Right:Set(optionGroup.Right)

            optionGroup.text = UIUtil.CreateText(OptionContainer, '', 14, "Arial")
            optionGroup.text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(optionGroup.text, optionGroup, 10)

            optionGroup.combo = CreateOptionCombo(optionGroup)
            LayoutHelpers.AtLeftTopIn(optionGroup.combo, optionGroup, 5, 22)
            OptionDisplay[index] = optionGroup
        end

        CreateElement(1)
        LayoutHelpers.Below(OptionDisplay[1], title, -3)
        LayoutHelpers.AtLeftIn(OptionDisplay[1], title, -5)

        local index = 2
        while OptionDisplay[table.getsize(OptionDisplay)].Bottom() + OptionDisplay[1].Height() < OptionContainer.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(OptionDisplay[index], OptionDisplay[index-1])
            index = index + 1
        end
    end
    CreateOptionElements()

    local numLines = function() return table.getsize(OptionDisplay) end

    local function DataSize()
        return table.getn(Options)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    OptionContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    OptionContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    OptionContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    OptionContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    OptionContainer.IsScrollable = function(self, axis)
        return true
    end

    -- determines what controls should be visible or not
    OptionContainer.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            if data.type == 'title' then
                line.text:SetText(LOC(data.text))
                line.text:SetFont(UIUtil.titleFont, 14, 3)
                line.text:SetColor(UIUtil.fontOverColor)
                line.bg:SetSolidColor('00000000')
                line.combo:Hide()
                LayoutHelpers.AtLeftTopIn(line.text, line, 0, 20)
                LayoutHelpers.AtHorizontalCenterIn(line.text, line)
            elseif data.type == 'spacer' then
                line.text:SetText('')
                line.combo:Hide()
            else
                line.text:SetText(LOC(data.text))
                line.text:SetFont(UIUtil.bodyFont, 14)
                line.text:SetColor(UIUtil.fontColor)
                line.bg:SetTexture(UIUtil.UIFile('/dialogs/mapselect03/options-panel-bar_bmp.dds'))
                LayoutHelpers.AtLeftTopIn(line.text, line, 10, 5)
                line.combo:ClearItems()
                line.combo:Show()
                local itemArray = {}
                line.combo.keyMap = {}
                local tooltipTable = {}
                
                local defValue = false
                local realDefValue = false
                
                for index, val in data.data.values do
                    itemArray[index] = val.text
                    line.combo.keyMap[val.key] = index
                    tooltipTable[index]={text=data.data.label,body=val.help}
                    --
                    if curOptions[data.data.key] and val.key == curOptions[data.data.key] then
                        defValue = index
                    end
                end

                if changedOptions[data.data.key].index then
                    defValue = changedOptions[data.data.key].index
                else
                    defValue = line.combo.keyMap[curOptions[data.data.key]] or data.data.default or 1
                end
                --
                if data.data.default then realDefValue = data.data.default end
                line.combo:AddItems(itemArray, defValue, realDefValue, true) -- For all (true for enable (default) label)
                line.combo.OnClick = function(self, index, text)
                    changedOptions[data.data.key] = {value = data.data.values[index].key, index = index}
                    if line.combo.EnableColor then
                        line.combo._text:SetColor('DBBADB')
                    end
                end
                line.HandleEvent = Group.HandleEvent
                Tooltip.AddControlTooltip(line, {text=data.data.label,body=data.data.help})
                Tooltip.AddComboTooltip(line.combo, tooltipTable, line.combo._list)
                line.combo.UpdateValue = function(key)
                    line.combo:SetItem(line.combo.keyMap[key])
                end
            end
        end
        for i, v in OptionDisplay do
            if Options[i + self.top] then
                SetTextLine(v, Options[i + self.top], i + self.top)
            else
                v.text:SetText('')
                v.combo:Hide()
                v.bg:SetSolidColor('00000000')
            end
        end
    end

    OptionContainer:CalcVisible()

    OptionContainer.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end

    UIUtil.CreateLobbyVertScrollbar(OptionContainer, -1, -5, -27)
end

function SetDescription(scen)
    local errors = false
    description:DeleteAllItems()
    if scen.name then
        description:AddItem(scen.name)
    else
        description:AddItem(LOC("<LOC map_select_0006>No Scenario Name"))
        errors = true
    end
    if scen.map_version then
        local verStr = LOC("<LOC MAINMENU_0007>Version: ") .. scen.map_version
        description:AddItem(verStr)
    end
    if scen.size then
        description:AddItem(LOCF("<LOC map_select_0000>Map Size: %dkm x %dkm", scen.size[1]/50, scen.size[2]/50))
    else
        description:AddItem(LOCF("<LOC map_select_0004>NO MAP SIZE INFORMATION"))
        errors = true
    end
    if scen.Configurations.standard.teams[1].armies then
        local maxplayers = table.getsize(scen.Configurations.standard.teams[1].armies)
        description:AddItem(LOCF("<LOC map_select_0001>Max Players: %d", maxplayers))
    else
        description:AddItem(LOCF("<LOC map_select_0005>NO START SPOTS DEFINED"))
        errors = true
    end

    if MapUtil.CheckMapHasMarkers(scen) then
        description:AddItem("AI Markers: Yes")
    else
        description:AddItem("AI Markers: No")
    end

    description:AddItem("")
    if scen.description then
        local textBoxWidth = description.Width()
        local wrapped = import('/lua/maui/text.lua').WrapText(LOC(scen.description), textBoxWidth,
            function(curText) return description:GetStringAdvance(curText) end)
        for i, line in wrapped do
            description:AddItem(line)
        end
    else
        description:AddItem(LOC("<LOC map_select_0007>No Scenario Description"))
        errors = true
    end
    if errors then
        selectButton:Disable()
    else
        selectButton:Enable()
    end
end

function PopulateMapList()
    mapList:DeleteAllItems()
    local count = 1
    for i,sceninfo in scenarios do
        local passedFiltering = true
        -- Subject this map to every activated filter.
        for k, filter in currentFilters do
            if not filter(sceninfo) then
                passedFiltering = false
                break
            end
        end

        if passedFiltering then
            scenarioKeymap[count] = i
            count = count + 1
            mapList:AddItem(LOC(sceninfo.name))
        end
    end

    randMapList = count - 1

    if randMapList == 0 then
        mapListTitle:SetText(LOCF("<LOC lobui_0579>No Map Available", randMapList))
    elseif randMapList == 1 then
        mapListTitle:SetText(LOCF("<LOC lobui_0580>%d Map Available", randMapList))
    else
        mapListTitle:SetText(LOCF("<LOC lobui_0581>%d Maps Available", randMapList))
    end
end
