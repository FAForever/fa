-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0001/UEL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

-- Automatically upvalued moho functions for performance
local CAnimationManipulatorMethods = _G.moho.AnimationManipulator
local CAnimationManipulatorMethodsPlayAnim = CAnimationManipulatorMethods.PlayAnim
local CAnimationManipulatorMethodsSetBoneEnabled = CAnimationManipulatorMethods.SetBoneEnabled
local CAnimationManipulatorMethodsSetRate = CAnimationManipulatorMethods.SetRate

local EntityMethods = _G.moho.entity_methods
local EntityMethodsRequestRefreshUI = EntityMethods.RequestRefreshUI

local GlobalMethods = _G
local GlobalMethodsRemoveEconomyEvent = GlobalMethods.RemoveEconomyEvent

local IAniManipulatorMethods = _G.moho.manipulator_methods
local IAniManipulatorMethodsSetPrecedence = IAniManipulatorMethods.SetPrecedence

local UnitMethods = _G.moho.unit_methods
local UnitMethodsAddCommandCap = UnitMethods.AddCommandCap
local UnitMethodsAddToggleCap = UnitMethods.AddToggleCap
local UnitMethodsHideBone = UnitMethods.HideBone
local UnitMethodsRemoveCommandCap = UnitMethods.RemoveCommandCap
local UnitMethodsRemoveNukeSiloAmmo = UnitMethods.RemoveNukeSiloAmmo
local UnitMethodsRemoveTacticalSiloAmmo = UnitMethods.RemoveTacticalSiloAmmo
local UnitMethodsRemoveToggleCap = UnitMethods.RemoveToggleCap
local UnitMethodsRestoreBuildRestrictions = UnitMethods.RestoreBuildRestrictions
local UnitMethodsSetCapturable = UnitMethods.SetCapturable
local UnitMethodsSetCreator = UnitMethods.SetCreator
local UnitMethodsSetProductionPerSecondEnergy = UnitMethods.SetProductionPerSecondEnergy
local UnitMethodsSetProductionPerSecondMass = UnitMethods.SetProductionPerSecondMass
local UnitMethodsSetWorkProgress = UnitMethods.SetWorkProgress
local UnitMethodsStopSiloBuild = UnitMethods.StopSiloBuild
-- End of automatically upvalued moho functions

local Shield = import('/lua/shield.lua').Shield
local ACUUnit = import('/lua/defaultunits.lua').ACUUnit
local TerranWeaponFile = import('/lua/terranweapons.lua')
local TDFZephyrCannonWeapon = TerranWeaponFile.TDFZephyrCannonWeapon
local DeathNukeWeapon = import('/lua/sim/defaultweapons.lua').DeathNukeWeapon
local TIFCruiseMissileLauncher = TerranWeaponFile.TIFCruiseMissileLauncher
local TDFOverchargeWeapon = TerranWeaponFile.TDFOverchargeWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local Buff = import('/lua/sim/Buff.lua')

UEL0001 = Class(ACUUnit)({
    Weapons = {
        DeathWeapon = Class(DeathNukeWeapon)({}),
        RightZephyr = Class(TDFZephyrCannonWeapon)({}),
        OverCharge = Class(TDFOverchargeWeapon)({}),
        AutoOverCharge = Class(TDFOverchargeWeapon)({}),
        TacMissile = Class(TIFCruiseMissileLauncher)({}),
        TacNukeMissile = Class(TIFCruiseMissileLauncher)({}),
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightZephyr')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        UnitMethodsSetCapturable(self, false)
        UnitMethodsHideBone(self, 'Right_Upgrade', true)
        UnitMethodsHideBone(self, 'Left_Upgrade', true)
        UnitMethodsHideBone(self, 'Back_Upgrade_B01', true)
        self:SetupBuildBones()
        self.HasLeftPod = false
        self.HasRightPod = false
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        if self:BeenDestroyed() then
            return
        end
        self.Animator = CreateAnimator(self)
        IAniManipulatorMethodsSetPrecedence(self.Animator, 0)
        if self.IdleAnim then
            CAnimationManipulatorMethodsPlayAnim(self.Animator, self:GetBlueprint().Display.AnimationIdle, true)
            for k, v in self.DisabledBones do
                CAnimationManipulatorMethodsSetBoneEnabled(self.Animator, v, false)
            end
        end
        self:BuildManipulatorSetEnabled(false)
        self:SetWeaponEnabledByLabel('RightZephyr', true)
        self:SetWeaponEnabledByLabel('TacMissile', false)
        self:SetWeaponEnabledByLabel('TacNukeMissile', false)
        self:ForkThread(self.GiveInitialResources)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStartBuild(self, unitBeingBuilt, order)
        if self.Animator then
            CAnimationManipulatorMethodsSetRate(self.Animator, 0)
        end
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
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
                EntityMethodsRequestRefreshUI(self)
                WaitFor(self.RebuildingPod)
                UnitMethodsSetWorkProgress(self, 0.0)
                GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
                local location = self:GetPosition('AttachSpecial02')
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'LeftPod')
                UnitMethodsSetCreator(pod, self)
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
                EntityMethodsRequestRefreshUI(self)
                WaitFor(self.RebuildingPod2)
                UnitMethodsSetWorkProgress(self, 0.0)
                GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod2)
                self.RebuildingPod2 = nil
                local location = self:GetPosition('AttachSpecial01')
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'RightPod')
                UnitMethodsSetCreator(pod, self)
                self.Trash:Add(pod)
                self.RightPod = pod
            end
        end
        EntityMethodsRequestRefreshUI(self)
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
            self:CreateEnhancement(pod .. 'Remove')
        end
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then
            return
        end
        if enh == 'LeftPod' then
            local location = self:GetPosition('AttachSpecial02')
            local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'LeftPod')
            UnitMethodsSetCreator(pod, self)
            self.Trash:Add(pod)
            self.HasLeftPod = true
            self.LeftPod = pod
        elseif enh == 'RightPod' then
            local location = self:GetPosition('AttachSpecial01')
            local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
            pod:SetParent(self, 'RightPod')
            UnitMethodsSetCreator(pod, self)
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
                    GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod)
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
                    GlobalMethodsRemoveEconomyEvent(self, self.RebuildingPod2)
                    self.RebuildingPod2 = nil
                end
            end
            KillThread(self.RebuildThread)
            KillThread(self.RebuildThread2)
        elseif enh == 'Teleporter' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Teleport')
        elseif enh == 'Shield' then
            UnitMethodsAddToggleCap(self, 'RULEUTC_ShieldToggle')
            self:CreateShield(bp)
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            RemoveUnitEnhancement(self, 'ShieldRemove')
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
        elseif enh == 'AdvancedEngineering' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT2BuildRate'] then
                BuffBlueprint({
                    Name = 'UEFACUT2BuildRate',
                    DisplayName = 'UEFACUT2BuildRate',
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
            Buff.ApplyBuff(self, 'UEFACUT2BuildRate')
        elseif enh == 'AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then
                return
            end
            UnitMethodsRestoreBuildRestrictions(self)
            self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'UEFACUT2BuildRate') then
                Buff.RemoveBuff(self, 'UEFACUT2BuildRate')
            end
        elseif enh == 'T3Engineering' then
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['UEFACUT3BuildRate'] then
                BuffBlueprint({
                    Name = 'UEFACUT3BuildRate',
                    DisplayName = 'UEFCUT3BuildRate',
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
            Buff.ApplyBuff(self, 'UEFACUT3BuildRate')
        elseif enh == 'T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then
                return
            end
            UnitMethodsRestoreBuildRestrictions(self)
            if Buff.HasBuff(self, 'UEFACUT3BuildRate') then
                Buff.RemoveBuff(self, 'UEFACUT3BuildRate')
            end
            self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        elseif enh == 'DamageStabilization' then
            if not Buffs['UEFACUDamageStabilization'] then
                BuffBlueprint({
                    Name = 'UEFACUDamageStabilization',
                    DisplayName = 'UEFACUDamageStabilization',
                    BuffType = 'DamageStabilization',
                    Stacks = 'REPLACE',
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
            Buff.ApplyBuff(self, 'UEFACUDamageStabilization')
        elseif enh == 'DamageStabilizationRemove' then
            if Buff.HasBuff(self, 'UEFACUDamageStabilization') then
                Buff.RemoveBuff(self, 'UEFACUDamageStabilization')
            end
        elseif enh == 'HeavyAntiMatterCannon' then
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(bp.ZephyrDamageMod)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'HeavyAntiMatterCannonRemove' then
            local bp = self:GetBlueprint().Enhancements['HeavyAntiMatterCannon']
            if not bp then
                return
            end
            local wep = self:GetWeaponByLabel('RightZephyr')
            wep:AddDamageMod(-bp.ZephyrDamageMod)
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
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
        elseif enh == 'TacticalMissile' then
            UnitMethodsAddCommandCap(self, 'RULEUCC_Tactical')
            UnitMethodsAddCommandCap(self, 'RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', true)
        elseif enh == 'TacticalNukeMissile' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Tactical')
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_SiloBuildTactical')
            UnitMethodsAddCommandCap(self, 'RULEUCC_Nuke')
            UnitMethodsAddCommandCap(self, 'RULEUCC_SiloBuildNuke')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', true)
            local amt = self:GetTacticalSiloAmmoCount()
            UnitMethodsRemoveTacticalSiloAmmo(self, amt or 0)
            UnitMethodsStopSiloBuild(self)
        elseif enh == 'TacticalMissileRemove' or enh == 'TacticalNukeMissileRemove' then
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Nuke')
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_SiloBuildNuke')
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_Tactical')
            UnitMethodsRemoveCommandCap(self, 'RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('TacMissile', false)
            self:SetWeaponEnabledByLabel('TacNukeMissile', false)
            local amt = self:GetTacticalSiloAmmoCount()
            UnitMethodsRemoveTacticalSiloAmmo(self, amt or 0)
            local amt = self:GetNukeSiloAmmoCount()
            UnitMethodsRemoveNukeSiloAmmo(self, amt or 0)
            UnitMethodsStopSiloBuild(self)
        end
    end,
})

TypeClass = UEL0001
