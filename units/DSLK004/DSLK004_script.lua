------------------------------------------------------------------------------
-- Author(s):  Mikko Tyster, Atte Hulkkonen
-- Summary  :  Seraphim T3 Mobile Lightning Anti-Air
-- Copyright © 2008 Blade Braver!
------------------------------------------------------------------------------

local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit

local SAALightningWeapon = import("/lua/seraphimweapons.lua").SAALightningWeapon
local LightningSmallSurfaceCollisionBeam = import("/lua/sim/collisionBeams/LightningSmallSurfaceCollisionBeam.lua").LightningSmallSurfaceCollisionBeam

---@class DSLK004 : SLandUnit
DSLK004 = ClassUnit(SLandUnit) {
    Weapons = {
        PhasonBeamAir = ClassWeapon(SAALightningWeapon){},
        PhasonBeamGround = ClassWeapon(SAALightningWeapon){
            BeamType = LightningSmallSurfaceCollisionBeam,
            FxBeamEndPointScale = 0.01,
        },
    },

    OnStopBeingBuilt = function(self,builder,layer)
        SLandUnit.OnStopBeingBuilt(self,builder,layer)
        local army = self.Army


        local EfctTempl = {
            '/Effects/Emitters/orbeffect_01.bp',
            '/Effects/Emitters/orbeffect_02.bp',
        }
        for k, v in EfctTempl do
            CreateAttachedEmitter(self, 'Orb', army, v)
        end
    end,
}

TypeClass = DSLK004

-- kept for backwards compatibility
local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local CollisionBeam = import("/lua/sim/collisionbeam.lua").CollisionBeam
local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam