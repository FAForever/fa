local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Statistics = import("/lua/shared/statistics.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Layouter = LayoutHelpers.ReusedLayoutFor
--local ScrollPolicy = import("/lua/maui/scrollbar.lua").ScrollPolicy


---@class ProfilerElementRow : Group
---@field name Text
---@field source Text
---@field scope Text
---@field value Text
---@field growth Text
---@field is_group boolean
ProfilerElementRow = Class(Group) {
    ---@param self ProfilerElementRow
    ---@param parent Control
    ---@param size number
    ---@param font LazyVarString
    __init = function(self, parent, size, font)
        Group.__init(self, parent)

        self.name = UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Function"), size, font, false)
        self.source = UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Source"), size, font, false)
        self.scope = UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Scope"), size, font, false)
        self.value = UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Value"), size, font, false)
        self.growth = UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Growth"), size, font, false)
    end;

    ---@param self ProfilerElementRow
    Layout = function(self)
        Layouter(self.name)
            :AtLeftTopIn(self, 10, 0)
            :End()

        Layouter(self.source)
            :FromLeftIn(self, 0.45)
            :AtTopIn(self, 0)
            :End()

        Layouter(self.scope)
            :FromLeftIn(self, 0.60)
            :AtTopIn(self, 0)
            :End()

        Layouter(self.value)
            :FromLeftIn(self, 0.75)
            :AtTopIn(self, 0)
            :End()

        Layouter(self.growth)
            :FromLeftIn(self, 0.9)
            :AtTopIn(self, 0)
            :End()
        return self
    end;

    ---@param self ProfilerElementRow
    ---@param color Color
    SetColor = function(self, color)
        self.name:SetColor(color)
        self.source:SetColor(color)
        self.scope:SetColor(color)
        self.value:SetColor(color)
        self.growth:SetColor(color)
    end;
}

---@param control ProfilerElementRow
local function SetToHighlightColor(control)
    if not control.is_group then
        control:SetColor("FFFF00")
    end
end
---@param control ProfilerElementRow
local function SetToBodyColor(control)
    if not control.is_group then
        control:SetColor(UIUtil.fontColor)
    end
end

---@param parent Group
---@return ProfilerElementRow
function CreateDefaultElement(parent)
    local row = ProfilerElementRow(parent, 14, UIUtil.bodyFont)
    row.is_group = true
    row.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:ApplyFunction(SetToHighlightColor)
            return true
        elseif event.Type == 'MouseExit' then
            self:ApplyFunction(SetToBodyColor)
            return true
        end
    end
    return row
end

---@param parent Group
---@return ProfilerElementRow
function CreateTitle(parent)
    local title = ProfilerElementRow(parent, 16, UIUtil.titleFont)
    title.SetColor("F1F382")
    return title
end

---@param element ProfilerElementRow
---@param entry ProfilerFunctionData
function PopulateDefaultElement(element, entry)
    element.name:SetText(entry.name)
    element.source:SetText(entry.source)
    element.scope:SetText(entry.scope)
    element.value:SetText(tostring(entry.value))
    element.growth:SetText(tostring(entry.growth))
end

---@param element ProfilerElementRow
function DepopulateDefaultElement(element)
    element.name:SetText("")
    element.source:SetText("")
    element.scope:SetText("")
    element.value:SetText("")
    element.growth:SetText("")
end

---@class ProfilerScrollArea : Group
---@field bg Bitmap
---@field title ProfilerElementRow
---@field rowCount number
---@field rows ProfilerElementRow[]
---@field _scrollable boolean
---
---@field ElementCount number
---@field Elements ProfilerData
---@field First number
ProfilerScrollArea = ClassUI(Group) {
    ---@param self ProfilerScrollArea
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        self.bg = Bitmap(self)
        self.title = CreateTitle(self)
        self.rows = {}
        self.rowCount = 0
        self._scrollable = false
        self.Elements = {}
        self.ElementCount = 0
        self.First = 0
    end,

    ---@param self ProfilerScrollArea
    Layout = function(self)
        local rows = self.rows
        for i = 1, self.rowCount do
            rows[i]:Destroy()
        end

        local previous = Layouter(self.title)
            :Height(20)
            :AtLeftIn(self)
            :AtTopIn(self)
            :AtRightIn(self)
            :End()

        -- make as many elements as will fit 
        local element = CreateDefaultElement(self)
        Layouter(element)
            :Height(20)
            :AtLeftIn(self)
            :AnchorToBottom(previous)
            :AtRightIn(self)
            :End()

        local n = math.floor((self.Height() - self.title.Height()) / element.Height())
        rows[1] = element
        for k = 2, n do
            rows[k] = CreateDefaultElement(self)
        end
        self.rowCount = n
        UIUtil.CreateLobbyVertScrollbar(self)

        Layouter(self.bg)
            :Fill(self)
            :Under(self)
            :Color("000000")
            :Alpha(0.5)
            :End()

        for i = 2, self.rowCount do
            previous = Layouter(rows[i])
                :Height(20)
                :AtLeftIn(self)
                :AnchorToBottom(previous)
                :AtRightIn(self)
                :End()
        end
        self._scrollable = true
    end,

    ---@param self ProfilerScrollArea
    ---@param elements ProfilerData
    ---@param count number
    ProvideElements = function(self, elements, count)
        self.Elements = elements
        self.ElementCount = count
    end,

    ---@return number rangeMin
    ---@return number rangeMax
    ---@return number visibleMin
    ---@return number visibleMax
    GetScrollValues = function(self)
        return 0, self.ElementCount,
            self.First, math.min(self.First + self.rowCount, self.ElementCount)
    end,

    --- Called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    ---@param self ProfilerScrollArea
    ---@param axis string
    ---@param delta number
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta))
    end,

    --- Called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    ---@param self ProfilerScrollArea
    ---@param axis string
    ---@param delta number
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta) * self.rowCount)
    end,

    --- called when the scrollbar wants to set a new visible top line
    ---@param self ProfilerScrollArea
    ---@param axis string
    ---@param top number
    ScrollSetTop = function(self, axis, top)
        -- compute where we end up
        local size = self.ElementCount
        local first = math.max(math.min(size - self.ElementCount, math.floor(top)), 0)

        -- check if it is different
        if first == self.First then
            return
        end

        -- if so, store it and compute what is visible
        self.First = first
        self:CalcVisible()
    end,

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    ---@param self ProfilerScrollArea
    ---@param axis string
    IsScrollable = function(self, axis)
        return self._scrollable
    end,

    ---@param self ProfilerScrollArea
    CalcVisible = function(self)
        for k = 1, self.rowCount do
            local index = k + self.First
            if index <= self.ElementCount then
                PopulateDefaultElement(self.rows[k], self.Elements[index])
            else
                DepopulateDefaultElement(self.rows[k])
            end
        end
    end,

    ---@param self ProfilerScrollArea
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' and self:IsScrollable() then
            if event.WheelRotation < 0 then
                self:ScrollLines(nil, 1)
            else
                self:ScrollLines(nil, -1)
            end
        end
    end,
}

---@class StatisticSummary : Group
---@field bg Bitmap
---@field clearButton Button
---@field deviation Text
---@field deviationLabel Text
---@field mean Text
---@field meanLabel Text
---@field samples Text
---@field samplesLabel Text
---@field skewness Text
---@field skewnessLabel Text
---@field summary Group
StatisticSummary = Class(Group) {
    ---@param self StatisticSummary
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        self.bg = Bitmap(self)

        local groupSummary = Group(self)
        self.summary = groupSummary

        -- Summary details
        self.summaryLabel = UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Summary"), 16, UIUtil.bodyFont, true)
        self.samplesLabel = UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Samples"), 14, UIUtil.bodyFont, true)
        self.meanLabel = UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Mean"), 14, UIUtil.bodyFont, true)
        self.deviationLabel = UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Deviation"), 14, UIUtil.bodyFont, true)
        self.skewnessLabel = UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Skewness"), 14, UIUtil.bodyFont, true)

        -- next column
        self.samples = UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true)
        self.mean = UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true)
        self.deviation = UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true)
        self.skewness = UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true)
        -- THIS MUST CHANGE IT'S AWFUL
        self.clearButton = UIUtil.CreateButtonStd(groupSummary, '/widgets02/small', "<LOC profiler_{auto}>Clear Stats", 12, 2)

        self.clearButton.OnClick = function()
            self.OnClickClearSummary(self)
        end
    end;

    Layout = function(self)
        local groupSummary = Layouter(self.summary)
            :FillFixedBorder(self, 5)
            :End()

        Layouter(self.bg)
            :FillFixedBorder(groupSummary)
            :Under(groupSummary, 5)
            :Color("7f000000")
            :End()
        -- Summary details

        local summaryLabel = Layouter(self.summaryLabel)
            :AtTopCenterIn(groupSummary, 5)
            :End()

        local samplesLabel = Layouter(self.samplesLabel)
            :Below(summaryLabel, 5)
            :AtLeftIn(groupSummary, 6)
            :End()

        local meanLabel = Layouter(self.meanLabel)
            :Below(samplesLabel, 3)
            :End()

        local deviationLabel = Layouter(self.deviationLabel)
            :Below(meanLabel, 3)
            :End()

        local skewnessLabel = Layouter(self.skewnessLabel)
            :Below(deviationLabel, 3)
            :End()

        local width = 10 + math.max(samplesLabel.Width(), meanLabel.Width(),
                deviationLabel.Width(), skewnessLabel.Width())

        -- next column

        Layouter(self.samples)
            :Top(samplesLabel.Top)
            :AtLeftIn(samplesLabel, width)
            :End()

        Layouter(self.mean)
            :Top(meanLabel.Top)
            :AtLeftIn(meanLabel, width)
            :End()

        Layouter(self.deviation)
            :Top(deviationLabel.Top)
            :AtLeftIn(deviationLabel, width)
            :End()

        Layouter(self.skewness)
            :Top(skewnessLabel.Top)
            :AtLeftIn(skewnessLabel, width)
            :End()

        -- THIS MUST CHANGE IT'S AWFUL
        local clearButton = Layouter(self.clearButton)
            :AtLeftTopIn(groupSummary)
            :End()
        Tooltip.AddButtonTooltip(clearButton, "pls replace me")
        self.ClearButton = clearButton

        LayoutHelpers.AtBottomIn(self, skewnessLabel, -10)
    end;

    ---@param self StatisticSummary
    OnClickClearSummary = function(self)
        SPEW("I should not be nil: " .. tostring(self))
        self:SetStats(nil)
    end;

    ---@param self StatisticSummary
    ---@param stats? number[]
    SetStats = function(self, stats)
        if stats then
            local n = stats.n
            local samples, mean, deviation, skewness = n, "0", "∞", "∞"

            ---[[ To be replaced when the statistics branch is merged
            if n > 0 then
                mean = Statistics.Mean(stats, n)
                if n > 1 then
                    -- from population variance to sample standard deviation
                    deviation = math.sqrt(Statistics.Deviation(stats, n, mean) * n / (n - 1))
                    if n > 2 then
                        if deviation > 0 then
                            skewness = 0
                            for i = 1, n do
                                local residual = (stats[i] - mean)
                                skewness = residual*residual*residual
                            end
                            skewness = skewness / deviation
                        else
                            skewness = "0"
                        end
                    end
                end
            end
            --]]

            --[[ Code for statistics merge
            local obj = Statistics.StatObject(stats, n)

            if n > 0 then
               mean = obj.mean
               if n > 1 then
                   deviation = obj.deviation
                   if n > 2 then
                       if deviation > 0 then
                           skewness = obj.skewness
                       else
                           skewness = "0"
                       end
                   end
               end
            end
            --]]

            self.samples:SetText(samples)
            self.mean:SetText(mean)
            self.deviation:SetText(deviation)
            self.skewness:SetText(skewness)
            self.summary:Show()
        else
            SPEW("HUDING")
            self.summary:Hide()
        end
    end;
}

---@class BytecodeArea : Group
---@field logButton Button
---@field bytecodeGroup Group
---@field details Group
---@field detailsBg Bitmap
---@field bytecode ItemList
---@field parameters Text
---@field upvalues Text
---@field constants Text
---@field maxStack Text
---@field Error? string
---@field DebugFunction? DebugFunction
BytecodeArea = Class(Group) {
    ---@param self BytecodeArea
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)

        local groupDetails = Group(self)
        local groupBytecode = Group(self)

        self.logButton = UIUtil.CreateButtonStd(self, "/BUTTON/log/")
        self.details = groupDetails
        self.groupBytecode = groupBytecode
        self.detailsBg = Bitmap(self) -- parent it to ourself so it still shows when the group is hidden
        self.parameters = UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true)
        self.maxStack = UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true)
        self.upvalues = UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true)
        self.constants = UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true)
        self.bytecode = ItemList(groupBytecode)

        self.logButton.OnClick = function(button_self)
            if self.DebugFunction then
                self:OnLog()
            end
        end
        self.bytecode.OnMouseoverItem = function(list_self, index)
            if self.DebugFunction then
                if index ~= -1 then
                    local tooltip = self:GetBytecodeTooltip(index)
                    if tooltip then
                        Tooltip.CreateMouseoverDisplay(list_self, tooltip)
                        return
                    end
                end
                Tooltip.DestroyMouseoverDisplay()
            end
        end
    end,

    Layout = function(self)
        local logButton = Layouter(self.logButton)
            :AtRightTopIn(self)
            :Over(self, 1)
            :End()
        Tooltip.AddButtonTooltip(logButton, "profiler_print_to_log")

        local groupDetails = Layouter(self.details)
            :AtLeftIn(self, 5)
            :LeftOf(logButton)
            :AtTopIn(logButton)
            :AtBottomIn(logButton)
            :End()

        local groupBytecode = Layouter(self.groupBytecode)
            :FillFixedBorder(self, 5)
            :AnchorToBottom(groupDetails)
            :End()

        Layouter(self.detailsBg)
            :Fill(groupDetails)
            :Under(groupDetails, 5)
            :Color("7f000000")
            :End()

        -- bytecode

        local parameters = Layouter(self.parameters)
            :AtLeftCenterIn(groupDetails, 10)
            :Over(groupDetails, 10)
            :End()

        local maxstack = Layouter(self.maxStack)
            :CenteredRightOf(parameters, 10)
            :Over(groupDetails, 10)
            :End()

        local upvalues = Layouter(self.upvalues)
            :CenteredRightOf(maxstack, 10)
            :Over(groupDetails, 10)
            :End()

        Layouter(self.constants)
            :CenteredRightOf(upvalues, 10)
            :Over(groupDetails, 10)
            :End()

        local bytecode = Layouter(self.bytecode)
            :Fill(groupBytecode)
            :Over(self, 10)
            :AtRightIn(groupBytecode, 14)
            :Font(UIUtil.fixedFont, 14)
            :End()

        ---[[
        UIUtil.CreateLobbyVertScrollbar(bytecode)
        --]]

        --[[ To be merged with scrollbar branch
        UIUtil.CreateLobbyScrollBars(bytecode, groupBytecode, ScrollPolicy.AsNeeded, ScrollPolicy.AsNeeded)
        --]]

        bytecode:ShowMouseoverItem(true)
    end;

    ---@param self BytecodeArea
    OnLog = function(self)
        local area = self.bytecode
        for i = 1, area:GetItemCount() do
            LOG(area:GetItem(i - 1)) -- list is 0-indexed
        end
        -- import("/lua/debug/UtilsDev.lua").SpewDebugFunction(self.benchmarkDebugFunction.func)
    end;

    ---@param self BytecodeArea
    ---@param index number
    GetBytecodeTooltip = function(self, index)
        local text = self.bytecode:GetItem(index)
        local jumpTooltipFormater = LOC("<LOC profiler_{auto}>Jump from %s")
        local jumpInd = text:find('>', nil, true)
        if jumpInd and jumpInd < 20 then
            -- pull the instruction address directly from the text
            local addr = text:gmatch("[1-9A-Fa-f]%x*")()
            if not addr then
                return
            end
            addr = tonumber(addr, 16) + 1
            local fn = self.DebugFunction
            local jumps = fn:ResolveJumps()[addr]
            local instructions = fn.instructions
            -- string together all jump-from locations
            local addrFrom = instructions[jumps[1] + 1]:AddressToString()
            local tooltip = jumpTooltipFormater:format(addrFrom)
            for i = 2, table.getn(jumps) do
                addrFrom = instructions[jumps[i] + 1]:AddressToString()
                tooltip = tooltip .. "; " .. jumpTooltipFormater:format(addrFrom)
            end
            return tooltip
        end
    end;

    ---@param self any
    ---@param data string | DebugFunction | nil
    SetFunction = function(self, data)
        local error = nil
        if type(data) == "string" then
            error = data
            data = nil
        end
        self.Error = error
        self.DebugFunction = data
        if data then
            self.logButton:Enable()
        else
            self.logButton:Disable()
        end
        self:UpdateDetails()
        self:UpdateBytecode()
    end;

    ---@param self BytecodeArea
    UpdateDetails = function(self)
        local fn = self.DebugFunction
        local details = self.details
        if fn then
            self.parameters:SetText(LOC("<LOC profiler_{auto}>Parameters: %d"):format(fn.numparams))
            self.maxStack:SetText(LOC("<LOC profiler_{auto}>Max Stack: %d"):format(fn.maxstack))
            self.upvalues:SetText(LOC("<LOC profiler_{auto}>Upvalues: %d"):format(fn.nups))
            self.constants:SetText(LOC("<LOC profiler_{auto}>Constants: %d"):format(fn.constantCount))
            details:Show()
        else
            details:Hide()
        end
    end;

    ---@param self BytecodeArea
    UpdateBytecode = function(self)
        local bytecode = self.bytecode
        bytecode:DeleteAllItems()
        local error = self.Error
        if error then
            bytecode:AddItem(error)
        else
            local fn = self.DebugFunction
            if fn then
                for _, line in ipairs(fn:PrettyPrint()) do
                    bytecode:AddItem(line)
                end
            end
        end
    end;
}