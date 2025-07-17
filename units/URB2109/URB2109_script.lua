--****************************************************************************
--**
--**  File     :  /cdimage/units/URB2109/URB2109_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Ground-based Torpedo Launcher Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CStructureUnit = import("/lua/cybranunits.lua").CStructureUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon
local FastDecayComponent = import("/lua/sim/units/components/FastDecayUnitComponent.lua").FastDecayComponent


---@class URB2109 : CStructureUnit, FastDecayComponent
URB2109 = ClassUnit(CStructureUnit, FastDecayComponent) {
    Weapons = {
        Turret01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },

    ---@param self URB2109
    OnCreate = function(self)
        CStructureUnit.OnCreate(self)
        self:StartFastDecayThread()
    end,
}

TypeClass = URB2109