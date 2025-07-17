--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2104/UEB2104_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Terran Anti-Air Gun Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TAALinkedRailgun = import("/lua/terranweapons.lua").TAALinkedRailgun
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent


---@class UEB2104 : TStructureUnit, FastDecayComponent
UEB2104 = ClassUnit(TStructureUnit, FastDecayComponent) {
    Weapons = {
        AAGun = ClassWeapon(TAALinkedRailgun) {},
    },

    ---@param self UEB2104
    OnCreate = function(self)
        TStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = UEB2104
