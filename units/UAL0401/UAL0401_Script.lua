#****************************************************************************
#**
#**  File     :  /cdimage/units/UAL0401/UAL0401_script.lua
#**  Author(s):  John Comes, Gordon Duclos
#**
#**  Summary  :  Aeon Galactic Colossus Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local WeaponsFile = import ('/lua/aeonweapons.lua')
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local ADFTractorClaw = WeaponsFile.ADFTractorClaw
local utilities = import('/lua/utilities.lua')
local explosion = import('/lua/defaultexplosions.lua')

UAL0401 = Class(AWalkingLandUnit) {
    Weapons = {
        EyeWeapon = Class(ADFPhasonLaser) {},
        RightArmTractor = Class(ADFTractorClaw) {},
        LeftArmTractor = Class(ADFTractorClaw) {},
    },
 
    OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        local wep = self:GetWeaponByLabel('EyeWeapon')
        local bp = wep:GetBlueprint()
        if bp.Audio.BeamStop then
            wep:PlaySound(bp.Audio.BeamStop)
        end
        if bp.Audio.BeamLoop and wep.Beams[1].Beam then
            wep.Beams[1].Beam:SetAmbientSound(nil, nil)
        end
        for k, v in wep.Beams do
            v.Beam:Disable()
        end     
    end,
        
    DeathThread = function(self, overkillRatio , instigator)
		self:PlayUnitSound('Destroyed')
        explosion.CreateDefaultHitExplosionAtBone( self, 'Torso', 4.0 )
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {self:GetUnitSizes()})           
        WaitSeconds(2)
        explosion.CreateDefaultHitExplosionAtBone( self, 'Right_Leg_B02', 1.0 )
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone( self, 'Right_Leg_B01', 1.0 )
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone( self, 'Left_Arm_B02', 1.0 )
        WaitSeconds(0.3)
        explosion.CreateDefaultHitExplosionAtBone( self, 'Right_Arm_B01', 1.0 )
        explosion.CreateDefaultHitExplosionAtBone( self, 'Right_Leg_B01', 1.0 )

        WaitSeconds(3.5)
        explosion.CreateDefaultHitExplosionAtBone( self, 'Torso', 5.0 )

        AWalkingLandUnit.DeathThread(self, overkillRatio, instigator)
    end,
    
}
TypeClass = UAL0401
