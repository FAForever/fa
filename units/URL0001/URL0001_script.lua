-----------------------------------------------------------------------------------------
-- File     :  /cdimage/units/URL0001/URL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos, Andres Mendez
-- Summary  :  Cybran Commander Unit Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------

---@alias CybranACUEnhancementBuffType
---| "ACUCLOAKBONUS"
---| "ACUSTEALTHBONUS"
---| "ACUBUILDRATE"
---| "ACUUPGRADEDMG"

---@alias CybranACUEnhancementBuffName        # BuffType
---| "CybranACUCloakBonus"                    # ACUCLOAKBONUS
---| "CybranACUStealthBonus"                  # ACUSTEALTHBONUS
---| "CybranACUT2BuildRate"                   # ACUBUILDRATE
---| "CybranACUT3BuildRate"                   # ACUBUILDRATE
---| "CybranACUNanoBonus"                     # ACUREGENRATE


local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local CCommandUnit = import("/lua/cybranunits.lua").CCommandUnit
local CWeapons = import("/lua/cybranweapons.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")
local CCannonMolecularWeapon = CWeapons.CCannonMolecularWeapon
local DeathNukeWeapon = import("/lua/sim/defaultweapons.lua").DeathNukeWeapon
local CDFHeavyMicrowaveLaserGeneratorCom = CWeapons.CDFHeavyMicrowaveLaserGeneratorCom
local CDFOverchargeWeapon = CWeapons.CDFOverchargeWeapon
local CANTorpedoLauncherWeapon = CWeapons.CANTorpedoLauncherWeapon
local Entity = import("/lua/sim/entity.lua").Entity

URL0001 = ClassUnit(ACUUnit, CCommandUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(DeathNukeWeapon) {},
        RightRipper = ClassWeapon(CCannonMolecularWeapon) {},
        Torpedo = ClassWeapon(CANTorpedoLauncherWeapon) {},
        MLG = ClassWeapon(CDFHeavyMicrowaveLaserGeneratorCom) {
            DisabledFiringBones = { 'Turret_Muzzle_03' },

            SetOnTransport = function(self, transportstate)
                CDFHeavyMicrowaveLaserGeneratorCom.SetOnTransport(self, transportstate)
                self.Trash:Add(ForkThread(self.OnTransportWatch,self))
            end,

            OnTransportWatch = function(self)
                while self:GetOnTransport() do
                    self:PlayFxBeamEnd()
                    self:SetWeaponEnabled(false)
                    WaitTicks(4)
                end
            end,
        },

        OverCharge = ClassWeapon(CDFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(CDFOverchargeWeapon) {},
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightRipper')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        CCommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        if self.Blueprint.General.BuildBones then
            self:SetupBuildBones()
        end
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.CYBRAN * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))

        local wepBp = self.Blueprint.Weapon
        self.normalRange = 22
        self.torpRange = 60
        for k, v in wepBp do
            if v.Label == 'RightRipper' then
                self.normalRange = v.MaxRadius
            elseif v.Label == 'Torpedo' then
                self.torpRange = v.MaxRadius
            end
        end
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RightRipper', true)
        self:SetWeaponEnabledByLabel('MLG', false)
        self:SetWeaponEnabledByLabel('Torpedo', false)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self:DisableUnitIntel('Enhancement', 'Sonar')
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self.Trash:Add(ForkThread(self.GiveInitialResources,self))
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        ACUUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

        local bp = self.Blueprint.Enhancements[enh]
        if enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            RemoveUnitEnhancement(self, 'Teleporter')
            RemoveUnitEnhancement(self, 'TeleporterRemove')
            self:RemoveCommandCap('RULEUCC_Teleport')
        elseif enh == 'StealthGenerator' then
            self:AddToggleCap('RULEUTC_StealthToggle')
            self.StealthEnh = true
            self:EnableUnitIntel('Enhancement', 'RadarStealth')
            self:EnableUnitIntel('Enhancement', 'SonarStealth')
            if not Buffs['CybranACUStealthBonus'] then
                BuffBlueprint {
                    Name = 'CybranACUStealthBonus',
                    DisplayName = 'CybranACUStealthBonus',
                    BuffType = 'ACUSTEALTHBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        }
                    },
                }
            end
            if not Buff.HasBuff(self, 'CybranACUStealthBonus') then
                Buff.ApplyBuff(self, 'CybranACUStealthBonus')
            end
        elseif enh == 'StealthGeneratorRemove' then
            self:RemoveToggleCap('RULEUTC_StealthToggle')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            self.StealthEnh = nil
            if Buff.HasBuff(self, 'CybranACUStealthBonus') then
                Buff.RemoveBuff(self, 'CybranACUStealthBonus')
            end
        elseif enh == 'FAF_SelfRepairSystem' then
            if not Buffs['CybranACURegenerateBonus'] then
                BuffBlueprint {
                    Name = 'CybranACURegenerateBonus',
                    DisplayName = 'CybranACURegenerateBonus',
                    BuffType = 'ACUNANO',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        }
                    },
                }
            end
            if not Buff.HasBuff(self, 'CybranACURegenerateBonus') then
                Buff.ApplyBuff(self, 'CybranACURegenerateBonus')
            end
        elseif enh == 'FAF_SelfRepairSystemRemove' then
            -- remove prerequisites
            self:RemoveToggleCap('RULEUTC_StealthToggle')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            self.StealthEnh = nil
            if Buff.HasBuff(self, 'CybranACUStealthBonus') then
                Buff.RemoveBuff(self, 'CybranACUStealthBonus')
            end

            -- remove repair system
            if Buff.HasBuff(self, 'CybranACURegenerateBonus') then
                Buff.RemoveBuff(self, 'CybranACURegenerateBonus')
            end
        elseif enh == 'CloakingGenerator' then
            if not bp then return end
            self:RemoveToggleCap('RULEUTC_StealthToggle')
            self:AddToggleCap('RULEUTC_CloakToggle')
            self.StealthEnh = nil
            self.CloakEnh = true
            self:EnableUnitIntel('Enhancement', 'Cloak')
            if not Buffs['CybranACUCloakBonus'] then
                BuffBlueprint {
                    Name = 'CybranACUCloakBonus',
                    DisplayName = 'CybranACUCloakBonus',
                    BuffType = 'ACUCLOAKBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if not Buff.HasBuff(self, 'CybranACUCloakBonus') then
                Buff.ApplyBuff(self, 'CybranACUCloakBonus')
            end
        elseif enh == 'CloakingGeneratorRemove' then
            -- remove prerequisites
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            self.StealthEnh = nil
            if Buff.HasBuff(self, 'CybranACUStealthBonus') then
                Buff.RemoveBuff(self, 'CybranACUStealthBonus')
            end
            if Buff.HasBuff(self, 'CybranACURegenerateBonus') then
                Buff.RemoveBuff(self, 'CybranACURegenerateBonus')
            end

            -- remove cloak
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('Enhancement', 'Cloak')
            self.CloakEnh = nil
            if Buff.HasBuff(self, 'CybranACUCloakBonus') then
                Buff.RemoveBuff(self, 'CybranACUCloakBonus')
            end
        elseif enh == 'ResourceAllocation' then
            local bpEcon = self.Blueprint.Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self.Blueprint.Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh =='AdvancedEngineering' then
            self.BuildBotTotal = 3
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['CybranACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'CybranACUT2BuildRate',
                    DisplayName = 'CybranACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
                            Mult = 1.0,
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
            Buff.ApplyBuff(self, 'CybranACUT2BuildRate')
        elseif enh == 'AdvancedEngineeringRemove' then
            self.BuildBotTotal = 2
            local buildRate = self.Blueprint.Economy.BuildRate
            if not buildRate then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.CYBRAN *
                (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'CybranACUT2BuildRate') then
                Buff.RemoveBuff(self, 'CybranACUT2BuildRate')
            end
        elseif enh =='T3Engineering' then
            self.BuildBotTotal = 4
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['CybranACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'CybranACUT3BuildRate',
                    DisplayName = 'CybranCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
                            Mult = 1.0,
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
            Buff.ApplyBuff(self, 'CybranACUT3BuildRate')
        elseif enh == 'T3EngineeringRemove' then

            self.BuildBotTotal = 2

            local buildRate = self.Blueprint.Economy.BuildRate
            if not buildRate then return end
            self:RestoreBuildRestrictions()
            if Buff.HasBuff(self, 'CybranACUT3BuildRate') then
                Buff.RemoveBuff(self, 'CybranACUT3BuildRate')
            end
            self:AddBuildRestriction(categories.CYBRAN * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        elseif enh =='CoolingUpgrade' then
            local wep = self:GetWeaponByLabel('RightRipper')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
            self.normalRange = bp.NewMaxRadius or 30
            wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
            local microwave = self:GetWeaponByLabel('MLG')
            microwave:ChangeMaxRadius(bp.NewMaxRadius or 30)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 30)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 30)
            if not (self.Layer == 'Seabed' and self:HasEnhancement('NaniteTorpedoTube')) then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
            end
        elseif enh == 'CoolingUpgradeRemove' then
            local wep = self:GetWeaponByLabel('RightRipper')
            local wepBp = self.Blueprint.Weapon
            for _, v in wepBp do
                if v.Label == 'RightRipper' then
                    local newRange = v.MaxRadius or 22
                    wep:ChangeRateOfFire(v.RateOfFire or 1)
                    wep:ChangeMaxRadius(newRange)
                    self.normalRange = newRange
                    self:GetWeaponByLabel('MLG'):ChangeMaxRadius(newRange)
                    self:GetWeaponByLabel('OverCharge'):ChangeMaxRadius(newRange)
                    self:GetWeaponByLabel('AutoOverCharge'):ChangeMaxRadius(newRange)
                    self.normalRange = newRange
                    if not (self.Layer == 'Seabed' and self:HasEnhancement('NaniteTorpedoTube')) then
                        self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
                    end
                    break
                end
            end
        elseif enh == 'MicrowaveLaserGenerator' then
            self:SetWeaponEnabledByLabel('MLG', true)
        elseif enh == 'MicrowaveLaserGeneratorRemove' then
            self:SetWeaponEnabledByLabel('MLG', false)
        elseif enh == 'NaniteTorpedoTube' then
            local enhbp = self.Blueprint.Enhancements[enh]
            self:SetWeaponEnabledByLabel('Torpedo', true)
            self:SetIntelRadius('Sonar', enhbp.NewSonarRadius or 60)
            self:EnableUnitIntel('Enhancement', 'Sonar')
            if self.Layer == 'Seabed' then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.torpRange)
            end
        elseif enh == 'NaniteTorpedoTubeRemove' then
            local bpIntel = self.Blueprint.Intel
            self:SetWeaponEnabledByLabel('Torpedo', false)
            self:SetIntelRadius('Sonar', bpIntel.SonarRadius or 26)
            self:DisableUnitIntel('Enhancement', 'Sonar')
            if self.Layer == 'Seabed' then
                self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange)
            end
        end
    end,

    -- Intel
    IntelEffects = {
        Cloak = {
            {
                Bones = {
                    'Head',
                    'Right_Turret',
                    'Left_Turret',
                    'Right_Arm_B01',
                    'Left_Arm_B01',
                    'Chest_Right',
                    'Chest_Left',
                    'Left_Leg_B01',
                    'Left_Leg_B02',
                    'Left_Foot_B01',
                    'Right_Leg_B01',
                    'Right_Leg_B02',
                    'Right_Foot_B01',
                },
                Scale = 1.0,
                Type = 'Cloak01',
            },
        },
        Field = {
            {
                Bones = {
                    'Head',
                    'Right_Turret',
                    'Left_Turret',
                    'Right_Arm_B01',
                    'Left_Arm_B01',
                    'Chest_Right',
                    'Chest_Left',
                    'Left_Leg_B01',
                    'Left_Leg_B02',
                    'Left_Foot_B01',
                    'Right_Leg_B01',
                    'Right_Leg_B02',
                    'Right_Foot_B01',
                },
                Scale = 1.6,
                Type = 'Cloak01',
            },
        },
    },

    OnIntelEnabled = function(self, intel)
        ACUUnit.OnIntelEnabled(self, intel)
        if self.CloakEnh and self:IsIntelEnabled('Cloak') then
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['CloakingGenerator'].MaintenanceConsumptionPerSecondEnergy
                or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        elseif self.StealthEnh and self:IsIntelEnabled('RadarStealth') and self:IsIntelEnabled('SonarStealth') then
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['StealthGenerator'].MaintenanceConsumptionPerSecondEnergy
                or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Field, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        end
    end,

    OnIntelDisabled = function(self, intel)
        ACUUnit.OnIntelDisabled(self, intel)
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        if self.CloakEnh and not self:IsIntelEnabled('Cloak') then
            self:SetMaintenanceConsumptionInactive()
        elseif self.StealthEnh and not self:IsIntelEnabled('RadarStealth') and not self:IsIntelEnabled('SonarStealth') then
            self:SetMaintenanceConsumptionInactive()
        end
    end,

    OnLayerChange = function(self, new, old)
        ACUUnit.OnLayerChange(self, new, old)
        if self:GetWeaponByLabel('DummyWeapon') == nil then return end
        if new == "Seabed" and self:HasEnhancement('NaniteTorpedoTube') then
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.torpRange or 60)
        else
            self:GetWeaponByLabel('DummyWeapon'):ChangeMaxRadius(self.normalRange or 22)
        end
    end,
}

TypeClass = URL0001
