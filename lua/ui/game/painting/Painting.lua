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

local DebugComponent = import("/lua/shared/components/DebugComponent.lua").DebugComponent

local DefaultPaintingDuration = 25

--- Responsible for providing an interface to interact with a collection of brush strokes.
---@class UIPainting : DebugComponent, Destroyable
---@field BrushStrokes TrashBag     # All brush strokes, including those shared by peers.
---@field WorldView WorldView
---@field BlockedAuthors table<string, boolean>
Painting = Class(DebugComponent) {

    DefaultPaintingDuration = 25,

    ---@param self UIPainting
    __init = function(self)
        self.BrushStrokes = TrashBag()
        self.BlockedAuthors = {}
    end,

    ---@param self UIPainting
    Destroy = function(self)
        self:OnDestroy()
    end,

    ---@param self UIPainting
    OnDestroy = function(self)
        self.BrushStrokes:Destroy()
    end,

    ---@param self UIPainting
    ---@param delta number
    OnRender = function(self, delta)
        -- render allowed brush strokes
        local blockedAuthors = self.BlockedAuthors
        ---@param brushStroke UIBrushStroke
        for k, brushStroke in self.BrushStrokes do
            if blockedAuthors[brushStroke.Author] then continue end

            local ok, msg = pcall(brushStroke.OnRender, brushStroke, delta)
            if not ok and self.EnabledErrors then
                WARN(msg)
                self.BrushStrokes[k] = nil
            end
        end
    end,

    ---------------------------------------------------------------------------
    --#region Utility functions

    --- Returns the decay duration.
    ---@param self UIPainting
    ---@return number
    GetDecayDuration = function(self)
        local defaultDuration = self.DefaultPaintingDuration
        if IsObserver() then
            return GetOptions('painting_duration_observing') or defaultDuration
        else
            return GetOptions('painting_duration') or defaultDuration
        end
    end,

    --- Returns all brush strokes that are within the given radius at the given coordinates.
    ---@param self UIPainting
    ---@param coordinates Vector
    ---@param radius number
    ---@return UIBrushStroke[]
    GetBrushStrokesAtCoordinates = function(self, coordinates, radius, cache)
        local brushStrokes = cache or {}

        for k, brushStroke in self.BrushStrokes do
            local distanceBoundingBox = brushStroke:DistanceToBoundingBox(coordinates)
            if distanceBoundingBox < radius then
                local distanceToSamples = brushStroke:DistanceTo(coordinates)
                if distanceToSamples < radius then
                    table.insert(brushStrokes, brushStroke)
                end
            end
        end

        return brushStrokes
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Public interface

    --- Adds a brush stroke to the canvas.
    ---@param self UIPainting
    ---@param brushStroke UIBrushStroke
    AddBrushStroke = function(self, brushStroke)
        self.BrushStrokes:Add(brushStroke)

        -- feature: brush strokes decay over time
        brushStroke:StartDecay(self:GetDecayDuration())

        if self.EnabledSpewing then
            SPEW(string.format("Brush strokes:"))
            for k, v in self.BrushStrokes do
                SPEW(string.format(
                    " - %d samples (%d bytes)",
                    table.getn(v.Samples.CoordinatesX),
                    v:ComputeAllocatedBytes()
                ))
            end
        end
    end,

    --- Deletes a single brush stroke by comparing their identifiers.
    ---@param self UIPainting
    ---@param brushStroke UIBrushStroke
    DeleteBrushStroke = function(self, brushStroke)
        for k, otherPainting in self.BrushStrokes do
            if otherPainting.ShareId == brushStroke.ShareId and
                otherPainting.Author == brushStroke.Author
            then
                self.BrushStrokes[k]:Destroy()
                self.BrushStrokes[k] = nil
            end
        end
    end,

    --- Deletes all brush strokes of a given author.
    ---@param self UIPainting
    ---@param author string
    DeleteBrushStrokesOfAuthor = function(self, author)
        for k, brushStroke in self.BrushStrokes do
            if brushStroke.Author == author then
                self.BrushStrokes[k]:Destroy()
                self.BrushStrokes[k] = nil
            end
        end
    end,

    --#endregion
}

---@return UIPainting
CreatePainting = function()
    local painting = Painting() --[[@as UIPainting]]
    return painting
end
