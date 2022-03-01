
local util = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

-- upvalue for performance
local Random = Random
local VectorCached = Vector(0, 0, 0)
local yield = coroutine.yield

local AttachBeamEntityToEntity = AttachBeamEntityToEntity
local CreateEmitterOnEntity = CreateEmitterOnEntity

function CreateDefaultBuildBeams(
    builder, unitBeingBuilt,    -- units
    BuildEffectBones,           -- table of bone names
    BuildEffectsBag             -- trashbag
)

    local vc = VectorCached
    local ox, oy, oz = unitBeingBuilt:GetPositionXYZ()

    -- allocation of entity
    local BeamEndEntity = Entity()
    BuildEffectsBag:Add(BeamEndEntity)

    vc[1] = ox 
    vc[2] = oy 
    vc[3] = oz
    Warp(BeamEndEntity, vc)

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            local beamEffect = AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, builder.Army, '/effects/emitters/build_beam_01_emit.bp')
            BuildEffectsBag:Add(beamEffect)
        end
    end

    CreateEmitterOnEntity(BeamEndEntity, builder.Army, '/effects/emitters/sparks_08_emit.bp')

    -- cache orientation

    local waitTime = Random(3, 15)
    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1)

        -- use orientation

        vc[1] = ox + x
        vc[2] = oy + y
        vc[3] = oz + z 

        Warp(BeamEndEntity, vc)
        yield(waitTime)
    end
end