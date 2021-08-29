------------------------------------------------------------
--
--  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--  Author(s):  Gordon Duclos, Aaron Lundquist
--
--  Summary  :  Thuntho Artillery Shell Projectile script
--              Seraphim T1 Artillery : XSL0103
--
--  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------

local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local SThunthoArtilleryShell2 = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShell2Opti

-- globals as upvalues for performance 
local DamageArea = DamageArea
local CreateDecal = CreateDecal

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition

-- attach for CTRL + SHIFT F replacement

SIFThunthoArtilleryShell02 = Class(SThunthoArtilleryShell2) {
    OnImpact = function(self, targetType, targetEntity)
        local pos = EntityGetPosition(self)

        local army = self.Army
        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        data.DamageAmount = data.DamageAmount - 2
        
        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = Random() * 2 * 3.141592
            CreateDecal(pos, rotation, 'crater_radial01_albedo', '', 'Albedo', radius-1, radius-1, 100, 10, army)
        end
        
        SThunthoArtilleryShell2.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFThunthoArtilleryShell02