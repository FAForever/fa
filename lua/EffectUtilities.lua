--****************************************************************************
--**
--**  File     :  /lua/EffectUtilities.lua
--**  Author(s):  Gordon Duclos
--**
--**  Summary  :  Effect Utility functions for scripts.
--**
--**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local util = import('utilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat


function CreateEffects( obj, army, EffectTable )
    local emitters = {}
    for k, v in EffectTable do
        table.insert(emitters,CreateEmitterAtEntity( obj, army, v ))
    end
    return emitters
end

function CreateEffectsWithOffset( obj, army, EffectTable, x, y, z )
    local emitters = {}
    for k, v in EffectTable  do
        table.insert(emitters,CreateEmitterAtEntity( obj, army, v ):OffsetEmitter(x, y, z))
    end
    return emitters
end

function CreateEffectsWithRandomOffset( obj, army, EffectTable, xRange, yRange, zRange )
    local emitters = {}
    for k, v in EffectTable do
        table.insert(emitters,CreateEmitterOnEntity( obj, army, v ):OffsetEmitter(util.GetRandomOffset(xRange, yRange, zRange, 1)))
    end
    return emitters
end

function CreateBoneEffects( obj, bone, army, EffectTable )
    local emitters = {}
    for k, v in EffectTable do
        table.insert(emitters,CreateEmitterAtBone( obj, bone, army, v ))
    end
    return emitters
end

function CreateBoneEffectsOffset( obj, bone, army, EffectTable, x, y, z )
    local emitters = {}
    for k, v in EffectTable do
        table.insert(emitters,CreateEmitterAtBone( obj, bone, army, v ):OffsetEmitter(x, y, z))
    end
    return emitters
end

function CreateBoneTableEffects( obj, BoneTable, army, EffectTable )
    for kBone, vBone in BoneTable do
        for kEffect, vEffect in EffectTable do
            table.insert(emitters,CreateEmitterAtBone( obj, vBone, army, vEffect ))
        end
    end
end

function CreateBoneTableRangedScaleEffects( obj, BoneTable, EffectTable, army, ScaleMin, ScaleMax )
    for kBone, vBone in BoneTable do
        for kEffect, vEffect in EffectTable do
            CreateEmitterAtBone( obj, vBone, army, vEffect ):ScaleEmitter(util.GetRandomFloat(ScaleMin, ScaleMax))
        end
    end
end

function CreateRandomEffects( obj, army, EffectTable, NumEffects )
    local NumTableEntries = table.getn(EffectTable)
    local emitters = {}
    for i = 1, NumEffects do
        table.insert(emitters, CreateEmitterOnEntity( obj, army, EffectTable[util.GetRandomInt(1,NumTableEntries)] ))
    end
    return emitters
end

function ScaleEmittersParam( Emitters, param, minRange, maxRange )
    for k, v in Emitters do
        v:SetEmitterParam( param, util.GetRandomFloat( minRange, maxRange ) )
    end
end

function CreateBuildCubeThread( unitBeingBuilt, builder, OnBeingBuiltEffectsBag )
    local bp = unitBeingBuilt:GetBlueprint()
    local mul = 1.15
    local xPos, yPos, zPos = unpack(unitBeingBuilt:GetPosition())
    local proj, slice = nil
    yPos = yPos + (bp.Physics.MeshExtentsOffsetY or 0)

    local x = bp.Physics.MeshExtentsX or (bp.Footprint.SizeX * mul)
    local z = bp.Physics.MeshExtentsZ or (bp.Footprint.SizeZ * mul)
    local y = bp.Physics.MeshExtentsY or (0.5 + (x + z) * 0.1)

    local SlicePeriod = 1.2

    -- Create a quick glow effect at location where unit is goig to be built
    proj = unitBeingBuilt:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp',0,0,0, nil, nil, nil )
    proj:SetScale(x * 1.05, y * 0.2, z * 1.05)
    WaitSeconds(0.1)
    if unitBeingBuilt.Dead then
        return
    end
    local BuildBaseEffect = unitBeingBuilt:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect03_proj.bp', 0, 0, 0, nil, nil, nil )
    OnBeingBuiltEffectsBag:Add(BuildBaseEffect)
    unitBeingBuilt.Trash:Add(BuildBaseEffect)
    Warp( BuildBaseEffect, Vector(xPos, yPos-y, zPos))
    BuildBaseEffect:SetScale(x, y, z)
    BuildBaseEffect:SetVelocity(0, 1.4 * y, 0)

    WaitSeconds( 0.8 )
    if unitBeingBuilt.Dead then
        return
    end

    if not BuildBaseEffect:BeenDestroyed() then
        BuildBaseEffect:SetVelocity(0)
    end

    unitBeingBuilt:ShowBone(0, true)
    unitBeingBuilt:HideLandBones()
    unitBeingBuilt.BeingBuiltShowBoneTriggered = true

    local lComplete = unitBeingBuilt:GetFractionComplete()
    WaitSeconds(0.3)
    if unitBeingBuilt.Dead then
        return
    end
    local cComplete = unitBeingBuilt:GetFractionComplete()


    -- Create glow slice cuts and resize base cube
    while not unitBeingBuilt.Dead and  cComplete < 1.0 do
        if lComplete < cComplete and not BuildBaseEffect:BeenDestroyed() then
            proj = BuildBaseEffect:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp',0,y * (1-cComplete),0, nil, nil, nil )
            OnBeingBuiltEffectsBag:Add(proj)
            slice = math.abs(lComplete - cComplete)
            proj:SetScale(x, y * slice, z)
            BuildBaseEffect:SetScale(x, y * (1-cComplete), z)
        end
        WaitSeconds(SlicePeriod)
        if unitBeingBuilt.Dead then
            break
        end
        lComplete = cComplete
        cComplete = unitBeingBuilt:GetFractionComplete()
    end
end

function CreateUEFUnitBeingBuiltEffects( builder, unitBeingBuilt, BuildEffectsBag )
    local army = builder:GetArmy()
    local buildAttachBone = builder:GetBlueprint().Display.BuildAttachBone
    BuildEffectsBag:Add( CreateAttachedEmitter( builder, buildAttachBone, army, '/effects/emitters/uef_mobile_unit_build_01_emit.bp' ) )
end

function CreateUEFBuildSliceBeams( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
    local army = builder:GetArmy()
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local buildbp = unitBeingBuilt:GetBlueprint()
    local x, y, z = unpack(unitBeingBuilt:GetPosition())
    y = y + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamEndEntity = unitBeingBuilt:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp',0,0,0,nil,nil,nil)
    BuildEffectsBag:Add( BeamEndEntity )

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            BuildEffectsBag:Add(AttachBeamEntityToEntity( builder, BuildBone, BeamEndEntity, -1, army, BeamBuildEmtBp ) )
            BuildEffectsBag:Add( CreateAttachedEmitter( builder, BuildBone, army, '/effects/emitters/flashing_blue_glow_01_emit.bp' ) )
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local mul = 1.15
    local ox = buildbp.Physics.MeshExtentsX or (buildbp.Footprint.SizeX * mul)
    local oz = buildbp.Physics.MeshExtentsZ or (buildbp.Footprint.SizeZ * mul)
    local oy = (buildbp.Physics.MeshExtentsY or (0.5 + (ox + oz) * 0.1))

    ox = ox * 0.5
    oz = oz * 0.5

    -- Determine the the 2 closest edges of the build cube and use those for the location of our laser
    local VectorExtentsList = { Vector(x + ox, y + oy, z + oz), Vector(x + ox, y + oy, z - oz), Vector(x - ox, y + oy, z + oz), Vector(x - ox, y + oy, z - oz) }
    local endVec1 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList )

    for k,v in VectorExtentsList do
        if(v == endVec1) then
            table.remove(VectorExtentsList, k)
        end
    end

    local endVec2 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList )
    local cx1, cy1, cz1 = unpack(endVec1)
    local cx2, cy2, cz2 = unpack(endVec2)

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velX = 2 * (endVec2.x - endVec1.x)
    local velY = 2 * (endVec2.y - endVec1.y)
    local velZ = 2 * (endVec2.z - endVec1.z)

    if unitBeingBuilt:GetFractionComplete() == 0 then
        Warp( BeamEndEntity, Vector( (cx1 + cx2) * 0.5, ((cy1 + cy2) * 0.5) - oy, (cz1 + cz2) * 0.5 ) )
        WaitSeconds( 0.8 )
    end

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        if flipDirection then
            Warp( BeamEndEntity, Vector( cx1, (cy1 - (oy * unitBeingBuilt:GetFractionComplete())), cz1 ) )
            BeamEndEntity:SetVelocity( velX, velY, velZ )
            flipDirection = false
        else
            Warp( BeamEndEntity, Vector( cx2, (cy2 - (oy * unitBeingBuilt:GetFractionComplete())), cz2 ) )
            BeamEndEntity:SetVelocity( -velX, -velY, -velZ )
            flipDirection = true
        end
        WaitSeconds( 0.6 )
    end
end

function CreateUEFCommanderBuildSliceBeams( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
    local army = builder:GetArmy()
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local buildbp = unitBeingBuilt:GetBlueprint()
    local x, y, z = unpack(unitBeingBuilt:GetPosition())
    y = y + (buildbp.Physics.MeshExtentsOffsetY or 0)

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamEndEntity = unitBeingBuilt:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp',0,0,0,nil,nil,nil)
    local BeamEndEntity2 = unitBeingBuilt:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp',0,0,0,nil,nil,nil)
    BuildEffectsBag:Add( BeamEndEntity )
    BuildEffectsBag:Add( BeamEndEntity2 )

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            BuildEffectsBag:Add( AttachBeamEntityToEntity( builder, BuildBone, BeamEndEntity, -1, army, BeamBuildEmtBp ) )
            BuildEffectsBag:Add( AttachBeamEntityToEntity( builder, BuildBone, BeamEndEntity2, -1, army, BeamBuildEmtBp ) )
            BuildEffectsBag:Add( CreateAttachedEmitter( builder, BuildBone, army, '/effects/emitters/flashing_blue_glow_01_emit.bp' ) )
        end
    end

    -- Determine beam positioning on build cube, this should match sizes of CreateBuildCubeThread
    local mul = 1.15
    local ox = buildbp.Physics.MeshExtentsX or (buildbp.Footprint.SizeX * mul)
    local oz = buildbp.Physics.MeshExtentsZ or (buildbp.Footprint.SizeZ * mul)
    local oy = (buildbp.Physics.MeshExtentsY or (0.5 + (ox + oz) * 0.1))

    ox = ox * 0.5
    oz = oz * 0.5

    -- Determine the the 2 closest edges of the build cube and use those for the location of our laser
    local VectorExtentsList = { Vector(x + ox, y + oy, z + oz), Vector(x + ox, y + oy, z - oz), Vector(x - ox, y + oy, z + oz), Vector(x - ox, y + oy, z - oz) }
    local endVec1 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList )

    for k,v in VectorExtentsList do
        if(v == endVec1) then
            table.remove(VectorExtentsList, k)
        end
    end

    local endVec2 = util.GetClosestVector(builder:GetPosition(), VectorExtentsList )
    local cx1, cy1, cz1 = unpack(endVec1)
    local cx2, cy2, cz2 = unpack(endVec2)

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velX = 2 * (endVec2.x - endVec1.x)
    local velY = 2 * (endVec2.y - endVec1.y)
    local velZ = 2 * (endVec2.z - endVec1.z)

    if unitBeingBuilt:GetFractionComplete() == 0 then
        Warp( BeamEndEntity, Vector( cx1, cy1 - oy, cz1 ) )
        Warp( BeamEndEntity2, Vector( cx2, cy2 - oy, cz2 ) )
        WaitSeconds( 0.8 )
    end

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        if flipDirection then
            Warp( BeamEndEntity, Vector( cx1, (cy1 - (oy * unitBeingBuilt:GetFractionComplete())), cz1 ) )
            BeamEndEntity:SetVelocity( velX, velY, velZ )
            Warp( BeamEndEntity2, Vector( cx2, (cy2 - (oy * unitBeingBuilt:GetFractionComplete())), cz2 ) )
            BeamEndEntity2:SetVelocity( -velX, -velY, -velZ )
            flipDirection = false
        else
            Warp( BeamEndEntity, Vector( cx2, (cy2 - (oy * unitBeingBuilt:GetFractionComplete())), cz2 ) )
            BeamEndEntity:SetVelocity( -velX, -velY, -velZ )
            Warp( BeamEndEntity2, Vector( cx1, (cy1 - (oy * unitBeingBuilt:GetFractionComplete())), cz1 ) )
            BeamEndEntity2:SetVelocity( velX, velY, velZ )
            flipDirection = true
        end
        WaitSeconds( 0.6 )
    end
end

function CreateDefaultBuildBeams( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
    local BeamBuildEmtBp = '/effects/emitters/build_beam_01_emit.bp'
    local ox, oy, oz = unpack(unitBeingBuilt:GetPosition())
    local BeamEndEntity = Entity()
    local army = builder:GetArmy()
    BuildEffectsBag:Add( BeamEndEntity )
    Warp( BeamEndEntity, Vector(ox, oy, oz))

    local BuildBeams = {}

    -- Create build beams
    if BuildEffectBones ~= nil then
        local beamEffect = nil
        for i, BuildBone in BuildEffectBones do
            local beamEffect = AttachBeamEntityToEntity(builder, BuildBone, BeamEndEntity, -1, army, BeamBuildEmtBp )
            table.insert( BuildBeams, beamEffect )
            BuildEffectsBag:Add(beamEffect)
        end
    end

    CreateEmitterOnEntity( BeamEndEntity, builder:GetArmy(),'/effects/emitters/sparks_08_emit.bp')
    local waitTime = util.GetRandomFloat( 0.3, 1.5 )

    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1 )
        Warp( BeamEndEntity, Vector(ox + x, oy + y, oz + z))
        WaitSeconds(waitTime)
    end
end

function CreateAeonBuildBaseThread( unitBeingBuilt, builder, EffectsBag )
    local bp = unitBeingBuilt:GetBlueprint()
    local x, y, z = unpack(unitBeingBuilt:GetPosition())
    local mul = 0.5
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil
    WaitSeconds(0.1)

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = unitBeingBuilt:CreateProjectile('/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil )
    BuildBaseEffect:SetScale(sx, sy * 1.5, sz)
    Warp( BuildBaseEffect, Vector(x,y,z))
    BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    unitBeingBuilt.Trash:Add(BuildBaseEffect)
    EffectsBag:Add(BuildBaseEffect)

    CreateEmitterOnEntity(BuildBaseEffect, builder:GetArmy(),'/effects/emitters/aeon_being_built_ambient_01_emit.bp')
    :SetEmitterCurveParam('X_POSITION_CURVE',0,sx * 1.5)
    :SetEmitterCurveParam('Z_POSITION_CURVE',0,sz * 1.5)

    CreateEmitterOnEntity(BuildBaseEffect, builder:GetArmy(),'/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    :ScaleEmitter( (sx + sz) * 0.3 )

    local slider = CreateSlider( unitBeingBuilt, 0 )
    slider:SetWorldUnits(true)
    slider:SetGoal(0, -sy, 0)
    slider:SetSpeed(-1)

    local fraction = unitBeingBuilt:GetFractionComplete()
    while not unitBeingBuilt.Dead and fraction < 1 do
        scale = 1.2 - math.pow(fraction, 4)
        BuildBaseEffect:SetScale(sx * scale, 1.5*sy*scale, sz * scale)
        slider:SetGoal(0, (fraction*sy - sy), 0)
        WaitSeconds(0.1)
        fraction = unitBeingBuilt:GetFractionComplete()
    end

    slider:Destroy()
    BuildBaseEffect:Destroy()
end

function CreateCybranBuildBeams( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
    WaitSeconds(0.2)
    local army = builder:GetArmy()
    local BeamBuildEmtBp = '/effects/emitters/build_beam_02_emit.bp'
    local BeamEndEntities = {}
    local ox, oy, oz = unpack(unitBeingBuilt:GetPosition())

    if BuildEffectBones then
        for i, BuildBone in BuildEffectBones do
            local beamEnd = Entity()
            builder.Trash:Add(beamEnd)
            table.insert( BeamEndEntities, beamEnd )
            BuildEffectsBag:Add( beamEnd )
            Warp( beamEnd, Vector(ox, oy, oz))
            CreateEmitterOnEntity( beamEnd, army, EffectTemplate.CybranBuildSparks01 )
            CreateEmitterOnEntity( beamEnd, army, EffectTemplate.CybranBuildFlash01 )
            BuildEffectsBag:Add(AttachBeamEntityToEntity(builder, BuildBone, beamEnd, -1, army, BeamBuildEmtBp))
        end
    end

    while not builder:BeenDestroyed() and not unitBeingBuilt:BeenDestroyed() do
        for k, v in BeamEndEntities do
            local x, y, z = builder.GetRandomOffset(unitBeingBuilt, 1 )
            if v and not v:BeenDestroyed() then
                Warp( v, Vector(ox + x, oy + y, oz + z))
            end
        end
        WaitSeconds(0.2)
    end
end

function SpawnBuildBots( builder, unitBeingBuilt, BuildEffectsBag)
    -- Buildbots are scaled: ~ 1 pr 15 units of BP
    -- clamped to a max of 10 to avoid insane FPS drop
    -- with mods that modify BP
    local numBots = math.min(math.ceil((10+builder:GetBuildRate()) / 15),
                             10)

    if not builder.buildBots then
        builder.buildBots = {}
    end
	local builderArmy = builder:GetArmy()
    local unitBeingBuiltArmy = unitBeingBuilt:GetArmy()

    --if is new, won't spawn build bots if they might accidentally capture the unit
	if builderArmy == unitBeingBuiltArmy or IsHumanUnit(unitBeingBuilt) then
        for k, b in builder.buildBots do
            if b:BeenDestroyed() then
                builder.buildBots[k] = nil
            end
        end

        local numUnits = numBots - table.getsize(builder.buildBots)
        if numUnits > 0 then
            local x, y, z = unpack(builder:GetPosition())
            local qx, qy, qz, qw = unpack(builder:GetOrientation())
            local angleInitial = 180
            local VecMul = 0.5
            local xVec = 0
            local yVec = builder:GetBlueprint().SizeY * 0.5
            local zVec = 0

            local angle = (2*math.pi) / numUnits

            -- Launch projectiles at semi-random angles away from the sphere, with enough
            -- initial velocity to escape sphere core
            for i = 0, (numUnits - 1) do
                xVec = math.sin(angleInitial + (i*angle)) * VecMul
                zVec = math.cos(angleInitial + (i*angle)) * VecMul
                local bot = CreateUnit('ura0001', builderArmy, x + xVec, y + yVec, z + zVec, qx, qy, qz, qw, 'Air' )

                -- Make build bots unkillable
                bot:SetCanTakeDamage(false)
                bot:SetCanBeKilled(false)
                bot.spawnedBy = builder

                table.insert(builder.buildBots, bot)
            end
        end

        for _, bot in builder.buildBots do
            ChangeState(bot, bot.BuildState)
        end

        return builder.buildBots
	end
end

function CreateCybranEngineerBuildEffects( builder, BuildBones, BuildBots, BuildEffectsBag )
    -- Create build constant build effect for each build effect bone defined
    if BuildBones and BuildBots then
        local army = builder:GetArmy()
        for kBone, vBone in BuildBones do
            for kEffect, vEffect in  EffectTemplate.CybranBuildUnitBlink01 do
                BuildEffectsBag:Add( CreateAttachedEmitter(builder,vBone,army,vEffect))
            end
            WaitSeconds( util.GetRandomFloat( 0.2, 1 ))
        end

        if builder:BeenDestroyed() then
            return
        end

        local i = 1
        for kBot, vBot in BuildBots do
            if not vBot or vBot:BeenDestroyed() then
                continue
            end

            BuildEffectsBag:Add(AttachBeamEntityToEntity(builder, BuildBones[i], vBot, -1, army, '/effects/emitters/build_beam_03_emit.bp'))
            i = i + 1
        end
    end
end

function CreateCybranFactoryBuildEffects( builder, unitBeingBuilt, BuildBones, BuildEffectsBag )
    local BuildEffects = {
        '/effects/emitters/sparks_03_emit.bp',
        '/effects/emitters/flashes_01_emit.bp',
    }
    local UnitBuildEffects = {
        '/effects/emitters/build_cybran_spark_flash_04_emit.bp',
        '/effects/emitters/build_sparks_blue_02_emit.bp',
    }
    local army = builder:GetArmy()

    CreateCybranBuildBeams(builder, unitBeingBuilt, BuildBones.BuildEffectBones, BuildEffectsBag)

    for kB,vB in BuildBones.BuildEffectBones do
        for kE, vE in BuildEffects do
            BuildEffectsBag:Add( CreateAttachedEmitter(builder,vB,army,vE) )
        end
    end

    BuildEffectsBag:Add( CreateAttachedEmitter( builder, BuildBones.BuildAttachBone, army, '/effects/emitters/cybran_factory_build_01_emit.bp' ) )

    --Add sparks to the collision box of the unit being built
    local sx, sy, sz = 0
    while not unitBeingBuilt.Dead and unitBeingBuilt:GetFractionComplete() < 1 do
        sx, sy, sz = unitBeingBuilt:GetRandomOffset(1)
        for kE, vE in UnitBuildEffects do
            CreateEmitterOnEntity(unitBeingBuilt,army,vE):OffsetEmitter(sx,sy,sz)
        end
        WaitSeconds(util.GetRandomFloat( 0.1, 0.6 ))
    end
end

function CreateAeonConstructionUnitBuildingEffects( builder, unitBeingBuilt, BuildEffectsBag )
	local army = builder:GetArmy()
    BuildEffectsBag:Add( CreateEmitterOnEntity(builder, army,'/effects/emitters/aeon_build_01_emit.bp') )

    local beamEnd = Entity()
    BuildEffectsBag:Add(beamEnd)
    Warp( beamEnd, unitBeingBuilt:GetPosition() )

    for k, v in EffectTemplate.AeonBuildBeams01 do
		local beamEffect = AttachBeamEntityToEntity(builder, 0, beamEnd, -1, army, v )
		beamEffect:SetEmitterParam( 'POSITION_Z', 0.45 )
		BuildEffectsBag:Add(beamEffect)
	end
end

function CreateAeonCommanderBuildingEffects( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
	local army = builder:GetArmy()
    local beamEnd = Entity()
    BuildEffectsBag:Add(beamEnd)
    Warp( beamEnd, unitBeingBuilt:GetPosition() )

    for kBone, vBone in BuildEffectBones do
		BuildEffectsBag:Add( CreateAttachedEmitter( builder, vBone, army, '/effects/emitters/aeon_build_02_emit.bp' ) )

    	for k, v in EffectTemplate.AeonBuildBeams01 do
			local beamEffect = AttachBeamEntityToEntity(builder, vBone, beamEnd, -1, army, v )
			BuildEffectsBag:Add(beamEffect)
		end
	end
end

function CreateAeonFactoryBuildingEffects( builder, unitBeingBuilt, BuildEffectBones, BuildBone, EffectsBag )
    local bp = unitBeingBuilt:GetBlueprint()
    local army = builder:GetArmy()
    local x, y, z = unpack(builder:GetPosition(BuildBone))
    local mul = 1
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = unitBeingBuilt:CreateProjectile('/effects/entities/AeonBuildEffect/AeonBuildEffect01_proj.bp', 0,0,1, nil, nil, nil )
    BuildBaseEffect:SetScale(sx, 1.5*sy, sz)
    ------BuildBaseEffect:SetOrientation(unitBeingBuilt:GetOrientation(), true)
    Warp( BuildBaseEffect, Vector(x, y-0.05, z))
    unitBeingBuilt.Trash:Add(BuildBaseEffect)
    EffectsBag:Add(BuildBaseEffect)

    CreateEmitterOnEntity(BuildBaseEffect, builder:GetArmy(),'/effects/emitters/aeon_being_built_ambient_02_emit.bp')
    :SetEmitterCurveParam('X_POSITION_CURVE',0,sx * 1.5)
    :SetEmitterCurveParam('Z_POSITION_CURVE',0,sz * 1.5)

    CreateEmitterOnEntity(BuildBaseEffect, builder:GetArmy(),'/effects/emitters/aeon_being_built_ambient_03_emit.bp')
    :ScaleEmitter( (sx + sz) * 0.3 )

    for kBone, vBone in BuildEffectBones do
		EffectsBag:Add( CreateAttachedEmitter( builder, vBone, army, '/effects/emitters/aeon_build_03_emit.bp' ) )
		for kBeam, vBeam in EffectTemplate.AeonBuildBeams02 do
			local beamEffect = AttachBeamEntityToEntity(builder, vBone, builder, BuildBone, army, vBeam )
			EffectsBag:Add(beamEffect)
		end
	end

    local slider = CreateSlider(unitBeingBuilt, 0)
    unitBeingBuilt.Trash:Add(slider)
    EffectsBag:Add(slider)
    slider:SetWorldUnits(true)
    slider:SetSpeed(-1)
    slider:SetGoal(0, -sy*0.5, 0)

    local fraction = unitBeingBuilt:GetFractionComplete()
    local scale
    while not unitBeingBuilt.Dead and fraction < 1 and not IsDestroyed(slider) do
        scale = 1-math.pow(fraction, 2)
        BuildBaseEffect:SetScale(sx * scale, 1.5*sy*scale, sz * scale)
        slider:SetGoal(0, 0.5*(fraction*sy - sy), 0)
        WaitSeconds(0.1)
        fraction = unitBeingBuilt:GetFractionComplete()
    end

    slider:Destroy()
    BuildBaseEffect:Destroy()
end


function CreateSeraphimUnitEngineerBuildingEffects( builder, unitBeingBuilt, BuildEffectBones, BuildEffectsBag )
	local army = builder:GetArmy()

    for kBone, vBone in BuildEffectBones do
		BuildEffectsBag:Add( CreateAttachedEmitter( builder, vBone, army, '/effects/emitters/seraphim_build_01_emit.bp' ) )

    	for k, v in EffectTemplate.SeraphimBuildBeams01 do
			local beamEffect = AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, v )
			BuildEffectsBag:Add(beamEffect)
		end
	end
end

function CreateSeraphimFactoryBuildingEffects( builder, unitBeingBuilt, BuildEffectBones, BuildBone, EffectsBag )
    local bp = unitBeingBuilt:GetBlueprint()
    local army = builder:GetArmy()
    local x, y, z = unpack(builder:GetPosition(BuildBone))
    local mul = 1
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil

    -- Create a pool mercury that slow draws into the build unit
    local BuildBaseEffect = unitBeingBuilt:CreateProjectile('/effects/entities/SeraphimBuildEffect01/SeraphimBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil )
    BuildBaseEffect:SetScale(sx, 1, sz)
    BuildBaseEffect:SetOrientation( unitBeingBuilt:GetOrientation(), true)
    Warp( BuildBaseEffect, Vector(x,y-0.05,z))
    unitBeingBuilt.Trash:Add(BuildBaseEffect)
    EffectsBag:Add(BuildBaseEffect)

    for kBone, vBone in BuildEffectBones do
		EffectsBag:Add( CreateAttachedEmitter( builder, vBone, army, '/effects/emitters/seraphim_build_01_emit.bp' ) )
		for kBeam, vBeam in EffectTemplate.SeraphimBuildBeams01 do
			EffectsBag:Add(AttachBeamEntityToEntity(builder, vBone, unitBeingBuilt, -1, army, vBeam ))
			EffectsBag:Add(CreateAttachedEmitter( unitBeingBuilt, -1, builder:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_02_emit.bp'))
			EffectsBag:Add(CreateAttachedEmitter( unitBeingBuilt, -1, builder:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_03_emit.bp'))
			EffectsBag:Add(CreateAttachedEmitter( unitBeingBuilt, -1, builder:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_04_emit.bp'))
			EffectsBag:Add(CreateAttachedEmitter( unitBeingBuilt, -1, builder:GetArmy(), '/effects/emitters/seraphim_being_built_ambient_05_emit.bp'))
		end
	end

    local slider = CreateSlider( unitBeingBuilt, 0 )
    unitBeingBuilt.Trash:Add(slider)
    EffectsBag:Add(slider)
    slider:SetWorldUnits(true)
    slider:SetGoal(0, sy, 0)
    slider:SetSpeed(-1)
    WaitFor(slider)
    if not unitBeingBuilt.Dead then
        slider:SetGoal(0,0,0)
        slider:SetSpeed(.05)
    end

    -- Wait till we are 80% done building, then snap our slider to
    while not unitBeingBuilt.Dead and unitBeingBuilt:GetFractionComplete() < 0.8 do
        WaitSeconds(0.5)
    end

    if not unitBeingBuilt.Dead then
        if not BuildBaseEffect:BeenDestroyed() then
	        BuildBaseEffect:SetScaleVelocity(-0.6, -0.6, -0.6)
	    end
    	if not slider:BeenDestroyed() then
            slider:SetSpeed(2)
        end
	    WaitSeconds(0.5)
	end

	if not slider:BeenDestroyed() then
        slider:Destroy()
    end

    if not BuildBaseEffect:BeenDestroyed() then
        BuildBaseEffect:Destroy()
    end
end

function CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, scaleFactor)
    local bp = unitBeingBuilt:GetBlueprint()
    local x, y, z = unpack(unitBeingBuilt:GetPosition())
    local mul = 0.5
    local sx = bp.Physics.MeshExtentsX or bp.Footprint.SizeX * mul
    local sz = bp.Physics.MeshExtentsZ or bp.Footprint.SizeZ * mul
    local sy = bp.Physics.MeshExtentsY or sx + sz

    local slice = nil
    WaitSeconds(0.1)

    local BuildBaseEffect = unitBeingBuilt:CreateProjectile('/effects/entities/SeraphimBuildEffect01/SeraphimBuildEffect01_proj.bp', nil, 0, 0, nil, nil, nil )
    BuildBaseEffect:SetScale(sx, 1, sz)
    BuildBaseEffect:SetOrientation( unitBeingBuilt:GetOrientation(), true)
    Warp( BuildBaseEffect, Vector(x,y,z))
    unitBeingBuilt.Trash:Add(BuildBaseEffect)
    EffectsBag:Add(BuildBaseEffect)

    local BuildEffectBaseEmitters = {
        '/effects/emitters/seraphim_being_built_ambient_01_emit.bp',
    }

    local BuildEffectsEmitters = {
        '/effects/emitters/seraphim_being_built_ambient_02_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_03_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_04_emit.bp',
        '/effects/emitters/seraphim_being_built_ambient_05_emit.bp',
    }

    local AdjustedEmitters = {}
    local effect = nil
    for k, vEffect in BuildEffectsEmitters do
        effect = CreateAttachedEmitter( unitBeingBuilt, -1, builder:GetArmy(), vEffect):ScaleEmitter(scaleFactor)
        table.insert( AdjustedEmitters, effect )
        EffectsBag:Add(effect)
    end

    for k, vEffect in BuildEffectBaseEmitters do
        effect = CreateAttachedEmitter( BuildBaseEffect, -1, builder:GetArmy(), vEffect):ScaleEmitter(scaleFactor)
        table.insert( AdjustedEmitters, effect )
        EffectsBag:Add(effect)
    end

    -- Poll the unit being built every 0.5 a second to adjust the effects to match
    local fractionComplete = unitBeingBuilt:GetFractionComplete()
    local unitScaleMetric = unitBeingBuilt:GetFootPrintSize() * 0.65
    while not unitBeingBuilt.Dead and fractionComplete < 1.0 do
        WaitSeconds(0.5)
        fractionComplete = unitBeingBuilt:GetFractionComplete()
        for k, vEffect in AdjustedEmitters do
            vEffect:ScaleEmitter(scaleFactor + (unitScaleMetric * fractionComplete))
        end
    end

    -- The flash can now be seen only by the player owning the building, his allies or enemies who
    -- have a visual of the building.
    local unitsArmy = unitBeingBuilt:GetArmy()
    local focusArmy = GetFocusArmy()
    if focusArmy == -1 or IsAlly(unitsArmy,focusArmy) then
        CreateLightParticle( unitBeingBuilt, -1, unitBeingBuilt:GetArmy(), unitBeingBuilt:GetFootPrintSize() * 7, 8, 'glow_02', 'ramp_blue_22' )
    elseif IsEnemy(unitsArmy,focusArmy) then
        local blip = unitBeingBuilt:GetBlip(focusArmy)
        if blip ~= nil and blip:IsSeenNow(focusArmy) then
            CreateLightParticle( unitBeingBuilt, -1, unitBeingBuilt:GetArmy(), unitBeingBuilt:GetFootPrintSize() * 7, 8, 'glow_02', 'ramp_blue_22' )
        end
    end

    WaitSeconds(0.5)
    BuildBaseEffect:Destroy()
end

function CreateSeraphimBuildBaseThread(unitBeingBuilt, builder, EffectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, 1)
end

function CreateSeraphimExperimentalBuildBaseThread(unitBeingBuilt, builder, EffectsBag)
    CreateSeraphimBuildThread(unitBeingBuilt, builder, EffectsBag, 2)
end

function CreateAdjacencyBeams( unit, adjacentUnit, AdjacencyBeamsBag )

    local info = {
        Unit = adjacentUnit,
        Trash = TrashBag(),
    }

    table.insert(AdjacencyBeamsBag, info)

    local uBp = unit:GetBlueprint()
    local aBp = adjacentUnit:GetBlueprint()
    local army = unit:GetArmy()
    local faction = uBp.General.FactionName

    -- Determine which effects we will be using
    local nodeMesh = nil
    local beamEffect = nil
    local emitterNodeEffects = {}
    local numNodes = 2
    local nodeList = {}
    local validAdjacency = true


	local unitPos = unit:GetPosition()
	local adjPos = adjacentUnit:GetPosition()

	-- Create hub start/end and all midpoint nodes
    local unitHub = {
		entity = Entity{},
		pos = unit:GetPosition(),
	}
	local adjacentHub = {
		entity = Entity{},
		pos = adjacentUnit:GetPosition(),
	}

    local spec = {
        Owner = unit,
    }

    if faction == 'Aeon' then
        nodeMesh = '/effects/entities/aeonadjacencynode/aeonadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_aeon_beam_0' .. util.GetRandomInt(1,3) .. '_emit.bp'
        numNodes = 3
    elseif faction == 'Cybran' then
        nodeMesh = '/effects/entities/cybranadjacencynode/cybranadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_cybran_beam_01_emit.bp'
    elseif faction == 'UEF' then
        nodeMesh = '/effects/entities/uefadjacencynode/uefadjacencynode_mesh'
        beamEffect = '/effects/emitters/adjacency_uef_beam_01_emit.bp'
    elseif faction == 'Seraphim' then
        nodeMesh = '/effects/entities/seraphimadjacencynode/seraphimadjacencynode_mesh'
        table.insert( emitterNodeEffects, EffectTemplate.SAdjacencyAmbient01 )
        if  util.GetDistanceBetweenTwoVectors( unitHub.pos, adjacentHub.pos ) < 2.5 then
            numNodes = 1
        else
            numNodes = 3
            table.insert( emitterNodeEffects, EffectTemplate.SAdjacencyAmbient02 )
            table.insert( emitterNodeEffects, EffectTemplate.SAdjacencyAmbient03 )
        end
    end

    for i = 1, numNodes do
		local node =
		{
            entity = Entity(spec),
			pos = {0,0,0},
			mesh = nil,
		}
        node.entity:SetVizToNeutrals('Intel')
        node.entity:SetVizToEnemies('Intel')
		table.insert( nodeList, node )
    end

	local verticalOffset = 0.05

	-- Move Unit Pos towards adjacent unit by bounding box size
	local uBpSizeX = uBp.SizeX * 0.5
	local uBpSizeZ = uBp.SizeZ * 0.5
	local aBpSizeX = aBp.SizeX * 0.5
	local aBpSizeZ = aBp.SizeZ * 0.5

	-- To Determine positioning, need to use the bounding box or skirt size
	local uBpSkirtX = uBp.Physics.SkirtSizeX * 0.5
	local uBpSkirtZ = uBp.Physics.SkirtSizeZ * 0.5
	local aBpSkirtX = aBp.Physics.SkirtSizeX * 0.5
	local aBpSkirtZ = aBp.Physics.SkirtSizeZ * 0.5

	-- Get edge corner positions, { TOP, LEFT, BOTTOM, RIGHT }
	local unitSkirtBounds = {
		unitHub.pos[3] - uBpSkirtZ,
		unitHub.pos[1] - uBpSkirtX,
		unitHub.pos[3] + uBpSkirtZ,
		unitHub.pos[1] + uBpSkirtX,
	}
	local adjacentSkirtBounds = {
		adjacentHub.pos[3] - aBpSkirtZ,
		adjacentHub.pos[1] - aBpSkirtX,
		adjacentHub.pos[3] + aBpSkirtZ,
		adjacentHub.pos[1] + aBpSkirtX,
	}

	-- Figure out the best matching ogrid position on units bounding box
	-- depending on it's skirt size

	-- Unit bottom or top skirt is aligned to adjacent unit
	if (unitSkirtBounds[3] == adjacentSkirtBounds[1]) or (unitSkirtBounds[1] == adjacentSkirtBounds[3]) then

		local sharedSkirtLower = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[2])
		local sharedSkirtUpper = unitSkirtBounds[4] - (unitSkirtBounds[4] - adjacentSkirtBounds[4])
		local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

		-- Depending on shared skirt bounds, determine the position of unit hub
		-- Find out how many times the shared skirt fits into the unit hub shared skirt
		local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
		local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

 		-- Z-offset, offset adjacency hub positions the proper direction
		if unitSkirtBounds[3] == adjacentSkirtBounds[1] then
			unitHub.pos[3] = unitHub.pos[3] + uBpSizeZ
			adjacentHub.pos[3] = adjacentHub.pos[3] - aBpSizeZ
		else -- unitSkirtBounds[1] == adjacentSkirtBounds[3]
			unitHub.pos[3] = unitHub.pos[3] - uBpSizeZ
			adjacentHub.pos[3] = adjacentHub.pos[3] + aBpSizeZ
		end

		-- X-offset, Find the shared adjacent x position range
		-- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
		if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
			local uSkirtLen = (unitSkirtBounds[4] - unitSkirtBounds[2]) * 0.5           -- Unit skirt length
			local uGridUnitSize = (uBpSizeX * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
			local xoffset = math.abs(unitSkirtBounds[2] - adjacentSkirtBounds[2]) * 0.5 -- Get offset of the unit along the skirt
			unitHub.pos[1] = (unitHub.pos[1] - uBpSizeX) + (xoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
		end

		-- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
		if numUnitSkirtsOnAdjSkirt > 1  or numAdjSkirtsOnUnitSkirt < 1 then
			local aSkirtLen = (adjacentSkirtBounds[4] - adjacentSkirtBounds[2]) * 0.5   -- Adjacent unit skirt length
			local aGridUnitSize = (aBpSizeX * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
			local xoffset = math.abs(adjacentSkirtBounds[2] - unitSkirtBounds[2]) * 0.5	-- Get offset of the unit along the adjacent unit
			adjacentHub.pos[1] = (adjacentHub.pos[1] - aBpSizeX) + (xoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end

	-- Unit right or top left is aligned to adjacent unit
	elseif (unitSkirtBounds[4] == adjacentSkirtBounds[2]) or (unitSkirtBounds[2] == adjacentSkirtBounds[4]) then

		local sharedSkirtLower = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[1])
		local sharedSkirtUpper = unitSkirtBounds[3] - (unitSkirtBounds[3] - adjacentSkirtBounds[3])
		local sharedSkirtLen = sharedSkirtUpper - sharedSkirtLower

		-- Depending on shared skirt bounds, determine the position of unit hub
		-- Find out how many times the shared skirt fits into the unit hub shared skirt
		local numAdjSkirtsOnUnitSkirt = (uBpSkirtX * 2) / sharedSkirtLen
		local numUnitSkirtsOnAdjSkirt = (aBpSkirtX * 2) / sharedSkirtLen

		-- X-offset
		if (unitSkirtBounds[4] == adjacentSkirtBounds[2]) then
			unitHub.pos[1] = unitHub.pos[1] + uBpSizeX
			adjacentHub.pos[1] = adjacentHub.pos[1] - aBpSizeX
		else -- unitSkirtBounds[2] == adjacentSkirtBounds[4]
			unitHub.pos[1] = unitHub.pos[1] - uBpSizeX
			adjacentHub.pos[1] = adjacentHub.pos[1] + aBpSizeX
		end

		-- Z-offset, Find the shared adjacent x position range
		-- If we have more than skirt on this section, then we need to adjust the x position of the unit hub
		if numAdjSkirtsOnUnitSkirt > 1 or numUnitSkirtsOnAdjSkirt < 1 then
			local uSkirtLen = (unitSkirtBounds[3] - unitSkirtBounds[1]) * 0.5           -- Unit skirt length
			local uGridUnitSize = (uBpSizeZ * 2) / uSkirtLen                            -- Determine one grid of adjacency along that length
			local zoffset = math.abs(unitSkirtBounds[1] - adjacentSkirtBounds[1]) * 0.5 -- Get offset of the unit along the skirt
			unitHub.pos[3] = (unitHub.pos[3] - uBpSizeZ) + (zoffset * uGridUnitSize) + (uGridUnitSize * 0.5) -- Now offset the position of adjacent point
		end

		-- If we have more than skirt on this section, then we need to adjust the x position of the adjacent hub
		if numUnitSkirtsOnAdjSkirt > 1 or numAdjSkirtsOnUnitSkirt < 1 then
			local aSkirtLen = (adjacentSkirtBounds[3] - adjacentSkirtBounds[1]) * 0.5   -- Adjacent unit skirt length
			local aGridUnitSize = (aBpSizeZ * 2) / aSkirtLen                            -- Determine one grid of adjacency along that length ??
			local zoffset = math.abs(adjacentSkirtBounds[1] - unitSkirtBounds[1]) * 0.5	-- Get offset of the unit along the adjacent unit
			adjacentHub.pos[3] = (adjacentHub.pos[3] - aBpSizeZ) + (zoffset * aGridUnitSize) + (aGridUnitSize * 0.5) -- Now offset the position of adjacent point
        end
    end

	-- Setup our midpoint positions
	if faction == 'Aeon' or faction == 'Seraphim' then
		local DirectionVec = util.GetDifferenceVector( unitHub.pos, adjacentHub.pos )
		local Dist = util.GetDistanceBetweenTwoVectors( unitHub.pos, adjacentHub.pos )
		local PerpVec = util.Cross( DirectionVec, Vector(0,0.35,0) )
		local segmentLen = 1 / (numNodes + 1)
		local halfDist = Dist * 0.5

		if util.GetRandomInt(0,1) == 1 then
			PerpVec[1] = -PerpVec[1]
			PerpVec[2] = -PerpVec[2]
			PerpVec[3] = -PerpVec[3]
		end

		local offsetMul = 0.15

		for i = 1, numNodes do
			local segmentMul = i * segmentLen

			if segmentMul <= 0.5 then
				offsetMul = offsetMul + 0.12
			else
				offsetMul = offsetMul - 0.12
			end

			nodeList[i].pos = {
				unitHub.pos[1] - (DirectionVec[1] * segmentMul) - (PerpVec[1] * offsetMul),
				nil,
				unitHub.pos[3] - (DirectionVec[3] * segmentMul) - (PerpVec[3] * offsetMul),
			}
		end
    elseif faction == 'Cybran' then
        if (unitPos[1] == adjPos[1]) or (unitPos[3] == adjPos[3]) then
            local Dist = util.GetDistanceBetweenTwoVectors( unitHub.pos, adjacentHub.pos )
            local DirectionVec = util.GetScaledDirectionVector( unitHub.pos, adjacentHub.pos, util.GetRandomFloat(0.35, Dist * 0.48) )
            DirectionVec[2] = 0
            local PerpVec = util.Cross( DirectionVec, Vector(0,util.GetRandomFloat(0.2, 0.35),0) )

            if util.GetRandomInt(0,1) == 1 then
                PerpVec[1] = -PerpVec[1]
                PerpVec[2] = -PerpVec[2]
                PerpVec[3] = -PerpVec[3]
            end

            -- Initialize 2 midpoint segments
            nodeList[1].pos = { unitHub.pos[1] - DirectionVec[1], unitHub.pos[2] - DirectionVec[2], unitHub.pos[3] - DirectionVec[3] }
            nodeList[2].pos = { adjacentHub.pos[1] + DirectionVec[1], adjacentHub.pos[2] + DirectionVec[2], adjacentHub.pos[3] + DirectionVec[3] }

            -- Offset beam positions
            nodeList[1].pos[1] = nodeList[1].pos[1] - PerpVec[1]
            nodeList[1].pos[3] = nodeList[1].pos[3] - PerpVec[3]
            nodeList[2].pos[1] = nodeList[2].pos[1] + PerpVec[1]
            nodeList[2].pos[3] = nodeList[2].pos[3] + PerpVec[3]

            unitHub.pos[1] = unitHub.pos[1] - PerpVec[1]
            unitHub.pos[3] = unitHub.pos[3] - PerpVec[3]
            adjacentHub.pos[1] = adjacentHub.pos[1] + PerpVec[1]
            adjacentHub.pos[3] = adjacentHub.pos[3] + PerpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if (unitSkirtBounds[3] == adjacentSkirtBounds[1]) then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) - (util.GetRandomFloat(0, 1))
                nodeList[2].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) + (util.GetRandomFloat(0, 1))
            elseif (unitSkirtBounds[1] == adjacentSkirtBounds[3]) then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) + (util.GetRandomFloat(0, 1))
                nodeList[2].pos[3] = ((unitHub.pos[3] + adjacentHub.pos[3]) * 0.5) - (util.GetRandomFloat(0, 1))
            elseif (unitSkirtBounds[4] == adjacentSkirtBounds[2]) then
                nodeList[1].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) - (util.GetRandomFloat(0, 1))
                nodeList[2].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) + (util.GetRandomFloat(0, 1))
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            elseif (unitSkirtBounds[2] == adjacentSkirtBounds[4]) then
                nodeList[1].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) + (util.GetRandomFloat(0, 1))
                nodeList[2].pos[1] = ((unitHub.pos[1] + adjacentHub.pos[1]) * 0.5) - (util.GetRandomFloat(0, 1))
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            else
                validAdjacency = false
            end
        end
    elseif faction == 'UEF' then
        if (unitPos[1] == adjPos[1]) or (unitPos[3] == adjPos[3]) then
            local DirectionVec = util.GetScaledDirectionVector( unitHub.pos, adjacentHub.pos, 0.35 )
            DirectionVec[2] = 0
            local PerpVec = util.Cross( DirectionVec, Vector(0,0.35,0) )
            if util.GetRandomInt(0,1) == 1 then
                PerpVec[1] = -PerpVec[1]
                PerpVec[2] = -PerpVec[2]
                PerpVec[3] = -PerpVec[3]
            end

            -- Initialize 2 midpoint segments
            for k, v in nodeList do
	            v.pos = util.GetMidPoint( unitHub.pos, adjacentHub.pos )
            end

            -- Offset beam positions
            nodeList[1].pos[1] = nodeList[1].pos[1] - PerpVec[1]
            nodeList[1].pos[3] = nodeList[1].pos[3] - PerpVec[3]
            nodeList[2].pos[1] = nodeList[2].pos[1] + PerpVec[1]
            nodeList[2].pos[3] = nodeList[2].pos[3] + PerpVec[3]

            unitHub.pos[1] = unitHub.pos[1] - PerpVec[1]
            unitHub.pos[3] = unitHub.pos[3] - PerpVec[3]
            adjacentHub.pos[1] = adjacentHub.pos[1] + PerpVec[1]
            adjacentHub.pos[3] = adjacentHub.pos[3] + PerpVec[3]
        else
            -- Unit bottom skirt is on top skirt of adjacent unit
            if (unitSkirtBounds[3] == adjacentSkirtBounds[1]) or (unitSkirtBounds[1] == adjacentSkirtBounds[3]) then
                nodeList[1].pos[1] = unitHub.pos[1]
                nodeList[2].pos[1] = adjacentHub.pos[1]
                nodeList[1].pos[3] = (unitHub.pos[3] + adjacentHub.pos[3]) * 0.5
                nodeList[2].pos[3] = (unitHub.pos[3] + adjacentHub.pos[3]) * 0.5

            -- Unit right skirt is on left skirt of adjacent unit
            elseif (unitSkirtBounds[4] == adjacentSkirtBounds[2]) or (unitSkirtBounds[2] == adjacentSkirtBounds[4]) then
                nodeList[1].pos[1] = (unitHub.pos[1] + adjacentHub.pos[1]) * 0.5
                nodeList[2].pos[1] = (unitHub.pos[1] + adjacentHub.pos[1]) * 0.5
                nodeList[1].pos[3] = unitHub.pos[3]
                nodeList[2].pos[3] = adjacentHub.pos[3]
            else
                validAdjacency = false
            end
        end
    end

    if validAdjacency then
        -- Offset beam positions above the ground at current positions terrain height
        for k, v in nodeList do
            v.pos[2] = GetSurfaceHeight(v.pos[1], v.pos[3]) + verticalOffset
        end

        unitHub.pos[2] = GetSurfaceHeight(unitHub.pos[1], unitHub.pos[3]) + verticalOffset
        adjacentHub.pos[2] = GetSurfaceHeight(adjacentHub.pos[1], adjacentHub.pos[3]) + verticalOffset

        -- Set the mesh of the entity and attach any node effects
        for i = 1, numNodes do
            nodeList[i].entity:SetMesh(nodeMesh, false)
            --nodeList[i].entity:SetDrawScale(0.003)
            nodeList[i].mesh = true
            if emitterNodeEffects[i] ~= nil and table.getn(emitterNodeEffects[i]) ~= 0 then
                for k, vEmit in emitterNodeEffects[i] do
                    emit = CreateAttachedEmitter( nodeList[i].entity, 0, army, vEmit )
                    info.Trash:Add(emit)
                    unit.Trash:Add(emit)
                end
            end
        end

        -- Insert start and end points into our list
        table.insert(nodeList, 1, unitHub )
        table.insert(nodeList, adjacentHub )

        -- Warp everything to its final position
        for i = 1, numNodes + 2 do
            Warp( nodeList[i].entity, nodeList[i].pos )
            info.Trash:Add(nodeList[i].entity)
            unit.Trash:Add(nodeList[i].entity)
        end

        -- Attach beams to the adjacent unit
        for i = 1, numNodes + 1 do
            if nodeList[i].mesh ~= nil then
                local vec = util.GetDirectionVector(Vector(nodeList[i].pos[1], nodeList[i].pos[2], nodeList[i].pos[3]), Vector(nodeList[i+1].pos[1], nodeList[i+1].pos[2], nodeList[i+1].pos[3]))
                nodeList[i].entity:SetOrientation( OrientFromDir( vec ),true)
            end
            if beamEffect then
                local beam = AttachBeamEntityToEntity( nodeList[i].entity, -1, nodeList[i+1].entity, -1, army, beamEffect  )
                info.Trash:Add(beam)
                unit.Trash:Add(beam)
            end
        end
    end
end

function PlaySacrificingEffects( unit, target_unit )
	local army = unit:GetArmy()
	local bp = unit:GetBlueprint()
	local faction = bp.General.FactionName

	if faction == 'Aeon' then
		for k, v in EffectTemplate.ASacrificeOfTheAeon01 do
			unit.Trash:Add( CreateEmitterOnEntity( unit, army, v) )
		end
	end
end

function PlaySacrificeEffects( unit, target_unit )
	local army = unit:GetArmy()
	local bp = unit:GetBlueprint()
	local faction = bp.General.FactionName

	if faction == 'Aeon' then
		for k, v in EffectTemplate.ASacrificeOfTheAeon02 do
			CreateEmitterAtEntity( target_unit, army, v)
		end
	end
end

function PlayReclaimEffects( reclaimer, reclaimed, BuildEffectBones, EffectsBag )
	local army = reclaimer:GetArmy()
    local pos = reclaimed:GetPosition()
    pos[2] = GetSurfaceHeight(pos[1], pos[3])

    local beamEnd = Entity()
    EffectsBag:Add(beamEnd)
    Warp( beamEnd, pos )

    for kBone, vBone in BuildEffectBones do
		for kEmit, vEmit in EffectTemplate.ReclaimBeams do
			local beamEffect = AttachBeamEntityToEntity(reclaimer, vBone, beamEnd, -1, army, vEmit )
			EffectsBag:Add(beamEffect)
		end
	end

	for k, v in EffectTemplate.ReclaimObjectAOE do
	    EffectsBag:Add( CreateEmitterOnEntity( reclaimed, army, v ) )
	end
end


function PlayReclaimEndEffects( reclaimer, reclaimed )

    local army = -1
    if reclaimer then
        army = reclaimer:GetArmy()
    end
	for k, v in EffectTemplate.ReclaimObjectEnd do
	    CreateEmitterAtEntity( reclaimed, army, v )
	end

	CreateLightParticleIntel( reclaimed, -1, army, 4, 6, 'glow_02', 'ramp_flare_02' )

end

function PlayCaptureEffects( capturer, captive, BuildEffectBones, EffectsBag )
	local army = capturer:GetArmy()

    for kBone, vBone in BuildEffectBones do
		for kEmit, vEmit in EffectTemplate.CaptureBeams do
			local beamEffect = AttachBeamEntityToEntity(capturer, vBone, captive, -1, army, vEmit )
			EffectsBag:Add(beamEffect)
		end
	end


end

function CreateCybranQuantumGateEffect( unit, bone1, bone2, TrashBag, startwaitSeed )
    -- Adding a quick wait here so that unit bone positions are correct
    WaitSeconds( startwaitSeed )

    local army = unit:GetArmy()
    local BeamEmtBp = '/effects/emitters/cybran_gate_beam_01_emit.bp'
    local pos1 = unit:GetPosition(bone1)
    local pos2 = unit:GetPosition(bone2)
    pos1[2] = pos1[2] - 0.72
    pos2[2] = pos2[2] - 0.72

    -- Create a projectile for the end of build effect and warp it to the unit
    local BeamStartEntity = unit:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp',0,0,0,nil,nil,nil)
    TrashBag:Add( BeamStartEntity )
    Warp( BeamStartEntity, pos1)

    local BeamEndEntity = unit:CreateProjectile('/effects/entities/UEFBuild/UEFBuild01_proj.bp',0,0,0,nil,nil,nil)
    TrashBag:Add( BeamEndEntity )
    Warp( BeamEndEntity, pos2)

    -- Create beam effect
    TrashBag:Add(AttachBeamEntityToEntity(BeamStartEntity, -1, BeamEndEntity, -1, army, BeamEmtBp ))

    -- Determine a the velocity of our projectile, used for the scaning effect
    local velY = 1
    BeamEndEntity:SetVelocity( 0, velY, 0 )

    local flipDirection = true

    -- Warp our projectile back to the initial corner and lower based on build completeness
    while not unit:BeenDestroyed() do

        if flipDirection then
            BeamStartEntity:SetVelocity( 0, velY, 0 )
            BeamEndEntity:SetVelocity( 0, velY, 0 )
            flipDirection = false
        else
            BeamStartEntity:SetVelocity( 0, -velY, 0 )
            BeamEndEntity:SetVelocity( 0, -velY, 0 )
            flipDirection = true
        end
        WaitSeconds( 1.5 )
    end
end

function CreateEnhancementEffectAtBone( unit, bone, TrashBag )
    local army = unit:GetArmy()
    for k, vEffect in EffectTemplate.UpgradeBoneAmbient do
        TrashBag:Add(CreateAttachedEmitter( unit, bone, army, vEffect ))
    end
end

function CreateEnhancementUnitAmbient( unit, bone, TrashBag )
    local army = unit:GetArmy()
    for k, vEffect in EffectTemplate.UpgradeUnitAmbient do
        TrashBag:Add(CreateAttachedEmitter( unit, bone, army, vEffect ))
    end
end

function CleanupEffectBag( self, EffectBag )
    for k, v in self[EffectBag] do
        v:Destroy()
    end
    self[EffectBag] = {}
end

function SeraphimRiftIn( unit )
	local army = unit:GetArmy()
	unit:HideBone(0, true)

	for k, v in EffectTemplate.SerRiftIn_Small do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
	WaitSeconds (2.0)
	CreateLightParticle( unit, -1, army, 4, 15, 'glow_05', 'ramp_jammer_01' )
	WaitSeconds (0.1)
	unit:ShowBone(0, true)
	WaitSeconds (0.25)
	for k, v in EffectTemplate.SerRiftIn_SmallFlash do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
end

function SeraphimRiftInLarge( unit )
	local army = unit:GetArmy()
	unit:HideBone(0, true)

	for k, v in EffectTemplate.SerRiftIn_Large do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
	WaitSeconds (2.0)
	CreateLightParticle( unit, -1, army, 25, 15, 'glow_05', 'ramp_jammer_01' )
	WaitSeconds (0.1)
	unit:ShowBone(0, true)
	WaitSeconds (0.25)
	for k, v in EffectTemplate.SerRiftIn_LargeFlash do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
end

function CybranBuildingInfection( unit )
	local army = unit:GetArmy()
	for k, v in EffectTemplate.CCivilianBuildingInfectionAmbient do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
end

function CybranQaiShutdown( unit )
	local army = unit:GetArmy()
	for k, v in EffectTemplate.CQaiShutdown do
		CreateAttachedEmitter ( unit, -1, army, v )
	end
end

function AeonHackACU( unit )
	for k, v in EffectTemplate.AeonOpHackACU do
		CreateAttachedEmitter ( unit, -1, unit:GetArmy(), v )
	end
end


--new function for insta capture fix
IsHumanUnit = function(self)
	local ArmyTable = ScenarioInfo.ArmySetup
	local ArmyIndex = self:GetArmy()

	for ArmyName,Army in ArmyTable do
		if Army.ArmyIndex == ArmyIndex then
			if Army.Human == true then
				return true
			else
				return false
			end

		end
	end


end

function PlayTeleportChargingEffects(unit, TeleportDestination, EffectsBag)
    -- Plays teleport effects for the given unit
    if not unit then
        return
    end

    local army = unit:GetArmy()
    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local Yoffset = TeleportGetUnitYOffset(unit)

    TeleportDestination = TeleportLocationToSurface(TeleportDestination)

    -- Play tele FX at unit location
    if bp.Display.TeleportEffects.PlayChargeFxAtUnit ~= false then
        unit:PlayUnitAmbientSound('TeleportChargingAtUnit')

        if faction == 'UEF' then
            -- We recycle the teleport destination effects since they are way more epic
            unit.TeleportChargeBag = {}
            local telefx = EffectTemplate.UEFTeleportCharge02
            for k, v in telefx do
                local fx = CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2) -- To make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0) -- Small initial rotation, will be faster as charging
                table.insert(unit.TeleportChargeBag, fx)
                EffectsBag:Add(fx)
            end
            
            -- Make steam FX
            local totalBones = unit:GetBoneCount() - 1
            for k, v in EffectTemplate.UnitTeleportSteam01 do
                for bone = 1, totalBones do
                    local emitter = CreateAttachedEmitter(unit, bone, army, v):SetEmitterParam('Lifetime', 9999) -- Adjust the lifetime so we always teleport before its done
                    
                    table.insert(unit.TeleportChargeBag, emitter)
                    EffectsBag:Add(emitter)
                end
            end
        -- Use a per-bone FX construction rather than wrap-around for the non-UEF factions
        elseif faction == 'Cybran' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.CybranTeleportCharge01, EffectsBag)
        elseif faction == 'Seraphim' then
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.SeraphimTeleportCharge01, EffectsBag)
        else
            unit.TeleportChargeBag = TeleportShowChargeUpFxAtUnit(unit, EffectTemplate.GenericTeleportCharge01, EffectsBag)
        end
    end

    -- Play tele FX at destination, including sounds
    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        -- Customized version of PlayUnitAmbientSound() from unit.lua to play sound at target destination
        local sound = 'TeleportChargingAtDestination'
        local sndEnt = false

        unit.TeleportSoundChargeBag = {}
        if sound and bp.Audio[sound] then
            if not unit.AmbientSounds then
                unit.AmbientSounds = {}
            end
            if not unit.AmbientSounds[sound] then
                sndEnt = Entity {}
                unit.AmbientSounds[sound] = sndEnt
                unit.Trash:Add(sndEnt)
                Warp(sndEnt, TeleportDestination)  -- Warping sound entity to destination so ambient sound plays there (and not at unit)
                table.insert(unit.TeleportSoundChargeBag, sndEnt)
            end
            unit.AmbientSounds[sound]:SetAmbientSound(bp.Audio[sound], nil)
        end

        -- Using a barebone entity to position effects, it is destroyed afterwards
        local TeleportDestFxEntity = Entity()
        Warp(TeleportDestFxEntity, TeleportDestination)
        unit.TeleportDestChargeBag = {}

        if faction == 'UEF' then
            local telefx = EffectTemplate.UEFTeleportCharge02
            for k, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, army, v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.75)
                fx:SetEmitterCurveParam('Y_POSITION_CURVE', 0, Yoffset * 2)  -- To make effects cover entire height of unit
                fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', 1, 0)  -- Small initial rotation, will be faster as charging
                table.insert(unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end
        elseif faction == 'Cybran' then
            local pos = table.copy(TeleportDestination)
            pos[2] = pos[2] + Yoffset -- Make sure sphere isn't half in the ground
            local sphere = TeleportCreateCybranSphere(unit, pos, 0.01)

            local telefx = EffectTemplate.CybranTeleportCharge02

            for k, v in telefx do
                local fx = CreateEmitterAtEntity(sphere, army, v)
                fx:ScaleEmitter(0.01 * unit.TeleportCybranSphereScale)
                table.insert(unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end
        elseif faction == 'Seraphim' then
            local telefx = EffectTemplate.SeraphimTeleportCharge02
            for k, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, army, v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert(unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

            TeleportDestFxEntity:Destroy()
        else
            local telefx = EffectTemplate.GenericTeleportCharge02
            for k, v in telefx do
                local fx = CreateEmitterAtEntity(TeleportDestFxEntity, army, v):OffsetEmitter(0, Yoffset, 0)
                fx:ScaleEmitter(0.01)
                table.insert(unit.TeleportDestChargeBag, fx)
                EffectsBag:Add(fx)
            end

            TeleportDestFxEntity:Destroy()
        end
    end
end

function TeleportGetUnitYOffset(unit)
    -- returns how high to create effects to make the effects appear in the center of the unit
    local bp = unit:GetBlueprint()
    return bp.Display.TeleportEffects.FxChargeAtDestOffsetY or ((bp.Physics.MeshExtentsY or bp.SizeY or 2) / 2)
end

function TeleportGetUnitSizes(unit)
    -- returns the sizes of the unit, to be used for teleportation effects
    local bp = unit:GetBlueprint()
    return (bp.Display.TeleportEffects.FxSizeX or bp.Physics.MeshExtentsX or bp.SizeX or 1),
           (bp.Display.TeleportEffects.FxSizeY or bp.Physics.MeshExtentsY or bp.SizeY or 1),
           (bp.Display.TeleportEffects.FxSizeZ or bp.Physics.MeshExtentsZ or bp.SizeZ or 1),
           (bp.Display.TeleportEffects.FxOffsetX or bp.CollisionOffsetX or 0),
           (bp.Display.TeleportEffects.FxOffsetY or bp.CollisionOffsetY or 0),
           (bp.Display.TeleportEffects.FxOffsetZ or bp.CollisionOffsetZ or 0)
end

function TeleportLocationToSurface(loc)
    -- takes the given location, adjust the Y value to the surface height on that location
    local pos = table.copy( loc )
    pos[2] = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
    return pos
end

function TeleportShowChargeUpFxAtUnit(unit, effectTemplate, EffectsBag)
    -- Creates charge up effects at the unit
    local bp = unit:GetBlueprint()
    local army = unit:GetArmy()
    local bones = bp.Display.TeleportEffects.ChargeFxAtUnitBones or {Bone = 0, Offset = {0,0.25,0}, }
    local bone, ox, oy, oz
    local emitters = {}
    for _, value in bones do
        bone = value.Bone or 0
        ox = value.Offset[1] or 0
        oy = value.Offset[2] or 0
        oz = value.Offset[3] or 0
        for k, v in effectTemplate do
            local fx = CreateEmitterAtBone(unit, bone, army, v):OffsetEmitter(ox, oy, oz)
            table.insert( emitters, fx)
            EffectsBag:Add(fx)
        end
    end
    return emitters
end

function TeleportCreateCybranSphere(unit, location, initialScale)
    -- Creates the sphere used by Cybran teleportation effects
    local bp = unit:GetBlueprint()
    local scale = 1

    local sx, sy, sz = TeleportGetUnitSizes(unit)
    local scale = 1.25 * math.max( sx, math.max( sy, sz))
    unit.TeleportCybranSphereScale = scale

    local sphere = Entity()
    sphere:SetPosition(location, true)
    sphere:SetMesh('/effects/Entities/CybranTeleport/CybranTeleport_mesh', false)
    sphere:SetDrawScale(initialScale or scale)
    unit.TeleportCybranSphere = sphere
    unit.Trash:Add(sphere)

    sphere:SetVizToAllies('Intel')
    sphere:SetVizToEnemies('Intel')
    sphere:SetVizToFocusPlayer('Intel')
    sphere:SetVizToNeutrals('Intel')

    return sphere
end

function TeleportChargingProgress(unit, fraction)
    local bp = unit:GetBlueprint()

    if bp.Display.TeleportEffects.PlayChargeFxAtDestination ~= false then
        fraction = math.min(math.max(fraction, 0.01), 1)
        local faction = bp.General.FactionName

        if faction == 'UEF' then
            -- Increase rotation of effects as progressing
            if unit.TeleportDestChargeBag then
                local scale = 0.75 + (0.5 * math.max( fraction, 0.01 ))
                for k, fx in unit.TeleportDestChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
                    fx:ScaleEmitter(scale)
                end

                -- Scale FX at unit location as well
                for k, fx in unit.TeleportChargeBag do
                    fx:SetEmitterCurveParam('ROTATION_RATE_CURVE', -(25 + (100 * fraction)), (30 * fraction))
                    fx:ScaleEmitter(scale)
                end
            end
        elseif faction == 'Cybran' then
            -- Increase size of sphere and effects as progressing
            local scale = math.max(fraction, 0.01) * (unit.TeleportCybranSphereScale or 5)
            if unit.TeleportCybranSphere then
                unit.TeleportCybranSphere:SetDrawScale(scale)
            end
            if unit.TeleportDestChargeBag then
                for k, fx in unit.TeleportDestChargeBag do
                   fx:ScaleEmitter(scale)
                end
            end
        elseif unit.TeleportDestChargeBag then
            -- Increase size of effects as progressing

            local scale = (2 * fraction) - math.pow(fraction, 2)
            for k, fx in unit.TeleportDestChargeBag do
               fx:ScaleEmitter(scale)
            end
        end
    end
end

function PlayTeleportOutEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just before the unit is taken from its original location

    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local army = unit:GetArmy()
    local Yoffset = TeleportGetUnitYOffset(unit)

    if bp.Display.TeleportEffects.PlayTeleportOutFx ~= false then

        unit:PlayUnitSound('TeleportOut')

        if faction == 'UEF' then

            local scaleX, scaleY, scaleZ = TeleportGetUnitSizes(unit)
            local cfx = unit:CreateProjectile('/effects/Entities/UEFBuildEffect/UEFBuildEffect02_proj.bp',0,0,0, nil, nil, nil )
            cfx:SetScale(scaleX, scaleY, scaleZ)
            EffectsBag:Add(cfx)

            CreateLightParticle( unit, -1, army, 3, 7, 'glow_03', 'ramp_blue_02' )
            local templ = unit.TeleportOutFxOverride or EffectTemplate.UEFTeleportOut01
            for k, v in templ do
                CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
            end

        elseif faction == 'Cybran' then

            CreateLightParticle( unit, -1, army, 4, 10, 'glow_02', 'ramp_red_06' )
            local templ = unit.TeleportOutFxOverride or EffectTemplate.CybranTeleportOut01
            for k, v in templ do
                CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
            end

        elseif faction == 'Seraphim' then

            CreateLightParticle( unit, -1, army, 4, 15, 'glow_05', 'ramp_jammer_01' )
            local templ = unit.TeleportOutFxOverride or EffectTemplate.SeraphimTeleportOut01
            for k, v in templ do
                CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
            end

        else  -- Aeon or other factions

            local templ = unit.TeleportOutFxOverride or EffectTemplate.GenericTeleportOut01
            for k, v in templ do
                CreateEmitterAtEntity(unit,army,v)
            end

        end
    end
end

function DoTeleportInDamage(unit)
    -- Check for teleport dummy weapon and deal the specified damage. Also show fx.

    local bp = unit:GetBlueprint()
    local Yoffset = TeleportGetUnitYOffset(unit)

    local dmg = 0
    local dmgRadius = 0
    local dmgType = 'Normal'
    local dmgFriendly = false

    if bp.Weapon then

        for k, wep in bp.Weapon do
            if wep.Label == 'TeleportWeapon' then
                dmg = wep.Damage or dmg
                dmgRadius = wep.DamageRadius or dmgRadius
                dmgType = wep.DamageType or dmgType
                dmgFriendly = wep.DamageFriendly or dmgFriendly
                break
            end
        end

        if dmg > 0 and dmgRadius > 0 then

            --LOG('*DEBUG: Do teleport in weapon')
            local faction = bp.General.FactionName
            local army = unit:GetArmy()
            local templ

            if unit.TeleportInWeaponFxOverride then
                templ = unit.TeleportInWeaponFxOverride
            elseif faction == 'UEF' then
                templ = EffectTemplate.UEFTeleportInWeapon01
            elseif faction == 'Cybran' then
                templ = EffectTemplate.CybranTeleportInWeapon01
            elseif faction == 'Seraphim' then
                templ = EffectTemplate.SeraphimTeleportInWeapon01
            else  -- Aeon or other factions
                templ = EffectTemplate.GenericTeleportInWeapon01
            end

            local MeshExtentsY = (bp.Physics.MeshExtentsY or 1)
            for k, v in templ do
                CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
            end

            DamageArea( unit, unit:GetPosition(), dmgRadius, dmg, dmgType, dmgFriendly )
        end
    end
end

function CreateTeleSteamFX(unit)
    local army = unit:GetArmy()
    local totalBones = unit:GetBoneCount() - 1
    for k, v in EffectTemplate.UnitTeleportSteam01 do
        for bone = 1, totalBones do
            CreateAttachedEmitter(unit, bone, army, v)
        end
    end
end

function PlayTeleportInEffects(unit, EffectsBag)
    -- Fired when the unit is being teleported, just after the unit is taken from its original location

    local bp = unit:GetBlueprint()
    local faction = bp.General.FactionName
    local army = unit:GetArmy()
    local Yoffset = TeleportGetUnitYOffset(unit)
    local decalOrient = RandomFloat(0, 2 * math.pi)

    DoTeleportInDamage(unit)  -- Fire teleport weapon

    if bp.Display.TeleportEffects.PlayTeleportInFx ~= false then
        unit:PlayUnitSound('TeleportIn')

        if faction == 'UEF' then
            local templ = unit.TeleportInFxOverride or EffectTemplate.UEFTeleportIn01
            for k, v in templ do
                CreateEmitterAtEntity(unit,army,v):OffsetEmitter(0, Yoffset, 0)
            end

            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)

            local fn = function(unit)
                local bp = unit:GetBlueprint()
                local MeshExtentsY = (bp.Physics.MeshExtentsY or 1)

                CreateLightParticle( unit, -1, army, 4, 10, 'glow_03', 'ramp_yellow_01' )
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                CreateTeleSteamFX(unit)
            end

            local thread = unit:ForkThread(fn)
        elseif faction == 'Cybran' then
            if not unit.TeleportCybranSphere then
                local pos = TeleportLocationToSurface( table.copy(unit:GetPosition()) )
                pos[2] = pos[2] + Yoffset
                unit.TeleportCybranSphere = TeleportCreateCybranSphere(unit, pos)
            end

            local templ = unit.TeleportInFxOverride or EffectTemplate.CybranTeleportIn01
            local scale = unit.TeleportCybranSphereScale or 5
            for k, v in templ do
                CreateEmitterAtEntity(unit.TeleportCybranSphere,army,v):ScaleEmitter(scale)
            end

            CreateLightParticle( unit.TeleportCybranSphere, -1, army, 4, 10, 'glow_02', 'ramp_white_01' )
            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)

            local fn = function(unit)
                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                WaitSeconds(0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds(0.8)

                if unit.TeleportCybranSphere then
                    unit.TeleportCybranSphere:Destroy()
                    unit.TeleportCybranSphere = false
                end

                CreateTeleSteamFX(unit)
            end

            local thread = unit:ForkThread(fn)
        elseif faction == 'Seraphim' then
            local fn = function(unit)

                local bp = unit:GetBlueprint()
                local Yoffset = TeleportGetUnitYOffset(unit)

                unit.TeleportFx_IsInvisible = true
                unit:HideBone(0, true)

                local templ = unit.TeleportInFxOverride or EffectTemplate.SeraphimTeleportIn01
                for k, v in templ do
                    CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
                end

                CreateLightParticle( unit, -1, army, 4, 15, 'glow_05', 'ramp_jammer_01' )
                DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

                local decalOrient = RandomFloat(0, 2 * math.pi)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_albedo', '', 'Albedo', 4, 4, 200, 300, army)
                CreateDecal(unit:GetPosition(), decalOrient, 'crater01_normals', '', 'Normals', 4, 4, 200, 300, army)

                WaitSeconds (0.3)

                unit:ShowBone(0, true)
                unit:ShowEnhancementBones()
                unit.TeleportFx_IsInvisible = false

                WaitSeconds (0.25)

                for k, v in EffectTemplate.SeraphimTeleportIn02 do
                    CreateEmitterAtEntity(unit, army, v):OffsetEmitter(0, Yoffset, 0)
                end
                
                CreateTeleSteamFX(unit)
            end
            
            local thread = unit:ForkThread(fn)
        else
            local templ = unit.TeleportInFxOverride or EffectTemplate.GenericTeleportIn01
            for k, v in templ do
                CreateEmitterAtEntity(unit,army,v):OffsetEmitter(0, Yoffset, 0)
            end

            DamageArea(unit, unit:GetPosition(), 9, 1, 'Force', true)

            CreateDecal(unit:GetPosition(), decalOrient, 'Scorch_generic_002_albedo', '', 'Albedo', 7, 7, 200, 300, army)

            CreateTeleSteamFX(unit)
        end
    end
end

function DestroyTeleportChargingEffects(unit, EffectsBag)
    -- Called when charging up is done because successful or cancelled
    if unit.TeleportChargeBag then
        for keys, values in unit.TeleportChargeBag do
            values:Destroy()
        end
        unit.TeleportChargeBag = {}
    end
    if unit.TeleportDestChargeBag then
        for keys, values in unit.TeleportDestChargeBag do
            values:Destroy()
        end
        unit.TeleportDestChargeBag = {}
    end
    if unit.TeleportSoundChargeBag then -- Emptying the sounds so they stop.
        for keys, values in unit.TeleportSoundChargeBag do
            values:Destroy()
        end
        if unit.AmbientSounds then
            unit.AmbientSounds = {} -- For some reason we couldnt simply add this to trash so empyting it like this
        end
        unit.TeleportSoundChargeBag = {}
    end
    EffectsBag:Destroy()

    unit:StopUnitAmbientSound('TeleportChargingAtUnit')
    unit:StopUnitAmbientSound('TeleportChargingAtDestination')
end

function DestroyRemainingTeleportChargingEffects(unit, EffectsBag)
    -- Called when we're done teleporting (because succesfull or cancelled)
    if unit.TeleportCybranSphere then
        unit.TeleportCybranSphere:Destroy()
    end
end
