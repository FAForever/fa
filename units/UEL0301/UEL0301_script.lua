-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsKill = EntityMethods.Kill
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI
local EntityMethodsSetIntelRadius = EntityMethods.SetIntelRadius

local GlobalMethods = _G
local GlobalMethodsRemoveEconomyEvent = GlobalMethods.RemoveEconomyEvent

local UnitMethods = _G.moho.unit_methods
local UnitMethodsAddToggleCap = UnitMethods.AddToggleCap
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsRemoveToggleCap = UnitMethods.RemoveToggleCap
local UnitMethodsSetCapturable = UnitMethods.SetCapturable
local UnitMethodsSetCreator = UnitMethods.SetCreator
local UnitMethodsSetProductionPerSecondEnergy = UnitMethods.SetProductionPerSecondEnergy
local UnitMethodsSetProductionPerSecondMass = UnitMethods.SetProductionPerSecondMass
local UnitMethodsSetWorkProgress = UnitMethods.SetWorkProgress

local UnitWeaponMethods = _G.moho.weapon_methods
local UnitWeaponMethodsChangeRateOfFire = UnitWeaponMethods.ChangeRateOfFire
-- End of automatically upvalued moho functions

local Shield = import('/lua/shield.lua').Shield
local EffectUtil = import('/lua/EffectUtilities.lua')
local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local TWeapons = import('/lua/terranweapons.lua')
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon

UEL0301 = Class(CommandUnit)({
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
        RightHeavyPlasmaCannon = Class(TDFHeavyPlasmaCannonWeapon)({}),
        DeathWeapon = Class(SCUDeathWeapon)({}),
    },

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        UnitMethodsSetCapturable(self, false)
        UnitMethodsHideBone(self, 'Jetpack', true)
        UnitMethodsHideBone(self, 'SAM', true)
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
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    RebuildPod = function(self)
        if self.HasPod == true then
            self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
            EntityMethodsRequestRefreshUI(self)
            WaitFor(self.RebuildingPod)
            UnitMethodsSetWorkProgress(self, 0.0)
            GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod)
            self.RebuildingPod = nil
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            UnitMethodsSetCreator(pod, self)
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
        if not bp then
            return
        end
        if enh == 'Pod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            UnitMethodsSetCreator(pod, self)
            self.Trash:Add(pod)
            self.HasPod = true
            self.Pod = pod
        elseif enh == 'PodRemove' then
            if self.HasPod == true then
                self.HasPod = false
                if self.Pod and not self.Pod:BeenDestroyed() then
                    EntityMethodsKill(self.Pod)
                    self.Pod = nil
                end
                if self.RebuildingPod ~= nil then
                    GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod)
                    self.RebuildingPod = nil
                end
            end
            KillThread(self.RebuildThread)
        elseif enh == 'Shield' then
            UnitMethodsAddToggleCap(self, 'RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            RemoveUnitEnhancement(self, 'Shield')
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            UnitMethodsRemoveToggleCap(self, 'RULEUTC_ShieldToggle')
        elseif enh == 'ShieldGeneratorField' then
            self:DestroyShield()
            self:ForkThread(function()
                WaitTicks(1)
                self:CreateShield(bp)
                self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
                self:SetMaintenanceConsumptionActive()
            end)
        elseif enh == 'ShieldGeneratorFieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            UnitMethodsRemoveToggleCap(self, 'RULEUTC_ShieldToggle')
        elseif enh == 'ResourceAllocation' then
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
        elseif enh == 'SensorRangeEnhancer' then
            EntityMethodsSetIntelRadius(self, 'Vision', bp.NewVisionRadius or 104)
            EntityMethodsSetIntelRadius(self, 'Omni', bp.NewOmniRadius or 104)
        elseif enh == 'SensorRangeEnhancerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            EntityMethodsSetIntelRadius(self, 'Vision', bpIntel.VisionRadius or 26)
            EntityMethodsSetIntelRadius(self, 'Omni', bpIntel.OmniRadius or 26)
        elseif enh == 'RadarJammer' then
            EntityMethodsSetIntelRadius(self, 'Jammer', bp.NewJammerRadius or 26)
            self.RadarJammerEnh = true
            self:EnableUnitIntel('Enhancement', 'Jammer')
            UnitMethodsAddToggleCap(self, 'RULEUTC_JammingToggle')
        elseif enh == 'RadarJammerRemove' then
            local bpIntel = self:GetBlueprint().Intel
            EntityMethodsSetIntelRadius(self, 'Jammer', 0)
            self:DisableUnitIntel('Enhancement', 'Jammer')
            self.RadarJammerEnh = false
            UnitMethodsRemoveToggleCap(self, 'RULEUTC_JammingToggle')
        elseif enh == 'AdvancedCoolingUpgrade' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            UnitWeaponMethodsChangeRateOfFire(wep, bp.NewRateOfFire)
        elseif enh == 'AdvancedCoolingUpgradeRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            UnitWeaponMethodsChangeRateOfFire(wep, self:GetBlueprint().Weapon[1].RateOfFire or 1)
        elseif enh == 'HighExplosiveOrdnance' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh == 'HighExplosiveOrdnanceRemove' then
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        else

        end
    end,

    OnIntelEnabled = function(self)
        CommandUnit.OnIntelEnabled(self)
        if self.RadarJammerEnh and self:IsIntelEnabled('Jammer') then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self.CreateTerrainTypeEffects(self, self.IntelEffects, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
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
})

TypeClass = UEL0301
