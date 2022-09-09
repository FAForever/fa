-------------------------------------------------------------------------------
--  File     :  /data/projectiles/SIFInainoSACUStrategicMissileEffect01/SIFInainoSACUStrategicMissileEffect01_script.lua
--  Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
--
--  Summary  :  Ohwalli Strategic Bomb effect script, non-damaging
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFInainoSACUStrategicMissileEffect01 = Class(import('/lua/sim/defaultprojectiles.lua').EmitterProjectile) {
	FxTrails = EffectTemplate.SIFSerSCUPlumeFxTrails01,
	FxImpactTrajectoryAligned = true,
}
TypeClass = SIFInainoSACUStrategicMissileEffect01
