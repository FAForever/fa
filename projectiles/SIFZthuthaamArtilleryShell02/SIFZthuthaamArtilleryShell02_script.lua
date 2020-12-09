------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFZthuthaamArtilleryShell02/SIFZthuthaamArtilleryShell02_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Zthuthaam Artillery Shell Projectile script
--              Seraphim T2 Artillery XSB2303
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local SZthuthaamArtilleryShell = import('/lua/seraphimprojectiles.lua').SZthuthaamArtilleryShell

SIFZthuthaamArtilleryShell02 = Class(SZthuthaamArtilleryShell) {
    OnImpact = function(self, targetType, targetEntity)
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
            local rotation = RandomFloat(0,2*math.pi)
            local pos = self:GetPosition()
            local radius = self.DamageData.DamageRadius
            local army = self.Army
            
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
            CreateDecal(pos, rotation, 'nuke_scorch_002_albedo', '', 'Albedo', radius * 2, radius * 2, 200, 100, army)
        end
        
        SZthuthaamArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFZthuthaamArtilleryShell02