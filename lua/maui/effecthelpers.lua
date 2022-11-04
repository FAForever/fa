--*****************************************************************************
--* File: lua/modules/maui/effecthelpers.lua
--* Author: Ted Snook
--* Summary: functions that make cool menu animation effects
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")

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

local pixelScaleFactor = Prefs.GetFromCurrentProfile('options').ui_scale or 1
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

function BottomToTopOpening(group, bottomAnchor, leftAnchor, rightAnchor, topAnchor)
    local curtop = bottomAnchor
    group:SetNeedsFrameUpdate(true)
    group.Left:Set(leftAnchor)
    group.Right:Set(rightAnchor)
    group.Bottom:Set(bottomAnchor)
    group.Top:Set(bottomAnchor)
    group.OnFrame = function(self, elapsedTime)
        if curtop > topAnchor then
            group.Top:Set(curtop)
            curtop = curtop - 10
        else
            group:SetNeedsFrameUpdate(false)
        end
    end
end

function ButtonGrowIn(button)
    local frameLimit = 10
    local frames = 1
    local speedMultiplier = 5

    effectGroup = Group(button)
    effectGroup.Top:Set(button.Top)
    effectGroup.Left:Set(button.Left)
    effectGroup.Right:Set(button.Right)
    effectGroup.Bottom:Set(button.Bottom)
    effectGroup:DisableHitTest()

    local topLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-left.dds'))
    topLeftEffect.Top:Set(button.Top)
    topLeftEffect.Left:Set(button.Left)
    topLeftEffect.Width:Set(0)
    topLeftEffect.Height:Set(0)

    local topRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-right.dds'))
    topRightEffect.Top:Set(button.Top)
    topRightEffect.Right:Set(button.Right)
    topRightEffect.Width:Set(0)
    topRightEffect.Height:Set(0)

    local bottomLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-left.dds'))
    bottomLeftEffect.Bottom:Set(button.Bottom)
    bottomLeftEffect.Left:Set(button.Left)
    bottomLeftEffect.Width:Set(0)
    bottomLeftEffect.Height:Set(0)

    local bottomRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-right.dds'))
    bottomRightEffect.Bottom:Set(button.Bottom)
    bottomRightEffect.Right:Set(button.Right)
    bottomRightEffect.Width:Set(0)
    bottomRightEffect.Height:Set(0)

    effectGroup:SetNeedsFrameUpdate(true)
    effectGroup.OnFrame = function(self, elapsedTime)
        if frames < frameLimit then
            topLeftEffect.Bottom:Set(function() return button.Top() - (frames * speedMultiplier) end)
            topLeftEffect.Right:Set(function() return button.Left() - (frames * speedMultiplier) end)

            topRightEffect.Bottom:Set(function() return button.Top() - (frames * speedMultiplier) end)
            topRightEffect.Left:Set(function() return button.Right() + (frames * speedMultiplier) end)

            bottomLeftEffect.Top:Set(function() return button.Bottom() + (frames * speedMultiplier) end)
            bottomLeftEffect.Right:Set(function() return button.Left() - (frames * speedMultiplier) end)

            bottomRightEffect.Top:Set(function() return button.Bottom() + (frames * speedMultiplier) end)
            bottomRightEffect.Left:Set(function() return button.Right() + (frames * speedMultiplier) end)
            frames = frames + 1
        end
    end
end

function ButtonFlyIn(button)
    local frameLimit = 10
    local frames = 1
    local speedMultiplier = 5

    effectGroup = Group(button)
    effectGroup.Top:Set(button.Top)
    effectGroup.Left:Set(button.Left)
    effectGroup.Right:Set(button.Right)
    effectGroup.Bottom:Set(button.Bottom)
    effectGroup:DisableHitTest()

    local topLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-left.dds'))
    topLeftEffect.Bottom:Set(button.Top)
    topLeftEffect.Right:Set(button.Left)

    local topRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-right.dds'))
    topRightEffect.Bottom:Set(button.Top)
    topRightEffect.Left:Set(button.Right)

    local bottomLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-left.dds'))
    bottomLeftEffect.Top:Set(button.Bottom)
    bottomLeftEffect.Right:Set(button.Left)

    local bottomRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-right.dds'))
    bottomRightEffect.Top:Set(button.Bottom)
    bottomRightEffect.Left:Set(button.Right)


    effectGroup:SetNeedsFrameUpdate(true)
    effectGroup.OnFrame = function(self, elapsedTime)
        if frames < frameLimit then
            topLeftEffect.Bottom:Set(function() return button.Top() + (frames * speedMultiplier) end)
            topLeftEffect.Right:Set(function() return button.Left() + (frames * speedMultiplier) end)

            topRightEffect.Bottom:Set(function() return button.Top() + (frames * speedMultiplier) end)
            topRightEffect.Left:Set(function() return button.Right() - (frames * speedMultiplier) end)

            bottomLeftEffect.Top:Set(function() return button.Bottom() - (frames * speedMultiplier) end)
            bottomLeftEffect.Right:Set(function() return button.Left() + (frames * speedMultiplier) end)

            bottomRightEffect.Top:Set(function() return button.Bottom() - (frames * speedMultiplier) end)
            bottomRightEffect.Left:Set(function() return button.Right() - (frames * speedMultiplier) end)
            frames = frames + 1
        end
    end
end

function ButtonLockIn(button)
    local frameLimit = 10
    local frames = 1
    local frames2 = 1
    local speedMultiplier = 10

    local horzMiddle = math.floor(button.Width() / 2)
    local vertMiddle = math.floor(button.Height() / 2)

    effectGroup = Group(button)
    effectGroup.Top:Set(button.Top)
    effectGroup.Left:Set(button.Left)
    effectGroup.Right:Set(button.Right)
    effectGroup.Bottom:Set(button.Bottom)
    effectGroup:DisableHitTest()

    local topLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-left.dds'))
    topLeftEffect.Bottom:Set(button.Top)
    topLeftEffect.Right:Set(function() return button.Left() + horzMiddle end)

    local topRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_top-right.dds'))
    topRightEffect.Bottom:Set(button.Top)
    topRightEffect.Left:Set(topLeftEffect.Right)

    local bottomLeftEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-left.dds'))
    bottomLeftEffect.Top:Set(button.Bottom)
    bottomLeftEffect.Right:Set(function() return button.Left() + horzMiddle end)

    local bottomRightEffect = Bitmap(effectGroup, UIUtil.UIFile('/widgets/effect_button_bottom-right.dds'))
    bottomRightEffect.Top:Set(button.Bottom)
    bottomRightEffect.Left:Set(bottomLeftEffect.Right)


    effectGroup:SetNeedsFrameUpdate(true)
    effectGroup.OnFrame = function(self, elapsedTime)
        if topLeftEffect.Left() > button.Left() then
            topLeftEffect.Right:Set(function() return (button.Left() + horzMiddle) - (frames * speedMultiplier) end)

            topRightEffect.Left:Set(function() return (button.Left() + horzMiddle) + (frames * speedMultiplier) end)

            bottomLeftEffect.Right:Set(function() return (button.Left() + horzMiddle) - (frames * speedMultiplier) end)

            bottomRightEffect.Left:Set(function() return (button.Left() + horzMiddle) + (frames * speedMultiplier) end)

            frames = frames + 1
        elseif topLeftEffect.Bottom() < (button.Top() + vertMiddle) then
            topLeftEffect.Bottom:Set(function() return button.Top() + (frames2 * speedMultiplier) end)

            topRightEffect.Bottom:Set(function() return button.Top() + (frames2 * speedMultiplier) end)

            bottomLeftEffect.Top:Set(function() return button.Bottom() - (frames2 * speedMultiplier) end)

            bottomRightEffect.Top:Set(function() return button.Bottom() - (frames2 * speedMultiplier) end)

            frames2 = frames2 + 1
        end
    end
end

function HideEffect()
    effectGroup:Hide()
end

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

        if timeAccum >= time then           -- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false) -- turn off frame updates
            self.Left:Set(xVal)             -- snap to the exact intended location. this is done since we can easily go past our intended destination due to inaccuracy in the frame-by-frame interpolation.
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

        if timeAccum >= time then               -- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)     -- turn off frame updates
            self.Width:Set(newWidth)            -- snap to the exact intended dimensions. this is done since we can easily go past our intended size due to inaccuracy in the frame-by-frame interpolation.
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

        if timeAccum >= time then               -- once the accrued time goes over our intended time
            self:SetNeedsFrameUpdate(false)     -- turn off frame updates
            self.Width:Set(newWidth)            -- snap to the exact intended dimensions. this is done since we can easily go past our intended size due to inaccuracy in the frame-by-frame interpolation.
            self.Height:Set(newHeight)
        end

        if frameFunction then frameFunction() end
    end
end

function MoveAndScaleTo(control, newScale, xVal, yVal, time, mode, origin, frameFunction)
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

    if mode == 1 then
        xVal = initialXpos + xVal
        yVal = initialYpos + yVal
    end

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Width:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, newWidth)))
        self.Height:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, newHeight)))
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self.Top:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialYpos, yVal)))

        if origin == 1 then
            self.Left:Set(math.floor(self.Left() + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(self.Top() + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then               -- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)     -- stop frame update
            self.Left:Set(xVal)                 -- snap to the exact intended location and size. this is done since we can easily go past our intended destination/size due to inaccuracy in the frame-by-frame interpolation.
            self.Top:Set(yVal)
            self.Width:Set(newWidth)
            self.Height:Set(newHeight)
        end

        if frameFunction then frameFunction() end
    end
end

function MoveAndSizeTo(control, newWidth, newHeight, xVal, yVal, time, mode, origin, frameFunction)
    -- moves control to a new position and sizes it to the specific dimensions over time
    -- mode sets whether the XY values are absolute positions (0, default) or offsets (1)
    -- origin is top left corner by default, but can be set to center (origin = 1)
    -- if frameFunction exists it will be called after the position is updated

    control:SetNeedsFrameUpdate(true)
    local initialXpos = control.Left()
    local initialYpos = control.Top()
    local initialWidth = control.Width()
    local initialHeight = control.Height()
    local timeAccum = 0

    if mode == 1 then
        xVal = initialXpos + xVal
        yVal = initialYpos + yVal
    end

    control.OnFrame = function(self, elapsedTime)
        timeAccum = timeAccum + elapsedTime
        self.Width:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialWidth, newWidth)))
        self.Height:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialHeight, newHeight)))
        self.Left:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialXpos, xVal)))
        self.Top:Set(math.floor(MATH_Lerp(timeAccum, 0, time, initialYpos, yVal)))

        if origin == 1 then
            self.Left:Set(math.floor(self.Left() + ((initialWidth - self.Width())/2)))
            self.Top:Set(math.floor(self.Top() + ((initialHeight - self.Height())/2)))
        end

        if timeAccum >= time then               -- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)     -- stop frame update
            self.Left:Set(xVal)                 -- snap to the exact intended location and size. this is done since we can easily go past our intended destination/size due to inaccuracy in the frame-by-frame interpolation.
            self.Top:Set(yVal)
            self.Width:Set(newWidth)
            self.Height:Set(newHeight)
        end

        if frameFunction then frameFunction() end
    end
end

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

        if timeAccum >= time then               -- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)     -- stop frame update
            self:SetAlpha(finalAlpha,true)
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

        if timeAccum >= time then               -- once accrued time goes over intended time
            self:SetNeedsFrameUpdate(false)     -- stop frame update
            self:SetAlpha(finalAlpha,true)
            control:Hide()
        end
   end
end

function Pulse(control, time, alphaBtm, alphaTop)
-- fades a control in (alphaTop) and out (alphaBtm) over time (time, in seconds)
-- default is 0 to 1 alpha over 1 second

    local duration = (time or 1) / 2
    local minAlpha = alphaBtm or 0
    local maxAlpha = alphaTop or 1

    local alphaNorm = maxAlpha - minAlpha
    local direction = 1
    local elapsedTime = 0
    local newAlpha = minAlpha

    control:SetAlpha(newAlpha)

    control.OnFrame = function(self, frameTime)
        elapsedTime = elapsedTime + frameTime
        if elapsedTime >= duration then
            direction = direction * -1 -- reverse direction
            elapsedTime = 0
        end
        local timeSlice = frameTime / duration
        newAlpha = newAlpha + (timeSlice * alphaNorm * direction)
        if newAlpha > 1 then
            newAlpha = 1
        elseif newAlpha < 0 then
            newAlpha = 0
        end
        control:SetAlpha(newAlpha)
    end
    control:SetNeedsFrameUpdate(true)
end