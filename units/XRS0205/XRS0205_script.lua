--****************************************************************************
--**
--**  File     :  /data/units/XRS0205/XRS0205_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Counter-Intelligence Boat Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CIFSmartCharge = import("/lua/cybranweapons.lua").CIFSmartCharge

---@class XRS0205 : CSeaUnit
XRS0205 = ClassUnit(CSeaUnit) {

    Weapons = {
        AntiTorpedo = ClassWeapon(CIFSmartCharge) {},
    },
    
}

TypeClass = XRS0205