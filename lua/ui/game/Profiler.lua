
--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Window = import("/lua/maui/window.lua").Window
local GameMain = import("/lua/ui/game/gamemain.lua")
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Combo = import("/lua/ui/controls/combo.lua").Combo
local ItemList = import("/lua/maui/itemlist.lua").ItemList

local sessionInfo = SessionGetScenarioInfo()

local CreateEmptyProfilerTable = import("/lua/shared/profiler.lua").CreateEmptyProfilerTable

local Observable = import("/lua/shared/observable.lua")
local ProfilerUtilities = import("/lua/ui/game/profilerutilities.lua")
local ProfilerElements = import("/lua/ui/game/profilerelements.lua")
local ProfilerScrollArea = import("/lua/ui/game/profilerelements.lua").ProfilerScrollArea

local data = CreateEmptyProfilerTable()

-- keep track of data of the last few ticks
local growth = {}
local growthHead = 1
local growthCount = 10
for k = 1, growthCount do
    growth[k] = {
        tick = -1,
        data = CreateEmptyProfilerTable()
    }
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
            Search = false,
            SortOn = "name",
            GUI = false
        },
        Samples = {
            Search = false
        },
        Stamps = {},
        Options = {},
        Benchmarks = {
            SelectedFile = 1
        }
    }
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
    SimCallback({
        Func = "ToggleProfiler",
        Args = {
            Army = GameMain.OriginalFocusArmy,
            ForceEnable = false
        }
    })
end

list = false



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
        State.GUI = ProfilerWindow(GetFrame(0))

        -- retrieve benchmarks
        SimCallback({
            Func = "FindBenchmarks",
            Args = {
                Army = GameMain.OriginalFocusArmy
            }
        })

        -- toggle the profiler
        SimCallback({
            Func = "ToggleProfiler",
            Args = {
                Army = GameMain.OriginalFocusArmy,
                ForceEnable = true
            }
        })
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

---@class ProfilerWindow : Window
ProfilerWindow = ClassUI(Window) {
    __init = function(self, parent)
        Window.__init(self, parent, "Profiler", false, false, false, true, false, "profiler2", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 810
        })
        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')
        self:InitTabs()
        State.Tabs.Overview.GUI = self:InitOverviewTab(self._tabs)
        StateSwitchHeader("Overview")
    end,

    InitTabs = function(self)
        self._tabs = Group(self)
        LayoutHelpers.FillParent(self._tabs, self.TitleGroup)
        self:InitOverviewButton(self._tabs)
        self:InitTimersButton(self._tabs)
        self:InitStampsButton(self._tabs)
        self:InitBenchmarksButton(self._tabs)
        self:InitOptionsButton(self._tabs)
    end,

    InitOverviewButton = function(self, parent)
        local OverviewButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', "Overview", 16, 2)
        LayoutHelpers.Below(OverviewButton, parent, 4)
        LayoutHelpers.FromLeftIn(OverviewButton, parent, 0.010)
        LayoutHelpers.DepthOverParent(OverviewButton, self, 10)
        OverviewButton.OnClick = function(self)
            StateSwitchHeader("Overview")
        end
        self._tabs.OverviewButton = OverviewButton
    end,

    InitTimersButton = function(self, parent)
        local TimersButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', "Timers", 16, 2)
        LayoutHelpers.Below(TimersButton, parent, 4)
        LayoutHelpers.FromLeftIn(TimersButton, parent, 0.210)
        LayoutHelpers.DepthOverParent(TimersButton, self, 10)
        TimersButton.OnClick = function(self)
            StateSwitchHeader("Timers")
        end
        -- TODO
        TimersButton:Disable()
        self._tabs.TimersButton = TimersButton
    end,

    InitStampsButton = function(self, parent)
        local StampsButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', "Stamps", 16, 2)
        LayoutHelpers.Below(StampsButton, parent, 4)
        LayoutHelpers.FromLeftIn(StampsButton, parent, 0.410)
        LayoutHelpers.DepthOverParent(StampsButton, self, 10)
        StampsButton.OnClick = function(self)
            StateSwitchHeader("Stamps")
        end

        -- TODO
        StampsButton:Disable()
        self._tabs.StampsButton = StampsButton
    end,

    InitBenchmarksButton = function(self, parent)
        local BenchmarksButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', "Benchmarks", 16, 2)
        LayoutHelpers.Below(BenchmarksButton, parent, 4)
        LayoutHelpers.FromLeftIn(BenchmarksButton, parent, 0.610)
        LayoutHelpers.DepthOverParent(BenchmarksButton, self, 10)
        BenchmarksButton.OnClick = function(self)
            StateSwitchHeader("Benchmarks")
        end
        -- TODO
        BenchmarksButton:Disable()
        self._tabs.BenchmarksButton = BenchmarksButton
    end,

    InitOptionsButton = function(self, parent)
        local OptionsButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', "Options", 16, 2)
        LayoutHelpers.Below(OptionsButton, parent, 4)
        LayoutHelpers.FromLeftIn(OptionsButton, parent, 0.810)
        LayoutHelpers.DepthOverParent(OptionsButton, self, 10)
        OptionsButton.OnClick = function(self)
            StateSwitchHeader("Options")
        end
        -- TODO
        OptionsButton:Disable()
        self._tabs.OptionsButton = OptionsButton
    end,

    -- TODO
    InitOverviewTab = function(self, parent)
        local tab = Group(parent)
        LayoutHelpers.Below(tab, parent, 40)
        tab.Width:Set(self.Width)
        LayoutHelpers.SetHeight(tab, 10)

        -- search bar

        local searchText = UIUtil.CreateText(tab, "Search: ", 18, UIUtil.bodyFont, true)
        LayoutHelpers.Below(searchText, tab)
        LayoutHelpers.AtLeftIn(searchText, tab, 10)

        local searchEdit = Edit(tab)
        LayoutHelpers.Below(searchEdit, tab)
        LayoutHelpers.CenteredRightOf(searchEdit, searchText, 10)
        LayoutHelpers.AtRightIn(searchEdit, tab, 156)
        LayoutHelpers.DepthOverParent(searchEdit, self, 10)
        searchEdit.Height:Set(function()
            return searchEdit:GetFontHeight()
        end)
        searchEdit.OnTextChanged = function(self, new, old)
            State.Tabs.Overview.Search = new
            list:ScrollLines(false, 0)
        end

        UIUtil.SetupEditStd(searchEdit, -- edit control
        UIUtil.fontColor, -- foreground color
        "ff060606", -- background color
        UIUtil.highlightColor, -- highlight foreground color
        "880085EF", -- highlight background color
        UIUtil.bodyFont, -- font
        14, -- size
        30 -- maximum characters
        )

        local searchClearButton = UIUtil.CreateButtonStd(tab, '/widgets02/small', "Clear", 14, 2)
        LayoutHelpers.CenteredRightOf(searchClearButton, searchEdit, 4)
        LayoutHelpers.DepthOverParent(searchClearButton, self, 10)
        searchClearButton.OnClick = function(self)
            searchEdit:ClearText()
            State.Tabs.Overview.Search = false
        end

        -- Sorting options

        local sortGroup = Group(tab)
        -- better to set height for control
        LayoutHelpers.AnchorToBottom(sortGroup, searchEdit, 13)
        LayoutHelpers.SetHeight(sortGroup, 30)
        sortGroup.Left:Set(self.Left)
        sortGroup.Right:Set(self.Right)

        local buttonName = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Name", 16, 2)
        LayoutHelpers.FromLeftIn(buttonName, sortGroup, 0.410)
        LayoutHelpers.FromTopIn(buttonName, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonName, self, 10)
        buttonName.OnClick = function(self)
            State.Tabs.Overview.SortOn = "name"
        end

        local buttonCount = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Count", 16, 2)
        LayoutHelpers.FromLeftIn(buttonCount, sortGroup, 0.610)
        LayoutHelpers.FromTopIn(buttonCount, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonCount, self, 10)
        buttonCount.OnClick = function(self)
            State.Tabs.Overview.SortOn = "value"
        end

        local buttonGrowth = UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', "Growth", 16, 2)
        LayoutHelpers.FromLeftIn(buttonGrowth, sortGroup, 0.810)
        LayoutHelpers.FromTopIn(buttonGrowth, sortGroup, 0)
        LayoutHelpers.DepthOverParent(buttonGrowth, self, 10)
        buttonGrowth.OnClick = function(self)
            State.Tabs.Overview.SortOn = "growth"
        end

        -- list of functions
        -- make as a class
        -- ScrollArea
        local area = ProfilerScrollArea(tab)
        LayoutHelpers.AnchorToBottom(area, sortGroup, 16)
        LayoutHelpers.AtBottomIn(area, self, 2)
        area.Left:Set(self.Left)
        LayoutHelpers.AtRightIn(area, self, 16)
        area:InitScrollableContent()
        -- dirty hack :)
        SPEW(" applied dirty hack")
        list = area

        -- hide it by default
        tab:Hide()

        self._tabs.OverviewTab = tab
        return tab
    end,


    InitBenchmarksTab = function(self, parent)
        -- basic debugging information

        Benchmarks:AddObserver(function(data)
            SPEW("Received benchmark information")
        end)

        BenchmarkOutput:AddObserver(function(data)
            SPEW("Received benchmark output")
        end)

        -- fill parent
        local BenchmarkTab = Group(parent)
        LayoutHelpers.AnchorToBottom(BenchmarkTab, parent, 40)
        BenchmarkTab.Left:Set(parent.Left)
        BenchmarkTab.Right:Set(self.Right)
        BenchmarkTab.Bottom:Set(self.Bottom)

        local tab = BenchmarkTab
        State.Tabs.Benchmarks.GUI = tab

        -- split up UI

        local groupNavigation = Group(tab)
        groupNavigation.Top:Set(tab.Top)
        groupNavigation.Left:Set(tab.Left)
        groupNavigation.Right:Set(function()
            return tab.Left() + 0.5 * tab.Width()
        end)
        groupNavigation.Bottom:Set(tab.Bottom)

        local groupDetails = Group(tab)
        groupDetails.Top:Set(tab.Top)
        groupDetails.Left:Set(function()
            return tab.Left() + 0.5 * tab.Width()
        end)
        groupDetails.Right:Set(tab.Right)
        groupDetails.Bottom:Set(function()
            return tab.Top() + 0.5 * tab.Height()
        end)

        local groupByteCode = Group(tab)
        groupByteCode.Top:Set(function()
            return tab.Top() + 0.5 * tab.Height()
        end)
        groupByteCode.Left:Set(function()
            return tab.Left() + 0.5 * tab.Width()
        end)
        groupByteCode.Right:Set(tab.Right)
        groupByteCode.Bottom:Set(tab.Bottom)

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
            local keys = {}
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
        LayoutHelpers.FillParentFixedBorder(benchmarkArea, groupNavigation, 10)
        LayoutHelpers.AnchorToBottom(benchmarkArea, benchmarkText, 10)

        -- construct list
        local list = ItemList(benchmarkArea)
        list:SetFont(UIUtil.bodyFont, 14)
        list:SetColors(UIUtil.fontColor, "00000000", "FF000000", UIUtil.highlightColor, "ffbcfffe")
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
        self._tabs.BenchmarkTab = tab
        return tab
    end,

    OnClose = function(self)
        CloseWindow()
    end
}
