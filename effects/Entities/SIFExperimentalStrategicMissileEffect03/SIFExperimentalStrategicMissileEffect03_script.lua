--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect03/SIFExperimentalStrategicMissileEffect03_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Inaino Strategic Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFExperimentalStrategicMissileEffect03 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SIFExperimentalStrategicMissilePlumeFxTrails02,
}
TypeClass = SIFExperimentalStrategicMissileEffect03
