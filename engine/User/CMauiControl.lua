---@meta

---@class moho.control_methods : Destroyable
---@field Left LazyVar<number>
---@field Width LazyVar<number>
---@field Right LazyVar<number>
---@field Top LazyVar<number>
---@field Height LazyVar<number>
---@field Bottom LazyVar<number>
---@field Depth LazyVar<number>
local CMauiControl = {}

---
function CMauiControl:AbandonKeyboardFocus()
end

---
---@param blocksKeyDown boolean
function CMauiControl:AcquireKeyboardFocus(blocksKeyDown)
end

--- Applies a function to this control and all children, function will recieve the control object as the only parameter
function CMauiControl:ApplyFunction(func)
end

---
function CMauiControl:ClearChildren()
end

--- Destroys a control
function CMauiControl:Destroy()
end

--- Hit testing will be skipped for this control
---@param recursive? boolean
function CMauiControl:DisableHitTest(recursive)
end

---
function CMauiControl:Dump()
end

--- Hit testing will be checked for this control
---@param recursive? boolean defaults to `true`
function CMauiControl:EnableHitTest(recursive)
end

---
---@return number
function CMauiControl:GetAlpha()
end

---
function CMauiControl:GetCurrentFocusControl()
end

---
---@return string
function CMauiControl:GetName()
end

--- Returns the parent of this control, or `nil` if it doesn't have one
---@return Control
function CMauiControl:GetParent()
end

---
---@return number
function CMauiControl:GetRenderPass()
end

---
---@return Frame
function CMauiControl:GetRootFrame()
end

--- Stops rendering and hit testing the control
function CMauiControl:Hide()
end

--- Given x,y coordinates, tells you if the control is under the coordinates
---@return boolean
function CMauiControl:HitTest(x, y)
end

--- Returns if the control is hidden
---@return boolean
function CMauiControl:IsHidden()
end

--- Returns if hit testing is disabled
---@return boolean
function CMauiControl:IsHitTestDisabled()
end

---
---@return boolean
function CMauiControl:NeedsFrameUpdate()
end

--- Sets the alpha of a given control, if children is true, also set children's alpha
---@param alpha number
---@param children? boolean
function CMauiControl:SetAlpha(alpha, children)
end

--- Sets the hidden state of the control
---@param hidden boolean
function CMauiControl:SetHidden(hidden)
end

---
---@param name string
function CMauiControl:SetName(name)
end

---
---@param needsIt boolean
function CMauiControl:SetNeedsFrameUpdate(needsIt)
end

--- Changes the control's parent
---@param newParentControl Control
function CMauiControl:SetParent(newParentControl)
end

---
---@param pass number
---@return number
function CMauiControl:SetRenderPass(pass)
end

--- Starts rendering and hit testing the control
function CMauiControl:Show()
end

--- Called by the engine when a scrollbar attached to this control needs its size. Returns the
--- minimum and maximum of the scroll range, then of the visible part. The engine logs a warning
--- and uses zeros unless all four values are returned.
---@type nil | fun(self: Control, axis: ScrollAxis): rangeMin: number, rangeMax: number, visibleMin: number, visibleMax: number
CMauiControl.GetScrollValues = nil

--- Called by the engine when an input event reaches this control. Return `true` to consume the
--- event; otherwise the engine passes it to the parent control.
---@type nil | fun(self: Control, event: KeyEvent): boolean
CMauiControl.HandleEvent = nil

--- Called by the engine to ask whether the control can scroll along an axis.
---@type nil | fun(self: Control, axis: ScrollAxis): boolean
CMauiControl.IsScrollable = nil

--- Called by the engine when the control is destroyed, before its children are destroyed.
---@type nil | fun(self: Control)
CMauiControl.OnDestroy = nil

--- Called by the engine every frame while the control needs frame updates, with the time since
--- the last frame in seconds.
---@see Control.SetNeedsFrameUpdate
---@type nil | fun(self: Control, delta: number)
CMauiControl.OnFrame = nil

--- Called by the engine when the control is shown or hidden, before the change. Return `true` to
--- cancel the change for this control and its children.
---@type nil | fun(self: Control, hidden: boolean): boolean?
CMauiControl.OnHide = nil

--- Called by the engine when the control is created by its `InternalCreate*` function.
---@type nil | fun(self: Control)
CMauiControl.OnInit = nil

--- Called by the engine on the control that had keyboard focus when any control acquires
--- keyboard focus, including when it acquires focus again itself.
---@type nil | fun(self: Control)
CMauiControl.OnKeyboardFocusChange = nil

--- Called by the engine on the control with keyboard focus when the user clicks a different control.
---@type nil | fun(self: Control)
CMauiControl.OnLoseKeyboardFocus = nil

--- Called by the engine when a scrollbar scrolls this control by lines. Negative values scroll up.
--- The engine also calls this, not `ScrollPages`, when the scrollbar scrolls by pages; `delta`
--- is then the number of pages.
---@type nil | fun(self: Control, axis: ScrollAxis, delta: number)
CMauiControl.ScrollLines = nil

--- Called by the engine when a scrollbar sets the first visible line of this control.
---@type nil | fun(self: Control, axis: ScrollAxis, top: number)
CMauiControl.ScrollSetTop = nil

return CMauiControl
