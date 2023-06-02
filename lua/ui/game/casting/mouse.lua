
local clients = GetSessionClients()
local armies = GetArmiesTable().armiesTable

---@class CastingMouseMessage
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
        if not isPlayer and client.name != localName then
            table.insert(observers, k)
        end
    end

    return observers
end

local UIUtil = import("/lua/ui/uiutil.lua")
local WorldMesh = import("/lua/ui/controls/worldmesh.lua").WorldMesh
local WorldViewManager = import("/lua/ui/game/worldview.lua")
local meshSphere = '/env/Common/Props/sphere_lod0.scm'

---@type WorldMesh[]
local Entities = { }

---@type Control[]
local Labels = { }

---@type table<string, Vector>
local LocationCurrent = { }

---@type table<string, Vector>
local LocationTarget = { }

---@type table<string, Vector>
local Locations = { }

--- Processes the mouse position send by players
---@param sender string
---@param info CastingMouseMessage
local function ProcessData(sender, info)

    -- prepare first time data is send
    if not Entities[sender] then

        -- create a mesh
        Entities[sender] = WorldMesh()
        Entities[sender]:SetMesh({
            MeshName = meshSphere,
            TextureName = '/meshes/game/Assist_albedo.dds',
            ShaderName = 'FakeRings',
            UniformScale = 1
        })

        Entities[sender]:SetStance(info.Position)
        Entities[sender]:SetHidden(false)

        -- create a label
        Labels[sender] = UIUtil.CreateText(GetFrame(0), sender, 12, UIUtil.bodyFont, true)
        Labels[sender].Left:Set(-100)
        Labels[sender].Top:Set(-100)

        -- set state
        LocationCurrent[sender] = info.Position
        LocationTarget[sender] = info.Position
        Locations[sender] = { }
    end

    -- keep track of it
    table.insert(Locations[sender], info)
end

--- Cleans up previous received mouse data
---@param Sync any
local function CleanupData(Sync)

    local tick = GameTick()

    -- cull old data
    local newLocations = { }
    for sender, data in Locations do
        newLocations[sender] = { }
        
        for k, info in data do 
            if tick - info.Tick < 10 then
                table.insert(newLocations[sender], info)
            end
        end
    end

    -- find sample of five ticks ago
    local tick = GameTick()
    for sender, data in newLocations do
        for k, info in data do
            if tick - info.Tick == 5 then
                LocationTarget[sender] = info.Position
            end
        end
    end

    Locations = newLocations
end

--- Sends the mouse position to all observers
---@param Sync any
local function SendData(Sync)

    -- retrieve position and elevation
    local position = GetMouseWorldPos()
    local clients = GetObserverClients()

    -- TODO: add check if we've actually moved the mouse

    -- do not send nils
    if position and position[1] and table.getn(clients) > 0 then

        ---@type CastingMouseMessage
        local msg = {
            -- identifier used to pass mouse information
            CastingMouse = true,

            -- mouse information
            Position = position,
            Tick = GameTick()
        }

        SessionSendChatMessage(clients, msg)
    end
end

--- Allow player to disable or start thread that shows mouse locations
local displayRendering = import("/lua/user/prefs.lua").GetFromCurrentProfile('options.share_mouse')
function UpdatePreferenceOption(value)
    displayRendering = value

    if value == 'on' then
        for id, entity in Entities do
            entity:SetHidden(false)
            Labels[id]:Show()
        end
    else
        for id, entity in Entities do
            entity:SetHidden(true)
            Labels[id]:Hide()
        end
    end
end

--- Interpolates the mouse position between updates
local function DisplayThread()

    -- update with existing value to initially show / hide the mesh and controls
    UpdatePreferenceOption(displayRendering)

    while true do
        if displayRendering == 'on' then
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
                    label.Left:SetValue(screen[1] - 0.5 * label.Width())
                    label.Top:SetValue(screen[2] - 30)
                end
            end

            -- interpolate position each frame
            WaitFrames(1)
        else
            -- wait a few frames before checking again
            WaitFrames(100)
        end
    end
end

-- check conditions for sharing
if clientCount > playerCount then
    AddOnSyncCallback(SendData, 'SendingCastingMouse')
    AddOnSyncCallback(CleanupData, 'ProcessingCastingMouse')
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ProcessData, 'CastingMouse')
    ForkThread(DisplayThread)
end
