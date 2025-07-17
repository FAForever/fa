--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2109/XSB2109_script.lua
--**  Author(s):  Jessica St. Croix, Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Seraphim Torpedo Launcher Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SANUallCavitationTorpedo = import("/lua/seraphimweapons.lua").SANUallCavitationTorpedo
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class XSB2109 : SStructureUnit, FastDecayComponent
XSB2109 = ClassUnit(SStructureUnit, FastDecayComponent) {
    Weapons = {
        Turret01 = ClassWeapon(SANUallCavitationTorpedo) {},
    },

    ---@param self XSB2109
    OnCreate = function(self)
        SStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}
TypeClass = XSB2109