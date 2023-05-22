------------------------------------------------------------------
--  File     :  /cdimage/units/UEA0304/UEA0304_script.lua
--  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--  Summary  :  UEF Strategic Bomber Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
local TIFSmallYieldNuclearBombWeapon = import("/lua/terranweapons.lua").TIFSmallYieldNuclearBombWeapon
local TAirToAirLinkedRailgun = import("/lua/terranweapons.lua").TAirToAirLinkedRailgun

---@class UEA0304 : TAirUnit
UEA0304 = ClassUnit(TAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(TIFSmallYieldNuclearBombWeapon) {},
        LinkedRailGun1 = ClassWeapon(TAirToAirLinkedRailgun) {},
        LinkedRailGun2 = ClassWeapon(TAirToAirLinkedRailgun) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        TAirUnit.OnStopBeingBuilt(self,builder,layer)
        --Turns Jamming off when unit is built
        self:SetScriptBit('RULEUTC_JammingToggle', true)
    end,
    
    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator.Army == self.Army and instigator.Blueprint.CategoriesHash.STRATEGICBOMBER then
            return
        end

        TAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}

TypeClass = UEA0304
