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

return CMauiControl
