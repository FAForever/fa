-----------------------------------------------------------------
-- **
-- File     :  /cdimage/units/UAL0001/UAL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- **
-- Summary  :  Aeon Commander Script
-- **
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
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
local UnitMethodsRestoreBuildRestrictions = UnitMethods.RestoreBuildRestrictions
local UnitMethodsSetCapturable = UnitMethods.SetCapturable
local UnitMethodsSetProductionPerSecondEnergy = UnitMethods.SetProductionPerSecondEnergy
local UnitMethodsSetProductionPerSecondMass = UnitMethods.SetProductionPerSecondMass

local UnitWeaponMethods = _G.moho.weapon_methods
local UnitWeaponMethodsChangeRateOfFire = UnitWeaponMethods.ChangeRateOfFire
-- End of automatically upvalued moho functions

local ACUUnit = import('/lua/defaultunits.lua').ACUUnit
local AWeapons = import('/lua/aeonweapons.lua')
local ADFDisruptorCannonWeapon = AWeapons.ADFDisruptorCannonWeapon
local DeathNukeWeapon = import('/lua/sim/defaultweapons.lua').DeathNukeWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local ADFOverchargeWeapon = AWeapons.ADFOverchargeWeapon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local Buff = import('/lua/sim/Buff.lua')

UAL0001 = Class(ACUUnit)({
    Weapons = {
        DeathWeapon = Class(DeathNukeWeapon)({}),
        RightDisruptor = Class(ADFDisruptorCannonWeapon)({}),
        ChronoDampener = Class(ADFChronoDampener)({}),
        OverCharge = Class(ADFOverchargeWeapon)({}),
        AutoOverCharge = Class(ADFOverchargeWeapon)({}),
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightDisruptor')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        UnitMethodsSetCapturable(self, false)
        self:SetupBuildBones()
        UnitMethodsHideBone(self, 'Back_Upgrade', true)
        UnitMethodsHideBone(self, 'Right_Upgrade', true)
        UnitMethodsHideBone(self, 'Left_Upgrade', true)
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RightDisruptor', true)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
        self:ForkThread(self.GiveInitialResources)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        -- Resource Allocation
        if enh == 'ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then
                return
            end
            UnitMethodsSetProductionPerSecondEnergy(self, bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            UnitMethodsSetProductionPerSecondMass(self, bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            UnitMethodsSetProductionPerSecondEnergy(self, bpEcon.ProductionPerSecondEnergy or 0)
            UnitMethodsSetProductionPerSecondMass(self, bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvanced' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then
                return
            end
            UnitMethodsSetProductionPerSecondEnergy(self, bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            UnitMethodsSetProductionPerSecondMass(self, bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvancedRemove' then
            local bpEcon = self:GetBlueprint().Economy
            UnitMethodsSetProductionPerSecondEnergy(self, bpEcon.ProductionPerSecondEnergy or 0)
            UnitMethodsSetProductionPerSecondMass(self, bpEcon.ProductionPerSecondMass or 0)
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
        elseif enh == 'ShieldHeavy' then
            UnitMethodsAddToggleCap(self, 'RULEUTC_ShieldToggle')
            self:ForkThread(self.CreateHeavyShield, bp)
        elseif enh == 'ShieldHeavyRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            UnitMethodsRemoveToggleCap(self, 'RULEUTC_ShieldToggle')
            -- Teleporter
        elseif enh == 'Teleporter' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Teleport')
            -- Chrono Dampener
        elseif enh == 'ChronoDampener' then
            self:SetWeaponEnabledByLabel('ChronoDampener', true)
            if not Buffs['AeonACUChronoDampener'] then
                BuffBlueprint({
                    Name = 'AeonACUChronoDampener',
                    DisplayName = 'AeonACUChronoDampener',
                    BuffType = 'DamageStabilization',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                    },
                })
            end
            Buff.ApplyBuff(self, 'AeonACUChronoDampener')
        elseif enh == 'ChronoDampenerRemove' then
            if Buff.HasBuff(self, 'AeonACUChronoDampener') then
                Buff.RemoveBuff(self, 'AeonACUChronoDampener')
            end
            self:SetWeaponEnabledByLabel('ChronoDampener', false)
            -- T2 Engineering
        elseif enh == 'AdvancedEngineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then
                return
            end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)

            if not Buffs['AeonACUT2BuildRate'] then
                BuffBlueprint({
                    Name = 'AeonACUT2BuildRate',
                    DisplayName = 'AeonACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
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
            Buff.ApplyBuff(self, 'AeonACUT2BuildRate')
        elseif enh == 'AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then
                return
            end
            UnitMethodsRestoreBuildRestrictions(self)
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT2BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT2BuildRate')
            end
            -- T3 Engineering
        elseif enh == 'T3Engineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then
                return
            end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['AeonACUT3BuildRate'] then
                BuffBlueprint({
                    Name = 'AeonACUT3BuildRate',
                    DisplayName = 'AeonCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
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
            Buff.ApplyBuff(self, 'AeonACUT3BuildRate')
        elseif enh == 'T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then
                return
            end
            UnitMethodsRestoreBuildRestrictions(self)
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT3BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT3BuildRate')
            end
            -- Crysalis Beam
        elseif enh == 'CrysalisBeam' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'CrysalisBeamRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
            -- Heat Sink Augmentation
        elseif enh == 'HeatSink' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            UnitWeaponMethodsChangeRateOfFire(wep, bp.NewRateOfFire or 2)
        elseif enh == 'HeatSinkRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            UnitWeaponMethodsChangeRateOfFire(wep, bpDisrupt or 1)
            -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            EntityMethodsSetIntelRadius(self, 'Vision', bp.NewVisionRadius or 104)
            EntityMethodsSetIntelRadius(self, 'Omni', bp.NewOmniRadius or 104)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            EntityMethodsSetIntelRadius(self, 'Vision', bpIntel.VisionRadius or 26)
            EntityMethodsSetIntelRadius(self, 'Omni', bpIntel.OmniRadius or 26)
        end
    end,

    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end,
})

TypeClass = UAL0001
