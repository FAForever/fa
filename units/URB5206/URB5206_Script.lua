-- File     :  /cdimage/units/URB5206/URB5206_script.lua
-- Author(s):  Jessica St. Croix
-- Summary  :  Cybran Tracking Device Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------
local Unit = import("/lua/sim/unit.lua").Unit

---@class URB5206 : Unit
URB5206 = ClassUnit(Unit) {

    OnCreate = function(self)
        Unit.OnCreate(self)
        ChangeState(self, self.TrackingState)
    end,

    TrackingState = State {
        Main = function(self)
            WaitTicks(3001)
            self:Destroy()
        end,
    },
}


TypeClass = URB5206