--
-- Terran Torpedo Bomb
--
local TTorpedoShipProjectile = import('/lua/terranprojectiles.lua').TTorpedoShipProjectile

TANAnglerTorpedo06 = Class(TTorpedoShipProjectile) 
{

    OnEnterWater = function(self)
        -- set a collision shape to make them easier to hit for defenses
        -- can't be too big (e.g., 1.0) because then torpedo bombers are worthless in shallow water
        self:SetCollisionShape('Sphere', 0, 0, 0, 0.5)
        
        -- splash!!
        local army = self:GetArmy()
        for k, v in self.FxEnterWater do
            CreateEmitterAtEntity(self,army,v)
        end

        -- set properties of the torpedo once it is underwater
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(240)

        -- set the magnitude of the velocity to something tiny to really make that water
        -- impact slow it down. We need this to prevent torpedo's striking the bottom
        -- of a shallow pond, like in setons
        self:SetVelocity(0.01)
        self:SetMaxSpeed(18)
        self:ForkThread(self.MovementThread)
    end,

    MovementThread = function(self)
        -- gradually increase acceleration, but make them less flexible
        self:SetAcceleration(2)
        self:SetTurnRate(200)
        WaitSeconds(0.25)
        self:SetAcceleration(4)
        self:SetTurnRate(160)
        WaitSeconds(0.25)
        self:SetAcceleration(6)
        self:SetTurnRate(120)
        WaitSeconds(0.25)
        self:SetAcceleration(8)
        self:SetTurnRate(80)
        WaitSeconds(0.25)
    end,

}

TypeClass = TANAnglerTorpedo06
