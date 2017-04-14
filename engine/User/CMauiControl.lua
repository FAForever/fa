--- Class CMauiControl
-- @classmod User.CMauiControl

---
--  AcquireKeyboardFocus(bool blocksKeyDown)
function CMauiControl:AcquireKeyboardFocus(bool blocksKeyDown)
end

---
--  ApplyFunction(func) - applys a function to this control and all children, function will recieve the control object as the only parameter
function CMauiControl:ApplyFunction(func)
end

---
--  ClearChildren()
function CMauiControl:ClearChildren()
end

---
--  Control:Destroy() -- destroy a control.
function CMauiControl:Destroy()
end

---
--  Control:DisableHitTest([recursive]) -- hit testing will be skipped for this control
function CMauiControl:DisableHitTest([recursive])
end

---
--  Dump
function CMauiControl:Dump()
end

---
--  Control:EnableHitTest([recursive]) -- hit testing will be checked for this control
function CMauiControl:EnableHitTest([recursive])
end

---
--  float GetAlpha()
function CMauiControl:GetAlpha()
end

---
--  GetCurrentFocusControl()
function CMauiControl:GetCurrentFocusControl()
end

---
--  string GetName()
function CMauiControl:GetName()
end

---
--  Control:GetParent() -- return the parent of this control, or nil if it doesn't have one.
function CMauiControl:GetParent()
end

---
--  int GetRenderPass()
function CMauiControl:GetRenderPass()
end

---
--  Frame GetRootFrame()
function CMauiControl:GetRootFrame()
end

---
--  Control:Hide() -- stop rendering and hit testing the control
function CMauiControl:Hide()
end

---
--  bool HitTest(x, y) - given x,y coordinates, tells you if the control is under the coordinates
function CMauiControl:HitTest(x,  y)
end

---
--  Control:IsHidden() -- determine if the control is hidden
function CMauiControl:IsHidden()
end

---
--  Control:IsHitTestDisabled() -- determine if hit testing is disabled
function CMauiControl:IsHitTestDisabled()
end

---
--  bool NeedsFrameUpdate()
function CMauiControl:NeedsFrameUpdate()
end

---
--  SetAlpha(float, children) - Set the alpha of a given control, if children is true, also sets childrens alpha
function CMauiControl:SetAlpha(float,  children)
end

---
--  Control:SetHidden() -- set the hidden state of the control
function CMauiControl:SetHidden()
end

---
--  SetName(string)
function CMauiControl:SetName(string)
end

---
--  SetNeedsFrameUpdate(bool needsIt)
function CMauiControl:SetNeedsFrameUpdate(bool needsIt)
end

---
--  Control:SetParent(newParentControl) -- change the control's parent
function CMauiControl:SetParent(newParentControl)
end

---
--  int SetRenderPass()
function CMauiControl:SetRenderPass()
end

---
--  Control:Show() -- start rendering and hit testing the control
function CMauiControl:Show()
end

---
--
function CMauiControl:moho.control_methods()
end

