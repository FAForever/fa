--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect02/SIFExperimentalStrategicMissileEffect02_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Seraphim experimental nuke effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFExperimentalStrategicMissileEffect02 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
    FxTrails = EffectTemplate.SIFExperimentalStrategicMissileFxTrails01,
}
TypeClass = SIFExperimentalStrategicMissileEffect02

