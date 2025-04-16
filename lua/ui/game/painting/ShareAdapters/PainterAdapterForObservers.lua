--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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

local PainterAdapter = import("/lua/ui/game/painting/ShareAdapters/PainterAdapter.lua").PainterAdapter

--- Do not create an instance of this class directly. Instead, use
--- the factory pattern in the file `PainterAdapterFactory.lua`.
---@class UIPainterAdapterForObservers : UIPainterAdapter
PainterAdapterForObservers = Class(PainterAdapter) {

    AdapterType = 'Observer',

    ---@param self UIPainterAdapterForObservers
    ---@param painter UIPainter
    __init = function(self, painter)
        PainterAdapter.__init(self, painter)

        self:SubscribeToCallback()
        self:SubscribeToChatEvents()
    end,

    --- Shares the brush stroke with all other observers through the chat message mechanic.
    ---@param self UIPainterAdapterForObservers
    ---@param shareablePainting UISharedBrushStroke
    SendShareablePainting = function(self, shareablePainting)
        PainterAdapter.SendShareablePainting(self, shareablePainting)

        self:PublishAsChatMessage(shareablePainting)
    end,
}

---@param painter UIPainter
---@return UIPainterAdapterForObservers
CreatePainterAdapterForObservers = function(painter)
    return PainterAdapterForObservers(painter)
end
