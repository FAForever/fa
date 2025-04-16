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

local PaintingCanvasAdapter = import("/lua/ui/game/painting/ShareAdapters/PaintingCanvasAdapter.lua").PaintingCanvasAdapter

--- Do not create an instance of this class directly. Instead, use 
--- the factory pattern in the file `PaintingCanvasAdapterFactory.lua`.
---@class UIPaintingCanvasAdapterForObservers : UIPaintingCanvasAdapter
PaintingCanvasAdapterForObservers = Class(PaintingCanvasAdapter) {

    AdapterType = 'Observer',

    ---@param self UIPaintingCanvasAdapterForObservers
    ---@param paintingCanvas UIPaintingCanvas
    __init = function(self, paintingCanvas)
        PaintingCanvasAdapter.__init(self, paintingCanvas)

        self:SubscribeToCallback()
        self:SubscribeToChatEvents()
    end,

    --- Shares the painting with all other observers through the chat message mechanic.
    ---@param self UIPaintingCanvasAdapterForObservers
    ---@param shareablePainting UISharedBrushStroke
    SendShareablePainting = function(self, shareablePainting)
        PaintingCanvasAdapter.SendShareablePainting(self, shareablePainting)

        self:PublishAsChatMessage(shareablePainting)
    end,
}

---@param paintingCanvas UIPaintingCanvas
---@return UIPaintingCanvasAdapterForObservers
CreatePaintingCanvasAdapterForObservers = function(paintingCanvas)
    return PaintingCanvasAdapterForObservers(paintingCanvas)
end
