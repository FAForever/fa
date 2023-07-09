-- File     :  /data/projectiles/SIFLaanseTacticalMissile04/SIFLaanseTacticalMissile04_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Laanse Tactical Missile Projectile script, XSB2108
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------
local SLaanseTacticalMissile = import("/lua/seraphimprojectiles.lua").SLaanseTacticalMissile

---@class SIFLaanseTacticalMissile04 : SLaanseTacticalMissile
SIFLaanseTacticalMissile04 = ClassProjectile(SLaanseTacticalMissile) {

    ---@param self SIFLaanseTacticalMissile04
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
        self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,

    ---@param self SIFLaanseTacticalMissile04
    MovementThread = function(self)
        self:SetTurnRate(8)
        WaitTicks(4)        
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    ---@param self SIFLaanseTacticalMissile04
    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        --Get the nuke as close to 90 deg as possible
        if dist > 50 then        
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(20)
        elseif dist > 128 and dist <= 213 then
						-- Increase check intervals
						self:SetTurnRate(30)
						WaitTicks(16)
            self:SetTurnRate(30)
        elseif dist > 43 and dist <= 107 then
						-- Further increase check intervals
                        WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 43 then
						-- Further increase check intervals            
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,        

    ---@param self SIFLaanseTacticalMissile04
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = SIFLaanseTacticalMissile04

