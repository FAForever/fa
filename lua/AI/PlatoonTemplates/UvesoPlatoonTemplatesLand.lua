
-- ==== Global Form platoons ==== --

PlatoonTemplate {
    Name = 'U123 SingleAttack',
    Plan = 'AttackPrioritizedLandTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT , 1, 1, 'Attack', 'none' }
    }
}
PlatoonTemplate {
    Name = 'LandAttackHuntUveso 2 10',
    Plan = 'AttackPrioritizedLandTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT , 2, 10, 'Attack', 'none' }
    }
}
PlatoonTemplate {
    Name = 'LandAttackHuntUveso 5 30',
    Plan = 'AttackPrioritizedLandTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT , 5, 30, 'Attack', 'none' }
    }
}
PlatoonTemplate {
    Name = 'LandAttackHuntUveso 10 40',
    Plan = 'AttackPrioritizedLandTargetsAIUveso',
    GlobalSquads = {
        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT , 10, 40, 'Attack', 'none' },
    }
}

PlatoonTemplate {
    Name = 'U12-LandCap 1 500', 
    Plan = 'AttackPrioritizedLandTargetsAIUveso', -- is targetting in order from Platoondata.PrioritizedCategories.
    GlobalSquads = {
        { categories.MOBILE * categories.LAND * ( categories.TECH1 + categories.TECH2 ) - categories.EXPERIMENTAL - categories.ENGINEER - categories.SCOUT, 1, 500, 'Attack', 'none' },
    }
}


PlatoonTemplate {
    Name = 'T4ExperimentalLandUveso 1 1',
    Plan = 'InterceptorAIUveso', -- is targetting in order from Platoondata.PrioritizedCategories.
    GlobalSquads = {
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.INSIGNIFICANTUNIT, 1, 1, 'attack', 'none' }
    },
}
PlatoonTemplate {
    Name = 'T4ExperimentalLandGroupUveso 2 2',
    Plan = 'AttackPrioritizedLandTargetsAIUveso', -- is targetting in order from Platoondata.PrioritizedCategories.
    GlobalSquads = {
        { categories.EXPERIMENTAL * categories.LAND * categories.MOBILE - categories.INSIGNIFICANTUNIT, 2, 2, 'attack', 'none' }
    },
}

-- ==== Factional Templates ==== --

--PlatoonTemplate {
--    Name = 'T1HeavyAssault',
--    FactionSquads = (function()
--        --local idlist = EntityCategoryGetUnitList(categories.ALLUNITS)
--        local idlist = EntityCategoryGetUnitList(categories.MOBILE * categories.BUILTBYTIER1ENGINEER * categories.TECH1)
--        for k,v in idlist do
--            LOG(repr(v))
--        end
--        local FactionSquads = {
--            UEF = {
--                { 'uel0103', 1, 1, 'Attack', 'none' }
--            },
--            Aeon = {
--                { 'ual0103', 1, 1, 'Attack', 'none' }
--            },
--            Cybran = {
--                { 'url0103', 1, 1, 'Attack', 'none' }
--            },
--            Seraphim = {
--                { 'xsl0103', 1, 1, 'Attack', 'none' }
--            },
--        }
--        LOG('Acessing PlatoonTemplate T1LandArtilleryUVESO')
--        return FactionSquads
--    end)()
--}


--    Plan = 'NavalForceAI',
--    GlobalSquads = {
--        { categories.MOBILE * categories.NAVAL - categories.EXPERIMENTAL - categories.CARRIER - categories.NUKE, 3, 100, 'Attack', 'GrowthFormation' }
--    },
--    Plan = 'AttackForceAISorian',
--    GlobalSquads = {
--        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 5, 100, 'Attack', 'none' }
--    },
--    Plan = 'StrikeForceAISorian',
--    GlobalSquads = {
--        { categories.MOBILE * categories.LAND - categories.EXPERIMENTAL - categories.ENGINEER - categories.xsl0402, 10, 100, 'Attack', 'AttackFormation' }
--    },
--    Plan = 'None',
--    GlobalSquads = {
--        { categories.DIRECTFIRE * categories.TECH2 * categories.LAND * categories.MOBILE - categories.SCOUT - categories.ENGINEER, 1, 3, 'guard', 'None' }
--    },
--    Plan = 'GuardMarkerSorian',
--    GlobalSquads = {
--        #{ categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 100, 'attack', 'none' },
--        { categories.LAND * categories.MOBILE * categories.DIRECTFIRE * categories.BOT - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 100, 'attack', 'none' },
--        #{ categories.TECH1 * categories.LAND * categories.MOBILE * categories.DIRECTFIRE - categories.SCOUT - categories.ENGINEER - categories.EXPERIMENTAL, 10, 25, 'attack', 'none' },
--        { categories.LAND * categories.SCOUT, 0, 1, 'attack', 'none' },
--    }
--    Plan = 'EngineerBuildAI',
--    GlobalSquads = {
--        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
--    },
--    Name = 'T2MobileShields',
--    FactionSquads = {
--        UEF = {
--            { 'uel0307', 1, 1, 'support', 'none' }
--   },
--    Plan = 'TacticalAISorian',
--    GlobalSquads = {
--        { categories.STRUCTURE * categories.TACTICALMISSILEPLATFORM, 1, 1, 'attack', 'none' },
--    }
--    Plan = 'ArtilleryAISorian',
--    GlobalSquads = {
--        { categories.ARTILLERY * categories.STRUCTURE * categories.TECH2, 1, 1, 'artillery', 'None' }
--    }
