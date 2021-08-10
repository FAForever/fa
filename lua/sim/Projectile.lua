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

Projectile = Class(moho.projectile_methods, Entity) {
    PassDamageData = function(self, DamageData)
        self.DamageData.DamageRadius = DamageData.DamageRadius
        self.DamageData.DamageAmount = DamageData.DamageAmount
        self.DamageData.DamageType = DamageData.DamageType
        self.DamageData.DamageFriendly = DamageData.DamageFriendly
        self.DamageData.CollideFriendly = DamageData.CollideFriendly
        self.DamageData.DoTTime = DamageData.DoTTime
        self.DamageData.DoTPulses = DamageData.DoTPulses
        self.DamageData.MetaImpactAmount = DamageData.MetaImpactAmount
        self.DamageData.MetaImpactRadius = DamageData.MetaImpactRadius
        self.DamageData.Buffs = DamageData.Buffs
        self.DamageData.ArtilleryShieldBlocks = DamageData.ArtilleryShieldBlocks
        self.DamageData.InitialDamageAmount = DamageData.InitialDamageAmount
        self.CollideFriendly = self.DamageData.CollideFriendly
    end,

    DoDamage = function(self, instigator, DamageData, targetEntity)
        local damage = DamageData.DamageAmount
        if damage and damage > 0 then
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    DamageArea(instigator, self:GetPosition(), radius, damage, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, self:GetPosition(), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, self:GetPosition(), targetEntity, initialDmg, DamageData.DamageType)
                        end
                    end

                    ForkThread(DefaultDamage.AreaDoTThread, instigator, self:GetPosition(), DamageData.DoTPulses or 1, (DamageData.DoTTime / (DamageData.DoTPulses or 1)), radius, damage, DamageData.DamageType, DamageData.DamageFriendly)
                end
            -- ONLY DO DAMAGE IF THERE IS DAMAGE DATA.  SOME PROJECTILE DO NOT DO DAMAGE WHEN THEY IMPACT.
            elseif DamageData.DamageAmount and targetEntity then
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    Damage(instigator, self:GetPosition(), targetEntity, DamageData.DamageAmount, DamageData.DamageType)
                else
                    -- DoT damage - check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(instigator, self:GetPosition(), radius, initialDmg, DamageData.DamageType, DamageData.DamageFriendly, DamageData.DamageSelf or false)
                        elseif targetEntity then
                            Damage(instigator, self:GetPosition(), targetEntity, initialDmg, DamageData.DamageType)
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

    -- Do not call the base class __init and __post_init, we already have a c++ object
    __init = function(self, spec)
    end,

    __post_init = function(self, spec)
    end,

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    FxImpactAirUnit = {},
    FxImpactLand = {},
    FxImpactNone = {},
    FxImpactProp = {},
    FxImpactShield = {},
    FxImpactWater = {},
    FxImpactUnderWater = {},
    FxImpactUnit = {},
    FxImpactProjectile = {},
    FxImpactProjectileUnderWater = {},
    FxOnKilled = {},

    FxAirUnitHitScale = 1,
    FxLandHitScale = 1,
    FxNoneHitScale = 1,
    FxPropHitScale = 1,
    FxProjectileHitScale = 1,
    FxProjectileUnderWaterHitScale = 1,
    FxShieldHitScale = 1,
    FxUnderWaterHitScale = 0.25,
    FxUnitHitScale = 1,
    FxWaterHitScale = 1,
    FxOnKilledScale = 1,

    FxImpactLandScorch = false,
    FxImpactLandScorchScale = 1.0,

    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,

    OnCreate = function(self, inWater)

        --- Cache common (engine-related) values that are static
        self.Launcher = self:GetLauncher()
        self.Army = self:GetArmy()
        self.Blueprint = self:GetBlueprint()

        self.Trash = TrashBag()

        self.DamageData = {
            DamageRadius = nil,
            DamageAmount = nil,
            DamageType = nil,
            DamageFriendly = nil,
            MetaImpactAmount = nil,
            MetaImpactRadius = nil,
        }


        local bp = self.Blueprint
        self:SetMaxHealth(bp.Defense.MaxHealth or 1)
        self:SetHealth(self, self:GetMaxHealth())
        local snd = bp.Audio.ExistLoop
        if snd then
            self:SetAmbientSound(snd, nil)
        end

        if bp.Physics.TrackTargetGround and bp.Physics.TrackTargetGround == true then
            local pos = self:GetCurrentTargetPosition()
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            self:SetNewTargetGround(pos)
        end
    end,

    OnCollisionCheck = function(self, other)
        -- If we return false the thing hitting us has no idea that it came into contact with us.
        -- By default, anything hitting us should know about it so we return true.
        if self.Army == other.Army then return false end

        local dnc_cats = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE
        if EntityCategoryContains(dnc_cats, self) and EntityCategoryContains(dnc_cats, other) then
            return false
        end

        if other.Blueprint.Physics.HitAssignedTarget and other:GetTrackingTarget() ~= self then
            return false
        end

        local dnc
        for _, p in {{self, other}, {other, self}} do
            dnc = p[1].Blueprint.DoNotCollideList
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
        local bp = self.Blueprint.Defense.MaxHealth
        if bp then
            self:DoTakeDamage(instigator, amount, vector, damageType)
        else
            self:OnKilled(instigator, damageType)
        end
    end,

    OnDestroy = function(self)
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        -- Check for valid projectile
        if not self or self:BeenDestroyed() then
            return
        end

        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health <= 0 then
            if damageType == 'Reclaimed' then
                self:Destroy()
            else
                local excessDamageRatio = 0.0

                -- Calculate the excess damage amount
                local excess = health - amount
                local maxHealth = self.Blueprint.Defense.MaxHealth or 10
                if excess < 0 and maxHealth > 0 then
                    excessDamageRatio = -excess / maxHealth
                end
                self:OnKilled(instigator, damageType, excessDamageRatio)
            end
        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        self:CreateImpactEffects(self.Army, self.FxOnKilled, self.FxOnKilledScale)
        self:Destroy()
    end,

    DoMetaImpact = function(self, damageData)
        if damageData.MetaImpactRadius and damageData.MetaImpactAmount then
            local pos = self:GetPosition()
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            MetaImpact(self, pos, damageData.MetaImpactRadius, damageData.MetaImpactAmount)
        end
    end,

    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            if self.FxImpactTrajectoryAligned then
                emit = CreateEmitterAtBone(self, -2, army, v)
            else
                emit = CreateEmitterAtEntity(self, army, v)
            end
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    CreateTerrainEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            emit = CreateEmitterAtBone(self, -2, army, v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    GetTerrainEffects = function(self, TargetType, ImpactEffectType)
        local pos = self:GetPosition()
        local TerrainType = nil

        if ImpactEffectType then
            TerrainType = GetTerrainType(pos.x, pos.z)
            if TerrainType.FXImpact[TargetType][ImpactEffectType] == nil then
                TerrainType = GetTerrainType(-1, -1)
            end
        else
            TerrainType = GetTerrainType(-1, -1)
            ImpactEffectType = 'Default'
        end

        return TerrainType.FXImpact[TargetType][ImpactEffectType] or {}
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        if not firingWeapon.CollideFriendly and self.Army == firingWeapon.unit.Army then
            return false
        end

        -- If this unit category is on the weapon's do-not-collide list, skip!
        local weaponBP = firingWeapon.Blueprint
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
        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local instigator = self.Launcher
        if instigator == nil then
            instigator = self
        end
        local damageData = self.DamageData

        -- Do Damage
        self:DoDamage(instigator, damageData, targetEntity)

        -- Meta-Impact
        self:DoMetaImpact(damageData)

        -- Buffs (Stun, etc)
        self:DoUnitImpactBuffs(targetEntity)

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
        local ImpactEffects = {}
        local ImpactEffectScale = 1
        local bp = self.Blueprint
        local bpAud = bp.Audio

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local snd = bpAud['Impact'..targetType]
        if snd then
            self:PlaySound(snd)
            -- Generic Impact Sound
        elseif bpAud.Impact then
            self:PlaySound(bpAud.Impact)
        end

        -- ImpactEffects
        if targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale
        elseif targetType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
            if self.FxImpactLandScorch then
                Explosion.CreateRandomScorchSplatAtObject(self, self.FxImpactLandScorchScale, 150, 20, self.Army)
            end
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
        elseif targetType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        local TerrainEffects = self:GetTerrainEffects(targetType, bp.Display.ImpactEffects.Type)
        self:CreateImpactEffects(self.Army, ImpactEffects, ImpactEffectScale)
        self:CreateTerrainEffects(self.Army, TerrainEffects, bp.Display.ImpactEffects.Scale or 1)

        local timeout = bp.Physics.ImpactTimeout
        if timeout and targetType == 'Terrain' then
            self:ForkThread(self.ImpactTimeoutThread, timeout)
        else
            self:OnImpactDestroy(targetType, targetEntity)
        end
    end,

    OnImpactDestroy = function(self, targetType, targetEntity)
        if self.DestroyOnImpact or not targetEntity or
            (not self.DestroyOnImpact and targetEntity and not EntityCategoryContains(categories.ANTIMISSILE * categories.ALLPROJECTILES, targetEntity)) then
            self:Destroy()
        end
    end,

    ImpactTimeoutThread = function(self, seconds)
        WaitSeconds(seconds)
        self:Destroy()
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

    GetCachePosition = function(self)
        return self:GetPosition()
    end,

    GetCollideFriendly = function(self)
        return self.CollideFriendly
    end,

    PassData = function(self, data)
        self.Data = data
    end,

    OnExitWater = function(self)
        local bp = self.Blueprint.Audio['ExitWater']
        if bp then
            self:PlaySound(bp)
        end
    end,

    OnEnterWater = function(self)
        local bp = self.Blueprint.Audio['EnterWater']
        if bp then
            self:PlaySound(bp)
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
            self.Trash:Add(self.MyUpperFlare)
            self.Trash:Add(self.MyLowerFlare)
        end

        self.Trash:Add(self.MyFlare)
    end,

    OnLostTarget = function(self)
        local bp = self.Blueprint.Physics
        if bp.TrackTarget and bp.TrackTarget == true then
            if bp.OnLostTargetLifetime then
                self:SetLifetime(bp.OnLostTargetLifetime)
            else
                self:SetLifetime(0.5)
            end
        end
    end,
}
