--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local SortUnitsByTech = import("/lua/sim/commands/shared.lua").SortUnitsByTech
local RingUnit = import("/lua/sim/commands/ringing/shared.lua").RingUnit

local InnerBuildOffsets = { { -2, 2 }, { 2, 2 }, { 2, -2 }, { -2, -2 }, }
local AllBuildOffsets = { { -2, 2 }, { 2, 2 }, { 2, -2 }, { -2, -2 }, { -4, 0 }, { 0, 4 }, { 4, 0 }, { 0, -4 }, }

---@param extractor Unit
---@param engineers Unit[]
---@param allFabricators boolean
RingExtractor = function(extractor, engineers, allFabricators)

    ---------------------------------------------------------------------------
    -- defensive programming

    -- confirm we have an extractor
    if (not extractor) or (IsDestroyed(extractor)) then
        return
    end

    -- confirm that we have one engineer that can build the unit
    SortUnitsByTech(engineers)
    local fabricator = engineers[1].Blueprint.BlueprintId:sub(1, 2) .. 'b1104'
    if (not __blueprints[fabricator]) or
        (not engineers[1]:CanBuild(fabricator))
    then
        return
    end

    local offsets = (allFabricators and AllBuildOffsets) or InnerBuildOffsets
    RingUnit(extractor, engineers, offsets, fabricator)
end
