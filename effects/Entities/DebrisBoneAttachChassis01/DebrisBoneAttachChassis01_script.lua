-- script for projectile BoneAttached
local GenericDebris = import("/lua/genericdebris.lua").GenericDebris
DebrisBoneAttachChassis01 = ClassDummyProjectile(GenericDebris) {
    FxLandHitScale = 1.0,
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,
    FxTrailScale = 1,
}
TypeClass = DebrisBoneAttachChassis01
