--******************************************************************************************************
--** Copyright (c) 2024 FAForever
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

-- upvalue scope for performance
local MathMax = math.max

---@class FormationScaleParametersOfLayer
---@field GridSizeFraction number
---@field GridSizeAbsolute number
---@field MinSeparationFraction number

---@class FormationScaleParameters
---@field Land FormationScaleParametersOfLayer
---@field Air FormationScaleParametersOfLayer
---@field Naval FormationScaleParametersOfLayer
---@field Submersible FormationScaleParametersOfLayer

--- Various parameters based on the behavior of the engine when there are units of different sizes in a formation.
---@class FormationScaleParametersOfLayer
FormationScaleParameters = {
    Land = {
        GridSizeFraction = 2.75,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 2.25,
    },

    Air = {
        GridSizeFraction = 1.3,
        GridSizeAbsolute = 2,
        MinSeparationFraction = 1,
    },

    Naval = {
        GridSizeFraction = 1.75,
        GridSizeAbsolute = 4,
        MinSeparationFraction = 1.15,
    },

    Submersible = {
        GridSizeFraction = 1.75,
        GridSizeAbsolute = 4,
        MinSeparationFraction = 1.15,
    },
}

--- Computes the scale of the formation to compensate for the behavior of the engine.
---@param formationScaleParametersOfLayer FormationScaleParametersOfLayer
---@param footprintMaximum number
ComputeFormationScale = function(formationScaleParametersOfLayer, footprintMinimum, footprintMaximum)

    -- A distance of 1 in formation coordinates translates to (largestFootprint + 2) in world coordinates.
    -- Unfortunately the engine separates land/naval units from air units and calls the formation function separately for both groups.
    -- That means if a CZAR and some light tanks are selected together, the tank formation will be scaled by the CZAR's size and we can't compensate.

    local gridSize = MathMax(
        footprintMinimum * formationScaleParametersOfLayer.GridSizeFraction,
        footprintMinimum + formationScaleParametersOfLayer.GridSizeAbsolute
    )

    local gridScale = gridSize / (footprintMaximum + 2)

    return gridScale
end
