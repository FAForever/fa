-- Class methods
-- Destroy()
-- control GetParent()
-- ClearChildren()
-- SetParent(control)
-- DisableHitTest()
-- EnableHitTest()
-- boolean IsHitTestDisabled()
-- Hide()
-- Show()
-- SetHidden(bool)
-- bool IsHidden()
-- SetRenderPass(int)
-- int GetRenderPass()
-- AcquireKeyboardFocus(bool blocksKeyDown)
-- AbandonKeyboardFocus()
-- bool NeedsFrameUpdate()
-- SetNeedsFrameUpdate(bool needsIt)
-- SetAlpha(float newAlpha, bool children)
-- float GetAlpha()


-- debug methods
    -- string GetName()
    -- SetName(string name)
    -- Dump()

Control = Class(moho.control_methods) {

    -- reset the control's layout to the defaults, in this case
    -- makes a circular dependency where you must have at least 4 defined
    -- Overload this in your own classes to make it behave differently
    ResetLayout = function(self)
        self.Left:Set(function() return self.Right() - self.Width() end)
        self.Top:Set(function() return self.Bottom() - self.Height() end)
        self.Right:Set(function() return self.Left() + self.Width() end)
        self.Bottom:Set(function() return self.Top() + self.Height() end)
        self.Width:Set(function() return self.Right() - self.Left() end)
        self.Height:Set(function() return self.Bottom() - self.Top() end)
    end,

    OnInit = function(self)
        self:ResetLayout()

        -- default to setting the depth to parent + 1
        self.Depth:Set(function() return self:GetParent().Depth() + 1 end)
        
        self._isDisabled = false
    end,

    HandleEvent = function(self, event)
        return false
    end,

    Disable = function(self)
        self._isDisabled = true
        self:DisableHitTest()
        self:OnDisable()
    end,

    Enable = function(self)
        self._isDisabled = false
        self:EnableHitTest()
        self:OnEnable()
    end,

    IsDisabled = function(self)
        return self._isDisabled
    end,

    -- called when the control is destroyed
    OnDestroy = function(self)
    end,

    -- called when a frame update is ready, elapsedTime is time since last frame
    OnFrame = function(self, elapsedTime)
    end,

    -- called when the control is enabled
    OnEnable = function(self)
    end,

    -- called when the control is disabled
    OnDisable = function(self)
    end,
    
    -- called when the control is shown or hidden
    -- if this function returns true, its children will not get their OnHide functions called
    OnHide = function(self, hidden)
    end,
    
    -- called when we have keyboard focus and another control is clicked on
    OnLoseKeyboardFocus = function(self)
    end,
    
    -- called when another control takes keyboard focus
    OnKeyboardFocusChange = function(self)
    end,
    
    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GetScrollValues = function(self, axis)
        return 0, 0, 0, 0
    end,

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    ScrollLines = function(self, axis, delta)
    end,

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    ScrollPages = function(self, axis, delta)
    end,

    -- called when the scrollbar wants to set a new visible top line
    ScrollSetTop = function(self, axis, top)
    end,

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    IsScrollable = function(self, axis)
        return false
    end,
}
