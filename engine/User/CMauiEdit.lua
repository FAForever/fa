---@meta

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
---@return Color
function CMauiEdit:GetForegroundColor()
end

---
---@return Color
function CMauiEdit:GetHighlightBackgroundColor()
end

---
---@return Color
function CMauiEdit:GetHighlightForegroundColor()
end

---
---@return number
function CMauiEdit:GetMaxChars()
end

--- Gets the advance of a string using the same font as the text box
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

---@class EventModifiers
---@field Alt? true
---@field Ctrl? true
---@field Left? true
---@field Right? true
---@field Shift? true

---@class KeyEvent
---@field Control Control
---@field KeyCode number
---@field Modifiers EventModifiers
---@field MouseX number
---@field MouseY number
---@field RawKeyCode number
---@field Type string
---@field WheelDelta number
---@field WheelRotation number

--- Called when the text has changed in the text box. Passes in the newly changed text
--- and the previous text.
---@type fun(self: Edit, newText: string, oldText: string)
CMauiEdit.OnTextChanged = nil

--- Called when the user presses the enter key. Passes in the current contents of the text box.
---@type fun(self: Edit, text: string)
CMauiEdit.OnEnterPressed = nil

--- Called when non-text keys are pressed. If the key already affected the text, such as with `Backspace`
--- or `Delete`, then the event has already been handled and won't propagate down.
-- @param keycode number Windows VK keycode
---@type fun(self: Edit, keycode: number, event: KeyEvent)
CMauiEdit.OnNonTextKeyPressed = nil

--- Called when a character key is pressed, before it is entered in to the dialog. If the function
--- returns `true` (indicating the char is handled) then the character is not inserted in the dialog.
---@type fun(self: Edit, charcode: number): boolean
CMauiEdit.OnCharPressed = nil

--- Called when the `escape` key is pressed. Return `true` to prevent the text box from clearing.
---@type fun(self: Edit, text: string): boolean
CMauiEdit.OnEscPressed = nil

return CMauiEdit
