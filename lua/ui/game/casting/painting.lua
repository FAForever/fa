
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local WorldViewManager = import("/lua/ui/game/worldview.lua")
local meshSphere = '/env/Common/Props/sphere_lod0.scm'

local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable
local durationInTicks = 100

---@class CastingPaintingRegister
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

---@type table<WorldMesh, boolean>
local Unused = { }

---@type table<WorldMesh, CastingPaintMessage>
local InUse = { }

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
    if not IsKeyDown(17) then
        return
    end

    -- retrieve position and elevation
    local position = GetMouseWorldPos()
    if not (position and position[1]) then
        return
    end

    ---@type CastingPaintMessage
    local msg = {
        -- identifier used to pass mouse information
        CastingPaintingRegister = true,

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

    -- remove old samples
    for sample, _ in Samples do
        if tick - sample.Tick > 10 then
            Samples[sample] = nil
        end
    end

    -- populate entities using samples
    for sample, _ in Samples do
        if tick - sample.Tick == 5 then
            local entity = next(Unused)
            if not entity then
                entity = AllocateEntity()
            end

            entity:SetHidden(false)
            entity:SetStance(sample.Position)
            Unused[entity] = nil
            InUse[entity] = sample
        end
    end

    -- remove old entities
    for entity, sample in InUse do
        if tick - sample.Tick > durationInTicks then
            entity:SetHidden(true)
            Unused[entity] = true
            InUse[entity] = nil
        end
    end
end

--- Interpolates the mouse position between updates
local function DisplayThread()
    while true do
        local tick = GameTick()
        for entity, sample in InUse do
            entity:SetFractionCompleteParameter(1 - ((tick - sample.Tick + 5) / durationInTicks))
        end
        WaitFrames(1)
    end
end

-- check conditions for sharing
if clientCount > playerCount then
    LOG("Sharing is caring!")
    AddOnSyncCallback(SendData, 'CastingPaintingSend')
    AddOnSyncCallback(ProcessData, 'CastingPaintingProcess')
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ReceiveData, 'CastingPaintingRegister')
    ForkThread(DisplayThread)
end
