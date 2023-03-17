local UIUtil = import("/lua/ui/uiutil.lua")

--* Percentage versus offset
--* Percentages are specified as a float, with 0.00 to 1.00 the normal ranges
--* Percentages can change spacing when dimension is expended.
--*
--* Offsets are specified in pixels for the "base art" size. If the art is
--* scaled (ie large UI mode) this factor will keep the layout correct

--* Store and set the current pixel scale multiplier. This will be used when the
--* artwork is scaled up or down so that offsets scale up and down appropriately.
--* Note that if you add a new layout helper function that uses offsets, you need
--* to scale the offset with this factor or your layout may get funky when the
--* art is changed

local pixelScaleFactor = 1.0
local effectGroup = false
local gameView = UIUtil.CreateScreenGroup(GetFrame(0), "Effect Helper ScreenGroup")

function SetPixelScaleFactor(newFactor)
    pixelScaleFactor = newFactor
end

function GetPixelScaleFactor()
    return pixelScaleFactor
end

--* These functions will set the controls position to be placed relative to
--* its parents dimensions. They are generally most useful for elements that
--* don't change size, they can also be used for controls that stretch
--* to match parent.

function MoveTo(control, xVal, yVal, time, mode, frameFunction)
    -- Move a control to a specified location or offset over a given time period.
    -- The mode parameter sets whether the values are absolute positions (0, default) or offsets (1)
    -- If frameFunction exists it will be called after the position is updated
    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local timeAccum = 0
    if mode == 1 then
        xVal = initialXpos + xVal
        yVal = initialYpos + yVal
    end
    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self.Top:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialYpos, yVal)))

        if timeAccum >= time then			-- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)	-- turn off frame updates
            self.Left:Set(xVal)				-- snap to the exact intended location. this is done since we can easily go past our intended destination due to inaccuracy in the frame-by-frame interpolation.
            self.Top:Set(yVal)
        end

        if frameFunction then frameFunction() end
    end
end

function ScaleTo(control, newScale, time, origin, frameFunction)
    -- scales the control by a percentage (1.0 = 100%) over time
    -- origin is top left corner by default, but can be set to center (origin = 1)
    -- if frameFunction exists it will be called after the position is updated
    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local initialWidth = control.Width()
    local initialHeight = control.Height()
    local timeAccum = 0
    local newWidth = math.floor(initialWidth * newScale)
    local newHeight = math.floor(initialHeight * newScale)

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Width:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, newWidth)))
        self.Height:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, newHeight)))

        if origin == 1 then
            self.Left:Set(math.floor(initialXpos + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(initialYpos + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then 				-- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)		-- turn off frame updates
            self.Width:Set(newWidth)			-- snap to the exact intended dimensions. this is done since we can easily go past our intended size due to inaccuracy in the frame-by-frame interpolation.
            self.Height:Set(newHeight)
        end

        if frameFunction then frameFunction() end
    end
end

function SizeTo(control, newWidth, newHeight, time, origin, frameFunction)
    -- resizes control to new Height/Width over time
    -- origin is top left corner by default, but can be set to center (origin = 1)
    -- if frameFunction exists it will be called after the position is updated
    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local initialWidth = control.Width()
    local initialHeight = control.Height()
    local timeAccum = 0

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Width:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, newWidth)))
        self.Height:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, newHeight)))

        if origin == 1 then
            self.Left:Set(math.floor(initialXpos + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(initialYpos + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then				-- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)		-- turn off frame updates
            self.Width:Set(newWidth)			-- snap to the exact intended dimensions. this is done since we can easily go past our intended size due to inaccuracy in the frame-by-frame interpolation.
            self.Height:Set(newHeight)
        end

        if frameFunction then frameFunction() end
    end
end

function MoveAndScaleTo(control, newScale, xVal, yVal, time, mode, origin, frameFunction, initialAlpha, finalAlpha)
    -- moves control to a new position and scales it by a percentage over time
    -- mode sets whether the XY values are absolute positions (0, default) or offsets (1)
    -- origin is top left corner by default, but can be set to center (origin = 1)
    -- if frameFunction exists it will be called after the position is updated

    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local initialWidth = control.Width()
    local initialHeight = control.Height()
    local timeAccum = 0
    local newWidth = math.floor(initialWidth * newScale)
    local newHeight = math.floor(initialHeight * newScale)

    local iAlpha = initialAlpha
    local fAlpha =  finalAlpha

    if iAlpha or fAlpha then
        control:Show()
        control:SetAlpha(iAlpha,true)
    end

    if mode == 1 then
        xVal = initialXpos + xVal
        yVal = initialYpos + yVal
    end

    control.isMoving = true


    control.OnFrame = function(self, elapsedTime)
        timeAccum = math.min(time, timeAccum + elapsedTime)
        self.Width:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, newWidth)))
        self.Height:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, newHeight)))
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self.Top:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialYpos, yVal)))
        if iAlpha and fAlpha then
            self:SetAlpha(math.min(MATH_Lerp(timeAccum, 0, time, iAlpha, fAlpha), 1),true)
        end

        if origin == 1 then
            self.Left:Set(math.floor(self.Left() + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(self.Top() + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then				-- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)		-- stop frame update
            self.Left:Set(xVal)					-- snap to the exact intended location and size. this is done since we can easily go past our intended destination/size due to inaccuracy in the frame-by-frame interpolation.
            self.Top:Set(yVal)
            self.Width:Set(newWidth)
            self.Height:Set(newHeight)
            if iAlpha and fAlpha then
                self:SetAlpha(fAlpha,true)
                if fAlpha == 0 then
                    self:Hide()
                end
            end
            self.isMoving = false
        end

        if frameFunction then frameFunction() end
    end
end


--MODDED ADDED FADE TO
function MoveAndSizeTo(control, newWidth, newHeight, xVal, yVal, time, mode, origin, frameFunction, initialAlpha, finalAlpha,controlparent)
 if time==0 then
    control.Left:Set(xVal)
       control.Top:Set(yVal)
    control.Width:Set(newWidth)
    control.Height:Set(newHeight)
    if initialAlpha and finalAlpha then	 if finalAlpha == 0 then control:Hide() else control:SetAlpha(finalAlpha,true) end	end
    control:Show()
else
    -- moves control to a new position and sizes it to the specific dimensions over time
    -- mode sets whether the XY values are absolute positions (0, default) or offsets (1)
    -- origin is top left corner by default, but can be set to center (origin = 1)
    -- if frameFunction exists it will be called after the position is updated
--	UIManager.draggerActivation =false
    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local initialWidth = control.Width()
    local initialHeight = control.Height()
    local timeAccum = 0

    local iAlpha = initialAlpha
    local fAlpha =  finalAlpha
    local newAlpha = initialAlpha

    if iAlpha or fAlpha then
        if controlparent then
            controlparent:Show()
            controlparent:SetAlpha(iAlpha,true)
        else
            control:Show()
            control:SetAlpha(iAlpha,true)
        end
    end

    if mode == 1 then
        xVal = initialXpos + xVal
        yVal = initialYpos + yVal
    end

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Right:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, xVal + newWidth)))
        self.Bottom:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, yVal + newHeight)))
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self.Top:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialYpos, yVal)))
        if iAlpha and fAlpha then
            newAlpha = math.min(MATH_Lerp(timeAccum, 0, time, iAlpha, fAlpha), 1),true
            if newAlpha >= 0 then
                if controlparent then
                    controlparent:SetAlpha(newAlpha,true)
                else
                    self:SetAlpha(newAlpha,true)
                end
            end
        end
        --LOG(self.Left())
        if origin == 1 then
            self.Left:Set(math.floor(self.Left() + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(self.Top() + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then				-- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)		-- stop frame update
            self.Left:Set(xVal)					-- snap to the exact intended location and size. this is done since we can easily go past our intended destination/size due to inaccuracy in the frame-by-frame interpolation.
            self.Top:Set(yVal)
            self.Right:Set(xVal + newWidth)
            self.Bottom:Set(yVal + newHeight)
            if iAlpha and fAlpha then
                if controlparent then
                    if fAlpha == 0 then
                        controlparent:Hide()
                    else
                        controlparent:SetAlpha(fAlpha,true)
                    end
                else
                    if fAlpha == 0 then
                        control:Hide()
                    else
                        self:SetAlpha(fAlpha,true)
                    end
                end
            end
            self.isMoving = false
            if frameFunction then frameFunction() end
        end

    end
end
end

--fades a control in, use control.noFade to set a table of children not to fade in
function FadeIn(control, time, initialValue, finalValue)
 -- fades a control in over time
 -- time is specified in seconds
 -- initialValue is the initial alpha (default = 0.0)
 -- finalValue is the final alpha (default = 1.0)
    control:SetNeedsFrameUpdate(true)

    local initAlpha = initialValue or 0.0
    local finalAlpha =  finalValue or 1.0
    local timeAccum = 0

    control:SetAlpha(initAlpha,true)
    control:Show()

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self:SetAlpha(math.min(MATH_Lerp(timeAccum, 0, time, initAlpha, finalAlpha), 1),true)

        if timeAccum >= time then				-- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)		-- stop frame update
            self:SetAlpha(finalAlpha,true)
        end
        if control.noFade then
            for i, subctrl in control.noFade do
                subctrl:SetAlpha(0)
            end
        end

    end
end

function FadeOut(control, time, initialValue, finalValue)
 -- fades a control in over time
 -- time is specified in seconds
 -- initialValue is the initial alpha (default = 1.0)
 -- finalValue is the final alpha (default = 0.0)

    control:SetNeedsFrameUpdate(true)

    local initAlpha = initialValue or 1.0
    local finalAlpha =  finalValue or 0.0
    local timeAccum = 0

    control:SetAlpha(initAlpha,true)
    control:Show()

    control.OnFrame = function(self, elapsedTime)

        timeAccum = timeAccum + elapsedTime
        self:SetAlpha(math.max(MATH_Lerp(timeAccum, 0, time, initAlpha, finalAlpha), 0),true)
        if control.noFade then
            for i, subctrl in control.noFade do
                subctrl:SetAlpha(0)
            end
        end
        if timeAccum >= time then				-- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)		-- stop frame update
            self:SetAlpha(finalAlpha,true)
            if not finalAlpha then
                control:Hide()
            end
        end
   end
end

--mod function
function FadeHide(control, time)
    control:SetNeedsFrameUpdate(true)

    local initAlpha = 1.0
    local finalAlpha =  0.0
    local timeAccum = 0

    control:SetAlpha(initAlpha,true)
    control:Show()

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self:SetAlpha(math.max(MATH_Lerp(timeAccum, 0, time, initAlpha, finalAlpha), 0),true)

        if timeAccum >= time then				-- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)		-- stop frame update
            self:SetAlpha(finalAlpha,true)
            control:Hide()
        end
   end

end

--mod function
function FadeHideAndMoveX(control,time, xVal)
    control:SetNeedsFrameUpdate(true)

    local initAlpha = 1.0
    local finalAlpha =  0.0
    local timeAccum = 0
    local initialXpos = control.Left()
    local timeAccum = 0

    xVal = initialXpos + xVal

    --control:SetAlpha(initAlpha,true)
    --control:Show()

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self:SetAlpha(math.max(MATH_Lerp(timeAccum, 0, time, initAlpha, finalAlpha), 0),true)

        if timeAccum >= time then			-- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)	-- turn off frame updates
            self.Left:Set(xVal)
            self:SetAlpha(finalAlpha,true)
            control:Hide()

        end

    end
end

--mod function
function FadeInAndMoveX(control,time, xVal, initialValue, finalValue,fct)
    control:SetNeedsFrameUpdate(true)

    local initAlpha = initialValue or 0.0
    local finalAlpha =  finalValue or 1.0
    local timeAccum = 0
    local initialXpos = control.Left()
    local timeAccum = 0


    control:SetAlpha(initAlpha,true)
    control:Show()
    if fct then fct:Hide() end

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self:SetAlpha(math.max(MATH_Lerp(timeAccum, 0, time, initAlpha, finalAlpha), 0),true)

        if timeAccum >= time then			-- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)	-- turn off frame updates
            self.Left:Set(xVal)
            self:SetAlpha(finalAlpha,true)


        end

    end
end

function PulseOnceAndFade(control, time, alphaBtm, alphaTop, initialAlpha)
-- fades a control in (alphaTop) and out (alphaBtm) over time (time, in seconds)
-- default is 0 to 1 alpha over 1 second

    local duration = (time or 1) / 2
    local minAlpha = alphaBtm or 0
    local maxAlpha = alphaTop or 1

    local alphaNorm = maxAlpha - minAlpha
    local direction = 1
    local elapsedTime = 0
    local newAlpha = initialAlpha

    control:SetAlpha(newAlpha)

    local repeats = 0

    control.OnFrame = function(self, frameTime)
        elapsedTime = elapsedTime + frameTime
        if elapsedTime >= duration then
            direction = direction * -1 -- reverse direction
            elapsedTime = 0
            repeats = repeats + 1
        end
        local timeSlice = frameTime / duration
        newAlpha = newAlpha + (timeSlice * alphaNorm * direction)
        if newAlpha > 1 then
            newAlpha = 1
            direction = direction * -1 -- reverse direction
            elapsedTime = 0
            repeats = repeats + 1
        elseif newAlpha < 0 then
            newAlpha = 0
        end
        control:SetAlpha(newAlpha)
        if repeats >= 2 then
            control:SetNeedsFrameUpdate(false)
            control:SetAlpha(0)
        end
    end
    control:SetNeedsFrameUpdate(true)
end

-- kept for mod backwards compatibility
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group