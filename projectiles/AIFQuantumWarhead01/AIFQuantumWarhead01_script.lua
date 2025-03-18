local AQuantumWarheadProjectile = import("/lua/aeonprojectiles.lua").AQuantumWarheadProjectile

-- Aeon Quantum Distortion Warhead
---@class AIFQuantumWarhead01 : AQuantumWarheadProjectile
AIFQuantumWarhead01 = ClassProjectile(AQuantumWarheadProjectile) {

    ---@param self AIFQuantumWarhead01
    OnCreate = function(self)
        AQuantumWarheadProjectile.OnCreate(self)
        self.effectEntityPath = '/projectiles/AIFQuantumWarhead02/AIFQuantumWarhead02_proj.bp'
        self:LauncherCallbacks()
    end,
}
TypeClass = AIFQuantumWarhead01