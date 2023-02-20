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

---@class UEB5103 : TStructureUnit
UEB5103 = ClassUnit(TStructureUnit) {
	FxTransportBeacon = {'/effects/emitters/red_beacon_light_01_emit.bp'},
	FxTransportBeaconScale =1,

	OnCreate = function(self)
		TStructureUnit.OnCreate(self)
		for k, v in self.FxTransportBeacon do
            self.Trash:Add(CreateAttachedEmitter(self, 0, -1, v):ScaleEmitter(self.FxTransportBeaconScale))
		end
	end,
}

TypeClass = UEB5103