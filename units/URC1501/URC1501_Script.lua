-- File     :  /cdimage/units/URC1501/URC1501_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  Cybran Manufacturing Center, Ver1
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local CCivilianStructureUnit = import("/lua/cybranunits.lua").CCivilianStructureUnit

---@class URC1501 : CCivilianStructureUnit
URC1501 = ClassUnit(CCivilianStructureUnit) {
	EffectBones01 = {
		'Smoke_Left01', 'Smoke_Left02', 'Smoke_Left03', 'Smoke_Left04', 'Smoke_Left05',
		'Smoke_Right01', 'Smoke_Right02', 'Smoke_Right03', 'Smoke_Right04', 'Smoke_Right05',
		'Smoke_Center01', 'Smoke_Center02',
	},

	OnCreate = function(self)
		CCivilianStructureUnit.OnCreate(self)
		local army = self.Army
		for k, v in self.EffectBones01 do
			CreateAttachedEmitter(self, v, army, '/effects/emitters/urc1501_ambient_01_emit.bp')
			CreateAttachedEmitter(self, v, army, '/effects/emitters/urc1501_ambient_02_emit.bp')
		end
	end,
}


TypeClass = URC1501
