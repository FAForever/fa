
-- cache for performance
local ReclaimObjectAOE = import('/lua/EffectTemplates.lua').ReclaimObjectAOE
local ReclaimBeams = import('/lua/EffectTemplates.lua').ReclaimBeams
local ReclaimObjectEnd = import('/lua/EffectTemplates.lua').ReclaimObjectEnd

-- upvalue for performance
local Random = Random 

local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy

local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticleIntel = CreateLightParticleIntel

local IEffectSetEmitterCurveParam = _G.moho.IEffect.SetEmitterCurveParam

--- Played when reclaiming starts.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed 
-- @param buildEffectBones Bones of the reclaimer to create beams from towards the reclaimed
-- @param effectsBag Trashbag that stores the effects
function PlayReclaimEffects(reclaimer, reclaimed, buildEffectBones, effectsBag)

    -- cache army
    local army = reclaimer.Army

    -- projectile to introduce a small animation
    local reclaimEndpoint = reclaimer.ReclaimEndpoint 
    if not reclaimEndpoint then 
        reclaimEndpoint = EntityCreateProjectile(reclaimer, '/effects/entities/ReclaimEndpoint/ReclaimEndpoint_proj.bp', 0, 0, 0)
        reclaimer.ReclaimEndpoint = reclaimEndpoint
        TrashAdd(reclaimer.Trash, reclaimEndpoint)
    end

    -- reset the state of the projectile
    ProjectileSetVelocity(beamEndBuilder, 0)

    -- move projectile to the reclaimed
    vc[1] = ox 
    vc[2] = oy 
    vc[3] = oz
    Warp(reclaimed, vc)

    -- create beams
    for _, bone in buildEffectBones do
        for _, emitter in ReclaimBeams do
            TrashAdd(effectsBag, AttachBeamEntityToEntity(reclaimer, bone, reclaimEndpoint, -1, army, emitter))
        end
    end

    -- create particle effects
    for _, v in ReclaimObjectAOE do
        TrashAdd(effectsBag, CreateEmitterOnEntity(reclaimEndpoint, army, v))
    end

    -- create movement animation
    WaitSeconds(1.0)
    LOG("Heh!")

end

--- Played when reclaiming has been completed.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed (and no longer exists after this effect)
function PlayReclaimEndEffects(reclaimer, reclaimed)

    -- cache army of reclaiming unit
    army = reclaimer.Army or -1

    -- create particle effects
    for _, v in ReclaimObjectEnd do
        CreateEmitterAtEntity(reclaimed, army, v)
    end

    -- create light effect
    CreateLightParticleIntel(reclaimed, -1, army, 4, 6, 'glow_02', 'ramp_flare_02')
end

--- Applies the wind direction to an emitter.
-- @param emitter Emitter to apply the wind direction to
function ApplyWindDirection(emitter, factor)
    local r = Random()
    IEffectSetEmitterCurveParam(emitter, "XDIR_CURVE", factor * 0.01, factor * (0.01 + 0.01 * r))
    IEffectSetEmitterCurveParam(emitter, "YDIR_CURVE", factor * 0.0025, factor * (0.005 + 0.01 * Random()))
    IEffectSetEmitterCurveParam(emitter, "ZDIR_CURVE", factor * 0.01, factor * (0.01 + 0.01 * r))
end