-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0301/UEL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  UEF Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local Shield = import("/lua/shield.lua").Shield
local EffectUtil = import("/lua/effectutilities.lua")
local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local TWeapons = import("/lua/terranweapons.lua")
local TDFHeavyPlasmaCannonWeapon = TWeapons.TDFHeavyPlasmaCannonWeapon
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon

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
    ---@param order string Unused
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
    ---@param pod TConstructionPodUnit
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


    EnhancementUpgrades = {

        Pod = function (self, bp)
            local x,y,z = self:GetPositionXYZ('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0003', self.Army, x, y, z, 0, 0, 0)
            local trash = self.Trash

            pod:SetParent(self, 'Pod')
            pod:SetCreator(self)

            TrashBagAdd(trash, pod)
            self.HasPod = true
            self.Pod = pod
        end,

        PodRemove = function (self,bp)
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

        Shield = function (self,bp)
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        end,

        ShieldRemove = function (self,bp)
            RemoveUnitEnhancement(self, 'Shield')
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        end,

        ShieldGeneratorField = function (self,bp)
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        end,

        ShieldGeneratorFieldRemove = function (self,bp)
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        end,

        ResourceAllocation = function (self,bp)
            local bpEcon = self.Blueprint.Economy
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)

            --TODO: Add Damage Death Weapon

            --TODO: Add Radius to Death Weapon
        end,

        ResourceAllocationRemove = function (self,bp)
            local bpEcon = self.Blueprint.Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)

            --TODO: Add Remove Damage Death Weapon

            --TODO: Add Remove Radius to Death Weapon
        end,

        SensorRangeEnhancer = function (self,bp)
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
            self:SetIntelRadius('Jammer', bp.NewJammerRadius or 28)
            self:EnableUnitIntel('Enhancement', 'Jammer')
            self.RadarJammerEnh = true
            self:AddToggleCap('RULEUTC_JammingToggle')
        end,

        SensorRangeEnhancerRemove = function (self, bp)
            local bpIntel = self.Blueprint.Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
            self:SetIntelRadius('Jammer', 0)
            self:DisableUnitIntel('Enhancement', 'Jammer')
            self:RemoveToggleCap('RULEUTC_JammingToggle')
            self.RadarJammerEnh = false
        end,

        AdvancedCoolingUpgrade = function(self, bp)
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(bp.NewRateOfFire)
        end,

        AdvancedCoolingUpgradeRemove = function(self, bp)
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:ChangeRateOfFire(bp.Weapon[1].RateOfFire or 1)
        end,

        HighExplosiveOrdnance  = function(self, bp)
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        end,

        HighExplosiveOrdnanceRemove = function(self, bp)
            local wep = self:GetWeaponByLabel('RightHeavyPlasmaCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        end,
    },




    ---@param self UEL0301
    ---@param enh string
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end

        if self.EnhancementUpgrades[enh] then
            self.EnhancementUpgrades[enh](self, bp)
        else
            WARN('SCURebalance: Enhancement '..repr(enh)..' failed. Has no Script')
        end
    end,

    ---@param self UEL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CommandUnit.OnIntelEnabled(self, intel)
        if self.EnhancementUpgrades.SensorRangeEnhancer and self:IsIntelEnabled('Jammer') then
            if self.IntelEffects then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects, 'FXIdle',  self.Layer, nil, self.IntelEffectsBag)
            end
            self:SetEnergyMaintenanceConsumptionOverride(self:GetBlueprint().Enhancements['RadarJammer'].MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        end
    end,

    ---@param self UEL0301
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CommandUnit.OnIntelDisabled(self, intel)
        if self.EnhancementUpgrades.SensorRangeEnhancer and not self:IsIntelEnabled('Jammer') then
            self:SetMaintenanceConsumptionInactive()
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            end
        end
    end,
}

TypeClass = UEL0301
