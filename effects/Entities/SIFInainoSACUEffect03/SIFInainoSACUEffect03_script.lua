#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFInainoSACUStrategicMissileEffect03/SIFInainoSACUStrategicMissileEffect03_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  Seraphim nuke effect script, non-damaging
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')

SIFInainoSACUStrategicMissileEffect03 = Class(import('/lua/sim/defaultprojectiles.lua').EmitterProjectile) {
    FxTrails = EffectTemplate.SIFSerSCUHitRingProjectileFxTrails01,
}
TypeClass = SIFInainoSACUStrategicMissileEffect03

