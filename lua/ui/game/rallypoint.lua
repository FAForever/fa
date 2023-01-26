-----------------------------------------------------------------------
-- File: lua/modules/ui/game/rallypoint.lua
-- Author: Chris Blackwell
-- Summary: Shows the first command in the queue for selected factories
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------------

local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local commandMeshResources = import("/lua/ui/game/commandmeshes.lua").commandMeshResources
local rallyMeshes = import("/lua/ui/game/commandmeshes.lua").rallyMeshes

local meshes = {}
local beatFunctionAdded = false

local function AddRallyPoint(unit)
    local commandQueue = unit:GetCommandQueue()
    local commandOfInterest = commandQueue[table.getn(commandQueue)] -- Last command

    if rallyMeshes[commandOfInterest.type] == nil and commandMeshResources[commandOfInterest.type] == nil then
        return
    end

    local mesh = WorldMesh()
    mesh.unit = unit
    table.insert(meshes, mesh)
    mesh:SetMesh({
        MeshName = rallyMeshes[commandOfInterest.type][1] or commandMeshResources[commandOfInterest.type][1],
        TextureName = rallyMeshes[commandOfInterest.type][2] or commandMeshResources[commandOfInterest.type][2],
        ShaderName = 'RallyPoint',
        UniformScale = 0.10
    })
    mesh:SetLifetimeParameter(10)
    mesh:SetStance(commandOfInterest.position)
    mesh:SetHidden(false)
end

function ClearAllRallyPoints()
    for index, mesh in meshes do
        mesh:Destroy()
    end
    meshes = {}
end

local function OnBeat()
    for index, mesh in meshes do
        if not mesh.unit:IsDead() then
            local commandQueue = mesh.unit:GetCommandQueue()
            mesh:SetStance(commandQueue[table.getn(commandQueue)].position)
        end
    end
end

function OnSelectionChanged(selection)
    if not beatFunctionAdded then
        import("/lua/ui/game/gamemain.lua").AddBeatFunction(OnBeat)
        beatFunctionAdded = true
    end

    ClearAllRallyPoints()

    local factories = EntityCategoryFilterDown(categories.STRUCTURE * categories.FACTORY, selection)
    if factories then
        for _, factory in factories do
            AddRallyPoint(factory)
        end
    end
end
