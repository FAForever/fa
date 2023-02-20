-- Class methods:
-- SetNewFont(family, pointsize) NOTE: Currently Width must be set before SetFont is called
-- SetNewForegroundColor(color)
-- color GetForegroundColor()
-- SetNewBackgroundColor(color)
-- color GetBackgroundColor()
-- ShowBackground(bool)
-- bool IsBackgroundVisible()
-- ClearText()
-- SetText(string text)
-- string GetText()
-- SetMaxChars(int)
-- int GetMaxChars()
-- SetCaretPosition(uint32)
-- uint32 GetCaretPosition
-- ShowCaret(bool)
-- bool IsCaretVisible()
-- SetNewCaretColor(color)
-- color GetCaretColor()
-- SetCaretCycle(float seconds, uint32 minAlpha, uint32 maxAlpha)
-- EnableInput()
-- DisableInput()
-- bool IsEnabled()
-- SetNewHighlightForegroundColor(color)
-- color GetHighlightForegroundColor()
-- SetNewHighlightBackgroundColor(color)
-- color GetHighlightBackgroundColor()
-- int GetFontHeight()
-- int GetStringAdvance(string)
-- SetDropShadow(bool)
-- AcquireFocus()

local Control = import("/lua/maui/control.lua").Control
local AddUnicodeCharToEditText = import("/lua/utf.lua").AddUnicodeCharToEditText
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

---@class Edit : moho.edit_methods, Control, InternalObject
Edit = ClassUI(moho.edit_methods, Control) {

    __init = function(self, parent, debugname)
        InternalCreateEdit(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua")
        self._lockFontChanges = false
        self._font = {_family = LazyVar.Create(), _pointsize = LazyVar.Create()}
        self._font._family.OnDirty = function(var)
            self:_internalSetFont()
        end
        self._font._pointsize.OnDirty = function(var)
            self:_internalSetFont()
        end

        self._fg = LazyVar.Create()
        self._fg.OnDirty = function(var)
            self:SetNewForegroundColor(var())
        end

        self._bg = LazyVar.Create()
        self._bg.OnDirty = function(var)
            self:SetNewBackgroundColor(var())
        end

        self._cc = LazyVar.Create()
        self._cc.OnDirty = function(var)
            self:SetNewCaretColor(var())
        end

        self._hfg = LazyVar.Create()
        self._hfg.OnDirty = function(var)
            self:SetNewHighlightForegroundColor(var())
        end

        self._hbg = LazyVar.Create()
        self._hbg.OnDirty = function(var)
            self:SetNewHighlightBackgroundColor(var())
        end

    end,

    -- lazy var support
    SetFont = function(self, family, pointsize)
        if self._font then
            self._lockFontChanges = true
            self._font._pointsize:Set(ScaleNumber(pointsize))
            self._font._family:Set(family)
            self._lockFontChanges = false
            self:_internalSetFont()
        end
    end,

    _internalSetFont = function(self)
        if not self._lockFontChanges then
            self:SetNewFont(self._font._family(), self._font._pointsize())
        end
    end,

    SetForegroundColor = function(self, color)
        if self._fg then self._fg:Set(color) end
    end,

    SetBackgroundColor = function(self, color)
        if self._bg then self._bg:Set(color) end
    end,

    SetCaretColor = function(self, color)
        if self._cc then self._cc:Set(color) end
    end,

    SetHighlightForegroundColor = function(self, color)
        if self._hfg then self._hfg:Set(color) end
    end,

    SetHighlightBackgroundColor = function(self, color)
        if self._hbg then self._hbg:Set(color) end
    end,

    OnDestroy = function(self)
        self._font._family:Destroy()
        self._font = nil
        self._fg:Destroy()
        self._fg = nil
        self._bg:Destroy()
        self._bg = nil
        self._cc:Destroy()
        self._cc = nil
        self._hfg:Destroy()
        self._hfg = nil
        self._hbg:Destroy()
        self._hbg = nil
    end,

    -- called when the text has changed in the control, passes in the newly changed text
    -- and the previous text
    OnTextChanged = function(self, newText, oldText)
    end,

    -- called when the user presses the enter key, passes in the current contents of the control
    OnEnterPressed = function(self, text)
    end,

    -- called when non text keys (that don't affect text editing) are pressed, passes in the windows VK key code
    OnNonTextKeyPressed = function(self, keycode, modifiers)
        AddUnicodeCharToEditText(self, keycode)
    end,

    -- called when a character key is pressed, before it is entered in to the dialog. If the function returns "true"
    -- (indicating char was handled) then the character is not inserted in the dialog
    OnCharPressed = function(self, charcode)
        return false
    end,

    -- called when the escape key is pressed, return true to prevent clearing the text box
    OnEscPressed = function(self, text)
        return false
    end,
}
