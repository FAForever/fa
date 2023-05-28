local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

---@class Checkbox : Group
---@field checkBmp Bitmap
---@field label? Text
---
---@field _checked boolean
---@field _controlState ControlState
---@field _states ControlStateMap<FileName> set to `checkedStates` or `uncheckedStates`, depending on `_checked`
---
---@field checkedStates ControlStateMap<FileName>
---@field uncheckedStates ControlStateMap<FileName>
---@field mRolloverCue string
---@field mClickCue string
Checkbox = ClassUI(Group) {
    ---@param self Checkbox
    ---@param parent Control
    ---@param normalUnchecked Lazy<FileName>
    ---@param normalChecked Lazy<FileName>
    ---@param overUnchecked? Lazy<FileName> defaults to `normalUnchecked`
    ---@param overChecked? Lazy<FileName> defaults to `normalChecked`
    ---@param disabledUnchecked? Lazy<FileName> defaults to `normalUnchecked`
    ---@param disabledChecked? Lazy<FileName> defaults to `normalChecked`
    ---@param label? UnlocalizedString
    ---@param labelRight? boolean if the label on the checkbox is to its right or left
    ---@param labelSize? number defaults to `13`
    ---@param clickCue? string defaults to `"UI_Mini_Rollover"`; use `"NO_SOUND"` to not have one
    ---@param rolloverCue? string defaults to `"UI_Mini_MouseDown"`; use `"NO_SOUND"` to not have one
    __init = function(self, parent, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked, disabledChecked, label, labelRight, labelSize, clickCue, rolloverCue)
        Group.__init(self, parent)

        local checkBmp = Bitmap(self, normalUnchecked)
        self.checkBmp = checkBmp

        -- Sound effects
        self.mRolloverCue = rolloverCue or 'UI_Mini_Rollover'
        self.mClickCue = clickCue or 'UI_Mini_MouseDown'

        self._checked = false
        self._controlState = "up"

        self:SetNewTextures(normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked, disabledChecked)

        -- Escape early if the layout is the extremely trivial case...
        if not label then
            self.Width:Set(checkBmp.Width)
            self.Height:Set(checkBmp.Height)
            LayoutHelpers.AtCenterIn(checkBmp, self)
            return
        end

        label = LOC(label)
        local textfield = UIUtil.CreateText(self, label, labelSize or 13, 'Arial', true)
        textfield.Height:Set(checkBmp:Height())
        textfield:SetText(label)

        -- Center the text inside the textfield (which we expand to be the whole height of the control)
        textfield:SetCenteredVertically(true)
        LayoutHelpers.SetDimensions(self, checkBmp.Width() + textfield.Width(), checkBmp.Height())
        if labelRight then
            LayoutHelpers.AtLeftTopIn(checkBmp, self)
            LayoutHelpers.RightOf(textfield, checkBmp)
        else
            LayoutHelpers.AtRightTopIn(checkBmp, self)
            LayoutHelpers.LeftOf(textfield, checkBmp)
        end

        -- Copy for closure
        local enclosingInstance = self

        -- Delegate clicks on the label to the main handler.
        textfield.OnClick = function(control, modifiers)
            enclosingInstance:OnClick(modifiers)
        end

        self.label = textfield
    end,

    ---@param self Checkbox
    ---@param normalUnchecked Lazy<FileName>
    ---@param normalChecked Lazy<FileName>
    ---@param overUnchecked? Lazy<FileName> defaults to `normalUnchecked`
    ---@param overChecked? Lazy<FileName> defaults to `normalChecked`
    ---@param disabledUnchecked? Lazy<FileName> defaults to `normalUnchecked`
    ---@param disabledChecked? Lazy<FileName> defaults to `normalChecked`
    SetNewTextures = function(self, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked, disabledChecked)
        self.checkedStates = {
            up = normalChecked,
            over = overChecked or normalChecked,
            disabled = disabledChecked or normalChecked,
        }

        self.uncheckedStates = {
            up = normalUnchecked,
            over = overUnchecked or normalUnchecked,
            disabled = disabledUnchecked or normalUnchecked,
        }

        -- Trigger a redraw
        self:SetCheck(self._checked, true)
    end,

    ---@param self Checkbox
    ---@param label LocalizedString
    SetLabel = function(self, label)
        self.label:SetText(label)
    end,

    ---@param self Checkbox
    ---@param isChecked boolean
    ---@param skipEvent? boolean if it will skip calling the `OnChecked` event (useful if calling this from there)
    SetCheck = function(self, isChecked, skipEvent)
        self._checked = isChecked

        -- Update the set of textures we're using to show the checkedness.
        if isChecked then
            self._states = self.checkedStates
        else
            self._states = self.uncheckedStates
        end

        self:_UpdateTexture()
        if not skipEvent then
            self:OnCheck(isChecked)
        end
    end,

    ---@param self Checkbox
    ToggleCheck = function(self)
        self:SetCheck(not self._checked)
    end,

    ---@param self Checkbox
    ---@return boolean
    IsChecked = function(self)
        return self._checked
    end,

    ---@param self Checkbox
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        if self._isDisabled then
            return true
        end

        if event.Type == 'MouseEnter' then
            self._controlState = "over"
            self:_UpdateTexture()
            if not  self.mRolloverCue or self.mRolloverCue == "NO_SOUND" then
                return true
            end

            PlaySound(Sound {
                Cue = self.mRolloverCue,
                Bank = "Interface",
            })
        elseif event.Type == 'MouseExit' then
            self._controlState = "up"
            self:_UpdateTexture()
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            self:OnClick(event.Modifiers)
            if self.mClickCue and self.mClickCue ~= "NO_SOUND" then
                PlaySound(Sound {
                    Cue = self.mClickCue,
                    Bank = "Interface",
                })
            end
        end

        return false
    end,

    -- override this method to handle checks
    ---@param self Checkbox
    ---@param checked boolean
    OnCheck = function(self, checked) end,

    -- override this method to handle clicks differently than default (which is ToggleCheck)
    ---@param self Checkbox
    ---@param modifiers EventModifiers
    OnClick = function(self, modifiers)
        self:ToggleCheck()
    end,

    -- Ensure the textfield is enabled/disabled with the checkbox.
    ---@param self Checkbox
    OnDisable = function(self)
        self.checkBmp:Disable()
        if self.label then
            self.label:Disable()
            self.label:SetColor(UIUtil.disabledColor)
        end

        self._controlState = "disabled"
        self:_UpdateTexture()
    end,

    ---@param self Checkbox
    OnEnable = function(self)
        self.checkBmp:Enable()
        if self.label then
            self.label:Enable()
            self.label:SetColor(UIUtil.fontColor)
        end

        self._controlState = "up"
        self:_UpdateTexture()
    end,

    --- Changes the texture of the Bitmap to reflect the current state of this control;
    --- by defaults, sets `checkBmp`'s texture to `_states[_controlState]`
    ---@param self Checkbox
    _UpdateTexture = function(self)
        self.checkBmp:SetTexture(self._states[self._controlState])
    end,
}
