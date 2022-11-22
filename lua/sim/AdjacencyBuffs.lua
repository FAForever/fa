--****************************************************************************
--**
--**  File     :  /lua/sim/AdjacencyBuffs.lua
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
---@declare-global

---@alias AdjacencyBuffType
---| "ENERGYACTIVEBONUS"
---| "ENERGYMAINTENANCEBONUS"
---| "ENERGYRPODUCTIONBONUS"
---| "ENERGYWEAPONBONUS"
---| "MASSACTIVEBONUS"
---| "MASSPRODUCTIONBONUS"
---| "RATEOFFIREBONUS"


---@alias AdjacencyBuffName
---| PowerGeneratorAdjacencyBuffName
---| MassExtractorAdjacencyBuffName
---| MassFabricatorAdjacencyBuffName
---| MassStorageAdjacencyBuffName
---| EnergyStorageAdjacencyBuffName


---@alias PowerGeneratorAdjacencyBuffName
---| T1PowerGeneratorAdjacencyBuffName
---| HydrocarbonAdjacencyBuffName
---| T2PowerGeneratorAdjacencyBuffName
---| T3PowerGeneratorAdjacencyBuffName

---@alias T1PowerGeneratorAdjacencyBuffName
---| T1PowerGeneratorEnergyActiveBuffName
---| T1PowerGeneratorEnergyMaintenanceBuffName
---| T1PowerGeneratorEnergyWeaponBuffName
---| T1PowerGeneratorRateOfFireBuffName
---@alias T1PowerGeneratorEnergyActiveBuffName
---| "T1PowerGeneratorEnergyActiveSize4"
---| "T1PowerGeneratorEnergyActiveSize8"
---| "T1PowerGeneratorEnergyActiveSize12"
---| "T1PowerGeneratorEnergyActiveSize16"
---| "T1PowerGeneratorEnergyActiveSize20"
---@alias T1PowerGeneratorEnergyMaintenanceBuffName
---| "T1PowerGeneratorEnergyMaintenanceSize4"
---| "T1PowerGeneratorEnergyMaintenanceSize8"
---| "T1PowerGeneratorEnergyMaintenanceSize12"
---| "T1PowerGeneratorEnergyMaintenanceSize16"
---| "T1PowerGeneratorEnergyMaintenanceSize20"
---@alias T1PowerGeneratorEnergyWeaponBuffName
---| "T1PowerGeneratorEnergyWeaponSize4"
---| "T1PowerGeneratorEnergyWeaponSize8"
---| "T1PowerGeneratorEnergyWeaponSize12"
---| "T1PowerGeneratorEnergyWeaponSize16"
---| "T1PowerGeneratorEnergyWeaponSize20"
---@alias T1PowerGeneratorRateOfFireBuffName
---| "T1PowerGeneratorRateOfFireSize4"
---| "T1PowerGeneratorRateOfFireSize8"
---| "T1PowerGeneratorRateOfFireSize12"
---| "T1PowerGeneratorRateOfFireSize16"
---| "T1PowerGeneratorRateOfFireSize20"

---@alias HydrocarbonAdjacencyBuffName
---| HydrocarbonEnergyActiveBuffName
---| HydrocarbonEnergyMaintenanceBuffName
---| HydrocarbonEnergyWeaponBuffName
---| HydrocarbonRateOfFireBuffName
---@alias HydrocarbonEnergyActiveBuffName
---| "HydrocarbonEnergyActiveSize4"
---| "HydrocarbonEnergyActiveSize8"
---| "HydrocarbonEnergyActiveSize12"
---| "HydrocarbonEnergyActiveSize16"
---| "HydrocarbonEnergyActiveSize20"
---@alias HydrocarbonEnergyMaintenanceBuffName
---| "HydrocarbonEnergyMaintenanceSize4"
---| "HydrocarbonEnergyMaintenanceSize8"
---| "HydrocarbonEnergyMaintenanceSize12"
---| "HydrocarbonEnergyMaintenanceSize16"
---| "HydrocarbonEnergyMaintenanceSize20"
---@alias HydrocarbonEnergyWeaponBuffName
---| "HydrocarbonEnergyWeaponSize4"
---| "HydrocarbonEnergyWeaponSize8"
---| "HydrocarbonEnergyWeaponSize12"
---| "HydrocarbonEnergyWeaponSize16"
---| "HydrocarbonEnergyWeaponSize20"
---@alias HydrocarbonRateOfFireBuffName
---| "HydrocarbonRateOfFireSize4"
---| "HydrocarbonRateOfFireSize8"
---| "HydrocarbonRateOfFireSize12"
---| "HydrocarbonRateOfFireSize16"
---| "HydrocarbonRateOfFireSize20"

---@alias T2PowerGeneratorAdjacencyBuffName
---| T2PowerGeneratorEnergyActiveBuffName
---| T2PowerGeneratorEnergyMaintenanceBuffName
---| T2PowerGeneratorEnergyWeaponBuffName
---| T2PowerGeneratorRateOfFireBuffName
---@alias T2PowerGeneratorEnergyActiveBuffName
---| "T2PowerGeneratorEnergyActiveSize4"
---| "T2PowerGeneratorEnergyActiveSize8"
---| "T2PowerGeneratorEnergyActiveSize12"
---| "T2PowerGeneratorEnergyActiveSize16"
---| "T2PowerGeneratorEnergyActiveSize20"
---@alias T2PowerGeneratorEnergyMaintenanceBuffName
---| "T2PowerGeneratorEnergyMaintenanceSize4"
---| "T2PowerGeneratorEnergyMaintenanceSize8"
---| "T2PowerGeneratorEnergyMaintenanceSize12"
---| "T2PowerGeneratorEnergyMaintenanceSize16"
---| "T2PowerGeneratorEnergyMaintenanceSize20"
---@alias T2PowerGeneratorEnergyWeaponBuffName
---| "T2PowerGeneratorEnergyWeaponSize4"
---| "T2PowerGeneratorEnergyWeaponSize8"
---| "T2PowerGeneratorEnergyWeaponSize12"
---| "T2PowerGeneratorEnergyWeaponSize16"
---| "T2PowerGeneratorEnergyWeaponSize20"
---@alias T2PowerGeneratorRateOfFireBuffName
---| "T2PowerGeneratorRateOfFireSize4"
---| "T2PowerGeneratorRateOfFireSize8"
---| "T2PowerGeneratorRateOfFireSize12"
---| "T2PowerGeneratorRateOfFireSize16"
---| "T2PowerGeneratorRateOfFireSize20"

---@alias T3PowerGeneratorAdjacencyBuffName
---| T3PowerGeneratorEnergyActiveBuffName
---| T3PowerGeneratorEnergyMaintenanceBuffName
---| T3PowerGeneratorEnergyWeaponBuffName
---| T3PowerGeneratorRateOfFireBuffName
---@alias T3PowerGeneratorEnergyActiveBuffName
---| "T3PowerGeneratorEnergyActiveSize4"
---| "T3PowerGeneratorEnergyActiveSize8"
---| "T3PowerGeneratorEnergyActiveSize12"
---| "T3PowerGeneratorEnergyActiveSize16"
---| "T3PowerGeneratorEnergyActiveSize20"
---@alias T3PowerGeneratorEnergyMaintenanceBuffName
---| "T3PowerGeneratorEnergyMaintenanceSize4"
---| "T3PowerGeneratorEnergyMaintenanceSize8"
---| "T3PowerGeneratorEnergyMaintenanceSize12"
---| "T3PowerGeneratorEnergyMaintenanceSize16"
---| "T3PowerGeneratorEnergyMaintenanceSize20"
---@alias T3PowerGeneratorEnergyWeaponBuffName
---| "T3PowerGeneratorEnergyWeaponSize4"
---| "T3PowerGeneratorEnergyWeaponSize8"
---| "T3PowerGeneratorEnergyWeaponSize12"
---| "T3PowerGeneratorEnergyWeaponSize16"
---| "T3PowerGeneratorEnergyWeaponSize20"
---@alias T3PowerGeneratorRateOfFireBuffName
---| "T3PowerGeneratorRateOfFireSize4"
---| "T3PowerGeneratorRateOfFireSize8"
---| "T3PowerGeneratorRateOfFireSize12"
---| "T3PowerGeneratorRateOfFireSize16"
---| "T3PowerGeneratorRateOfFireSize20"


---@alias MassExtractorAdjacencyBuffName
---| T1MassExtractorAdjacencyBuffName
---| T2MassExtractorAdjacencyBuffName
---| T3MassExtractorAdjacencyBuffName

---@alias T1MassExtractorAdjacencyBuffName T1MassExtractorMassActiveBuffName
---@alias T1MassExtractorMassActiveBuffName
---| "T1MassExtractorMassActiveSize4"
---| "T1MassExtractorMassActiveSize8"
---| "T1MassExtractorMassActiveSize12"
---| "T1MassExtractorMassActiveSize16"
---| "T1MassExtractorMassActiveSize20"

---@alias T2MassExtractorAdjacencyBuffName T2MassExtractorMassActiveBuffName
---@alias T2MassExtractorMassActiveBuffName
---| "T2MassExtractorMassActiveSize4"
---| "T2MassExtractorMassActiveSize8"
---| "T2MassExtractorMassActiveSize12"
---| "T2MassExtractorMassActiveSize16"
---| "T2MassExtractorMassActiveSize20"

---@alias T3MassExtractorAdjacencyBuffName T3MassExtractorMassActiveBuffName
---@alias T3MassExtractorMassActiveBuffName
---| "T3MassExtractorMassActiveSize4"
---| "T3MassExtractorMassActiveSize8"
---| "T3MassExtractorMassActiveSize12"
---| "T3MassExtractorMassActiveSize16"
---| "T3MassExtractorMassActiveSize20"


---@alias MassFabricatorAdjacencyBuffName
---| T1MassFabricatorAdjacencyBuffName
---| T3MassFabricatorAdjacencyBuffName

---@alias T1MassFabricatorAdjacencyBuffName T1MassFabricatorMassActiveBuffName
---@alias T1MassFabricatorMassActiveBuffName
---| "T1MassFabricatorMassActiveSize4"
---| "T1MassFabricatorMassActiveSize8"
---| "T1MassFabricatorMassActiveSize12"
---| "T1MassFabricatorMassActiveSize16"
---| "T1MassFabricatorMassActiveSize20"

---@alias T3MassFabricatorAdjacencyBuffName T3MassFabricatorMassActiveBuffName
---@alias T3MassFabricatorMassActiveBuffName
---| "T3MassFabricatorMassActiveSize4"
---| "T3MassFabricatorMassActiveSize8"
---| "T3MassFabricatorMassActiveSize12"
---| "T3MassFabricatorMassActiveSize16"
---| "T3MassFabricatorMassActiveSize20"


---@alias EnergyStorageAdjacencyBuffName T1EnergyStorageAdjacencyBuffName
---@alias T1EnergyStorageAdjacencyBuffName T1EnergyStorageEnergyProductionBuffName
---@alias T1EnergyStorageEnergyProductionBuffName
---| "T1EnergyStorageEnergyProductionSize4"
---| "T1EnergyStorageEnergyProductionSize8"
---| "T1EnergyStorageEnergyProductionSize12"
---| "T1EnergyStorageEnergyProductionSize16"
---| "T1EnergyStorageEnergyProductionSize20"


---@alias MassStorageAdjacencyBuffName T1MassStorageAdjacencyBuffName
---@alias T1MassStorageAdjacencyBuffName T1MassStorageMassProductionBuffName
---@alias T1MassStorageMassProductionBuffName
---| "T1MassStorageMassProductionSize4"
---| "T1MassStorageMassProductionSize8"
---| "T1MassStorageMassProductionSize12"
---| "T1MassStorageMassProductionSize16"
---| "T1MassStorageMassProductionSize20"


---@type T1PowerGeneratorAdjacencyBuffName[]
T1PowerGeneratorAdjacencyBuffs = nil
---@type HydrocarbonAdjacencyBuffName[]
HydrocarbonAdjacencyBuffs = nil
---@type T2PowerGeneratorAdjacencyBuffName[]
T2PowerGeneratorAdjacencyBuffs = nil
---@type T3PowerGeneratorAdjacencyBuffName[]
T3PowerGeneratorAdjacencyBuffs = nil

---@type T1MassExtractorAdjacencyBuffName[]
T1MassExtractorAdjacencyBuffs = nil
---@type T2MassExtractorAdjacencyBuffName[]
T2MassExtractorAdjacencyBuffs = nil
---@type T3MassExtractorAdjacencyBuffName[]
T3MassExtractorAdjacencyBuffs = nil

---@type T1MassFabricatorAdjacencyBuffName[]
T1MassFabricatorAdjacencyBuffs = nil
---@type T3MassFabricatorAdjacencyBuffName[]
T3MassFabricatorAdjacencyBuffs = nil

---@type T1EnergyStorageAdjacencyBuffName[]
T1EnergyStorageAdjacencyBuffs = nil
---@type T1MassStorageAdjacencyBuffName[]
T1MassStorageAdjacencyBuffs = nil




local AdjBuffFuncs = import("/lua/sim/adjacencybufffunctions.lua")

local adj = {            --   SIZE4     SIZE8     SIZE12     SIZE16     SIZE20
    T1PowerGenerator = {
        EnergyActive =      {-0.0625,  -0.03125, -0.0208,   -0.01563,  -0.0025},
        EnergyMaintenance = {-0.0625,  -0.03125, -0.0208,   -0.01563,  -0.0125},
        EnergyWeapon =      {-0.0250,  -0.01250, -0.0083,   -0.00625,  -0.0050},
        RateOfFire =        {-0.0400,  -0.01250, -0.0083,   -0.00625,  -0.0050},
    },
    T2PowerGenerator = {
        EnergyActive =      {-0.125,   -0.125,   -0.125,    -0.125,    -0.025},
        EnergyMaintenance = {-0.125,   -0.125,   -0.125,    -0.125,    -0.125},
        EnergyWeapon =      {-0.05,    -0.05,    -0.05,     -0.05,     -0.05},
        RateOfFire =        {-0.0625,  -0.0625,  -0.0625,   -0.0625,   -0.0625},
    },
    T3PowerGenerator = {
        EnergyActive =      {-0.1875,  -0.1875,  -0.1875,   -0.1875,   -0.05},
        EnergyMaintenance = {-0.1875,  -0.1875,  -0.1875,   -0.1875,   -0.1875},
        EnergyWeapon =      {-0.075,   -0.075,   -0.075,    -0.075,    -0.075},
        RateOfFire =        {-0.1,     -0.1,     -0.1,      -0.1,      -0.1},
    },
    T1MassExtractor = {
        MassActive =        {-0.1,     -0.05,    -0.0333,   -0.075,    -0.075},
    },
    T2MassExtractor = {
        MassActive =        {-0.15,    -0.075,   -0.05,     -0.1,      -0.1},
    },
    T3MassExtractor = {
        MassActive =        {-0.2,     -0.1,     -0.0667,   -0.125,    -0.125},
    },
    T1MassFabricator = {
        MassActive =        {-0.025,   -0.0125,  -0.008333, -0.0125,   -0.0075},
    },
    T3MassFabricator = {
        MassActive =        {-0.2,     -0.2,     -0.125,    -0.2,      -0.0375},
    },
    T1EnergyStorage = {
        EnergyProduction =  {0.125,    0.0625,   0.041667,  0.03125,   0.025},
    },
    T1MassStorage = {
        MassProduction =    {0.125,    0.0625,   0.03,      0.03125,   0.025},
    },
}
adj.Hydrocarbon = adj.T2PowerGenerator

for a, buffs in adj do
    _G[a .. 'AdjacencyBuffs'] = {}
    for t, sizes in buffs do
        for i, add in sizes do
            local size = i * 4
            local display_name = a .. t
            local name = display_name .. 'Size' .. size
            local category = 'STRUCTURE SIZE' .. size

            if t == 'RateOfFire' and size == 4 then
                category = category .. ' ARTILLERY'
            end

            BuffBlueprint {
                Name = name,
                DisplayName = display_name,
                BuffType = string.upper(t) .. 'BONUS',
                Stacks = 'ALWAYS',
                Duration = -1,
                EntityCategory = category,
                BuffCheckFunction = AdjBuffFuncs[t .. 'BuffCheck'],
                OnBuffAffect = AdjBuffFuncs.DefaultBuffAffect,
                OnBuffRemove = AdjBuffFuncs.DefaultBuffRemove,
                Affects = {[t]={Add=add}},
            }

            table.insert(_G[a .. 'AdjacencyBuffs'], name)
        end
    end
end
