#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB1105/UAB1105_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Aeon Energy Storage
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AEnergyStorageUnit = import('/lua/aeonunits.lua').AEnergyStorageUnit

UAB1105 = Class(AEnergyStorageUnit) {

    OnStopBeingBuilt = function(self,builder,layer)
        AEnergyStorageUnit.OnStopBeingBuilt(self,builder,layer)
        self.Trash:Add(CreateStorageManip(self, 'Side_Pods', 'ENERGY', 0, 0, 0, 0, 0, .3))
        self.Trash:Add(CreateStorageManip(self, 'Center_Pod', 'ENERGY', 0, 0, 0, 0, 0, .3))
    end,

	OnKilled = function(self, instigator, type, overkillRatio)
			if not instigator then 
				self.DeathWeaponEnabled = false
			end
		AEnergyStorageUnit.OnKilled(self, instigator, type, overkillRatio)
	end,
	
}

TypeClass = UAB1105