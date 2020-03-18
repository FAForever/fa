-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0301/XSL0301_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Sub Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CommandUnit = import('/lua/defaultunits.lua').CommandUnit
local SWeapons = import('/lua/seraphimweapons.lua')
local Buff = import('/lua/sim/Buff.lua')
local SCUDeathWeapon = import('/lua/sim/defaultweapons.lua').SCUDeathWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local SDFLightChronotronCannonWeapon = SWeapons.SDFLightChronotronCannonWeapon
local SDFOverChargeWeapon = SWeapons.SDFLightChronotronCannonOverchargeWeapon
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher

XSL0301 = Class(CommandUnit) {
    Weapons = {
        LightChronatronCannon = Class(SDFLightChronotronCannonWeapon) {},
        DeathWeapon = Class(SCUDeathWeapon) {},
        OverCharge = Class(SDFOverChargeWeapon) {},
        AutoOverCharge = Class(SDFOverChargeWeapon) {},
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
        self:HideBone('Back_Upgrade', true)
        self:SetupBuildBones()
        self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
        self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag)
    end,

	GetUnitsToBuff = function(self, bp)
        local unitCat = ParseEntityCategory(bp.UnitCategory or 'BUILTBYTIER3FACTORY + BUILTBYQUANTUMGATE + NEEDMOBILEBUILD')
        local brain = self:GetAIBrain()
        local all = brain:GetUnitsAroundPoint(unitCat, self:GetPosition(), bp.Radius, 'Ally')
        local units = {}

        for _, u in all do
            if not u.Dead and not u:IsBeingBuilt() then
                table.insert(units, u)
            end
        end

        return units
    end,

    RegenFieldBuffThread = function(self, type)
        local bp = self:GetBlueprint().Enhancements[type]
        local buff = 'SeraphimSACU' .. type

        while not self.Dead do
            local units = self:GetUnitsToBuff(bp)
            for _,unit in units do
                Buff.ApplyBuff(unit, buff)
                unit:RequestRefreshUI()
            end
            WaitSeconds(5)
        end
    end,
	
    CreateEnhancement = function(self, enh)
        CommandUnit.CreateEnhancement(self, enh)
        local bp = self:GetBlueprint().Enhancements[enh]
        if not bp then return end
        -- Regenerative Aura
        if enh == 'RegenAura' then
            local buff
            local type

            buff = 'SeraphimSACU' .. enh

            if not Buffs[buff] then
                local buff_bp = {
                    Name = buff,
                    DisplayName = buff,
                    BuffType = 'COMMANDERAURA_' .. enh,
                    --Stacks = 'REPLACE',
                    Duration = 5,
                    Effects = {'/effects/emitters/seraphim_regenerative_aura_02_emit.bp'},
                    Affects = {
                        Regen = {
                            Add = 0,
                            Mult = bp.RegenPerSecond,
                            --Floor = bp.RegenFloor,
                            --CeilT1 = bp.RegenCeilingT1,
                            --CeilT2 = bp.RegenCeilingT2,
                            --CeilT3 = bp.RegenCeilingT3,
                            --CeilT4 = bp.RegenCeilingT4,
                        },
                    },
                }
                BuffBlueprint(buff_bp)
            end

            --buff2 = buff .. 'SelfBuff'

            --if not Buffs[buff2] then   -- AURA SELF BUFF
             --   BuffBlueprint {
             --       Name = buff2,
            --        DisplayName = buff2,
            --        BuffType = 'COMMANDERAURAFORSELF',
            --        Stacks = 'REPLACE',
             --       Duration = -1,
            --    }
            --end

            --Buff.ApplyBuff(self, buff2)
            --table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'XSL0001', self:GetArmy(), '/effects/emitters/seraphim_regenerative_aura_01_emit.bp'))
            --if self.RegenFieldThreadHandle then
            --    KillThread(self.RegenFieldThreadHandle)
            --    self.RegenFieldThreadHandle = nil
            --end

            self.RegenFieldThreadHandle = self:ForkThread(self.RegenFieldBuffThread, enh)
        elseif enh == 'RegenAuraRemove' then
            if self.ShieldEffectsBag then
                for k, v in self.ShieldEffectsBag do
                    v:Destroy()
                end
                self.ShieldEffectsBag = {}
            end

            KillThread(self.RegenFieldThreadHandle)
            self.RegenFieldThreadHandle = nil
            for _, b in {'SeraphimACURegenAura', 'SeraphimACUAdvancedRegenAura'} do
                if Buff.HasBuff(self, b .. 'SelfBuff') then
                    Buff.RemoveBuff(self, b .. 'SelfBuff')
                end
            end
		-- Teleporter
        elseif enh == 'Teleporter' then
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
        -- Overcharge
        elseif enh == 'Overcharge' then
            self:AddCommandCap('RULEUCC_Overcharge')
            self:GetWeaponByLabel('OverCharge').NeedsUpgrade = false
            self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = false
        elseif enh == 'OverchargeRemove' then
            self:RemoveCommandCap('RULEUCC_Overcharge')
            self:SetWeaponEnabledByLabel('OverCharge', false)
            self:SetWeaponEnabledByLabel('AutoOverCharge', false)
            self:GetWeaponByLabel('OverCharge').NeedsUpgrade = true
            self:GetWeaponByLabel('AutoOverCharge').NeedsUpgrade = true
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
            if Buff.HasBuff(self, 'SeraphimSCUBuildRate') then
                Buff.RemoveBuff(self, 'SeraphimSCUBuildRate')
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
            if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
                Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
            end
            Buff.ApplyBuff(self, 'SeraphimSCUDamageStabilization')
          elseif enh == 'DamageStabilizationRemove' then
            if Buff.HasBuff(self, 'SeraphimSCUDamageStabilization') then
                Buff.RemoveBuff(self, 'SeraphimSCUDamageStabilization')
            end
        -- Enhanced Sensor Systems
        elseif enh == 'EnhancedSensors' then
            self:SetIntelRadius('Vision', bp.NewVisionRadius or 104)
            self:SetIntelRadius('Omni', bp.NewOmniRadius or 104)
        elseif enh == 'EnhancedSensorsRemove' then
            local bpIntel = self:GetBlueprint().Intel
            self:SetIntelRadius('Vision', bpIntel.VisionRadius or 26)
            self:SetIntelRadius('Omni', bpIntel.OmniRadius or 16)
		-- Gun Range
        elseif enh == 'GunRange' then
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 35)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(35)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(35)
        elseif enh == 'GunRangeRemove' then
            local wep = self:GetWeaponByLabel('LightChronatronCannon')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
            local wep = self:GetWeaponByLabel('OverCharge')
            wep:ChangeMaxRadius(bp.NewMaxRadius or 25)
            local aoc = self:GetWeaponByLabel('AutoOverCharge')
            aoc:ChangeMaxRadius(bp.NewMaxRadius or 25)
        end
    end,
}

TypeClass = XSL0301
