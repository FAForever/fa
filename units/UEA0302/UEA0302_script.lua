--****************************************************************************
--**
--**  File     :  /cdimage/units/UEA0302/UEA0302_script.lua
--**  Author(s):  Jessica St. Croix, David Tomandl
--**
--**  Summary  :  UEF Spy Plane Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TAirUnit = import("/lua/terranunits.lua").TAirUnit
-- The torpedo is a temporary implementation of the ability to launch sonar buoys.
-- Currently, a torpedo is dropped into the water that transforms into the buoy.
-- Once we get proper "alt abilities", we can switch the buoy creation to use that system.
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler

---@class UEA0302 : TAirUnit
UEA0302 = ClassUnit(TAirUnit) {
-- Disabling for now, while Design decides whether they want this functionality
--    Weapons = {
--        BuoyLauncher = ClassWeapon(TANTorpedoAngler) {
--            FiringMuzzleBones = {'Projectile',},
--        },
--    },

}

TypeClass = UEA0302