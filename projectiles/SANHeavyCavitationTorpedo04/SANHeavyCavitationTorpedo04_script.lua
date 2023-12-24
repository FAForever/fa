-- File     :  /data/projectiles/SANHeavyCavitationTorpedo04/SANHeavyCavitationTorpedo04_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Cavitation Torpedo Projectile script, XSA0204
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------------------------------
local SHeavyCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SHeavyCavitationTorpedo
local EffectTemplate = import("/lua/effecttemplates.lua")

-- upvalue for perfomance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local CreateEmitterOnEntity = CreateEmitterOnEntity
local TrashBagAdd = TrashBag.Add

--- Heavy Cavitation Torpedo Projectile script, XSA0204
---@class SANHeavyCavitationTorpedo04 : SHeavyCavitationTorpedo
SANHeavyCavitationTorpedo04 = ClassProjectile(SHeavyCavitationTorpedo) {

    ---@param self SANHeavyCavitationTorpedo04
    OnCreate = function(self)
        SHeavyCavitationTorpedo.OnCreate(self)
        local trash = self.Trash
        local army = self.Army

        self:SetCollisionShape('Sphere', 0, 0, 0, 0.5)
        TrashBagAdd(trash,ForkThread(self.PauseUntilTrack, self))
        CreateEmitterOnEntity(self, army, EffectTemplate.SHeavyCavitationTorpedoFxTrails)
    end,

    ---@param self SANHeavyCavitationTorpedo04
    PauseUntilTrack = function(self)
        WaitTicks(2)
        self:TrackTarget(true)
    end,
}
TypeClass = SANHeavyCavitationTorpedo04
