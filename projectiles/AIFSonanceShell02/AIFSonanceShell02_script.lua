--******************************************************************************************************
--** Copyright (c) 2023 FAForever
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

local AArtilleryProjectile = import("/lua/aeonprojectiles.lua").AArtilleryProjectile
local AArtilleryProjectileOnCreate = AArtilleryProjectile.OnCreate
local AArtilleryProjectileOnImpact = AArtilleryProjectile.OnImpact

local EffectTemplate = import("/lua/effecttemplates.lua")

local MathSqrt = math.sqrt
local MathSin = math.sin
local MathCos = math.cos
local MathFloor = math.floor
local MathPi = math.pi
local MathMax = math.max
local MathMin = math.min

-- ticks the shell holds in place between its two impacts
local HoldTicks = 38

-- radius of the original Sonance explosion at scale 1, taken from its ring (aeon_sonance_hit_02,
-- end size 5). Both explosions are scaled up from this to match the damage radius
local ExplosionRadius = 2.5

-- the widest each effect of the explosions gets at scale 1, with how far its particles fly: none is
-- scaled up beyond the width of the damage area, so that none looks bigger than the damage it does
local EffectWidth = {
    -- the big circle and its distortion still spread as they fade out: kept a tenth inside
    ['/effects/emitters/aeon_sonance_hit_02_emit.bp'] = 5.6,
    ['/effects/emitters/_Mercy_distort.bp'] = 5.5,
    ['/effects/emitters/czar_splash_01_emit.bp'] = 6.9, -- the burst of distortion: a fifth smaller still
    ['/effects/emitters/aeon_sonance_hit_01_emit.bp'] = 10.1,
    ['/effects/emitters/aeon_sonance_hit_03_emit.bp'] = 7.6,
    ['/effects/emitters/quark_bomb_explosion_08_emit.bp'] = 8.4,
    ['/effects/emitters/aeon_sonance_hit_04_soft_emit.bp'] = 10.1,
    ['/effects/emitters/aeon_sonance_hit_01_elect_emit.bp'] = 12,
    ['/effects/emitters/aeon_sonance_hit_05_emit.bp'] = 5.6, -- the dark rays: a quarter larger than the rest
    ['/effects/emitters/aeon_sonance_hit_06_emit.bp'] = 8,
}
-- the effects the base class plays on the first impact (ASonanceWeaponHit02Core) can only be scaled
-- together: the widest of them
local CoreWidth = 10.1

-- stock emitters used for effects of their own: how each is set, wherever it is created (before it is
-- scaled). Sizes are for scale 1
local EmitterSetup = {
    -- the distortion of the Mercy, as a single ring of distortion spreading with the big circle of the
    -- explosion (aeon_sonance_hit_02: 10 ticks, size 2 to 5, 0.3 up)
    ['/effects/emitters/_Mercy_distort.bp'] = function(emitter)
        emitter:SetEmitterParam('LIFETIME', 1)
        emitter:SetEmitterCurveParam('EMITRATE_CURVE', 1, 0)
        emitter:SetEmitterCurveParam('LIFETIME_CURVE', 10, 0)
        emitter:SetEmitterCurveParam('VELOCITY_CURVE', 0, 0)
        emitter:SetEmitterCurveParam('ROTATION_RATE_CURVE', 0, 0)
        emitter:SetEmitterCurveParam('Y_POSITION_CURVE', 0.3, 0)
        emitter:SetEmitterCurveParam('BEGINSIZE_CURVE', 2, 0)
        emitter:SetEmitterCurveParam('ENDSIZE_CURVE', 5, 0)
    end,
    -- the splash of distortion of the Czar, as a burst of distortion: quicker, smaller, staying put
    ['/effects/emitters/czar_splash_01_emit.bp'] = function(emitter)
        emitter:SetEmitterCurveParam('LIFETIME_CURVE', 4, 0)
        emitter:SetEmitterCurveParam('YDIR_CURVE', 0, 0)
        emitter:SetEmitterCurveParam('Y_POSITION_CURVE', 0.2, 0)
        emitter:SetEmitterCurveParam('ENDSIZE_CURVE', 5, 0)
    end,
    -- the splash of small units destroyed on the water (ExplosionSmallWater), as a single burst from one
    -- point: they repeat every 5s, and the column and the spray are scattered around where they start
    ['/effects/emitters/Watertower_s.bp'] = function(emitter)
        emitter:SetEmitterParam('LIFETIME', 1)
        emitter:SetEmitterParam('REPEATTIME', 1)
        emitter:SetEmitterCurveParam('EMITRATE_CURVE', 6, 0)
        emitter:SetEmitterCurveParam('SIZE_CURVE', 0, 0)
    end,
    ['/effects/emitters/Watersplash_s.bp'] = function(emitter)
        emitter:SetEmitterParam('LIFETIME', 1)
        emitter:SetEmitterParam('REPEATTIME', 1)
        emitter:SetEmitterCurveParam('EMITRATE_CURVE', 10, 0)
        emitter:SetEmitterCurveParam('SIZE_CURVE', 0, 0)
    end,
    ['/effects/emitters/Water_pie_s.bp'] = function(emitter)
        emitter:SetEmitterParam('LIFETIME', 1)
        emitter:SetEmitterParam('REPEATTIME', 1)
        emitter:SetEmitterCurveParam('LIFETIME_CURVE', 20, 0)
    end,
    -- the slow rings of the impact of the Salvation, all spreading as far, to 9
    ['/effects/emitters/aeon_quanticcluster_hit_08_emit.bp'] = function(emitter)
        emitter:SetEmitterCurveParam('ENDSIZE_CURVE', 9, 0)
    end,
}

-- held by a shield, the shell drills. The streak of its trail grows back up its path, as if from a thruster
-- pushing harder and harder (aeon_sonance_drill_thrust_01, which lasts until the shell is released). And it
-- pulses, faster and harder as the drill goes on: with each pulse a burst of energy orbs sprays back up the
-- path like the sparks of a drill, in a cone around it (jets evenly around the cone, turned by a random
-- angle with each burst), flying further pulse by pulse, and the shield flares as if hit: only the effect,
-- no damage is dealt. When the shell is released it flashes and the air distorts
local Drill = {}
Drill.Tick = 3 -- tick of the hold the streak starts at
Drill.ThrustBack = 0.6 -- distance up the path from the shell that the streak starts at, so none of it shows ahead
Drill.PulseTicks = { 6, 13, 19, 24, 28, 31, 34, 36 } -- ticks of the hold the shell pulses at
-- from the first pulse to the last:
Drill.BurstRate = { 20, 29 } -- orbs per tick of the jets around the cone together, for the two ticks of a burst
Drill.BurstScale = { 1.1, 1.4 } -- of the orbs
Drill.SparkLife = { 9, 14 } -- ticks the orbs live, give or take 40%: with their speed, how far they fly
Drill.SparkSpeed = 0.25 -- of the orbs, per tick, give or take 45%
Drill.Jets = 16 -- around the cone, close enough together to draw its surface
Drill.Along = 0.87 -- direction of the jets, up the path and out from it: cos and sin of half the
Drill.Across = 0.5 -- angle of the cone (60 degrees)
Drill.Spread = 0.08 -- random spread of the direction of the jets, small so that the orbs keep to the surface of the cone
Drill.ConeScatter = 0.1 -- random offset of where the orbs of the cone come from
Drill.FlashScale = 2.5 -- of the release flash, as the drill flashes
-- strength of the burst of sparks left where the shell broke through a shield, as a pulse from first (0)
-- to last (1)
Drill.BreakBurst = 1

-- both hits fling motes out around the path, about as many as the sparkles of the explosion (some 45)
local HitBurst = {}
HitBurst.Strength = 0 -- as a pulse of the drill from first (0, 40 motes) to last (1, 58)
HitBurst.Along = 0.26 -- direction of the burst, back up the path and out from it: cos and sin of the angle
HitBurst.Across = 0.97 -- from the path (75 degrees), so that it flies out nearly square to it

-- held in terrain or a unit, the shell does not drill: it sits like a bomb, swelling, while air swirls into
-- it as into a vortex. Motes fade in just outside the damage area and spiral flat into the core, turning
-- faster as they close in, in a stream that thickens toward the second hit. From the start the air distorts
-- in a circle closing in with them, and on the ground puffs of dust appear evenly around and curl in, more
-- and thicker toward the end, or on the water waves roll in. In the last moments a faint layer of tiny bits of debris collapses into it
-- (as on the impact of the Salvation). The second hit adds the slow rings of the Salvation, a flash of
-- dark rays, electricity and a burst of distortion to the explosion. A shell that lodged after passing on,
-- where nothing exploded, kicks up dirt or a splash and a weak ripple of air as it lands. On the water the
-- shell is held on the surface as on the ground, and both hits splash. Nothing here is the energy
-- of the explosion: that would read as damage. Each mote is a small projectile drawn as a glowing point,
-- set moving a few times
local Vortex = {}
Vortex.MoteBlueprint = '/effects/Entities/AIFSonanceVortexMote01/AIFSonanceVortexMote01_proj.bp'
Vortex.Count = 300
Vortex.MoteSize = 0.21 -- full size of a mote, less than 1: the draw scale carries the fade as well (SonanceFade in mesh.fx)
Vortex.SmallestSize = 0.4 -- of the full size of a mote, the size of each is random between
-- each mote, with its own random path. Ranges are { lowest, highest }:
Vortex.Reach = { 1.1, 1.32 } -- of the damage radius, that it appears at: outside the edge of the damage area
Vortex.Height = { 0.02, 0.15 } -- of the damage radius, above the core, that it appears at: flat, with some depth
Vortex.Flight = { 8, 14 } -- ticks it takes to spiral in
Vortex.Turns = { 0.4, 0.8 } -- around the core on the way, faster and faster
Vortex.Segments = 6 -- straight stretches it flies its spiral in
Vortex.FadeTicks = 8 -- that it fades in over
Vortex.FirstTick = 3 -- tick of the hold the first motes appear at, after the explosion
Vortex.DebrisSize = 1 / 3 -- of the damage radius: the radius of the layer of debris as it appears
Vortex.DebrisTicks = 10 -- before the second hit, that the debris appears and collapses over
Vortex.DistortSize = 0.6 -- of the damage radius: the radius of the distorted air as it appears
-- with the motes, on the ground puffs of dust are picked up around the core and drawn into it. Each is a
-- few faint overlapping particles: the more, the thicker
Vortex.DustPuffs = 30 -- more and more of them toward the end
-- of the damage radius, where each appears: a puff (about 2 across) reaching the edge of the damage area
Vortex.DustReach = { 0.7, 0.8 }
Vortex.DustJitter = 0.4 -- radians, how far each strays from evenly around
Vortex.DustLife = { 6, 10 } -- ticks each takes to reach the core
Vortex.DustRate = { 1, 5 } -- particles in each, from the first to the last
Vortex.DustLift = 1.2 -- above the ground that each appears, fading in: more than half the width of a puff
-- each curls in: it sets off around the core, the way the motes turn, and is pulled into it, arriving on
-- time. How fast it sets off around, as a share of the speed it would fly straight in at
Vortex.DustCurl = 1.0
-- the core sits where the shell stopped: its glow and sparkles, as in flight, at least this far above
-- the surface, as the shell stops a little into the ground
Vortex.CoreLift = 0.4
-- the core swells as it charges, until it explodes. Scale of its glow and sparkles, as a multiple of
-- their scale in flight
Vortex.CoreSwell = 2.0 -- by the end of the hold, growing faster and faster
Vortex.DirtScale = 1.3 -- of the dirt kicked up as the shell hits the ground, directly or lodging
Vortex.SplashScale = 1 -- of the splash as the shell hits the water
-- on the water, waves roll in instead of the dust: the crests of the ripples of idle units on the water
-- (water_idle_ripples_03), running inward
Vortex.WaveSize = 1.1 -- of the damage radius: the radius of each wave as it starts
Vortex.WaveTicks = 12 -- that each takes to roll into the core
Vortex.WaveEvery = 1.5 -- ticks between them, on average: whole ticks, 1 and 2 by turns
Vortex.WaveLift = 0.15 -- above the water: flat effects right on it can be drawn under it
Vortex.WaveCopies = 2 -- of each wave, overlapping: more for a stronger wave
Vortex.DirtLife = 15 -- ticks the dirt lasts, give or take 30%
Vortex.RippleRadius = 0.3 -- of the ripple of air of a shell that lodged, as a fraction of the damage radius


--- A wave rolling in over the water to the shell: the crest of the ripples of idle units on the water
--- (water_idle_ripples_03, emitting without end, scattered a little), as a single wave closing in from 2 to
--- 0.2, just above the water (the core it is created at is higher), so that it is not drawn under it.
--- Sizes are for scale 1
---@param emitter moho.IEffect
---@param ticks number  # that it takes to roll in
local function SetUpWave(emitter, ticks)
    emitter:SetEmitterParam('LIFETIME', 1)
    emitter:SetEmitterCurveParam('EMITRATE_CURVE', Vortex.WaveCopies, 0)
    emitter:SetEmitterCurveParam('LIFETIME_CURVE', ticks, 0)
    emitter:SetEmitterCurveParam('VELOCITY_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('X_POSITION_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('Z_POSITION_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('Y_POSITION_CURVE', Vortex.WaveLift - Vortex.CoreLift, 0)
    emitter:SetEmitterCurveParam('BEGINSIZE_CURVE', 2, 0)
    emitter:SetEmitterCurveParam('ENDSIZE_CURVE', 0.2, 0)
end

--- The ripple of air of a shell that lodged: the distortion of the Mercy, small and quick (8 ticks, size
--- 0.1 to 2)
---@param emitter moho.IEffect
local function SetUpRipple(emitter)
    emitter:SetEmitterParam('LIFETIME', 1)
    emitter:SetEmitterCurveParam('EMITRATE_CURVE', 1, 0)
    emitter:SetEmitterCurveParam('LIFETIME_CURVE', 8, 0)
    emitter:SetEmitterCurveParam('VELOCITY_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('ROTATION_RATE_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('Y_POSITION_CURVE', 0, 0)
    emitter:SetEmitterCurveParam('BEGINSIZE_CURVE', 0.1, 0)
    emitter:SetEmitterCurveParam('ENDSIZE_CURVE', 2, 0)
end

-- the flat effects of the explosion are created from an anchor that stands upright on the shell, see
-- CreateUprightEffects
local AnchorBlueprint = '/effects/Entities/AIFSonanceAnchor01/AIFSonanceAnchor01_proj.bp'

-- distance the shell is moved back along its path before it is released, so that
-- the engine registers the collision with whatever it is still resting against
local ReleaseBackstep = 1

-- the engine default, which the weapon targeting expects
local BallisticAcceleration = -4.9

-- impacts that end the shell immediately. Water is held on as the ground is
local FinalImpactTypes = {
    Underwater = true,
    UnitUnderwater = true,
}

--- Whether the first impact killed what it hit, for the shell to pass on through it: dead units and
--- collapsed shields no longer take collisions
---@param entity? Entity
---@return boolean
local function IsKilled(entity)
    return entity ~= nil and (IsDestroyed(entity) or entity.DisallowCollisions == true)
end

--- A point for effects of the drill to come from. Not turned: projectiles are created turned like the
--- shell, and the directions of the effects of the drill are given in the world
---@param shell AIFSonanceShell02
---@param x number
---@param y number
---@param z number
---@return Projectile
local function CreateDrillPoint(shell, x, y, z)
    local point = shell:CreateProjectile(AnchorBlueprint, 0, 0, 0, nil, nil, nil)
    Warp(point, Vector(x, y, z))
    point:SetOrientation(UnsafeQuaternion(0, 0, 0, 1), true)
    shell.Trash:Add(point)
    return point
end

--- Sprays a burst of sparks of the drill from an entity, in a direction: the motes of the firing of the
--- Emissary (aeon_sonance_muzzle_03), as a burst of two ticks. Their directions are its own (LocalVelocity),
--- the entity is not turned
---@param source Projectile
---@param army number
---@param scatter number    # random offset of where the orbs come from
---@param dx number
---@param dy number
---@param dz number
---@param spread number
---@param rate number   # orbs per tick
---@param scale number
---@param life number   # ticks the orbs live
---@param speed number  # distance per tick
local function SparkJet(source, army, scatter, dx, dy, dz, spread, rate, scale, life, speed)
    CreateEmitterAtEntity(source, army, EffectTemplate.ASonanceWeaponDrillSparks02)
        :SetEmitterParam('LIFETIME', 2)
        :SetEmitterCurveParam('BEGINSIZE_CURVE', 0.55, 0.3)
        :SetEmitterCurveParam('ENDSIZE_CURVE', 0.1, 0.1)
        :SetEmitterCurveParam('X_POSITION_CURVE', 0, scatter)
        :SetEmitterCurveParam('Y_POSITION_CURVE', 0, scatter)
        :SetEmitterCurveParam('Z_POSITION_CURVE', 0, scatter)
        :SetEmitterCurveParam('XDIR_CURVE', dx, spread)
        :SetEmitterCurveParam('YDIR_CURVE', dy, spread)
        :SetEmitterCurveParam('ZDIR_CURVE', dz, spread)
        :SetEmitterCurveParam('EMITRATE_CURVE', rate, 0)
        :SetEmitterCurveParam('LIFETIME_CURVE', life, 0.4 * life)
        :SetEmitterCurveParam('VELOCITY_CURVE', speed, 0.45 * speed)
        :ScaleEmitter(scale)
end

--- A random number in a range
---@param range number[] # lowest, highest
---@return number
local function RandomIn(range)
    return range[1] + (range[2] - range[1]) * Random()
end

--- Sprays a burst of sparks of the drill from a point: jets evenly around a cone back up the path of the
--- shell, turned by a random angle
---@param point Projectile
---@param army number
---@param ax number     # back up the path of the shell
---@param ay number
---@param az number
---@param f number      # strength, as a pulse of the drill from first (0) to last (1)
---@param along number  # cone: cos and sin of the angle from the path
---@param across number
local function SprayDrillSparks(point, army, ax, ay, az, f, along, across)
    -- around the path: s level, n square to both
    local sx, sz = az, -ax
    local side = MathSqrt(sx * sx + sz * sz)
    if side > 0.001 then
        sx, sz = sx / side, sz / side
    else
        sx, sz = 1, 0
    end
    local nx, ny, nz = ay * sz, az * sx - ax * sz, -ay * sx

    local jetRate = (Drill.BurstRate[1] + (Drill.BurstRate[2] - Drill.BurstRate[1]) * f) / Drill.Jets
    local burstScale = Drill.BurstScale[1] + (Drill.BurstScale[2] - Drill.BurstScale[1]) * f
    local life = Drill.SparkLife[1] + (Drill.SparkLife[2] - Drill.SparkLife[1]) * f
    local turn = 6.2832 * Random()
    for jet = 1, Drill.Jets do
        local angle = turn + 6.2832 * jet / Drill.Jets
        local out, up = across * MathCos(angle), across * MathSin(angle)
        SparkJet(point, army, Drill.ConeScatter, along * ax + out * sx + up * nx, along * ay + up * ny,
            along * az + out * sz + up * nz, Drill.Spread, jetRate, burstScale, life, Drill.SparkSpeed)
    end
end

--- Creates effects where the shell is, standing upright. Emitters are offset in the frame of the entity
--- they are created at, and the shell keeps the angle it came in at: flat effects that are lifted off
--- the ground would be shifted sideways instead. The anchor is only needed while they are created
---@param shell AIFSonanceShell02
---@param effects FileName[]
---@param scale number
---@param setup? fun(emitter: moho.IEffect)   # in place of the setup of EmitterSetup
---@return moho.IEffect[]
local function CreateUprightEffects(shell, effects, scale, setup)
    local x, y, z = shell:GetPositionXYZ()
    local anchor = shell:CreateProjectile(AnchorBlueprint, 0, 0, 0, nil, nil, nil)
    Warp(anchor, Vector(x, y, z))
    anchor:SetOrientation(UnsafeQuaternion(0, 0, 0, 1), true)
    local created = {}
    local width = 2 * shell.DamageData.DamageRadius
    for k, effect in effects do
        created[k] = CreateEmitterAtEntity(anchor, shell.Army, effect)
        local setUp = setup or EmitterSetup[effect]
        if setUp then
            setUp(created[k])
        end
        if EffectWidth[effect] then
            created[k]:ScaleEmitter(MathMin(scale, width / EffectWidth[effect]))
        else
            created[k]:ScaleEmitter(scale)
        end
    end
    anchor:Destroy()
    return created
end

--- Kicks up dirt where the shell hits the ground, only as it hits, or a splash where it hits the water,
--- see Vortex
---@param shell AIFSonanceShell02
---@param targetType string
local function KickUp(shell, targetType)
    if targetType == 'Terrain' then
        local dirt = CreateUprightEffects(shell, EffectTemplate.ASonanceWeaponLodgeDirt02, Vortex.DirtScale)
        for _, effect in dirt do
            effect:SetEmitterParam('LIFETIME', 1)
            effect:SetEmitterCurveParam('LIFETIME_CURVE', Vortex.DirtLife, 0.3 * Vortex.DirtLife)
        end
    elseif targetType == 'Water' then
        CreateUprightEffects(shell, EffectTemplate.ASonanceWeaponLodgeWater02, Vortex.SplashScale)
    end
end

-- Aeon T3 Static Artillery Projectile : uab2302
-- Hits, holds in place, then continues on its path and hits again for the same damage, 3.8s after the
-- first. When the first impact kills what it hit (a unit, or a shield that collapses), the shell passes
-- on through it instead, lodges in whatever it hits next without damaging it, and the second hit comes
-- when the 3.8s are up
---@class AIFSonanceShell02 : AArtilleryProjectile
---@field HasHeld? boolean          # the first impact has happened, the next damaging one is the last
---@field HeldBy? Shield            # the shield the shell is held by, if any
---@field FirstTarget? Unit|Prop|Shield # what the first impact hit, while the shell holds in it
---@field FirstImpactTick? number
---@field Passing? boolean          # passing on after killing what it first hit, to lodge in what it hits next
---@field TrailStreak? moho.IEffect
---@field HeldOn? string            # the type of what the shell is held in: what it hit first, or lodged in
AIFSonanceShell02 = ClassProjectile(AArtilleryProjectile) {
    -- created by the shell itself, see CreateTrails
    FxTrails = {},
    FxImpactUnit = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactProp = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactLand = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactWater = EffectTemplate.ASonanceWeaponHit02Core,

    ---@param self AIFSonanceShell02
    OnCreate = function(self)
        AArtilleryProjectileOnCreate(self)
        self:CreateTrails()
    end,

    --- The trail of the shell in flight. Its streak (the first of the trail emitters) is kept, so that it
    --- can be stopped while the shell is held: it would pile up on the shell and point ahead of it. The
    --- glow and sparkles are what is seen of the shell itself, they stay
    ---@param self AIFSonanceShell02
    ---@param streakOnly? boolean
    CreateTrails = function(self, streakOnly)
        for k, effect in EffectTemplate.ASonanceWeaponFXTrail02 do
            if k == 1 then
                if not self.TrailStreak then
                    self.TrailStreak = CreateEmitterOnEntity(self, self.Army, effect):ScaleEmitter(self.FxTrailScale)
                end
            elseif not streakOnly then
                CreateEmitterOnEntity(self, self.Army, effect):ScaleEmitter(self.FxTrailScale)
            end
        end
    end,

    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield   # nil for terrain and water
    OnImpact = function(self, targetType, targetEntity)
        -- dead units and collapsed shields, see Projectile.OnImpact. Checked here as well, so that the
        -- shell does not lodge in what it just killed
        if targetEntity and targetEntity.DisallowCollisions then
            return
        end
        if self.Passing and not FinalImpactTypes[targetType] then
            self:Lodge(targetType, targetEntity)
            return
        end
        self.Passing = nil

        -- both impacts deal the same damage and explode alike: the shared impact effects are played
        -- by the base class, scale them to the damage radius, within the damage area (see EffectWidth)
        local radius = self.DamageData.DamageRadius
        local scale = MathMin(radius / ExplosionRadius, 2 * radius / CoreWidth)
        self.FxLandHitScale = scale
        self.FxUnitHitScale = scale
        self.FxPropHitScale = scale
        self.FxWaterHitScale = scale
        if targetType == 'Shield' and not self.HasHeld then
            self.HeldBy = targetEntity
        end
        AArtilleryProjectileOnImpact(self, targetType, targetEntity)
    end,

    --- Only called for impacts that applied damage
    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield   # nil for terrain and water
    OnImpactDestroy = function(self, targetType, targetEntity)
        -- the rest of the original explosion, on both impacts
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponHit02Final, self.DamageData.DamageRadius / ExplosionRadius)
        self:ShakeCamera(25, 3, 0, 1.5)

        if self.HasHeld or FinalImpactTypes[targetType] then
            -- the final explosion: the slow rings of the Salvation, at their own size, and a splash on the water
            CreateUprightEffects(self, EffectTemplate.ASonanceWeaponFinalRings02, 1)
            if targetType == 'Water' then
                KickUp(self, targetType)
            end
            self:BurstMotes()
            self:Destroy()
            return
        end

        self.HasHeld = true
        self.HeldOn = targetType
        self.FirstImpactTick = GetGameTick()
        KickUp(self, targetType)
        self:BurstMotes()

        -- it killed what it hit: not destroying the shell is enough for it to fly on, as the railgun of
        -- the Seadragon in BlackOps Unleashed (XCannon01) does
        if IsKilled(targetEntity) then
            if targetType == 'Shield' then
                self:BreakThrough(self:GetVelocity())
            end
            self:StartPassing()
            return
        end

        local vx, vy, vz, speed = self:Freeze()
        self.FirstTarget = targetEntity
        self.Trash:Add(ForkThread(self.HoldThread, self, vx, vy, vz, speed, 1))
    end,

    --- Stops the shell where it is
    ---@param self AIFSonanceShell02
    ---@return number vx    # velocity it had, in distance per tick
    ---@return number vy
    ---@return number vz
    ---@return number speed
    Freeze = function(self)
        local vx, vy, vz = self:GetVelocity()
        local speed = MathSqrt(vx * vx + vy * vy + vz * vz)
        if speed < 0.01 then
            vx, vy, vz, speed = 0, -0.5, 0, 0.5
        end

        if self.TrailStreak then
            self.TrailStreak:Destroy()
            self.TrailStreak = nil
        end
        self:SetCollideSurface(false)
        self:SetCollideEntity(false)
        self:SetBallisticAcceleration(0)
        self:SetVelocity(0, 0, 0)
        return vx, vy, vz, speed
    end,

    --- A hit flings motes out around the path, see HitBurst
    ---@param self AIFSonanceShell02
    BurstMotes = function(self)
        local vx, vy, vz = self:GetVelocity()
        local speed = MathSqrt(vx * vx + vy * vy + vz * vz)
        if speed < 0.001 then
            vx, vy, vz, speed = 0, -1, 0, 1
        end
        local x, y, z = self:GetPositionXYZ()
        SprayDrillSparks(CreateDrillPoint(self, x, y, z), self.Army, -vx / speed, -vy / speed, -vz / speed,
            HitBurst.Strength, HitBurst.Along, HitBurst.Across)
    end,

    --- The first impact collapsed the shield it hit: a burst of sparks is left where the shell broke through
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity of the shell
    ---@param vy number
    ---@param vz number
    BreakThrough = function(self, vx, vy, vz)
        local speed = MathSqrt(vx * vx + vy * vy + vz * vz)
        if speed < 0.001 then
            return
        end
        local x, y, z = self:GetPositionXYZ()
        SprayDrillSparks(CreateDrillPoint(self, x, y, z), self.Army, -vx / speed, -vy / speed, -vz / speed,
            Drill.BreakBurst, Drill.Along, Drill.Across)
    end,

    --- The first impact killed what it hit: the shell flies on through it, to lodge in what it hits next.
    --- Should it hit nothing in time, it explodes where it is when the time is up
    ---@param self AIFSonanceShell02
    StartPassing = function(self)
        self.Passing = true
        self.FirstTarget = nil
        self.HeldBy = nil
        self.Trash:Add(ForkThread(self.PassTimeoutThread, self))
    end,

    --- As StartPassing, for a shell that was already held: it is set moving again first
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity to fly on with, in distance per tick
    ---@param vy number
    ---@param vz number
    PassOn = function(self, vx, vy, vz)
        self:SetBallisticAcceleration(BallisticAcceleration)
        self:SetVelocity(10 * vx, 10 * vy, 10 * vz)
        self:SetCollideSurface(true)
        self:SetCollideEntity(true)
        self:CreateTrails(true)
        self:StartPassing()
    end,

    ---@param self AIFSonanceShell02
    PassTimeoutThread = function(self)
        WaitTicks(HoldTicks - (GetGameTick() - self.FirstImpactTick))
        if self.Passing then
            self.Passing = nil
            self:SetBallisticAcceleration(0)
            self:SetVelocity(0, 0, 0)
            self:OnImpact('Terrain', nil)
        end
    end,

    --- Having passed on, the shell lodges in what it hits, without damaging it, and holds there for the rest
    --- of the time before the second hit
    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield
    Lodge = function(self, targetType, targetEntity)
        self.Passing = nil
        self.HeldOn = targetType
        if targetType == 'Shield' then
            self.HeldBy = targetEntity
        end
        local vx, vy, vz, speed = self:Freeze()
        local startTick = GetGameTick() - self.FirstImpactTick + 1
        self.Trash:Add(ForkThread(self.HoldThread, self, vx, vy, vz, speed, startTick))
    end,

    --- Holds the shell until the second hit: drilling into a shield, or as a bomb, see VortexThread
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity at the first impact, in distance per tick
    ---@param vy number
    ---@param vz number
    ---@param speed number
    ---@param startTick number  # tick of the 3.8s to start at, later when the shell lodged after passing on
    HoldThread = function(self, vx, vy, vz, speed, startTick)
        if not self.HeldBy then
            self:VortexThread(vx, vy, vz, speed, startTick)
            return
        end

        -- the drill: the sparks spray back up the path (a) and out from it, the streak back up it, from a
        -- little up the path. Pulse by pulse, f goes from 0 to 1
        local ax, ay, az = -vx / speed, -vy / speed, -vz / speed
        local cx, cy, cz = self:GetPositionXYZ()
        local shield = self.HeldBy
        local army = self.Army
        local radius = self.DamageData.DamageRadius
        local pulseCount = table.getn(Drill.PulseTicks)
        local carrier
        local pulse = 1
        while Drill.PulseTicks[pulse] and Drill.PulseTicks[pulse] < startTick do
            pulse = pulse + 1
        end

        -- the point the sparks come from
        local conePoint = CreateDrillPoint(self, cx, cy, cz)
        for tick = startTick, HoldTicks do
            -- the first impact killed what it hit after all, when the damage only lands a tick later
            if tick == 2 and IsKilled(self.FirstTarget) then
                if carrier then
                    carrier:Destroy()
                end
                conePoint:Destroy()
                self:BreakThrough(vx, vy, vz)
                self:PassOn(vx, vy, vz)
                return
            end
            if not carrier and tick >= Drill.Tick then
                local back = Drill.ThrustBack
                carrier = CreateDrillPoint(self, cx + back * ax, cy + back * ay, cz + back * az)
                CreateEmitterAtEntity(carrier, army, EffectTemplate.ASonanceWeaponDrillThrust02)
                    :SetEmitterCurveParam('XDIR_CURVE', ax, 0)
                    :SetEmitterCurveParam('YDIR_CURVE', ay, 0)
                    :SetEmitterCurveParam('ZDIR_CURVE', az, 0)
            end
            if tick == Drill.PulseTicks[pulse] then
                local f = (pulse - 1) / (pulseCount - 1)
                pulse = pulse + 1

                SprayDrillSparks(conePoint, army, ax, ay, az, f, Drill.Along, Drill.Across)

                if shield and not IsDestroyed(shield) and shield:IsUp() then
                    -- as for an impact: from the point of impact to the centre of the shield
                    local hx, hy, hz = shield:GetPositionXYZ()
                    ForkThread(shield.CreateImpactEffect, shield, Vector(hx - cx, hy - cy, hz - cz))
                end
            end
            WaitTicks(1)
        end

        -- the drill flashes and is gone as the shell is released, the air distorting as when the bomb
        -- goes off
        for _, effect in EffectTemplate.ASonanceWeaponRelease02 do
            CreateEmitterAtEntity(self, army, effect):ScaleEmitter(Drill.FlashScale)
        end
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponFinalDistort02, radius / ExplosionRadius)
        if carrier then
            carrier:Destroy()
        end
        conePoint:Destroy()
        self:Release(vx, vy, vz, speed)
    end,

    --- Held in terrain or a unit: the shell sits like a bomb while air swirls into it, see Vortex
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity at the impact, in distance per tick
    ---@param vy number
    ---@param vz number
    ---@param speed number
    ---@param startTick number  # tick of the 3.8s to start at, later when the shell lodged after passing on
    VortexThread = function(self, vx, vy, vz, speed, startTick)
        local radius = self.DamageData.DamageRadius
        local scale = radius / ExplosionRadius
        local army = self.Army

        -- the core, sitting on the surface
        local px, py, pz = self:GetPositionXYZ()
        local surface = GetSurfaceHeight(px, pz)
        local cy = MathMax(py, surface + Vortex.CoreLift)
        local corePoint = CreateDrillPoint(self, px, cy, pz)
        local core = {}
        for k, effect in EffectTemplate.ASonanceWeaponFXTrail02 do
            if k > 1 then
                table.insert(core, CreateEmitterOnEntity(corePoint, army, effect):ScaleEmitter(self.FxTrailScale))
            end
        end

        -- landing after passing on: dirt in the ground or a splash in the water, a ripple of air
        if startTick > 1 then
            KickUp(self, self.HeldOn)
            CreateUprightEffects(self, EffectTemplate.ASonanceWeaponLodgeAir02, radius * Vortex.RippleRadius, SetUpRipple)
        end

        -- plan the motes: on each tick, what to do with which. Appearing later and later, more of them
        -- toward the end (the square root), each arriving in the core by the second hit
        local plan = {}
        local function Plan(tick, action)
            plan[tick] = plan[tick] or {}
            table.insert(plan[tick], action)
        end
        local first = MathMax(startTick, Vortex.FirstTick)
        local debrisStart = MathMax(first, HoldTicks + 1 - Vortex.DebrisTicks)
        Plan(debrisStart, { 'debris', HoldTicks + 1 - debrisStart })
        Plan(first, { 'distort', HoldTicks + 1 - first })
        if self.HeldOn == 'Water' then
            -- the waves: the last rolls into the core as the second hit explodes
            local lastWave = HoldTicks + 1 - Vortex.WaveTicks
            local k = 0
            while lastWave - MathFloor(k * Vortex.WaveEvery) >= first do
                Plan(lastWave - MathFloor(k * Vortex.WaveEvery), { 'wave', Vortex.WaveTicks })
                k = k + 1
            end
        elseif self.HeldOn == 'Terrain' then
            -- coming in evenly from all around: each, in the order they appear, turned on by the golden
            -- angle from the last, into the widest gap left, give or take a little
            local turn = 2 * MathPi * Random()
            for p = 1, Vortex.DustPuffs do
                local life = Vortex.DustLife[1] + MathFloor((Vortex.DustLife[2] - Vortex.DustLife[1] + 1) * Random())
                life = MathMin(life, HoldTicks + 1 - first)
                local last = HoldTicks + 1 - life
                local progress = MathSqrt((p - Random()) / Vortex.DustPuffs)
                local heading = turn + p * 2.39996 + Vortex.DustJitter * (Random() - 0.5)
                Plan(first + MathFloor((last - first) * progress), { 'dust', life, progress, heading })
            end
        end
        local motes = {}
        for i = 1, Vortex.Count do
            local flight = Vortex.Flight[1] + MathFloor((Vortex.Flight[2] - Vortex.Flight[1] + 1) * Random())
            flight = MathMin(flight, HoldTicks + 1 - first)
            if flight >= Vortex.Segments then
                local last = HoldTicks + 1 - flight
                local appear = first + MathFloor((last - first) * MathSqrt((i - Random()) / Vortex.Count))
                local reach = radius * RandomIn(Vortex.Reach)
                local height = radius * RandomIn(Vortex.Height)
                local angle = 2 * MathPi * Random()
                local turns = 2 * MathPi * RandomIn(Vortex.Turns)

                -- the spiral, as points relative to the core
                local points = {}
                for k = 0, Vortex.Segments do
                    local q = k / Vortex.Segments
                    local a = angle + turns * q * q
                    points[k] = { reach * (1 - q) * MathCos(a), height * (1 - q), reach * (1 - q) * MathSin(a), appear + MathFloor(flight * q + 0.5) }
                end

                local mote = { size = RandomIn({ Vortex.SmallestSize, 1 }), from = points[0] }
                motes[i] = mote
                Plan(appear, { 'appear', mote })
                for k = 0, Vortex.Segments - 1 do
                    local a, b = points[k], points[k + 1]
                    local time = 0.1 * (b[4] - a[4])
                    Plan(a[4], { 'move', mote, (b[1] - a[1]) / time, (b[2] - a[2]) / time, (b[3] - a[3]) / time })
                end
                for f = 1, Vortex.FadeTicks do
                    Plan(appear + f, { 'fade', mote, f / Vortex.FadeTicks })
                end
                Plan(appear + flight, { 'arrive', mote })
            end
        end

        for tick = startTick, HoldTicks do
            -- the first impact killed what it hit after all, when the damage only lands a tick later
            if tick == 2 and IsKilled(self.FirstTarget) then
                for _, mote in motes do
                    if mote.entity then
                        mote.entity:Destroy()
                    end
                end
                corePoint:Destroy()
                self:PassOn(vx, vy, vz)
                return
            end
            -- the core swelling
            local q = tick / HoldTicks
            local swell = 1 + (Vortex.CoreSwell - 1) * q * q
            for _, effect in core do
                effect:ScaleEmitter(self.FxTrailScale * swell)
            end

            if plan[tick] then
                for _, action in plan[tick] do
                    local kind, mote = action[1], action[2]
                    if kind == 'debris' then
                        CreateEmitterAtEntity(corePoint, army, EffectTemplate.ASonanceWeaponVortexDebris02)
                            :ScaleEmitter(radius * Vortex.DebrisSize)
                            :SetEmitterCurveParam('LIFETIME_CURVE', mote, 0)
                    elseif kind == 'distort' then
                        CreateEmitterAtEntity(corePoint, army, EffectTemplate.ASonanceWeaponVortexDistort02)
                            :ScaleEmitter(radius * Vortex.DistortSize)
                            :SetEmitterCurveParam('LIFETIME_CURVE', mote, 0)
                    elseif kind == 'wave' then
                        local wave = CreateEmitterAtEntity(corePoint, army, EffectTemplate.ASonanceWeaponVortexWave02)
                        SetUpWave(wave, mote)
                        wave:ScaleEmitter(radius * Vortex.WaveSize)
                    elseif kind == 'dust' then
                        -- a puff appearing above the ground around the core, curling into it: setting off around
                        -- it (s, the way the motes turn), pulled in by a steady acceleration (a) that brings it to
                        -- the core at the end of its life: from p = s t + a t^2 / 2. Distance per tick
                        local life, progress, heading = mote, action[3], action[4]
                        local reach = radius * RandomIn(Vortex.DustReach)
                        local dx, dz = reach * MathCos(heading), reach * MathSin(heading)
                        local ground = GetSurfaceHeight(px + dx, pz + dz) + Vortex.DustLift
                        local dy = cy - ground
                        local around = Vortex.DustCurl * reach / life
                        local sx, sz = -around * MathSin(heading), around * MathCos(heading)
                        local ax = 2 * (-dx - sx * life) / (life * life)
                        local ay = 2 * dy / (life * life)
                        local az = 2 * (-dz - sz * life) / (life * life)
                        local rate = Vortex.DustRate[1] + (Vortex.DustRate[2] - Vortex.DustRate[1]) * progress
                        local puff = CreateDrillPoint(self, px + dx, ground, pz + dz)
                        CreateEmitterAtEntity(puff, army, EffectTemplate.ASonanceWeaponVortexDust02)
                            :SetEmitterCurveParam('XDIR_CURVE', sx / around, 0)
                            :SetEmitterCurveParam('YDIR_CURVE', 0, 0)
                            :SetEmitterCurveParam('ZDIR_CURVE', sz / around, 0)
                            :SetEmitterCurveParam('VELOCITY_CURVE', around, 0)
                            :SetEmitterCurveParam('X_ACCEL_CURVE', ax, 0)
                            :SetEmitterCurveParam('Y_ACCEL_CURVE', ay, 0)
                            :SetEmitterCurveParam('Z_ACCEL_CURVE', az, 0)
                            :SetEmitterCurveParam('LIFETIME_CURVE', life, 0)
                            :SetEmitterCurveParam('EMITRATE_CURVE', rate, 0)
                    elseif kind == 'appear' then
                        local entity = self:CreateProjectile(Vortex.MoteBlueprint, 0, 0, 0, nil, nil, nil)
                        Warp(entity, Vector(px + mote.from[1], cy + mote.from[2], pz + mote.from[3]))
                        -- faded out: the whole part of the draw scale is how far, in tenths
                        mote.full = Vortex.MoteSize * mote.size
                        entity:SetDrawScale(10 + mote.full)
                        self.Trash:Add(entity)
                        mote.entity = entity
                    elseif mote.entity and not IsDestroyed(mote.entity) then
                        if kind == 'move' then
                            mote.entity:SetVelocity(action[3], action[4], action[5])
                        elseif kind == 'fade' then
                            mote.entity:SetDrawScale(MathFloor(10 * (1 - action[3]) + 0.5) + mote.full)
                        else
                            mote.entity:Destroy()
                        end
                    end
                end
            end
            WaitTicks(1)
        end

        for _, mote in motes do
            if mote.entity and not IsDestroyed(mote.entity) then
                mote.entity:Destroy()
            end
        end
        corePoint:Destroy()
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponVortexFinal02, scale)
        self:Release(vx, vy, vz, speed)
    end,

    --- Sends the shell on along its path, to hit again right away
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity at the impact, in distance per tick
    ---@param vy number
    ---@param vz number
    ---@param speed number
    Release = function(self, vx, vy, vz, speed)
        self.FirstTarget = nil

        -- on the water the shell is already where it hits: it hits there, rather than flying on to hit the
        -- water again, which the engine does not register (it goes on to the seabed)
        if self.HeldOn == 'Water' then
            self:OnImpact('Water', nil)
            return
        end

        local x, y, z = self:GetPositionXYZ()
        local backstep = ReleaseBackstep / speed
        self:SetPosition(Vector(x - vx * backstep, y - vy * backstep, z - vz * backstep), true)

        self:SetBallisticAcceleration(BallisticAcceleration)
        self:SetVelocity(10 * vx, 10 * vy, 10 * vz)
        self:SetCollideSurface(true)
        self:SetCollideEntity(true)
        self:CreateTrails(true)
    end,
}
TypeClass = AIFSonanceShell02
