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

-- upvalue globals for performance
local VDist2 = VDist2
local VDist3 = VDist3
local MathPow = math.pow
local MathSqrt = math.sqrt
local MathAbs = math.abs
local MathSin = math.sin
local MathCos = math.cos
local MathAcos = math.acos
local MathAtan = math.atan
local MathPi = math.pi

--- Semi-Ballistic Component
---@class SemiBallisticComponent
---@field LaunchTicks number                # How long we spend in the launch phase, in ticks
---@field LaunchTicksRange number           # Randomness factor for `LaunchTicks` in ticks
---@field LaunchTurnRate number             # Inital launch phase turn rate, gives a little turnover coming out of the tube
---@field LaunchTurnRateRange number        # Randomness factor for `LaunchTurnRate`
---@field HeightDistanceFactor number       # Each missile calculates an optimal highest point of its trajectory, based on its distance to the target. This is the factor that determines how high above the target that point is, in relation to the horizontal distance.  A higher number will result in a lower trajectory 5-8 is a decent value
---@field HeightDistanceFactorRange number  # Randomness factor for `HeightDistanceFactor`
---@field MinHeight number                  # Minimum height of the highest point of the trajectory measured from the position of the missile at the end of the launch phase minRadius/2 or so is a decent value
---@field MinHeightRange number             # Randomness factor for `MinHeight`
---@field FinalBoostAngle number            # Angle in degrees that we'll aim to be at the end of the boost phase 90 is vertical, 0 is horizontal
---@field FinalBoostAngleRange number       # Randomness factor for `FinalBoostAngleRange`
---@field MaxZigZagThreshold number         # Threshold for when we consider the missile to be zigzagging
SemiBallisticComponent = ClassSimple {

    -- set some sane defaults
    LaunchTicks = 2,
    LaunchTicksRange = 0,

    LaunchTurnRate = 6,
    LaunchTurnRateRange = 0,

    HeightDistanceFactor = 5,
    HeightDistanceFactorRange = 0,

    MinHeight = 2,
    MinHeightRange = 0,

    FinalBoostAngle = 0,
    FinalBoostAngleRange = 0,

    MaxZigZagThreshold = 1,

    --- For a projectile that starts under acceleration, 
    --- but needs to calculate a ballistic trajectory mid-flight
    ---@param self SemiBallisticComponent | Projectile
    ---@param maxSpeed number
    ---@return number   # acceleration
    ---@return number   # time to impact (in ticks)
    CalculateBallisticAcceleration = function(self, maxSpeed)
        local ux, uy, uz = self:GetVelocity()
        local s0 = self:GetPosition()
        local target = self:GetCurrentTargetPosition()
        local dist = VDist2(target[1], target[3], s0[1], s0[3])

        -- we need velocity in m/s, not in m/tick
        local ux, uy, uz = ux*10, uy*10, uz*10
    
        local timeToImpact = dist / MathSqrt(MathPow(ux, 2) + MathPow(uz, 2))
        local ballisticAcceleration = (2 * ((target[2] - s0[2]) - uy * timeToImpact)) / MathPow(timeToImpact, 2)

        return ballisticAcceleration, timeToImpact
    end,

    --- Gives a turn rate based on a desired final angle and flight. Used for the initial part of a trajectory
    ---@param self SemiBallisticComponent | Projectile
    ---@return number
    ---@return number
    TurnRateFromAngleAndHeight = function(self)
        local finalBoostAngle = self.FinalBoostAngle + self.FinalBoostAngleRange * (2 * Random() - 1)
        local targetAngle = finalBoostAngle * MathPi/180
        local currentAngle = self:ElevationAngle()
        local deltaY = self:OptimalMaxHeight() - self:GetPosition()[2]

        local minHeight = self.MinHeight + self.MinHeightRange * (2 * Random() - 1)
        if deltaY < minHeight then
            deltaY = minHeight
        end

        local turnTime = deltaY/self:AverageVerticalVelocityThroughTurn(targetAngle, currentAngle)
        local degreesPerSecond = MathAbs(targetAngle - currentAngle)/turnTime * 180/MathPi        
        return degreesPerSecond, turnTime
    end,

    --- Gives a turn rate based on current angle and distance to the target. Used for the final part of the trajectory, gives a nice smooth turn
    ---@param self SemiBallisticComponent | Projectile
    ---@return number
    ---@return number
    TurnRateFromDistance = function(self)
        local blueprintPhysics = self.Blueprint.Physics

        local dist = self:DistanceToTarget()
        local targetVector = VDiff(self:GetCurrentTargetPosition(), self:GetPosition())
        local ux, uy, uz = self:GetVelocity()
        local velocityVector = Vector(ux, uy, uz)
        local speed = self:GetCurrentSpeed()

        local theta = MathAcos(VDot(targetVector, velocityVector) / (speed * dist))
        --local radius = dist/(2 * MathSin(theta))
        local arcLength = 2 * theta * dist/(2 * MathSin(theta))

        local averageSpeed
        if speed*10 < blueprintPhysics.MaxSpeed * 0.95 then
            -- assuming acceleration is still equal to the blueprint value, this could bite us!
            averageSpeed = self:AverageSpeedOverDistance(arcLength, blueprintPhysics.Acceleration)
        else
            averageSpeed = blueprintPhysics.MaxSpeed
        end

        local arcTime = arcLength / averageSpeed
        local degreesPerSecond = 2 * theta / arcTime * ( 180 / MathPi )
        return degreesPerSecond, arcTime
    end,

    -- Gives an average speed over a given distance (arc or straight). Used for a projectile that has not yet reached max speed
    ---@param self SemiBallisticComponent | Projectile
    ---@param dist number
    ---@param acceleration number
    ---@return number
    AverageSpeedOverDistance = function(self, dist, acceleration)
        local blueprintPhysics = self.Blueprint.Physics

        local speed = self:GetCurrentSpeed()*10
        local maxSpeed = blueprintPhysics.MaxSpeed
        local accelerationDistance = (MathPow(maxSpeed,2) - MathPow(speed,2)) / (2 * acceleration)
        local averageSpeed
        if dist < accelerationDistance then
            -- we'll never reach max speed
            local speedFinal = MathSqrt(2 * acceleration * dist + MathPow(speed,2))
            averageSpeed = (speed + speedFinal) / 2
        else
            -- we'll reach max speed
            local remainingDistance = dist - accelerationDistance
            averageSpeed = ((maxSpeed + speed)/2 * accelerationDistance + maxSpeed * remainingDistance) / dist
        end
        return averageSpeed
    end,

    -- As we turn from our current elevation angle to the target elevation angle, what will our average vertical velocity be? (we can use that number to calculate how long the turn should take, and therefore the turn rate)
    ---@param self SemiBallisticComponent | Projectile
    ---@param targetAngle number
    ---@param currentAngle number
    ---@return number
    AverageVerticalVelocityThroughTurn = function(self, targetAngle, currentAngle)
        local averageVerticalVelocity = 1/(targetAngle-currentAngle) * (MathCos(currentAngle) - MathCos(targetAngle))
        averageVerticalVelocity = averageVerticalVelocity * self:GetBlueprint().Physics.MaxSpeed
        return averageVerticalVelocity
    end,

    ---@param self SemiBallisticComponent | Projectile
    ---@return number
    DistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist3(tpos, mpos)
    end,

    ---@param self SemiBallisticComponent | Projectile
    ---@return number
    HorizontalDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    -- Angle between the given vector and the horizontal plane
    ---@param self SemiBallisticComponent | Projectile
    ---@param v? Vector
    ---@return number
    ElevationAngle = function(self, v)
        local vx, vy, vz
        if v then
            vx, vy, vz = v[1],v[2],v[3]
        else
            vx, vy, vz = self:GetVelocity()
        end
        local vh = VDist2(vx, vz, 0, 0)
        if vh == 0 then
            if vy >= 0 then
                return MathPi/2
            else
                return -MathPi/2
            end
        end
        return MathAtan(vy / vh)
    end,

    -- optimal highest point of the trajectory based on the heightDistanceFactor
    ---@param self SemiBallisticComponent | Projectile
    ---@return number
    OptimalMaxHeight = function(self)
        local horizDist = self:HorizontalDistanceToTarget()
        local targetHeight = self:GetCurrentTargetPosition()[2]
        local maxHeight = targetHeight + horizDist/(self.HeightDistanceFactor + self.HeightDistanceFactorRange * (2 * Random() - 1))
        return maxHeight
    end,

}