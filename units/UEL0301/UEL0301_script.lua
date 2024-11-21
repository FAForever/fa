-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DefaultWep = import("/lua/sim/defaultweapons.lua")
local DefaultUnit = import("/lua/defaultunits.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local TWeapons = import("/lua/terranweapons.lua")

local CommandUnit = DefaultUnit.CommandUnit
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = DefaultWep.SCUDeathWeapon

---@class UEL0301 : CommandUnit
UEL0301 = ClassUnit(CommandUnit) {
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
        RightHeavyPlasmaCannon = ClassWeapon(TDFHeavyPlasmaCannonWeapon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
    },

    ---@param self UEL0301
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Jetpack', true)
        self:HideBone('SAM', true)
        self:SetupBuildBones()
    end,

    ---@param self UEL0301
    __init = function(self)
        CommandUnit.__init(self, 'RightHeavyPlasmaCannon')
    end,

    ---@param self UEL0301
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CommandUnit.OnStopBeingBuilt(self, builder, layer)
        -- Block Jammer until Enhancement is built
        self:DisableUnitIntel('Enhancement', 'Jammer')
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        CommandUnit.OnStartBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        CommandUnit.OnStopBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingRepaired Unit
    OnStartRepair = function(self, unitBeingRepaired)
        CommandUnit.OnStartRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param unitBeingRepaired Unit
    OnStopRepair = function(self, unitBeingRepaired)
        CommandUnit.OnStopRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param target Unit|Prop
    OnStartReclaim = function(self, target)
        CommandUnit.OnStartReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    ---@param target Unit|Prop
    OnStopReclaim = function(self, target)
        CommandUnit.OnStopReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0301
    RebuildPod = function(self)
        if self.HasPod == true then
            self.RebuildingPod = CreateEconomyEvent(self, 1600, 160, 10, self.SetWorkProgress)
            self:RequestRefreshUI()
            WaitFor(self.RebuildingPod)
            self:SetWorkProgress(0.0)
            RemoveEconomyEvent(self, self.RebuildingPod)
            self.RebuildingPod = nil
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'Pod')
            pod:SetCreator(self)
            self.Trash:Add(pod)
            self.Pod = pod
        end
    end,

    ---@param self UEL0301
    ---@param pod TConstructionPodUnit unused
    ---@param rebuildDrone boolean
    NotifyOfPodDeath = function(self, pod, rebuildDrone)
        if rebuildDrone == true then
            if self.HasPod == true then
                self.RebuildThread = self:ForkThread(self.RebuildPod)
            end
        else
            self:CreateEnhancement('PodRemove')
        end
    end,

    ---Calling this function will pull any pods without explicit orders to our current task
    ---@param self UEL0301
    RefreshPodFocus = function(self)
        for _, pod in self:GetPods() do
            if not pod.Dead and pod:GetCommandQueue()[1].commandType == 29 then
                IssueToUnitClearCommands(pod)
            end
        end
    end,

    ---@param self UEL0301
    ---@return Unit[]? pods
    GetPods = function(self)
        return {self.Pod}
    end,

    ---@param self UEL0301
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportAttach = function(self, bone, attachee)
        CommandUnit.OnTransportAttach(self, bone, attachee)
        attachee:SetDoNotTarget(true)
    end,

    ---@param self UEL0301
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportDetach = function(self, bone, attachee)
        CommandUnit.OnTransportDetach(self, bone, attachee)
        attachee:SetDoNotTarget(false)
    end,


    -- ============================================================================================================================================================
    -- ENHANCEMENTS

    --- Drone Upgrade
    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPod = function(self, bp)
        local location = self:GetPosition('AttachSpecial01')
        local pod = CreateUnitHPR('UEA0003', self.Army, location[1], location[2], location[3], 0, 0, 0)
        pod:SetParent(self, 'Pod')
        pod:SetCreator(self)
        self.Trash:Add(pod)
        self.HasPod = true
        self.Pod = pod
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementPodRemove = function(self, bp)
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
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function (self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
        self:CreateShield(bp)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function (self, bp)
        RemoveUnitEnhancement(self, 'Shield')
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        self:DestroyShield()
        self:ForkThread(function()
            WaitTicks(1)
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSensorRangeEnhancer = function(self, bp)
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSensorRangeEnhancerRemove = function(self, bp)
        local bpIntel = self.Blueprint.Intel
        self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
        self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRadarJammer = function(self, bp)
        self:SetIntelRadius('Jammer', bp.NewJammerRadius or 26)
        self:EnableUnitIntel('Enhancement', 'Jammer')
        self:AddToggleCap('RULEUTC_JammingToggle')
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()

        if self.IntelEffects then
            self.IntelEffectsBag = {}
            self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle',  self.Layer, nil, self.IntelEffectsBag)
        end

    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementRadarJammerRemove = function(self, bp)
        self.RadarJammerEnh = false
        self:SetIntelRadius('Jammer', 0)
        self:DisableUnitIntel('Enhancement', 'Jammer')
        self:RemoveToggleCap('RULEUTC_JammingToggle')
        self:SetMaintenanceConsumptionInactive()

        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
        end
        
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedCoolingUpgrade = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:ChangeRateOfFire(bp.NewRateOfFire)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementAdvancedCoolingUpgradeRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:ChangeRateOfFire(self.Blueprint.Weapon[1].RateOfFire or 1)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnance = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
    end,

    ---@param self UEL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHighExplosiveOrdnanceRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
    end,

    ---@param self UEL0301
    ---@param enh Enhancement
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self.Blueprint.Enhancements[enh]
        if not bp then return end

        local ref = 'ProcessEnhancement' .. enh
        local handler = self[ref]
        if handler then
            handler(self, bp)
        else
            WARN("Missing enhancement: ", enh, " for unit: ", self:GetUnitId(), " note that the function name should be called: ", ref)
        end
    end,

        ---@param self UEL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CommandUnit.OnIntelEnabled(self, intel)
        if self.RadarJammerEnh and self:IsIntelEnabled('Jammer') then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle',  self.Layer, nil, self.IntelEffectsBag)
            end
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['RadarJammer'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end
    end,

    ---@param self UEL0301
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CommandUnit.OnIntelDisabled(self, intel)
        if self.RadarJammerEnh and not self:IsIntelEnabled('Jammer') then
            self:SetMaintenanceConsumptionInactive()
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            end
        end
    end,
}

TypeClass = UEL0301

--#region Mod Compatibility
local Shield = import("/lua/shield.lua").Shield
--#endregion