------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local DefaultDamage = import("/lua/sim/defaultdamage.lua")
local Flare = import("/lua/defaultantiprojectile.lua").Flare

local TableGetn = table.getn

-- scorch mark interaction
local ScorchSplatTextures = {
    'scorch_001_albedo',
    'scorch_002_albedo',
    'scorch_003_albedo',
    'scorch_004_albedo',
    'scorch_005_albedo',
    'scorch_006_albedo',
    'scorch_007_albedo',
    'scorch_008_albedo',
    'scorch_009_albedo',
    'scorch_010_albedo',
}

-- various information surrounding the scorch marks that allows us to quickly access scorch marks
-- and prevents scorch marks at the same location
local ScorchSplatTexturesCount = TableGetn(ScorchSplatTextures)
local ScorchSplatTexturesLookup = { }
local ScorchSplatTexturesLookupCount = 100
local ScorchSplatTexturesLookupIndex = 1
for k = 1, ScorchSplatTexturesLookupCount do 
    ScorchSplatTexturesLookup[k] = Random(1, ScorchSplatTexturesCount)
end

-- terrain interaction 
local GetTerrainType = GetTerrainType
local DefaultTerrainType = GetTerrainType(-1, -1)
local TerrainEffectsPreviousX = 0
local TerrainEffectsPreviousZ = 0

-- keep track of the previous impact location to cull effects
local OnImpactPreviousX = 0
local OnImpactPreviousZ = 0

local VectorCached = Vector(0, 0, 0)

-- upvalue for performance
local EntityGetBlueprint = _G.moho.entity_methods.GetBlueprint
local EntityGetArmy = _G.moho.entity_methods.GetArmy
local EntitySetMaxHealth = _G.moho.entity_methods.SetMaxHealth
local EntitySetHealth = _G.moho.entity_methods.SetHealth
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ
local EntityDestroy = _G.moho.entity_methods.Destroy

local ProjectileGetLauncher = _G.moho.projectile_methods.GetLauncher

local TrashBag = TrashBag

local TableEmpty = table.empty

local EntityCategoryContains = EntityCategoryContains
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateSplat = CreateSplat
local DamageArea = DamageArea
local Damage = Damage
local Random = Random
local IsAlly = IsAlly
local ForkThread = ForkThread

-- cache categories computations
local CategoriesDoNotCollide = categories.TORPEDO + categories.MISSILE + categories.DIRECTFIRE
local OnImpactDestroyCategories = categories.ANTIMISSILE * categories.ALLPROJECTILES

---@class Projectile : moho.projectile_methods
Projectile = Class(moho.projectile_methods) {

    DestroyOnImpact = true,
    FxImpactTrajectoryAligned = true,

    -- tables used for effects

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

    -- scale values used for effects

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

    -- Engine functionality

    --- Called by the engine when the projectile is created
    ---@param self Projectile The projectile that we're creating
    ---@param inWater? boolean Flag to indicate the projectile is in water or not
    OnCreate = function(self, inWater)

        -- store information 
        self.Blueprint = EntityGetBlueprint(self)
        self.Army = EntityGetArmy(self)
        self.Launcher = ProjectileGetLauncher(self)
        self.Trash = TrashBag()

        -- set some health, if we have some
        if self.Blueprint.Defense and self.Blueprint.Defense.MaxHealth then
            local health = self.Blueprint.Defense.MaxHealth or 1
            EntitySetMaxHealth(self, health)
            EntitySetHealth(self, self, health)
        end

        -- only used by tactical missiles
        if self.Blueprint.Physics.TrackTargetGround then
            local pos = self:GetCurrentTargetPosition()
            pos[2] = GetSurfaceHeight(pos[1], pos[3])
            self:SetNewTargetGround(pos)
        end
    end,

    --- Called by the engine when a projectile collides with another projectile to check if the collision is valid. An example is a tactical missile defense
    ---@param self Projectile
    ---@param other Projectile The projectile we're checking the collision with
    ---@return boolean
    OnCollisionCheck = function(self, other)

        -- we can't hit our own
        if self.Army == other.Army then
            return false
        end

        -- flag if we can hit allied projectiles
        local alliedCheck = not (self.CollideFriendly and IsAlly(self.Army, other.Army))

        -- torpedoes can only be taken down by anti torpedo
        if self.Blueprint.CategoriesHash['TORPEDO'] then
            if other.Blueprint.CategoriesHash["ANTITORPEDO"] then
                return alliedCheck
            else
                return false
            end
        end

        -- missiles can only be taken down by anti missiles
        if self.Blueprint.CategoriesHash["TACTICAL"] or self.Blueprint.CategoriesHash["STRATEGIC"] then
            if other.Blueprint.CategoriesHash["ANTIMISSILE"] then
                return other.OriginalTarget == self
            else
                return false
            end
        end

        -- enemies always hit
        return alliedCheck
    end,

    --- Called by the engine when a projectile collides with a collision beam to check if the collision is valid
    ---@param self Projectile The projectile we're checking the collision for
    ---@param firingWeapon any The weapon the beam originates from that we're checking the collision with
    ---@return boolean
    OnCollisionCheckWeapon = function(self, firingWeapon)

        -- we can't hit our own
        if self.Army == firingWeapon.Army then 
            return false 
        end

        -- flag that indicates whether we should impact allied projectiles
        local alliedCheck = not (self.CollideFriendly and IsAlly(self.Army, firingWeapon.Army))

        -- specific check if we have a weapon that is defensive
        if firingWeapon.Blueprint.WeaponCategory == 'Defense' then 
            if self.Blueprint.CategoriesHash['TACTICAL'] or self.Blueprint.CategoriesHash['STRATEGIC'] then 
                return alliedCheck
            else 
                return false 
            end
        end

        -- depend on allied flag whether we hit or not
        return alliedCheck
    end,

    --- Called by the engine when the projectile receives damage
    ---@param self Projectile
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
    OnDamage = function(self, instigator, amount, vector, damageType)
        if self.Blueprint.Defense.MaxHealth then
            -- we have some health, try and survive
            self:DoTakeDamage(instigator, amount, vector, damageType)
        else
            -- we have no health, just perish
            self:OnKilled(instigator, damageType)
        end
    end,

    --- Called by the engine when the projectile is destroyed
    ---@param self Projectile
    OnDestroy = function(self)
        if self.Trash then
            self.Trash:Destroy()
        end
    end,

    --- Called by the engine when the projectile is killed, in other words: intercepted
    ---@param self Projectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)

        -- callbacks for launcher to have an idea what is going on for AIs
        if not IsDestroyed(self.Launcher) then 
            self.Launcher:OnMissileIntercepted(self:GetCurrentTargetPosition(), instigator, self:GetPosition())

            -- keep track of the number of intercepted missiles
            -- if not IsDestroyed(instigator) then 
            --     instigator:SetStat('KILLS', instigator:GetStat('KILLS', 0).Value + 1)
            -- end
        end

        self:CreateImpactEffects(self.Army, self.FxOnKilled, self.FxOnKilledScale)
        self:Destroy()
    end,

    --- Called by the engine when the projectile impacts something 
    ---@param self Projectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)

        -- in case the OnImpact crashes it guarantees that it gets destroyed at some point, useful for mods
        self.Impacts = (self.Impacts or 0) + 1
        if self.Impacts > 3 then 
            WARN("Faulty projectile destroyed manually: " .. tostring(self.Blueprint.BlueprintId))
            self:Destroy()
            return
        end

        -- localize information for performance
        local position = self:GetPosition()
        local damageData = self.DamageData
        local radius = damageData.DamageRadius or 0
        local bp = self.Blueprint

        -- callbacks for launcher to have an idea what is going on for AIs
        local categoriesHash = self.Blueprint.CategoriesHash
        if categoriesHash['TACTICAL'] or categoriesHash['STRATEGIC'] then
            -- we have a target, but got caught by terrain
            if targetType == 'Terrain' then
                if not IsDestroyed(self.Launcher) then
                    self.Launcher:OnMissileImpactTerrain(self:GetCurrentTargetPosition(), position)
                end

            -- we have a target, but got caught by an (unexpected) shield
            elseif targetType == 'Shield' then
                if not IsDestroyed(self.Launcher) then 
                    self.Launcher:OnMissileImpactShield(self:GetCurrentTargetPosition(), targetEntity.Owner, position)
                end
            end
        end

        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local instigator = self.Launcher or self

        -- localize information for performance
        local vc = VectorCached 
        vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)

        -- adjust the impact location based on the velocity of the thing we're hitting, this fixes a bug with damage being applied the tick after the collision
        -- is registered. As a result, the unit has moved one step ahead already, allowing it to 'miss' the area damage that we're trying to apply. Usually
        -- air units are affected by this, see also the pull request for a visual aid on this issue on Github
        if radius > 0 and targetEntity then
            if targetType == 'Unit' or targetType == 'UnitAir' then
                local vx, vy, vz = targetEntity:GetVelocity()
                vc[1] = vc[1] + vx
                vc[2] = vc[2] + vy
                vc[3] = vc[3] + vz
            elseif targetType == 'Shield' then
                local vx, vy, vz = targetEntity.Owner:GetVelocity()
                vc[1] = vc[1] + vx
                vc[2] = vc[2] + vy
                vc[3] = vc[3] + vz
            end
        end

        -- do the projectile damage
        self:DoDamage(instigator, damageData, targetEntity, vc)

        -- compute whether we should spawn additional effects for this
        -- projectile, there's always a 10% chance or if we're far away from
        -- the previous impact
        local dx = OnImpactPreviousX - vc[1]
        local dz = OnImpactPreviousZ - vc[3]
        local dsqrt = dx * dx + dz * dz
        local doEffects = Random() < 0.1 or dsqrt > radius

        -- do splat logic and knock over trees
        if radius > 0 and doEffects then

            -- update last position of known effects
            OnImpactPreviousX = vc[1]
            OnImpactPreviousZ = vc[3]

            -- knock over trees
            DamageArea(
                self,               -- instigator
                vc,                 -- position
                0.75 * radius,      -- radius
                1,                  -- damage amount
                'TreeForce',        -- damage type
                false               -- damage friendly flag
            )

            -- try and spawn in a splat
            if
                -- if we flat out hit the terrain
                targetType == "Terrain" or

                -- if we hit a unit that is on land
                (targetEntity and targetEntity.Layer == "Land")
            then 
                -- choose a splat to spawn
                local splat = bp.Display.ScorchSplat
                if not splat then 
                    splat = ScorchSplatTextures[ScorchSplatTexturesLookup[ScorchSplatTexturesLookupIndex]]
                    ScorchSplatTexturesLookupIndex = ScorchSplatTexturesLookupIndex + 1
                    if ScorchSplatTexturesLookupIndex > ScorchSplatTexturesLookupCount then 
                        ScorchSplatTexturesLookupIndex = 1 
                    end
                end

                -- choose our radius to use
                local altRadius = bp.Display.ScorchSplatSize
                if not altRadius then 
                    local damageMultiplier = (0.01 * damageData.DamageAmount)
                    if damageMultiplier > 1 then 
                        damageMultiplier = 1
                    end
                    altRadius = damageMultiplier * radius
                end

                -- radius, lod and lifetime share the same rng adjustment
                local rngRadius = altRadius * Random()

                CreateSplat(
                    -- position, orientation and the splat
                    vc,                                     -- position
                    6.28 * Random(),                        -- heading
                    splat,                                  -- splat

                    -- scale the splat, lod and duration randomly
                    0.75 * altRadius + 0.2 * rngRadius,     -- size x
                    0.75 * altRadius + 0.2 * rngRadius,     -- size z
                    10 + 30 * altRadius + 30 * rngRadius,   -- lod
                    8 + 8 * altRadius + 8 * rngRadius,      -- duration
                    self.Army                               -- owner of splat
                )
            end
        end

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
        local ImpactEffects = false
        local ImpactEffectScale = 1
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

        if targetType == 'Terrain' then
            ImpactEffects = self.FxImpactLand
            ImpactEffectScale = self.FxLandHitScale
        elseif targetType == 'Water' then
            ImpactEffects = self.FxImpactWater
            ImpactEffectScale = self.FxWaterHitScale
        elseif targetType == 'Unit' then
            ImpactEffects = self.FxImpactUnit
            ImpactEffectScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            ImpactEffects = self.FxImpactAirUnit
            ImpactEffectScale = self.FxAirUnitHitScale
        elseif targetType == 'Shield' then
            ImpactEffects = self.FxImpactShield
            ImpactEffectScale = self.FxShieldHitScale
        elseif targetType == 'Air' then
            ImpactEffects = self.FxImpactNone
            ImpactEffectScale = self.FxNoneHitScale
        elseif targetType == 'Projectile' then
            ImpactEffects = self.FxImpactProjectile
            ImpactEffectScale = self.FxProjectileHitScale
        elseif targetType == 'ProjectileUnderwater' then
            ImpactEffects = self.FxImpactProjectileUnderWater
            ImpactEffectScale = self.FxProjectileUnderWaterHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            ImpactEffects = self.FxImpactUnderWater
            ImpactEffectScale = self.FxUnderWaterHitScale
        elseif targetType == 'Prop' then
            ImpactEffects = self.FxImpactProp
            ImpactEffectScale = self.FxPropHitScale
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        ImpactEffects = ImpactEffects or { }

        -- impact effects, always make these
        self:CreateImpactEffects(self.Army, ImpactEffects, ImpactEffectScale)

        -- terrain effects, only make these when they're relatively unique
        if doEffects then   
            -- do the terrain effects
            local TerrainEffects = self:GetTerrainEffects(targetType, bp.Display.ImpactEffects.Type, vc)
            if TerrainEffects then 
                self:CreateTerrainEffects(self.Army, TerrainEffects, bp.Display.ImpactEffects.Scale or 1)
            end
        end

        -- in case we die slightly later
        local timeout = bp.Physics.ImpactTimeout
        if timeout and targetType == 'Terrain' then
            self.Trash:Add(ForkThread(self.ImpactTimeoutThread, self, timeout))
        else
            self:OnImpactDestroy(targetType, targetEntity)
        end
    end,

    --- Called by the engine when the projectile exits the water
    ---@param self Projectile
    OnExitWater = function(self)
        -- try and do a splash
        if self.FxExitWaterEmitter then 
            for k, v in self.FxExitWaterEmitter do
                CreateEmitterAtEntity(self, self.Army, v)
            end

            local bp = self.Blueprint.Audio['ExitWater']
            if bp then
                self:PlaySound(bp)
            end
        end
    end,

    --- Called by the engine when the projectile enters the water
    ---@param self Projectile
    OnEnterWater = function(self)
        -- try and do a splash
        if self.FxEnterWater then 
            for k, v in self.FxEnterWater do 
                CreateEmitterAtEntity(self, self.Army, v)
            end

            local bp = self.Blueprint.Audio['EnterWater']
            if bp then
                self:PlaySound(bp)
            end
        end
    end,

    --- Called by the engine when the target of the projectile is lost, typically due to 
    -- the target being destroyed before arrival.
    ---@param self Projectile
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

    -- Lua functionality

    --- Called by Lua to pass the damage data as a metatable
    ---@param self Projectile
    ---@param data table
    PassMetaDamage = function(self, data)
        self.DamageData = { }
        setmetatable(self.DamageData, data)
    end,

    --- Called by Lua to process the damage logic of a projectile
    -- @param self The projectile itself
    -- @param instigator The launcher, and if it doesn't exist, the projectile itself
    -- @param DamageData The damage data passed by the weapon
    -- @param targetEntity The entity we hit, is nil if we hit terrain
    -- @param cachedPosition A cached position that is passed to prevent table allocations, can not be used in fork threads and / or after a yield statement
    ---@param self Projectile
    ---@param instigator Unit
    ---@param DamageData table
    ---@param targetEntity Unit | Prop
    ---@param cachedPosition Vector
    DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)

        -- this may be a cached vector, we can not send this to threads or use after waiting statements!
        cachedPosition = cachedPosition or self:GetPosition()

        local damage = DamageData.DamageAmount
        if damage and damage > 0 then

            -- check for radius
            local radius = DamageData.DamageRadius
            if radius and radius > 0 then

                -- check for damage-over-time
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then
                    -- no damage over time, do radius-based damage
                    DamageArea(
                        instigator, 
                        cachedPosition, 
                        radius, 
                        damage, 
                        DamageData.DamageType, 
                        DamageData.DamageFriendly, 
                        DamageData.DamageSelf or false
                    )
                else
                    -- check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if radius > 0 then
                            DamageArea(
                                instigator, 
                                cachedPosition , 
                                radius, 
                                initialDmg, 
                                DamageData.DamageType, 
                                DamageData.DamageFriendly, 
                                DamageData.DamageSelf or false
                            )
                        elseif targetEntity then
                            Damage(
                                instigator, 
                                cachedPosition, 
                                targetEntity, 
                                initialDmg, 
                                DamageData.DamageType
                            )
                        end
                    end

                    -- apply damage over time
                    ForkThread(
                        DefaultDamage.AreaDoTThread, 
                        instigator, 
                        self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                        DamageData.DoTPulses or 1, 
                        (DamageData.DoTTime / (DamageData.DoTPulses or 1)), 
                        radius, 
                        damage, 
                        DamageData.DamageType, 
                        DamageData.DamageFriendly
                    )
                end

            -- check for entity-specific damage
            elseif DamageData.DamageAmount and targetEntity then

                -- check for damage-over-time
                if not DamageData.DoTTime or DamageData.DoTTime <= 0 then

                    -- no damage over time, do single target damage
                    Damage(
                        instigator, 
                        cachedPosition, 
                        targetEntity, 
                        DamageData.DamageAmount, 
                        DamageData.DamageType
                    )
                else
                    -- check for initial damage
                    local initialDmg = DamageData.InitialDamageAmount or 0
                    if initialDmg > 0 then
                        if targetEntity then
                            Damage(
                                instigator, 
                                cachedPosition, 
                                targetEntity, 
                                initialDmg, 
                                DamageData.DamageType
                            )
                        end
                    end

                    -- apply damage over time
                    ForkThread(
                        DefaultDamage.UnitDoTThread, 
                        instigator, 
                        targetEntity, 
                        DamageData.DoTPulses or 1, 
                        (DamageData.DoTTime / (DamageData.DoTPulses or 1)), 
                        damage, 
                        DamageData.DamageType, 
                        DamageData.DamageFriendly
                    )
                end
            end
        end

        -- related to strategic missiles
        if self.InnerRing and self.OuterRing then
            self.InnerRing:DoNukeDamage(
                self.Launcher, 
                self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                self.Brain, 
                self.Army, 
                DamageData.DamageType or 'Nuke'
            )

            self.OuterRing:DoNukeDamage(
                self.Launcher, 
                self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                self.Brain, 
                self.Army, 
                DamageData.DamageType or 'Nuke'
            )
        end
    end,

    --- Called by Lua to process buffs on impact
    ---@param self Projectile
    ---@param target Unit
    DoUnitImpactBuffs = function(self, target)
        local data = self.DamageData

        -- Check for buff
        if not TableEmpty(data.Buffs) then

            -- Check for valid target
            for k, v in data.Buffs do
                if v.Add.OnImpact == true then
                    if v.AppliedToTarget ~= true or (v.Radius and v.Radius > 0) then
                        target = self:GetLauncher()
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

    --- Called by Lua to determine whether the projectile should be destroyed
    ---@param self Projectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpactDestroy = function(self, targetType, targetEntity)
        if  self.DestroyOnImpact or 
            (not targetEntity) or
            (not EntityCategoryContains(OnImpactDestroyCategories, targetEntity))
        then
            EntityDestroy(self)
        end
    end,

    --- Called by Lua for a delayed destruction
    ---@param self Projectile
    ---@param seconds number
    ImpactTimeoutThread = function(self, seconds)
        WaitSeconds(seconds)
        self:Destroy()
    end,

    --- Called by Lua to add a flare
    ---@param self Projectile
    ---@param tbl? table
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

    --- Called by Lua to create the impact effects
    ---@param self Projectile
    ---@param army number
    ---@param EffectTable string[] 
    ---@param EffectScale? number
    CreateImpactEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            if self.FxImpactTrajectoryAligned then
                emit = CreateEmitterAtBone(self, -2, army, v)
            else
                emit = CreateEmitterAtEntity(self, army, v)
            end

            if EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    --- Called by Lua to create the terrain effects
    ---@param self  Projectile
    ---@param army number
    ---@param EffectTable string[]
    ---@param EffectScale? number
    CreateTerrainEffects = function(self, army, EffectTable, EffectScale)
        local emit = nil
        for _, v in EffectTable do
            emit = CreateEmitterAtBone(self, -2, army, v)
            if emit and EffectScale ~= 1 then
                emit:ScaleEmitter(EffectScale or 1)
            end
        end
    end,

    --- Called by Lua to retrieve the terrain effects
    ---@param self Projectile
    ---@param TargetType string
    ---@param ImpactEffectType string
    ---@param position Vector
    ---@return boolean
    GetTerrainEffects = function(self, TargetType, ImpactEffectType, position)

        local position = position or self:GetPosition()

        local TerrainType = nil
        if ImpactEffectType then
            TerrainType = GetTerrainType(position.x, position.z)
            if TerrainType.FXImpact[TargetType][ImpactEffectType] == nil then
                TerrainType = DefaultTerrainType
            end
        else
            TerrainType = DefaultTerrainType
            ImpactEffectType = 'Default'
        end

        return TerrainType.FXImpact[TargetType][ImpactEffectType] or false
    end,

    --- Called by Lua to process taking damage
    ---@param self Projectile
    ---@param instigator Unit
    ---@param amount number
    ---@param vector Vector
    ---@param damageType DamageType
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

    -- Deprecated functionality

    ---@deprecated
    ---@param self Projectile
    ---@return Vector
    GetCachePosition = function(self)
        return self:GetPosition()
    end,

    ---@deprecated
    ---@param self Projectile
    ---@param data table
    PassData = function(self, data)
        self.Data = data
    end,

    ---@deprecated
    ---@param self Projectile
    ---@return boolean
    GetCollideFriendly = function(self)
        return self.CollideFriendly
    end,

    ---@deprecated
    ---@param self Projectile
    ---@param DamageData table
    PassDamageData = function(self, DamageData)
        self.DamageData = { }
        self.DamageData.DamageRadius = DamageData.DamageRadius
        self.DamageData.DamageAmount = DamageData.DamageAmount
        self.DamageData.DamageType = DamageData.DamageType
        self.DamageData.DamageFriendly = DamageData.DamageFriendly
        self.DamageData.CollideFriendly = DamageData.CollideFriendly
        self.DamageData.DoTTime = DamageData.DoTTime
        self.DamageData.DoTPulses = DamageData.DoTPulses
        self.DamageData.Buffs = DamageData.Buffs
        self.DamageData.ArtilleryShieldBlocks = DamageData.ArtilleryShieldBlocks
        self.DamageData.InitialDamageAmount = DamageData.InitialDamageAmount
        self.CollideFriendly = self.DamageData.CollideFriendly
    end,

    ---root of all performance evil
    ---@deprecated
    ---@param self Projectile
    ---@param fn function
    ---@param ... any
    ---@return thread
    ForkThread = function(self, fn, ...)
        if fn then
            local thread = ForkThread(fn, self, unpack(arg))
            self.Trash:Add(thread)
            return thread
        else
            return nil
        end
    end,
}

--- A dummy projectile that solely inherits what it needs. Useful for 
-- effects that require projectiles without additional overhead.
---@class DummyProjectile : moho.projectile_methods
DummyProjectile = Class(moho.projectile_methods) {

    ---@param self DummyProjectile
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        -- expected to be cached by all projectiles
        self.Blueprint = EntityGetBlueprint(self) 
        self.Army = EntityGetArmy(self)
    end,

    ---@param self DummyProjectile
    ---@param targetType string
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        self:Destroy()
    end,
}

-- imports kept for backwards compatibility with mods

local Explosion = import("/lua/defaultexplosions.lua")
local Entity = import("/lua/sim/entity.lua").Entity