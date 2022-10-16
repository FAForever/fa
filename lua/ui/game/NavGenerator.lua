
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Window = import('/lua/maui/window.lua').Window
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local Shared = import('/lua/shared/NavGenerator.lua')

local Root = nil
local DebugInterface = false 

---@alias NavUIStates 'overview' | 'actions'

---@class NavUIOverview
NavUIOverview = Class(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIOverview')
    end
}

---@class NavUILayerStatistics
NavUILayerStatistics = Class(Group) {
    __init = function(self, parent, layer)
        local name = 'NavUILayerStatistics - ' .. tostring(layer)
        Group.__init(self, parent, 'NavUILayerStatistics - ' .. tostring(layer))

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77' .. Shared.colors[layer])
            :DisableHitTest(true)
            :End()

        ---@type Text
        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, string.format('Layer: %s', layer), 8, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End()

        ---@type Text
        self.Subdivisions = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Subdivisions: 0', 12, UIUtil.bodyFont))
            :Below(self.Title, 2)
            :Over(self, 1)
            :End()

        ---@type Text
        self.PathableLeafs = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'PathableLeafs: 0', 12, UIUtil.bodyFont))
            :Below(self.Subdivisions)
            :Over(self, 1)
            :End()

        ---@type Text
        self.UnpathableLeafs = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'UnpathableLeafs: 0', 12, UIUtil.bodyFont))
            :Below(self.PathableLeafs)
            :Over(self, 1)
            :End()

        self.ToggleScanButton = LayoutHelpers.LayoutFor(UIUtil.CreateButtonStd(self, '/game/mfd_btn/control', nil, nil, nil, nil, 'UI_Tab_Click_01', 'UI_Tab_Rollover_01'))
            :AtRightTopIn(self)
            :Width(24)
            :Height(16)
            :Over(self, 1)
            :End()

        self.ToggleScanButton.OnClick = function()
            SimCallback({ Func = string.format("NavToggle%sScan", layer), Args = { }}, false)
        end

        AddOnSyncCallback(
            function(Sync)
                if Sync.NavLayerData then
                    ---@type NavLayerData
                    local data = Sync.NavLayerData

                    self.Subdivisions:SetText(string.format('Subdivisions: %d', data[layer].Subdivisions))
                    self.PathableLeafs:SetText(string.format('PathableLeafs: %d', data[layer].PathableLeafs))
                    self.UnpathableLeafs:SetText(string.format('UnpathableLeafs: %d', data[layer].UnpathableLeafs))
                end
            end, name
        )
    end,
}

---@class NavUIActions
NavUIActions = Class(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIActions')

        self.Debug = LayoutHelpers.LayoutFor(Group(GetFrame(0)))
            :Fill(self)
            :End()

        self.BodyGenerate = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.Left() + LayoutHelpers.ScaleNumber(180) end)
            :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Bottom() - LayoutHelpers.ScaleNumber(10) end)
            :Over(self, 1)
            :End()

        self._border = UIUtil.SurroundWithBorder(self.BodyGenerate, '/scx_menu/lan-game-lobby/frame/')

        LayoutHelpers.LayoutFor(Bitmap(self.Debug))
            :Fill(self.BodyGenerate)
            :Color('99999999')
            :End()

        self.StatisticsLand = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Land'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.BodyGenerate.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.BodyGenerate.Top() + LayoutHelpers.ScaleNumber(85) end)
            :Over(self, 1)
            :End()

        self.StatisticsAmph = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Amphibious'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsLand.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsLand.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :Over(self, 1)
            :End()

        self.StatisticsHover = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Hover'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsAmph.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsAmph.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :Over(self, 1)
            :End()

        self.StatisticsNaval = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Water'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsHover.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsHover.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :Over(self, 1)
            :End()

        self.ButtonGenerate = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self.BodyGenerate, '/BUTTON/medium/', "Generate"))
            :CenteredBelow(self.StatisticsNaval, 10)
            :Over(self.BodyGenerate, 1)
            :End()

        self.ButtonGenerate.OnClick = function()
            SimCallback({ Func = 'NavGenerate', Args = { }}, false)
        end

        self.BodyScanning = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.BodyGenerate.Right() + LayoutHelpers.ScaleNumber(20) end)
            :Right(function() return self.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Bottom() - LayoutHelpers.ScaleNumber(10) end)
            :Over(self, 1)
            :End()

        self._border = UIUtil.SurroundWithBorder(self.BodyScanning, '/scx_menu/lan-game-lobby/frame/')

        self.Debug:DisableHitTest(true)
        if not DebugInterface then
            self.Debug:Hide()
        end
    end,    
}

---@class NavUI
NavUI = Class(Window) {

    __init = function(self, parent)

        -- prepare base class

        Window.__init(self, parent, "NavUI", false, false, false, true, false, "NavUI2", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 750
        })

        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')

        -- prepare this class

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('22ffffff')
            :End()

        self.Debug = LayoutHelpers.LayoutFor(Group(GetFrame(0)))
            :Fill(self)
            :End()

        self.Header = LayoutHelpers.LayoutFor(Group(self))
            :Left(self.Left)
            :Right(self.Right)
            :Top(self.Top)
            :Bottom(function() return self.Top() + LayoutHelpers.ScaleNumber(25) end)
            :End()

        self.Body = LayoutHelpers.LayoutFor(Group(self))
            :Left(self.Left)
            :Right(self.Right)
            :Top(function() return self.Header.Bottom() + LayoutHelpers.ScaleNumber(4) end)
            :Bottom(self.Bottom)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(self.Debug))
            :Fill(self.Body)
            :Color('9999ff99')
            :End() 

        -- prepare header



        -- prepare body

        -- self.NavUIOverview = LayoutHelpers.LayoutFor(NavUIOverview(self.Body))
        --     :Fill(self.Body)
        --     :End()

        self.NavUIActions = LayoutHelpers.LayoutFor(NavUIActions(self.Body))
            :Fill(self.Body)
            :End()

        self.Debug:DisableHitTest(true)
        if not DebugInterface then
            self.Debug:Hide()
        end
    end,

    ---comment
    ---@param self any
    ---@param identifier any
    SwitchState = function(self, identifier)

    end,

    OnClose = function(self)
        self:Hide()
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = NavUI(GetFrame(0))
        Root:Show()
    end
end

function CloseWindow()
    if Root then
        Root:Hide()
    end
end

function OnNavProfileData(data)
    if Root then 
        Root:OnNavProfileData(data)
    end
end

function OnNavLayerData(data)
    if Root then 
        Root:OnNavProfileData(data)
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __OnDirtyModule()
    if Root then
        Root:Destroy()
    end
end