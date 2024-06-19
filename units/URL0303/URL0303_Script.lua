-----------------------------------------------------------------
-- File     :  /cdimage/units/URL0303/URL0303_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Siege Assault Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local GetTrueEnemyUnitsInSphere = import("/lua/utilities.lua").GetTrueEnemyUnitsInSphere
local cWeapons = import("/lua/cybranweapons.lua")
local CDFLaserDisintegratorWeapon = cWeapons.CDFLaserDisintegratorWeapon01
local CDFElectronBolterWeapon = cWeapons.CDFElectronBolterWeapon
local CDFMissileRedirectWeapon01 = import("/lua/sim/weapons/cybran/CDFMissileRedirectWeapon01.lua").CDFMissileRedirectWeapon01
local MissileRedirect = import("/lua/defaultantiprojectile.lua").MissileRedirect

---@class URL0303 : CWalkingLandUnit
URL0303 = ClassUnit(CWalkingLandUnit) {
    PlayEndAnimDestructionEffects = false,

    Weapons = {
        Disintigrator = ClassWeapon(CDFLaserDisintegratorWeapon) {},
        HeavyBolter = ClassWeapon(CDFElectronBolterWeapon) {},
        RedirectMissile = ClassWeapon(CDFMissileRedirectWeapon01) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)

        -- fancy pants red glow
        CreateLightParticle(self, -1, self.Army, 24, 62, 'flare_lens_add_02', 'ramp_red_10')

        -- apply a stun manually
        local radius = 10
        local bpWeapon = self.Blueprint.Weapon
        for _, v in bpWeapon do 
            if v.Label == 'DeathStun' then
                radius = v.DamageRadius
                break
            end
        end

        local targets = GetTrueEnemyUnitsInSphere(self, self:GetPosition(), radius, categories.MOBILE - (categories.EXPERIMENTAL + categories.COMMAND))
        if targets then
            for k = 1, table.getn(targets) do
                local target = targets[k]
                if target.Layer ~= 'Air' then
                    target:SetStunned(1.5)
                end
            end
        end
    end,
}

TypeClass = URL0303
