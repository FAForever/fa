-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0303/URL0303_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local Weapon = import("/lua/sim/weapon.lua").Weapon
local cWeapons = import("/lua/cybranweapons.lua")
local CDFLaserDisintegratorWeapon = cWeapons.CDFLaserDisintegratorWeapon01
local CDFElectronBolterWeapon = cWeapons.CDFElectronBolterWeapon
local MissileRedirect = import("/lua/defaultantiprojectile.lua").MissileRedirect

---@class EMPDeathWeapon : Weapon
local EMPDeathWeapon = ClassWeapon(Weapon) {
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self.Blueprint
        DamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius,
            blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
}

---@class URL0303 : CWalkingLandUnit
URL0303 = ClassUnit(CWalkingLandUnit) {
    PlayEndAnimDestructionEffects = false,

    Weapons = {
        Disintigrator = ClassWeapon(CDFLaserDisintegratorWeapon) {},
        HeavyBolter = ClassWeapon(CDFElectronBolterWeapon) {},
        DeathWeapon = ClassWeapon(EMPDeathWeapon) {},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self.Blueprint.Defense.AntiMissile
        local antiMissile = MissileRedirect {
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire
        }
        self.Trash:Add(antiMissile)
        self.ChargingInitiated = false
        self.ChargingInProgress = false
    end,

    InitiateCharge = function(self)
        local army = self.Army
        
        
        if self.ChargingInitiated then return end

        self.ChargingInitiated = true
        local blueprint = self.Blueprint
        local bufffx3 = CreateAttachedEmitter(self, 0, army, '/effects/emitters/cybran_loyalist_charge_03_emit.bp')
        self.Trash:Add(bufffx3)
        WaitSeconds(blueprint.SecondsBeforeChargeKicksIn)

        self.ChargingInProgress = true
        self:SetAccMult(blueprint.Physics.ChargeAccMult)
        self:SetSpeedMult(blueprint.Physics.ChargeSpeedMult)

        local bufffx1 = CreateAttachedEmitter(self, 0, army, '/effects/emitters/cybran_loyalist_charge_01_emit.bp')
        local bufffx2 = CreateAttachedEmitter(self, 0, army, '/effects/emitters/cybran_loyalist_charge_02_emit.bp')
        self.Trash:Add(bufffx1)
        self.Trash:Add(bufffx2)
        StartCountdown(self.EntityId, blueprint.SecondsBeforeExplosionWhenCharging)
        WaitSeconds(blueprint.SecondsBeforeExplosionWhenCharging)
        self:Kill()
    end,

    OnScriptBitSet = function(self, bit)
        if bit == 7 then
            self.Trash:Add(ForkThread(self.InitiateCharge, self))
        end
    end,

    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end
        CWalkingLandUnit.DoDeathWeapon(self)
        local original_bp = table.deepcopy(self.Blueprint.Buffs)
        local bp
        for k, v in original_bp do
            if v.Add.OnDeath then
                bp = v
            end
            if self.ChargingInProgress then
                bp.Duration = bp.DurationWhenCharging
            end
        end

        if bp ~= nil then
            self:AddBuff(bp)
        end

        CreateLightParticle(self, -1, self.Army, 24, 62, 'flare_lens_add_02', 'ramp_red_10')
    end,
}

TypeClass = URL0303
