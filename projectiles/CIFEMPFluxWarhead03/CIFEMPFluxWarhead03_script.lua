local EmitterProjectile = import("/lua/sim/defaultprojectiles.lua").EmitterProjectile

-- Fire Plume Test Projectile Script
---@class CIFEMPFluxWarhead03: EmitterProjectile
CIFEMPFluxWarhead03 = ClassProjectile(EmitterProjectile) {
    FxTrails = {'/effects/emitters/empfluxwarhead_04_emit.bp',},
}
TypeClass = CIFEMPFluxWarhead03