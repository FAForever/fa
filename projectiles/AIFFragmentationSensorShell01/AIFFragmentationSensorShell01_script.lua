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

        local vx, vy, vz = self:GetVelocity()
        LOG('vx: '..vx..' vy: '..vy..' vz: '..vz)
        LOG('Current speed: '..self:GetCurrentSpeed())
        LOG('DetonateBelowHeight: '..bp.DetonateBelowHeight)
        local vMult = bp.InitialSpeed/(self:GetCurrentSpeed()*10)
        LOG('vMult: '..vMult)

        -- We'll implicitly calculate our remaining horizontal distance on
        -- the assumption that our initial trajectory was accurate, then
        -- calculate our new desired ballistic acceleration to reach the target.
        local rangeToTarget = math.sqrt(4.75/(2*bp.DetonateBelowHeight)) * VDist2(0,0,vx*10,vz*10)
        LOG('Range to target: '..rangeToTarget)
        local newTimeToImpact = rangeToTarget / VDist2(0,0,vx*vMult,vz*vMult)
        LOG('New time to impact: '..newTimeToImpact)
        LOG('New vertical speed: '..vy*vMult)
        local newBallisticAcceleration = - (2 * (bp.DetonateBelowHeight + vy*vMult*10)) / MathPow(newTimeToImpact, 2)
        LOG('New ballistic acceleration: '..newBallisticAcceleration)

		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile(bp.FragmentId)
            :SetVelocity(vx*vMult*10, vy*vMult*10, vz*vMult*10)
            :SetBallisticAcceleration(newBallisticAcceleration).DamageData = self.DamageData

		-- Create several other projectiles in a dispersal pattern
        local numProjectiles = bp.Fragments - 1
        local angle = (2 * math.pi) / numProjectiles
        local angleInitial = RandomFloat( 0, angle )

        -- Randomization of the spread
        local angleVariation = angle * 8 -- Adjusts angle variance spread
        local spreadMul = 0.8 -- Adjusts the width of the dispersal        

        local xVec
        local zVec

        -- Launch projectiles at semi-random angles away from split location
        for i = 0, numProjectiles - 1 do
            xVec = vx + (math.sin(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            zVec = vz + (math.cos(angleInitial + (i*angle) + RandomFloat(-angleVariation, angleVariation))) * spreadMul
            self:CreateChildProjectile(bp.FragmentId)
                :SetVelocity(xVec*vMult, vy*vMult, zVec*vMult)
                :SetBallisticAcceleration(newBallisticAcceleration).DamageData = self.DamageData
        end

        self:Destroy()
    end,
}
TypeClass = AIFFragmentationSensorShell01