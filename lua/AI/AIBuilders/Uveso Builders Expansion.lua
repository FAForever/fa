local UCBC = '/lua/editor/UnitCountBuildConditions.lua'
local UBC = '/lua/editor/UvesoBuildConditions.lua'

BuilderGroup {
    BuilderGroupName = 'U1 Expansion Builder Uveso',
    BuildersType = 'EngineerBuilder',

    Builder {
        BuilderName = 'U1 Vacant Start Location',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1200,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH2 } },
            { UCBC, 'StartLocationNeedsEngineer', { 'LocationType', 1000, -1000, 5, 0, 'StructuresNotMex' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.LAND } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.AIR } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = 'ExpansionBaseTemplates',
                ExpansionBase = true,
                NearMarkerType = 'Start Location',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1Radar',
                    'T1AADefense',
                    'T1LandFactory',
                    'T1AirFactory',
                }
            },
        }
    },
    Builder {
        BuilderName = 'U1 Vacant Expansion Area',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1200,
        InstanceCount = 2,
        BuilderConditions = {
            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.MASSEXTRACTION * categories.TECH2 } },
            { UCBC, 'ExpansionAreaNeedsEngineer', { 'LocationType', 1000, -1000, 0, 2, 'StructuresNotMex' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.LAND } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.AIR } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
        },
        BuilderType = 'Any',
        BuilderData = {
            RequireTransport = true,
            Construction = {
                BuildClose = false,
                BaseTemplate = 'ExpansionBaseTemplates',
                ExpansionBase = true,
                NearMarkerType = 'Expansion Area',
                LocationRadius = 1000,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 2,
                ThreatType = 'StructuresNotMex',
                ExpansionRadius = 50,
                BuildStructures = {
                    'T1Radar',
                    'T1AADefense',
                    'T1LandFactory',
                    'T1AirFactory',
                }
            },
        }
    },
    Builder {
        BuilderName = 'U1 Naval Builder',
        PlatoonTemplate = 'EngineerBuilder',
        Priority = 1000,
        InstanceCount = 4,
        BuilderConditions = {
--            { UCBC, 'ExpansionBaseCheck', { } },
            { UCBC, 'HaveGreaterThanUnitsWithCategory', { 6, categories.MASSEXTRACTION } },
            { UCBC, 'NavalAreaNeedsEngineer', { 'LocationType', 250, -1000, 10, 1, 'AntiSurface' } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.35, '<=', categories.STRUCTURE - categories.MASSEXTRACTION } },
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.LAND } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
            { UBC, 'HaveUnitRatioVersusCap', { 0.024, '<=', categories.STRUCTURE * categories.FACTORY * categories.AIR } }, -- Maximal 3 factories at 125 unitcap, 12 factories at 500 unitcap...
        },
        BuilderType = 'Any',
        BuilderData = {
            Construction = {
                BuildClose = false,
                BaseTemplate = 'ExpansionBaseTemplates',
                ExpansionBase = true,
                NearMarkerType = 'Naval Area',
                LocationRadius = 250,
                LocationType = 'LocationType',
                ThreatMin = -1000,
                ThreatMax = 100,
                ThreatRings = 2,
                ThreatType = 'AntiSurface',
                ExpansionRadius = 70,
                BuildStructures = {
                    'T1SeaFactory',
                    'T1Sonar',
                    'T1NavalDefense',
                    'T1AADefense',
                    'T1SeaFactory',
                    'T1NavalDefense',
                }
            }
        }
    },
}
