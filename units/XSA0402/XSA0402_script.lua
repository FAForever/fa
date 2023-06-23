--****************************************************************************
--**
--**  File     :  /units/XSA0402/XSA0402_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Seraphim Experimental Strategic Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SAALosaareAutoCannonWeapon = SeraphimWeapons.SAALosaareAutoCannonWeapon
local SB0OhwalliExperimentalStrategicBombWeapon = SeraphimWeapons.SB0OhwalliExperimentalStrategicBombWeapon
local CreateSeraphimExperimentalBuildBaseThread = import("/lua/effectutilitiesseraphim.lua").CreateSeraphimExperimentalBuildBaseThread
local explosion = import("/lua/defaultexplosions.lua")

---@class XSA0402 : SAirUnit
XSA0402 = ClassUnit(SAirUnit) {
    DestroyNoFallRandomChance = 1.1,
    
    Weapons = {
        Bomb = ClassWeapon(SB0OhwalliExperimentalStrategicBombWeapon) {},
        RightFrontAutocannon = ClassWeapon(SAALosaareAutoCannonWeapon) {},
        LeftFrontAutocannon = ClassWeapon(SAALosaareAutoCannonWeapon) {},
        RightRearAutocannon = ClassWeapon(SAALosaareAutoCannonWeapon) {},
        LeftRearAutocannon = ClassWeapon(SAALosaareAutoCannonWeapon) {},
    },
    
    ContrailEffects = {'/effects/emitters/contrail_ser_ohw_polytrail_01_emit.bp',},

    OnKilled = function(self, instigator, type, overkillRatio)
        self.detector = CreateCollisionDetector(self)
        self.Trash:Add(self.detector)
        self.detector:WatchBone('Nose_Extent')
        self.detector:WatchBone('Right_Wing_Extent')
        self.detector:WatchBone('Left_Wing_Extent')
        self.detector:WatchBone('Tail_Extent')
        self.detector:EnableTerrainCheck(true)
        self.detector:Enable()
        
        SAirUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnAnimTerrainCollision = function(self, bone,x,y,z)
        local position = {x, y, z}
        DamageArea(self, position, 5, 1000, 'Default', true, false)
        DamageArea(self, position, 5, 1, 'TreeForce', false)
        explosion.CreateDefaultHitExplosionAtBone( self, bone, 5.0 )
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {self:GetUnitSizes()})
    end,
    
    StartBeingBuiltEffects = function(self, builder, layer)
		SAirUnit.StartBeingBuiltEffects(self, builder, layer)
		self:ForkThread( CreateSeraphimExperimentalBuildBaseThread, builder, self.OnBeingBuiltEffectsBag, 0.5 )
    end,    
}
TypeClass = XSA0402