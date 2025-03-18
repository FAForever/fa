--***************************************************************************
--*
--**  File     :  /lua/ai/AirPlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Note some mods will replace this file, any new templates that need to be added should be added to AirPlatoonNewTemplates.lua
-- ==== Global Form platoons ==== --
PlatoonTemplate {
    Name = 'AirAttack',
    Plan = 'StrikeForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR - categories.EXPERIMENTAL - categories.TRANSPORTFOCUS - categories.ANTINAVY, 1, 100, 'Attack', 'GrowthFormation' }
    },
}

PlatoonTemplate {
    Name = 'BomberAttack',
    Plan = 'StrikeForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.BOMBER - categories.EXPERIMENTAL - categories.ANTINAVY, 1, 100, 'Attack', 'GrowthFormation' },
        --{ categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.EXPERIMENTAL - categories.BOMBER - categories.TRANSPORTFOCUS, 0, 10, 'Attack', 'GrowthFormation' },
    }
}

PlatoonTemplate {
    Name = 'TorpedoBomberAttack',
    Plan = 'AttackForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.ANTINAVY - categories.EXPERIMENTAL, 1, 100, 'Attack', 'GrowthFormation' },
        --{ categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.EXPERIMENTAL - categories.BOMBER - categories.TRANSPORTFOCUS, 0, 10, 'Attack', 'GrowthFormation' },
    }
}

PlatoonTemplate {
    Name = 'GunshipAttack',
    Plan = 'GunshipHuntAI',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.TRANSPORTFOCUS, 1, 100, 'Attack', 'GrowthFormation' },
        --{ categories.MOBILE * categories.AIR * categories.ANTIAIR - categories.EXPERIMENTAL - categories.BOMBER - categories.TRANSPORTFOCUS, 0, 10, 'Attack', 'GrowthFormation' },
    }
}

PlatoonTemplate {
    Name = 'GunshipMassHunter',
    Plan = 'GuardMarker',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * categories.GROUNDATTACK - categories.EXPERIMENTAL - categories.TRANSPORTFOCUS, 1, 5, 'Attack', 'GrowthFormation' },
    }
}

PlatoonTemplate {
    Name = 'MassHunterBomber',
    Plan = 'StrikeForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.AIR * (categories.TECH1 + categories.TECH2) * categories.BOMBER - categories.EXPERIMENTAL - categories.ANTINAVY, 1, 3, 'Attack', 'GrowthFormation' },
    },
}

PlatoonTemplate {
    Name = 'T1AirScoutForm',
    Plan = 'ScoutingAI',
    GlobalSquads = {
        { categories.AIR * categories.SCOUT * categories.TECH1, 1, 1, 'scout', 'None' },
    }
}

PlatoonTemplate {
    Name = 'AntiAirHunt',
    Plan = 'InterceptorAI',
    GlobalSquads = {
        { categories.AIR * categories.MOBILE * categories.ANTIAIR * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL, 5, 100, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'AntiAirBaseGuard',
    Plan = 'GuardBase',
    GlobalSquads = {
        { categories.AIR * categories.MOBILE * categories.ANTIAIR * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL, 1, 100, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'GunshipBaseGuard',
    Plan = 'GuardBase',
    GlobalSquads = {
        { categories.AIR * categories.MOBILE * categories.GROUNDATTACK * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL, 1, 100, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T3AirScoutForm',
    Plan = 'ScoutingAI',
    GlobalSquads = {
        { categories.AIR * categories.INTELLIGENCE * categories.TECH3, 1, 1, 'scout', 'None' },
    }
}

PlatoonTemplate {
    Name = 'T4ExperimentalAir',
    Plan = 'ExperimentalAIHub',
    GlobalSquads = {
        --DUNCAN - exclude novax
        { categories.AIR * categories.EXPERIMENTAL * categories.MOBILE - categories.SATELLITE, 1, 1, 'attack', 'none' },
    },
}

PlatoonTemplate {
    Name = 'T4ExperimentalAirGroup',
    Plan = 'ExperimentalAIHub',
    GlobalSquads = {
        --DUNCAN - exclude novax
        { categories.AIR * categories.EXPERIMENTAL * categories.MOBILE - categories.SATELLITE, 2, 3, 'attack', 'none' },
    },
}

PlatoonTemplate {
    Name = 'AirEscort',
    Plan = 'GuardUnit',
    GlobalSquads = {
        { categories.AIR * categories.MOBILE * categories.ANTIAIR * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.BOMBER - categories.TRANSPORTFOCUS - categories.EXPERIMENTAL, 5, 100, 'attack', 'none' },
    }
}

-- ==== Faction Build Platoons ==== --
PlatoonTemplate {
    Name = 'T1AirScout',
    FactionSquads = {
        UEF = {
            { 'uea0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0101', 1, 1, 'scout', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1Gunship',
    FactionSquads = {
        Cybran = {
            { 'xra0105', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T1AirBomber',
    FactionSquads = {
        UEF = {
            { 'uea0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0103', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1AirFighter',
    FactionSquads = {
        UEF = {
            { 'uea0102', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0102', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0102', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0102', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1AirTransport',
    FactionSquads = {
        UEF = {
            { 'uea0107', 1, 1, 'support', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0107', 1, 1, 'support', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0107', 1, 1, 'support', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0107', 1, 1, 'support', 'GrowthFormation' }
        },
    }
}

-- ==================== --
--     T3 Air Units
-- ==================== --
PlatoonTemplate {
    Name = 'T2AirScout',
    FactionSquads = {
        UEF = {
            { 'uea0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0101', 1, 1, 'scout', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0101', 1, 1, 'scout', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2AirGunship',
    FactionSquads = {
        UEF = {
            { 'uea0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0203', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2FighterBomber',
    FactionSquads = {
        UEF = {
            { 'dea0202', 1, 1, 'attack', 'None' },
        },
        Aeon = {
            { 'xaa0202', 1, 1, 'attack', 'None' },
        },
        Cybran = {
            { 'dra0202', 1, 1, 'attack', 'None' },
        },
        Seraphim = {
            { 'xsa0202', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T2AirTorpedoBomber',
    FactionSquads = {
        UEF = {
            { 'uea0204', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0204', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0204', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0204', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2AirTransport',
    FactionSquads = {
        UEF = {
            { 'uea0104', 1, 1, 'support', 'GrowthFormation' },
        },
        Aeon = {
            { 'uaa0104', 1, 1, 'support', 'GrowthFormation' },
        },
        Cybran = {
            { 'ura0104', 1, 1, 'support', 'GrowthFormation' },
        },
        Seraphim = {
            { 'xsa0104', 1, 1, 'support', 'GrowthFormation' },
        },
    }
}

-- ==================== --
--     T3 Air Units
-- ==================== --
PlatoonTemplate {
    Name = 'T3AirBomber',
    FactionSquads = {
        UEF = {
            { 'uea0304', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0304', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0304', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0304', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3AirFighter',
    FactionSquads = {
        UEF = {
            { 'uea0303', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0303', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0303', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0303', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3AirGunship',
    FactionSquads = {
        UEF = {
            { 'uea0305', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'xaa0305', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'xra0305', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3AirScout',
    FactionSquads = {
        UEF = {
            { 'uea0302', 1, 1, 'scout', 'GrowthFormation' }
        },
        Aeon = {
            { 'uaa0302', 1, 1, 'scout', 'GrowthFormation' }
        },
        Cybran = {
            { 'ura0302', 1, 1, 'scout', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xsa0302', 1, 1, 'scout', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3AirTransport',
    FactionSquads = {
        UEF = {
            { 'xea0306', 1, 1, 'support', 'GrowthFormation' },
        },
        Aeon = {
            { 'uaa0104', 1, 1, 'support', 'GrowthFormation' },
        },
        Cybran = {
            { 'ura0104', 1, 1, 'support', 'GrowthFormation' },
        },
        Seraphim = {
            { 'xsa0104', 1, 1, 'support', 'GrowthFormation' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3TorpedoBomber',
    FactionSquads = {
        Aeon = {
            { 'xaa0306', 1, 1, 'attack', 'GrowthFormation' },
        },
    }
}
