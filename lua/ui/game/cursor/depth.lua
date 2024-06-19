
local WorldView = import("/lua/ui/game/worldview.lua")
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh

local meshSphere = '/env/Common/Props/sphere_lod0.scm'

local MeshOnTerrain = nil
local MeshOnTerrainRed = nil
local MeshesInBetween = { }
local MaxMeshesInbetweenCount = 5
local MeshFadeDistance = 300

local Trash = TrashBag()

--- Allow player to disable or start thread that shows mouse locations
local option = import("/lua/user/prefs.lua").GetFromCurrentProfile('options.cursor_depth_scanning')
function UpdatePreferenceOption(value)
    option = value
end

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

--- Checks conditions for scanning
local function CheckConditions(CommandMode)

    if WorldView.viewLeft and not WorldView.viewLeft.CursorOverWorld then
        return false
    end

    -- easy picking
    if option == 'on' then
        return true
    end

    if option == 'off' then
        return false
    end

    -- conditions based on command mode
    local info = CommandMode.GetCommandMode()
    local command = info[1]

    if command == 'build' and option == 'building' then
        return true
    end

    if command and option == 'commands' then
        return true
    end

    return false
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
    local f2 = math.clamp(surfaceHeight - terrainHeight - 0.25, 0, 0.5)*2
    return f1 * f2
end

--- Runs a depth scanning process to help the player understand where his cursor 
--- really is (when it is on top of water)
local function DepthScanningThread()

    local scenario = SessionGetScenarioInfo()
    local Exit = import("/lua/ui/override/exit.lua")
    local CommandMode = import("/lua/ui/game/commandmode.lua")
    
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
        ShaderName = 'FakeRings',
        UniformScale = 0.3,
        LODCutoff = MeshFadeDistance
    })
    MeshOnTerrainRed = WorldMesh()
    MeshOnTerrainRed:SetMesh({
        MeshName = meshSphere,
        TextureName = '/meshes/game/Attack_albedo.dds',
        ShaderName = 'FakeRings',
        UniformScale = 0.3,
        LODCutoff = MeshFadeDistance
    })
    
    Trash:Add(MeshOnTerrain)
    Trash:Add(MeshOnTerrainRed)

    -- allocate intermediate bits
    for k = 1, MaxMeshesInbetweenCount do

        local bit = WorldMesh()
        if k == 2 then
            bit:SetMesh({
                MeshName = meshSphere,
                TextureName = '/meshes/game/map-border_squ_cybran_a_SpecTeam.dds',
                ShaderName = 'FakeRings',
                UniformScale = 0.15,
                LODCutoff = MeshFadeDistance
            })
        else
            bit:SetMesh({
                MeshName = meshSphere,
                TextureName = '/meshes/game/Assist_albedo.dds',
                ShaderName = 'FakeRings',
                UniformScale = 0.15,
                LODCutoff = MeshFadeDistance
            })
        end
        
        MeshesInBetween[k] = bit
        Trash:Add(bit)
    end

    -- pre-allocate all locals for performance
    local camera, position, cursor, elevation, transparency, location, info
    location = { }
    while true do

        camera = GetCamera('WorldCamera')
        position = GetMouseWorldPos()
        cursor = GetCursorInformation()
        elevation = cursor.Elevation

        -- check if we have all the data required
        if position and position[1] and cursor and cursor.Elevation and CheckConditions(CommandMode) then
            
            position[1] = math.clamp(position[1], 0, scenario.size[1])
            position[3] = math.clamp(position[3], 0, scenario.size[2])

            -- move with the grid when building
            info = CommandMode.GetCommandMode()
            if info[1] == 'build' then
                position[1] = math.floor(position[1]) + 0.5
                position[3] = math.floor(position[3]) + 0.5
            end

            -- determine location on the terrain
            location[1] = position[1]
            location[2] = elevation
            location[3] = position[3]

            -- update visibility terrain mesh
            transparency = ComputeTransparency(camera, MeshFadeDistance, elevation, position[2])
            if transparency > 0.05 then
                if (position[2] - elevation) > 1.5 then
                    MeshOnTerrain:SetHidden(false)
                    MeshOnTerrain:SetStance(location)
                    MeshOnTerrain:SetFractionCompleteParameter(transparency)
                    MeshOnTerrainRed:SetHidden(true)
                else
                    MeshOnTerrainRed:SetHidden(false)
                    MeshOnTerrainRed:SetStance(location)
                    MeshOnTerrainRed:SetFractionCompleteParameter(transparency)
                    MeshOnTerrain:SetHidden(true)
                end
            else
                MeshOnTerrain:SetHidden(true)
                MeshOnTerrainRed:SetHidden(true)
            end

            -- update visiblity intermediate dots
            for k = 1, MaxMeshesInbetweenCount do
                local bit = MeshesInBetween[k]
                location[2] = position[2] - k*0.5 - (k-1)*0.5 - (k-1)*(k-2) * 0.05 * (position[2] - elevation) -- 1:0.5, 2:1.5, 3-5: scaled based on elevation

                transparency = ComputeTransparency(camera, MeshFadeDistance, elevation, position[2])
                if transparency > 0.05 then
                    bit:SetHidden(false)
                    bit:SetStance(location)
                    bit:SetFractionCompleteParameter(transparency)
                else
                    bit:SetHidden(true)
                end
            end
        else
            -- hide them
            MeshOnTerrain:SetHidden(true)
            MeshOnTerrainRed:SetHidden(true)
            for k = 1, MaxMeshesInbetweenCount do
                MeshesInBetween[k]:SetHidden(true)
            end
        end

        WaitFrames(1)
    end
end

Trash:Add(ForkThread(DepthScanningThread))