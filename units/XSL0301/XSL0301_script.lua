-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Sub Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetIntelRadius = EntityMethods.SetIntelRadius

local UnitMethods = _G.moho.unit_methods
local UnitMethodsAddCommandCap = UnitMethods.AddCommandCap
local UnitMethodsAddToggleCap = UnitMethods.AddToggleCap
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsRemoveCommandCap = UnitMethods.RemoveCommandCap
local UnitMethodsRemoveToggleCap = UnitMethods.RemoveToggleCap
local UnitMethodsSetCapturable = UnitMethods.SetCapturable
-- End of automatically upvalued moho functions

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local SWeapons = import('/lua/seraphimweapons.lua')
local Buff = import('/lua/sim/Buff.lua')
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher

XSL0301 = Class(CommandUnit)({
    Weapons = {
        LightChronatronCannon = Class(SDFLightChronotronCannonWeapon)({}),
        DeathWeapon = Class(SCUDeathWeapon)({}),
        OverCharge = Class(SDFOverChargeWeapon)({}),
        AutoOverCharge = Class(SDFOverChargeWeapon)({}),
        Missile = Class(SIFLaanseTacticalMissileLauncher)({
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        }),
    },

    __init = function(self)
        CommandUnit.__init(self, 'LightChronatronCannon')
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        UnitMethodsSetCapturable(self, false)
        UnitMethodsHideBone(self, 'Back_Upgrade', true)
        self:SetupBuildBones()
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then
            return
        end
        -- Teleporter
        if enh == 'Teleporter' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Teleport')
            -- Missile
        elseif enh == 'Missile' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Tactical')
            UnitMethodsAddCommandCap(self, 'RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', true)
        elseif enh == 'MissileRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Tactical')
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', false)
            -- Shields
        elseif enh == 'Shield' then
            UnitMethodsAddToggleCap(self, 'RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            UnitMethodsRemoveToggleCap(self, 'RULEUTC_ShieldToggle')
            -- Overcharge
        elseif enh == 'Overcharge' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Overcharge')
            self:GetWeaponByLabel('OverCharge').NeedsUpgrade = false
            self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = false
        elseif enh == 'OverchargeRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Overcharge')
            self:SetWeaponEnabledByLabel('OverCharge', false)
            self:SetWeaponEnabledByLabel('AutoOverCharge', false)
            self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
            self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
            -- Engineering Throughput Upgrade
        elseif enh == 'EngineeringThroughput' then
            if not Buffs['SeraphimSCUBuildRate'] then
                BuffBlueprint({
                    Name = 'SeraphimSCUBuildRate',
                    DisplayName = 'SeraphimSCUBuildRate',
                    BuffType = 'SCUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                    },
                })
            end
            Buff.ApplyBuff(self, 'SeraphimSCUBuildRate')
        elseif enh == 'EngineeringThroughputRemove' then
            if Buff.HasBuff(self, 'SeraphimSCUBuildRate') then
                Buff.RemoveBuff(self, 'SeraphimSCUBuildRate')
            end
            -- Damage Stabilization
        elseif enh == 'DamageStabilization' then
            if not Buffs['SeraphimSCUDamageStabilization'] then
                BuffBlueprint({
                    Name = 'SeraphimSCUDamageStabilization',
                    DisplayName = 'SeraphimSCUDamageStabilization',
                    BuffType = 'SCUUPGRADEDMG',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                })
            end
            if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
                Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
            end
            Buff.ApplyBuff(self, 'SeraphimSCUDamageStabilization')
        elseif enh == 'DamageStabilizationRemove' then
            if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
                Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
            end
            -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            EntityMethodsSetIntelRadius(self, 'Vision', bp.NewVisionRadius or 104)
            EntityMethodsSetIntelRadius(self, 'Omni', bp.NewOmniRadius or 104)
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(35)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(35)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            EntityMethodsSetIntelRadius(self, 'Vision', bpIntel.VisionRadius or 26)
            EntityMethodsSetIntelRadius(self, 'Omni', bpIntel.OmniRadius or 16)
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 25)
        else

        end
    end,
})

TypeClass = XSL0301
