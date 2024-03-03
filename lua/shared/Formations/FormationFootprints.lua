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
local __blueprints = __blueprints
local TableGetn = table.getn

--- Computes the footprint data of a formation.
---@param blueprintCountCache FormationBlueprintCount
---@param blueprintIds BlueprintId[]
---@return number # all size-x footprints combined
---@return number # the smallest size-z footprint
---@return number # the largest size-z footprint
ComputeFootprintData = function(blueprintCountCache, blueprintIds)
    -- local scope for performance
    local __blueprints = __blueprints

    local footprintMinimum = 1000
    local footprintMaximum = 0
    local footprintTotalLength = 0
    for k = 1, TableGetn(blueprintIds) do
        local blueprintId            = blueprintIds[k]
        local blueprintCount         = blueprintCountCache[blueprintId]
        local blueprintFootprintSize = __blueprints[blueprintId].Footprint.SizeX

        if blueprintCount > 0 then
            footprintTotalLength = footprintTotalLength + blueprintCount * blueprintFootprintSize

            if blueprintFootprintSize > footprintMaximum then
                footprintMaximum = blueprintFootprintSize
            end

            if blueprintFootprintSize < footprintMinimum then
                footprintMinimum = blueprintFootprintSize
            end
        end
    end

    return footprintTotalLength, footprintMinimum, footprintMaximum
end
