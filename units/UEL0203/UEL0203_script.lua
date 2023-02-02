--****************************************************************************
--**
--**  File     :  /cdimage/units/UEL0203/UEL0203_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  UEF Amphibious Tank Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")
local THoverLandUnit = import("/lua/terranunits.lua").THoverLandUnit
local TDFRiotWeapon = import("/lua/terranweapons.lua").TDFRiotWeapon
local SlowHover = import("/lua/defaultunits.lua").SlowHoverLandUnit

UEL0203 = ClassUnit(THoverLandUnit, SlowHover) {
    Weapons = {
        Riotgun01 = ClassWeapon(TDFRiotWeapon) {
            FxMuzzleFlash = EffectTemplate.TRiotGunMuzzleFxTank
        },
    },
}

TypeClass = UEL0203