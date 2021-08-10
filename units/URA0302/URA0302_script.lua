#****************************************************************************
#**
#**  File     :  /cdimage/units/URA0302/URA0302_script.lua
#**  Author(s):  David Tomandl
#**
#**  Summary  :  Cybran Spy Plane Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local CAirUnit = import('/lua/cybranunits.lua').CAirUnit

URA0302 = Class(CAirUnit) {
    OnStopBeingBuilt = function(self,builder,layer)
        CAirUnit.OnStopBeingBuilt(self,builder,layer)
    end,
}
TypeClass = URA0302