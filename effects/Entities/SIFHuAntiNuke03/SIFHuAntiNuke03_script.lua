--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFHuAntiNuke03/SIFHuAntiNuke03_script.lua
--**  Author(s):  Greg Kohne
--**
--**  Summary  : Seraphim Anti Nuke Missile Hit Small Tendrils
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SIFHuAntiNuke = import("/lua/seraphimprojectiles.lua").SIFKhuAntiNukeSmallTendril
SIFHuAntiNuke03 = Class(SIFHuAntiNuke) {

    OnCreate = function(self)
        SIFHuAntiNuke.OnCreate(self)
    end,
}
TypeClass = SIFHuAntiNuke03

