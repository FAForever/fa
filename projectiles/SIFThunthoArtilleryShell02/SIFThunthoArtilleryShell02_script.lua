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
        local army = self.Army
        local data = self.DamageData
        local radius = data.DamageRadius
        local FriendlyFire = data.DamageFriendly
        local pos = EntityGetPosition(self)
        
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        DamageArea( self, pos, radius, 1, 'Force', FriendlyFire )
        
        data.DamageAmount = data.DamageAmount - 2
        
        if targetType == 'Terrain' then
            CreateDecal(pos, Random() * 6.28, 'crater_radial01_albedo', '', 'Albedo', radius-1, radius-1, 100, 10, army)
        end
        
        SThunthoArtilleryShell2.OnImpact(self, targetType, targetEntity)
    end,
}
TypeClass = SIFThunthoArtilleryShell02