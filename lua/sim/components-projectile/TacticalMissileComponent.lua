
local SemiBallisticComponent = import("/lua/sim/components-projectile/semiballisticcomponent.lua").SemiBallisticComponent

---@class TacticalMissileComponent : SemiBallisticComponent
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {

    ---@param self TacticalMissileComponent | Projectile
    MovementThread = function(self)

        -- are we a wiggler?
        local zigZagger = false
        if self:GetBlueprint().Physics.MaxZigZag and
           self:GetBlueprint().Physics.MaxZigZag > self.MaxZigZagThreshold then
            zigZagger = true
        end

        -- launch
        self:SetTurnRate(self.LaunchTurnRate)
        WaitTicks(self.LaunchTicks)

        -- boost
        local boostTurnRate, boostTime = self:TurnRateFromAngleAndHeight()
        self:SetTurnRate(boostTurnRate)
        WaitTicks(boostTime * 10)
        
        -- glide
        local glideTurnRate, glideTime = self:TurnRateFromDistance()
        if zigZagger then
            self:SetTurnRate(75)
            -- wait until we're just short of our target (just short of the normal glide time is a good number)
            -- then up the turn rate so we can actually get close to hitting something
            WaitTicks((glideTime-1) * 10)
            self:SetTurnRate(100)
        else
            self:SetTurnRate(glideTurnRate)
            -- wait until we've allegedly hit our target, then turn tracking off
            -- (in case we miss, so we don't fly in circles forever)
            WaitTicks((glideTime+1) * 10)
            if not self:BeenDestroyed() then
                self:TrackTarget(false)
            end
        end
    end,
}
