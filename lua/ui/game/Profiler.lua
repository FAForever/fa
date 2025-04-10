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
local Layouter = LayoutHelpers.ReusedLayoutFor



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
        BenchmarkProgress = 0,
        BenchmarkRunning = false,
        BenchmarkRunningMod = false,
        BenchmarkRunningBen = false,
        BenchmarkRuns = 0,
        ---@type UserBenchmarkModule[]
        Modules = false,
        Parameters = {10000, 45},
        SelectedBenchmark = 0,
        SelectedModule = 1,
        ---@type table<string, number[]>
        StatCache = {},
        ---@type table<string, number[]>
        BaselineCache = {},
    },
    Options = {},
}

local BenchmarkModuleSelected = ObservableCreate()
local BenchmarkSelected = ObservableCreate()
local BenchmarkModulesReceived = ObservableCreate()
local BenchmarkInfoReceived = ObservableCreate()
local BenchmarkOutputReceived = ObservableCreate()


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

--- Closes the window
function CloseWindow()
    SPEW("Closing profiler window")
    State.WindowIsOpen = false
    local GUI = GUI
    if GUI then
        GUI:Hide()
    end
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

local function GetBenchmarkCacheKey(modIndex, benIndex)
    local state = State.Benchmarks
    modIndex = modIndex or state.SelectedModule
    benIndex = benIndex or state.SelectedBenchmark
    return tostring(modIndex) .. ',' .. tostring(benIndex)
end

---@param modIndex? number
---@param benIndex? number
---@return number[] | nil
local function GetBenchmarkStatCache(modIndex, benIndex)
    local key = GetBenchmarkCacheKey(modIndex, benIndex)
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

---@param data number[] | nil
---@param baselines number[] | nil
---@param modIndex? number
---@param benIndex? number
---@return number[] | nil data
---@return number[] | nil baselines
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
    benchmarkState.BenchmarkRunning = true
    benchmarkState.BenchmarkRunningMod = benchmarkState.SelectedModule
    benchmarkState.BenchmarkRunningBen = benchmarkState.SelectedBenchmark
    local params = benchmarkState.ParameterCount
    if not params then
        WARN("Missing debug function to start benchmark")
        return
    end
    local parameters = {}
    local benchmarkParams = benchmarkState.Parameters
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
        benchmarkState.ParameterCount = info.bytecode.numparams
        self.Tabs.Benchmarks:UpdateBenchmarkInfo(info)
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
        benchmarksTab:UpdateBenchmarkProgress()
        benchmarksTab:UpdateRunButtonState()
    end,
}


----------
-- Tabs
----------

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
---@field benchmarkText Text
---@field benchmarkList ItemList
---@field bytecode BytecodeArea
---@field fileText Text
---@field groupInput Group
---@field groupInteraction Group
---@field groupNavigation Group
---@field groupOutput Group
---@field modulePicker Combo
---@field parametersLabel ItemList
---@field progressLabel Text
---@field runButton Button
---@field summary StatisticSummary
ProfilerBenchmarks = Class(Group) {
    ---@param self ProfilerBenchmarks
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)

        self.groupInput = Group(self)
        self.groupOutput = Group(self)
        self.groupInteraction = Group(self.groupInput)
        self.groupNavigation = Group(self.groupInput)
        self.runButton = UIUtil.CreateButtonStd(self.groupInteraction, "/widgets02/small", LOC("<LOC profiler_0006>Run"), 16, 2)
        self.parametersLabel = ItemList(self.groupInteraction, 0, 0)
        self.progressLabel = UIUtil.CreateText(self.groupInteraction, "", 10, UIUtil.bodyFont, true)
        self.fileText = UIUtil.CreateText(self.groupNavigation, LOC("<LOC profiler_0007>Benchmark Modules"), 16, UIUtil.bodyFont, true)
        self.modulePicker = Combo(self.groupNavigation, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
        self.benchmarkText = UIUtil.CreateText(self.groupNavigation, "", 16, UIUtil.bodyFont, true) -- should immediately update, so no need to set label
        self.benchmarkList = ItemList(self.groupNavigation)
        self.benchmarkList.background = Bitmap(self.benchmarkList)
        self.bytecode = ProfilerElements.BytecodeArea(self.groupOutput)
        self.summary = ProfilerElements.StatisticSummary(self.groupOutput)

        self.runButton.OnClick = function(button_self)
            self:OnClickRunButton()
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

        local groupNavigation = Layouter(self.groupNavigation)
            :Fill(groupInput)
            :AnchorToTop(groupInteraction, 5)
            :End()

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

        -- Navigation components

        local fileText = Layouter(self.fileText)
            :AtLeftTopIn(groupNavigation, 10, 10)
            :End()

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
                UIUtil.fontColor, "000000",
                UIUtil.highlightColor, "bcfffe"
            )
            :MouseoverItem(true)
            :End()
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

    ---@param self ProfilerBenchmarks
    OnClickRunButton = function(self)
        local benchmarkState = State.Benchmarks
        if benchmarkState.BenchmarkRunning then
            StopBenchmark()
            return
        end
        local module = benchmarkState.SelectedModule
        local benchmark = benchmarkState.SelectedBenchmark
        if module > 0 and benchmark > 0 then
            StartBenchmark(module, benchmark)
        end
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
        self.benchmarkList:SetSelection(index - 1) -- to zero-index list
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
        self.summary:SetStats(AddBenchmarkStatCache(data, baselines, mod, ben))
    end,

    ---@param self ProfilerBenchmarks
    ---@param info RawFunctionDebugInfo | string | nil
    UpdateBenchmarkInfo = function(self, info)
        local bytecodeArea = self.bytecode
        if type(info) == "table" then
            info = DebugFunction(info)
        end
        bytecodeArea:SetFunction(info)
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
        if params then
            local label = self.parametersLabel
            label:Hide()
            label:DeleteAllItems()
            if params > 0 then
                local paramFormatter = LOC("<LOC profiler_0008>Parameter %d: %s")
                local parameters = benchmarkState.Parameters
                for i = 1, params do
                    label:AddItem(paramFormatter:format(i, tostring(parameters[i])))
                end
            end
            label:Show()
        end
    end,

    ---@param self ProfilerBenchmarks
    UpdateBenchmarkStats = function(self)
        self.summary:SetStats(GetBenchmarkStatCache())
    end,

    ---@param self ProfilerBenchmarks
    UpdateRunButtonState = function(self)
        local benchmarkState = State.Benchmarks
        local disabled = benchmarkState.SelectedBenchmark == 0
        local running = benchmarkState.BenchmarkRunning
        self:SetRunButtonState(disabled, running)
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
        local runButton = self.runButton
        if disabled then
            runButton:Disable()
        else
            runButton:Enable()
        end
        if running then
            runButton.label:SetText(LOC("<LOC profiler_0010>Stop"))
        else
            runButton.label:SetText(LOC("<LOC profiler_0006>Run"))
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
