-- UEF T3 Artillery Anti-Matter Shells : ueb2302

local TArtilleryAntiMatterProjectile02 = import("/lua/terranprojectiles.lua").TArtilleryAntiMatterProjectile02
TIFAntiMatterShells01 = ClassProjectile(TArtilleryAntiMatterProjectile02) {
    OnImpact = function(self, targetType, targetEntity)
        TArtilleryAntiMatterProjectile02.OnImpact(self, targetType, targetEntity)
        self:ShakeCamera(20, 2, 0, 1)
    end,
}
TypeClass = TIFAntiMatterShells01