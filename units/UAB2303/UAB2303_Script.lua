#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB2303/UAB2303_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Light Artillery Installation Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AIFArtilleryMiasmaShellWeapon = import('/lua/aeonweapons.lua').AIFArtilleryMiasmaShellWeapon

UAB2303 = Class(AStructureUnit) {

    Weapons = {
        MainGun = Class(AIFArtilleryMiasmaShellWeapon) {},
    },
}

TypeClass = UAB2303