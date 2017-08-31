-----------------------------------------------------------------
-- File     : /lua/defaultprojectiles.lua
-- Author(s): John Comes, Gordon Duclos
-- Summary  : Script for default projectiles
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local Projectile = import('/lua/sim/Projectile.lua').Projectile

-----------------------------------------------------------------
-- Null Shell
-----------------------------------------------------------------
NullShell = Class(Projectile) {}

-----------------------------------------------------------------
-- PROJECTILE WITH ATTACHED EFFECT EMITTERS
-----------------------------------------------------------------
EmitterProjectile = Class(Projectile) {
    FxTrails = {'/effects/emitters/missile_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,

    OnCreate = function(self)
        Projectile.OnCreate(self)
        local army = self:GetArmy()
        for i in self.FxTrails do
            CreateEmitterOnEntity(self, army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
        end
    end,
}

-----------------------------------------------------------------
-- BEAM PROJECTILES
-----------------------------------------------------------------
SingleBeamProjectile = Class(EmitterProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = {},

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        if self.BeamName then
            CreateBeamEmitterOnEntity(self, -1, self:GetArmy(), self.BeamName)
        end
    end,
}

MultiBeamProjectile = Class(EmitterProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    FxTrails = {},

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        local beam = nil
        local army = self:GetArmy()
        for k, v in self.Beams do
            CreateBeamEmitterOnEntity(self, -1, army, v)
        end
    end,
}

-- Nukes
NukeProjectile = Class(NullShell) {
    MovementThread = function(self)
        local army = self:GetArmy()
        local launcher = self:GetLauncher()
        self.CreateEffects(self, self.InitialEffects, army, 1)
        self:TrackTarget(false)
        WaitSeconds(2.5) -- Height
        self:SetCollision(true)
        self.CreateEffects(self, self.LaunchEffects, army, 1)
        WaitSeconds(2.5)
        self.CreateEffects(self, self.ThrustEffects, army, 3)
        WaitSeconds(2.5)
        self:TrackTarget(true) -- Turn ~90 degrees towards target
        self:SetDestroyOnWater(true)
        self:SetTurnRate(47.36)
        WaitSeconds(2) -- Now set turn rate to zero so nuke flies straight
        self:SetTurnRate(0)
        self:SetAcceleration(0.001)
        self.WaitTime = 0.5
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        -- Get the nuke as close to 90 deg as possible
        if dist > 150 then
            -- Freeze the turn rate as to prevent steep angles at long distance targets
            self:SetTurnRate(0)
        elseif dist > 75 and dist <= 150 then
            -- Increase check intervals
            self.WaitTime = 0.3
        elseif dist > 32 and dist <= 75 then
            -- Further increase check intervals
            self.WaitTime = 0.1
        elseif dist < 32 then
            -- Turn the missile down
            self:SetTurnRate(50)
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,

    CreateEffects = function(self, EffectTable, army, scale)
        if not EffectTable then return end
        for k, v in EffectTable do
            self.Trash:Add(CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(scale))
        end
    end,

    ForceThread = function(self)
        -- Knockdown force rings
        local position = self:GetPosition()
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
        WaitSeconds(0.1)
        DamageRing(self, position, 0.1, 45, 1, 'Force', true)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        if not TargetEntity or not EntityCategoryContains(categories.PROJECTILE, TargetEntity) then
            -- Play the explosion sound
            local myBlueprint = self:GetBlueprint()
            if myBlueprint.Audio.NukeExplosion then
                self:PlaySound(myBlueprint.Audio.NukeExplosion)
            end

            self.effectEntity = self:CreateProjectile(self.effectEntityPath, 0, 0, 0, nil, nil, nil):SetCollision(false)
            self.effectEntity:ForkThread(self.effectEntity.EffectThread)
            self:ForkThread(self.ForceThread)
        end
        NullShell.OnImpact(self, TargetType, TargetEntity)
    end,

    LauncherCallbacks = function(self)
        local launcher = self:GetLauncher()
        if launcher and not launcher.Dead and launcher.EventCallbacks.ProjectileDamaged then
            self.ProjectileDamaged = {}
            for k,v in launcher.EventCallbacks.ProjectileDamaged do
                table.insert(self.ProjectileDamaged, v)
            end
        end
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self:ForkThread(self.MovementThread)
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        if self.ProjectileDamaged then
            for k,v in self.ProjectileDamaged do
                v(self)
            end
        end
        NullShell.DoTakeDamage(self, instigator, amount, vector, damageType)
    end,
}

-----------------------------------------------------------------
-- POLY-TRAIL PROJECTILES
-----------------------------------------------------------------
SinglePolyTrailProjectile = Class(EmitterProjectile) {

    PolyTrail = '/effects/emitters/test_missile_trail_emit.bp',
    PolyTrailOffset = 0,
    FxTrails = {},

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        if self.PolyTrail != '' then
            CreateTrail(self, -1, self:GetArmy(), self.PolyTrail):OffsetEmitter(0, 0, self.PolyTrailOffset)
        end
    end,
}

MultiPolyTrailProjectile = Class(EmitterProjectile) {

    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = {0},
    FxTrails = {},
    RandomPolyTrails = 0,   -- Count of how many are selected randomly for PolyTrail table

    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)
        if self.PolyTrails then
            local NumPolyTrails = table.getn(self.PolyTrails)
            local army = self:GetArmy()

            if self.RandomPolyTrails != 0 then
                local index = nil
                for i = 1, self.RandomPolyTrails do
                    index = math.floor(Random(1, NumPolyTrails))
                    CreateTrail(self, -1, army, self.PolyTrails[index]):OffsetEmitter(0, 0, self.PolyTrailOffset[index])
                end
            else
                for i = 1, NumPolyTrails do
                    CreateTrail(self, -1, army, self.PolyTrails[i]):OffsetEmitter(0, 0, self.PolyTrailOffset[i])
                end
            end
        end
    end,
}


-----------------------------------------------------------------
-- COMPOSITE EMITTER PROJECTILES - MULTIPURPOSE PROJECTILES
-- - THAT COMBINES BEAMS, POLYTRAILS, AND NORMAL EMITTERS
-----------------------------------------------------------------

-- LIGHTWEIGHT VERSION THAT LIMITS USE TO 1 BEAM, 1 POLYTRAIL, AND STANDARD EMITTERS
SingleCompositeEmitterProjectile = Class(SinglePolyTrailProjectile) {

    BeamName = '/effects/emitters/default_beam_01_emit.bp',
    FxTrails = {},

    OnCreate = function(self)
        SinglePolyTrailProjectile.OnCreate(self)
        if self.BeamName != '' then
            CreateBeamEmitterOnEntity(self, -1, self:GetArmy(), self.BeamName)
        end
    end,
}

-- HEAVYWEIGHT VERSION, ALLOWS FOR MULTIPLE BEAMS, POLYTRAILS, AND STANDARD EMITTERS
MultiCompositeEmitterProjectile = Class(MultiPolyTrailProjectile) {

    Beams = {'/effects/emitters/default_beam_01_emit.bp',},
    PolyTrails = {'/effects/emitters/test_missile_trail_emit.bp'},
    PolyTrailOffset = {0},
    RandomPolyTrails = 0,   -- Count of how many are selected randomly for PolyTrail table
    FxTrails = {},

    OnCreate = function(self)
        MultiPolyTrailProjectile.OnCreate(self)
        local beam = nil
        local army = self:GetArmy()
        for k, v in self.Beams do
            CreateBeamEmitterOnEntity(self, -1, army, v)
        end
    end,
}

-----------------------------------------------------------------
-- TRAIL ON ENTERING WATER PROJECTILE
-----------------------------------------------------------------
OnWaterEntryEmitterProjectile = Class(Projectile) {
    FxTrails = {'/effects/emitters/torpedo_munition_trail_01_emit.bp',},
    FxTrailScale = 1,
    FxTrailOffset = 0,
    PolyTrail = '',
    PolyTrailOffset = 0,
    TrailDelay = 5,
    EnterWaterSound = 'Torpedo_Enter_Water_01',

    OnCreate = function(self, inWater)
        Projectile.OnCreate(self, inWater)
        if inWater then
            local army = self:GetArmy()
            for i in self.FxTrails do
                CreateEmitterOnEntity(self, army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
            end
            if self.PolyTrail != '' then
                CreateTrail(self, -1, self:GetArmy(), self.PolyTrail):OffsetEmitter(0, 0, self.PolyTrailOffset)
            end
        end
    end,

    EnterWaterThread = function(self)
        WaitTicks(self.TrailDelay)
        local army = self:GetArmy()
        for i in self.FxTrails do
            CreateEmitterOnEntity(self, army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
        end
        if self.PolyTrail != '' then
            CreateTrail(self, -1, self:GetArmy(), self.PolyTrail):OffsetEmitter(0, 0, self.PolyTrailOffset)
        end
    end,

    OnEnterWater = function(self)
        Projectile.OnEnterWater(self)
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self.TTT1 = self:ForkThread(self.EnterWaterThread)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        Projectile.OnImpact(self, TargetType, TargetEntity)
        KillThread(self.TTT1)
    end,
}

-----------------------------------------------------------------
-- GENERIC DEBRIS PROJECTILE
-----------------------------------------------------------------
BaseGenericDebris = Class(EmitterProjectile){
    FxUnitHitScale = 0.25,
    FxWaterHitScale = 0.25,
    FxUnderWaterHitScale = 0.25,
    FxNoneHitScale = 0.25,
    FxImpactLand = false,
    FxLandHitScale = 0.5,
    FxTrails = false,
    FxTrailScale = 1,
}


-----------------------------------------------------------------
-- PROJECTILE THAT ADJUSTS DAMAGE AND ENERGY COST ON IMPACT
-----------------------------------------------------------------
OverchargeProjectile = Class() {
    OnImpact = function(self, targetType, targetEntity)
        local unit = self:GetLauncher()
        local currentCharges = self.Overcharge.CurrentCharges
        local charges = currentCharges
        local maxCharges = self.Overcharge.MaxCharges
        if charges < maxCharges then
            local energyStored = unit:GetAIBrain():GetEconomyStored('ENERGY')
            maxCharges = math.min(maxCharges, charges + math.floor(energyStored / self.Overcharge.EnergyPerCharge))
        end

        if charges < maxCharges and targetEntity then
            charges = math.max(charges, self:CalcChargesNeeded(targetEntity))
        end

        if charges < maxCharges then
            local unitsInRange = unit:GetAIBrain():GetUnitsAroundPoint(categories.ALLUNITS, self:GetPosition(), self.DamageData.DamageRadius, 'Enemy')
            for _, unit in unitsInRange do
                charges = math.max(charges, self:CalcChargesNeeded(unit))
                if charges >= maxCharges then
                    break
                end
            end
        end

        if charges > currentCharges and maxCharges > currentCharges then
            charges = math.min(charges, maxCharges)
            self:SetChargeCount(charges)

            local energyNeeded = self.Overcharge.EnergyPerCharge * (charges - currentCharges)
            if energyNeeded > 0 then
                unit:ForkThread(function()
                    if self.Overcharge.FiringDrain then
                        WaitFor(self.Overcharge.FiringDrain)
                    end
                    local event = CreateEconomyEvent(unit, energyNeeded, 0, energyNeeded / self.Overcharge.EnergyDrain)
                    WaitFor(event)
                    RemoveEconomyEvent(unit, event)
                end)
            end
        end
    end,

    SetChargeCount = function(self, charges)
        self.DamageData.DamageAmount = (self.Overcharge.BaseDamage + self.Overcharge.DamagePerCharge * charges) * (self.Overcharge.DamageMultiplier or 1)
        self.Overcharge.CurrentCharges = charges
    end,

    CalcChargesNeeded = function(self, target)
        local targetHealth
        local targetArmor = 1
        if target and IsEntity(target) then
            targetHealth = target:GetHealth()
            if target.MyShield and target.MyShield.IsOn() and target.MyShield.ShieldType ~= 'Bubble' then
                targetHealth = targetHealth + target.MyShield:GetHealth()
            end

            if IsUnit(target) then
                targetArmor = target:GetArmorMult(self.DamageData.DamageType)
            elseif target.Owner and IsUnit(target.Owner) then -- Target is a shield
                targetArmor = target.Owner:GetArmorMult(self.DamageData.DamageType)
            end
        end

        if not targetHealth then
            return self.Overcharge.MaxCharges -- Do max damage when ground firing
        elseif targetArmor <= 0 then
            return 0
        end

        local damageNeeded = targetHealth / targetArmor / (self.Overcharge.DamageMultiplier or 1)
        local chargesNeeded = math.ceil((damageNeeded - self.Overcharge.BaseDamage) / self.Overcharge.DamagePerCharge)
        return math.min(math.max(chargesNeeded, 0), self.Overcharge.MaxCharges)
    end,
}
