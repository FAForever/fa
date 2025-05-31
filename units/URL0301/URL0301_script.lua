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
---@field HasStealthEnh? boolean
---@field HasCloakEnh? boolean
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

    ---@param self URL0301
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
    end,

    ---@param self URL0301
    __init = function(self)
        CCommandUnit.__init(self, 'RightDisintegrator')
    end,

    ---@param self URL0301
    ---@param builder Unit
    ---@param layer Layer
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


    -- =====================================================================================================================4
    -- ENHANCEMENTS

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCloakingGenerator = function (self, bp)
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:AddToggleCap('RULEUTC_CloakToggle')
        self.HasStealthEnh = false
        self.HasCloakEnh = true
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
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCloakingGeneratorRemove = function (self, bp)
        -- remove prerequisites
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')

        -- remove cloak
        self:DisableUnitIntel('Enhancement', 'Cloak')
        self.HasCloakEnh = false
        self:RemoveToggleCap('RULEUTC_CloakToggle')
        if Buff.HasBuff(self, 'CybranSCUCloakBonus') then
            Buff.RemoveBuff(self, 'CybranSCUCloakBonus')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGenerator = function (self, bp)
        self:AddToggleCap('RULEUTC_StealthToggle')
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        self.HasStealthEnh = true
        self:EnableUnitIntel('Enhancement', 'RadarStealth')
        self:EnableUnitIntel('Enhancement', 'SonarStealth')
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStealthGeneratorRemove = function (self, bp)
        self:RemoveToggleCap('RULEUTC_StealthToggle')
        self:DisableUnitIntel('Enhancement', 'RadarStealth')
        self:DisableUnitIntel('Enhancement', 'SonarStealth')
        self.HasStealthEnh = false
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystem = function(self, bp)
        self:ShowBone('AA_Gun', true)
        self:SetWeaponEnabledByLabel('NMissile', true)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementNaniteMissileSystemRemove = function(self, bp)
        self:HideBone('AA_Gun', true)
        self:SetWeaponEnabledByLabel('NMissile', false)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystem = function(self, bp)
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
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSelfRepairSystemRemove = function(self, bp)
        if Buff.HasBuff(self, 'CybranSCURegenerateBonus') then
            Buff.RemoveBuff(self, 'CybranSCURegenerateBonus')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSwitchback = function(self, bp)
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
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSwitchbackRemove = function(self, bp)
        self.BuildBotTotal = 3
        if Buff.HasBuff(self, 'CybranSCUBuildRate') then
            Buff.RemoveBuff(self, 'CybranSCUBuildRate')
        end
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertor = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:AddDamageMod(bp.NewDamageMod or 0)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFocusConvertorRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:AddDamageMod(-self.Blueprint.Enhancements['FocusConvertor'].NewDamageMod)
        wep:ChangeMaxRadius(self.Blueprint.Weapon[1].MaxRadius or 25)
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEMPCharge = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:ReEnableBuff('STUN')
    end,

    ---@param self URL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEMPChargeRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisintegrator')
        wep:DisableBuff('STUN')
    end,

    ---@param self URL0301
    ---@param enh Enhancement
    CreateEnhancement = function(self, enh)
        CCommandUnit.CreateEnhancement(self, enh)
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

    ---@param self URL0301
    ---@param intel IntelType
    OnIntelEnabled = function(self, intel)
        CCommandUnit.OnIntelEnabled(self, intel)
        if self.HasCloakEnh and self:IsIntelEnabled('Cloak') then
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['CloakingGenerator'].MaintenanceConsumptionPerSecondEnergy
                or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        elseif self.HasStealthEnh and self:IsIntelEnabled('RadarStealth') and self:IsIntelEnabled('SonarStealth') then
            self:SetEnergyMaintenanceConsumptionOverride(self.Blueprint.Enhancements['StealthGenerator'].MaintenanceConsumptionPerSecondEnergy
                or 0)
            self:SetMaintenanceConsumptionActive()
            if not self.IntelEffectsBag then
                self.IntelEffectsBag = {}
                self:CreateTerrainTypeEffects(self.IntelEffects.Field, 'FXIdle', self.Layer, nil, self.IntelEffectsBag)
            end
        end
    end,

    ---@param self URL0301
    ---@param intel IntelType
    OnIntelDisabled = function(self, intel)
        CCommandUnit.OnIntelDisabled(self, intel)
        if self.IntelEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'IntelEffectsBag')
            self.IntelEffectsBag = nil
        end
        if self.HasCloakEnh and not self:IsIntelEnabled('Cloak') then
            self:SetMaintenanceConsumptionInactive()
        elseif self.HasStealthEnh and not self:IsIntelEnabled('RadarStealth') and not self:IsIntelEnabled('SonarStealth') then
            self:SetMaintenanceConsumptionInactive()
        end
    end,
}

TypeClass = URL0301
