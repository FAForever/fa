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
local DeathNukeWeapon = import("/lua/sim/defaultweapons.lua").DeathNukeWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local ADFOverchargeWeapon = AWeapons.ADFOverchargeWeapon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local Buff = import("/lua/sim/buff.lua")

-- upvalue for performance
local ParseEntityCategory = ParseEntityCategory
local BuffBlueprint = BuffBlueprint
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks



---@class UAL0001 : ACUUnit
UAL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(DeathNukeWeapon) {},
        RightDisruptor = ClassWeapon(ADFDisruptorCannonWeapon) {},
        ChronoDampener = ClassWeapon(ADFChronoDampener) {},
        OverCharge = ClassWeapon(ADFOverchargeWeapon) {},
        AutoOverCharge = ClassWeapon(ADFOverchargeWeapon) {},
    },

    ---@param self UAL0001
    __init = function(self)
        ACUUnit.__init(self, 'RightDisruptor')
    end,

    ---@param self UAL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    ---@param self UAL0001
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        local trash = self.Trash

        self:SetWeaponEnabledByLabel('RightDisruptor', true)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
        TrashBagAdd(trash,ForkThread(self.GiveInitialResources,self))
    end,

    ---@param self UAL0001
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateAeonCommanderBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    ---@param self UAL0001
    ---@param enh string
    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        local bp = self.Blueprint
        local bpEnh = bp.Enhancements[enh]
        local bpEcon = bp.Economy
        local bpBr = bpEcon.BuildRate
        local bpRange = bp.Weapon[1].MaxRadius
        local bpIntel = bp.Intel
        local trash = self.Trash


        -- Resource Allocation
        if enh == 'ResourceAllocation' then
            if not bpEnh then return end
            self:SetProductionPerSecondEnergy((bpEnh.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bpEnh.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationRemove' then
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvanced' then
            if not bpEnh then return end
            self:SetProductionPerSecondEnergy((bpEnh.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
            self:SetProductionPerSecondMass((bpEnh.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
        elseif enh == 'ResourceAllocationAdvancedRemove' then
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        -- Shields
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bpEnh.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bpEnh)
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldHeavy' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            TrashBagAdd(trash,ForkThread(self.CreateHeavyShield,self, bpEnh))
        elseif enh == 'ShieldHeavyRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        -- Teleporter
        elseif enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        -- Chrono Dampener
        elseif enh == 'ChronoDampener' then
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
                            Add = bpEnh.NewHealth,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUChronoDampener')
        elseif enh == 'ChronoDampenerRemove' then
            if Buff.HasBuff(self, 'AeonACUChronoDampener') then
                Buff.RemoveBuff(self, 'AeonACUChronoDampener')
            end
            self:SetWeaponEnabledByLabel('ChronoDampener', false)
        -- T2 Engineering
        elseif enh =='AdvancedEngineering' then
            if not bpEnh then return end
            local cat = ParseEntityCategory(bpEnh.BuildableCategoryAdds)
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
                            Add =  bpEnh.NewBuildRate - bpEcon.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bpEnh.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bpEnh.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUT2BuildRate')
        elseif enh =='AdvancedEngineeringRemove' then
            if not bpBr then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT2BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT2BuildRate')
         end
        -- T3 Engineering
        elseif enh =='T3Engineering' then
            if not bpEnh then return end
            local cat = ParseEntityCategory(bpEnh.BuildableCategoryAdds)
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
                            Add =  bpEnh.NewBuildRate - bpEcon.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bpEnh.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bpEnh.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'AeonACUT3BuildRate')
        elseif enh =='T3EngineeringRemove' then
            if not bpBr then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction(categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
            if Buff.HasBuff(self, 'AeonACUT3BuildRate') then
                Buff.RemoveBuff(self, 'AeonACUT3BuildRate')
         end
        -- Crysalis Beam
        elseif enh == 'CrysalisBeam' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bpEnh.NewMaxRadius or 30)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpEnh.NewMaxRadius or 30)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpEnh.NewMaxRadius or 30)
        elseif enh == 'CrysalisBeamRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bpRange or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpRange or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpRange or 22)
        -- Advanced Cryslised Beam
        elseif enh == 'FAF_CrysalisBeamAdvanced' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bpEnh.NewMaxRadius or 35)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpEnh.NewMaxRadius or 35)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpEnh.NewMaxRadius or 35)
        elseif enh == 'FAF_CrysalisBeamAdvancedRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bpRange or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpRange or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpRange or 22)
        -- Heat Sink Augmentation
        elseif enh == 'HeatSink' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeRateOfFire(bpEnh.NewRateOfFire or 2)
        elseif enh == 'HeatSinkRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeRateOfFire(bpRange or 1)
        -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            self:SetIntelRadius('Vision', bpEnh.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bpEnh.NewOmniRadius or 104)
        elseif enh == 'EnhancedSensorsRemove' then
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
      end
    end,

    ---@param self UAL0001
    ---@param bp Blueprint
    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end
}

TypeClass = UAL0001
