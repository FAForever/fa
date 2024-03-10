-- File     :  /cdimage/units/UAB0303/UAB0303_script.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos
-- Summary  :  Aeon Tier 3 Naval Factory Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local ASeaFactoryUnit = import("/lua/aeonunits.lua").ASeaFactoryUnit

-- upvalue for perfomance
local TrashBagAdd = TrashBag.Add

---@class UAB0303 : ASeaFactoryUnit
UAB0303 = ClassUnit(ASeaFactoryUnit) {

    ---@param self UAB0303
    OnCreate = function(self)
        ASeaFactoryUnit.OnCreate(self)
        local bp = self.blueprint
        local trash = self.Trash

        self.BuildPointSlider = CreateSlider(self, bp.Display.BuildAttachBone or 0, -15, 0, 0, -1)
        TrashBagAdd(trash,self.BuildPointSlider)
    end,
}

TypeClass = UAB0303

