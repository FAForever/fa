#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFInainoSACUStrategicMissileEffect04/SIFInainoSACUStrategicMissileEffect04_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  InainoSACU Strategic Bomb effect script, non-damaging
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFInainoSACUStrategicMissileEffect04 = Class(import('/lua/sim/defaultprojectiles.lua').EmitterProjectile) {
	FxTrails = EffectTemplate.SIFSerSCUPlumeFxTrails03,
}
TypeClass = SIFInainoSACUStrategicMissileEffect04
