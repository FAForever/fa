-- ****************************************************************************
-- **
-- **  File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- **  Author(s):  Jessica St. Croix, Gordon Duclos
-- **
-- **  Summary  :  Seraphim Sub Commander Script
-- **
-- **  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local AWeapons = import('/lua/aeonweapons.lua')
local SWeapons = import('/lua/seraphimweapons.lua')
local Buff = import('/lua/sim/Buff.lua')

local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher
local AIFCommanderDeathWeapon = AWeapons.AIFCommanderDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')

XSL0301 = Class(CommandUnit) {
    Weapons = {
        LightChronatronCannon = Class(SDFLightChronotronCannonWeapon) {},
        DeathWeapon = Class(AIFCommanderDeathWeapon) {},
        OverCharge = Class(SDFOverChargeWeapon) {},
        Missile = Class(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
    },

    __init = function(self)
        CommandUnit.__init(self, 'LightChronatronCannon')
    end,

    OnCreate = function(self)
        CommandUnit.OnCreate(self)
        self:SetCapturable(false)
        -- self:HideBone('Turbine', true)
        self:HideBone('Back_Upgrade', true)
        self:SetupBuildBones()
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,

    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        -- Teleporter
        if enh == 'Teleporter' then
            -- WHY IS THIS UNUSED. WHAT HAVE YOU DONE ZEP.
            WarpInEffectThread = function(self)
                self:PlayUnitSound('CommanderArrival')
                self:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
                WaitSeconds(2.1)
                self:ShowBone(0, true)
                self:HideBone('Back_Upgrade', true)
                self:HideBone('Right_Upgrade', true)
                self:HideBone('Left_Upgrade', true)
                self:SetUnSelectable(false)
                self:SetBusy(false)
                self:SetBlockCommandQueue(false)

                local totalBones = self:GetBoneCount() - 1
                local army = self:GetArmy()
                for k, v in EffectTemplate.UnitTeleportSteam01 do
                    for bone = 1, totalBones do
                        CreateAttachedEmitter(self,bone,army, v)
                    end
                end

                WaitSeconds(6)
            end,
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        -- Missile
        elseif enh == 'Missile' then
            self:AddCommandCap('RULEUCC_Tactical')
            self:AddCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', true)
        elseif enh == 'MissileRemove' then
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', false)
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
        -- Overcharge
        elseif enh == 'Overcharge' then
      	    self:AddCommandCap('RULEUCC_Overcharge')
      	    self:SetWeaponEnabledByLabel('OverCharge', true)
        elseif enh == 'OverchargeRemove' then
      	    self:RemoveCommandCap('RULEUCC_Overcharge')
      	    self:SetWeaponEnabledByLabel('OverCharge', false)
        -- Engineering Throughput Upgrade
        elseif enh =='EngineeringThroughput' then
            if not Buffs['SeraphimSCUBuildRate'] then
                BuffBlueprint {
                    Name = 'SeraphimSCUBuildRate',
                    DisplayName = 'SeraphimSCUBuildRate',
                    BuffType = 'SCUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'SeraphimSCUBuildRate')
        elseif enh == 'EngineeringThroughputRemove' then
            if Buff.HasBuff( self, 'SeraphimSCUBuildRate' ) then
                Buff.RemoveBuff( self, 'SeraphimSCUBuildRate' )
            end
        -- Damage Stabilization
        elseif enh == 'DamageStabilization' then
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
            if Buff.HasBuff( self, 'SeraphimSCUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'SeraphimSCUDamageStabilization' )
            end
            Buff.ApplyBuff(self, 'SeraphimSCUDamageStabilization')
      	elseif enh == 'DamageStabilizationRemove' then
            if Buff.HasBuff( self, 'SeraphimSCUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'SeraphimSCUDamageStabilization' )
            end
        -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(35)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 16)
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
        end
    end
}

TypeClass = XSL0301
