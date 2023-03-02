--
-- Aeon Quantum Distortion Warhead
--
local AQuantumWarheadProjectile = import("/lua/aeonprojectiles.lua").AQuantumWarheadProjectile

AIFQuantumWarhead01 = Class(AQuantumWarheadProjectile) {
    OnCreate = function(self)
        AQuantumWarheadProjectile.OnCreate(self)
        self.effectEntityPath = '/projectiles/AIFQuantumWarhead02/AIFQuantumWarhead02_proj.bp'
        self:LauncherCallbacks()
    end,
}

TypeClass = AIFQuantumWarhead01