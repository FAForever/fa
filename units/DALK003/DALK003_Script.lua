------------------------------------
-- Author(s):  Mikko Tyster       --
-- Summary  :  Aeon T3 Anti-Air   --
-- Copyright © 2008 Blade Braver! --
------------------------------------

local AWalkingLandUnit = import("/lua/aeonunits.lua").AWalkingLandUnit
local AAAZealotMissileWeapon = import("/lua/aeonweapons.lua").AAAZealotMissileWeapon

---@class DALK003 : AWalkingLandUnit
DALK003 = ClassUnit(AWalkingLandUnit) {
    Weapons = {
        Missile = ClassWeapon(AAAZealotMissileWeapon) {},
    },
}
TypeClass = DALK003

-- Kept for Mod Support
local EffectUtil = import('/lua/EffectUtilities.lua')