
local Prefs = import("/lua/user/prefs.lua")
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local meshSphere = '/env/Common/Props/sphere_lod0.scm'

local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable
local durationInSeconds = 10

local KeyCodeAlt = 18
local KeyCodeCtrl = 17
local KeyCodeShift = 16

local offset = CurrentTime()

---@class CastingPaintMessage
---@field CastingMouse boolean 
---@field Position Vector
---@field Time number

-- determine if there are observers
local clientCount = table.getn(clients)
local playerCount = 0
for k, data in armies do
    if data.human then
        playerCount = playerCount + 1
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
        if not isPlayer then
            table.insert(observers, k)
        end
    end

    return observers
end

local Trash = TrashBag()

---@type table<WorldMesh, boolean>
local Unused = { }

---@type table<WorldMesh, CastingPaintMessage>
local InUse = { }

---@type table<string, Vector>
local Samples = { }

local EntityMesh = {
    MeshName = meshSphere,
    TextureName = '/meshes/game/Assist_albedo.dds',
    ShaderName = 'FakeRings',
    UniformScale = 1.5
}

local function AllocateEntity()
    local entity = WorldMesh()
    entity:SetMesh(EntityMesh)
    return entity
end

--- Sends the mouse position to all observers
---@param Sync any
local function SendData(Sync)

    local lastPosition = { 0, 0, 0 }

    while true do

        WaitSeconds(0.01)

        local key = Prefs.GetFromCurrentProfile('options.casting_painting')
        if key then

            -- only paint when we hold control (or some other key)
            local position = GetMouseWorldPos()
            if IsKeyDown(key) and position and position[1] then
                local dx = lastPosition[1] - position[1]
                local dz = lastPosition[3] - position[3]
                if dx * dx + dz * dz > 1 then
                    lastPosition = position

                    ---@type CastingPaintMessage
                    local msg = {
                        -- identifier used to pass mouse information
                        CastingPaintingRegister = true,

                        -- mouse information
                        Position = position,
                        Time = CurrentTime() - offset
                    }

                    local clients = GetObserverClients()
                    SessionSendChatMessage(clients, msg)
                end
            end
        end
    end
end

--- Processes the mouse position send by players
---@param sender string
---@param info CastingPaintMessage
local function ReceiveData(sender, info)
    Samples[info] = true
end

--- Cleans up previous received mouse data
---@param Sync any
local function ProcessData(Sync)

    while true do

        WaitSeconds(0.01)

        local time = CurrentTime() - offset

        -- populate entities using samples
        for sample, _ in Samples do
            local entity = next(Unused)
            if not entity then
                entity = AllocateEntity()
                Trash:Add(entity)
            end

            entity:SetHidden(false)
            entity:SetStance(sample.Position)
            Samples[sample] = nil
            Unused[entity] = nil
            InUse[entity] = sample
        end

        -- remove old entities
        for entity, sample in InUse do
            if time - sample.Time > durationInSeconds then
                entity:SetHidden(true)
                Unused[entity] = true
                InUse[entity] = nil
            end
        end

        -- update entities
        for entity, sample in InUse do
            entity:SetFractionCompleteParameter(1 - ((time - sample.Time) / durationInSeconds))
        end
    end
end

-- check conditions for sharing
if GetFocusArmy() == -1 then
    ForkThread(SendData)
    ForkThread(ProcessData)
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ReceiveData, 'CastingPaintingRegister')

    local Exit = import("/lua/ui/override/exit.lua")
    Exit.AddOnExitCallback(
        'CastingPainting',
        function()
            Trash:Destroy()
        end
    )
end
