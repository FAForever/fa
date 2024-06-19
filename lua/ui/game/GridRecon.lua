local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group

local Root = false

---@class GridReconUIDebugCell
---@field LossOfRecon number
---@field LossOfRadar number
---@field LossOfSonar number
---@field LossOfOmni number
---@field LossOfLOSNow number

---@class GridReconUIDebugUpdate
---@field Time number

---@class GridReconUICell : Group
---@field Title Text
---@field Recon Text
---@field LOSNow Text
---@field Radar Text
---@field Sonar Text
---@field Omni Text
GridReconUICell = ClassUI(Group) {

    ---@param self GridReconUICell
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'GridReconUICell')

        self.Title = UIUtil.CreateText(self, 'Scanning information', 14)
        self.Recon = UIUtil.CreateText(self, 'Recon loss: ...', 12)
        self.LOSNow = UIUtil.CreateText(self, 'Line of sight loss: ...', 12)
        self.Radar = UIUtil.CreateText(self, 'Radar loss: ...', 12)
        self.Sonar = UIUtil.CreateText(self, 'Sonar loss: ...', 12)
        self.Omni = UIUtil.CreateText(self, 'Omni loss: ...', 12)

        AddOnSyncHashedCallback(
        ---@param data GridReconUIDebugCell
            function(data)
                if Root then
                    self.Recon:SetText(string.format('Recon loss: %d', data.LossOfRecon))
                    self.LOSNow:SetText(string.format('Line of Sight loss: %d', data.LossOfLOSNow))
                    self.Sonar:SetText(string.format('Sonar loss: %d', data.LossOfSonar))
                    self.Radar:SetText(string.format('Radar loss: %d', data.LossOfRadar))
                    self.Omni:SetText(string.format('Omni loss: %d', data.LossOfOmni))
                end
            end, 'GridReconUIDebugCell', 'Alice'
        )
    end,

    ---@param self GridReconUICell
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self.Title)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        LayoutHelpers.LayoutFor(self.Recon)
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()

        LayoutHelpers.LayoutFor(self.LOSNow)
            :Over(self, 5)
            :Below(self.Recon, 2)
            :End()

        LayoutHelpers.LayoutFor(self.Radar)
            :Over(self, 5)
            :Below(self.LOSNow, 2)
            :End()
        LayoutHelpers.LayoutFor(self.Sonar)
            :Over(self, 5)
            :Below(self.Radar, 2)
            :End()

        LayoutHelpers.LayoutFor(self.Omni)
            :Over(self, 5)
            :Below(self.Sonar, 2)
            :End()
    end,
}


---@class GridReconUIUpdate : Group
---@field Title Text
---@field Time Text
---@field Updates Text
---@field Processed Text
GridReconUIUpdate = ClassUI(Group) {

    ---@param self GridReconUIUpdate
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'GridReconUIUpdate')

        self.Title = UIUtil.CreateText(self, 'Update information', 14)
        self.Time = UIUtil.CreateText(self, 'Time to compute: ... (ms)', 12)

        AddOnSyncHashedCallback(
        ---@param data GridReconUIDebugUpdate
            function(data)
                if Root then
                    self.Time:SetText(string.format('Time to compute: %.2f (ms)', 1000 * data.Time))
                end
            end, 'GridReconUIDebugUpdate', 'Alice'
        )
    end,

    __post_init = function(self)
        LayoutHelpers.LayoutFor(self.Title)
            :Over(self, 5)
            :AtLeftTopIn(self, 14, 4)
            :End()

        LayoutHelpers.LayoutFor(self.Time)
            :Over(self, 5)
            :Below(self.Title, 4)
            :End()
    end,
}

---@class GridReconUI : Window
GridReconUI = ClassUI(Window) {

    __init = function(self, parent)
        Window.__init(self, parent, "Grid Recon UI", false, false, false, true, false, "GridReconUI10", {
            Left = 10,
            Top = 300,
            Right = 310,
            Bottom = 510
        })

        self.CellInfo = LayoutHelpers.LayoutFor(GridReconUICell(self))
            :Left(self.Left)
            :Right(self.Right)
            :AtTopIn(self, 30)
            :Height(120)
            :End()

        self.UpdateInfo = LayoutHelpers.LayoutFor(GridReconUIUpdate(self))
            :Left(self.Left)
            :Right(self.Right)
            :Below(self.CellInfo)
            :Bottom(self.Bottom)
            :End()
    end,

    OnClose = function(self)
        SimCallback({
            Func = 'GridReconDebugDisable',
            Args = {}
        }, false)

        self:Hide()
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = GridReconUI(GetFrame(0))
        Root:Show()
    end

    SimCallback({
        Func = 'GridReconDebugEnable',
        Args = {}
    }, false)
end

function CloseWindow()
    if Root then
        Root:Hide()

        SimCallback({
            Func = 'GridReconDebugDisable',
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
