--****************************************************************************
--**
--**  File     :  /lua/tarmacs.lua
--**  Author(s):  Robert Oates
--**
--**  Summary  :  Map for terrain-specific tarmacs.
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--**
--****************************************************************************

local TarmacTable =
{
    --UEF Tarmac Overrides
    [1] = {
    },

    --Aeon Tarmac Overrides
    [2] = {
    },

    --Cybran Tarmac Overrides
    [3] = {
    },

    --Seraphim Tarmac Overrides.
    [4] = {
        Dirt01 = '',
        Dirt02 = '_Evergreen',
        Dirt03 = '',
        Dirt05 = '_RedRock',
        Dirt06 = '_RedRock',
        Dirt07 = '_Desert',
        Dirt08 = '_Desert',

        Sand01 = '_Tropical',
        Sand02 = '_Evergreen',

        Vegetation01 = '',
        Vegetation02 = '_Evergreen',
        Vegetation03 = '_Evergreen',
        Vegetation04 = '_Evergreen',
        Vegetation05 = '_Tropical',

        Rocky01 = '',
        Rocky02 = '_Evergreen',
        Rocky03 = '_Tundra',
        Rocky04 = '_RedRock',
        Rocky05 = '_Desert',
        Rocky06 = '_Lava',
        Rocky07 = '_Lava',
        Rocky08 = '_Evergreen',
        Rocky09 = '_Tropical',
        Rocky10 = '_Tropical',
        Rocky11 = '_Geothermal',
        Rocky12 = '_Geothermal',
        Rocky13 = '_Geothermal',

        Concrete01 = '',

        Snowy01 = '_Tundra',
        Snowy02 = '_Tundra',
        Snowy03 = '_Tundra',
    },
}

function GetTarmacType(factionIdx, terrainType, tarmacLayer)
    return TarmacTable[factionIdx][terrainType] or ''
end
