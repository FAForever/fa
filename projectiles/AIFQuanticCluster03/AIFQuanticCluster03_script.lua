----------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFQuanticCluster03/AIFQuanticCluster03_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  Quantic Cluster Projectile script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local AQuantumCluster = import("/lua/aeonprojectiles.lua").AQuantumCluster

---@class AIFQuanticCluster03 : AQuantumCluster
AIFQuanticCluster03 = ClassProjectile(AQuantumCluster) {
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}
TypeClass = AIFQuanticCluster03