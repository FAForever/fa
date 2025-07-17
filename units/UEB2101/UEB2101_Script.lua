--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2101/UEB2101_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Terran Light Gun Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TDFLightPlasmaCannonWeapon = import("/lua/terranweapons.lua").TDFLightPlasmaCannonWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class UEB2101 : TStructureUnit, FastDecayComponent
UEB2101 = ClassUnit(TStructureUnit, FastDecayComponent) {
    Weapons = {
        MainGun = ClassWeapon(TDFLightPlasmaCannonWeapon) {}
    },

    ---@param self UEB2101
    OnCreate = function(self)
        TStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = UEB2101