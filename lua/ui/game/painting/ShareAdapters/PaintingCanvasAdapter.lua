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
local DefaultSharedColor = 'ffffffff'

--- Keeps track of all active canvas adapter instances
local CanvasAdapterInstances = TrashBag()

---@alias UIPaintingCanvasAdapterType 'Abstract' | 'Observer' | 'Player'

--- Generic container to use when sharing paintings
---@class UIShareablePaintingMessage
---@field ShareablePainting UISharedPainting

--- Container to use when sharing paintings through sim callbacks
---@class UIShareablePaintingCallbackMessage : UIShareablePaintingMessage

--- Container to use when sharing paintings through chat messages
---@class UIShareablePaintingChatMessage : UIShareablePaintingMessage
---@field Painting true

--- Do not create an instance of this class directly. Instead, use
--- the factory pattern in the file `PaintingCanvasAdapterFactory.lua`.
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
        -- function exists to not break trashbags.
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

    --- Prepares the painting to be send to all other worldviews and peers.
    ---@param self UIPaintingCanvasAdapter
    ---@param painting UIPainting
    SharePainting = function(self, painting)
        local sharedPainting = self:ToSharedPainting(painting)
        sharedPainting.PeerName = self:GetLocalPeerName()

        self:SendShareablePainting(sharedPainting)
    end,

    --- Sends a shareable painting to all other worldviews and peers.
    ---
    --- Do not call this class directly. Use `SharePainting` instead.
    ---@param self UIPaintingCanvasAdapter
    ---@param sharedPainting UISharedPainting
    SendShareablePainting = function(self, sharedPainting)
        -- send it locally to all adapters
        local painting = self:FromSharedPainting(sharedPainting)
        for k, adapter in CanvasAdapterInstances do
            local paintingCanvas = adapter.PaintingCanvas
            if not IsDestroyed(paintingCanvas) then
                paintingCanvas:AddSharedPainting(painting)
            end
        end

        -- to be extended by subclasses to send across the network
    end,

    --- Converts a painting to a something that is easier to share across a network.
    ---@param self UIPaintingCanvasAdapter
    ---@param painting UIPainting
    ---@return UISharedPainting
    ToSharedPainting = function(self, painting)
        local samplesX = {}
        local samplesY = {}
        local samplesZ = {}

        for k, sample in painting.Samples do
            table.insert(samplesX, sample.Position[1])
            table.insert(samplesY, sample.Position[2])
            table.insert(samplesZ, sample.Position[3])
        end

        ---@type UISharedPainting
        local sharedPainting = {
            SamplesX = samplesX,
            SamplesY = samplesY,
            SamplesZ = samplesZ
        }

        return sharedPainting
    end,

    --- Computes the color of a shared painting.
    ---@param self UIPaintingCanvas
    ---@param peerId number
    ---@return Color?
    ComputeColorOfPeerId = function(self, peerId)
        local armiesTable = GetArmiesTable().armiesTable
        if peerId then
            for k = 1, table.getn(armiesTable) do
                local armyInfo = armiesTable[k]
                if table.find(armyInfo.authorizedCommandSources, peerId) then
                    return armyInfo.color
                end
            end
        end
    end,

    --- Computes the color of a shared painting.
    ---@param self UIPaintingCanvas
    ---@param peerName string
    ---@return Color?
    ComputeColorOfPeerName = function(self, peerName)
        local armiesTable = GetArmiesTable().armiesTable
        for k = 1, table.getn(armiesTable) do
            local armyInfo = armiesTable[k]
            if armyInfo.nickname == peerName then
                return armyInfo.color
            end
        end
    end,

    --- Converts a shared painting to something that is easier to draw.
    ---@param self UIPaintingCanvasAdapter
    ---@param sharedPainting UISharedPainting
    ---@return UIPainting
    FromSharedPainting = function(self, sharedPainting)
        local samples = {}
        local samplesX = sharedPainting.SamplesX
        local samplesY = sharedPainting.SamplesY
        local samplesZ = sharedPainting.SamplesZ

        for k = 1, table.getn(sharedPainting.SamplesX) do
            local sx = samplesX[k]
            local sy = samplesY[k]
            local sz = samplesZ[k]
            if tonumber(sx) and tonumber(sy) and tonumber(sz) then
                table.insert(samples, { Position = { sx, sy, sz } })
            end
        end

        -- color depends on the peer that sent the painting
        local color = DefaultSharedColor
        if sharedPainting.PeerName then
            color = self:ComputeColorOfPeerName(sharedPainting.PeerName) or color
        elseif sharedPainting.PeerId then
            color = self:ComputeColorOfPeerId(sharedPainting.PeerId) or color
        end

        -- we use import directly for developer convenience: it enables you to reload the file without restarting
        local painting = import('/lua/ui/game/painting/Painting.lua').CreatePainting(
            self.PaintingCanvas.WorldView, samples, color)

        return painting
    end,

    --- Subscribe and callback/sync events that are related to paintings.
    ---@param self UIPaintingCanvasAdapter
    SubscribeToSyncEvents = function(self)
        local identifier = self:GetIdentifier()
        local paintingCanvas = self.PaintingCanvas
        local syncCategory = self.SyncCategory

        -- feature: share the active painting with all relevant peers
        AddOnSyncHashedCallback(
        ---@param sharedPaintings UIShareablePaintingCallbackMessage[]
            function(sharedPaintings)
                if paintingCanvas.EnabledSpewing then
                    LOG(string.format("Received %d paintings for %s", table.getsize(sharedPaintings), identifier))
                end

                -- process event
                if not IsDestroyed(paintingCanvas) then
                    for k = 1, table.getn(sharedPaintings) do
                        local data = sharedPaintings[k]
                        local painting = self:FromSharedPainting(data.ShareablePainting)
                        paintingCanvas:AddSharedPainting(painting)
                    end
                end
            end, syncCategory, identifier
        )
    end,

    --- Subscribe to chat events that are related to paintings.
    SubscribeToChatEvents = function(self)

        --- The chat function is relatively limited. It does not allow us to subscribe with multiple functions
        --- to a single identifier. As a result, we cheat a little bit here. All adapters of all world views
        --- try to subscribe with the same identifier. Since only one will end up being used we manually share
        --- that message with all other adapters.

        import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
        ---@param sender string
        ---@param data UIShareablePaintingChatMessage
            function(sender, data)
                data.ShareablePainting.PeerName = sender

                local painting = self:FromSharedPainting(data.ShareablePainting)

                -- share it with all other adapters as we can only subscribe with one.
                for k, canvasAdapterInstance in CanvasAdapterInstances do
                    if not IsDestroyed(canvasAdapterInstance.PaintingCanvas) then
                        canvasAdapterInstance.PaintingCanvas:AddSharedPainting(painting)
                    end
                end
            end, "Painting"
        )
    end,
}
