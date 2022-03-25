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

local VectorCached = Vector(0, 0, 0)

local Random = Random 
local DamageArea = DamageArea
local CreateDecal = CreateDecal
local CreateTrail = CreateTrail

local EntityGetPositionXYZ = _G.moho.entity_methods.GetPositionXYZ

local SThunthoArtilleryShell2 = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShell2

SIFThunthoArtilleryShell02 = Class(SThunthoArtilleryShell2) {

    OnImpact = function(self, targetType, targetEntity)
        SThunthoArtilleryShell2.OnImpact(self, targetType, targetEntity)

        -- cache the position
        local vc = VectorCached
        vc[1], vc[2], vc[3] = EntityGetPositionXYZ(self)

        -- knock over some trees
        local radius = self.DamageData.DamageRadius
        DamageArea( self, vc, radius, 1, 'KnockTree', false )
        
        -- create a decal if we hit terrain
        if targetType == "Terrain" then            
            CreateDecal(
                vc,                             -- position
                6.28 * Random(),                -- orientation
                'crater_radial01_albedo',       -- regular texture
                '',                             -- special texture
                'Albedo',                       -- type
                radius-1,                       -- radius
                radius-1,                       -- ??
                100,                            -- LOD
                10,                             -- duration
                self.Army                       -- army 
            )
        end
    end,
}
TypeClass = SIFThunthoArtilleryShell02