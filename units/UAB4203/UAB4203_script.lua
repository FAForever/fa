--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB4203/UAB4203_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix, John Comes, Gordon Duclos
--**
--**  Summary  :  Aeon Radar Jammer Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ARadarJammerUnit = import("/lua/aeonunits.lua").ARadarJammerUnit

---@class UAB4203 : ARadarJammerUnit
UAB4203 = ClassUnit(ARadarJammerUnit) {
    IntelEffects = {
		{
			Bones = {
				'UAB4203',
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

TypeClass = UAB4203