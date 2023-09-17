-- 
-- URS0304 : cybran nuke sub
-- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
-- 
local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile
local TacticalMissileComponent = import('/lua/sim/DefaultProjectiles.lua').TacticalMissileComponent

CIFMissileTactical02 = ClassProjectile(CLOATacticalMissileProjectile, TacticalMissileComponent) {

    NumChildMissiles = 3,
    FxWaterHitScale = 1.65,

    LaunchTicks = 6,
    LaunchTurnRate = 6,
    HeightDistanceFactor = 5,
    MinHeight = 5,
    FinalBoostAngle = 0,

    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Split = false
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,

    OnImpact = function(self, targetType, targetEntity)
        CreateLightParticle( self, -1, self.Army, 3, 7, 'glow_03', 'ramp_fire_11' )

        -- if I collide with terrain dont split
        if targetType != 'Projectile' then
            self.Split = true
        end

        CLOATacticalMissileProjectile.OnImpact(self, targetType, targetEntity)
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        if not self.Split and (amount >= self:GetHealth()) then
            self.Split = true
            local vx, vy, vz = self:GetVelocity()
            local velocity = 7
            local ChildProjectileBP = '/projectiles/CIFMissileTacticalSplit01/CIFMissileTacticalSplit01_proj.bp'
            local angle = (2*math.pi) / self.NumChildMissiles
            local spreadMul = 0.5  -- Adjusts the width of the dispersal        

            self.DamageData.DamageAmount = self.Launcher.Blueprint.SplitDamage.DamageAmount or 0
            self.DamageData.DamageRadius = self.Launcher.Blueprint.SplitDamage.DamageRadius or 1

            -- Launch projectiles at semi-random angles away from split location
            for i = 0, (self.NumChildMissiles - 1) do
                local xVec = vx + math.sin(i*angle) * spreadMul
                local yVec = vy + math.cos(i*angle) * spreadMul
                local zVec = vz + math.cos(i*angle) * spreadMul
                local proj = self:CreateChildProjectile(ChildProjectileBP)
                proj:SetVelocity(xVec,yVec,zVec)
                proj:SetVelocity(velocity)
                proj.DamageData = self.DamageData
            end
        end
        CLOATacticalMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
    end,

    OnExitWater = function(self)
        CLOATacticalMissileProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CIFMissileTactical02

