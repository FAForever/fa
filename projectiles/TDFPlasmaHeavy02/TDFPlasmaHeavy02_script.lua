------------------------------------------------------------------
--
--  File     :  /effects/projectiles/TDFPlasmsaHeavy02/TDFPlasmsaHeavy02_script.lua
--  Author(s):  Gordon Duclos
--
--  Summary  :  UEF Heavy Plasma Cannon projectile, UEA0305 : T3 uef gunship & XEA0306 : T3 transport
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local THeavyPlasmaCannonProjectile = import('/lua/terranprojectiles.lua').THeavyPlasmaCannonProjectile
local EffectTemplate = import('/lua/EffectTemplates.lua')

TDFPlasmaHeavy02 = Class(THeavyPlasmaCannonProjectile) {
    FxTrails = EffectTemplate.TPlasmaCannonHeavyMunition02,
    
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        -- local FriendlyFire = self.DamageData.DamageFriendly and radius ~=0
        
        -- DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )
        -- DamageArea( self, pos, 0.5, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' and targetType ~= 'Unit' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'scorch_001_albedo', '', 'Albedo', 0.5, 0.5, 50, 15, army)
        end
        
        THeavyPlasmaCannonProjectile.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = TDFPlasmaHeavy02

