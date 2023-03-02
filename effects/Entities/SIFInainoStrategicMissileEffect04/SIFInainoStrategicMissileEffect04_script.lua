--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFInainoStrategicMissileEffect04/SIFInainoStrategicMissileEffect04_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Inaino Strategic Bomb effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFInainoStrategicMissileEffect04 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
	FxTrails = EffectTemplate.SIFInainoPlumeFxTrails03,
}
TypeClass = SIFInainoStrategicMissileEffect04
