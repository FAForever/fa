------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Thuntho Artillery Shell Projectile script
--              Seraphim T1 Artillery : XSL0103
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local SThunthoArtilleryShell2 = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShell2

SIFThunthoArtilleryShell02 = Class(SThunthoArtilleryShell2) {
    OnImpact = function(self, targetType, targetEntity) 
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local army = self.Army
            
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius-1, radius-1, 100, 10, army)
        end
        
        DamageArea( self, pos, radius, 1, 'Force', false )
        DamageArea( self, pos, radius, 1, 'Force', false )
        
        SThunthoArtilleryShell2.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFThunthoArtilleryShell02