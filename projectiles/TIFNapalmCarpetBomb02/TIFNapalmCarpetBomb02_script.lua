-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/TIFNapalmCarpetBomb02/TIFNapalmCarpetBomb02_script.lua
--  Author(s):  Matt Vainio
--
--  Summary  :  Heavy Napalm Bomb, DEA0202
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local TNapalmHvyCarpetBombProjectile = import('/lua/terranprojectiles.lua').TNapalmHvyCarpetBombProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

TIFNapalmCarpetBomb02 = Class(TNapalmHvyCarpetBombProjectile) {

    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0,2*math.pi)
            local radius = self.DamageData.DamageRadius
            local size = radius + RandomFloat(0.75,2.0)
            local pos = self:GetPosition()
            local army = self.Army

            DamageRing(self, pos, 0.1, radius+1, 10, 'Fire', false, false)
            DamageArea(self, pos, radius, 1, 'Force', true)
            DamageArea(self, pos, radius, 1, 'Force', true)
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', size, size, 150, 30, army)
        end
        TNapalmHvyCarpetBombProjectile.OnImpact(self, targetType, targetEntity)
    end,
}

TypeClass = TIFNapalmCarpetBomb02
