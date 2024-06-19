local GenericDebris = import("/lua/genericdebris.lua").GenericDebris

---@class DebrisBoneAttachChassis01 : GenericDebris
DebrisBoneAttachChassis01 = ClassDummyProjectile(GenericDebris) {
    FxLandHitScale = 1.0,
    FxTrails = { },
    FxTrailScale = 1,
}
TypeClass = DebrisBoneAttachChassis01