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

---@alias KeyEventType 
---| KeyEventType.Mouse
---| KeyEventType.Keyboard

--- Key events from the mouse
---@alias KeyEventType.Mouse
---| "ButtonPress"
---| "ButtonRelease"
---| "ButtonDClick"
---| "MouseEnter"
---| "MouseMotion"
---| "MouseExit"
---| "WheelRotation"

--- Key events from the keyboard when a Control has "keyboard focus" or is an "input capture"
---@see Control.AcquireKeyboardFocus # Keyboard focus
---@see Control.AbandonKeyboardFocus # Keyboard focus
---@see Control.OnKeyboardFocusChange # Keyboard focus
---@see Control.OnLoseKeyboardFocus # Keyboard focus
---@see AddInputCapture # Input Capture
---@see AnyInputCapture # Input Capture
---@see GetInputCapture # Input Capture
---@see RemoveInputCapture # Input Capture
---@alias KeyEventType.Keyboard
---| "KeyDown"
---| "Char"
---| "KeyUp"

--- Generic input-event payload delivered to MAUI control hooks. Each
--- control hook (`HandleEvent`, the keyboard / mouse callbacks on `Edit`,
--- `Button`, `Checkbox`, etc.) receives a single `KeyEvent` table; not
--- every field is meaningful for every event Type, so MouseX/Y are -1
--- on key events and WheelDelta/Rotation are 0 outside wheel events.
---
--- For `Edit.OnNonTextKeyPressed` the function gets `(self, keycode, event)`.
--- `keycode` is a Windows virtual-key code (see `VK_KeyCode`) and
--- `event.Modifiers` is the modifier state at the time of the press.
---@class KeyEvent
---@field Type           KeyEventType   # "Char" / "KeyDown" / "ButtonPress" / "MouseEnter" / "MouseExit" / "WheelRotation" / ...
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
---@see moho.edit_methods.OnTextChanged # Called with the new and the previous text
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
---@see moho.edit_methods.OnTextChanged # Called with the new and the previous text
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

--- Engine does not call HandleEvent for Edit controls
---@type nil
CMauiEdit.HandleEvent = nil

--- Called by the engine when a character key is pressed, before the character is inserted.
--- `charcode` is the character code, which includes `Tab` (9) and `Space` (32). Return `true` to
--- handle the character yourself, so the engine doesn't insert it
---@type nil | fun(self: Edit, charcode: integer): boolean?
CMauiEdit.OnCharPressed = nil

--- Called by the engine when the user presses `Enter`. `currentText` is the text in the edit when
--- the key is pressed. Return `true` to keep the text; otherwise the engine clears it
---@type nil | fun(self: Edit, currentText: string): boolean?
CMauiEdit.OnEnterPressed = nil

--- Called by the engine when the user presses `Escape`. `currentText` is the text in the edit when
--- the key is pressed. Return `true` to keep the text and focus; otherwise the engine clears the
--- text, or abandons keyboard focus if the text is already empty
---@type nil | fun(self: Edit, currentText: string): boolean?
CMauiEdit.OnEscPressed = nil

--- Called by the engine when a key that doesn't type a character is pressed, with its Windows
--- virtual-key code. `event.KeyCode` holds the wxWidgets code of the same key instead. Keys the
--- engine uses for editing (`Backspace`, `Delete`, `Insert`, `Home`, `End`, `Left` and `Right`)
--- and `Enter` and `Escape` don't reach this callback. `Up`, `Down`, `Page Up` and `Page Down`
--- do
---@see VK_KeyCode # The codes, and the `UIUtil.VK_*` constants
---@type nil | fun(self: Edit, keycode: VK_KeyCode, event: KeyEvent)
CMauiEdit.OnNonTextKeyPressed = nil

--- Called by the engine when the text changes, with the new and the previous text
---@see moho.edit_methods.SetText # Changes the text
---@see moho.edit_methods.ClearText # Clears the text
---@type nil | fun(self: Edit, newText: string, oldText: string)
CMauiEdit.OnTextChanged = nil

return CMauiEdit
