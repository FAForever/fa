-- File     :  /cdimage/units/UAS0201/UAS0201_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix
-- Summary  :  Aeon Destroyer Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local ASeaUnit = import("/lua/aeonunits.lua").ASeaUnit
local AeonWeapons = import("/lua/aeonweapons.lua")
local AANDepthChargeBombWeapon02 = AeonWeapons.AANDepthChargeBombWeapon02
local AANChronoTorpedoWeapon = AeonWeapons.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = AeonWeapons.AIFQuasarAntiTorpedoWeapon
local NavalCannonOblivionWeapon = AeonWeapons.ADFCannonOblivionNaval

---@class UAS0201 : ASeaUnit
UAS0201 = ClassUnit(ASeaUnit) {
    BackWakeEffect = {},
    Weapons = {
        FrontTurret = ClassWeapon(NavalCannonOblivionWeapon) {},
        DepthCharge = ClassWeapon(AANDepthChargeBombWeapon02) {},
        Torpedo1 = ClassWeapon(AANChronoTorpedoWeapon) {},
        Torpedo2 = ClassWeapon(AANChronoTorpedoWeapon) {},
        AntiTorpedo = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo2 = ClassWeapon(AIFQuasarAntiTorpedoWeapon) {},
    },
}
TypeClass = UAS0201