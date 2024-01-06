local AQuantumWarheadProjectile = import("/lua/aeonprojectiles.lua").AQuantumWarheadProjectile

-- Aeon Quantum Distortion Warhead, nuke launched
---@class AIFQuantumWarhead03 : AQuantumWarheadProjectile
AIFQuantumWarhead03 = ClassProjectile(AQuantumWarheadProjectile) {
    Beams = {'/effects/emitters/aeon_nuke_exhaust_beam_02_emit.bp',},

    ---@param self AIFQuantumWarhead03
    OnCreate = function(self)
        AQuantumWarheadProjectile.OnCreate(self)
        self.effectEntityPath = '/projectiles/AIFQuantumWarhead02/AIFQuantumWarhead02_proj.bp'
        self:LauncherCallbacks()
    end,
}
TypeClass = AIFQuantumWarhead03