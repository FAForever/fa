-- File     :  /data/projectiles/SIFSuthanusArtilleryShell01/SIFSuthanusArtilleryShell01_script.lua
-- Author(s):  Gordon Duclos, Greg Kohne, Dru Staltman, Aaron Lundquist
-- Summary  :  Suthanus Artillery Shell Projectile script. Seraphim T3 Mobile Artillery : XSL0304
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local EffectTemplate = import("/lua/effecttemplates.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat
local SSuthanusMobileArtilleryShell = import("/lua/seraphimprojectiles.lua").SSuthanusMobileArtilleryShell

local SThunderStormCannonProjectileSplitFx = EffectTemplate.SThunderStormCannonProjectileSplitFx
local SuthanusImpactEffects = EffectTemplate.SRifterMobileArtilleryHit

local CreateEmitterAtEntity = CreateEmitterAtEntity
local MathSqrt = math.sqrt
local MathPow = math.pow
local MathPi = math.pi
local MathSin = math.sin
local MathCos = math.cos
local EntityDestroy = _G.moho.entity_methods.Destroy
local EntityPlaySound = _G.moho.entity_methods.PlaySound
local ProjectileCreateChildProjectile = _G.moho.projectile_methods.CreateChildProjectile
local ProjectileSetVelocity = _G.moho.projectile_methods.SetVelocity
local ProjectileGetVelocity = _G.moho.projectile_methods.GetVelocity
local ProjectileGetCurrentSpeed = _G.moho.projectile_methods.GetCurrentSpeed
local ProjectileSetBallisticAcceleration = _G.moho.projectile_methods.SetBallisticAcceleration

-- Gravitational acceleration used by ballistic projectiles.
local Gravity = -4.9

local function ConfigureFragment(fragment, damageData, ballisticAcceleration)
    ProjectileSetBallisticAcceleration(fragment, ballisticAcceleration)
    fragment.DamageData = damageData
    fragment.FxImpactLand = SuthanusImpactEffects
    fragment.FxImpactNone = SuthanusImpactEffects
    fragment.FxImpactProp = SuthanusImpactEffects
    fragment.FxImpactUnit = SuthanusImpactEffects
    fragment.FxLandHitScale = 0.45
    fragment.FxNoneHitScale = 0.45
    fragment.FxPropHitScale = 0.45
    fragment.FxUnitHitScale = 0.45
end

--- Suthanus Artillery Shell Projectile script. Seraphim T3 Mobile Artillery : XSL0304
---@class SIFSuthanusArtilleryShell01 : SSuthanusMobileArtilleryShell
SIFSuthanusArtilleryShell01 = ClassProjectile(SSuthanusMobileArtilleryShell) {

    ---@param self SIFSuthanusArtilleryShell01
    ---@param targetType string
    ---@param targetEntity Prop|Unit
    OnImpact = function(self, targetType, targetEntity)
        CreateEmitterAtEntity(self, self.Army, SThunderStormCannonProjectileSplitFx[1])
        EntityPlaySound(self, self.Blueprint.Audio.Impact)

        local physics = self.Blueprint.Physics
        local vx, vy, vz = ProjectileGetVelocity(self)

        -- Match Salvation's ballistic spread calculation so the ground
        -- radius remains consistent across the weapon's firing range.
        vx, vy, vz = vx * 10, vy * 10, vz * 10
        local velocityMultiplier = physics.InitialSpeed / (10 * ProjectileGetCurrentSpeed(self))
        local detonationHeight = physics.DetonateBelowHeight
        local timeToImpact = (
            (-vy - MathSqrt(MathPow(vy, 2) - 2 * Gravity * detonationHeight)) / Gravity
        ) / velocityMultiplier
        local ballisticAcceleration = -2 * (
            detonationHeight + vy * velocityMultiplier * timeToImpact
        ) / MathPow(timeToImpact, 2)

        vx, vy, vz =
            vx * velocityMultiplier,
            vy * velocityMultiplier,
            vz * velocityMultiplier

        local fragmentSpeed = physics.InitialSpeed
            + RandomFloat(-physics.InitialSpeedRange, physics.InitialSpeedRange)

        -- Three fragments land two units from the aim point, allowing their
        -- damage radii to overlap at the center.
        local centerFragmentCount = 3
        local centerAngle = (2 * MathPi) / centerFragmentCount
        local centerAngleInitial = RandomFloat(0, centerAngle)
        local centerSpreadMagnitude = 2 / timeToImpact

        for i = 0, centerFragmentCount - 1 do
            local offsetAngle = centerAngleInitial + i * centerAngle
            local fragment = ProjectileCreateChildProjectile(self, physics.FragmentId)
            ProjectileSetVelocity(
                fragment,
                vx + MathSin(offsetAngle) * centerSpreadMagnitude,
                vy,
                vz + MathCos(offsetAngle) * centerSpreadMagnitude
            )
            ProjectileSetVelocity(fragment, fragmentSpeed)
            ConfigureFragment(fragment, self.DamageData, ballisticAcceleration)
        end

        local dispersedFragmentCount = physics.Fragments - centerFragmentCount
        local angle = (2 * MathPi) / dispersedFragmentCount
        local angleInitial = RandomFloat(0, angle)
        local angleVariation = angle * 8
        local spreadMagnitude = physics.FragmentRadius / timeToImpact

        for i = 0, dispersedFragmentCount - 1 do
            local offsetAngle = angleInitial + i * angle + RandomFloat(-angleVariation, angleVariation)
            local magnitudeVariation = RandomFloat(0.9, 1.1)
            local xVec = vx + MathSin(offsetAngle) * spreadMagnitude * magnitudeVariation
            local zVec = vz + MathCos(offsetAngle) * spreadMagnitude * magnitudeVariation

            local fragment = ProjectileCreateChildProjectile(self, physics.FragmentId)
            ProjectileSetVelocity(fragment, xVec, vy, zVec)
            ProjectileSetVelocity(
                fragment,
                physics.InitialSpeed + RandomFloat(-physics.InitialSpeedRange, physics.InitialSpeedRange)
            )
            ConfigureFragment(fragment, self.DamageData, ballisticAcceleration)
        end

        EntityDestroy(self)
    end,
}
TypeClass = SIFSuthanusArtilleryShell01
