---------------------------------------------------------------------------
-- File     :  /cdimage/units/URB4201/URB4201_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  Cybran Phalanx Gun Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------

local CAmphibiousStructureUnit = import('/lua/cybranunits.lua').CAmphibiousStructureUnit
local CAMZapperWeapon = import('/lua/cybranweapons.lua').CAMZapperWeapon

URB4201 = Class(CAmphibiousStructureUnit) {
    Weapons = {
        Turret01 = Class(CAMZapperWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        CAmphibiousStructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:HideBones({'Turret_Muzzle'}, false)
    end,
}

TypeClass = URB4201
