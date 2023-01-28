--****************************************************************************
--**
--**  File     :  /cdimage/units/XSB1201/XSB1201_script.lua
--**  Author(s):  Dru Staltman
--**
--**  Summary  :  Seraphim T2 Power Generator Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
XSB1201 = ClassUnit(import("/lua/seraphimunits.lua").SEnergyCreationUnit) {
    AmbientEffects = 'ST2PowerAmbient',
}
TypeClass = XSB1201