local Group = import('/lua/maui/group.lua').Group
local UIUtil = import('/lua/ui/uiutil.lua')



---@class StaticScrollable : Group
---@field _topLine  integer
---@field _dataSize integer
---@field _numLines integer
StaticScrollable = Class(Group) {

    Setup = function(self, topIndex, dataSize, numLines)
        self._topLine = topIndex
        self._dataSize = dataSize
        self._numLines = numLines
    end,

    GetScrollValues = function(self, axis)
        return 1, self._dataSize, self._topLine, math.min(self._topLine + self._numLines - 1, self._dataSize)
    end,

    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + delta)
    end,

    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self._topLine + math.floor(delta) * self._numLines)
    end,

    ScrollSetTop = function(self, axis, top)
        top = math.floor(math.max(math.min(self._dataSize - self._numLines + 1, top), 1))
        if top == self._topLine then return end
        self._topLine = top
        self:CalcVisible()
    end,

    ScrollToBottom = function(self)
        self:ScrollSetTop(nil, self._numLines)
    end,

    ---Determines what controls should be visible or not
    ---@param self StaticScrollable
    CalcVisible = function(self)
        local lineIndex = 1
        for index = self._topLine, self._numLines + self._topLine - 1 do
            self:RenderLine(lineIndex, index)
            lineIndex = lineIndex + 1
        end
    end,



    ---Overload for rendering lines
    ---@param self StaticScrollable
    ---@param lineIndex integer
    ---@param scrollIndex integer
    RenderLine = function(self, lineIndex, scrollIndex)
        WARN(debug.traceback("Not implemented method!"))
    end,

    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
        end
        return self:OnEvent(event)
    end,

    ---HandleEvent overload
    ---@param self StaticScrollable
    ---@param event Event
    ---@return boolean
    OnEvent = function(self, event)
        return true
    end
}
