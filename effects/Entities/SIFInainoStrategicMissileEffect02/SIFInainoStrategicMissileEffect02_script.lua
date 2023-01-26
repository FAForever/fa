--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFInainoStrategicMissileEffect02/SIFInainoStrategicMissileEffect02_script.lua
--**  Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
--**
--**  Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFInainoStrategicMissileEffect02 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SIFInainoPlumeFxTrails02,
	FxImpactTrajectoryAligned = true,
}
TypeClass = SIFInainoStrategicMissileEffect02
