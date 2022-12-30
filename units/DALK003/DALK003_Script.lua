--****************************************************************************
--**
--**  Author(s):  Mikko Tyster
--**
--**  Summary  :  Aeon T3 Anti-Air
--**
--**  Copyright © 2008 Blade Braver!
--****************************************************************************

local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local AAAZealotMissileWeapon = import("/lua/aeonweapons.lua").AAAZealotMissileWeapon
local EffectUtil = import("/lua/effectutilities.lua")

---@class DALK003 : AWalkingLandUnit
DALK003 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        Missile = ClassWeapon(AAAZealotMissileWeapon) {},
    },
}
TypeClass = DALK003