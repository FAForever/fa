#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB1201/UAB1201_script.lua
#**  Author(s):  John Comes, Dave Tomandl, Jessica St. Croix
#**
#**  Summary  :  Aeon T2 Power Generator Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AEnergyCreationUnit = import('/lua/aeonunits.lua').AEnergyCreationUnit

UAB1201 = Class(AEnergyCreationUnit) {
    AmbientEffects = 'AT2PowerAmbient',
}

TypeClass = UAB1201