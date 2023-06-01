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
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

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
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

    ---@param self MultiBeamProjectile
    OnCreate = function(self)
        EmitterProjectile.OnCreate(self)

        local beam = nil
        for k, v in self.Beams do
            CreateBeamEmitterOnEntity(self, -1, self.Army, v)
        end
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
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

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
    PolyTrailOffset = import("/lua/effecttemplates.lua").DefaultPolyTrailOffset1,
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

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
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

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
    PolyTrailOffset = import("/lua/effecttemplates.lua").DefaultPolyTrailOffset1,
    -- Count of how many are selected randomly for PolyTrail table
    RandomPolyTrails = 0,
    FxTrails = import("/lua/effecttemplates.lua").NoEffects,

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
        self.Trash:Add(ForkThread(self.EnterWaterThread, self))
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
local CreateEmitterAtBone = CreateEmitterAtBone
local GetTerrainType = GetTerrainType

-- upvalued read-only values
local DefaultTerrainTypeFxImpact = GetTerrainType(-1, -1).FXImpact

-- moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntityPlaySound = EntityMethods.PlaySound
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter

---@class BaseGenericDebris : DummyProjectile
BaseGenericDebris = ClassProjectile(DummyProjectile) {

    ---@param self BaseGenericDebris
    ---@param targetType string
    ---@param targetEntity Unit
    OnImpact = function(self, targetType, targetEntity)

        -- cache values
        local blueprint = EntityGetBlueprint(self)
        local blueprintDisplayImpactEffects = blueprint.Display.ImpactEffects
        local impactEffectType = blueprintDisplayImpactEffects.Type or 'Default'

        -- determine sound value
        local impactSnd = "Impact"
        if targetType == 'Terrain' then
            impactSnd = "ImpactTerrain"
        elseif targetType == 'Water' then
            impactSnd = "ImpactWater"
        end

        -- play impact sound
        local snd = blueprint.Audio[impactSnd]
        if snd then 
            EntityPlaySound(self, snd)
        end

        -- Inlined GetTerrainEffects --

        -- get x / z position
        local x, _, z = EntityGetPositionXYZ(self)

        -- get terrain at that location and try and get some effects
        local terrainTypeFxImpact = GetTerrainType(x, z).FXImpact
        local terrainEffects = terrainTypeFxImpact[targetType][impactEffectType] or DefaultTerrainTypeFxImpact[targetType][impactEffectType] or false

        -- Inlined CreateTerrainEffects --

        -- check if table exists, can be set to false
        if terrainEffects then 

            -- store values in cache
            local emit = false
            local army = self.Army
            local effectScale = blueprintDisplayImpactEffects.Scale or 1

            for _, v in terrainEffects do

                -- create emitter and scale accordingly
                emit = CreateEmitterAtBone(self, -2, army, v)
                if effectScale ~= 1 then
                    EmitterScaleEmitter(emit, effectScale)
                end
            end
        end

        -- destroy ourselves :(
        EntityDestroy(self)
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
            if energyAvailable < 5000 then
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