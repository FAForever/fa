
local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable

---@class CastingPaintMessage
---@field CastingMouse boolean 
---@field Position Vector
---@field Tick number

-- determine if there are observers
local clientCount = table.getn(clients)
local playerCount = 0
for k, data in armies do
    if data.human then
        playerCount = playerCount + 1
    end
end

local localName = ''
for k, client in clients do
    if client['local'] then
        localName = client.name
    end
end

--- Returns a list of clients that are considered observers
---@return number[]
local function GetObserverClients()
    local observers = { }
    for k, client in clients do
        local isPlayer = false
        for l, army in armies do
            if army.nickname == client.name then
                isPlayer = true
            end
        end

        -- do not send to ourself or to players
        if true then -- not isPlayer and client.name != localName
            table.insert(observers, k)
        end
    end

    return observers
end

local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local WorldViewManager = import("/lua/ui/game/worldview.lua")
local meshSphere = '/env/Common/Props/sphere_lod0.scm'

---@type table<WorldMesh, boolean>
local Unused = { }

---@type table<WorldMesh, CastingPaintMessage>
local InUse = { }

---@type table<string, Vector>
local LocationTarget = { }

---@type table<string, Vector>
local Samples = { }

local function AllocateEntity()
    local entity = WorldMesh()
    entity:SetMesh({
        MeshName = meshSphere,
        TextureName = '/meshes/game/Assist_albedo.dds',
        ShaderName = 'FakeRings',
        UniformScale = 1
    })

    return entity
end

--- Sends the mouse position to all observers
---@param Sync any
local function SendData(Sync)

    -- only paint when we hold control (or some other key)
    if not IsKeyDown('Ctrl') then
        return
    end

    -- retrieve position and elevation
    local position = GetMouseWorldPos()
    if not (position and position[1]) then
        return
    end

    ---@type CastingMouseMessage
    local msg = {
        -- identifier used to pass mouse information
        CastingMouse = true,

        -- mouse information
        Position = position,
        Tick = GameTick()
    }

    local clients = GetObserverClients()
    SessionSendChatMessage(clients, msg)
end

--- Processes the mouse position send by players
---@param sender string
---@param info CastingMouseMessage
local function ReceiveData(sender, info)
    Samples[info] = true
end

--- Cleans up previous received mouse data
---@param Sync any
local function ProcessData(Sync)

    local tick = GameTick()

    -- cull old data
    for sample, _ in Samples do
        if tick - sample.Tick < 10 then
            Samples[sample] = nil
        end
    end

    -- populate new data
    for sample, _ in Samples do 
        if tick - sample.Tick == 5 then
            local entity = next(Unused)
            if not entity then
                entity = AllocateEntity()
            end

            InUse[entity] = sample
        end
    end
end

--- Interpolates the mouse position between updates
local function DisplayThread()
    while true do
        for id, entity in Entities do
            local next = LocationTarget[id]
            local curr = LocationCurrent[id]

            local x = next[1] * 0.1 + curr[1] * 0.9
            local y = next[2] * 0.1 + curr[2] * 0.9
            local z = next[3] * 0.1 + curr[3] * 0.9

            local position = {x, y, z}
            LocationCurrent[id] = position

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

-- check conditions for sharing
if clientCount > playerCount then
    LOG("Sharing is caring!")
    AddOnSyncCallback(SendData, 'CastingSendPainting')
    AddOnSyncCallback(ProcessData, 'CastingSend')
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ReceiveData, 'CastingPainting')
    ForkThread(DisplayThread)
end
