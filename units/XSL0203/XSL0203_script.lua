-----------------------------------------------------------------
-- File     :  /cdimage/units/XSL0203/XSL0203_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos
-- Summary  :  Seraphim Amphibious Tank Script
-- Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local SHoverLandUnit = import("/lua/seraphimunits.lua").SHoverLandUnit
local SDFThauCannon = import("/lua/seraphimweapons.lua").SDFThauCannon
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit

XSL0203 = ClassUnit(SHoverLandUnit, SlowHover) {
    Weapons = {
        TauCannon01 = ClassWeapon(SDFThauCannon){
            FxMuzzleFlashScale = 0.5,
        },
    },
}
TypeClass = XSL0203
