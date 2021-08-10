--****************************************************************************
--**
--**  File     :  /data/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_script.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SHeavyCavitationTorpedo = import('/lua/seraphimprojectiles.lua').SHeavyCavitationTorpedo
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat
local EffectTemplate = import('/lua/EffectTemplates.lua')

SANHeavyCavitationTorpedo03 = Class(SHeavyCavitationTorpedo) {
    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.1)
        SHeavyCavitationTorpedo.OnCreate(self)
        self:ForkThread(self.PauseUntilTrack)
        CreateEmitterOnEntity(self,self.Army,EffectTemplate.SHeavyCavitationTorpedoFxTrails)
    end,

    PauseUntilTrack = function(self)
        local distance = self:GetDistanceToTarget()
        local waittime
        local turnrate = 360
        -- The pause time needs to scale down depending on how far away the target is, otherwise
        -- the torpedoes will initially shoot past their target.
        if distance > 6 then
            waittime = .1--.45
            if distance > 12 then
                waittime = .1--.7
                if distance > 18 then
                        waittime = 0.1--1
                end
            end
        else
            waittime = .1
            turnrate = 720
        end
        WaitSeconds(waittime)
        self:SetMaxSpeed(20)
        self:TrackTarget(true)
        self:SetTurnRate(turnrate)
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = SANHeavyCavitationTorpedo03
