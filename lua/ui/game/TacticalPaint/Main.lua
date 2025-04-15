local Prefs = import('/lua/user/prefs.lua')
local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

local LinesCollection = import("LinesCollection.lua").LinesCollection


---@type table<integer, LinesCollection>
local collectionsTable = {}


local function GetArmyColor(id)
    return GetArmiesTable().armiesTable[id].color or "ffffffff"
end

function GetLinesCollections()
    return collectionsTable
end

---@param id integer
---@return LinesCollection
function GetCollection(id)
    local collection = collectionsTable[id]
    if not collection then
        collection = LinesCollection(GetArmyColor(id))
        collectionsTable[id] = collection
    end
    return collection
end

---@param id integer
---@param pos1 Vector
---@param pos2 Vector
function DrawLine(id, pos1, pos2)
    local lifetime = Prefs.GetFromCurrentProfile('options.tpaint_lifetime') or 20
    GetCollection(id):Add(pos1, pos2, lifetime + GetGameTimeSeconds())
end

---@param x number
---@param z number
---@param radiusSq number
---@return boolean
function ClearLinesAt(x, z, radiusSq)
    local removedAny = false

    for player, holder in collectionsTable do
        removedAny = removedAny or holder:ClearLinesAt(x, z, radiusSq)
    end

    return removedAny
end

---@param id integer
---@param tdata TacticalPaintData
local function ProcessPaintData(id, tdata)
    local data = tdata.Data
    local remove = tdata.Remove
    local me = GetFocusArmy()
    -- reprsl(GetArmiesTable())
    if me == id and me ~= -1 then
        return
    end

    if not (IsObserver() or IsAlly(me, id)) then
        return
    end

    if remove then
        local x, z, offset = data[1], data[2], data[3]
        ClearLinesAt(x, z, offset)
    else
        local collection = GetCollection(id)
        local lifeTime = tdata.LifeTime

        local prevPos = nil
        for i, pos in data do
            if prevPos then
                collection:Add(prevPos, pos, lifeTime)
            end
            prevPos = pos
        end
    end
end

---@param data any
---@param remove boolean
function SendPaintData(data, remove)
    local lifetime = Prefs.GetFromCurrentProfile('options.tpaint_lifetime') or 20

    if IsObserver() then
        local FindClients = import('/lua/ui/game/chat.lua').FindClients
        SessionSendChatMessage(FindClients(), {
            TacticalPaint = true,
            Remove = remove,
            Data = data,
            LifeTime = lifetime + GetGameTimeSeconds()
        })
        return
    end
    SimCallback({
        Func = "TacticalPaint",
        Args = {
            Data = data,
            Remove = remove,
            LifeTime = lifetime + GetGameTimeSeconds()
        },
    })
end

---@param syncData SyncTacticalPaintData
function ProcessSyncPaintData(syncData)
    for i, data in pairs(syncData) do
        for _, samples in data do
            ProcessPaintData(i, samples)
        end
    end
end

---@param id integer
---@param state boolean
function SetSourceEnabled(id, state)
    local collection = GetCollection(id)

    collection:SetEnabled(state)
end

function TacticalPaint()

    local views = import("/lua/ui/game/worldview.lua").GetWorldViews()
    for _, view in views do
        ---@type Canvas?
        local canvas = view._canvas
        if canvas then
            canvas:SetActive(not canvas:GetActive())
        end
    end

    -- if canvas:GetActive() then
    --     local EscapeHandler = import('/lua/ui/dialogs/eschandler.lua')
    --     EscapeHandler.PushEscapeHandler(function()
    --         canvas:SetActive(false)
    --     end)
    -- end

end

function Clear()
    for player, holder in collectionsTable do
        holder:ClearAll()
    end
end

local isEnabled = false
local lock = false
local function UnlockThread()
    lock = false
    WaitSeconds(0.5)
    while lock do
        lock = false
        WaitFrames(5)
    end
    isEnabled = false
    local views = import("/lua/ui/game/worldview.lua").GetWorldViews()
    for _, view in views do
        ---@type Canvas?
        local canvas = view._canvas
        if canvas then
            canvas:SetActive(false)
        end
    end
end

function OnHold()
    lock = true
    if isEnabled then
        return
    end
    isEnabled = true

    local views = import("/lua/ui/game/worldview.lua").GetWorldViews()
    for _, view in views do
        ---@type Canvas?
        local canvas = view._canvas
        if canvas then
            canvas:SetActive(true)
        end
    end

    ForkThread(UnlockThread)
end

---@param isReplay boolean
function Main(isReplay)
    if IsObserver() then
        import('/lua/ui/game/gamemain.lua').RegisterChatFunc(function(sender, data)
            for i, armyData in GetArmiesTable().armiesTable do
                if armyData.nickname == sender then
                    return
                end
            end
            ProcessPaintData(-1, data)
        end, 'TacticalPaint')
    end
end
