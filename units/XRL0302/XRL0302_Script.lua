----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon
local Weapon = import('/lua/sim/Weapon.lua').Weapon

local EMPDeathWeapon = Class(Weapon) {
    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), blueprint.DamageRadius,
                   blueprint.Damage, blueprint.DamageType, blueprint.DamageFriendly)
    end,
}

XRL0302 = Class(CWalkingLandUnit) {

    Weapons = {
        Suicide = Class(CMobileKamikazeBombWeapon) {},
        DeathWeapon = Class(EMPDeathWeapon) {},
    },

    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        if instigator then
            self:GetWeaponByLabel('Suicide'):FireWeapon()
        end
    end,
    
    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end

        CWalkingLandUnit.DoDeathWeapon(self) -- Handle the normal DeathWeapon procedures

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
        self:DoDeathWeapon()
    end,
}

TypeClass = XRL0302
