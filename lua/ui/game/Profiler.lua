

local GameMain = import('/lua/ui/game/gamemain.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Observable = import("/lua/shared/observable.lua")
local ProfilerUtilities = import("/lua/ui/game/ProfilerUtilities.lua")
local SharedProfiler = import("/lua/shared/Profiler.lua")
local Statistics = import("/lua/shared/statistics.lua")
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

-- The benchmarks the user can interact with
local Benchmarks = Observable.Create()

-- Output of benchmarks
local BenchmarkOutput = Observable.Create()

-- Selected benchmark in the UI
local BenchmarkCategorySelected = Observable.Create()
local BenchmarkSelected = Observable.Create()
-- local BenchmarkOnProgress = Observable.Create()

local benchmarkDebugFunction
local benchmarkRunning = false
--local benchmarkRuns = 0
--local benchmarkProgress = 0

local list = false

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
            SelectedFile = 1,
            SelectedBenchmark = 0,
            StatCache = {},
        }
    }
}

local function StateSwitchHeader(target)
    State.Header = target

    -- hide all tabs
    for _, tab in State.Tabs do
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
    Benchmarks:Set(data)
end

function ReceiveBenchmarkOutput(data)
    SPEW("Received benchmark output")
    BenchmarkOutput:Set(data)
    if State.GUI then
        local benchmarkState = State.Tabs.Benchmarks
        local runButton = benchmarkState.GUI.RunButton
        runButton.label:SetText("Run")
        if benchmarkState.SelectedBenchmark ~= 0 then
            runButton:Enable()
        end
    end
    benchmarkRunning = false
end

-- doesn't work!
--function ReceiveBenchmarkProgress(data)
--    SPEW("Received benchmark progress!")
--    if data.runs then
--        benchmarkRuns = data.runs
--    end
--    if data.progress then
--        benchmarkProgress = data.progress
--        BenchmarkOnProgress:Set(benchmarkProgress < benchmarkRuns)
--    end
--end

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
        StateSwitchHeader(State.Header)
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
        State.Tabs.Benchmarks.GUI = self:InitBenchmarksTab(self._tabs)
        StateSwitchHeader(State.Header)
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
        -- split up UI
        local horzSplit = 0.45
        local vertSplit = 0.65

        local tab = Layouter(Group(parent))
            :AnchorToBottom(parent, 38)
            :Left(parent.Left)
            :Right(self.Right)
            :Bottom(self.Bottom)
            :End()

        local runButton = UIUtil.CreateButtonStd(tab, '/widgets02/small', "Run", 16, 2)
        local sep = runButton.Height() * 0.5 + 5

        local groupIO, groupByteCode = UIUtil.CreateHorzSplitGroups(tab, horzSplit, 1)

        local groupNavigation, groupDetails = UIUtil.CreateVertSplitGroups(groupIO, vertSplit, sep)

        LayoutHelpers.ReusedLayoutFor(runButton)
            :CenteredBelow(groupNavigation, 5)
            :Over(tab, 10)
            :End()
        runButton:Disable()

        --local benchmarkProgressLabel = LayoutHelpers.ReusedLayoutFor(UIUtil.CreateText(tab, "", 10, UIUtil.bodyFont, true))
        --    :RightOf(runButton)
        --    :End()

        local fileText = Layouter(UIUtil.CreateText(groupNavigation, "Files with benchmarks", 16, UIUtil.bodyFont, true))
            :AtTopIn(groupNavigation, 10)
            :AtLeftIn(groupNavigation, 10)
            :End()

        local filePicker = Layouter(Combo(tab, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :Below(fileText, 10)
            :AtLeftIn(groupNavigation, 10)
            :AtRightIn(groupNavigation, 10)
            :Over(tab, 10)
            :End()

        local benchmarkText = Layouter(UIUtil.CreateText(tab, "Benchmarks in file", 16, UIUtil.bodyFont, true))
            :Below(filePicker, 10)
            :AtLeftIn(tab, 10)
            :End()

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
        benchmarkList:SetColors(UIUtil.fontColor, "00000000", "FF000000", UIUtil.highlightColor, "ffbcfffe")
        benchmarkList:ShowMouseoverItem(true)
        UIUtil.CreateLobbyVertScrollbar(benchmarkList, 0, 0, 0)

        local details = Layouter(Group(groupDetails))
            :FillFixedBorder(groupDetails, 10)
            :End()

        local bytecodeParams = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :AtTopIn(groupByteCode, 5)
            :AtLeftIn(groupByteCode, 10)
            :Over(groupByteCode, 10)
            :End()
        local bytecodeStack = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeParams, 10)
            :Over(groupByteCode, 10)
            :End()
        local bytecodeUpvals = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeStack, 10)
            :Over(groupByteCode, 10)
            :End()
        local bytecodeConsts = Layouter(UIUtil.CreateText(tab, "", 14, UIUtil.bodyFont, true))
            :RightOf(bytecodeUpvals, 10)
            :Over(groupByteCode, 10)
            :End()

        local bytecode = Layouter(ItemList(benchmarkArea))
            :Left(groupByteCode.Left)
            :Top(bytecodeStack.Bottom)
            :AtRightIn(groupByteCode, 14 + 5)
            :AtBottomIn(groupByteCode,     5)
            :Over(groupByteCode, 10)
            :End()
        bytecode:SetFont(UIUtil.fixedFont, 14)
        UIUtil.CreateLobbyVertScrollbar(bytecode, 0, 0, 0)
        -- AaaaAaaahhh, it doesn't work
        --UIUtil.CreateLobbyHorzScrollbar(bytecode, 0, 0, 0)

        local statsLabel = Layouter(UIUtil.CreateText(details, "Time Summary", 16, UIUtil.bodyFont, true))
            :AtTopCenterIn(details, 5)
            :End()

        local statsMean = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Below(statsLabel, 5)
            :AtLeftIn(details)
            :End()

        local statsDev = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Below(statsMean, 3)
            :AtLeftIn(details)
            :End()

        local statsSkew = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Below(statsDev, 3)
            :AtLeftIn(details)
            :End()

        local statsKurt = Layouter(UIUtil.CreateText(details, "", 14, UIUtil.bodyFont, true))
            :Below(statsSkew, 3)
            :AtLeftIn(details)
            :End()

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

        runButton.OnClick = function(self)
            if benchmarkRunning then
                return
            end
            local benchmarkState = State.Tabs.Benchmarks
            local file = benchmarkState.SelectedFile
            local benchmark = benchmarkState.SelectedBenchmark
            if file > 0 and benchmark > 0 then
                benchmarkRunning = true
                SimCallback({
                    Func = "RunBenchmark",
                    Args = {
                        File = file,
                        Benchmark = benchmark,
                    }
                })
                runButton.label:SetText("Running...")
                runButton:Disable()
            end
        end
        filePicker.OnClick = function(self, index, text)
            -- index is already 1-indexed for Combo boxes
            local benchmarkState = State.Tabs.Benchmarks
            if index == benchmarkState.SelectedFile then
                return
            end
            benchmarkState.SelectedFile = index
            BenchmarkCategorySelected:Set(index)
        end
        benchmarkList.OnClick = function(self, rawIndex, text)
            local index = rawIndex + 1 -- make 1-indexed
            local benchmarkState = State.Tabs.Benchmarks
            if index == benchmarkState.SelectedBenchmark then
                return
            end
            ItemList.OnClick(self, rawIndex)
            benchmarkState.SelectedBenchmark = index
            benchmarkState.Categories[benchmarkState.SelectedFile].LastBenchmarkSelected = index
            BenchmarkSelected:Set(index)
        end

        local function PopulateFilePicker(info)
            -- find keys
            local keys = {}
            for k, category in info do
                local categoryName = category.name
                if categoryName == "" then
                    local folder = category.folder
                    if folder:sub(-1) ~= '/' then
                        folder = folder .. '/'
                    end
                    local folderLen = string.len(folder)
                    categoryName = category.file
                    if string.sub(categoryName, 1, folderLen) == folder then
                        categoryName = string.sub(categoryName, folderLen + 1)
                    end
                end
                keys[k] = categoryName
            end
            local i = State.Tabs.Benchmarks.SelectedFile
            State.Tabs.Benchmarks.FileComboKeys = keys
            filePicker:ClearItems()
            filePicker:AddItems(keys, i, i)
        end

        local function SetData(info)
            for _, cat in info do
                cat.LastBenchmarkSelected = 0
            end
            State.Tabs.Benchmarks.Categories = info
            BenchmarkCategorySelected:Set(1)
        end

        local function PopulateBenchmarkList(index)
            benchmarkList:DeleteAllItems()
            local benchmarkState = State.Tabs.Benchmarks
            local benchmarks = benchmarkState.Categories[index]
            local lastSelected = benchmarks.LastBenchmarkSelected
            BenchmarkSelected:Set(lastSelected)
            benchmarkState.SelectedBenchmark = lastSelected
            if benchmarks.faulty then
                benchmarkList:AddItem("Error loading file")
                bytecode:AddItem(benchmarks.desc)
            else
                local keys = {}
                for k, element in benchmarks.benchmarks do
                    keys[k] = element
                    local name = element.title
                    if name == "" then
                        name = element.name
                    end
                    benchmarkList:AddItem(name)
                end
                State.Tabs.Benchmarks.BenchmarkComboKeys = keys
                if lastSelected ~= 0 then
                    benchmarkList:SetSelection(lastSelected - 1)
                end
            end
        end

        local function CacheStats(data)
            local benchmarkState = State.Tabs.Benchmarks
            local key = benchmarkState.SelectedFile .. "," .. benchmarkState.SelectedBenchmark
            benchmarkState.StatCache[key] = data
        end

        local function SetStats(data)
            if not data.n then
                local benchmarkState = State.Tabs.Benchmarks
                local key = tostring(benchmarkState.SelectedFile) .. "," .. tostring(benchmarkState.SelectedBenchmark)
                data = benchmarkState.StatCache[key]
            end
            local samp, n = data.data, data.samples
            if n then
                local obj = Statistics.StatObject(samp, n)
                statsLabel:SetText("Time Summary (" .. n .. " samples)")
                statsMean:SetText("Mean: " .. obj.mean)
                statsDev:SetText("Deviation: " .. obj.deviation)
                statsSkew:SetText("Skewness: " .. obj.sampSkewness)
                statsKurt:SetText("Excess Kurtosis: " .. obj.normalExcessKurtosis)
            else
                statsLabel:SetText("Time Summary")
                statsMean:SetText("")
                statsDev:SetText("")
                statsSkew:SetText("")
                statsKurt:SetText("")
            end
        end

        local function UpdateDetails(index)
            local benchmarks = State.Tabs.Benchmarks.Categories[index]
            local num
            if benchmarks.faulty then
                num = "unknown"
            else
                num = table.getn(benchmarks.benchmarks)
            end
            benchmarkText:SetText("Benchmarks in file: " .. num)
        end

        local function PopulateCodeArea(benchmarkInd)
            bytecode:DeleteAllItems()
            if benchmarkInd == 0 then
                bytecodeParams:SetText("")
                bytecodeStack:SetText("")
                bytecodeUpvals:SetText("")
                bytecodeConsts:SetText("")
                return
            end
            local benchmarkState = State.Tabs.Benchmarks
            local categoryData = benchmarkState.Categories[benchmarkState.SelectedFile]
            local funcData = categoryData.benchmarks[benchmarkInd]
            local file = categoryData.file
            local category = import(file)
            if not category[funcData.name] then
                WARN("can't open benchmark category at " .. tostring(file))
                bytecodeParams:SetText("")
                bytecodeStack:SetText("")
                bytecodeUpvals:SetText("")
                bytecodeConsts:SetText("")
                return
            end

            benchmarkDebugFunction = DebugFunction(category[funcData.name])
            bytecodeParams:SetText("Parameters: " .. benchmarkDebugFunction.numparams)
            bytecodeStack:SetText("Max Stack: " .. benchmarkDebugFunction.maxstack)
            bytecodeUpvals:SetText("Upvalues: " .. benchmarkDebugFunction.nups)
            bytecodeConsts:SetText("Constants: " .. benchmarkDebugFunction.constantCount)
            local jumps = benchmarkDebugFunction:ResolveJumps()
            local instructionCount = 0
            for _, line in benchmarkDebugFunction.lines do
                bytecode:AddItem("Line " .. line.lineNumber .. ":")
                local prepend
                for i = 1, line.instructionCount do
                    local instr = line[i]
                    local str = instr:ToString(benchmarkDebugFunction)
                    -- insert jump indicator if the instruction is jumped to by another instruction
                    if jumps[instructionCount] then
                        str = str:sub(1, 9) .. ">" .. str:sub(10)
                    end
                    local controlFlow = instr.opcode.controlFlow
                    if prepend then
                        str = prepend .. str
                        prepend = nil
                    else
                        str = "    " .. str
                    end
                    if controlFlow == "skip" then
                        prepend = "        "
                    end
                    bytecode:AddItem(str)
                    instructionCount = instructionCount + 1
                end
            end
        end

        local function SetRunButtonState(index)
            if index == 0 or benchmarkRunning then
                runButton:Disable()
            else
                runButton:Enable()
            end
        end

        --local function UpdateBenchmarkProgress(prog)
        --    if prog then
        --        benchmarkProgressLabel:SetText(benchmarkProgress .. " / " .. benchmarkRuns)
        --    else
        --        benchmarkProgressLabel:SetText("")
        --    end
        --end

        -- allows us to act on changes
        Benchmarks:AddObserver(PopulateFilePicker)
        Benchmarks:AddObserver(SetData)
        BenchmarkCategorySelected:AddObserver(PopulateBenchmarkList)
        BenchmarkCategorySelected:AddObserver(UpdateDetails)
        BenchmarkCategorySelected:AddObserver(SetStats)
        BenchmarkSelected:AddObserver(PopulateCodeArea)
        BenchmarkSelected:AddObserver(SetRunButtonState)
        BenchmarkSelected:AddObserver(SetStats)
        BenchmarkOutput:AddObserver(CacheStats)
        BenchmarkOutput:AddObserver(SetStats)
        --BenchmarkOnProgress:AddObserver(UpdateBenchmarkProgress)

        -- hide it by default
        tab:Hide()
        State.Tabs.Benchmarks.GUI = tab
        State.Tabs.Benchmarks.GUI.RunButton = runButton
        self._tabs.BenchmarkTab = tab
        self._tabs.BenchmarksButton = runButton
        return tab
    end,

    OnClose = function(self)
        CloseWindow()
    end
}
