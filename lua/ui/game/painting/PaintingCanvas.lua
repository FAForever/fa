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

local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local ParseColor = import("/lua/shared/color.lua").ParseColor

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local Instances = {}

local DefaultPaintingDuration = 25
local DefaultPaintingStrokeWidth = 0.15

local SyncIdentifier = "PaintingCanvas.lua"
local SyncCategory = 'SharePainting'

---@class UISharedPainting
---@field Identifier string
---@field Samples UIPaintingSample[]
---@field Color Color
---@field PeerId? number
---@field PeerName? string

--- A painting canvas that is responsible for registering the painting efforts of
--- players. This involves both the painting itself, as the sharing and receiving
--- of paintings from peers.
---@class UIPaintingCanvas : Bitmap, DebugComponent
---@field Trash TrashBag                        # Contains all (active) paintings.
---@field WorldView WorldView                   # Worldview that this canvas is for.
---@field ActivePainting? UIActivePainting      # The active painting of the local peer.
---@field Paintings UIPainting                  # All paintings, including those shared by peers.
PaintingCanvas = Class(Bitmap, DebugComponent) {

    ---@param self UIPaintingCanvas
    ---@param worldview WorldView
    __init = function(self, worldview)
        Bitmap.__init(self, worldview)

        self.Trash = TrashBag()
        self.Paintings = {}
        self.WorldView = worldview
    end,

    ---@param self UIPaintingCanvas
    ---@param worldview WorldView
    __post_init = function(self, worldview)
        LayoutFor(self)
            :Fill(worldview)
            :ResetWidth()
            :ResetHeight()
            :Over(worldview)
            :EnableHitTest()
            :End()
    end,

    ---@param self UIPaintingCanvas
    Destroy = function(self)
        Bitmap.Destroy(self)
        self.Trash:Destroy()
    end,

    ---@param self UIPaintingCanvas
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)

        -- feature: enable/disable the painting feature
        if GetOptions("painting") ~= "on" then
            return false
        end

        local selectedUnits = GetSelectedUnits()
        if not table.empty(selectedUnits) then
            return false
        end
            if not self.ActivePainting then
                -- we use import directly for developer convenience: it enables you to reload the file without restarting
                self.ActivePainting = import('/lua/ui/game/painting/ActivePainting.lua').CreateActivePainting(
                    self.WorldView, self:ComputeColorOfActivePainting()
                )
            end

            self.ActivePainting:AddSample(GetMouseWorldPos())
        end

        if not IsKeyDown(17) then
            if self.ActivePainting then
                SimCallback({
                    Func = SyncCategory,
                    Args = {
                        Identifier = self.ActivePainting.Identifier,
                        Samples = self.ActivePainting.Samples
                    }
                })

                -- turn it into a regular painting
                -- we use import directly for developer convenience: it enables you to reload the file without restarting
                local painting = import('/lua/ui/game/painting/Painting.lua').CreatePainting(
                    self.WorldView,
                    self.ActivePainting.Samples,
                    self.ActivePainting.Color,
                    tonumber(GetOptions('painting_duration')) or DefaultPaintingDuration
                )

                self:AddPainting(painting)

                -- destroy the active painting
                self.ActivePainting:Destroy()
                self.ActivePainting = nil
            end
        end

        return false
    end,

    --- Checks if a painting identifier is already in use. This can be the case
    --- when we receive a shared painting that the local peer created.
    ---@param self UIPaintingCanvas
    ---@param id string
    ---@return boolean
    PaintingIdentifierInUse = function(self, id)
        -- check if we already have this painting
        for k = 1, table.getn(self.Paintings) do
            local painting = self.Paintings[k]
            if painting.Identifier == id then
                return true
            end
        end

        return false
    end,

    --- Checks if a painting has the correct format.
    ---@param self UIPaintingCanvas
    ---@param painting UISharedPainting
    ---@return boolean
    CorrectPaintingFormat = function(self, painting)
        if not painting.Identifier or -- value should exist
            type(painting.Identifier) ~= 'string' -- value should be a string
        then
            if self.EnabledWarnings then
                WARN("Received painting with a malformed identifier")
            end
            return false
        end

        if not painting.Samples or -- value should exist
            type(painting.Samples) ~= 'table' -- value should be a table
        then
            if self.EnabledWarnings then
                WARN("Received painting with malformed samples")
            end

            return false
        end

        return true
    end,

    --- Computes the color of the active painting.
    ---@param self UIPaintingCanvas
    ComputeColorOfActivePainting = function(self)

        -- in this case we just want to use the color of the 
        -- current focus army. This may not always match the
        -- command source, but the color is only visible to 
        -- the person drawing it and not to the rest of the
        -- game.

        local armiesTable = GetArmiesTable().armiesTable
        return armiesTable[GetFocusArmy()].color
    end,

    --- Computes the color of a shared painting.
    ---@param self UIPaintingCanvas
    ---@param sharedPainting UISharedPainting
    ---@return Color
    ComputeColorOfSharedPainting = function(self, sharedPainting)
        local armiesTable = GetArmiesTable().armiesTable

        -- if we receive it from the sim then there will be a command source to match
        if sharedPainting.PeerId then
            for k = 1, table.getn(armiesTable) do
                local armyInfo = armiesTable[k]
                if table.find(armyInfo.authorizedCommandSources, sharedPainting.PeerId) then
                    return armyInfo.color
                end
            end
        end

        -- if we receive it from a chat message then there will be a peer name
        if sharedPainting.PeerName then
            for k = 1, table.getn(armiesTable) do
                local armyInfo = armiesTable[k]
                if armyInfo.nickname == sharedPainting.PeerName then
                    return armyInfo.color
                end
            end
        end

        -- what, how!!
        return 'ffffffff'
    end,

    --- Attempts to add a painting that is shared by peers.
    ---
    --- Since we can not trust our peers (yes, world is tough) there's some additional sanity
    --- checks involved. These may flag a painting to be 'malicious' and therefore ignored.
    ---@param self UIPaintingCanvas
    ---@param sharedPainting UISharedPainting
    AddSharedPainting = function(self, sharedPainting)

        -- feature: enable/disable the painting feature
        if GetOptions("painting") ~= "on" then
            return
        end

        -- do not allow malformed paintings
        if not self:CorrectPaintingFormat(sharedPainting) then
            return
        end

        -- do not allow overwriting and/or duplicate paintings
        if self:PaintingIdentifierInUse(sharedPainting.Identifier) then
            return
        end

        -- do not allow paintings with excessive samples
        if table.getn(sharedPainting.Samples) > 150 then
            return
        end

        local paintingColor = self:ComputeColorOfSharedPainting(sharedPainting)

        -- we use import directly for developer convenience: it enables you to reload the file without restarting
        local painting = import('/lua/ui/game/painting/Painting.lua').CreatePainting(
            self.WorldView, sharedPainting.Samples, paintingColor,
            tonumber(GetOptions('painting_duration')) or DefaultPaintingDuration
        )
        self:AddPainting(painting)
    end,

    --- Adds a painting to the canvas.
    ---@param self UIPaintingCanvas
    ---@param painting UIPainting
    AddPainting = function(self, painting)
        self.Trash:Add(painting)
        table.insert(self.Paintings, painting)
    end,
}

---@param worldview WorldView
---@return UIPaintingCanvas
CreatePaintingCanvas = function(worldview)
    -- create a new instance
    local instance = PaintingCanvas(worldview) --[[@as UIPaintingCanvas]]
    table.insert(Instances, instance)

    -- listen to sync events
    AddOnSyncHashedCallback(
    ---@param sharedPaintings UISharedPainting[]
        function(sharedPaintings)
            if instance.EnabledLogging then
                LOG(string.format("Received %d paintings for %s", table.getsize(sharedPaintings), SyncIdentifier))
            end

            -- process event
            for l, canvas in Instances do
                if not IsDestroyed(canvas) then
                    for k, painting in sharedPaintings do
                        canvas:AddSharedPainting(painting)
                    end
                end
            end
        end, SyncCategory, SyncIdentifier
    )

    return instance
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    print("Reloading painting canvas instances...")

    for k, v in Instances do
        local worldview = v.WorldView

        -- clean up old instances
        v:Destroy()

        -- create new instances
        worldview.PaintingCanvas = newModule.CreatePaintingCanvas(worldview)
    end
end

--- Called by the module manager when this module becomes dirty
function __moduleinfo.OnDirty()
    print("Disk changes detected for painting canvas...")

    -- force a reload
    ForkThread(
        function()
            import("/lua/ui/game/painting/PaintingCanvas.lua")
        end
    )
end

--#endregionGetSingleton
