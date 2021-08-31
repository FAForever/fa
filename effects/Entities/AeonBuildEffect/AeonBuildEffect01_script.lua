#
# script for projectile BoneAttached
#
local NullShell = import('/lua/sim/defaultprojectiles.lua').NullShell

AeonBuildEffect01 = Class(NullShell) {
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,
}

TypeClass =AeonBuildEffect01

