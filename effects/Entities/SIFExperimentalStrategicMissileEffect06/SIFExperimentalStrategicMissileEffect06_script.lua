--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect06/SIFExperimentalStrategicMissileEffect06_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Seraphim experimental nuke effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFExperimentalStrategicMissileEffect06 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
    FxTrails = EffectTemplate.SIFExperimentalStrategicMissilePlumeFxTrails05,
}
TypeClass = SIFExperimentalStrategicMissileEffect06

