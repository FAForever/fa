--
-- Terran Torpedo Bomb
--
local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

TANAnglerTorpedo06 = Class(TTorpedoShipProjectile) 
{
    OnEnterWater = function(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
        local army = self.Army

        for k, v in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self,army,v)
        end
        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetTurnRate(240)
        self:SetMaxSpeed(18)
     end,
}
TypeClass = TANAnglerTorpedo06