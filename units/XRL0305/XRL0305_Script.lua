--****************************************************************************
--**
--**  File     :  /cdimage/units/XRL0305/XRL0305_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Siege Assault Bot Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local CWeapons = import("/lua/cybranweapons.lua")
local CDFHeavyDisintegratorWeapon = CWeapons.CDFHeavyDisintegratorWeapon
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon
local CIFSmartCharge = import("/lua/cybranweapons.lua").CIFSmartCharge

---@class XRL0305 : CWalkingLandUnit
XRL0305 = ClassUnit(CWalkingLandUnit)
{
    Weapons = {
        Disintigrator = ClassWeapon(CDFHeavyDisintegratorWeapon) {},
        Torpedo = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo = ClassWeapon(CIFSmartCharge) {},
    },
}
TypeClass = XRL0305