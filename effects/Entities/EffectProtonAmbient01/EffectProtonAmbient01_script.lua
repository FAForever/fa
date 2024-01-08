local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

---@class EffectProtonAmbient01 : EmitterProjectile
EffectProtonAmbient01 = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/proton_bomb_hit_03_emit.bp',},
}
TypeClass = EffectProtonAmbient01