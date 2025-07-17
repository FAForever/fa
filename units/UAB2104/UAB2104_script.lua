--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB2104/UAB2104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Aeon Anti-Air Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AStructureUnit = import("/lua/aeonunits.lua").AStructureUnit
local AAASonicPulseBatteryWeapon = import("/lua/aeonweapons.lua").AAASonicPulseBatteryWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class UAB2104 : AStructureUnit, FastDecayComponent
UAB2104 = ClassUnit(AStructureUnit, FastDecayComponent) {

    Weapons = {
        AAGun = ClassWeapon(AAASonicPulseBatteryWeapon) {
            FxMuzzleScale = 2.25,
        },
    },

    ---@param self UAB2104
    OnCreate = function(self)
        AStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = UAB2104
