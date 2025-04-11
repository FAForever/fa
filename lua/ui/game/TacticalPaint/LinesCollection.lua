local GetGameTimeSeconds = GetGameTimeSeconds
local UI_DrawLine = UI_DrawLine

local decayTime = 60
local maxLinesPerPlayer = 1000

---@class Line
---@field p1 Vector
---@field p2 Vector
---@field lifeTime number

---@class LinesCollection
---@field _lines Line[]
---@field _color Color
---@field _i integer
---@field _curLines integer
---@field _enabled boolean
LinesCollection = Class()
{
    ---@param self LinesCollection
    ---@param color Color
    __init = function(self, color)
        self._lines = {}
        self._color = color
        self._i = 1
        self._curLines = 0
        self._enabled = true
    end,

    ---@param self LinesCollection
    ---@param pos1 Vector
    ---@param pos2 Vector
    ---@param lifetime number
    Add = function(self, pos1, pos2, lifetime)
        self._lines[self._i] = {
            p1 = pos1,
            p2 = pos2,
            lifeTime = lifetime,
        }
        self._i = self._i + 1
        self._curLines = self._curLines + 1

        if self._curLines > maxLinesPerPlayer then
            self:RemoveOldestLines(self._curLines - maxLinesPerPlayer)
        end
    end,

    ---@param self LinesCollection
    Remove = function(self, i)
        self._lines[i] = nil
        self._curLines = self._curLines - 1
    end,

    ---@param self LinesCollection
    RemoveOldestLine = function(self)
        local k, min = nil, GetGameTimeSeconds()
        for i, line in self._lines do
            local lineLifeTime = line.lifeTime
            if lineLifeTime < min then
                min = lineLifeTime
                k = i
            end
        end
        if k ~= nil then
            self:Remove(k)
        end
    end,

    ---@param self LinesCollection
    ---@param n integer
    RemoveOldestLines = function(self, n)
        for i = 1, n do
            self:RemoveOldestLine()
        end
    end,

    ---@param self LinesCollection
    ---@param delta number
    Render = function(self, delta)
        --- Should we still check lines to delete?
        if not self._enabled then
            return
        end

        local UI_DrawLine = UI_DrawLine
        local color       = self._color
        local time        = GetGameTimeSeconds()
        local lines       = self._lines

        for i, line in lines do
            if line.lifeTime < time then
                self:Remove(i)
            else
                UI_DrawLine(line.p1, line.p2, color, 0.15)
            end
        end
    end,

    ---@param self LinesCollection
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

    ---@param self LinesCollection
    ClearAll = function(self)
        local lines = self._lines
        for j in lines do
            lines[j] = nil
        end
        self._i = 1
        self._curLines = 0
    end,

    ---@param self LinesCollection
    ---@param state boolean
    SetEnabled = function(self, state)
        self._enabled = state
    end,

    ---@param self LinesCollection
    ---@return boolean
    GetEnabled = function(self)
        return self._enabled
    end
}
