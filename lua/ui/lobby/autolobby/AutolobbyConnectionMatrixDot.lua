--******************************************************************************************************
--** Copyright (c) 2024 Willem 'Jip' Wijnia
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

local EnumColors = import("/lua/shared/color.lua").EnumColors

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

--- A small dot that represents the connection status between players.
---@class UIAutolobbyConnectionMatrixDot : Bitmap
---@field IsAliveTimestamp number
local AutolobbyConnectionMatrixDot = Class(Bitmap) {

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self.IsAliveTimestamp = 0

        -- initial state
        self:SetConnected(false)
        self:SetStatus('None')
    end,

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param parent Control
    __post_init = function(self, parent)

    end,

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param delta number
    OnFrame = function(self, delta)
        local time = GetSystemTimeSeconds()
        local diff = time - self.IsAliveTimestamp
        self:SetAlpha(math.max(0, 1 - (0.25 * diff)))
    end,

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param isConnected boolean
    SetConnected = function(self, isConnected)
        if isConnected then
            self:SetAlpha(0.9)
        else
            self:SetAlpha(0.5)
        end
    end,

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param status UIPeerStatus
    SetStatus = function(self, status)
        if status == 'None' then
            self:SetSolidColor(EnumColors.AliceBlue)
        elseif status == 'Pending' then
            self:SetSolidColor(EnumColors.Yellow)
        elseif status == 'Connecting' then
            self:SetSolidColor(EnumColors.YellowGreen)
        elseif status == 'Answering' then
            self:SetSolidColor(EnumColors.YellowGreen)
        elseif status == 'Established' then
            self:SetSolidColor(EnumColors.Green)
        elseif status == 'TimedOut' then
            self:SetSolidColor(EnumColors.Red)
        elseif status == 'Errored' then
            self:SetSolidColor(EnumColors.Crimson)
        end
    end,

    ---@param self UIAutolobbyConnectionMatrixDot
    ---@param timestamp number
    SetIsAliveTimestamp = function(self, timestamp)
        self:SetNeedsFrameUpdate(true)
        self.IsAliveTimestamp = timestamp
    end
}

---@param parent Control
---@return UIAutolobbyConnectionMatrixDot
Create = function(parent)
    return AutolobbyConnectionMatrixDot(parent)
end
