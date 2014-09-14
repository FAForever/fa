#****************************************************************************
#**
#**  File     :  /cdimage/units/UAL0303/UAL0303_script.lua
#**  Author(s):  John Comes, David Tomandl
#**
#**  Summary  :  Aeon Siege Assault Bot Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local ADFLaserHighIntensityWeapon = import('/lua/aeonweapons.lua').ADFLaserHighIntensityWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')

UAL0303 = Class(AWalkingLandUnit) {
    Weapons = {
        FrontTurret01 = Class(ADFLaserHighIntensityWeapon) {}
    },

    CreateShield = function(self, shieldSpec)
        # the bubble shield on this unit is considered personal: the harbinger should not be damaged as long as its shield is up
        AWalkingLandUnit.CreateShield(self, shieldSpec)
        if self.MyShield then
            self.MyShield:SetType('Personal')
        end
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateAeonCommanderBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,
}
--	Dynamically change the hitbox so it's a sphere when the personal shield is on,
--  and a normal box when it's off.
	OnShieldEnabled = function(self)
		local bp = self:GetBlueprint()	
		AWalkingLandUnit.OnShieldEnabled(self)
		self:SetCollisionShape('Sphere', 0, bp.SizeY * 0.5, 0, (bp.Defense.Shield.ShieldSize * 0.5))
	end,
	
	OnShieldDisabled = function(self)
		local bp = self:GetBlueprint()			
		AWalkingLandUnit.OnShieldDisabled(self)
		self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
	end,

	OnShieldHpDepleted = function(self)
		local bp = self:GetBlueprint()
		AWalkingLandUnit.OnShieldHpDepleted(self)
		self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
	end,

	OnShieldEnergyDepleted = function(self)
		local bp = self:GetBlueprint()	
		AWalkingLandUnit.OnShieldEnergyDepleted(self)
		self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
	end,	

TypeClass = UAL0303
