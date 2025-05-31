-- File     :  /cdimage/units/XSL0001/XSL0001_script.lua
-- Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
-- Summary  :  Seraphim Commander Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

---@alias SeraphimACUEnhancementBuffType
---| "ACUUPGRADEDMG"
---| "COMMANDERAURA"
---| "COMMANDERAURAFORSELF"
---| "ACUBUILDRATE"

---@alias SeraphimACUEnhancementBuffName      # BuffType
---| "SeraphimACUDamageStabilization"         # ACUUPGRADEDMG
---| "SeraphimACUDamageStabilizationAdv"      # ACUUPGRADEDMG
---| "SeraphimACUAdvancedRegenAura"           # COMMANDERAURA
---| "SeraphimACUAdvancedRegenAuraSelfBuff"   # COMMANDERAURAFORSELF
---| "SeraphimACURegenAura"                   # COMMANDERAURA
---| "SeraphimACURegenAuraSelfBuff"           # COMMANDERAURAFORSELF
---| "SeraphimACUT2BuildRate"                 # ACUBUILDRATE
---| "SeraphimACUT3BuildRate"                 # ACUBUILDRATE


local ACUUnit = import("/lua/defaultunits.lua").ACUUnit
local Buff = import("/lua/sim/buff.lua")
local SWeapons = import("/lua/seraphimweapons.lua")
local SDFChronotronCannonWeapon = SWeapons.SDFChronotronCannonWeapon
local SDFChronotronOverChargeCannonWeapon = SWeapons.SDFChronotronCannonOverChargeWeapon
local ACUDeathWeapon = import("/lua/sim/defaultweapons.lua").ACUDeathWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher
local AIUtils = import("/lua/ai/aiutilities.lua")

---@class XSL0001 : ACUUnit
---@field ShieldEffectsBag moho.IEffect[] # stores the regen aura effects (level 1 has 1 effect, level 2 has 2 effects)
XSL0001 = ClassUnit(ACUUnit) {
    Weapons = {
        DeathWeapon = ClassWeapon(ACUDeathWeapon) {},
        ChronotronCannon = ClassWeapon(SDFChronotronCannonWeapon) {},
        Missile = ClassWeapon(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
        OverCharge = ClassWeapon(SDFChronotronOverChargeCannonWeapon) {},
        AutoOverCharge = ClassWeapon(SDFChronotronOverChargeCannonWeapon) {},
    },

    ---@param self XSL0001
    __init = function(self)
        ACUUnit.__init(self, 'ChronotronCannon')
    end,

    ---@param self XSL0001
    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    ---@param self XSL0001
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ACUUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetWeaponEnabledByLabel('ChronotronCannon', true)
        self.Trash:Add(ForkThread(self.GiveInitialResources, self))
        self.ShieldEffectsBag = {}
    end,

    ---@param self XSL0001
    ---@param unitBeingBuilt Unit
    ---@param order string unused
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones,
            self.BuildEffectsBag)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ---@return Unit[]
    GetUnitsToBuff = function(self, bp)
        local unitCat = ParseEntityCategory(bp.UnitCategory or
            'BUILTBYTIER3FACTORY + BUILTBYQUANTUMGATE + NEEDMOBILEBUILD')
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

    ---@param self XSL0001
    ---@param regenAuraType Enhancement
    RegenBuffThread = function(self, regenAuraType)
        local bp = self.Blueprint.Enhancements[regenAuraType]
        local buff = 'SeraphimACU' .. regenAuraType

        while not self.Dead do
            local units = self:GetUnitsToBuff(bp)
            for _, unit in units do
                Buff.ApplyBuff(unit, buff)
                unit:RequestRefreshUI()
            end
            WaitTicks(51)
        end
    end,

    --====================================================================================================================================
    -- Enhancements

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRegenAura = function(self, bp)
        local type
        if not Buffs['SeraphimACURegenAura'] then
            local buff_bp = {
                Name = 'SeraphimACURegenAura',
                DisplayName = 'SeraphimACURegenAura',
                BuffType = 'COMMANDERAURA_RegenAura',
                Stacks = 'REPLACE',
                Duration = 5,
                Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
                Affects = {
                    Regen = {
                        Add = 0,
                        Mult = bp.RegenPerSecond,
                        Floor = bp.RegenFloor,
                        BPCeilings = {
                            TECH1 = bp.RegenCeilingT1,
                            TECH2 = bp.RegenCeilingT2,
                            TECH3 = bp.RegenCeilingT3,
                            EXPERIMENTAL = bp.RegenCeilingT4,
                            SUBCOMMANDER = bp.RegenCeilingSCU,
                        },
                    },
                },
            }
            buff_bp.Affects.MaxHealth = {
                Add = 0,
                Mult = bp.MaxHealthFactor,
                DoNotFill = true,
            }
            BuffBlueprint(buff_bp)
        end

        if not Buffs['SeraphimACURegenAuraSelfBuff'] then -- AURA SELF BUFF
            BuffBlueprint {
                Name = 'SeraphimACURegenAuraSelfBuff',
                DisplayName = 'SeraphimACURegenAuraSelfBuff',
                BuffType = 'COMMANDERAURAFORSELF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.ACUAddHealth,
                        Mult = 1,
                    },
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1,
                    },
                },
            }
        end

        Buff.ApplyBuff(self, 'SeraphimACURegenAuraSelfBuff')
        table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'XSL0001', self.Army, '/effects/emitters/seraphim_regenerative_aura_01_emit.bp'))
        if self.RegenThreadHandle then
            KillThread(self.RegenThreadHandle)
            self.RegenThreadHandle = nil
        end

        self.RegenThreadHandle = self:ForkThread(self.RegenBuffThread, "RegenAura")
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRegenAuraRemove = function(self, bp)
        if self.ShieldEffectsBag then
            for _, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
        KillThread(self.RegenThreadHandle)
        self.RegenThreadHandle = nil

        if Buff.HasBuff(self, 'SeraphimACURegenAuraSelfBuff') then
            Buff.RemoveBuff(self, 'SeraphimACURegenAuraSelfBuff')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedRegenAura = function(self, bp)
        local type
        if not Buffs['SeraphimACUAdvancedRegenAura'] then
            local buff_bp = {
                Name = 'SeraphimACUAdvancedRegenAura',
                DisplayName = 'SeraphimACUAdvancedRegenAura',
                BuffType = 'COMMANDERAURA_AdvancedRegenAura',
                Stacks = 'REPLACE',
                Duration = 5,
                Effects = { '/effects/emitters/seraphim_regenerative_aura_02_emit.bp' },
                Affects = {
                    Regen = {
                        Add = 0,
                        Mult = bp.RegenPerSecond,
                        Floor = bp.RegenFloor,
                        BPCeilings = {
                            TECH1 = bp.RegenCeilingT1,
                            TECH2 = bp.RegenCeilingT2,
                            TECH3 = bp.RegenCeilingT3,
                            EXPERIMENTAL = bp.RegenCeilingT4,
                            SUBCOMMANDER = bp.RegenCeilingSCU,
                        },
                    },
                },
            }
            buff_bp.Affects.MaxHealth = {
                Add = 0,
                Mult = bp.MaxHealthFactor,
                DoNotFill = true,
            }
            BuffBlueprint(buff_bp)
        end

        if not Buffs['SeraphimACUAdvancedRegenAuraSelfBuff'] then -- AURA SELF BUFF
            BuffBlueprint {
                Name = 'SeraphimACUAdvancedRegenAuraSelfBuff',
                DisplayName = 'SeraphimACUAdvancedRegenAuraSelfBuff',
                BuffType = 'COMMANDERAURAFORSELF',
                Stacks = 'REPLACE',
                Duration = -1,
                Affects = {
                    MaxHealth = {
                        Add = bp.ACUAddHealth,
                        Mult = 1,
                    },
                    Regen = {
                        Add = bp.NewRegenRate,
                        Mult = 1,
                    },
                },
            }
        end

        Buff.ApplyBuff(self, 'SeraphimACUAdvancedRegenAuraSelfBuff')
        table.insert(self.ShieldEffectsBag, CreateAttachedEmitter(self, 'XSL0001', self.Army, '/effects/emitters/seraphim_regenerative_aura_01_emit.bp'))
        if self.RegenThreadHandle then
            KillThread(self.RegenThreadHandle)
            self.RegenThreadHandle = nil
        end

        self.RegenThreadHandle = self:ForkThread(self.RegenBuffThread, "AdvancedRegenAura")
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedRegenAuraRemove = function(self, bp)
        if self.ShieldEffectsBag then
            for _, v in self.ShieldEffectsBag do
                v:Destroy()
            end
            self.ShieldEffectsBag = {}
        end
        KillThread(self.RegenThreadHandle)
        self.RegenThreadHandle = nil
        if Buff.HasBuff(self, 'SeraphimACUAdvancedRegenAuraSelfBuff') then
            Buff.RemoveBuff(self, 'SeraphimACUAdvancedRegenAuraSelfBuff')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocation = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        if not bp then return end
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvanced = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        if not bp then return end
        self:SetProductionPerSecondEnergy((bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy) or 0)
        self:SetProductionPerSecondMass((bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass) or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementResourceAllocationAdvancedRemove = function(self, bp)
        local bpEcon = self.Blueprint.Economy
        self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
        self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilization = function(self, bp)
        if not Buffs['SeraphimACUDamageStabilization'] then
            BuffBlueprint {
                Name = 'SeraphimACUDamageStabilization',
                DisplayName = 'SeraphimACUDamageStabilization',
                BuffType = 'ACUUPGRADEDMG',
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
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
        Buff.ApplyBuff(self, 'SeraphimACUDamageStabilization')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationRemove = function(self, bp)
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationAdvanced = function(self, bp)
        if not Buffs['SeraphimACUDamageStabilizationAdv'] then
            BuffBlueprint {
                Name = 'SeraphimACUDamageStabilizationAdv',
                DisplayName = 'SeraphimACUDamageStabilizationAdv',
                BuffType = 'ACUUPGRADEDMG',
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
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilizationAdv') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilizationAdv')
        end
        Buff.ApplyBuff(self, 'SeraphimACUDamageStabilizationAdv')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementDamageStabilizationAdvancedRemove = function(self, bp)
        -- since there's no way to just remove an upgrade anymore, if we're remove adv, were removing both
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilizationAdv') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilizationAdv')
        end
        if Buff.HasBuff(self, 'SeraphimACUDamageStabilization') then
            Buff.RemoveBuff(self, 'SeraphimACUDamageStabilization')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporter = function(self, bp)
        self:AddCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementTeleporterRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Teleport')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMissile = function(self, bp)
        self:AddCommandCap('RULEUCC_Tactical')
        self:AddCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', true)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementMissileRemove = function(self, bp)
        self:RemoveCommandCap('RULEUCC_Tactical')
        self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
        self:SetWeaponEnabledByLabel('Missile', false)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineering = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['SeraphimACUT2BuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimACUT2BuildRate',
                DisplayName = 'SeraphimACUT2BuildRate',
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
        Buff.ApplyBuff(self, 'SeraphimACUT2BuildRate')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementAdvancedEngineeringRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
        if Buff.HasBuff(self, 'SeraphimACUT2BuildRate') then
            Buff.RemoveBuff(self, 'SeraphimACUT2BuildRate')
        end
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3Engineering = function(self, bp)
        if not bp then return end
        local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
        self:RemoveBuildRestriction(cat)
        if not Buffs['SeraphimACUT3BuildRate'] then
            BuffBlueprint {
                Name = 'SeraphimACUT3BuildRate',
                DisplayName = 'SeraphimCUT3BuildRate',
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
        Buff.ApplyBuff(self, 'SeraphimACUT3BuildRate')
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementT3EngineeringRemove = function(self, bp)
        local bp = self.Blueprint.Economy.BuildRate
        if not bp then return end
        self:RestoreBuildRestrictions()
        if Buff.HasBuff(self, 'SeraphimACUT3BuildRate') then
            Buff.RemoveBuff(self, 'SeraphimACUT3BuildRate')
        end
        self:AddBuildRestriction(categories.SERAPHIM *
            (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER))
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementBlastAttack = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:AddDamageRadiusMod(bp.NewDamageRadius or 5)
        wep:AddDamageMod(bp.AdditionalDamage)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementBlastAttackRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:AddDamageRadiusMod(-self.Blueprint.Enhancements['BlastAttack'].NewDamageRadius) -- unlimited AOE bug fix by brute51 [117]
        wep:AddDamageMod(-self.Blueprint.Enhancements['BlastAttack'].AdditionalDamage)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRateOfFire = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
        wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bp.NewMaxRadius or 44)
    end,

    ---@param self XSL0001
    ---@param bp UnitBlueprintEnhancement
    ProcessEnhancementRateOfFireRemove = function(self, bp)
        local wep = self:GetWeaponByLabel('ChronotronCannon')
        local bpDisrupt = self.Blueprint.Weapon[1].RateOfFire
        wep:ChangeRateOfFire(bpDisrupt or 1)
        bpDisrupt = self.Blueprint.Weapon[1].MaxRadius
        wep:ChangeMaxRadius(bpDisrupt or 22)
        local oc = self:GetWeaponByLabel('OverCharge')
        oc:ChangeMaxRadius(bpDisrupt or 22)
        local aoc = self:GetWeaponByLabel('AutoOverCharge')
        aoc:ChangeMaxRadius(bpDisrupt or 22)
    end,

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
}

TypeClass = XSL0001
