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

--- A painting canvas that is responsible for registering the painting efforts of
--- players. This involves both the painting itself, as the sharing and receiving
--- of paintings from peers.
---@class UIPaintingCanvas : Bitmap, DebugComponent
---@field Adapter UIPaintingCanvasAdapter
---@field Trash TrashBag                        # Contains all (active) paintings.
---@field WorldView WorldView                   # Worldview that this canvas is for.
---@field ActivePainting? UIActivePainting      # The active painting of the local peer.
---@field Paintings TrashBag                    # All paintings, including those shared by peers.
---@field AbortedActivePainting boolean
PaintingCanvas = Class(Bitmap, DebugComponent) {

    ---@param self UIPaintingCanvas
    ---@param worldview WorldView
    __init = function(self, worldview)
        Bitmap.__init(self, worldview)

        self.Trash = TrashBag()
        self.Paintings = self.Trash:Add(TrashBag())
        self.WorldView = worldview
        self.AbortedActivePainting = false
        self.Adapter = GetPaintingCanvasAdapter(self)

        self.Trash:Add(ForkThread(self.AbortActivePaintingThread, self))
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
        -- feature: enable/disable painting
        if GetOptions("painting") ~= "on" then
            self:DestroyActivePainting()
            return false
        end

        -- limitation: only enable painting when no unit is selected. This limitation enables us
        -- to use a wide range of (mouse) buttons that would otherwise be used by engine functions
        local selectedUnits = GetSelectedUnits()
        if not table.empty(selectedUnits) then
            self:AbortActivePainting()
            return false
        end

        -- feature: be able to make a painting!
        if event.Type == 'MouseMotion' and event.Modifiers.Right and not self.AbortedActivePainting then
            self:CreateActivePainting()
        end

        if event.Type == 'ButtonRelease' then
            self.AbortedActivePainting = false

            -- feature: share the active painting with all relevant peers
            if self.ActivePainting then
                self:ShareActivePainting()
            end
        end

        return false
    end,

    --- Creates a new active painting, or adds samples to the current active painting.
    ---@param self UIPaintingCanvas
    CreateActivePainting = function(self)
        if not self.ActivePainting then
            -- we use import directly for developer convenience: it enables you to reload the file without restarting
            self.ActivePainting = import('/lua/ui/game/painting/ActivePainting.lua').CreateActivePainting(
                self.WorldView, self:ComputeColorOfActivePainting()
            )

            self.ActivePainting:StartRendering()
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
    ---@param skipMessage? boolean
    DestroyActivePainting = function(self, skipMessage)
        if self.ActivePainting then
            self.ActivePainting:Destroy()
            self.ActivePainting = nil
        end
    end,

    --- An active thread that checks if the user wants to abort the active painting.
    ---@param self UIPaintingCanvas
    AbortActivePaintingThread = function(self)
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

        -- turn it into a regular painting
        -- we use import directly for developer convenience: it enables you to reload the file without restarting
        local painting = import('/lua/ui/game/painting/Painting.lua').CreatePainting(
            self.WorldView,
            self.ActivePainting.Samples,
            self.ActivePainting.Color
        )

        self.Adapter:SharePainting(painting)

        -- remove the active painting as we replaced it with a regular painting
        self:DestroyActivePainting()
    end,

    --- Checks if a painting identifier is already in use. This can be the case
    --- when we receive a shared painting that the local peer created.
    ---@param self UIPaintingCanvas
    ---@param id string
    ---@return boolean
    PaintingIdentifierInUse = function(self, id)
        -- check if we already have this painting
        for k = 1, table.getn(self.Paintings) do
            local painting = self.Paintings[k] --[[@as UIPainting]]
            if painting.PaintingIdentifier == id then
                return true
            end
        end

        return false
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

    --- Attempts to add a painting that is shared by peers.
    ---
    --- Since we can not trust our peers (yes, world is tough) there's some additional sanity
    --- checks involved. These may flag a painting to be 'malicious' and therefore ignored.
    ---@param self UIPaintingCanvas
    ---@param painting UIPainting
    AddSharedPainting = function(self, painting)
        -- feature: enable/disable the painting feature
        if GetOptions("painting") ~= "on" then
            return
        end

        -- do not allow overwriting and/or duplicate paintings
        if self:PaintingIdentifierInUse(painting.PaintingIdentifier) then
            return
        end

        -- do not allow paintings with excessive samples
        if table.getn(painting.Samples) > 300 then
            return
        end

        self:AddPainting(painting)
    end,

    --- Adds a painting to the canvas.
    ---@param self UIPaintingCanvas
    ---@param painting UIPainting
    AddPainting = function(self, painting)
        self.Trash:Add(painting)
        self.Paintings:Add(painting)

        -- start rendering the painting
        painting:StartRendering()

        -- start the decay of the painting
        painting:StartDecay(
            tonumber(GetOptions('painting_duration')) or DefaultPaintingDuration
        )

        if self.EnabledSpewing then
            SPEW(
                string.format(
                    "Active paintings for %s: %d (%d bytes)",
                    self.WorldView._cameraName,
                    table.getsize(self.Paintings),
                    debug.allocatedrsize(self.Paintings, { WorldView = true })
                )
            )
        end
    end,
}

--- Aborts all active paintings. As an example, this can be used to stop
--- all active drawing when you enter cinematic mode.
AbortAllActivePaintings = function()
    for k = 1, table.getn(PaintingCanvasInstances) do
        local paintingCanvasInstance = PaintingCanvasInstances[k] --[[@as UIPaintingCanvas]]
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:AbortActivePainting()
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
