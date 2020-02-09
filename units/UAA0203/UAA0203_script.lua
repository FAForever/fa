#****************************************************************************
#**
#**  File     :  /cdimage/units/UAA0203/UAA0203_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Gunship Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local ADFLaserLightWeapon = import('/lua/aeonweapons.lua').ADFLaserLightWeapon

UAA0203 = Class(AAirUnit) {
    Weapons = {
        Turret = Class(ADFLaserLightWeapon) {
			FxChassisMuzzleFlash = {'/effects/emitters/aeon_gunship_body_illumination_01_emit.bp',},
			
			PlayFxMuzzleSequence = function(self, muzzle)
				local bp = self:GetBlueprint()
				local army = self.unit:GetArmy()
				for k, v in self.FxMuzzleFlash do
					CreateAttachedEmitter(self.unit, muzzle, army, v)
				end
				
				for k, v in self.FxChassisMuzzleFlash do
					CreateAttachedEmitter(self.unit, -1, army, v)
				end
				
				if self.unit:GetCurrentLayer() == 'Water' and bp.Audio.FireUnderWater then
					self:PlaySound(bp.Audio.FireUnderWater)
				elseif bp.Audio.Fire then
					self:PlaySound(bp.Audio.Fire)
				end
			end,        
        },
    },
}

TypeClass = UAA0203