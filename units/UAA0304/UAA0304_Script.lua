------------------------------------------------------------------
--  File     :  /cdimage/units/UAA0304/UAA0304_script.lua
--  Author(s):  John Comes, David Tomandl
--  Summary  :  Aeon Strategic Bomber Script
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local AIFBombQuarkWeapon = import("/lua/aeonweapons.lua").AIFBombQuarkWeapon

---@class UAA0304 : AAirUnit
UAA0304 = ClassUnit(AAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(AIFBombQuarkWeapon) {},
    },

    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator.Blueprint.CategoriesHash.STRATEGICBOMBER and instigator.Army == self.Army then
            return
        end
        AAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}
TypeClass = UAA0304