---@alias BaseTemplateType (string[] | Vector)[]

---@param unitList string[]
---@param size number
---@param offset_i number
---@param offset_j number
---@return BaseTemplateType
local Style1CoordinateGeneration = function(unitList, size, offset_i, offset_j)
    local res = { unitList }
    local resIndex = 2
    for i = 0, size do
        for j = 0, size-1 do
            res[resIndex] = { 2*i+offset_i-size, 2*j+offset_j-size+1, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

---@param unitList string[]
---@param size number
---@param offset_i number
---@param offset_j number
---@return BaseTemplateType
local Style2CoordinateGeneration = function(unitList, size, offset_i, offset_j)
    local res = { unitList }
    local resIndex = 2
    for i = 0, size-1 do
        for j = 0, size do
            res[resIndex] = { 2*i+offset_i-size+1, 2*j+offset_j-size, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

---@param unitList string[]
---@param size number
---@return BaseTemplateType
local Style3CoordinateGeneration = function(unitList, size)
    local res = { unitList }
    local resIndex = 2
    for i = 1, size do
        for j = 0, 2*i-2 do
            res[resIndex] = { 2*i-2*j-2, 1-2*i, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-2 do
            res[resIndex] = { 2-2*i+2*j, 2*i-1, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-1 do
            res[resIndex] = { i*2, 2*i-2*j-1, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-1 do
            res[resIndex] = { -i*2, 1-2*i+2*j, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

---@param unitList string[]
---@param size number
---@return BaseTemplateType
local Style4CoordinateGeneration = function(unitList, size)
    local res = { unitList }
    local resIndex = 2
    for i = 1, size do
        for j = 0, 2*i-2 do
            res[resIndex] = { 2*i-1, 2*i-2*j-2, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-2 do
            res[resIndex] = { 1-2*i, 2-2*i+2*j, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-1 do
            res[resIndex] = { 2*i-2*j-1, -2*i, 0 }
            resIndex = resIndex + 1
        end
        for j = 0, 2*i-1 do
            res[resIndex] = { 1-2*i+2*j, 2*i, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

---@type string[]
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

---@type string[]
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

---@type string[]
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

BaseTemplates =   CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 30,   0,   0), Style2CoordinateGeneration(UnitList2, 30,   0,   0) })
MovedTemplates1 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50, -50), Style2CoordinateGeneration(UnitList2, 20, -50, -50) })
MovedTemplates2 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50,   0), Style2CoordinateGeneration(UnitList2, 20, -50,   0) })
MovedTemplates3 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20, -50,  50), Style2CoordinateGeneration(UnitList2, 20, -50,  50) })
MovedTemplates4 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20,   0, -50), Style2CoordinateGeneration(UnitList2, 20,   0, -50) })
MovedTemplates5 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20,   0,  50), Style2CoordinateGeneration(UnitList2, 20,   0,  50) })
MovedTemplates6 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20,  50, -50), Style2CoordinateGeneration(UnitList2, 20,  50, -50) })
MovedTemplates7 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20,  50,   0), Style2CoordinateGeneration(UnitList2, 20,  50,   0) })
MovedTemplates8 = CreateFactionIndexNesting({ Style1CoordinateGeneration(UnitList1, 20,  50,  50), Style2CoordinateGeneration(UnitList2, 20,  50,  50) })
ExpansionBaseTemplates = CreateFactionIndexNesting({ Style3CoordinateGeneration(UnitList1, 10), Style4CoordinateGeneration(UnitList2, 10) })
Adjacency2x2 = CreateFactionIndexNesting({ UnitListAdjacency, { 2, 0, 0 }, { -2, 0, 0 }, { 0, 2, 0 }, { 0, -2, 0 } })