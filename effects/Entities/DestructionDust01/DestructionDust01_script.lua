local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile
DestructionDust01 = Class(EmitterProjectile) {
    FxTrails = {'/effects/emitters/terran_bomber_dust_blanket_01_emit.bp',},
}
TypeClass = DestructionDust01