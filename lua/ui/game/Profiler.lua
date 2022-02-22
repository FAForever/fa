
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Window = import('/lua/maui/window.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Combo = import('/lua/ui/controls/combo.lua').Combo
local ItemList = import('/lua/maui/itemlist.lua').ItemList

local sessionInfo = SessionGetScenarioInfo()

local CreateEmptyProfilerTable = import("/lua/shared/Profiler.lua").CreateEmptyProfilerTable

local Observable = import("/lua/shared/observable.lua")
local ProfilerUtilities = import("/lua/ui/game/ProfilerUtilities.lua")
local ProfilerElements = import("/lua/ui/game/ProfilerElements.lua")

local data = CreateEmptyProfilerTable()

-- keep track of data of the last few ticks
local growth = {  }
local growthHead = 1
local growthCount = 10
for k = 1, growthCount do 
    growth[k] = { tick = -1, data = CreateEmptyProfilerTable() }
end

-- The benchmarks the user can interact with
local Benchmarks = Observable.Create()

-- Output of benchmarks
local BenchmarkOutput = Observable.Create()

-- Selected benchmark in the UI
local BenchmarkSelected = Observable.Create()

-- complete state of this window
local State = {
    WindowIsOpen = false,
    Header = "Overview",
    GUI = false,
    Tabs = { 
        Overview = {
              Search = false
            , SortOn = "name"
            , GUI = false
        },
        Samples = { 
            Search = false
        },
        Stamps = { },
        Options = { },
        Benchmarks = { 
            SelectedFile = 1
        },
    },
}

local function StateSwitchHeader(target)

    local old = State.Header 

    LOG("Switching header to: " .. tostring(target))

    State.Header = target

    -- hide all tabs
    for k, tab in State.Tabs do 
        if tab.GUI then 
            tab.GUI:Hide()
        end
    end

    -- show the tab we're interested in
    if State.Tabs[target].GUI then 
        State.Tabs[target].GUI:Show()
    end
end

--- Received data from the sim about function calls
function ReceiveData(other)
    -- Lua, C or main
    for source, i1 in other do 
        -- global, local, method, field or other (empty)
        for scope, i2 in i1 do 
            -- name of function and number of calls
            for name, calls in i2 do 
                -- add it up
                local value = data[source][scope][name]
                if not value then 
                    data[source][scope][name] = 1
                else 
                    data[source][scope][name] = value + calls
                end
            end
        end
    end

    -- keep track of the past
    growth[growthHead].tick = GameTick()
    growth[growthHead].data = other
    growthHead = growthHead + 1
    if growthHead > growthCount then
        growthHead = 1
    end

    -- populate list

    if list then 
        local growthCombined = ProfilerUtilities.Combine(growth)
        local growthLookup = ProfilerUtilities.LookUp(growthCombined)

        local cache, count = ProfilerUtilities.Format(data, growthLookup, false, false, State.Tabs.Overview.Search)
        local sorted, count = ProfilerUtilities.Sort(cache, count, State.Tabs.Overview.SortOn)
        list:ProvideElements(sorted, count)
        list:CalcVisible()
    end
end

function ReceiveBenchmarks(data)
    Benchmarks:Set(data)
end

function ReceiveBenchmarkOutput(data)
    BenchmarkOutput:Set(data)
end

--- Toggles the profiler on / off in the simulation, sends along the army that initiated the call
function ToggleProfiler()

end

list = false

function CreateWindow()

    local function CreateOverviewTab(window, parent)

        -- fill parent
        parent.OverviewTab = Group(parent)
        parent.OverviewTab.Top:Set(function() return parent.Bottom() + 40 end)
        parent.OverviewTab.Left:Set(function() return parent.Left() end )
        parent.OverviewTab.Width:Set(function() return window.Width() end )
        parent.OverviewTab.Height:Set(function() return 10 end )

        local tab = parent.OverviewTab
        State.Tabs.Overview.GUI = tab

        -- search bar

        local searchText = UIUtil.CreateText(tab, "Search: ", 16, UIUtil.bodyFont, true)
        LayoutHelpers.Below(searchText, tab)
        LayoutHelpers.AtLeftIn(searchText, tab, 10)

        local searchEdit = Edit(tab)
        LayoutHelpers.Below(searchEdit, tab)
        LayoutHelpers.CenteredRightOf(searchEdit, searchText, 10)
        LayoutHelpers.AtRightIn(searchEdit, tab, 156)
        LayoutHelpers.DepthOverParent(searchEdit, window, 10)
        searchEdit.Height:Set(function() return searchEdit:GetFontHeight() end)
        searchEdit.OnTextChanged = function(self, new, old)
            State.Tabs.Overview.Search = new 
            list:ScrollLines(false, 0)
        end

        UIUtil.SetupEditStd(
            searchEdit,             -- edit control
            UIUtil.fontColor,       -- foreground color
            "00569FFF",             -- background color
            UIUtil.highlightColor,  -- highlight foreground color
            "880085EF",             -- highlight background color
            UIUtil.bodyFont,        -- font
            14,                     -- size
            30                      -- maximum characters
        )

        local searchClearButton = UIUtil.CreateButtonStd(tab, '/widgets02/small', "Clear", 14, 2)
        LayoutHelpers.CenteredRightOf(searchClearButton, searchEdit, 4)
        LayoutHelpers.DepthOverParent(searchClearButton, window, 10)
        searchClearButton.OnClick = function (self)
            searchEdit:ClearText()
            State.Tabs.Overview.Search = false
        end

        -- Sorting options

        local sortGroup = Group(tab)
        sortGroup.Top:Set(function() return searchEdit.Bottom() + LayoutHelpers.ScaleNumber(13) end)
        sortGroup.Bottom:Set(function() return searchEdit.Bottom() + LayoutHelpers.ScaleNumber(40) end)
        sortGroup.Left:Set(function() return window.Left() end )
        sortGroup.Right:Set(function() return window.Right() end )

        local buttonName = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Name", 16, 2)
        LayoutHelpers.FromLeftIn(buttonName, sortGroup, 0.410)
        LayoutHelpers.FromTopIn(buttonName, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonName, window, 10)
        buttonName.OnClick = function (self)
            State.Tabs.Overview.SortOn = "name"
        end

        local buttonCount = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Count", 16, 2)
        LayoutHelpers.FromLeftIn(buttonCount, sortGroup, 0.610)
        LayoutHelpers.FromTopIn(buttonCount, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonCount, window, 10)
        buttonCount.OnClick = function (self)
            State.Tabs.Overview.SortOn = "value"
        end

        local buttonGrowth = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Growth", 16, 2)
        LayoutHelpers.FromLeftIn(buttonGrowth, sortGroup, 0.810)
        LayoutHelpers.FromTopIn(buttonGrowth, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonGrowth, window, 10)
        buttonGrowth.OnClick = function (self)
            State.Tabs.Overview.SortOn = "growth"
        end

        -- list of functions

        local area = Group(tab)
        area.Top:Set(function () return sortGroup.Bottom() + LayoutHelpers.ScaleNumber(16) end)
        area.Bottom:Set(function () return window.Bottom() - LayoutHelpers.ScaleNumber(2) end)
        area.Left:Set(function () return window.Left() end)
        area.Right:Set(function () return window.Right() - LayoutHelpers.ScaleNumber(16) end)

        ProfilerElements.CreateScrollableContent(
            area, 
            ProfilerElements.CreateDefaultElement, 
            ProfilerElements.PopulateDefaultElement, 
            ProfilerElements.DepopulateDefaultElement
        )

        -- dirty hack :)
        SPEW(" applied dirty hack" )
        list = area

        -- hide it by default
        tab:Hide()
    end

    local function CreateCallsTab(parent)

    end

    local function CreateStampsTab(parent)

    end

    local function CreateOptionsTab(parent)

    end

    local function CreateBenchmarksTab(window, parent)

        -- basic debugging information

        Benchmarks:AddObserver(
            function(data) 
                SPEW("Received benchmark information")
            end
        )

        BenchmarkOutput:AddObserver(
            function(data) 
                SPEW("Received benchmark output")
            end
        )

        -- fill parent
        parent.BenchmarkTab = Group(parent)
        parent.BenchmarkTab.Top:Set(function() return parent.Bottom() + 40 end)
        parent.BenchmarkTab.Left:Set(function() return parent.Left() end )
        parent.BenchmarkTab.Right:Set(function() return window.Right() end )
        parent.BenchmarkTab.Bottom:Set(function() return window.Bottom() end )

        local tab = parent.BenchmarkTab
        State.Tabs.Benchmarks.GUI = tab

        -- split up UI

        local groupNavigation = Group(tab)
        groupNavigation.Top:Set(function() return tab.Top() end)
        groupNavigation.Left:Set(function() return tab.Left() end )
        groupNavigation.Right:Set(function() return tab.Left() + 0.5 * tab.Width() end )
        groupNavigation.Bottom:Set(function() return tab.Bottom() end )

        local groupDetails = Group(tab)
        groupDetails.Top:Set(function() return tab.Top() end)
        groupDetails.Left:Set(function() return tab.Left() + 0.5 * tab.Width() end )
        groupDetails.Right:Set(function() return tab.Right() end )
        groupDetails.Bottom:Set(function() return tab.Top() + 0.5 * tab.Height() end )

        local groupByteCode = Group(tab)
        groupByteCode.Top:Set(function() return tab.Top() + 0.5 * tab.Height() end)
        groupByteCode.Left:Set(function() return tab.Left() + 0.5 * tab.Width() end )
        groupByteCode.Right:Set(function() return tab.Right() end )
        groupByteCode.Bottom:Set(function() return tab.Bottom() end )

        -- used for debugging the UI areas

        -- local bitmapNavigation = Bitmap(groupNavigation)
        -- bitmapNavigation:InternalSetSolidColor("ff0000")
        -- LayoutHelpers.FillParent(bitmapNavigation, groupNavigation)
        -- LayoutHelpers.DepthUnderParent(bitmapNavigation, tab, 1000)

        -- local bitmapDetails = Bitmap(groupDetails)
        -- bitmapDetails:InternalSetSolidColor("00ff00")
        -- LayoutHelpers.FillParent(bitmapDetails, groupDetails)
        -- LayoutHelpers.DepthUnderParent(bitmapDetails, tab, 1000)



        -- populate 

        -- combo box to select from benchmarks

        local fileText = UIUtil.CreateText(tab, "File with benchmarks ", 16, UIUtil.bodyFont, true)
        LayoutHelpers.AtTopIn(fileText, tab, 10)
        LayoutHelpers.AtLeftIn(fileText, tab, 10)

        local filePicker = Combo(tab, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        LayoutHelpers.Below(filePicker, fileText, 10)
        LayoutHelpers.AtLeftIn(filePicker, groupNavigation, 10)
        LayoutHelpers.AtRightIn(filePicker, groupNavigation, 10)
        LayoutHelpers.DepthOverParent(filePicker, tab, 10)

        filePicker.OnClick = function(self, index, text)
            State.Tabs.Benchmarks.SelectedFile = index
            BenchmarkSelected:Set(index)
        end

        local function PopulateFilePicker(info)
            -- find keys
            local keys = { }
            for k, element in info do 
                keys[k] = element.file
            end

            -- find starting index
            local i = State.Tabs.Benchmarks.SelectedFile

            -- keep track of the existing keys for lookups later on
            State.Tabs.Benchmarks.ComboKeys = keys 

            -- clear it out
            filePicker:ClearItems()

            -- add them in
            filePicker:AddItems(keys, i, i)
        end

        -- allows us to act on changes
        Benchmarks:AddObserver(PopulateFilePicker)

        -- 
        local benchmarkText = UIUtil.CreateText(tab, "Benchmarks in file ", 16, UIUtil.bodyFont, true)
        LayoutHelpers.Below(benchmarkText, filePicker, 10)
        LayoutHelpers.AtLeftIn(benchmarkText, tab, 10)

        local benchmarkArea = Group(groupNavigation)
        benchmarkArea.Top:Set(function() return benchmarkText.Bottom() + LayoutHelpers.ScaleNumber(10) end)
        benchmarkArea.Left:Set(function() return groupNavigation.Left() + LayoutHelpers.ScaleNumber(10) end )
        benchmarkArea.Right:Set(function() return groupNavigation.Right() - LayoutHelpers.ScaleNumber(10) end )
        benchmarkArea.Bottom:Set(function() return groupNavigation.Bottom() - LayoutHelpers.ScaleNumber(10) end )

        -- construct list
        local list = ItemList(benchmarkArea)
        list:SetFont(UIUtil.bodyFont, 14)
        list:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
        list:ShowMouseoverItem(true)

        -- position it, keep room for scrollbar
        LayoutHelpers.FillParent(list, benchmarkArea)
        LayoutHelpers.AtRightIn(list, benchmarkArea, 10)
        LayoutHelpers.DepthOverParent(list, benchmarkArea, 10)

        UIUtil.CreateLobbyVertScrollbar(list, 0, 0, 0)

        local function PopulateBenchmarkList(index)
            local benchmarks = Benchmark
        end

        -- hide it by default
        tab:Hide()

    end

    SPEW("Created profiler window")

    -- create the window
    State.GUI = Window.CreateDefaultWindow(
        GetFrame(0), 
        "Profiler", 
        false, 
        false, 
        false, 
        true, 
        false, 
        "profiler2",
        10,
        300, 
        830,
        810
    )

    State.GUI.Border = UIUtil.SurroundWithBorder(State.GUI, '/scx_menu/lan-game-lobby/frame/')

    -- functionality of exit button
    State.GUI.OnClose = function(self)
        CloseWindow()
    end

    -- create group that will become the parent of all the elements
    State.GUI.Tabs = Group(State.GUI)
    LayoutHelpers.FillParent(State.GUI.Tabs, State.GUI.TitleGroup)
    local tabs = State.GUI.Tabs

    -- create primary tabs
    tabs.OverviewButton = UIUtil.CreateButtonStd(tabs, '/widgets02/small', "Overview", 16, 2)
    LayoutHelpers.Below(tabs.OverviewButton, tabs, 4)
    LayoutHelpers.FromLeftIn(tabs.OverviewButton, tabs, 0.010)
    LayoutHelpers.DepthOverParent(tabs.OverviewButton, State.GUI, 10)
    tabs.OverviewButton.OnClick = function (self)
        StateSwitchHeader("Overview")
    end

    tabs.StampsButton = UIUtil.CreateButtonStd(tabs, '/widgets02/small', "Stamps", 16, 2)
    LayoutHelpers.Below(tabs.StampsButton, tabs, 4)
    LayoutHelpers.FromLeftIn(tabs.StampsButton, tabs, 0.410)
    LayoutHelpers.DepthOverParent(tabs.StampsButton, State.GUI, 10)
    tabs.StampsButton.OnClick = function (self)
        StateSwitchHeader("Stamps")
    end

    -- TODO
    tabs.StampsButton:Disable()

    tabs.BenchmarksButton = UIUtil.CreateButtonStd(tabs, '/widgets02/small', "Benchmarks", 16, 2)
    LayoutHelpers.Below(tabs.BenchmarksButton, tabs, 4)
    LayoutHelpers.FromLeftIn(tabs.BenchmarksButton, tabs, 0.610)
    LayoutHelpers.DepthOverParent(tabs.BenchmarksButton, State.GUI, 10)
    tabs.BenchmarksButton.OnClick = function (self)
        StateSwitchHeader("Benchmarks")
    end

    -- TODO
    tabs.BenchmarksButton:Disable()

    tabs.OptionsButton = UIUtil.CreateButtonStd(tabs, '/widgets02/small', "Options", 16, 2)
    LayoutHelpers.Below(tabs.OptionsButton, tabs, 4)
    LayoutHelpers.FromLeftIn(tabs.OptionsButton, tabs, 0.810)
    LayoutHelpers.DepthOverParent(tabs.OptionsButton, State.GUI, 10)
    tabs.OptionsButton.OnClick = function (self)
        StateSwitchHeader("Options")
    end

    -- TODO
    tabs.OptionsButton:Disable()

    -- -- populate tabs
    CreateOverviewTab(State.GUI, tabs)
    -- CreateBenchmarksTab(State.GUI, tabs)
    -- CreateStampsTab(State.GUI, State.GUI.TitleGroup, State.GUI.Tabs)
    -- CreateOptionsTab(State.GUI, State.GUI.TitleGroup, State.GUI.Tabs)

    StateSwitchHeader("Overview")

end

--- Opens up the window
function OpenWindow()

    local gameHasAIs = GameMain.GameHasAIs 
    local cheatsOn = sessionInfo.Options.CheatsEnabled 
    local isThisJip = "jip" == GetArmiesTable()[GameMain.OriginalFocusArmy].nickname
    if not (gameHasAIs or cheatsOn or isThisJip) then 
        WARN("Unable to open Profiler window: no AIs or no cheats")
        return 
    end

    -- make hotkey act as a toggle
    if State.WindowIsOpen then 
        CloseWindow()
        return
    end

    SPEW("Opening profiler window")

    State.WindowIsOpen = true 

    -- populate the GUI
    if not State.GUI then 
        CreateWindow()

        -- retrieve benchmarks
        SimCallback( { Func = "FindBenchmarks", Args = { Army = GameMain.OriginalFocusArmy } } )

        -- toggle the profiler
        SimCallback( { Func = "ToggleProfiler", Args = { Army = GameMain.OriginalFocusArmy, ForceEnable = true } } )
    else
        State.GUI:Show()
    end
end

--- Closes the window
function CloseWindow()

    SPEW("Closing profiler window")

    State.WindowIsOpen = false

    if State.GUI then 
        State.GUI:Hide()
    end
end