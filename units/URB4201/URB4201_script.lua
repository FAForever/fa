#****************************************************************************
#**
#**  File     :  /cdimage/units/URB4201/URB4201_script.lua
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos
#**
#**  Summary  :  Cybran Phalanx Gun Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CStructureUnit = import('/lua/cybranunits.lua').CStructureUnit
local CAMZapperWeapon = import('/lua/cybranweapons.lua').CAMZapperWeapon

URB4201 = Class(CStructureUnit) {
    
    Weapons = {
        Turret01 = Class(CAMZapperWeapon) {},
    },

    OnStopBeingBuilt = function(self,builder,layer)
        CStructureUnit.OnStopBeingBuilt(self,builder,layer)
        self:HideBone('Turret_Muzzle', false)
    end,
}

TypeClass = URB4201