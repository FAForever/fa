local CTorpedoShipProjectile = import("/lua/cybranprojectiles.lua").CTorpedoShipProjectile

-- upvalue for perfomance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local TrashBagAdd = TrashBag.Add


-- Cybran Non-guided Torpedo, Made to be fired from above the water
---@class CANTorpedoMeson01 : CTorpedoShipProjectile
CANTorpedoMeson01 = ClassProjectile(CTorpedoShipProjectile) {
    FxSplashScale = 1,

    FxExitWaterEmitter = {
        '/effects/emitters/destruction_water_splash_ripples_01_emit.bp',
        '/effects/emitters/destruction_water_splash_wash_01_emit.bp',
        '/effects/emitters/destruction_water_splash_plume_01_emit.bp',
    },

    ---@param self CANTorpedoMeson01
    OnEnterWater = function(self)
        CTorpedoShipProjectile.OnEnterWater(self)
        local trash = self.Trash

        self:TrackTarget(true)
        self:StayUnderwater(true)
        self:SetBallisticAcceleration(0)
        self:SetTurnRate(120)
        self:SetMaxSpeed(18)
        self:SetVelocity(3)
        TrashBagAdd(trash,ForkThread(self.SpinUpThread))
    end,

    ---@param self CANTorpedoMeson01
    SpinUpThread = function(self)
        WaitTicks(21)
        self:TrackTarget(false)
        self:SetTurnRate(0)
	end,
}
TypeClass = CANTorpedoMeson01