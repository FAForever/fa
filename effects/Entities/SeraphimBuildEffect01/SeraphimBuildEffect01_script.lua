--****************************************************************************
--**
--**  File     :  /effects/Entities/SeraphimBuildEffect01/SeraphimBuildEffect01_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Seraphim build effect script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
SeraphimBuildEffect01 = Class(import("/lua/sim/defaultprojectiles.lua").NullShell) {
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,
}
TypeClass = SeraphimBuildEffect01

