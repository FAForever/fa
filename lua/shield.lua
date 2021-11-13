------------------------------------------------------------------
--  File     :  /lua/shield.lua
--  Author(s):  John Comes, Gordon Duclos
--  Summary  : Shield lua module
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local shield_methodsSetMesh = moho.shield_methods.SetMesh
local aibrain_methodsGetEconomyStored = moho.aibrain_methods.GetEconomyStored
local unit_methodsIsUnitState = moho.unit_methods.IsUnitState
local unit_methodsGetBuildRate = moho.unit_methods.GetBuildRate
local unit_methodsGetShieldRatio = moho.unit_methods.GetShieldRatio
local IsEnemy = IsEnemy
local shield_methodsSetVizToAllies = moho.shield_methods.SetVizToAllies
local shield_methodsGetEntityId = moho.shield_methods.GetEntityId
local _c_CreateShield = _c_CreateShield
local shield_methodsGetHealth = moho.shield_methods.GetHealth
local ipairs = ipairs
local unit_methodsGetGuards = moho.unit_methods.GetGuards
local tableInsert = table.insert
local CreateEmitterAtBone = CreateEmitterAtBone
local shield_methodsGetArmy = moho.shield_methods.GetArmy
local ArmyGetHandicap = ArmyGetHandicap
local shield_methodsSetVizToEnemies = moho.shield_methods.SetVizToEnemies
local mathMin = math.min
local EntityCategoryContains = EntityCategoryContains
local IsUnit = IsUnit
local shield_methodsGetPosition = moho.shield_methods.GetPosition
local unit_methodsGetArmorMult = moho.unit_methods.GetArmorMult
local IsEntity = IsEntity
local shield_methodsSetDrawScale = moho.shield_methods.SetDrawScale
local unit_methodsRevertCollisionShape = moho.unit_methods.RevertCollisionShape
local shield_methodsSetHealth = moho.shield_methods.SetHealth
local ForkThread = ForkThread
local OrientFromDir = OrientFromDir
local shield_methodsAdjustHealth = moho.shield_methods.AdjustHealth
local next = next
local ParseEntityCategory = ParseEntityCategory
local KillThread = KillThread
local pairs = pairs
local unit_methodsGetResourceConsumed = moho.unit_methods.GetResourceConsumed
local mathMax = math.max
local unit_methodsGetFocusUnit = moho.unit_methods.GetFocusUnit
local tableAssimilate = table.assimilate
local shield_methodsAttachBoneTo = moho.shield_methods.AttachBoneTo
local shield_methodsSetMaxHealth = moho.shield_methods.SetMaxHealth
local shield_methodsSetVizToNeutrals = moho.shield_methods.SetVizToNeutrals
local unit_methodsSetShieldRatio = moho.unit_methods.SetShieldRatio
local shield_methodsGetMaxHealth = moho.shield_methods.GetMaxHealth
local Warp = Warp
local Vector = Vector
local shield_methodsSetCollisionShape = moho.shield_methods.SetCollisionShape
local shield_methodsSetParentOffset = moho.shield_methods.SetParentOffset
local shield_methodsSetVizToFocusPlayer = moho.shield_methods.SetVizToFocusPlayer

local Entity = import('/lua/sim/Entity.lua').Entity
local Overspill = import('/lua/overspill.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('utilities.lua')

-- Default values for a shield specification table (to be passed to native code)
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
}

Shield = Class(moho.shield_methods, Entity) {
    __init = function(self, spec, owner)
        -- This key deviates in name from the blueprints...
        spec.Size = spec.ShieldSize

        -- Apply default options
        local spec = tableAssimilate(spec, DEFAULT_OPTIONS)
        spec.Owner = owner

        _c_CreateShield(self, spec)
    end,

    OnCreate = function(self, spec)
        self.Trash = TrashBag()
        self.Owner = spec.Owner
        self.MeshBp = spec.Mesh
        self.MeshZBp = spec.MeshZ
        self.ImpactMeshBp = spec.ImpactMesh
        self.Army = shield_methodsGetArmy(self)
        self.EntityId = shield_methodsGetEntityId(self)
        self._IsUp = false
        if spec.ImpactEffects ~= '' then
            self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
        else
            self.ImpactEffects = {}
        end

        self:SetSize(spec.Size)
        shield_methodsSetMaxHealth(self, spec.ShieldMaxHealth)
        shield_methodsSetHealth(self, self, spec.ShieldMaxHealth)
        self:SetType('Bubble')
        self.SpillOverDmgMod = mathMax(spec.ShieldSpillOverDamageMod or 0.15, 0)

        -- Show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        self:SetRechargeTime(spec.ShieldRechargeTime or 5, spec.ShieldEnergyDrainRechargeTime or 5)
        self:SetVerticalOffset(spec.ShieldVerticalOffset)

        shield_methodsSetVizToFocusPlayer(self, 'Always')
        shield_methodsSetVizToEnemies(self, 'Intel')
        shield_methodsSetVizToAllies(self, 'Always')
        shield_methodsSetVizToNeutrals(self, 'Intel')

        shield_methodsAttachBoneTo(self, -1, spec.Owner, -1)

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

        self.OffHealth = -1

        self.PassOverkillDamage = spec.PassOverkillDamage

        local ownerCategories = self.Owner:GetBlueprint().CategoriesHash
        if ownerCategories.STRUCTURE then
            self.StaticShield = true
        elseif ownerCategories.COMMAND then
            self.CommandShield = true
        end

        ChangeState(self, self.OnState)
    end,

    SetRechargeTime = function(self, rechargeTime, energyRechargeTime)
        self.ShieldRechargeTime = rechargeTime
        self.ShieldEnergyDrainRechargeTime = energyRechargeTime
    end,

    SetVerticalOffset = function(self, offset)
        self.ShieldVerticalOffset = offset
    end,

    SetSize = function(self, size)
        self.Size = size
    end,

    SetShieldRegenRate = function(self, rate)
        self.RegenRate = rate
    end,

    SetShieldRegenStartTime = function(self, time)
        self.RegenStartTime = time
    end,

    SetType = function(self, type)
        self.ShieldType = type
    end,

    UpdateShieldRatio = function(self, value)
        if value >= 0 then
            unit_methodsSetShieldRatio(self.Owner, value)
        else
            unit_methodsSetShieldRatio(self.Owner, shield_methodsGetHealth(self) / shield_methodsGetMaxHealth(self))
        end
    end,

    GetCachePosition = function(self)
        return shield_methodsGetPosition(self)
    end,

    -- Note, this is called by native code to calculate spillover damage. The
    -- damage logic will subtract this value from any damage it does to units
    -- under the shield. The default is to always absorb as much as possible
    -- but the reason this function exists is to allow flexible implementations
    -- like shields that only absorb partial damage (like armor).
    OnGetDamageAbsorption = function(self, instigator, amount, type)
        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (unit_methodsGetArmorMult(self.Owner, type))
        amount = amount * (1.0 - ArmyGetHandicap(shield_methodsGetArmy(self)))
        return mathMin(shield_methodsGetHealth(self), amount)
    end,

    OnCollisionCheckWeapon = function(self, firingWeapon)
        local weaponBP = firingWeapon:GetBlueprint()
        local collide = weaponBP.CollideFriendly
        if collide == false then
            if not (IsEnemy(self.Army, firingWeapon.unit.Army)) then
                return false
            end
        end
        -- Check DNC list
        if weaponBP.DoNotCollideList then
            for _, v in pairs(weaponBP.DoNotCollideList) do
                if EntityCategoryContains(ParseEntityCategory(v), self) then
                    return false
                end
            end
        end

        return true
    end,

    GetOverkill = function(self, instigator, amount, type)
        -- Like armor damage, first multiply by armor reduction, then apply handicap
        -- See SimDamage.cpp (DealDamage function) for how this should work
        amount = amount * (unit_methodsGetArmorMult(self.Owner, type))
        amount = amount * (1.0 - ArmyGetHandicap(shield_methodsGetArmy(self)))
        local finalVal =  amount - shield_methodsGetHealth(self)
        if finalVal < 0 then
            finalVal = 0
        end
        return finalVal
    end,

    OnDamage = function(self, instigator, amount, vector, dmgType)
        -- Only called when a shield is directly impacted, so not for Personal Shields
        -- This means personal shields never have ApplyDamage called with doOverspill as true
        self:ApplyDamage(instigator, amount, vector, dmgType, true)
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- check for UnitId, so we only check the ACU Overcharge damage and not shield overspill damage
        -- when UnitId is false and EntityId is true, then we got overspill from a shield that was impacted
        -- by the splat damage of an ACU overcharge weapon.
        if dmgType == 'Overcharge' and instigator.UnitId then
            local wep = instigator:GetWeaponByLabel('OverCharge')
            if self.StaticShield then -- fixed damage for static shields
                amount = wep:GetBlueprint().Overcharge.structureDamage * 2
                -- Static shields absorbing 50% OC damage somehow, I don't want to change anything anywhere so just *2.
            elseif self.CommandShield then --fixed damage for all ACU shields
                amount = wep:GetBlueprint().Overcharge.commandDamage
            end
        end
        if self.Owner ~= instigator then
            local absorbed = self:OnGetDamageAbsorption(instigator, amount, dmgType)

            shield_methodsAdjustHealth(self, instigator, -absorbed)
            self:UpdateShieldRatio(-1)
            ForkThread(self.CreateImpactEffect, self, vector)
            if self.RegenThread then
                KillThread(self.RegenThread)
                self.RegenThread = nil
            end
            if shield_methodsGetHealth(self) <= 0 then
                ChangeState(self, self.DamageRechargeState)
            elseif self.OffHealth < 0 then
                if self.RegenRate > 0 then
                    self.RegenThread = ForkThread(self.RegenStartThread, self)
                    self.Owner.Trash:Add(self.RegenThread)
                end
            else
                self:UpdateShieldRatio(0)
            end
        end

        -- Only do overspill on events where we have an instigator.
        -- "Force" damage events from stratbombs are one example
        -- where we don't.
        if doOverspill and IsEntity(instigator) then
            Overspill.DoOverspill(self, instigator, amount, dmgType, self.SpillOverDmgMod)
        end
    end,

    RegenStartThread = function(self)
        --ActiveConsumption means shield is upgrading. Upgrade has highest priority than regen and engies always assist it first
        --no need to launch validation thread in this case
        if self.StaticShield and not self.AssistersThread and not self.Owner.ActiveConsumption then
            self.AssistersThread = ForkThread(self.ValidateAssistersThread, self)
            self.Owner.Trash:Add(self.AssistersThread)
        end

        WaitSeconds(self.RegenStartTime)
        while shield_methodsGetHealth(self) < shield_methodsGetMaxHealth(self) do

            shield_methodsAdjustHealth(self, self.Owner, self.RegenRate / 10)

            self:UpdateShieldRatio(-1)

            WaitTicks(1)
        end
        self.RegenThread = nil
    end,

    --Fix "free" shield regen. Assist efficiency never drops, no matter what mass income you have
    --We have to compensate it in this thread.
    ValidateAssistersThread = function(self)
        local shieldBP = self.Owner:GetBlueprint().Defense.Shield
        local RegenPerBR = shieldBP.ShieldRegenRate / shieldBP.RegenAssistMult / 10 --amount of hp per 1 buildrate (for 1 tick). Weird formula

        local previousTickTotalBR
        local previousTickAssisters

        while self.RegenThread and not self.Owner.ActiveConsumption or self.OnStateCharging and shield_methodsGetHealth(self) ~= shieldBP.ShieldMaxHealth do
            if previousTickAssisters then
                local realBuildRate = 0

                for key, unit in previousTickAssisters do
                    -- ActiveConsumption means unit is not on pause. Without this, rapid pausing/unpausing engies causes hp drops
                    if not unit.Dead and unit.ActiveConsumption then
                        realBuildRate = realBuildRate + (unit_methodsGetResourceConsumed(unit) * unit.AssistBuildRate)
                    else
                        realBuildRate = realBuildRate + unit.AssistBuildRate
                    end
                end

                if realBuildRate ~= previousTickTotalBR then
                    local health = (previousTickTotalBR - realBuildRate) * RegenPerBR --calculate "free" hp that should be subtracted

                    shield_methodsAdjustHealth(self, self.Owner, -health)
                end

                previousTickAssisters = nil
                previousTickTotalBR = nil
            end

            local assisters = unit_methodsGetGuards(self.Owner)

            if assisters[1] then
                local engineers = {}
                local totalBR = 0

                for key, unit in assisters do
                    --only engies can have shield as FocusUnit, also checking for pause
                    if unit_methodsGetFocusUnit(unit) == self.Owner and unit.ActiveConsumption then
                        unit.AssistBuildRate = unit_methodsGetBuildRate(unit)
                        totalBR = totalBR + unit.AssistBuildRate

                        tableInsert(engineers, unit)
                    end
                end

                if engineers[1] then
                    previousTickAssisters = engineers
                    previousTickTotalBR = totalBR
                end
            end

            WaitTicks(1)
        end

        self.AssistersThread = nil
    end,

    CreateImpactEffect = function(self, vector)
        if not self or self.Owner.Dead then return end
        local OffsetLength = Util.GetVectorLength(vector)
        local ImpactMesh = Entity {Owner = self.Owner}
        Warp(ImpactMesh, shield_methodsGetPosition(self))

        if self.ImpactMeshBp ~= '' then
            ImpactMesh:SetMesh(self.ImpactMeshBp)
            ImpactMesh:SetDrawScale(self.Size)
            ImpactMesh:SetOrientation(OrientFromDir(Vector(-vector.x, -vector.y, -vector.z)), true)
        end

        for _, v in self.ImpactEffects do
            CreateEmitterAtBone(ImpactMesh, -1, self.Army, v):OffsetEmitter(0, 0, OffsetLength)
        end

        WaitSeconds(5)
        ImpactMesh:Destroy()
    end,

    OnDestroy = function(self)
        shield_methodsSetMesh(self, '')
        if self.MeshZ ~= nil then
            self.MeshZ:Destroy()
            self.MeshZ = nil
        end
        self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,

    -- Return true to process this collision, false to ignore it.
    OnCollisionCheck = function(self, other)
        if other.Army == -1 then
            return false
        end

        if EntityCategoryContains(categories.SHIELDCOLLIDE, other) then
            if other.ShieldImpacted then
                return false
            else
                if other and not other:BeenDestroyed() then
                    other:OnImpact('Shield', self)
                    return false
                end
            end
        end

        -- Allow strategic nuke missile to penetrate shields
        if EntityCategoryContains(categories.STRATEGIC, other) and
            EntityCategoryContains(categories.MISSILE, other) then
            return false
        end

        if other:GetBlueprint().Physics.CollideFriendlyShield then
            return true
        end

        return IsEnemy(self.Army, other.Army)
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
        return (self:IsOn() and self._IsUp)
    end,

    RemoveShield = function(self)
        self._IsUp = false

        shield_methodsSetCollisionShape(self, 'None')

        shield_methodsSetMesh(self, '')
        if self.MeshZ ~= nil then
            self.MeshZ:Destroy()
            self.MeshZ = nil
        end
    end,

    CreateShieldMesh = function(self)
        shield_methodsSetCollisionShape(self, 'Sphere', 0, 0, 0, self.Size / 2)

        shield_methodsSetMesh(self, self.MeshBp)
        shield_methodsSetParentOffset(self, Vector(0, self.ShieldVerticalOffset, 0))
        shield_methodsSetDrawScale(self, self.Size)

        if self.MeshZ == nil then
            self.MeshZ = Entity {Owner = self.Owner}
            self.MeshZ:SetMesh(self.MeshZBp)
            Warp(self.MeshZ, self.Owner:GetPosition())
            self.MeshZ:SetDrawScale(self.Size)
            self.MeshZ:AttachBoneTo(-1, self.Owner, -1)
            self.MeshZ:SetParentOffset(Vector(0, self.ShieldVerticalOffset, 0))

            self.MeshZ:SetVizToFocusPlayer('Always')
            self.MeshZ:SetVizToEnemies('Intel')
            self.MeshZ:SetVizToAllies('Always')
            self.MeshZ:SetVizToNeutrals('Intel')
        end

        self._IsUp = true
    end,

    -- Basically run a timer, but with visual bar movement
    ChargingUp = function(self, curProgress, time)
        self.Charging = true
        while curProgress < time do
            local fraction = unit_methodsGetResourceConsumed(self.Owner)
            curProgress = curProgress + (fraction / 10)
            curProgress = mathMin(curProgress, time)

            local workProgress = curProgress / time

            self:UpdateShieldRatio(workProgress)
            WaitTicks(1)
        end
        self.Charging = nil
    end,

    OnState = State {
        Main = function(self)
            if self.DamageRecharge then
                self.Owner:SetMaintenanceConsumptionActive()
                self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)
                ChangeState(self, self.DamageRechargeState)

            -- If the shield was turned off; use the recharge time before turning back on
            elseif self.OffHealth >= 0 then
                self.Owner:SetMaintenanceConsumptionActive()
                self.OnStateCharging = true

                -- In this particular case (OnState + charging) shield can be assisted by engineers
                -- It's unfixable without changing the state (and changing state causes even more issues)
                -- so we have to launch assisters thread here too
                if self.StaticShield and not self.AssistersThread and not self.Owner.ActiveConsumption then
                    self.AssistersThread = ForkThread(self.ValidateAssistersThread, self)
                    self.Owner.Trash:Add(self.AssistersThread)
                end

                self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)
                self.OnStateCharging = nil

                -- If the shield has less than full health, allow the shield to begin regening
                if shield_methodsGetHealth(self) < shield_methodsGetMaxHealth(self) and self.RegenRate > 0 then
                    self.RegenThread = ForkThread(self.RegenStartThread, self)
                    self.Owner.Trash:Add(self.RegenThread)
                end
            end
            self.Owner:OnShieldEnabled()

            -- We are no longer turned off
            self.OffHealth = -1

            self:UpdateShieldRatio(-1)
            self:CreateShieldMesh()

            self.Owner:PlayUnitSound('ShieldOn')
            self.Owner:SetMaintenanceConsumptionActive()

            local aiBrain = self.Owner:GetAIBrain()

            WaitSeconds(1.0)
            local fraction = unit_methodsGetResourceConsumed(self.Owner)
            local on = true
            local test = false

            -- Test in here if we have run out of power; if the fraction is ever not 1 we don't have full power
            while on do
                WaitTicks(1)

                self:UpdateShieldRatio(-1)

                fraction = unit_methodsGetResourceConsumed(self.Owner)
                if fraction ~= 1 and aibrain_methodsGetEconomyStored(aiBrain, 'ENERGY') <= 1 then
                    if test then
                        on = false
                    else
                        test = true
                    end
                else
                    on = true
                    test = false
                end
            end

            -- Record the amount of health on the shield here so when the unit tries to turn its shield
            -- back on and off it has the amount of health from before.
            --self.OffHealth = self:GetHealth()
            ChangeState(self, self.EnergyDrainRechargeState)
        end,

        IsOn = function(self)
            return true
        end,
    },

    -- When manually turned off
    OffState = State {
        Main = function(self)
            self.Owner:OnShieldDisabled()
            self.OnStateCharging = nil

            -- No regen during off state
            if self.RegenThread then
                KillThread(self.RegenThread)
                self.RegenThread = nil
            end

            -- Set the offhealth - this is used basically to let the unit know the unit was manually turned off
            self.OffHealth = shield_methodsGetHealth(self)

            if self.DamageRecharge then
                self.DamageRecharge = unit_methodsGetShieldRatio(self.Owner, self.Owner)
            end

            -- Get rid of the shield bar
            self:UpdateShieldRatio(0)
            self:RemoveShield()

            self.Owner:PlayUnitSound('ShieldOff')
            self.Owner:SetMaintenanceConsumptionInactive()

            WaitSeconds(1)
        end,

        IsOn = function(self)
            return false
        end,
    },

    -- This state happens when the shield has been depleted due to damage
    DamageRechargeState = State {
        Main = function(self)
            if not self.DamageRecharge then
                self.DamageRecharge = true

                self:RemoveShield()

                self.Owner:OnShieldDisabled()
                self.Owner:PlayUnitSound('ShieldOff')

                -- We must make the unit charge up before getting its shield back
                self:ChargingUp(0, self.ShieldRechargeTime)

                -- Fully charged, get full health
                shield_methodsSetHealth(self, self, shield_methodsGetMaxHealth(self))

                self.DamageRecharge = nil
                ChangeState(self, self.OnState)
            else
                self:RemoveShield()

                self.Owner:OnShieldDisabled()
                self.Owner:PlayUnitSound('ShieldOff')

                self:ChargingUp(self.ShieldRechargeTime * self.DamageRecharge, self.ShieldRechargeTime)

                shield_methodsSetHealth(self, self, shield_methodsGetMaxHealth(self))

                self.DamageRecharge = nil
                ChangeState(self, self.OnState)
            end
        end,

        IsOn = function(self)
            return false
        end,
    },

    -- This state happens only when the army has run out of power
    EnergyDrainRechargeState = State {
        Main = function(self)
            self:RemoveShield()

            self.Owner:OnShieldDisabled()
            self.Owner:PlayUnitSound('ShieldOff')

            self:ChargingUp(0, self.ShieldEnergyDrainRechargeTime)

            -- If the unit is attached to a transport, make sure the shield goes to the off state
            -- so the shield isn't turned on while on a transport
            if not unit_methodsIsUnitState(self.Owner, 'Attached') then
                ChangeState(self, self.OnState)
            else
                ChangeState(self, self.OffState)
            end
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
}

--- A bubble shield attached to a single unit.
PersonalBubble = Class(Shield) {
    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)

        -- Store off useful values from the blueprint
        local OwnerBp = self.Owner:GetBlueprint()

        self.SizeX = OwnerBp.SizeX
        self.SizeY = OwnerBp.SizeY
        self.SizeZ = OwnerBp.SizeZ

        self.ShieldSize = spec.ShieldSize

        -- Manually disable the bubble shield's collision sphere after its creation so it acts like the new personal shields
        shield_methodsSetCollisionShape(self, 'None')
        self:SetType('Personal')
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- We want all personal shields to pass overkill damage, including this one
        -- Was handled by self.PassOverkillDamage bp value, now defunct
        if self.Owner ~= instigator then
            local overkill = self:GetOverkill(instigator, amount, dmgType)
            if self.Owner and IsUnit(self.Owner) and overkill > 0 then
                self.Owner:DoTakeDamage(instigator, overkill, vector, dmgType)
            end
        end

        Shield.ApplyDamage(self, instigator, amount, vector, dmgType, doOverspill)
    end,

    CreateShieldMesh = function(self)
        Shield.CreateShieldMesh(self)
        shield_methodsSetCollisionShape(self, 'None')
    end,

    RemoveShield = function(self)
        Shield.RemoveShield(self)
        shield_methodsSetCollisionShape(self, 'None')
    end,

    OnState = State(Shield.OnState) {
        Main = function(self)
            -- Set the collision profile of the unit to match the apparent shield sphere.
            -- Since the collision handler in Unit deals with personal shields, the damage will be
            -- passed to the shield.
            self.Owner:SetCollisionShape('Sphere', 0, self.SizeY * 0.5, 0, self.ShieldSize * 0.5)
            Shield.OnState.Main(self)
        end
    },

    OffState = State(Shield.OffState) {
        Main = function(self)
            -- When the shield is down for some reason, reset the unit's collision profile so it can
            -- again be hit.
            unit_methodsRevertCollisionShape(self.Owner)
            Shield.OffState.Main(self)
        end
    },

    DamageRechargeState = State(Shield.DamageRechargeState) {
        Main = function(self)
            unit_methodsRevertCollisionShape(self.Owner)
            Shield.DamageRechargeState.Main(self)
         end
    },

    EnergyDrainRechargeState = State(Shield.EnergyDrainRechargeState) {
        Main = function(self)
            unit_methodsRevertCollisionShape(self.Owner)
            Shield.EnergyDrainRechargeState.Main(self)
        end
    }
}

--- A personal bubble that can render a set of encompassed units invincible.
-- Useful for shielded transports (to work around the area-damage bug).
TransportShield = Class(Shield) {
    -- Yes it says contents, but this includes the generating transport too
    SetContentsVulnerable = function(self, canTakeDamage)
        for k, v in self.protectedUnits do
            k:SetCanTakeDamage(canTakeDamage)
        end
    end,

    RemoveProtectedUnit = function(self, unit)
        self.protectedUnits[unit] = nil
        unit:SetCanTakeDamage(true)
    end,

    AddProtectedUnit = function(self, unit)
        self.protectedUnits[unit] = true
    end,

    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)

        self.protectedUnits = {}
    end,

    -- Protect the contents while the shield is up.
    OnState = State(Shield.OnState) {
        Main = function(self)
            -- We want to protect ourself too!
            self:AddProtectedUnit(self.Owner)

            self:SetContentsVulnerable(false)
            Shield.OnState.Main(self)
        end,

        AddProtectedUnit = function(self, unit)
            self.protectedUnits[unit] = true
            unit:SetCanTakeDamage(false)
        end
    },

    -- Set the contents vulnerable in the various shield-down states.
    OffState = State(Shield.OffState) {
        Main = function(self)
            self:SetContentsVulnerable(true)
            Shield.OffState.Main(self)
        end,
    },

    DamageRechargeState = State(Shield.DamageRechargeState) {
        Main = function(self)
            self:SetContentsVulnerable(true)
            Shield.DamageRechargeState.Main(self)
        end
    },

    EnergyDrainRechargeState = State(Shield.EnergyDrainRechargeState) {
        Main = function(self)
            self:SetContentsVulnerable(true)
            Shield.EnergyDrainRechargeState.Main(self)
        end
    }
}

--- A shield that sticks to the surface of the unit. Doesn't have its own collision physics, just
-- grants extra health.
PersonalShield = Class(Shield){
    OnCreate = function(self, spec)
        self.Trash = TrashBag()
        self.Owner = spec.Owner

        self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
        self.CollisionSizeX = spec.CollisionSizeX or 1
        self.CollisionSizeY = spec.CollisionSizeY or 1
        self.CollisionSizeZ = spec.CollisionSizeZ or 1
        self.CollisionCenterX = spec.CollisionCenterX or 0
        self.CollisionCenterY = spec.CollisionCenterY or 0
        self.CollisionCenterZ = spec.CollisionCenterZ or 0
        self.OwnerShieldMesh = spec.OwnerShieldMesh or ''

        self:SetSize(spec.Size)
        self:SetType('Personal')

        shield_methodsSetMaxHealth(self, spec.ShieldMaxHealth)
        shield_methodsSetHealth(self, self, spec.ShieldMaxHealth)

        -- Show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        self:SetRechargeTime(spec.ShieldRechargeTime or 5, spec.ShieldEnergyDrainRechargeTime or 5)
        self:SetVerticalOffset(spec.ShieldVerticalOffset)

        shield_methodsSetVizToFocusPlayer(self, 'Always')
        shield_methodsSetVizToEnemies(self, 'Intel')
        shield_methodsSetVizToAllies(self, 'Always')
        shield_methodsSetVizToNeutrals(self, 'Always')

        shield_methodsAttachBoneTo(self, -1, spec.Owner, -1)

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

        self.PassOverkillDamage = spec.PassOverkillDamage

        ChangeState(self, self.OnState)
    end,

    ApplyDamage = function(self, instigator, amount, vector, dmgType, doOverspill)
        -- We want all personal shields to pass overkill damage
        -- Was handled by self.PassOverkillDamage bp value, now defunct
        if self.Owner ~= instigator then
            local overkill = self:GetOverkill(instigator, amount, dmgType)
            if self.Owner and IsUnit(self.Owner) and overkill > 0 then
                self.Owner:DoTakeDamage(instigator, overkill, vector, dmgType)
            end
        end

        Shield.ApplyDamage(self, instigator, amount, vector, dmgType, doOverspill)
    end,

    CreateImpactEffect = function(self, vector)
        local OffsetLength = Util.GetVectorLength(vector)
        local ImpactEnt = Entity {Owner = self.Owner}

        Warp(ImpactEnt, shield_methodsGetPosition(self))
        ImpactEnt:SetOrientation(OrientFromDir(Vector(-vector.x, -vector.y, -vector.z)), true)

        for k, v in self.ImpactEffects do
            CreateEmitterAtBone(ImpactEnt, -1, self.Army, v):OffsetEmitter(0, 0, OffsetLength)
        end
        WaitSeconds(1)

        ImpactEnt:Destroy()
    end,

    CreateShieldMesh = function(self)
        -- Personal shields (unit shields) don't handle collisions anymore.
        -- This is done in the Unit's OnDamage function instead.
        shield_methodsSetCollisionShape(self, 'None')
        self.Owner:SetMesh(self.OwnerShieldMesh, true)
    end,

    RemoveShield = function(self)
        shield_methodsSetCollisionShape(self, 'None')
        self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
    end,

    OnDestroy = function(self)
        if not self.Owner.MyShield or self.Owner.MyShield.EntityId == self.EntityId then
            self.Owner:SetMesh(self.Owner:GetBlueprint().Display.MeshBlueprint, true)
        end
        self:UpdateShieldRatio(0)
        ChangeState(self, self.DeadState)
    end,
}

AntiArtilleryShield = Class(Shield) {
    OnCreate = function(self, spec)
        Shield.OnCreate(self, spec)
        self:SetType('AntiArtillery')
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
CzarShield = Class(PersonalShield) {
    OnCreate = function(self, spec)
        self.Trash = TrashBag()
        self.Owner = spec.Owner
        self.MeshBp = spec.Mesh
        self.ImpactMeshBp = spec.ImpactMesh
        self.ImpactMeshBigBp = spec.ImpactMeshBig

        self.ImpactEffects = EffectTemplate[spec.ImpactEffects]
        self.CollisionSizeX = spec.CollisionSizeX or 1
        self.CollisionSizeY = spec.CollisionSizeY or 1
        self.CollisionSizeZ = spec.CollisionSizeZ or 1
        self.CollisionCenterX = spec.CollisionCenterX or 0
        self.CollisionCenterY = spec.CollisionCenterY or 0
        self.CollisionCenterZ = spec.CollisionCenterZ or 0
        self.OwnerShieldMesh = spec.OwnerShieldMesh or ''

        self:SetSize(spec.Size)
        self:SetType('Personal')

        shield_methodsSetMaxHealth(self, spec.ShieldMaxHealth)
        shield_methodsSetHealth(self, self, spec.ShieldMaxHealth)

        -- Show our 'lifebar'
        self:UpdateShieldRatio(1.0)

        self:SetRechargeTime(spec.ShieldRechargeTime or 5, spec.ShieldEnergyDrainRechargeTime or 5)
        self:SetVerticalOffset(spec.ShieldVerticalOffset)

        shield_methodsSetVizToFocusPlayer(self, 'Always')
        shield_methodsSetVizToEnemies(self, 'Intel')
        shield_methodsSetVizToAllies(self, 'Always')
        shield_methodsSetVizToNeutrals(self, 'Always')

        shield_methodsAttachBoneTo(self, -1, spec.Owner, -1)

        self:SetShieldRegenRate(spec.ShieldRegenRate)
        self:SetShieldRegenStartTime(spec.ShieldRegenStartTime)

        self.PassOverkillDamage = spec.PassOverkillDamage

        ChangeState(self, self.OnState)
    end,


    CreateImpactEffect = function(self, vector)
        if not self or self.Owner.Dead then return end
        local army = shield_methodsGetArmy(self)
        local OffsetLength = Util.GetVectorLength(vector)
        local ImpactMesh = Entity {Owner = self.Owner}
        local pos = shield_methodsGetPosition(self)

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
    end,

    CreateShieldMesh = function(self)
        -- Personal shields (unit shields) don't handle collisions anymore.
        -- This is done in the Unit's OnDamage function instead.
        shield_methodsSetCollisionShape(self, 'None')

        shield_methodsSetMesh(self, self.MeshBp)
        shield_methodsSetParentOffset(self, Vector(0, self.ShieldVerticalOffset, 0))
        shield_methodsSetDrawScale(self, self.Size)
    end,

    OnDestroy = function(self)
        Shield.OnDestroy(self)
    end,

    RemoveShield = function(self)
        Shield.RemoveShield(self)
        shield_methodsSetCollisionShape(self, 'None')
    end,
}