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
XSS0302 = Class(SSeaUnit) {
    FxDamageScale = 2,
    DestructionTicks = 400,

    Weapons = {
        BackTurret = Class(SDFHeavyQuarnonCannon) {},
        FrontTurret = Class(SDFHeavyQuarnonCannon) {},
        MidTurret = Class(SDFHeavyQuarnonCannon) {},
        AntiMissileLeft = Class(SAMElectrumMissileDefense) {},
        AntiMissileRight = Class(SAMElectrumMissileDefense) {},
        AntiAirLeft = Class(SAAOlarisCannonWeapon) {},
        AntiAirRight = Class(SAAOlarisCannonWeapon) {},
        InainoMissiles = Class(SIFInainoWeapon) {},
    },
}

TypeClass = XSS0302
