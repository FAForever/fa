-- File     :  /data/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------------
local SHeavyCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SHeavyCavitationTorpedo
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class SANHeavyCavitationTorpedo03: SHeavyCavitationTorpedo
SANHeavyCavitationTorpedo03 = ClassProjectile(SHeavyCavitationTorpedo) {

    ---@param self SANHeavyCavitationTorpedo03
    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.1)
        SHeavyCavitationTorpedo.OnCreate(self)
        self.Trash:Add(ForkThread(self.PauseUntilTrack,self))
        CreateEmitterOnEntity(self,self.Army,EffectTemplate.SHeavyCavitationTorpedoFxTrails)
    end,

    ---@param self SANHeavyCavitationTorpedo03
    PauseUntilTrack = function(self)
        local distance = self:GetDistanceToTarget()
        local turnrate = 360

        if distance < 6 then
            turnrate = 720
        end
        WaitTicks(2)
        self:SetMaxSpeed(20)
        self:TrackTarget(true)
        self:SetTurnRate(turnrate)
    end,

    ---@param self SANHeavyCavitationTorpedo03
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = SANHeavyCavitationTorpedo03
