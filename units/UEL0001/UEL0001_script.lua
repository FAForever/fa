-----------------------------------------------------------------
-- File     :  /cdimage/units/UEL0001/UEL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  UEF Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias UEFACUEnhancementBuffType
---| "DamageStabilization"
---| "ACUBUILDRATE"

---@alias UEFACUEnhancementBuffName           # BuffType
---| "UEFACUDamageStabilization"              # DamageStabilization
---| "UEFACUT2BuildRate"                      # ACUBUILDRATE
---| "UEFACUT3BuildRate"                      # ACUBUILDRATE


local Shield = import("/lua/shield.lua").Shield
local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local TerranWeaponFile = import("/lua/terranweapons.lua")
local TDFZephyrCannonWeapon = TerranWeaponFile.TDFZephyrCannonWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local TIFCruiseMissileLauncher = TerranWeaponFile.TIFCruiseMissileLauncher
local TDFOverchargeWeapon = TerranWeaponFile.TDFOverchargeWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")

local podBpEco = __blueprints['uea0001']--[[@as UnitBlueprint]].Economy

---@class UEL0001 : ACUUnit
---@field LeftPod TConstructionPodUnit
---@field HasLeftPod boolean
---@field RebuildThread? thread # Rebuilds left pod
---@field RightPod TConstructionPodUnit
---@field HasRightPod boolean
---@field RebuildThread2? thread # Rebuilds right pod
---@field MissileHatchSlider moho.SlideManipulator
UEL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        RightZephyr = ClassWeapon(TDFZephyrCannonWeapon) {},
        OverCharge = ClassWeapon(TDFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(TDFOverchargeWeapon) {},
        --- Special weapon with UEF ACU hatch animations when reloading
        ---@class TacMissile : TIFCruiseMissileLauncher
        ---@field unit UEL0001
        TacMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            ---@param self TacMissile
            PlayFxRackSalvoChargeSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoChargeSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    hatch:SetGoal(0, 0, 1.9):SetSpeed(9.5) -- Matches charge time - 0.1 seconds
                end
            end,

            ---@param self TacMissile
            PlayFxRackSalvoReloadSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoReloadSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.Trash:Add(
                        ForkThread(
                            self.CloseHatchThread, self, hatch
                        )
                    )
                end
            end,

            ---@param self TacMissile
            ---@param slider moho.SlideManipulator
            CloseHatchThread = function(self, slider)
                -- wait for the launch effects to clear
                WaitTicks(30)

                if IsDestroyed(slider) then
                    return
                end

                slider:SetGoal(0, 0, 0)
                slider:SetSpeed(1.12) -- speed matches reload time
            end,
        },

        --- Special weapon with UEF ACU hatch animations when reloading
        ---@class TacNukeMissile : TIFCruiseMissileLauncher
        ---@field unit UEL0001
        TacNukeMissile = ClassWeapon(TIFCruiseMissileLauncher) {
            ---@param self TacNukeMissile
            PlayFxRackSalvoChargeSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoChargeSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.unit.MissileHatchSlider:SetGoal(0, 0, 1.9):SetSpeed(9.5) -- Matches charge time - 0.1 seconds
                end
            end,

            ---@param self TacNukeMissile
            PlayFxRackSalvoReloadSequence = function(self)
                TIFCruiseMissileLauncher.PlayFxRackSalvoReloadSequence(self)
                local hatch = self.unit.MissileHatchSlider
                if hatch then
                    self.Trash:Add(
                        ForkThread(
                            self.CloseHatchThread, self, hatch
                        )
                    )
                end
            end,

            ---@param self TacNukeMissile
            ---@param slider moho.SlideManipulator
            CloseHatchThread = function(self, slider)
                -- wait for the launch effects to clear
                WaitTicks(30)

                if IsDestroyed(slider) then
                    return
                end

                -- speed matches reload time
                slider:SetGoal(0, 0, 0)
                slider:SetSpeed(0.077)
            end,
        },
    },

    ---@param self UEL0001
    __init = function(self)
        ACUUnit.__init(self, 'RightZephyr')
    end,

    ---@param self UEL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        self:HideBone('Back_Upgrade_B01', true)
        self:SetupBuildBones()
        self.HasLeftPod = false
        self.HasRightPod = false
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))

        local hatchBone = 'Back_Upgrade_B02'
        if self:IsValidBone(hatchBone) then
            self.MissileHatchSlider = CreateSlider(self, hatchBone)
        else
            WARN('*ERROR: Trying to use the bone, ' ..
                hatchBone .. ' on unit ' .. self.UnitId .. ' and it does not exist in the model.')
        end
    end,

    ---@param self UEL0001
    ---@param builder Unit
    ---@param layer string
    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        if self:BeenDestroyed() then return end
        self.Animator = CreateAnimator(self)
        self.Animator:SetPrecedence(0)
        self:BuildManipulatorSetEnabled(false)
        self:SetWeaponEnabledByLabel('RightZephyr', true)
        self:SetWeaponEnabledByLabel('TacMissile', false)
        self:SetWeaponEnabledByLabel('TacNukeMissile', false)
        self:ForkThread(self.GiveInitialResources)
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStartBuild(self, unitBeingBuilt, order)
        if self.Animator then
            self.Animator:SetRate(0)
        end
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStopBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStopBuild(self, unitBeingBuilt, order)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingRepaired Unit
    OnStartRepair = function(self, unitBeingRepaired)
        ACUUnit.OnStartRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingRepaired Unit
    OnStopRepair = function(self, unitBeingRepaired)
        ACUUnit.OnStopRepair(self, unitBeingRepaired)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param target Unit|Prop
    OnStartReclaim = function(self, target)
        ACUUnit.OnStartReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param target Unit|Prop
    OnStopReclaim = function(self, target)
        ACUUnit.OnStopReclaim(self, target)
        self:RefreshPodFocus()
    end,

    ---@param self UEL0001
    ---@param unitBeingBuilt Unit | { BuildingCube : boolean }
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFCommanderBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones,
                self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    ---@param self UEL0001
    ---@param PodNumber integer
    RebuildPod = function(self, PodNumber)
        if PodNumber == 1 then
            -- Force pod rebuilds to queue up
            if self.RebuildingPod2 ~= nil then
                WaitFor(self.RebuildingPod2)
            end
            if self.HasLeftPod == true then
                self.RebuildingPod = CreateEconomyEvent(self, podBpEco.BuildCostEnergy, podBpEco.BuildCostMass, podBpEco.BuildTime / self:GetBuildRate(), self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod)
                self.RebuildingPod = nil
                local location = self:GetPosition('AttachSpecial02')
                ---@type UEA0001
                ---@diagnostic disable-next-line: assign-type-mismatch
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
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
                self.RebuildingPod2 = CreateEconomyEvent(self, podBpEco.BuildCostEnergy, podBpEco.BuildCostMass, podBpEco.BuildTime / self:GetBuildRate(), self.SetWorkProgress)
                self:RequestRefreshUI()
                WaitFor(self.RebuildingPod2)
                self:SetWorkProgress(0.0)
                RemoveEconomyEvent(self, self.RebuildingPod2)
                self.RebuildingPod2 = nil
                local location = self:GetPosition('AttachSpecial01')
                ---@type UEA0001
                ---@diagnostic disable-next-line: assign-type-mismatch
                local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
                pod:SetParent(self, 'RightPod')
                pod:SetCreator(self)
                self.Trash:Add(pod)
                self.RightPod = pod
            end
        end
        self:RequestRefreshUI()
    end,

    ---@param self UEL0001
    ---@param pod string
    ---@param rebuildDrone boolean
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

    ---Calling this function will pull any pods without explicit orders to our current task
    ---@param self UEL0001
    RefreshPodFocus = function(self)
        for _, pod in self:GetPods() do
            if not pod.Dead and pod:GetCommandQueue()[1].commandType == 29 then
                IssueToUnitClearCommands(pod)
            end
        end
    end,

    ---@param self UEL0001
    ---@return Unit[]? pods
    GetPods = function(self)
        return {self.LeftPod, self.RightPod}
    end,

    ---@param self UEL0001
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportAttach = function(self, bone, attachee)
        ACUUnit.OnTransportAttach(self, bone, attachee)
        attachee:SetDoNotTarget(true)
    end,

    ---@param self UEL0001
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportDetach = function(self, bone, attachee)
        ACUUnit.OnTransportDetach(self, bone, attachee)
        attachee:SetDoNotTarget(false)
    end,

    ---------------------------------------------------------------------------
    --#region Enhancements

    -- Drone Upgrades

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementLeftPod = function(self, bp)
        local location = self:GetPosition('AttachSpecial02')
        ---@type UEA0001
        ---@diagnostic disable-next-line: assign-type-mismatch
        local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
        pod:SetParent(self, 'LeftPod')
        pod:SetCreator(self)
        self.Trash:Add(pod)
        self.HasLeftPod = true
        self.LeftPod = pod
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementLeftPodRemove = function(self, bp)
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
        KillThread(self.RebuildThread)
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRightPod = function(self, bp)
        local location = self:GetPosition('AttachSpecial01')
        ---@type UEA0001
        ---@diagnostic disable-next-line: assign-type-mismatch
        local pod = CreateUnitHPR('UEA0001', self.Army, location[1], location[2], location[3], 0, 0, 0)
        pod:SetParent(self, 'RightPod')
        pod:SetCreator(self)
        self.Trash:Add(pod)
        self.HasRightPod = true
        self.RightPod = pod
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRightPodRemove = function(self, bp)
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
    end,

    -- Teleport Upgrade

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    -- Personal Shield

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        RemoveUnitEnhancement(self, 'ShieldRemove')
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    -- Bubble Shield

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorField = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:DestroyShield()
        self:ForkThread(
            function()
                WaitTicks(1)
                self:CreateShield(bp)
                self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
                self:SetMaintenanceConsumptionActive()
            end
        )
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldGeneratorFieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    -- T2 Engineering Suite

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineering = function(self, bp)
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['UEFACUT2BuildRate'] then
            BuffBlueprint {
                Name = 'UEFACUT2BuildRate',
                DisplayName = 'UEFACUT2BuildRate',
                BuffType = 'ACUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
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
            }
        end
        Buff.ApplyBuff(self, 'UEFACUT2BuildRate')

    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineeringRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        self:AddBuildRestriction(categories.UEF *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        self:AddBuildRestriction(categories.UEF *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        if Buff.HasBuff(self, 'UEFACUT2BuildRate') then
            Buff.RemoveBuff(self, 'UEFACUT2BuildRate')
        end
    end,

    -- T3 Engineering Suite

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3Engineering = function(self, bp)
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['UEFACUT3BuildRate'] then
            BuffBlueprint {
                Name = 'UEFACUT3BuildRate',
                DisplayName = 'UEFCUT3BuildRate',
                BuffType = 'ACUBUILDRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    BuildRate = {
                        Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
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
            }
        end
        Buff.ApplyBuff(self, 'UEFACUT3BuildRate')

    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3EngineeringRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        if Buff.HasBuff(self, 'UEFACUT3BuildRate') then
            Buff.RemoveBuff(self, 'UEFACUT3BuildRate')
        end
        self:AddBuildRestriction(categories.UEF * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    -- Nano Repair System

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilization = function(self, bp)
        if not Buffs['UEFACUDamageStabilization'] then
            BuffBlueprint {
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
            }
        end
        Buff.ApplyBuff(self, 'UEFACUDamageStabilization')

    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationRemove = function(self, bp)
        if Buff.HasBuff(self, 'UEFACUDamageStabilization') then
            Buff.RemoveBuff(self, 'UEFACUDamageStabilization')
        end
    end,

    -- Gun Upgrade

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHeavyAntiMatterCannon = function(self, bp)
        local wep = self:GetWeaponByLabel('RightZephyr')
        wep:AddDamageMod(bp.ZephyrDamageMod)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHeavyAntiMatterCannonRemove = function(self, bp)
        local bp = self.Blueprint.Enhancements['HeavyAntiMatterCannon']
        if not bp then return end
        local wep = self:GetWeaponByLabel('RightZephyr')
        wep:AddDamageMod(-bp.ZephyrDamageMod)
        local bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        wep:ChangeMaxRadius(bpDisrupt or 22)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bpDisrupt or 22)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bpDisrupt or 22)
    end,

    -- RAS

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        if not bp then return end
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)

    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    -- Tactical Missile Launcher

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTacticalMissile = function(self, bp)
        self:AddCommandCap('RULEUCC_Tactical')
        self:AddCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('TacMissile', true)
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTacticalMissileRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('TacMissile', false)
        local amt = self:GetTacticalSiloAmmoCount()
        self:RemoveTacticalSiloAmmo(amt or 0)
        self:StopSiloBuild()
    end,

    -- Billy Nuke

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTacticalNukeMissile = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:AddCommandCap('RULEUCC_Nuke')
        self:AddCommandCap('RULEUCC_SiloBuildNuke')
        self:SetWeaponEnabledByLabel('TacMissile', false)
        self:SetWeaponEnabledByLabel('TacNukeMissile', true)
        local amt = self:GetTacticalSiloAmmoCount()
        self:RemoveTacticalSiloAmmo(amt or 0)
        self:StopSiloBuild()
    end,

    ---@param self UEL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTacticalNukeMissileRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Nuke')
        self:RemoveCommandCap('RULEUCC_SiloBuildNuke')
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('TacMissile', false)
        self:SetWeaponEnabledByLabel('TacNukeMissile', false)
        local amt = self:GetTacticalSiloAmmoCount()
        self:RemoveTacticalSiloAmmo(amt or 0)
        local amt = self:GetNukeSiloAmmoCount()
        self:RemoveNukeSiloAmmo(amt or 0)
        self:StopSiloBuild()
    end,


    ---@param self UEL0001
    ---@param enh Enhancement
    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

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

    --#endregion
}

TypeClass = UEL0001
