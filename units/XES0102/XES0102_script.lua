--****************************************************************************
--**
--**  File     :  /units/XES0102/XES0102_script.lua
--**
--**  Summary  :  UEF Anti-Sub boat
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponFile = import("/lua/terranweapons.lua")
local TANTorpedoAngler = WeaponFile.TANTorpedoAngler
local TIFSmartCharge = WeaponFile.TIFSmartCharge

---@class XES0102 : TSeaUnit
XES0102 = ClassUnit(TSeaUnit) {

    Weapons = {
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
        AntiTorpedo = ClassWeapon(TIFSmartCharge) {},
    },    
}

TypeClass = XES0102