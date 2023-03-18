-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0301/URL0301_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Sub Commander Script
-- Copyright Š 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias CybranSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUCLOAKBONUS"
---| "SCUREGENERATEBONUS"

---@alias CybranSCUEnhancementBuffName        # BuffType
---| "CybranSCUBuildRate"                     # SCUBUILDRATE
---| "CybranSCUCloakBonus"                    # SCUCLOAKBONUS
---| "CybranSCURegenerateBonus"               # SCUREGENERATEBONUS


local CybranUnits = import("/lua/cybranunits.lua")
local CCommandUnit = CybranUnits.CCommandUnit
local CWeapons = import("/lua/cybranweapons.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")
local CAAMissileNaniteWeapon = CWeapons.CAAMissileNaniteWeapon
local CDFLaserDisintegratorWeapon = CWeapons.CDFLaserDisintegratorWeapon02
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon

---@class URL0301 : CCommandUnit
URL0301 = ClassUnit(CCommandUnit) {
    LeftFoot = 'Left_Foot02',
    RightFoot = 'Right_Foot02',

    Weapons = {
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
        RightDisintegrator = ClassWeapon(CDFLaserDisintegratorWeapon) {
            OnCreate = function(self)
                CDFLaserDisintegratorWeapon.OnCreate(self)
                self:DisableBuff('STUN')
            end,
        },
        NMissile = ClassWeapon(CAAMissileNaniteWeapon) {},
    },

    -- Creation
    OnCreate = function(self)
        CCommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('AA_Gun', true)
        self:HideBone('Power_Pack', true)
        self:HideBone('Rez_Protocol', true)
        self:HideBone('Torpedo', true)
        self:HideBone('Turbine', true)
        self:SetWeaponEnabledByLabel('NMissile', false)
        if self.Blueprint.General.BuildBones then
            self:SetupBuildBones()
        end
        self.IntelButtonSet = true
    end,

    __init = function(self)
        CCommandUnit.__init(self, 'RightDisintegrator')
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CCommandUnit.OnStopBeingBuilt(self, builder, layer)
        self:BuildManipulatorSetEnabled(false)
        self:SetMaintenanceConsumptionInactive()
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self.LeftArmUpgrade = 'EngineeringArm'
        self.RightArmUpgrade = 'Disintegrator'
    end,

    -- Enhancements
    CreateEnhancement = function(self, enh)
        CCommandUnit.CreateEnhancement(self, enh)
        local bp = self.Blueprint.Enhancements[enh]
        if not bp then return end
        if enh == 'CloakingGenerator' then
            self.StealthEnh = false
            self.CloakEnh = true
            self:EnableUnitIntel('Enhancement', 'Cloak')
            if not Buffs['CybranSCUCloakBonus'] then
                BuffBlueprint {
                    Name = 'CybranSCUCloakBonus',
                    DisplayName = 'CybranSCUCloakBonus',
                    BuffType = 'SCUCLOAKBONUS',
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
            if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
                Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
            end
            Buff.ApplyBuff(self, 'CybranSCUCloakBonus')
        elseif enh == 'CloakingGeneratorRemove' then
            self:DisableUnitIntel('Enhancement', 'Cloak')
            self.StealthEnh = false
            self.CloakEnh = false
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
                Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
            end
        elseif enh == 'StealthGenerator' then
            self:AddToggleCap('RULEUTC_CloakToggle')
            if self.IntelEffectsBag then
                EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
                self.IntelEffectsBag = nil
            end
            self.CloakEnh = false
            self.StealthEnh = true
            self:EnableUnitIntel('Enhancement', 'RadarStealth')
            self:EnableUnitIntel('Enhancement', 'SonarStealth')
        elseif enh == 'StealthGeneratorRemove' then
            self:RemoveToggleCap('RULEUTC_CloakToggle')
            self:DisableUnitIntel('Enhancement', 'RadarStealth')
            self:DisableUnitIntel('Enhancement', 'SonarStealth')
            self.StealthEnh = false
            self.CloakEnh = false
        elseif enh == 'NaniteMissileSystem' then
            self:ShowBone('AA_Gun', true)
            self:SetWeaponEnabledByLabel('NMissile', true)
        elseif enh == 'NaniteMissileSystemRemove' then
            self:HideBone('AA_Gun', true)
            self:SetWeaponEnabledByLabel('NMissile', false)
        elseif enh == 'SelfRepairSystem' then
            CCommandUnit.CreateEnhancement(self, enh)
            local bpRegenRate = self.Blueprint.Enhancements.SelfRepairSystem.NewRegenRate or 0
            if not Buffs['CybranSCURegenerateBonus'] then
                BuffBlueprint {
                    Name = 'CybranSCURegenerateBonus',
                    DisplayName = 'CybranSCURegenerateBonus',
                    BuffType = 'SCUREGENERATEBONUS',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        Regen = {
                            Add = bpRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
                Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
            end
            Buff.ApplyBuff(self, 'CybranSCURegenerateBonus')
        elseif enh == 'SelfRepairSystemRemove' then
            CCommandUnit.CreateEnhancement(self, enh)
            if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
                Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
            end
        elseif enh == 'ResourceAllocation' then
            local bpEcon = self.Blueprint.Economy
            self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self.Blueprint.Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'Switchback' then
            self.BuildBotTotal = 4
            if not Buffs['CybranSCUBuildRate'] then
                BuffBlueprint {
                    Name = 'CybranSCUBuildRate',
                    DisplayName = 'CybranSCUBuildRate',
                    BuffType = 'SCUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add = bp.NewBuildRate - self.Blueprint.Economy.BuildRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'CybranSCUBuildRate')
        elseif enh == 'SwitchbackRemove' then
            self.BuildBotTotal = 3
            if Buff.HasBuff(self, 'CybranSCUBuildRate') then
                Buff.RemoveBuff(self, 'CybranSCUBuildRate')
            end
        elseif enh == 'FocusConvertor' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:AddDamageMod(bp.NewDamageMod or 0)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        elseif enh == 'FocusConvertorRemove' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:AddDamageMod(-self.Blueprint.Enhancements['FocusConvertor'].NewDamageMod)
            wep:ChangeMaxRadius(self.Blueprint.Weapon[1].MaxRadius or 25)
        elseif enh == 'EMPCharge' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:ReEnableBuff('STUN')
        elseif enh == 'EMPChargeRemove' then
            local wep = self:GetWeaponByLabel('RightDisintegrator')
            wep:DisableBuff('STUN')
        end
    end,

    IntelEffects = {
        Cloak = {
            {
                Bones = {
                    'Head',
                    'Right_Elbow',
                    'Left_Elbow',
                    'Right_Arm01',
                    'Left_Shoulder',
                    'Torso',
                    'URL0301',
                    'Left_Thigh',
                    'Left_Knee',
                    'Left_Leg',
                    'Right_Thigh',
                    'Right_Knee',
                    'Right_Leg',
                },
                Scale = 1.0,
                Type = 'Cloak01',
            },
        },
        Field = {
            {
                Bones = {
                    'Head',
                    'Right_Elbow',
                    'Left_Elbow',
                    'Right_Arm01',
                    'Left_Shoulder',
                    'Torso',
                    'URL0301',
                    'Left_Thigh',
                    'Left_Knee',
                    'Left_Leg',
                    'Right_Thigh',
                    'Right_Knee',
                    'Right_Leg',
                },
                Scale = 1.6,
                Type = 'Cloak01',
            },
        },
    },

    OnIntelEnabled = function(self, intel)
        CCommandUnit.OnIntelEnabled(self, intel)
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
        CCommandUnit.OnIntelDisabled(self, intel)
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
}

TypeClass = URL0301
