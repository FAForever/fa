#****************************************************************************
#**
#**  File     :  /data/projectiles/AIFFragmentationSensorShell03/AIFFragmentationSensorShell03_script.lua
#**  Author(s):  Drew Staltman, Gordon Duclos
#**
#**  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
#**				 Child Projectile after 2st split	
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile03
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFFragmentationSensorShell03 = Class(AArtilleryFragmentationSensorShellProjectile) {
    OnImpact = function(self, TargetType, targetEntity)
        local rotation = RandomFloat(0,2*math.pi)
        local size = RandomFloat(2.25,3.75)
        
        CreateDecal(self:GetPosition(), rotation, 'scorch_004_albedo', '', 'Albedo', size, size, 300, 15, self:GetArmy())
 
        AArtilleryFragmentationSensorShellProjectile.OnImpact( self, TargetType, targetEntity )
    end,	
}
TypeClass = AIFFragmentationSensorShell03