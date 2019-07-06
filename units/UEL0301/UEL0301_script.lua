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
        self:HideBones({'Jetpack', 'SAM'}, true)
        self:SetupBuildBones()
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
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag)
        else
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateSliceBeam, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag))
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateSliceBeam, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag, true))
        end
    end,

    RebuildPod = function(self)
        if self.HasPod == true then
            self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
            self:RequestRefreshUI()
            WaitFor(self.RebuildingPod)
            self:SetWorkProgress(0.0)
            RemoveEconomyEvent(self, self.RebuildingPod)
            self.RebuildingPod = nil
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.Pod = pod
        end
    end,

    NotifyOfPodDeath = function(self, pod, rebuildDrone)
        if rebuildDrone == true then
            if self.HasPod == true then
                self.RebuildThread = self:ForkThread(self.RebuildPod)
            end
        else
            self:CreateEnhancement('PodRemove')
        end
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        if enh == 'Pod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self:GetArmy(), location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.HasPod = true
            self.Pod = pod
        elseif enh == 'PodRemove' then
            if self.HasPod == true then
                self.HasPod = false
                if self.Pod and not self.Pod:BeenDestroyed() then
                    self.Pod:Kill()
                    self.Pod = nil
                end
                if self.RebuildingPod ~= nil then
                    RemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            KillThread(self.RebuildThread)
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
            self:DestroyShield()
            ForkThread(function()
                WaitTicks(1)
                self:CreateShield(bp)
                self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
                self:SetMaintenanceConsumptionActive()
            end)
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
        elseif enh == 'SensorRangeEnhancer' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        elseif enh == 'SensorRangeEnhancerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
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
        elseif enh =='HighExplosiveOrdnance' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh =='HighExplosiveOrdnanceRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
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
