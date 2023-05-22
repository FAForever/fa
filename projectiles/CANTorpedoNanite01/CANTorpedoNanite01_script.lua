--
-- Sub-Based Torpedo Script
--
local CTorpedoSubProjectile = import("/lua/cybranprojectiles.lua").CTorpedoSubProjectile

CANTorpedoNanite01 = ClassProjectile(CTorpedoSubProjectile) {

	OnCreate = function(self, inWater)
        CTorpedoSubProjectile.OnCreate(self, inWater)
        if inWater then
            self:SetBallisticAcceleration(0)
        else
            self:SetBallisticAcceleration(-20)
            self:TrackTarget(false)
            self:SetTurnRate(0)
        end
    end,
    
    OnEnterWater = function(self)
        CTorpedoSubProjectile.OnEnterWater(self)
        self:SetBallisticAcceleration(0)
        self:SetTurnRate(120)
        self:TrackTarget(true)
    end,
}

TypeClass = CANTorpedoNanite01