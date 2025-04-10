local GetMouseWorldPos = GetMouseWorldPos

local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Prefs = import('/lua/user/prefs.lua')

local LayoutFor = import('/lua/maui/layouthelpers.lua').ReusedLayoutFor

local TacticalPaint = import("/lua/ui/game/TacticalPaint/Main.lua")

local minDist = 0.5



---@class Canvas : Bitmap, Renderable
---@field _text Text
---@field _btn Button
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
            :AtTopIn(self, 100)
            :Over(self)
            :DisableHitTest()

        local hideBtn = UIUtil.CreateButtonStd(self, '/BUTTON/medium/', "Hide", 20)
        LayoutFor(hideBtn)
            :Below(text, 10)
            :AtHorizontalCenterIn(text)
            :Width(200)
            :Over(self)
            :EnableHitTest()

        ---@param btn Button
        hideBtn.OnClick = function(btn)
            self._isHiddenLines = not self._isHiddenLines
            if self._isHiddenLines then
                btn.label:SetText("Show")
            else
                btn.label:SetText("Hide")
            end
        end

        self._btn = hideBtn
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
            self._btn:Show()
            self._text:Show()
        else
            self._text:Hide()
            self._btn:Hide()

            self:OnDrawEnd()
        end
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
        table.insert(self._collectedLines, self._prevMousePos)
    end,

    ---@param self Canvas
    ---@param pos Vector
    OnDraw = function(self, pos)
        local prevMouseWorldPos = self._prevMousePos
        if prevMouseWorldPos then
            if VDist2(prevMouseWorldPos[1], prevMouseWorldPos[3], pos[1], pos[3]) > minDist then
                table.insert(self._collectedLines, pos)
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
        if not isCanvasActive or self._isHiddenLines then
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
