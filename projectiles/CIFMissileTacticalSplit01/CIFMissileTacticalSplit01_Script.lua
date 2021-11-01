-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetDamage = ProjectileMethods.SetDamage
local ProjectileMethodsSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
local ProjectileMethodsSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileMethodsTrackTarget = ProjectileMethods.TrackTarget
-- End of automatically upvalued moho functions

#
# Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
# enemy anti-missile systems
#
local CLOATacticalChildMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalChildMissileProjectile

CIFMissileTacticalSplit01 = Class(CLOATacticalChildMissileProjectile)({

    OnCreate = function(self)
        CLOATacticalChildMissileProjectile.OnCreate(self)
        EntityMethodsSetCollisionShape(self, 'Sphere', 0, 0, 0, 2.5)
        ProjectileMethodsSetDamage(self, 25)
        self.invincible = true
        self:ForkThread(self.DelayForDestruction)
    end,

    # Give the projectile enough time to get out of the explosion
    DelayForDestruction = function(self)
        self.CanTakeDamage = false
        WaitSeconds(0.3)
        self.invincible = false
        self.CanTakeDamage = true
        ProjectileMethodsSetDestroyOnWater(self, true)
        ProjectileMethodsTrackTarget(self, true)
        ProjectileMethodsSetTurnRate(self, 80)
        #25
        ProjectileMethodsSetMaxSpeed(self, 15)
        #25
        self:SetAcceleration(6)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.invincible then
            CLOATacticalChildMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
        end
    end,
})
TypeClass = CIFMissileTacticalSplit01