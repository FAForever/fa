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

---@alias UIPainterAdapterType 'Abstract' | 'Observer' | 'Player'

--- Keeps track of all muted peers.
---@type table<string, boolean>
local MutedPeers = {}

--- Represents a shared brush stroke that is send across the network. The data structure is slightly different to reduce network bandwidth.
---@class UISharedBrushStroke
---@field PaintingAdapterIdentifier string
---@field Samples UIBrushStrokeSamples
---@field PeerName? string
---@field ShareId number

--- Generic container to use when sharing paintings
---@class UIShareableBrushStrokeMessage
---@field ShareablePainting UISharedBrushStroke

--- Container to use when sharing paintings through sim callbacks
---@class UIShareableBrushStrokeCallbackMessage : UIShareableBrushStrokeMessage

--- Container to use when sharing paintings through chat messages
---@class UIShareableBrushStrokeChatMessage : UIShareableBrushStrokeMessage
---@field Painting true

---@type number
local UniquePaintingId = 0

---@return number
GetUniquePaintingId = function()
    UniquePaintingId = UniquePaintingId + 1
    return UniquePaintingId
end

--- The painter adapter is responsible for sharing interactions
--- across worldviews and across the network.
---
--- Do not create an instance of this class directly. Instead, use
--- the factory pattern in the file `PainterAdapterFactory.lua`.
---@class UIPainterAdapter : DebugComponent
---@field AdapterType UIPainterAdapterType
---@field Painter UIPainter
PainterAdapter = Class(DebugComponent) {

    AdapterType = 'Abstract',
    SyncCategory = 'SharePaintingBrushStroke',

    ---@param self UIPainterAdapter
    ---@param painter UIPainter
    __init = function(self, painter)
        self.Painter = painter

        CanvasAdapterInstances:Add(self)
    end,

    ---@param self UIPainterAdapter
    Destroy = function(self)
        local identifier = self:GetIdentifier()
        local syncCategory = self.SyncCategory

        -- clean up the sync callback
        RemoveOnSyncHashedCallback(syncCategory, identifier)
    end,

    --- Retrieves the nickname of the local peer.
    ---@param self UIPainterAdapter
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
    ---@param self UIPainterAdapter
    GetIdentifier = function(self)
        -- sanity check
        if not self.Painter then
            if self.EnabledWarnings then
                WARN("Painter or world view is nil!")
            end
        end

        return "PainterAdapter of " .. tostring(self.Painter)
    end,

    ---------------------------------------------------------------------------
    --#region Activity across world views

    --- Mutes a peer. A peer remains muted for the remainder of the session.
    ---@param self UIPainterAdapter
    ---@param author string
    MutePainter = function(self, author)
        -- do not mute ourselves
        local localPeer = self:GetLocalPeerName()
        if author == localPeer then
            return
        end

        local isMuted = MutedPeers[author]
        if not isMuted then
            MutedPeers[author] = true
            print(LOCF("<LOC painting_mute_message>Muted %s for this session", author))
        end

        -- delete all brush strokes across all worldviews
        for k, adapter in CanvasAdapterInstances do
            local painter = adapter.Painter --[[@as UIPainter]]
            painter.Painting:DeleteBrushStrokesOfAuthor(author)
        end
    end,

    --- Checks if a peer is muted.
    ---@param self UIPainterAdapter
    ---@param peer string
    ---@return boolean
    IsPeerMuted = function(self, peer)
        return MutedPeers[peer] == true
    end,

    --- Deletes the brush stroke across all world views.
    ---@param self UIPainterAdapter
    ---@param brushStroke UIBrushStroke
    DeleteBrushStroke = function(self, brushStroke)
        for k, adapter in CanvasAdapterInstances do
            local painter = adapter.Painter --[[@as UIPainter]]
            painter.Painting:DeleteBrushStroke(brushStroke)
        end
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Activity across network and world views

    --- Prepares the brush stroke to be send to all other worldviews and peers.
    ---@param self UIPainterAdapter
    ---@param brushStroke UIBrushStroke
    SharePaintingBrushStroke = function(self, brushStroke)
        -- check if we have something to share
        if table.empty(brushStroke.Samples.CoordinatesX) then
            return
        end

        local sharedBrushStroke = self:ToSharedBrushStroke(brushStroke)
        sharedBrushStroke.PeerName = self:GetLocalPeerName()

        self:SendShareablePainting(sharedBrushStroke)
    end,

    --- Sends a shareable brush stroke to all other worldviews and peers.
    ---
    --- Do not call this class directly. Use `SharePaintingBrushStroke` instead.
    ---@param self UIPainterAdapter
    ---@param sharedBrushStroke UISharedBrushStroke
    SendShareablePainting = function(self, sharedBrushStroke)
        -- send it locally to all adapters
        for k, adapter in CanvasAdapterInstances do
            local painter = adapter.Painter
            if not IsDestroyed(painter) then
                local brushStroke = adapter:FromSharedBrushStroke(sharedBrushStroke)
                painter.Painting:AddBrushStroke(brushStroke)
            end
        end

        -- to be extended by subclasses to send across the network by calling `PublishAsChatMessage` or `PublishAsSimCallback`.
    end,

    --- Computes the color of a shared brush stroke.
    ---@param self UIPainter
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

    --- Converts a shared brush stroke to something that is easier to draw.
    ---
    --- See also `ToSharedBrushStroke` for the publisher side.
    ---@param self UIPainterAdapter
    ---@param sharedBrushStroke UISharedBrushStroke
    ---@return UIBrushStroke
    FromSharedBrushStroke = function(self, sharedBrushStroke)
        local coordinatesX = {}
        local coordinatesY = {}
        local coordinatesZ = {}
        local samplesX = sharedBrushStroke.Samples.CoordinatesX
        local samplesY = sharedBrushStroke.Samples.CoordinatesY
        local samplesZ = sharedBrushStroke.Samples.CoordinatesZ

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

        ---@type UIBrushStrokeSamples
        local samples = {
            CoordinatesX = coordinatesX,
            CoordinatesY = coordinatesY,
            CoordinatesZ = coordinatesZ
        }

        -- color depends on the peer that sent the brush stroke
        local color = DefaultSharedColor
        if sharedBrushStroke.PeerName then
            color = self:ComputeColorOfPeerName(sharedBrushStroke.PeerName) or color
        end

        -- we use import directly for developer convenience: it enables you to reload the file without restarting
        local brushStroke = import('/lua/ui/game/brushStroke/BrushStroke.lua').CreateBrushStroke(samples, color)
        brushStroke.Author = sharedBrushStroke.PeerName
        brushStroke.ShareId = sharedBrushStroke.ShareId
        return brushStroke
    end,

    --- Converts a brush stroke to a something that is easier to share across a network.
    ---
    --- See also `FromSharedBrushStroke` for the subscriber side.
    ---@param self UIPainterAdapter
    ---@param brushStroke UIBrushStroke
    ---@return UISharedBrushStroke
    ToSharedBrushStroke = function(self, brushStroke)
        ---@type UISharedBrushStroke
        local sharedBrushStroke = {
            PaintingAdapterIdentifier = tostring(self),
            Samples = brushStroke.Samples,
            ShareId = GetUniquePaintingId(),
        }

        return sharedBrushStroke
    end,


    --- A rough check to see if a shared brushStroke originates from the local peer.
    ---@param self UIPainterAdapter
    ---@param sharedBrushStroke UISharedBrushStroke
    SharedPaintingIsKnown = function(self, sharedBrushStroke)
        for k, canvasAdapterInstance in CanvasAdapterInstances do
            if tostring(canvasAdapterInstance) == sharedBrushStroke.PaintingAdapterIdentifier then
                return true
            end
        end

        return false
    end,

    ---@param self UIPainterAdapter
    ---@param sharedBrushStroke UISharedBrushStroke
    AddSharedPainting = function(self, sharedBrushStroke)
        -- feature: do not add the same brush stroke twice
        if self:SharedPaintingIsKnown(sharedBrushStroke) then
            return
        end

        -- feature: do not add a brush stroke from a muted peer
        if self:IsPeerMuted(sharedBrushStroke.PeerName) then
            return
        end

        -- do not share paintings to a canvas that is destroyed, it appears this only happens during development.
        if IsDestroyed(self.Painter) then
            return
        end

        local brushStroke = self:FromSharedBrushStroke(sharedBrushStroke)
        self.Painter.Painting:AddBrushStroke(brushStroke)
    end,

    --- Publishes a brush stroke as a callback. Paintings that are published as a callback
    --- are stored in the replay. They're visible when replaying the game. Only players
    --- with an army are able to send sim callbacks.
    ---
    --- See also `SubscribeToCallback` for the subscriber side.
    ---@param self UIPainterAdapter
    ---@param shareablePainting UISharedBrushStroke
    PublishAsCallback = function(self, shareablePainting)
        ---@type UIShareableBrushStrokeCallbackMessage
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
    ---@param self UIPainterAdapter
    SubscribeToCallback = function(self)
        local identifier = self:GetIdentifier()
        local painter = self.Painter
        local syncCategory = self.SyncCategory

        -- feature: share the active brush stroke with all relevant peers
        AddOnSyncHashedCallback(
        ---@param sharedPaintings UIShareableBrushStrokeCallbackMessage[]
            function(sharedPaintings)
                if painter.EnabledSpewing then
                    SPEW(string.format("Received %d brush stroke(s) for %s", table.getsize(sharedPaintings), identifier))
                end

                -- process event
                if not IsDestroyed(painter) then
                    for k = 1, table.getn(sharedPaintings) do
                        local data = sharedPaintings[k]
                        self:AddSharedPainting(data.ShareablePainting)
                    end
                end
            end, syncCategory, identifier
        )
    end,

    --- Publishes a brush stroke as a chat message. Paintings that are published as a chat message are not stored in the replay. And they're also limited in size.
    ---
    --- See also `SubscribeToChatEvents` for the subscriber side.
    ---@param self UIPainterAdapter
    ---@param shareablePainting UISharedBrushStroke
    PublishAsChatMessage = function(self, shareablePainting)

        -- limitation: chat messages have a limited amount of space per
        -- message. Messages send to peers with `SessionSendChatMessage` are
        -- limited in size. The limit appears to be around 4kb. If we exceed
        -- that then `SessionSendChatMessage` will just error out.
        --
        -- There are two options:
        --
        -- - 1) We implement the ability to chop a brush stroke into several messages.
        -- - 2) We limit the size of a brush stroke.
        --
        -- At the moment we take option 2. An active brush stroke will stop adding
        -- samples once it's reached a certain threshold. With normal use,
        -- this guarantees that the brush stroke does not exceed the limit.

        local FindClients = import('/lua/ui/game/chat.lua').FindClients
        local clients = FindClients()

        ---@type UIShareableBrushStrokeChatMessage
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

        import("/lua/ui/game/gamemain.lua").RegisterChatFunc(
        ---@param sender string
        ---@param data UIShareableBrushStrokeChatMessage
            function(sender, data)
                data.ShareablePainting.PeerName = sender

                if self.Painter.EnabledSpewing then
                    SPEW(string.format("Received a brush stroke from %s", tostring(data.ShareablePainting.PeerName)))
                end

                -- share it with all other adapters as we can only subscribe with one.
                for k, canvasAdapterInstance in CanvasAdapterInstances do
                    if not IsDestroyed(canvasAdapterInstance.Painter) then
                        self:AddSharedPainting(data.ShareablePainting)
                    end
                end
            end, "Painting"
        )
    end,

    --#endregion
}
