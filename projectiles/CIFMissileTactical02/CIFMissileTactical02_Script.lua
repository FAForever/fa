-- 
-- URS0304 : cybran nuke sub
-- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
-- 
local CLOATacticalMissileProjectile = import('/lua/cybranprojectiles.lua').CLOATacticalMissileProjectile

CIFMissileTactical02 = Class(CLOATacticalMissileProjectile) {

    NumChildMissiles = 3,
    FxWaterHitScale = 1.65,

    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Split = false
        self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )        
    end,
    
    PassDamageData = function(self, damageData)
        CLOATacticalMissileProjectile.PassDamageData(self,damageData)
        local launcherbp = self.Launcher.Blueprint  
        self.ChildDamageData = table.copy(self.DamageData)
        self.ChildDamageData.DamageAmount = launcherbp.SplitDamage.DamageAmount or 0
        self.ChildDamageData.DamageRadius = launcherbp.SplitDamage.DamageRadius or 1   
    end,    
    
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army
        local radius = self.DamageData.DamageRadius
        local pos = self:GetPosition()
        local FriendlyFire = self.DamageData.DamageFriendly
        
        CreateLightParticle( self, -1, army, 3, 7, 'glow_03', 'ramp_fire_11' )
        
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        
        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', radius * 2.5, radius * 2.5, 200, 90, army)
        end
        
        -- if I collide with terrain dont split
        if targetType ~= 'Projectile' then
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

            -- Launch projectiles at semi-random angles away from split location
            for i = 0, (self.NumChildMissiles - 1) do
                local xVec = vx + math.sin(i*angle) * spreadMul
                local yVec = vy + math.cos(i*angle) * spreadMul
                local zVec = vz + math.cos(i*angle) * spreadMul
                local proj = self:CreateChildProjectile(ChildProjectileBP)
                proj:SetVelocity(xVec,yVec,zVec)
                proj:SetVelocity(velocity)
                proj:PassDamageData(self.ChildDamageData)
            end
        end
        CLOATacticalMissileProjectile.OnDamage(self, instigator, amount, vector, damageType)
    end,

    MovementThread = function(self)
        self.WaitTime = 0.1
        self:SetTurnRate(8)
        WaitSeconds(0.3)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 50 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitSeconds(2)
            self:SetTurnRate(20)
        elseif dist > 64 and dist <= 107 then
            -- Increase check intervals
            self:SetTurnRate(30)
            WaitSeconds(1.5)
            self:SetTurnRate(30)
        elseif dist > 21 and dist <= 64 then
            -- Further increase check intervals
            WaitSeconds(0.3)
            self:SetTurnRate(50)
        elseif dist > 0 and dist <= 21 then
            -- Further increase check intervals            
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

    OnExitWater = function(self)
        CLOATacticalMissileProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CIFMissileTactical02

