

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
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea
local Window = import('/lua/maui/window.lua').Window


local sessionInfo = SessionGetScenarioInfo()

local data = CreateEmptyProfilerTable()


local BenchmarkModuleSelected = Observable.Create()
local BenchmarkSelected = Observable.Create()
local BenchmarkProgressReceived = Observable.Create()
local BenchmarkModulesReceived = Observable.Create()
local BenchmarkOutputReceived = Observable.Create()

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

function ReceiveBenchmarkModules(data)
    BenchmarkModulesReceived:Set(data)
end

function ReceiveBenchmarkOutput(data)
    SPEW("Received benchmark output")
    BenchmarkOutputReceived:Set(data)
end

function ReceiveBenchmarkProgress(data)
    SPEW("Receiving progress")
    BenchmarkProgressReceived:Set(data)
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

        -- temporary parameters until a UI for them gets made
        self.BenchmarkParameters = {10000, 45}

        self.benchmarkDebugFunction = false
        self.benchmarkRunning = false
        self.benchmarkRuns = 0
        self.benchmarkProgress = 0
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

        -- Breakdown tab into groups

        local groupIO, groupBytecode = UIUtil.CreateHorzSplitGroups(tab, horzSplit, 1)

        local groupInteraction = Layouter(Group(groupIO))
            :FillFixedBorder(groupIO, 5)
            :FromVerticalCenterIn(groupIO, vertSplit)
            :Height(10) -- placeholder until we can set it to depend on the run button height
            :End()

        local groupNavigation = Layouter(Group(groupIO))
            :Fill(groupIO)
            :AnchorToTop(groupInteraction, 5)
            :End()

        local groupSummary = Layouter(Group(groupIO))
            :OffsetIn(groupIO, 10, 5, 10, 5)
            :AnchorToBottom(groupInteraction, 5)
            :End()
        controls.Summary = groupSummary

        local groupBytecodeDetails = Layouter(Group(groupBytecode))
            :Fill(groupBytecode)
            :End()
        controls.BytecodeDetails = groupBytecodeDetails

        -- Interaction components

        local runButton = Layouter(UIUtil.CreateButtonStd(groupInteraction, '/widgets02/small', LOC("<LOC profiler_0014>Run"), 16, 2))
            :AtCenterIn(groupInteraction)
            :Over(groupInteraction, 10)
            :End()
        runButton:Disable()
        controls.RunButton = runButton

        local benchmarkParametersLabel = ItemList(groupInteraction, 0, 0); Layouter(benchmarkParametersLabel)
            :AtLeftIn(groupInteraction)
            :AnchorToLeft(runButton)
            :AtVerticalCenterIn(groupInteraction)
            :ResetWidth()
            :Height(function()
                return (1 + benchmarkParametersLabel:GetItemCount()) * benchmarkParametersLabel:GetRowHeight() + 10
            end)
            :End()
        benchmarkParametersLabel:SetFont(UIUtil.bodyFont, 10)
        benchmarkParametersLabel:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
        controls.ParametersLabel = benchmarkParametersLabel

        local benchmarkProgressLabel = Layouter(UIUtil.CreateText(groupInteraction, "", 10, UIUtil.bodyFont, true))
           :CenteredRightOf(runButton)
           :End()
        controls.ProgressLabel = benchmarkProgressLabel


        -- Navigation components

        local fileText = Layouter(UIUtil.CreateText(groupNavigation, LOC("<LOC profiler_0015>Benchmark Modules"), 16, UIUtil.bodyFont, true))
            :AtLeftTopIn(groupNavigation, 10, 10)
            :End()

        local modulePicker = Layouter(Combo(groupNavigation, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :Below(fileText, 10)
            :AtLeftIn(groupNavigation, 10)
            :AtRightIn(groupNavigation, 10)
            :Over(groupNavigation, 10)
            :End()
        controls.ModulePicker = modulePicker

        -- should immediately update, so no need to set label
        local benchmarkText = Layouter(UIUtil.CreateText(groupNavigation, "", 16, UIUtil.bodyFont, true))
            :Below(modulePicker, 8)
            :AtLeftIn(groupNavigation, 10)
            :End()
        controls.BenchmarksLabel = benchmarkText

        local benchmarkList = Layouter(ItemList(groupNavigation))
            :OffsetIn(groupNavigation, 10, 5, 10 + 14) -- leave space for scrollbar
            :AnchorToBottom(benchmarkText, 10)
            :Over(groupNavigation, 10)
            :End()
        benchmarkList:SetFont(UIUtil.bodyFont, 14)
        benchmarkList:SetColors(UIUtil.fontColor, "00000000", "000000", UIUtil.highlightColor, "bcfffe")
        benchmarkList:ShowMouseoverItem(true)
        UIUtil.CreateLobbyVertScrollbar(benchmarkList, 0, 0, 0)
        controls.BenchmarkList = benchmarkList


        -- Summary details

        local statsLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_0017>Summary"), 16, UIUtil.bodyFont, true))
            :AtTopCenterIn(groupSummary, 5)
            :End()

        local statsSampLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_0018>Samples"), 14, UIUtil.bodyFont, true))
            :Below(statsLabel, 5)
            :AtLeftIn(groupSummary, 6)
            :End()

        local statsMeanLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_0019>Mean"), 14, UIUtil.bodyFont, true))
            :Below(statsSampLabel, 3)
            :End()

        local statsDevLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_0020>Deviation"), 14, UIUtil.bodyFont, true))
            :Below(statsMeanLabel, 3)
            :End()

        local statsSkewLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_0021>Skewness"), 14, UIUtil.bodyFont, true))
            :Below(statsDevLabel, 3)
            :End()

        local width = 10 + math.max(statsSampLabel.Width(), statsMeanLabel.Width(),
                statsDevLabel.Width(), statsSkewLabel.Width())

        local statsSamp = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(statsSampLabel.Top)
            :AtLeftIn(statsSampLabel, width)
            :End()
        controls.SummarySamples = statsSamp

        local statsMean = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(statsMeanLabel.Top)
            :AtLeftIn(statsMeanLabel, width)
            :End()
        controls.SummaryMean = statsMean

        local statsDev = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(statsDevLabel.Top)
            :AtLeftIn(statsDevLabel, width)
            :End()
        controls.SummaryDeviation = statsDev

        local statsSkew = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(statsSkewLabel.Top)
            :AtLeftIn(statsSkewLabel, width)
            :End()
        controls.SummarySkew = statsSkew

        -- THIS MUST CHANGE IT'S AWFUL
        local statsClear = Layouter(UIUtil.CreateButtonStd(groupSummary, '/widgets02/small', "<LOC profiler_0028>Clear Stats", 12, 2))
            :AtLeftTopIn(groupSummary)
            :End()
        Tooltip.AddButtonTooltip(statsClear, "pls replace me")
        controls.ClearStatsButton = statsClear


        -- bytecode

        local bytecodeLogButton = Layouter(UIUtil.CreateButtonStd(tab, "/BUTTON/log/"))
            :AtRightTopIn(groupBytecode, 5, 5)
            :Over(groupBytecodeDetails, 1)
            :End()
        Tooltip.AddButtonTooltip(bytecodeLogButton, "profiler_print_to_log")
        controls.BytecodeLogButton = bytecodeLogButton

        local bytecodeParams = Layouter(UIUtil.CreateText(groupBytecodeDetails, "", 14, UIUtil.bodyFont, true))
            :AtLeftCenterIn(groupBytecodeDetails, 10)
            :Over(groupBytecodeDetails, 10)
            :End()
        controls.BytecodeParameters = bytecodeParams

        local bytecodeStack = Layouter(UIUtil.CreateText(groupBytecodeDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(bytecodeParams, 10)
            :Over(groupBytecodeDetails, 10)
            :End()
        controls.BytecodeMaxStack = bytecodeStack

        local bytecodeUpvals = Layouter(UIUtil.CreateText(groupBytecodeDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(bytecodeStack, 10)
            :Over(groupBytecodeDetails, 10)
            :End()
        controls.BytecodeUpvalues = bytecodeUpvals

        local bytecodeConsts = Layouter(UIUtil.CreateText(groupBytecodeDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(bytecodeUpvals, 10)
            :Over(groupBytecodeDetails, 10)
            :End()
        controls.BytecodeConstants = bytecodeConsts

        local bytecode = Layouter(ItemList(groupBytecode))
            :Left(groupBytecode.Left)
            :Top(groupBytecodeDetails.Bottom)
            :AtRightBottomIn(groupBytecode, 14 + 5, 5)
            :Over(groupBytecode, 10)
            :End()
        bytecode:ShowMouseoverItem(true)
        bytecode:SetFont(UIUtil.fixedFont, 14)
        UIUtil.CreateLobbyVertScrollbar(bytecode, 0, 0, 0)
        -- UIUtil.CreateLobbyHorzScrollbar(bytecode, 0, 0, 0)  -- AaaaAaaahhh, it doesn't work
        controls.BytecodeArea = bytecode


        -- layout 'editing'
        groupInteraction.Height:Set(function() return runButton.Height() + 10 end)
        groupBytecodeDetails.Right:Set(bytecodeLogButton.Left)
        groupBytecodeDetails.Top:Set(bytecodeLogButton.Top)
        groupBytecodeDetails.Bottom:Set(bytecodeLogButton.Bottom)


        -- backgrounds
        -- don't let these hide with the group they're under
        Layouter(Bitmap(groupIO))
            :FillFixedBorder(benchmarkList)
            :Under(benchmarkList, 5)
            :End()
            :InternalSetSolidColor("7f000000")
        Layouter(Bitmap(groupIO))
            :FillFixedBorder(groupSummary)
            :Under(groupSummary, 5)
            :End()
            :InternalSetSolidColor("7f000000")

        Layouter(Bitmap(groupBytecode))
            :Fill(groupBytecodeDetails)
            :Under(groupBytecodeDetails, 5)
            :End()
            :InternalSetSolidColor("7f000000")


        runButton.OnClick = function(button_self)
            if self.benchmarkRunning then
                self:BenchmarkStop()
                return
            end
            local benchmarkState = State.Tabs.Benchmarks
            local module = benchmarkState.SelectedModule
            local benchmark = benchmarkState.SelectedBenchmark
            if module > 0 and benchmark > 0 then
                self:BenchmarkStart(module, benchmark)
            end
        end
        modulePicker.OnClick = function(picker_self, index, text)
            -- index is already 1-indexed for Combo boxes
            local benchmarkState = State.Tabs.Benchmarks
            if index == benchmarkState.SelectedModule then
                return
            end
            BenchmarkModuleSelected:Set(index)
        end
        benchmarkList.OnClick = function(list_self, rawIndex, text)
            local index = rawIndex + 1 -- make 1-indexed
            if index == State.Tabs.Benchmarks.SelectedBenchmark then
                return
            end
            ItemList.OnClick(list_self, rawIndex)
            BenchmarkSelected:Set(index)
        end
        bytecodeLogButton.OnClick = function(button_self)
            if (self.benchmarkDebugFunction) then
                local area = self.BenchmarkControls.BytecodeArea
                for i = 1, area:GetItemCount() do
                    LOG(area:GetItem(i - 1)) -- list is 0-indexed
                end
            end
        end
        statsClear.OnClick = function(button_self)
            self:ResetBenchmarkStats()
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
        BenchmarkModulesReceived:AddObserver(function(modules)
            self:ReceiveBenchmarkModules(modules)
        end)
        BenchmarkProgressReceived:AddObserver(function(progress)
            self:ReceiveBenchmarkProgress(progress)
        end)
        BenchmarkOutputReceived:AddObserver(function(output)
            self:ReceiveBenchmarkOutput(output)
        end)
        BenchmarkModuleSelected:AddObserver(function(index)
            self:OnModuleSelected(index)
        end)
        BenchmarkSelected:AddObserver(function(index)
            self:OnBenchmarkSelected(index)
        end)

        -- hide it by default
        tab:Hide()
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
        self:UpdateBenchmarkStats() -- rehide the summary when the tab is shown
    end;
    OnFocusTabOptions = function(self)
    end;

    OnClose = function(self)
        CloseWindow()
    end;

    BenchmarkStop = function(self)
        SimCallback({
            Func = "StopBenchmark",
            Args = {}
        })
    end;

    BenchmarkStart = function(self, module, benchmark)
        -- We asymetrically update the `benchmarkRunning` state to true on start, but wait for results
        -- from the sim on stop to set to false. This is so that we can't send benchmark requests
        -- to the sim while one is running.
        self.benchmarkRunning = true
        local fn = self.benchmarkDebugFunction
        if not fn then
            WARN("Missing debug function to start benchmark")
            return
        end
        local parameters = {}
        for i = 1, fn.numparams do
            parameters[i] = self.BenchmarkParameters[i]
        end
        SPEW("STARTING")
        SimCallback({
            Func = "RunBenchmark",
            Args = {
                Module = module,
                Benchmark = benchmark,
                Parameters = parameters,
            },
        })
        self:UpdateRunButtonState()
    end;

    OnModuleSelected = function(self, index)
        State.Tabs.Benchmarks.SelectedModule = index
        self:PopulateBenchmarkList(index)
        self:UpdateBenchmarkDetails(index)
    end;

    OnBenchmarkSelected = function(self, index)
        local benchmarkState = State.Tabs.Benchmarks
        benchmarkState.SelectedBenchmark = index
        benchmarkState.Modules[benchmarkState.SelectedModule].LastBenchmarkSelected = index
        self:PopulateCodeArea()
        self:UpdateParametersLabel()
        self:UpdateRunButtonState()
        self:UpdateBenchmarkStats()
    end;

    ReceiveBenchmarkModules = function(self, modules)
        for _, module in modules do
            module.LastBenchmarkSelected = 0
        end
        State.Tabs.Benchmarks.Modules = modules
        self:PopulateModulePicker(modules)
        BenchmarkModuleSelected:Set(1)
    end;

    ReceiveBenchmarkProgress = function(self, progress)
        if progress.runs then
            self.benchmarkRuns = progress.runs
            self:UpdateRunButtonState()
            self.benchmarkProgress = progress.complete
        else
            self.benchmarkProgress = self.benchmarkProgress + progress.complete
        end
        self:UpdateBenchmarkProgress()
    end;

    ReceiveBenchmarkOutput = function(self, output)
        self.benchmarkRunning = false
        self:AddBenchmarkStats(output)
        self:UpdateBenchmarkProgress()
        self:UpdateRunButtonState()
    end;

    PopulateModulePicker = function(self, modules)
        -- find keys
        local keys = {}
        local tooltips = {}
        for k, module in ipairs(modules) do
            -- module name is `name` unless it's empty, then it's `file` (with `path` removed)
            local moduleName = module.name
            local moduleDesc = module.description
            if moduleName == "" then
                local modulePath = module.path
                if modulePath:sub(-1) ~= '/' then
                    modulePath = modulePath .. '/'
                end
                local modulePathLen = modulePath:len()
                moduleName = module.file
                if moduleName:sub(1, modulePathLen) == modulePath then
                    moduleName = moduleName:sub(modulePathLen + 1)
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
            -- show descriptions
            modulePicker.OnMouseExit = function(self)
                Tooltip.DestroyMouseoverDisplay()
            end
            modulePicker.OnOverItem = function(self, index, text)
                if index ~= -1 and tooltips[index] then
                    Tooltip.CreateMouseoverDisplay(modulePicker, tooltips[index])
                else
                    Tooltip.DestroyMouseoverDisplay()
                end
            end
        else
            modulePicker.OnMouseExit = nil
            modulePicker.OnOverItem = nil
        end
    end;

    PopulateBenchmarkList = function(self, index)
        local benchmarkList = self.BenchmarkControls.BenchmarkList
        benchmarkList:DeleteAllItems()

        local benchmarkState = State.Tabs.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        local lastSelected = moduleData.LastBenchmarkSelected
        if not moduleData.faulty then
            local tooltips = {}
            for k, element in ipairs(moduleData.benchmarks) do
                -- benchmark name is `title` unless it's empty, then it's `name`
                local name = element.title
                local desc = element.description
                if name == "" then
                    name = element.name
                end
                benchmarkList:AddItem(name)
                if desc ~= "" then
                    tooltips[k] = desc
                end
            end
            if not table.empty(tooltips) then
                -- show descriptions
                benchmarkList.OnMouseoverItem = function(self, index)
                    index = index + 1 -- to one-index
                    if index ~= 0 and tooltips[index] then
                        Tooltip.CreateMouseoverDisplay(benchmarkList, tooltips[index])
                    else
                        Tooltip.DestroyMouseoverDisplay()
                    end
                end
            else
                benchmarkList.OnMouseoverItem = nil
            end
            if lastSelected ~= 0 then
                benchmarkList:SetSelection(lastSelected - 1) -- to zero-index list
            end
        end
        BenchmarkSelected:Set(lastSelected)
    end;

    PopulateCodeArea = function(self)
        local controls = self.BenchmarkControls
        local bytecode = controls.BytecodeArea
        bytecode:DeleteAllItems()

        local benchmarkState = State.Tabs.Benchmarks
        local moduleData = benchmarkState.Modules[benchmarkState.SelectedModule]
        if moduleData.faulty then
            bytecode:AddItem(moduleData.description)
        else
            local benchmarkInd = benchmarkState.SelectedBenchmark
            if benchmarkInd ~= 0 then
                local funcData = moduleData.benchmarks[benchmarkInd]
                local file = moduleData.file
                local module = import(file)
                local fn = module[funcData.name]
                if fn then
                    fn = DebugFunction(fn)
                    self.benchmarkDebugFunction = fn
                    controls.BytecodeParameters:SetText(LOC("<LOC profiler_0022>Parameters: %d"):format(fn.numparams))
                    controls.BytecodeMaxStack:SetText(LOC("<LOC profiler_0023>Max Stack: %d"):format(fn.maxstack))
                    controls.BytecodeUpvalues:SetText(LOC("<LOC profiler_0024>Upvalues: %d"):format(fn.nups))
                    controls.BytecodeConstants:SetText(LOC("<LOC profiler_0025>Constants: %d"):format(fn.constantCount))
                    controls.BytecodeLogButton:Enable()
                    controls.BytecodeDetails:Show()
                    for _, line in ipairs(fn:PrettyPrint()) do
                        bytecode:AddItem(line)
                    end
                    return
                end
                WARN("can't open benchmark file at " .. tostring(file))
            end
        end
        controls.BytecodeDetails:Hide()
        controls.BytecodeLogButton:Disable()
    end;

    BytecodeTooltip = function(self, index)
        local text = self.BenchmarkControls.BytecodeArea:GetItem(index)
        local jumpTooltipFormater = LOC("<LOC profiler_0027>Jump from %s")
        local jumpInd = text:find('>', nil, true)
        if jumpInd and jumpInd < 20 then
            -- pull the instruction address directly from the text
            local addr = text:gmatch("[1-9A-Fa-f]%x*")()
            if not addr then
                return
            end
            addr = tonumber(addr, 16) + 1
            local fn = self.benchmarkDebugFunction
            local jumps = fn:ResolveJumps()[addr]
            local instructions = fn.instructions
            local addrFrom = instructions[jumps[1] + 1]:AddressToString()
            local tooltip = jumpTooltipFormater:format(addrFrom)
            for i = 2, table.getn(jumps) do
                addrFrom = instructions[jumps[i] + 1]:AddressToString()
                tooltip = tooltip .. "; " .. jumpTooltipFormater:format(addrFrom)
            end
            return tooltip
        end
    end;

    ResetBenchmarkStats = function(self)
        local benchmarkState = State.Tabs.Benchmarks
        local mod = benchmarkState.SelectedModule
        local ben = benchmarkState.SelectedBenchmark
        local key = tostring(mod) .. "," .. tostring(ben)
        benchmarkState.StatCache[key] = nil
        self:UpdateBenchmarkStats()
    end;

    AddBenchmarkStats = function(self, data)
        local benchmarkState = State.Tabs.Benchmarks
        local mod = benchmarkState.SelectedModule
        local ben = benchmarkState.SelectedBenchmark
        local key = tostring(mod) .. "," .. tostring(ben)
        local cache = benchmarkState.StatCache[key]
        local n = data.samples
        data = data.data
        if cache then
            local offset = cache.n
            for i = 1, n do
                cache[offset + i] = data[i]
            end
            cache.n = offset + n
        else
            cache = {n = n}
            benchmarkState.StatCache[key] = cache
            for i = 1, n do
                cache[i] = data[i]
            end
        end
        self:UpdateBenchmarkStats()
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
        label:SetText(LOCF("<LOC profiler_0016>Benchmarks in module: %s", num))
    end;

    UpdateParametersLabel = function(self)
        local fn = self.benchmarkDebugFunction
        if fn then
            local label = self.BenchmarkControls.ParametersLabel
            label:DeleteAllItems()
            local paramCount = fn.numparams
            if paramCount > 0 then
                local paramFormater = LOC("<LOC profiler_0030>Parameter %d: %s")
                local parameters = self.BenchmarkParameters
                for i = 1, paramCount do
                    label:AddItem(paramFormater:format(i, tostring(parameters[i])))
                end
            end
            label:Show()
            SPEW("Current: " .. label:GetItemCount())
            for i = 1, label:GetItemCount() do
                SPEW(label:GetItem(i - 1))
            end
        end
    end;

    UpdateRunButtonState = function(self)
        local runButton = self.BenchmarkControls.RunButton
        if State.Tabs.Benchmarks.SelectedBenchmark == 0 then
            runButton:Disable()
        else
            runButton:Enable()
        end
        if self.benchmarkRunning then
            runButton.label:SetText(LOC("<LOC profiler_0002>Stop"))
        else
            runButton.label:SetText(LOC("<LOC profiler_0014>Run"))
        end
    end;

    UpdateBenchmarkProgress = function(self)
        local progressLabel = self.BenchmarkControls.ProgressLabel
        local prog = self.benchmarkProgress
        local runs = self.benchmarkRuns
        if prog < runs then
            progressLabel:Show()
            progressLabel:SetText(LOC("<LOC profiler_0026>%d / %d"):format(prog, runs))
        else
            progressLabel:Hide()
        end
    end;

    UpdateBenchmarkStats = function(self)
        local benchmarkState = State.Tabs.Benchmarks
        local mod = benchmarkState.SelectedModule
        local ben = benchmarkState.SelectedBenchmark
        local key = tostring(mod) .. "," .. tostring(ben)
        local cache = benchmarkState.StatCache[key]
        local tab = self.BenchmarkControls
        if cache then
            local n = cache.n
            local obj = Statistics.StatObject(cache, n)
            tab.SummarySamples:SetText(n)
            if n > 0 then
                tab.SummaryMean:SetText(obj.mean)
            else
                tab.SummaryMean:SetText("0")
            end
            if n > 1 then
                tab.SummaryDeviation:SetText(obj.deviation)
            else
                tab.SummaryDeviation:SetText("∞")
            end
            if n > 2 then
                if obj.deviation > 0 then
                    tab.SummarySkew:SetText(obj.sampSkewness)
                else
                    tab.SummarySkew:SetText("0")
                end
            else
                tab.SummarySkew:SetText("∞")
            end
            tab.Summary:Show()
        else
            tab.Summary:Hide()
        end
    end;
}
