local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Statistics = import("/lua/shared/statistics.lua")
local Tooltip = import('/lua/ui/game/tooltip.lua')

local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Layouter = LayoutHelpers.ReusedLayoutFor
--local ScrollPolicy = import('/lua/maui/scrollbar.lua').ScrollPolicy

---@class ProfilerElementRow : Group
---@field name Text
---@field source Text
---@field scope Text
---@field value Text
---@field growth Text
---@field is_group boolean
ProfilerElementRow = Class(Group) {
    __init = function(self, parent, alignment, size, font, color)
        Group.__init(self, parent)

        if alignment then
            Layouter(self)
                :Left(parent.Left)
                :Right(parent.Right)
                :Top(alignment.Bottom)
                :Height(20)
                :End()
        else
            Layouter(self)
                :Left(parent.Left)
                :Right(parent.Right)
                :Top(parent.Top)
                :Height(20)
                :End()
        end

        self.name = Layouter(UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Function"), size, font, false))
            :AtLeftTopIn(self, 10, 0)
            :End()

        self.source = Layouter(UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Source"), size, font, false))
            :FromLeftIn(self, 0.45)
            :AtTopIn(self, 0)
            :End()

        self.scope = Layouter(UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Scope"), size, font, false))
            :FromLeftIn(self, 0.60)
            :AtTopIn(self, 0)
            :End()

        self.value = Layouter(UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Value"), size, font, false))
            :FromLeftIn(self, 0.75)
            :AtTopIn(self, 0)
            :End()

        self.growth = Layouter(UIUtil.CreateText(self, LOC("<LOC profiler_{auto}>Growth"), size, font, false))
            :FromLeftIn(self, 0.9)
            :AtTopIn(self, 0)
            :End()

        if color then
            self.name:SetColor(color)
            self.source:SetColor(color)
            self.scope:SetColor(color)
            self.value:SetColor(color)
            self.growth:SetColor(color)
        end
    end;
}

---@param control ProfilerElementRow
local function SetToHighlightColor(control)
    if not control.is_group then
        control:SetColor('ffff00')
    end
end
---@param control ProfilerElementRow
local function SetToBodyColor(control)
    if not control.is_group then
        control:SetColor(UIUtil.fontColor)
    end
end

---@param parent Group
---@param alignment? Control optional control to align to the bottom of
---@return ProfilerElementRow
function CreateDefaultElement(parent, alignment)
    local group = ProfilerElementRow(parent, alignment, 14, UIUtil.bodyFont)
    group.is_group = true
    group.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:ApplyFunction(SetToHighlightColor)
            return true
        elseif event.Type == 'MouseExit' then
            self:ApplyFunction(SetToBodyColor)
            return true
        end
    end
    return group
end

---@param parent Group
---@return ProfilerElementRow
function CreateTitle(parent)
    return ProfilerElementRow(parent, nil, 16, UIUtil.titleFont, 'F1F382')
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
---@field NumberOfUIElements number
---@field NumberOfElements number
---@field UIElements ProfilerElementRow[]
---@field Elements ProfilerData
---@field First number
---
---@field _scrollable boolean
ProfilerScrollArea = Class(Group) {
    ---@param self ProfilerScrollArea
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        self.bg = Bitmap(self); LayoutHelpers.ReusedLayoutFor(self.bg)
            :Under(parent)
            :Color("000000")
            :Fill(self)
            :Alpha(0.5)
            --:End() -- haven't laidout ourselves yet, so this will error
        self._scrollable = false
    end,

    ---@param self ProfilerScrollArea
    InitScrollableContent = function(self)
        local elements = {}

        -- compute size of an element
        local title = CreateTitle(self)
        local dummy = CreateDefaultElement(self, self)
        local height = dummy.Height()
        dummy:Destroy()
        local n = math.floor((self.Height() - title.Height()) / height)

        -- make list of elements

        local previous = title
        for k = 1, n do
            elements[k] = CreateDefaultElement(self, previous)
            previous = elements[k]
        end

        UIUtil.CreateLobbyVertScrollbar(self, -- calls functions on this
            0, -- offset right
            0, -- offset bottom
            0 -- offset top
        )

        -- populate it a bit
        self.UIElements = elements
        self.NumberOfUIElements = n
        self.Elements = {}
        self.NumberOfElements = 0
        self.First = 0
        self._scrollable = true
    end,

    ---@param self ProfilerScrollArea
    ---@param elements ProfilerData
    ---@param count number
    ProvideElements = function(self, elements, count)
        self.Elements = elements
        self.NumberOfElements = count
    end,

    ---@return number rangeMin
    ---@return number rangeMax
    ---@return number visibleMin
    ---@return number visibleMax
    GetScrollValues = function(self)
        return 0, self.NumberOfElements,
            self.First, math.min(self.First + self.NumberOfUIElements, self.NumberOfElements)
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
        self:ScrollSetTop(axis, self.First + math.floor(delta) * self.NumberOfUIElements)
    end,

    --- called when the scrollbar wants to set a new visible top line
    ---@param self ProfilerScrollArea
    ---@param axis string
    ---@param top number
    ScrollSetTop = function(self, axis, top)
        -- compute where we end up
        local size = self.NumberOfElements
        local first = math.max(math.min(size - self.NumberOfUIElements, math.floor(top)), 0)

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
        for k = 1, self.NumberOfUIElements do
            local index = k + self.First
            if index <= self.NumberOfElements then
                PopulateDefaultElement(self.UIElements[k], self.Elements[index])
            else
                DepopulateDefaultElement(self.UIElements[k])
            end
        end
    end,

    ---@param self ProfilerScrollArea
    ---@param event string
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
---@field ClearButton Button
---@field Deviation Text
---@field Mean Text
---@field Samples Text
---@field Skewness Text
---@field Summary Group
StatisticSummary = Class(Group) {
    ---@param self StatisticSummary
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)

        local groupSummary = Layouter(Group(self))
            :FillFixedBorder(self, 5)
            :End()
        self.Summary = groupSummary

        -- Summary details

        local summaryLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Summary"), 16, UIUtil.bodyFont, true))
            :AtTopCenterIn(groupSummary, 5)
            :End()

        local samplesLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Samples"), 14, UIUtil.bodyFont, true))
            :Below(summaryLabel, 5)
            :AtLeftIn(groupSummary, 6)
            :End()

        local meanLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Mean"), 14, UIUtil.bodyFont, true))
            :Below(samplesLabel, 3)
            :End()

        local deviationLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Deviation"), 14, UIUtil.bodyFont, true))
            :Below(meanLabel, 3)
            :End()

        local skewnessLabel = Layouter(UIUtil.CreateText(groupSummary, LOC("<LOC profiler_{auto}>Skewness"), 14, UIUtil.bodyFont, true))
            :Below(deviationLabel, 3)
            :End()

        local width = 10 + math.max(samplesLabel.Width(), meanLabel.Width(),
                deviationLabel.Width(), skewnessLabel.Width())

        -- next column

        local samples = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(samplesLabel.Top)
            :AtLeftIn(samplesLabel, width)
            :End()
        self.Samples = samples

        local mean = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(meanLabel.Top)
            :AtLeftIn(meanLabel, width)
            :End()
        self.Mean = mean

        local deviation = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(deviationLabel.Top)
            :AtLeftIn(deviationLabel, width)
            :End()
        self.Deviation = deviation

        local skewness = Layouter(UIUtil.CreateText(groupSummary, "", 14, UIUtil.bodyFont, true))
            :Top(skewnessLabel.Top)
            :AtLeftIn(skewnessLabel, width)
            :End()
        self.Skewness = skewness

        -- THIS MUST CHANGE IT'S AWFUL
        local clearButton = Layouter(UIUtil.CreateButtonStd(groupSummary, '/widgets02/small', "<LOC profiler_{auto}>Clear Stats", 12, 2))
            :AtLeftTopIn(groupSummary)
            :End()
        Tooltip.AddButtonTooltip(clearButton, "pls replace me")
        self.ClearButton = clearButton

        LayoutHelpers.AtBottomIn(self, skewnessLabel, -10)

        Layouter(Bitmap(parent))
            :FillFixedBorder(groupSummary)
            :Under(groupSummary, 5)
            :Color("7f000000")
            :End()

        clearButton.OnClick = function()
            self.OnClickClearSummary(self)
        end
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

            self.Samples:SetText(samples)
            self.Mean:SetText(mean)
            self.Deviation:SetText(deviation)
            self.Skewness:SetText(skewness)
            self.Summary:Show()
        else
            self.Summary:Hide()
        end
    end;
}

---@class BytecodeArea : Group
---@field Bytecode ItemList
---@field Details Group
---@field LogButton Button
---@field Parameters Text
---@field Upvalues Text
---@field Constants Text
---@field MaxStack Text
---@field Error? string
---@field DebugFunction? DebugFunction
BytecodeArea = Class(Group) {
    ---@param self BytecodeArea
    ---@param parent Group
    __init = function(self, parent)
        Group.__init(self, parent)
        LayoutHelpers.FillParent(self, parent)

        local groupDetails = Layouter(Group(self))
            :FillFixedBorder(self, 5) -- will edit to the log button height once we create that
            :End()
        self.Details = groupDetails

        local groupBytecode = Layouter(Group(self))
            :FillFixedBorder(self, 5)
            :AnchorToBottom(groupDetails)
            :End()

        -- bytecode

        local logButton = Layouter(UIUtil.CreateButtonStd(self, "/BUTTON/log/"))
            :AtRightTopIn(self)
            :Over(self, 1)
            :End()
        Tooltip.AddButtonTooltip(logButton, "profiler_print_to_log")
        self.LogButton = logButton

        local params = Layouter(UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true))
            :AtLeftCenterIn(groupDetails, 10)
            :Over(groupDetails, 10)
            :End()
        self.Parameters = params

        local maxstack = Layouter(UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(params, 10)
            :Over(groupDetails, 10)
            :End()
        self.MaxStack = maxstack

        local upvalues = Layouter(UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(maxstack, 10)
            :Over(groupDetails, 10)
            :End()
        self.Upvalues = upvalues

        local constants = Layouter(UIUtil.CreateText(groupDetails, "", 14, UIUtil.bodyFont, true))
            :CenteredRightOf(upvalues, 10)
            :Over(groupDetails, 10)
            :End()
        self.Constants = constants

        local bytecode = ItemList(self)

        ---[[
        UIUtil.CreateLobbyVertScrollbar(bytecode)
        Layouter(bytecode)
            :Fill(groupBytecode)
            :Over(self, 10)
            :AtRightIn(groupBytecode, 14)
            :End()
        --]]

        --[[ To be merged with scrollbar branch
        UIUtil.CreateLobbyScrollBars(bytecode, groupBytecode, ScrollPolicy.AsNeeded, ScrollPolicy.AsNeeded)
        --]]

        bytecode:ShowMouseoverItem(true)
        bytecode:SetFont(UIUtil.fixedFont, 14)
        self.Bytecode = bytecode


        -- layout 'editing'
        groupDetails.Right:Set(logButton.Left)
        groupDetails.Top:Set(logButton.Top)
        groupDetails.Bottom:Set(logButton.Bottom)

        Layouter(Bitmap(self))
            :Fill(groupDetails)
            :Under(groupDetails, 5)
            :Color("7f000000")
            :End()


        logButton.OnClick = function(button_self)
            if self.DebugFunction then
                self:OnLog()
            end
        end
        bytecode.OnMouseoverItem = function(list_self, index)
            if self.DebugFunction then
                if index ~= -1 then
                    local tooltip = self:GetBytecodeTooltip(index)
                    if tooltip then
                        Tooltip.CreateMouseoverDisplay(bytecode, tooltip)
                        return
                    end
                end
                Tooltip.DestroyMouseoverDisplay()
            end
        end
    end,

    ---@param self BytecodeArea
    OnLog = function(self)
        local area = self.Bytecode
        for i = 1, area:GetItemCount() do
            LOG(area:GetItem(i - 1)) -- list is 0-indexed
        end
        -- import("/lua/debug/UtilsDev.lua").SpewDebugFunction(self.benchmarkDebugFunction.func)
    end;

    ---@param self BytecodeArea
    ---@param index number
    GetBytecodeTooltip = function(self, index)
        local text = self.Bytecode:GetItem(index)
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
            self.LogButton:Enable()
        else
            self.LogButton:Disable()
        end
        self:UpdateDetails()
        self:UpdateBytecode()
    end;

    ---@param self BytecodeArea
    UpdateDetails = function(self)
        local fn = self.DebugFunction
        local details = self.Details
        if fn then
            self.Parameters:SetText(LOC("<LOC profiler_{auto}>Parameters: %d"):format(fn.numparams))
            self.MaxStack:SetText(LOC("<LOC profiler_{auto}>Max Stack: %d"):format(fn.maxstack))
            self.Upvalues:SetText(LOC("<LOC profiler_{auto}>Upvalues: %d"):format(fn.nups))
            self.Constants:SetText(LOC("<LOC profiler_{auto}>Constants: %d"):format(fn.constantCount))
            details:Show()
        else
            details:Hide()
        end
    end;

    ---@param self BytecodeArea
    UpdateBytecode = function(self)
        local bytecode = self.Bytecode
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