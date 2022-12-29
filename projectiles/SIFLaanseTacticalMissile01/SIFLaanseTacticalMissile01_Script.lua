-- File     :  /data/projectiles/SIFLaanseTacticalMissile01/SIFLaanseTacticalMissile01_script.lua
-- Author(s):  Gordon Duclos, Aaron Lundquist
-- Summary  :  Laanse Tactical Missile Projectile script, XSL0111
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------------
local SLaanseTacticalMissile = import("/lua/seraphimprojectiles.lua").SLaanseTacticalMissile

SIFLaanseTacticalMissile01 = Class(SLaanseTacticalMissile) {
    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self:ForkThread(self.MovementThread)
    end,

    MovementThread = function(self)
        self.WaitTime = 2
        self.Distance = self:GetDistanceToTarget()
        self:SetTurnRate(8)
        WaitTicks(4)        
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(self.WaitTime)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	self:SetTurnRate(75)
        	WaitTicks(31)
        	self:SetTurnRate(8)
        	self.Distance = self:GetDistanceToTarget()
        end
        if dist > 50 then
            --Freeze the turn rate as to prevent steep angles at long distance targets
            WaitTicks(21)
            self:SetTurnRate(10)
        elseif dist > 30 and dist <= 50 then
						self:SetTurnRate(12)
						WaitTicks(16)
            self:SetTurnRate(12)
        elseif dist > 10 and dist <= 25 then
            WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 10 then
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,        

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = SIFLaanseTacticalMissile01

