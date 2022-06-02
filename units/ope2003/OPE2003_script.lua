--****************************************************************************
--**
--**  File     :  /cdimage/units/OPE2003/OPE2003_script.lua
--**  Author(s):  David Tomandl
--**
--**  Summary  :  Operation E2 Civilian Transport Truck
--**
--**  Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TLandUnit = import('/lua/terranunits.lua').TLandUnit

OPE2003 = Class(TLandUnit) {
    KickupBones = {'Kickup_R','Kickup_L'},
}

TypeClass = OPE2003