--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2101/URB2101_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Light Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class URB2101 : CStructureUnit, FastDecayComponent
URB2101 = ClassUnit(CStructureUnit, FastDecayComponent) {

    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {}
    },

    ---@param self URB2101
    OnCreate = function(self)
        CStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = URB2101
