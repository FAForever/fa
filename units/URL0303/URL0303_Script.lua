-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0303/URL0303_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsKill = EntityMethods.Kill

local GlobalMethods = _G
local GlobalMethodsCreateLightParticle = GlobalMethods.CreateLightParticle
local GlobalMethodsDamageArea = GlobalMethods.DamageArea

local UnitMethods = _G.moho.unit_methods
local UnitMethodsSetAccMult = UnitMethods.SetAccMult
local UnitMethodsSetSpeedMult = UnitMethods.SetSpeedMult
-- End of automatically upvalued moho functions

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local Weapon = import('/lua/sim/Weapon.lua').Weapon
local cWeapons = import('/lua/cybranweapons.lua')
local CDFLaserDisintegratorWeapon = cWeapons.CDFLaserDisintegratorWeapon01
local CDFElectronBolterWeapon = cWeapons.CDFElectronBolterWeapon
local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileRedirect

local EMPDeathWeapon = Class(Weapon)({
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self:GetBlueprint()
        GlobalMethodsDamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
})

URL0303 = Class(CWalkingLandUnit)({
    PlayEndAnimDestructionEffects = false,

    Weapons = {
        Disintigrator = Class(CDFLaserDisintegratorWeapon)({}),
        HeavyBolter = Class(CDFElectronBolterWeapon)({}),
        DeathWeapon = Class(EMPDeathWeapon)({}),
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint().Defense.AntiMissile
        local antiMissile = MissileRedirect({
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire,
        })
        self.Trash:Add(antiMissile)
        self.ChargingInitiated = false
        self.ChargingInProgress = false
    end,

    InitiateCharge = function(self)
        if self.ChargingInitiated then
            return
        end

        self.ChargingInitiated = true
        local blueprint = self:GetBlueprint()
        local bufffx3 = CreateAttachedEmitter(self, 0, self:GetArmy(), '/effects/emitters/cybran_loyalist_charge_03_emit.bp')
        self.Trash:Add(bufffx3)
        WaitSeconds(blueprint.SecondsBeforeChargeKicksIn)

        self.ChargingInProgress = true
        self:SetWeaponEnabledByLabel('Disintigrator', false)
        self:SetWeaponEnabledByLabel('HeavyBolter', false)
        UnitMethodsSetAccMult(self, blueprint.Physics.ChargeAccMult)
        UnitMethodsSetSpeedMult(self, blueprint.Physics.ChargeSpeedMult)
        -- EMP duration mult added in DoDeathWeapon 

        local bufffx1 = CreateAttachedEmitter(self, 0, self:GetArmy(), '/effects/emitters/cybran_loyalist_charge_01_emit.bp')
        local bufffx2 = CreateAttachedEmitter(self, 0, self:GetArmy(), '/effects/emitters/cybran_loyalist_charge_02_emit.bp')
        self.Trash:Add(bufffx1)
        self.Trash:Add(bufffx2)
        StartCountdown(self.EntityId, blueprint.SecondsBeforeExplosionWhenCharging)
        WaitSeconds(blueprint.SecondsBeforeExplosionWhenCharging)
        EntityMethodsKill(self)
    end,

    OnScriptBitSet = function(self, bit)
        if bit == 7 then
            self:ForkThread(self.InitiateCharge)
        end
    end,

    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then
            return
        end

        -- Handle the normal DeathWeapon procedures
        CWalkingLandUnit.DoDeathWeapon(self)

        -- Now handle our special buff and FX
        local original_bp = table.deepcopy(self:GetBlueprint().Buffs)
        local bp
        for k, v in original_bp do
            if v.Add.OnDeath then
                bp = v
            end
            if self.ChargingInProgress then
                bp.Duration = bp.DurationWhenCharging
            end
        end

        -- If we could find a blueprint with v.Add.OnDeath, then add the buff
        if bp ~= nil then
            self:AddBuff(bp)
        end

        -- Play EMP Effect
        GlobalMethodsCreateLightParticle(self, -1, -1, 24, 62, 'flare_lens_add_02', 'ramp_red_10')
    end,
})

TypeClass = URL0303
