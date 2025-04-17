local IsObserver = IsObserver
local GetCamera = GetCamera
local GetMouseWorldPos = GetMouseWorldPos
local GetFocusArmy = GetFocusArmy
local MathMax = math.max
local TableInsert = table.insert

local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

local PlayerMuteList = import("PlayerMuteList.lua").PlayerMuteList
local TacticalPaint = import("/lua/ui/game/TacticalPaint/Main.lua")

local minDist = 1

---@class Canvas : Bitmap, Renderable
---@field _text Text
---@field _btn Button
---@field _muteBtn Button
---@field _list PlayerMuteList?
---@field _collectedLines Line[]
---@field _prevMousePos Vector?
---@field _color Color
---@field _isHiddenLines boolean
Canvas = Class(Bitmap)
{
    ---@param self Canvas
    ---@param parent Control
    __init = function(self, parent)
        Bitmap.__init(self, parent)

        self._active = false
        self._collectedLines = {}
        self._prevMousePos = nil
        self._isHiddenLines = false

        local text = UIUtil.CreateText(self, "Tactical Paint", 20, "Arial")
        LayoutFor(text)
            :AtHorizontalCenterIn(self)
            :AtTopIn(self, 80)
            :Over(self)
            :DisableHitTest()

        local hideBtn = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', "Hide", 16)
        LayoutFor(hideBtn)
            :Below(text, 5)
            :AtHorizontalCenterIn(text, 50)
            :Width(120)
            :Over(self)
            :EnableHitTest()

        local muteBtn = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', "Mute", 16)
        LayoutFor(muteBtn)
            :Below(text, 5)
            :AtHorizontalCenterIn(text, -50)
            :Width(120)
            :Over(self)
            :EnableHitTest()

        ---@param btn Button
        hideBtn.OnClick = function(btn)
            self:SetHiddenLines(not self._isHiddenLines)
        end

        ---@param btn Button
        muteBtn.OnClick = function(btn)
            if self._list then
                self._list:Destroy()
                self._list = nil
            else
                self:CreatePlayerList()
            end
        end

        self._muteBtn = muteBtn
        self._btn = hideBtn
        self._text = text
    end,

    ---@param self Canvas
    ---@param state boolean
    SetHiddenLines = function(self, state)
        self._isHiddenLines = state
        if self._isHiddenLines then
            self._btn.label:SetText("Show")
        else
            self._btn.label:SetText("Hide")
        end
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
            self._btn:Show()
            self._muteBtn:Show()
            self._text:Show()
        else
            self._btn:Hide()
            self._muteBtn:Hide()
            self._text:Hide()

            if self._list then
                self._list:Destroy()
                self._list = nil
            end

            self:OnDrawEnd()
        end
    end,

    ---@param self Canvas
    CreatePlayerList = function(self)
        if not IsDestroyed(self._list) then
            return
        end

        local collectionsTable = TacticalPaint.GetLinesCollections()

        local armies = GetArmiesTable().armiesTable

        ---@type PlayerMuteData[]
        local playerData = {}

        for id, army in armies do
            if not army.civilian then
                if IsObserver() or GetFocusArmy() ~= id and IsAlly(id, GetFocusArmy()) then
                    local name    = army.nickname
                    local enabled = true

                    local collection = collectionsTable[id]
                    if collection then
                        enabled = collection:GetEnabled()
                    end

                    table.insert(playerData, {
                        id      = id,
                        name    = name,
                        enabled = enabled,
                        color   = army.color or "ffffffff"
                    })
                end
            end
        end


        self._list = PlayerMuteList(self, TacticalPaint.SetSourceEnabled)
        self._list:InitStates(playerData)

        LayoutFor(self._list)
            :AtLeftTopIn(self, 100, 300)
            :Width(0)
            :Height(0)
            :Over(self)
    end,

    ---@param self Canvas
    ---@param delta number
    OnRender = function(self, delta, worldview)
        if self._isHiddenLines then
            return
        end

        for player, holder in TacticalPaint.GetLinesCollections() do
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
                TacticalPaint.SendPaintData(package, false)
            end
        elseif n > 0 then
            TacticalPaint.SendPaintData(lines, false)
        end

    end,

    ---@param self Canvas
    OnDrawStart = function(self)
        self._prevMousePos = GetMouseWorldPos()
        TableInsert(self._collectedLines, self._prevMousePos)
    end,

    ---@param self Canvas
    ---@param pos Vector
    OnDraw = function(self, pos, minDist)
        local prevMouseWorldPos = self._prevMousePos
        if prevMouseWorldPos then
            local minDistSq = minDist * minDist
            local x1, y1 = prevMouseWorldPos[1], prevMouseWorldPos[3]
            local x2, y2 = pos[1], pos[3]
            local dx = x1 - x2
            local dy = y1 - y2
            if dx * dx + dy * dy > minDistSq then
                TableInsert(self._collectedLines, pos)
                TacticalPaint.DrawLine(GetFocusArmy(), prevMouseWorldPos, pos)
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
        local wasRemoved = TacticalPaint.ClearLinesAt(x, z, radius)

        if wasRemoved then
            TacticalPaint.SendPaintData({ x, z, radius }, true)
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
        if (not isCanvasActive or self._isHiddenLines) and not IsObserver() then
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
            elseif isEventRelease and not isModLeft then
                self:OnDrawEnd()
            elseif isEventMotion then
                local pos = GetMouseWorldPos()
                local zoom = GetCamera(worldview._cameraName):GetZoom()

                if isModLeft then
                    local offset = zoom / 100
                    self:OnDraw(pos, MathMax(offset, minDist))
                elseif isModRight then
                    local offset = zoom / 50
                    self:OnErase(pos, offset)
                end
            end

            return true
        end
        return false
    end,
}


---@param view WorldView
---@return Canvas
function AttachCanvasToWorldView(view)
    view._canvas = Canvas(view)
    LayoutFor(view._canvas)
        :Fill(view)
        :ResetWidth()
        :ResetHeight()
        :Over(view)
        :EnableHitTest()
    view._canvas:SetActive(false)
    view:RegisterRenderable(view._canvas, "TacticalPaint.Canvas")
    return view._canvas
end
