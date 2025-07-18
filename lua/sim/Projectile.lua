------------------------------------------------------------------
--  File     :  /lua/sim/Projectile.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  :  Base Projectile Definition
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local DefaultDamage = import("/lua/sim/defaultdamage.lua")
local UnitDoTThread = DefaultDamage.UnitDoTThread
local AreaDoTThread = DefaultDamage.AreaDoTThread
local Flare = import("/lua/defaultantiprojectile.lua").Flare
local DepthCharge = import("/lua/defaultantiprojectile.lua").DepthCharge

local RotateVectorXYZByQuat =  import("/lua/utilities.lua").RotateVectorXYZByQuat

-- upvalue scope for performance
local unpack = unpack
local Damage = Damage
local Random = Random
local IsAlly = IsAlly
local ForkThread = ForkThread
local DamageArea = DamageArea
local IsDestroyed = IsDestroyed
local CreateSplat = CreateSplat
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateEmitterAtEntity = CreateEmitterAtEntity
local EntityCategoryContains = EntityCategoryContains

local DebugProjectileComponent = import("/lua/sim/projectiles/components/debugprojectilecomponent.lua").DebugProjectileComponent

local ProjectileMethods = moho.projectile_methods
local ProjectileMethodsCreateChildProjectile = ProjectileMethods.CreateChildProjectile
local ProjectileMethodsGetMaxZigZag = ProjectileMethods.GetMaxZigZag
local ProjectileMethodsGetZigZagFrequency = ProjectileMethods.GetZigZagFrequency
local ProjectileMethodsSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration

local EntityMethods = _G.moho.entity_methods
local EntityGetBlueprint = EntityMethods.GetBlueprint
local EntityGetArmy = EntityMethods.GetArmy
local EntitySetMaxHealth = EntityMethods.SetMaxHealth
local EntitySetHealth = EntityMethods.SetHealth
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ
local EntityDestroy = EntityMethods.Destroy
local EntityGetOrientation = EntityMethods.GetOrientation
local EntityPlaySound = EntityMethods.PlaySound

local TrashBag = TrashBag
local TrashBagAdd = TrashBag.Add
local TrashBagDestroy = TrashBag.Destroy

local TableEmpty = table.empty
local TableGetn = table.getn

-- cache categories computations
local OnImpactDestroyCategories = categories.ANTIMISSILE * categories.ALLPROJECTILES

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
local ScorchSplatTexturesLookup = {}
local ScorchSplatTexturesLookupCount = 100
local ScorchSplatTexturesLookupIndex = 1
for k = 1, ScorchSplatTexturesLookupCount do
    ScorchSplatTexturesLookup[k] = Random(1, ScorchSplatTexturesCount)
end

-- terrain interaction
local GetTerrainType = GetTerrainType
local DefaultTerrainType = GetTerrainType(-1, -1)

-- keep track of the previous impact location to cull effects
local OnImpactPreviousX = 0
local OnImpactPreviousZ = 0

local VectorCached = Vector(0, 0, 0)

---@class Projectile : moho.projectile_methods, InternalObject, DebugProjectileComponent
---@field Blueprint ProjectileBlueprint
---@field Army Army
---@field Trash TrashBag
---@field Launcher Unit
---@field OriginalTarget? Unit | Blip
---@field DamageData WeaponDamageTable
---@field MyDepthCharge? DepthCharge    # If weapon blueprint has a (valid) `DepthCharge` field
---@field MyFlare? Flare            # If weapon blueprint has a (valid) `Flare` field
---@field MyUpperFlare? Flare       # If weapon blueprint has a (valid) `Flare` field that wants to be stacked
---@field MyLowerFlare? Flare       # If weapon blueprint has a (valid) `Flare` field that wants to be stacked
---@field CreatedByWeapon Weapon
---@field IsRedirected? boolean
---@field InnerRing? NukeAOE
---@field OuterRing? NukeAOE
Projectile = ClassProjectile(ProjectileMethods, DebugProjectileComponent) {
    IsProjectile = true,
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
        local blueprint = EntityGetBlueprint(self) --[[@as ProjectileBlueprint]]
        local trash = TrashBag() --[[@as TrashBag]]

        self.Blueprint = blueprint
        self.Trash = trash
        self.Army = EntityGetArmy(self) --[[@as number]]
        self.Launcher = self:GetLauncher() --[[@as Unit]]

        -- set some health, if we have some
        local maxHealth = blueprint.Defense.MaxHealth
        if maxHealth then
            EntitySetMaxHealth(self, maxHealth)
            EntitySetHealth(self, self, maxHealth)
        end

        -- do not track target, but track where the target was
        if blueprint.Physics.TrackTargetGround then
            TrashBagAdd(trash, ForkThread(self.OnTrackTargetGround, self))
        end
    end,

    --- Called by Lua during the `OnCreate` event when the blueprint field `TrackTargetGround` is set,
    --- used by tactical missiles to track a point around/inside the target's hitbox
    ---@param self Projectile
    OnTrackTargetGround = function(self)
        local target = self.OriginalTarget or self:GetTrackingTarget() or self.Launcher:GetTargetEntity()
        local physics = self.Blueprint.Physics
        local offset = physics.TrackTargetGroundOffset or 0

        if target and target.IsUnit then
            local unitBlueprint = target.Blueprint

            -- X-offset units often have displaced center bones, so they're not accounted for.
            local cy, cz = unitBlueprint.CollisionOffsetY or 0, unitBlueprint.CollisionOffsetZ or 0
            local sx, sy, sz = unitBlueprint.SizeX or 1, unitBlueprint.SizeY or 1, unitBlueprint.SizeZ or 1
            local px, py, pz = target:GetPositionXYZ()

            -- don't target the part of the hitbox below the surface
            if cy < 0 then
                sy = sy + cy
                cy = 0
            end

            local fuzziness = physics.TrackTargetGroundFuzziness or 0.8
            sx = sx + offset
            sz = sz + offset

            local dx = sx * (Random() - 0.5) * fuzziness
            local dy = (sy + offset) * (Random() - 0.5) * fuzziness + sy / 2 + cy
            local dz = sz * (Random() - 0.5) * fuzziness + cz

            local orientation = EntityGetOrientation(target)

            dx, dy, dz = RotateVectorXYZByQuat(dx, dy, dz, orientation)

            self:SetNewTargetGroundXYZ(px + dx, py + dy, pz + dz)
        else
            local px, _, pz = self:GetCurrentTargetPositionXYZ()

            local fuzziness = physics.TrackTargetGroundFuzziness or 0
            local tx = px + (Random() - 0.5) * fuzziness * (1 + offset)
            local tz = pz + (Random() - 0.5) * fuzziness * (1 + offset)

            self:SetNewTargetGroundXYZ(tx, GetSurfaceHeight(tx, tz), tz)
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

        local selfHashedCategories = self.Blueprint.CategoriesHash
        local otherHashedCategories = other.Blueprint.CategoriesHash

        -- torpedoes can only be taken down by anti torpedo
        if selfHashedCategories['TORPEDO'] then
            if otherHashedCategories["ANTITORPEDO"] then
                return other.OriginalTarget == self
            else
                return false
            end
        end

        -- missiles can only be taken down by anti missiles
        if selfHashedCategories["TACTICAL"] or selfHashedCategories["STRATEGIC"] then
            if otherHashedCategories["ANTIMISSILE"] then
                return other.OriginalTarget == self
            else
                return false
            end
        end

        -- enemies always hit
        return not (self.CollideFriendly and IsAlly(self.Army, other.Army)) -- flag if we can hit allied projectiles
    end,

    --- Called by the engine when a projectile collides with a collision beam to check if the collision is valid
    ---@param self Projectile The projectile we're checking the collision for
    ---@param firingWeapon Weapon The weapon the beam originates from that we're checking the collision with
    ---@return boolean
    OnCollisionCheckWeapon = function(self, firingWeapon)
        -- we can't hit our own
        if self.Army == firingWeapon.Army then
            return false
        end

        local selfHashedCategories = self.Blueprint.CategoriesHash

        -- check for projectile types that require a defensive weapon to intercept
        if selfHashedCategories['TACTICAL'] or selfHashedCategories['STRATEGIC'] or selfHashedCategories['TORPEDO'] then
            if firingWeapon.Blueprint.WeaponCategory == 'Defense' then
                return firingWeapon:GetCurrentTarget() == self
            else
                return false
            end
        end

        -- depend on allied flag whether we hit or not
        return not (self.CollideFriendly and IsAlly(self.Army, firingWeapon.Army)) -- flag that indicates whether we should impact allied projectiles
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
        local trash = self.Trash
        if trash then
            TrashBagDestroy(trash)
        end
    end,

    --- Called by the engine when the projectile is killed, in other words: intercepted
    ---@param self Projectile
    ---@param instigator Unit
    ---@param type string
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)

        -- callbacks for launcher to have an idea what is going on for AIs
        local launcher = self.Launcher
        if not IsDestroyed(launcher) then
            launcher:OnMissileIntercepted(self:GetCurrentTargetPosition(), instigator, self:GetPosition(), self)

            -- keep track of the number of intercepted missiles
            if not IsDestroyed(instigator) and instigator.GetStat then
                instigator:UpdateStat('KILLS', instigator:GetStat('KILLS', 0).Value + 1)
            end
        end

        self:CreateImpactEffects(self.Army, self.FxOnKilled, self.FxOnKilledScale)
        self:Destroy()
    end,

    --- Called by the engine when the projectile impacts something
    ---@param self Projectile
    ---@param targetType ImpactType
    ---@param targetEntity Unit | Prop
    OnImpact = function(self, targetType, targetEntity)
        -- Since collision is checked before impacts are run, collision changes caused by impacts need to be checked by impacts
        -- For example, a shield will first tell every projectile that it can collide with it, and then only afterwards will
        -- HP be drained from the shield, and collisions turned off due to the shield being down. The same applies for units.
        if targetEntity.DisallowCollisions then
            return
        end

        -- localize information for performance
        local position = self:GetPosition()
        local damageData = self.DamageData
        local radius = damageData.DamageRadius or 0

        local launcher = self.Launcher

        local blueprint = self.Blueprint
        local blueprintAudio = blueprint.Audio
        local blueprintDisplay = blueprint.Display
        local blueprintCategoriesHash = blueprint.CategoriesHash

        -- callbacks for launcher to have an idea what is going on for AIs
        if blueprintCategoriesHash['TACTICAL'] or blueprintCategoriesHash['STRATEGIC'] then

            -- we have a target, but got caught by terrain
            if targetType == 'Terrain' then
                if not IsDestroyed(launcher) then
                    launcher:OnMissileImpactTerrain(self:GetCurrentTargetPosition(), position)
                end

                -- we have a target, but got caught by an (unexpected) shield
            elseif targetType == 'Shield' then
                if not IsDestroyed(launcher) then
                    launcher:OnMissileImpactShield(self:GetCurrentTargetPosition(), targetEntity.Owner, position)
                end
            end
        end

        -- Try to use the launcher as instigator first. If its been deleted, use ourselves (this
        -- projectile is still associated with an army)
        local instigator = launcher or self

        -- localize information for performance
        local vcx, vcy, vcz = EntityGetPositionXYZ(self)

        -- adjust the impact location based on the velocity of the thing we're hitting, this fixes a bug with damage being applied the tick after the collision
        -- is registered. As a result, the unit has moved one step ahead already, allowing it to 'miss' the area damage that we're trying to apply. Usually
        -- air units are affected by this, see also the pull request for a visual aid on this issue on Github
        if radius > 0 and targetEntity then
            if targetType == 'Unit' or targetType == 'UnitAir' then
                local velx, vely, velz = targetEntity:GetVelocity()
                vcx = vcx + velx
                vcy = vcy + vely
                vcz = vcz + velz
            elseif targetType == 'Shield' then
                local velx, vely, velz = targetEntity.Owner:GetVelocity()
                vcx = vcx + velx
                vcy = vcy + vely
                vcz = vcz + velz
            end
        end

        -- localize information for performance
        local vc = VectorCached
        vc[1], vc[2], vc[3] = vcx, vcy, vcz

        -- do the projectile damage
        self:DoDamage(instigator, damageData, targetEntity, vc)

        -- compute whether we should spawn additional effects for this
        -- projectile, there's always a 10% chance or if we're far away from
        -- the previous impact
        local dx = OnImpactPreviousX - vcx
        local dz = OnImpactPreviousZ - vcz
        local dsqrt = dx * dx + dz * dz
        local doEffects = Random() < 0.1 or dsqrt > radius

        -- do splat logic and knock over trees
        if radius > 0 and doEffects then

            -- update last position of known effects
            OnImpactPreviousX = vcx
            OnImpactPreviousZ = vcz

            -- knock over trees
            DamageArea(
                self, -- instigator
                vc, -- position
                0.75 * radius, -- radius
                1, -- damage amount
                'TreeForce', -- damage type
                false-- damage friendly flag
            )

            if (-- see if we need to spawn a splat
                targetType == "Terrain" or
                    targetEntity and targetEntity.Layer == "Land"
                ) and (not blueprintDisplay.NoGenericScorchSplats)
            then
                -- choose a splat
                local splat = ScorchSplatTextures[ ScorchSplatTexturesLookup[ScorchSplatTexturesLookupIndex] ]
                ScorchSplatTexturesLookupIndex = ScorchSplatTexturesLookupIndex + 1
                if ScorchSplatTexturesLookupIndex > ScorchSplatTexturesLookupCount then
                    ScorchSplatTexturesLookupIndex = 1
                end

                -- determine radius
                local damageMultiplier = (0.01 * damageData.DamageAmount)
                if damageMultiplier > 1 then
                    damageMultiplier = 1
                end
                local altRadius = damageMultiplier * radius

                -- radius, lod and lifetime share the same rng adjustment
                local rngRadius = altRadius * Random()

                local splatRadius = 0.75 * altRadius + 0.2 * rngRadius

                CreateSplat(
                    vc, -- position
                    6.28 * Random(), -- heading
                    splat, -- splat

                    -- scale the splat, lod and duration randomly
                    splatRadius, -- size x
                    splatRadius, -- size z
                    10 + 30 * altRadius + 30 * rngRadius, -- lod
                    8 + 8 * altRadius + 8 * rngRadius, -- duration
                    self.Army-- owner of splat
                )
            end
        end

        -- Buffs (Stun, etc)
        self:DoUnitImpactBuffs(targetEntity)

        -- Sounds for all other impacts, ie: Impact<TargetTypeName>
        local snd = blueprintAudio['Impact' .. targetType]
        if snd then
            EntityPlaySound(self, snd)
        elseif blueprintAudio.Impact then
            EntityPlaySound(self, blueprintAudio.Impact)
        end

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
        local impactEffects
        local impactEffectsScale = 1

        if targetType == 'Terrain' then
            impactEffects = self.FxImpactLand
            impactEffectsScale = self.FxLandHitScale
        elseif targetType == 'Water' then
            impactEffects = self.FxImpactWater
            impactEffectsScale = self.FxWaterHitScale
        elseif targetType == 'Unit' then
            impactEffects = self.FxImpactUnit
            impactEffectsScale = self.FxUnitHitScale
        elseif targetType == 'UnitAir' then
            impactEffects = self.FxImpactAirUnit
            impactEffectsScale = self.FxAirUnitHitScale
        elseif targetType == 'Shield' then
            impactEffects = self.FxImpactShield
            impactEffectsScale = self.FxShieldHitScale
        elseif targetType == 'Air' then
            impactEffects = self.FxImpactNone
            impactEffectsScale = self.FxNoneHitScale
        elseif targetType == 'Projectile' then
            impactEffects = self.FxImpactProjectile
            impactEffectsScale = self.FxProjectileHitScale
        elseif targetType == 'ProjectileUnderwater' then
            impactEffects = self.FxImpactProjectileUnderWater
            impactEffectsScale = self.FxProjectileUnderWaterHitScale
        elseif targetType == 'Underwater' or targetType == 'UnitUnderwater' then
            impactEffects = self.FxImpactUnderWater
            impactEffectsScale = self.FxUnderWaterHitScale
        elseif targetType == 'Prop' then
            impactEffects = self.FxImpactProp
            impactEffectsScale = self.FxPropHitScale
        else
            LOG('*ERROR: Projectile:OnImpact(): UNKNOWN TARGET TYPE ', repr(targetType))
        end

        if impactEffects then
            -- impact effects, always make these
            self:CreateImpactEffects(self.Army, impactEffects, impactEffectsScale)
        end

        -- terrain effects, only make these when they're relatively unique
        if doEffects then
            -- do the terrain effects
            local blueprintDislayImpactEffects = blueprintDisplay.ImpactEffects
            local terrainEffects = self:GetTerrainEffects(targetType, blueprintDislayImpactEffects.Type, vc)
            if terrainEffects then
                self:CreateTerrainEffects(self.Army, terrainEffects, blueprintDislayImpactEffects.Scale or 1)
            end
        end

        self:OnImpactDestroy(targetType, targetEntity)
    end,

    --- Called by the engine when the projectile exits the water
    ---@param self Projectile
    OnExitWater = function(self)
        -- try and do a splash
        local fxExitWater = self.FxExitWaterEmitter
        if fxExitWater then
            local army = self.Army
            local blueprintAudio = self.Blueprint.Audio['ExitWater']
            for _, v in fxExitWater do
                CreateEmitterAtEntity(self, army, v)
            end

            if blueprintAudio then
                EntityPlaySound(self, blueprintAudio)
            end
        end
    end,

    --- Called by the engine when the projectile enters the water
    ---@param self Projectile
    OnEnterWater = function(self)
        -- try and do a splash
        local fxEnterWater = self.FxEnterWater
        if fxEnterWater then
            local army = self.Army
            local blueprintAudio = self.Blueprint.Audio['EnterWater']
            for _, v in fxEnterWater do
                CreateEmitterAtEntity(self, army, v)
            end

            if blueprintAudio then
                EntityPlaySound(self, blueprintAudio)
            end
        end
    end,

    --- Called by the engine when the target of the projectile is lost, typically due to
    -- the target being destroyed before arrival.
    ---@param self Projectile
    OnLostTarget = function(self)
        local bp = self.Blueprint.Physics
        if bp.TrackTarget and not bp.TrackTargetGround then
            TrashBagAdd(self.Trash, ForkThread(self.RetargetThread, self))
        end
    end,

    -- Lua functionality

    ---@param self Projectile
    RetargetThread = function(self)
        local createdByWeapon = self.CreatedByWeapon
        if createdByWeapon then
            WaitTicks(0.5)

            if IsDestroyed(self) then
                return
            end

            if IsDestroyed(createdByWeapon) then
                return
            end

            local target = createdByWeapon:GetCurrentTarget()
            if target then
                self:SetNewTarget(target)
                self:TrackTarget(true)
                return
            end
        end

        -- we couldn't find a new target, take us out
        local bp = self.Blueprint.Physics
        if bp.OnLostTargetLifetime then
            self:SetLifetime(bp.OnLostTargetLifetime)
        else
            self:SetLifetime(0.5)
        end
    end,

    -- Lua functionality

    --- Called by Lua to pass the damage data as a metatable
    ---@param self Projectile
    ---@param data WeaponDamageTable
    PassMetaDamage = function(self, data)
        self.DamageData = {}
        setmetatable(self.DamageData, data)
    end,

    --- Called by Lua to process the damage logic of a projectile
    ---@param self Projectile
    ---@param instigator Unit # The launcher, and if it doesn't exist, the projectile itself
    ---@param DamageData WeaponDamageTable # passed by the weapon
    ---@param targetEntity Unit | Prop | nil # nil if hitting terrain
    ---@param cachedPosition Vector # A cached position that is passed to prevent table allocations, can not be used in fork threads and / or after a yield statement
    DoDamage = function(self, instigator, DamageData, targetEntity, cachedPosition)

        -- this may be a cached vector, we can not send this to threads or use after waiting statements!
        cachedPosition = cachedPosition or self:GetPosition()

        local damage = DamageData.DamageAmount
        if damage > 0 then

            -- deal damage in a radius
            local radius = DamageData.DamageRadius
            if radius > 0 then
                local damageType = DamageData.DamageType
                local damageFriendly =  DamageData.DamageFriendly
                local damageSelf = DamageData.DamageSelf or false

                -- do initial damage in a radius
                -- anti-shield damage first so that the remaining damage can overkill under the shield
                local damageToShields = DamageData.DamageToShields
                if damageToShields then
                    DamageArea(
                        instigator,
                        cachedPosition,
                        radius,
                        damageToShields,
                        "FAF_AntiShield",
                        damageFriendly,
                        damageSelf
                    )
                end

                DamageArea(
                    instigator,
                    cachedPosition,
                    radius,
                    damage + (DamageData.InitialDamageAmount or 0),
                    damageType,
                    damageFriendly,
                    damageSelf
                )

                -- check for and deal damage over time
                local DoTTime = DamageData.DoTTime
                if DoTTime > 0 then
                    -- initial damage pulse was already dealt so subtract 1
                    local DoTPulses = DamageData.DoTPulses - 1
                    if DoTPulses >= 1 then
                        ForkThread(
                            AreaDoTThread,
                            instigator,
                            self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                            DoTPulses,
                            (DoTTime / (DoTPulses)),
                            radius,
                            damage,
                            damageType,
                            damageFriendly
                        )
                    end
                end

            -- damage a single entity
            elseif targetEntity then
                local damageType = DamageData.DamageType

                -- do initial damage
                -- anti-shield damage first so remainder can overkill under the shield
                local damageToShields = DamageData.DamageToShields
                if damageToShields then
                    Damage(
                        instigator,
                        cachedPosition,
                        targetEntity,
                        damageToShields,
                        "FAF_AntiShield"
                    )
                end

                Damage(
                    instigator,
                    cachedPosition,
                    targetEntity,
                    damage + (DamageData.InitialDamageAmount or 0),
                    damageType
                )

                -- check for and apply damage over time
                local DoTTime = DamageData.DoTTime
                if DoTTime > 0 then
                    -- initial damage pulse was already dealt so subtract 1
                    local DoTPulses = DamageData.DoTPulses - 1
                    if DoTPulses >= 1 then
                        ForkThread(
                            UnitDoTThread,
                            instigator,
                            targetEntity,
                            DoTPulses,
                            (DoTTime / (DoTPulses)),
                            damage,
                            damageType
                        )
                    end
                end
            end
        end

        -- related to strategic missiles
        if self.InnerRing and self.OuterRing then
            local damageType = DamageData.DamageType or 'Nuke'
            self.InnerRing:DoNukeDamage(
                self.Launcher,
                self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                self.Brain,
                self.Army,
                damageType
            )

            self.OuterRing:DoNukeDamage(
                self.Launcher,
                self:GetPosition(), -- can't use cachedPosition here: breaks invariant
                self.Brain,
                self.Army,
                damageType
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
        if self.DestroyOnImpact or
            (not targetEntity) or
            (not EntityCategoryContains(OnImpactDestroyCategories, targetEntity))
        then
            EntityDestroy(self)
        end
    end,

    --- Called by Lua to add a flare
    ---@param self Projectile
    ---@param tbl? WeaponBlueprintFlare
    AddFlare = function(self, tbl)
        if not (tbl and tbl.Radius) then return end
        local flareSpec = {
            Owner = self,
            Radius = tbl.Radius,
            Category = tbl.Category, -- We pass the category bp value along so that it actually has a function.
        }

        self.MyFlare = Flare(flareSpec)
        TrashBagAdd(self.Trash, self.MyFlare)

        if tbl.Stack == true then -- Secondary flare hitboxes, one above, one below (Aeon TMD)
            local offsetMutl = tbl.OffsetMult

            flareSpec.OffSetMult = offsetMutl
            self.MyUpperFlare = Flare(flareSpec)
            TrashBagAdd(self.Trash, self.MyUpperFlare)

            flareSpec.OffSetMult = -offsetMutl
            self.MyLowerFlare = Flare(flareSpec)
            TrashBagAdd(self.Trash, self.MyLowerFlare)
        end
    end,

    ---@param self TDepthChargeProjectile
    ---@param blueprint WeaponBlueprintDepthCharge
    AddDepthCharge = function(self, blueprint)
        if not (blueprint and blueprint.Radius) then return end

        ---@type DepthChargeSpec
        local depthChargeSpec = {
            Owner = self,
            Radius = blueprint.Radius or 10,
            ProjectilesToDeflect = blueprint.ProjectilesToDeflect
        }

        self.MyDepthCharge = TrashBagAdd(self.Trash, DepthCharge(depthChargeSpec))
    end,

    --- Called by Lua to create the impact effects
    ---@param self Projectile
    ---@param army number
    ---@param effectTable string[]
    ---@param effectScale? number
    CreateImpactEffects = function(self, army, effectTable, effectScale)
        local emit = nil
        local scaleEmit = effectScale and effectScale ~= 1
        local fxImpactTrajectoryAligned = self.FxImpactTrajectoryAligned
        for _, v in effectTable do
            if fxImpactTrajectoryAligned then
                emit = CreateEmitterAtBone(self, -2, army, v)
            else
                emit = CreateEmitterAtEntity(self, army, v)
            end

            if scaleEmit then
                emit:ScaleEmitter(effectScale or 1)
            end
        end
    end,

    --- Called by Lua to create the terrain effects
    ---@param self  Projectile
    ---@param army number
    ---@param effectTable string[]
    ---@param effectScale? number
    CreateTerrainEffects = function(self, army, effectTable, effectScale)
        local emit = nil
        local scaleEmit = effectScale and effectScale ~= 1
        for _, v in effectTable do
            emit = CreateEmitterAtBone(self, -2, army, v)
            if emit and scaleEmit then
                ---@diagnostic disable-next-line: param-type-mismatch
                emit:ScaleEmitter(effectScale)
            end
        end
    end,

    --- Called by Lua to retrieve the terrain effects
    ---@param self Projectile
    ---@param targetType string
    ---@param impactEffectType string
    ---@param position Vector
    ---@return string[] | boolean
    GetTerrainEffects = function(self, targetType, impactEffectType, position)
        position = position or self:GetPosition()

        local terrainType = nil
        if impactEffectType then
            terrainType = GetTerrainType(position[1], position[3])
            if terrainType.FXImpact[targetType][impactEffectType] == nil then
                terrainType = DefaultTerrainType
            end
        else
            terrainType = DefaultTerrainType
            impactEffectType = 'Default'
        end

        return terrainType.FXImpact[targetType][impactEffectType] or false
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

    ---------------------------------------------------------------------------
    --#region C hooks

    --- Creates a child projectile that inherits the speed, orientation and launcher of its parent
    ---@param blueprint BlueprintId
    ---@return Projectile
    CreateChildProjectile = function(self, blueprint)
        local childProjectile = ProjectileMethodsCreateChildProjectile(self, blueprint)
        childProjectile.Launcher = self.Launcher
        return childProjectile
    end,

    --- Returns the zig zag distance of the projectile.
    ---@param self Projectile
    ---@return number
    GetMaxZigZag = function(self)
        local distance = ProjectileMethodsGetMaxZigZag(self)
        if distance == -1 then
            distance = self.Blueprint.Physics.MaxZigZag or 0
        end

        return distance
    end,

    --- Returns the zig zag frequency of the projectile.
    ---@param self Projectile
    ---@return number
    GetZigZagFrequency = function(self)
        local frequency = ProjectileMethodsGetZigZagFrequency(self)
        if frequency == -1 then
            frequency = self.Blueprint.Physics.ZigZagFrequency or 0
        end

        return frequency
    end,

    --- Set the vertical (gravitational) acceleration of the projectile. Default is -4.9, which is expected by the engine's weapon targeting and firing
    ---@param acceleration number
    SetBallisticAcceleration = function(self, acceleration)

        -- Fix an engine bug where the values `1.#INF` or `-1.#IND` passed 
        -- into this particular engine function can cause the simulation to freeze up.
        --
        -- Since `math.huge` does not exist (and does not cover the #IND case) I see
        -- no other approach than this to try and 'fix' it.
        --
        -- Related sources:
        -- - https://stackoverflow.com/questions/19107302/in-lua-what-is-inf-and-ind

        -- guard to prevent invalid numbers (#IND) and infinite numbers (#INF) from reaching the engine function
        local stringified = tostring(acceleration)
        if stringified:find('#') then
            error("Invalid acceleration value: " .. stringified)
        end

        return ProjectileMethodsSetBallisticAcceleration(self, acceleration)
    end,

    ---------------------------------------------------------------------------
    --#region Deprecated functionality

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
    ---@param DamageData WeaponDamageTable
    PassDamageData = function(self, DamageData)
        self.DamageData = {}
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
        self.CollideFriendly = DamageData.CollideFriendly
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
---@field Blueprint ProjectileBlueprint
---@field Army Army
DummyProjectile = ClassDummyProjectile(ProjectileMethods) {
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
