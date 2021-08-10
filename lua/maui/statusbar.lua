local Bitmap = import('bitmap.lua').Bitmap
local lazyvar = import('/lua/lazyvar.lua')

# vertical true means the bar will grow in the vertical direction
# negative true means for horizontal bars they will grow right to left, for vertical they will grow top to bottom

StatusBar = Class(Bitmap)
{
    __init = function(self, parent, rangeMin, rangeMax, vertical, negative, background, bar, stretchTextures, debugname)
        Bitmap.__init(self, parent, background)
        self:SetName(debugname or "statusbar")
        
        self._rangeMin = rangeMin
        self._rangeMax = rangeMax
        self._minSlidePercent = 0.0
        self._range = rangeMax - rangeMin
        self._value = lazyvar.Create(rangeMin)
        self._vertical = vertical
        self._negative = negative
        self._stretch = stretchTextures or false
        self._bar = Bitmap(self, bar)

        if self._vertical then
            if self._negative then
                self._bar.Top:Set(self.Top)
                self._bar.Bottom:Set(function() 
                    local rangePercent = self:_CalcRangePercent()
                    if not self._stretch then
                        self._bar:SetUV(0, 1 - rangePercent, 1, 1)
                    end
                    return math.floor(self.Top() + (rangePercent * (self.Bottom() - self.Top())))
                end)
            else
                self._bar.Bottom:Set(self.Bottom)
                self._bar.Top:Set(function()
                    local rangePercent = self:_CalcRangePercent()
                    if not self._stretch then
                        self._bar:SetUV(0, 0, 1, rangePercent)
                    end
                    return math.floor(self.Bottom() - (rangePercent * (self.Bottom() - self.Top())))
                end)
            end
            self._bar.Left:Set(self.Left)
            self._bar.Width:Set(self.Width)                
        else
            if self._negative then
                self._bar.Right:Set(self.Right)
                self._bar.Left:Set(function()
                    local rangePercent = self:_CalcRangePercent()
                    if not self._stretch then
                        self._bar:SetUV(0, 0, rangePercent, 1)
                    end
                    return math.floor(self.Right() - (rangePercent * (self.Right() - self.Left())))
                end)
            else
                self._bar.Left:Set(self.Left)
                self._bar.Right:Set(function()
                    local rangePercent = self:_CalcRangePercent()
                    if not self._stretch then
                        self._bar:SetUV(1 - rangePercent, 0, 1, 1)
                    end
                    return math.floor(self.Left() + (rangePercent * (self.Right() - self.Left())))
                end)
            end
            self._bar.Top:Set(self.Top)
            self._bar.Height:Set(self.Height)
        end        
    end,

    SetValue = function(self, value)
        self._value:Set(self:_Constrain(value))
    end,
    
    SetRange = function(self, rangeMin, rangeMax)
        self._rangeMin = rangeMin
        self._rangeMax = rangeMax
        self._range = rangeMax - rangeMin
        # since the ranges have changed, we need to control to redraw itself
        self:SetValue(self._value())
    end,
    
    # this allows the bar to move in an incremental value, rather than smoothly
    SetMinimumSlidePercentage = function(self, percentage)
        self._minSlidePercent = percentage
    end,

    _CalcRangePercent = function(self)
        if self._minSlidePercent == 0 then
            return (self._value() - self._rangeMin) / (self._range)
        else
            return math.floor(((self._value() - self._rangeMin) / (self._range)) / self._minSlidePercent) * self._minSlidePercent
        end
    end,
    
    _Constrain = function(self, value)
        return math.max(math.min(value, self._rangeMax), self._rangeMin)
    end,
}