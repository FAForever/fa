-----------------------------------------------------------------
-- File     :  /cdimage/units/URS0304/URS0304_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Strategic Missile Submarine Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CSubUnit = import("/lua/cybranunits.lua").CSubUnit
local CybranWeapons = import("/lua/cybranweapons.lua")
local CIFMissileLoaWeapon = CybranWeapons.CIFMissileLoaWeapon
local CIFMissileStrategicWeapon = CybranWeapons.CIFMissileStrategicWeapon
local CANTorpedoLauncherWeapon = CybranWeapons.CANTorpedoLauncherWeapon

---@class URS0304 : CSubUnit
URS0304 = Class(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        NukeMissile = Class(CIFMissileStrategicWeapon){},
        CruiseMissile = Class(CIFMissileLoaWeapon){},
        Torpedo01 = Class(CANTorpedoLauncherWeapon){},
        Torpedo02= Class(CANTorpedoLauncherWeapon){},
    },

    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetMaintenanceConsumptionActive()
    end,
}

TypeClass = URS0304
