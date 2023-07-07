-- Aeon quantum 'bolt'
local AQuantumCannonProjectile = import("/lua/aeonprojectiles.lua").AQuantumCannonProjectile

---@class ADFQuantumCannon02: AQuantumCannonProjectile
ADFQuantumCannon02 = ClassProjectile(AQuantumCannonProjectile) {
    FxTrails = {
        '/effects/emitters/quantum_cannon_munition_05_emit.bp',
        '/effects/emitters/quantum_cannon_munition_06_emit.bp',},
}
TypeClass = ADFQuantumCannon02