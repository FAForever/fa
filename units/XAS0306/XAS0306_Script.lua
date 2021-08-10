#****************************************************************************
#**
#**  File     :  /data/units/XAS0306/XAS0306_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Aeon Missile Ship Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local AIFMissileTacticalSerpentine02Weapon = import('/lua/aeonweapons.lua').AIFMissileTacticalSerpentine02Weapon
local AIFQuasarAntiTorpedoWeapon = import('/lua/aeonweapons.lua').AIFQuasarAntiTorpedoWeapon

XAS0306 = Class(ASeaUnit) {
    FxDamageScale = 2,
    DestructionTicks = 400,

    Weapons = {
        AntiTorpedoRight1 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoRight2 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoLeft1 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedoLeft2 = Class(AIFQuasarAntiTorpedoWeapon) {},
        MissileRackFront = Class(AIFMissileTacticalSerpentine02Weapon) {},
        MissileRackBack = Class(AIFMissileTacticalSerpentine02Weapon) {},
    },
}

TypeClass = XAS0306