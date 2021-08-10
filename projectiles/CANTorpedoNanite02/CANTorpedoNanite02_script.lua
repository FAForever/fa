--****************************************************************************
--**
--**  File     :  /data/projectiles/CANTorpedoNanite02/CANTorpedoNanite02_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Cybran Anti-Navy Nanite Torpedo Script
--                Nanite Torpedo releases tiny nanites that do DoT
--**
--**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CTorpedoShipProjectile = import('/lua/cybranprojectiles.lua').CTorpedoShipProjectile
local Entity = import('/lua/sim/Entity.lua').Entity
local defaultDamage = import('/lua/sim/defaultdamage.lua')

CANTorpedoNanite02 = Class(CTorpedoShipProjectile) {

    TrailDelay = 0,
    OnCreate = function(self, inWater)
        CTorpedoShipProjectile.OnCreate(self, inWater)
        self:ForkThread( self.MovementThread )
    end,   
    
    MovementThread = function(self)
        while not self:BeenDestroyed() and (self:GetDistanceToTarget() > 8) do
            WaitSeconds(0.25)
        end  
        if not self:BeenDestroyed() then
			self:ChangeMaxZigZag(0)
			self:ChangeZigZagFrequency(0)	      
		end
    end,
    
    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,     
         

    OnEnterWater = function(self)
        CTorpedoShipProjectile.OnEnterWater(self)
        self.CreateImpactEffects( self, self:GetArmy(), self.FxEnterWater, self.FxSplashScale )
        self:StayUnderwater(true)
        self:TrackTarget(true)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        self:SetVelocity(3)
    end,

}

TypeClass = CANTorpedoNanite02