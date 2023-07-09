local CTorpedoSubProjectile = import("/lua/cybranprojectiles.lua").CTorpedoSubProjectile

-- Sub-Based Torpedo Script
---@class CANTorpedoNanite01: CTorpedoSubProjectile
CANTorpedoNanite01 = ClassProjectile(CTorpedoSubProjectile) {

    ---@param self CANTorpedoNanite01
    ---@param inWater? boolean
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

    ---@param self CANTorpedoNanite01
    OnEnterWater = function(self)
        CTorpedoSubProjectile.OnEnterWater(self)
        self:SetBallisticAcceleration(0)
        self:SetTurnRate(120)
        self:TrackTarget(true)
    end,
}

TypeClass = CANTorpedoNanite01