
local Prefs = import("/lua/user/prefs.lua")
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh

local meshSphere = '/env/Common/Props/sphere_lod0.scm'
local meshCylinder = '/meshes/game/PathRing_LOD0.scm'

local MeshCylinder = nil
local MeshOnTerrain = nil
local MeshesInBetween = { }
local MeshesInbetweenCount = 4
local MeshFadeDistance = 300

local Trash = TrashBag()
local Selection = { }

--- Checks conditions for scanning
local function CheckConditions()
    local option = Prefs.GetFromCurrentProfile('options.cursor_hover_scanning')

    -- easy picking
    if option == 'on' then
        return true
    end

    if option == 'off' then
        return false
    end

    return true
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

    -- visibility based on terrain difference
    local f2 = math.clamp(surfaceHeight - terrainHeight - 1, 0, 1)
    return f1
end

--- Runs a depth scanning process to help the player understand where his cursor 
--- really is (when it is on top of water)
local function HoverScanningThread()

    local scenario = SessionGetScenarioInfo()
    local Exit = import("/lua/ui/override/exit.lua")
    
    -- clear out all entities before we exit
    Exit.AddOnExitCallback(
        'HoverScanning',
        function(event)
            Trash:Destroy()
        end
    )

    -- keep track of the current selection
    import("/lua/ui/game/gamemain.lua").ObserveSelection:AddObserver(
        function(selectionData)
            Selection = selectionData.newSelection
        end
    )

    -- allocate mesh that is on the terrain
    MeshOnTerrain = WorldMesh()
    MeshOnTerrain:SetMesh({
        MeshName = meshSphere,
        TextureName = '/meshes/game/Assist_albedo.dds',
        ShaderName = 'FakeRings',
        UniformScale = 0.3,
        LODCutoff = MeshFadeDistance
    })

    MeshCylinder = WorldMesh()
    MeshCylinder:SetMesh({
        MeshName = meshCylinder,
        TextureName = '/meshes/game/Assist_albedo.dds',
        ShaderName = 'FakeRings',
        UniformScale = 0.3,
        LODCutoff = MeshFadeDistance
    })

    Trash:Add(MeshOnTerrain)

    -- allocate intermediate bits
    for k = 1, MeshesInbetweenCount do

        local bit = WorldMesh()
        bit:SetMesh({
            MeshName = meshSphere,
            TextureName = '/meshes/game/Assist_albedo.dds',
            ShaderName = 'FakeRings',
            UniformScale = 0.15,
            LODCutoff = MeshFadeDistance
        })

        MeshesInBetween[k] = bit
        Trash:Add(bit)
    end

    -- pre-allocate all locals for performance
    local camera, position, elevation, transparency, location, size
    location = { }
    while true do
        
        -- hide by default
        MeshCylinder:SetHidden(true)
        MeshOnTerrain:SetHidden(true)
        for k = 1, MeshesInbetweenCount do
            MeshesInBetween[k]:SetHidden(true)
        end

        -- only works if we have 1 selected unit
        if Selection[1] and not Selection[2] then

            -- only works for bombers
            local bomber = Selection[1]
            local blueprint = bomber:GetBlueprint()
            if blueprint.CategoriesHash['BOMBER'] then

                camera = GetCamera('WorldCamera')
                position = GetMouseWorldPos()
                elevation = blueprint.Physics.Elevation
                size = 0.1 * (blueprint.SizeSphere or math.max(blueprint.SizeX or 1, blueprint.SizeY or 1, blueprint.SizeZ or 1))

                -- check if we have all the data required
                if position and position[1] and elevation and size and CheckConditions() then

                    position[1] = math.clamp(position[1], 0, scenario.size[1])
                    position[3] = math.clamp(position[3], 0, scenario.size[2])

                    -- determine location on the terrain
                    location[1] = position[1]
                    location[2] = position[2] + elevation
                    location[3] = position[3]

                    -- update visibility terrain mesh
                    transparency = ComputeTransparency(camera, MeshFadeDistance, elevation, position[2])
                    if transparency > 0.05 then
                        MeshOnTerrain:SetHidden(false)
                        MeshOnTerrain:SetStance(location)
                        MeshOnTerrain:SetFractionCompleteParameter(transparency)

                        MeshCylinder:SetHidden(false)
                        MeshCylinder:SetStance(location)
                        MeshCylinder:SetFractionCompleteParameter(transparency)
                        MeshCylinder:SetScale({size, 1, size})
                    else
                        MeshOnTerrain:SetHidden(true)
                        MeshCylinder:SetHidden(true)
                    end

                    -- update visiblity intermediate dots
                    for k = 1, MeshesInbetweenCount do
                        local bit = MeshesInBetween[k]
                        location[2] = position[2] + (0.2 * k) * elevation

                        transparency = ComputeTransparency(camera, MeshFadeDistance, elevation, position[2])
                        if transparency > 0.05 then
                            bit:SetHidden(false)
                            bit:SetStance(location)
                            bit:SetFractionCompleteParameter(transparency)
                        else
                            bit:SetHidden(true)
                        end
                    end
                end
            end
        end

        WaitFrames(1)
    end
end

-- Trash:Add(ForkThread(HoverScanningThread))