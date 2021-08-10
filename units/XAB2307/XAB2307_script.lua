#****************************************************************************
#**
#**  File     :  /data/units/XAB2307/XAB2307_script.lua
#**  Author(s):  Dru Staltman, Gordon Duclos
#**
#**  Summary  :  Aeon T3 Rapid Fire Artillery
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit
local AIFQuanticArtillery = import('/lua/aeonweapons.lua').AIFQuanticArtillery

XAB2307 = Class(AStructureUnit) {
    Weapons = {
        MainGun = Class(AIFQuanticArtillery) {},
    },
}
TypeClass = XAB2307