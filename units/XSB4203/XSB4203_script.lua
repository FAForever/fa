--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB4203/XSB4203_script.lua
--**
--**  Summary  :  Seraphim Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SRadarJammerUnit = import("/lua/seraphimunits.lua").SRadarJammerUnit

---@class XSB4203 : SRadarJammerUnit
XSB4203 = ClassUnit(SRadarJammerUnit) {
    IntelEffects = {
		{
			Bones = {
				'XSB4203',
			},
			Offset = {
				0,
				3.5,
				0,
			},
			Type = 'Jammer01',
		},
    },
}

TypeClass = XSB4203