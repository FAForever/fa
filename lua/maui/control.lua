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

---@class Control : moho.control_methods
---@field _isDisabled boolean
Control = ClassUI(moho.control_methods) {
    --- Resets the control's layout to the defaults, in this case
    --- makes a circular dependency where you must have at least 4 defined.
    --- Overload this in your own classes to make it behave differently
    ---@param self Control
    ResetLayout = function(self)
        self.Left:Set(function() return self.Right() - self.Width() end)
        self.Top:Set(function() return self.Bottom() - self.Height() end)
        self.Right:Set(function() return self.Left() + self.Width() end)
        self.Bottom:Set(function() return self.Top() + self.Height() end)
        self.Width:Set(function() return self.Right() - self.Left() end)
        self.Height:Set(function() return self.Bottom() - self.Top() end)
    end,

    --- Called when the internal C object is created using one of the internal creation functions
    ---@param self Control
    OnInit = function(self)
        self:ResetLayout()

        -- default to setting the depth to parent + 1
        self.Depth:Set(function() return self:GetParent().Depth() + 1 end)

        self._isDisabled = false
    end,

    --- The function is called when a event occurs for this control.
    --- If it returns false then it calls parent HandleEvent.
    --- If it returns true then it doesn't.
    --- Requires HitTest to be true.
    ---@param self Control
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        return false
    end,

    --- Sets this control to be disabled and calls `OnDisable()`
    ---@param self Control
    Disable = function(self)
        self._isDisabled = true
        self:DisableHitTest()
        self:OnDisable()
    end,

    --- Sets this control to be enabled and calls `OnEnable()`
    ---@param self any
    Enable = function(self)
        self._isDisabled = false
        self:EnableHitTest()
        self:OnEnable()
    end,

    --- Returns if this control is disabled
    ---@param self Control
    ---@return boolean _isDisabled
    IsDisabled = function(self)
        return self._isDisabled
    end,

    --- Called when the control is destroyed
    ---@param self Control
    OnDestroy = function(self)
    end,

    --- Called when a frame update is ready, elapsedTime is time since last frame
    ---@param self Control
    OnFrame = function(self, elapsedTime)
    end,

    --- Called when the control is enabled
    ---@param self Control
    OnEnable = function(self)
    end,

    --- Called when the control is disabled
    ---@param self Control
    OnDisable = function(self)
    end,

    --- Called when the control is shown or hidden.
    --- If this function returns true, its children will not get their `OnHide` functions called.
    ---@param self Control
    ---@param hidden boolean
    OnHide = function(self, hidden)
    end,

    --- Called when we have keyboard focus and another control is clicked on
    ---@param self Control
    OnLoseKeyboardFocus = function(self)
    end,

    --- Called when another control takes keyboard focus
    ---@param self Control
    OnKeyboardFocusChange = function(self)
    end,

    -- Called when the scrollbar for the control requires data to size itself
    ---@param self Control
    ---@param axis ScrollAxis
    ---@return number rangeMin
    ---@return number rangeMax
    ---@return number visibleMin
    ---@return number visibleMax
    GetScrollValues = function(self, axis)
        return 0, 0, 0, 0
    end,

    --- Called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    ---@param self Control
    ---@param axis ScrollAxis
    ---@param delta number
    ScrollLines = function(self, axis, delta)
    end,

    --- Called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    ---@param self Control
    ---@param axis ScrollAxis
    ---@param delta number
    ScrollPages = function(self, axis, delta)
    end,

    --- Called when the scrollbar wants to set a new visible top line
    ---@param self Control
    ---@param axis ScrollAxis
    ---@param top number
    ScrollSetTop = function(self, axis, top)
    end,

    --- Called to determine if the control is scrollable on a particular access. Must return true or false.
    ---@param self Control
    ---@param axis ScrollAxis
    ---@return boolean
    IsScrollable = function(self, axis)
        return false
    end,
}