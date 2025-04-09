local RegisterChatFunc = import('/lua/ui/game/gamemain.lua').RegisterChatFunc
local FindClients = import('/lua/ui/game/chat.lua').FindClients
local Prefs = import('/lua/user/prefs.lua')
local UI_DrawLine = UI_DrawLine

local PrevMouseWorldPos = nil
local minDist = 0.5


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

function getKeyBind()
    for key, value in Prefs.GetFromCurrentProfile('UserKeyMap') do
        if value == 'Paint Tool' then
            return keyMap[key]
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

local function sendPaintData(data, remove)
    -- local text = data[1].x .. ' ' .. data[1].y .. ' ' .. data[1].z .. ' ' .. data[2].x .. ' ' .. data[2].y .. ' ' ..
    -- data[2].z
    data.remove = remove
    local msg = {
        to = 'allies',
        TacticalPaint = true,
        -- text = text,
        text = data
    }
    SessionSendChatMessage(FindClients(), msg)
end

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field lifeTime number
---@field color Color

---@type Line[]
local lines = {}
local i = 1

---@param pos1 Vector
---@param pos2 Vector
---@param color string
---@param send boolean
local function DrawLine(pos1, pos2, color, send)

    if send then
        sendPaintData({ pos1, pos2, color })
    end

    if VDist2(pos1[1], pos1[3], pos2[1], pos2[3]) < minDist / 2 then
        return
    end


    lines[i] = {
        p1 = pos1,
        p2 = pos2,
        color = color, --"aa" .. string.sub(color, 3),
        -- lifeTime = Prefs.GetFromCurrentProfile('options')['TPaint_lifetime']
    }
    i = i + 1
end

---@param x number
---@param z number
---@param radiusSq number
---@return boolean
local function ClearLinesAt(x, z, radiusSq)
    local removedAny = false
    for j, line in lines do
        local p1 = line.p1
        local p2 = line.p2

        local dx = p1[1] - x
        local dz = p1[3] - z
        local distSq = dx * dx + dz * dz
        if distSq < radiusSq then
            removedAny = true
            lines[j] = nil
        else
            dx     = p2[1] - x
            dz     = p2[3] - z
            distSq = dx * dx + dz * dz
            if distSq < radiusSq then
                removedAny = true
                lines[j] = nil
            end
        end
    end
    return removedAny
end

local function processPaintData(player, msg)
    local data = msg.text
    local me = GetFocusArmy()
    -- reprsl(GetArmiesTable())

    local isSenderUs = GetArmiesTable().armiesTable[me].nickname == player
    local isAlly = isAllytoMe(player)

    if IsObserver() or not isSenderUs and isAlly then
        if data.remove then
            local x, z, offset = data[1], data[2], data[3]
            ClearLinesAt(x, z, offset)
        else
            DrawLine({
                data[1][1],
                data[1][2],
                data[1][3]
            }, {
                data[2][1],
                data[2][2],
                data[2][3]
            }, data[3], false)
        end
    end
end

local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

---@class Canvas : Bitmap
Canvas = Class(Bitmap)
{
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
        end
    end,

    ---@param self Canvas
    ---@param delta number
    Render = function(self, delta)
        for j, line in lines do
            -- if line.lifeTime > 0 then
            -- line.lifeTime = line.lifeTime - delta
            UI_DrawLine(line.p1, line.p2, line.color, 0.15)
            -- else
            --     lines[j] = nil
            -- end
        end
    end,

    HandleDrawing = function(self, worldview, event)
        local isCanvasActive = self:GetActive()
        if isCanvasActive and
            (
            event.Type == "MouseMotion" or
                event.Type == "ButtonPress" and (event.Modifiers.Left or event.Modifiers.Right)
            ) then

            if event.Type == "ButtonPress" then
                PrevMouseWorldPos = GetMouseWorldPos()
            end

            local color
            if myColor then
                color = myColor
            else
                color = string.lower(Prefs.GetFromCurrentProfile('options')['TPaintobs_color'] or 'ffffffff')
            end

            if event.Type == "MouseMotion" and event.Modifiers.Left then
                local pos = GetMouseWorldPos()
                if VDist2(PrevMouseWorldPos[1], PrevMouseWorldPos[3], pos[1], pos[3]) > minDist then
                    DrawLine(PrevMouseWorldPos, pos, color, true)
                    PrevMouseWorldPos = pos
                end
            elseif event.Type == "MouseMotion" and event.Modifiers.Right then
                local offset = GetCamera(worldview._cameraName):GetZoom() / 50
                offset = offset * offset
                local pos = GetMouseWorldPos()
                local x, z = pos[1], pos[3]
                local wasRemoved = ClearLinesAt(x, z, offset)

                if wasRemoved then
                    sendPaintData({ x, z, offset }, true)
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
    for j in lines do
        lines[j] = nil
    end
end

local MathFloor = math.floor

---@param isReplay boolean
function Main(isReplay)

    local KeyMapper = import('/lua/keymap/keymapper.lua')
    KeyMapper.SetUserKeyAction('Open Tactical Paint canvas', { action = "UI_Lua import('/lua/ui/game/TacticalPaint/Main.lua').TacticalPaint()", category = 'Tactical Paint' })
    KeyMapper.SetUserKeyAction('Clear canvas', { action = "UI_Lua import('/lua/ui/game/TacticalPaint/Main.lua').Clear()", category = 'Tactical Paint' })

    RegisterChatFunc(processPaintData, 'TacticalPaint')

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
        local isCanvasActive = self._canvas and self._canvas:HandleDrawing(self, event)
        if isCanvasActive then
            return true
        end
        return WVH(self, event)
    end
end
