--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

--- A small utility class that will 'animate' a bitmap by pulsing it on and off by manipulating its alpha channel.
---@class UIAnimatedGlow : Bitmap
---@field Rate number   # factor to make the animation go faster or slower
AnimatedGlow = Class(Bitmap) {

    __init = function(self, parent, texture, rate)
        Bitmap.__init(self, parent, texture)

        self.Rate = rate
    end,

    ---@param self UIAnimatedGlow
    ---@param parent Control
    __post_init = function(self, parent, texture, rate)
        LayoutHelpers.LayoutFor(self)
            :Texture(texture)
            :DisableHitTest(true)
            :NeedsFrameUpdate(true)
            :Fill(parent)
            :End()
    end,

    --- An 'animation' that will pulse over the current time to influence the opacity of the texture.
    ---@param self UIAnimatedGlow
    ---@param delta number
    OnFrame = function(self, delta)
        if delta then
            local alpha = MATH_Lerp(math.sin(CurrentTime() * self.Rate), -1.0, 1.0, 0.0, 0.5)
            self:SetAlpha(alpha)
        end
    end,
}

--- Create an instance of the animated glow utility class.
---@param parent Control
---@param texture Lazy<FileName> | FileName | string
---@param rate number # factor to make the animation go faster or slower
CreateAnimatedGlow = function(parent, texture, rate)
    local animatedGlow = AnimatedGlow(parent, texture, rate) --[[@as UIAnimatedGlow]]
    return animatedGlow
end
