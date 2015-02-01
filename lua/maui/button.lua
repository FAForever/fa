local Bitmap = import('bitmap.lua').Bitmap
local Dragger = import('dragger.lua').Dragger
local UIUtil = import('/lua/ui/uiutil.lua')

Button = Class(Bitmap) {

    __init = function(self, parent, normal, active, highlight, disabled, clickCue, rolloverCue, frameRate, debugname)
        Bitmap.__init(self, parent, normal)
        self:SetName(debugname or "button")
        self.mNormal = normal
        self.mActive = active
        self.mHighlight = highlight
        self.mDisabled = disabled
        self.mMouseOver = false
        self.mClickCue = clickCue
        self.mRolloverCue = rolloverCue
        self.mAltToggledFlag = false
        self.mAltNormal = normal
        self.mAltActive = active
        self.mAltHighlight = highlight
        self.mAltDisabled = disabled
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

    SetUpAltButtons = function(self, normal, active, highlight, disabled)
        self.mAltNormal = normal
        self.mAltActive = active
        self.mAltHighlight = highlight
        self.mAltDisabled = disabled
    end,

    ApplyTextures = function(self)
        if self.mAltToggledFlag then
            if self._isDisabled and self.mAltDisabled then
                self:SetTexture(self.mAltDisabled)
            elseif self.mAltNormal then
                self:SetTexture(self.mAltNormal)
            end
        else
            if self._isDisabled and self.mDisabled then
                self:SetTexture(self.mDisabled)
            elseif self.mNormal then
                self:SetTexture(self.mNormal)
            end
        end
        self:Play()
    end,

    OnAltToggle = function(self)
        if self.mAltToggledFlag then
            self.mAltToggledFlag = false
            self:SetTexture(self.mActive)
        else
            self.mAltToggledFlag = true
            self:SetTexture(self.mAltActive)
        end
        self:Play()
    end,

    OnDisable = function(self)
        self:ApplyTextures()
    end,

    OnRolloverEvent = function(self, state)
    end,

    OnEnable = function(self)
        self:ApplyTextures()
    end,

    HandleEvent = function(self, event)
        if self._isDisabled then
            return true
        end
        local eventHandled = false

        if event.Type == 'MouseEnter' then
            if self.mDragger then
                if self.mAltToggledFlag then
                    self:SetTexture(self.mAltActive)
                else
                    self:SetTexture(self.mActive)
                end
                self:OnRolloverEvent('enter')
                self:Play()
            else
                if self.mAltToggledFlag then
                    self:SetTexture(self.mAltHighlight)
                else
                    self:SetTexture(self.mHighlight)
                end
                self:OnRolloverEvent('enter')
                self:Play()
                if self.mRolloverCue then
                    local sound = Sound({Cue = self.mRolloverCue, Bank = "Interface",})
                    PlaySound(sound)
                end
            end
            self.mMouseOver = true
            eventHandled = true
        elseif event.Type == 'MouseExit' then
            if self.mAltToggledFlag then
                self:SetTexture(self.mAltNormal)
            else
                self:SetTexture(self.mNormal)
            end
            self:OnRolloverEvent('exit')
            self:Play()
            self.mMouseOver = false
            eventHandled = true
        elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
            local dragger = Dragger()
            dragger.OnRelease = function(dragger, x, y)
                dragger:Destroy()
                self.mDragger = nil
                if self.mMouseOver then
                    if self.mAltToggledFlag then
                        self:SetTexture(self.mAltHighlight)
                    else
                        self:SetTexture(self.mHighlight)
                    end
                    self:OnRolloverEvent('exit')
                    self:Play()
                    self:OnClick(event.Modifiers)
                end
            end
            dragger.OnCancel = function(dragger)
                if self.mMouseOver then
                    if self.mAltToggledFlag then
                        self:SetTexture(self.mAltHighlight)
                    else
                        self:SetTexture(self.mHighlight)
                    end
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
            if self.mAltToggledFlag then
                self:SetTexture(self.mAltActive)
            else
                self:SetTexture(self.mActive)
            end
            self:OnRolloverEvent('down')
            self:Play()
            PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
            eventHandled = true
        end

        return eventHandled
    end,

    OnClick = function(self, modifiers) end

}
