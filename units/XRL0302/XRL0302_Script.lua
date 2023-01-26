----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CMobileKamikazeBombWeapon = import("/lua/cybranweapons.lua").CMobileKamikazeBombWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

local Weapon = import("/lua/sim/weapon.lua").Weapon

--- A unique death weapon for the Fire Beetle
local DeathWeaponKamikaze = Class(Weapon) {
    OnFire = function(self)
        -- do regular death weapon of unit if we didn't already
        if not self.unit.Dead then 
            self.unit:Kill()
        end
    end,
}

--- A unique death weapon for the Fire Beetle
local DeathWeaponEMP = Class(Weapon) {

    FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,

    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)

        -- get information
        local blueprint = self:GetBlueprint()
        local position = self.unit:GetPosition()

        -- do emitters
        local army = self.unit.Army
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
        end
        
        -- do a decal
        if not self.unit.transportDrop then
            
            local rotation = math.random(0, 6.28)
            
            DamageArea( self.unit, position, 6, 1, 'TreeForce', true )
            DamageArea( self.unit, position, 6, 1, 'TreeForce', true )
            
            CreateDecal( position, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        -- do the damage
        DamageArea(self.unit, position, blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType or 'Normal', blueprint.DamageFriendly or false)
        self.unit:PlayUnitSound('Destroyed')
        self.unit:Destroy()
    end,
}

---@class XRL0302 : CWalkingLandUnit
XRL0302 = Class(CWalkingLandUnit) {

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
        Suicide = Class(DeathWeaponKamikaze) {},
        DeathWeapon = Class(DeathWeaponEMP) {},
    },

    AmbientExhaustBones = {
        'XRL0302',
    },

    AmbientLandExhaustEffects = {
        '/effects/emitters/cannon_muzzle_smoke_12_emit.bp',
    },

    --- Called when the unit is created, initialises some logic such as the effects
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)

        self.EffectsBagXRL = TrashBag()
        self.AmbientExhaustEffectsBagXRL = TrashBag()
        self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle',  self.Layer, nil, self.EffectsBag)
        self.PeriodicFXThread = self:ForkThread(self.EmitPeriodicEffects)
    end,

    --- Called when the unit is done building, adds the cloak shader
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:ForkThread(self.HideUnit, self)
    end,

    --- Adds the cloaking mesh to the unit to hide it
    HideUnit = function(self)
        WaitTicks(1)
        self:SetMesh(self:GetBlueprint().Display.CloakMeshBlueprint, true)
    end,

    -- This is the Denotate button - triggers the weapon but without an instigator so that it doesn't get called twice.
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,
    
    --- Periodically creates effects
    EmitPeriodicEffects = function(self)

        -- cache information for the while loop
        local army = self.Army
        local ambientLandExhaustEffects = self.AmbientLandExhaustEffects
        local ambientExhaustBones = self.AmbientExhaustBones

        while not self.Dead do

            -- create the effects
            for kE, vE in ambientLandExhaustEffects do
                for kB, vB in ambientExhaustBones do
                    CreateAttachedEmitter(self, vB, army, vE)
                end
            end

            WaitSeconds(3)
        end
    end,
    
    --- Called when the unit dies by Unit.OnKilled.
    DoDeathWeapon = function(self)

        if self:IsBeingBuilt() then return end

        -- handle regular death weapon procedures
        CWalkingLandUnit.DoDeathWeapon(self)

        -- clean up some effects
        self.EffectsBagXRL:Destroy()
        self.AmbientExhaustEffectsBagXRL:Destroy()

        -- stop the periodice effects
        self.PeriodicFXThread:Destroy()
        self.PeriodicFXThread = nil

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
}

TypeClass = XRL0302
