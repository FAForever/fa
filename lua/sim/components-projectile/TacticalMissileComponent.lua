local GetRandomInt = import('/lua/utilities.lua').GetRandomInt
local MathMax = math.max

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
        local launchTicks = GetRandomInt(self.LaunchTicks - self.LaunchTicksVariation, self.LaunchTicks + self.LaunchTicksVariation)
        WaitTicks(MathMax(launchTicks, 1))

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
            -- set remaining glideTime to 1 for the miss check later, tweak this value if we end up disabling tracking too early
            glideTime = 1
            self:SetTurnRate(100)
        else
            self:SetTurnRate(glideTurnRate)
        end

        -- wait until we've allegedly hit our target, then turn tracking off
        -- (in case we miss, so we don't fly in circles forever)

        self:SetLifetime((glideTime+3))

        WaitTicks((glideTime+1) * 10)
        if not self:BeenDestroyed() then

            -- target the ground below us slowly turn towards the ground so that we do not fly off indefinitely
            local position = self:GetPosition()
            position[2] = GetSurfaceHeight(position[1], position[3])
            self:SetNewTargetGround(position)

            for k = 4, 1, -1 do
                if IsDestroyed(self) then
                    break
                end

                self:SetTurnRate(10 * k)
                WaitTicks(6)
            end
        end
    end,
}
