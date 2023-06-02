--
-- Terran Torpedo Bomb
--
local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

TANAnglerTorpedo01 = ClassProjectile(TTorpedoShipProjectile) 
{
    OnEnterWater = function(self)
        TTorpedoShipProjectile.OnEnterWater(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        self:ForkThread(self.MovementThread)
    end,
}

TypeClass = TANAnglerTorpedo01
