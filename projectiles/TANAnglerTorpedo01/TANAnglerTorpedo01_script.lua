local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

-- Terran Torpedo Bomb
---@class TANAnglerTorpedo01 : TTorpedoShipProjectile
TANAnglerTorpedo01 = ClassProjectile(TTorpedoShipProjectile){

    ---@param self TANAnglerTorpedo01
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