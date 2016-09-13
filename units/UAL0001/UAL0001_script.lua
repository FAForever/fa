-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/UAL0001/UAL0001_script.lua
-- **  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- **
-- **  Summary  :  Aeon Commander Script
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local ACUUnit = import('/lua/defaultunits.lua').ACUUnit
local AWeapons = import('/lua/aeonweapons.lua')
local ADFDisruptorCannonWeapon = AWeapons.ADFDisruptorCannonWeapon
local DeathNukeWeapon = import('/lua/sim/defaultweapons.lua').DeathNukeWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local ADFOverchargeWeapon = AWeapons.ADFOverchargeWeapon
local ADFChronoDampener = AWeapons.ADFChronoDampener
local Buff = import('/lua/sim/Buff.lua')

UAL0001 = Class(ACUUnit) {
    Weapons = {
        DeathWeapon = Class(DeathNukeWeapon) {},
        RightDisruptor = Class(ADFDisruptorCannonWeapon) {},
        ChronoDampener = Class(ADFChronoDampener) {},
        OverCharge = Class(ADFOverchargeWeapon) {},
        AutoOverCharge = Class(ADFOverchargeWeapon) {},
    },

    __init = function(self)
        ACUUnit.__init(self, 'RightDisruptor')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetWeaponEnabledByLabel('ChronoDampener', false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)        
        self:HideBone('Left_Upgrade', true)            
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction( categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        ACUUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetWeaponEnabledByLabel('RightDisruptor', true)
        self:ForkThread(self.GiveInitialResources)
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateAeonCommanderBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,  

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        -- Resource Allocation
        if enh == 'ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvanced' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvancedRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        -- Shields
        elseif enh == 'Shield' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
            self:SetMaintenanceConsumptionActive()
            self:CreateShield(bp)
        elseif enh == 'ShieldRemove' then
            self:DestroyShield()
            self:SetMaintenanceConsumptionInactive()
            self:RemoveToggleCap('RULEUTC_ShieldToggle')
        elseif enh == 'ShieldHeavy' then
            self:AddToggleCap('RULEUTC_ShieldToggle')
            self:ForkThread(self.CreateHeavyShield, bp)
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
        elseif enh == 'ChronoDampenerRemove' then
            self:SetWeaponEnabledByLabel('ChronoDampener', false)
        -- T2 Engineering
        elseif enh =='AdvancedEngineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
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
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
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
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        elseif enh =='AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.AEON * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'AeonACUT2BuildRate' ) then
                Buff.RemoveBuff( self, 'AeonACUT2BuildRate' )
         end
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        -- T3 Engineering
        elseif enh =='T3Engineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
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
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
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
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        elseif enh =='T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.AEON * ( categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'AeonACUT3BuildRate' ) then
                Buff.RemoveBuff( self, 'AeonACUT3BuildRate' )
         end
        -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
        self:updateBuildRestrictions()
        -- Crysalis Beam
        elseif enh == 'CrysalisBeam' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'CrysalisBeamRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bpDisrupt or 22)
        -- Heat Sink Augmentation
        elseif enh == 'HeatSink' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
        elseif enh == 'HeatSinkRemove' then
            local wep = self:GetWeaponByLabel('RightDisruptor')
            local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisrupt or 1)
        -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 26)
      end
    end,

    CreateHeavyShield = function(self, bp)
        WaitTicks(1)
        self:CreateShield(bp)
        self:SetEnergyMaintenanceConsumptionOverride(bp.MaintenanceConsumptionPerSecondEnergy or 0)
        self:SetMaintenanceConsumptionActive()
    end
}

TypeClass = UAL0001
