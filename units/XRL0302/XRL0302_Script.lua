----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local EffectTemplate = import("/lua/effecttemplates.lua")
local Weapon = import("/lua/sim/weapon.lua").Weapon

-- upvalue scope for performance
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local DamageArea = DamageArea
local CreateEmitterAtBone = CreateEmitterAtBone
local CreateDecal = CreateDecal
local CreateLightParticle = CreateLightParticle

local DeathWeaponKamikaze = ClassWeapon(Weapon) {
    OnFire = function(self)
        local unit = self.unit
        if not unit.Dead then
            unit:Kill()
        end
    end,
}

---@class DeathWeaponEMP : Weapon
local DeathWeaponEMP = ClassWeapon(Weapon) {
    FxDeath = EffectTemplate.CMobileBeetleExplosion,

    DebrisBlueprints = {
        '/effects/Entities/BeetleDebris01/BeetleDebris01_proj.bp',
    },

    ---@param self DeathWeaponEMP
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    ---@param self DeathWeaponEMP
    Fire = function(self)
        local blueprint = self.Blueprint
        local unit = self.unit
        local position = unit:GetPosition()

        -- do the damage
        DamageArea(unit, position, blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType or 'Normal',
            blueprint.DamageFriendly or false)

        -- create explosion effect
        local army = unit.Army
        for k, v in self.FxDeath do
            local effect = CreateEmitterAtBone(unit, -2, army, v)
            effect:ScaleEmitter(0.85)
        end

        -- create a decal
        if not unit.transportDrop then
            local rotation = 6.28 * Random()
            DamageArea(unit, position, 6, 1, 'TreeForce', true)
            DamageArea(unit, position, 6, 1, 'TreeForce', true)
            CreateDecal(position, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        -- create light flash
        CreateLightParticle(unit, -1, army, 7, 12, 'glow_03', 'ramp_red_06')
        CreateLightParticle(unit, -1, army, 7, 22, 'glow_03', 'ramp_antimatter_02')

        -- create flying and burning debris
        local vx, _, vz = unit:GetVelocity()
        for k = 1, 5 do
            local blueprint = table.random(self.DebrisBlueprints)
            local pvx = (vx + Random() - 0.5)
            local pvz = (vz + Random() - 0.5)
            unit:CreateProjectile(blueprint, 0, 0.2, 0, pvx, 1, pvz)
        end

        -- destroy the unit
        unit:PlayUnitSound('Destroyed')
        unit:Destroy()
    end,
}

---@class XRL0302 : CWalkingLandUnit
XRL0302 = ClassUnit(CWalkingLandUnit) {
    Weapons = {
        Suicide = ClassWeapon(DeathWeaponKamikaze) {},
        DeathWeapon = ClassWeapon(DeathWeaponEMP) {},
    },

    ---@param self XRL0302
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self.EffectsBagXRL = TrashBag()
        self.AmbientExhaustEffectsBagXRL = TrashBag()

        self.Trash:Add(
            ForkThread(
                self.TrackTargetThread, self
            )
        )
    end,

    ---@param self XRL0302
    TrackTargetThread = function(self)
        local navigator = self:GetNavigator()
        local weapon = self:GetWeaponByLabel('Suicide')

        while not IsDestroyed(self) do

            -- adjust behavior of the weapon so it only fires when we're trying to attack something
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

            -- adjust behavior of tracking a target so that we speed through the target instead of bump into it
            local command = self:GetCommandQueue()[1]
            if command and command.commandType == 10 then
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
    end,

    ---@param self XRL0302
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,

    ---@param self XRL0302
    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end
        CWalkingLandUnit.DoDeathWeapon(self)
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
