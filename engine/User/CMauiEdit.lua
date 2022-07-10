---@declare-global
---@class moho.edit_methods : moho.control_methods
local CMauiEdit = {}

---
function CMauiEdit:AbandonFocus()
end

---
function CMauiEdit:AcquireFocus()
end

---
function CMauiEdit:ClearText()
end

---
function CMauiEdit:DisableInput()
end

---
function CMauiEdit:EnableInput()
end

---
---@return string
function CMauiEdit:GetBackgroundColor()
end

---
---@return string
function CMauiEdit:GetCaretColor()
end

---
---@return number
function CMauiEdit:GetCaretPosition()
end

---
---@return number
function CMauiEdit:GetFontHeight()
end

---
---@return string
function CMauiEdit:GetForegroundColor()
end

---
---@return string
function CMauiEdit:GetHighlightBackgroundColor()
end

---
---@return string
function CMauiEdit:GetHighlightForegroundColor()
end

---
---@return number
function CMauiEdit:GetMaxChars()
end

--- Get the advance of a string using the same font as the control
---@param text string
function CMauiEdit:GetStringAdvance(text)
end

---
---@return string
function CMauiEdit:GetText()
end

---
---@return boolean
function CMauiEdit:IsBackgroundVisible()
end

---
---@return boolean
function CMauiEdit:IsCaretVisible()
end

---
---@return boolean
function CMauiEdit:IsEnabled()
end

---
---@param seconds number
---@param minAlpha number
---@param maxAlpha number
function CMauiEdit:SetCaretCycle(seconds, minAlpha, maxAlpha)
end

---
---@param pos number
function CMauiEdit:SetCaretPosition(pos)
end

---
---@param show boolean
function CMauiEdit:SetDropShadow(show)
end

---
---@param size number
function CMauiEdit:SetMaxChars(size)
end

---
---@param color string
function CMauiEdit:SetNewBackgroundColor(color)
end

---
---@param color string
function CMauiEdit:SetNewCaretColor(color)
end

---
---@param family string
---@param pointsize number
function CMauiEdit:SetNewFont(family, pointsize)
end

---
---@param color string
function CMauiEdit:SetNewForegroundColor(color)
end

---
---@param color string
function CMauiEdit:SetNewHighlightBackgroundColor(color)
end

---
---@param color string
function CMauiEdit:SetNewHighlightForegroundColor(color)
end

---
---@param text string
function CMauiEdit:SetText(text)
end

---
---@param show boolean
function CMauiEdit:ShowBackground(show)
end

---
---@param show boolean
function CMauiEdit:ShowCaret(show)
end

return CMauiEdit
