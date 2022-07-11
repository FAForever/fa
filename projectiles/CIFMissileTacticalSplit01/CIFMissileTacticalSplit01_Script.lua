--
-- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
-- enemy anti-missile systems
--
local CLOATacticalChildMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalChildMissileProjectile

CIFMissileTacticalSplit01 = Class(CLOATacticalChildMissileProjectile) {

    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.5)
        self:SetDamage(25)
        self.invincible = true
        self:ForkThread(self.DelayForDestruction)
    end,

    -- Give the projectile enough time to get out of the explosion
    DelayForDestruction = function(self)
        self.CanTakeDamage = false
        WaitSeconds(0.3)
        self.invincible = false
        self.CanTakeDamage = true
        self:SetDestroyOnWater(true)
        self:TrackTarget(true)
        self:SetTurnRate(80)
        self:SetMaxSpeed(15)--25
        self:SetAcceleration(6)--25
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.invincible then
            CLOATacticalChildMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
        end
    end,
}
TypeClass = CIFMissileTacticalSplit01