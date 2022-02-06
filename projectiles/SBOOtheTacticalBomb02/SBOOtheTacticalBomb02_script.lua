-------------------------------------------------------------------------------
--
--  File     :  /data/projectiles/SBOOtheTacticalBomb02/SBOOtheTacticalBomb02_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Othe Tactical Bomb script, XSA0202
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local SOtheTacticalBomb = import('/lua/seraphimprojectiles.lua').SOtheTacticalBomb

SBOOtheTacticalBomb02 = Class(SOtheTacticalBomb) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~=0
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local army = self.Army
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

            CreateDecal( pos, RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', radius*5, radius*5, 200, 70, army)          
        end
        
		SOtheTacticalBomb.OnImpact(self, targetType, targetEntity) 
    end,
}
TypeClass = SBOOtheTacticalBomb02