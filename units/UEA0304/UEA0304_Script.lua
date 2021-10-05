------------------------------------------------------------------
--  File     :  /cdimage/units/UEA0304/UEA0304_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  UEF Strategic Bomber Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local TAirUnit = import('/lua/terranunits.lua').TAirUnit
local TIFSmallYieldNuclearBombWeapon = import('/lua/terranweapons.lua').TIFSmallYieldNuclearBombWeapon
local TAirToAirLinkedRailgun = import('/lua/terranweapons.lua').TAirToAirLinkedRailgun

UEA0304 = Class(TAirUnit) {
    Weapons = {
        Bomb = Class(TIFSmallYieldNuclearBombWeapon) {},
        LinkedRailGun1 = Class(TAirToAirLinkedRailgun) {},
        LinkedRailGun2 = Class(TAirToAirLinkedRailgun) {},
    },


    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator:GetBlueprint().CategoriesHash.STRATEGICBOMBER and instigator.Army == self.Army then
            return
        end
        
        TAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}

TypeClass = UEA0304
