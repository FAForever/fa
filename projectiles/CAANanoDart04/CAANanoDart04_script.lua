
-----------------------------------------------------------------------------
-- File     :  /data/projectiles/CAANanoDart04/CAANanoDart04_script.lua
-- Author(s):  Greg Kohne
-- Summary  :  Cybran Anti Air Projectile, on unit DRA0202
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------
import("/lua/utilities.lua")
CAANanoDartProjectile = import("/lua/cybranprojectiles.lua").CAANanoDartProjectile02

CAANanoDart04 = ClassProjectile(CAANanoDartProjectile) {
    OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        --Set the orientation of this thing to facing the target from the beginning.
        local ourPos= self:GetPosition()
        local targetPos= self:GetCurrentTargetPosition()
        local orientation= {targetPos[1]-ourPos[1],targetPos[2]-ourPos[2],targetPos[3]-ourPos[3]}         --Aim for the target.
        --Determine and set the initial velocity of the projectile.
        self:SetVelocity(orientation[1],orientation[2]-40,orientation[3])
        self.Trash:Add(ForkThread(self.UpdateThread,self))
   end,

    UpdateThread = function(self)
        self:SetMaxSpeed(50)                --Immediately go to max speed.
        WaitTicks(3)                   --Wait for a small amount of time
        self:SetBallisticAcceleration(-0.5) --Accelerate the projectile forward (negative is forward for this one).
        local army = self.Army         --Set the army affiliation for this projectile.
        --Set the mesh for the unfolded-fins missile now.
        self:SetMesh('/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')
        self:SetAcceleration(8 + Random() * 5)
        --Wait a little bit more before letting this missile be able to turn through a full range of rotation
        -- in its tracking.
        WaitTicks(4)
        self:SetTurnRate(360)
    end,
}
TypeClass = CAANanoDart04