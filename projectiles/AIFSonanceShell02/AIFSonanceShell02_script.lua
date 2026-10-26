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

-- radius of the stock Sonance explosion's ring at scale 1 (aeon_sonance_hit_02, end size 5). Both
-- explosions are scaled from it to the damage radius
local ExplosionRadius = 2.5

-- width of each explosion emitter at scale 1, particle travel included. None is scaled wider than the
-- damage area
local EffectWidth = {
    -- these two keep spreading as they fade: kept 10% inside
    ['/effects/emitters/aeon_sonance_hit_02_emit.bp'] = 5.6,
    ['/effects/emitters/aeon_sonance02_hit_ring_distort_emit.bp'] = 5.5,
    ['/effects/emitters/aeon_sonance02_final_distort_emit.bp'] = 6.9, -- 20% inside
    ['/effects/emitters/aeon_sonance_hit_01_emit.bp'] = 10.1,
    ['/effects/emitters/aeon_sonance_hit_03_emit.bp'] = 7.6,
    ['/effects/emitters/quark_bomb_explosion_08_emit.bp'] = 8.4,
    ['/effects/emitters/aeon_sonance02_hit_flash_emit.bp'] = 10.1,
    ['/effects/emitters/aeon_sonance02_hit_elect_emit.bp'] = 12,
    ['/effects/emitters/aeon_sonance02_hit_rays_emit.bp'] = 5.6, -- 25% outside
    ['/effects/emitters/aeon_sonance02_hit_glare_emit.bp'] = 8,
}
-- the base class scales its impact effects (ASonanceWeaponHit02Core) together: the widest of them
local CoreWidth = 10.1

-- Held in a shield, the shell drills: a streak grows back up its path (aeon_sonance02_drill_thrust), and
-- it pulses faster and harder. Each pulse sprays a cone of sparks back up the path and plays the shield's
-- impact effect, without damage. On release it flashes and the air distorts
local Drill = {
    Tick = 3, -- hold tick the streak starts at
    ThrustBack = 0.6, -- the streak starts this far up the path, so none of it shows ahead of the shell
    PulseTicks = { 6, 13, 19, 24, 28, 31, 34, 36 }, -- hold ticks of the pulses
    -- { first pulse, last pulse }:
    BurstRate = { 20, 29 }, -- sparks per tick of all jets together, for the 2 ticks of a burst
    BurstScale = { 1.1, 1.4 },
    SparkLife = { 9, 14 }, -- ticks, +-40%
    Jets = 16, -- around the cone
    Along = 0.87, -- cos and sin of the cone's half angle (30 degrees)
    Across = 0.5,
    Spread = 0.08, -- of the jet directions, small to keep the sparks on the cone
    BreakBurst = 1, -- strength of the sparks left when a shield collapses, see SprayDrillSparks
}

-- both hits fling sparks out around the path
local HitBurst = {
    Strength = 0, -- see SprayDrillSparks: 40 sparks
    Along = 0.26, -- cos and sin of the angle from the path (75 degrees)
    Across = 0.97,
}

-- Held in terrain, water or a unit, the shell swells like a bomb while motes spiral into it, thickening
-- toward the second hit. Distortion closes in with them, dust curls in on the ground, waves roll in on the
-- water, and debris collapses into it at the end. A lodged shell also kicks up dirt or a splash and a small
-- air ripple. None of this looks like the explosion, which would read as damage. Motes are small
-- projectiles, given a new velocity at each straight stretch of their spiral
local Vortex = {
    MoteBlueprint = '/effects/Entities/AIFSonance02VortexMote/AIFSonance02VortexMote_proj.bp',
    Count = 300,
    MoteSize = { 0.084, 0.21 }, -- below 1: the whole part of the draw scale is the fade (SonanceFade in mesh.fx)
    -- ranges are random per mote or puff
    Reach = { 1.1, 1.32 },  -- start distance in damage radii, outside the damage area
    Height = { 0.02, 0.15 }, -- start height above the core, in damage radii
    Flight = { 8, 14 },     -- ticks to reach the core
    Turns = { 0.4, 0.8 },   -- around the core, speeding up
    Segments = 6,           -- straight stretches of the spiral
    FadeTicks = 8,
    FirstTick = 3,          -- hold tick the first motes appear at
    DebrisSize = 1 / 3,     -- start radius in damage radii
    DebrisTicks = 10,       -- before the second hit
    DistortSize = 0.6,      -- start radius in damage radii
    DustPuffs = 30,         -- more of them toward the end
    DustReach = { 0.7, 0.8 }, -- start distance in damage radii: the puffs, about 2 across, reach its edge
    DustJitter = 0.4,       -- radians off evenly spaced
    DustLife = { 6, 10 },   -- ticks to reach the core
    DustRate = { 1, 5 },    -- particles per puff, first to last
    DustLift = 1.2,         -- start height above the ground
    DustCurl = 1.0,         -- sideways start speed, as a share of the speed straight in
    CoreLift = 0.4,         -- min height of the core above the surface: the shell stops a little into the ground
    CoreSwell = 2.0,        -- scale of the core at the second hit, relative to its scale in flight
    -- waves: the crests of water_idle_ripples_03, running inward
    WaveSize = 1.1, -- start radius in damage radii
    WaveTicks = 12, -- to reach the core: the LifetimeCurve of aeon_sonance02_vortex_wave_emit.bp
    WaveEvery = 1.5, -- ticks between waves, 1 and 2 alternating
    RippleRadius = 0.3, -- air ripple of a lodged shell, in damage radii
}

-- invisible entity to create effects at, see CreatePoint
local AnchorBlueprint = '/effects/Entities/AIFSonance02Anchor/AIFSonance02Anchor_proj.bp'

-- the engine default, which the weapon targeting expects
local BallisticAcceleration = -4.9

--- Dead units and collapsed shields no longer take collisions
---@param entity? Unit|Prop|Shield
---@return boolean
local function IsKilled(entity)
    return entity ~= nil and (IsDestroyed(entity) or entity.DisallowCollisions == true)
end

--- The unit the shell rides along with: the unit it is held in or the owner of the shield, if it is mobile
---@param targetType string
---@param entity? Unit|Prop|Shield
---@return Unit?
local function MobileHost(targetType, entity)
    if entity == nil or IsDestroyed(entity) then
        return nil
    end
    if targetType == 'Shield' then
        ---@cast entity Shield
        entity = entity.Owner
    elseif targetType ~= 'Unit' and targetType ~= 'UnitAir' then
        return nil
    end
    ---@cast entity Unit
    if entity and not IsDestroyed(entity) and entity.Blueprint.CategoriesHash['MOBILE'] then
        return entity
    end
    return nil
end

--- An invisible, unturned entity to create effects at. Emitters are offset and directed in the frame of
--- the entity they are created at, and the shell itself stays turned the way it came in
---@param shell AIFSonanceShell02
---@param x number
---@param y number
---@param z number
---@return Projectile
local function CreatePoint(shell, x, y, z)
    local point = shell:CreateProjectile(AnchorBlueprint, 0, 0, 0, nil, nil, nil)
    Warp(point, Vector(x, y, z))
    point:SetOrientation(UnsafeQuaternion(0, 0, 0, 1), true)
    shell.Trash:Add(point)
    return point
end

--- A burst of drill sparks in one direction. The direction is local to the source, so the source must not
--- be turned
---@param source Projectile
---@param army number
---@param dx number
---@param dy number
---@param dz number
---@param spread number
---@param rate number   # sparks per tick
---@param scale number
---@param life number   # ticks
local function SparkJet(source, army, dx, dy, dz, spread, rate, scale, life)
    CreateEmitterAtEntity(source, army, EffectTemplate.ASonanceWeaponDrillSparks02)
        :SetEmitterCurveParam('XDIR_CURVE', dx, spread)
        :SetEmitterCurveParam('YDIR_CURVE', dy, spread)
        :SetEmitterCurveParam('ZDIR_CURVE', dz, spread)
        :SetEmitterCurveParam('EMITRATE_CURVE', rate, 0)
        :SetEmitterCurveParam('LIFETIME_CURVE', life, 0.4 * life)
        :ScaleEmitter(scale)
end

---@param range number[] # { from, to }
---@param f number         # 0 to 1
---@return number
local function Lerp(range, f)
    return range[1] + (range[2] - range[1]) * f
end

---@param range number[] # { lowest, highest }
---@return number
local function RandomIn(range)
    return Lerp(range, Random())
end

--- A random whole number, both ends included
---@param range number[] # { lowest, highest }
---@return number
local function RandomTicksIn(range)
    return range[1] + MathFloor((range[2] - range[1] + 1) * Random())
end

--- Sprays drill sparks in jets evenly around a cone back up the shell's path, at a random turn
---@param point Projectile
---@param army number
---@param ax number     # unit vector back up the path
---@param ay number
---@param az number
---@param f number      # strength, from the first drill pulse (0) to the last (1)
---@param along number  # cos and sin of the cone's half angle
---@param across number
local function SprayDrillSparks(point, army, ax, ay, az, f, along, across)
    -- s: level and square to the path, n: square to both
    local sx, sz = az, -ax
    local side = MathSqrt(sx * sx + sz * sz)
    if side > 0.001 then
        sx, sz = sx / side, sz / side
    else
        sx, sz = 1, 0
    end
    local nx, ny, nz = ay * sz, az * sx - ax * sz, -ay * sx

    local jetRate = Lerp(Drill.BurstRate, f) / Drill.Jets
    local burstScale = Lerp(Drill.BurstScale, f)
    local life = Lerp(Drill.SparkLife, f)
    local turn = 2 * MathPi * Random()
    for jet = 1, Drill.Jets do
        local angle = turn + 2 * MathPi * jet / Drill.Jets
        local out, up = across * MathCos(angle), across * MathSin(angle)
        SparkJet(point, army, along * ax + out * sx + up * nx, along * ay + up * ny, along * az + out * sz + up * nz,
            Drill.Spread, jetRate, burstScale, life)
    end
end

--- Creates effects at the shell, upright, scaled no wider than the damage area (see EffectWidth)
---@param shell AIFSonanceShell02
---@param effects FileName[]
---@param scale number
local function CreateUprightEffects(shell, effects, scale)
    local anchor = CreatePoint(shell, shell:GetPositionXYZ())
    local width = 2 * shell.DamageData.DamageRadius
    for _, effect in effects do
        local emitter = CreateEmitterAtEntity(anchor, shell.Army, effect)
        if EffectWidth[effect] then
            emitter:ScaleEmitter(MathMin(scale, width / EffectWidth[effect]))
        else
            emitter:ScaleEmitter(scale)
        end
    end
    anchor:Destroy()
end

--- Dirt where the shell hits the ground, or a splash where it hits the water
---@param shell AIFSonanceShell02
---@param targetType string
local function KickUp(shell, targetType)
    if targetType == 'Terrain' then
        CreateUprightEffects(shell, EffectTemplate.ASonanceWeaponLodgeDirt02, 1)
    elseif targetType == 'Water' then
        CreateUprightEffects(shell, EffectTemplate.ASonanceWeaponLodgeWater02, 1)
    end
end

--- A point of a vortex mote's spiral, relative to the core, and the tick the mote reaches it
---@param mote table
---@param k number  # 0 to Vortex.Segments, from where it appears to the core
---@return number x
---@return number y
---@return number z
---@return number tick
local function SpiralPoint(mote, k)
    local q = k / Vortex.Segments
    local a = mote.angle + mote.turns * q * q
    local r = mote.reach * (1 - q)
    return r * MathCos(a), mote.height * (1 - q), r * MathSin(a), mote.appear + MathFloor(mote.flight * q + 0.5)
end

-- Aeon T3 Static Artillery Projectile : uab2302
-- Hits, holds still, then hits again where it is held (see ReadHits for the timing). Held in a mobile
-- unit or its shield, it rides along. If the first hit kills what it hit, the shell flies on and lodges,
-- without damage, in what it hits next
---@class AIFSonanceShell02 : AArtilleryProjectile
---@field HitsLeft? number          # including the next one
---@field HoldTicks? number         # between hits
---@field FirstImpactTick? number
---@field Passing? boolean          # flying on after the first hit killed its target
---@field TrailStreak? moho.IEffect
---@field HeldOn? string            # impact type of what the shell is held in
---@field HeldIn? Unit|Prop|Shield  # nil for terrain and water
---@field Host? Unit                # the mobile unit the shell rides along with, see Follow
---@field Riders? table             # entities that ride along: the shell and its effect points
AIFSonanceShell02 = ClassProjectile(AArtilleryProjectile) {
    -- see CreateTrails
    FxTrails = {},
    FxImpactUnit = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactProp = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactLand = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactWater = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactAirUnit = EffectTemplate.ASonanceWeaponHit02Core,
    FxImpactNone = EffectTemplate.ASonanceWeaponHit02Core,

    ---@param self AIFSonanceShell02
    OnCreate = function(self)
        AArtilleryProjectileOnCreate(self)
        self:CreateTrails()
    end,

    --- The streak (the first trail emitter) is kept, to stop it while the shell is held: it would pile up
    --- on the shell. The glow and sparkles are the shell itself, and stay
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
        -- as in Projectile.OnImpact, before lodging, so the shell does not lodge in what it just killed
        if targetEntity and targetEntity.DisallowCollisions then
            return
        end
        if self.Passing then
            self:Lodge(targetType, targetEntity)
            return
        end
        if not self.HitsLeft then
            self:ReadHits()
        end

        -- the base class plays the impact effects: scale them to the damage area, see EffectWidth
        local radius = self.DamageData.DamageRadius
        local scale = MathMin(radius / ExplosionRadius, 2 * radius / CoreWidth)
        self.FxLandHitScale = scale
        self.FxUnitHitScale = scale
        self.FxPropHitScale = scale
        self.FxWaterHitScale = scale
        self.FxAirUnitHitScale = scale
        self.FxNoneHitScale = scale
        AArtilleryProjectileOnImpact(self, targetType, targetEntity)
    end,

    --- Only called for impacts that applied damage
    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield   # nil for terrain and water
    OnImpactDestroy = function(self, targetType, targetEntity)
        -- the rest of the stock explosion
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponHit02Final, self.DamageData.DamageRadius / ExplosionRadius)
        self:ShakeCamera(25, 3, 0, 1.5)

        if self.HitsLeft <= 1 then
            -- the last hit
            CreateUprightEffects(self, EffectTemplate.ASonanceWeaponFinalRings02, 1)
            if targetType == 'Water' then
                KickUp(self, targetType)
            end
            self:BurstMotes()
            self:Destroy()
            return
        end

        self.HitsLeft = self.HitsLeft - 1
        self.HeldOn = targetType
        self.FirstImpactTick = GetGameTick()
        KickUp(self, targetType)
        self:BurstMotes()

        -- not destroying the shell is enough for it to fly on (as BlackOps Unleashed's XCannon01 does)
        if IsKilled(targetEntity) then
            if targetType == 'Shield' then
                self:BreakThrough(self:GetVelocity())
            end
            self:StartPassing()
            return
        end

        local vx, vy, vz, speed = self:Freeze()
        self:HoldIn(targetType, targetEntity)
        self.Trash:Add(ForkThread(self.HoldThread, self, vx, vy, vz, speed, 1))
    end,

    --- The weapon's damage over time gives the hits: `DoTPulses` hits of `Damage`, `DoTTime / (DoTPulses - 1)`
    --- seconds apart, as the engine would deal them. The shell deals them itself, so the engine's damage
    --- over time is turned off in the shell's own damage table
    ---@param self AIFSonanceShell02
    ReadHits = function(self)
        local data = self.DamageData
        local hits = data.DoTPulses or 1
        local time = data.DoTTime or 0
        if hits < 2 or time <= 0 then
            hits = 1
        end
        self.HitsLeft = hits
        self.HoldTicks = 0
        if hits > 1 then
            self.HoldTicks = MATH_IRound(10 * time / (hits - 1))
        end
        data.DoTTime = 0
    end,

    --- Remembers what the shell is held in for the next hit, and rides along with it if it moves
    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield
    HoldIn = function(self, targetType, targetEntity)
        self.HeldIn = targetEntity
        self.Host = MobileHost(targetType, targetEntity)
        self.Riders = {}
        self:Ride(self)
    end,

    --- Makes an entity keep its offset from the host. The offset is in world axes: it does not turn with it
    ---@param self AIFSonanceShell02
    ---@param entity Projectile
    Ride = function(self, entity)
        local host = self.Host
        if host then
            local hx, hy, hz = host:GetPositionXYZ()
            local x, y, z = entity:GetPositionXYZ()
            table.insert(self.Riders, { entity = entity, dx = x - hx, dy = y - hy, dz = z - hz })
        end
    end,

    --- Sets each rider's velocity to reach its place by the host's next tick. With no host (left, or
    --- dead), all riders stop
    ---@param self AIFSonanceShell02
    ---@param motes? table    # flying vortex motes: they get the host's velocity added to their own
    ---@return number vx      # of the host, per tick
    ---@return number vy
    ---@return number vz
    Follow = function(self, motes)
        local riders = self.Riders
        if not riders then
            return 0, 0, 0
        end
        local host = self.Host
        local vx, vy, vz = 0, 0, 0
        local hx, hy, hz
        if host and not IsKilled(host) and not host.Dead then
            vx, vy, vz = host:GetVelocity()
            hx, hy, hz = host:GetPositionXYZ()
        else
            self.Host = nil
            self.Riders = nil
        end
        for _, rider in riders do
            local entity = rider.entity
            if not IsDestroyed(entity) then
                if hx then
                    local x, y, z = entity:GetPositionXYZ()
                    entity:SetVelocity(10 * (hx + vx + rider.dx - x), 10 * (hy + vy + rider.dy - y), 10 * (hz + vz + rider.dz - z))
                else
                    entity:SetVelocity(0, 0, 0)
                end
            end
        end
        if motes then
            for _, mote in motes do
                if mote.entity and not IsDestroyed(mote.entity) and mote.vx then
                    mote.entity:SetVelocity(mote.vx + 10 * vx, mote.vy + 10 * vy, mote.vz + 10 * vz)
                end
            end
        end
        return vx, vy, vz
    end,

    --- Stops the shell where it is
    ---@param self AIFSonanceShell02
    ---@return number vx    # velocity it had, per tick
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

    --- Sprays drill sparks from the shell, back up its path
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity of the shell, straight down if it has none
    ---@param vy number
    ---@param vz number
    ---@param f number      # strength, see SprayDrillSparks
    ---@param along number
    ---@param across number
    SprayBack = function(self, vx, vy, vz, f, along, across)
        local speed = MathSqrt(vx * vx + vy * vy + vz * vz)
        if speed < 0.001 then
            vx, vy, vz, speed = 0, -1, 0, 1
        end
        local x, y, z = self:GetPositionXYZ()
        SprayDrillSparks(CreatePoint(self, x, y, z), self.Army, -vx / speed, -vy / speed, -vz / speed, f, along, across)
    end,

    --- A hit flings motes out around the path, see HitBurst
    ---@param self AIFSonanceShell02
    BurstMotes = function(self)
        local vx, vy, vz = self:GetVelocity()
        self:SprayBack(vx, vy, vz, HitBurst.Strength, HitBurst.Along, HitBurst.Across)
    end,

    --- The shield the shell hit collapsed: sparks are left where it broke through
    ---@param self AIFSonanceShell02
    ---@param vx number     # velocity of the shell
    ---@param vy number
    ---@param vz number
    BreakThrough = function(self, vx, vy, vz)
        self:SprayBack(vx, vy, vz, Drill.BreakBurst, Drill.Along, Drill.Across)
    end,

    --- Flies on, to lodge in what it hits next, or hit in the air if it hits nothing in time
    ---@param self AIFSonanceShell02
    StartPassing = function(self)
        self.Passing = true
        self.HeldIn = nil
        self.Trash:Add(ForkThread(self.PassTimeoutThread, self))
    end,

    --- StartPassing for a shell that is held
    ---@param self AIFSonanceShell02
    ---@param vx number     # per tick
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
        WaitTicks(self.HoldTicks - (GetGameTick() - self.FirstImpactTick))
        if self.Passing then
            self.Passing = nil
            self:SetBallisticAcceleration(0)
            self:SetVelocity(0, 0, 0)
            self:OnImpact('Air', nil)
        end
    end,

    --- Holds in what the passing shell hit, without damage, until the next hit is due
    ---@param self AIFSonanceShell02
    ---@param targetType string
    ---@param targetEntity? Unit|Prop|Shield
    Lodge = function(self, targetType, targetEntity)
        self.Passing = nil
        self.HeldOn = targetType
        local vx, vy, vz, speed = self:Freeze()
        self:HoldIn(targetType, targetEntity)
        local startTick = GetGameTick() - self.FirstImpactTick + 1
        self.Trash:Add(ForkThread(self.HoldThread, self, vx, vy, vz, speed, startTick))
    end,

    --- Holds the shell until the next hit: drills into a shield, see Drill, or else see VortexThread
    ---@param self AIFSonanceShell02
    ---@param vx number     # at the impact, per tick
    ---@param vy number
    ---@param vz number
    ---@param speed number
    ---@param startTick number  # hold tick to start at: later than 1 when the shell lodged
    HoldThread = function(self, vx, vy, vz, speed, startTick)
        if self.HeldOn ~= 'Shield' then
            self:VortexThread(vx, vy, vz, startTick)
            return
        end

        -- a: back up the path
        local ax, ay, az = -vx / speed, -vy / speed, -vz / speed
        local cx, cy, cz = self:GetPositionXYZ()
        local shield = self.HeldIn --[[@as Shield ]] -- HeldOn above confirms
        local army = self.Army
        local radius = self.DamageData.DamageRadius
        local holdTicks = self.HoldTicks
        local pulseCount = table.getn(Drill.PulseTicks)
        local carrier
        local pulse = 1
        while Drill.PulseTicks[pulse] and Drill.PulseTicks[pulse] < startTick do
            pulse = pulse + 1
        end

        local conePoint = CreatePoint(self, cx, cy, cz)
        self:Ride(conePoint)
        local Emit = self.Host and CreateEmitterOnEntity or CreateEmitterAtEntity
        for tick = startTick, holdTicks do
            self:Follow()
            cx, cy, cz = self:GetPositionXYZ()
            -- units can die, and shields collapse, a tick after the hit
            if tick == 2 and IsKilled(shield) then
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
                carrier = CreatePoint(self, cx + back * ax, cy + back * ay, cz + back * az)
                self:Ride(carrier)
                Emit(carrier, army, EffectTemplate.ASonanceWeaponDrillThrust02)
                    :SetEmitterCurveParam('XDIR_CURVE', ax, 0)
                    :SetEmitterCurveParam('YDIR_CURVE', ay, 0)
                    :SetEmitterCurveParam('ZDIR_CURVE', az, 0)
            end
            if tick == Drill.PulseTicks[pulse] then
                local f = (pulse - 1) / (pulseCount - 1)
                pulse = pulse + 1

                SprayDrillSparks(conePoint, army, ax, ay, az, f, Drill.Along, Drill.Across)

                if shield and not IsDestroyed(shield) and shield:IsUp() then
                    -- from the impact to the shield's centre, as for a real impact
                    local hx, hy, hz = shield:GetPositionXYZ()
                    ForkThread(shield.CreateImpactEffect, shield, Vector(hx - cx, hy - cy, hz - cz))
                end
            end
            WaitTicks(1)
        end

        -- stop riding
        self.Host = nil
        self:Follow()
        for _, effect in EffectTemplate.ASonanceWeaponRelease02 do
            CreateEmitterAtEntity(self, army, effect)
        end
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponFinalDistort02, radius / ExplosionRadius)
        if carrier then
            carrier:Destroy()
        end
        conePoint:Destroy()
        self:Release()
    end,

    --- See Vortex
    ---@param self AIFSonanceShell02
    ---@param vx number     # at the impact, per tick
    ---@param vy number
    ---@param vz number
    ---@param startTick number  # hold tick to start at: later than 1 when the shell lodged
    VortexThread = function(self, vx, vy, vz, startTick)
        local radius = self.DamageData.DamageRadius
        local holdTicks = self.HoldTicks
        local scale = radius / ExplosionRadius
        local army = self.Army

        -- the core: the shell's flight glow and sparkles, above the surface
        local px, py, pz = self:GetPositionXYZ()
        local surface = GetSurfaceHeight(px, pz)
        local cy = MathMax(py, surface + Vortex.CoreLift)
        local corePoint = CreatePoint(self, px, cy, pz)
        self:Ride(corePoint)
        local Emit = self.Host and CreateEmitterOnEntity or CreateEmitterAtEntity
        local core = {}
        for k, effect in EffectTemplate.ASonanceWeaponFXTrail02 do
            if k > 1 then
                table.insert(core, CreateEmitterOnEntity(corePoint, army, effect):ScaleEmitter(self.FxTrailScale))
            end
        end

        -- lodged
        if startTick > 1 then
            KickUp(self, self.HeldOn)
            CreateUprightEffects(self, EffectTemplate.ASonanceWeaponLodgeAir02, radius * Vortex.RippleRadius)
        end

        -- motes and dust puffs appear more often toward the end (square root), and all arrive by the next hit
        local first = MathMax(startTick, Vortex.FirstTick)
        local debrisStart = MathMax(first, holdTicks + 1 - Vortex.DebrisTicks)

        -- waves count down to the last, which arrives with the next hit
        local lastWave = holdTicks + 1 - Vortex.WaveTicks
        local wave = -1
        if self.HeldOn == 'Water' then
            while lastWave - MathFloor((wave + 1) * Vortex.WaveEvery) >= first do
                wave = wave + 1
            end
        end

        local puffs = {}
        if self.HeldOn == 'Terrain' then
            -- each turned by the golden angle from the last, to spread them evenly
            local turn = 2 * MathPi * Random()
            for p = 1, Vortex.DustPuffs do
                local life = MathMin(RandomTicksIn(Vortex.DustLife), holdTicks + 1 - first)
                local progress = MathSqrt((p - Random()) / Vortex.DustPuffs)
                puffs[p] = {
                    tick = first + MathFloor((holdTicks + 1 - life - first) * progress),
                    life = life,
                    progress = progress,
                    heading = turn + p * 2.39996 + Vortex.DustJitter * (Random() - 0.5),
                }
            end
        end

        local motes = {}
        for i = 1, Vortex.Count do
            local flight = MathMin(RandomTicksIn(Vortex.Flight), holdTicks + 1 - first)
            if flight >= Vortex.Segments then
                local last = holdTicks + 1 - flight
                local appear = first + MathFloor((last - first) * MathSqrt((i - Random()) / Vortex.Count))
                table.insert(motes, {
                    appear = appear,
                    flight = flight,
                    reach = radius * RandomIn(Vortex.Reach),
                    height = radius * RandomIn(Vortex.Height),
                    angle = 2 * MathPi * Random(),
                    turns = 2 * MathPi * RandomIn(Vortex.Turns),
                    size = RandomIn(Vortex.MoteSize),
                    segment = 0, -- the next straight stretch of the spiral, see SpiralPoint
                    segmentTick = appear,
                })
            end
        end

        for tick = startTick, holdTicks do
            -- units can die a tick after the hit
            if tick == 2 and IsKilled(self.HeldIn) then
                for _, mote in motes do
                    if mote.entity then
                        mote.entity:Destroy()
                    end
                end
                corePoint:Destroy()
                self:PassOn(vx, vy, vz)
                return
            end
            local hvx, hvy, hvz = self:Follow(motes)
            px, cy, pz = corePoint:GetPositionXYZ()
            local q = tick / holdTicks
            local swell = 1 + (Vortex.CoreSwell - 1) * q * q
            for _, effect in core do
                effect:ScaleEmitter(self.FxTrailScale * swell)
            end

            if tick == first then
                Emit(corePoint, army, EffectTemplate.ASonanceWeaponVortexDistort02)
                    :ScaleEmitter(radius * Vortex.DistortSize)
                    :SetEmitterCurveParam('LIFETIME_CURVE', holdTicks + 1 - first, 0)
            end
            if tick == debrisStart then
                Emit(corePoint, army, EffectTemplate.ASonanceWeaponVortexDebris02)
                    :ScaleEmitter(radius * Vortex.DebrisSize)
                    :SetEmitterCurveParam('LIFETIME_CURVE', holdTicks + 1 - debrisStart, 0)
            end
            while wave >= 0 and tick == lastWave - MathFloor(wave * Vortex.WaveEvery) do
                CreateEmitterAtEntity(corePoint, army, EffectTemplate.ASonanceWeaponVortexWave02)
                    :ScaleEmitter(radius * Vortex.WaveSize)
                wave = wave - 1
            end

            for _, puff in puffs do
                if puff.tick == tick then
                    -- starts sideways (s) and is pulled in by a constant acceleration (a) that reaches
                    -- the core at the end of its life: p = s t + a t^2 / 2, per tick
                    local life, heading = puff.life, puff.heading
                    local reach = radius * RandomIn(Vortex.DustReach)
                    local dx, dz = reach * MathCos(heading), reach * MathSin(heading)
                    local ground = GetSurfaceHeight(px + dx, pz + dz) + Vortex.DustLift
                    local dy = cy - ground
                    local around = Vortex.DustCurl * reach / life
                    local sx, sz = -around * MathSin(heading), around * MathCos(heading)
                    local ax = 2 * (-dx - sx * life) / (life * life)
                    local ay = 2 * dy / (life * life)
                    local az = 2 * (-dz - sz * life) / (life * life)
                    CreateEmitterAtEntity(CreatePoint(self, px + dx, ground, pz + dz), army, EffectTemplate.ASonanceWeaponVortexDust02)
                        :SetEmitterCurveParam('XDIR_CURVE', sx / around, 0)
                        :SetEmitterCurveParam('ZDIR_CURVE', sz / around, 0)
                        :SetEmitterCurveParam('VELOCITY_CURVE', around, 0)
                        :SetEmitterCurveParam('X_ACCEL_CURVE', ax, 0)
                        :SetEmitterCurveParam('Y_ACCEL_CURVE', ay, 0)
                        :SetEmitterCurveParam('Z_ACCEL_CURVE', az, 0)
                        :SetEmitterCurveParam('LIFETIME_CURVE', life, 0)
                        :SetEmitterCurveParam('EMITRATE_CURVE', Lerp(Vortex.DustRate, puff.progress), 0)
                end
            end

            for _, mote in motes do
                local age = tick - mote.appear
                if age == 0 then
                    local x, y, z = SpiralPoint(mote, 0)
                    local entity = self:CreateProjectile(Vortex.MoteBlueprint, 0, 0, 0, nil, nil, nil)
                    Warp(entity, Vector(px + x, cy + y, pz + z))
                    -- fully faded: the whole part of the draw scale is the fade, in tenths
                    entity:SetDrawScale(10 + mote.size)
                    self.Trash:Add(entity)
                    mote.entity = entity
                end
                local entity = mote.entity
                if entity and not IsDestroyed(entity) then
                    if age >= mote.flight then
                        entity:Destroy()
                    else
                        if age > 0 and age <= Vortex.FadeTicks then
                            entity:SetDrawScale(MathFloor(10 * (1 - age / Vortex.FadeTicks) + 0.5) + mote.size)
                        end
                        if tick == mote.segmentTick then
                            local x0, y0, z0, t0 = SpiralPoint(mote, mote.segment)
                            local x1, y1, z1, t1 = SpiralPoint(mote, mote.segment + 1)
                            local time = 0.1 * (t1 - t0)
                            mote.vx, mote.vy, mote.vz = (x1 - x0) / time, (y1 - y0) / time, (z1 - z0) / time
                            entity:SetVelocity(mote.vx + 10 * hvx, mote.vy + 10 * hvy, mote.vz + 10 * hvz)
                            mote.segment = mote.segment + 1
                            mote.segmentTick = t1
                        end
                    end
                end
            end
            WaitTicks(1)
        end

        -- stop riding
        self.Host = nil
        self:Follow()
        for _, mote in motes do
            if mote.entity and not IsDestroyed(mote.entity) then
                mote.entity:Destroy()
            end
        end
        corePoint:Destroy()
        CreateUprightEffects(self, EffectTemplate.ASonanceWeaponVortexFinal02, scale)
        self:Release()
    end,

    --- The next hit: on what the shell is held in, or in the air if that is gone
    ---@param self AIFSonanceShell02
    Release = function(self)
        local targetType, targetEntity = self.HeldOn, self.HeldIn
        ---@cast targetType -nil # only called on next hit
        if IsKilled(targetEntity) then
            targetType, targetEntity = 'Air', nil
        end
        self:OnImpact(targetType, targetEntity)
    end,
}
TypeClass = AIFSonanceShell02
