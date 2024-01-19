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

---@type Luft
local luft = require "luft"

---@type UnitBlueprint[]
local BlueprintUnits = {}

-------------------------------------------------------------------------------
--#region Mock constructors

---@param t table
---@return table
function Sound(t)
    return t
end

---@param t table
---@return table
function RPCSound(t)
    return t
end

---@param bp UnitBlueprint
function UnitBlueprint(bp)
    table.insert(BlueprintUnits, bp)
end

-------------------------------------------------------------------------------

---@type { Files : string[] }
local GeneratedFile = {}
dofile("/tests/blueprints/generated-unit-blueprint-list.lua")

for k, blueprintFile in ipairs(Files) do
    dofile(blueprintFile)
end

local BlueprintIntelNameToOgrids = {
    CloakFieldRadius = 4,
    OmniRadius = 4,
    RadarRadius = 4,
    RadarStealthFieldRadius = 4,
    SonarRadius = 4,
    SonarStealthFieldRadius = 4,
    WaterVisionRadius = 4,
    VisionRadius = 2,
}

luft.describe(
    'Unit blueprints - intel radius values',
    function()
        luft.test_all(
            "Vision radius",
            BlueprintUnits,

            ---@param unitBlueprint UnitBlueprint
            function(unitBlueprint)
                if unitBlueprint.Intel then
                    local visionRadius = unitBlueprint.Intel.VisionRadius
                    if visionRadius and visionRadius > 0 then
                        local visionRadiusOnGrid = math.floor(visionRadius / 2) * 2
                        luft.expect(visionRadiusOnGrid).to.be(visionRadius)
                    end
                end
            end
        )
    end
)
