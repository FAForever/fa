--****************************************************************************
--**
--**  File     :  /lua/sim/AdjacencyBuffs.lua
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

---@alias AdjacencyBuffType
---| 'T1PowerGeneratorBONUS'
---| 'T2PowerGeneratorBONUS'
---| 'T3PowerGeneratorBONUS'
---| 'T1MassExtractorBONUS'
---| 'T2MassExtractorBONUS'
---| 'T3MassExtractorBONUS'
---| 'T1MassFabricatorBONUS'
---| 'T3MassFabricatorBONUS'
---| 'T1EnergyStorageBONUS'
---| 'T1MassStorageBONUS'

local AdjBuffFuncs = import('/lua/sim/AdjacencyBuffFunctions.lua')

local adj = {           -- SIZE4     SIZE8   SIZE12    SIZE16   SIZE20
    T1PowerGenerator={
        EnergyActive=       {-0.0625, -0.03125, -0.0208, -0.01563, -0.0025},
        EnergyMaintenance=  {-0.0625, -0.03125, -0.0208, -0.01563, -0.0125},
        EnergyWeapon=       {-0.0250, -0.01250, -0.0083, -0.00625, -0.0050},
        RateOfFire=         {-0.0400, -0.01250, -0.0083, -0.00625, -0.0050},
    },
    T2PowerGenerator={
        EnergyActive=       {-0.125,  -0.125,   -0.125,  -0.125,   -0.125},
        EnergyMaintenance=  {-0.125,  -0.125,   -0.125,  -0.125,   -0.125},
        EnergyWeapon=       {-0.05,   -0.05,    -0.05,   -0.05,    -0.05},
        RateOfFire=         {-0.0625, -0.0625,  -0.0625, -0.0625,  -0.0625},
    },
    T3PowerGenerator={
        EnergyActive=       {-0.15, -0.15,  -0.15, -0.15,  -0.05},
        EnergyMaintenance=  {-0.1875, -0.1875,  -0.1875, -0.1875,  -0.1875},
        EnergyWeapon=       {-0.075,  -0.075,   -0.075,  -0.075,   -0.075},
        RateOfFire=         {-0.1,    -0.1,     -0.1,    -0.1,     -0.1},
    },
    T1MassExtractor={
        MassActive=         {-0.1, -0.05, -0.0333, -0.075, -0.075},
    },
    T2MassExtractor={
        MassActive=         {-0.15, -0.075, -0.05, -0.1, -0.1},
    },
    T3MassExtractor={
        MassActive=         {-0.2, -0.1, -0.0667, -0.125, -0.125},
    },
    T1MassFabricator={
        MassActive=         {-0.025, -0.0125, -0.008333, -0.0125, -0.0075},
    },
    T3MassFabricator={
        MassActive=         {-0.2, -0.2, -0.125, -0.2, -0.0375},
    },
    T1EnergyStorage={
        EnergyProduction=   {0.125, 0.0625, 0.041667, 0.03125, 0.025},
    },
    T1MassStorage={
        MassProduction=     {0.125, 0.0625, 0.03, 0.03125, 0.025},
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
