-- Note to modders:
-- if you feel the need to extend the capabilities of this file, please make a pull request to
-- https://github.com/FAForever/fa/blob/deploy/fafdevelop/lua/ui/game/Profiler.lua
-- so that the contribution is available to everyone

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
        Modules = false,
        Parameters = {10000, 45},
        SelectedBenchmark = 0,
        SelectedModule = 1,
        StatCache = {},
    },
    Options = {},
}

local BenchmarkModuleSelected = Observable.Create()
local BenchmarkSelected = Observable.Create()
local BenchmarkProgressReceived = Observable.Create()
local BenchmarkModulesReceived = Observable.Create()
local BenchmarkOutputReceived = Observable.Create()


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
            ForceEnable = false,
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



function SwitchHeader(target)
    local tabs = GUI.Tabs
    State.Header = target

    -- hide all tabs
    tabs:Hide()

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

function GetBenchmarkCacheKey(modIndex, benIndex)
    return tostring(modIndex) .. "," .. tostring(benIndex)
end


function StartBenchmark(module, benchmark)
    -- We asymetrically update the `benchmarkRunning` state to true on start, but wait for results
    -- from the sim on stop to set to false. This is so that we can't send benchmark requests
    -- to the sim while one is running.
    local benchmarkState = State.Benchmarks
    benchmarkState.BenchmarkRunning = true
    local params = State.Benchmarks.BenchmarkParameterCount
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
    GUI:UpdateRunButtonState()
end

function StopBenchmark()
    SimCallback({
        Func = "StopBenchmark",
        Args = {}
    })
end



---@class ProfilerWindow : Window
ProfilerWindow = Class(Window) {
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

        SwitchHeader(State.Header)
    end,

    InitHeaders = function(self)
        local titleGroup = self.TitleGroup
        self:InitHeaderButton(titleGroup, "Overview", "<LOC profiler_{auto}>Overview", 0.0)
        self:InitHeaderButton(titleGroup, "Timers", "<LOC profiler_{auto}>Timers", 0.2)
        self:InitHeaderButton(titleGroup, "Stamps", "<LOC profiler_{auto}>Stamps", 0.4)
        self:InitHeaderButton(titleGroup, "Benchmarks", "<LOC profiler_{auto}>Benchmarks", 0.6)
        self:InitHeaderButton(titleGroup, "Options", "<LOC profiler_{auto}>Options", 0.8)
    end,

    InitHeaderButton = function(self, parent, name, text, pos)
        local button = Layouter(UIUtil.CreateButtonStd(parent, '/widgets02/small', LOC(text), 16, 2))
            :Below(parent, 4)
            :FromLeftIn(parent, pos + 0.010)
            :Over(self, 10)
            :End()
        button.OnClick = function()
            SwitchHeader(name)
        end
        parent[name] = button
        return button
    end,

    InitTabs = function(self)
        local Tabs = Layouter(Group(self, "window content pane"))
            :Below(self.TitleGroup)
            :Right(self.Right)
            :Bottom(self.Bottom)
            :End()
        Tabs.Overview = self:CreateOverviewTab(Tabs)
        --Tabs.Timers = self:CreateTimersTab(Tabs)
        --Tabs.Stamps = self:CreateStampsTab(Tabs)
        Tabs.Benchmarks = self:CreateBenchmarksTab(Tabs)
        --Tabs.Options = self:CreateOptionsTab(Tabs)
        Tabs:Hide()
        self.Tabs = Tabs
    end;

    CreateOverviewTab = function(self, parent)
        local tab = Layouter(Group(parent, "overview tab"))
            :Fill(parent)
            :End()

        -- search bar

        local searchText = Layouter(UIUtil.CreateText(tab, LOC("<LOC profiler_{auto}>Search"), 18, UIUtil.bodyFont, true))
            :Under(tab)
            :AtLeftTopIn(tab, 10, 8)
            :End()

        local searchClearButton = Layouter(UIUtil.CreateButtonStd(tab, '/widgets02/small', LOC("<LOC profiler_{auto}>Clear"), 14, 2))
            :AtVerticalCenterIn(searchText)
            :AtRightIn(tab, 10)
            :Over(self, 10)
            :End()

        local searchEdit = Edit(tab); Layouter(searchEdit)
            :Under(tab)
            :CenteredRightOf(searchText, 10)
            :AnchorToLeft(searchClearButton, 10)
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

        -- Sorting options

        local sortGroup = Layouter(Group(tab))
        -- better to set height for control
            :AnchorToBottom(searchEdit, 13)
            :Height(LayoutHelpers.ScaleNumber(30))
            :Left(self.Left)
            :Right(self.Right)
            :End()

        local buttonName = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_{auto}>Name"), 16, 2))
            :FromLeftIn(sortGroup, 0.410)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        local buttonCount = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_{auto}>Count"), 16, 2))
            :FromLeftIn(sortGroup, 0.610)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        local buttonGrowth = Layouter(UIUtil.CreateButtonStd(sortGroup, '/widgets02/small', LOC("<LOC profiler_{auto}>Growth"), 16, 2))
            :FromLeftIn(sortGroup, 0.810)
            :FromTopIn(sortGroup, 0)
            :Over(self, 10)
            :End()

        -- list of functions
        -- make as a class
        -- ScrollArea
        local area = Layouter(ProfilerElements.ProfilerScrollArea(tab))
            :AnchorToBottom(sortGroup, 16)
            :AtBottomIn(self, 2)
            :Left(self.Left)
            :AtRightIn(self, 16)
            :End()
        area:InitScrollableContent()
        -- dirty hack :)
        SPEW(" applied dirty hack")
        self.List = area

        searchEdit.OnTextChanged = function(edit_self, new, old)
            State.Overview.Search = new
            GUI.Tabs.Overview.Controls.List:ScrollLines(false, 0)
        end
        searchClearButton.OnClick = function(edit_self)
            searchEdit:ClearText()
            State.Overview.Search = false
        end
        buttonName.OnClick = function(button_self)
            State.Overview.SortOn = "name"
        end
        buttonCount.OnClick = function(button_self)
            State.Overview.SortOn = "value"
        end
        buttonGrowth.OnClick = function(button_self)
            State.Overview.SortOn = "growth"
        end

        return tab
    end,

    CreateTimersTab = function(self, parent)
        local tab = Layouter(Group(parent, "timers tab"))
            :Fill(parent)
            :End()

        -- TODO

        return tab
    end;

    CreateStampsTab = function(self, parent)
        local tab = Layouter(Group(parent, "stamps tab"))
            :Fill(parent)
            :End()

        -- TODO

        return tab
    end;

    CreateBenchmarksTab = function(self, parent)
        local tab = ProfilerBenchmarks(parent)

        tab.OnFocus = function(self)
            self:UpdateBenchmarkStats() -- rehide the summary when the tab is shown
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
            self:ReceiveModuleSelected(index)
        end)
        BenchmarkSelected:AddObserver(function(index)
            self:ReceiveBenchmarkSelected(index)
        end)

        return tab
    end,

    CreateOptionsTab = function(self, parent)
        local tab = Layouter(Group(parent, "options tab"))
            :Fill(parent)
            :End()

        -- TODO

        return tab
    end;


    OnClose = function(self)
        CloseWindow()
    end;

    ReceiveModuleSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[index]
        benchmarkState.SelectedModule = index
        self.Tabs.Benchmarks:UpdateBenchmarkDetails(moduleData)
        BenchmarkSelected:Set(moduleData.LastBenchmarkSelected)
    end;

    ReceiveBenchmarkSelected = function(self, index)
        local benchmarkState = State.Benchmarks
        local moduleData = benchmarkState.Modules[benchmarkState.SelectedModule]
        benchmarkState.SelectedBenchmark = index
        moduleData.LastBenchmarkSelected = index
    end;

    ReceiveBenchmarkModules = function(self, modules)
        for _, module in modules do
            module.LastBenchmarkSelected = 0
            for _, benchmark in module do
                benchmark.info = DebugFunction(benchmark.info)
            end
        end
        State.Benchmarks.Modules = modules
        self.Tabs.Benchmarks:PopulateModulePicker(modules)
        BenchmarkModuleSelected:Set(1)
    end;

    ReceiveBenchmarkProgress = function(self, progress)
        local benchmarkState = State.Benchmarks
        if progress.runs then
            benchmarkState.BenchmarkRuns = progress.runs
            self:UpdateRunButtonState()
            benchmarkState.BenchmarkProgress = progress.complete
        else
            benchmarkState.BenchmarkProgress = benchmarkState.BenchmarkProgress + progress.complete
        end
        self:UpdateBenchmarkProgress()
    end;

    ReceiveBenchmarkOutput = function(self, output)
        State.Benchmarks.BenchmarkRunning = false
        self:AddBenchmarkStats(output)
        self:UpdateBenchmarkProgress()
        self:UpdateRunButtonState()
    end;
}


ProfilerBenchmarks = Class(Group) {
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

        local summary = Layouter(ProfilerElements.ProfilerSummary(groupOutput))
            :FillFixedBorder(groupOutput, 5)
            :End()
        self.Summary = summary

        local bytecode = ProfilerElements.ProfilerBytecodeArea(groupOutput)
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
            local benchmarkState = State.Benchmarks
            local mod = benchmarkState.SelectedModule
            local ben = benchmarkState.SelectedBenchmark
            local key = GetBenchmarkCacheKey(mod, ben)
            benchmarkState.StatCache[key] = nil
        end;

        BenchmarkModuleSelected:Add(function(index)
            self:SelectModule(index)
        end)
        BenchmarkSelected:Add(function(index)
            self:SelectBenchmark(index)
        end)
    end,

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

    SelectModule = function(self, index)
        self:PopulateBenchmarkList(index)
    end;

    SelectBenchmark = function(self, index)
        local benchmarkState = State.Benchmarks
        local benchmark = benchmarkState.Modules[benchmarkState.SelectedModule].Benchmarks[index]
        self.BenchmarkList:SetSelection(index - 1) -- to zero-index list
        self.Bytecode:SetBenchmark(benchmark.Info)
        self:UpdateParametersLabel()
        self:UpdateBenchmarkStats()
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

    AddBenchmarkStats = function(self, data)
        local benchmarkState = State.Benchmarks
        local key = GetBenchmarkCacheKey(benchmarkState.SelectedModule, benchmarkState.SelectedBenchmark)
        local benchmarkStatCache = benchmarkState.StatCache
        local cache = benchmarkStatCache[key]
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
            benchmarkStatCache[key] = cache
            for i = 1, n do
                cache[i] = data[i]
            end
        end
        self.Tabs.Benchmarks:SetBenchmarkStats(cache)
    end;

    UpdateBenchmarkDetails = function(self, moduleData)
        local num
        if moduleData.faulty then
            num = "<LOC lobui_0458>Unknown"
        else
            num = table.getn(moduleData.benchmarks)
        end
        self.BenchmarksLabel:SetText(LOCF("<LOC profiler_{auto}>Benchmarks in module: %s", num))
    end;

    UpdateParametersLabel = function(self)
        local benchmarkState = State.Benchmarks
        local params = State.Benchmarks.BenchmarkParameterCount
        if params then
            local label = self.ParametersLabel
            label:DeleteAllItems()
            if params > 0 then
                local paramFormater = LOC("<LOC profiler_{auto}>Parameter %d: %s")
                local parameters = benchmarkState.Parameters
                for i = 1, params do
                    label:AddItem(paramFormater:format(i, tostring(parameters[i])))
                end
            end
            label:Show()
            for i = 1, label:GetItemCount() do
                SPEW(label:GetItem(i - 1))
            end
        end
    end;

    UpdateBenchmarkStats = function(self)
        local benchmarkState = State.Benchmarks
        local key = GetBenchmarkCacheKey(benchmarkState.SelectedModule, benchmarkState.SelectedBenchmark)
        local cache = benchmarkState.StatCache[key]
        self.Tabs.Benchmarks:SetBenchmarkStats(cache)
    end;

    UpdateRunButtonState = function(self)
        local benchmarkState = State.Benchmarks
        local disabled = benchmarkState.SelectedBenchmark == 0
        local running = benchmarkState.BenchmarkRunning
        self.Tabs.Benchmarks:SetRunButtonState(disabled, running)
    end;

    UpdateBenchmarkProgress = function(self)
        local benchmarkState = State.Benchmarks
        local prog = benchmarkState.BenchmarkProgress
        local runs = benchmarkState.BenchmarkRuns
        self.Tabs.Benchmarks:SetBenchmarkProgress(prog, runs)
    end;

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