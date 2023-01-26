--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFExperimentalStrategicMissileEffect04/SIFExperimentalStrategicMissileEffect04_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos
--**
--**  Summary  :  Seraphim Experimental Nuke effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFExperimentalStrategicMissileEffect04 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SIFExperimentalStrategicMissilePlumeFxTrails03,
}
TypeClass = SIFExperimentalStrategicMissileEffect04
