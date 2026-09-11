-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Sub Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias SeraphimSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUUPGRADEDMG"

---@alias SeraphimSCUEnhancementBuffName      # BuffType
---| "SeraphimSCUDamageStabilization"         # SCUUPGRADEDMG
---| "SeraphimSCUBuildRate"                   # SCUBUILDRATE


local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local SWeapons = import("/lua/seraphimweapons.lua")
local Buff = import("/lua/sim/buff.lua")
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher

---@class XSL0301 : CommandUnit
XSL0301 = ClassUnit(CommandUnit) {
    Weapons = {
        LightChronatronCannon = ClassWeapon(SDFLightChronotronCannonWeapon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
        OverCharge = ClassWeapon(SDFOverChargeWeapon) {},
        AutoOverCharge = ClassWeapon(SDFOverChargeWeapon) {},
        Missile = ClassWeapon(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
    },

    ---@param self XSL0301
    __init = function(self)
        CommandUnit.__init(self, 'LightChronatronCannon')
    end,

    ---@param self XSL0301
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Back_Upgrade', true)
        self:SetupBuildBones()
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
    end,

    ---@param self XSL0301
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        CommandUnit.StartBeingBuiltEffects(self, builder, layer)
        self.Trash:Add(ForkThread(EffectUtil.CreateSeraphimBuildThread, self, builder, self.OnBeingBuiltEffectsBag, 2))
    end,

    ---@param self XSL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    -- =====================================================================================================================
    -- EMHANCEMENTS

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementMissile = function(self, bp)
        self:AddCommandCap('RULEUCC_Tactical')
        self:AddCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', true)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementMissileRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', false)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
        self:CreateShield(bp)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementOvercharge = function(self, bp)
        self:AddCommandCap('RULEUCC_Overcharge')
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = false
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = false
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementOverchargeRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Overcharge')
        self:SetWeaponEnabledByLabel('OverCharge', false)
        self:SetWeaponEnabledByLabel('AutoOverCharge', false)
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEngineeringThroughput = function(self, bp)
        if not Buffs['SeraphimSCUBuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimSCUBuildRate',
                DisplayName = 'SeraphimSCUBuildRate',
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
        Buff.ApplyBuff(self, 'SeraphimSCUBuildRate')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringThroughputRemove = function(self, bp)
        if Buff.HasBuff(self, 'SeraphimSCUBuildRate') then
            Buff.RemoveBuff(self, 'SeraphimSCUBuildRate')
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilization = function (self, bp)
        if not Buffs['SeraphimSCUDamageStabilization'] then
            BuffBlueprint {
                Name = 'SeraphimSCUDamageStabilization',
                DisplayName = 'SeraphimSCUDamageStabilization',
                BuffType = 'SCUUPGRADEDMG',
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
                    },
                },
            }
        end
        if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
        end
        Buff.ApplyBuff(self, 'SeraphimSCUDamageStabilization')
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementDamageStabilizationRemove = function (self, bp)
        if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
        end
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEnhancedSensors = function(self, bp)
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        local wep = self:GetWeaponByLabel('OverCharge')
        wep:ChangeMaxRadius(35)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(35)
    end,

    ---@param self XSL0301
    ---@param bp UnitBlueprintEnhancement 
    ProcessEnhancementEnhancedSensorsRemove = function(self, bp)
        local bpIntel = self.Blueprint.Intel
        self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
        self:SetIntelRadius('Omni', bpIntel.OmniRadius or 16)
        local wep = self:GetWeaponByLabel('LightChronatronCannon')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        local wep = self:GetWeaponByLabel('OverCharge')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 25)
    end,

    ---@param self XSL0301
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
}

TypeClass = XSL0301
