--
-- Aeon Very Fast Anti-Missile Missile
--
local AIMFlareProjectile = import("/lua/aeonprojectiles.lua").AIMFlareProjectile

---@class AIMAntiMissile01 : AIMFlareProjectile
AIMAntiMissile01 = ClassProjectile(AIMFlareProjectile) {

    ---@param self AIMAntiMissile01
    OnCreate = function(self)
        AIMFlareProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,
}

TypeClass = AIMAntiMissile01

