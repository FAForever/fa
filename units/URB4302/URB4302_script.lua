--****************************************************************************
--**
--**  File     :  /cdimage/units/URB4302/URB4302_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Strategic Missile Defense Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAMEMPMissileWeapon = import("/lua/cybranweapons.lua").CAMEMPMissileWeapon
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class URB4302 : CStructureUnit
URB4302 = ClassUnit(CStructureUnit) {
    Weapons = {
        MissileRack = ClassWeapon(CAMEMPMissileWeapon) {
            FxMuzzleFlash = EffectTemplate.CAntiNukeLaunch01,
        },
    },
}

TypeClass = URB4302