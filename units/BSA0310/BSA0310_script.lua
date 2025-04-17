#****************************************************************************
#**
#**  File     :  /cdimage/units/UAA0203/UAA0203_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos
#**
#**  Summary  :  Seraphim Gunship Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit

local SAALightningWeapon = import("/lua/seraphimweapons.lua").SAALightningWeapon
local SANHeavyCavitationTorpedo = import("/lua/seraphimweapons.lua").SANHeavyCavitationTorpedo
local LightningSmallSurfaceCollisionBeam = import("/lua/sim/collisionBeams/LightningSmallSurfaceCollisionBeam.lua").LightningSmallSurfaceCollisionBeam

BSA0310 = Class(SAirUnit) {
    Weapons = {
         PhasonBeamGround = ClassWeapon(SAALightningWeapon){
            BeamType = LightningSmallSurfaceCollisionBeam,
            FxBeamEndPointScale = 0.01,
        },
        TurretLeft = ClassWeapon(SANHeavyCavitationTorpedo) {},
        TurretRight = ClassWeapon(SANHeavyCavitationTorpedo) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        SAirUnit.OnStopBeingBuilt(self,builder,layer)
        local army = self.Army

        CreateAttachedEmitter(self, "Orb", army, "/effects/emitters/orbeffect_01.bp")
        CreateAttachedEmitter(self, "Orb", army, "/effects/emitters/orbeffect_02.bp")
    end,

}

TypeClass = BSA0310

local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam