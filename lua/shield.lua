------------------------------------------------------------------
--  File     :  /lua/shield.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  : Shield lua module
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

-- Legacy shield flags:
--  - _IsUp: determines whether the shield is up

-- Shield flags:
--  - Enabled: flag that indicates the shield is enabled or not (via the toggle of the user)
--  - Recharged : flag that indicates whether the shield is recharged
--  - DepletedByEnergy: flag that indicates the shield is drained of energy and needs to recharge
--  - DepletedByDamage: flag that indicates the shield sustained too much damage and needs to recharge
--  - NoEnergyToSustain: flag that indicates the shield does not have sufficient energy to recharge
--  - RolledFromFactory: flag that allows us to skip the first attachment check

-- Shield flags for mods:
--  - SkipAttachmentCheck: flag that allows us to skip all attachment checks, as an example when the unit is attached to a transport

-- Shield states:
-- - OnState
-- - OffState
-- - RechargeState
-- - DamageDrainedState
-- - EnergyDrainedState
-- - DeadState

local Entity = import("/lua/sim/entity.lua").Entity
local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")

local DeprecatedWarnings = { }

local VectorCached = Vector(0, 0, 0)

-- cache math and table functions
local MathSqrt = math.sqrt
local MathMin = math.min 

local TableAssimilate = table.assimilate

-- cache globals
local Warp = Warp
local IsEntity = IsEntity
local IsUnit = IsUnit
local IsAlly = IsAlly
local IsEnemy = IsEnemy
local Random = Random
local GetGameTick = GetGameTick
local SuspendCurrentThread = SuspendCurrentThread
local ForkThread = ForkThread
local ResumeThread = ResumeThread
local ChangeState = ChangeState
local ArmyGetHandicap = ArmyGetHandicap
local CoroutineYield = coroutine.yield 
local CreateEmitterAtBone = CreateEmitterAtBone
local _c_CreateShield = _c_CreateShield

-- cache cfunctions
local EntityGetHealth = _G.moho.entity_methods.GetHealth
local EntityGetMaxHealth = _G.moho.entity_methods.GetMaxHealth
local EntitySetHealth = _G.moho.entity_methods.SetHealth 
local EntitySetMaxHealth = _G.moho.entity_methods.SetMaxHealth 
local EntityAdjustHealth = _G.moho.entity_methods.AdjustHealth
local EntityGetArmy = _G.moho.entity_methods.GetArmy 
local EntityGetEntityId = _G.moho.entity_methods.GetEntityId
local EntitySetVizToFocusPlayer = _G.moho.entity_methods.SetVizToFocusPlayer
local EntitySetVizToEnemies = _G.moho.entity_methods.SetVizToEnemies
local EntitySetVizToAllies = _G.moho.entity_methods.SetVizToAllies
local EntitySetVizToNeutrals = _G.moho.entity_methods.SetVizToNeutrals
local EntityAttachBoneTo = _G.moho.entity_methods.AttachBoneTo
local EntityGetPosition = _G.moho.entity_methods.GetPosition 
local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ 
local EntitySetMesh = _G.moho.entity_methods.SetMesh
local EntitySetDrawScale = _G.moho.entity_methods.SetDrawScale
local EntitySetOrientation = _G.moho.entity_methods.SetOrientation
local EntityDestroy = _G.moho.entity_methods.Destroy
local EntityBeenDestroyed = _G.moho.entity_methods.BeenDestroyed
local EntitySetCollisionShape = _G.moho.entity_methods.SetCollisionShape

local EntitySetParentOffset = _G.moho.entity_methods.SetParentOffset

local UnitSetScriptBit = _G.moho.unit_methods.SetScriptBit
local UnitIsUnitState = _G.moho.unit_methods.IsUnitState
local UnitRevertCollisionShape = _G.moho.unit_methods.RevertCollisionShape

local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter 

-- cache trashbag functions 
local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy

-- cache categories computations
local CategoriesOverspill = (categories.SHIELD * categories.DEFENSE) + categories.BUBBLESHIELDSPILLOVERCHECK

-- default values for a shield specification table (to be passed to native code)
local DEFAULT_OPTIONS = {
    Mesh = '',
    MeshZ = '',
    ImpactMesh = '',
    ImpactEffects = '',
    Size = 10,
    ShieldMaxHealth = 250,
    ShieldRechargeTime = 10,
    ShieldEnergyDrainRechargeTime = 10,
    ShieldVerticalOffset = -1,
    ShieldRegenRate = 1,
    ShieldRegenStartTime = 5,
    PassOverkillDamage = false,

    -- flags for mods
    -- SkipAttachmentCheck = false, -- defaults to nil, same as false
}

-- scan blueprints for the largest shield radius
LargestShieldDiameter = 0
for k, bp in __blueprints do 
    -- check for blueprints that have a shield and a shield size set
    if bp.Defense and bp.Defense.Shield and bp.Defense.Shield.ShieldSize then 
        -- skip Aeon palace and UEF shield boat as they skew the results
        if not (bp.BlueprintId == "xac2101" or bp.BlueprintId == "xes0205") then 
            local size = bp.Defense.Shield.ShieldSize
            if size > LargestShieldDiameter then 
                LargestShieldDiameter = size
            end
        end
    end
end

---@class Shield : moho.shield_methods, Entity
---@field Brain AIBrain
Shield = Class(moho.shield_methods, Entity) {
    __init = function(self, spec, owner)
        -- This key deviates in name from the blueprints...
        spec.Size = spec.ShieldSize

        -- Apply default options
        local spec = TableAssimilate(spec, DEFAULT_OPTIONS)
        spec.Owner = owner

        _c_CreateShield(self, spec)
    end,

    ---@param self Shield
    ---@param spec unknown is this Entity?
    OnCreate = function(self, spec)
        -- cache information that is used frequently
        self.Army = EntityGetArmy(self)
        self.EntityId = EntityGetEntityId(self)
        self.Brain = spec.Owner:GetAIBrain()

        -- copy over information from specifiaction
        self.Size = spec.Size 
        self.Owner = spec.Owner
        self.MeshBp = spec.Mesh
        self.MeshZBp = spec.MeshZ
        self.SpillOverDmgMod = spec.ShieldSpillOverDamageMod or 0.15
        self.ShieldRechargeTime = spec.ShieldRechargeTime or 5
        self.ShieldEnergyDrainRechargeTime = spec.ShieldEnergyDrainRechargeTime
        self.ShieldVerticalOffset = spec.ShieldVerticalOffset
        self.RegenRate = spec.ShieldRegenRate
        self.RegenStartTime = spec.ShieldRegenStartTime
        self.PassOverkillDamage = spec.PassOverkillDamage
        self.ImpactMeshBp = spec.ImpactMesh
        self.SkipAttachmentCheck = spec.SkipAttachmentCheck

        if spec.ImpactEffects ~= '' then
            self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
        else
            self.ImpactEffects = {}
        end

        -- set some internal state related to shields
        self._IsUp = false
        self.ShieldType = 'Bubble'

        -- set our health
        EntitySetMaxHealth(self, spec.ShieldMaxHealth)
        EntitySetHealth(self, self, spec.ShieldMaxHealth)

        -- show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        -- tell the engine when we should be visible
        EntitySetVizToFocusPlayer(self, 'Always')
        EntitySetVizToEnemies(self, 'Intel')
        EntitySetVizToAllies(self, 'Always')
        EntitySetVizToNeutrals(self, 'Intel')

        -- attach us to the owner
        EntityAttachBoneTo(self, -1, spec.Owner, -1)

        -- lookup as to whether we're static or a commander shield
        local ownerCategories = self.Owner.Blueprint.CategoriesHash
        if ownerCategories.STRUCTURE then
            self.StaticShield = true
        elseif ownerCategories.COMMAND then
            self.CommandShield = true
        end

        -- use trashbag of the unit that owns us
        self.Trash = self.Owner.Trash

        -- manage impact entities
        self.LiveImpactEntities = 0
        self.ImpactEntitySpecs = { Owner = self.Owner }

        -- manage overlapping shields
        self.OverlappingShields = { }
        self.OverlappingShieldsCount = 0
        self.OverlappingShieldsTick = -1

        -- manage overspill
        self.DamagedTick = { }
        self.DamagedRegular = { }
        self.DamagedOverspill = { }

        -- manage regeneration thread
        self.RegenThreadSuspended = true
        self.RegenThreadState = "On"
        self.RegenThread = ForkThread(self.RegenThread, self)
        TrashAdd(self.Trash, self.RegenThread)

        -- manage the loss of shield when energy is depleted
        self.Brain:AddEnergyDependingEntity(self)

        -- by default, turn on maintenance and the toggle for the owner
        self.Enabled = true
        self.Recharged = true 
        self.RolledFromFactory = false 
        self.Owner:SetMaintenanceConsumptionActive()
        UnitSetScriptBit(self.Owner, 'RULEUTC_ShieldToggle', true)

        -- then check if we can actually turn it on
        if not self.Brain.EnergyDepleted then 
            self:OnEnergyViable()
        else 
            self:OnEnergyDepleted()
        end
    end,

    RegenThread = function(self)

        -- cache globals 
        local GetGameTick = GetGameTick
        local CoroutineYield = CoroutineYield
        local SuspendCurrentThread = SuspendCurrentThread

        -- cache cfunctions
        local EntityGetHealth = EntityGetHealth
        local EntityGetMaxHealth = EntityGetMaxHealth
        local EntityAdjustHealth = EntityAdjustHealth

        while not IsDestroyed(self) do

            -- gather some information
            local fromSuspension = false
            local tick = GetGameTick()
            local health = EntityGetHealth(self)
            local maxHealth = EntityGetMaxHealth(self)

            -- check if we need to suspend ourself
            if 
                -- we're at zero health or lower
                    health <= 0 
                -- we're full health
                or  health == maxHealth
                -- we're not enabled
                or  not self.Enabled 
                -- we're not recharged
                or  not self.Recharged
            then 
                -- adjust shield bar one last time
                self:UpdateShieldRatio(health / maxHealth)

                -- suspend ourselves and wait
                self.RegenThreadSuspended = true 
                SuspendCurrentThread()
                self.RegenThreadSuspended = false
                fromSuspension = true 
            end

            -- if we didn't suspend then check regeneration conditions
            if not fromSuspension then 

                -- check if we're allowed to start regenerating again
                if tick > self.RegenThreadStartTick then 

                    -- adjust health, rate is in seconds 
                    EntityAdjustHealth(self, self.Owner, 0.1 * self.RegenRate)

                -- if not, yield for the difference in ticks
                end

                -- adjust shield bar as we may be assisted
                self:UpdateShieldRatio(health / maxHealth)
            end

            -- wait till next tick
            CoroutineYield(1)
        end
    end,

    ---@param self Shield
    OnEnergyDepleted = function(self)
        self.NoEnergyToSustain = true 

        -- change state if we're enabled
        if self.Enabled then 
            ChangeState(self, self.EnergyDrainedState)
        end
    end,

    ---@param self Shield
    OnEnergyViable = function(self)
        self.NoEnergyToSustain = false 

        -- change state if we're enabled
        if self.Enabled then 
            ChangeState(self, self.OnState)
        end
    end,

    --- Retrieves allied shields that overlap with this shield, caches the results per tick
    -- @param self A shield that we're computing the overlapping shields for
    -- @param tick Optional parameter, represents the game tick. Used to determine if we need to refresh the cash
    GetOverlappingShields = function(self, tick)

        -- allow the game tick to be send to us, saves cycles
        tick = tick or GetGameTick()

        -- see if we need to re-compute the overlapping shields as the information we're requesting is of a different tick
        if tick ~= self.OverlappingShieldsTick then 
            self.OverlappingShieldsTick = tick 

            local brain = self.Brain
            local position = EntityGetPosition(self.Owner)

            -- diameter where other shields overlap with us or are contained by us
            local diameter = LargestShieldDiameter + self.Size

            -- retrieve candidate units
            local units = brain:GetUnitsAroundPoint(CategoriesOverspill, position, 0.5 * diameter, 'Ally')

            if units then 

                -- allocate locals once
                local shieldOther
                local radiusOther
                local distanceToOverlap
                local osx, osy, osz
                local d, dx, dy, dz 
                
                -- compute our information only once
                local psx, psy, psz = EntityGetPositionXYZ(self)
                local radius = 0.5 * self.Size

                local head = 1 
                for k, other in units do 

                    -- store reference to reduce table lookups
                    shieldOther = other.MyShield

                    -- check if it is a different unti and that it has an active shield with a radius
                    -- larger than 0, as engine defaults shield table to 0
                    if      shieldOther 
                        and shieldOther.ShieldType ~= "Personal"
                        and shieldOther:IsUp()
                        and shieldOther.Size
                        and shieldOther.Size > 0 
                        and self.Owner.EntityId ~= other.EntityId 
                    then 

                        -- compute radius of shield
                        radiusOther = 0.5 * shieldOther.Size

                        -- compute total distance to overlap and square it to prevent a square root
                        distanceToOverlap = radius + radiusOther 
                        distanceToOverlap = distanceToOverlap * distanceToOverlap

                        -- retrieve position of other shield
                        osx, osy, osz = EntityGetPositionXYZ(shieldOther)

                        -- compute vector from self to other
                        dx = osx - psx 
                        dy = osy - psy 
                        dz = osz - psz

                        -- compute squared distance and check it
                        d = dx * dx + dy * dy + dz * dz
                        if d < distanceToOverlap then 
                            self.OverlappingShields[head] = shieldOther 
                            head = head + 1
                        end
                    end
                end

                -- keep track of the number of adjacent shields
                self.OverlappingShieldsCount = head - 1
            else 
                -- no units found
                self.OverlappingShieldsCount = 0
            end
        end

        -- return the shields in question
        return self.OverlappingShields, self.OverlappingShieldsCount
    end,

    UpdateShieldRatio = function(self, value)
        if value >= 0 then
            self.Owner:SetShieldRatio(value)
        else
            self.Owner:SetShieldRatio(EntityGetHealth(self) / EntityGetMaxHealth(self))
        end
    end,

    -- Note, this is called by native code to calculate spillover damage. The
    -- damage logic will subtract this value from any damage it does to units
    -- under the shield. The default is to always absorb as much as possible
    -- but the reason this function exists is to allow flexible implementations
    -- like shields that only absorb partial damage (like armor).
    OnGetDamageAbsorption = function(self, instigator, amount, type)
        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (self.Owner:GetArmorMult(type))
        amount = amount * (1.0 - ArmyGetHandicap(self.Army))

        local health = EntityGetHealth(self)
        if health < amount then 
            return health 
        else 
            return amount 
        end
    end,

    GetOverkill = function(self, instigator, amount, type)
        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (self.Owner:GetArmorMult(type))
        amount = amount * (1.0 - ArmyGetHandicap(self.Army))
        local finalVal =  amount - EntityGetHealth(self)
        if finalVal < 0 then
            finalVal = 0
        end
        return finalVal
    end,

    OnDamage = function(self, instigator, amount, vector, damageType)

        -- only applies to trees
        if damageType == "TreeForce" or damageType == "TreeFire" then 
            return 
        end

        -- Only called when a shield is directly impacted, so not for Personal Shields
        -- This means personal shields never have ApplyDamage called with doOverspill as true
        self:ApplyDamage(instigator, amount, vector, damageType, true)
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)

        -- cache information used throughout the function

        local tick = GetGameTick()

        -- damage correction for overcharge
        
        if dmgType == 'Overcharge' then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            if self.StaticShield then -- fixed damage for static shields
                amount = wep:GetBlueprint().Overcharge.structureDamage * 2
                -- Static shields absorbing 50% OC damage somehow, I don't want to change anything anywhere so just *2.
            elseif self.CommandShield then --fixed damage for all ACU shields
                amount = wep:GetBlueprint().Overcharge.commandDamage
            end
        end

        -- damage correction for overspill, do not apply to personal shields

        if self.ShieldType ~= "Personal" then

            local instigatorId = (instigator and instigator.EntityId) or false
            if instigatorId then 

                -- reset our status quo for this instigator
                if self.DamagedTick[instigatorId] ~= tick then 
                    self.DamagedTick[instigatorId] = tick 
                    self.DamagedRegular[instigatorId] = false 
                    self.DamagedOverspill[instigatorId] = 0 
                end

                -- anything but shield spill damage is regular damage, remove any previous overspill damage from the same instigator during the same tick
                if dmgType ~= "ShieldSpill" then 
                    self.DamagedRegular[instigatorId] = tick 
                    amount = amount - self.DamagedOverspill[instigatorId]
                    self.DamagedOverspill[instigatorId] = 0 
                else 
                    -- if we have already received regular damage from this instigator at this tick, skip the overspill damage
                    if self.DamagedRegular[instigatorId] == tick then 
                        return 
                    end

                    -- keep track of overspill damage if we have not received any actual damage yet
                    self.DamagedOverspill[instigatorId] = self.DamagedOverspill[instigatorId] + amount 
                end
            end
        end

        -- do damage logic for shield

        if self.Owner ~= instigator then
            local absorbed = self:OnGetDamageAbsorption(instigator, amount, dmgType)

            -- take some damage
            EntityAdjustHealth(self, instigator, -absorbed)

            -- check to spawn impact effect
            local r = Random(1, self.Size)
            if  dmgType ~= "ShieldSpill"
                and not (       self.LiveImpactEntities > 10
                            and (r >= 0.2 * self.Size and r < self.LiveImpactEntities))
            then 
                ForkThread(self.CreateImpactEffect, self, vector)
            end

            -- if we have no health, collapse
            if EntityGetHealth(self) <= 0 then
                ChangeState(self, self.DamageDrainedState)
            -- otherwise, attempt to regenerate
            else 
                self.RegenThreadStartTick = tick + 10 * self.RegenStartTime
                if self.RegenThreadSuspended then 
                    ResumeThread(self.RegenThread)
                end
            end
        end

        -- overspill damage checks

        if 
            -- prevent recursively applying overspill
            doOverspill 
            -- personal shields do not have overspill damage
            and self.ShieldType ~= "Personal"
            -- we consider damage without an instigator irrelevant, typically force events
            and IsEntity(instigator) 
            -- we consider damage that is 1 or lower irrelevant, typically force events
            and amount > 1 
            -- do not recursively apply overspill damage
            and dmgType ~= "ShieldSpill"
        then 
            local spillAmount = self.SpillOverDmgMod * amount

            -- retrieve shields that overlap with us
            local others, count = self:GetOverlappingShields(tick)

            -- apply overspill damage to neighbour shields
            for k = 1, count do 
                others[k]:ApplyDamage(
                    instigator,         -- instigator
                    spillAmount,        -- amount
                    nil,                -- vector
                    "ShieldSpill",      -- type
                    false               -- do overspill
                )
            end
        end
    end,

    CreateImpactEffect = function(self, vector)

        if IsDestroyed(self) then
            return
        end

        -- keep track of this entity
        self.LiveImpactEntities = self.LiveImpactEntities + 1

        -- cache values
        local effect
        local army = self.Army
        local vc = VectorCached

        -- compute distance to offset effect
        local x = vector[1]
        local y = vector[2]
        local z = vector[3]
        local d = MathSqrt(x * x + y * y + z * z)

        -- allocate an entity
        local entity = Entity( self.ImpactEntitySpecs )

        vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)
        Warp(entity, vc)

        -- set the impact mesh and scale it accordingly
        if self.ImpactMeshBp ~= '' then
            EntitySetMesh(entity, self.ImpactMeshBp)
            EntitySetDrawScale(entity, self.Size)

            vc[1], vc[2], vc[3] = -x, -y, -z
            EntitySetOrientation(entity, OrientFromDir(vc), true)
        end

        -- spawn additional effects
        for _, v in self.ImpactEffects do
            effect = CreateEmitterAtBone(entity, -1, army, v)
            IEffectOffsetEmitter(effect, 0, 0, d)
        end

        -- hold up a bit
        CoroutineYield(20)

        -- take out the entity again
        EntityDestroy(entity)
        
        self.LiveImpactEntities = self.LiveImpactEntities - 1
    end,

    OnDestroy = function(self)
        EntitySetMesh(self, '')
        if self.MeshZ ~= nil then
            EntityDestroy(self.MeshZ)
            self.MeshZ = nil
        end
        self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,

    --- Called when a shield collides with a projectile to check if the collision is valid
    -- @param self The shield we're checking the collision for
    -- @param other The projectile we're checking the collision with
    OnCollisionCheck = function(self, other)

        -- special logic when it is a projectile to simulate air crashes
        if other.CrashingAirplaneShieldCollisionLogic then 
            if other.ShieldImpacted then
                return false
            else
                if other and not EntityBeenDestroyed(other) then
                    other:OnImpact('Shield', self)
                    return false
                end
            end
        end

        -- special behavior for projectiles that always collide with 
        -- shields, like the seraphim storm when the Ythotha dies
        if other.CollideFriendlyShield then
            return true
        end

        if      -- our projectiles do not collide with our shields
                self.Army == other.Army
                -- neutral projectiles do not collide with any shields
            or  other.Army == -1 
        then
            return false
        end

        -- special behavior for projectiles that represent strategic missiles
        local otherHashedCats = other.Blueprint.CategoriesHash
        if otherHashedCats['STRATEGIC'] and otherHashedCats['MISSILE'] then
            return false
        end

        -- otherwise, only collide if we're hostile to the other army
        return IsEnemy(self.Army, other.Army)
    end,

    --- Called when a shield collides with a collision beam to check if the collision is valid
    -- @param self The shield we're checking the collision for
    -- @param firingWeapon The weapon the beam originates from that we're checking the collision with
    OnCollisionCheckWeapon = function(self, firingWeapon)

        -- if we're allied, check if we allow that type of collision
        if self.Army == firingWeapon.Army or IsAlly(self.Army, firingWeapon.Army) then
            return firingWeapon.Blueprint.CollideFriendly
        end

        return true
    end,

    TurnOn = function(self)
        ChangeState(self, self.OnState)
    end,

    TurnOff = function(self)
        ChangeState(self, self.OffState)
    end,

    IsOn = function(self)
        return false
    end,

    IsUp = function(self)
        return (self:IsOn() and self.Enabled)
    end,

    RemoveShield = function(self)
        self._IsUp = false 

        EntitySetCollisionShape(self, 'None')

        EntitySetMesh(self, '')
        if self.MeshZ ~= nil then
            EntityDestroy(self.MeshZ)
            self.MeshZ = nil
        end
    end,

    CreateShieldMesh = function(self)
        EntitySetCollisionShape(self, 'Sphere', 0, 0, 0, self.Size / 2)

        EntitySetMesh(self, self.MeshBp)
        EntitySetParentOffset(self, Vector(0, self.ShieldVerticalOffset, 0))
        EntitySetDrawScale(self, self.Size)

        if self.MeshZ == nil then
            local vc = VectorCached 

            self.MeshZ = Entity (self.ImpactEntitySpecs)
            EntitySetMesh(self.MeshZ, self.MeshZBp)
            EntitySetDrawScale(self.MeshZ, self.Size)

            vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self.Owner)
            Warp(self.MeshZ, vc)
            EntityAttachBoneTo(self.MeshZ, -1, self.Owner, -1)

            vc[1], vc[2], vc[3] = 0, self.ShieldVerticalOffset, 0
            EntitySetParentOffset(self.MeshZ, vc)

            EntitySetVizToFocusPlayer(self.MeshZ, 'Always')
            EntitySetVizToEnemies(self.MeshZ, 'Intel')
            EntitySetVizToAllies(self.MeshZ, 'Always')
            EntitySetVizToNeutrals(self.MeshZ, 'Intel')
        end

        self._IsUp = true
    end,

    -- Basically run a timer, but with visual bar movement
    ChargingUp = function(self, curProgress, time)

        local max = 1
        if not self.DepletedByDamage then 
            max = EntityGetHealth(self) / EntityGetMaxHealth(self)
        end

        while curProgress < time do
            CoroutineYield(1)

            curProgress = curProgress + 0.1
            local workProgress = curProgress / time
            self:UpdateShieldRatio(workProgress * max)
        end

        self:UpdateShieldRatio(1)
    end,

    OnState = State {
        Main = function(self)

            -- always start consuming energy at this point
            self.Enabled = true 
            self.Owner:SetMaintenanceConsumptionActive()

            -- if we're attached to a transport then our shield should be off
            if (not self.SkipAttachmentCheck) and (UnitIsUnitState(self.Owner, 'Attached') and self.RolledFromFactory) then
                ChangeState(self, self.OffState)

            -- if we're still out of energy, go wait for that to fix itself
            elseif self.NoEnergyToSustain then 
                ChangeState(self, self.EnergyDrainedState)

            -- if we are depleted for some reason, go fix that first
            elseif self.DepletedByEnergy or self.DepletedByDamage or not self.Recharged then 
                ChangeState(self, self.RechargeState)

            -- we're all good, go shield things
            else 

                -- unsuspend the regeneration thread
                if self.RegenThreadSuspended then 
                    ResumeThread(self.RegenThread)
                end

                -- introduce the shield bar
                self:UpdateShieldRatio(-1)
                self:CreateShieldMesh()

                -- inform owner that the shield is enabled
                self.Owner:OnShieldEnabled()
                self.Owner:PlayUnitSound('ShieldOn')
            end

            -- mobile shields are 'attached' to the factory when they are build, this allows
            -- us to skip the first check of whether we're attached to a transport
            self.RolledFromFactory = true 
        end,

        IsOn = function(self)
            return true
        end,
    },

    -- When manually turned off
    OffState = State {

        Main = function(self)

            -- update internal state
            self.Enabled = false 
            self.Recharged = false 
            self.Owner:SetMaintenanceConsumptionInactive()

            -- remove the shield and the shield bar
            self:RemoveShield()
            self:UpdateShieldRatio(0)

            -- inform the owner that the shield is disabled
            self.Owner:OnShieldDisabled()
            self.Owner:PlayUnitSound('ShieldOff')
        end,

        IsOn = function(self)
            return false
        end,
    },

    RechargeState = State {
        Main = function(self)

            -- determine recharge time
            local rechargeTime = self.ShieldEnergyDrainRechargeTime           
            if self.DepletedByDamage and self.ShieldRechargeTime > rechargeTime then 
                rechargeTime = self.ShieldRechargeTime
            end

            -- wait until we're done charging up
            self:ChargingUp(0, rechargeTime)

            -- determine health 
            local health = EntityGetHealth(self)
            if self.DepletedByDamage then 
                health = EntityGetMaxHealth(self)
            end

            -- fully charged, reset our helpt
            EntitySetHealth(self, self, health)

            -- update internal state
            self.DepletedByDamage = false
            self.DepletedByEnergy = false 
            self.Recharged = true 
            self.RegenThreadStartTick = GetGameTick() + 10 * self.RegenStartTime

            -- back to the regular onstate
            ChangeState(self, self.OnState)
        end,

        IsOn = function(self)
            return false
        end,
    },

    DamageDrainedState = State {
        Main = function(self)

            -- update internal state
            self.DepletedByDamage = true 
            self.Recharged = false 

            -- remove the shield
            self:RemoveShield()
            self:UpdateShieldRatio(0)

            -- interact with the owner
            self.Owner:OnShieldDisabled()
            self.Owner:PlayUnitSound('ShieldOff')

            -- start recharging right away
            ChangeState(self, self.RechargeState)
        end,

        IsOn = function(self)
            return false
        end,
    },

    EnergyDrainedState = State {
        Main = function(self)

            -- update internal state
            self.DepletedByEnergy = true 
            self.Recharged = false 

            -- remove the shield
            self:RemoveShield()
            self:UpdateShieldRatio(0)

            -- interact with the owner
            self.Owner:OnShieldDisabled()
            self.Owner:PlayUnitSound('ShieldOff')

            -- do not start recharging, wait until we have some power in storage. We're
            -- informed through the OnEnergyViable callback
            -- ChangeState(self, self.RechargeState)
        end,

        IsOn = function(self)
            return false
        end,
    },

    DeadState = State {
        Main = function(self) 
        end,

        IsOn = function(self)
            return false
        end,
    },

    --- Deprecated functionality

    DamageRechargeState = State {

        Main = function(self)

            -- if not DeprecatedWarnings.DamageRechargeState then 
            --     DeprecatedWarnings.DamageRechargeState = true 
            --     SPEW("DamageRechargeState is deprecated: use shield.RechargeState instead.")
            --     SPEW("Unit type of owner: " .. self.Owner.UnitId)
            --     SPEW("Stacktrace: " .. repr(debug.traceback()))
            -- end

            -- back to the regular onstate
            ChangeState(self, self.RechargeState)
        end,
    },

    GetCachePosition = function(self)

        -- if not DeprecatedWarnings.GetCachePosition then 
        --     DeprecatedWarnings.GetCachePosition = true 
        --     SPEW("GetCachePosition is deprecated: use shield:GetPosition() or shield:GetPositionXYZ() instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        return self:GetPosition()
    end,

    SetRechargeTime = function(self, rechargeTime, energyRechargeTime)

        -- if not DeprecatedWarnings.SetRechargeTime then 
        --     DeprecatedWarnings.SetRechargeTime = true 
        --     SPEW("SetRechargeTime is deprecated: set the values shield.ShieldRechargeTime and shield.ShieldEnergyDrainRechargeTime instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.ShieldRechargeTime = rechargeTime
        self.ShieldEnergyDrainRechargeTime = energyRechargeTime
    end,

    SetVerticalOffset = function(self, offset)

        -- if not DeprecatedWarnings.SetVerticalOffset then 
        --     DeprecatedWarnings.SetVerticalOffset = true 
        --     SPEW("SetVerticalOffset is deprecated: set the value shield.ShieldVerticalOffset instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.ShieldVerticalOffset = offset
    end,

    SetSize = function(self, size)

        -- if not DeprecatedWarnings.SetSize then 
        --     DeprecatedWarnings.SetSize = true 
        --     SPEW("SetSize is deprecated: set the value shield.Size instead.")
        --     SPEW("Source: " .. repr(debug.traceback()))
        -- end

        self.Size = size
    end,

    SetShieldRegenRate = function(self, rate)

        -- if not DeprecatedWarnings.SetShieldRegenRate then 
        --     DeprecatedWarnings.SetShieldRegenRate = true 
        --     SPEW("SetShieldRegenRate is deprecated: set the value shield.RegenRate instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.RegenRate = rate
    end,

    SetShieldRegenStartTime = function(self, time)

        -- if not DeprecatedWarnings.SetShieldRegenStartTime then 
        --     DeprecatedWarnings.SetShieldRegenStartTime = true 
        --     SPEW("SetShieldRegenStartTime is deprecated: set the value shield.RegenStartTime instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.RegenStartTime = time
    end,

    SetType = function(self, type)

        -- if not DeprecatedWarnings.ShieldType then 
        --     DeprecatedWarnings.ShieldType = true 
        --     SPEW("ShieldType is deprecated: set the value shield.ShieldType instead.")
        --     SPEW("Stacktrace: " .. repr(debug.traceback()))
        -- end

        self.ShieldType = type
    end,
}

--- A bubble shield attached to a single unit.
---@class PersonalBubble : Shield
PersonalBubble = Class(Shield) {
    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)

        -- Store off useful values from the blueprint
        local OwnerBp = self.Owner.Blueprint or self.Owner:GetBlueprint()

        self.SizeX = OwnerBp.SizeX
        self.SizeY = OwnerBp.SizeY
        self.SizeZ = OwnerBp.SizeZ

        self.ShieldSize = spec.ShieldSize

        self.ShieldType = 'Personal'

        -- Manually disable the bubble shield's collision sphere after its creation so it acts like the new personal shields
        EntitySetCollisionShape(self, 'None')
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- We want all personal shields to pass overkill damage, including this one
        -- Was handled by self.PassOverkillDamage bp value, now defunct
        if self.Owner ~= instigator then
            local overkill = self:GetOverkill(instigator, amount, dmgType)
            if overkill > 0 and self.Owner and IsUnit(self.Owner)  then
                self.Owner:DoTakeDamage(instigator, overkill, vector, dmgType)
            end
        end

        Shield.ApplyDamage(self, instigator, amount, vector, dmgType, doOverspill)
    end,

    CreateShieldMesh = function(self)
        Shield.CreateShieldMesh(self)
        EntitySetCollisionShape(self, 'None')
    end,

    RemoveShield = function(self)
        Shield.RemoveShield(self)
        EntitySetCollisionShape(self, 'None')
    end,

    OnState = State(Shield.OnState) {
        Main = function(self)
            -- Set the collision profile of the unit to match the apparent shield sphere.
            -- Since the collision handler in Unit deals with personal shields, the damage will be
            -- passed to the shield.
            EntitySetCollisionShape(self.Owner, 'Sphere', 0, self.SizeY * 0.5, 0, self.ShieldSize * 0.5)
            Shield.OnState.Main(self)
        end
    },

    OffState = State(Shield.OffState) {
        Main = function(self)
            -- When the shield is down for some reason, reset the unit's collision profile so it can
            -- again be hit.
            UnitRevertCollisionShape(self.Owner)
            Shield.OffState.Main(self)
        end
    },

    RechargeState = State(Shield.RechargeState) {
        Main = function(self)
            UnitRevertCollisionShape(self.Owner)
            Shield.RechargeState.Main(self)
         end
    },
}

--- A personal bubble that can render a set of encompassed units invincible.
-- Useful for shielded transports (to work around the area-damage bug).
---@class TransportShield : Shield
TransportShield = Class(Shield) {

    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self.protectedUnits = {}
    end,

    -- toggle vulnerability of the transport and its content
    SetContentsVulnerable = function(self, canTakeDamage)
        for k, v in self.protectedUnits do
            k.CanTakeDamage = canTakeDamage
        end
    end,

    -- we try and forget this unit
    RemoveProtectedUnit = function(self, unit)
        self.protectedUnits[unit] = nil
        unit.CanTakeDamage = true
    end,

    -- we try and protect this unit
    AddProtectedUnit = function(self, unit)
        self.protectedUnits[unit] = true
    end,

    OnState = State(Shield.OnState) {
        Main = function(self)
            Shield.OnState.Main(self)

            -- prevent ourself and our content from taking damage
            self:SetContentsVulnerable(false)
            self.Owner.CanTakeDamage = false 
        end,

        AddProtectedUnit = function(self, unit)
            self.protectedUnits[unit] = true
            unit.CanTakeDamage = false
        end
    },

    OffState = State(Shield.OffState) {
        Main = function(self)
            Shield.OffState.Main(self)

            -- allow ourself and our content to take damage
            self:SetContentsVulnerable(true)
            self.Owner.CanTakeDamage = true 
        end,
    },

    DamageDrainedState = State(Shield.DamageDrainedState) {
        Main = function(self)
            Shield.DamageDrainedState.Main(self)

            -- allow ourself and our content to take damage
            self:SetContentsVulnerable(true)
            self.Owner.CanTakeDamage = true 
        end
    },

    EnergyDrainedState = State(Shield.EnergyDrainedState) {
        Main = function(self)
            Shield.EnergyDrainedState.Main(self)

            -- allow ourself and our content to take damage
            self:SetContentsVulnerable(true)
            self.Owner.CanTakeDamage = true 
        end
    },
}

--- A shield that sticks to the surface of the unit. Doesn't have its own collision physics, just
-- grants extra health.
---@class PersonalShield : Shield
PersonalShield = Class(Shield){
    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)

        -- store information from spec
        self.CollisionSizeX = spec.CollisionSizeX or 1
        self.CollisionSizeY = spec.CollisionSizeY or 1
        self.CollisionSizeZ = spec.CollisionSizeZ or 1
        self.CollisionCenterX = spec.CollisionCenterX or 0
        self.CollisionCenterY = spec.CollisionCenterY or 0
        self.CollisionCenterZ = spec.CollisionCenterZ or 0
        self.OwnerShieldMesh = spec.OwnerShieldMesh or ''

        -- set our shield type
        self.ShieldType = 'Personal'

        -- cache our shield effect entity
        self.ShieldEffectEntity = Entity( self.ImpactEntitySpecs )
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- We want all personal shields to pass overkill damage
        -- Was handled by self.PassOverkillDamage bp value, now defunct
        if self.Owner ~= instigator then
            local overkill = self:GetOverkill(instigator, amount, dmgType)
            if overkill > 0 and self.Owner and IsUnit(self.Owner) then
                self.Owner:DoTakeDamage(instigator, overkill, vector, dmgType)
            end
        end

        Shield.ApplyDamage(self, instigator, amount, vector, dmgType, doOverspill)
    end,

    CreateImpactEffect = function(self, vector)

        if IsDestroyed(self) then
            return
        end

        -- keep track of this entity
        self.LiveImpactEntities = self.LiveImpactEntities + 1

        -- cache values
        local effect
        local army = self.Army
        local vc = VectorCached

        -- compute length of vector that points at the point of impact
        local x = vector[1]
        local y = vector[2]
        local z = vector[3]
        local d = MathSqrt(x * x + y * y + z * z)

        -- re-use previous entity as we have no mesh
        local entity = self.ShieldEffectEntity

        -- warp the entity
        vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)
        Warp(entity, vc)
        
        -- orientate it to orientate the effect
        vc[1], vc[2], vc[3] = -x, -y, -z
        EntitySetOrientation(entity, OrientFromDir(vc), true)

        -- create the effect
        for k, v in self.ImpactEffects do
            effect = CreateEmitterAtBone(entity, -1, army, v)
            IEffectOffsetEmitter(effect, 0, 0, d)
        end

        -- hold a bit to lower the number of allowed effects
        CoroutineYield(20)

        self.LiveImpactEntities = self.LiveImpactEntities - 1
    end,

    CreateShieldMesh = function(self)
        -- Personal shields (unit shields) don't handle collisions anymore.
        -- This is done in the Unit's OnDamage function instead.
        EntitySetCollisionShape(self, 'None')
        EntitySetMesh(self.Owner, self.OwnerShieldMesh, true)
    end,

    RemoveShield = function(self)
        EntitySetCollisionShape(self, 'None')
        EntitySetMesh(self.Owner, self.Owner.Blueprint.Display.MeshBlueprint, true)
    end,

    OnDestroy = function(self)
        if not self.Owner.MyShield or self.Owner.MyShield.EntityId == self.EntityId then
            EntitySetMesh(self.Owner, self.Owner.Blueprint.Display.MeshBlueprint, true)
        end
        self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,
}

---@class AntiArtilleryShield : Shield
AntiArtilleryShield = Class(Shield) {
    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self.ShieldType = 'AntiArtillery'
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        local bp = firingWeapon:GetBlueprint()
        if bp.CollideFriendly == false then
            if self.Army == firingWeapon.unit.Army then
                return false
            end
        end
        -- Check DNC list
        if bp.DoNotCollideList then
            for k, v in pairs(bp.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end
        if bp.ArtilleryShieldBlocks then
            return true
        end
        return false
    end,

    -- Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self, other)
        if other.Army == -1 then
            return false
        end

        if other:GetBlueprint().Physics.CollideFriendlyShield and other.DamageData.ArtilleryShieldBlocks then
            return true
        end

        if other.DamageData.ArtilleryShieldBlocks and IsEnemy(self.Army, other.Army) then
            return true
        end

        return false
    end,
}

-- Pretty much the same as personal shield (no collisions), but has its own mesh and special effects.
---@class CzarShield : PersonalShield
CzarShield = Class(PersonalShield) {
    OnCreate = function(self, spec)
        PersonalShield.OnCreate(self, spec)

        self.ImpactMeshBp = spec.ImpactMesh
        self.ImpactMeshBigBp = spec.ImpactMeshBig
    end,


    CreateImpactEffect = function(self, vector)

        if IsDestroyed(self) then
            return
        end

        self.LiveImpactEntities = self.LiveImpactEntities + 1

        local army = self:GetArmy()
        local OffsetLength = Util.GetVectorLength(vector)
        local ImpactMesh = Entity ( self.ImpactEntitySpecs )
        local pos = self:GetPosition()

        -- Shield has non-standard form (ellipsoid) and no collision, so we need some magic to make impacts look good
        -- All impacts from above and below (>1 & <1) cause big pulses in the center of shield
        -- Projectiles that come from same elevation (ASF etc.) cause small pulses on the edge of shield using
        -- standard effect from static shields
        if vector.y > 1 then
            Warp(ImpactMesh, {pos[1], pos[2] + 9.5, pos[3]})

            ImpactMesh:SetMesh(self.ImpactMeshBigBp)
            ImpactMesh:SetDrawScale(self.Size)
            ImpactMesh:SetOrientation(OrientFromDir(Vector(0, -30, 0)), true)
        elseif vector.y < -1 then
            Warp(ImpactMesh, {pos[1], pos[2] - 9.5, pos[3]})

            ImpactMesh:SetMesh(self.ImpactMeshBigBp)
            ImpactMesh:SetDrawScale(self.Size)
            ImpactMesh:SetOrientation(OrientFromDir(Vector(0, 30, 0)), true)
        else
            Warp(ImpactMesh, {pos[1], pos[2], pos[3]})

            ImpactMesh:SetMesh(self.ImpactMeshBp)
            ImpactMesh:SetDrawScale(self.Size)
            ImpactMesh:SetOrientation(OrientFromDir(Vector(-vector.x, -vector.y, -vector.z)), true)
        end

        for _, v in self.ImpactEffects do
            CreateEmitterAtBone(ImpactMesh, -1, army, v):OffsetEmitter(0, 0, OffsetLength)
        end

        WaitSeconds(5)
        ImpactMesh:Destroy()
        self.LiveImpactEntities = self.LiveImpactEntities - 1
    end,

    CreateShieldMesh = function(self)
        -- Personal shields (unit shields) don't handle collisions anymore.
        -- This is done in the Unit's OnDamage function instead.
        self:SetCollisionShape('None')

        self:SetMesh(self.MeshBp)
        self:SetParentOffset(Vector(0, self.ShieldVerticalOffset, 0))
        self:SetDrawScale(self.Size)
    end,

    OnDestroy = function(self)
        Shield.OnDestroy(self)
    end,

    RemoveShield = function(self)
        Shield.RemoveShield(self)
        self:SetCollisionShape('None')
    end,
}

-- kept for mod backwards compatibility
UnitShield = PersonalShield