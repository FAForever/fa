-----------------------------------------------------------------
-- **
-- File     :  /cdimage/units/UAL0001/UAL0001_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- **
-- Summary  :  Aeon Commander Script
-- **
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias AeonACUEnhancementBuffType
---| "DamageStabilization"
---| "ACUBUILDRATE"

---@alias AeonACUEnhancementBuffName          # BuffType
---| "AeonACUChronoDampener"                  # DamageStabilization
---| "AeonACUT2BuildRate"                     # ACUBUILDRATE
---| "AeonACUT3BuildRate"                     # ACUBUILDRATE


local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local AWeapons = import("/lua/aeonweapons.lua")
local ADFDisruptorCannonWeapon = AWeapons.ADFDisruptorCannonWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local ADFOverchargeWeapon = AWeapons.ADFOverchargeWeapon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local Buff = import("/lua/sim/buff.lua")

---@class UAL0001 : ACUUnit
UAL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        RightDisruptor = ClassWeapon(ADFDisruptorCannonWeapon) {},
        ChronoDampener = ClassWeapon(ADFChronoDampener) {},
        OverCharge = ClassWeapon(ADFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(ADFOverchargeWeapon) {},
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightDisruptor')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        -- Set initial range of Chrono here so that max range can be displayed in the UI
        local bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bpDisrupt)
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('RightDisruptor', true)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
        self:ForkThread(self.GiveInitialResources)
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,


    ---------------------------------------------------------------------------
    --#region Enhancements

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        if not bp then return end
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvanced = function(self, bp)
        if not bp then return end
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvancedRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement # This enhancement blueprint also includes the fields from `UnitBlueprintDefenseShield`
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
        self:CreateShield(bp)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement # This enhancement blueprint also includes the fields from `UnitBlueprintDefenseShield`
    ProcessEnhancementShieldHeavy = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:ForkThread(self.CreateHeavyShield, bp)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldHeavyRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementChronoDampener = function(self, bp)
        self:SetWeaponEnabledByLabel('ChronoDampener', true)
        if not Buffs['AeonACUChronoDampener'] then
            BuffBlueprint {
                Name = 'AeonACUChronoDampener',
                DisplayName = 'AeonACUChronoDampener',
                BuffType = 'DamageStabilization',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.NewHealth,
                        Mult = 1.0,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'AeonACUChronoDampener')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementChronoDampenerRemove = function(self, bp)
        if Buff.HasBuff(self, 'AeonACUChronoDampener') then
            Buff.RemoveBuff(self, 'AeonACUChronoDampener')
        end
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineering = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)

        if not Buffs['AeonACUT2BuildRate'] then
            BuffBlueprint {
                Name = 'AeonACUT2BuildRate',
                DisplayName = 'AeonACUT2BuildRate',
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
        Buff.ApplyBuff(self, 'AeonACUT2BuildRate')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineeringRemove = function(self, bp)
        self:RestoreBuildRestrictions()
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        if Buff.HasBuff(self, 'AeonACUT2BuildRate') then
            Buff.RemoveBuff(self, 'AeonACUT2BuildRate')
        end
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3Engineering = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['AeonACUT3BuildRate'] then
            BuffBlueprint {
                Name = 'AeonACUT3BuildRate',
                DisplayName = 'AeonCUT3BuildRate',
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
        Buff.ApplyBuff(self, 'AeonACUT3BuildRate')
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3EngineeringRemove = function(self, bp)
        self:RestoreBuildRestrictions()
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        if Buff.HasBuff(self, 'AeonACUT3BuildRate') then
            Buff.RemoveBuff(self, 'AeonACUT3BuildRate')
        end
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCrysalisBeam = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bp.NewMaxRadius or 30)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 30)
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bp.NewMaxRadius or 30)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementCrysalisBeamRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        local bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        wep:ChangeMaxRadius(bpDisrupt or 22)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bpDisrupt or 22)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bpDisrupt or 22)
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bpDisrupt or 22)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFAF_CrysalisBeamAdvanced = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bp.NewMaxRadius or 35)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 35)
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bp.NewMaxRadius or 35)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementFAF_CrysalisBeamAdvancedRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        local bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        wep:ChangeMaxRadius(bpDisrupt or 22)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bpDisrupt or 22)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bpDisrupt or 22)
        local cd = self:GetWeaponByLabel('ChronoDampener')
        cd:ChangeMaxRadius(bpDisrupt or 22)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHeatSink = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementHeatSinkRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightDisruptor')
        local bpDisrupt = self.Blueprint.Weapon[1].RateOfFire
        wep:ChangeRateOfFire(bpDisrupt or 1)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEnhancedSensors = function(self, bp)
        self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
        self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
    end,

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEnhancedSensorsRemove = function(self, bp)
        local bpIntel = self.Blueprint.Intel
        self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
        self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
    end,

    ---@param self UAL0001
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

    ---@param self UAL0001
    ---@param bp UnitBlueprintEnhancement # This enhancement blueprint also includes the fields from `UnitBlueprintDefenseShield`
    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end

    --#endregion
}

TypeClass = UAL0001
