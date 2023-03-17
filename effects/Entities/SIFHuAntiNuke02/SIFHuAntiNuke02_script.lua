--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFHuAntiNuke02/SIFHuAntiNuke02_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  : Seraphim Anti Nuke Missile Hit Large Tendrils
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SIFHuAntiNuke = import("/lua/seraphimprojectiles.lua").SIFKhuAntiNukeTendril
SIFHuAntiNuke02 = Class(SIFHuAntiNuke) {

    OnCreate = function(self)
        SIFHuAntiNuke.OnCreate(self)
    end,
}
TypeClass = SIFHuAntiNuke02

