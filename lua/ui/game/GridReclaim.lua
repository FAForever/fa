local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class GridReclaimUIDebugCell
---@field TotalMass number
---@field TotalEnergy number
---@field ReclaimCount number
---@field X number
---@field Z number

---@class GridReclaimUIDebugUpdate
---@field Tick number
---@field Time number
---@field Memory number
---@field Updates number
---@field Processed number

GridReclaimUICell = ClassUI(Group) {
    __init = function(self, parent)
        Group.__init(self, parent, 'GridReclaimUICell')

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Scanning information', 14))
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        self.Mass = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Mass in cell: ...', 12))
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()

        self.Energy = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Energy in cell: ...', 12))
            :Over(self, 5)
            :Below(self.Mass, 2)
            :End()

        self.Count = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Number of reclaim: ...', 12))
            :Over(self, 5)
            :Below(self.Energy, 2)
            :End()

        AddOnSyncHashedCallback(
        ---@param data GridReclaimUIDebugCell
            function(data)
                if Root then
                    self.Mass:SetText(string.format('Mass in cell: %d', data.TotalMass))
                    self.Energy:SetText(string.format('Energy in cell: %d', data.TotalEnergy))
                    self.Count:SetText(string.format('Number of reclaim: %d', data.ReclaimCount))
                end
            end, 'GridReclaimUIDebugCell', 'Alice'
        )
    end
}

GridReclaimUIUpdate = ClassUI(Group) {
    __init = function(self, parent)
        Group.__init(self, parent, 'GridReclaimUIUpdate')

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Update information', 14))
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        self.Time = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Time to compute: ... (ms)', 12))
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()

        self.Updates = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Updates processed: ...', 12))
            :Over(self, 5)
            :Below(self.Time, 2)
            :End()

        self.Processed = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Props processed: ...', 12))
            :Over(self, 5)
            :Below(self.Updates, 2)
            :End()

        AddOnSyncHashedCallback(
        ---@param data GridReclaimUIDebugUpdate
            function(data)
                if Root then
                    self.Time:SetText(string.format('Time to compute: %.2f (ms)', 1000 * data.Time))
                    self.Updates:SetText(string.format('Updates processed: %d', data.Updates))
                    self.Processed:SetText(string.format('Props processed: %d', data.Processed))
                end
            end, 'GridReclaimUIDebugUpdate', 'Alice'
        )
    end
}

---@class GridReclaimUI : Window
GridReclaimUI = ClassUI(Window) {

    __init = function(self, parent)
        Window.__init(self, parent, "Grid reclaim UI", false, false, false, true, false, "GridReclaimUI4", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 525
        })

        self.CellInfo = LayoutHelpers.LayoutFor(GridReclaimUICell(self))
            :Left(self.Left)
            :Right(self.Right)
            :AtTopIn(self, 30)
            :Height(100)
            :End()

        self.UpdateInfo = LayoutHelpers.LayoutFor(GridReclaimUIUpdate(self))
            :Left(self.Left)
            :Right(self.Right)
            :Below(self.CellInfo)
            :Bottom(self.Bottom)
            :End()
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
        Root = GridReclaimUI(GetFrame(0))
        Root:Show()
    end

    SimCallback({
        Func = 'GridReclaimDebugEnable',
        Args = {}
    }, false)
end

function CloseWindow()
    if Root then
        Root:Hide()

        SimCallback({
            Func = 'GridReclaimDebugDisable',
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
