#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect05/SIFExperimentalStrategicMissileEffect05_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  Seraphim experimental nuke effect script, non-damaging
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFExperimentalStrategicMissileEffect05 = Class(import('/lua/sim/defaultprojectiles.lua').EmitterProjectile) {
    FxTrails = EffectTemplate.SIFExperimentalStrategicMissilePlumeFxTrails04,
}
TypeClass = SIFExperimentalStrategicMissileEffect05

