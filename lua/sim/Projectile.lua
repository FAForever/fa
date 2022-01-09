------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

-- DOCUMENTATION --

-- Particles are the definition of garbage creation: they are created with 
-- the sole purpose to be destroyed again a few seconds later. Therefore it 
-- is important that they allocate as little as possible to make the life of 
-- our garbage collector easier.

-- See /engine/sim/projectile.lua for projectile-specfic moho functions
-- See /engine/sim/entity.lua for entity-specific moho functions

-- List of functions called from the c-boundary:
-- __init           (do not edit this one)
-- __post_init      (do not edit this one)
-- OnCreate
-- OnCollisionCheck
-- OnDamage
-- OnDestroy
-- OnCollisionCheckWeapon
-- OnImpact
-- OnExitWater
-- OnEnterWater

-- IMPORTS --

local Entity = import('/lua/sim/Entity.lua').Entity
local DefaultDamage = import('/lua/sim/defaultdamage.lua')
local AreaDoTThread = DefaultDamage.AreaDoTThread
local Flare = import('/lua/defaultantiprojectile.lua').Flare

-- UPVALUES --

-- Globals for performance
local DamageArea = _G.DamageArea
local Damage = _G.Damage

local TrashBag = _G.TrashBag
local TrashBagAdd = _G.TrashBag.Add 
local TrashBagDestroy = _G.TrashBag.Destroy

local ForkThread = _G.ForkThread
local GetTerrainType = _G.GetTerrainType
local GetSurfaceHeight = _G.GetSurfaceHeight

local getmetatable = getmetatable
local EntityCategoryContains = EntityCategoryContains
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- Moho functions for performance
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

-- Read-only values
local DoNotCollideCategories = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE
local OnImpactDestroyCategories = categories.ANTIMISSILE * categories.ALLPROJECTILES
local DefaultTerrainTypeFxImpact = GetTerrainType(-1, -1).FxImpact

-- MISCELLANEOUS --

local DeprecatedWarnings = { }

local VectorCache = Vector(0, 0, 0)
local OnCollisionCheckTableCache = { {false, false}, {false, false} }

local OnImpactDecals = {
    -- radius of at most 2
    {
        -- albedo
    },
    -- radius of at most 4
    {
        -- albedo
        -- normals
    },
    -- radius of at most 6
    {
        -- albedo
        -- normals
    },
    -- radius of at most 8
    {
        -- albedo
        -- normals
        -- normals (large)
    },
    -- radius of 8 or more
    {
        -- albedo
        -- albedo (large)
        -- normals
        -- normals (large) 
    },
}

local function CacheViaMetatable(projectile)

    local meta = getmetatable(projectile)
    local blueprint = projectile:GetBlueprint()

    meta.Cached = true

    -- cache the blueprint
    meta.Blueprint = blueprint

    -- cache parsed version of the do not collide lists
    meta.DoNotCollideListParsed = false
    if blueprint.DoNotCollideList then 
        meta.DoNotCollideListParsed = { }
        for k, v in blueprint.DoNotCollideList do 
            meta.DoNotCollideListParsed[k] = ParseEntityCategory(v)
        end
    end
end

Projectile = Class(ProjectileMethods, Entity) {

    -- # Values # --

    -- Cached in the meta table
    Cached = false,
    Blueprint = false, 
    DoNotCollideListParsed = false,

    -- Prevent calling these functions as we already have a C object
    __init = false,
    __post_init = false,

    -- these values are used throughout the code but we no longer load
    -- them by default. This reduces the memory footprint. There are
    -- hundreds of unique projectiles and therefore hundreds of
    -- unique meta tables that hold these values by default. Instead,
    -- we check in the code whether the value exists. If it doesn't, 
    -- we use the default.

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

    -- Due to legacy reasons we can not apply the same logic to these ^^
    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    -- # Functions called by the engine # --

    -- Called by engine when made 
    OnCreate = function(self, inWater)

        if not self.Cached then 
            CacheViaMetatable(self)
        end

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

    -- Called by the engine when a projectile should be de-allocated
    OnDestroy = function(self)
        TrashBagDestroy(self.Trash)
    end,

    -- Called by the engine when a tracking projectile loses its target, called by the engine
    OnLostTarget = function(self)
        local physics = self.Blueprint.Physics
        if physics.TrackTarget then
            ProjectileSetLifetime(self, physics.OnLostTargetLifetime)
        end
    end,

    -- Called by the engine when a projectile hits some other entity
    OnCollisionCheck = function(self, other)
        -- do not hit our own
        if self.Army == other.Army then 
            return false 
        end

        -- do not hit what we're not interested in
        if EntityCategoryContains(DoNotCollideCategories, self) and EntityCategoryContains(DoNotCollideCategories, other) then
            return false
        end

        -- check for specific do-not-collide entities, such as for strategic missiles not hitting air
        local doNotCollideList = false
        OnCollisionCheckTableCache[1][1] = self 
        OnCollisionCheckTableCache[1][2] = other 
        OnCollisionCheckTableCache[2][1] = other
        OnCollisionCheckTableCache[2][2] = self 
        for _, p in OnCollisionCheckTableCache do
            doNotCollideList= p[1].DoNotCollideListParsed
            if doNotCollideList then
                for _, v in doNotCollideList do
                    if EntityCategoryContains(v, p[2]) then
                        return false
                    end
                end
            end
        end

        -- if it should only hit a specific target and we're not the one being tracked
        if other.Blueprint.Physics.HitAssignedTarget and ProjectileGetTrackingTarget(other) ~= self then
            return false
        end

        return true
    end,

    -- Called by the engine when a projectile receives damage
    OnDamage = function(self, instigator, amount, vector, damageType)

        -- This type of damage is used to knock over trees
        if damageType == 'KnockOverTree' then 
            return 
        end

        if self.BlueprintDefenseMaxHealth then
            self.DoTakeDamage(self, instigator, amount, vector, damageType)
        else
            self.OnKilled(self, instigator, damageType)
        end
    end,

    -- Called by the engine when a projectile hits something - time for explosions!
    OnImpact = function(self, targetType, targetEntity)
        
        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local army = self.Army
        local instigator = self.Launcher or self 
        local damageData = self.DamageData
        local px, py, pz = self:GetPositionXYZ()

        -- Do the damage of this projectile
        self.DoDamage(self, instigator, damageData, targetEntity)

        -- Make trees fall down, needs to be applied after damage is to ensure the tree group is broken
        local knockOverTreeRadius = damageData.KnockOverTreeRadius or (0.5 * damageData.DamageRadius)
        if knockOverTreeRadius > 0 then 
            VectorCache[1] = px
            VectorCache[2] = py 
            VectorCache[3] = pz
            DamageArea(self, VectorCache, knockOverTreeRadius, 1, 'KnockOverTree', false)
        end

        -- Apply buffs of this projectile
        self.DoUnitImpactBuffs(self, targetEntity)

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local blueprintAudio = self.BlueprintAudio
        local snd = blueprintAudio['Impact' .. targetType]
        if snd then
            EntityPlaySound(self, snd)
            -- Generic Impact Sound
        elseif blueprintAudio.Impact then
            EntityPlaySound(self, blueprintAudio.Impact)
        end

        -- Possible 'target type' values are:
        --  'Unit', 'Terrain', 'Water'
        --  'Air', 'Prop', 'Shield'
        --  'UnitAir', 'UnderWater', 'UnitUnderwater'
        --  'Projectile', 'ProjectileUnderWater
        local ImpactEffects = false
        local ImpactEffectScale = 1
        local blueprint = self.Blueprint

        -- Determine effects
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

    -- Called by the engine when the projectile exits the water
    OnExitWater = function(self)
        -- no projectile blueprint has this value set
        local snd = self.Blueprint.Audio.ExitWater
        if snd then
            EntityPlaySound(self, snd)
        end
    end,

    -- Called by the engine when the projectile enters the water 
    OnEnterWater = function(self)
        local snd = self.BlueprintAudio.EnterWater
        if snd then
            EntityPlaySound(self, snd)
        end
    end,

    -- # Various Lua functions # --

    --- Passes the damage data in a shallow manner (reference copy instead of deep copy).
    ShallowPassDamageData = function(self, data)
        self.DamageData = data
        self.CollideFriendly = data.CollideFriendly
    end,

    --- Passes the damage data in a shallow manner (deep copy instead of reference).
    PassDamageData = function(self, data)
        -- only copy data that is present
        local SelfDamageData = self.DamageData
        for k, value in data do 
            SelfDamageData[k] = value
        end

        -- additional copy
        self.CollideFriendly = data.CollideFriendly
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

    -- Called by the engine when the projectile is killed
    OnKilled = function(self, instigator, type, overkillRatio)
        self.CreateImpactEffects(self, self.Army, self.FxOnKilled, self.FxOnKilledScale)
        EntityDestroy(self)
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

    -- Adds a flare, used by uab4201 (Aeon t2 TMD) and uas0202 (Aeon T2 Cruiser) and uas0302 (Aeon t3 Battleship)
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

    -- # Deprecated functionality # --

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

    --- This should never be called - use the actual function.
    GetCachePosition = function(self)

        -- deprecation warning in case it ever happens.
        if not DeprecatedWarnings.GetCachePosition then 
            DeprecatedWarnings.GetCachePosition = true 
            WARN("GetCachePosition is deprecated: use projectile:GetPosition() instead.")
            WARN("Source: " .. repr(debug.getinfo(2)))
        end

        return self:GetPosition()
    end,

    --- This should never be called - use the actual value.
    GetCollideFriendly = function(self)

        -- deprecation warning in case it ever happens.
        if not DeprecatedWarnings.GetCollideFriendly then 
            DeprecatedWarnings.GetCollideFriendly = true 
            WARN("GetCollideFriendly is deprecated: use projectile.CollideFriendly instead.")
            WARN("Source: " .. repr(debug.getinfo(2)))
        end

        return self.CollideFriendly
    end,
}

--- A dummy projectile that solely inherits what it needs. Useful for 
-- effects that require projectiles without additional overhead.
DummyProjectile = Class(moho.projectile_methods, Entity) {

    -- Cached in the meta table
    Cached = false,
    Blueprint = false, 
    DoNotCollideListParsed = false,

    -- Prevent calling these functions as we already have a C object
    __init = false,
    __post_init = false,

    -- Called when the projectile is created
    OnCreate = function(self, inWater) 

        if not self.Cached then 
            CacheViaMetatable(self)
        end

        -- store values for direct access to prevent hashing / engine calls
        self.Army = self:GetArmy()
        self.Launcher = self:GetLauncher()
        
        -- prepare trashbag
        self.Trash = TrashBag()
    end,

    -- Called when the projectile is destroyed
    OnDestroy = function(self)
        self.Trash:Destroy()
    end,
}