local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

-- ## URS0304 : cybran nuke sub
-- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
---@class CIFMissileTactical02 : CLOATacticalMissileProjectile
CIFMissileTactical02 = ClassProjectile(CLOATacticalMissileProjectile) {

    NumChildMissiles = 3,
    FxWaterHitScale = 1.65,

    ---@param self CIFMissileTactical02
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Split = false
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,

    ---@param self CIFMissileTactical02
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        CreateLightParticle( self, -1, self.Army, 3, 7, 'glow_03', 'ramp_fire_11' )

        -- if I collide with terrain dont split
        if targetType != 'Projectile' then
            self.Split = true
        end

        CLOATacticalMissileProjectile.OnImpact(self, targetType, targetEntity)
    end,

    ---@param self CIFMissileTactical02
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType string
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

    ---@param self CIFMissileTactical02 
    MovementThread = function(self)
        self:SetTurnRate(8)
        WaitTicks(4)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    ---@param self CIFMissileTactical02
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 50 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(20)
        elseif dist > 64 and dist <= 107 then
            -- Increase check intervals
            self:SetTurnRate(30)
            WaitTicks(16)
            self:SetTurnRate(30)
        elseif dist > 21 and dist <= 64 then
            -- Further increase check intervals
            WaitTicks(4)
            self:SetTurnRate(50)
        elseif dist > 0 and dist <= 21 then
            -- Further increase check intervals            
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,        

    ---@param self CIFMissileTactical02
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

    ---@param self CIFMissileTactical02
    OnExitWater = function(self)
        CLOATacticalMissileProjectile.OnExitWater(self)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CIFMissileTactical02

