--***************************************************************************
--*
--**  File     :  /lua/ai/LandPlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Note some mods will replace this file, any new templates that need to be added should be added to LandPlatoonNewTemplates.lua
-- ==== Global Form platoons ==== --
PlatoonTemplate {
    Name = 'LandAttack',
    Plan = 'AttackForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 1, 25, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'LandAttackMedium',
    Plan = 'AttackForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 25, 50, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'LandAttackLarge',
    Plan = 'AttackForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 50, 100, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'BaseGuardSmall',
    Plan = 'GuardBase',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 5, 15, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'BaseGuardMedium',
    Plan = 'GuardBase',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 15, 25, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'LABAttack',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND * categories.TECH1 * categories.BOT - categories.REPAIR + (categories.SERAPHIM * categories.SCOUT), 5, 50, 'Attack', 'none' }
    },
}
--DUNCAN - Added
PlatoonTemplate {
    Name = 'GhettoMarines',
    Plan = 'GhettoAI',
    GlobalSquads = {
        --DUNCAN - the REPAIR is to remove the mantis. Added in Selen too.
        { categories.MOBILE * categories.LAND * categories.TECH1 * categories.BOT - categories.REPAIR + (categories.SERAPHIM * categories.SCOUT), 6, 6, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'HuntAttackSmall',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 5, 25, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'HuntAttackMedium',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 25, 50, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'StartLocationAttack',
    Plan = 'GuardMarker',
    GlobalSquads = {
        --DUNCAN - was 15 to 25
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 5, 25, 'Attack', 'none' },
    },
}
PlatoonTemplate {
    Name = 'StartLocationAttack2',
    Plan = 'GuardMarker',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 15, 25, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'LandAttackHunt',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER, 10, 100, 'Attack', 'none' } --DUNCAN - was 1 to 100
    }
}

PlatoonTemplate {
    Name = 'T1LandScoutForm',
    Plan = 'ScoutingAI',
    GlobalSquads = {
        { categories.MOBILE * categories.SCOUT * categories.TECH1, 1, 1, 'scout', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T1MassHuntersCategory',
    --Plan = 'AttackForceAI',
    Plan = 'GuardMarker',
    GlobalSquads = {
        --DUNCAN - removed bot as mantis is a bot?
        { categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 3, 15, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2MassHuntersCategory',
    --Plan = 'AttackForceAI',
    Plan = 'GuardMarker',
    GlobalSquads = {
        --DUNCAN - removed bot as mantis is a bot?
        { categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 25, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T1MassHuntersCategoryHunt',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.TECH1 * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 3, 50, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2HuntersCategory',
    --Plan = 'AttackForceAI',
    Plan = 'HuntAI',
    GlobalSquads = {
        { categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 15, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T4ExperimentalLand',
    Plan = 'ExperimentalAIHub',
    GlobalSquads = {
        --DUNCAN - removed the sera lightning unit
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.INSIGNIFICANTUNIT, 1, 1, 'attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'T4ExperimentalLandGroup',
    Plan = 'ExperimentalAIHub',
    GlobalSquads = {
        --DUNCAN - removed the sera lightning unit
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.INSIGNIFICANTUNIT, 2, 3, 'attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'T1EngineerGuard',
    Plan = 'None',
    GlobalSquads = {
        --DUNCAN - was 1 to 3
        { categories.DIRECTFIRE * categories.TECH1 * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 2, 3, 'guard', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3ExperimentalGuard',
    Plan = 'GuardUnit',
    GlobalSquads = {
        { categories.DIRECTFIRE * (categories.TECH3 + categories.TECH2) * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 1, 20, 'guard', 'None' }
    },
}

PlatoonTemplate {
    Name = 'StateMachinePlatoon',
    Plan = 'StateMachineAI',
    GlobalSquads = {
        { categories.DIRECTFIRE * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 2, 15, 'Attack', 'None' },
        { categories.LAND * categories.MOBILE * categories.SCOUT, 1, 2, 'Scout', 'None' }
    },
}

PlatoonTemplate {
    Name = 'StateMachineSmallAttackPlatoon',
    Plan = 'StateMachineAI',
    GlobalSquads = {
        { categories.DIRECTFIRE * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 2, 5, 'Attack', 'None' },
        { categories.LAND * categories.MOBILE * categories.SCOUT, 0, 2, 'Scout', 'None' }
    },
}
-- ==== Factional Templates ==== --

-- T1
PlatoonTemplate {
    Name = 'T1LandAA',
    FactionSquads = {
        UEF = {
            { 'uel0104', 1, 1, 'Attack', 'none' }
        },
        Aeon = {
            { 'ual0104', 1, 1, 'attack', 'none' }
        },
        Cybran = {
            { 'url0104', 1, 1, 'attack', 'none' }
        },
        Seraphim = {
            { 'xsl0104', 1, 1, 'attack', 'none' }
        },
    },
}

PlatoonTemplate {
    Name = 'T1LandArtillery',
    FactionSquads = {
        UEF = {
            { 'uel0103', 1, 1, 'Attack', 'none' }
        },
        Aeon = {
            { 'ual0103', 1, 1, 'Attack', 'none' }
        },
        Cybran = {
            { 'url0103', 1, 1, 'Attack', 'none' }
        },
        Seraphim = {
            { 'xsl0103', 1, 1, 'Attack', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1LandDFBot',
    FactionSquads = {
        UEF = {
            { 'uel0106', 1, 1, 'attack', 'None' }
        },
        Aeon = {
            { 'ual0106', 1, 1, 'attack', 'None' }
        },
        Cybran = {
            { 'url0106', 1, 1, 'attack', 'None' }
        },
        Seraphim = {
            { 'xsl0201', 1, 1, 'attack', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1LandDFTank',
    FactionSquads = {
        UEF = {
            { 'uel0201', 1, 1, 'attack', 'none' }
        },
        Aeon = {
            { 'ual0201', 1, 1, 'attack', 'none' }
        },
        Cybran = {
            { 'url0107', 1, 1, 'attack', 'none' }
        },
        Seraphim = {
            { 'xsl0201', 1, 1, 'attack', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1LandScout',
    FactionSquads = {
        UEF = {
            { 'uel0101', 1, 1, 'scout', 'none' }
        },
        Aeon = {
            { 'ual0101', 1, 1, 'scout', 'none' }
        },
        Cybran = {
            { 'url0101', 1, 1, 'scout', 'none' }
        },
        Seraphim = {
            { 'xsl0101', 1, 1, 'scout', 'none' }
        },
    }
}

-- T2
PlatoonTemplate {
    Name = 'T2LandAA',
    FactionSquads = {
        UEF = {
            { 'uel0205', 1, 1, 'attack', 'none' }
        },
        Aeon = {
            { 'ual0205', 1, 1, 'attack', 'none' }
        },
        Cybran = {
            { 'url0205', 1, 1, 'attack', 'none' }
        },
        Seraphim = {
            { 'xsl0205', 1, 1, 'attack', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2LandAmphibious',
    FactionSquads = {
        UEF = {
            { 'uel0203', 1, 1, 'attack', 'none' }
        },
        Aeon = {
            { 'ual0201', 1, 1, 'attack', 'none' }
        },
        Cybran = {
            { 'url0203', 1, 1, 'attack', 'none' }
        },
        Seraphim = {
            { 'xsl0203', 1, 1, 'attack', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2LandArtillery',
    FactionSquads = {
        UEF = {
            { 'uel0111', 1, 1, 'artillery', 'none' },
        },
        Aeon = {
            { 'ual0111', 1, 1, 'artillery', 'none' },
        },
        Cybran = {
            { 'url0111', 1, 1, 'artillery', 'none' },
        },
        Seraphim = {
            { 'xsl0111', 1, 1, 'artillery', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T2LandDFTank',
    FactionSquads = {
        UEF = {
            { 'uel0202', 1, 1, 'attack', 'none' },
        },
        Aeon = {
            { 'ual0202', 1, 1, 'attack', 'none' },
        },
        Cybran = {
            { 'url0202', 1, 1, 'attack', 'none' },
        },
        Seraphim = {
            { 'xsl0202', 1, 1, 'attack', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T2AttackTank',
    FactionSquads = {
        UEF = {
            { 'del0204', 1, 1, 'attack', 'None' },
        },
        Aeon = {
            { 'xal0203', 1, 1, 'attack', 'None' },
        },
        Cybran = { --DUNCAN - Was UEF in orig
            { 'drl0204', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T2MobileShields',
    FactionSquads = {
        UEF = {
            { 'uel0307', 1, 1, 'support', 'none' }
        },
        Aeon = {
            { 'ual0307', 1, 1, 'support', 'none' }
        },
        Cybran = {
            { 'url0306', 1, 1, 'support', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2MobileBombs',
    FactionSquads = {
        Cybran = {
            { 'xrl0302', 1, 1, 'attack', 'none' },
        },
    }
}

-- T3
PlatoonTemplate {
    Name = 'T3LandAA',
    FactionSquads = {
        UEF = {
            { 'delk002', 1, 1, 'attack', 'none' }
        },
        Aeon = {
            { 'dalk003', 1, 1, 'attack', 'none' }
        },
        Cybran = {
            { 'drlk001', 1, 1, 'attack', 'none' }
        },
        Seraphim = {
            { 'dslk004', 1, 1, 'attack', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3LandArtillery',
    FactionSquads = {
        UEF = {
            { 'uel0304', 1, 1, 'artillery', 'none' },
        },
        Aeon = {
            { 'ual0304', 1, 1, 'artillery', 'none' },
        },
        Cybran = {
            { 'url0304', 1, 1, 'artillery', 'none' },
        },
        Seraphim = {
            { 'xsl0304', 1, 1, 'artillery', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3LandBot',
    FactionSquads = {
        UEF = {
            { 'uel0303', 1, 1, 'attack', 'none' },
        },
        Aeon = {
            { 'ual0303', 1, 1, 'attack', 'none' },
        },
        Cybran = {
            { 'url0303', 1, 1, 'attack', 'none' },
        },
        Seraphim = {
            { 'xsl0303', 1, 1, 'attack', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3SniperBots',
    FactionSquads = {
        Aeon = {
            { 'xal0305', 1, 1, 'attack', 'none' },
        },
        Seraphim = {
            { 'xsl0305', 1, 1, 'attack', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3ArmoredAssault',
    FactionSquads = {
        UEF = {
            { 'xel0305', 1, 1, 'attack', 'none' }, --DUNCAN - fixed typo
        },
        Cybran = {
            { 'xrl0305', 1, 1, 'attack', 'none' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3MobileMissile',
    FactionSquads = {
        UEF = {
            { 'xel0306', 1, 1, 'attack', 'None' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3MobileShields',
    FactionSquads = {
        UEF = {
            { 'uel0307', 1, 1, 'support', 'none' }
        },
        Aeon = {
            { 'ual0307', 1, 1, 'support', 'none' }
        },
        Cybran = {
            { 'url0306', 1, 1, 'support', 'none' }
        },
        Seraphim = {
            { 'xsl0307', 1, 1, 'support', 'none' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3LandSubCommander',
    FactionSquads = {
        UEF = {
            { 'uel0301', 1, 1, 'support', 'none' }
        },
        Aeon = {
            { 'ual0301', 1, 1, 'support', 'none' }
        },
        Cybran = {
            { 'url0301', 1, 1, 'support', 'none' }
        },
        Seraphim = {
            { 'xsl0301', 1, 1, 'support', 'none' }
        },
    }
}
