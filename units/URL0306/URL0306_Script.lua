--****************************************************************************
--**
--**  File     :  /cdimage/units/URL0306/URL0306_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Mobile Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CRadarJammerUnit = import('/lua/cybranunits.lua').CRadarJammerUnit
local EffectUtil = import('/lua/EffectUtilities.lua')

URL0306 = Class(CRadarJammerUnit) {
    IntelEffects = {
        {
            Bones = {
                'AttachPoint',
            },
            Offset = {
                0,
                0.3,
                0,
            },
            Scale = 0.2,
            Type = 'Jammer01',
        },
    },
}

TypeClass = URL0306
