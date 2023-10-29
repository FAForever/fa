---@class TacticalDebris01 : GenericDebris
TacticalDebris01 = ClassDummyProjectile(import("/lua/genericdebris.lua").GenericDebris) {
    FxTrails = import("/lua/EffectTemplates.lua").TacticalDebrisTrails01,
}
TypeClass = TacticalDebris01
