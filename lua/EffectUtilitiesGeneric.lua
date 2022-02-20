
-- cache for performance
local ReclaimObjectAOE = import('/lua/EffectTemplates.lua').ReclaimObjectAOE
local ReclaimBeams = import('/lua/EffectTemplates.lua').ReclaimBeams
local ReclaimObjectEnd = import('/lua/EffectTemplates.lua').ReclaimObjectEnd

-- upvalue for performance
local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticleIntel = CreateLightParticleIntel

--- Played when reclaiming starts.
-- @param reclaimer Unit that is reclaiming
-- @param reclaimed Unit that is reclaimed 
-- @param buildEffectBones Bones of the reclaimer to create beams from towards the reclaimed
-- @param effectsBag Trashbag that stores the effects
function PlayReclaimEffects(reclaimer, reclaimed, buildEffectBones, effectsBag)

    -- cache army
    local army = reclaimer.Army

    -- create beams
    for _, bone in buildEffectBones do
        for _, emitter in ReclaimBeams do
            effectsBag:Add(AttachBeamEntityToEntity(reclaimer, bone, reclaimed, -1, army, emitter))
        end
    end

    -- create particle effects
    for _, v in ReclaimObjectAOE do
        effectsBag:Add(CreateEmitterOnEntity(reclaimed, army, v))
    end
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