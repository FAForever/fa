local GenericDebris = import("/lua/genericdebris.lua").GenericDebris

---@class TacticalDebris03 : GenericDebris
TacticalDebris03 = ClassDummyProjectile(GenericDebris) {
    FxTrails = import("/lua/effecttemplates.lua").TacticalDebrisTrails03,
}
TypeClass = TacticalDebris03