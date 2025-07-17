--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2101/UAB2101_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Light Laser Tower Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local ADFGravitonProjectorWeapon = import("/lua/aeonweapons.lua").ADFGravitonProjectorWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class UAB2101 : AStructureUnit, FastDecayComponent
UAB2101 = ClassUnit(AStructureUnit, FastDecayComponent) {
    Weapons = {
        MainGun = ClassWeapon(ADFGravitonProjectorWeapon) {},
    },

    ---@param self UAB2101
    OnCreate = function(self)
        AStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = UAB2101