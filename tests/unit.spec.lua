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
    if bp.Description then
        BlueprintUnits[bp.Description] = { bp }
    end
end

---@param bp MeshBlueprint
function MeshBlueprint(bp)
    return bp
end

-------------------------------------------------------------------------------

---@type { Files : string[] }
local GeneratedFile = {}
dofile("blueprints/generated-unit-blueprint-list.lua")

for k, blueprintFile in ipairs(Files) do
    -- ./units/UEL0301/UEL0301_PersonalShield_mesh.bp
    -- to
    -- ../units/UEL0301/UEL0301_PersonalShield_mesh.bp
    dofile("." .. blueprintFile)
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
        luft.describe_each(
            "%s",
            BlueprintUnits,

            ---@param name string
            ---@param unitBlueprintPacked UnitBlueprint[]
            function(name, unitBlueprintPacked)
                local unitBlueprint = unpack(unitBlueprintPacked)
                if unitBlueprint.Intel then
                    local visionRadius = unitBlueprint.Intel.VisionRadius
                    if visionRadius and visionRadius > 0 then
                        luft.test(
                            "Vision radius",
                            function()
                                local visionRadiusOnGrid = math.floor(visionRadius / 2) * 2
                                luft.expect(visionRadius).to.be(visionRadiusOnGrid)
                            end
                        )
                    end

                    local cloakFieldRadius = unitBlueprint.Intel.CloakFieldRadius
                    if cloakFieldRadius and cloakFieldRadius > 0 then
                        luft.test(
                            "Cloak field radius",
                            function()
                                local cloakFieldRadiusOnGrid = math.floor(cloakFieldRadius / 4) * 4
                                luft.expect(cloakFieldRadius).to.be(cloakFieldRadiusOnGrid)
                            end
                        )
                    end

                    local omniRadius = unitBlueprint.Intel.OmniRadius
                    if omniRadius and omniRadius > 0 then
                        luft.test(
                            "Omni field radius",
                            function()
                                local omniRadiusOnGrid = math.floor(omniRadius / 4) * 4
                                luft.expect(omniRadius).to.be(omniRadiusOnGrid)
                            end
                        )
                    end

                    local radarRadius = unitBlueprint.Intel.RadarRadius
                    if radarRadius and radarRadius > 0 then
                        luft.test(
                            "Radar field radius",
                            function()
                                local radarRadiusOnGrid = math.floor(radarRadius / 4) * 4
                                luft.expect(radarRadius).to.be(radarRadiusOnGrid)
                            end
                        )
                    end

                    local radarStealthFieldRadius = unitBlueprint.Intel.RadarStealthFieldRadius
                    if radarStealthFieldRadius and radarStealthFieldRadius > 0 then
                        luft.test(
                            "Radar stealth field radius",
                            function()
                                local radarStealthFieldRadiusOnGrid = math.floor(radarStealthFieldRadius / 4) * 4
                                luft.expect(radarStealthFieldRadius).to.be(radarStealthFieldRadiusOnGrid)
                            end
                        )
                    end

                    local sonarRadius = unitBlueprint.Intel.SonarRadius
                    if sonarRadius and sonarRadius > 0 then
                        luft.test(
                            "Sonar field radius",
                            function()
                                local sonarRadiusOnGrid = math.floor(sonarRadius / 4) * 4
                                luft.expect(sonarRadius).to.be(sonarRadiusOnGrid)
                            end
                        )
                    end

                    local sonarStealthFieldRadius = unitBlueprint.Intel.SonarStealthFieldRadius
                    if sonarStealthFieldRadius and sonarStealthFieldRadius > 0 then
                        luft.test(
                            "Sonar stealth field radius",
                            function()
                                local sonarStealthFieldRadiusOnGrid = math.floor(sonarStealthFieldRadius / 4) * 4
                                luft.expect(sonarStealthFieldRadius).to.be(sonarStealthFieldRadiusOnGrid)
                            end
                        )
                    end

                    local waterVisionRadius = unitBlueprint.Intel.WaterVisionRadius
                    if waterVisionRadius and waterVisionRadius > 0 then
                        luft.test(
                            "Water vision radius",
                            function()
                                local waterVisionRadiusOnGrid = math.floor(waterVisionRadius / 4) * 4
                                luft.expect(waterVisionRadius).to.be(waterVisionRadiusOnGrid)
                            end
                        )
                    end
                end
            end
        )
    end
)