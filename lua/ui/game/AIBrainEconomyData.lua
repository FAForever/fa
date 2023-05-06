local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class AIBrainEconomyDataUI : Window
---@field Energy Text
---@field EnergyIncome Text
---@field EnergyRequestedIncome Text
---@field EnergyEfficiencyOverTime Text
---@field EnergyTrendOverTime Text
---@field Mass Text
---@field MassIncome Text
---@field MassRequested Text
---@field MassEfficiencyOverTime Text
---@field MassTrendyOverTime Text
---@field EconomyData AIBrainEconomyOverTimeData[]
AIBrainEconomyDataUI = ClassUI(Window) {

    ---@param self AIBrainEconomyDataUI
    ---@param parent Control
    __init = function(self, parent)
        Window.__init(self, parent, "AIBrain Economy Data", false, false, false, true, false, "AIBrainEconomyData1", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 525
        })

        self.EconomyData = { }

        self.Energy = UIUtil.CreateText(self, 'Energy', 14)
        self.EnergyIncome = UIUtil.CreateText(self, 'Income: ...', 12)
        self.EnergyRequestedIncome = UIUtil.CreateText(self, 'Requested: ...', 12)
        self.EnergyEfficiencyOverTime = UIUtil.CreateText(self, 'Efficiency: ...', 12)
        self.EnergyTrendOverTime = UIUtil.CreateText(self, 'Trend: ...', 12)

        self.Mass = UIUtil.CreateText(self, 'Mass', 14)
        self.MassIncome = UIUtil.CreateText(self, 'Income: ...', 12)
        self.MassRequested = UIUtil.CreateText(self, 'Requested: ...', 12)
        self.MassEfficiencyOverTime = UIUtil.CreateText(self, 'Efficiency: ...', 12)
        self.MassTrendyOverTime = UIUtil.CreateText(self, 'Trend: ...', 12)

        AddOnSyncHashedCallback(
            function(data)
                if data.EconomyData then
                    self.EconomyData = data.EconomyData
                    if Root then
                        Root:Update()
                    end
                end

            end, 'AIBrainData', 'AIBrainEconomyDataUI'
        )

        AddOnSyncHashedCallback(
            function(data)
                if Root then
                    self:Update()
                end
            end, 'FocusArmyChanged', 'AIBrainEconomyDataUI'
        )
    end,

    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self.Energy)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 34)
            :End()

        LayoutHelpers.LayoutFor(self.EnergyIncome)
            :Over(self, 5)
            :Below(self.Energy, 4)
            :End()

        LayoutHelpers.LayoutFor(self.EnergyRequestedIncome)
            :Over(self, 5)
            :Below(self.EnergyIncome, 2)
            :End()

        LayoutHelpers.LayoutFor(self.EnergyEfficiencyOverTime)
            :Over(self, 5)
            :Below(self.EnergyRequestedIncome, 2)
            :End()

        LayoutHelpers.LayoutFor(self.EnergyTrendOverTime)
            :Over(self, 5)
            :Below(self.EnergyEfficiencyOverTime, 2)
            :End()

        LayoutHelpers.LayoutFor(self.Mass)
            :Over(self, 5)
            :Below(self.EnergyTrendOverTime, 4)
            :End()

        LayoutHelpers.LayoutFor(self.MassIncome)
            :Over(self, 5)
            :Below(self.Mass, 2)
            :End()

        LayoutHelpers.LayoutFor(self.MassRequested)
            :Over(self, 5)
            :Below(self.MassIncome, 2)
            :End()

        LayoutHelpers.LayoutFor(self.MassEfficiencyOverTime)
            :Over(self, 5)
            :Below(self.MassRequested, 2)
            :End()

        LayoutHelpers.LayoutFor(self.MassTrendyOverTime)
            :Over(self, 5)
            :Below(self.MassEfficiencyOverTime, 2)
            :End()

        LayoutHelpers.LayoutFor(self)
            :AtBottomIn(self.MassTrendyOverTime, -14)
            :End()
    end,

    ---@param self AIBrainEconomyDataUI
    Update = function(self)
        local focusArmy = GetFocusArmy()
        local data = self.EconomyData[focusArmy]
        if data then
            self.EnergyIncome:SetText(string.format('Income: %.2f', data.EnergyIncome))
            self.EnergyRequestedIncome:SetText(string.format('Requested: %.2f', data.EnergyRequested))
            self.EnergyEfficiencyOverTime:SetText(string.format('Efficiency: %.2f', data.EnergyEfficiencyOverTime))
            self.EnergyTrendOverTime:SetText(string.format('Trend: %.2f', data.EnergyTrendOverTime))
            self.MassIncome:SetText(string.format('Income: %.2f', data.MassIncome))
            self.MassRequested:SetText(string.format('Requested: %.2f', data.MassRequested))
            self.MassEfficiencyOverTime:SetText(string.format('Efficiency: %.2f', data.MassEfficiencyOverTime))
            self.MassTrendyOverTime:SetText(string.format('Trend: %.2f', data.MassTrendOverTime))
        else
            self.EnergyIncome:SetText(string.format('Income: (no data)'))
            self.EnergyRequestedIncome:SetText(string.format('Requested: (no data)'))
            self.EnergyEfficiencyOverTime:SetText(string.format('Efficiency: (no data)'))
            self.EnergyTrendOverTime:SetText(string.format('Trend: (no data)'))
            self.MassIncome:SetText(string.format('Income: (no data)'))
            self.MassRequested:SetText(string.format('Requested: (no data)'))
            self.MassEfficiencyOverTime:SetText(string.format('Efficiency: (no data)'))
            self.MassTrendyOverTime:SetText(string.format('Trend: (no data)'))
        end
    end,

    OnClose = function(self)
        SimCallback({
            Func = 'GridReclaimDebugDisable',
            Args = {}
        }, false)

        self:Hide()
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = AIBrainEconomyDataUI(GetFrame(0))
        Root:Show()
    end

    SimCallback({
        Func = 'AIBrainEconomyDebugEnable',
        Args = {}
    }, false)
end

function CloseWindow()
    if Root then
        Root:Hide()

        SimCallback({
            Func = 'AIBrainEconomyDebugDisable',
            Args = {}
        }, false)
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Root then
        Root:Destroy()
        Root = false
    end
end
