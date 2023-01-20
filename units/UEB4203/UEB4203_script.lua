--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB4203/UEB4203_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TRadarJammerUnit = import("/lua/terranunits.lua").TRadarJammerUnit

---@class UEB4203 : TRadarJammerUnit
UEB4203 = ClassUnit(TRadarJammerUnit) {
	IntelEffects = {
		{
			Bones = {
				'UEB4203',
			},
			Offset = {
				0,
				0,
				3,
			},
			Type = 'Jammer01',
		},
    },
}

TypeClass = UEB4203