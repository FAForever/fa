----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon
local EffectUtil = import('/lua/EffectUtilities.lua')
local Weapon = import('/lua/sim/Weapon.lua').Weapon

local EMPDeathWeapon = Class(Weapon)({
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
})

XRL0302 = Class(CWalkingLandUnit)({

    IntelEffects = {
        Cloak = {
            {
                Bones = {
                    'XRL0302',
                },
                Scale = 3.0,
                Type = 'Cloak01',
            },
        },
    },

    Weapons = {
        Suicide = Class(CMobileKamikazeBombWeapon)({}),
        DeathWeapon = Class(EMPDeathWeapon)({}),
    },

    AmbientExhaustBones = {
        'XRL0302',
    },

    AmbientLandExhaustEffects = {
        '/effects/emitters/cannon_muzzle_smoke_12_emit.bp',
    },

    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)

        self.EffectsBag = {}
        self.AmbientExhaustEffectsBag = {}
        self.CreateTerrainTypeEffects(self, self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.EffectsBag)
        self.PeriodicFXThread = self:ForkThread(self.EmitPeriodicEffects)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        --LOG('IEXIST')
        self:ForkThread(self.HideUnit, self)
        --self:SetMesh(self:GetBlueprint().Display.CloakMeshBlueprint, true)
    end,

    HideUnit = function(self)
        WaitTicks(1)
        --LOG('IEXIST3', self:GetBlueprint().Display.CloakMeshBlueprint)
        self:SetMesh(self:GetBlueprint().Display.CloakMeshBlueprint, true)
    end,

    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,

    EmitPeriodicEffects = function(self)
        while not self.Dead do
            local army = self:GetArmy()

            for kE, vE in self.AmbientLandExhaustEffects do
                for kB, vB in self.AmbientExhaustBones do
                    table.insert(self.AmbientExhaustEffectsBag, CreateAttachedEmitter(self, vB, army, vE))
                end
            end

            WaitSeconds(3)
            EffectUtil.CleanupEffectBag(self, 'AmbientExhaustEffectsBag')

        end
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        if instigator then
            self:GetWeaponByLabel('Suicide'):FireWeapon()
        end
    end,

    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then
            return
        end

        if self.EffectsBag then
            EffectUtil.CleanupEffectBag(self, 'EffectsBag')
            self.EffectsBag = nil
        end
        if self.AmbientExhaustEffectsBag then
            EffectUtil.CleanupEffectBag(self, 'AmbientExhaustEffectsBag')
            self.AmbientExhaustEffectsBag = nil
        end
        self.PeriodicFXThread:Destroy()
        self.PeriodicFXThread = nil
        -- Handle the normal DeathWeapon procedures
        CWalkingLandUnit.DoDeathWeapon(self)

        -- Now handle our special buff
        local bp
        for k, v in self:GetBlueprint().Buffs do
            if v.Add.OnDeath then
                bp = v
            end
        end

        -- If we could find a blueprint with v.Add.OnDeath, then add the buff
        if bp ~= nil then
            self:AddBuff(bp)
        end
    end,

    OnDestroy = function(self)
        CWalkingLandUnit.OnDestroy(self)
    end,


})

TypeClass = XRL0302
