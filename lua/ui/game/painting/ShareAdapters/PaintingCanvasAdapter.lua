--******************************************************************************************************
--** Copyright (c) 2025 FAForever
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

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

--- Keeps track of all active canvas adapter instances
local CanvasAdapterInstances = TrashBag()

---@alias UIPaintingCanvasAdapterType 'Abstract' | 'Observer' | 'Player'

---@class UIPaintingCanvasAdapter : DebugComponent
---@field AdapterType UIPaintingCanvasAdapterType
---@field PaintingCanvas UIPaintingCanvas
PaintingCanvasAdapter = Class(DebugComponent) {

    AdapterType = 'Abstract',
    SyncCategory = 'SharePainting',

    ---@param self UIPaintingCanvasAdapter
    ---@param paintingCanvas UIPaintingCanvas
    __init = function(self, paintingCanvas)
        self.PaintingCanvas = paintingCanvas

        CanvasAdapterInstances:Add(self)
        if self.EnabledSpewing then
            SPEW(string.format("Created a canvas adapter of type %s for camera %s", tostring(self.AdapterType), tostring(self.PaintingCanvas.WorldView._cameraName)))
        end
    end,

    ---@param self UIPaintingCanvasAdapter
    Destroy = function(self)

    end,

    --- Retrieves the nickname of the local peer.
    ---@param self UIPaintingCanvasAdapter
    ---@return string
    GetLocalPeerName = function(self)
        local clients = GetSessionClients()
        for k, v in clients do
            if v["local"] then
                return v.name
            end
        end

        return "unknown"
    end,

    --- Computes a unique identifier for this adapter.
    ---@param self UIPaintingCanvasAdapter
    GetIdentifier = function(self)
        return "PaintingCanvasAdapter" .. tostring(self.PaintingCanvas.WorldView)
    end,

    ---@param self UIPaintingCanvasAdapter
    ---@param painting UIPainting
    SharePainting = function(self, painting)
        ---@type UISharedPainting
        local sharedPainting = {
            PaintingIdentifier = painting.PaintingIdentifier,
            PeerName = self:GetLocalPeerName(),
            Samples = painting.Samples
        }

        self:SharePaintingLocally(sharedPainting)

        -- to be extended by subclasses
    end,

    --- Shares a painting between all worldviews of the local peer.
    ---@param self UIPaintingCanvasAdapter
    ---@param painting UISharedPainting
    SharePaintingLocally = function(self, painting)
        for k, adapter in CanvasAdapterInstances do
            local paintingCanvas = adapter.PaintingCanvas
            if not IsDestroyed(paintingCanvas) then
                paintingCanvas:AddSharedPainting(painting)
            end
        end
    end,

    --- Subscribe and callback/sync events that are related to paintings.
    ---@param self UIPaintingCanvasAdapter
    SubscribeToSyncEvents = function(self)
        local identifier = self:GetIdentifier()
        local paintingCanvas = self.PaintingCanvas
        local syncCategory = self.SyncCategory

        -- feature: share the active painting with all relevant peers
        AddOnSyncHashedCallback(
        ---@param sharedPaintings UISharedPainting[]
            function(sharedPaintings)
                if paintingCanvas.EnabledSpewing then
                    LOG(string.format("Received %d paintings for %s", table.getsize(sharedPaintings), identifier))
                end

                -- process event
                if not IsDestroyed(paintingCanvas) then
                    for k, sharedPainting in sharedPaintings do
                        paintingCanvas:AddSharedPainting(sharedPainting)
                    end
                end
            end, syncCategory, identifier
        )
    end,

    --- Subscribe to chat events that are related to paintings.
    SubscribeToChatEvents = function(self)
        import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
        ---@param sender string
        ---@param sharedPainting UISharedPainting
            function(sender, sharedPainting)
                sharedPainting.PeerName = sender
                for k, canvasAdapterInstance in CanvasAdapterInstances do
                    if not IsDestroyed(canvasAdapterInstance.PaintingCanvas) then
                        canvasAdapterInstance.PaintingCanvas:AddSharedPainting(sharedPainting)
                    end
                end
            end, "Painting"
        )
    end,
}
