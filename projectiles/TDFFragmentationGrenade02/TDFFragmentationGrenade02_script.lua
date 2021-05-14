#****************************************************************************
#**
#**  File     :  /data/projectiles/TDFFragmentationGrenade02/TDFFragmentationGrenade02_script.lua
#**  Author(s):  Matt Vainio
#**
#**  Summary  :  UEF Fragmentation Shells, DEL0204
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local TFragmentationGrenade2 = import('/lua/terranprojectiles.lua').TFragmentationGrenade2
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

TDFFragmentationGrenade02 = Class(TFragmentationGrenade2) {
    OnImpact = function(self, TargetType, targetEntity)
        if TargetType != 'Shield' and TargetType != 'Water' and TargetType != 'Air' and TargetType != 'UnitAir' and TargetType != 'Projectile' then
            local rotation = RandomFloat(0,2*math.pi)
            local size = RandomFloat(7.5,10.0)
            CreateDecal(self:GetPosition(), rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 15, self:GetArmy())
        end
        TFragmentationGrenade2.OnImpact(self, TargetType, targetEntity)
    end,
}

TypeClass = TDFFragmentationGrenade02 