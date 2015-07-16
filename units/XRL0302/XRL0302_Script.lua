----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon

XRL0302 = Class(CWalkingLandUnit) {

    -- OK this unit was horribly overcomplicated in the past. What we want is for only one of 
    -- three situations to ever blow up the bomb. The unit getting in range and firing, the 
    -- player pressing the detonate button, or the player using CTRL-K to suicide the unit.

    -- Since the weapon itself kills the unit with self.unit:Kill(), and CTRL-K detonates the
    -- weapon immediately thanks to selfdestruct.lua, we don't need any logic here for OnKilled()

    Weapons = {        
        Suicide = Class(CMobileKamikazeBombWeapon) {},
    },

    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
    OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,
    
    OnKilled = function(self, instigator, type, overkillRatio)
        -- We need to leave no wreck on suicide. instigator can only be self when the
        -- weapon is fired, as it passes it specially.
        if instigator == self then
            self:Destroy()
        else
            CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
        end
    end,
}
TypeClass = XRL0302
