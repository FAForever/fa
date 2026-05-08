local Style1CoordinateGeneration = function(initialEntry, n, offset_i, offset_j)
    local res = { initialEntry }
    local resIndex = 2
    for i = 0, n do
        for j = 0, n-1 do
            res[resIndex] = { 2*i+offset_i-n, 2*j+offset_j-n+1, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

local Style2CoordinateGeneration = function(initialEntry, n, offset_i, offset_j)
    local res = { initialEntry }
    local resIndex = 2
    for i = 0, n-1 do
        for j = 0, n do
            res[resIndex] = { 2*i+offset_i-n+1, 2*j+offset_j-n, 0 }
            resIndex = resIndex + 1
        end
    end
    return res
end

local Style3CoordinateGeneration = function(initialEntry, n)
    local res = { initialEntry }
    local resIndex = 2
    for i = 1, n do
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

local Style4CoordinateGeneration = function(initialEntry, n)
    local res = { initialEntry }
    local resIndex = 2
    for i = 1, n do
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

--[[
    Differences compared to original basetemplates.lua file:
    - In MovedTemplates7, Aeon Faction (index 2), "T3Artillery" and "T4Artillery" were swapped
    - In MovedTemplates8, UEF Faction (index 1), "T4Artillery" and "T3RapidArtillery" were swapped
]]
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

--[[
    Differences compared to the original:
    - Instead of a distinct copy for each template array, this code creates the array once and then points subsequent factions at the first version, saving memory.
]]
BaseTemplates =   { { Style1CoordinateGeneration(UnitList1, 30,   0,   0), Style2CoordinateGeneration(UnitList2, 30,   0,   0) } }
MovedTemplates1 = { { Style1CoordinateGeneration(UnitList1, 20, -50, -50), Style2CoordinateGeneration(UnitList2, 20, -50, -50) } }
MovedTemplates2 = { { Style1CoordinateGeneration(UnitList1, 20, -50,   0), Style2CoordinateGeneration(UnitList2, 20, -50,   0) } }
MovedTemplates3 = { { Style1CoordinateGeneration(UnitList1, 20, -50,  50), Style2CoordinateGeneration(UnitList2, 20, -50,  50) } }
MovedTemplates4 = { { Style1CoordinateGeneration(UnitList1, 20,   0, -50), Style2CoordinateGeneration(UnitList2, 20,   0, -50) } }
MovedTemplates5 = { { Style1CoordinateGeneration(UnitList1, 20,   0,  50), Style2CoordinateGeneration(UnitList2, 20,   0,  50) } }
MovedTemplates6 = { { Style1CoordinateGeneration(UnitList1, 20,  50, -50), Style2CoordinateGeneration(UnitList2, 20,  50, -50) } }
MovedTemplates7 = { { Style1CoordinateGeneration(UnitList1, 20,  50,   0), Style2CoordinateGeneration(UnitList2, 20,  50,   0) } }
MovedTemplates8 = { { Style1CoordinateGeneration(UnitList1, 20,  50,  50), Style2CoordinateGeneration(UnitList2, 20,  50,  50) } }

ExpansionBaseTemplates = { { Style3CoordinateGeneration(UnitList1, 10), Style4CoordinateGeneration(UnitList2, 10) } }
Adjacency2x2 = { { UnitListAdjacency, { 2, 0, 0 }, { -2, 0, 0 }, { 0, 2, 0 }, { 0, -2, 0 } } }

for factionIndex = 2, 4 do
    BaseTemplates[factionIndex] = BaseTemplates[1]
    MovedTemplates1[factionIndex] = MovedTemplates1[1]
    MovedTemplates2[factionIndex] = MovedTemplates2[1]
    MovedTemplates3[factionIndex] = MovedTemplates3[1]
    MovedTemplates4[factionIndex] = MovedTemplates4[1]
    MovedTemplates5[factionIndex] = MovedTemplates5[1]
    MovedTemplates6[factionIndex] = MovedTemplates6[1]
    MovedTemplates7[factionIndex] = MovedTemplates7[1]
    MovedTemplates8[factionIndex] = MovedTemplates8[1]
    ExpansionBaseTemplates[factionIndex] = ExpansionBaseTemplates[1]
    Adjacency2x2[factionIndex] = Adjacency2x2[1]
end
