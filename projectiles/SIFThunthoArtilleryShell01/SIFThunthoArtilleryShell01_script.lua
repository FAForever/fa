-- File     :  /data/projectiles/SIFThunthoArtilleryShell01/SIFThunthoArtilleryShell01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Thuntho Artillery Shell Projectile script, XSL0103
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------

local SThunthoArtilleryShell = import("/lua/seraphimprojectiles.lua").SThunthoArtilleryShell
local SThunderStormCannonProjectileSplitFx = import("/lua/effecttemplates.lua").SThunderStormCannonProjectileSplitFx 

-- upvalue for performance
local CreateTrail = CreateTrail
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity

local Random = Random

local MathSin = math.sin 
local MathCos = math.cos

local EntityDestroy = _G.moho.entity_methods.Destroy

local ProjectileCreateChildProjectile = _G.moho.projectile_methods.CreateChildProjectile
local ProjectileSetVelocity = _G.moho.projectile_methods.SetVelocity
local ProjectileGetVelocity = _G.moho.projectile_methods.GetVelocity

SIFThunthoArtilleryShell01 = ClassProjectile(SThunthoArtilleryShell) {
    OnImpact = function(self, TargetType, TargetEntity) 

        -- the split fx
        CreateEmitterAtEntity( self, self.Army, SThunderStormCannonProjectileSplitFx[1])

        -- Create several other projectiles in a dispersal pattern
        local bp = self.Blueprint.Physics
        local numProjectiles = bp.Fragments

        -- Randomization of the spread
        -- 1 / 2 * pi = 0.159235669
        local angle = 0.159235669 * numProjectiles
        local angleInitial = angle * Random()
        local angleVariation = angle * 0.8   

        -- retrieve the current velocity
        local vx, vy, vz = ProjectileGetVelocity(self)
        local xVec = 0
        local yVec = vy
        local zVec = 0

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do

            -- compute a random offset of the velocity for this fragment
            local a = angleInitial + (i*angle)
            xVec = vx + (MathSin(a + 2 * angleVariation * Random() - angleVariation)) * 0.15
            zVec = vz + (MathCos(a + 2 * angleVariation * Random() - angleVariation)) * 0.15 

            -- create the projectile and set the velocity direction and then the velocity magnitude
            local proj = ProjectileCreateChildProjectile(self, bp.FragmentId)
            ProjectileSetVelocity(proj, xVec,yVec,zVec)
            ProjectileSetVelocity(proj, 18)

            -- just copy the damage data
            proj.DamageData = self.DamageData
        end

        EntityDestroy(self)
    end
}
TypeClass = SIFThunthoArtilleryShell01