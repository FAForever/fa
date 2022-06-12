--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB0101/UAB0101_script.lua
--**  Author(s):  David Tomandl, Gordon Duclos
--**
--**  Summary  :  Aeon Land Factory Tier 1 Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ALandFactoryUnit = import('/lua/aeonunits.lua').ALandFactoryUnit

UAB0101 = Class(ALandFactoryUnit) {
    GetUpgradeAnimation = function(self, unitBeingBuilt) 
        if unitBeingBuilt.BlueprintId == 'test001' then 
            return self.Blueprint.Display.Animation1 
        else
            return self.Blueprint.Display.Animation2 
        end 
    end,
}

TypeClass = UAB0101