--****************************************************************************
--**
--**  File     :  /cdimage/units/UEB5208/UEB5208_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  UEF Temporary Sonar Beacon Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local Unit = import("/lua/sim/unit.lua").Unit

-- upvlaue for perfomance
local TrashBagAdd = TrashBag.Add
local ForkThread = ForkThread
local WaitSeconds = WaitSeconds

---@class UEB5208 : Unit
UEB5208 = ClassUnit(Unit) {


    OnCreate = function(self)
        local trash = self.Trash

        Unit.OnCreate(self)
        TrashBagAdd(trash,ForkThread( self.WaitingToDie, self ))
    end,

    WaitingToDie = function(self)
        WaitSeconds(120)
        self:Destroy()
    end,
}

TypeClass = UEB5208