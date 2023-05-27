-- A combo box consists of a text control, a button to expand it, and a dropdown selectable list
-- this is a custom control as it its default has very game specific look to it
-- Combo box will need to have its width set, but height will be auto based on the bitmaps

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group

local TableGetN = table.getn

---@class SpecialGrid : Group
SpecialGrid = ClassUI(Group) {

    ---@param self SpecialGrid
    ---@param parent Control
    ---@param isVertical boolean
    __init = function(self, parent, isVertical)
        Group.__init(self, parent)
        self.top = 1
        self.Items = {}
        self.DisplayData = {}
        self._scrollMin = false
        self._scrollMax = false
        self._pageMin = false
        self._pageMax = false
        self._vertical = isVertical
    
        self.Right.OnDirty = function(var)
            self:ClearItems()
        end

    end,

    CreateElement = function()
    end,

    ---@param control Control
    ---@param type type
    SetControlToType = function(control, type)
    end,

    ---@param control Control
    ---@param vertical boolean
    SetToVertical = function(control, vertical)
        control.top = 1
        control._vertical = vertical
        control:ClearItems()
        control:CalcVisible()
    end,

    ---@param self SpecialGrid
    ---@param scrollmin number
    ---@param scrollmax number
    ---@param pagemin number
    ---@param pagemax number
    SetupScrollControls = function(self, scrollmin, scrollmax, pagemin, pagemax)
        if scrollmin then
            self._scrollMin = scrollmin
            self._scrollMin.OnClick = function(control, modifiers)
                 self:ScrollLines(-1)
            end
        end
        if scrollmax then
            self._scrollMax = scrollmax
            self._scrollMax.OnClick = function(control, modifiers)
                 self:ScrollLines(1)
            end
        end
        if pagemin then
            self._pageMin = pagemin
            self._pageMin.OnClick = function(control, modifiers)
                self.top = 1
                self:CalcVisible()
            end
        end
        if pagemax then
            self._pageMax = pagemax
            self._pageMax.OnClick = function(control, modifiers)
                self.top = TableGetN(self.DisplayData) - table.getsize(self.Items) + 1
                self:CalcVisible()
            end
        end
    end,

    ---@param self SpecialGrid
    CalcVisible = function(self)
        local maxItemWidth = 0
        local itemIndex = 1
        local minControl = 'Left'
        local maxControl = 'Right'
        if self._vertical then
            minControl = 'Top'
            maxControl = 'Bottom'
        end
        for i = self.top, TableGetN(self.DisplayData) do
            local index = i
            if not self.Items[itemIndex] then
                self.Items[itemIndex] = self.CreateElement()
                if self._vertical then
                    if index == 1 then
                        LayoutHelpers.AtTopIn(self.Items[itemIndex], self)
                        LayoutHelpers.AtHorizontalCenterIn(self.Items[itemIndex], self)
                    else
                        LayoutHelpers.Below(self.Items[itemIndex], self.Items[itemIndex-1])
                        LayoutHelpers.AtHorizontalCenterIn(self.Items[itemIndex], self)
                    end
                else
                    if index == 1 then
                        LayoutHelpers.AtLeftIn(self.Items[itemIndex], self)
                        LayoutHelpers.AtVerticalCenterIn(self.Items[itemIndex], self)
                    else
                        LayoutHelpers.RightOf(self.Items[itemIndex], self.Items[itemIndex-1])
                        LayoutHelpers.AtVerticalCenterIn(self.Items[itemIndex], self)
                    end
                end
            end
            if itemIndex == 1 or self.Items[itemIndex-1][maxControl]() + maxItemWidth < self[maxControl]() then
                local data = self.DisplayData[index]
                local control = self.Items[itemIndex]
                control:Show()
                control.Data = data
                self.SetControlToType(control, data.type)
                if control.OptionMenu then
                    control.OptionMenu:Destroy()
                    control.OptionMenu = nil
                end
                if control.Width() > maxItemWidth then
                    maxItemWidth = control.Width()
                end
            else
                -- if an item is found that can't fit it needs to be destroyed because it won't display
                -- ideally the calculation as to whether it can fit would be done before creating the item
                -- but this will do in a pinch
                self.Items[itemIndex]:Destroy()
                self.Items[itemIndex] = nil
                break
            end
            itemIndex = itemIndex + 1
        end
        if self._scrollMin and self.top == 1 then
            self._scrollMin:Disable()
            self._pageMin:Disable()
        elseif self._scrollMin then
            self._scrollMin:Enable()
            self._pageMin:Enable()
        end
        if self._scrollMax and (TableGetN(self.DisplayData) - self.top) >= table.getsize(self.Items) then
            self._scrollMax:Enable()
            self._pageMax:Enable()
        elseif self._scrollMax then
            self._scrollMax:Disable()
            self._pageMax:Disable()
        end
        for i = itemIndex, table.getsize(self.Items) do
            local index = i
            self.Items[index]:Hide()
            if self.Items[index][maxControl]() > self[maxControl]() then
                self.Items[index]:Destroy()
                self.Items[index] = nil
            end
        end
    end,

    ---@param self SpecialGrid
    ClearItems = function(self)
        for i, item in self.Items do
            item:Destroy()
            self.Items[i] = nil
        end
    end,

    ---@param self SpecialGrid
    ---@param lines number
    ScrollLines = function(self, lines)
        local top = self.top
        self.top = math.max(1, math.min(top + lines, (TableGetN(self.DisplayData) - TableGetN(self.Items))+1))
        self:CalcVisible()
    end,

    ---@param self SpecialGrid
    ---@param newData any
    Refresh = function(self, newData)
        self.top = 1
        self.DisplayData = newData
        self:CalcVisible()
    end,
}

-- kept for mod backwards compatibility
local UIUtil = import("/lua/ui/uiutil.lua")
local Text = import("/lua/maui/text.lua").Text
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Dragger = import("/lua/maui/dragger.lua").Dragger