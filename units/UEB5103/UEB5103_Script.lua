--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB5103/UEB5103_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  UEF Quantum Gate Beacon Unit
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add
local CreateAttachedEmitter = CreateAttachedEmitter

---@class UEB5103 : TStructureUnit
UEB5103 = ClassUnit(TStructureUnit) {
	FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
	FxTransportBeaconScale =1,

	OnCreate = function(self)
		TStructureUnit.OnCreate(self)
		local trash = self.Trash

		for k, v in self.FxTransportBeacon do
            TrashBagAdd(trash,CreateAttachedEmitter(self, 0, -1, v):ScaleEmitter(self.FxTransportBeaconScale))
		end
	end,
}

TypeClass = UEB5103