--****************************************************************************
--**
--**  File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
--**  Author(s):  Gordon Duclos, Aaron Lundquist
--**
--**  Summary  :  Thuntho Artillery Shell Projectile script, XSL0103
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local SThunthoArtilleryShell = import('/lua/seraphimprojectiles.lua').SThunthoArtilleryShellOpti
local SThunderStormCannonProjectileSplitFx = import('/lua/EffectTemplates.lua').SThunderStormCannonProjectileSplitFx

-- globals as upvalues for performance 
local Random = Random
local CreateEmitterAtEntity = CreateEmitterAtEntity

-- math functions as upvalues for performance
local MathSin = _G.math.sin
local MathCos = _G.math.cos 

-- moho functions as upvalue for performance
local EntityMethods = _G.moho.entity_methods
local EntityDestroy = EntityMethods.Destroy

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileGetVelocity = ProjectileMethods.GetVelocity
local ProjectileSetVelocity = ProjectileMethods.SetVelocity
local ProjectileCreateChildProjectile = ProjectileMethods.CreateChildProjectile

-- attach for CTRL + SHIFT F replacement

SIFThunthoArtilleryShell01 = Class(SThunthoArtilleryShell) {
               
    OnImpact = function(self, targetType, targetEntity) 
        
        -- cache for performance
        local army = self.Army
        local bp = self.Blueprint.Physics
        local bpFragments = bp.Fragments
        local bpFragmentId = bp.FragmentId
        local damageData = self.DamageData
        local fxFragEffect = SThunderStormCannonProjectileSplitFx
              
        -- split effects
        for k, v in fxFragEffect do
            CreateEmitterAtEntity( self, army, v )
        end     

        -- Randomization of the spread
        local angle = 6.28 / bpFragments
        local angleInitial = Random() * angle
        local angleVariation = angle * 0.8 -- Adjusts angle variance spread     

        local vx, vy, vz = ProjectileGetVelocity(self)

        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        local proj = false
        for i = 1, bpFragments do
            xVec = vx + 0.15 * (MathSin(angleInitial + (i * angle) + 2 * Random() * angleVariation - angleVariation))  -- spreadMul
            zVec = vz + 0.15 * (MathCos(angleInitial + (i * angle) + 2 * Random() * angleVariation - angleVariation))  -- spreadMul
            proj = ProjectileCreateChildProjectile(self, bpFragmentId)
            ProjectileSetVelocity(proj, xVec, yVec, zVec)
            ProjectileSetVelocity(proj, 18) -- velocity
            proj.DamageData = damageData
        end
        
        EntityDestroy(self)
    end
}

TypeClass = SIFThunthoArtilleryShell01