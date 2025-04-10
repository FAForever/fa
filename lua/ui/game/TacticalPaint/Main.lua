local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

local LinesCollection = import("LinesCollection.lua").LinesCollection


---@type table<integer, LinesCollection>
local linesHolder = {}


local function GetArmyColor(id)
    return GetArmiesTable().armiesTable[id].color or "ffffffff"
end

function GetLinesCollections()
    return linesHolder
end

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field lifeTime number
---@field color Color


---@param player integer
---@param pos1 Vector
---@param pos2 Vector
function DrawLine(player, pos1, pos2)

    local holder = linesHolder[player]
    if not holder then
        holder = LinesCollection(GetArmyColor(player))
        linesHolder[player] = holder
    end

    holder:Add(pos1, pos2)
end

---@param x number
---@param z number
---@param radiusSq number
---@return boolean
function ClearLinesAt(x, z, radiusSq)
    local removedAny = false

    for player, holder in linesHolder do
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
    if me == id then
        return
    end

    if not (IsObserver() or IsAlly(me, id)) then
        return
    end

    if remove then
        local x, z, offset = data[1], data[2], data[3]
        ClearLinesAt(x, z, offset)
    else
        local holder = linesHolder[id]
        if not holder then
            holder = LinesCollection(GetArmyColor(id))
            linesHolder[id] = holder
        end

        local prevPos = nil
        for i, pos in data do
            if prevPos then
                holder:Add(prevPos, pos)
            end
            prevPos = pos
        end
    end
end

---@param data any
---@param remove boolean
function SendPaintData(data, remove)
    if GetFocusArmy() == -1 then
        local FindClients = import('/lua/ui/game/chat.lua').FindClients
        SessionSendChatMessage(FindClients(), {
            TacticalPaint = true,
            Remove = remove,
            Data = data
        })
        return
    end
    SimCallback({
        Func = "TacticalPaint",
        Args = {
            Data = data,
            Remove = remove,
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
    for player, holder in linesHolder do
        holder:ClearAll()
    end
end

---@param isReplay boolean
function Main(isReplay)

    local KeyMapper = import('/lua/keymap/keymapper.lua')
    KeyMapper.SetUserKeyAction('Open Tactical Paint canvas',
        {
            action = "UI_Lua import('/lua/ui/game/TacticalPaint/Main.lua').TacticalPaint()",
            category = 'Tactical Paint'
        })

    KeyMapper.SetUserKeyAction('Clear canvas',
        {
            action = "UI_Lua import('/lua/ui/game/TacticalPaint/Main.lua').Clear()",
            category = 'Tactical Paint'
        })

    if GetFocusArmy() == -1 then
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
