#****************************************************************************
#**
#**  File     :  /data/units/XAB3301/XAB3301_script.lua
#**  Author(s):  Jessica St. Croix, Ted Snook, Dru Staltman
#**
#**  Summary  :  Aeon Quantum Optics Facility Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AStructureUnit = import('/lua/aeonunits.lua').AStructureUnit

# Setup as RemoteViewing child of AStructureUnit
local RemoteViewing = import('/lua/RemoteViewing.lua').RemoteViewing
AStructureUnit = RemoteViewing( AStructureUnit )

XAB3301 = Class( AStructureUnit ) {
}

TypeClass = XAB3301