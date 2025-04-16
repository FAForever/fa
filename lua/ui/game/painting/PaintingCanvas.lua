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
local CreatePainting = import("/lua/ui/game/painting/Painting.lua").CreatePainting

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local PaintingCanvasInstances = TrashBag()

local SyncIdentifier = "PaintingCanvas.lua"

---@alias UIPaintingCanvasActiveInteraction 'Create' | 'Delete' | 'Mute'

---@class UIPaintingCanvasInput
---@field ActiveInteraction UIPaintingCanvasActiveInteraction

--- Responsible for glueing together the painting, the brush stroke and the painting network adapter.
---@class UIPaintingCanvas : Bitmap, DebugComponent, Renderable
---@field Adapter UIPaintingCanvasAdapter
---@field Painting UIPainting
---@field Trash TrashBag
---@field WorldView WorldView                   # Worldview that this canvas is for
---@field InhibitionSet table<string, boolean>  # A set of reasons for the canvas to be disabled.
---@field PaintingBrush UIPaintingBrush
PaintingCanvas = Class(Bitmap, DebugComponent) {

    ---@param self UIPaintingCanvas
    ---@param worldview WorldView
    __init = function(self, worldview)
        Bitmap.__init(self, worldview)

        self.Trash = TrashBag()
        self.Painting = CreatePainting()
        self.Adapter = self.Trash:Add(GetPaintingCanvasAdapter(self))

        self.WorldView = worldview

        -- register us to render
        self.WorldView:RegisterRenderable(self, tostring(self))

        self.InhibitionSet = {}
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
        local gameOption = GetOptions("painting")
        if gameOption == 'on' then
            return true
        elseif gameOption == 'observing' and (IsObserver() or SessionIsReplay()) then
            return true
        end

        return false
    end,

    --- Checks if there are any reasons to be disabled.
    ---@param self UIPaintingCanvas
    IsInhibited = function(self)
        return not table.empty(self.InhibitionSet)
    end,

    --- Lifts a reason to be disabled. Function is idempotent. Calling it twice is the same as calling it once.
    ---@param self UIPaintingCanvas
    ---@param reason string
    LiftInhibition = function(self, reason)
        self.InhibitionSet[reason] = nil
    end,

    --- Adds a reason to be disabled. Function is idempotent. Calling it twice is the same as calling it once. All active paintings are destroyed.
    ---@param self UIPaintingCanvas
    ---@param reason string
    AddInhibition = function(self, reason)
        self.InhibitionSet[reason] = true
        self:CancelBrush()
    end,

    ---------------------------------------------------------------------------
    --#region User interactions with the painting canvas

    --- Responsible for the creation of paintings.
    ---@param self UIPaintingCanvas
    ---@param event KeyEvent
    ---@return boolean
    HandleEvent = function(self, event)
        -- feature: enable/disable painting as a whole
        if not self:IsEnabledByGameOptions() then
            self:CancelBrush()
            return false
        end

        -- feature: do not interact if this canvas is inhibited
        if self:IsInhibited() then
            self:CancelBrush()
            return false
        end

        -- feature: be able to interact with the canvas
        if event.Modifiers.Right then
            if event.Type == 'ButtonPress' then
                self.PaintingBrush = import("/lua/ui/game/painting/PaintingBrush.lua").CreatePaintingBrush(self)
            end
        end

        return false
    end,

    --#endregion

    --- Responsible for rendering all the paintings that are part of this canvas.
    ---@param self UIPaintingCanvas
    ---@param delta any
    OnRender = function(self, delta)
        -- feature: global toggle to enable/disable painting
        if not self:IsEnabledByGameOptions() then
            self:CancelBrush()
            return false
        end

        -- feature: render the brush
        if self.PaintingBrush then
            local ok, msg = pcall(self.PaintingBrush.OnRender, self.PaintingBrush, delta)
            if not ok and self.EnabledErrors then
                WARN(msg)
                self:CancelBrush()
            end
        end

        -- feature: render the painting
        self.Painting:OnRender(delta)
    end,

    --- Cancels the brush, destroying any active painting in the process.
    ---@param self UIPaintingCanvas
    CancelBrush = function(self)
        if self.PaintingBrush then
            self.PaintingBrush:Destroy()
            self.PaintingBrush = nil
        end
    end,
}

--- Aborts all active paintings. As an example, this can be used to stop
--- all active drawing when you enter cinematic mode.
AbortAllActivePaintings = function()
    for k, paintingCanvasInstance in pairs(PaintingCanvasInstances) do
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:CancelBrush()
        end
    end
end

--- Lifts a reason for all paintings to be disabled. Function is idempotent. Calling it twice is the same as calling it once.
---@param reason string     # for example: 'selection'
LiftInhibitionOfAllPaintings = function(reason)
    for k, paintingCanvasInstance in pairs(PaintingCanvasInstances) do
        if not IsDestroyed(paintingCanvasInstance) then
            paintingCanvasInstance:LiftInhibition(reason)
        end
    end
end

--- Adds a reason for all paintings to be disabled. Function is idempotent. Calling it twice is the same as calling it once.
---@param reason string     # for example: 'selection'
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
