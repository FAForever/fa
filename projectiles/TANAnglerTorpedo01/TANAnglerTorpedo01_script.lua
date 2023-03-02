--
-- Terran Torpedo Bomb
--
local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

TANAnglerTorpedo01 = Class(TTorpedoShipProjectile) 
{

    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        local army = self:GetArmy()

        for k, v in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self,army,v)
        end
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        --self:SetVelocity(0)
        self:ForkThread(self.MovementThread)
    end,

}

TypeClass = TANAnglerTorpedo01
