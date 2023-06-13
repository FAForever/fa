--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2302/UAB2302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Long Range Artillery Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AIFArtillerySonanceShellWeapon = import("/lua/aeonweapons.lua").AIFArtillerySonanceShellWeapon

---@class UAB2302 : AStructureUnit
UAB2302 = ClassUnit(AStructureUnit) {
    Weapons = {
        MainGun = ClassWeapon(AIFArtillerySonanceShellWeapon) {},
    },
}

TypeClass = UAB2302