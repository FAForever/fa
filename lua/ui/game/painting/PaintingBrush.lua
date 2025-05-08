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

local Dragger = import('/lua/maui/dragger.lua').Dragger
local DraggerInit = Dragger.__init

---@alias UIPaintingBrushType 'Create' | 'Delete' | 'Mute'

--- Responsible for all interactions with a painting.
---@class UIPaintingBrush : Dragger
---@field PaintingCanvas UIPaintingCanvas
---@field ActiveBrushStroke? UIActiveBrushStroke      # The active brush stroke of the local peer.
---@field WorldCoordinates Vector
PaintingBrush = Class(Dragger) {

    ---@param self UIPaintingBrush
    ---@param canvas UIPaintingCanvas
    __init = function(self, canvas)
        DraggerInit(self)

        self.PaintingCanvas = canvas
        self.Trash:Add(ForkThread(self.CancelBrushThread, self))

        -- initial coordinates
        self.WorldCoordinates = GetMouseWorldPos()
    end,

    ---@param self UIPaintingBrush
    OnDestroy = function(self)
        Dragger.OnDestroy(self)

        self:CancelActiveBrushStroke()
    end,

    ---------------------------------------------------------------------------
    --#region Shared utility functions

    --- Determines the type of interaction of the brush with the canvas.
    ---@param self UIPaintingBrush
    ---@return UIPaintingBrushType
    GetBrushType = function(self)
        local KeyCodeAlt = 18
        local KeyCodeCtrl = 17
        if IsKeyDown(KeyCodeAlt) then
            if IsKeyDown(KeyCodeCtrl) then
                return 'Mute'
            end

            return 'Delete'
        end

        return 'Create'
    end,

    --- Computes the radius to interact with existing brush strokes, to for example delete them.
    ---@param self UIPaintingBrush
    ---@return number
    GetBrushRadius = function(self)
        local worldViewManager = import("/lua/ui/game/worldview.lua")

        -- feature: zoom sensitivity when interacting with existing paintings

        local mouseScreenCoordinates = GetMouseScreenPos()
        local worldView = worldViewManager.GetTopmostWorldViewAt(mouseScreenCoordinates[1], mouseScreenCoordinates[2])
        local radius = 3
        if worldView then
            local camera = GetCamera(worldView._cameraName)
            if camera then
                local zoom = camera:GetZoom()
                radius = math.max(radius, zoom * 0.02)
            end
        end

        return radius
    end,

    --#endregion

    --- Computes the color of the active brush stroke.
    ---@param self UIPaintingBrush
    GetColorOfActiveBrushStroke = function(self)

        -- observers are always white
        if IsObserver() then
            return 'ffffffff'
        end

        -- in this case we just want to use the color of the
        -- current focus army. This may not always match the
        -- command source, but the color is only visible to
        -- the person drawing it and not to the rest of the
        -- peers.

        local armiesTable = GetArmiesTable().armiesTable
        return armiesTable[GetFocusArmy()].color or 'ffffffff'
    end,

    --- Creates and adds samples to an active brush stroke.
    ---@param self UIPaintingBrush
    ---@param coordinates Vector
    CreatePaintingAtBrush = function(self, coordinates)
        if not self.ActiveBrushStroke then
            -- we use import directly for developer convenience: it enables you to reload the file without restarting
            self.ActiveBrushStroke = import('/lua/ui/game/painting/ActiveBrushStroke.lua').CreateActiveBrushStroke(
                self:GetColorOfActiveBrushStroke()
            )
        end

        self.ActiveBrushStroke:ProcessSample(coordinates)
    end,

    --- Deletes all brush strokes that the brush is on top of.
    ---@param self UIPaintingBrush
    ---@param coordinates Vector
    ---@param radius number
    DeletePaintingAtBrush = function(self, coordinates, radius)
        self:CancelActiveBrushStroke()

        -- feature: ability to delete paintings

        local paintings = self.PaintingCanvas.Painting:GetBrushStrokesAtCoordinates(coordinates, radius)
        for k, painting in paintings do
            self.PaintingCanvas.Adapter:DeleteBrushStroke(painting)
        end
    end,

    --- Deletes and mutes the author of all brush stroke that the brush is on top of.
    ---@param self UIPaintingBrush
    ---@param coordinates Vector
    ---@param radius number
    MutePaintersOfPaintingAtBrush = function(self, coordinates, radius)
        self:CancelActiveBrushStroke()

        -- feature: ability to mute painters

        local paintings = self.PaintingCanvas.Painting:GetBrushStrokesAtCoordinates(coordinates, radius)
        for k, painting in paintings do
            if painting.Author then
                self.PaintingCanvas.Adapter:MutePainter(painting.Author)
            end
        end
    end,

    --- Called by the engine when the mouse is moved
    ---@param self UIPaintingBrush
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnMove = function(self, x, y)
        -- gather all info
        local brushType = self:GetBrushType()
        local brushRadius = self:GetBrushRadius()
        local brushCoordinates = UnProject(self.PaintingCanvas.WorldView, {x, y})
        self.WorldCoordinates = brushCoordinates

        -- do the work
        if brushType == 'Create' then
            self:CreatePaintingAtBrush(brushCoordinates)
        elseif brushType == 'Delete' then
            self:DeletePaintingAtBrush(brushCoordinates, brushRadius)
        elseif brushType == 'Mute' then
            self:MutePaintersOfPaintingAtBrush(brushCoordinates, brushRadius)
        end
    end,

    --- Called by the engine when the button we're tracking is released.
    ---@param self UIPaintingBrush
    ---@param x number  # x coordinate of screen position
    ---@param y number  # y coordinate of screen position
    OnRelease = function(self, x, y)
        local activeBrushStroke = self.ActiveBrushStroke
        if activeBrushStroke then

            -- only process brushes with at least two samples in there
            if activeBrushStroke:GetSampleCount() > 1 then
                activeBrushStroke:AddLastSample()

                -- simplify the brush stroke and share it
                activeBrushStroke:Simplify()
                self.PaintingCanvas.Adapter:SharePaintingBrushStroke(activeBrushStroke)
            end
        end

        self.PaintingCanvas:CancelBrush()
        self:Destroy()
    end,

    --- Called by the engine when the dragger is cancelled.
    ---@param self UIPaintingBrush
    OnCancel = function(self)
        if self.ActiveBrushStroke then
            -- user feedback
            local message = "<LOC painting_cancel_message>Cancelled a brush stroke"
            if Random() < 0.01 then
                message = "<LOC painting_cancel_message_rare>Cancelled that work of art"
            end
            print(LOC(message))
        end

        self.PaintingCanvas:CancelBrush()
        self:Destroy()
    end,

    ---@param self UIPaintingBrush
    ---@param delta number
    OnRender = function(self, delta)
        if self.ActiveBrushStroke then
            self.ActiveBrushStroke:OnRender(delta)
        end

        -- feature: visualize interactions with the canvas
        local brushRadius = self:GetBrushRadius()
        local brushCoordinates = self.WorldCoordinates
        local brushType = self:GetBrushType()
        if brushType == 'Create' then
            UI_DrawCircle(brushCoordinates, 0, self:GetColorOfActiveBrushStroke(), 0)
        elseif brushType == 'Delete' then
            UI_DrawCircle(brushCoordinates, brushRadius, 'FF9D00', 0)
        elseif brushType == 'Mute' then
            UI_DrawCircle(brushCoordinates, brushRadius, 'FF0000', 0)
        end
    end,

    --- The logic that determines the brush should be cancelled.
    ---@param self UIPaintingBrush
    ---@return boolean
    ShouldCancelBrush = function(self)
        return IsKeyDown('ESCAPE')
    end,

    --- A thread that checks if the active brush stroke should be cancelled.
    ---@param self UIPaintingBrush
    CancelBrushThread = function(self)
        -- feature: be able to cancel the active painting
        while not IsDestroyed(self) do
            if self:ShouldCancelBrush() then
                self:OnCancel()
            end

            WaitFrames(1)
        end
    end,

    --- Cancels the active brush stroke.
    ---@param self UIPaintingBrush
    CancelActiveBrushStroke = function(self)
        if self.ActiveBrushStroke then
            self.ActiveBrushStroke:Destroy()
            self.ActiveBrushStroke = nil
        end
    end,
}

---@param canvas UIPaintingCanvas
CreatePaintingBrush = function(canvas)
    local brush = PaintingBrush(canvas) --[[@as UIPaintingBrush]]
    PostDragger(canvas:GetRootFrame(), 'RBUTTON', brush)
    return brush
end
