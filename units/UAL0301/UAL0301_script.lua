-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0301/UAL0301_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Aeon Sub Commander Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
---@alias AeonSCUEnhancementBuffType
---| "SCUBUILDRATE"
---| "SCUREGENRATE"

---@alias AeonSCUEnhancementBuffName          # BuffType
---| "AeonSCUBuildRate"                       # SCUBUILDRATE
---| "AeonSCURegenRate"                       # SCUREGENRATE

local CommandUnit = import("/lua/defaultunits.lua").CommandUnit
local AWeapons = import("/lua/aeonweapons.lua")
local ADFReactonCannon = AWeapons.ADFReactonCannon
local SCUDeathWeapon = import("/lua/sim/defaultweapons.lua").SCUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local Buff = import("/lua/sim/buff.lua")

---@class UAL0301 : CommandUnit
UAL0301 = ClassUnit(CommandUnit) {
    Weapons = {
        RightReactonCannon = ClassWeapon(ADFReactonCannon) {},
        DeathWeapon = ClassWeapon(SCUDeathWeapon) {},
    },

    ---@param self UAL0301
    __init = function(self)
        CommandUnit.__init(self, 'RightReactonCannon')
    end,

    ---@param self UAL0301
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        CommandUnit.OnStopBuild(self, unitBeingBuilt)
        self:BuildManipulatorSetEnabled(false)
        self.BuildArmManipulator:SetPrecedence(0)
        self:SetWeaponEnabledByLabel('RightReactonCannon', true)
        self:GetWeaponManipulatorByLabel('RightReactonCannon'):SetHeadingPitch(self.BuildArmManipulator:GetHeadingPitch())
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil
        self.BuildingUnit = false
    end,

    ---@psaram self UAL0301
    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        self:HideBone('Turbine', true)
        self:SetupBuildBones()
    end,

    ---@param self UAL0301
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    -- ============================================================================================================================================
    -- ENHANCEMENTS

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShield = function(self, bp)
        self:AddToggleCap('RULEUTC_ShieldToggle')
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
        self:CreateShield(bp)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementShieldHeavy = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementShieldHeavyRemove = function(self, bp)
        self:DestroyShield()
        self:SetMaintenanceConsumptionInactive()
        self:RemoveToggleCap('RULEUTC_ShieldToggle')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementEngineeringFocusModule = function(self, bp)
        if not Buffs['AeonSCUBuildRate'] then
            BuffBlueprint {
                Name = 'AeonSCUBuildRate',
                DisplayName = 'AeonSCUBuildRate',
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
        Buff.ApplyBuff(self, 'AeonSCUBuildRate')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementEngineeringFocusModuleRemove = function(self, bp)
        if Buff.HasBuff(self, 'AeonSCUBuildRate') then
            Buff.RemoveBuff(self, 'AeonSCUBuildRate')
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementSystemIntegrityCompensator = function(self, bp)
        if not Buffs['AeonSCURegenRate'] then
            BuffBlueprint {
                Name = 'AeonSCURegenRate',
                DisplayName = 'AeonSCURegenRate',
                BuffType = 'SCUREGENRATE',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    Regen = {
                        Add = bp.NewRegenRate - self.Blueprint.Defense.RegenRate,
                        Mult = 1,
                    },
                },
            }
        end
        Buff.ApplyBuff(self, 'AeonSCURegenRate')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSystemIntegrityCompensatorRemove = function(self, bp)
        if Buff.HasBuff(self, 'AeonSCURegenRate') then
            Buff.RemoveBuff(self, 'AeonSCURegenRate')
        end
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSacrifice = function(self, bp)
        self:AddCommandCap('RULEUCC_Sacrifice')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement unused
    ProcessEnhancementSacrificeRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Sacrifice')
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressant = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:AddDamageMod(bp.NewDamageMod or 0)
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 40)
    end,

    ---@param self UAL0301
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementStabilitySuppressantRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('RightReactonCannon')
        wep:AddDamageMod(-self.Blueprint.Enhancements['RightReactonCannon'].NewDamageMod)
        wep:AddDamageRadiusMod(bp.NewDamageRadiusMod or 0)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 30)
    end,

    ---@param self UAL0301
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

TypeClass = UAL0301
