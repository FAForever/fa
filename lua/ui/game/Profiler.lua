

local GameMain = import('/lua/ui/game/gamemain.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Observable = import("/lua/shared/observable.lua")
local ProfilerUtilities = import("/lua/ui/game/ProfilerUtilities.lua")
local SharedProfiler = import("/lua/shared/Profiler.lua")
local Statistics = import("/lua/shared/statistics.lua")
local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Combo = import('/lua/ui/controls/combo.lua').Combo
local CreateEmptyProfilerTable = SharedProfiler.CreateEmptyProfilerTable
local DebugFunction = SharedProfiler.DebugFunction
local Edit = import('/lua/maui/edit.lua').Edit
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Layouter = LayoutHelpers.ReusedLayoutFor
local PlayerIsDev = SharedProfiler.PlayerIsDev
local ProfilerScrollArea = import("/lua/ui/game/ProfilerElements.lua").ProfilerScrollArea
local Window = import('/lua/maui/window.lua').Window


local sessionInfo = SessionGetScenarioInfo()

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

-- complete state of this window
local State = {
    WindowIsOpen = false,
    Header = "Overview",
    GUI = false,
    Tabs = {
        Overview = {
            Search = false,
            SortOn = "name",
        },
        Samples = {
            Search = false
        },
        Stamps = {},
        Options = {},
        Benchmarks = {
            SelectedModule = 1,
            SelectedBenchmark = 0,
            StatCache = {},
        }
    }
}

--- Received data from the sim about function calls
function ReceiveData(info)
    -- Lua, C or main
    for source, sourceinfo in info do
        -- global, local, method, field or other (empty)
        local sourceData = data[source]
        for scope, scopeinfo in sourceinfo do
            -- name of function and number of calls
            local scopeData = sourceData[scope]
            for name, calls in scopeinfo do
                -- add it up
                local value = scopeData[name]
                if not value then
                    scopeData[name] = 1
                else
                    scopeData[name] = value + calls
                end
            end
        end
    end

    -- keep track of the past
    growth[growthHead].tick = GameTick()
    growth[growthHead].data = info
    growthHead = growthHead + 1
    if growthHead > growthCount then
        growthHead = 1
    end

    -- populate list
    local list = State.GUI.OverviewControls.List
    if list then
        local growthCombined = ProfilerUtilities.Combine(growth)
        local growthLookup = ProfilerUtilities.LookUp(growthCombined)
        local overview = State.Tabs.Overview
        local cache, count = ProfilerUtilities.Format(data, growthLookup, false, false, overview.Search)
        local sorted, count = ProfilerUtilities.Sort(cache, count, overview.SortOn)
        list:ProvideElements(sorted, count)
        list:CalcVisible()
    end
end

function ReceiveBenchmarks(data)
    local benchmarks = State.GUI.Benchmarks
    if benchmarks then
        benchmarks:Set(data)
    end
end

function ReceiveBenchmarkOutput(data)
    SPEW("Received benchmark output")
    local profiler = State.GUI
    if not profiler then return end
    profiler.BenchmarkOutput:Set(data)
    profiler.BenchmarkOnProgress:Set(false)
    profiler.BenchmarkControls.RunButton.label:SetText(LOC("<LOC profiler_0014>Run"))
    profiler.benchmarkRunning = false
end

function ReceiveBenchmarkProgress(data)
    local profiler = State.GUI
    if not profiler then return end
    if data.runs then
        profiler.benchmarkProgress = 0
        profiler.benchmarkRuns = data.runs
        profiler.BenchmarkControls.RunButton.label:SetText(LOC("<LOC profiler_0002>Stop"))
    end
    if data.complete then
        profiler.benchmarkProgress = data.complete
        SPEW("Completed benchmark sample " .. profiler.benchmarkProgress)
    end
    profiler.BenchmarkOnProgress:Set(true)
end

--- Toggles the profiler in the simulation, sends along the army that initiated the call
function ToggleProfiler()
    SimCallback({
        Func = "ToggleProfiler",
        Args = {
            Army = GameMain.OriginalFocusArmy,
            ForceEnable = false
        }
    })
end

local function CanUseProfiler(army)
    if GameMain.GameHasAIs then
        return true
    end
    if sessionInfo.Options.CheatsEnabled then
        return true
    end
    if SessionIsReplay() then
        return true
    end
    if PlayerIsDev(army) then
        return true
    end
    return false
end

--- Opens up the window
function OpenWindow()
    local originalFocusArmy = GameMain.OriginalFocusArmy
    if not CanUseProfiler(originalFocusArmy) then
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
                Army = originalFocusArmy,
            }
        })
        -- toggle the profiler
        SimCallback({
            Func = "ToggleProfiler",
            Args = {
                Army = originalFocusArmy,
                ForceEnable = true,
            }
        })
    else
        State.GUI:Show()
        State.GUI:SwitchHeader(State.Header)
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
ProfilerWindow = Class(Window) {
    __init = function(self, parent)
        Window.__init(self, parent, LOC("<LOC profiler_0003>Profiler"), false, false, false, true, false, "profiler2", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 810
        })
        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')
        self:InitTabs()
        State.Tabs.Overview.GUI = self:InitOverviewTab(self._tabs)
        State.Tabs.Benchmarks.GUI = self:InitBenchmarksTab(self._tabs)
        self:SwitchHeader(State.Header)
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
        local OverviewButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC("<LOC profiler_0004>Overview"), 16, 2)
        LayoutHelpers.Below(OverviewButton, parent, 4)
        LayoutHelpers.FromLeftIn(OverviewButton, parent, 0.010)
        LayoutHelpers.DepthOverParent(OverviewButton, self, 10)
        OverviewButton.OnClick = function(button_self)
            self:SwitchHeader("Overview")
        end
        self._tabs.OverviewButton = OverviewButton
    end,

    InitTimersButton = function(self, parent)
        local TimersButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC("<LOC profiler_0005>Timers"), 16, 2)
        LayoutHelpers.Below(TimersButton, parent, 4)
        LayoutHelpers.FromLeftIn(TimersButton, parent, 0.210)
        LayoutHelpers.DepthOverParent(TimersButton, self, 10)
        TimersButton.OnClick = function(button_self)
            self:SwitchHeader("Timers")
        end
        -- TODO
        TimersButton:Disable()
        self._tabs.TimersButton = TimersButton
    end,

    InitStampsButton = function(self, parent)
        local StampsButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC("<LOC profiler_0006>Stamps"), 16, 2)
        LayoutHelpers.Below(StampsButton, parent, 4)
        LayoutHelpers.FromLeftIn(StampsButton, parent, 0.410)
        LayoutHelpers.DepthOverParent(StampsButton, self, 10)
        StampsButton.OnClick = function(button_self)
            self:SwitchHeader("Stamps")
        end

        -- TODO
        StampsButton:Disable()
        self._tabs.StampsButton = StampsButton
    end,

    InitBenchmarksButton = function(self, parent)
        local BenchmarksButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC("<LOC profiler_0007>Benchmarks"), 16, 2)
        LayoutHelpers.Below(BenchmarksButton, parent, 4)
        LayoutHelpers.FromLeftIn(BenchmarksButton, parent, 0.610)
        LayoutHelpers.DepthOverParent(BenchmarksButton, self, 10)
        BenchmarksButton.OnClick = function(button_self)
            self:SwitchHeader("Benchmarks")
        end
        self._tabs.BenchmarksButton = BenchmarksButton
    end,

    InitOptionsButton = function(self, parent)
        local OptionsButton = UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC("<LOC profiler_0008>Options"), 16, 2)
        LayoutHelpers.Below(OptionsButton, parent, 4)
        LayoutHelpers.FromLeftIn(OptionsButton, parent, 0.810)
        LayoutHelpers.DepthOverParent(OptionsButton, self, 10)
        OptionsButton.OnClick = function(button_self)
            self:SwitchHeader("Options")
        end
        -- TODO
        OptionsButton:Disable()
        self._tabs.OptionsButton = OptionsButton
    end,

    SwitchHeader = function(self, target)
        State.Header = target

        -- hide all tabs
        for _, tab in State.Tabs do
            if tab.GUI then
                tab.GUI:Hide()
            end
        end

        -- show the tab we're interested in
        local tab = State.Tabs[target].GUI
        if tab then
            tab:Show()
            self["OnFocusTab" .. target](self)
        end
    end;

    -- TODO
    InitOverviewTab = function(self, parent)
        local controls = {}
        self.OverviewControls = controls

        local tab = Layouter(Group(parent))
            :Below(parent, 40)
            :Width(self.Width)
            :Height(LayoutHelpers.ScaleNumber(10))
            :End()

        -- search bar

        local searchText = Layouter(UIUtil.CreateText(tab, LOC("<LOC profiler_0009>Search"), 18, UIUtil.bodyFont, true))
            :Below(tab)
            :AtLeftIn(tab, 10)
            :End()

        local searchEdit = Edit(tab); Layouter(searchEdit)
            :Below(tab)
            :CenteredRightOf(searchText, 10)
            :AtRightIn(tab, 156)
            :Over(self, 10)
            :Height(function()
                return searchEdit:GetFontHeight()
            end)
            :End()

        UIUtil.SetupEditStd(
            searchEdit, -- edit control
            UIUtil.fontColor, -- foreground color
            "ff060606", -- background color
            UIUtil.highlightColor, -- highlight foreground color
            "880085EF", -- highlight background color
            UIUtil.bodyFont, -- font
            14, -- size
            30 -- maximum characters
        )

        local searchClearButton = Layouter(UIUtil.CreateButtonStd(tab, '/widgets02/small', LOC("<LOC profiler_0010>Clear"), 14, 2))
            :CenteredRightOf(searchEdit, 4)
            :Over(self, 10)
            :End()

        -- Sorting options

        local sortGroup = Layouter(Group(tab))
        -- better to set height for control
            :AnchorToBottom(searchEdit, 13)
            :Height(LayoutHelpers.ScaleNumber(30))
            :Left(self.Left)
            :Right(self.Right)
            :End()

        local buttonName = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_0011>Name"), 16, 2))
            :FromLeftIn(sortGroup, 0.410)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        local buttonCount = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_0012>Count"), 16, 2))
            :FromLeftIn(sortGroup, 0.610)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        local buttonGrowth = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_0013>Growth"), 16, 2))
            :FromLeftIn(sortGroup, 0.810)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        -- list of functions
        -- make as a class
        -- ScrollArea
        local area = Layouter(ProfilerScrollArea(tab))
            :AnchorToBottom(sortGroup, 16)
            :AtBottomIn(self, 2)
            :Left(self.Left)
            :AtRightIn(self, 16)
            :End()
        area:InitScrollableContent()
        -- dirty hack :)
        SPEW(" applied dirty hack")
        controls.List = area

        searchEdit.OnTextChanged = function(edit_self, new, old)
            State.Tabs.Overview.Search = new
            self.OverviewControls.List:ScrollLines(false, 0)
        end
        searchClearButton.OnClick = function(edit_self)
            searchEdit:ClearText()
            State.Tabs.Overview.Search = false
        end
        buttonName.OnClick = function(button_self)
            State.Tabs.Overview.SortOn = "name"
        end
        buttonCount.OnClick = function(button_self)
            State.Tabs.Overview.SortOn = "value"
        end
        buttonGrowth.OnClick = function(button_self)
            State.Tabs.Overview.SortOn = "growth"
        end

        -- hide it by default
        tab:Hide()

        self._tabs.OverviewTab = tab
        return tab
    end,


    InitBenchmarksTab = function(self, parent)
        self.BenchmarkModuleSelected = Observable.Create(self)
        self.BenchmarkSelected = Observable.Create(self)
        self.BenchmarkOnProgress = Observable.Create(self)
        self.Benchmarks = Observable.Create(self)
        self.BenchmarkOutput = Observable.Create(self)

        self.benchmarkDebugFunction = false
        self.benchmarkRunning = false
        self.benchmarkRuns = 0
        self.benchmarkProgress = 0

        -- split up UI
        local horzSplit = 0.45
        local vertSplit = 0.65

        local controls = {}
        self.BenchmarkControls = controls

        local tab = Layouter(Group(parent))
            :AnchorToBottom(parent, 38)
            :Left(parent.Left)
            :Right(self.Right)
            :Bottom(self.Bottom)
            :End()
        State.Tabs.Benchmarks.GUI = tab

        local runButton = UIUtil.CreateButtonStd(tab, '/widgets02/small', LOC("<LOC profiler_0014>Run"), 16, 2)
        local sep = runButton.Height() * 0.5 + 5

        local groupIO, groupByteCode = UIUtil.CreateHorzSplitGroups(tab, horzSplit, 1)

        local groupNavigation, groupDetails = UIUtil.CreateVertSplitGroups(groupIO, vertSplit, sep)

        LayoutHelpers.ReusedLayoutFor(runButton)
            :CenteredBelow(groupNavigation, 5)
            :Over(tab, 10)
            :End()
        runButton:Disable()
        controls.RunButton = runButton

        local benchmarkProgressLabel = Layouter(UIUtil.CreateText(tab, "", 10, UIUtil.bodyFont, true))
           :CenteredRightOf(runButton)
           :End()
        controls.ProgressLabel = benchmarkProgressLabel

        local fileText = Layouter(UIUtil.CreateText(groupNavigation, LOC("<LOC profiler_0015>Files with benchmarks"), 16, UIUtil.bodyFont, true))
            :AtTopIn(groupNavigation, 10)
            :AtLeftIn(groupNavigation, 10)
            :End()

        local modulePicker = Layouter(Combo(tab, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :Below(fileText, 10)
            :AtLeftIn(groupNavigation, 10)
            :AtRightIn(groupNavigation, 10)
            :Over(tab, 10)
            :End()
        controls.ModulePicker = modulePicker

        -- should immediately update
        local benchmarkText = Layouter(UIUtil.CreateText(tab, "", 16, UIUtil.bodyFont, true))
            :Below(modulePicker, 10)
            :AtLeftIn(tab, 10)
            :End()
        controls.BenchmarksLabel = benchmarkText

        local benchmarkArea = Layouter(Group(groupNavigation))
            :FillFixedBorder(groupNavigation, 10)
            :AnchorToBottom(benchmarkText, 10)
            :End()

        -- construct list
        local benchmarkList = Layouter(ItemList(benchmarkArea))
            :Fill(benchmarkArea)
            :AtRightIn(benchmarkArea, 10)
            :Over(benchmarkArea, 10)
            :End()
        benchmarkList:SetFont(UIUtil.bodyFont, 14)
        benchmarkList:SetColors(UIUtil.fontColor, "00000000", "000000", UIUtil.highlightColor, "bcfffe")
        benchmarkList:ShowMouseoverItem(true)
        UIUtil.CreateLobbyVertScrollbar(benchmarkList, 0, 0, 0)
        controls.BenchmarkList = benchmarkList

        local details = Layouter(Group(groupDetails))
            :FillFixedBorder(groupDetails, 10)
            :End()
        controls.Details = details

        local bytecodeParams = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :AtTopIn(groupByteCode, 5)
            :AtLeftIn(groupByteCode, 10)
            :Over(groupByteCode, 10)
            :End()
        controls.BytecodeParameters = bytecodeParams

        local bytecodeStack = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeParams, 10)
            :Over(groupByteCode, 10)
            :End()
        controls.BytecodeMaxStack = bytecodeStack

        local bytecodeUpvals = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeStack, 10)
            :Over(groupByteCode, 10)
            :End()
        controls.BytecodeUpvalues = bytecodeUpvals

        local bytecodeConsts = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeUpvals, 10)
            :Over(groupByteCode, 10)
            :End()
        controls.BytecodeConstants = bytecodeConsts

        local bytecode = Layouter(ItemList(benchmarkArea))
            :Left(groupByteCode.Left)
            :Top(bytecodeStack.Bottom)
            :AtRightIn(groupByteCode, 14 + 5)
            :AtBottomIn(groupByteCode,     5)
            :Over(groupByteCode, 10)
            :End()
        bytecode:ShowMouseoverItem(true)
        bytecode:SetFont(UIUtil.fixedFont, 14)
        UIUtil.CreateLobbyVertScrollbar(bytecode, 0, 0, 0)
        -- AaaaAaaahhh, it doesn't work
        -- UIUtil.CreateLobbyHorzScrollbar(bytecode, 0, 0, 0)
        controls.BytecodeArea = bytecode

        local statsLabel = Layouter(UIUtil.CreateText(details, LOC("<LOC profiler_0017>Summary"), 16, UIUtil.bodyFont, true))
            :AtTopCenterIn(details, 5)
            :End()

        local statsSampLabel = Layouter(UIUtil.CreateText(details, LOC("<LOC profiler_0018>Samples"), 14, UIUtil.bodyFont, true))
            :Below(statsLabel, 5)
            :AtLeftIn(details)
            :End()

        local statsMeanLabel = Layouter(UIUtil.CreateText(details, LOC("<LOC profiler_0019>Mean"), 14, UIUtil.bodyFont, true))
            :Below(statsSampLabel, 3)
            :AtLeftIn(details)
            :End()

        local statsDevLabel = Layouter(UIUtil.CreateText(details, LOC("<LOC profiler_0020>Deviation"), 14, UIUtil.bodyFont, true))
            :Below(statsMeanLabel, 3)
            :AtLeftIn(details)
            :End()

        local statsSkewLabel = Layouter(UIUtil.CreateText(details, LOC("<LOC profiler_0021>Skewness"), 14, UIUtil.bodyFont, true))
            :Below(statsDevLabel, 3)
            :AtLeftIn(details)
            :End()

        local width = 10 + math.max(statsSampLabel.Width(), statsMeanLabel.Width(),
                statsDevLabel.Width(), statsSkewLabel.Width())

        local statsSamp = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Top(statsSampLabel.Top)
            :AtLeftIn(details, width)
            :End()
        controls.DetailSamples = statsSamp

        local statsMean = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Top(statsMeanLabel.Top)
            :AtLeftIn(details, width)
            :End()
        controls.DetailMean = statsMean

        local statsDev = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Top(statsDevLabel.Top)
            :AtLeftIn(details, width)
            :End()
        controls.DetailDeviation = statsDev

        local statsSkew = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Top(statsSkewLabel.Top)
            :AtLeftIn(details, width)
            :End()
        controls.DetailSkew = statsSkew

        -- backgrounds
        Layouter(Bitmap(groupNavigation))
            :FillFixedBorder(groupNavigation, 5)
            :Under(groupNavigation, 5)
            :End()
            :InternalSetSolidColor("7f000000")

        Layouter(Bitmap(groupDetails))
            :FillFixedBorder(groupDetails, 5)
            :Under(groupDetails, 5)
            :End()
            :InternalSetSolidColor("7f000000")

        Layouter(Bitmap(groupDetails))
            :Left(groupByteCode.Left)
            :Right(function() return groupByteCode.Right() - 5 end)
            :Top(bytecodeStack.Top)
            :Bottom(bytecodeStack.Bottom)
            :Under(groupDetails, 5)
            :End()
            :InternalSetSolidColor("7f000000")

        runButton.OnClick = function(button_self)
            if self.benchmarkRunning then
                SimCallback({
                    Func = "StopBenchmark",
                    Args = {}
                })
                return
            end
            local benchmarkState = State.Tabs.Benchmarks
            local module = benchmarkState.SelectedModule
            local benchmark = benchmarkState.SelectedBenchmark
            if module > 0 and benchmark > 0 then
                self.benchmarkRunning = true
                SimCallback({
                    Func = "RunBenchmark",
                    Args = {
                        Module = module,
                        Benchmark = benchmark,
                    }
                })
            end
        end
        modulePicker.OnClick = function(picker_self, index, text)
            -- index is already 1-indexed for Combo boxes
            local benchmarkState = State.Tabs.Benchmarks
            if index == benchmarkState.SelectedModule then
                return
            end
            benchmarkState.SelectedModule = index
            self.BenchmarkModuleSelected:Set(index)
        end
        benchmarkList.OnClick = function(list_self, rawIndex, text)
            local index = rawIndex + 1 -- make 1-indexed
            local benchmarkState = State.Tabs.Benchmarks
            if index == benchmarkState.SelectedBenchmark then
                return
            end
            ItemList.OnClick(list_self, rawIndex)
            benchmarkState.SelectedBenchmark = index
            benchmarkState.Modules[benchmarkState.SelectedModule].LastBenchmarkSelected = index
            self.BenchmarkSelected:Set(index)
        end
        bytecode.OnMouseoverItem = function(list_self, index)
            if self.benchmarkDebugFunction then
                if index ~= -1 then
                    local tooltip = self:BytecodeTooltip(index)
                    if tooltip then
                        Tooltip.CreateMouseoverDisplay(bytecode, tooltip)
                        return
                    end
                end
                Tooltip.DestroyMouseoverDisplay()
            end
        end

        -- allows us to act on changes
        self.Benchmarks:AddObserver("PopulateModulePicker")
        self.Benchmarks:AddObserver("SetBenchmarkData")
        self.BenchmarkModuleSelected:AddObserver("PopulateBenchmarkList")
        self.BenchmarkModuleSelected:AddObserver("UpdateBenchmarkDetails")
        self.BenchmarkModuleSelected:AddObserver("SetBenchmarkStats")
        self.BenchmarkSelected:AddObserver("PopulateCodeArea")
        self.BenchmarkSelected:AddObserver("SetRunButtonState")
        self.BenchmarkSelected:AddObserver("SetBenchmarkStats")
        self.BenchmarkOutput:AddObserver("CacheBenchmarkStats")
        self.BenchmarkOutput:AddObserver("SetBenchmarkStats")
        self.BenchmarkOnProgress:AddObserver("UpdateBenchmarkProgress")

        -- hide it by default
        tab:Hide()
        details:Hide()
        self._tabs.BenchmarkTab = tab
        return tab
    end,

    OnFocusTabOverview = function(self)
    end;
    OnFocusTabTimers = function(self)
    end;
    OnFocusTabStamps = function(self)
    end;
    OnFocusTabBenchmarks = function(self)
        self:SetBenchmarkStats() -- rehide the summary when the tab is shown
    end;
    OnFocusTabOptions = function(self)
    end;

    OnClose = function(self)
        CloseWindow()
    end;

    PopulateModulePicker = function(self, info)
        -- find keys
        local keys = {}
        local tooltips = {}
        for k, module in ipairs(info) do
            local moduleName = module.name
            local moduleDesc = module.desc
            if moduleName == "" then
                local folder = module.folder
                if folder:sub(-1) ~= '/' then
                    folder = folder .. '/'
                end
                local folderLen = folder:len()
                moduleName = module.file
                if moduleName:sub(1, folderLen) == folder then
                    moduleName = moduleName:sub(folderLen + 1)
                end
            end
            keys[k] = moduleName
            if moduleDesc ~= "" then
                tooltips[k] = moduleDesc
            end
        end
        local controls = self.BenchmarkControls
        local modulePicker = controls.ModulePicker
        modulePicker:ClearItems()
        modulePicker:AddItems(keys)
        if not table.empty(tooltips) then
            modulePicker.OnMouseExit = function(self)
                Tooltip.DestroyMouseoverDisplay()
            end
            modulePicker.OnOverItem = function(self, index, text)
                SPEW(text)
                if index ~= -1 and tooltips[index] then
                    Tooltip.CreateMouseoverDisplay(modulePicker, tooltips[index])
                else
                    Tooltip.DestroyMouseoverDisplay()
                end
            end
        end
    end;

    SetBenchmarkData = function(self, info)
        for _, cat in info do
            cat.LastBenchmarkSelected = 0
        end
        State.Tabs.Benchmarks.Modules = info
        self.BenchmarkModuleSelected:Set(1)
    end;

    PopulateBenchmarkList = function(self, index)
        local benchmarkList = self.BenchmarkControls.BenchmarkList
        benchmarkList:DeleteAllItems()

        local benchmarkState = State.Tabs.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        local lastSelected = moduleData.LastBenchmarkSelected
        self.BenchmarkSelected:Set(lastSelected)
        benchmarkState.SelectedBenchmark = lastSelected
        if not moduleData.faulty then
            local tooltips = {}
            for k, element in ipairs(moduleData.benchmarks) do
                local name = element.title
                local desc = element.desc
                if name == "" then
                    name = element.name
                end
                benchmarkList:AddItem(name)
                if desc ~= "" then
                    tooltips[k] = desc
                end
            end
            if not table.empty(tooltips) then
                benchmarkList.OnMouseoverItem = function(self, index)
                    if index ~= -1 and tooltips[index] then
                        Tooltip.CreateMouseoverDisplay(benchmarkList, tooltips[index])
                    else
                        Tooltip.DestroyMouseoverDisplay()
                    end
                end
            end
            if lastSelected ~= 0 then
                benchmarkList:SetSelection(lastSelected - 1)
            end
        end
    end;

    CacheBenchmarkStats = function(self, data)
        local benchmarkState = State.Tabs.Benchmarks
        local mod = benchmarkState.SelectedModule
        local ben = benchmarkState.SelectedBenchmark
        local key = tostring(mod) .. "," .. tostring(ben)
        benchmarkState.StatCache[key] = data
    end;

    SetBenchmarkStats = function(self, data)
        local benchmarkState = State.Tabs.Benchmarks
        if not data.n then
            local mod = benchmarkState.SelectedModule
            local ben = benchmarkState.SelectedBenchmark
            local key = tostring(mod) .. "," .. tostring(ben)
            data = benchmarkState.StatCache[key]
        end
        local samp, n = data.data, data.samples
        local tab = self.BenchmarkControls
        if n then
            local obj = Statistics.StatObject(samp, n)
            tab.Details:Show()
            tab.DetailSamples:SetText(n)
            tab.DetailMean:SetText(obj.mean)
            tab.DetailDeviation:SetText(obj.deviation)
            tab.DetailSkew:SetText(obj.sampSkewness)
        else
            tab.Details:Hide()
        end
    end;

    UpdateBenchmarkDetails = function(self, index)
        local benchmarkState = State.Tabs.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        local num
        if moduleData.faulty then
            num = "<LOC lobui_0458>Unknown"
        else
            num = table.getn(moduleData.benchmarks)
        end
        local label = self.BenchmarkControls.BenchmarksLabel
        label:SetText(LOCF("<LOC profiler_0016>Benchmarks in file: %s", num))
    end;

    PopulateCodeArea = function(self, benchmarkInd)
        local controls = self.BenchmarkControls
        local bytecode = controls.BytecodeArea
        bytecode:DeleteAllItems()

        local benchmarkState = State.Tabs.Benchmarks
        local moduleData = benchmarkState.Modules[benchmarkState.SelectedModule]
        if benchmarkInd == 0 then
            if moduleData.faulty then
                bytecode:AddItem(moduleData.desc)
            end
            controls.BytecodeParameters:SetText("")
            controls.BytecodeMaxStack:SetText("")
            controls.BytecodeUpvalues:SetText("")
            controls.BytecodeConstants:SetText("")
            return
        end
        local funcData = moduleData.benchmarks[benchmarkInd]
        local file = moduleData.file
        local module = import(file)
        if not module[funcData.name] then
            WARN("can't open benchmark file at " .. tostring(file))
            controls.BytecodeParameters:SetText("")
            controls.BytecodeMaxStack:SetText("")
            controls.BytecodeUpvalues:SetText("")
            controls.BytecodeConstants:SetText("")
            return
        end

        local fn = DebugFunction(module[funcData.name])
        self.benchmarkDebugFunction = fn
        controls.BytecodeParameters:SetText(LOC("<LOC profiler_0022>Parameters: %d"):format(fn.numparams))
        controls.BytecodeMaxStack:SetText(LOC("<LOC profiler_0023>Max Stack: %d"):format(fn.maxstack))
        controls.BytecodeUpvalues:SetText(LOC("<LOC profiler_0024>Upvalues: %d"):format(fn.nups))
        controls.BytecodeConstants:SetText(LOC("<LOC profiler_0025>Constants: %d"):format(fn.constantCount))
        for _, line in ipairs(fn:PrettyPrint()) do
            bytecode:AddItem(line)
        end
    end;

    SetRunButtonState = function(self, index)
        local runButton = self.BenchmarkControls.RunButton
        if index == 0 then
            runButton:Disable()
        else
            runButton:Enable()
        end
    end;

    UpdateBenchmarkProgress = function(self, prog)
        local progressLabel = self.BenchmarkControls.ProgressLabel
        if prog then
            local prog = self.benchmarkProgress
            local runs = self.benchmarkRuns
            progressLabel:SetText(LOC("<LOC profiler_0026>%d / %d"):format(prog, runs))
        else
            progressLabel:SetText("")
        end
    end;

    BytecodeTooltip = function(self, index)
        local text = self.BenchmarkControls.BytecodeArea:GetItem(index)
        local jumpTooltipFormater = LOC("<LOC profiler_0027>Jump from %s")
        local jumpInd = text:find('>', nil, true)
        if jumpInd and jumpInd < 20 then
            -- pull the instruction address directly from the text
            local addr = text:gmatch("[1-9A-Fa-F]%x*")()
            if not addr then
                return
            end
            addr = tonumber(addr, 16) + 1
            local fn = self.benchmarkDebugFunction
            local jumps = fn:ResolveJumps()[addr]
            local instructions = fn.instructions
            local addrFrom = instructions[jumps[1]]:AddressToString()
            local tooltip = jumpTooltipFormater:format(addrFrom)
            for i = 2, table.getn(jumps) do
                addrFrom = instructions[jumps[i]]:AddressToString()
                tooltip = tooltip .. "\n" .. jumpTooltipFormater:format(addrFrom)
            end
            return tooltip
        end
    end;
}
