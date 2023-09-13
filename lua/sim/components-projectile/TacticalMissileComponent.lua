
local SemiBallisticComponent = import("/lua/sim/components-projectile/semiballisticcomponent.lua").SemiBallisticComponent

---@class TacticalMissileProjectile : NullShell
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {

    -- TacticalMissileComponent Trajectory Parameters
    --- LaunchTicks: how long we spend in the launch phase
    --- LaunchTurnRate: inital launch phase turn rate, gives a little turnover coming out of the tube
    --- HeightDistanceFactor: each missile calculates an optimal highest point of its trajectory,
    -- based on its distance to the target.
    -- This is the factor that determines how high above the target that point is, in relation to the horizontal distance.
    -- a higher number will result in a lower trajectory
    -- 5-8 is a decent value
    --- MinHeight: minimum height of the highest point of the trajectory
    -- measured from the position of the missile at the end of the launch phase
    -- minRadius/2 or so is a decent value
    --- FinalBoostAngle: angle in degrees that we'll aim to be at the end of the boost phase
    -- 90 is vertical, 0 is horizontal

    maxZigZagThreshold = 1,

    ---@param self TacticalMissileProjectile
    MovementThread = function(self)

        -- are we a wiggler?
        local zigZagger = false
        if self:GetBlueprint().Physics.MaxZigZag and
           self:GetBlueprint().Physics.MaxZigZag > self.maxZigZagThreshold then
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
