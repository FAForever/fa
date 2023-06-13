--****************************************************************************
--**
--**  File     :  /data/projectiles/TIFFragmentationShell01/TIFFragmentationShell01_script.lua
--**  Author(s):  Matt Vainio
--**
--**  Summary  :  Terran Fragmentation Shells, DEL0204
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local EffectTemplate = import("/lua/effecttemplates.lua")

TIFFragmentationShell01 = ClassProjectile(TArtilleryProjectile) {
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
}
TypeClass = TIFFragmentationShell01