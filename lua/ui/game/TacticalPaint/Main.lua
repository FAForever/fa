local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

local LinesCollection = import("LinesCollection.lua").LinesCollection

local minDist = 0.5

---@type table<integer, LinesCollection>
local linesHolder = {}


local function GetArmyColor(id)
    return GetArmiesTable().armiesTable[id].color or "ffffffff"
end

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field lifeTime number
---@field color Color


---@param player integer
---@param pos1 Vector
---@param pos2 Vector
local function DrawLine(player, pos1, pos2)

    if VDist2(pos1[1], pos1[3], pos2[1], pos2[3]) < minDist / 2 then
        return
    end

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
local function ClearLinesAt(x, z, radiusSq)
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
local function SendPaintData(data, remove)
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

---@class Canvas : Bitmap
---@field _text Text
---@field _collectedLines Line[]
---@field _prevMousePos Vector?
---@field _color Color
Canvas = Class(Bitmap)
{
    ---@param self Canvas
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)
        self._active = false

        local text = UIUtil.CreateText(self, "Tactical Paint", 20, "Arial")
        LayoutFor(text)
            :AtHorizontalCenterIn(self)
            :AtTopIn(self, 100)
            :Over(self)
            :DisableHitTest()

        self._text = text

        self._collectedLines = {}
        self._prevMousePos = nil
    end,

    ---@param self Canvas
    ---@return boolean
    GetActive = function(self)
        return self._active
    end,

    ---@param self Canvas
    ---@param active boolean
    SetActive = function(self, active)
        self._active = active
        if active then
            self:EnableHitTest()
            -- self:SetAlpha(0.1)
            self._text:Show()
        else
            self:DisableHitTest()
            -- self:SetAlpha(0.0)
            self._text:Hide()

            self:OnDrawEnd()
        end
    end,

    ---@param self Canvas
    ---@param delta number
    Render = function(self, delta)
        for player, holder in linesHolder do
            holder:Render(delta)
        end

    end,

    ---@param self Canvas
    SendLines = function(self)
        local lines          = self._collectedLines
        self._collectedLines = {}
        local maxPerPackage  = 20

        local n = table.getn(lines)
        if n > maxPerPackage then
            local numPackages = math.ceil(n / maxPerPackage)
            local packageSize = math.ceil(n / numPackages)

            local lineIndex = 1

            for i = 1, numPackages do
                local package = {}
                for j = lineIndex, lineIndex + packageSize do
                    local pos = lines[j]
                    if pos then
                        table.insert(package, pos)
                    end
                end
                lineIndex = lineIndex + packageSize
                SendPaintData(package, false)
            end
        elseif n > 0 then
            SendPaintData(lines, false)
        end

    end,

    ---@param self Canvas
    OnDrawStart = function(self)
        self._prevMousePos = GetMouseWorldPos()
        table.insert(self._collectedLines, self._prevMousePos)
    end,

    ---@param self Canvas
    ---@param pos Vector
    OnDraw = function(self, pos)
        local prevMouseWorldPos = self._prevMousePos
        if prevMouseWorldPos then
            if VDist2(prevMouseWorldPos[1], prevMouseWorldPos[3], pos[1], pos[3]) > minDist then
                table.insert(self._collectedLines, pos)
                DrawLine(GetFocusArmy(), prevMouseWorldPos, pos)
                self._prevMousePos = pos
            end
        end
    end,

    ---@param self Canvas
    ---@param pos Vector
    ---@param radius number
    OnErase = function(self, pos, radius)
        radius = radius * radius
        local x, z = pos[1], pos[3]
        local wasRemoved = ClearLinesAt(x, z, radius)

        if wasRemoved then
            SendPaintData({ x, z, radius }, true)
        end
    end,

    ---@param self Canvas
    OnDrawEnd = function(self)
        self._prevMousePos = nil
        self:SendLines()
    end,

    ---@param self Canvas
    ---@param worldview WorldView
    ---@param event KeyEvent
    ---@return boolean
    HandleDrawing = function(self, worldview, event)

        local isCanvasActive = self:GetActive()
        if not isCanvasActive then
            return false
        end

        local isEventMotion = event.Type == "MouseMotion"
        local isEventPress = event.Type == "ButtonPress"
        local isEventRelease = event.Type == "ButtonRelease"
        local isModLeft = event.Modifiers.Left
        local isModRight = event.Modifiers.Right

        if isEventRelease or (isEventMotion or isEventPress) and (isModLeft or isModRight) then

            if isEventPress and isModLeft then
                self:OnDrawStart()
            end

            if isEventRelease and not isModLeft then
                self:OnDrawEnd()
            end

            if isEventMotion then
                local pos = GetMouseWorldPos()

                if isModLeft then
                    self:OnDraw(pos)
                elseif isModRight then
                    local offset = GetCamera(worldview._cameraName):GetZoom() / 50
                    self:OnErase(pos, offset)
                end
            end

            return true
        end
        return false
    end,


}

function TacticalPaint()

    ---@type WorldView
    local viewleft = import("/lua/ui/game/worldview.lua").viewLeft
    viewleft:SetCustomRender(true)

    ---@type Canvas?
    local canvas = viewleft._canvas
    if not canvas then
        viewleft._canvas = Canvas(viewleft)
        canvas = viewleft._canvas
        LayoutFor(canvas)
            :Fill(viewleft)
            :ResetWidth()
            :ResetHeight()
            :Over(viewleft)
            :EnableHitTest()

    end
    canvas:SetActive(not canvas:GetActive())

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

    local WorldView = import("/lua/ui/controls/worldview.lua").WorldView

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

    local WorldViewOnRender = WorldView.OnRenderWorld
    WorldView.OnRenderWorld = function(self, delta)
        local canvas = self._canvas
        if canvas then
            canvas:Render(delta)
        end
        return WorldViewOnRender(self, delta)
    end

    local WVH = WorldView.HandleEvent
    ---@param self WorldView
    ---@param event KeyEvent
    WorldView.HandleEvent = function(self, event)
        local canvas = self._canvas
        return canvas and canvas:HandleDrawing(self, event) or WVH(self, event)
    end
end
