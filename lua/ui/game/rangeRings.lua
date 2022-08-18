
local meshSphere = '/env/Common/Props/sphere_lod0.scm'
local meshCircularRing = '/meshes/game/PathRing_LOD0.scm'
local meshSquareRing = '/meshes/game/PathSquare_LOD0.scm'
local meshCylinder = '/meshes/game/PathCylinder_LOD0.scm'

function CreateTestRings(trash)

    local cam = GetCamera('WorldCamera')
    local WorldMesh = import('/lua/ui/controls/worldmesh.lua').WorldMesh



    local function TransparencyBasedOnDepth(mesh, distance)
        local zoom = cam:GetZoom()
        local fraction = math.max(0, 1 - (zoom / distance))
        mesh:SetFractionCompleteParameter(fraction)
    end

    local function Depth()

        local terrain = WorldMesh()
        terrain:SetMesh({
            MeshName = meshSphere,
            TextureName = '/meshes/game/Assist_albedo.dds',
            ShaderName = 'FakeRings',
            UniformScale = 0.3
        })
        
        terrain:SetFractionCompleteParameter(0.5)
        terrain:SetHidden(false)
        trash:Add(terrain)

        local bits = { }
        for k = 1, 4 do 
            local bit = WorldMesh()
            table.insert(bits, bit)
            trash:Add(bit)

            bit:SetMesh({
                MeshName = meshSphere,
                TextureName = '/meshes/game/Assist_albedo.dds',
                ShaderName = 'FakeRings',
                UniformScale = 0.15
            })
            bit:SetFractionCompleteParameter(0.5)
            bit:SetHidden(false)
        end
        

        while true do 
            local cursor = GetCursorInformation()
            local position = GetMouseWorldPos()
            if position and position[1] and next(cursor) then


                if position[2] > cursor.Elevation + 0.1 then

                    -- show them
                    terrain:SetHidden(false)
                    for k = 1, 4 do
                        bits[k]:SetHidden(false)
                    end

                    -- determine location on the terrain
                    local location = {
                        position[1],
                        cursor.Elevation,
                        position[3]
                    }

                    terrain:SetStance(location)
                    TransparencyBasedOnDepth(terrain, 200)

                    -- determine intermediate locations
                    for k = 1, 4 do 
                        local bit = bits[k]
                        local bitLocation = {
                            position[1],
                            (k / 5) * position[2] + (1 - k / 5) * cursor.Elevation,
                            position[3]
                        }

                        bit:SetStance(bitLocation)
                        TransparencyBasedOnDepth(bit, 200)
                    end
                else 

                    -- hide them
                    terrain:SetHidden(true)
                    for k = 1, 4 do 
                        bits[k]:SetHidden(true)
                    end
                end

            end

            WaitFrames(1)
        end
    end


    local function Grid()

        local size = 4
        local longestDistance = math.sqrt(size * size + size * size)


        local cells = { }
        for y = -size, size do 
            cells[y] = { }
            for x = -size, size do 

                local mesh = WorldMesh()
                mesh:SetMesh({
                    MeshName = meshSquareRing,
                    TextureName = '/meshes/game/Assist_albedo.dds',
                    ShaderName = 'FakeRingsNoDepth',
                    UniformScale = 0.015
                })
                mesh:SetFractionCompleteParameter(0.5)
                mesh:SetHidden(false)
                trash:Add(mesh)

                cells[y][x] = mesh
            end
        end

        while true do 
            local cursor = GetCursorInformation()
            local position = GetMouseWorldPos()
            local floored = {
                math.floor(position[1]),
                position[2],
                math.floor(position[3]),
            }

            if position then

                local zoom = cam:GetZoom()
                local fraction = math.max(0, 1 - (zoom / 250.0))

                for y = -size, size do 
                    for x = -size, size do 
                        local mesh = cells[y][x]
                        local location = {
                            floored[1] + x + 0.5,
                            floored[2],
                            floored[3] + y + 0.5
                        }
                        mesh:SetStance(location)

                        local dx = (position[1] - location[1])
                        local dz = (position[3] - location[3])
                        local d = 1 - math.sqrt(dx * dx + dz * dz) / longestDistance
                        local param = math.max(0, d) * fraction 
                        -- LOG(param)
                        mesh:SetFractionCompleteParameter(d * fraction)
                    end
                end
            end

            WaitFrames(1)
        end
    end

    local function TestRings()


        local cam = GetCamera('WorldCamera')



        local terrainCircle = WorldMesh()


        local surfaceCircle = WorldMesh()
        surfaceCircle:SetMesh({
            MeshName = '/meshes/game/PathRing_LOD0.scm',
            TextureName = '/meshes/game/Rally_albedo.dds',
            ShaderName = 'FakeRings',
            UniformScale = 0.2
        })
        surfaceCircle:SetFractionCompleteParameter(0.5)
        surfaceCircle:SetHidden(false)
        trash:Add(surfaceCircle)


    end

    local fork = ForkThread (function() end)

    trash:Add(fork)
    return fork
end