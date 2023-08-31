--*****************************************************************************
--* File: lua/modules/ui/dialogs/mapselect.lua
--* Author: Chris Blackwell
--* Summary: Dialog to facilitate map selection
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Edit = import("/lua/maui/edit.lua").Edit
local Group = import("/lua/maui/group.lua").Group
local ResourceMapPreview = import("/lua/ui/controls/resmappreview.lua").ResourceMapPreview
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local MapUtil = import("/lua/ui/maputil.lua")
local Combo = import("/lua/ui/controls/combo.lua").Combo
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Prefs = import("/lua/user/prefs.lua")

local scenarios = nil
local selectedScenario = nil
local isSinglePlayer = nil
local description = nil
local descText = nil
local posGroup = nil
local mapList = nil
local filters = {}
local filterTitle = nil
local mapListTitle = nil
local mapsize = nil
local mapplayers = nil
local mapInfo = nil
local preview = nil
local selectButton = nil

-- Table containing filter functions to apply to the map list.
local currentFilters = {}
local nameFilter = nil

local scenarioKeymap = {}
local Options = {}
local OptionSource = {}
local OptionContainer = nil
local advOptions = nil
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
            {text = "<LOC MAPSEL_0040>9",  key = 9},
            {text = "<LOC MAPSEL_0041>10", key = 10},
            {text = "<LOC MAPSEL_0042>11", key = 11},
            {text = "<LOC MAPSEL_0043>12", key = 12},
            {text = "<LOC MAPSEL_0044>13", key = 13},
            {text = "<LOC MAPSEL_0045>14", key = 14},
            {text = "<LOC MAPSEL_0046>15", key = 15},
            {text = "<LOC MAPSEL_0047>16", key = 16},
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
        FilterName = "<LOC MAPSEL_0032>Map Type",
        FilterKey = 'map_type',
        NoDelimiter = true,
        Options = {
            {text = "<LOC MAPSEL_0025>All", key = 0},
            {text = "<LOC MAPSEL_0033>Official", key = 1},
            {text = "<LOC MAPSEL_0034>Custom", key = 2},
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
    {
        FilterName = "<LOC MAPSEL_0035>Hide Obsolete",
        FilterKey = 'map_obsolete',
        NoDelimiter = true,
        Options = {
            {text = "<LOC _Yes>Yes", key = 1},
            {text = "<LOC _No>No", key = 0},
        },
        FilterFactory = {
            SelectedKey = 1,
            Filters = {
                function(scenInfo)
                    if CheckMapIsOfficial(scenInfo) then
                        return true
                    end
                    if scenInfo.Outdated then
                        return false
                    end
                    local version = scenInfo.map_version or 0
                    for _,comparisionlist in scenarios do
                        if scenInfo.name == comparisionlist.name then
                            if comparisionlist.map_version then
                                if version < comparisionlist.map_version then
                                    return false
                                end
                            end
                        end
                    end
                    return true
                end
            },
            Build = function(self)
                return self.Filters[self.SelectedKey]
            end
        },
    },
}

-- Eeeewww
local function GetFilterIndex(filterKey)
    for k, v in mapFilters do
        if v.FilterKey == filterKey then
            return k
        end
    end
end

--- Load old filter config from the prefs file and configure accordingly.
function InitFilters()
    currentFilters = {}
    local savedFilterState = Prefs.GetFromCurrentProfile("stored_filter_state") or {
        map_obsolete = {
            SelectedKey = 1 -- Enable obsolete map filtering by default.
        }
    }
    savedFilterState['map_obsolete'] = {
        SelectedKey = 1 -- Enable obsolete map filtering by default.
    }

    -- savedFilterState is an array of tables of filter options
    for filterKey, v in savedFilterState do
        local filter = mapFilters[GetFilterIndex(filterKey)]
        local factory = filter.FilterFactory
        factory.SelectedKey = v.SelectedKey
        factory.SelectedComparator = v.SelectedComparator
        currentFilters[filter.FilterKey] = factory:Build()
    end
end

--- Write the current filter configuration to the preferences file.
function SaveFilterState()

    local pickled = {}
    for filterKey, v in currentFilters do
        local index = GetFilterIndex(filterKey)

        -- Read off the factory configuration
        local factory = mapFilters[index].FilterFactory
        pickled[filterKey] = {
            SelectedKey = factory.SelectedKey,
            SelectedComparator = factory.SelectedComparator
        }

    end

    Prefs.SetToCurrentProfile("stored_filter_state", pickled)
end

-- Create a filter dropdown and title from the table above
function CreateFilter(parent, filterData)
    local group = Group(parent)
    LayoutHelpers.SetWidth(group, 286)

    group.title = UIUtil.CreateText(group, filterData.FilterName, 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(group.title, group, 2)
    Tooltip.AddControlTooltip(group.title, filterData.FilterKey)
    group.Height:Set(function() return group.title.Height() + 4 end)

    group.combo = Combo(group, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.AtVerticalCenterIn(group.combo, group.title)
    LayoutHelpers.AtRightIn(group.combo, group, 10)
    LayoutHelpers.SetWidth(group.combo, 80)

    local comboBg = Bitmap(group)
    comboBg.Depth:Set(group.Depth)
    comboBg.Width:Set(group.Width() + LayoutHelpers.ScaleNumber(4))
    comboBg.Height:Set(group.Height() + LayoutHelpers.ScaleNumber(4))
    LayoutHelpers.AtLeftTopIn(comboBg, group, -2, -4)
    comboBg:SetTexture(UIUtil.UIFile('/dialogs/mapselect03/options-panel-bar_bmp.dds'))

    local itemArray = {}
    local keyMap = {}
    for index, val in filterData.Options do
        itemArray[index] = val.text
        keyMap[index] = val.key
    end

    local filterKey = filterData.FilterKey
    local filterIndex = GetFilterIndex(filterKey)
    local filterEntry = filterData -- Closure copy.

    -- Relate filter keys back to combo indexes, and use it to set up the initial UI state correctly
    local filterOptions = mapFilters[filterIndex].Options
    local filterFactory = mapFilters[filterIndex].FilterFactory
    for i, v in filterOptions do
        if v.key == filterFactory.SelectedKey then
            group.combo:AddItems(itemArray, i)
            break
        end
    end

    group.combo.OnClick = function(self, index, text)
        local factory = filterEntry.FilterFactory
        factory.SelectedKey = keyMap[index]

        -- Key zero represents the null filter.
        if keyMap[index] == 0 then
            currentFilters[filterKey] = nil
        else
            currentFilters[filterKey] = factory:Build()
        end

        SaveFilterState()
        PopulateMapList()
    end

    if not filterData.NoDelimiter then
        group.comboFilter = Combo(group, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.AtVerticalCenterIn(group.comboFilter, group.title)
        LayoutHelpers.AnchorToLeft(group.comboFilter, group.combo, 5)
        LayoutHelpers.SetWidth(group.comboFilter, 60)

        group.comboFilter:AddItems({"=", ">=", "<="}, filterFactory.SelectedComparator)

        group.comboFilter.OnClick = function(self, index, text)
            local factory = filterEntry.FilterFactory
            factory.SelectedComparator = index

            -- Don't activate the filter if the other dropdown has turned it off.
            if factory.SelectedKey ~= 0 then
                currentFilters[filterKey] = factory:Build()
            end

            SaveFilterState()
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

function PreloadMap(row)
    local scen = scenarios[scenarioKeymap[row+1]]

    selectedScenario = scen
    local mapfile = scen.map
    if DiskGetFileInfo(mapfile) then
        advOptions = scen.options
        MapUtil.ValidateScenarioOptions(advOptions)
        RefreshOptions(false)
        preview:SetScenario(scen)
        SetDescription(scen)
    else
        WARN("No scenario map file defined")
        description:DeleteAllItems()
        description:AddItem(LOC("<LOC MAPSEL_0000>No description available."))
        mapplayers:SetText(LOCF("<LOC map_select_0002>NO START SPOTS DEFINED"))
        mapsize:SetText(LOCF("<LOC map_select_0003>NO MAP SIZE INFORMATION"))
        selectButton:Disable()
    end
end

-- Called when the selected map is changed.
local OnMapChanged = function(self, row, noSound)
    mapList:SetSelection(row)
    PreloadMap(row)
    local sound = Sound({Cue = "UI_Skirmish_Map_Select", Bank = "Interface"})
    if not noSound then
        PlaySound(sound)
    end
end

function CreateDialog(selectBehavior, exitBehavior, over, singlePlayer, defaultScenarioName, curOptions, availableMods, OnModsChanged)
    LoadScenarios()

    -- Initialise the selected scenario from the name we were passed.
    for i, scenario in scenarios do
        if string.lower(scenario.file) == string.lower(defaultScenarioName) then
            selectedScenario = scenario
        end
    end

    InitFilters()
    isSinglePlayer = singlePlayer

    -- control layout
    dialogContent = Group(over)
    LayoutHelpers.SetDimensions(dialogContent, 956, 692)

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
    local randomMapButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC lobui_0501>Random Map")
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
        import("/lua/ui/lobby/unitsmanager.lua").CreateDialog(dialogContent,
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
        -- direct import allows data caching in ModsManager
        import("/lua/ui/lobby/modsmanager.lua").CreateDialog(dialogContent, true, availableMods, OnModsChanged)
    end
    dialogContent.modButton = modButton

    UIUtil.MakeInputModal(dialogContent)

    local MAP_PREVIEW_SIZE = 292
    preview = ResourceMapPreview(dialogContent, MAP_PREVIEW_SIZE, 5, 8, true)
    UIUtil.SurroundWithBorder(preview, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.AtLeftTopIn(preview, dialogContent, 19, 50)
    dialogContent.preview = preview

    -- A Group to enclose the map info elements.
    local mapInfoGroup = Group(dialogContent)
    LayoutHelpers.SetWidth(mapInfoGroup, MAP_PREVIEW_SIZE)
    LayoutHelpers.Below(mapInfoGroup, preview, 23)
    dialogContent.mapInfoGroup = mapInfoGroup
    local descriptionTitle = UIUtil.CreateText(dialogContent, "<LOC sel_map_0000>Map Info", 18)
    LayoutHelpers.AtLeftTopIn(descriptionTitle, mapInfoGroup, 4, 2)
    mapInfoGroup.title = descriptionTitle

    description = ItemList(mapInfoGroup, "mapselect:description")
    description:SetFont(UIUtil.bodyFont, 14)
    description:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
    LayoutHelpers.SetDimensions(description, 271, 234)
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

    namefilterTitle = UIUtil.CreateText(filterGroup, "<LOC sel_map_0007>Name Filter", 18)
    LayoutHelpers.Below(namefilterTitle, filters[table.getn(filters)], 10)

    filterName = Edit(filterGroup)
    LayoutHelpers.SetDimensions(filterName, MAP_PREVIEW_SIZE, 22)
    filterName:SetFont(UIUtil.bodyFont, 16)
    filterName:SetForegroundColor(UIUtil.fontColor)
    filterName:ShowBackground(true)
    filterName:SetBackgroundColor('77778888')
    filterName:SetCaretColor('ffff9999')
    filterName:SetDropShadow(true)
    LayoutHelpers.Below(filterName, namefilterTitle)

    filterName.OnTextChanged = function(self, newText, oldText)
      PopulateMapList()
    end

    nameFilter = filterName

    -- Expand the group to encompass all the filter controls
    LayoutHelpers.AtBottomIn(filterGroup, filterName, -3)
    LayoutHelpers.AtRightIn(filterGroup, filters[table.getn(filters)], -1)

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
    mapList.Width:Set(function() return mapSelectGroup.Width() - LayoutHelpers.ScaleNumber(21) end)
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

    local OptionGroup = Group(dialogContent)
    dialogContent.OptionGroup = OptionGroup
    UIUtil.SurroundWithBorder(OptionGroup, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.SetWidth(OptionGroup, 290)
    OptionGroup.Bottom:Set(mapSelectGroup.Bottom)
    LayoutHelpers.RightOf(OptionGroup, filterGroup, 23)
    SetupOptionsPanel(OptionGroup, curOptions)

    selectButton.OnClick = function(self, modifiers)
        if mapIsOutdated() then
            GUI_OldMap(over)
        end
        selectBehavior(selectedScenario, changedOptions, restrictedCategories)
        ResetFilters()
    end

    cancelButton.OnClick = function(self, modifiers)
        exitBehavior()
        ResetFilters()
    end

    mapList.OnKeySelect = OnMapChanged
    mapList.OnClick = OnMapChanged
    mapList.OnDoubleClick = function(self, row)
        if mapIsOutdated() then
            GUI_OldMap(over)
        end
        mapList:SetSelection(row)
        PreloadMap(row)
        local scen = scenarios[scenarioKeymap[row+1]]
        selectedScenario = scen
        selectBehavior(selectedScenario, changedOptions, restrictedCategories)
        ResetFilters()
    end

    PopulateMapList()


    return popup
end


function RefreshOptions(skipRefresh)
    -- a little weird, but the "skip refresh" is set to prevent calc visible from being called before the control is properly setup
    -- it also means it's a flag that tells you this is the first time the dialog has been opened
    -- so we'll use this flag to reset the options sources so they can set up for multiplayer
    if skipRefresh then
        OptionSource[1] = {title = "<LOC uilobby_0001>Team Options", options = import("/lua/ui/lobby/lobbyoptions.lua").teamOptions}
        OptionSource[2] = {title = "<LOC uilobby_0002>Game Options", options = import("/lua/ui/lobby/lobbyoptions.lua").globalOpts}
        OptionSource[3] = {title = "<LOC uilobby_0003>AI Options", options = import("/lua/ui/lobby/lobbyoptions.lua").AIOpts}
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
                if not(isSinglePlayer and optionData.mponly == true) and table.getn(optionData.values) > 1 then
                    table.insert(Options, {type = 'option', text = optionData.label, data = optionData, default = optionData.default}) -- option1 for teamOptions for exemple
                end
            end
        end
    end
    if not skipRefresh then
        -- Remove all info about advancedOptions in changedOptions
        -- So we have a clean slate regarding the advanced options each map switch
        for _,optionData in OptionSource[4].options do
            changedOptions[optionData.key] = nil
        end

        OptionContainer:CalcVisible()
    end
end

function SetupOptionsPanel(parent, curOptions)
    local title = UIUtil.CreateText(parent, '<LOC PROFILE_0012>', 18)
    LayoutHelpers.AtLeftTopIn(title, parent, 4, 2)
    parent.title = title

    OptionContainer = Group(parent)
    OptionContainer.Height:Set(function() return parent.Height() - title.Height() end)
    OptionContainer.Width:Set(function() return parent.Width() - LayoutHelpers.ScaleNumber(18) end)
    OptionContainer.top = 0
    LayoutHelpers.Below(OptionContainer, title, 2)

    local OptionDisplay = {}
    RefreshOptions(true)

    local function CreateOptionCombo(parent)
        local combo = Combo(parent, nil, nil, nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.SetWidth(combo, 266)
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
            LayoutHelpers.SetHeight(optionGroup, 46)
            optionGroup.Width:Set(function() return OptionContainer.Width() + LayoutHelpers.ScaleNumber(4) end)

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
            local function UseSavedValue(data)
                -- always use saved data when looking at currently hosted map
                if string.lower(tostring(selectedScenario.file)) == string.lower(tostring(curOptions.ScenarioFile)) then
                    return true
                end
                -- otherwise, don't use saved data for advanced options
                local advancedOptions = OptionSource[4].options
                for _,option in advancedOptions do
                    if option.key == data.key then
                        return false
                    end
                end
                -- use saved data for non-advanced options
                return true
            end
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
                local optData = data.data

                for index, val in optData.values do
                    local key = val.key or val
                    local text = val.text or optData.value_text
                    local help = val.help or optData.value_help
                    itemArray[index] = LOCF(text, key)
                    line.combo.keyMap[key] = index
                    tooltipTable[index]={text=optData.label, body=LOCF(help, key)}

                    -- only use current settings of advanced options for current map
                    if curOptions[optData.key] and key == curOptions[optData.key] and UseSavedValue(optData) then
                        defValue = index
                    end
                end
                -- use changed option values
                if changedOptions[optData.key].index then
                    defValue = changedOptions[optData.key].index
                end
                -- if not yet set and no changed option value, use default
                if not defValue then
                    defValue = optData.default or 1
                end
                --
                if optData.default then realDefValue = optData.default end
                line.combo:AddItems(itemArray, defValue, realDefValue)
                line.combo.OnClick = function(self, index, text)
                    local value = optData.values[index].key
                    if value == nil then value = optData.values[index] end
                    changedOptions[optData.key] = {value = value, index = index}
                    if line.combo.EnableColor then
                        line.combo._text:SetColor('DBBADB')
                    end
                end
                line.HandleEvent = Group.HandleEvent
                Tooltip.AddControlTooltip(line, {text=optData.label,body=optData.help})
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
        description:AddItem(LOC("<LOC lobui_0757>AI Markers: Yes"))
    else
        description:AddItem(LOC("<LOC lobui_0758>AI Markers: No"))
    end

    description:AddItem("")
    if scen.description then
        local textBoxWidth = description.Width()
        local wrapped = import("/lua/maui/text.lua").WrapText(LOC(scen.description), textBoxWidth,
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

    local reselectRow = false

    mapList:DeleteAllItems()

    local selectedRow = 0
    local count = 1
    for i,sceninfo in scenarios do
        local passedFiltering = true

        -- If this is the currently selected map, mark it for reselection
        if selectedScenario and string.lower(sceninfo.file) == string.lower(selectedScenario.file) then
            selectedRow = count - 1
        -- Else, check filtering
        else
            -- Subject this map to every activated filter.
            for k, filter in currentFilters do
                if not filter(sceninfo) then
                    passedFiltering = false
                    break
                end
            end
            -- Name filter needs special treatment
            if nameFilter and nameFilter:GetText() ~= "" then
                passedFiltering = passedFiltering and string.lower(sceninfo.name):find(string.lower(nameFilter:GetText()))
            end
        end

        if passedFiltering then
            -- Make sure we finish up with the right map selected.
            scenarioKeymap[count] = i
            if sceninfo == selectedScenario then
                reselectRow = count
            end
            count = count + 1
            mapList:AddItem(LOC(sceninfo.name))
        end
    end

    OnMapChanged(mapList, selectedRow, true)
    mapList:ShowItem(selectedRow)

    randMapList = count - 1

    if randMapList == 0 then
        mapListTitle:SetText(LOCF("<LOC lobui_0579>No Map Available", randMapList))
    elseif randMapList == 1 then
        mapListTitle:SetText(LOCF("<LOC lobui_0580>%d Map Available", randMapList))
    else
        mapListTitle:SetText(LOCF("<LOC lobui_0581>%d Maps Available", randMapList))
    end

    if reselectRow then
        mapList:OnClick(reselectRow -1, true)
        mapList:ShowItem(reselectRow -1)
    end
end

function GUI_OldMap(over)
    local GUI = UIUtil.CreateScreenGroup(over, "CreateMapPopup ScreenGroup")
    local dialogContent = Group(GUI)
    LayoutHelpers.SetDimensions(dialogContent, 1000, 100)

    local ChangelogData = import("/lua/ui/lobby/changelogdata.lua")
    local OldMapPopup = Popup(GUI, dialogContent)
    OldMapPopup.OnClosed = function()
        Prefs.SetToCurrentProfile('LobbyChangelog', ChangelogData.last_version)
    end

    -- Title --
    local text0 = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0773>The currently selected map is outdated and/or unbalanced. Please download the latest version from the map vault."), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(text0, dialogContent, 0)
    LayoutHelpers.AtTopIn(text0, dialogContent, 10)

    -- OK button --
    local OkButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
    LayoutHelpers.AtCenterIn(OkButton, dialogContent, 20)
    LayoutHelpers.AtBottomIn(OkButton, dialogContent, 10)
    OkButton.OnClick = function()
        OldMapPopup:Close()
    end
end

function mapIsOutdated()
    local obsoleteFilterFactory = mapFilters[GetFilterIndex('map_obsolete')].FilterFactory
    obsoleteFilterFactory.SelectedKey = 1
    local obsoleteFilter = obsoleteFilterFactory:Build()
    return not obsoleteFilter(selectedScenario)
end

-- kept for mod backwards compatibility
local Scrollbar = import("/lua/maui/scrollbar.lua").Scrollbar
local Text = import("/lua/maui/text.lua").Text
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText
local Button = import("/lua/maui/button.lua").Button
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local MainMenu = import("/lua/ui/menus/main.lua")
local Mods = import("/lua/mods.lua")
local ModManager = import("/lua/ui/lobby/modsmanager.lua")