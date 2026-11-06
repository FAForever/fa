-- A flat panel for overlays: a dark translucent fill with a one-pixel border, in the colours of the skin's panels.
-- Everything is drawn from solid rectangles, so it stays sharp at any size and UI scale.

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

Fill = 'e00b1116'
Border = 'ff415055'

--- A rectangle that draws and takes no events.
function Rectangle(parent, color, depthAbove)
    local rectangle = Bitmap(parent)
    rectangle:SetSolidColor(color)
    rectangle:DisableHitTest()
    rectangle.Depth:Set(function() return parent.Depth() + depthAbove end)
    return rectangle
end

--- Hides or shows a control only when that changes anything. `Show` on a parent shows every child, so a control
--- that may stay hidden sets this each frame.
function SetVisible(control, visible)
    if visible == control:IsHidden() then
        if visible then
            control:Show()
        else
            control:Hide()
        end
    end
end

FlatPanel = ClassUI(Group) {
    __init = function(self, parent, name)
        Group.__init(self, parent, name)

        local background = Rectangle(self, Fill, 0)
        LayoutHelpers.FillParent(background, self)

        local top = Rectangle(self, Border, 1)
        top.Left:Set(self.Left)
        top.Right:Set(self.Right)
        top.Top:Set(self.Top)
        top.Height:Set(1)

        local bottom = Rectangle(self, Border, 1)
        bottom.Left:Set(self.Left)
        bottom.Right:Set(self.Right)
        bottom.Bottom:Set(self.Bottom)
        bottom.Height:Set(1)

        local left = Rectangle(self, Border, 1)
        left.Left:Set(self.Left)
        left.Top:Set(self.Top)
        left.Bottom:Set(self.Bottom)
        left.Width:Set(1)

        local right = Rectangle(self, Border, 1)
        right.Right:Set(self.Right)
        right.Top:Set(self.Top)
        right.Bottom:Set(self.Bottom)
        right.Width:Set(1)

        self.mOpacity = 1
    end,

    --- Moves toward shown or hidden, over `seconds`. A hidden panel takes no clicks.
    Fade = function(self, shown, delta, seconds)
        local goal = shown and 1 or 0
        if self.mOpacity == goal then
            if shown then
                SetVisible(self, true)
            end
            return
        end
        local step = delta / seconds
        if shown then
            self.mOpacity = math.min(self.mOpacity + step, 1)
            SetVisible(self, true)
        else
            self.mOpacity = math.max(self.mOpacity - step, 0)
        end
        self:SetAlpha(self.mOpacity, true)
        if self.mOpacity == 0 then
            SetVisible(self, false)
        end
    end,

    --- At once, with no fade.
    SetShown = function(self, shown)
        self.mOpacity = shown and 1 or 0
        self:SetAlpha(self.mOpacity, true)
        SetVisible(self, shown)
    end,
}
