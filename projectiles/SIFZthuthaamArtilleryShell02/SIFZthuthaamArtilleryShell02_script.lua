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
    
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        
        if targetType != 'Shield' and targetType != 'Water' and targetType != 'UnitAir' then
            DamageArea( self, pos, radius, 1, 'Force', true )
            DamageArea( self, pos, radius, 1, 'Force', true )
        end
        
        SZthuthaamArtilleryShell.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFZthuthaamArtilleryShell02