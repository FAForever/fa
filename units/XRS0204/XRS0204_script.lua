--****************************************************************************
--**
--**  File     :  /data/units/XRS0204/XRS0204_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Sub Killer Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSubUnit = import("/lua/cybranunits.lua").CSubUnit
local WeaponsFile = import("/lua/cybranweapons.lua")
local CANNaniteTorpedoWeapon = WeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = WeaponsFile.CIFSmartCharge

---@class XRS0204 : CSubUnit
XRS0204 = ClassUnit(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,

    Weapons = {
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo01 = ClassWeapon(CIFSmartCharge) {},
        AntiTorpedo02 = ClassWeapon(CIFSmartCharge) {},
    },
    OnCreate = function(self)
        CSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = XRS0204