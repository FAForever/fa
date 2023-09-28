--******************************************************************************************************
--** Copyright (c) 2022  clyf
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Reticle = import('/lua/ui/controls/reticle.lua').Reticle

local LockZoom = import('/lua/keymap/misckeyactions.lua').lockZoom

--- Mousewheel capture reticle allows us to capture mousewheel input 
--- and update a numeric value with it when a key is held down
--- Includes functionality for a value change callback to update
--- whatever system it is that we're capturing for
---@class MousewheelCaptureReticle : Reticle
---@field captureKey string
---@field captureCallback function
local MousewheelCaptureReticle = ClassUI(Reticle) {

    __init = function(self, parent, data)
        Reticle.__init(self, parent, data)
        self.captureKey = data.captureKey or 'MENU' -- 'MENU' == 'ALT'
        self.captureValue = data.captureValueInit or 0
        self.changedCapturing = false
        self.capturing = false

        -- this callback will update whatever system we're capturing for
        if type(data.captureCallback) == 'function' then
            self.captureCallback = data.captureCallback
        elseif data.captureCallback ~= nil then
            WARN('MousewheelCaptureReticle requires a function for captureCallback')
        end
    end,

    HandleEvent = function(self, event)
        if not self:UpdateCaptureStatus() then
            -- capture key is up, disable collision and bail
            return
        elseif event.Type == 'MouseEnter' then
            -- set our reticle back to what it should be when we start capturing
            -- tell WorldView we're still over the world, because for all other purposes we are
            self.WorldView.CursorOverWorld = true
            GetCursor():SetTexture(UIUtil.GetCursor(self.WorldView.CursorLastIdentifier))
        elseif event.Type == "WheelRotation" then
            -- adjust the value according to the wheel rotation
            if event.WheelRotation > 0 then
                self.captureValue = self.captureValue + 1
            else
                self.captureValue = self.captureValue - 1
            end
            -- update our text value
            -- do our count change callback if it exists
            if self.captureCallback then self.captureCallback(self.captureValue) end
        end
        self:UpdatePosition(event)
    end,

    UpdatePosition = function(self, event)
        if event then
            self.Left:Set(event.MouseX - self.Width()/2)
            self.Top:Set(event.MouseY - self.Height()/2)
        else
            Reticle.UpdatePosition(self)
        end
    end,

    UpdateCaptureStatus = function(self)
        -- try to approximate a standard format for binary states
        -- first, check if our condition is equal to our state variable
        if IsKeyDown(self.captureKey) ~= self.capturing then
            -- if different, set our changed flag and flip our state bool
            self.changedCapturing = true
            self.capturing = not self.capturing
            -- finally, do whatever else needs to be done
            if self.capturing then
                -- enable reading inputs and lock zoom
                self:EnableHitTest()
                LockZoom()
            else
                -- disable reading inputs and unlock zoom
                -- if somebody hits the lock zoom hotkey while we're capturing, we'll be stuck!
                -- just hit the hotkey again! or i'll fix it so it doesn't happen!
                self:DisableHitTest()
                LockZoom()
            end
        end
        return self.capturing
    end,

    OnFrame = function(self, elapsedTime)
        -- our reticle will be hidden if we're not over the world, so only ask for input when it is
        if self.WorldView.CursorOverWorld then
            self:UpdateCaptureStatus()
        end
        Reticle.OnFrame(self, elapsedTime)
    end,
}

--- Test mousewheel capture reticle, displays the current capturing state and count
---@class MousewheelCaptureTestReticle : MousewheelCaptureReticle
MousewheelCaptureTestReticle = ClassUI(MousewheelCaptureReticle) {

    SetLayout = function(self)
        self.captureValuePrefix = UIUtil.CreateText(self, "value: ", 10, UIUtil.bodyFont, true)
        self.captureValueText = UIUtil.CreateText(self, self.captureValue, 10, UIUtil.bodyFont, true)
        LayoutHelpers.RightOf(self.captureValuePrefix, self, 0)
        LayoutHelpers.RightOf(self.captureValueText, self.captureValuePrefix, 0)
    end,

    UpdateDisplay = function(self, mouseWorldPos)
        self.captureValueText:SetText(self.captureValue)
    end,
}