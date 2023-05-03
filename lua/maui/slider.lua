
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local lazyvar = import("/lua/lazyvar.lua")

local UIUtil = import("/lua/ui/uiutil.lua")

---@class Slider : Group
Slider = ClassUI(Group) {
    -- TODO make it possible for the start value to be greate than the end value and have that work the opposite way
    __init = function(self, parent, isVertical, startValue, endValue, thumb, thumbOver, thumbDown, background, debugname)
        Group.__init(self, parent)
        self:SetName(debugname or "Slider")

        self._isVertical = isVertical
        self._startValue = startValue
        self._currentValue = lazyvar.Create(startValue)
        self._endValue = endValue
        self._thumb = Bitmap(self, thumb)
        self.mThumbUp = thumb
        self.mThumbOver = thumbOver
        self.mThumbDown = thumbDown
        self._background = Bitmap(self, background)

        -- set size of group relative to background
        self.Width:Set(self._background.Width)
        self.Height:Set(self._background.Height)

        -- set background to top left of group
        self._background.Left:Set(self.Left)
        self._background.Top:Set(self.Top)

        -- place the thumb in the center of the group on the non-moving axis
        -- set the bottom or left to a function that is determined by the current and end values
        self._thumb.Depth:Set(function() return self._background.Depth() + 1 end)
        if self._isVertical then
            LayoutHelpers.AtHorizontalCenterIn(self._thumb, self)
            self._thumb.Bottom:Set(function()
                    return math.floor(self.Bottom() - (((self._currentValue() - self._startValue) / (self._endValue - self._startValue)) * (self.Bottom() - (self.Top() + self._thumb.Height()))))
                end)
        else
            LayoutHelpers.AtVerticalCenterIn(self._thumb, self)
            self._thumb.Left:Set(function()
                    return math.floor(self.Left() + (((self._currentValue() - self._startValue) / (self._endValue - self._startValue)) * (self.Right() - (self.Left() + self._thumb.Width()))))
                end)
        end

        -- set up thumb event handler
        self._thumb.HandleEvent = function(control, event)
            eventHandled = false
            if event.Type == 'ButtonPress' then
                local dragger = Dragger()
                dragger.OnMove = function(control, x, y)
                    local value = self:CalculateValueFromMouse(x, y)
                    value = self:_Constrain(value)
                    local curVal = self:GetValue()
                    self._thumb:SetTexture(self.mThumbDown)
                    if value != curVal then
                        self:SetValue(value)
                        self:OnScrub(value)
                    end
                end

                dragger.OnRelease = function(control, x, y)
                    local value = self:CalculateValueFromMouse(x, y)
                    if (x < self._thumb.Left() or x > self._thumb.Right()) or (y < self._thumb.Top() or y > self._thumb.Bottom()) then                    
                        self._thumb:SetTexture(self.mThumbUp)
                    else
                        self._thumb:SetTexture(self.mThumbOver)
                    end
                    self:SetValue(value)
                    self:OnValueSet(self:_Constrain(value))
                    self:OnEndChange()
                    dragger:Destroy()
                end
                control:SetTexture(self.mThumbDown)
                self:OnBeginChange()
                PostDragger(self:GetRootFrame(), event.KeyCode, dragger)
                eventHandled = true
            elseif event.Type == 'MouseEnter' then
                control:SetTexture(self.mThumbOver)
            elseif event.Type == 'MouseExit' then
                control:SetTexture(self.mThumbUp)
            end

            return eventHandled
        end

        -- set up background event handler
        self._background.HandleEvent = function(control, event)
            eventHandled = false
            if event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                local value = self:CalculateValueFromMouse(event.MouseX, event.MouseY)
                self:SetValue(value)
                self:OnValueSet(self._currentValue())
                eventHandled = true
            end
            return eventHandled
        end
    end,

    -- this will constrain your values to not exceed min or max
    SetValue = function(self, value)
        self._currentValue:Set(self:_Constrain(value))
        self:OnValueChanged(self._currentValue())
    end,

    GetValue = function(self)
        return self._currentValue()
    end,

    SetStartValue = function(self, startValue)
        self._startValue = startValue
        self:SetValue(self._currentValue())
    end,

    SetEndValue = function(self, endValue)
        self._endValue = endValue
        self:SetValue(self._currentValue())
    end,

    CalculateValueFromMouse = function(self, x, y)
        local newValue = self._currentValue()
        if self._isVertical then
            newValue = self._startValue + (((self.Bottom() - y) / (self.Bottom() - (self.Top() + self._thumb.Height()))) * (self._endValue - self._startValue))
        else
            newValue = self._startValue + (((x - self.Left()) / (self.Right() - (self.Left() + self._thumb.Width()))) * (self._endValue - self._startValue))
        end
        return newValue
    end,

    _Constrain = function(self, value)
        return math.max(math.min(value, self._endValue), self._startValue)
    end,

    -- overload to be informed when the value is set by a mouse release
    OnValueSet = function(self, newValue) end,

    -- overload to be informed when the value is changed
    OnValueChanged = function(self, newValue) end,

    -- overload to be informed when someone starts and stops dragging the
    -- slider
    OnBeginChange = function(self) end,
    OnEndChange = function(self) end,

    -- overload to be informed during scrub
    OnScrub = function(self,value) end,
}

---@class IntegerSlider : Slider
IntegerSlider = ClassUI(Slider) {
    __init = function(self, parent, isVertical, startValue, endValue, indentValue, thumb, thumbOver, thumbDown, background)

        thumb = thumb or UIUtil.SkinnableFile('/slider02/slider_btn_up.dds')
        thumbOver = thumbOver or UIUtil.SkinnableFile('/slider02/slider_btn_over.dds')
        thumbDown = thumbDown or UIUtil.SkinnableFile('/slider02/slider_btn_down.dds')
        background = background or UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds')

        Slider.__init(self, parent, isVertical, math.floor(startValue), math.floor(endValue), thumb, thumbOver, thumbDown, background)
        self._indentValue = math.floor(indentValue)
    end,

    _Constrain = function(self,value)
        value = Slider._Constrain(self,value)
        value = math.floor(value / self._indentValue) * self._indentValue
        return value
    end,
}
