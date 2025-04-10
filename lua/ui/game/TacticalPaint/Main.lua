local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Prefs = import('/lua/user/prefs.lua')
local UI_DrawLine = UI_DrawLine

local minDist = 0.5
local maxLinesPerPlayer = 1000

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field createdAt number
---@field color Color

---@class PlayerLinesHolder
---@field _lines Line[]
---@field _color Color
---@field _i integer
---@field _curLines integer
---@field _frameTime number
local PlayerLinesHolder = Class()
{
    ---@param self PlayerLinesHolder
    ---@param color Color
    __init = function(self, color)
        self._lines = {}
        self._color = color
        self._i = 1
        self._curLines = 0
        self._frameTime = 0
    end,

    ---@param self PlayerLinesHolder
    ---@param pos1 Vector
    ---@param pos2 Vector
    Add = function(self, pos1, pos2)
        self._lines[self._i] = {
            p1 = pos1,
            p2 = pos2,
            createdAt = self._frameTime
            --"aa" .. string.sub(color, 3),
            -- lifeTime = Prefs.GetFromCurrentProfile('options')['TPaint_lifetime']
        }
        self._i = self._i + 1
        self._curLines = self._curLines + 1

        if self._curLines > maxLinesPerPlayer then
            self:RemoveOldestLines(self._curLines - maxLinesPerPlayer)
        end
    end,

    ---@param self PlayerLinesHolder
    Remove = function(self, i)
        self._lines[i] = nil
        self._curLines = self._curLines - 1
    end,

    ---@param self PlayerLinesHolder
    RemoveOldestLine = function(self)
        local k, min = nil, self._frameTime
        for i, line in self._lines do
            local lineCreatedTime = line.createdAt
            if lineCreatedTime < min then
                min = lineCreatedTime
                k = i
            end
        end
        if k ~= nil then
            self:Remove(k)
        end
    end,

    ---@param self PlayerLinesHolder
    ---@param n integer
    RemoveOldestLines = function(self, n)
        for i = 1, n do
            self:RemoveOldestLine()
        end
    end,

    ---@param self PlayerLinesHolder
    ---@param delta number
    Render = function(self, delta)
        local color       = self._color
        local UI_DrawLine = UI_DrawLine

        for _, line in self._lines do
            UI_DrawLine(line.p1, line.p2, color, 0.15)
        end

        self._frameTime = self._frameTime + delta
    end,

    ---@param self PlayerLinesHolder
    ---@param x number
    ---@param z number
    ---@param radiusSq number
    ---@return boolean
    ClearLinesAt = function(self, x, z, radiusSq)
        local lines = self._lines
        local removedAny = false
        for j, line in lines do
            local p1 = line.p1
            local p2 = line.p2

            local dx = p1[1] - x
            local dz = p1[3] - z
            local distSq = dx * dx + dz * dz
            if distSq < radiusSq then
                removedAny = true
                self:Remove(j)
            else
                dx     = p2[1] - x
                dz     = p2[3] - z
                distSq = dx * dx + dz * dz
                if distSq < radiusSq then
                    removedAny = true
                    self:Remove(j)
                end
            end
        end
        return removedAny
    end,

    ---@param self PlayerLinesHolder
    ClearAll = function(self)
        local lines = self._lines
        for j in lines do
            lines[j] = nil
        end
        self._i = 1
        self._curLines = 0
        self._frameTime = 0
    end
}

---@type table<string, PlayerLinesHolder>
local linesHolder = {}



function isObs(nickname)
    for _, player in GetArmiesTable().armiesTable do
        if player.nickname == nickname then
            return false
        end
    end
    return true
end

function getArmyColor(nickname)
    if nickname then
        for _, player in GetArmiesTable().armiesTable do
            if player.nickname == nickname then
                return player.color
            end
        end
    end
    local me = GetFocusArmy()

    return GetArmiesTable().armiesTable[me].color
end

function isAllytoMe(nickname)
    local focus = GetFocusArmy()
    if focus == -1 then
        return false
    end

    for id, player in GetArmiesTable().armiesTable do
        if player.nickname == nickname then
            return IsAlly(focus, id)
        end
    end
end

local myColor = getArmyColor()

function FindClients(id)
    local t = GetArmiesTable()
    local focus = t.focusArmy
    local result = {}
    if focus == -1 then
        for index, client in GetSessionClients() do
            if not client.connected then
                continue
            end
            local playerIsObserver = true
            for id, player in GetArmiesTable().armiesTable do
                if player.outOfGame and player.human and player.nickname == client.name then
                    table.insert(result, index)
                    playerIsObserver = false
                    break
                elseif player.nickname == client.name then
                    playerIsObserver = false
                    break
                end
            end
            if playerIsObserver then
                table.insert(result, index)
            end
        end
    else
        local srcs = {}
        for army, info in t.armiesTable do
            if id then
                if army == id then
                    for k, cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                    break
                end
            else
                if IsAlly(focus, army) then
                    for k, cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                end
            end
        end
        for index, client in GetSessionClients() do
            for k, cmdsrc in client.authorizedCommandSources do
                if srcs[cmdsrc] then
                    table.insert(result, index)
                    break
                end
            end
        end
    end
    return result
end

local function SendPaintData(data, remove)
    -- local text = data[1].x .. ' ' .. data[1].y .. ' ' .. data[1].z .. ' ' .. data[2].x .. ' ' .. data[2].y .. ' ' ..
    -- data[2].z
    local msg = {
        to = 'allies',
        TacticalPaint = true,
        Remove = remove,
        -- text = text,
        Data = data
    }
    SessionSendChatMessage(FindClients(), msg)
end

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field lifeTime number
---@field color Color


---@param player string
---@param pos1 Vector
---@param pos2 Vector
---@param color string
local function DrawLine(player, pos1, pos2, color)

    if VDist2(pos1[1], pos1[3], pos2[1], pos2[3]) < minDist / 2 then
        return
    end

    local holder = linesHolder[player]
    if not holder then
        holder = PlayerLinesHolder(getArmyColor(player))
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

local function ProcessPaintData(player, msg)
    local data = msg.Data
    local remove = msg.Remove
    local me = GetFocusArmy()
    -- reprsl(GetArmiesTable())

    local isSenderUs = GetArmiesTable().armiesTable[me].nickname == player
    local isAlly = isAllytoMe(player)

    if IsObserver() or not isSenderUs and isAlly then
        if remove then
            local x, z, offset = data[1], data[2], data[3]
            ClearLinesAt(x, z, offset)
        else
            local holder = linesHolder[player]
            if not holder then
                holder = PlayerLinesHolder(getArmyColor(player))
                linesHolder[player] = holder
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

        local color
        if myColor then
            color = myColor
        else
            color = string.lower(Prefs.GetFromCurrentProfile('options')['TPaintobs_color'] or 'ffffffff')
        end

        self._color = color
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
                DrawLine("me", prevMouseWorldPos, pos, self._color)
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

    RegisterChatFunc(ProcessPaintData, 'TacticalPaint')

    local WorldView = import("/lua/ui/controls/worldview.lua").WorldView

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
