local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local lazyvar = import("/lua/lazyvar.lua")
local MathFloor = math.floor

---@class StatusBar : Bitmap
---@field _rangeMin number
---@field _rangeMax number
---@field _minSlidePercent number
---@field _value LazyVar<number>
---@field _vertical boolean
---@field _negative boolean
---@field _stretch boolean
---@field _bar Bitmap
StatusBar = ClassUI(Bitmap) {

    ---@param self StatusBar
    ---@param parent Control
    ---@param rangeMin number
    ---@param rangeMax number
    ---@param vertical boolean # When true, the bar grows vertically instead of horizontally
    ---@param negative boolean # When true, the bar grows in the other direction
    ---@param background Lazy<FileName>
    ---@param bar FileName
    ---@param stretchTextures boolean
    ---@param debugname string
    __init = function(self, parent, rangeMin, rangeMax, vertical, negative, background, bar, stretchTextures, debugname)
        Bitmap.__init(self, parent, background)
        self:SetName(debugname or "statusbar")

        self._rangeMin = rangeMin
        self._rangeMax = rangeMax
        self._minSlidePercent = 0.0
        self._value = lazyvar.Create(rangeMin)
        self._vertical = vertical
        self._negative = negative
        self._stretch = stretchTextures or false
        self._bar = Bitmap(self, bar)

        if vertical then
            if negative then
                self._bar.Top:SetFunction(self.Top)
                self._bar.Bottom:SetFunction(
                    function()
                        local rangePercent = self:_CalcRangePercent()
                        if not self._stretch then
                            self._bar:SetUV(0, 1 - rangePercent, 1, 1)
                        end
                        return MathFloor(self.Top() + (rangePercent * (self.Bottom() - self.Top())))
                    end
                )
            else
                self._bar.Bottom:SetFunction(self.Bottom)
                self._bar.Top:SetFunction(
                    function()
                        local rangePercent = self:_CalcRangePercent()
                        if not self._stretch then
                            self._bar:SetUV(0, 0, 1, rangePercent)
                        end
                        return MathFloor(self.Bottom() - (rangePercent * (self.Bottom() - self.Top())))
                    end
                )
            end
            self._bar.Left:SetFunction(self.Left)
            self._bar.Width:SetFunction(self.Width)
        else
            if negative then
                self._bar.Right:SetFunction(self.Right)
                self._bar.Left:SetFunction(
                    function()
                        local rangePercent = self:_CalcRangePercent()
                        if not self._stretch then
                            self._bar:SetUV(0, 0, rangePercent, 1)
                        end
                        return MathFloor(self.Right() - (rangePercent * (self.Right() - self.Left())))
                    end
                )
            else
                self._bar.Left:SetFunction(self.Left)
                self._bar.Right:SetFunction(
                    function()
                        local rangePercent = self:_CalcRangePercent()
                        if not self._stretch then
                            self._bar:SetUV(1 - rangePercent, 0, 1, 1)
                        end
                        return MathFloor(self.Left() + (rangePercent * (self.Right() - self.Left())))
                    end
                )
            end
            self._bar.Top:SetFunction(self.Top)
            self._bar.Height:SetFunction(self.Height)
        end
    end,

    ---@param self StatusBar
    ---@param value number
    SetValue = function(self, value)
        local min = self._rangeMin
        local max = self._rangeMax

        if value < min then
            value = min
        elseif value > max then
            value = max
        end

        self._value:SetValue(value)
    end,

    ---@param self StatusBar
    ---@param rangeMin number
    ---@param rangeMax number
    SetRange = function(self, rangeMin, rangeMax)
        self._rangeMin = rangeMin
        self._rangeMax = rangeMax
        -- since the ranges have changed, we need to control to redraw itself
        self:SetValue(self._value())
    end,

    -- this allows the bar to move in an incremental value, rather than smoothly
    ---@param self StatusBar
    ---@param percentage number
    SetMinimumSlidePercentage = function(self, percentage)
        self._minSlidePercent = percentage
    end,

    ---@param self StatusBar
    _CalcRangePercent = function(self)
        local min = self._rangeMin
        local max = self._rangeMax
        local range = max - min

        local value = self._value()
        local minSlidePercent = self._minSlidePercent

        if minSlidePercent == 0 then
            return (value - min) / (range)
        else
            return MathFloor(((value - min) / (range)) / minSlidePercent) * minSlidePercent
        end
    end,

    --- Contraints the parameter to the min / max values of the status bar
    ---@deprecated
    ---@param self StatusBar
    ---@param value number
    _Constrain = function(self, value)
        local min = self._rangeMin
        local max = self._rangeMax

        if value < min then
            return min
        elseif value > max then
            return max
        end

        return value
    end,
}
