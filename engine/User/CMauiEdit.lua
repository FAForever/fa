---@meta

--- Modifier-key state attached to an input event. Each field is `true`
--- only when the matching modifier was held at the moment the event
--- fired; absent entries are nil rather than `false`, so test with
--- `event.Modifiers.Shift` (truthy / nil) rather than equality.
---@class KeyModifiers
---@field Shift?  boolean
---@field Ctrl?   boolean
---@field Alt?    boolean
---@field Left?   boolean   # left mouse button held (mouse events)
---@field Right?  boolean   # right mouse button held (mouse events)
---@field Middle? boolean   # middle mouse button held (mouse events)

--- Generic input-event payload delivered to MAUI control hooks. Each
--- control hook (`HandleEvent`, the keyboard / mouse callbacks on `Edit`,
--- `Button`, `Checkbox`, etc.) receives a single `KeyEvent` table; not
--- every field is meaningful for every event Type, so MouseX/Y are -1
--- on key events and WheelDelta/Rotation are 0 outside wheel events.
---
--- For `Edit.OnNonTextKeyPressed` the function gets `(self, keycode, event)`
--- — `keycode` is the raw VK_* code (compare against `UIUtil.VK_*`) and
--- `event.Modifiers` is the modifier state at the time of the press.
---@class KeyEvent
---@field Type           string         # "Char" / "KeyDown" / "ButtonPress" / "MouseEnter" / "MouseExit" / "WheelRotation" / ...
---@field Control        Control        # the control receiving the event
---@field KeyCode        number         # engine-translated keycode (post-IME, etc.)
---@field RawKeyCode     number         # OS-level VK_* keycode (compare against `UIUtil.VK_*`)
---@field Modifiers      KeyModifiers   # which modifiers / mouse buttons were held when the event fired
---@field MouseX         number         # cursor X in screen coords (-1 on non-mouse events)
---@field MouseY         number         # cursor Y in screen coords (-1 on non-mouse events)
---@field WheelDelta     number         # mouse-wheel delta (0 outside wheel events)
---@field WheelRotation  number         # mouse-wheel rotation in 1/120 ticks (0 outside wheel events)

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
