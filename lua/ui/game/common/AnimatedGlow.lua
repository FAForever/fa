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

---@class UIAnimatedGlow : Bitmap
AnimatedGlow = Class(Bitmap) {

    DebugName = "AnimatedGlow",

    ---@param self UIAnimatedGlow
    ---@param parent Control
    __post_init = function(self, parent, texture)
        LayoutHelpers.LayoutFor(self)
            :Texture(texture)
            :DisableHitTest(true)
            :NeedsFrameUpdate(true)
            :Fill(parent)
            :End()
    end,

    ---@param self UIAnimatedGlow
    ---@param delta number
    OnFrame = function(self, delta)
        if delta then
            local alpha = MATH_Lerp(math.sin(10 * CurrentTime()), -1.0, 1.0, 0.0, 0.5)
            self:SetAlpha(alpha)
        end
    end,
}

---@param parent Control
---@param texture Lazy<FileName> | FileName | string
CreateAnimatedGlow = function(parent, texture)
    local animatedGlow = AnimatedGlow(parent, texture) --[[@as UIAnimatedGlow]]
    return animatedGlow
end
