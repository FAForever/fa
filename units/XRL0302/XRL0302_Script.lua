----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local EffectTemplate = import("/lua/effecttemplates.lua")
local Weapon = import("/lua/sim/weapon.lua").Weapon

local DeathWeaponEMP = ClassWeapon(Weapon) {

    FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,

    OnFire = function(self)
        Weapon.OnFire(self)

        -- Disable our death weapon so we don't fire it again
        self.unit:SetDeathWeaponEnabled(false)

        local blueprint = self.Blueprint
        local position = self.unit:GetPosition()

        local army = self.unit.Army
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
        end

        -- Do tree knockdown if we're not in a transport
        if not self.unit.transportDrop then
            local rotation = math.random(0, 6.28)
            DamageArea(self.unit, position, blueprint.DamageRadius, 1, 'TreeForce', true)
            CreateDecal(position, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        -- Do damage
        DamageArea(self.unit, position, blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType or 'Normal',
            blueprint.DamageFriendly or false)
        self.unit:PlayUnitSound('Destroyed')

        -- Kill unit if it's not already dead
        if not self.unit.Dead then
            self.unit:Kill()
        end

        -- Don't leave wreckage
        self.unit:Destroy()
    end,

    -- This prevents us from firing the death weapon when we're moving
    -- also gives much better tailchase performance by adjusting the detonation range
    OnMotionHorzEventChange = function(self, new, old)
        if new == 'Cruise' then
            self:SetEnabled(false)
        elseif new == 'Stopping' then
            if not self.unit:IsUnitState('Moving') then
                self:SetEnabled(true)
                if self.unit:IsUnitState('Attacking') then
                    local target = self.unit:GetCommandQueue()[1].target
                    if target then
                        local dist = VDist3(self.unit:GetPosition(), target:GetPosition())
                        if not self.chasing and dist < self.Blueprint.MaxRadius or
                        self.chasing and dist < self.Blueprint.DamageRadius then
                            self:FireWeapon()
                        end
                    end
                    self.unit:GetNavigator():SetSpeedThroughGoal(true)
                    self.chasing = true
                end
            end
        elseif new == 'Stopped' then
            self:SetEnabled(true)
            self.unit:GetNavigator():SetSpeedThroughGoal(false)
            self.chasing = nil
        end
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
        KamikazeEMP = ClassWeapon(DeathWeaponEMP) {},
    },

    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle', self.Layer, nil, self.Trash)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self.Trash:Add(ForkThread(self.HideUnit, self))

        -- Enable our death weapon
        self:SetDeathWeaponEnabled(true)
    end,

    HideUnit = function(self)
        WaitTicks(1)
        self:SetMesh(self.Blueprint.Display.CloakMeshBlueprint, true)
    end,

    -- Use the special toggle instead of production pausing as our detonator
    EnableSpecialToggle = function(self)
        self:GetWeaponByLabel('KamikazeEMP'):FireWeapon()
    end,

    DoDeathWeapon = function(self)
        self:GetWeaponByLabel('KamikazeEMP'):FireWeapon()
    end,
}

TypeClass = XRL0302

-- Kept for mod support
local CMobileKamikazeBombWeapon = import("/lua/cybranweapons.lua").CMobileKamikazeBombWeapon
local EffectUtil = import("/lua/effectutilities.lua")