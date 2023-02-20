--****************************************************************************
--**
--**  File     :  /data/units/XAA0306/XAA0306_script.lua
--**  Author(s):  Jessica St. Croix, Matt Vainio
--**
--**  Summary  :  Aeon Torpedo Cluster Bomber Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local AAirUnit = import("/lua/aeonunits.lua").AAirUnit
local AANTorpedoCluster = import("/lua/aeonweapons.lua").AANTorpedoCluster


---@class XAA0306 : AAirUnit
XAA0306 = ClassUnit(AAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(AANTorpedoCluster) {},
    },
}

TypeClass = XAA0306