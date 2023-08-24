local GenericDebris = import("/lua/genericdebris.lua").GenericDebris
DebrisBoneAttachHigh01 = ClassDummyProjectile(GenericDebris) {
    FxUnitHitScale = 0.25,
    FxWaterHitScale = 0.25,
    FxUnderWaterHitScale = 0.25,
    FxNoneHitScale = 0.25,
    FxLandHitScale = 0.5,
    FxTrails = { },
    FxTrailScale = 1,
}
TypeClass = DebrisBoneAttachHigh01