--****************************************************************************
--**
--**  File     :  /data/units/XAS0306/XAS0306_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Aeon Missile Ship Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local AIFMissileTacticalSerpentine02Weapon = import("/lua/aeonweapons.lua").AIFMissileTacticalSerpentine02Weapon
local AIFQuasarAntiTorpedoWeapon = import("/lua/aeonweapons.lua").AIFQuasarAntiTorpedoWeapon

---@class XAS0306 : ASeaUnit
XAS0306 = ClassUnit(ASeaUnit) {
    Weapons = {
        AntiTorpedoRight1 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoRight2 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoLeft1 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoLeft2 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        MissileRackFront = ClassWeapon(AIFMissileTacticalSerpentine02Weapon) {},
        MissileRackBack = ClassWeapon(AIFMissileTacticalSerpentine02Weapon) {},
    },
}

TypeClass = XAS0306