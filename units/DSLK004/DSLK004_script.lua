------------------------------------------------------------------------------
-- Author(s):  Mikko Tyster, Atte Hulkkonen
-- Summary  :  Seraphim T3 Mobile Lightning Anti-Air
-- Copyright © 2008 Blade Braver!
------------------------------------------------------------------------------

local weapons = import("/lua/seraphimweapons.lua")
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local PhasonCollisionBeam2 = weapons.PhasonBeam2
local PhasonBeam = weapons.PhasonBeam

---@class DSLK004 : SLandUnit
DSLK004 = ClassUnit(SLandUnit) {
    Weapons = {
        PhasonBeamAir = ClassWeapon(PhasonBeam) {},
        PhasonBeamGround = ClassWeapon(PhasonBeam) {
            BeamType = PhasonCollisionBeam2,
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