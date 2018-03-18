#***************************************************************************
#*
#**  File     :  /lua/ai/StructurePlatoonTemplates.lua
#**
#**  Summary  : Global platoon templates
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

PlatoonTemplate {
    Name = 'MassFabsSorian',
    Plan = 'PauseAI',
    GlobalSquads = {
        { categories.STRUCTURE * categories.MASSFABRICATION, 1, 1, 'support', 'none' },
    }
}

# ==== Missile systems ==== #
PlatoonTemplate {
    Name = 'T2TacticalLauncherSorian',
    Plan = 'TacticalAISorian',
    GlobalSquads = {
        { categories.STRUCTURE * categories.TACTICALMISSILEPLATFORM, 1, 1, 'attack', 'none' },
    }
}

# ==== Artillery platoons ==== #
PlatoonTemplate {
    Name = 'T2ArtilleryStructureSorian',
    Plan = 'ArtilleryAISorian',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.TECH2, 1, 1, 'artillery', 'None' }
    }
}

PlatoonTemplate {
    Name = 'T3ArtilleryStructureSorian',
    Plan = 'ArtilleryAISorian',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.TECH3, 1, 1, 'artillery', 'None' }
    }
}

PlatoonTemplate {
    Name = 'T4ArtilleryStructureSorian',
    Plan = 'ArtilleryAISorian',
    GlobalSquads = {
        { categories.ARTILLERY * categories.STRUCTURE * categories.EXPERIMENTAL, 1, 1, 'artillery', 'None' }
    }
}

PlatoonTemplate {
    Name = 'T3NukeSorian',
    Plan = 'NukeAI',
    GlobalSquads = {
        { categories.NUKE * categories.STRUCTURE * categories.TECH3, 1, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T4NukeSorian',
    Plan = 'NukeAISAI',
    GlobalSquads = {
        { categories.NUKE * categories.STRUCTURE * categories.EXPERIMENTAL, 1, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2Engineering',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        UEF = {
            { 'xeb0104', 0, 1, 'support', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Engineering1',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'xrb0104', 0, 1, 'support', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2Engineering2',
    Plan = 'UnitUpgradeAI',
    FactionSquads = {
        Cybran = {
            { 'xrb0204', 0, 1, 'support', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T4SatelliteExperimentalSorian',
    Plan = 'SatelliteAISorian',
    GlobalSquads = {
        { categories.SATELLITE, 1, 1, 'attack', 'none' },
    }
}
