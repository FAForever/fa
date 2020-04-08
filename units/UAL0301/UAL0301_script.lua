-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0301/UAL0301_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local AWeapons = import('/lua/aeonweapons.lua')
local ADFReactonCannon = AWeapons.ADFReactonCannon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')

UAL0301 = Class(CommandUnit) {
    Weapons = {
        RightReactonCannon = Class(ADFReactonCannon) {},
        ChronoDampener = Class(ADFChronoDampener) {},
		DeathWeapon = Class(SCUDeathWeapon) {},
    },

    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
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
        -- ChronoDampener
        elseif enh == 'ChronoDampener' then
            self:SetWeaponEnabledByLabel('ChronoDampener', true)
            if not Buffs['AeonSACUChronoDampener'] then
				BuffBlueprint {
					Name = 'AeonSACUChronoDampener',
					DisplayName = 'AeonSACUChronoDampener',
					BuffType = 'DamageStabilization',
					Stacks = 'REPLACE',
					Duration = -1,
					Affects = {
						MaxHealth = {
							Add = bp.NewHealth,
							Mult = 1.0,
						},
					},
				}
			end
			Buff.ApplyBuff(self, 'AeonSACUChronoDampener')
		elseif enh == 'ChronoDampenerRemove' then
		    if Buff.HasBuff(self, 'AeonSACUChronoDampener') then
				Buff.RemoveBuff(self, 'AeonSACUChronoDampener')
			end
			self:SetWeaponEnabledByLabel('ChronoDampener', false)
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
            self:AddCommandCap('RULEUCC_Sacrifice')
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
			self:RemoveCommandCap('RULEUCC_Sacrifice')
            if Buff.HasBuff(self, 'AeonSCUBuildRate') then
                Buff.RemoveBuff(self, 'AeonSCUBuildRate')
            end
        -- GunRange
        elseif enh =='GunRange' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 40)
        elseif enh =='GunRangeRemove' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
        end
		-- GunAoe
        elseif enh =='GunAoe' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
        elseif enh =='GunAoeRemove' then
            local bp = self:GetBlueprint().Enhancements['GunAoe']
            if not bp then return end
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageRadiusMod(-bp.NewDamageRadiusMod)
        -- GunRange
        elseif enh =='GunDps' then
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageMod(bp.GunDamageMod)
        elseif enh =='GunDpsRemove' then
            local bp = self:GetBlueprint().Enhancements['GunDps']
            if not bp then return end
            local wep = self:GetWeaponByLabel('RightReactonCannon')
            wep:AddDamageMod(-bp.GunDamageMod)
    end,

    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = UAL0301
