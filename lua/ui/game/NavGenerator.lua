
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Window = import('/lua/maui/window.lua').Window
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local Model = import('/lua/ui/game/NavGeneratorState.lua').State

local Root = nil
local DebugInterface = true 

---@alias NavUIStates 'overview' | 'actions'

---@class NavUIOverview
NavUIOverview = Class(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIOverview')
    end
}

---@class NavUIActions
NavUIActions = Class(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIActions')

        self.BodyGenerate = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.Right() + LayoutHelpers.ScaleNumber(200) end)
            :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :End()

        self.ButtonGenerate = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self.BodyGenerate, '/BUTTON/medium/', "Generate"))
            :AtLeftTopIn(self.BodyGenerate, 10, 10)
            :End()

        self.ButtonGenerate.OnClick = function()
            SimCallback({ Func = 'NavGenerate', Args = { }}, false)
        end
    end,
}


---@class NavUI
NavUI = Class(Window) {

    __init = function(self, parent)

        -- prepare base class

        Window.__init(self, parent, "NavUI", false, false, false, true, false, "NavUI", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 810
        })

        LayoutHelpers.DepthOverParent(self, parent, 1)
        self._border = UIUtil.SurroundWithBorder(self, '/scx_menu/lan-game-lobby/frame/')

        -- prepare this class

        self.Common = LayoutHelpers.LayoutFor(Group(self))
            :Fill(self)
            :End()

        self.Debug = LayoutHelpers.LayoutFor(Group(self))
            :Fill(self)
            :End()

        self.Header = LayoutHelpers.LayoutFor(Group(self.Common))
            :Left(self.Common.Left)
            :Right(self.Common.Right)
            :Top(self.Common.Top)
            :Bottom(function() return self.Common.Top() + LayoutHelpers.ScaleNumber(60) end)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(self.Debug))
            :Fill(self.Header)
            :Color('99999999')
            :End()

        self.Body = LayoutHelpers.LayoutFor(Group(self.Common))
            :Left(self.Common.Left)
            :Right(self.Common.Right)
            :Top(function() return self.Header.Bottom() + LayoutHelpers.ScaleNumber(4) end)
            :Bottom(self.Common.Bottom)
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

--- Called by the module manager when this module is dirty due to a disk change
function OnDirtyModule()
    if Root then
        Root:Destroy()
    end
end