

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Window = import('/lua/maui/window.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Text = import('/lua/maui/text.lua').Text
local GameMain = import('/lua/ui/game/gamemain.lua')
local Edit = import('/lua/maui/edit.lua').Edit

function CreateDefaultElement(parent, alignment)
    local group = Group(parent)
    group.Left:Set(function() return parent.Left() end)
    group.Right:Set(function() return parent.Right() end)
    group.Top:Set(function() return alignment.Bottom() end)
    group.Bottom:Set(function() return alignment.Bottom() + LayoutHelpers.ScaleNumber(16) end)

    group.name = UIUtil.CreateText(group, "function", 14, UIUtil.bodyFont, false)
    LayoutHelpers.AtLeftIn(group.name, group, 10)
    LayoutHelpers.AtTopIn(group.name, group, 0.0)

    group.source = UIUtil.CreateText(group, "source", 14, UIUtil.bodyFont, false)
    LayoutHelpers.FromLeftIn(group.source, group, 0.45)
    LayoutHelpers.AtTopIn(group.source, group, 0.0)

    group.scope = UIUtil.CreateText(group, "scope", 14, UIUtil.bodyFont, false)
    LayoutHelpers.FromLeftIn(group.scope, group, 0.60)
    LayoutHelpers.AtTopIn(group.scope, group, 0.0)

    group.value = UIUtil.CreateText(group, "value", 14, UIUtil.bodyFont, false)
    LayoutHelpers.FromLeftIn(group.value, group, 0.75)
    LayoutHelpers.AtTopIn(group.value, group, 0.0)

    group.growth = UIUtil.CreateText(group, "growth", 14, UIUtil.bodyFont, false)
    LayoutHelpers.FromLeftIn(group.growth, group, 0.9)
    LayoutHelpers.AtTopIn(group.growth, group, 0.0)

    return group
end

function PopulateDefaultElement(element, entry)
    element.name:SetText(entry.name)
    element.source:SetText(entry.source)
    element.scope:SetText(entry.scope)
    element.value:SetText(tostring(entry.value))
    element.growth:SetText(tostring(entry.growth))
end

function DepopulateDefaultElement(element, entry)
    element.name:SetText("")
    element.source:SetText("")
    element.scope:SetText("")
    element.value:SetText("")
    element.growth:SetText("")
end

function CreateScrollableContent(area, create, populate, empty)

    local elements = { }

    -- compute size of an element
    local dummy = create(area, area)
    local width = dummy.Width()
    local height = dummy.Height()
    local n = math.floor(area.Height() / height)

    -- make list of elements
    local previous = Group(area)
    previous.Left:Set(function() return area.Left() end)
    previous.Right:Set(function() return area.Right() end)
    previous.Top:Set(function() return area.Top() end)
    previous.Bottom:Set(function() return area.Top() end)

    for k = 1, n do 
        elements[k] = create(area, previous)
        previous = elements[k]
    end

    UIUtil.CreateLobbyVertScrollbar(
        area,   -- calls functions on this
        0,      -- offset right
        0,      -- offset bottom
        0       -- offset top
    )

    -- populate it a bit
    area.UIElements = elements
    area.NumberOfUIElements = n 
    area.Elements = { }
    area.NumberOfElements = 0
    area.First = 0

    area.ProvideElements = function (self, elements, count)
        self.Elements = elements
        self.NumberOfElements = count
    end

    -- rangeMin, rangeMax, visibleMin, visibleMax
    area.GetScrollValues = function(self, axis)
        return 0, self.NumberOfElements, self.First, math.min(self.First + self.NumberOfUIElements, self.NumberOfElements)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    area.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    area.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta) * self.NumberOfUIElements)
    end

    -- called when the scrollbar wants to set a new visible top line
    area.ScrollSetTop = function(self, axis, top)

        -- compute where we end up
        local size = self.NumberOfElements
        first = math.max(math.min(size - self.NumberOfUIElements , math.floor(top)), 0) 

        -- check if it is different
        if first == self.First then return end

        -- if so, store it and compute what is visible
        self.First = first
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    area.IsScrollable = function(self, axis)
        return true
    end


    area.CalcVisible = function(self)
        for k = 1, self.NumberOfUIElements do 
            local index = k + self.First 
            if index <= self.NumberOfElements then 
                populate(self.UIElements[k], self.Elements[index])
            else 
                empty(self.UIElements[k])
            end
        end
    end
end
