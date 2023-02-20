
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger

---@alias MauiCheckboxState "normal" | "over" | "disabled"

---@class MauiCheckboxTexture
---@field checked FileName
---@field unchecked FileName

---@class MauiCheckboxStateTextures
---@field normal MauiCheckboxTexture
---@field over MauiCheckboxTexture
---@field disabled MauiCheckboxTexture

---@alias CheckState "checked" | "unchecked"

---@class MauiCheckbox : Bitmap
---@field _checkState CheckState
---@field _controlState MauiCheckboxState
---@field _states MauiCheckboxStateTextures
---
---@field mRolloverCue? string
---@field mClickCue? string
Checkbox = ClassUI(Bitmap) {
    ---@param self MauiCheckbox
    ---@param parent Control
    ---@param normalUnchecked FileName
    ---@param normalChecked FileName
    ---@param overUnchecked FileName
    ---@param overChecked FileName
    ---@param disabledUnchecked FileName
    ---@param disabledChecked FileName
    ---@param clickCue? string 
    ---@param rolloverCue? string
    ---@param debugname? string defaults to `"checkbox"`
    __init = function(self, parent, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked, disabledChecked, clickCue, rolloverCue, debugname)
        Bitmap.__init(self, parent, normalUnchecked, debugname or "checkbox")
        self._states =  {}
        self._states.normal = {}
        self._states.normal.checked = normalChecked
        self._states.normal.unchecked = normalUnchecked
        self._states.over = {}
        self._states.over.checked = overChecked or normalChecked
        self._states.over.unchecked = overUnchecked or normalUnchecked
        self._states.disabled = {}
        self._states.disabled.checked = disabledChecked or normalChecked
        self._states.disabled.unchecked = disabledUnchecked or normalUnchecked
        self.mRolloverCue = rolloverCue
        self.mClickCue = clickCue

        self._checkState = "unchecked"
        self._controlState = "normal"
    end,

    ---@param self MauiCheckbox
    ---@param normalUnchecked FileName
    ---@param normalChecked FileName
    ---@param overUnchecked FileName
    ---@param overChecked FileName
    ---@param disabledUnchecked FileName
    ---@param disabledChecked FileName
    SetNewTextures = function(self, normalUnchecked, normalChecked, overUnchecked, overChecked, disabledUnchecked, disabledChecked)
        self._states.normal.checked = normalChecked
        self._states.normal.unchecked = normalUnchecked
        self._states.over.checked = overChecked or normalChecked
        self._states.over.unchecked = overUnchecked or normalUnchecked
        self._states.disabled.checked = disabledChecked or normalChecked
        self._states.disabled.unchecked = disabledUnchecked or normalUnchecked
        -- update current texture
        self:SetTexture(self._states[self._controlState][self._checkState])
    end,

    ---@param self MauiCheckbox
    ---@param isChecked boolean
    ---@param skipEvent? boolean
    SetCheck = function(self, isChecked, skipEvent)
        if isChecked == true then
            self._checkState = "checked"
        else
            self._checkState = "unchecked"
        end
        self:SetTexture(self._states[self._controlState][self._checkState])
        if not skipEvent then
            self:OnCheck(isChecked)
        end
    end,

    ---@param self MauiCheckbox
    ToggleCheck = function(self)
        if self._checkState == "checked" then
            self:SetCheck(false)
        else
            self:SetCheck(true)
        end
    end,

    ---@param self MauiCheckbox
    IsChecked = function(self)
        return self._checkState == "checked"
    end,

    ---@param self MauiCheckbox
    OnDisable = function(self)
        if self._controlState != "disabled" then
            self._controlState = "disabled"
            self:SetTexture(self._states[self._controlState][self._checkState])
        end
    end,

    ---@param self MauiCheckbox
    OnEnable = function(self)
        if self._controlState != "normal" then
            self._controlState = "normal"
            self:SetTexture(self._states[self._controlState][self._checkState])
        end
    end,

    ---@param self MauiCheckbox
    ---@param event KeyEvent
    HandleEvent = function(self, event)
        local eventHandled = false
        if event.Type == 'MouseEnter' then
            if self._controlState != "disabled" then
                self._controlState = "over"
                self:SetTexture(self._states[self._controlState][self._checkState])
                local rolloverCue = self.mRolloverCue
                if rolloverCue and rolloverCue != "NO_SOUND" then
                    PlaySound(Sound {
                        Cue = rolloverCue,
                        Bank = "Interface",
                    })
                end
                eventHandled = true
            end
        elseif event.Type == 'MouseExit' then
            if self._controlState != "disabled" then
                self._controlState = "normal"
                self:SetTexture(self._states[self._controlState][self._checkState])
                eventHandled = true
            end
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            self:OnClick(event.Modifiers)
            local clickCue = self.mClickCue
            if clickCue and clickCue != "NO_SOUND" then
                PlaySound(Sound {
                    Cue = clickCue,
                    Bank = "Interface",
                })
            end
            eventHandled = true
        end

        return eventHandled
    end,

    --- Override this method to handle checks
    ---@param self MauiCheckbox
    ---@param checked boolean
    OnCheck = function(self, checked) end,

    --- Override this method to handle clicks differently than default (which is ToggleCheck)
    ---@param self MauiCheckbox
    ---@param modifiers EventModifiers
    OnClick = function(self, modifiers)
        self:ToggleCheck()
    end,
}