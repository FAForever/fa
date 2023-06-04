--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFInainoStrategicMissileEffect03/SIFInainoStrategicMissileEffect03_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Seraphim nuke effect script, non-damaging
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local EffectTemplate = import("/lua/effecttemplates.lua")

SIFInainoStrategicMissileEffect03 = Class(import("/lua/sim/defaultprojectiles.lua").EmitterProjectile) {
    FxTrails = EffectTemplate.SIFInainoHitRingProjectileFxTrails01,
}
TypeClass = SIFInainoStrategicMissileEffect03

