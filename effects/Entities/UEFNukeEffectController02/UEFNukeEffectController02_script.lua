-----------------------------------------------------------------------------------------------
-- File     :  /effects/Entities/UEFNukeEffectController01/UEFNukeEffectController01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Nuclear explosion script
-- Copyright © 2005,2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------------------------------
local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")
local Util = import("/lua/utilities.lua")
local RandomFloat = Util.GetRandomFloat

-- upvalue for perfomance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add
local WaitTicks = WaitTicks
local MathSin = math.sin
local MathCos = math.cos
local MathPi = math.pi

---@class UEFNukeEffectController01 : NullShell
UEFNukeEffectController01 = Class(NullShell) {

    ---@param self any
    ---@param inWater any
    OnCreate = function(self, inWater)
        NullShell.OnCreate(self, inWater)
        ForkThread(self.EffectThread, self)
    end,

    ---@param self UEFNukeEffectController01
    EffectThread = function(self)
        local army = self.Army
        local trash = self.Trash
        local position = self:GetPosition()

        -- Create projectile that controls plume effects
        local PlumeEffectYOffset = 0
        self:CreateProjectile('/effects/entities/UEFBillyNukeEffect02/UEFBillyNukeEffect02_proj.bp', 0,
            PlumeEffectYOffset, 0, 0, 0, 1)

        -- Create full-screen glow flash
        CreateLightParticle(self, -1, army, 20, 2, 'glow_02', 'ramp_red_02')
        WaitTicks(2)
        CreateLightParticle(self, -1, army, 40, 10, 'glow_03', 'ramp_fire_06')

        -- Create initial fireball dome effect
        local FireballDomeYOffset = -5
        self:CreateProjectile('/effects/entities/UEFBillyNukeEffect01/UEFBillyNukeEffect01_proj.bp', 0,
            FireballDomeYOffset, 0, 0, 0, 1)

        for k, v in EffectTemplate.TNukeRings01 do
            CreateEmitterAtEntity(self, army, v):ScaleEmitter(0.5)
        end

        self:CreateInitialFireballSmokeRing()
        TrashBagAdd(trash, ForkThread(self.CreateHeadConvectionSpinners, self))
        TrashBagAdd(trash, ForkThread(self.CreateFlavorPlumes, self))

    -- Create ground decals
        local orientation = RandomFloat(0, 2 * MathPi)
        CreateDecal(position, orientation, 'Crater01_albedo', '', 'Albedo', 25, 25, 1200, 0, army)
        CreateDecal(position, orientation, 'Crater01_normals', '', 'Normals', 25, 25, 1200, 0, army)
        WaitTicks(5)
        CreateLightParticle(self, -1, army, 100, 120, 'glow_03', 'ramp_nuke_04')
        WaitTicks(90)
        self:CreateGroundPlumeConvectionEffects(army)
    end,

    ---@param self UEFNukeEffectController01
    CreateInitialFireballSmokeRing = function(self)
        local sides = 12
        local angle = (2 * MathPi) / sides
        local velocity = 1
        local OffsetMod = 8

        for i = 0, (sides - 1) do
            local X = MathSin(i * angle)
            local Z = MathCos(i * angle)
            self:CreateProjectile('/effects/entities/UEFNukeShockwave01/UEFNukeShockwave01_proj.bp', X * OffsetMod, 1.5,
                Z * OffsetMod, X, 0, Z)
                :SetVelocity(velocity):SetAcceleration(-0.5)
        end
    end,

    ---@param self UEFNukeEffectController01
    CreateFlavorPlumes = function(self)
        local numProjectiles = 8
        local angle = (2 * MathPi) / numProjectiles
        local angleInitial = RandomFloat(0, angle)
        local angleVariation = angle * 0.75
        local projectiles = {}

        local xVec = 0
        local yVec = 0
        local zVec = 0
        local velocity = 0

        -- yVec -0.2, requires 2 initial velocity to start
        -- yVec 0.3, requires 3 initial velocity to start
        -- yVec 1.8, requires 8.5 initial velocity to start

        -- Launch projectiles at semi-random angles away from the sphere, with enough
        -- initial velocity to escape sphere core
        for i = 0, (numProjectiles - 1) do
            xVec = MathSin(angleInitial + (i * angle) + RandomFloat(-angleVariation, angleVariation))
            yVec = RandomFloat(0.2, 1)
            zVec = MathCos(angleInitial + (i * angle) + RandomFloat(-angleVariation, angleVariation))
            velocity = 1.5
            table.insert(projectiles,
                self:CreateProjectile('/effects/entities/UEFNukeFlavorPlume01/UEFNukeFlavorPlume01_proj.bp', 0, 0, 0,
                    xVec, yVec, zVec):SetVelocity(velocity))
        end

        WaitSeconds(2)

        -- Slow projectiles down to normal speed
        for k, v in projectiles do
            v:SetVelocity(1):SetBallisticAcceleration(-0.15)
        end
    end,

    ---@param self UEFNukeEffectController01
    CreateHeadConvectionSpinners = function(self)
        local sides = 10
        local angle = (2 * MathPi) / sides
        local HeightOffset = -5
        local velocity = 1
        local OffsetMod = 10
        local projectiles = {}

        for i = 0, (sides - 1) do
            local x = MathSin(i * angle) * OffsetMod
            local z = MathCos(i * angle) * OffsetMod
            local proj = self:CreateProjectile('/effects/entities/UEFBillyNukeEffect03/UEFBillyNukeEffect03_proj.bp', x,
                HeightOffset, z, x, 0, z)
                :SetVelocity(velocity)
            table.insert(projectiles, proj)
        end

        WaitTicks(10)
        for i = 0, (sides - 1) do
            local x = MathSin(i * angle)
            local z = MathCos(i * angle)
            local proj = projectiles[i + 1]
            proj:SetVelocityAlign(false)
            proj:SetOrientation(OrientFromDir(Util.Cross(Vector(x, 0, z), Vector(0, 1, 0))), true)
            proj:SetVelocity(0, 2, 0)
            proj:SetBallisticAcceleration(-0.05)
        end
    end,

    ---@param self UEFNukeEffectController01
    ---@param army number
    CreateGroundPlumeConvectionEffects = function(self, army)
        for k, v in EffectTemplate.TNukeGroundConvectionEffects01 do
            CreateEmitterAtEntity(self, army, v)
        end

        local sides = 10
        local angle = (2 * MathPi) / sides
        local outer_lower_limit = 2
        local outer_upper_limit = 2
        local outer_lower_height = 2
        local outer_upper_height = 3

        sides = 8
        angle = (2 * MathPi) / sides
        for i = 0, (sides - 1) do
            local magnitude = RandomFloat(outer_lower_limit, outer_upper_limit)
            local x = MathSin(i * angle + RandomFloat(-angle / 2, angle / 4)) * magnitude
            local z = MathCos(i * angle + RandomFloat(-angle / 2, angle / 4)) * magnitude
            local velocity = RandomFloat(1, 2.5) * 2
            self:CreateProjectile('/effects/entities/UEFNukeEffect05/UEFNukeEffect05_proj.bp', x,
                RandomFloat(outer_lower_height, outer_upper_height), z, x, 0, z)
                :SetVelocity(x * velocity, 0, z * velocity)
        end
    end,
}
TypeClass = UEFNukeEffectController01