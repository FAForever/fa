local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

---@class SCUDeathShockwave01 : EmitterProjectile
SCUDeathShockwave01 = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/shockwave_smoke_01_emit.bp',},
}
TypeClass = SCUDeathShockwave01