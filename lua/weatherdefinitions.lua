--****************************************************************************
--**
--**  File     :  /lua/weatherdefinitions.lua
--**  Author(s):  Gordon Duclos, Chris Gorski
--**
--**  Summary  :  Weather definitions
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--**
--****************************************************************************

--[[
    Map Style Types:
        Desert
        Evergreen
        Geothermal
        Lava
        RedRock
        Tropical
        Tundra

    Style Weather Types:
        Desert
            LightStratus -
        Evergreen
            CumulusClouds -
            StormClouds -
            RainClouds - WARNING, only use these a ForceType on a weather generator, max 2 per map
        Geothermal
        Lava
        RedRock
            LightStratus -
        Tropical
            LightStratus -
        Tundra
            WhitePatchyClouds -
            SnowClouds - WARNING, only use these a ForceType on a weather generator, max 2 per map

        All Styles:
            Notes: ( Cirrus style cloud emitters, should be used on a ForceType Weather Generator, placed )
                   ( in the center of a map. Take note that the these are sized specific for map scale    )
            CirrusSparse256 -
            CirrusMedium256 -
            CirrusHeavy256 -
            CirrusSparse512 -
            CirrusMedium512 -
            CirrusHeavy512 -
            CirrusSparse1024 -
            CirrusMedium1024 -
            CirrusHeavy1024 -
            CirrusSparse4096 -
            CirrusMedium4096 -
            CirrusHeavy4096 -
]]--

-- Map Style Type List - defines the different map styles
MapStyleList = {
    'Desert',
    'Evergreen',
    'Geothermal',
    'Lava',
    'RedRock',
    'Tropical',
    'Tundra',
}

EmitterBasePath = '/effects/emitters/'

CirrusSparse256Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_256_01_emit.bp',
    },
}
CirrusMedium256Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_256_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_256_03_emit.bp',
    },
}
CirrusHeavy256Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_256_01_emit.bp',
        EmitterBasePath .. 'weather_cirrus_256_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_256_03_emit.bp',
        EmitterBasePath .. 'weather_cirrus_256_04_emit.bp',
    },
}
CirrusSparse512Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_512_01_emit.bp',
    },
}
CirrusMedium512Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_512_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_512_03_emit.bp',
    },
}
CirrusHeavy512Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_512_01_emit.bp',
        EmitterBasePath .. 'weather_cirrus_512_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_512_03_emit.bp',
        EmitterBasePath .. 'weather_cirrus_512_04_emit.bp',
    },
}
CirrusSparse1024Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_1024_01_emit.bp',
    },
}
CirrusMedium1024Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_1024_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_1024_03_emit.bp',
    },
}
CirrusHeavy1024Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_1024_01_emit.bp',
        EmitterBasePath .. 'weather_cirrus_1024_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_1024_03_emit.bp',
        EmitterBasePath .. 'weather_cirrus_1024_04_emit.bp',
    },
}
CirrusSparse4096Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_4096_01_emit.bp',
    },
}
CirrusMedium4096Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_4096_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_4096_03_emit.bp',
    },
}
CirrusHeavy4096Definition = {
    {
        EmitterBasePath .. 'weather_cirrus_4096_01_emit.bp',
        EmitterBasePath .. 'weather_cirrus_4096_02_emit.bp',
        EmitterBasePath .. 'weather_cirrus_4096_03_emit.bp',
        EmitterBasePath .. 'weather_cirrus_4096_04_emit.bp',
    },
}

-- Map Style Weather Type List - defines the different weather types for each style
MapWeatherList = {
    Desert = {
        LightStratus = {
            {
                EmitterBasePath .. 'weather_stratus_09_emit.bp',	-- 40x40		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_11_emit.bp',	-- 10x10		Med
            },
        },
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Evergreen = {
        CumulusClouds = {
            {
                EmitterBasePath .. 'weather_stratus_07_emit.bp',	-- 60x50		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_08_emit.bp',	-- 100x100	Med
            },
            {
                EmitterBasePath .. 'weather_stratus_09_emit.bp',	-- 40x40		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_10_emit.bp',	-- 40x40		Med
            },
        },
        StormClouds = {
            {
                EmitterBasePath .. 'weather_cumulus_storm_01_emit.bp',	-- 40x40		Heavy
            },
            {
                EmitterBasePath .. 'weather_cumulus_storm_02_emit.bp',	-- 100x100	Heavy
            },
            {
                EmitterBasePath .. 'weather_cumulus_storm_03_emit.bp',	-- 40x40		Heavy
            },
        },
        RainClouds = {
            {
                EmitterBasePath .. 'weather_stratus_08_emit.bp',		-- 100x100	Med
                EmitterBasePath .. 'weather_rainfall_01_emit.bp',
            },
        },
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Geothermal = {
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Lava = {
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Redrock = {
        LightStratus = {
            {
                EmitterBasePath .. 'weather_stratus_09_emit.bp',	-- 40x40		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_11_emit.bp',	-- 10x10		Med
            },
        },
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Tropical = {
        LightStratus = {
            {
                EmitterBasePath .. 'weather_stratus_09_emit.bp',	-- 40x40		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_11_emit.bp',	-- 10x10		Med
            },
        },
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
    Tundra = {
        SnowClouds = {
            {															-- Size		Opacity
                EmitterBasePath .. 'weather_cumulus_snow_01_emit.bp',	-- 60x50		Heavy
                EmitterBasePath .. 'weather_snow_falling_01_emit.bp',
            },
            {
                EmitterBasePath .. 'weather_cumulus_snow_02_emit.bp',		-- 100x100	Med
                EmitterBasePath .. 'weather_snow_falling_01_emit.bp',
            },
            {
                EmitterBasePath .. 'weather_cumulus_snow_03_emit.bp',		-- 40x40		Med
                EmitterBasePath .. 'weather_snow_falling_01_emit.bp',
            },
            {
                EmitterBasePath .. 'weather_cumulus_snow_04_emit.bp',		-- 40x40		Med
                EmitterBasePath .. 'weather_snow_falling_01_emit.bp',
            },
        },
        WhitePatchyClouds = {										-- Size		Opacity
            {
                EmitterBasePath .. 'weather_stratus_07_emit.bp',	-- 60x50		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_08_emit.bp',	-- 100x100	Med
            },
            {
                EmitterBasePath .. 'weather_stratus_09_emit.bp',	-- 40x40		Med
            },
            {
                EmitterBasePath .. 'weather_stratus_10_emit.bp',	-- 40x40		Med
            },
        },
        CirrusSparse256 = CirrusSparse256Definition,
        CirrusMedium256 = CirrusMedium256Definition,
        CirrusHeavy256 = CirrusHeavy256Definition,
        CirrusSparse512 = CirrusSparse512Definition,
        CirrusMedium512 = CirrusMedium512Definition,
        CirrusHeavy512 = CirrusHeavy512Definition,
        CirrusSparse1024 = CirrusSparse1024Definition,
        CirrusMedium1024 = CirrusMedium1024Definition,
        CirrusHeavy1024 = CirrusHeavy1024Definition,
        CirrusSparse4096 = CirrusSparse4096Definition,
        CirrusMedium4096 = CirrusMedium4096Definition,
        CirrusHeavy4096 = CirrusHeavy4096Definition,
    },
}