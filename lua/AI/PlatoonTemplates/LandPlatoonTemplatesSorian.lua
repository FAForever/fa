PlatoonTemplate {
    Name = 'LandAttackSorian',
    Plan = 'AttackForceAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 5, 100, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'LandAttackMediumSorian',
    Plan = 'AttackForceAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'LandAttackLargeSorian',
    Plan = 'AttackForceAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 20, 100, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'HuntAttackSmallSorian',
    Plan = 'HuntAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 5, 100, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'HuntAttackMediumSorian',
    Plan = 'HuntAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'BaseGuardSmallSorian',
    Plan = 'GuardBaseSorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 5, 15, 'Attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'BaseGuardMediumSorian',
    Plan = 'GuardBaseSorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 25, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'StrikeForceMediumSorian',
    Plan = 'StrikeForceAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'AttackFormation' }
    },
}
PlatoonTemplate {
    Name = 'StartLocationAttackSorian',
    Plan = 'GuardMarkerSorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'none' },
        { categories.ENGINEER - categories.COMMAND, 1, 1, 'Attack', 'none' },
    },
}
PlatoonTemplate {
    Name = 'StartLocationAttack2Sorian',
    Plan = 'GuardMarkerSorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'T1LandScoutFormSorian',
    Plan = 'ScoutingAISorian',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND * categories.SCOUT * categories.TECH1, 1, 1, 'scout', 'none' }
    }
}

PlatoonTemplate {
    Name = 'T2EngineerGuard',
    Plan = 'None',
    GlobalSquads = {
        { categories.DIRECTFIRE * categories.TECH2 * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 1, 3, 'guard', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerGuard',
    Plan = 'None',
    GlobalSquads = {
        { categories.DIRECTFIRE * categories.TECH3 * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 1, 3, 'guard', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3ExpGuard',
    Plan = 'GuardExperimentalSorian',
    GlobalSquads = {
        { categories.LAND * categories.MOBILE - categories.TECH1 - categories.ANTIAIR - categories.SCOUT - categories.ENGINEER - categories.ual0303 - categories.xsl0402, 1, 10, 'guard', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T1GhettoSquad',
    Plan = 'GhettoAISorian',
    GlobalSquads = {
        { categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 6, 6, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T1MassHuntersCategorySorian',
    #Plan = 'AttackForceAI',
    Plan = 'GuardMarkerSorian',
    GlobalSquads = {
        { categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 3, 100, 'attack', 'none' },
        #{ categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 3, 15, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T2MassHuntersCategorySorian',
    #Plan = 'AttackForceAI',
    Plan = 'GuardMarkerSorian',
    GlobalSquads = {
        #{ categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 100, 'attack', 'none' },
        { categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 100, 'attack', 'none' },
        #{ categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 25, 'attack', 'none' },
        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'T4ExperimentalLandSorian',
    Plan = 'ExperimentalAIHubSorian',
    GlobalSquads = {
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.url0401, 1, 10, 'attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'T4ExperimentalScathisSorian',
    Plan = 'ExperimentalAIHubSorian',
    GlobalSquads = {
        { categories.url0401, 1, 1, 'attack', 'none' }
    },
}

PlatoonTemplate {
    Name = 'T4ExperimentalLandLate',
    Plan = 'ExperimentalAIHubSorian',
    GlobalSquads = {
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.url0401, 2, 5, 'attack', 'GrowthFormation' }
    },
}

PlatoonTemplate {
    Name = 'T2AttackTankSorian',
    FactionSquads = {
        UEF = {
            { 'del0204', 1, 1, 'attack', 'None' },
        },
        Aeon = {
            { 'xal0203', 1, 1, 'attack', 'None' },
        },
        Cybran = {
            { 'drl0204', 1, 1, 'attack', 'None' },
        },
    },
}

PlatoonTemplate {
    Name = 'T3ArmoredAssaultSorian',
    FactionSquads = {
        UEF = {
            { 'xel0305', 1, 1, 'attack', 'none' },
        },
        Cybran = {
            { 'xrl0305', 1, 1, 'attack', 'none' },
        },
    }
}