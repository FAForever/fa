------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local DefaultDamage = import('/lua/sim/defaultdamage.lua')
local AreaDoTThread = DefaultDamage.AreaDoTThread
local Flare = import('/lua/defaultantiprojectile.lua').Flare

-- upvalued globals for performance
local DamageArea = _G.DamageArea
local Damage = _G.Damage

local TrashBag = _G.TrashBag
local TrashBagAdd = _G.TrashBag.Add 
local TrashBagDestroy = _G.TrashBag.Destroy

local ForkThread = _G.ForkThread
local GetTerrainType = _G.GetTerrainType
local GetSurfaceHeight = _G.GetSurfaceHeight

local EntityCategoryContains = EntityCategoryContains
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetArmy = EntityMethods.GetArmy
local EntityDestroy = EntityMethods.Destroy
local EntityPlaySound = EntityMethods.PlaySound
local EntitySetHealth = EntityMethods.SetHealth
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntitySetAmbientSound = EntityMethods.SetAmbientSound
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local EntityGetPosition = EntityMethods.GetPosition
local EntityAdjustHealth = EntityMethods.AdjustHealth
local EntityGetHealth = EntityMethods.GetHealth

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetLauncher = ProjectileMethods.GetLauncher
local ProjectileSetNewTargetGround = ProjectileMethods.SetNewTargetGround
local ProjectileGetCurrentTargetPosition = ProjectileMethods.GetCurrentTargetPosition
local ProjectileGetTrackingTarget = ProjectileMethods.GetTrackingTarget
local ProjectileSetLifetime = ProjectileMethods.SetLifetime

local EmitterMethods = _G.moho.IEffect
local EmitterScaleEmitter = EmitterMethods.ScaleEmitter
local EmitterOffsetEmitter = EmitterMethods.OffsetEmitter

-- upvalued read-only values
local DoNotCollideCategories = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE
local OnImpactDestroyCategories = categories.ANTIMISSILE * categories.ALLPROJECTILES
local DefaultTerrainTypeFxImpact = GetTerrainType(-1, -1).FxImpact

local DeprecatedWarnings = { }

Projectile = Class(ProjectileMethods, Entity) {

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self, spec)
    end,

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __post_init = function(self, spec)
    end,

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    -- FxImpactAirUnit = false,
    -- FxImpactLand = false,
    -- FxImpactNone = false,
    -- FxImpactProp = false,
    -- FxImpactShield = false,
    -- FxImpactWater = false,
    -- FxImpactUnderWater = false,
    -- FxImpactUnit = false,
    -- FxImpactProjectile = false,
    -- FxImpactProjectileUnderWater = false,
    -- FxOnKilled = false,

    -- FxAirUnitHitScale = 1,
    -- FxLandHitScale = 1,
    -- FxNoneHitScale = 1,
    -- FxPropHitScale = 1,
    -- FxProjectileHitScale = 1,
    -- FxProjectileUnderWaterHitScale = 1,
    -- FxShieldHitScale = 1,
    -- FxUnderWaterHitScale = 0.25,
    -- FxUnitHitScale = 1,
    -- FxWaterHitScale = 1,
    -- FxOnKilledScale = 1,

    -- this is always false
    -- FxImpactLandScorch = false,
    -- FxImpactLandScorchScale = 1.0,

    -- Performance-wise this function just hurts and is not needed
    ForkThread = function(self, fn, ...)

        LOG("Projectile forkthread called at: " .. repr(debug.getinfo(2)))

        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            TrashBagAdd(self.Trash, thread)
            return thread
        else
            return nil
        end
    end,

    -- Called by engine when made
    OnCreate = function(self, inWater)

        -- get blueprint into local scope for performance
        local blueprint = EntityGetBlueprint(self)

        -- store original blueprint for functions that need it
        self.Blueprint = blueprint
        self.BlueprintAudio = blueprint.Audio

        -- store values for direct access to prevent hashing / engine calls
        self.Army = EntityGetArmy(self)
        self.Launcher = ProjectileGetLauncher(self)

        -- used when colliding or taking damage, cached for efficiency
        self.BlueprintDoNotCollideList = blueprint.DoNotCollideList
        self.BlueprintDefenseMaxHealth = blueprint.Defense.MaxHealth or 1

        -- allocate damage data
        self.DamageData = { }

        -- set original health
        EntitySetMaxHealth(self, self.BlueprintDefenseMaxHealth)
        EntitySetHealth(self, self, self.BlueprintDefenseMaxHealth) -- 2nd self is instigator

        -- update target if we track
        if blueprint.Physics.TrackTargetGround then
            local pos = ProjectileGetCurrentTargetPosition(self)
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            ProjectileSetNewTargetGround(self, pos)
        end

        -- prepare trashbag
        self.Trash = TrashBag()
    end,

    -- TODO: shallow-copy the damage data instead, and update all units that require a deep copy (for example: when projectiles split the damage is sometimes divided by the number of projectiles).
    -- Receive damage data as deep-copy from the weapon
    -- PERFORMANCE-TODO: Does this need to be a deep-copy?
    PassDamageData = function(self, DamageData)
        -- only copy data that is present
        local SelfDamageData = self.DamageData
        for k, value in DamageData do 
            SelfDamageData[k] = value
        end

        -- additional copy
        self.CollideFriendly = SelfDamageData.CollideFriendly
    end,

    -- Called when a projectile should apply its damage
    DoDamage = function(self, instigator, DamageData, targetEntity)
        local damage = DamageData.DamageAmount
        if damage and damage > 0 then
            local position = EntityGetPosition(self)
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    DamageArea(instigator, position, radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, position, radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, position, targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.AreaDoTThread, instigator, position, DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), radius, damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            -- ONLY DO DAMAGE IF THERE IS DAMAGE DATA.  SOME PROJECTILE DO NOT DO DAMAGE WHEN THEY IMPACT.
            elseif DamageData.DamageAmount and targetEntity then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    Damage(instigator, position, targetEntity, DamageData.DamageAmount, DamageData.DamageType)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, position, radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, position, targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.UnitDoTThread, instigator, targetEntity, DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            end
        end
        if self.InnerRing and self.OuterRing then
            local pos = self:GetPosition()
            self.InnerRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
            self.OuterRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
        end
    end,

    -- Called when a projectile hits some other entity
    OnCollisionCheck = function(self, other)

        -- if we return false the thing hitting us has no idea that it came into contact with us
        if self.Army == other.Army then return false end

        -- pass the default do-not-collide categories
        if EntityCategoryContains(DoNotCollideCategories, self) and EntityCategoryContains(DoNotCollideCategories, other) then
            return false
        end

        -- if it should only hit a specific target and we're not the one being tracked
        if other.Blueprint.Physics.HitAssignedTarget and ProjectileGetTrackingTarget(other) ~= self then
            return false
        end

        -- check for specific do-not-collide entities, such as for strategic missiles not hitting air
        for _, p in {{self, other}, {other, self}} do -- TODO: table creation!
            local dnc = p[1].BlueprintDoNotCollideList
            if dnc then
                for _, v in dnc do
                    if EntityCategoryContains(categories[v], p[2]) then
                        return false
                    end
                end
            end
        end

        return true
    end,

    -- Called when a projectile receives damage
    OnDamage = function(self, instigator, amount, vector, damageType)
        if self.BlueprintDefenseMaxHealth then
            self.DoTakeDamage(self, instigator, amount, vector, damageType)
        else
            self.OnKilled(self, instigator, damageType)
        end
    end,

    -- Called when a projectile should be de-allocated
    OnDestroy = function(self)
        TrashBagDestroy(self.Trash)
    end,

    -- Called when a projectile takes damage
    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Check for valid projectile
        if not self or self:BeenDestroyed() then
            return
        end

        EntityAdjustHealth(self, instigator, -amount)
        local health = EntityGetHealth(self)
        if health <= 0 then
            if damageType == 'Reclaimed' then
                EntityDestroy(self)
            else
                local excessDamageRatio = 0.0

                -- Calculate the excess damage amount
                local excess = health - amount
                local maxHealth = self.BlueprintDefenseMaxHealth
                if excess < 0 and maxHealth > 0 then
                    excessDamageRatio = -excess / maxHealth
                end
                self.OnKilled(self, instigator, damageType, excessDamageRatio)
            end
        end
    end,

    -- Called when the projectile is killed.
    OnKilled = function(self, instigator, type, overkillRatio)
        self.CreateImpactEffects(self, self.Army, self.FxOnKilled, self.FxOnKilledScale)
        EntityDestroy(self)
    end,

    -- ??
    DoMetaImpact = function(self, damageData)
        if damageData.MetaImpactRadius and damageData.MetaImpactAmount then
            local x, y, z = EntityGetPositionXYZ(self)
            y = GetSurfaceHeight(x, z)
            MetaImpact(self, { x, y, z }, damageData.MetaImpactRadius, damageData.MetaImpactAmount)
        end
    end,

    -- Creates the impact effects of the projectile itself
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        -- default values
        EffectScale = EffectScale or 1

        -- caching
        local fxImpactTrajectoryAligned = self.FxImpactTrajectoryAligned

        -- create the emitters
        local emit
        if EffectTable then 
            for _, v in EffectTable do

                -- construct emitter
                if fxImpactTrajectoryAligned then
                    emit = CreateEmitterAtBone(self, -2, army, v)
                else
                    emit = CreateEmitterAtEntity(self, army, v)
                end

                EmitterScaleEmitter(emit, EffectScale)
            end
        end
    end,

    -- Creates generic terrain effects that always spawn
    CreateTerrainEffects = function(self, army, EffectTable, EffectScale)
        -- default values
        EffectScale = EffectScale or 1

        for _, v in EffectTable do
            local emit = CreateEmitterAtBone(self, -2, army, v)
            EmitterScaleEmitter(emit, EffectScale )
        end
    end,

    -- Retrieves the generic terrain effects
    GetTerrainEffects = function(self, TargetType, ImpactEffectType)
        -- default value
        ImpactEffectType = ImpactEffectType or 'Default'

        -- get x / z position
        local x, y, z = EntityGetPositionXYZ(self)
    
        -- get terrain at that location and try and get some effects
        local TerrainType = GetTerrainType(x, z)
        local TerrainEffect = TerrainType.FXImpact[TargetType][ImpactEffectType] or DefaultTerrainTypeFxImpact[TargetType][ImpactEffectType] or { }
        return TerrainEffect
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        if not firingWeapon.CollideFriendly and self.Army == firingWeapon.unit.Army then
            return false
        end

        -- If this unit category is on the weapon's do-not-collide list, skip!
        local weaponBP = EntityGetBlueprint(firingWeapon)
        if weaponBP.DoNotCollideList then
            for k, v in weaponBP.DoNotCollideList do
                if EntityCategoryContains(ParseEntityCategory(v), self) then -- TODO: Parsing!!
                    return false
                end
            end
        end
        return true
    end,

    -- Create some cool explosions when we get destroyed
    OnImpact = function(self, targetType, targetEntity)
        
        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local army = self.Army
        local instigator = self.Launcher or self 
        local damageData = self.DamageData

        -- Do Damage
        self.DoDamage(self, instigator, damageData, targetEntity)

        -- Meta-Impact
        -- self.DoMetaImpact(self, damageData) -- this doesn't do anything, just takes up cycles

        -- Buffs (Stun, etc)
        self.DoUnitImpactBuffs(self, targetEntity)

        -- Possible 'target' values are:
        --  'Unit'
        --  'Terrain'
        --  'Water'
        --  'Air'
        --  'Prop'
        --  'Shield'
        --  'UnitAir'
        --  'UnderWater'
        --  'UnitUnderwater'
        --  'Projectile'
        --  'ProjectileUnderWater
        local ImpactEffects = false
        local ImpactEffectScale = 1
        local blueprint = self.Blueprint

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local blueprintAudio = self.BlueprintAudio
        local snd = blueprintAudio['Impact' .. targetType]
        if snd then
            EntityPlaySound(self, snd)
            -- Generic Impact Sound
        elseif blueprintAudio.Impact then
            EntityPlaySound(self, blueprintAudio.Impact)
        end

        -- ImpactEffects
        if targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
        elseif targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale
        elseif targetType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif targetType == 'Air' then
            ImpactEffects = self.FxImpactNone
            ImpactEffectScale = self.FxNoneHitScale
        elseif targetType == 'Projectile' then
            ImpactEffects = self.FxImpactProjectile
            ImpactEffectScale = self.FxProjectileHitScale
        elseif targetType == 'ProjectileUnderwater' then
            ImpactEffects = self.FxImpactProjectileUnderWater
            ImpactEffectScale = self.FxProjectileUnderWaterHitScale
        elseif targetType == 'Prop' then
            ImpactEffects = self.FxImpactProp
            ImpactEffectScale = self.FxPropHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale or 0.25
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        -- default values
        ImpactEffects = ImpactEffects or { }
        ImpactEffectScale = ImpactEffectScale or 1

        local BlueprintDisplayImpactEffects = blueprint.Display.ImpactEffects
        local TerrainEffects = self.GetTerrainEffects(self, targetType, BlueprintDisplayImpactEffects.Type)
        self.CreateImpactEffects(self, army, ImpactEffects, ImpactEffectScale)
        self.CreateTerrainEffects(self, army, TerrainEffects, BlueprintDisplayImpactEffects.Scale or 1)

        local timeout = blueprint.Physics.ImpactTimeout
        if timeout and targetType == 'Terrain' then
            TrashBagAdd(self.Trash, ForkThread(self.ImpactTimeoutThread, self, timeout))
        else
            self.OnImpactDestroy(self, targetType, targetEntity)
        end
    end,

    -- An instantanious destroy for the typical projectile
    OnImpactDestroy = function(self, targetType, targetEntity)
        local destroyOnImpact = self.DestroyOnImpact
        if destroyOnImpact or not targetEntity or
            (not destroyOnImpact and targetEntity and not EntityCategoryContains(OnImpactDestroyCategories, targetEntity)) then
            EntityDestroy(self)
        end
    end,

    -- A delayed destroy for when blueprint.Physics.ImpactTimeout is set
    ImpactTimeoutThread = function(self, seconds)
        WaitSeconds(seconds)
        EntityDestroy(self)
    end,

    -- When this projectile impacts with the target, do any buffs that have been passed to it.
    DoUnitImpactBuffs = function(self, target)
        local data = self.DamageData
        -- Check for buff
        if data.Buffs then
            -- Check for valid target
            for k, v in data.Buffs do
                if v.Add.OnImpact == true then
                    local radius = v.radius
                    if v.AppliedToTarget ~= true or (radius and radius > 0) then
                        target = self.Launcher
                    end
                    -- Check for target validity
                    if target and IsUnit(target) then
                        if radius and radius > 0 then
                            -- This is a radius buff
                            -- get the position of the projectile
                            target.AddBuff(target, v, EntityGetPosition(self))
                        else
                            -- This is a single target buff
                            target.AddBuff(target, v)
                        end
                    end
                end
            end
        end
    end,

    -- this should never be called - use the actual function.
    GetCachePosition = function(self)

        -- deprecation warning in case it ever happens.
        if not DeprecatedWarnings.CreateCybranBuildBeams then 
            DeprecatedWarnings.CreateCybranBuildBeams = true 
            WARN("CreateCybranBuildBeams is deprecated: use projectile:GetPosition() instead.")
            WARN("Source: " .. repr(debug.getinfo(2)))
        end

        return self:GetPosition()
    end,

    -- this should never be called - use the actual value.
    GetCollideFriendly = function(self)

        -- deprecation warning in case it ever happens.
        if not DeprecatedWarnings.CreateCybranBuildBeams then 
            DeprecatedWarnings.CreateCybranBuildBeams = true 
            WARN("CreateCybranBuildBeams is deprecated: get projectile.CollideFriendly instead.")
            WARN("Source: " .. repr(debug.getinfo(2)))
        end

        return self.CollideFriendly
    end,

    -- this should never be called - use the actual value.
    PassData = function(self, data)

        -- deprecation warning in case it ever happens.
        if not DeprecatedWarnings.CreateCybranBuildBeams then 
            DeprecatedWarnings.CreateCybranBuildBeams = true 
            WARN("CreateCybranBuildBeams is deprecated: set projectile.Data instead.")
            WARN("Source: " .. repr(debug.getinfo(2)))
        end

        self.Data = data
    end,

    -- when the projectile exits the water
    OnExitWater = function(self)
        -- no projectile blueprint has this value set
        local snd = self.Blueprint.Audio.ExitWater
        if snd then
            EntityPlaySound(self, snd)
        end
    end,

    -- when the projectile enters the water
    OnEnterWater = function(self)
        local snd = self.BlueprintAudio.EnterWater
        if snd then
            EntityPlaySound(self, snd)
        end
    end,

    AddFlare = function(self, tbl)
        if not tbl then return end
        if not tbl.Radius then return end
        self.MyFlare = Flare {
            Owner = self,
            Radius = tbl.Radius or 5,
            Category = tbl.Category or 'MISSILE',  -- We pass the category bp value along so that it actually has a function.
        }
        if tbl.Stack == true then -- Secondary flare hitboxes, one above, one below (Aeon TMD)
            self.MyUpperFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            self.MyLowerFlare = Flare {
                Owner = self,
                Radius = tbl.Radius,
                OffsetMult = -tbl.OffsetMult,
                Category = tbl.Category or 'MISSILE',
            }
            TrashBagAdd(self.Trash, self.MyUpperFlare)
            TrashBagAdd(self.Trash, self.MyLowerFlare)
        end

        TrashBagAdd(self.Trash, self.MyFlare)
    end,

    OnLostTarget = function(self)
        local physics = self.Blueprint.Physics
        if physics.TrackTarget then
            ProjectileSetLifetime(self, physics.OnLostTargetLifetime)
        end
    end,
}

--- A dummy projectile that solely inherits what it needs. Useful for 
-- effects that require projectiles without additional overhead.
DummyProjectile = Class(moho.projectile_methods, Entity) {
    -- the only things we need
    __init = function(self, spec) end,
    __post_init = function(self, spec) end,
    OnCreate = function(self, inWater) end,
}