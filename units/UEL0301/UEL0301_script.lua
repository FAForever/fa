-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local Shield = import('/lua/shield.lua').Shield
local EffectUtil = import('/lua/EffectUtilities.lua')
local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local TWeapons = import('/lua/terranweapons.lua')
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon

UEL0301 = Class(CommandUnit) {
    IntelEffects = {
        {
            Bones = {
                'Jetpack',
            },
            Scale = 0.5,
            Type = 'Jammer01',
        },
    },

    Weapons = {
        RightHeavyPlasmaCannon = Class(TDFHeavyPlasmaCannonWeapon) {},
        DeathWeapon = Class(SCUDeathWeapon) {},
    },

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Jetpack', true)
        self:HideBone('SAM', true)
        self:SetupBuildBones()
		self.HasLeftPod = false
        self.HasRightPod = false
    end,

    __init = function(self)
        CommandUnit.__init(self, 'RightHeavyPlasmaCannon')
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        -- Block Jammer until Enhancement is built
        self:DisableUnitIntel('Enhancement', 'Jammer')
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        local UpgradesFrom = unitBeingBuilt:GetBlueprint().General.UpgradesFrom
        -- If we are assisting an upgrading unit, or repairing a unit, play separate effects
        if (order == 'Repair' and not unitBeingBuilt:IsBeingBuilt()) or (UpgradesFrom and UpgradesFrom ~= 'none' and self:IsUnitState('Guarding'))then
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    RebuildPod = function(self, PodNumber)
        if PodNumber == 1 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod2 ~= nil then
                WaitFor(self.RebuildingPod2)
            end
            if self.HasLeftPod == true then
                self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'LeftPod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.LeftPod = pod
            end
        elseif PodNumber == 2 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod ~= nil then
                WaitFor(self.RebuildingPod)
            end
            if self.HasRightPod == true then
                self.RebuildingPod2 = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod2)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod2)
                self.RebuildingPod2 = nil
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'RightPod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.RightPod = pod
            end
        end
        self:RequestRefreshUI()
    end,

    NotifyOfPodDeath = function(self, pod, rebuildDrone)
        if rebuildDrone == true then
            if pod == 'LeftPod' then
                if self.HasLeftPod == true then
                    self.RebuildThread = self:ForkThread(self.RebuildPod, 1)
                end
            elseif pod == 'RightPod' then
                if self.HasRightPod == true then
                    self.RebuildThread2 = self:ForkThread(self.RebuildPod, 2)
                end
            end
        else
            self:CreateEnhancement(pod..'Remove')
        end
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'LeftPod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'LeftPod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.HasLeftPod = true
            self.LeftPod = pod
        elseif enh == 'RightPod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'RightPod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.HasRightPod = true
            self.RightPod = pod
        elseif enh == 'LeftPodRemove' or enh == 'RightPodRemove' then
            if self.HasLeftPod == true then
                self.HasLeftPod = false
                if self.LeftPod and not self.LeftPod.Dead then
                    self.LeftPod:Kill()
                    self.LeftPod = nil
                end
                if self.RebuildingPod ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            if self.HasRightPod == true then
                self.HasRightPod = false
                if self.RightPod and not self.RightPod.Dead then
                    self.RightPod:Kill()
                    self.RightPod = nil
                end
                if self.RebuildingPod2 ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod2)
                    self.RebuildingPod2 = nil
                end
            end
            KillThread(self.RebuildThread)
            KillThread(self.RebuildThread2)
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            RemoveUnitEnhancement(self, 'Shield')
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldGeneratorField' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
			self:CreateShield(bp)
        elseif enh == 'ShieldGeneratorFieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
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
        --Sensor + Jammer
		elseif enh == 'SensorRangeEnhancer' then
		
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
			self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
			self.RadarJammerEnh = true
			self:EnableUnitIntel('Enhancement', 'Jammer')
			self:AddToggleCap('RULEUTC_JammingToggle')
        elseif enh == 'SensorRangeEnhancerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
			self:SetIntelRadius('Jammer', 0)
			self:DisableUnitIntel('Enhancement', 'Jammer')
			self.RadarJammerEnh = false
			self:RemoveToggleCap('RULEUTC_JammingToggle')
        elseif enh == 'RadarJammer' then
            self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
            self.RadarJammerEnh = true
            self:EnableUnitIntel('Enhancement', 'Jammer')
            self:AddToggleCap('RULEUTC_JammingToggle')
        elseif enh == 'RadarJammerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Jammer', 0)
            self:DisableUnitIntel('Enhancement', 'Jammer')
            self.RadarJammerEnh = false
            self:RemoveToggleCap('RULEUTC_JammingToggle')
        elseif enh =='AdvancedCoolingUpgrade' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(bp.NewRateOfFire)
        elseif enh =='AdvancedCoolingUpgradeRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(self:GetBlueprint().Weapon[1].RateOfFire or 1)
        --Gun AoE
		elseif enh =='HighExplosiveOrdnance' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh =='HighExplosiveOrdnanceRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
			wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
		end
	end,

    OnIntelEnabled = function(self)
        CommandUnit.OnIntelEnabled(self)
        if self.RadarJammerEnh and self:IsIntelEnabled('Jammer') then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self.CreateTerrainTypeEffects(self, self.IntelEffects, 'FXIdle',  self:GetCurrentLayer(), nil, self.IntelEffectsBag)
            end
            self:SetEnergyMaintenanceConsumptionOverride(self:GetBlueprint().Enhancements['RadarJammer'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end
    end,

    OnIntelDisabled = function(self)
        CommandUnit.OnIntelDisabled(self)
        if self.RadarJammerEnh and not self:IsIntelEnabled('Jammer') then
            self:SetMaintenanceConsumptionInactive()
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            end
        end
    end,
}

TypeClass = UEL0301
