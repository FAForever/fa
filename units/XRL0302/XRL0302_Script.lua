----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local EffectTemplate = import("/lua/effecttemplates.lua")
local Weapon = import("/lua/sim/weapon.lua").Weapon

local DeathWeaponKamikaze = ClassWeapon(Weapon) {
    OnFire = function(self)
        if not self.unit.Dead then
            self.unit:Kill()
        end
    end,
}

local DeathWeaponEMP = ClassWeapon(Weapon) {
    FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self.Blueprint
        local position = self.unit:GetPosition()

        local army = self.unit.Army
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
        end

        if not self.unit.transportDrop then
            local rotation = math.random(0, 6.28)
            DamageArea(self.unit, position, 6, 1, 'TreeForce', true)
            DamageArea(self.unit, position, 6, 1, 'TreeForce', true)
            CreateDecal(position, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        DamageArea(self.unit, position, blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType or 'Normal',
            blueprint.DamageFriendly or false)
        self.unit:PlayUnitSound('Destroyed')
        self.unit:Destroy()
    end,
}

---@class XRL0302 : CWalkingLandUnit
---@field EffectsBagXRL TrashBag
---@field AmbientExhaustEffectsBagXRL TrashBag
---@field PeriodicFXThread thread
XRL0302 = ClassUnit(CWalkingLandUnit) {

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
        Suicide = ClassWeapon(DeathWeaponKamikaze) {},
        DeathWeapon = ClassWeapon(DeathWeaponEMP) {},
    },

    AmbientExhaustBones = {
        'XRL0302',
    },

    AmbientLandExhaustEffects = {
        '/effects/emitters/cannon_muzzle_smoke_12_emit.bp',
    },

    ---@param self XRL0302
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self.EffectsBagXRL = TrashBag()
        self.AmbientExhaustEffectsBagXRL = TrashBag()
        self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.EffectsBag)
        self.PeriodicFXThread = ForkThread(self.EmitPeriodicEffects, self)
        self.Trash:Add(self.PeriodicFXThread)

        self.Trash:Add(
            ForkThread(
                self.TrackTargetThread, self
            )
        )
    end,

    ---@param self XRL0302
    TrackTargetThread = function(self)
        local navigator = self:GetNavigator()
        while not IsDestroyed(self) do

            -- adjust behavior of the weapon so it only fires when we're trying to attack something
            local weapon = self:GetWeaponByLabel('Suicide')
            if weapon then
                if (
                    -- we're trying to attack
                    self:IsUnitState('Attacking') or
                        -- engineer trying to take us
                        self:IsUnitState('BeingCaptured') or self:IsUnitState('BeingReclaimed')
                    )
                then
                    weapon:SetEnabled(true)
                else
                    weapon:SetEnabled(false)
                end
            end

            -- adjust behavior of tracking 
            local command = self:GetCommandQueue()[1]
            -- confirm that it is an attack command
            if command and command.commandType == 10 then
                -- override navigator behavior
                local target = command.target
                if target then
                    navigator:SetDestUnit(target)
                    navigator:SetSpeedThroughGoal(true)
                end
            end

            WaitTicks(6)
        end
    end,

    ---@param self XRL0302
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.Trash:Add(ForkThread(self.HideUnit, self))
    end,

    ---@param self XRL0302
    HideUnit = function(self)
        WaitTicks(1)
        self:SetMesh(self.Blueprint.Display.CloakMeshBlueprint, true)
    end,

    ---@param self XRL0302
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,

    ---@param self XRL0302
    EmitPeriodicEffects = function(self)
        local army = self.Army
        local ambientLandExhaustEffects = self.AmbientLandExhaustEffects
        local ambientExhaustBones = self.AmbientExhaustBones

        while not self.Dead do
            for kE, vE in ambientLandExhaustEffects do
                for kB, vB in ambientExhaustBones do
                    CreateAttachedEmitter(self, vB, army, vE)
                end
            end
            WaitTicks(31)
        end
    end,

    ---@param self XRL0302
    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end
        CWalkingLandUnit.DoDeathWeapon(self)
        self.EffectsBagXRL:Destroy()
        self.AmbientExhaustEffectsBagXRL:Destroy()
        self.PeriodicFXThread:Destroy()
        self.PeriodicFXThread = nil
        local bp
        for k, v in self.Blueprint.Buffs do
            if v.Add.OnDeath then
                bp = v
            end
        end

        if bp ~= nil then
            self:AddBuff(bp)
        end
    end,
}

TypeClass = XRL0302

-- Kept for mod support
local CMobileKamikazeBombWeapon = import("/lua/cybranweapons.lua").CMobileKamikazeBombWeapon
local EffectUtil = import("/lua/effectutilities.lua")
