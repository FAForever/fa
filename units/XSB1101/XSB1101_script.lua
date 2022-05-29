#****************************************************************************
#**
#**  File     :  /cdimage/units/XSB1101/XSB1101_script.lua
#**  Author(s):  Jessica St. Croix, Gordon Duclos
#**
#**  Summary  :  Seraphim T1 Power Generator Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
XSB1101 = Class(import('/lua/seraphimunits.lua').SEnergyCreationUnit) {
    AmbientEffects = 'ST1PowerAmbient',
}
TypeClass = XSB1101