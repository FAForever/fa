--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB2109/UEB2109_script.lua
--**  Author(s):  John Comes, David Tomandl
--**
--**  Summary  :  Terran Ground-based Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TStructureUnit = import("/lua/terranunits.lua").TStructureUnit
local TANTorpedoLandWeapon = import("/lua/terranweapons.lua").TANTorpedoLandWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent

---@class UEB2109 : TStructureUnit, FastDecayComponent
UEB2109 = ClassUnit(TStructureUnit, FastDecayComponent) {
    Weapons = {
        Turret01 = ClassWeapon(TANTorpedoLandWeapon) {},
    },

    ---@param self UEB2109
    OnCreate = function(self)
        TStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = UEB2109

