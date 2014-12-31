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

}

TypeClass = UAL0303
