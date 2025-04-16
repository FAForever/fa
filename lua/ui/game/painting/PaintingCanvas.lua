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

local GetPaintingCanvasAdapter = import('/lua/ui/game/painting/ShareAdapters/PaintingCanvasAdapterFactory.lua').GetPaintingCanvasAdapter

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local PaintingCanvasInstances = TrashBag()

local DefaultPaintingDuration = 25

local SyncIdentifier = "PaintingCanvas.lua"

---@alias UIPaintingCanvasActiveInteraction 'Delete' | 'Mute'

--- A painting canvas that is responsible for registering and painting the artistic efforts of players.
---@class UIPaintingCanvas : Bitmap, DebugComponent, Renderable
---@field Adapter UIPaintingCanvasAdapter
---@field Trash TrashBag                        # Contains all (active) paintings.
---@field WorldView WorldView                   # Worldview that this canvas is for.
---@field ActivePainting? UIActivePainting      # The active painting of the local peer.
---@field Paintings TrashBag                    # All paintings, including those shared by peers.
---@field ActiveInteraction UIPaintingCanvasActiveInteraction?
---@field AbortedActivePainting boolean
---@field InhibitionSet table<string, boolean>  # A set of reasons for the canvas to be disabled.
PaintingCanvas = Class(Bitmap, DebugComponent) {

    ---@param self UIPaintingCanvas
    ---@param worldview WorldView
    __init = function(self, worldview)
        Bitmap.__init(self, worldview)

        self.Trash = TrashBag()
        self.Paintings = self.Trash:Add(TrashBag())
        self.Adapter = self.Trash:Add(GetPaintingCanvasAdapter(self))
        self.Trash:Add(ForkThread(self.AbortActivePaintingThread, self))

        self.WorldView = worldview
        self.AbortedActivePainting = false

        -- register us to render
        self.WorldView:RegisterRenderable(self, tostring(self))

        self.InhibitionSet = {}
        self:SetNeedsFrameUpdate(true)
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

        -- deregister us to render
        self.WorldView:UnregisterRenderable(tostring(self))
    end,

    --- Checks if the painting feature is disabled as a whole.
    IsDisabledByGameOptions = function(self)
        return GetOptions("painting") ~= "on"
    end,

    --- Checks if there are any reasons to be disabled.
    ---@param self UIPaintingCanvas
    IsInhibited = function(self)
        return not table.empty(self.InhibitionSet)
    end,

    --- Lifts a reason to be disabled.
    ---@param self UIPaintingCanvas
    ---@param reason string
    LiftInhibition = function(self, reason)
        self.InhibitionSet[reason] = nil
    end,

    --- Adds a reason to be disabled. This operation is not accumulative. All active paintings are destroyed.
    ---@param self UIPaintingCanvas
    ---@param reason string
    AddInhibition = function(self, reason)
        self.InhibitionSet[reason] = true
        self:DestroyActivePainting()
    end,

    --- Responsible for the deleting of paintings and muting of players.
    ---@param self UIPaintingCanvas
    OnFrame = function(self, delta)
        -- feature: global toggle to enable/disable painting
        if self:IsDisabledByGameOptions() then
            self:DestroyActivePainting()
            return false
        end

        self.ActiveInteraction = nil

        -- feature: do not interact if this canvas is inhibited
        if self:IsInhibited() then
            self:DestroyActivePainting()
            return false
        end

        local KeyCodeAlt = 18
        local KeyCodeCtrl = 17
        if IsKeyDown(KeyCodeAlt) then
            if IsKeyDown(KeyCodeCtrl) then
                self:MutePainters()
                return
            end

            self:DeletePaintings()
            return
        end
    end,

    --- Responsible for the creation of paintings.
    ---@param self UIPaintingCanvas
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        -- feature: enable/disable painting
        if self:IsDisabledByGameOptions() then
            self:DestroyActivePainting()
            return false
        end

        -- feature: do not interact if this canvas is inhibited
        if self:IsInhibited() then
            self:DestroyActivePainting()
            return false
        end

        -- feature: do not paint if we're interacting with paintings
        if self.ActiveInteraction ~= nil then
            self:DestroyActivePainting()
            return false
        end

        self:CreatePaintings(event)

        return false
    end,

    --- Computes the radius to interact with existing paintings, to for example delete them.
    ---@param self UIPaintingCanvas
    ---@return number
    GetInteractionRadius = function(self)
        local worldViewManager = import("/lua/ui/game/worldview.lua")

        -- feature: zoom sensitivity when interacting with existing paintings

        local mouseScreenCoordinates = GetMouseScreenPos()
        local worldView = worldViewManager.GetTopmostWorldViewAt(mouseScreenCoordinates[1], mouseScreenCoordinates[2])
        local radius = 3
        if worldView then
            local camera = GetCamera(worldView._cameraName)
            if camera then
                local zoom = camera:GetZoom()
                if zoom > 200 then
                    radius = radius * zoom * 0.005
                end
            end
        end

        return radius
    end,

    --- Responsible for the deletion of paintings.
    ---@param self UIPaintingCanvas
    DeletePaintings = function(self)
        self.ActiveInteraction = 'Delete'

        -- feature: ability to delete paintings
        local radius = self:GetInteractionRadius()
        local mouseWorldCoordinates = GetMouseWorldPos()
        for k, painting in self.Paintings do
            local distanceBoundingBox = painting:DistanceToBoundingBox(mouseWorldCoordinates)
            if distanceBoundingBox < radius then
                local distanceToSamples = painting:DistanceTo(mouseWorldCoordinates)
                if distanceToSamples < radius then
                    painting:Destroy()
                    self.Paintings[k] = nil
                end
            end
        end
    end,

    --- Responsible for the muting of painters.
    ---@param self UIPaintingCanvas
    MutePainters = function(self)
        self.ActiveInteraction = 'Mute'

        -- feature: ability to mute painters
        local radius = self:GetInteractionRadius()
        -- TODO
    end,

    --- Responsible for the creation of paintings.
    ---@param self UIPaintingCanvas
    ---@param event KeyEvent
    CreatePaintings = function(self, event)
        -- feature: ability to make a painting!
        if event.Type == 'MouseMotion' and event.Modifiers.Right and not self.AbortedActivePainting then
            self:CreateActivePainting()
        end

        -- feature: share the active painting with all relevant peers
        if event.Type == 'ButtonRelease' then
            self.AbortedActivePainting = false

            if self.ActivePainting then
                self:ShareActivePainting()
            end
        end
    end,

    --- Responsible for rendering all the paintings that are part of this canvas.
    ---@param self UIPaintingCanvas
    ---@param delta any
    OnRender = function(self, delta)
        -- feature: global toggle to enable/disable painting
        if self:IsDisabledByGameOptions() then
            self:DestroyActivePainting()
            return false
        end

        -- render the active painting
        if (self.ActivePainting) then
            local ok, msg = pcall(self.ActivePainting.OnRender, self.ActivePainting, delta)
            if not ok and self.EnabledErrors then
                WARN(msg)
                self:DestroyActivePainting()
            end
        end

        -- render all other paintings
        for k, painting in self.Paintings do
            local ok, msg = pcall(painting.OnRender, painting, delta)
            if not ok and self.EnabledErrors then
                WARN(msg)
                self.Paintings[k] = nil
            end
        end

        -- feature: visualize interactions with the canvas
        local interactionRadius = self:GetInteractionRadius()
        local mouseWorldCoordinates = GetMouseWorldPos()
        if self.ActiveInteraction == 'Delete' then
            UI_DrawCircle(mouseWorldCoordinates, interactionRadius, 'FF9D00', 0)
        end

        if self.ActiveInteraction == 'Mute' then
            UI_DrawCircle(mouseWorldCoordinates, interactionRadius, 'FF0000', 0)
        end
    end,

    --- Creates a new active painting, or adds samples to the current active painting.
    ---@param self UIPaintingCanvas
    CreateActivePainting = function(self)
        if not self.ActivePainting then
            -- we use import directly for developer convenience: it enables you to reload the file without restarting
            self.ActivePainting = import('/lua/ui/game/painting/ActivePainting.lua').CreateActivePainting(
                self:ComputeColorOfActivePainting()
            )
        end

        self.ActivePainting:AddSample(GetMouseWorldPos())
    end,

    --- Aborts the active painting and prints a message to the user that it happened.
    ---@param self any
    AbortActivePainting = function(self)
        if self.ActivePainting then

            -- user feedback
            local message = "<LOC painting_cancel_message>Cancelled a painting"
            if Random() < 0.01 then
                message = "<LOC painting_cancel_message_rare>Cancelled that work of art"
            end
            print(LOC(message))

            self:DestroyActivePainting()
        end
    end,

    --- Removes the active painting.
    ---@param self UIPaintingCanvas
    DestroyActivePainting = function(self)
        if self.ActivePainting then
            self.ActivePainting:Destroy()
            self.ActivePainting = nil
        end
    end,

    --- An active thread that checks if the user wants to abort the active painting.
    ---@param self UIPaintingCanvas
    AbortActivePaintingThread = function(self)

        -- feature: be able to cancel the active painting
        while not IsDestroyed(self) do
            local escapePressed = IsKeyDown('ESCAPE')

            -- feature: be able to cancel the active painting
            if escapePressed and self.ActivePainting then
                self.AbortedActivePainting = true
                self:AbortActivePainting()
            end

            WaitFrames(1)
        end
    end,

    --- Shares the active painting with all relevant peers.
    ---@param self UIPaintingCanvas
    ShareActivePainting = function(self)
        if not self.ActivePainting then
            return
        end

        -- share the painting across worldviews and peers. 
        self.Adapter:SharePainting(self.ActivePainting)

        -- cleanup the active painting.
        self:DestroyActivePainting()
    end,

    --- Computes the color of the active painting.
    ---@param self UIPaintingCanvas
    ComputeColorOfActivePainting = function(self)

        -- in this case we just want to use the color of the
        -- current focus army. This may not always match the
        -- command source, but the color is only visible to
        -- the person drawing it and not to the rest of the
        -- peers.

        local armiesTable = GetArmiesTable().armiesTable
        return armiesTable[GetFocusArmy()].color or 'ffffffff'
    end,

    --- Adds a painting to the canvas. 
    --- 
    --- At this stage we need to guarantee that the painting is legitimate.
    ---@param self UIPaintingCanvas
    ---@param painting UIPainting
    AddPainting = function(self, painting)
        -- feature: enable/disable the painting feature
        if self:IsDisabledByGameOptions() then
            return
        end

        self.Paintings:Add(painting)

        -- feature: paintings decay over time
        painting:StartDecay(
            tonumber(GetOptions('painting_duration')) or DefaultPaintingDuration
        )

        if self.EnabledSpewing then
            SPEW("Active paintings:")
            for k, v in self.Paintings do
                SPEW(string.format(
                    " - %s: %d samples (%d bytes)",
                    self.WorldView._cameraName,
                    table.getn(v.Samples.CoordinatesX),
                    v:ComputeAllocatedBytes()
                ))
            end
        end
    end,
}

--- Aborts all active paintings. As an example, this can be used to stop
--- all active drawing when you enter cinematic mode.
AbortAllActivePaintings = function()
    for k, paintingCanvasInstance in pairs(PaintingCanvasInstances) do
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:AbortActivePainting()
        end
    end
end

LiftInhibitionOfAllPaintings = function(reason)
    for k, paintingCanvasInstance in pairs(PaintingCanvasInstances) do
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:LiftInhibition(reason)
        end
    end
end

InhibitAllPaintings = function(reason)
    for k, paintingCanvasInstance in pairs(PaintingCanvasInstances) do
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:AddInhibition(reason)
        end
    end
end

---@param worldview WorldView
---@return UIPaintingCanvas
CreatePaintingCanvas = function(worldview)
    -- create a new instance
    local instance = PaintingCanvas(worldview) --[[@as UIPaintingCanvas]]
    PaintingCanvasInstances:Add(instance)

    -- feature: abort all active paintings when we enter cinematic mode
    AddOnSyncHashedCallback(
        function()
            AbortAllActivePaintings()
        end, "NISMode", SyncIdentifier
    )

    -- feature: abort all active paintings when the local peer switches focus army
    AddOnSyncHashedCallback(
        function()
            AbortAllActivePaintings()
        end, "FocusArmyChanged", SyncIdentifier
    )

    return instance
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    print("Reloading painting canvas instances...")

    for k, v in PaintingCanvasInstances do
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
