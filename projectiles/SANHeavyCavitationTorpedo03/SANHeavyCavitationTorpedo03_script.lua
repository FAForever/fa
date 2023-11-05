﻿-- File     :  /data/projectiles/SANHeavyCavitationTorpedo03/SANHeavyCavitationTorpedo03_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Cavitation Torpedo Projectile script, XSB2205
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------------
local SHeavyCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SHeavyCavitationTorpedo
local EffectTemplate = import("/lua/effecttemplates.lua")

--- Heavy Cavitation Torpedo Projectile script, XSB2205
---@class SANHeavyCavitationTorpedo03 : SHeavyCavitationTorpedo
SANHeavyCavitationTorpedo03 = ClassProjectile(SHeavyCavitationTorpedo) {

    ---@param self SANHeavyCavitationTorpedo03
    OnCreate = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.5)
        SHeavyCavitationTorpedo.OnCreate(self)
        self.Trash:Add(ForkThread(self.PauseUntilTrack,self))
        CreateEmitterOnEntity(self,self.Army,EffectTemplate.SHeavyCavitationTorpedoFxTrails)
    end,

    ---@param self SANHeavyCavitationTorpedo03
    PauseUntilTrack = function(self)
        WaitTicks(2)
        self:TrackTarget(true)
    end,
}
TypeClass = SANHeavyCavitationTorpedo03
