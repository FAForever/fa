-- Note to modders:
-- if you feel the need to extend the capabilities of this file, please make a pull request to
-- https://github.com/FAForever/fa/blob/deploy/fafdevelop/lua/ui/game/Profiler.lua
-- so that the contribution is available to everyone

---@alias ProfilerTab "Overview" | "Timers" | "Stamps" | "Benchmarks" | "Options"

local GameMain = import('/lua/ui/game/gamemain.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Observable = import("/lua/shared/observable.lua")
local ProfilerElements = import("/lua/ui/game/ProfilerElements.lua")
local ProfilerUtilities = import("/lua/ui/game/ProfilerUtilities.lua")
local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Combo = import('/lua/ui/controls/combo.lua').Combo
local DebugFunction = import("/lua/shared/DebugFunction.lua").DebugFunction
local Edit = import('/lua/maui/edit.lua').Edit
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Window = import('/lua/maui/window.lua').Window

local CreateEmptyProfilerTable = import("/lua/shared/Profiler.lua").CreateEmptyProfilerTable
local Layouter = LayoutHelpers.ReusedLayoutFor
local PlayerIsDev = import("/lua/shared/Profiler.lua").PlayerIsDev


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
        BenchmarkRuns = 0,
        ---@type UserBenchmarkModule[]
        Modules = false,
        Parameters = {10000, 45},
        SelectedBenchmark = 0,
        SelectedModule = 1,
        ---@type table<string, number[]>
        StatCache = {},
    },
    Options = {},
}

local BenchmarkModuleSelected = Observable.Create()
local BenchmarkSelected = Observable.Create()
local BenchmarkProgressReceived = Observable.Create()
local BenchmarkModulesReceived = Observable.Create()
local BenchmarkInfoReceived = Observable.Create()
local BenchmarkOutputReceived = Observable.Create()


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
    local list = GUI.Tabs.Overview.List
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

---@param data {samples?: number, data?: number[], success: boolean}
function ReceiveBenchmarkOutput(data)
    SPEW("Received benchmark output")
    BenchmarkOutputReceived:Set(data)
end

---@param data {complete: number, runs?: number}
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
            ForceEnable = false,
        }
    })
end

-- note: this function can be hooked by UI mods to access the window, but the sim still
-- locks the player out

---@param player Army | AIBrain | string
---@return boolean
local function CanUseProfiler(player)
    return
        GameMain.GameHasAIs or
        sessionInfo.Options.CheatsEnabled == "true" or
        SessionIsReplay() or
        PlayerIsDev(player)
end


--- Opens up the window
function OpenWindow()
    local originalFocusArmy = GameMain.OriginalFocusArmy
    if not CanUseProfiler(originalFocusArmy) then
        WARN("Unable to open Profiler window: no AIs or no cheats")
        return
    end
    import("/lua/debug/DevUtils.lua").SpewMissingLoc({
        "/lua/ui/game/Profiler.lua",
        "/lua/ui/game/ProfilerElements.lua",
        "/lua/sim/Profiler.lua",
        "/lua/shared/Profiler.lua",
    })

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
    return tostring(modIndex) .. "," .. tostring(benIndex)
end

---@param modIndex? number
---@param benIndex? number
---@return number[] | nil
local function GetBenchmarkStatCache(modIndex, benIndex)
    return State.Benchmarks.StatCache[GetBenchmarkCacheKey(modIndex, benIndex)]
end

---@param data number[] | nil
---@param modIndex? number
---@param benIndex? number
local function SetBenchmarkStatCache(data, modIndex, benIndex)
    State.Benchmarks.StatCache[GetBenchmarkCacheKey(modIndex, benIndex)] = data
end

---@param data number[] | nil
---@param modIndex? number
---@param benIndex? number
---@return number[] | nil
local function AddBenchmarkStatCache(data, modIndex, benIndex)
    local key = GetBenchmarkCacheKey(modIndex, benIndex)
    local statCaches = State.Benchmarks.StatCache
    local cache = statCaches[key]
    if not cache then
        if data then
            local n = data.n
            cache = {n = n}
            for i = 1, n do
                cache[i] = data[i]
            end
            statCaches[key] = cache
        end
    elseif data then
        local n = data.n
        local offset = cache.n
        for i = 1, n do
            cache[offset + i] = data[i]
        end
        data.n = offset + n
    else
        statCaches[key] = nil
        return nil
    end
    return cache
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
    SPEW("STARTING")
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
ProfilerWindow = Class(Window) {
    ---@param self ProfilerWindow
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, LOC("<LOC profiler_{auto}>Profiler"), false, false, false, true, false, "profiler2", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 810
        })
        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')

        self:InitHeaders()
        self:InitTabs()
    end,

    ---@param self ProfilerWindow
    InitHeaders = function(self)
        local clientGroup = self.ClientGroup
        local _, height = GetTextureDimensions(UIUtil.UIFile('/widgets02/small_btn_up.dds'))
        local header = Layouter(Group(clientGroup))
            :AtLeftIn(clientGroup)
            :AtRightIn(clientGroup)
            :AtTopIn(clientGroup)
            :Height(height + 8)
            :End()
        clientGroup.Header = header

        self:InitHeaderButton(header, "Overview", "<LOC profiler_{auto}>Overview", 0.0)
        self:InitHeaderButton(header, "Timers", "<LOC profiler_{auto}>Timers", 0.2):Disable()
        self:InitHeaderButton(header, "Stamps", "<LOC profiler_{auto}>Stamps", 0.4):Disable()
        self:InitHeaderButton(header, "Benchmarks", "<LOC profiler_{auto}>Benchmarks", 0.6)
        self:InitHeaderButton(header, "Options", "<LOC profiler_{auto}>Options", 0.8):Disable()
    end,

    ---@param self ProfilerWindow
    ---@param parent Group
    ---@param name string
    ---@param text string
    ---@param pos number
    ---@return Button
    InitHeaderButton = function(self, parent, name, text, pos)
        local button = Layouter(UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC(text), 16, 2))
            :AtTopIn(parent, 4)
            :FromLeftIn(parent, pos + 0.010)
            :Over(self, 10)
            :End()
        button.OnClick = function()
            SwitchHeader(name)
        end
        parent[name] = button
        return button
    end,

    ---@param self ProfilerWindow
    InitTabs = function(self)
        local clientGroup = self.ClientGroup
        local tabGroup = Layouter(Group(clientGroup))
            :AtLeftIn(clientGroup)
            :AtRightIn(clientGroup)
            :AtBottomIn(clientGroup)
            :AnchorToBottom(clientGroup.Header)
            :End()
        self.Tabs = {}

        self:InitOverviewTab(tabGroup)
        --self:InitTimersTab(tabGroup)
        --self:InitStampsTab(tabGroup)
        self:InitBenchmarksTab(tabGroup)
        --self:InitOptionsTab(tabGroup)
    end;

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitOverviewTab = function(self, tabs)
        self.Tabs.Overview = ProfilerOverview(tabs)
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitTimersTab = function(self, tabs)
        self.Tabs.Timers = ProfilerTimers(tabs)
    end;

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitStampsTab = function(self, tabs)
        self.Tabs.Stamps = ProfilerStamps(tabs)
    end;

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitBenchmarksTab = function(self, tabs)
        self.Tabs.Benchmarks = ProfilerBenchmarks(tabs)

        -- allows us to act on changes
        BenchmarkModulesReceived:AddObserver(function(modules)
            self:ReceiveBenchmarkModules(modules)
        end)
        BenchmarkInfoReceived:AddObserver(function(info)
            self:ReceiveBenchmarkInfo(info)
        end)
        BenchmarkProgressReceived:AddObserver(function(progress)
            self:ReceiveBenchmarkProgress(progress)
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
    end,

    ---@param self ProfilerWindow
    ---@param tabs Group
    InitOptionsTab = function(self, tabs)
        self.Tabs.Options = ProfilerOptions(tabs)
    end;


    ---@param self ProfilerWindow
    OnClose = function(self)
        CloseWindow()
    end;

    ---@param self ProfilerWindow
    ---@param index number
    ReceiveModuleSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        benchmarkState.SelectedModule = index
        self.Tabs.Benchmarks:UpdateBenchmarkDetails(moduleData)
        BenchmarkSelected:Set(moduleData.LastBenchmarkSelected)
    end;

    ---@param self ProfilerWindow
    ---@param index number
    ReceiveBenchmarkSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[benchmarkState.SelectedModule]
        benchmarkState.SelectedBenchmark = index
        moduleData.LastBenchmarkSelected = index
    end;

    ---@param self ProfilerWindow
    ---@param modules Module
    ReceiveBenchmarkModules = function(self, modules)
        State.Benchmarks.Modules = modules
        self.Tabs.Benchmarks:PopulateModulePicker(modules)
        BenchmarkModuleSelected:Set(1)
    end;

    ---@param self ProfilerWindow
    ---@param progress table
    ReceiveBenchmarkProgress = function(self, progress)
        local benchmarkState = State.Benchmarks
        local benchmarksTab = self.Tabs.Benchmarks
        if progress.runs then
            benchmarkState.BenchmarkRuns = progress.runs
            benchmarksTab:UpdateRunButtonState()
            benchmarkState.BenchmarkProgress = progress.complete
        else
            benchmarkState.BenchmarkProgress = benchmarkState.BenchmarkProgress + progress.complete
        end
        benchmarksTab:UpdateBenchmarkProgress()
    end;

    ---@param self ProfilerWindow
    ---@param info RawFunctionDebugInfo
    ReceiveBenchmarkInfo = function(self, info)
        local benchmarkState = State.Benchmarks
        benchmarkState.ParameterCount = info.bytecode.numparams
        self.Tabs.Benchmarks:UpdateBenchmarkInfo(info)
    end;

    ---@param self ProfilerWindow
    ---@param output Module
    ReceiveBenchmarkOutput = function(self, output)
        State.Benchmarks.BenchmarkRunning = false
        local benchmarksTab = self.Tabs.Benchmarks
        benchmarksTab:AddBenchmarkStats(output)
        benchmarksTab:UpdateBenchmarkProgress()
        benchmarksTab:UpdateRunButtonState()
    end;
}


----------
-- Tabs
----------

---@param searchbar Group
---@param tab string
---@return Button
---@return Edit
local function CreateSearchBar(searchbar, tab)
    local text = Layouter(UIUtil.CreateText(searchbar, LOC("<LOC profiler_{auto}>Search"), 18, UIUtil.bodyFont, true))
        :AtLeftTopIn(searchbar)
        :End()

    local clearButton = Layouter(UIUtil.CreateButtonStd(searchbar, '/widgets02/small', LOC("<LOC profiler_{auto}>Clear"), 14, 2))
        :AtVerticalCenterIn(text)
        :AtRightIn(searchbar)
        :Over(searchbar, 10)
        :End()

    local edit = Edit(searchbar); Layouter(edit)
        :CenteredRightOf(text, 6)
        :AnchorToLeft(clearButton, 6)
        :Over(searchbar, 10)
        :Height(function()
            return edit:GetFontHeight()
        end)
        :End()

    UIUtil.SetupEditStd(edit,
        UIUtil.fontColor,      -- foreground color
        "ff060606",          -- background color
        UIUtil.highlightColor, -- highlight foreground color
        "880085EF",          -- highlight background color
        UIUtil.bodyFont,       -- font
        14, -- size
        30  -- maximum characters
    )

    edit.OnTextChanged = function(edit_self, new, old)
        State[tab].Search = new
        GUI.Tabs[tab].List:ScrollLines(false, 0)
    end
    clearButton.OnClick = function()
        edit:ClearText()
        State[tab].Search = false
    end

    searchbar.Height:Set(clearButton.Height())
    return clearButton, edit
end

---@param sortbar Group
---@param tab string
local function CreateSortBar(sortbar, tab)
    local buttonName = Layouter(UIUtil.CreateButtonStd(sortbar, '/widgets02/small', LOC("<LOC profiler_{auto}>Name"), 16, 2))
        :FromLeftIn(sortbar, 0.010)
        :FromTopIn(sortbar)
        :Over(sortbar, 10)
        :End()

    local buttonCount = Layouter(UIUtil.CreateButtonStd(sortbar, '/widgets02/small', LOC("<LOC profiler_{auto}>Count"), 16, 2))
        :FromLeftIn(sortbar, 0.620)
        :FromTopIn(sortbar)
        :Over(sortbar, 10)
        :End()

    local buttonGrowth = Layouter(UIUtil.CreateButtonStd(sortbar, '/widgets02/small', LOC("<LOC profiler_{auto}>Growth"), 16, 2))
        :FromLeftIn(sortbar, 0.810)
        :FromTopIn(sortbar)
        :Over(sortbar, 10)
        :End()

    buttonName.SortOn = "name"
    buttonCount.SortOn = "value"
    buttonGrowth.SortOn = "growth"

    local function onClick(self)
        State[tab].SortOn = self.SortOn
    end
    buttonName.OnClick = onClick
    buttonCount.OnClick = onClick
    buttonGrowth.OnClick = onClick
end


---@class ProfilerOverview : Group
---@field List ProfilerScrollArea
ProfilerOverview = Class(Group) {
    ---@param self ProfilerOverview
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)

        -- search bar

        local searchBar = Layouter(Group(self))
            :AtLeftTopIn(parent, 10, 10)
            :AtRightIn(parent, 10)
            :Height(10) -- placeholder
            :End()

        CreateSearchBar(searchBar, "Overview")

        -- Sorting options

        local sortGroup = Layouter(Group(self))
        -- better to set height for control
            :AnchorToBottom(searchBar, 10)
            :Height(30)
            :Left(self.Left)
            :Right(self.Right)
            :End()

        CreateSortBar(sortGroup, "Overview")

        -- list of functions
        -- make as a class
        local area = Layouter(ProfilerElements.ProfilerScrollArea(self))
            :AnchorToBottom(sortGroup, 8)
            :AtBottomIn(self, 2)
            :AtLeftIn(self, 2)
            :AtRightIn(self, 2 + 14)
            :End()
        area:InitScrollableContent()
        -- dirty hack :)
        SPEW(" applied dirty hack")
        self.List = area
    end;
}

---@class ProfilerTimers : Group
ProfilerTimers = Class(Group) {
    ---@param self ProfilerTimers
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)
    end
}

---@class ProfilerStamps : Group
ProfilerStamps = Class(Group) {
    ---@param self ProfilerStamps
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)
    end
}

---@class ProfilerBenchmarks : Group
---@field BenchmarksLabel Text
---@field BenchmarkList ItemList
---@field Bytecode BytecodeArea
---@field ModulePicker Combo
---@field ParametersLabel ItemList
---@field ProgressLabel Text
---@field RunButton Button
---@field Summary StatisticSummary
ProfilerBenchmarks = Class(Group) {
    ---@param self ProfilerBenchmarks
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)

        -- split up UI
        local horzSplit = 0.45

        -- Breakdown tab into groups

        local groupInput, groupOutput = UIUtil.CreateHorzSplitGroups(self, horzSplit, 1)

        local groupInteraction = Layouter(Group(groupInput))
            :FillFixedBorder(groupInput, 5)
            :Height(10) -- placeholder until we can set it to depend on the run button height
            :ResetTop()
            :End()

        local groupNavigation = Layouter(Group(groupInput))
            :Fill(groupInput)
            :AnchorToTop(groupInteraction, 5)
            :End()

        -- Interaction components

        local runButton = Layouter(UIUtil.CreateButtonStd(groupInteraction, '/widgets02/small', LOC("<LOC profiler_{auto}>Run"), 16, 2))
            :AtCenterIn(groupInteraction)
            :Over(groupInteraction, 10)
            :End()
        runButton:Disable()
        self.RunButton = runButton

        local parametersLabel = ItemList(groupInteraction, 0, 0); Layouter(parametersLabel)
            :AtLeftIn(groupInteraction)
            :AnchorToLeft(runButton)
            :AtVerticalCenterIn(groupInteraction)
            :ResetWidth()
            :Height(function()
                return (1 + parametersLabel:GetItemCount()) * parametersLabel:GetRowHeight() + 10
            end)
            :End()
        parametersLabel:SetFont(UIUtil.bodyFont, 10)
        parametersLabel:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
        self.ParametersLabel = parametersLabel

        local progressLabel = Layouter(UIUtil.CreateText(groupInteraction, "", 10, UIUtil.bodyFont, true))
            :CenteredRightOf(runButton)
            :End()
        self.ProgressLabel = progressLabel


        -- Navigation components

        local fileText = Layouter(UIUtil.CreateText(groupNavigation, LOC("<LOC profiler_{auto}>Benchmark Modules"), 16, UIUtil.bodyFont, true))
            :AtLeftTopIn(groupNavigation, 10, 10)
            :End()

        local modulePicker = Layouter(Combo(groupNavigation, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :Below(fileText, 10)
            :AtLeftIn(groupNavigation, 10)
            :AtRightIn(groupNavigation, 10)
            :Over(groupNavigation, 10)
            :End()
        self.ModulePicker = modulePicker

        -- should immediately update, so no need to set label
        local benchmarkText = Layouter(UIUtil.CreateText(groupNavigation, "", 16, UIUtil.bodyFont, true))
            :Below(modulePicker, 8)
            :AtLeftIn(groupNavigation, 10)
            :End()
        self.BenchmarksLabel = benchmarkText

        local benchmarkList = Layouter(ItemList(groupNavigation))
            :OffsetIn(groupNavigation, 10, 5, 10 + 14) -- leave space for scrollbar
            :AnchorToBottom(benchmarkText, 10)
            :Over(groupNavigation, 10)
            :End()
        benchmarkList:SetFont(UIUtil.bodyFont, 14)
        benchmarkList:SetColors(UIUtil.fontColor, "00000000", "000000", UIUtil.highlightColor, "bcfffe")
        benchmarkList:ShowMouseoverItem(true)
        UIUtil.CreateLobbyVertScrollbar(benchmarkList, 0, 0, 0)
        self.BenchmarkList = benchmarkList

        -- Output

        local summary = ProfilerElements.StatisticSummary(groupOutput)
        self.Summary = summary

        local bytecode = ProfilerElements.BytecodeArea(groupOutput)
        bytecode.Top:Set(summary.Bottom)
        self.Bytecode = bytecode


        -- layout 'editing'
        groupInteraction.Height:Set(function() return runButton.Height() + 10 end)


        -- background
        -- don't let it hide with the group it's under
        Layouter(Bitmap(groupInput))
            :FillFixedBorder(benchmarkList)
            :Under(benchmarkList, 5)
            :Color("7f000000")
            :End()


        runButton.OnClick = function(button_self)
            self:OnClickRunButton()
        end
        modulePicker.OnClick = function(picker_self, index, text)
            -- index is already 1-indexed for Combo boxes
            if index == State.Benchmarks.SelectedModule then
                return
            end
            BenchmarkModuleSelected:Set(index)
        end
        benchmarkList.OnClick = function(list_self, rawIndex, text)
            local index = rawIndex + 1 -- make 1-indexed
            if index == State.Benchmarks.SelectedBenchmark then
                return
            end
            ItemList.OnClick(list_self, rawIndex)
            BenchmarkSelected:Set(index)
        end
        local hook = summary.OnClickClearSummary
        summary.OnClickClearSummary = function()
            hook()
            SetBenchmarkStatCache(nil)
        end;

        BenchmarkModuleSelected:AddObserver(function(index)
            self:SelectModule(index)
        end)
        BenchmarkSelected:AddObserver(function(index)
            self:SelectBenchmark(index)
        end)
    end;

    ---@param self ProfilerBenchmarks
    OnFocus = function(self)
        -- rehide components
        self:UpdateBenchmarkStats()
        self.ProgressLabel:Hide()
    end;

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
    end;

    ---@param self ProfilerBenchmarks
    ---@param index number
    SelectModule = function(self, index)
        local module = State.Benchmarks.Modules[index]
        self:PopulateBenchmarkList(module)
        self:UpdateBenchmarkDetails(module)
    end;

    ---@param self ProfilerBenchmarks
    ---@param index number
    SelectBenchmark = function(self, index)
        self.BenchmarkList:SetSelection(index - 1) -- to zero-index list
        self:UpdateParametersLabel()
        self:UpdateBenchmarkStats()
        self:UpdateRunButtonState()
        LoadBenchmark(State.Benchmarks.SelectedModule, index)
        if index ~= 0 then
            self:UpdateBenchmarkInfo(LOC("<LOC profiler_{auto}>waiting for benchmark data..."))
        else
            self:UpdateBenchmarkInfo()
        end
    end;

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

        local modulePicker = self.ModulePicker
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

    ---@param self ProfilerBenchmarks
    ---@param moduleData UserBenchmarkModule
    PopulateBenchmarkList = function(self, moduleData)
        local benchmarkList = self.BenchmarkList
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
    end;

    ---@param self ProfilerBenchmarks
    ---@param data table
    AddBenchmarkStats = function(self, data)
        if data.success then
            local toAdd = data.data
            toAdd.n = data.samples
            local stats = AddBenchmarkStatCache(toAdd)
            self.Summary:SetStats(stats)
            SPEW(stats.n)
        end
    end;

    ---@param self ProfilerBenchmarks
    ---@param info RawFunctionDebugInfo | nil
    UpdateBenchmarkInfo = function(self, info)
        local bytecodeArea = self.Bytecode
        if type(info) == "table" then
            info = DebugFunction(info)
        end
        bytecodeArea:SetFunction(info)
        self:UpdateParametersLabel()
        self:UpdateBenchmarkStats()
        self:UpdateRunButtonState()
    end;

    ---@param self ProfilerBenchmarks
    ---@param moduleData UserBenchmarkModule
    UpdateBenchmarkDetails = function(self, moduleData)
        local n = moduleData.faulty and "<LOC lobui_0458>Unknown" or table.getn(moduleData.benchmarks)
        self.BenchmarksLabel:SetText(LOCF("<LOC profiler_{auto}>Benchmarks in module: %s", n))
    end;

    ---@param self ProfilerBenchmarks
    UpdateParametersLabel = function(self)
        local benchmarkState = State.Benchmarks
        local params = benchmarkState.ParameterCount
        if params then
            local label = self.ParametersLabel
            label:Hide()
            label:DeleteAllItems()
            if params > 0 then
                local paramFormatter = LOC("<LOC profiler_{auto}>Parameter %d: %s")
                local parameters = benchmarkState.Parameters
                for i = 1, params do
                    label:AddItem(paramFormatter:format(i, tostring(parameters[i])))
                end
            end
            label:Show()
        end
    end;

    ---@param self ProfilerBenchmarks
    UpdateBenchmarkStats = function(self)
        self.Summary:SetStats(GetBenchmarkStatCache())
    end;

    ---@param self ProfilerBenchmarks
    UpdateRunButtonState = function(self)
        local benchmarkState = State.Benchmarks
        local disabled = benchmarkState.SelectedBenchmark == 0
        local running = benchmarkState.BenchmarkRunning
        self:SetRunButtonState(disabled, running)
    end;

    ---@param self ProfilerBenchmarks
    UpdateBenchmarkProgress = function(self)
        local benchmarkState = State.Benchmarks
        local prog = benchmarkState.BenchmarkProgress
        local runs = benchmarkState.BenchmarkRuns
        self:SetBenchmarkProgress(prog, runs)
    end;

    ---@param self ProfilerBenchmarks
    ---@param disabled? boolean
    ---@param running? boolean
    SetRunButtonState = function(self, disabled, running)
        local runButton = self.RunButton
        if disabled then
            runButton:Disable()
        else
            runButton:Enable()
        end
        if running then
            runButton.label:SetText(LOC("<LOC profiler_{auto}>Stop"))
        else
            runButton.label:SetText(LOC("<LOC profiler_{auto}>Run"))
        end
    end;

    ---@param self ProfilerBenchmarks
    ---@param prog number
    ---@param runs number
    SetBenchmarkProgress = function(self, prog, runs)
        local progressLabel = self.ProgressLabel
        if prog < runs then
            progressLabel:Show()
            progressLabel:SetText(LOC("<LOC profiler_{auto}>%d / %d"):format(prog, runs))
        else
            progressLabel:Hide()
        end
    end;
}

---@class ProfilerOptions : Group
ProfilerOptions = Class(Group) {
    ---@param self ProfilerOptions
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)
    end
}