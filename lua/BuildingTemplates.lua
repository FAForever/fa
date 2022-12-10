----****************************************************************************
----**
----**  File     :  /lua/basetemplates.lua
----**  Author(s):  Dru Staltman
----**
----**  Summary  :
----**
----**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----****************************************************************************
----------------------------------------------------------------------------------
---- Base Templates                       --
----------------------------------------------------------------------------------

BuildingTemplates =
{
    -- UEF Building List
    {
        -- Power Structures
        {
            'T1EnergyProduction',
            'ueb1101',
        },
        {
            'T1HydroCarbon',
            'ueb1102',
        },
        {
            'T2EnergyProduction',
            'ueb1201',
        },
        {
            'T3EnergyProduction',
            'ueb1301',
        },

        -- Mass Structures
        {
            'T1Resource',
            'ueb1103',
        },
        {
            'T1MassCreation',
            'ueb1104',
        },
        {
            'T2Resource',
            'ueb1202',
        },
        {
            'T3Resource',
            'ueb1302',
        },
        {
            'T3MassCreation',
            'ueb1303',
        },
        {
            'T3MassExtraction',
            'ueb1302',
        },

        -- Land Factory Structures
        {
            'T1LandFactory',
            'ueb0101',
        },
        {
            'T2LandFactory',
            'ueb0201',
        },
        {
            'T2SupportLandFactory',
            'zeb9501',
        },
        {
            'T3LandFactory',
            'ueb0301',
        },
        {
            'T3SupportLandFactory',
            'zeb9601',
        },
        {
            'T3QuantumGate',
            'ueb0304',
        },


        -- Air Factory Structures
        {
            'T1AirFactory',
            'ueb0102',
        },
        {
            'T2AirFactory',
            'ueb0202',
        },
        {
            'T2SupportAirFactory',
            'zeb9502',
        },
        {
            'T3AirFactory',
            'ueb0302',
        },
        {
            'T3SupportAirFactory',
            'zeb9602',
        },

        -- Sea Factory Structures
        {
            'T1SeaFactory',
            'ueb0103',
        },
        {
            'T2SeaFactory',
            'ueb0203',
        },
        {
            'T2SupportSeaFactory',
            'zeb9503',
        },
        {
            'T3SeaFactory',
            'ueb0303',
        },
        {
            'T3SupportSeaFactory',
            'zeb9603',
        },

        -- Storage Structures
        {
            'MassStorage',
            'ueb1106',
        },
        {
            'EnergyStorage',
            'ueb1105',
        },

        -- Defense Structures
        -- -Wall
        {
            'Wall',
            'ueb5101',
        },
        -- -Ground Defense
        {
            'T1GroundDefense',
            'ueb2101',
        },
        {
            'T2GroundDefense',
            'ueb2301',
        },

        -- -Air Defense
        {
            'T1AADefense',
            'ueb2104',
        },
        {
            'T2AADefense',
            'ueb2204',
        },
        {
            'T3AADefense',
            'ueb2304',
        },
        -- -Naval Defense
        {
            'T1NavalDefense',
            'ueb2109',
        },
        {
            'T2NavalDefense',
            'ueb2205',
        },
        -- -Shield Defense
        {
            'T2ShieldDefense',
            'ueb4202',
        },
        {
            'T3ShieldDefense',
            'ueb4301',
        },
        -- -Missile Defense
        {
            'T2MissileDefense',
            'ueb4201',
        },

        -- Intelligence Strucutres
        {
            'T1Radar',
            'ueb3101',
        },
        {
            'T2Radar',
            'ueb3201',
        },
        {
            'T3Radar',
            'ueb3104',
        },
        {
            'T2RadarJammer',
            'ueb4203',
        },
        {
            'T1Sonar',
            'ueb3102',
        },
        {
            'T2Sonar',
            'ueb3202',
        },
        {
            'T3Sonar',
            'ues0305',
        },

        -- Artillery Structures
        {
            'T2Artillery',
            'ueb2303',
        },
        {
            'T3Artillery',
            'ueb2302',
        },
        {
            'T4Artillery',
            'ueb2401',
        },

        -- Strategic Missile Structures
        {
            'T2StrategicMissile',
            'ueb2108',
        },
        {
            'T3StrategicMissile',
            'ueb2305',
        },
        {
            'T3StrategicMissileDefense',
            'ueb4302',
        },

        -- Misc Structures
        {
            '1x1Concrete',
            'ueb5204',
        },
        {
            '2x2Concrete',
            'ueb5205',
        },
        {
            'T2AirStagingPlatform',
            'ueb5202'
        },
        -- Experimental Structures
        {
            'T4LandExperimental1',
            'uel0401',
        },
        {
            'T4LandExperimental2',
            'uel0401',
        },
        {
            'T4AirExperimental1',
            'uel0401',
        },
        {
            'T4SeaExperimental1',
            'ues0401',
        },
        {
            'T4SatelliteExperimental',
            'xeb2402',
        },

        -- UEF FA Specific
        {
            'T2EngineerSupport',
            'xeb0104',
        },
        {
            'T3GroundDefense',
            'xeb2306',
        },
    },

    -- Aeon Building List
    {
        -- Experimental Units
        {
            'Experimental',
            'uaa0310',
        },
        -- Power Structures
        {
            'T1EnergyProduction',
            'uab1101',
        },
        {
            'T1HydroCarbon',
            'uab1102',
        },
        {
            'T2EnergyProduction',
            'uab1201',
        },
        {
            'T3EnergyProduction',
            'uab1301',
        },

        -- Mass Structures
        {
            'T1Resource',
            'uab1103',
        },
        {
            'T1MassCreation',
            'uab1104',
        },
        {
            'T2Resource',
            'uab1202',
        },
        {
            'T3Resource',
            'uab1302',
        },
        {
            'T3MassCreation',
            'uab1303',
        },
                {
            'T3MassExtraction',
            'uab1302',
        },

        -- Land Factory Structures
        {
            'T1LandFactory',
            'uab0101',
        },
        {
            'T2LandFactory',
            'uab0201',
        },
        {
            'T2SupportLandFactory',
            'zab9501',
        },
        {
            'T3LandFactory',
            'uab0301',
        },
        {
            'T3SupportLandFactory',
            'zab9601',
        },
        {
            'T3QuantumGate',
            'uab0304',
        },

        -- Air Factory Structures
        {
            'T1AirFactory',
            'uab0102',
        },
        {
            'T2AirFactory',
            'uab0202',
        },
        {
            'T2SupportAirFactory',
            'zab9502',
        },
        {
            'T3AirFactory',
            'uab0302',
        },
        {
            'T3SupportAirFactory',
            'zab9602',
        },

        -- Sea Factory Structures
        {
            'T1SeaFactory',
            'uab0103',
        },
        {
            'T2SeaFactory',
            'uab0203',
        },
        {
            'T2SupportSeaFactory',
            'zab9503',
        },
        {
            'T3SeaFactory',
            'uab0303',
        },
        {
            'T3SupportSeaFactory',
            'zab9603',
        },

        -- Storage Structures
        {
            'MassStorage',
            'uab1106',
        },
        {
            'EnergyStorage',
            'uab1105',
        },

        -- Defense Structures
        -- -Wall
        {
            'Wall',
            'uab5101',
        },
        -- -Ground Defense
        {
            'T1GroundDefense',
            'uab2101',
        },
        {
            'T2GroundDefense',
            'uab2301',
        },
        -- -Naval Defense
        {
            'T1NavalDefense',
            'uab2109',
        },
        {
            'T2NavalDefense',
            'uab2205',
        },
        -- -Air Defense
        {
            'T1AADefense',
            'uab2104',
        },
        {
            'T2AADefense',
            'uab2204',
        },
        {
            'T3AADefense',
            'uab2304',
        },
        -- -Shield Defense
        {
            'T2ShieldDefense',
            'uab4202',
        },
        {
            'T3ShieldDefense',
            'uab4301',
        },
        -- -Missile Defense
        {
            'T2MissileDefense',
            'uab4201',
        },

        -- Intelligence Strucutres
        {
            'T1Radar',
            'uab3101',
        },
        {
            'T2Radar',
            'uab3201',
        },
        {
            'T3Radar',
            'uab3104',
        },
        {
            'T2RadarJammer',
            'uab4203',
        },
        {
            'T1Sonar',
            'uab3102',
        },
        {
            'T2Sonar',
            'uab3202',
        },
        {
            'T3Sonar',
            'uas0305',
        },

        -- Artillery Structures
        {
            'T2Artillery',
            'uab2303',
        },
        {
            'T3Artillery',
            'uab2302',
        },
        {
            'T4Artillery',
            'uab2302',
        },

        -- Strategic Missile Structures
        {
            'T2StrategicMissile',
            'uab2108',
        },
        {
            'T3StrategicMissile',
            'uab2305',
        },
        {
            'T3StrategicMissileDefense',
            'uab4302',
        },

        -- Misc Structures
        {
            '1x1Concrete',
            'uab5204',
        },
        {
            '2x2Concrete',
            'uab5205',
        },
        {
            'T2AirStagingPlatform',
            'uab5202'
        },
        -- Experimental Structures
        {
            'T4LandExperimental1',
            'ual0401',
        },
        {
            'T4LandExperimental2',
            'ual0401',
        },
        {
            'T4AirExperimental1',
            'uaa0310',
        },
        {
            'T4SeaExperimental1',
            'uas0401',
        },
        {
            'T4EconExperimental',
            'xab1401',
        },

        -- FA Aeon specific
        {
            'T3Optics',
            'xab3301',
        },
        {
            'T3RapidArtillery',
            'xab2307',
        },
    },

    -- Cybran Building List
    {
        -- Power Structures
        {
            'T1EnergyProduction',
            'urb1101',
        },
        {
            'T1HydroCarbon',
            'urb1102',
        },
        {
            'T2EnergyProduction',
            'urb1201',
        },
        {
            'T3EnergyProduction',
            'urb1301',
        },

        -- Mass Structures
        {
            'T1Resource',
            'urb1103',
        },
        {
            'T1MassCreation',
            'urb1104',
        },
        {
            'T2Resource',
            'urb1202',
        },
        {
            'T3Resource',
            'urb1302',
        },
        {
            'T3MassCreation',
            'urb1303',
        },
                {
            'T3MassExtraction',
            'uab1302',
        },

        -- Land Factory Structures
        {
            'T1LandFactory',
            'urb0101',
        },
        {
            'T2LandFactory',
            'urb0201',
        },
        {
            'T2SupportLandFactory',
            'zrb9501',
        },
        {
            'T3LandFactory',
            'urb0301',
        },
        {
            'T3SupportLandFactory',
            'zrb9601',
        },
        {
            'T3QuantumGate',
            'urb0304',
        },

        -- Air Factory Structures
        {
            'T1AirFactory',
            'urb0102',
        },
        {
            'T2AirFactory',
            'urb0202',
        },
        {
            'T2SupportAirFactory',
            'zrb9502',
        },
        {
            'T3AirFactory',
            'urb0302',
        },
        {
            'T3SupportAirFactory',
            'zrb9602',
        },

        -- Sea Factory Structures
        {
            'T1SeaFactory',
            'urb0103',
        },
        {
            'T2SeaFactory',
            'urb0203',
        },
        {
            'T2SupportSeaFactory',
            'zrb9503',
        },
        {
            'T3SeaFactory',
            'urb0303',
        },
        {
            'T3SupportSeaFactory',
            'zrb9603',
        },

        -- Storage Structures
        {
            'MassStorage',
            'urb1106',
        },
        {
            'EnergyStorage',
            'urb1105',
        },

        -- Defense Structures
        -- -Wall
        {
            'Wall',
            'urb5101',
        },
        -- -Ground Defense
        {
            'T1GroundDefense',
            'urb2101',
        },
        {
            'T2GroundDefense',
            'urb2301',
        },
        -- -Naval Defense
        {
            'T1NavalDefense',
            'urb2109',
        },
        {
            'T2NavalDefense',
            'urb2205',
        },
        -- -Air Defense
        {
            'T1AADefense',
            'urb2104',
        },
        {
            'T2AADefense',
            'urb2204',
        },
        {
            'T3AADefense',
            'urb2304',
        },
        -- -Shield Defense
        {
            'T2ShieldDefense',
            'urb4202',
        },
        {
            'T3ShieldDefense',
            'urb4202',
        },
        -- -Missile Defense
        {
            'T2MissileDefense',
            'urb4201',
        },

        -- Intelligence Strucutres
        {
            'T1Radar',
            'urb3101',
        },
        {
            'T2Radar',
            'urb3201',
        },
        {
            'T3Radar',
            'urb3104',
        },
        {
            'T2RadarJammer',
            'urb4203',
        },
        {
            'T1Sonar',
            'urb3102',
        },
        {
            'T2Sonar',
            'urb3202',
        },
        {
            'T3Sonar',
            'urs0305',
        },

        -- Artillery Structures
        {
            'T2Artillery',
            'urb2303',
        },
        {
            'T3Artillery',
            'urb2302',
        },
        {
            'T4Artillery',
            'urb2302',
        },

        -- Strategic Missile Structures
        {
            'T2StrategicMissile',
            'urb2108',
        },
        {
            'T3StrategicMissile',
            'urb2305',
        },
        {
            'T3StrategicMissileDefense',
            'urb4302',
        },

        -- Misc Structures
        {
            '1x1Concrete',
            'urb5204',
        },
        {
            '2x2Concrete',
            'urb5205',
        },
        {
            'T2AirStagingPlatform',
            'urb5202'
        },
        -- Experimental Structures
        {
            'T4LandExperimental1',
            'url0402',
        },
        {
            'T4LandExperimental2',
            'url0401',
        },
        {
            'T4LandExperimental3',
            'xrl0403',
        },
        {
            'T4AirExperimental1',
            'ura0401',
        },
        {
            'T4SeaExperimental1',
            'urb0101',
        },

        -- Cybran FA Specific
        {
            'T3Optics',
            'xrb3301',
        },
        {
            'T2EngineerSupport',
            'xrb0104',
        },
        {
            'T3NavalDefense',
            'xrb2308',
        },
    },

    -- Seraphim Building List
    {
        -- Power Structures
        {
            'T1EnergyProduction',
            'xsb1101',
        },
        {
            'T1HydroCarbon',
            'xsb1102',
        },
        {
            'T2EnergyProduction',
            'xsb1201',
        },
        {
            'T3EnergyProduction',
            'xsb1301',
        },

        -- Mass Structures
        {
            'T1Resource',
            'xsb1103',
        },
        {
            'T1MassCreation',
            'xsb1104',
        },
        {
            'T2Resource',
            'xsb1202',
        },
        {
            'T3Resource',
            'xsb1302',
        },
        {
            'T3MassCreation',
            'xsb1303',
        },
                {
            'T3MassExtraction',
            'uab1302',
        },

        -- Land Factory Structures
        {
            'T1LandFactory',
            'xsb0101',
        },
        {
            'T2LandFactory',
            'xsb0201',
        },
        {
            'T2SupportLandFactory',
            'zsb9501',
        },
        {
            'T3LandFactory',
            'xsb0301',
        },
        {
            'T3SupportLandFactory',
            'zsb9601',
        },
        {
            'T3QuantumGate',
            'xsb0304',
        },

        -- Air Factory Structures
        {
            'T1AirFactory',
            'xsb0102',
        },
        {
            'T2AirFactory',
            'xsb0202',
        },
        {
            'T2SupportAirFactory',
            'zsb9502',
        },
        {
            'T3AirFactory',
            'xsb0302',
        },
        {
            'T3SupportAirFactory',
            'zsb9602',
        },

        -- Sea Factory Structures
        {
            'T1SeaFactory',
            'xsb0103',
        },
        {
            'T2SeaFactory',
            'xsb0203',
        },
        {
            'T2SupportSeaFactory',
            'zsb9503',
        },
        {
            'T3SeaFactory',
            'xsb0303',
        },
        {
            'T3SupportSeaFactory',
            'zsb9603',
        },

        -- Storage Structures
        {
            'MassStorage',
            'xsb1106',
        },
        {
            'EnergyStorage',
            'xsb1105',
        },

        -- Defense Structures
        -- -Wall
        {
            'Wall',
            'xsb5101',
        },
        -- -Ground Defense
        {
            'T1GroundDefense',
            'xsb2101',
        },
        {
            'T2GroundDefense',
            'xsb2301',
        },
        -- -Naval Defense
        {
            'T1NavalDefense',
            'xsb2109',
        },
        {
            'T2NavalDefense',
            'xsb2205',
        },
        -- -Air Defense
        {
            'T1AADefense',
            'xsb2104',
        },
        {
            'T2AADefense',
            'xsb2204',
        },
        {
            'T3AADefense',
            'xsb2304',
        },
        -- -Shield Defense
        {
            'T2ShieldDefense',
            'xsb4202',
        },
        {
            'T3ShieldDefense',
            'xsb4301',
        },
        -- -Missile Defense
        {
            'T2MissileDefense',
            'xsb4201',
        },

        -- Intelligence Strucutres
        {
            'T1Radar',
            'xsb3101',
        },
        {
            'T2Radar',
            'xsb3201',
        },
        {
            'T3Radar',
            'xsb3104',
        },
        {
            'T2RadarJammer',
            'xsb4203',
        },
        {
            'T1Sonar',
            'xsb3102',
        },
        {
            'T2Sonar',
            'xsb3202',
        },
        {
            'T3Sonar',
            'xrs0305',
        },

        -- Artillery Structures
        {
            'T2Artillery',
            'xsb2303',
        },
        {
            'T3Artillery',
            'xsb2302',
        },
        {
            'T4Artillery',
            'xsb2401',
        },

        -- Strategic Missile Structures
        {
            'T2StrategicMissile',
            'xsb2108',
        },
        {
            'T3StrategicMissile',
            'xsb2305',
        },
        {
            'T3StrategicMissileDefense',
            'xsb4302',
        },

        -- Misc Structures
        {
            '1x1Concrete',
            'xsb5204',
        },
        {
            '2x2Concrete',
            'xsb5205',
        },
        {
            'T2AirStagingPlatform',
            'xsb5202'
        },
        -- Experimental Structures
        {
            'T4LandExperimental1',
            'xsl0401',
        },
        {
            'T4LandExperimental2',
            'xsl0401',
        },
        {
            'T4AirExperimental1',
            'xsa0402',
        },
        {
            'T4SeaExperimental1',
            'xsb0101',
        },
    }
}

RebuildStructuresTemplate = {
    -- UEF
    {
        -- factories
        {'ueb0201', 'ueb0101',},
        {'ueb0202', 'ueb0102',},
        {'ueb0203', 'ueb0103',},
        {'ueb0301', 'ueb0101',},
        {'ueb0302', 'ueb0102',},
        {'ueb0303', 'ueb0103',},
        -- extractors
        {'ueb1202', 'ueb1103',},
        -- radar
        -- {'ueb3104', 'ueb3101',},
        -- {'ueb3201', 'ueb3101',},
        -- engie stations
        {'xeb0204', 'xeb0104',},
    },
    -- Aeon
    {
        -- factories
        {'uab0201', 'uab0101',},
        {'uab0202', 'uab0102',},
        {'uab0203', 'uab0103',},
        {'uab0301', 'uab0101',},
        {'uab0302', 'uab0102',},
        {'uab0303', 'uab0103',},
        -- extractors
        {'uab1202', 'uab1103',},
        -- radar
        -- {'uab3104', 'uab3101',},
        -- {'uab3201', 'uab3101',},
    },
    -- Cybran
    {
        -- factories
        {'urb0201', 'urb0101',},
        {'urb0202', 'urb0102',},
        {'urb0203', 'urb0103',},
        {'urb0301', 'urb0101',},
        {'urb0302', 'urb0102',},
        {'urb0303', 'urb0103',},
        -- extractors
        {'urb1202', 'urb1103',},
        -- radar
        -- {'urb3104', 'urb3101',},
        -- {'urb3201', 'urb3101',},
        -- shields
        {'urb4204', 'urb4202',},
        {'urb4205', 'urb4202',},
        {'urb4206', 'urb4202',},
        {'urb4207', 'urb4202',},
        -- engie stations
        {'xrb0204', 'xrb0104',},
        {'xrb0304', 'xrb0104',},
    },

    -- Seraphim
    {
        -- factories
        {'xsb0201', 'xsb0101',},
        {'xsb0202', 'xsb0102',},
        {'xsb0203', 'xsb0103',},
        {'xsb0301', 'xsb0101',},
        {'xsb0302', 'xsb0102',},
        {'xsb0303', 'xsb0103',},
        -- extractors
        {'xsb1202', 'xsb1103',},
        -- radar
        -- {'xsb3104', 'xsb3101',},
        -- {'xsb3201', 'xsb3101',},
    },
}
