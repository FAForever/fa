---@declare-global
---@class moho.control_methods
local CMauiControl = {}

---
function CMauiControl:AbandonKeyboardFocus()
end


---@param blocksKeyDown boolean
function CMauiControl:AcquireKeyboardFocus(blocksKeyDown)
end

--- Applys a function to this control and all children, function will recieve the control object as the only parameter
function CMauiControl:ApplyFunction(func)
end

---
function CMauiControl:ClearChildren()
end

--- Destroy a control
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
---@param recursive? boolean
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

--- Return the parent of this control, or nil if it doesn't have one
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

--- Stop rendering and hit testing the control
function CMauiControl:Hide()
end

--- Given x,y coordinates, tell you if the control is under the coordinates
---@return boolean
function CMauiControl:HitTest(x, y)
end

--- Determine if the control is hidden
function CMauiControl:IsHidden()
end

--- Determine if hit testing is disabled
function CMauiControl:IsHitTestDisabled()
end

---
--  bool NeedsFrameUpdate()
function CMauiControl:NeedsFrameUpdate()
end

--- Set the alpha of a given control, if children is true, also set children's alpha
---@param alpha number
---@param children boolean
function CMauiControl:SetAlpha(alpha, children)
end

--- Set the hidden state of the control
function CMauiControl:SetHidden()
end

---
---@param name string
function CMauiControl:SetName(name)
end

---
---@param needsIt boolean
function CMauiControl:SetNeedsFrameUpdate(needsIt)
end

--- Change the control's parent
---@param newParentControl Control
function CMauiControl:SetParent(newParentControl)
end

---
---@return number
function CMauiControl:SetRenderPass()
end

--- Start rendering and hit testing the control
function CMauiControl:Show()
end

return CMauiControl
