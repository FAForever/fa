#****************************************************************************
#**
#**  File     :  /cdimage/units/UEB5208/UEB5208_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  UEF Temporary Sonar Beacon Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local Unit = import('/lua/sim/Unit.lua').Unit

UEB5208 = Class(Unit) {

    OnCreate = function(self)
        Unit.OnCreate(self)
        ForkThread( self.WaitingToDie, self )
    end,

    WaitingToDie = function(self)
        WaitSeconds(120)
        self:Destroy()
    end,
}

TypeClass = UEB5208