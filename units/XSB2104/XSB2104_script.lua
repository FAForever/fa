--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB2104/XSB2104_script.lua
--**
--**  Summary  :  Seraphim Anti-Air Gun Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SStructureUnit = import("/lua/seraphimunits.lua").SStructureUnit
local SAAShleoCannonWeapon = import("/lua/seraphimweapons.lua").SAAShleoCannonWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class XSB2104 : SStructureUnit, FastDecayComponent
XSB2104 = ClassUnit(SStructureUnit, FastDecayComponent) {

    Weapons = {
        AAGun = ClassWeapon(SAAShleoCannonWeapon) {
            FxMuzzleScale = 2.25,
        },
    },

    ---@param self XSB2104
    OnCreate = function(self)
        SStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = XSB2104
