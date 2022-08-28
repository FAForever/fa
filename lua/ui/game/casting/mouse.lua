
local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable

---@class CastingMouseData
---@field [1] number # x coordinate
---@field [2] number # y coordinate
---@field [3] number # z coordinate
---@field [4] number # elevation

---@class CastingMouseMessage
---@field CastingMouse boolean 
---@field data  CastingMouseData

-- determine if there are observers
local clientCount = table.getn(clients)
local playerCount = 0
for k, data in armies do
    if data.human then
        playerCount = playerCount + 1
    end
end

--- Returns the terrain elevation on the mouse position, hefty function at the moment
---@return number
local function GetMouseElevation ()
    if __EngineStats and __EngineStats.Children then
        for _, a in __EngineStats.Children do
            if a.Name == 'Camera' then
                for _, b in a.Children do
                    if b.Name == 'Cursor' then
                        for _, c in b.Children do
                            if c.Name == 'Elevation' then
                                return c.Value
                            end
                        end
                    end
                end
            end
        end
    end

    return 0
end

--- Returns a list of clients that are considered observers
---@return number[]
local function GetObserverClients()

    local observers = { 1 }
    for k, client in clients do
        local isPlayer = false
        for l, army in armies do
            if army.nickname == client.name then
                isPlayer = true
            end
        end

        if not isPlayer then
            table.insert(observers, k)
        end
    end

    return observers
end

local UIUtil = import('/lua/ui/uiutil.lua')
local WorldMesh = import('/lua/ui/controls/worldmesh.lua').WorldMesh
local WorldViewManager = import('/lua/ui/game/worldview.lua')
local meshSphere = '/env/Common/Props/sphere_lod0.scm'

---@type WorldMesh[]
local Entities = { }

---@type Control[]
local Labels = { }

---@type number
local LastUpdate = 0

---@type table<string, Vector>
local LocationsNext = { }

---@type table<string, Vector>
local LocationsCurr = { }

--- Processes the mouse position send by players
---@param sender string
local function ProcessMouse(sender, info)

    -- prepare first time data is send
    if not Entities[sender] then
        Entities[sender] = WorldMesh()
        Entities[sender]:SetMesh({
            MeshName = meshSphere,
            TextureName = '/meshes/game/Assist_albedo.dds',
            ShaderName = 'FakeRings',
            UniformScale = 1
        })

        Entities[sender]:SetStance(info.Position)
        Entities[sender]:SetHidden(false)

        Labels[sender] = UIUtil.CreateText(GetFrame(0), sender, 12, UIUtil.bodyFont, true)
        Labels[sender].Left:Set(-100)
        Labels[sender].Top:Set(-100)

        LocationsNext[sender] = info.Position
        LocationsCurr[sender] = info.Position
    end

    LastUpdate = GetGameTimeSeconds()
    LocationsCurr[sender] = LocationsNext[sender]
    LocationsNext[sender] = info.Position

    -- local label = labels[sender]
    -- local screen = UnProject({data[1], data[2], data[3]})
end

--- Sends the mouse position to observers
local function SendMouse()

    -- retrieve position and elevation
    local position = GetMouseWorldPos()
    local elevation = GetMouseElevation()

    -- do not send nils
    if position and position[1] then

        ---@type CastingMouseMessage
        local msg = {
            -- identifier used to pass mouse information
            CastingMouse = true,

            -- mouse information
            Position = position,
            Time = GetGameTime()
        }

        SessionSendChatMessage(GetObserverClients(), msg)
    end
end

--- Interpolates the mouse position between updates
local function DisplayMouseThread()
    while true do 

        local time = GetGameTimeSeconds()
        for id, entity in Entities do

            -- determine interpolated position
            local diff = 10 * (time - LastUpdate)
            if diff > 1 then
                diff = 1
            end
            local curr = LocationsCurr[id]
            local next = LocationsNext[id]

            local x = next[1] * diff + curr[1] * (1 - diff)
            local y = next[2] * diff + curr[2] * (1 - diff)
            local z = next[3] * diff + curr[3] * (1 - diff)

            local position = {x, y, z}

            -- update everything

            if x and y and z then
                entity:SetStance(position)

                local label = Labels[id]
                local screen = WorldViewManager.viewLeft:Project(position)
                label.Left:Set(screen[1] - 0.5 * label.Width())
                label.Top:Set(screen[2] - 30)
            end
        end

        WaitFrames(1)
    end
end

if clientCount > playerCount or true then
    AddOnSyncCallback(SendMouse, 'CastingMouse')
    import('/lua/ui/game/gamemain.lua').RegisterChatFunc(ProcessMouse, 'CastingMouse')
    ForkThread(DisplayMouseThread)
end
