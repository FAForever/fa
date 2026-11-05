--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

-- Note to modders:
-- if you feel the need to extend the capabilities of this file, please make a pull request to
-- https://github.com/FAForever/fa/blob/deploy/fafdevelop/lua/ui/game/Profiler.lua
-- so that the contribution is available to everyone

---@alias ProfilerTab "Overview" | "Timers" | "Stamps" | "Benchmarks" | "Options"

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local ProfilerElements = import("/lua/ui/game/profilerelements.lua")
local ProfilerReport = import("/lua/ui/game/profilerreport.lua")
local ProfilerUtilities = import("/lua/ui/game/profilerutilities.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")
local UIUtil = import("/lua/ui/uiutil.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo = import("/lua/ui/controls/combo.lua").Combo
local DebugFunction = import("/lua/shared/debugfunction.lua").DebugFunction
local Edit = import("/lua/maui/edit.lua").Edit
local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Window = import("/lua/maui/window.lua").Window

local ObservableCreate = import("/lua/shared/observable.lua").Create
local CreateEmptyProfilerTable = import("/lua/shared/profiler.lua").CreateEmptyProfilerTable
local CoarseTimerFactor = import("/lua/shared/statistics.lua").CoarseTimerFactor
local IsTimerTooCoarse = import("/lua/shared/statistics.lua").IsTimerTooCoarse
local Mean = import("/lua/shared/statistics.lua").Mean
local TimestampResolution = import("/lua/shared/statistics.lua").TimestampResolution
local Layouter = LayoutHelpers.ReusedLayoutFor
local Summarize = ProfilerElements.Summarize

-- "Run to 5%" repeats the benchmark until the 95% confidence interval of the mean is this narrow
local AutoRunMargin = 0.05
local AutoRunMinSamples = 5
local AutoRunMaxSamples = 1000

-- Multiplies a module's loop count so short benchmarks take longer than the timer's resolution
local LoopMultipliers = {1, 2, 5, 10, 20, 50, 100}
-- Second parameter, for benchmarks with an inner loop
local InnerLoopCount = 45

local sessionInfo = SessionGetScenarioInfo()
local data = CreateEmptyProfilerTable()

-- keep track of data of the last few ticks
local growth = {}
local growthHead = 1
local growthCount = 10
for k = 1, growthCount do
    growth[k] = {
        tick = -1,
        data = CreateEmptyProfilerTable(),
    }
end

---@type ProfilerWindow
local GUI = false

-- complete state of this window
local State = {
    -- State
    Header = "Overview",
    WindowIsOpen = false,

    Overview = {
        Search = false,
        SortOn = "name",
    },
    Samples = {},
    Stamps = {},
    Benchmarks = {
        AutoRun = false,
        BenchmarkProgress = 0,
        BenchmarkRunning = false,
        ---@type number
        BenchmarkRunningMod = false,
        ---@type number
        BenchmarkRunningBen = false,
        BenchmarkRuns = 0,
        ---@type UserBenchmarkModule[]
        Modules = false,
        LoopMultiplier = 1,
        ---@type table<string, number>
        ParameterCountCache = {},
        --- Set while "Module to 5%" or "All to 5%" steps through the benchmarks
        ---@type { module: number, index: number, waiting: boolean, allModules: boolean, coarse: string[] } | false
        RunAll = false,
        SelectedBenchmark = 0,
        SelectedModule = 1,
        ---@type table<string, number[]>
        StatCache = {},
        ---@type table<string, number[]>
        BaselineCache = {},
    },
    Options = {},
}

local BenchmarkModuleSelected = ObservableCreate() ---@type Observer<integer>
local BenchmarkSelected = ObservableCreate() ---@type Observer<integer>
local BenchmarkModulesReceived = ObservableCreate() ---@type Observer<UserBenchmarkModule[]>
local BenchmarkInfoReceived = ObservableCreate() ---@type Observer<RawFunctionDebugInfo>
local BenchmarkOutputReceived = ObservableCreate() ---@type Observer<BenchmarkOutput>


--- Received data from the sim about function calls
---@param info ProfilerData
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
    local list = GUI.Tabs.Overview.list
    if list then
        local growthCombined = ProfilerUtilities.Combine(growth)
        local growthLookup = ProfilerUtilities.LookUp(growthCombined)
        local overviewState = State.Overview
        local cache, count = ProfilerUtilities.Format(data, growthLookup, false, false, overviewState.Search)
        local sorted, count = ProfilerUtilities.Sort(cache, count, overviewState.SortOn)
        list:ProvideElements(sorted, count)
        list:CalcVisible()
    end
end

---@param data UserBenchmarkModule[]
function ReceiveBenchmarkModules(data)
    BenchmarkModulesReceived:Set(data)
end

---@param data RawFunctionDebugInfo
function ReceiveBenchmarkInfo(data)
    BenchmarkInfoReceived:Set(data)
end

---@param data BenchmarkOutput
function ReceiveBenchmarkOutput(data)
    BenchmarkOutputReceived:Set(data)
end

--- Toggles the profiler in the simulation, sends along the army that initiated the call
function ToggleProfiler()
    SimCallback({
        Func = "ToggleProfiler",
        Args = {
            ForceEnable = false,
        }
    })
end

-- note: this function can be hooked by UI mods to access the window, but the sim still
-- locks the player out

---@return boolean
local function CanUseProfiler()
    return sessionInfo.Options.CheatsEnabled == "true"
end

---@param modIndex? number
---@param benIndex? number
---@param multiplier? number defaults to the selected loop multiplier
local function GetBenchmarkCacheKey(modIndex, benIndex, multiplier)
    local state = State.Benchmarks
    modIndex = modIndex or state.SelectedModule
    benIndex = benIndex or state.SelectedBenchmark
    -- each multiplier keeps its own samples, since it changes how long they take
    return tostring(modIndex) .. ',' .. tostring(benIndex) .. ',x' .. tostring(multiplier or state.LoopMultiplier)
end

--- Gets the parameters a module's benchmarks run with: its loop count times the multiplier, then the
--- inner loop count. The baseline loops get the same parameters.
---@param modIndex number
---@return number[]
local function GetBenchmarkParameters(modIndex)
    local state = State.Benchmarks
    return {state.Modules[modIndex].loopCount * state.LoopMultiplier, InnerLoopCount}
end

---@param modIndex? number
---@param benIndex? number
---@param multiplier? number defaults to the selected loop multiplier
---@return number[]?
---@return number[]?
local function GetBenchmarkStatCache(modIndex, benIndex, multiplier)
    local key = GetBenchmarkCacheKey(modIndex, benIndex, multiplier)
    return State.Benchmarks.StatCache[key], State.Benchmarks.BaselineCache[key]
end

---@param data number[] | nil
---@param baselines number[] | nil
---@param modIndex? number
---@param benIndex? number
local function SetBenchmarkStatCache(data, baselines, modIndex, benIndex)
    local key = GetBenchmarkCacheKey(modIndex, benIndex)
    State.Benchmarks.StatCache[key] = data
    State.Benchmarks.BaselineCache[key] = baselines
end

---@param data { [integer]: number, n: integer } | nil
---@param baselines number[]
---@param modIndex? number
---@param benIndex? number
---@return { [integer]: number, n: integer } | nil data
---@return { [integer]: number, n: integer } | nil baselines
local function AddBenchmarkStatCache(data, baselines, modIndex, benIndex)
    local key = GetBenchmarkCacheKey(modIndex, benIndex)
    local statCaches = State.Benchmarks.StatCache
    local baseCaches = State.Benchmarks.BaselineCache
    local sCache = statCaches[key]
    local bCache = baseCaches[key]
    if not sCache then
        if data then
            local n = data.n
            sCache = {n = n}
            bCache = {n = n}
            for i = 1, n do
                sCache[i] = data[i]
                bCache[i] = baselines[i]
            end
            statCaches[key] = sCache
            baseCaches[key] = bCache
        end
    elseif data then
        local n = table.getn(data)
        local offset = table.getn(sCache)
        for i = 1, n do
            sCache[offset + i] = data[i]
            bCache[offset + i] = baselines[i]
        end
        table.setn(sCache, offset + n)
        table.setn(bCache, offset + n)
    else
        statCaches[key] = nil
        baseCaches[key] = nil
        return nil
    end
    return sCache, bCache
end

--- Gets the title of a benchmark, or its function name when it has no title
---@param modIndex number
---@param benIndex number
---@return string
local function GetBenchmarkName(modIndex, benIndex)
    local info = State.Benchmarks.Modules[modIndex].benchmarks[benIndex]
    if info.title ~= "" then
        return info.title
    end
    return info.name
end

--- Adds the loop multiplier to a name, unless it is x1
---@param name string
---@param multiplier number
---@return string
local function WithMultiplier(name, multiplier)
    if multiplier == 1 then
        return name
    end
    return name .. " (x" .. multiplier .. ")"
end

--- Checks whether any benchmark of a module has statistics, with any loop multiplier
---@param modIndex number
---@return boolean
local function ModuleHasData(modIndex)
    local benchmarks = State.Benchmarks.Modules[modIndex].benchmarks
    for benIndex = 1, table.getn(benchmarks or {}) do
        for _, multiplier in ipairs(LoopMultipliers) do
            if GetBenchmarkStatCache(modIndex, benIndex, multiplier) then
                return true
            end
        end
    end
    return false
end

--- Gets the loop multiplier that makes a benchmark's samples long enough for the timer, or nil when
--- they already are. Suggests the largest multiplier when none is enough.
---@param stats? { [integer]: number, n: integer }
---@param baselines? { [integer]: number, n: integer } checked too, for the modes that divide by them
---@param multiplier number that the samples were taken with
---@return number? needed
---@return number resolution seconds
---@return number? mean seconds, of the shorter samples
local function GetNeededMultiplier(stats, baselines, multiplier)
    local resolution = TimestampResolution(GetSystemTimeSeconds())
    -- raw sample times, whatever the mode
    local mean = stats and stats.n > 0 and Mean(stats, stats.n)
    -- baseline loops are shorter than their benchmark, so they lose precision first
    if mean and baselines and baselines[1] ~= nil then
        mean = math.min(mean, Mean(baselines, table.getn(baselines)))
    end
    if not mean or not IsTimerTooCoarse(resolution, mean) then
        return nil, resolution, mean
    end
    local needed = multiplier * CoarseTimerFactor(resolution, mean)
    for _, option in ipairs(LoopMultipliers) do
        if option >= needed then
            return option, resolution, mean
        end
    end
    return LoopMultipliers[table.getn(LoopMultipliers)], resolution, mean
end

---@param lines string[]
local function LogLines(lines)
    for _, line in ipairs(lines) do
        LOG(line)
    end
end

---@param module number
---@param benchmark number
function LoadBenchmark(module, benchmark)
    SimCallback({
        Func = "LoadBenchmark",
        Args = {
            Module = module,
            Benchmark = benchmark,
        },
    })
end

---@param module number
---@param benchmark number
function StartBenchmark(module, benchmark)
    -- We asymetrically update the `benchmarkRunning` state to true on start, but wait for results
    -- from the sim on stop to set to false. This is so that we can't send benchmark requests
    -- to the sim while one is running.
    local benchmarkState = State.Benchmarks
    -- selecting the running benchmark again clears its count until the info arrives
    local params = benchmarkState.ParameterCount
        or benchmarkState.ParameterCountCache[GetBenchmarkCacheKey(module, benchmark)]
    if not params then
        WARN("Missing debug function to start benchmark")
        -- nothing will come back from the sim, so don't wait on it
        benchmarkState.AutoRun = false
        benchmarkState.RunAll = false
        return
    end
    benchmarkState.BenchmarkRunning = true
    benchmarkState.BenchmarkRunningMod = module
    benchmarkState.BenchmarkRunningBen = benchmark
    benchmarkState.ParameterCountCache[GetBenchmarkCacheKey(module, benchmark)] = params
    local parameters = {}
    local benchmarkParams = GetBenchmarkParameters(module)
    for i = 1, params do
        parameters[i] = benchmarkParams[i]
    end
    SPEW("Starting benchmark")
    SimCallback({
        Func = "RunBenchmark",
        Args = {
            Module = module,
            Benchmark = benchmark,
            Parameters = parameters,
        },
    })
    GUI.Tabs.Benchmarks:UpdateRunButtonState()
end

function StopBenchmark()
    SimCallback({
        Func = "StopBenchmark",
        Args = {},
    })
end

---@param target ProfilerTab
function SwitchHeader(target)
    local tabs = GUI.Tabs
    if tabs then
        State.Header = target

        -- hide all tabs
        for _, tab in tabs do
            tab:Hide()
        end

        -- show the tab we're interested in
        local tab = tabs[target]
        if tab then
            tab:Show()
            local onFocus = tab.OnFocus
            if onFocus then
                onFocus(tab)
            end
        end
    end
end

--- Closes the window
function CloseWindow()
    SPEW("Closing profiler window")
    State.WindowIsOpen = false
    local GUI = GUI
    if GUI then
        GUI:Hide()
    end
end

---@param parent Control
---@param tab string
---@return Group
local function CreateSearchBar(parent, tab)
    local searchbar = Group(parent)

    local text = UIUtil.CreateText(searchbar, LOC("<LOC profiler_0037>Search"), 18, UIUtil.bodyFont, true)
    local clearButton = UIUtil.CreateButtonStd(searchbar, "/widgets02/small", LOC("<LOC profiler_0038>Clear"), 14, 2)
    local edit = Edit(searchbar)

    searchbar.text = text
    searchbar.clearButton = clearButton
    searchbar.edit = edit

    function searchbar:OnLayout()
        self.Height:Set(self.clearButton.Height)
    end

    function searchbar:Layout()
        local text = Layouter(self.text)
            :AtLeftTopIn(self)
            :End()

        local clearButton = Layouter(self.clearButton)
            :AtVerticalCenterIn(text)
            :AtRightIn(self)
            :Over(self, 10)
            :End()

        Layouter(self.edit)
            :CenteredRightOf(text, 6)
            :AnchorToLeft(clearButton, 6)
            :Over(self, 10)
            :Height(function()
                return edit:GetFontHeight()
            end)
            :Setup(
                UIUtil.fontColor, "ff060606",
                UIUtil.highlightColor, "880085EF",
                UIUtil.bodyFont, 14,
                30
            )
            :End()
    end

    clearButton.OnClick = function()
        edit:ClearText()
        State[tab].Search = false
    end
    edit.OnTextChanged = function(edit_self, new, old)
        State[tab].Search = new
        GUI.Tabs[tab].list:ScrollLines(false, 0)
    end

    return searchbar
end

---@param parent Control
---@param tab string
---@return Group
local function CreateSortBar(parent, tab)
    local sortbar = Group(parent)

    local buttonName = UIUtil.CreateButtonStd(sortbar, "/widgets02/small", LOC("<LOC profiler_0039>Name"), 16, 2)
    local buttonCount = UIUtil.CreateButtonStd(sortbar, "/widgets02/small", LOC("<LOC profiler_0040>Count"), 16, 2)
    local buttonGrowth = UIUtil.CreateButtonStd(sortbar, "/widgets02/small", LOC("<LOC profiler_0024>Growth"), 16, 2)

    buttonName.SortOn = "name"
    buttonCount.SortOn = "value"
    buttonGrowth.SortOn = "growth"

    sortbar.buttonName = buttonName
    sortbar.buttonCount = buttonCount
    sortbar.buttonGrowth = buttonGrowth

    function sortbar:Layout()
        Layouter(self.buttonName)
            :FromLeftIn(self, 0.010)
            :FromTopIn(self)
            :Over(self, 10)
            :End()

        Layouter(self.buttonCount)
            :FromLeftIn(self, 0.620)
            :FromTopIn(self)
            :Over(self, 10)
            :End()

        Layouter(self.buttonGrowth)
            :FromLeftIn(self, 0.810)
            :FromTopIn(self)
            :Over(self, 10)
            :End()
    end

    local function onClick(self)
        State[tab].SortOn = self.SortOn
    end
    buttonName.OnClick = onClick
    buttonCount.OnClick = onClick
    buttonGrowth.OnClick = onClick

    return sortbar
end

--#region Tabs

---@class ProfilerOverview : Group
---@field searchBar Group
---@field sortGroup Group
---@field list ProfilerScrollArea
ProfilerOverview = Class(Group) {
    ---@param self ProfilerOverview
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)

        self.searchBar = CreateSearchBar(self, "Overview")
        self.sortGroup = CreateSortBar(self, "Overview")
        self.list = ProfilerElements.ProfilerScrollArea(self)
    end,

    Layout = function(self)
        local searchBar = Layouter(self.searchBar)
            :AtLeftTopIn(self, 10, 10)
            :AtRightIn(self, 10)
            :End()

        local sortGroup = Layouter(self.sortGroup)
            :Height(30) -- better to set height for control
            :AnchorToBottom(searchBar, 10)
            :Left(self.Left)
            :Right(self.Right)
            :End()

        Layouter(self.list)
            :AnchorToBottom(sortGroup, 8)
            :AtBottomIn(self, 2)
            :AtLeftIn(self, 2)
            :AtRightIn(self, 2 + 14)
            :End()
    end,
}

---@class ProfilerTimers : Group
ProfilerTimers = Class(Group) {
    ---@param self ProfilerTimers
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
    end
}

---@class ProfilerStamps : Group
ProfilerStamps = Class(Group) {
    ---@param self ProfilerStamps
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
    end
}

---@class ProfilerBenchmarks : Group
---@field autoRunButton Button
---@field benchmarkText Text
---@field benchmarkList ItemList | { background: Bitmap }
---@field bytecode BytecodeArea
---@field fileText Text
---@field groupActions Group
---@field groupInput Group
---@field groupInteraction Group
---@field groupNavigation Group
---@field groupOutput Group
---@field logAllButton Button
---@field logButton Button
---@field logModulesButton Button
---@field loopMultiplier Combo
---@field modulePicker Combo
---@field parametersLabel ItemList
---@field progressLabel Text
---@field runAllButton Button
---@field runButton Button
---@field runModulesButton Button
---@field summary StatisticSummary
---@field timerWarning Text
ProfilerBenchmarks = Class(Group) {
    ---@param self ProfilerBenchmarks
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)

        self.groupInput = Group(self)
        self.groupOutput = Group(self)
        self.groupInteraction = Group(self.groupInput)
        self.groupNavigation = Group(self.groupInput)
        self.groupActions = Group(self.groupInput)
        self.autoRunButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0043>Run to 5%"), 14, 2)
        self.runAllButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0052>Module to 5%"), 14, 2)
        self.runModulesButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0055>All to 5%"), 14, 2)
        self.logModulesButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0058>Log all"), 14, 2)
        self.logButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0046>Log"), 14, 2)
        self.logAllButton = UIUtil.CreateButtonStd(self.groupActions, "/widgets02/small", LOC("<LOC profiler_0049>Log module"), 14, 2)
        self.runButton = UIUtil.CreateButtonStd(self.groupInteraction, "/widgets02/small", LOC("<LOC profiler_0006>Run"), 16, 2)
        self.parametersLabel = ItemList(self.groupInteraction, 0, 0)
        self.loopMultiplier = Combo(self.groupInteraction, 14, table.getn(LoopMultipliers))
        self.progressLabel = UIUtil.CreateText(self.groupInteraction, "", 10, UIUtil.bodyFont, true)
        self.fileText = UIUtil.CreateText(self.groupNavigation, LOC("<LOC profiler_0007>Benchmark Modules"), 16, UIUtil.bodyFont, true)
        self.modulePicker = Combo(self.groupNavigation, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        self.timerWarning = UIUtil.CreateText(self.groupNavigation, "", 12, UIUtil.bodyFont, true)
        self.benchmarkText = UIUtil.CreateText(self.groupNavigation, "", 16, UIUtil.bodyFont, true) -- should immediately update, so no need to set label
        self.benchmarkList = ItemList(self.groupNavigation)
        self.benchmarkList.background = Bitmap(self.benchmarkList)
        self.bytecode = ProfilerElements.BytecodeArea(self.groupOutput)
        self.summary = ProfilerElements.StatisticSummary(self.groupOutput)

        self.runButton.OnClick = function(button_self)
            self:OnClickRunButton()
        end
        self.autoRunButton.OnClick = function(button_self)
            self:OnClickRunButton(true)
        end
        self.runAllButton.OnClick = function(button_self)
            self:OnClickRunAllButton(false)
        end
        self.runModulesButton.OnClick = function(button_self)
            self:OnClickRunAllButton(true)
        end
        self.logModulesButton.OnClick = function(button_self)
            self:LogModules()
        end
        self.logButton.OnClick = function(button_self)
            self:OnClickLogButton()
        end
        self.logAllButton.OnClick = function(button_self)
            self:OnClickLogAllButton()
        end
        local multiplierLabels = {}
        for i, multiplier in LoopMultipliers do
            multiplierLabels[i] = "x" .. multiplier
        end
        self.loopMultiplier:AddItems(multiplierLabels)
        self.loopMultiplier.OnClick = function(combo_self, index)
            State.Benchmarks.LoopMultiplier = LoopMultipliers[index]
            self:UpdateParametersLabel()
            self:UpdateBenchmarkStats()
            self:UpdateRunButtonState()
        end
        self.modulePicker.OnClick = function(picker_self, index, text)
            -- index is already 1-indexed for Combo boxes
            if index == State.Benchmarks.SelectedModule then
                return
            end
            BenchmarkModuleSelected:Set(index)
        end
        self.benchmarkList.OnClick = function(list_self, rawIndex, text)
            local index = rawIndex + 1 -- make 1-indexed
            if index == State.Benchmarks.SelectedBenchmark then
                return
            end
            ItemList.OnClick(list_self, rawIndex)
            BenchmarkSelected:Set(index)
        end
        local hook = self.summary.OnClickClearSummary
        self.summary.OnClickClearSummary = function(summary_self)
            local hook = hook
            if hook then
                hook(summary_self)
            end
            SetBenchmarkStatCache(nil)
            self:UpdateRunButtonState()
        end

        BenchmarkModuleSelected:AddObserver(function(index)
            self:SelectModule(index)
        end)
        BenchmarkSelected:AddObserver(function(index)
            self:SelectBenchmark(index)
        end)
    end,

    ---@param self ProfilerBenchmarks
    Layout = function(self)
        local groupInput = self.groupInput
        local groupOutput = self.groupOutput

        LayoutHelpers.SplitHorizontallyIn(groupInput, groupOutput, self, 0.45, 1)

        local groupInteraction = Layouter(self.groupInteraction)
            :FillFixedBorder(groupInput, 5)
            :Height(function() return self.runButton.Height() + 10 end)
            :ResetTop()
            :End()

        local groupActions = Layouter(self.groupActions)
            :FillHorizontally(groupInteraction)
            :Height(function() return 3 * self.autoRunButton.Height() + 20 end)
            :AnchorToTop(groupInteraction)
            :ResetTop()
            :End()

        local groupNavigation = Layouter(self.groupNavigation)
            :Fill(groupInput)
            :AnchorToTop(groupActions, 5)
            :End()

        -- Action components

        -- run buttons on the left, the matching log buttons on the right
        local autoRunButton = Layouter(self.autoRunButton)
            :FromLeftIn(groupActions, 0.02)
            :AtTopIn(groupActions, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(autoRunButton, "profiler_benchmark_run_margin")

        local runAllButton = Layouter(self.runAllButton)
            :FromLeftIn(groupActions, 0.02)
            :Below(autoRunButton, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(runAllButton, "profiler_benchmark_run_all_margin")

        local runModulesButton = Layouter(self.runModulesButton)
            :FromLeftIn(groupActions, 0.02)
            :Below(runAllButton, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(runModulesButton, "profiler_benchmark_run_modules_margin")

        local logButton = Layouter(self.logButton)
            :FromLeftIn(groupActions, 0.52)
            :AtTopIn(groupActions, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(logButton, "profiler_benchmark_log")

        local logAllButton = Layouter(self.logAllButton)
            :FromLeftIn(groupActions, 0.52)
            :Below(logButton, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(logAllButton, "profiler_benchmark_log_all")

        local logModulesButton = Layouter(self.logModulesButton)
            :FromLeftIn(groupActions, 0.52)
            :Below(logAllButton, 5)
            :Over(groupActions, 10)
            :Disable()
            :End()
        Tooltip.AddButtonTooltip(logModulesButton, "profiler_benchmark_log_modules")

        -- Interaction components

        local runButton = Layouter(self.runButton)
            :AtCenterIn(groupInteraction)
            :Over(groupInteraction, 10)
            :Disable()
            :End()

        local parametersLabel = self.parametersLabel
        Layouter(parametersLabel)
            :AtLeftIn(groupInteraction)
            :AnchorToLeft(runButton)
            :AtVerticalCenterIn(groupInteraction)
            :ResetWidth()
            :Height(function()
                return (1 + parametersLabel:GetItemCount()) * parametersLabel:GetRowHeight() + 10
            end)
            :Font(UIUtil.bodyFont, 10)
            :Colors(
                UIUtil.fontColor, "00000000",
                UIUtil.fontColor, "00000000",
                UIUtil.fontColor, "00000000"
            )
            :End()

        Layouter(self.progressLabel)
            :CenteredRightOf(runButton)
            :End()

        local loopMultiplier = Layouter(self.loopMultiplier)
            :AtRightIn(groupInteraction, 10)
            :AtVerticalCenterIn(groupInteraction)
            :Width(60)
            :End()
        Tooltip.AddControlTooltip(loopMultiplier, "profiler_benchmark_loop_multiplier")

        -- Navigation components

        local fileText = Layouter(self.fileText)
            :AtLeftTopIn(groupNavigation, 10, 10)
            :End()

        local timerWarning = Layouter(self.timerWarning)
            :AtRightIn(groupNavigation, 10)
            :AtVerticalCenterIn(fileText)
            :Color("FFFFA500")
            :Hide()
            :End()
        Tooltip.AddControlTooltip(timerWarning, "profiler_benchmark_timer")

        local modulePicker = Layouter(self.modulePicker)
            :Below(fileText, 10)
            :AtLeftIn(groupNavigation, 10)
            :AtRightIn(groupNavigation, 10)
            :Over(groupNavigation, 10)
            :End()

        local benchmarkText = Layouter(self.benchmarkText)
            :Below(modulePicker, 8)
            :AtLeftIn(groupNavigation, 10)
            :End()

        local benchmarkList = Layouter(self.benchmarkList)
            :OffsetIn(groupNavigation, 10, 5, 10 + 14) -- leave space for scrollbar
            :AnchorToBottom(benchmarkText, 10)
            :Over(groupNavigation, 10)
            :Font(UIUtil.bodyFont, 14)
            :Colors(
                UIUtil.fontColor, "00000000",
                "FFFF00", "30bcfffe",
                UIUtil.highlightColor, "bcfffe"
            )
            :MouseoverItem(true)
            :End() --[[ @as ItemList | { background: Bitmap } ]]
        UIUtil.CreateLobbyVertScrollbar(benchmarkList, 0, 0, 0)

        Layouter(benchmarkList.background)
            :FillFixedBorder(benchmarkList)
            :Under(benchmarkList, 5)
            :Color("7f000000")
            :End()

        -- Output components

        local summary = Layouter(self.summary)
            :FillHorizontally(groupOutput)
            :AtBottomIn(groupOutput)
            :End()

        Layouter(self.bytecode)
            :Fill(groupOutput)
            :Bottom(summary.Top)
            :End()
    end,

    ---@param self ProfilerBenchmarks
    OnFocus = function(self)
        -- rehide components
        self:UpdateBenchmarkStats()
        self.progressLabel:Hide()
    end,

    --- Starts the selected benchmark, or stops the running one
    ---@param self ProfilerBenchmarks
    ---@param autoRun? boolean keep running until the margin is reached
    OnClickRunButton = function(self, autoRun)
        local benchmarkState = State.Benchmarks
        if benchmarkState.BenchmarkRunning then
            benchmarkState.AutoRun = false
            StopBenchmark()
            return
        end
        local module = benchmarkState.SelectedModule
        local benchmark = benchmarkState.SelectedBenchmark
        if module > 0 and benchmark > 0 then
            benchmarkState.AutoRun = autoRun == true
            StartBenchmark(module, benchmark)
        end
    end,

    --- Starts another run until the margin is reached, called when a run finishes
    ---@param self ProfilerBenchmarks
    ---@param output BenchmarkOutput
    ContinueAutoRun = function(self, output)
        local benchmarkState = State.Benchmarks
        if not benchmarkState.AutoRun or output.success == nil then
            return
        end
        benchmarkState.AutoRun = false

        local module = benchmarkState.BenchmarkRunningMod
        local benchmark = benchmarkState.BenchmarkRunningBen
        -- stopping clears `AutoRun` first, so a failure here is an error in the benchmark
        if not output.success then
            self:WarnCoarseTimer(module, benchmark)
            self:AdvanceRunAll()
            return
        end

        local stats, baselines = GetBenchmarkStatCache(module, benchmark)
        -- cleared, or the selection (and its parameters) changed
        if not stats
            or module ~= benchmarkState.SelectedModule or benchmark ~= benchmarkState.SelectedBenchmark then
            self:CancelRunAll()
            return
        end

        local summary = Summarize(stats, baselines, self.summary:GetMode())
        local margin = summary.relativeMargin
        -- a zero mean has no relative margin, but identical samples can't improve any further
        if summary.n >= AutoRunMinSamples and summary.mean == 0 and summary.margin == 0 then
            WARN("Benchmark samples are all zero, the timer is too coarse to measure it")
            self:WarnCoarseTimer(module, benchmark)
            self:AdvanceRunAll()
        elseif stats.n >= AutoRunMinSamples and (summary.n == 0 or summary.mean ~= summary.mean or summary.mean == math.huge) then
            -- paired samples divided by zero baselines are all removed, and a ratio over them is infinite
            WARN("Benchmark baselines are zero, the timer is too coarse to measure them")
            self:WarnCoarseTimer(module, benchmark)
            self:AdvanceRunAll()
        elseif margin and summary.n >= AutoRunMinSamples and margin <= AutoRunMargin then
            SPEW(("Benchmark reached +/-%.1f%% with %d samples"):format(margin * 100, summary.n))
            self:WarnCoarseTimer(module, benchmark)
            self:AdvanceRunAll()
        elseif stats.n >= AutoRunMaxSamples then
            WARN(("Benchmark did not reach +/-%.0f%% within %d samples"):format(AutoRunMargin * 100, stats.n))
            self:WarnCoarseTimer(module, benchmark)
            self:AdvanceRunAll()
        else
            benchmarkState.AutoRun = true
            StartBenchmark(module, benchmark)
        end
    end,

    --- Starts or stops stepping through the benchmarks of the selected module, or of every module
    ---@param self ProfilerBenchmarks
    ---@param allModules boolean
    OnClickRunAllButton = function(self, allModules)
        local benchmarkState = State.Benchmarks
        local runAll = benchmarkState.RunAll
        if runAll then
            if runAll.stopping then
                return
            end
            benchmarkState.AutoRun = false
            if benchmarkState.BenchmarkRunning then
                -- the summary waits for the stopped benchmark's own timer warning
                runAll.stopping = true
                StopBenchmark()
            else
                self:CancelRunAll()
            end
            self:UpdateRunButtonState()
            return
        end
        if benchmarkState.BenchmarkRunning then
            return
        end

        local moduleIndex = 0 -- before the first module
        if not allModules then
            moduleIndex = benchmarkState.SelectedModule
            local module = benchmarkState.Modules and benchmarkState.Modules[moduleIndex]
            if not module or module.faulty then
                return
            end
        end
        benchmarkState.RunAll = {module = moduleIndex, index = 0, waiting = false, allModules = allModules, coarse = {}}
        self:AdvanceRunAll()
        self:UpdateRunButtonState()
    end,

    --- Gets the first module after `index` that has benchmarks to run
    ---@param self ProfilerBenchmarks
    ---@param index number
    ---@return number?
    FindNextModule = function(self, index)
        local modules = State.Benchmarks.Modules
        for i = index + 1, table.getn(modules) do
            local module = modules[i]
            if not module.faulty and table.getn(module.benchmarks) > 0 then
                return i
            end
        end
    end,

    --- Selects the next benchmark, which is started once its info arrives
    ---@param self ProfilerBenchmarks
    AdvanceRunAll = function(self)
        local benchmarkState = State.Benchmarks
        local runAll = benchmarkState.RunAll
        if not runAll then
            return
        end

        runAll.index = runAll.index + 1
        local module = benchmarkState.Modules[runAll.module]
        if not module or module.faulty or runAll.index > table.getn(module.benchmarks) then
            local nextModule = runAll.allModules and self:FindNextModule(runAll.module)
            if not nextModule then
                benchmarkState.RunAll = false
                SPEW("Finished running all benchmarks")
                self:WarnCoarseTimers(runAll)
                if runAll.allModules then
                    self:LogModules()
                end
                return
            end

            runAll.module = nextModule
            runAll.index = 1
            runAll.waiting = true
            -- selecting the module also selects its last benchmark, so make that the one we want
            benchmarkState.Modules[nextModule].LastBenchmarkSelected = 1
            self.modulePicker:SetItem(nextModule)
            BenchmarkModuleSelected:Set(nextModule)
            return
        end
        runAll.waiting = true
        BenchmarkSelected:Set(runAll.index)
    end,

    --- Warns when the timer was too coarse for a benchmark's samples, and suggests a loop multiplier.
    --- While running all, the warning is also kept for the summary at the end.
    ---@param self ProfilerBenchmarks
    ---@param module number
    ---@param benchmark number
    WarnCoarseTimer = function(self, module, benchmark)
        local benchmarkState = State.Benchmarks
        local multiplier = benchmarkState.LoopMultiplier
        local needed, resolution, mean = self:GetNeededMultiplier(module, benchmark, multiplier)
        if not needed then
            return
        end
        local moduleData = benchmarkState.Modules[module]
        local advice = "restart the game"
        if needed > multiplier then
            advice = ("use the x%d loop multiplier or restart the game"):format(needed)
        end
        local text = ('"%s" in %s: the %.3f ms timer resolution is too coarse for its %.3f ms samples, %s'):format(
            WithMultiplier(GetBenchmarkName(module, benchmark), multiplier),
            moduleData.name ~= "" and moduleData.name or moduleData.file,
            resolution * 1000, mean * 1000, advice)
        WARN(text)
        local runAll = benchmarkState.RunAll
        if runAll then
            table.insert(runAll.coarse, text)
        end
    end,

    --- Gets the loop multiplier that a benchmark's samples need, see `GetNeededMultiplier`
    ---@param self ProfilerBenchmarks
    ---@param module? number
    ---@param benchmark? number
    ---@param multiplier number
    ---@return number? needed
    ---@return number resolution seconds
    ---@return number? mean seconds
    GetNeededMultiplier = function(self, module, benchmark, multiplier)
        local stats, baselines = GetBenchmarkStatCache(module, benchmark)
        if self.summary:GetMode() == "none" then
            baselines = nil
        end
        return GetNeededMultiplier(stats, baselines, multiplier)
    end,

    --- Ends a module or all-module run before it finishes
    ---@param self ProfilerBenchmarks
    CancelRunAll = function(self)
        local benchmarkState = State.Benchmarks
        local runAll = benchmarkState.RunAll
        if runAll then
            benchmarkState.RunAll = false
            self:WarnCoarseTimers(runAll)
        end
    end,

    --- Repeats the timer warnings of a module or all-module run at its end
    ---@param self ProfilerBenchmarks
    ---@param runAll { coarse: string[] }
    WarnCoarseTimers = function(self, runAll)
        local count = table.getn(runAll.coarse)
        if count == 0 then
            return
        end
        WARN(("The timer was too coarse for %d benchmark%s:"):format(count, count == 1 and "" or "s"))
        for _, text in ipairs(runAll.coarse) do
            WARN("    " .. text)
        end
    end,

    --- Starts the benchmark that `AdvanceRunAll` selected, once its parameter count is known
    ---@param self ProfilerBenchmarks
    OnBenchmarkInfoReady = function(self)
        local benchmarkState = State.Benchmarks
        local runAll = benchmarkState.RunAll
        if not runAll or not runAll.waiting then
            return
        end

        runAll.waiting = false
        if runAll.module ~= benchmarkState.SelectedModule or runAll.index ~= benchmarkState.SelectedBenchmark then
            self:CancelRunAll()
            self:UpdateRunButtonState()
            return
        end
        benchmarkState.AutoRun = true
        StartBenchmark(runAll.module, runAll.index)
    end,

    ---@param self ProfilerBenchmarks
    OnClickLogButton = function(self)
        local benchmarkState = State.Benchmarks
        local stats, baselines = GetBenchmarkStatCache()
        if not stats then
            WARN("No benchmark data to log")
            return
        end

        local summary = Summarize(stats, baselines, self.summary:GetMode())
        local parameters
        local count = benchmarkState.ParameterCount
        if count and count > 0 then
            parameters = {}
            local values = GetBenchmarkParameters(benchmarkState.SelectedModule)
            for i = 1, count do
                parameters[i] = tostring(values[i])
            end
        end
        local baseline
        if baselines and baselines[1] ~= nil then
            baseline = Summarize(baselines, nil, "none")
        end
        local name = GetBenchmarkName(benchmarkState.SelectedModule, benchmarkState.SelectedBenchmark)
        LogLines(ProfilerReport.FormatSummary(WithMultiplier(name, benchmarkState.LoopMultiplier), summary, parameters, baseline))
    end,

    ---@param self ProfilerBenchmarks
    OnClickLogAllButton = function(self)
        if not self:LogModule(State.Benchmarks.SelectedModule) then
            WARN("No benchmark data to log")
        end
    end,

    ---@param self ProfilerBenchmarks
    LogModules = function(self)
        local logged = false
        for moduleIndex = 1, table.getn(State.Benchmarks.Modules) do
            logged = self:LogModule(moduleIndex) or logged
        end
        if not logged then
            WARN("No benchmark data to log")
        end
    end,

    --- Logs a table of the module's benchmarks, if any of them have data
    ---@param self ProfilerBenchmarks
    ---@param moduleIndex number
    ---@return boolean logged
    LogModule = function(self, moduleIndex)
        local benchmarkState = State.Benchmarks
        local module = benchmarkState.Modules and benchmarkState.Modules[moduleIndex]
        if not module or module.faulty then
            return false
        end

        local mode = self.summary:GetMode()
        -- rows grouped by multiplier, so higher multipliers come after the base loop count
        local groups = {}
        for i in LoopMultipliers do
            groups[i] = {}
        end
        -- baselines by multiplier, and by parameter count since that picks the baseline loop
        ---@type { params: number, multiplier: number, samples: { [integer]: number, n: integer } }[]
        local pools = {}
        local hasData = false
        for benchmarkIndex = 1, table.getn(module.benchmarks) do
            local name = GetBenchmarkName(moduleIndex, benchmarkIndex)
            local ran = false
            -- a row for each multiplier that has samples
            for multiplierIndex, multiplier in ipairs(LoopMultipliers) do
                local stats, baselines = GetBenchmarkStatCache(moduleIndex, benchmarkIndex, multiplier)
                if stats then
                    ran = true
                    local params = benchmarkState.ParameterCountCache[GetBenchmarkCacheKey(moduleIndex, benchmarkIndex, multiplier)]
                    table.insert(groups[multiplierIndex], {
                        name = WithMultiplier(name, multiplier),
                        summary = Summarize(stats, baselines, mode),
                        params = params,
                    })
                    if params and baselines and baselines[1] ~= nil then
                        local pool
                        for _, candidate in ipairs(pools) do
                            if candidate.params == params and candidate.multiplier == multiplier then
                                pool = candidate
                            end
                        end
                        if not pool then
                            pool = {params = params, multiplier = multiplier, samples = {n = 0}}
                            table.insert(pools, pool)
                        end
                        local samples = pool.samples
                        for i = 1, baselines.n do
                            samples.n = samples.n + 1
                            samples[samples.n] = baselines[i]
                        end
                    end
                end
            end
            -- benchmarks that haven't been run get a blank row
            if ran then
                hasData = true
            else
                table.insert(groups[1], {name = name})
            end
        end
        if not hasData then
            return false
        end
        local rows = {}
        for _, group in ipairs(groups) do
            for _, row in ipairs(group) do
                table.insert(rows, row)
            end
        end

        table.sort(pools, function(a, b)
            if a.multiplier ~= b.multiplier then
                return a.multiplier < b.multiplier
            end
            return a.params < b.params
        end)
        local baselineRows = {}
        for _, pool in ipairs(pools) do
            local params = pool.params
            table.insert(baselineRows, {
                name = WithMultiplier(("Baseline, %d parameter%s"):format(params, params == 1 and "" or "s"), pool.multiplier),
                summary = Summarize(pool.samples, nil, "none"),
                params = params,
            })
        end

        LOG(('Benchmark statistics for "%s", loop count %d')
            :format(module.name ~= "" and module.name or module.file, module.loopCount))
        LogLines(ProfilerReport.FormatTable(rows, baselineRows))
        return true
    end,

    ---@param self ProfilerBenchmarks
    ---@param index number
    SelectModule = function(self, index)
        local module = State.Benchmarks.Modules[index]
        self:PopulateBenchmarkList(module)
        self:UpdateBenchmarkDetails(module)
    end,

    ---@param self ProfilerBenchmarks
    ---@param index number
    SelectBenchmark = function(self, index)
        local benchmarkState = State.Benchmarks
        -- leaving a running benchmark stops it so its results don't end up on this page
        if benchmarkState.BenchmarkRunning and
            (benchmarkState.SelectedModule ~= benchmarkState.BenchmarkRunningMod or index ~= benchmarkState.BenchmarkRunningBen) then
            benchmarkState.AutoRun = false
            self:CancelRunAll()
            StopBenchmark()
        end
        benchmarkState.SelectedBenchmark = index
        -- the previous benchmark's, until this one's info arrives
        benchmarkState.ParameterCount = nil

        self.benchmarkList:SetSelection(index - 1) -- to zero-index list
        if index > 0 then
            self.benchmarkList:ShowItem(index - 1)
        end
        self:UpdateParametersLabel()
        self:UpdateBenchmarkStats()
        self:UpdateRunButtonState()
        self:HideBenchmarkStats()
        LoadBenchmark(State.Benchmarks.SelectedModule, index)
        if index ~= 0 then
            self:UpdateBenchmarkInfo(LOC("<LOC profiler_0012>waiting for benchmark data..."))
        else
            self:UpdateBenchmarkInfo()
        end
    end,

    ---@param self ProfilerBenchmarks
    ---@param modules UserBenchmarkModule
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

        local modulePicker = self.modulePicker
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
    end,

    ---@param self ProfilerBenchmarks
    ---@param moduleData UserBenchmarkModule
    PopulateBenchmarkList = function(self, moduleData)
        local benchmarkList = self.benchmarkList
        benchmarkList:DeleteAllItems()
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
        end
    end,

    ---@param self ProfilerBenchmarks
    HideBenchmarkStats = function(self)
        self.summary:SetStats()
    end,

    ---@param self ProfilerBenchmarks
    ---@param data number[]
    ---@param baselines? number[]
    AddBenchmarkStats = function(self, data, baselines)
        if not data then
            return
        end
        if not baselines then
            baselines = {}
        end
        data.n = table.getn(data)
        baselines.n = table.getn(baselines)

        local benchmarkState = State.Benchmarks
        local mod = benchmarkState.BenchmarkRunningMod
        local ben = benchmarkState.BenchmarkRunningBen
        local stats, cachedBaselines = AddBenchmarkStatCache(data, baselines, mod, ben)
        if mod == benchmarkState.SelectedModule and ben == benchmarkState.SelectedBenchmark then
            ---@diagnostic disable-next-line: param-type-mismatch
            self.summary:SetStats(stats, cachedBaselines)
        end
    end,

    ---@param self ProfilerBenchmarks
    ---@param info RawFunctionDebugInfo | string | nil
    UpdateBenchmarkInfo = function(self, info)
        local bytecodeArea = self.bytecode
        if type(info) == "table" then
            info = DebugFunction(info)
        end
        bytecodeArea:SetFunction(info --[[@as string?]])
        self:UpdateParametersLabel()
        self:UpdateBenchmarkStats()
        self:UpdateRunButtonState()
    end,

    ---@param self ProfilerBenchmarks
    ---@param moduleData UserBenchmarkModule
    UpdateBenchmarkDetails = function(self, moduleData)
        local n = moduleData.faulty and "<LOC lobui_0458>Unknown" or table.getn(moduleData.benchmarks)
        self.benchmarkText:SetText(LOCF("<LOC profiler_0011>Benchmarks in module: %s", n))
    end,

    ---@param self ProfilerBenchmarks
    UpdateParametersLabel = function(self)
        local benchmarkState = State.Benchmarks
        local params = benchmarkState.ParameterCount
        if not params then
            self.parametersLabel:Hide()
        else
            local label = self.parametersLabel
            label:Hide()
            label:DeleteAllItems()
            if params > 0 then
                local paramFormatter = LOC("<LOC profiler_0008>Parameter %d: %s") --[[@as LocalizedString]]
                local parameters = GetBenchmarkParameters(benchmarkState.SelectedModule)
                for i = 1, params do
                    label:AddItem(paramFormatter:format(i, tostring(parameters[i])))
                end
            end
            label:Show()
        end
    end,

    ---@param self ProfilerBenchmarks
    UpdateBenchmarkStats = function(self)
        ---@diagnostic disable-next-line: param-type-mismatch
        self.summary:SetStats(GetBenchmarkStatCache())
    end,

    ---@param self ProfilerBenchmarks
    UpdateRunButtonState = function(self)
        local benchmarkState = State.Benchmarks
        local running = benchmarkState.BenchmarkRunning
        local disabled = benchmarkState.SelectedBenchmark == 0 or not (running or benchmarkState.ParameterCount)
        self:SetRunButtonState(disabled, running)
        self:UpdateTimerWarning()
    end,

    --- Shows the timer resolution when it is too coarse for the selected benchmark's samples
    ---@param self ProfilerBenchmarks
    UpdateTimerWarning = function(self)
        local current = State.Benchmarks.LoopMultiplier
        local multiplier, resolution = self:GetNeededMultiplier(nil, nil, current)
        if multiplier then
            if multiplier > current then
                self.timerWarning:SetText(LOCF("<LOC profiler_0061>Timer resolution: %.3f ms, use x%d", resolution * 1000, multiplier))
            else
                self.timerWarning:SetText(LOCF("<LOC profiler_0066>Timer resolution: %.3f ms, restart the game", resolution * 1000))
            end
            self.timerWarning:Show()
        else
            self.timerWarning:Hide()
        end
    end,

    ---@param self ProfilerBenchmarks
    UpdateBenchmarkProgress = function(self)
        local benchmarkState = State.Benchmarks
        local prog = benchmarkState.BenchmarkProgress
        local runs = benchmarkState.BenchmarkRuns
        self:SetBenchmarkProgress(prog, runs)
    end,

    ---@param self ProfilerBenchmarks
    ---@param disabled? boolean
    ---@param running? boolean
    SetRunButtonState = function(self, disabled, running)
        -- while running all, only its own button can stop it
        local runAll = State.Benchmarks.RunAll
        local runButton = self.runButton
        if disabled or runAll then
            runButton:Disable()
        else
            runButton:Enable()
        end
        if running then
            runButton.label:SetText(LOC("<LOC profiler_0010>Stop"))
        else
            runButton.label:SetText(LOC("<LOC profiler_0006>Run"))
        end

        local autoRunButton = self.autoRunButton
        local autoRunning = running and State.Benchmarks.AutoRun and not runAll
        if disabled or runAll or (running and not autoRunning) then
            autoRunButton:Disable()
        else
            autoRunButton:Enable()
        end
        if autoRunning then
            autoRunButton.label:SetText(LOC("<LOC profiler_0010>Stop"))
        else
            autoRunButton.label:SetText(LOC("<LOC profiler_0043>Run to 5%"))
        end

        -- running all doesn't need a selected benchmark, just a usable module
        local modules = State.Benchmarks.Modules
        local module = modules and modules[State.Benchmarks.SelectedModule]
        local canRunAll = module and not module.faulty and table.getn(module.benchmarks) > 0
        local canRunModules = modules and self:FindNextModule(0) ~= nil

        -- only the button that started a run can stop it
        local runAllButton = self.runAllButton
        local runningAll = runAll and not runAll.allModules
        if runningAll or (canRunAll and not running and not runAll) then
            runAllButton:Enable()
        else
            runAllButton:Disable()
        end
        runAllButton.label:SetText(runningAll and LOC("<LOC profiler_0010>Stop") or LOC("<LOC profiler_0052>Module to 5%"))

        local runModulesButton = self.runModulesButton
        local runningModules = runAll and runAll.allModules
        if runningModules or (canRunModules and not running and not runAll) then
            runModulesButton:Enable()
        else
            runModulesButton:Disable()
        end
        runModulesButton.label:SetText(runningModules and LOC("<LOC profiler_0010>Stop") or LOC("<LOC profiler_0055>All to 5%"))

        if GetBenchmarkStatCache() then
            self.logButton:Enable()
        else
            self.logButton:Disable()
        end

        if canRunAll and ModuleHasData(State.Benchmarks.SelectedModule) then
            self.logAllButton:Enable()
        else
            self.logAllButton:Disable()
        end

        local anyHasData = false
        for moduleIndex = 1, modules and table.getn(modules) or 0 do
            if ModuleHasData(moduleIndex) then
                anyHasData = true
                break
            end
        end
        if anyHasData then
            self.logModulesButton:Enable()
        else
            self.logModulesButton:Disable()
        end

        -- clearing or switching samples mid-run would pull them out from under it
        local clearButton = self.summary.clearButton
        if running or runAll then
            clearButton:Disable()
            self.loopMultiplier:Disable()
        else
            clearButton:Enable()
            self.loopMultiplier:Enable()
        end
    end,

    ---@param self ProfilerBenchmarks
    ---@param prog number
    ---@param runs number
    SetBenchmarkProgress = function(self, prog, runs)
        local progressLabel = self.progressLabel
        if prog < runs then
            progressLabel:Show()
            progressLabel:SetText(LOC("<LOC profiler_0009>%d / %d"):format(prog, runs))
        else
            progressLabel:Hide()
        end
    end,
}

---@class ProfilerOptions : Group
ProfilerOptions = Class(Group) {
    ---@param self ProfilerOptions
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
    end
}

--#endregion

---@class ProfilerWindow : Window
---@field Tabs {Overview: ProfilerOverview, Timers: ProfilerTimers, Stamps: ProfilerStamps, Benchmarks: ProfilerBenchmarks, Options: ProfilerOptions}
---@field Headers {[1]: "Overview", [2]: "Timers", [3]: "Stamps", [4]: "Benchmarks", [5]: "Options"}
ProfilerWindow = ClassUI(Window) {
    ---@param self ProfilerWindow
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, LOC("<LOC profiler_0000>Profiler"),
            false, false, false, true, false, "profiler2", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 810,
        })
        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, "/scx_menu/lan-game-lobby/frame/")

        self:InitHeaders()
        self:InitTabs()

        -- allows us to act on changes
        BenchmarkModulesReceived:AddObserver(function(modules)
            self:ReceiveBenchmarkModules(modules)
        end)
        BenchmarkInfoReceived:AddObserver(function(info)
            self:ReceiveBenchmarkInfo(info)
        end)
        BenchmarkOutputReceived:AddObserver(function(output)
            self:ReceiveBenchmarkOutput(output)
        end)
        BenchmarkModuleSelected:AddObserver(function(index)
            self:ReceiveModuleSelected(index)
        end)
        BenchmarkSelected:AddObserver(function(index)
            self:ReceiveBenchmarkSelected(index)
        end)

        self:Layout()
    end,

    ---@param self ProfilerWindow
    InitHeaders = function(self)
        local clientGroup = self.ClientGroup
        local header = Group(clientGroup)
        clientGroup.header = header

        self.Headers = {}
        self:InitHeaderButton(header, "Overview", "<LOC profiler_0001>Overview")
        self:InitHeaderButton(header, "Timers", "<LOC profiler_0002>Timers")
        self:InitHeaderButton(header, "Stamps", "<LOC profiler_0003>Stamps")
        self:InitHeaderButton(header, "Benchmarks", "<LOC profiler_0004>Benchmarks")
        self:InitHeaderButton(header, "Options", "<LOC profiler_0005>Options")
    end,

    ---@param self ProfilerWindow
    InitTabs = function(self)
        local clientGroup = self.ClientGroup
        local tabGroup = Group(clientGroup)
        clientGroup.tabGroup = tabGroup

        self.Tabs = {}
        self:InitOverviewTab(tabGroup)
        --self:InitTimersTab(tabGroup)
        --self:InitStampsTab(tabGroup)
        self:InitBenchmarksTab(tabGroup)
        --self:InitOptionsTab(tabGroup)
    end,

    ---@param self ProfilerWindow
    ---@param parent Group
    ---@param name string
    ---@param text UnlocalizedString
    InitHeaderButton = function(self, parent, name, text)
        local button = UIUtil.CreateButtonStd(parent, "/widgets02/small", LOC(text), 16, 2)
        button.Tab = name

        table.insert(self.Headers, name)
        parent[name] = button

        button.OnClick = function(button_self)
            SwitchHeader(button_self.Tab)
        end
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitOverviewTab = function(self, tabs)
        self.Tabs.Overview = ProfilerOverview(tabs)
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitTimersTab = function(self, tabs)
        self.Tabs.Timers = ProfilerTimers(tabs)
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitStampsTab = function(self, tabs)
        self.Tabs.Stamps = ProfilerStamps(tabs)
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitBenchmarksTab = function(self, tabs)
        self.Tabs.Benchmarks = ProfilerBenchmarks(tabs)
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitOptionsTab = function(self, tabs)
        self.Tabs.Options = ProfilerOptions(tabs)
    end,

    Layout = function(self)
        local clientGroup = self.ClientGroup
        local tabs = self.Tabs

        local header = Layouter(clientGroup.header)
            :AtLeftIn(clientGroup)
            :AtRightIn(clientGroup)
            :AtTopIn(clientGroup)
            :HeightFromTexture(UIUtil.UIFile("/widgets02/small_btn_up.dds"), 8)
            :End()

        local pos = 0.010
        for _, name in self.Headers do
            local button = header[name]
            Layouter(button)
                :AtTopIn(header, 4)
                :FromLeftIn(header, pos)
                :Over(header, 10)
                :End()
            if not tabs[button.Tab] then
                button:Disable()
            end
            pos = pos + 0.2
        end

        -- tabs

        local tabGroup = Layouter(clientGroup.tabGroup)
            :AtLeftIn(clientGroup)
            :AtRightIn(clientGroup)
            :AtBottomIn(clientGroup)
            :AnchorToBottom(clientGroup.header)
            :End()

        for _, tab in tabs do
            Layouter(tab)
                :Fill(tabGroup)
                :End()
        end
    end,

    ---@param self ProfilerWindow
    OnClose = function(self)
        CloseWindow()
    end,

    ---@param self ProfilerWindow
    ---@param index number
    ReceiveModuleSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        benchmarkState.SelectedModule = index
        self.Tabs.Benchmarks:UpdateBenchmarkDetails(moduleData)
        BenchmarkSelected:Set(moduleData.LastBenchmarkSelected)
    end,

    ---@param self ProfilerWindow
    ---@param index number
    ReceiveBenchmarkSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[benchmarkState.SelectedModule]
        benchmarkState.SelectedBenchmark = index
        moduleData.LastBenchmarkSelected = index
    end,

    ---@param self ProfilerWindow
    ---@param modules Module[]
    ReceiveBenchmarkModules = function(self, modules)
        State.Benchmarks.Modules = modules
        self.Tabs.Benchmarks:PopulateModulePicker(modules)
        BenchmarkModuleSelected:Set(1)
    end,

    ---@param self ProfilerWindow
    ---@param info RawFunctionDebugInfo
    ReceiveBenchmarkInfo = function(self, info)
        local benchmarkState = State.Benchmarks
        -- the info of a benchmark that was selected before can still arrive
        local module = benchmarkState.Modules[benchmarkState.SelectedModule]
        local benchmark = module and module.benchmarks[benchmarkState.SelectedBenchmark]
        if not benchmark or benchmark.name ~= info.info.name then
            return
        end
        benchmarkState.ParameterCount = info.bytecode.numparams
        self.Tabs.Benchmarks:UpdateBenchmarkInfo(info)
        self.Tabs.Benchmarks:OnBenchmarkInfoReady()
    end,

    ---@param self ProfilerWindow
    ---@param output BenchmarkOutput
    ReceiveBenchmarkOutput = function(self, output)
        local benchmarksTab = self.Tabs.Benchmarks
        local benchmarkState = State.Benchmarks

        benchmarkState.BenchmarkRunning = output.success == nil
        local complete = 0
        if output.data then
            complete = table.getn(output.data)
        end
        if output.runs then
            benchmarkState.BenchmarkRuns = output.runs
            benchmarkState.BenchmarkProgress = complete
        else
            benchmarkState.BenchmarkProgress = benchmarkState.BenchmarkProgress + complete
        end
        benchmarksTab:AddBenchmarkStats(output.data, output.baselines)
        -- an auto run warns about the timer itself once it stops repeating
        local autoRun = benchmarkState.AutoRun
        benchmarksTab:ContinueAutoRun(output)
        if output.success ~= nil and not autoRun then
            benchmarksTab:WarnCoarseTimer(benchmarkState.BenchmarkRunningMod, benchmarkState.BenchmarkRunningBen)
            local runAll = benchmarkState.RunAll
            if runAll and runAll.stopping then
                benchmarksTab:CancelRunAll()
            end
        end
        benchmarksTab:UpdateBenchmarkProgress()
        benchmarksTab:UpdateRunButtonState()
    end,
}

--- Opens up the window
function OpenWindow()
    if not CanUseProfiler() then
        WARN("Unable to open Profiler window")
        return
    end

    local State = State

    -- make hotkey act as a toggle
    if State.WindowIsOpen then
        CloseWindow()
        return
    end
    SPEW("Opening profiler window")

    State.WindowIsOpen = true
    -- populate the GUI
    local localGUI = GUI
    if localGUI then
        localGUI:Show()
        SwitchHeader(State.Header)
    else
        GUI = ProfilerWindow(GetFrame(0))
        SwitchHeader(State.Header)
        -- retrieve benchmarks
        SimCallback({
            Func = "FindBenchmarks",
            Args = {},
        })
        -- toggle the profiler
        SimCallback({
            Func = "ToggleProfiler",
            Args = {
                ForceEnable = true,
            },
        })
    end
end
