#****************************************************************************
#**
#**  File     :  /data/projectiles/TIFFragmentationShell01/TIFFragmentationShell01_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  Terran Fragmentation Shells, DEL0204
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TArtilleryProjectile = import('/lua/terranprojectiles.lua').TArtilleryProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TIFFragmentationShell01 = Class(TArtilleryProjectile) {
    FxTrails     = EffectTemplate.TFragmentationSensorShellTrail,
    FxImpactUnit = EffectTemplate.TFragmentationSensorShellHit,
    FxImpactLand = EffectTemplate.TFragmentationSensorShellHit,
    
    #OnCreate = function(self)
    #    TArtilleryProjectile.OnCreate(self)
    #    #local army = self:GetArmy()
    #    #for i in self.FxTrails do
    #    #    CreateEmitterOnEntity(self, army, self.FxTrails[i]):ScaleEmitter(self.FxTrailScale):OffsetEmitter(0, 0, self.FxTrailOffset)
    #    #end
    #    CreateEmitterAtBone( self, -1, self:GetArmy(), '/effects/emitters/mortar_munition_02_flare_emit.bp')
    #end,
}
TypeClass = TIFFragmentationShell01