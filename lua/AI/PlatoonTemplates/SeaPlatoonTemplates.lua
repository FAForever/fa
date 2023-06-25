--***************************************************************************
--*
--**  File     :  /lua/ai/SeaPlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Note some mods will replace this file, any new templates that need to be added should be added to SeaPlatoonNewTemplates.lua
-- ==== Global Form platoons ==== --
PlatoonTemplate {
    Name = 'SeaAttack',
    Plan = 'NavalForceAI',
    GlobalSquads = {
        { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL - categories.CARRIER - categories.NUKE, 3, 100, 'Attack', 'GrowthFormation' }
    },
}

PlatoonTemplate {
    Name = 'SeaNuke',
    Plan = 'NavalForceAI',
    GlobalSquads = {
        { categories.NAVAL * categories.NUKE, 1, 1, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'T4ExperimentalSea',
    Plan = 'NavalForceAI',
    GlobalSquads = {
        { categories.NAVAL * categories.EXPERIMENTAL * categories.MOBILE, 1, 1, 'attack', 'none' },
    },
}

-- ==== Faction build platoons ==== --
PlatoonTemplate {
    Name = 'T1SeaFrigate',
    FactionSquads = {
        UEF = {
            { 'ues0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0103', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1SeaAntiAir',
    FactionSquads = {
        UEF = {
            { 'ues0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0102', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0103', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0103', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T1SeaSub',
    FactionSquads = {
        UEF = {
            { 'ues0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0203', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0203', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2SeaCruiser',
    FactionSquads = {
        UEF = {
            { 'ues0202', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0202', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0202', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0202', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2SeaDestroyer',
    FactionSquads = {
        UEF = {
            { 'ues0201', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0201', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0201', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0201', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2SubKiller',
    FactionSquads = {
        UEF = {
            { 'xes0102', 1, 1, 'attack', 'None' },
        },
        Aeon = {
            { 'xas0204', 1, 1, 'attack', 'None' },
        },
        Cybran = {
            { 'xrs0204', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T2ShieldBoat',
    FactionSquads = {
        UEF = {
            { 'xes0205', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T2CounterIntelBoat',
    FactionSquads = {
        Cybran = {
            { 'xrs0205', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T3SeaBattleship',
    FactionSquads = {
        UEF = {
            { 'ues0302', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0302', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0302', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0302', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3SeaCarrier',
    Plan = 'CarrierAI',
    FactionSquads = {
        Aeon = {
            { 'uas0303', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0303', 1, 1, 'attack', 'GrowthFormation' }
        },
        Seraphim = {
            { 'xss0303', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3MissileBoat',
    FactionSquads = {
        Aeon = {
            { 'xas0306', 1, 1, 'attack', 'None' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3Battlecruiser',
    FactionSquads = {
        UEF = {
            { 'xes0307', 1, 1, 'attack', 'None' },
        },
    }
}

PlatoonTemplate {
    Name = 'T3SubKiller',
    FactionSquads = {
        Seraphim = {
            { 'xss0304', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T3SeaNukeSub',
    FactionSquads = {
        UEF = {
            { 'ues0304', 1, 1, 'attack', 'GrowthFormation' }
        },
        Aeon = {
            { 'uas0304', 1, 1, 'attack', 'GrowthFormation' }
        },
        Cybran = {
            { 'urs0304', 1, 1, 'attack', 'GrowthFormation' }
        },
    }
}
