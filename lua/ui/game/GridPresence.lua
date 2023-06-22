local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class GridPresenceUIDebugCell
---@field Inferred 'Allied' | 'Hostile' | 'Contested' | 'Unoccupied'
---@field Label number

---@class GridPresenceUIDebugUpdate
---@field ResourcePointsTime number
---@field ResourcePointsTick number
---@field InferredTime number
---@field InferredTick number

---@class GridPresenceUICell : Group
---@field Title Text
---@field Inferred Text
---@field Label Text
GridPresenceUICell = ClassUI(Group) {

    ---@param self GridPresenceUICell
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'GridPresenceUICell')

        self.Title = UIUtil.CreateText(self, 'Scanning information', 14)
        self.Inferred = UIUtil.CreateText(self, 'Inferred status: ...', 12)
        self.Label = UIUtil.CreateText(self, 'Of label: ...', 12)

        AddOnSyncHashedCallback(
        ---@param data GridPresenceUIDebugCell
            function(data)
                if Root then
                    self.Inferred:SetText(string.format('Inferred status: %s', data.Inferred))
                    self.Label:SetText(string.format('Of label: %d', data.Label))
                end
            end, 'GridPresenceUIDebugCell', 'Alice'
        )

        AddOnSyncHashedCallback(
            function(data)
                if Root then
                    self.Inferred:SetText(string.format('Inferred status: ...'))
                    self.Label:SetText(string.format('Of label: ...'))
                end
            end, 'FocusArmyChanged', 'GridPresenceCell'
        )
    end,

    ---@param self GridPresenceUICell
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self.Title)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        LayoutHelpers.LayoutFor(self.Inferred)
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()

        LayoutHelpers.LayoutFor(self.Label)
            :Over(self, 5)
            :Below(self.Inferred, 4)
            :End()
    end,
}

---@class GridPresenceUIUpdate : Group
---@field Title Text
---@field CountingTime Text
---@field CountingTick Text
---@field InferredTime Text
---@field InferredTick Text
GridPresenceUIUpdate = ClassUI(Group) {

    ---@param self GridPresenceUIUpdate
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'GridPresenceUIUpdate')

        self.Title = UIUtil.CreateText(self, 'Update information', 14)
        self.CountingTime = UIUtil.CreateText(self, 'Time to count: ... (ms)', 12)
        self.CountingTick = UIUtil.CreateText(self, 'Tick we counted: ...', 12)
        self.InferredTime = UIUtil.CreateText(self, 'Time to infer: ... (ms)', 12)
        self.InferredTick = UIUtil.CreateText(self, 'Tick we inferred: ...', 12)

        AddOnSyncHashedCallback(
        ---@param data GridPresenceUIDebugUpdate
            function(data)
                if Root then
                    self.CountingTime:SetText(string.format('Time to count: %.2f (ms)', 1000 * data.ResourcePointsTime))
                    self.CountingTick:SetText(string.format('Tick we counted: %d', data.ResourcePointsTick))
                    self.InferredTime:SetText(string.format('Time to infer: %.2f (ms)', 1000 * data.InferredTime))
                    self.InferredTick:SetText(string.format('Tick we inferred: %d', data.InferredTick))
                end
            end, 'GridPresenceUIDebugUpdate', 'Alice'
        )

        AddOnSyncHashedCallback(
            function(data)
                if Root then
                    self.CountingTime:SetText(string.format('Time to count: ... (ms)'))
                    self.CountingTick:SetText(string.format('Tick we counted: ...'))
                    self.InferredTime:SetText(string.format('Time to infer: ... (ms)'))
                    self.InferredTick:SetText(string.format('Tick we inferred: ...'))
                end
            end, 'FocusArmyChanged', 'GridPresenceUpdate'
        )
    end,

    ---@param self GridPresenceUIUpdate
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self.Title)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        LayoutHelpers.LayoutFor(self.CountingTime)
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()

        LayoutHelpers.LayoutFor(self.CountingTick)
            :Over(self, 5)
            :Below(self.CountingTime, 2)
            :End()

        LayoutHelpers.LayoutFor(self.InferredTime)
            :Over(self, 5)
            :Below(self.CountingTick, 2)
            :End()

        LayoutHelpers.LayoutFor(self.InferredTick)
            :Over(self, 5)
            :Below(self.InferredTime, 2)
            :End()
    end,
}

---@class GridPresenceUI : Window
GridPresenceUI = ClassUI(Window) {

    __init = function(self, parent)
        Window.__init(self, parent, "Grid Presence UI", false, false, false, true, false, "GridPresenceUI6", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 515
        })

        self.CellInfo = LayoutHelpers.LayoutFor(GridPresenceUICell(self))
            :Left(self.Left)
            :Right(self.Right)
            :AtTopIn(self, 30)
            :Height(70)
            :End()

        self.UpdateInfo = LayoutHelpers.LayoutFor(GridPresenceUIUpdate(self))
            :Left(self.Left)
            :Right(self.Right)
            :Below(self.CellInfo)
            :Bottom(self.Bottom)
            :End()
    end,

    OnClose = function(self)
        SimCallback({
            Func = 'GridPresenceDebugDisable',
            Args = {}
        }, false)

        self:Hide()
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = GridPresenceUI(GetFrame(0))
        Root:Show()
    end

    SimCallback({
        Func = 'GridPresenceDebugEnable',
        Args = {}
    }, false)
end

function CloseWindow()
    if Root then
        Root:Hide()

        SimCallback({
            Func = 'GridPresenceDebugDisable',
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
