--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2104/URB2104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Cybran Anti-Air Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CAAAutocannon = import("/lua/cybranweapons.lua").CAAAutocannon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent


---@class URB2104 : CStructureUnit, FastDecayComponent
URB2104 = ClassUnit(CStructureUnit, FastDecayComponent) {

    Weapons = {
        AAGun = ClassWeapon(CAAAutocannon) {
            FxMuzzleScale = 2.25,
        },
    },

    ---@param self URB2104
    OnCreate = function(self)
        CStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}


TypeClass = URB2104
