#****************************************************************************
#**
#**  File     :  /units/XSA0402/XSA0402_script.lua
#**  Author(s):  Greg Kohne, Gordon Duclos
#**
#**  Summary  :  Seraphim Experimental Strategic Bomber Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import('/lua/seraphimunits.lua').SAirUnit
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAALosaareAutoCannonWeapon = SeraphimWeapons.SAALosaareAutoCannonWeapon
local SB0OhwalliExperimentalStrategicBombWeapon = SeraphimWeapons.SB0OhwalliExperimentalStrategicBombWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local explosion = import('/lua/defaultexplosions.lua')

XSA0402 = Class(SAirUnit) {
    DestroyNoFallRandomChance = 1.1,
    
    Weapons = {
        Bomb = Class(SB0OhwalliExperimentalStrategicBombWeapon) {},
        RightFrontAutocannon = Class(SAALosaareAutoCannonWeapon) {},
        LeftFrontAutocannon = Class(SAALosaareAutoCannonWeapon) {},
        RightRearAutocannon = Class(SAALosaareAutoCannonWeapon) {},
        LeftRearAutocannon = Class(SAALosaareAutoCannonWeapon) {},
    },
    
    ContrailEffects = {'/effects/emitters/contrail_ser_ohw_polytrail_01_emit.bp',},

    StartBeingBuiltEffects = function(self, builder, layer)
		SAirUnit.StartBeingBuiltEffects(self, builder, layer)
		self:ForkThread( EffectUtil.CreateSeraphimExperimentalBuildBaseThread, builder, self.OnBeingBuiltEffectsBag )
    end,    
}
TypeClass = XSA0402
