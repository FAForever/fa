--******************************************************************************************************
--** Copyright (c) 2023  clyf
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local SemiBallisticComponent = import("/lua/sim/projectiles/components/semiballisticcomponent.lua").SemiBallisticComponent

local MathAbs = math.abs

---@class TacticalMissileComponent : SemiBallisticComponent
---@field TerminalTimeFactor number # Duration of the terminal phase as a proportion of glide time. Default is 0.25.
---@field TerminalDistance number   # Approximate distance from the target where terminal phase starts, overrides TerminalTimeFactor.
---@field TerminalSpeed number      # MaxSpeed of the missile in the terminal phase.
---@field TerminalZigZagMultiplier number     # MaxZigZag of the missile in the terminal phase. Default is 0.25.
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {
    
    TerminalTimeFactor = 0.25,
    TerminalZigZagMultiplier = 0.25,

    ---@param self TacticalMissileComponent | Projectile
    MovementThread = function(self, skipLaunchSequence)
        local blueprintPhysics = self.Blueprint.Physics
        local blueprintMaxZigZag = blueprintPhysics.MaxZigZag

        -- are we a wiggler?
        local zigZagger = false
        if blueprintMaxZigZag and
            blueprintMaxZigZag > self.MaxZigZagThreshold then
            zigZagger = true
        end

        if not skipLaunchSequence then
            -- launch
            local launchTurnRateRange = self.LaunchTurnRateRange
            local launchTurnRate = self.LaunchTurnRate + launchTurnRateRange * (2 * Random() - 1)
            self:SetTurnRate(launchTurnRate)

            local launchTicksRange = self.LaunchTicksRange
            local launchTicks = self.LaunchTicks + Random(-launchTicksRange, launchTicksRange)
            WaitTicks(launchTicks)

            -- boost
            local boostTurnRate, boostTime = self:TurnRateFromAngleAndHeight()
            if boostTime < 0 then
                boostTime = 0
            end

            self:SetTurnRate(boostTurnRate)
            WaitTicks(boostTime * 10 + 1)
        end

        -- glide
        local glideTurnRate, glideTime = self:TurnRateFromDistance()

        self:SetLifetime((glideTime + 3))

        -- try to create a smooth transition for zig-zaggers
        if zigZagger then
            if glideTime > 4.0 then
                for k = 1, 10 do
                    WaitTicks(4)
                    self:SetTurnRate(5 * k)
                end
                glideTime = glideTime - 4.0
            elseif glideTime > 2.0 then
                for k = 1, 5 do
                    WaitTicks(4)
                    self:SetTurnRate(10 * k)
                end
                glideTime = glideTime - 2.0
            elseif glideTime > 1.0 then
                for k = 1, 5 do
                    WaitTicks(2)
                    self:SetTurnRate(10 * k)
                end
                glideTime = glideTime - 1.0
            else
                self:SetTurnRate(50)
            end
        else
            self:SetTurnRate(glideTurnRate)
        end

        local terminalTime = glideTime * self.TerminalTimeFactor
        local terminalDistance = self.TerminalDistance
        local terminalSpeed = self.TerminalSpeed
        local terminalZigZagMultiplier = self.TerminalZigZagMultiplier

        local maxSpeed = blueprintPhysics.MaxSpeed
        local accel = blueprintPhysics.Acceleration

        if terminalDistance then
            terminalTime = terminalDistance / (terminalSpeed or maxSpeed)
        end

        -- Changing the max speed below the current speed decelerates the projectile in 2 ticks.
        -- Instead, create a smoother deceleration based on the projectile's actual acceleration.
        if terminalSpeed then
            local accelTime = MathAbs(maxSpeed - terminalSpeed) / accel

            -- The glide time is based on max speed, but the terminal phase is based on terminal speed,
            -- so we have to convert to the common variable of distance
            -- and then back into time by dividing by max speed.
            local accelDist = MathAbs((terminalSpeed * terminalSpeed - maxSpeed * maxSpeed) / 2 / accel)
            local timeBeforeTerminal = glideTime - terminalTime * terminalSpeed / maxSpeed - accelDist / maxSpeed
            -- Wait until the projectile reaches the point where the terminal phase should start.
            if timeBeforeTerminal > 0 then
                WaitTicks(timeBeforeTerminal * 10)
            end

            -- We will be changing our velocity in the next Wait, so update the lifetime.
            glideTime = accelTime + terminalTime
            self:SetLifetime((glideTime + 3))

            for t = 0.2, accelTime, 0.2 do
                self:SetMaxSpeed(maxSpeed - (maxSpeed - terminalSpeed) * t/accelTime)
                WaitTicks(3) -- This waits 2 ticks instead of 3 according to GetGameTick().
            end
            self:SetMaxSpeed(terminalSpeed)
        else
            WaitTicks((glideTime - terminalTime) * 10)
        end

        glideTime = terminalTime

        -- at this point we just want to make sure we hit the target, we increase the glide turn rate based
        -- on the zig zag that the missile had during flight to make sure it can align if it needs to
        self:ChangeMaxZigZag(terminalZigZagMultiplier * blueprintMaxZigZag)
        self:SetTurnRate((1 + 0.6 * blueprintMaxZigZag) * glideTurnRate)

        -- wait until we've allegedly hit our target
        WaitTicks((glideTime + 1) * 10)

        -- then, if we still exist, we just want to stop existing. Therefore we find our way to the ground
        -- target the ground below us slowly turn towards the ground so that we do not fly off indefinitely
        local position = self:GetPosition()
        position[2] = GetSurfaceHeight(position[1], position[3])
        self:SetNewTargetGround(position)

        -- increase turn rate to aim towards the ground
        for k = 4, 1, -1 do
            self:SetTurnRate(10 * k)
            WaitTicks(6)
        end
    end,
}
