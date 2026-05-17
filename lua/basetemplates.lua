--- The 'Base Templates' defined in this file are used by AI to search for build locations.
--- Coordinate vectors are interpreted as { x, z }.

--- List of building template names from `BuildingTemplates.lua`
---@alias UnitList string[]

--- The first index is of type UnitList, and the rest of type Vector
---@alias BaseTemplateType { [1]: UnitList, [number]: Vector2 }

--- Generates a coordinate grid, where x and z values are within the interval [offset-size, offset+size] (for their respective offsets).
---
--- Coordinates are ordered first by x value then by z value (both smallest first).
---
--- Only generates coordinates of parity (even x, odd z).
---
--- Similar to Style2CoordinateGeneration, differing only in coordinate parity.
---@param unitList UnitList
---@param size integer
---@param offset_x integer
---@param offset_z integer
---@return BaseTemplateType
local Style1CoordinateGeneration = function(unitList, size, offset_x, offset_z)
    local res = { unitList }
    local resIndex = 2
    for i = 0, size do
        for j = 0, size - 1 do
            res[resIndex] = { 2 * i + offset_x - size, 2 * j + offset_z - size + 1 }
            resIndex = resIndex + 1
        end
    end
    return res
end

--- Generates a coordinate grid, where x and z values are within the interval [offset-size, offset+size] (for their respective offsets).
---
--- Coordinates are ordered first by x value then by z value (both smallest first).
---
--- Only generates coordinates of parity (odd x, even z).
---
--- Similar to Style1CoordinateGeneration, differing only in coordinate parity.
---@param unitList UnitList
---@param size integer
---@param offset_x integer
---@param offset_z integer
---@return BaseTemplateType
local Style2CoordinateGeneration = function(unitList, size, offset_x, offset_z)
    local res = { unitList }
    local resIndex = 2
    for i = 0, size - 1 do
        for j = 0, size do
            res[resIndex] = { 2 * i + offset_x - size + 1, 2 * j + offset_z - size }
            resIndex = resIndex + 1
        end
    end
    return res
end

--- Generates a coordinate grid, where x and z values are within the interval [-2\*size, 2\*size].
---
--- Coordinates are ordered as concentric square rings growing out from around the origin, with each ring traced as follows:
--- - 'Bottom side' - i.e. low z, high to low x;
--- - 'Top side' - i.e. high z, low to high x;
--- - 'Right side' - i.e. high x, high to low z;
--- - 'Left side' - i.e. low x, low to high z.
---
--- Only generates coordinates of parity (even x, odd z).
---
--- Similar to Style4CoordinateGeneration, but differs in parity and ordering of sides in each ring.
---@param unitList UnitList
---@param size integer
---@return BaseTemplateType
local Style3CoordinateGeneration = function(unitList, size)
    local res = { unitList }
    local resIndex = 2
    for i = 1, size do
        for j = 0, 2 * i - 2 do
            res[resIndex] = { 2 * i - 2 * j - 2, 1 - 2 * i }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 2 do
            res[resIndex] = { 2 - 2 * i + 2 * j, 2 * i - 1 }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 1 do
            res[resIndex] = { i * 2, 2 * i - 2 * j - 1 }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 1 do
            res[resIndex] = { -i * 2, 1 - 2 * i + 2 * j }
            resIndex = resIndex + 1
        end
    end
    return res
end

--- Generates a coordinate grid, where x and z values are within the interval [-2\*size, 2\*size].
---
--- Coordinates are ordered as concentric square rings growing out from around the origin, with each ring traced as follows:
--- - 'Right side' - i.e. high x, high to low z;
--- - 'Left side' - i.e. low x, low to high z;
--- - 'Bottom side' - i.e. low z, high to low x;
--- - 'Top side' - i.e. high z, low to high x.
---
--- Only generates coordinates of parity (odd x, even z).
---
--- Similar to Style3CoordinateGeneration, but differs in parity and ordering of sides in each ring.
---@param unitList UnitList
---@param size integer
---@return BaseTemplateType
local Style4CoordinateGeneration = function(unitList, size)
    local res = { unitList }
    local resIndex = 2
    for i = 1, size do
        for j = 0, 2 * i - 2 do
            res[resIndex] = { 2 * i - 1, 2 * i - 2 * j - 2 }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 2 do
            res[resIndex] = { 1 - 2 * i, 2 - 2 * i + 2 * j }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 1 do
            res[resIndex] = { 2 * i - 2 * j - 1, -2 * i }
            resIndex = resIndex + 1
        end
        for j = 0, 2 * i - 1 do
            res[resIndex] = { 1 - 2 * i + 2 * j, 2 * i }
            resIndex = resIndex + 1
        end
    end
    return res
end

---@type UnitList
local UnitList1 = {
    'T1EnergyProduction',
    'MassStorage',
    'EnergyStorage',
    'T1MassCreation',
    'T1Resource',
    'T1Radar',
    'T2Radar',
    'T2Resource',
    'T2Resource',
    'T3MassExtraction',
    'T2EnergyProduction',
    'T1HydroCarbon',
    'T2RadarJammer',
    'T3ShieldDefense',
    'T3StrategicMissile',
    'T2AirStagingPlatform',
    'T3Radar',
    'Wall',
    'T1AADefense',
    'T1GroundDefense',
    'T1NavalDefense',
    'T2NavalDefense',
    'T3NavalDefense',
    'T1Sonar',
    'T2Sonar',
    'T3Sonar',
    'T3Optics',
}

---@type UnitList
local UnitList2 = {
    'T2StrategicMissile',
    'T2ShieldDefense',
    'T3StrategicMissileDefense',
    'T2Artillery',
    'T2AADefense',
    'T2GroundDefense',
    'T3GroundDefense',
    'T3AADefense',
    'T2MissileDefense',
    'T1LandFactory',
    'T2LandFactory',
    'T3LandFactory',
    'T3QuantumGate',
    'T1AirFactory',
    'T2AirFactory',
    'T3AirFactory',
    'T1SeaFactory',
    'T2SeaFactory',
    'T3SeaFactory',
    'T2EngineerSupport',
    'T3EnergyProduction',
    'T3Artillery',
    'T4Artillery',
    'T3RapidArtillery',
    'T3MassCreation',
    'T4SatelliteExperimental',
    'T4LandExperimental1',
    'T4LandExperimental2',
    'T4LandExperimental3',
    'T4AirExperimental1',
    'T4SeaExperimental1',
    'T4EconExperimental',
}

---@type UnitList
local UnitListAdjacency = {
    'T1EnergyProduction',
    'MassStorage',
    'EnergyStorage',
    'T1MassCreation',
    'T1Resource',
    'T1Radar',
    'T2Radar',
    'T2Resource',
    'T3Resource',
    'T2StrategicMissile',
    'T2ShieldDefense',
    'T3StrategicMissileDefense',
    'T3Optics',
    'T2Artillery',
    'T2AADefense',
    'T2GroundDefense',
    'T3GroundDefense',
    'T3AADefense',
    'T2MissileDefense',
    'T2EnergyProduction',
    'T1HydroCarbon',
    'T2RadarJammer',
    'T3ShieldDefense',
    'T3StrategicMissile',
    'T1LandFactory',
    'T2LandFactory',
    'T3LandFactory',
    'T3QuantumGate',
    'T1AirFactory',
    'T2AirFactory',
    'T3AirFactory',
    'T1SeaFactory',
    'T2SeaFactory',
    'T3SeaFactory',
    'T3EnergyProduction',
    'T3MassCreation',
    'T3Radar',
    'T2EngineerSupport',
    'T2AirStagingPlatform',
    'T3Artillery',
    'T4Artillery',
    'T3RapidArtillery',
    'T1GroundDefense',
    'Wall',
    'T1AADefense',
    'T1NavalDefense',
    'T2NavalDefense',
    'T3NavalDefense',
    'T1Sonar',
    'T2Sonar',
    'T3Sonar'
}

---@param template BaseTemplateType
---@return { [1]: BaseTemplateType, [2]: BaseTemplateType, [3]: BaseTemplateType, [4]: BaseTemplateType }
local CreateFactionIndexNesting = function(template)
    return { template, template, template, template }
end

BaseTemplates = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 30, 0, 0), Style2CoordinateGeneration(UnitList2, 30, 0, 0) })
MovedTemplates1 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50, -50), Style2CoordinateGeneration(UnitList2, 20, -50, -50) })
MovedTemplates2 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50, 0), Style2CoordinateGeneration(UnitList2, 20, -50, 0) })
MovedTemplates3 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50, 50), Style2CoordinateGeneration(UnitList2, 20, -50, 50) })
MovedTemplates4 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, 0, -50), Style2CoordinateGeneration(UnitList2, 20, 0, -50) })
MovedTemplates5 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, 0, 50), Style2CoordinateGeneration(UnitList2, 20, 0, 50) })
MovedTemplates6 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, 50, -50), Style2CoordinateGeneration(UnitList2, 20, 50, -50) })
MovedTemplates7 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, 50, 0), Style2CoordinateGeneration(UnitList2, 20, 50, 0) })
MovedTemplates8 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, 50, 50), Style2CoordinateGeneration(UnitList2, 20, 50, 50) })
ExpansionBaseTemplates = CreateFactionIndexNesting({ Style3CoordinateGeneration(UnitList1, 10), Style4CoordinateGeneration(UnitList2, 10) })
Adjacency2x2 = CreateFactionIndexNesting({ UnitListAdjacency, { 2, 0 }, { -2, 0 }, { 0, 2 }, { 0, -2 } })
