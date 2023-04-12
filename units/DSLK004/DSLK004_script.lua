------------------------------------------------------------------------------
-- Author(s):  Mikko Tyster, Atte Hulkkonen
-- Summary  :  Seraphim T3 Mobile Lightning Anti-Air
-- Copyright © 2008 Blade Braver!
------------------------------------------------------------------------------
local SLandUnit = import("/lua/seraphimunits.lua").SLandUnit
local CollisionBeam = import("/lua/seraphimweapons.lua").PhasonCollisionBeam2
local PhasonBeam = import("/lua/seraphimweapons.lua").PhasonBeam

---@class DSLK004 : SLandUnit
DSLK004 = ClassUnit(SLandUnit) {
    Weapons = {
        PhasonBeamAir = ClassWeapon(PhasonBeam) {},
        PhasonBeamGround = ClassWeapon(PhasonBeam) {
            BeamType = CollisionBeam,
            FxBeamEndPointScale = 0.01,
        },
    },

    OnStopBeingBuilt = function(self, builder, layer)
        SLandUnit.OnStopBeingBuilt(self, builder, layer)

        local EfctTempl = {
            '/Effects/Emitters/orbeffect_01.bp',
            '/Effects/Emitters/orbeffect_02.bp',
        }
        for k, v in EfctTempl do
            CreateAttachedEmitter(self, 'Orb', self.Army, v)
        end
    end,
}
TypeClass = DSLK004

--- Kept for mod support
local DefaultBeamWeapon = import("/lua/sim/defaultweapons.lua").DefaultBeamWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")
local SCCollisionBeam = import("/lua/defaultcollisionbeams.lua").SCCollisionBeam