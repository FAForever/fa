------------------------------------------------------------
--
--  File     :  /data/projectiles/AIFFragmentationSensorShell03/AIFFragmentationSensorShell03_script.lua
--  Author(s):  Drew Staltman, Gordon Duclos
--
--  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script
--				 Child Projectile after 2st split
--              Aeon Salvation : XAB2307
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile03
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFFragmentationSensorShell03 = Class(AArtilleryFragmentationSensorShellProjectile) {
    OnImpact = function(self, targetType, targetEntity)
        local rotation = RandomFloat(0,2*math.pi)
        local size = RandomFloat(2.25,3.75)
        local pos = self:GetPosition()
        
        CreateDecal(pos, rotation, 'scorch_004_albedo', '', 'Albedo', size, size, 300, 15, self:GetArmy())
        
        local radius = self.DamageData.DamageRadius
        if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        AArtilleryFragmentationSensorShellProjectile.OnImpact( self, targetType, targetEntity )
    end,	
}
TypeClass = AIFFragmentationSensorShell03