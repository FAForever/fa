-- File     :  /data/projectiles/SIFHuAntiNuke01/SIFHuAntiNuke01_script.lua
-- Author(s):  Greg Kohne, Matt Vainio
-- Summary  : Seraphim Anti Nuke Missile
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------

local EffectTemplate = import("/lua/effecttemplates.lua")
local SIFHuAntiNuke = import("/lua/seraphimprojectiles.lua").SIFHuAntiNuke
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local RandomInt = import("/lua/utilities.lua").GetRandomInt
SIFHuAntiNuke01 = ClassProjectile(SIFHuAntiNuke) {
    --This is a custom impact to maeke the seraphim hit look really good, like some kind of tendrilled explosion.
    OnImpact = function(self, TargetType, TargetEntity) 
        local FxHitEffect = EffectTemplate.SKhuAntiNukeHit 
        local LargeTendrilProjectile = '/effects/Entities/SIFHuAntiNuke02/SIFHuAntiNuke02_proj.bp'  
        local SmallTendrilProjectile = '/effects/Entities/SIFHuAntiNuke03/SIFHuAntiNuke03_proj.bp'  
        --Play the hit effect for the core explosion on the anti nuke.
        for k, v in FxHitEffect do
            CreateEmitterAtEntity( self, self.Army, v )
        end
        local vx, vz = self:GetVelocity()
        local velocity = 19

        -- Create several other projectiles in a dispersal pattern
        local num_projectiles = 5
        local horizontal_angle = (2*math.pi) / num_projectiles
        local angleInitial = RandomFloat( 0, horizontal_angle )
        -- Randomization of the spread
        local angleVariation = horizontal_angle * 0.25  --Adjusts horizontal_angle variance spread
        local xVec
        local yVec
        local zVec
        ------------Create LARGE TENDRIL projectiles--------------
        for i = 0, (num_projectiles -1) do
            xVec = (math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            yVec =  RandomFloat(-3,33)
            zVec = (math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            local proj = self:CreateChildProjectile(LargeTendrilProjectile):SetLifetime( RandomFloat(0.4,0.65) ) :SetVelocity(velocity)
            proj:SetBallisticAcceleration(0,-89.92,0)
            proj:SetVelocity(xVec,yVec,zVec)
        end
        ------Ensure that the number of smaller tendrils is more.
        num_projectiles= RandomInt((num_projectiles + 3),(num_projectiles*2 + 3) )
        horizontal_angle = (2*math.pi) / num_projectiles

        ------------Create SMALL TENDRILS projectiles------------
        for i = 0, (num_projectiles -1) do
            xVec = vx + (math.sin(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            yVec = RandomFloat(-3,33)
            zVec = vz + (math.cos(angleInitial + (i*horizontal_angle) + RandomFloat(-angleVariation, angleVariation))) * RandomFloat(1,5)
            local proj = self:CreateChildProjectile(SmallTendrilProjectile):SetLifetime(RandomFloat(0.25,0.35)):SetVelocity(xVec,yVec,zVec):SetVelocity(velocity)
            proj:SetBallisticAcceleration(0,-89.92,0)
        end
        SIFHuAntiNuke.OnImpact(self, TargetType, TargetEntity)
    end,
}
TypeClass = SIFHuAntiNuke01