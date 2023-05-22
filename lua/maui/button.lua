local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local UIUtil = import("/lua/ui/uiutil.lua")

---@class Button : Bitmap
---@field mNormal FileName
---@field mActive FileName
---@field mHighlight FileName
---@field mDisabled FileName
---@field mMouseOver boolean
---@field mClickCue string
---@field mRolloverCue string
---@field mDragger? Dragger
Button = ClassUI(Bitmap) {
    ---@param self Button
    ---@param parent Control
    ---@param normal FileName
    ---@param active FileName
    ---@param highlight FileName
    ---@param disabled FileName
    ---@param clickCue FileName
    ---@param rolloverCue any
    ---@param frameRate any
    __init = function(self, parent, normal, active, highlight, disabled, clickCue, rolloverCue, frameRate)
        Bitmap.__init(self, parent, normal)
        self.mNormal = normal
        self.mActive = active
        self.mHighlight = highlight
        self.mDisabled = disabled
        self.mMouseOver = false
        self.mClickCue = clickCue
        self.mRolloverCue = rolloverCue
        if frameRate then
            self:SetFrameRate(frameRate)
        end
        self:SetLoopPingPongPattern()
        self:Loop(true)
    end,

    SetNewTextures = function(self, normal, active, highlight, disabled)
        self.mNormal = normal
        self.mActive = active
        self.mHighlight = highlight
        self.mDisabled = disabled
    end,

    ApplyTextures = function(self)
        if self._isDisabled and self.mDisabled then
            self:SetTexture(self.mDisabled)
        elseif self.mDragger and self.mMouseOver and self.mActive then
            self:SetTexture(self.mActive)
        elseif self.mMouseOver and self.mHighlight then
            self:SetTexture(self.mHighlight)
        elseif self.mNormal then
            self:SetTexture(self.mNormal)
        end
        self:Play()
    end,

    OnDisable = function(self)
        -- it probably makes sense to enable this, but I'll leave the behavior as-is for now
        --self.mMouseOver = false
        --if self.mDragger then
        --    self.mDragger:Destroy()
        --    self.mDragger = nil
        --end
        self:ApplyTextures()
    end,

    OnRolloverEvent = function(self, state)
    end,

    OnEnable = function(self)
        self:ApplyTextures()
    end,

    HandleEvent = function(self, event)
        if self._isDisabled then
            if not self:IsHitTestDisabled() then
                if event.Type == 'MouseEnter' then
                    self.mMouseOver = true
                elseif event.Type == 'MouseExit' then
                    self.mMouseOver = false
                end
            end
            return true
        end

        if event.Type == 'MouseEnter' then
            if self.mDragger then
                self:SetTexture(self.mActive)
                self:OnRolloverEvent('enter')
                self:Play()
            else
                self:SetTexture(self.mHighlight)
                self:OnRolloverEvent('enter')
                self:Play()
                if self.mRolloverCue then
                    PlaySound(Sound({Cue = self.mRolloverCue, Bank = "Interface"}))
                end
            end
            self.mMouseOver = true
            return true
        elseif event.Type == 'MouseExit' then
            self:SetTexture(self.mNormal)
            self:OnRolloverEvent('exit')
            self:Play()
            self.mMouseOver = false
            return true
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local dragger = Dragger()
            dragger.OnRelease = function(dragger, x, y)
                dragger:Destroy()
                self.mDragger = nil
                if self.mMouseOver and not self._isDisabled then
                    self:SetTexture(self.mHighlight)
                    self:OnRolloverEvent('exit')
                    self:OnClick(event.Modifiers)
                    self:Play()
                end
            end
            dragger.OnCancel = function(dragger)
                if self.mMouseOver and not self._isDisabled then
                    self:SetTexture(self.mHighlight)
                    self:Play()
                end
                dragger:Destroy()
                self.mDragger = nil
            end
            self.mDragger = dragger
            if self.mClickCue then
                local sound = Sound({Cue = self.mClickCue, Bank = "Interface",})
                PlaySound(sound)
            end
            self:SetTexture(self.mActive)
            self:OnRolloverEvent('down')
            self:Play()
            PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
            return true
        end

        return false
    end,

    OnClick = function(self, modifiers) end

}

-- CONSIDERED HARMFUL
--- A button that can optionally have its textures "fixed" to some value. This is special-snowflaking
-- for the retarded construction UI, and can probably be got rid of when we think of a better way of
-- doing this. For now this at least gets this bollocks out of the Button class.
---@class FixableButton : Button
FixableButton = ClassUI(Button) {
    SetOverrideTexture = function(self, texture)
        self.textureOverride = texture
    end,

    OverrideHandleEvent = function(self, event)
        if self._isDisabled then
            if not self:IsHitTestDisabled() then
                if event.Type == 'MouseEnter' then
                    self.mMouseOver = true
                elseif event.Type == 'MouseExit' then
                    self.mMouseOver = false
                end
            end
            return true
        end

        if event.Type == 'MouseEnter' then
            if self.mDragger then
                self:OnRolloverEvent('enter')
            else
                self:OnRolloverEvent('enter')
                if self.mRolloverCue then
                    PlaySound(Sound({Cue = self.mRolloverCue, Bank = "Interface"}))
                end
            end
            self.mMouseOver = true
            return true
        elseif event.Type == 'MouseExit' then
            self:OnRolloverEvent('exit')
            self.mMouseOver = false
            return true
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local dragger = Dragger()
            dragger.OnRelease = function(dragger, x, y)
                dragger:Destroy()
                self.mDragger = nil
                if self.mMouseOver and not self._isDisabled then
                    self:OnRolloverEvent('exit')
                    self:OnClick(event.Modifiers)
                end
            end
            dragger.OnCancel = function(dragger)
                dragger:Destroy()
                self.mDragger = nil
            end
            self.mDragger = dragger
            if self.mClickCue then
                PlaySound(Sound({Cue = self.mClickCue, Bank = "Interface"}))
            end
            self:OnRolloverEvent('down')
            PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
            return true
        end

        return false
    end,

    EnableOverride = function(self)
        self:SetTexture(self.textureOverride)
        self.HandleEvent = FixableButton.OverrideHandleEvent
        self.ApplyTextures = function() end
    end,

    DisableOverride = function(self)
        self.HandleEvent = Button.HandleEvent
        self.ApplyTextures = Button.ApplyTextures
        self:ApplyTextures()
    end,

    SetOverrideEnabled = function(self, flag)
        if flag then
            self:EnableOverride()
        else
            self:DisableOverride()
        end
    end,

    GetOverrideEnabled = function(self)
        return self.HandleEvent == FixableButton.OverrideHandleEvent
    end,

    ToggleOverride = function(self)
        self:SetOverrideEnabled(not self:GetOverrideEnabled())
    end
}
