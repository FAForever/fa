--****************************************************************************
--**
--**  File     :  /cdimage/units/UAB1101/UAB1101_script.lua
--**  Author(s):  David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Aeon Power Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local AEnergyCreationUnit = import("/lua/aeonunits.lua").AEnergyCreationUnit

---@class UAB1101 : AEnergyCreationUnit
UAB1101 = ClassUnit(AEnergyCreationUnit) {
    AmbientEffects = 'AT1PowerAmbient',
    
}

TypeClass = UAB1101