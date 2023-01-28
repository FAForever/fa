-----------------------------------------------------------------
-- File     :  /cdimage/units/XSS0302/XSS0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos, Aaron Lundquist
-- Summary  :  Seraphim Battleship Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local SSeaUnit = import("/lua/seraphimunits.lua").SSeaUnit
local SeraphimWeapons = import("/lua/seraphimweapons.lua")
local SDFHeavyQuarnonCannon = SeraphimWeapons.SDFHeavyQuarnonCannon
local SAMElectrumMissileDefense = SeraphimWeapons.SAMElectrumMissileDefense
local SAAOlarisCannonWeapon = SeraphimWeapons.SAAOlarisCannonWeapon
local SIFInainoWeapon = SeraphimWeapons.SIFInainoWeapon

---@class XSS0302 : SSeaUnit
XSS0302 = ClassUnit(SSeaUnit) {
    Weapons = {
        BackTurret = ClassWeapon(SDFHeavyQuarnonCannon) {},
        FrontTurret = ClassWeapon(SDFHeavyQuarnonCannon) {},
        MidTurret = ClassWeapon(SDFHeavyQuarnonCannon) {},
        AntiMissileLeft = ClassWeapon(SAMElectrumMissileDefense) {},
        AntiMissileRight = ClassWeapon(SAMElectrumMissileDefense) {},
        AntiAirLeft = ClassWeapon(SAAOlarisCannonWeapon) {},
        AntiAirRight = ClassWeapon(SAAOlarisCannonWeapon) {},
        InainoMissiles = ClassWeapon(SIFInainoWeapon) {},
    },
}

TypeClass = XSS0302
