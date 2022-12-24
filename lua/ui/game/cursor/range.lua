
local Prefs = import("/lua/user/prefs.lua")
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local Gamemain = import("/lua/ui/game/gamemain.lua")

local hashedSelection = { }
Gamemain.ObserveSelection:AddObserver(
    function(data)
        -- clear out previous hashed selection
        for k, v in hashedSelection do
            hashedSelection[k] = nil
        end

        -- create new hashed selection
        for k, v in data.newSelection do
            local blueprint = v:GetBlueprint()
            local id = blueprint.BlueprintId
            if not hashedSelection[id] then
                hashedSelection[id] = blueprint
            end
        end
    end
)

local meshSphere = '/meshes/game/PathRing_LOD0.scm'
local MeshOnTerrain, MeshOnSurface = nil, nil
local MeshFadeDistance = 300
local Trash = TrashBag()

--- Retrieves cursor information from the engine statistics
---@return table
local function GetCursorInformation()
    local cursor = { }
    if __EngineStats and __EngineStats.Children then
        for _, a in __EngineStats.Children do
            if a.Name == 'Camera' then
                for _, b in a.Children do
                    if b.Name == 'Cursor' then
                        for _, c in b.Children do
                            cursor[c.Name] = c.Value
                        end
                        break
                    end
                end
            end
        end
    end

    return cursor
end

---@return number?
local function FindReclaimRange()
    local largest = nil
    for id, blueprint in hashedSelection do
        local radius = blueprint.Economy.MaxBuildDistance
        if radius then
            if not largest then
                largest = radius
            elseif radius > largest then
                largest = radius
            end
        end
    end

    return largest
end

---@return number?
local function FindDirectAttackRange()

end

---@return number?
local function FindIndirectAttackRange()

end

--- Defines the transparency curve
---@param camera Camera
---@param distance number
---@param terrainHeight number
---@param surfaceHeight number
---@return number
local function ComputeTransparency(camera, distance, terrainHeight, surfaceHeight)
    -- visibility based on camera distance
    local zoom = camera:GetZoom()
    local f1 = math.max(0, 1 - (zoom / distance))

    return f1
end

--- Runs a depth scanning process to help the player understand where his cursor 
--- really is (when it is on top of water)
local function Thread()

    local scenario = SessionGetScenarioInfo()
    local Exit = import("/lua/ui/override/exit.lua")
    
    -- clear out all entities before we exit
    Exit.AddOnExitCallback(
        'HoverScanning',
        function(event)
            Trash:Destroy()
        end
    )

    -- allocate mesh that is on the terrain
    MeshOnTerrain = WorldMesh()
    MeshOnTerrain:SetMesh({
        MeshName = meshSphere,
        TextureName = '/meshes/game/Assist_albedo.dds',
        ShaderName = 'FakeRingsNoDepth',
        UniformScale = 1.0,
        LODCutoff = MeshFadeDistance
    })

    MeshOnSurface = WorldMesh()
    MeshOnSurface:SetMesh({
        MeshName = meshSphere,
        TextureName = '/meshes/game/Assist_albedo.dds',
        ShaderName = 'FakeRingsNoDepth',
        UniformScale = 1.0,
        LODCutoff = MeshFadeDistance
    })

    Trash:Add(MeshOnSurface)
    Trash:Add(MeshOnTerrain)

    -- pre-allocate all locals for performance
    local camera, surface, cursor, elevation, transparency
    terrain = { }
    while true do

        camera = GetCamera('WorldCamera')
        surface = GetMouseWorldPos()
        cursor = GetCursorInformation()
        elevation = cursor.Elevation

        local reclaimRange = FindReclaimRange();

        -- check if we have all the data required
        if reclaimRange and surface and surface[1] and cursor and cursor.Elevation then -- and CheckConditions(CommandMode)

            reclaimRange = 0.035 * (reclaimRange + 2)
            transparency = ComputeTransparency(camera, MeshFadeDistance, elevation, surface[2])

            surface[1] = math.clamp(surface[1], 0, scenario.size[1])
            surface[2] = math.clamp(surface[2], 0, 255)
            surface[3] = math.clamp(surface[3], 0, scenario.size[2])

            terrain[1] = surface[1]
            terrain[2] = elevation
            terrain[3] = surface[3]

            if transparency > 0.05 then
                MeshOnTerrain:SetHidden(false)
                MeshOnTerrain:SetStance(terrain)
                MeshOnTerrain:SetFractionCompleteParameter(transparency)
                MeshOnTerrain:SetScale({reclaimRange, 1, reclaimRange})

                MeshOnSurface:SetHidden(false)
                MeshOnSurface:SetStance(surface)
                MeshOnSurface:SetFractionCompleteParameter(transparency)
                MeshOnSurface:SetScale({reclaimRange, 1, reclaimRange})
            else
                MeshOnTerrain:SetHidden(true)
                MeshOnSurface:SetHidden(true)
            end


        else
            -- hide them
            MeshOnTerrain:SetHidden(true)
            MeshOnSurface:SetHidden(true)
        end

        WaitFrames(1)
    end
end

Trash:Add(ForkThread(Thread))

-- is run in the old context
__moduleinfo.OnDirty = function()
    Trash:Destroy()
    ForkThread(
        function()
            WaitSeconds(0.1)
            import("/lua/ui/game/cursor/range.lua")
        end
    )

    LOG("OnDirty")
end

-- is run in the new context
__moduleinfo.OnReload = function(old)
    Trash:Add(ForkThread(Thread))
    LOG("OnReload")
end