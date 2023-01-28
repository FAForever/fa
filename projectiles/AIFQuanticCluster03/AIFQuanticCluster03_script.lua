--****************************************************************************
--**
--**  File     :  /data/projectiles/AIFQuanticCluster03/AIFQuanticCluster03_script.lua
--**  Author(s):  Drew Staltman, Gordon Duclos
--**
--**  Summary  :  Quantic Cluster Projectile script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local EffectTemplate = import("/lua/effecttemplates.lua")

AIFQuanticCluster03 = ClassProjectile(import("/lua/aeonprojectiles.lua").AQuantumCluster) {
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}
TypeClass = AIFQuanticCluster03