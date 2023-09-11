-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local Projectile = import("/lua/sim/projectile.lua").Projectile
local DummyProjectile = import("/lua/sim/projectile.lua").DummyProjectile
local UnitsInSphere = import("/lua/utilities.lua").GetTrueEnemyUnitsInSphere
local GetDistanceBetweenTwoEntities = import("/lua/utilities.lua").GetDistanceBetweenTwoEntities
local OCProjectiles = {}

-- shared between sim and ui
local OverchargeShared = import("/lua/shared/overcharge.lua")

-- upvalue globals for performance
local Random = Random
local CreateTrail = CreateTrail
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateBeamEmitterOnEntity = CreateBeamEmitterOnEntity
local VDist2 = VDist2
local MathPow = math.pow
local MathSqrt = math.sqrt

local TableGetn = table.getn

-- upvalue moho functions for performance
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter

-----------------------------------------------------------------
-- Null Shell
-----------------------------------------------------------------

---@class NullShell : Projectile
NullShell = ClassProjectile(Projectile) {}

-----------------------------------------------------------------
-- PROJECTILE WITH ATTACHED EFFECT EMITTERS
-----------------------------------------------------------------

---@class EmitterProjectile : Projectile
EmitterProjectile = ClassProjectile(Projectile) {
    FxTrails = {'/effects/emitters/missile_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,

    ---@param self EmitterProjectile
    OnCreate = function(self)
        Projectile.OnCreate(self)

        local effect
        for i in self.FxTrails do
            effect = CreateEmitterOnEntity(self, self.Army, self.FxTrails[i])

            -- only do these engine calls when they matter
            if self.FxTrailScale ~= 1 then 
                IEffectScaleEmitter(effect, self.FxTrailScale)
            end

            if self.FxTrailOffset ~= 1 then 
                IEffectOffsetEmitter(effect, 0, 0, self.FxTrailOffset)
            end
        end
    end,
}

-----------------------------------------------------------------
-- BEAM PROJECTILES
-----------------------------------------------------------------

---@class SingleBeamProjectile : EmitterProjectile
SingleBeamProjectile = ClassProjectile(EmitterProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = { },

    ---@param self SingleBeamProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        if self.BeamName then
            CreateBeamEmitterOnEntity(self, -1, self.Army, self.BeamName)
        end
    end,
}

---@class MultiBeamProjectile : EmitterProjectile
MultiBeamProjectile = ClassProjectile(EmitterProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    FxTrails = { },

    ---@param self MultiBeamProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        local beam = nil
        for k, v in self.Beams do
            CreateBeamEmitterOnEntity(self, -1, self.Army, v)
        end
    end,
}

--- Semi-Ballistic Component
---@class SemiBallisticComponent
SemiBallisticComponent = ClassSimple {

    --- This is called whenever we're changing our trajectory (generally twice)
    --- It updates the generic data we need to calculate our trajectory
    --- Avoids redundant function calls in the subordinate functions
    --UpdateFlightState = function(self)
    --    self.ux, self.uy, self.uz = self:GetVelocity()
    --- For a projectile that starts under acceleration, 
    --- but needs to calculate a ballistic trajectory mid-flight
    CalculateBallisticAcceleration = function(self, maxSpeed)
        local ux, uy, uz = self:GetVelocity()
        local s0 = self:GetPosition()
        local target = self:GetCurrentTargetPosition()
        local dist = VDist2(target[1], target[3], s0[1], s0[3])

        -- we need velocity in m/s, not in m/tick
        local ux, uy, uz = ux*10, uy*10, uz*10
    
        local timeToImpact = dist / MathSqrt(MathPow(ux, 2) + MathPow(uz, 2))
        local ballisticAcceleration = (2 * ((target[2] - s0[2]) - uy * timeToImpact)) / MathPow(timeToImpact, 2)

        -- need to do a second pass, because ballistic acceleration doesn't account for max speed
        return ballisticAcceleration, timeToImpact
    end,

    TurnRateFromDistance = function(self)

        local dist = self:DistanceToTarget()
        local targetVector = VDiff(self:GetCurrentTargetPosition(), self:GetPosition())
        local ux, uy, uz = self:GetVelocity()
        local velocityVector = Vector(ux, uy, uz)
        local speed = self:GetCurrentSpeed()

        local theta = math.acos(VDot(targetVector, velocityVector) / (speed * dist))
        --local radius = dist/(2 * math.sin(theta))
        local arcLength = 2 * theta * dist/(2 * math.sin(theta))
        local arcTime = arcLength / self:AverageSpeedOverDistance(arcLength, self:GetBlueprint().Physics.Acceleration)

        local degreesPerSecond = 2 * theta / arcTime * ( 180 / math.pi )
        return degreesPerSecond
    end,

    AverageSpeedOverDistance = function(self, dist, acceleration)
        local speed = self:GetCurrentSpeed()*10
        local maxSpeed = self:GetBlueprint().Physics.MaxSpeed
        local accelerationTime = (maxSpeed - speed) / acceleration
        local accelerationDistance = (speed + maxSpeed) / 2 * accelerationTime
        if dist < accelerationDistance then
            -- we'll never reach max speed
            local timeToTarget = math.sqrt(2 * dist / acceleration)
            local averageSpeed = dist / timeToTarget
            return averageSpeed
        else
            -- we'll reach max speed
            local remainingDistance = dist - accelerationDistance
            local averageSpeed = (speed * accelerationDistance + maxSpeed * remainingDistance) / dist
            return averageSpeed
        end
    end,

    DistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist3(tpos, mpos)
    end,

    HorizontalDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    ElevationAngle = function(self, v)
        local vx, vy, vz
        if v then
            vx, vy, vz = v[1],v[2],v[3]
        else
            vx, vy, vz = self:GetVelocity()
        end
        local vh = VDist2(vx, vz, 0, 0)
        if vh == 0 then
            if vy >= 0 then
                return math.pi/2
            else
                return -math.pi/2
            end
        end
        return math.atan(vy / vh)
    end,

    -- as we turn from our current elevation angle to the target elevation angle,
    -- what will our average vertical velocity be?
    -- (we can use that number to calculate how long the turn should take, and therefore the turn rate)
    AverageVerticalVelocityThroughTurn = function(self, targetAngle, currentAngle)
        local averageVerticalVelocity = 1/(targetAngle-currentAngle) * (math.cos(currentAngle) - math.cos(targetAngle))
        averageVerticalVelocity = averageVerticalVelocity * self:GetBlueprint().Physics.MaxSpeed
        return averageVerticalVelocity
    end,

    TurnRateFromAngleAndDistance = function(self, targetAngleDegrees, maxHeight)

        local targetAngle = targetAngleDegrees * math.pi/180
        local currentAngle = self:ElevationAngle()
        local deltaY = maxHeight - self:GetPosition()[2]
        if deltaY < self.minHeight then
            deltaY = self.minHeight
        end
        local turnTime = deltaY/self:AverageVerticalVelocityThroughTurn(targetAngle, currentAngle)

        local degreesPerSecond = math.abs(targetAngle - currentAngle)/turnTime * 180/math.pi
        return degreesPerSecond, turnTime
    end,

    -- optimal highest point of the trajectory based on the heightDistanceFactor
    OptimalMaxHeight = function(self)
        local horizDist = self:HorizontalDistanceToTarget()
        local targetHeight = self:GetCurrentTargetPosition()[2]
        local maxHeight = targetHeight + horizDist/self.heightDistanceFactor
        return maxHeight
    end,

}

--- Tactical Missile
---@class TacticalMissileProjectile : NullShell
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {

    -- default trajectory parameters

    -- how long we spend in the launch phase
    launchTicks = 2,

    -- inital launch phase turn rate, gives a little turnover coming out of the tube
    launchTurnRate = 8,

    -- each missile calculates an optimal highest point of its trajectory based on its distance to the target
    -- this is the factor that determines how high above the target that point is, in relation to the horizontal distance
    -- a higher number will result in a lower trajectory
    heightDistanceFactor = 5,

    -- minimum height of the high point of the trajectory
    -- measured from the position of the missile at the end of the launch phase
    minHeight = 2,

    -- angle in degrees that we'll aim to be at the end of the boost phase
    -- 90 is vertical, 0 is horizontal
    targetFinalBoostAngle = 0,

    ---@param self TacticalMissileProjectile
    MovementThread = function(self)

        -- launch
        self:SetTurnRate(self.launchTurnRate)
        WaitTicks(self.launchTicks)

        -- boost
        self.boostTurnRate, self.boostTime = self:TurnRateFromAngleAndDistance(self.targetFinalBoostAngle, self:OptimalMaxHeight())
        self:SetTurnRate(self.boostTurnRate)
        WaitTicks(self.boostTime * 10)
        

        -- glide
        LOG('Glide phase')
        LOG('Elevation angle: ', self:ElevationAngle()*180/math.pi)
        -- self:SetAcceleration(0)

        -- turn rate sufficiently high to keep us aligned with the direction of travel during the ballistic phase
        self:SetTurnRate(self:TurnRateFromDistance())
    end,

}
--- Nukes
---@class NukeProjectile : NullShell
NukeProjectile = ClassProjectile(NullShell) {
    ---@param self NukeProjectile
    MovementThread = function(self)
		self.Nuke = true
        self:CreateEffects(self.InitialEffects, self.Army, 1)
        self:TrackTarget(false)
        WaitTicks(26) -- Height
        self:SetCollision(true)
        self:CreateEffects(self.LaunchEffects, self.Army, 1)
        WaitTicks(26)
        self:CreateEffects(self.ThrustEffects, self.Army, 3)
        WaitTicks(26)
        self:TrackTarget(true) -- Turn ~90 degrees towards target
        self:SetDestroyOnWater(true)
        self:SetTurnRate(45)
        WaitTicks(21) -- Now set turn rate to zero so nuke flies straight
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        self.WaitTime = 6 -- start at 0.5; `SetTurnRateByDist` will decrease this as we get closer
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(self.WaitTime)
        end
    end,

    --- Sets the turn rate to angle the nuke down if it gets close to the target (or stops turning
    --- if too far). Otherwise, decreases `WaitTime` as it gets closer to the target.
    ---@param self NukeProjectile
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 150 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            self:SetTurnRate(0)
        elseif dist > 75 and dist <= 150 then
            -- Decrease check interval
            self.WaitTime = 4
        elseif dist > 32 and dist <= 75 then
            -- Further decrease check interval
            self.WaitTime = 2
        elseif dist < 32 then
            -- Turn the missile down
            self:SetTurnRate(50)
        end
    end,

    --- Gets the horizontal distance from the nuke to the current target position
    ---@param self NukeProjectile
    ---@return number
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

    ---@param self NukeProjectile
    ---@param EffectTable FileName[]
    ---@param army Army
    ---@param scale number
    CreateEffects = function(self, EffectTable, army, scale)
        if not EffectTable then return end
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

    ---@param self NukeProjectile
    ForceThread = function(self)
        -- Knockdown force rings
        local position = self:GetPosition()
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
        WaitTicks(2)
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
    end,

    ---@param self NukeProjectile
    ---@param TargetType string
    ---@param TargetEntity Unit | Prop
    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE * categories.ANTIMISSILE * categories.TECH3, TargetEntity) then
            local myBlueprint = self.Blueprint
            if myBlueprint.Audio.NukeExplosion then
                self:PlaySound(myBlueprint.Audio.NukeExplosion)
            end

            self.effectEntity = self:CreateProjectile(self.effectEntityPath, 0, 0, 0, nil, nil, nil):SetCollision(false)
            self.effectEntity:ForkThread(self.effectEntity.EffectThread)
            self.Trash:Add(ForkThread(self.ForceThread,self))
        end
        NullShell.OnImpact(self, TargetType, TargetEntity)
    end,

    ---@param self NukeProjectile
    LauncherCallbacks = function(self)
        local launcher = self.Launcher
        if launcher and not launcher.Dead and launcher.EventCallbacks.ProjectileDamaged then
            self.ProjectileDamaged = {}
            for k,v in launcher.EventCallbacks.ProjectileDamaged do
                table.insert(self.ProjectileDamaged, v)
            end
        end
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    ---@param self NukeProjectile
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k,v in self.ProjectileDamaged do
                v(self)
            end
        end
        NullShell.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,

    ---@param self NukeProjectile
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
		local bp = self.Blueprint.Defense.MaxHealth
			if bp then
			self:DoTakeDamage(instigator, amount, vector, damageType)
		else
			self:OnKilled(instigator, damageType)
		end
    end,
}

-----------------------------------------------------------------
-- POLY-TRAIL PROJECTILES
-----------------------------------------------------------------

---@class SinglePolyTrailProjectile : EmitterProjectile
SinglePolyTrailProjectile = ClassProjectile(EmitterProjectile) {

    PolyTrail = '/effects/emitters/test_missile_trail_emit.bp',
    PolyTrailOffset = 0,
    FxTrails = { },

    ---@param self SinglePolyTrailProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        if self.PolyTrail ~= '' then
            local effect = CreateTrail(self, -1, self.Army, self.PolyTrail)

            -- only do these engine calls when they matter
            if self.PolyTrailOffset ~= 0 then 
                IEffectOffsetEmitter(effect, 0, 0, self.PolyTrailOffset)
            end
        end
    end,
}

---@class MultiPolyTrailProjectile : EmitterProjectile
MultiPolyTrailProjectile = ClassProjectile(EmitterProjectile) {

    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = { 0 },
    FxTrails = { },

    --- Count of how many are selected randomly for PolyTrail table
    RandomPolyTrails = 0,   

    ---@param self MultiPolyTrailProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        if self.PolyTrails then
            local effect
            local army = self.Army
            local NumPolyTrails = TableGetn(self.PolyTrails)

            if self.RandomPolyTrails ~= 0 then
                local index
                for i = 1, self.RandomPolyTrails do
                    index = Random(1, NumPolyTrails)
                    effect = CreateTrail(self, -1, army, self.PolyTrails[index])

                    -- only do these engine calls when they matter
                    if self.PolyTrailOffset[index] ~= 0 then 
                        IEffectOffsetEmitter(effect, 0, 0, self.PolyTrailOffset[index])
                    end
                end
            else
                for i = 1, NumPolyTrails do
                    effect = CreateTrail(self, -1, army, self.PolyTrails[i])

                    -- only do these engine calls when they matter
                    if self.PolyTrailOffset[i] ~= 0 then 
                        IEffectOffsetEmitter(effect, 0, 0, self.PolyTrailOffset[i])
                    end
                end
            end
        end
    end,
}

-----------------------------------------------------------------
-- COMPOSITE EMITTER PROJECTILES - MULTIPURPOSE PROJECTILES
-- - THAT COMBINES BEAMS, POLYTRAILS, AND NORMAL EMITTERS
-----------------------------------------------------------------

--- Lightweight Version That Limits Use To 1 Beam, polytrail and standard emitters
---@class SingleCompositeEmitterProjectile : SinglePolyTrailProjectile
SingleCompositeEmitterProjectile = ClassProjectile(SinglePolyTrailProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = { },

    ---@param self SingleCompositeEmitterProjectile
    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)

        if self.BeamName ~= '' then
            CreateBeamEmitterOnEntity(self, -1, self.Army, self.BeamName)
        end
    end,
}

--- Heavyweight Version, Allows for multiple beams, polytrails and standard emmiters
---@class MultiCompositeEmitterProjectile : MultiPolyTrailProjectile
MultiCompositeEmitterProjectile = ClassProjectile(MultiPolyTrailProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = { 0 },
    -- Count of how many are selected randomly for PolyTrail table
    RandomPolyTrails = 0,
    FxTrails = { },

    ---@param self MultiCompositeEmitterProjectile
    OnCreate = function(self)
        MultiPolyTrailProjectile.OnCreate(self)

        local beam = nil
        for k, v in self.Beams do
            CreateBeamEmitterOnEntity(self, -1, self.Army, v)
        end
    end,
}

-----------------------------------------------------------------
-- TRAIL ON ENTERING WATER PROJECTILE
-----------------------------------------------------------------

---@class OnWaterEntryEmitterProjectile : Projectile
OnWaterEntryEmitterProjectile = ClassProjectile(Projectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,
    PolyTrail = '',
    PolyTrailOffset = 0,
    TrailDelay = 2,
    EnterWaterSound = 'Torpedo_Enter_Water_01',
    FxEnterWater= {
        '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
        '/effects/emitters/water_splash_plume_01_emit.bp',
    },

    ---@param self OnWaterEntryEmitterProjectile
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        Projectile.OnCreate(self, inWater)

        if inWater then

            local effect 
            local army = self.Army

            for i in self.FxTrails do
                effect = CreateEmitterOnEntity(self, army, self.FxTrails[i])

                -- only do these engine calls when they matter
                if self.FxTrailScale ~= 1 then 
                    IEffectScaleEmitter(effect, self.FxTrailScale)
                end

                if self.FxTrailOffset ~= 1 then 
                    IEffectOffsetEmitter(effect, 0, 0, self.FxTrailOffset)
                end
            end

            if self.PolyTrail ~= '' then
                effect = CreateTrail(self, -1, army, self.PolyTrail)

                -- only do these engine calls when they matter
                if self.PolyTrailOffset ~= 0 then 
                    IEffectOffsetEmitter(effect, 0, 0, self.PolyTrailOffset)
                end
            end
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    EnterWaterThread = function(self)
        WaitTicks(self.TrailDelay)

        if IsDestroyed(self) then
            return
        end

        local army = self.Army
        local fxTrails = self.FxTrails
        local fxTrailScale = self.FxTrailScale
        local fxTrailOffset = self.FxTrailOffset
        local polyTrail = self.PolyTrail
        local polyTrailOffset = self.PolyTrailOffset

        for i in fxTrails do
            local effect = CreateEmitterOnEntity(self, army, fxTrails[i])

            -- only do these engine calls when they matter
            if fxTrailScale ~= 1 then
                IEffectScaleEmitter(effect, fxTrailScale)
            end

            if fxTrailOffset ~= 1 then
                IEffectOffsetEmitter(effect, 0, 0, fxTrailOffset)
            end
        end

        if polyTrail ~= '' then
            local effect = CreateTrail(self, -1, army, polyTrail)

            -- only do these engine calls when they matter
            if polyTrailOffset ~= 0 then
                IEffectOffsetEmitter(effect, 0, 0, polyTrailOffset)
            end
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    OnEnterWater = function(self)
        Projectile.OnEnterWater(self)

        self:SetVelocityAlign(true)
        self:SetStayUpright(false)
        self:TrackTarget(true)
        self:StayUnderwater(true)

        -- adds the effects after a delay
        self.Trash:Add(ForkThread(self.EnterWaterThread, self))

        -- adjusts the velocity / acceleration, used for torpedo bombers
        if self.MovementThread then
            self.Trash:Add(ForkThread(self.MovementThread, self))
        end
    end,

    ---@param self OnWaterEntryEmitterProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        -- we only fix this for projectiles that are supposed to go into the water
        local px, py, pz = self:GetPositionXYZ()
        local surfaceHeight = GetSurfaceHeight(px, pz)
        if py <= surfaceHeight - 0.1 then
            if targetType == 'Terrain' then
                targetType = 'Underwater'
            end
        end

        Projectile.OnImpact(self, targetType, targetEntity)
    end,
}

-----------------------------------------------------------------
-- GENERIC DEBRIS PROJECTILE
-----------------------------------------------------------------

-- upvalued for performance
local CreateEmitterAtEntity = CreateEmitterAtEntity

---@class BaseGenericDebris : DummyProjectile
BaseGenericDebris = ClassDummyProjectile(DummyProjectile) {

    FxImpactLand = import("/lua/effecttemplates.lua").GenericDebrisLandImpact01,
    FxImpactWater = import("/lua/effecttemplates.lua").WaterSplash01,
    FxTrails = import("/lua/effecttemplates.lua").GenericDebrisTrails01,

    ---@param self BaseGenericDebris
    OnCreate = function(self)
        DummyProjectile.OnCreate(self)

        local army = self.Army
        for k, effect in self.FxTrails do
            CreateEmitterOnEntity(self, army, effect)
        end
    end,

    ---@param self BaseGenericDebris
    ---@param targetType string
    ---@param targetEntity Unit | Shield | Projectile
    OnImpact = function(self, targetType, targetEntity)
        local army = self.Army

        -- default impact effect for land
        if targetType == 'Terrain' then
            for _, effect in self.FxImpactLand do
                local emit = CreateEmitterAtEntity(self, army, effect)
                emit:ScaleEmitter(0.05 + 0.15 * Random())
            end
        -- default impact for water
        elseif targetType == 'Water' then
            for _, effect in self.FxImpactWater do
                local emit = CreateEmitterAtEntity(self, army, effect)
                emit:ScaleEmitter(0.4 + 0.4 * Random())
            end
        end

        self:Destroy()
    end,
}

-----------------------------------------------------------
-- PROJECTILE THAT ADJUSTS DAMAGE AND ENERGY COST ON IMPACT
-----------------------------------------------------------

---@class OverchargeProjectile
OverchargeProjectile = ClassSimple {
    ---@param self OverchargeProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)
        -- Stop us doing blueprint damage in the other OnImpact call if we ditch this one without resetting self.DamageData
        self.DamageData.DamageAmount = 0

        local launcher = self:GetLauncher()
        if not launcher then 
            return 
        end

        local wep = launcher:GetWeaponByLabel('OverCharge')
        if not wep then
             return 
            end

        if IsDestroyed(wep) then
            return
        end

        --  Table layout for Overcharge data section
        --  Overcharge = {
        --      energyMult = _, -- What proportion of current storage are we allowed to spend?
        --      commandDamage = _, -- Takes effect in ACUUnit DoTakeDamage()
        --      structureDamage = _, -- Takes effect in StructureUnit DoTakeDamage() & Shield  ApplyDamage()
        --      maxDamage = _,
        --      minDamage = _,
        --  },

        local data = wep:GetBlueprint().Overcharge
        if not data then return end

        -- Set the damage dealt by the projectile for hitting the floor or an ACUUnit
        -- Energy drained is calculated by the relationship equations
        local damage = data.minDamage

        local killShieldUnit = false
        if targetEntity then
            -- Handle hitting shields. We want the unit underneath, not the shield itself
            if not IsUnit(targetEntity) then
                if not targetEntity.Owner then -- We hit something odd, not a shield
                    WARN('Overcharge hit something that was not the ground, a shield, or a unit')
                    LOG(targetType)
                    return
                end

                targetEntity = targetEntity.Owner
            end

            -- Get max energy available to drain according to how much we have
            local energyAvailable = launcher:GetAIBrain():GetEconomyStored('ENERGY')
            local energyLimit = energyAvailable * data.energyMult
            if OCProjectiles[self.Army] > 1 then
                energyLimit = energyLimit / OCProjectiles[self.Army]
            end
            local energyLimitDamage = self:EnergyAsDamage(energyLimit)
            -- Find max available damage
            damage = math.min(data.maxDamage, energyLimitDamage)
            -- How much damage do we actually need to kill the unit?
            local idealDamage = targetEntity:GetHealth()
            local maxHP = self:UnitsDetection(targetType, targetEntity)
            idealDamage = maxHP or data.minDamage
            
            local targetCats = targetEntity:GetBlueprint().CategoriesHash

            -----SHIELDS------
            if targetEntity.MyShield and targetEntity.MyShield.ShieldType == 'Bubble' then
                if targetCats.DIESTOOCDEPLETINGSHIELD then
                    killShieldUnit = true
                end

                if targetCats.STRUCTURE then
                    idealDamage = data.minDamage
                else
                    idealDamage = targetEntity.MyShield:GetMaxHealth()
                end
                --MaxHealth instead of GetHealth because with getHealth OC won't kill bubble shield which is in AoE range but has more hp than targetEntity.MyShield.
                --good against group of mobile shields
            end
            ------ ACU -------
            if targetCats.COMMAND and not maxHP then -- no units around ACU - min.damage
                idealDamage = data.minDamage
            end
            damage = math.min(damage, idealDamage)
            damage = math.max(data.minDamage, damage)
            -- prevents radars blinks if there is less than 5k e in storage when OC hits the target
            if energyAvailable < 7500 then
                damage = energyLimitDamage
            end   
        end
        -- Turn the final damage into energy
        local drain = self:DamageAsEnergy(damage)


        self.DamageData.DamageAmount = damage

        if drain > 0 then
            launcher.EconDrain = CreateEconomyEvent(launcher, drain, 0, 0)
            launcher:ForkThread(function()
                WaitFor(launcher.EconDrain)
                RemoveEconomyEvent(launcher, launcher.EconDrain)
                OCProjectiles[self.Army] = OCProjectiles[self.Army] - 1
                launcher.EconDrain = nil
                -- if oc depletes a mobile shield it kills the generator, vet counted, no wreck left
                if killShieldUnit and targetEntity and not IsDestroyed(targetEntity) and (IsDestroyed(targetEntity.MyShield) or (not targetEntity.MyShield:IsUp())) then
                    targetEntity:Kill(launcher, 'Overcharge', 2)
                    launcher:OnKilledUnit(targetEntity, targetEntity:GetVeterancyValue())
                end
            end)
        end
    end,

    ---@param self OverchargeProjectile
    ---@param damage number
    ---@return integer
    DamageAsEnergy = function(self, damage)
        return OverchargeShared.DamageAsEnergy(damage)
    end,

    ---@param self OverchargeProjectile
    ---@param energy number
    ---@return number
    EnergyAsDamage = function(self, energy)
        return OverchargeShared.EnergyAsDamage(energy)
    end,

    ---@param self OverchargeProjectile
    ---@param targetType string
    ---@param targetEntity Unit
    ---@return number
    UnitsDetection = function(self, targetType, targetEntity)
     -- looking for units around target which are in splash range
        local launcher = self.Launcher
        local maxHP = 0

        for _, unit in UnitsInSphere(launcher, self:GetPosition(), 2.7, categories.MOBILE -categories.COMMAND) or {} do
                if unit.MyShield and unit:GetHealth() + unit.MyShield:GetHealth() > maxHP then
                    maxHP = unit:GetHealth() + unit.MyShield:GetHealth()
                elseif unit:GetHealth() > maxHP then
                    maxHP = unit:GetHealth()
                end
        end

        for _, unit in UnitsInSphere(launcher, self:GetPosition(), 13.2, categories.EXPERIMENTAL*categories.LAND*categories.MOBILE) or {} do
            -- Special for fatty's shield
            if EntityCategoryContains(categories.UEF, unit) and unit.MyShield._IsUp and unit.MyShield:GetMaxHealth() > maxHP then
                maxHP = unit.MyShield:GetMaxHealth()
            elseif unit:GetHealth() > maxHP then
                local distance = math.min(unit:GetBlueprint().SizeX, unit:GetBlueprint().SizeZ)
                if GetDistanceBetweenTwoEntities(unit, self) < distance + self.DamageData.DamageRadius then
                    maxHP = unit:GetHealth()
                end
            end
        end

        if EntityCategoryContains(categories.EXPERIMENTAL, targetEntity) and targetEntity:GetHealth() > maxHP then
            maxHP = targetEntity:GetHealth()
            --[[ we need this because if OC shell hitted top part of GC model its health won't be in our table
            Bug appeared since we use shell.pos in getUnitsInSphere instead of target.pos.
            Shell is too far from actual target.pos(target pos is somewhere near land and shell is near GC's head)
            and getUnits returns nothing. Same to GetDistance. Distance between shell and GC pos > than math.min (x,z) size]]
        end

        if maxHP ~= 0 then
            return maxHP
        end
    end,

    ---@param self OverchargeProjectile
    OnCreate = function(self)
        self.Army = self.Army

        if not OCProjectiles[self.Army] then
            OCProjectiles[self.Army] = 0
        end

        OCProjectiles[self.Army] = OCProjectiles[self.Army] + 1
    end,
}

-- Kept for mod backwards compatability
local MathFloor = math.floor