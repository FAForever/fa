--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2101/XSB2101_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Light Laser Tower Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SDFOhCannon = import("/lua/seraphimweapons.lua").SDFOhCannon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class XSB2101 : SStructureUnit, FastDecayComponent
XSB2101 = ClassUnit(SStructureUnit, FastDecayComponent) {
    Weapons = {
        MainGun = ClassWeapon(SDFOhCannon) {},
    },

    ---@param self XSB2101
    OnCreate = function(self)
        SStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}
TypeClass = XSB2101