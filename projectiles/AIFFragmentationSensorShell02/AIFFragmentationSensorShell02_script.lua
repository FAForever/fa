-------------------------------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/AIFFragmentationSensorShell02/AIFFragmentationSensorShell02_script.lua
-- Author(s):  Drew Staltman, Gordon Duclos
-- Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script , Child Projectile after 1st split - XAB2307
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local AArtilleryFragmentationSensorShellProjectile = import("/lua/aeonprojectiles.lua").AArtilleryFragmentationSensorShellProjectile02
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

local MathSqrt = math.sqrt
local MathPow = math.pow
local MathPi = math.pi
local MathSin = math.sin
local MathCos = math.cos

-- We'll update our ballistic parameters so we still hit the target, but only need
-- to do it once for the subprojectiles, because the velocity delta will be very similar
-- and these won't change much/at all.
local ballisticAcceleration
local vMult
local spreadMagnitude

-- Gravitational constant
local g = -4.9

--- Aeon Quantic Cluster Fragmentation Sensor shell script , Child Projectile after 1st split - XAB2307
---@class AIFFragmentationSensorShell02 : AArtilleryFragmentationSensorShellProjectile02
AIFFragmentationSensorShell02 = ClassProjectile(AArtilleryFragmentationSensorShellProjectile) {

	---@param self AIFFragmentationSensorShell02
	---@param TargetType string
	---@param TargetEntity Prop|Unit
	OnImpact = function(self, TargetType, TargetEntity)
        if TargetType != 'Shield' then
	        local FxFragEffect = EffectTemplate.Aeon_QuanticClusterFrag02
            local bp = self.Blueprint.Physics
	        -- Split effects
	        for k, v in FxFragEffect do
				local army = self.Army
	            CreateEmitterAtBone( self, -1, army, v )
	        end

			local vx, vy, vz = self:GetVelocity()
			-- Normalize our velocity to ogrids/second
			vx, vy, vz = vx*10, vy*10, vz*10

			-- If we haven't already calculated our ballistic acceleration, do so now
			-- This shouldn't change much between subprojectiles, so we only need to do it once
			if not ballisticAcceleration then
				local detonationHeight = bp.DetonateBelowHeight
				vMult = bp.InitialSpeed/(10 * self:GetCurrentSpeed())

				-- Time to impact (with our reduced speed) is calculated using the quadratic formula and vMult.
				local timeToImpact = ((-vy - MathSqrt(MathPow(vy,2) - 2*g*detonationHeight))/g) / vMult

				-- Calculate the new ballistic acceleration
				ballisticAcceleration = -2 * (detonationHeight + vy*vMult * timeToImpact) / MathPow(timeToImpact, 2)
				spreadMagnitude = bp.FragmentRadius / timeToImpact
			end

			-- Update our velocity values
			-- There appears to be inevitable decay with child projectiles, so we give a slight vertical lift to compensate
			vx, vy, vz = vx*vMult, vy*vMult + 2, vz*vMult

			-- One initial projectile following same directional path as the original
			self:CreateChildProjectile(bp.FragmentId)
				:SetVelocity(vx, vy, vz)
				:SetVelocity(bp.InitialSpeed)
				:SetBallisticAcceleration(ballisticAcceleration).DamageData = self.DamageData

			-- Create several other projectiles in a dispersal pattern
            local numProjectiles = bp.Fragments - 1
            local angle = (2 * MathPi) / numProjectiles
            local angleInitial = RandomFloat( 0, angle )

            -- Randomization of the spread
            local angleVariation = angle * 13 -- Adjusts angle variance spread
			local xVec
			local zVec
			local offsetAngle
			local magnitudeVariation
	
			-- Launch projectiles at semi-random angles away from split location
			for i = 0, numProjectiles - 1 do
				offsetAngle = angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation)
				magnitudeVariation = RandomFloat(0.9, 1.1)
				xVec = vx + MathSin(offsetAngle) * spreadMagnitude * magnitudeVariation
				zVec = vz + MathCos(offsetAngle) * spreadMagnitude * magnitudeVariation
				self:CreateChildProjectile(bp.FragmentId)
					:SetVelocity(xVec, vy, zVec)
					:SetVelocity(bp.InitialSpeed + RandomFloat(-bp.InitialSpeedRange, bp.InitialSpeedRange))
					:SetBallisticAcceleration(ballisticAcceleration).DamageData = self.DamageData
			end
	        self:Destroy()
		else
	        self:DoDamage(self, self.DamageData, TargetEntity)
	        self:OnImpactDestroy(TargetType, TargetEntity)
        end
    end,
}
TypeClass = AIFFragmentationSensorShell02