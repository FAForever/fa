-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0301/UAL0301_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local AWeapons = import("/lua/aeonweapons.lua")
local ADFReactonCannon = AWeapons.ADFReactonCannon
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")

---@class UAL0301 : CommandUnit
UAL0301 = Class(CommandUnit) {
    Weapons = {
        RightReactonCannon = Class(ADFReactonCannon) {},
        DeathWeapon = Class(SCUDeathWeapon) {},
    },

    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('RightReactonCannon', true)
        self:GetWeaponManipulatorByLabel('RightReactonCannon'):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Turbine', true)
        self:SetupBuildBones()
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        -- Teleporter
        if enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        -- Shields
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldHeavy' then
            self:ForkThread(self.CreateHeavyShield, bp)
        elseif enh == 'ShieldHeavyRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        -- ResourceAllocation
        elseif enh =='ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        -- Engineering Focus Module
        elseif enh =='EngineeringFocusingModule' then
            if not Buffs['AeonSCUBuildRate'] then
                BuffBlueprint {
                    Name = 'AeonSCUBuildRate',
                    DisplayName = 'AeonSCUBuildRate',
                    BuffType = 'SCUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonSCUBuildRate')
        elseif enh == 'EngineeringFocusingModuleRemove' then
            if Buff.HasBuff(self, 'AeonSCUBuildRate') then
                Buff.RemoveBuff(self, 'AeonSCUBuildRate')
            end
        -- SystemIntegrityCompensator
        elseif enh == 'SystemIntegrityCompensator' then
            local name = 'AeonSCURegenRate'
            if not Buffs[name] then
                BuffBlueprint {
                    Name = name,
                    DisplayName = name,
                    BuffType = 'SCUREGENRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add =  bp.NewRegenRate - self:GetBlueprint().Defense.RegenRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, name)
        elseif enh == 'SystemIntegrityCompensatorRemove' then
            if Buff.HasBuff(self, 'AeonSCURegenRate') then
                Buff.RemoveBuff(self, 'AeonSCURegenRate')
            end
        -- Sacrifice
        elseif enh == 'Sacrifice' then
            self:AddCommandCap('RULEUCC_Sacrifice')
        elseif enh == 'SacrificeRemove' then
            self:RemoveCommandCap('RULEUCC_Sacrifice')
        -- StabilitySupressant
        elseif enh =='StabilitySuppressant' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageMod(bp.NewDamageMod or 0)
            wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 40)
        elseif enh =='StabilitySuppressantRemove' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageMod(-self:GetBlueprint().Enhancements['RightReactonCannon'].NewDamageMod)
            wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
        end
    end,

    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = UAL0301
