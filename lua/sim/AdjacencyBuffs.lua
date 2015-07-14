#****************************************************************************
#**
#**  File     :  /lua/sim/AdjacencyBuffs.lua
#**
#**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AdjBuffFuncs = import('/lua/sim/AdjacencyBuffFunctions.lua')

##################################################################
## TIER 1 POWER GEN BUFF TABLE
##################################################################

T1PowerGeneratorAdjacencyBuffs = {
    'T1PowerEnergyBuildBonusSize4',
    'T1PowerEnergyBuildBonusSize8',
    'T1PowerEnergyBuildBonusSize12',
    'T1PowerEnergyBuildBonusSize16',
    'T1PowerEnergyBuildBonusSize20',
    'T1PowerEnergyWeaponBonusSize4',
    'T1PowerEnergyWeaponBonusSize8',
    'T1PowerEnergyWeaponBonusSize12',
    'T1PowerEnergyWeaponBonusSize16',
    'T1PowerEnergyWeaponBonusSize20',
    'T1PowerEnergyMaintenanceBonusSize4',
    'T1PowerEnergyMaintenanceBonusSize8',
    'T1PowerEnergyMaintenanceBonusSize12',
    'T1PowerEnergyMaintenanceBonusSize16',
    'T1PowerEnergyMaintenanceBonusSize20',
    'T1PowerRateOfFireBonusSize4',
    'T1PowerRateOfFireBonusSize8',
    'T1PowerRateOfFireBonusSize12',
    'T1PowerRateOfFireBonusSize16',
    'T1PowerRateOfFireBonusSize20',
}

##################################################################
## ENERGY BUILD BONUS - TIER 1 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T1PowerEnergyBuildBonusSize4',
    DisplayName = 'T1PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.0625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyBuildBonusSize8',
    DisplayName = 'T1PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.03125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyBuildBonusSize12',
    DisplayName = 'T1PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.020833,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyBuildBonusSize16',
    DisplayName = 'T1PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.015625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyBuildBonusSize20',
    DisplayName = 'T1PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY MAINTENANCE BONUS - TIER 1 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T1PowerEnergyMaintenanceBonusSize4',
    DisplayName = 'T1PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.0625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyMaintenanceBonusSize8',
    DisplayName = 'T1PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.03125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyMaintenanceBonusSize12',
    DisplayName = 'T1PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.020833,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyMaintenanceBonusSize16',
    DisplayName = 'T1PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.015625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyMaintenanceBonusSize20',
    DisplayName = 'T1PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY WEAPON BONUS - TIER 1 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T1PowerEnergyWeaponBonusSize4',
    DisplayName = 'T1PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.025,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyWeaponBonusSize8',
    DisplayName = 'T1PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyWeaponBonusSize12',
    DisplayName = 'T1PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.008333,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyWeaponBonusSize16',
    DisplayName = 'T1PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.00625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerEnergyWeaponBonusSize20',
    DisplayName = 'T1PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.005,
            Mult = 1.0,
        },
    },
}

##################################################################
## RATE OF FIRE WEAPON BONUS - TIER 1 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T1PowerRateOfFireBonusSize4',
    DisplayName = 'T1PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4 ARTILLERY',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.04,#-0.025
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerRateOfFireBonusSize8',
    DisplayName = 'T1PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerRateOfFireBonusSize12',
    DisplayName = 'T1PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.008333,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerRateOfFireBonusSize16',
    DisplayName = 'T1PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.00625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1PowerRateOfFireBonusSize20',
    DisplayName = 'T1PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.005,
            Mult = 1.0,
        },
    },
}





##################################################################
## HYDROCARBON POWER GEN BUFF TABLE
##################################################################

HydrocarbonAdjacencyBuffs = {
    'T2PowerEnergyBuildBonusSize4',
    'T2PowerEnergyBuildBonusSize8',
    'T2PowerEnergyBuildBonusSize12',
    'T2PowerEnergyBuildBonusSize16',
    'T2PowerEnergyBuildBonusSize20',
    'T2PowerEnergyWeaponBonusSize4',
    'T2PowerEnergyWeaponBonusSize8',
    'T2PowerEnergyWeaponBonusSize12',
    'T2PowerEnergyWeaponBonusSize16',
    'T2PowerEnergyWeaponBonusSize20',
    'T2PowerEnergyMaintenanceBonusSize4',
    'T2PowerEnergyMaintenanceBonusSize8',
    'T2PowerEnergyMaintenanceBonusSize12',
    'T2PowerEnergyMaintenanceBonusSize16',
    'T2PowerEnergyMaintenanceBonusSize20',
    'T2PowerRateOfFireBonusSize4',
    'T2PowerRateOfFireBonusSize8',
    'T2PowerRateOfFireBonusSize12',
    'T2PowerRateOfFireBonusSize16',
    'T2PowerRateOfFireBonusSize20',
}


##################################################################
## TIER 2 POWER GEN BUFF TABLE
##################################################################

T2PowerGeneratorAdjacencyBuffs = {
    'T2PowerEnergyBuildBonusSize4',
    'T2PowerEnergyBuildBonusSize8',
    'T2PowerEnergyBuildBonusSize12',
    'T2PowerEnergyBuildBonusSize16',
    'T2PowerEnergyBuildBonusSize20',
    'T2PowerEnergyWeaponBonusSize4',
    'T2PowerEnergyWeaponBonusSize8',
    'T2PowerEnergyWeaponBonusSize12',
    'T2PowerEnergyWeaponBonusSize16',
    'T2PowerEnergyWeaponBonusSize20',
    'T2PowerEnergyMaintenanceBonusSize4',
    'T2PowerEnergyMaintenanceBonusSize8',
    'T2PowerEnergyMaintenanceBonusSize12',
    'T2PowerEnergyMaintenanceBonusSize16',
    'T2PowerEnergyMaintenanceBonusSize20',
    'T2PowerRateOfFireBonusSize4',
    'T2PowerRateOfFireBonusSize8',
    'T2PowerRateOfFireBonusSize12',
    'T2PowerRateOfFireBonusSize16',
    'T2PowerRateOfFireBonusSize20',
}


##################################################################
## ENERGY BUILD BONUS - TIER 2 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T2PowerEnergyBuildBonusSize4',
    DisplayName = 'T2PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyBuildBonusSize8',
    DisplayName = 'T2PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyBuildBonusSize12',
    DisplayName = 'T2PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyBuildBonusSize16',
    DisplayName = 'T2PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyBuildBonusSize20',
    DisplayName = 'T2PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY MAINTENANCE BONUS - TIER 2 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T2PowerEnergyMaintenanceBonusSize4',
    DisplayName = 'T2PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyMaintenanceBonusSize8',
    DisplayName = 'T2PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyMaintenanceBonusSize12',
    DisplayName = 'T2PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyMaintenanceBonusSize16',
    DisplayName = 'T2PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyMaintenanceBonusSize20',
    DisplayName = 'T2PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.125,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY WEAPON BONUS - TIER 2 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T2PowerEnergyWeaponBonusSize4',
    DisplayName = 'T2PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyWeaponBonusSize8',
    DisplayName = 'T2PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyWeaponBonusSize12',
    DisplayName = 'T2PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyWeaponBonusSize16',
    DisplayName = 'T2PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerEnergyWeaponBonusSize20',
    DisplayName = 'T2PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

##################################################################
## RATE OF FIRE WEAPON BONUS - TIER 2 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T2PowerRateOfFireBonusSize4',
    DisplayName = 'T2PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4 ARTILLERY',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0625,#-0.05
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerRateOfFireBonusSize8',
    DisplayName = 'T2PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0625,#-0.05
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerRateOfFireBonusSize12',
    DisplayName = 'T2PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0625,#-0.05
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerRateOfFireBonusSize16',
    DisplayName = 'T2PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0625,#-0.05
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2PowerRateOfFireBonusSize20',
    DisplayName = 'T2PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.0625,#-0.05
            Mult = 1.0,
        },
    },
}





##################################################################
## TIER 3 POWER GEN BUFF TABLE
##################################################################

T3PowerGeneratorAdjacencyBuffs = {
    'T3PowerEnergyBuildBonusSize4',
    'T3PowerEnergyBuildBonusSize8',
    'T3PowerEnergyBuildBonusSize12',
    'T3PowerEnergyBuildBonusSize16',
    'T3PowerEnergyBuildBonusSize20',
    'T3PowerEnergyWeaponBonusSize4',
    'T3PowerEnergyWeaponBonusSize8',
    'T3PowerEnergyWeaponBonusSize12',
    'T3PowerEnergyWeaponBonusSize16',
    'T3PowerEnergyWeaponBonusSize20',
    'T3PowerEnergyMaintenanceBonusSize4',
    'T3PowerEnergyMaintenanceBonusSize8',
    'T3PowerEnergyMaintenanceBonusSize12',
    'T3PowerEnergyMaintenanceBonusSize16',
    'T3PowerEnergyMaintenanceBonusSize20',
    'T3PowerRateOfFireBonusSize4',
    'T3PowerRateOfFireBonusSize8',
    'T3PowerRateOfFireBonusSize12',
    'T3PowerRateOfFireBonusSize16',
    'T3PowerRateOfFireBonusSize20',
}


##################################################################
## ENERGY BUILD BONUS - TIER 3 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T3PowerEnergyBuildBonusSize4',
    DisplayName = 'T3PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyBuildBonusSize8',
    DisplayName = 'T3PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyBuildBonusSize12',
    DisplayName = 'T3PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyBuildBonusSize16',
    DisplayName = 'T3PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyBuildBonusSize20',
    DisplayName = 'T3PowerEnergyBuildBonus',
    BuffType = 'ENERGYBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyBuildBuffRemove,
    Affects = {
        EnergyActive = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY MAINTENANCE BONUS - TIER 3 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T3PowerEnergyMaintenanceBonusSize4',
    DisplayName = 'T3PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyMaintenanceBonusSize8',
    DisplayName = 'T3PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyMaintenanceBonusSize12',
    DisplayName = 'T3PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyMaintenanceBonusSize16',
    DisplayName = 'T3PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyMaintenanceBonusSize20',
    DisplayName = 'T3PowerEnergyMaintenanceBonus',
    BuffType = 'ENERGYMAINTENANCEBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyMaintenanceBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyMaintenanceBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyMaintenanceBuffRemove,
    Affects = {
        EnergyMaintenance = {
            Add = -0.1875,
            Mult = 1.0,
        },
    },
}

##################################################################
## ENERGY WEAPON BONUS - TIER 3 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T3PowerEnergyWeaponBonusSize4',
    DisplayName = 'T3PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyWeaponBonusSize8',
    DisplayName = 'T3PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyWeaponBonusSize12',
    DisplayName = 'T3PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyWeaponBonusSize16',
    DisplayName = 'T3PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerEnergyWeaponBonusSize20',
    DisplayName = 'T3PowerEnergyWeaponBonus',
    BuffType = 'ENERGYWEAPONBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyWeaponBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyWeaponBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyWeaponBuffRemove,
    Affects = {
        EnergyWeapon = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

##################################################################
## RATE OF FIRE WEAPON BONUS - TIER 3 POWER GENS
##################################################################

BuffBlueprint {
    Name = 'T3PowerRateOfFireBonusSize4',
    DisplayName = 'T3PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4 ARTILLERY',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.1,#-0.075
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerRateOfFireBonusSize8',
    DisplayName = 'T3PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.1,#-0.075
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerRateOfFireBonusSize12',
    DisplayName = 'T3PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.1,#-0.075
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerRateOfFireBonusSize16',
    DisplayName = 'T3PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.1,#-0.075
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3PowerRateOfFireBonusSize20',
    DisplayName = 'T3PowerRateOfFireBonus',
    BuffType = 'RATEOFFIREADJACENCY',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.RateOfFireBuffCheck,
    OnBuffAffect = AdjBuffFuncs.RateOfFireBuffAffect,
    OnBuffRemove = AdjBuffFuncs.RateOfFireBuffRemove,
    Affects = {
        RateOfFire = {
            Add = -0.1,#-0.075
            Mult = 1.0,
        },
    },
}




##################################################################
## TIER 1 MASS EXTRACTOR BUFF TABLE
##################################################################

T1MassExtractorAdjacencyBuffs = {
    'T1MEXMassBuildBonusSize4',
    'T1MEXMassBuildBonusSize8',
    'T1MEXMassBuildBonusSize12',
    'T1MEXMassBuildBonusSize16',
    'T1MEXMassBuildBonusSize20',
}

##################################################################
## MASS BUILD BONUS - TIER 1 MASS EXTRACTOR
##################################################################

BuffBlueprint {
    Name = 'T1MEXMassBuildBonusSize4',
    DisplayName = 'T1MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.1,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MEXMassBuildBonusSize8',
    DisplayName = 'T1MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MEXMassBuildBonusSize12',
    DisplayName = 'T1MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.033333,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MEXMassBuildBonusSize16',
    DisplayName = 'T1MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075, #-0.025
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MEXMassBuildBonusSize20',
    DisplayName = 'T1MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075, #-0.02
            Mult = 1.0,
        },
    },
}





##################################################################
## TIER 2 MASS EXTRACTOR BUFF TABLE
##################################################################

T2MassExtractorAdjacencyBuffs = {
    'T2MEXMassBuildBonusSize4',
    'T2MEXMassBuildBonusSize8',
    'T2MEXMassBuildBonusSize12',
    'T2MEXMassBuildBonusSize16',
    'T2MEXMassBuildBonusSize20',
}

##################################################################
## MASS BUILD BONUS - TIER 2 MASS EXTRACTOR
##################################################################

BuffBlueprint {
    Name = 'T2MEXMassBuildBonusSize4',
    DisplayName = 'T2MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.15,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2MEXMassBuildBonusSize8',
    DisplayName = 'T2MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2MEXMassBuildBonusSize12',
    DisplayName = 'T2MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.05,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2MEXMassBuildBonusSize16',
    DisplayName = 'T2MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.1,#-0.0375
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T2MEXMassBuildBonusSize20',
    DisplayName = 'T2MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.1,#-0.03
            Mult = 1.0,
        },
    },
}





##################################################################
## TIER 3 MASS EXTRACTOR BUFF TABLE
##################################################################

T3MassExtractorAdjacencyBuffs = {
    'T3MEXMassBuildBonusSize4',
    'T3MEXMassBuildBonusSize8',
    'T3MEXMassBuildBonusSize12',
    'T3MEXMassBuildBonusSize16',
    'T3MEXMassBuildBonusSize20',
}

##################################################################
## MASS BUILD BONUS - TIER 3 MASS EXTRACTOR
##################################################################

BuffBlueprint {
    Name = 'T3MEXMassBuildBonusSize4',
    DisplayName = 'T3MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.2,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3MEXMassBuildBonusSize8',
    DisplayName = 'T3MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.1,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3MEXMassBuildBonusSize12',
    DisplayName = 'T3MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.066667,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3MEXMassBuildBonusSize16',
    DisplayName = 'T3MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.125, #-0.05
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3MEXMassBuildBonusSize20',
    DisplayName = 'T3MEXMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.125,#-0.04
            Mult = 1.0,
        },
    },
}





##################################################################
## TIER 1 MASS FABRICATOR BUFF TABLE
##################################################################

T1MassFabricatorAdjacencyBuffs = {
    'T1FabricatorMassBuildBonusSize4',
    'T1FabricatorMassBuildBonusSize8',
    'T1FabricatorMassBuildBonusSize12',
    'T1FabricatorMassBuildBonusSize16',
    'T1FabricatorMassBuildBonusSize20',
}

##################################################################
## MASS BUILD BONUS - TIER 1 MASS FABRICATOR
##################################################################

BuffBlueprint {
    Name = 'T1FabricatorMassBuildBonusSize4',
    DisplayName = 'T1FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.025,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1FabricatorMassBuildBonusSize8',
    DisplayName = 'T1FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.0125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1FabricatorMassBuildBonusSize12',
    DisplayName = 'T1FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.008333,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1FabricatorMassBuildBonusSize16',
    DisplayName = 'T1FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.0125 ,#-0.00625
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1FabricatorMassBuildBonusSize20',
    DisplayName = 'T1FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.0075,#-0.005
            Mult = 1.0,
        },
    },
}




##################################################################
## TIER 3 MASS FABRICATOR BUFF TABLE
##################################################################

T3MassFabricatorAdjacencyBuffs = {
    'T3FabricatorMassBuildBonusSize4',
    'T3FabricatorMassBuildBonusSize8',
    'T3FabricatorMassBuildBonusSize12',
    'T3FabricatorMassBuildBonusSize16',
    'T3FabricatorMassBuildBonusSize20',
}

##################################################################
## MASS BUILD BONUS - TIER 3 MASS FABRICATOR
##################################################################

BuffBlueprint {
    Name = 'T3FabricatorMassBuildBonusSize4',
    DisplayName = 'T3FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3FabricatorMassBuildBonusSize8',
    DisplayName = 'T3FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3FabricatorMassBuildBonusSize12',
    DisplayName = 'T3FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.075,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3FabricatorMassBuildBonusSize16',
    DisplayName = 'T3FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.2,#-0.075
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T3FabricatorMassBuildBonusSize20',
    DisplayName = 'T3FabricatorMassBuildBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassBuildBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassBuildBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassBuildBuffRemove,
    Affects = {
        MassActive = {
            Add = -0.0225,#-0.075
            Mult = 1.0,
        },
    },
}




##################################################################
## TIER 1 ENERGY STORAGE
##################################################################

T1EnergyStorageAdjacencyBuffs = {
    'T1EnergyStorageEnergyProductionBonusSize4',
    'T1EnergyStorageEnergyProductionBonusSize8',
    'T1EnergyStorageEnergyProductionBonusSize12',
    'T1EnergyStorageEnergyProductionBonusSize16',
    'T1EnergyStorageEnergyProductionBonusSize20',
}

##################################################################
## ENERGY PRODUCTION BONUS - TIER 1 ENERGY STORAGE
##################################################################

BuffBlueprint {
    Name = 'T1EnergyStorageEnergyProductionBonusSize4',
    DisplayName = 'T1EnergyStorageEnergyProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
    Affects = {
        EnergyProduction = {
            Add = 0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1EnergyStorageEnergyProductionBonusSize8',
    DisplayName = 'T1EnergyStorageEnergyProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
    Affects = {
        EnergyProduction = {
            Add = 0.0625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1EnergyStorageEnergyProductionBonusSize12',
    DisplayName = 'T1EnergyStorageEnergyProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
    Affects = {
        EnergyProduction = {
            Add = 0.041667,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1EnergyStorageEnergyProductionBonusSize16',
    DisplayName = 'T1EnergyStorageEnergyProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
    Affects = {
        EnergyProduction = {
            Add = 0.03125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1EnergyStorageEnergyProductionBonusSize20',
    DisplayName = 'T1EnergyStorageEnergyProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.EnergyProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.EnergyProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.EnergyProductionBuffRemove,
    Affects = {
        EnergyProduction = {
            Add = 0.025,
            Mult = 1.0,
        },
    },
}




##################################################################
## TIER 1 MASS STORAGE
##################################################################

T1MassStorageAdjacencyBuffs = {
    'T1MassStorageMassProductionBonusSize4',
    'T1MassStorageMassProductionBonusSize8',
    'T1MassStorageMassProductionBonusSize12',
    'T1MassStorageMassProductionBonusSize16',
    'T1MassStorageMassProductionBonusSize20',
}

##################################################################
## MASS PRODUCTION BONUS - TIER 1 MASS STORAGE
##################################################################

BuffBlueprint {
    Name = 'T1MassStorageMassProductionBonusSize4',
    DisplayName = 'T1MassStorageMassProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE4',
    BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
    Affects = {
        MassProduction = {
            Add = 0.125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MassStorageMassProductionBonusSize8',
    DisplayName = 'T1MassStorageMassProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE8',
    BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
    Affects = {
        MassProduction = {
            Add = 0.0625,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MassStorageMassProductionBonusSize12',
    DisplayName = 'T1MassStorageMassProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE12',
    BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
    Affects = {
        MassProduction = {
            Add = 0.041667,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MassStorageMassProductionBonusSize16',
    DisplayName = 'T1MassStorageMassProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE16',
    BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
    Affects = {
        MassProduction = {
            Add = 0.03125,
            Mult = 1.0,
        },
    },
}

BuffBlueprint {
    Name = 'T1MassStorageMassProductionBonusSize20',
    DisplayName = 'T1MassStorageMassProductionBonus',
    BuffType = 'MASSBUILDBONUS',
    Stacks = 'ALWAYS',
    Duration = -1,
    EntityCategory = 'STRUCTURE SIZE20',
    BuffCheckFunction = AdjBuffFuncs.MassProductionBuffCheck,
    OnBuffAffect = AdjBuffFuncs.MassProductionBuffAffect,
    OnBuffRemove = AdjBuffFuncs.MassProductionBuffRemove,
    Affects = {
        MassProduction = {
            Add = 0.025,
            Mult = 1.0,
        },
    },
}

