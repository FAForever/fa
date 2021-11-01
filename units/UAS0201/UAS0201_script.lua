#****************************************************************************
#**
#**  File     :  /cdimage/units/UAS0201/UAS0201_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon Destroyer Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local AeonWeapons = import('/lua/aeonweapons.lua')
local AANDepthChargeBombWeapon = AeonWeapons.AANDepthChargeBombWeapon
local AANChronoTorpedoWeapon = AeonWeapons.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = AeonWeapons.AIFQuasarAntiTorpedoWeapon

--Custom files
local NavalCannonOblivionWeapon = import('/lua/aeon_naval_weapons.lua').ADFCannonOblivionNaval


UAS0201 = Class(ASeaUnit)({
    BackWakeEffect = {},
    Weapons = {
        FrontTurret = Class(NavalCannonOblivionWeapon)({}),
        DepthCharge = Class(AANDepthChargeBombWeapon)({}),
        Torpedo1 = Class(AANChronoTorpedoWeapon)({}),
        Torpedo2 = Class(AANChronoTorpedoWeapon)({}),
        AntiTorpedo = Class(AIFQuasarAntiTorpedoWeapon)({}),
        AntiTorpedo2 = Class(AIFQuasarAntiTorpedoWeapon)({}),
    },
})

TypeClass = UAS0201
