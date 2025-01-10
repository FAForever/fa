--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB4201/UAB4201_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Phalanx Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAMWillOWisp = import("/lua/aeonweapons.lua").AAMWillOWisp

-- upvalue for perfomance
local CreateRotator = CreateRotator
local TrashBagAdd = TrashBag.Add

---@class UAB4201 : AStructureUnit
UAB4201 = ClassUnit(AStructureUnit) {
    Weapons = {
        AntiMissile = ClassWeapon(AAMWillOWisp) {},
    },
}

TypeClass = UAB4201
