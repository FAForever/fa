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
        AWalkingLandUnit.CreateShield(self, shieldSpec)
        --Set the shield's type to Personal to prevent damage to the base unit from things which somehow get under the shield
        if self.MyShield then
            self.MyShield:SetType('Personal')
        end
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateAeonCommanderBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,

    --  Begin Shielding fix: Since Personal Shields no longer use their own collision, instead handling
    --  all damage in unit.lua, and the harbinger is unique in having a personal bubble shield, we need
    --  the hitbox to be the shape and size of the bubble when the shield is up, and the box of the unit
    --  when the shield is down. Anti-collision for this unit is also handled here as it's not officially a personal shield.

    --These functions are empty in unit.lua so no callback required
    OnShieldEnabled = function(self)
        local bp = self:GetBlueprint()
        self:SetCollisionShape('Sphere', 0, bp.SizeY * 0.5, 0, (bp.Defense.Shield.ShieldSize * 0.5))
        --Manually disable the bubble shield's collision sphere after its creation so it acts like the new personal shields
        self.MyShield:SetCollisionShape('None')
    end,

    OnShieldDisabled = function(self)
        local bp = self:GetBlueprint()
        self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
    end,

    OnShieldHpDepleted = function(self)
        local bp = self:GetBlueprint()
        self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
    end,

    OnShieldEnergyDepleted = function(self)
        local bp = self:GetBlueprint()
        self:SetCollisionShape('Box', 0, bp.SizeY * 0.5, 0, bp.SizeX * 0.5, bp.SizeY * 0.5, bp.SizeZ * 0.5)
    end,

    --End Shielding fix
}

TypeClass = UAL0303
