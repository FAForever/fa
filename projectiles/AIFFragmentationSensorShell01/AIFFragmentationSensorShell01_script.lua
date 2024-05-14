------------------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFFragmentationSensorShell01/AIFFragmentationSensorShell01_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script,XAB2307
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local AArtilleryFragmentationSensorShellProjectile = import("/lua/aeonprojectiles.lua").AArtilleryFragmentationSensorShellProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local MathPow = math.pow
local MathSqrt = math.sqrt

-- Gravitational constant
local g = -4.9

---@class AIFFragmentationSensorShell01 : AArtilleryFragmentationSensorShellProjectile
AIFFragmentationSensorShell01 = ClassProjectile(AArtilleryFragmentationSensorShellProjectile) {

    ---@param self AIFFragmentationSensorShell01
    ---@param TargetType string
    ---@param TargetEntity Prop|Unit
    OnImpact = function(self, TargetType, TargetEntity)
        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag01
        local bp = self.Blueprint.Physics

        -- Split effects
        for k, v in FxFragEffect do
            CreateEmitterAtBone( self, -1, self.Army, v )
        end

        local detonationHeight = bp.DetonateBelowHeight
        local vx, vy, vz = self:GetVelocity()
        -- Normalize our velocity to ogrids/second
        vx, vy, vz = vx*10, vy*10, vz*10
        local vMult = bp.InitialSpeed/(10 * self:GetCurrentSpeed())

        -- Time to impact (with our reduced speed) is calculated using the quadratic formula and vMult.
        local timeToImpact = ((-vy - MathSqrt(MathPow(vy,2) - 2*g*detonationHeight))/g) / vMult

        -- Calculate the new ballistic acceleration
        local ballisticAcceleration = -2 * (detonationHeight + vy*vMult * timeToImpact) / MathPow(timeToImpact, 2)

        -- Update our velocity values to their new lower values 
        vx, vy, vz = vx*vMult, vy*vMult, vz*vMult

		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile(bp.FragmentId)
            :SetVelocity(vx, vy, vz)
            :SetBallisticAcceleration(ballisticAcceleration).DamageData = self.DamageData

		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments - 1
        local angle = (2 * math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )

        -- Randomization of the spread
        local angleVariation = angle * 8 -- Adjusts angle variance spread
        local spreadMagnitude = bp.FragmentRadius / timeToImpact -- Adjusts the width of the dispersal

        local xVec
        local zVec
        local offsetAngle

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            offsetAngle = angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation)
            xVec = vx + math.sin(offsetAngle) * spreadMagnitude
            zVec = vz + math.cos(offsetAngle) * spreadMagnitude
            self:CreateChildProjectile(bp.FragmentId)
                :SetVelocity(xVec, vy, zVec)
                :SetVelocity(bp.InitialSpeed + RandomFloat(-bp.InitialSpeedRange, bp.InitialSpeedRange))
                :SetBallisticAcceleration(ballisticAcceleration).DamageData = self.DamageData
        end

        self:Destroy()
    end,
}
TypeClass = AIFFragmentationSensorShell01