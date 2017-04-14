-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0303/URL0303_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local Weapon = import('/lua/sim/Weapon.lua').Weapon
local cWeapons = import('/lua/cybranweapons.lua')
local CDFLaserDisintegratorWeapon = cWeapons.CDFLaserDisintegratorWeapon01
local CDFElectronBolterWeapon = cWeapons.CDFElectronBolterWeapon
local MissileRedirect = import('/lua/defaultantiprojectile.lua').MissileRedirect

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

URL0303 = Class(CWalkingLandUnit) {
    PlayEndAnimDestructionEffects = false,

    Weapons = {
        Disintigrator = Class(CDFLaserDisintegratorWeapon) {},
        HeavyBolter = Class(CDFElectronBolterWeapon) {},
        DeathWeapon = Class(EMPDeathWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        local bp = self:GetBlueprint().Defense.AntiMissile
        local antiMissile = MissileRedirect {
            Owner = self,
            Radius = bp.Radius,
            AttachBone = bp.AttachBone,
            RedirectRateOfFire = bp.RedirectRateOfFire
        }
        self.Trash:Add(antiMissile)
    end,

    DoDeathWeapon = function(self)
        if self:IsBeingBuilt() then return end

        CWalkingLandUnit.DoDeathWeapon(self) -- Handle the normal DeathWeapon procedures

        -- Now handle our special buff and FX
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

        -- Play EMP Effect
        CreateLightParticle(self, -1, -1, 24, 62, 'flare_lens_add_02', 'ramp_red_10')
    end,
}

TypeClass = URL0303
