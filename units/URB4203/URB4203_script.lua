#****************************************************************************
#**
#**  File     :  /cdimage/units/URB4203/URB4203_script.lua
#**  Author(s):  David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Cybran Radar Jammer Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CRadarJammerUnit = import('/lua/cybranunits.lua').CRadarJammerUnit

URB4203 = Class(CRadarJammerUnit) {
    IntelEffects = {
		{
			Bones = {
				'URB4203',
			},
			Offset = {
				0,
				0,
				4,
			},
			Type = 'Jammer01',
		},
    },
}

TypeClass = URB4203