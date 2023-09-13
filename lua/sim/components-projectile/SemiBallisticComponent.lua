
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
SemiBallisticComponent = ClassSimple {

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

    --- Gives a turn rate based on a desired final angle and flight
    --- Used for the initial part of a trajectory
    TurnRateFromAngleAndHeight = function(self)

        local targetAngle = self.FinalBoostAngle * MathPi/180
        local currentAngle = self:ElevationAngle()
        local deltaY = self:OptimalMaxHeight() - self:GetPosition()[2]
        if deltaY < self.MinHeight then
            deltaY = self.MinHeight
        end
        local turnTime = deltaY/self:AverageVerticalVelocityThroughTurn(targetAngle, currentAngle)

        local degreesPerSecond = MathAbs(targetAngle - currentAngle)/turnTime * 180/MathPi
        return degreesPerSecond, turnTime
    end,

    --- Gives a turn rate based on current angle and distance to the target
    --- Used for the final part of the trajectory, gives a nice smooth turn
    TurnRateFromDistance = function(self)

        local dist = self:DistanceToTarget()
        local targetVector = VDiff(self:GetCurrentTargetPosition(), self:GetPosition())
        local ux, uy, uz = self:GetVelocity()
        local velocityVector = Vector(ux, uy, uz)
        local speed = self:GetCurrentSpeed()

        local theta = MathAcos(VDot(targetVector, velocityVector) / (speed * dist))
        --local radius = dist/(2 * MathSin(theta))
        local arcLength = 2 * theta * dist/(2 * MathSin(theta))

        local averageSpeed
        if speed*10 < self:GetBlueprint().Physics.MaxSpeed * 0.95 then
            -- assuming acceleration is still equal to the blueprint value, this could bite us!
            averageSpeed = self:AverageSpeedOverDistance(arcLength, self:GetBlueprint().Physics.Acceleration)
        else
            averageSpeed = self:GetBlueprint().Physics.MaxSpeed
        end

        local arcTime = arcLength / averageSpeed
        local degreesPerSecond = 2 * theta / arcTime * ( 180 / MathPi )
        return degreesPerSecond, arcTime
    end,

    -- Gives an average speed over a given distance (arc or straight)
    -- Used for a projectile that has not yet reached max speed
    AverageSpeedOverDistance = function(self, dist, acceleration)
        local speed = self:GetCurrentSpeed()*10
        local maxSpeed = self:GetBlueprint().Physics.MaxSpeed
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

    -- As we turn from our current elevation angle to the target elevation angle,
    -- what will our average vertical velocity be?
    -- (we can use that number to calculate how long the turn should take, and therefore the turn rate)
    AverageVerticalVelocityThroughTurn = function(self, targetAngle, currentAngle)
        local averageVerticalVelocity = 1/(targetAngle-currentAngle) * (MathCos(currentAngle) - MathCos(targetAngle))
        averageVerticalVelocity = averageVerticalVelocity * self:GetBlueprint().Physics.MaxSpeed
        return averageVerticalVelocity
    end,

    DistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist3(tpos, mpos)
    end,

    HorizontalDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        return VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
    end,

    -- Angle between the given vector and the horizontal plane
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
    OptimalMaxHeight = function(self)
        local horizDist = self:HorizontalDistanceToTarget()
        local targetHeight = self:GetCurrentTargetPosition()[2]
        local maxHeight = targetHeight + horizDist/self.HeightDistanceFactor
        return maxHeight
    end,

}