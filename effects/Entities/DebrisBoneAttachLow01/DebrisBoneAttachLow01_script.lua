local GenericDebris = import("/lua/genericdebris.lua").GenericDebris

---@class DebrisBoneAttachHigh01 : GenericDebris
DebrisBoneAttachLow01 = ClassDummyProjectile(GenericDebris) {
    FxUnitHitScale = 0.25,
    FxUnderWaterHitScale = 0.25,
    FxNoneHitScale = 0.25,
    FxWaterHitScale = 0.25,
    FxLandHitScale = 0.5,
    FxTrails = { },
    FxTrailScale = 1,
}
TypeClass = DebrisBoneAttachLow01