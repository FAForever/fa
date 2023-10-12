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

---@class TacticalMissileComponent : SemiBallisticComponent
TacticalMissileComponent = ClassSimple(SemiBallisticComponent) {

    ---@param self TacticalMissileComponent | Projectile
    MovementThread = function(self)
        local blueprintPhysics = self.Blueprint.Physics

        -- are we a wiggler?
        local zigZagger = false
        if blueprintPhysics.MaxZigZag and
           blueprintPhysics.MaxZigZag > self.MaxZigZagThreshold then
            zigZagger = true
        end

        -- launch
        local launchTurnRateRange = self.LaunchTurnRateRange
        local launchTurnRate = self.LaunchTurnRate + launchTurnRateRange * (2 * Random() - 1)
        self:SetTurnRate(launchTurnRate)

        local launchTicksRange = self.LaunchTicksRange
        local launchTicks = self.LaunchTicks + Random(-launchTicksRange, launchTicksRange)
        WaitTicks(launchTicks)

        -- boost
        local boostTurnRate, boostTime = self:TurnRateFromAngleAndHeight()
        self:SetTurnRate(boostTurnRate)
        WaitTicks(boostTime * 10 + 1)

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
