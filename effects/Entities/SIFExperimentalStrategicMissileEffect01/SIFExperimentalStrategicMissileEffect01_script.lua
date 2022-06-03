#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect01/SIFExperimentalStrategicMissileEffect01_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  Inaino Strategic Bomb effect script, non-damaging
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFExperimentalStrategicMissileEffect01 = Class(import('/lua/sim/defaultprojectiles.lua').EmitterProjectile) {
	FxTrails = EffectTemplate.SIFExperimentalStrategicMissilePlumeFxTrails01,
}
TypeClass = SIFExperimentalStrategicMissileEffect01
