-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetCollisionShape = EntityMethods.SetCollisionShape

local GlobalMethods = _G
local GlobalMethodsCreateEmitterOnEntity = GlobalMethods.CreateEmitterOnEntity

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetMaxSpeed = ProjectileMethods.SetMaxSpeed
local ProjectileMethodsSetTurnRate = ProjectileMethods.SetTurnRate
local ProjectileMethodsTrackTarget = ProjectileMethods.TrackTarget
-- End of automatically upvalued moho functions

#****************************************************************************
#**
#**  File     :  /data/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_script.lua
#**  Author(s):  Gordon Duclos
#**
#**  Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SHeavyCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SHeavyCavitationTorpedo
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

SANHeavyCavitationTorpedo03 = Class(SHeavyCavitationTorpedo)({
    OnCreate = function(self)
        EntityMethodsSetCollisionShape(self, 'Sphere', 0, 0, 0, 0.1)
        SHeavyCavitationTorpedo.OnCreate(self)
        self:ForkThread(self.PauseUntilTrack)
        GlobalMethodsCreateEmitterOnEntity(self, self.Army, EffectTemplate.SHeavyCavitationTorpedoFxTrails)
    end,

    PauseUntilTrack = function(self)
        local distance = self:GetDistanceToTarget()
        local waittime
        local turnrate = 360
        # The pause time needs to scale down depending on how far away the target is, otherwise
        # the torpedoes will initially shoot past their target.
        if distance > 6 then
            #.45
            waittime = 0.1
            if distance > 12 then
                #.7
                waittime = 0.1
                if distance > 18 then
                    #1
                    waittime = 0.1
                end
            end
        else
            waittime = 0.1
            turnrate = 720
        end
        WaitSeconds(waittime)
        ProjectileMethodsSetMaxSpeed(self, 20)
        ProjectileMethodsTrackTarget(self, true)
        ProjectileMethodsSetTurnRate(self, turnrate)
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
})
TypeClass = SANHeavyCavitationTorpedo03
