------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local Explosion = import('/lua/defaultexplosions.lua')
local DefaultDamage = import('/lua/sim/defaultdamage.lua')
local Flare = import('/lua/defaultantiprojectile.lua').Flare

-- upvalued globals for performance
local Damage = _G.Damage
local DamageArea = _G.DamageArea

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
local EntityGetHealth = EntityMethods.GetHealth
local EntitySetHealth = EntityMethods.SetHealth
local EntityAdjustHealth = EntityMethods.AdjustHealth
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

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
local DefaultTerrainTypeFxImpact = GetTerrainType(-1, -1).FXImpact

Projectile = Class(moho.projectile_methods, Entity) {

    -- data initialisation --

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

    -- this is always false: legacy code from SC1
    -- FxImpactLandScorch = false,
    -- FxImpactLandScorchScale = 1.0,

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    --- Passes the damage data as a shallow copy.
    PassDamageData = function(self, DamageData)
        -- shallow copy (copy reference)
        self.DamageData = DamageData
    end,

    --- Passes the data as a deep copy.
    DeepDamageData = function(self, DamageData)
        -- deep copy (copy values)

        -- cache for performance
        local selfDamageData = self.DamageData

        -- loop over table and get all values
        for k, data in Damagedata do 
            selfDamageData[k] = data
        end
    end,

    --- Performs damage.
    DoDamage = function(self, instigator, DamageData, targetEntity)
        local damage = DamageData.DamageAmount
        if damage and damage > 0 then
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    DamageArea(instigator, EntityGetPosition(self), radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, EntityGetPosition(self), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, EntityGetPosition(self), targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.AreaDoTThread, instigator, EntityGetPosition(self), DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), radius, damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            -- ONLY DO DAMAGE IF THERE IS DAMAGE DATA.  SOME PROJECTILE DO NOT DO DAMAGE WHEN THEY IMPACT.
            elseif DamageData.DamageAmount and targetEntity then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    Damage(instigator, EntityGetPosition(self), targetEntity, DamageData.DamageAmount, DamageData.DamageType)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, EntityGetPosition(self), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, EntityGetPosition(self), targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.UnitDoTThread, instigator, targetEntity, DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            end
        end
        if self.InnerRing and self.OuterRing then
            local pos = EntityGetPosition(self)
            self.InnerRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
            self.OuterRing:DoNukeDamage(self.Launcher, pos, self.Brain, self.Army, DamageData.DamageType or 'Nuke')
        end
    end,

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self, spec)
    end,

    __post_init = function(self, spec)
    end,

    OnCreate = function(self, inWater)
        -- retrieve the blueprint
        local blueprint = EntityGetBlueprint(self)

        -- cache some engine related information
        self.Trash = TrashBag()
        self.Army = EntityGetArmy(self)
        self.Launcher = ProjectileGetLauncher(self)
        self.Blueprint = blueprint -- questionable according to KionX
        
        -- this data is typically part of a shallow copy
        -- self.DamageData = false

        -- set health of projectile and cache max health
        local health = blueprint.Defense.MaxHealth or 1
        self.MaxHealth = health
        EntitySetMaxHealth(self, health)
        EntitySetHealth(self, self, health)

        -- adjust for surface height 
        if blueprint.Physics.TrackTargetGround and blueprint.Physics.TrackTargetGround == true then
            local pos = ProjectileGetCurrentTargetPosition(self)
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            ProjectileSetNewTargetGround(self, pos)
        end
    end,

    OnCollisionCheck = function(self, other)

        -- prevent colliding to ourselves
        if self.Army == other.Army then return false end

        -- standard do not collide categories
        if EntityCategoryContains(DoNotCollideCategories, self) and EntityCategoryContains(DoNotCollideCategories, other) then
            return false
        end

        if other:GetBlueprint().Physics.HitAssignedTarget and other:GetTrackingTarget() ~= self then
            return false
        end

        local dnc
        for _, p in {{self, other}, {other, self}} do
            dnc = p[1]:GetBlueprint().DoNotCollideList
            if dnc then
                for _, v in dnc do
                    if EntityCategoryContains(ParseEntityCategory(v), p[2]) then
                        return false
                    end
                end
            end
        end

        return true
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)
        -- only perform damage logic if we can sustain any damage
        if self.MaxHealth > 1 then
            self.DoTakeDamage(self, instigator, amount, vector, damageType)
        -- otherwise just get rid of ourselves :(
        else
            self.OnKilled(self, instigator, damageType)
        end
    end,

    OnDestroy = function(self)
        -- Not all projectiles inherit the OnCreate we made here. An example is
        -- the UEF dummy projectile for build animations. Hence the if statement.
        local trash = self.Trash 
        if trash then 
            TrashBagDestroy(self.Trash)
        end
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)

        -- check for valid projectile
        if not self or EntityBeenDestroyed(self) then
            return
        end

        -- adjust health accordingly
        EntityAdjustHealth(self, instigator, -amount)
        local health = EntityGetHealth(self)

        -- if we're a gooner
        if health <= 0 then
            -- hold up, reclaimable?
            if damageType == 'Reclaimed' then
                self:Destroy()
            -- create impact effects through OnKilled
            else
                self:OnKilled(instigator, damageType, 0)
            end
        end
    end,

    --- Called when the projectile is killed in a typical fashion
    OnKilled = function(self, instigator, type, overkillRatio)
        self.CreateImpactEffects(self, self.Army, self.FxOnKilled, self.FxOnKilledScale)
        EntityDestroy(self)
    end,

    --- TODO: What is this?
    DoMetaImpact = function(self, damageData)
        if damageData.MetaImpactRadius and damageData.MetaImpactAmount then
            local pos = EntityGetPosition(self)
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            MetaImpact(self, pos, damageData.MetaImpactRadius, damageData.MetaImpactAmount)
        end
    end,

    --- Creates the impact effects such as explosions when it a jet flies into the projectile
    CreateImpactEffects = function(self, army, effectTable, effectScale)

        -- keep on stack for performance
        local emit = false
        effectScale = effectScale or 1

        -- check if table exists, can be set to false
        if effectTable then 

            local fxImpactTrajectoryAligned = self.FxImpactTrajectoryAligned

            for _, v in effectTable do

                -- create emitter accordingly
                if fxImpactTrajectoryAligned then
                    emit = CreateEmitterAtBone(self, -2, army, v)
                else
                    emit = CreateEmitterAtEntity(self, army, v)
                end

                -- scale if applicable
                if effectScale != 1 then
                    EmitterScaleEmitter(emit, effectScale)
                end
            end
        end
    end,

    --- Creates terrain effects such as a water splash
    CreateTerrainEffects = function(self, army, effectTable, effectScale)
        -- keep on stack for performance
        local emit = false
        effectScale = effectScale or 1

        -- check if table exists, can be set to false
        if effectTable then 
            for _, v in effectTable do

                -- create emitter and scale accordingly
                emit = CreateEmitterAtBone(self, -2, army, v)
                if effectScale != 1 then
                    EmitterScaleEmitter(emit, effectScale)
                end
            end
        end
    end,

    --- Get the terrain effects depending on terrain type and impact type
    GetTerrainEffects = function(self, targetType, impactEffectType)
        -- default value
        impactEffectType = impactEffectType or 'Default'

        -- get x / z position
        local x, y, z = EntityGetPositionXYZ(self)
    
        -- get terrain at that location and try and get some effects
        local terrainTypeFxImpact = GetTerrainType(x, z).FXImpact
        return terrainTypeFxImpact[targetType][impactEffectType] or DefaultTerrainTypeFxImpact[targetType][impactEffectType] or { }
    end,

    --- Check if the firing weapon has its own do-not-collide list
    -- TODO: parsing in live code
    OnCollisionCheckWeapon = function(self, firingWeapon)
        if not firingWeapon.CollideFriendly and self.Army == firingWeapon.unit.Army then
            return false
        end

        -- If this unit category is on the weapon's do-not-collide list, skip!
        local weaponBP = firingWeapon:GetBlueprint()
        if weaponBP.DoNotCollideList then
            for k, v in pairs(weaponBP.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end
        return true
    end,

    -- Create some cool explosions when we get destroyed
    OnImpact = function(self, targetType, targetEntity)
        -- put values on stack for performance
        local army = self.Army
        local blueprint = self.Blueprint
        local damageData = self.DamageData
        local instigator = self.Launcher or self -- use launcher for army if available

        local ImpactEffects = false
        local ImpactEffectScale = 1

        -- Do Damage
        self.DoDamage(self, instigator, damageData, targetEntity)

        -- Meta-Impact
        self.DoMetaImpact(self, damageData)

        -- Buffs (Stun, etc)
        self.DoUnitImpactBuffs(self, targetEntity)

        -- try and play specific sound file, or generic as fallback
        local blueprintAudio = self.Blueprint.Audio
        local snd = blueprintAudio['Impact' .. targetType]
        if snd then
            EntityPlaySound(self, snd)
            -- Generic Impact Sound
        elseif blueprintAudio.Impact then
            EntityPlaySound(self, blueprintAudio.Impact)
        end

        -- Possible targetType values are:
        --  'Unit', 'Terrain', 'Water', 'Air', 'Prop'
        --  'Shield', 'UnitAir', 'UnderWater', 'UnitUnderwater'
        --  'Projectile', 'ProjectileUnderWater

        if targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
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

        -- check if they were set and use default values otherwise
        ImpactEffects = ImpactEffects or false
        ImpactEffectScale = ImpactEffectScale or self.FxScale or 1

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

    --- What to do when we're destroyed on impact
    OnImpactDestroy = function(self, targetType, targetEntity)
        local destroyOnImpact = self.DestroyOnImpact
        if destroyOnImpact or not targetEntity or
            (not destroyOnImpact and targetEntity and (not EntityCategoryContains(OnImpactDestroyCategories, targetEntity))) then
            EntityDestroy(self)
        end
    end,

    --- An impact delay for the dramatic effects
    ImpactTimeoutThread = function(self, seconds)
        WaitTicks(seconds * 10 + 1) -- add one for coroutine.yield offset
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
                    if v.AppliedToTarget ~= true or (v.Radius and v.Radius > 0) then
                        target = self.Launcher
                    end
                    -- Check for target validity
                    if target and IsUnit(target) then
                        if v.Radius and v.Radius > 0 then
                            -- This is a radius buff
                            -- get the position of the projectile
                            target:AddBuff(v, self:GetPosition())
                        else
                            -- This is a single target buff
                            target:AddBuff(v)
                        end
                    end
                end
            end
        end
    end,

    -- this should never be called - use the actual function.
    GetCachePosition = function(self)
        return self:GetPosition()
    end,

    -- this should never be called - use the actual value.
    GetCollideFriendly = function(self)
        return self.CollideFriendly
    end,

    -- this should never be called - use the actual value.
    PassData = function(self, data)
        self.Data = data
    end,

    OnExitWater = function(self)
        -- no projectile blueprint has this value set
        -- local snd = self.Blueprint.Audio.ExitWater
        -- if snd then
        --     self:PlaySound(snd)
        -- end
    end,

    OnEnterWater = function(self)
        local snd = self.Blueprint.Audio['EnterWater']
        if snd then
            self:PlaySound(snd)
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
        local bp = self.Blueprint.Physics
        if bp.TrackTarget then
            local time = bp.OnLostTargetLifetime or 0.5
            ProjectileSetLifetime(self, time)
        end
    end,
}
