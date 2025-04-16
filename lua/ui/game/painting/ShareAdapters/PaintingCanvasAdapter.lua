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

--- Keeps track of all muted peers.
---@type table<string, boolean>
local MutedPeers = {}

--- Represents a shared painting that is send across the network. The data structure is slightly different to reduce network bandwidth.
---@class UISharedPainting
---@field PaintingAdapterIdentifier string
---@field Samples UIPaintingSamples
---@field PeerId? number
---@field PeerName? string

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
        local identifier = self:GetIdentifier()
        local syncCategory = self.SyncCategory

        -- clean up the sync callback
        RemoveOnSyncHashedCallback(syncCategory, identifier)
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
        return "PaintingCanvasAdapter of " .. tostring(self.PaintingCanvas.WorldView)
    end,

    --- Prepares the painting to be send to all other worldviews and peers.
    ---@param self UIPaintingCanvasAdapter
    ---@param painting UIPainting
    SharePainting = function(self, painting)
        -- check if we have something to share
        if table.empty(painting.Samples.CoordinatesX) then
            return
        end

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
        for k, adapter in CanvasAdapterInstances do
            local paintingCanvas = adapter.PaintingCanvas
            if not IsDestroyed(paintingCanvas) then
                local painting = adapter:FromSharedPainting(sharedPainting)
                paintingCanvas:AddPainting(painting)
            end
        end

        -- to be extended by subclasses to send across the network by calling `PublishAsChatMessage` or `PublishAsSimCallback`.
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
    ---
    --- See also `ToSharedPainting` for the publisher side.
    ---@param self UIPaintingCanvasAdapter
    ---@param sharedPainting UISharedPainting
    ---@return UIPainting
    FromSharedPainting = function(self, sharedPainting)
        local coordinatesX = {}
        local coordinatesY = {}
        local coordinatesZ = {}
        local samplesX = sharedPainting.Samples.CoordinatesX
        local samplesY = sharedPainting.Samples.CoordinatesY
        local samplesZ = sharedPainting.Samples.CoordinatesZ

        for k = 1, table.getn(samplesX) do
            local sx = samplesX[k]
            local sy = samplesY[k]
            local sz = samplesZ[k]

            -- only keep the valid samples
            if tonumber(sx) and tonumber(sy) and tonumber(sz) then
                table.insert(coordinatesX, sx)
                table.insert(coordinatesY, sy)
                table.insert(coordinatesZ, sz)
            end
        end

        ---@type UIPaintingSamples
        local samples = {
            CoordinatesX = coordinatesX,
            CoordinatesY = coordinatesY,
            CoordinatesZ = coordinatesZ
        }

        -- color depends on the peer that sent the painting
        local color = DefaultSharedColor
        if sharedPainting.PeerName then
            color = self:ComputeColorOfPeerName(sharedPainting.PeerName) or color
        elseif sharedPainting.PeerId then
            color = self:ComputeColorOfPeerId(sharedPainting.PeerId) or color
        end

        -- we use import directly for developer convenience: it enables you to reload the file without restarting
        local painting = import('/lua/ui/game/painting/Painting.lua').CreatePainting(samples, color)
        painting.Author = sharedPainting.PeerName

        return painting
    end,

    --- Converts a painting to a something that is easier to share across a network.
    ---
    --- See also `FromSharedPainting` for the subscriber side.
    ---@param self UIPaintingCanvasAdapter
    ---@param painting UIPainting
    ---@return UISharedPainting
    ToSharedPainting = function(self, painting)
        ---@type UISharedPainting
        local sharedPainting = {
            PaintingAdapterIdentifier = tostring(self),
            Samples = painting.Samples
        }

        return sharedPainting
    end,

    --- Mutes a peer. A peer remains muted for the remainder of the session.
    ---@param self UIPaintingCanvasAdapter
    ---@param peer string
    MutePeer = function(self, peer)
        -- do not mute ourselves
        local localPeer = self:GetLocalPeerName()
        if peer == localPeer then
            return
        end

        local isMuted = MutedPeers[peer]
        if not isMuted then
            MutedPeers[peer] = true
            print("Muted a peer")
        end
    end,

    --- Checks if a peer is muted.
    ---@param self UIPaintingCanvasAdapter
    ---@param peer string
    ---@return boolean
    IsPeerMuted = function(self, peer)
        return MutedPeers[peer] == true
    end,

    ---------------------------------------------------------------------------
    --#region Publisher/Subscriber across network

    --- A rough check to see if a shared painting originates from the local peer.
    ---@param self UIPaintingCanvasAdapter
    ---@param sharedPainting UISharedPainting
    SharedPaintingIsKnown = function(self, sharedPainting)
        for k, canvasAdapterInstance in CanvasAdapterInstances do
            if tostring(canvasAdapterInstance) == sharedPainting.PaintingAdapterIdentifier then
                return true
            end
        end

        return false
    end,

    ---@param self UIPaintingCanvasAdapter
    ---@param sharedPainting UISharedPainting
    AddSharedPainting = function(self, sharedPainting)
        -- feature: do not add the same painting twice
        if self:SharedPaintingIsKnown(sharedPainting) then
            return
        end

        -- feature: do not add a painting from a muted peer
        if self:IsPeerMuted(sharedPainting.PeerName) then
            return
        end

        -- do not share paintings to a canvas that is destroyed, it appears this only happens during development.
        if IsDestroyed(self.PaintingCanvas) then
            return
        end

        local painting = self:FromSharedPainting(sharedPainting)
        self.PaintingCanvas:AddPainting(painting)
    end,

    --- Publishes a painting as a callback. Paintings that are published as a callback
    --- are stored in the replay. They're visible when replaying the game. Only players
    --- with an army are able to send sim callbacks.
    ---
    --- See also `SubscribeToCallback` for the subscriber side.
    ---@param self UIPaintingCanvasObserverAdapter
    ---@param shareablePainting UISharedPainting
    PublishAsCallback = function(self, shareablePainting)
        ---@type UIShareablePaintingCallbackMessage
        local message = {
            ShareablePainting = shareablePainting
        }

        SimCallback({
            Func = self.SyncCategory,
            Args = message
        })
    end,

    --- Subscribe and callback/sync events that are related to paintings.
    ---
    --- See also `PublishAsCallback` for the publisher side.
    ---@param self UIPaintingCanvasAdapter
    SubscribeToCallback = function(self)
        local identifier = self:GetIdentifier()
        local paintingCanvas = self.PaintingCanvas
        local syncCategory = self.SyncCategory

        -- feature: share the active painting with all relevant peers
        AddOnSyncHashedCallback(
        ---@param sharedPaintings UIShareablePaintingCallbackMessage[]
            function(sharedPaintings)
                if paintingCanvas.EnabledSpewing then
                    SPEW(string.format("Received %d painting(s) for %s", table.getsize(sharedPaintings), identifier))
                end

                -- process event
                if not IsDestroyed(paintingCanvas) then
                    for k = 1, table.getn(sharedPaintings) do
                        local data = sharedPaintings[k]
                        self:AddSharedPainting(data.ShareablePainting)
                    end
                end
            end, syncCategory, identifier
        )
    end,

    --- Publishes a painting as a chat message. Paintings that are published as a chat message are not stored in the replay. And they're also limited in size.
    ---
    --- See also `SubscribeToChatEvents` for the subscriber side.
    ---@param self UIPaintingCanvasObserverAdapter
    ---@param shareablePainting UISharedPainting
    PublishAsChatMessage = function(self, shareablePainting)

        -- TODO: chat messages are limited in size. We should have a way to split up a painting into multiple messages.

        local FindClients = import('/lua/ui/game/chat.lua').FindClients
        local clients = FindClients()

        ---@type UIShareablePaintingChatMessage
        local message = {
            Painting = true,
            ShareablePainting = shareablePainting
        }

        SessionSendChatMessage(clients, message)
    end,

    --- Subscribe to chat events that are related to paintings.
    ---
    --- See also `PublishAsChatMessage` for the publisher side.
    SubscribeToChatEvents = function(self)

        -- The chat function is relatively limited. It does not allow us to subscribe with multiple functions
        -- to a single identifier. As a result, we cheat a little bit here. All adapters of all world views
        -- try to subscribe with the same identifier. Since only one will end up being used we manually share
        -- that message with all other adapters.

        -- TODO: chat messages are limited in size. We should have a method to receive multiple messages and combine it into one painting.

        import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
        ---@param sender string
        ---@param data UIShareablePaintingChatMessage
            function(sender, data)
                data.ShareablePainting.PeerName = sender

                if self.PaintingCanvas.EnabledSpewing then
                    SPEW(string.format("Received a painting from %s", tostring(data.ShareablePainting.PeerName)))
                end

                -- share it with all other adapters as we can only subscribe with one.
                for k, canvasAdapterInstance in CanvasAdapterInstances do
                    if not IsDestroyed(canvasAdapterInstance.PaintingCanvas) then
                        self:AddSharedPainting(data.ShareablePainting)
                    end
                end
            end, "Painting"
        )
    end,

    --#endregion
}
