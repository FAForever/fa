--***************************************************************************
--*
--**  File     :  /lua/ai/StructurePlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Note some mods will replace this file, any new templates that need to be added should be added to StructurePlatoonNewTemplates.lua
-- ==== Factory Upgrades ==== --
PlatoonTemplate {
    Name = 'T1LandFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH1 * categories.FACTORY * categories.LAND, 1, 1, 'support', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T2LandFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH2 * categories.FACTORY * categories.LAND, 1, 1, 'support', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T1AirFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH1 * categories.FACTORY * categories.AIR, 1, 1, 'support', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T2AirFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH2 * categories.FACTORY * categories.AIR, 1, 1, 'support', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T1SeaFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH1 * categories.FACTORY * categories.NAVAL, 1, 1, 'support', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T2SeaFactoryUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.TECH2 * categories.FACTORY * categories.NAVAL, 1, 1, 'support', 'none' }
    }
}


-- ==== Extractor Upgrades === --
PlatoonTemplate {
    Name = 'T1MassExtractorUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.MASSEXTRACTION * categories.TECH1, 1, 1, 'support', 'none' }
    },
}

PlatoonTemplate {
    Name = 'T2MassExtractorUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.MASSEXTRACTION * categories.TECH2, 1, 1, 'support', 'none' }
    },
}

-- ==== Radar Upgrades ==== --
PlatoonTemplate {
    Name = 'T1RadarUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.RADAR * categories.TECH1 * categories.STRUCTURE, 1, 1, 'support', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2RadarUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.RADAR * categories.TECH2 * categories.STRUCTURE, 1, 1, 'support', 'none' },
    }
}

-- ==== Sonar Upgrades ==== --
PlatoonTemplate {
    Name = 'T1SonarUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.SONAR * categories.TECH1 * categories.STRUCTURE, 1, 1, 'support', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2SonarUpgrade',
    Plan = 'UnitUpgradeAI',
    GlobalSquads = {
        { categories.SONAR * categories.TECH2 * categories.STRUCTURE, 1, 1, 'support', 'none' },
    }
}

-- ==== Artillery platoons ==== --
PlatoonTemplate {
    Name = 'T2ArtilleryStructure',
    Plan = 'ArtilleryAI',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.TECH2, 1, 1, 'artillery', 'None' }
    }
}

PlatoonTemplate {
    Name = 'T3ArtilleryStructure',
    Plan = 'ArtilleryAI',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.TECH3, 1, 1, 'artillery', 'None' }
    }
}

PlatoonTemplate {
    Name = 'T4ArtilleryStructure',
    Plan = 'ArtilleryAI',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.EXPERIMENTAL, 1, 1, 'artillery', 'None' }
    }
}

-- ==== Shield Upgrades ==== --
PlatoonTemplate {
    Name = 'T2Shield',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        UEF = {
            { 'ueb4202', 0, 1, 'support', 'None' }
        },
        Seraphim = {
            { 'xsb4202', 0, 1, 'attack', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Shield1',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'urb4202', 0, 1, 'attack', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Shield2',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'urb4204', 0, 1, 'attack', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Shield3',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'urb4205', 0, 1, 'attack', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Shield4',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'urb4206', 0, 1, 'attack', 'None' }
        },
    }
}

-- ==== Missile systems ==== --
PlatoonTemplate {
    Name = 'T2TacticalLauncher',
    Plan = 'TacticalAI',
    GlobalSquads = {
        { categories.STRUCTURE * categories.TACTICALMISSILEPLATFORM, 1, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T3Nuke',
    Plan = 'NukeAI',
    GlobalSquads = {
        { categories.NUKE * categories.STRUCTURE * ( categories.TECH3 + categories.EXPERIMENTAL ), 1, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T4Nuke',
    Plan = 'NukeAI',
    GlobalSquads = {
        { categories.NUKE * categories.STRUCTURE * categories.EXPERIMENTAL, 1, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T3AntiNuke',
    Plan = 'AntiNukeAI',
    GlobalSquads = {
        { categories.ANTIMISSILE * categories.STRUCTURE * categories.TECH3, 1, 1, 'attack', 'none' },
    }
}

-- ==== Satellite ==== --
PlatoonTemplate {
    Name = 'T4SatelliteExperimental',
    Plan = 'StrikeForceAI',
    GlobalSquads = {
        { categories.SATELLITE, 1, 1, 'attack', 'none' },
    }
}