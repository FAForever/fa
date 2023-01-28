local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Window = import("/lua/maui/window.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")
local Text = import("/lua/maui/text.lua").Text
local GameMain = import("/lua/ui/game/gamemain.lua")
local Edit = import("/lua/maui/edit.lua").Edit

-- TODO 
-- move to other class
function CreateDefaultElement(parent, alignment)
    local group = Group(parent)
    group.Left:Set(parent.Left)
    group.is_group = true
    group.Right:Set(parent.Right)
    group.Top:Set(alignment.Bottom)
    LayoutHelpers.AtBottomIn(group, alignment, -16)
    local highlightColor = 'ffffff00'
    local function MakeText(parent, text)
        return UIUtil.CreateText(parent, text, 14, UIUtil.bodyFont, false)
    end

    group.name = MakeText(group, "function")
    LayoutHelpers.AtLeftIn(group.name, group, 10)
    LayoutHelpers.AtTopIn(group.name, group)

    group.source = MakeText(group, "source")
    LayoutHelpers.FromLeftIn(group.source, group, 0.45)
    LayoutHelpers.AtTopIn(group.source, group)

    group.scope = MakeText(group, "scope")
    LayoutHelpers.FromLeftIn(group.scope, group, 0.60)
    LayoutHelpers.AtTopIn(group.scope, group)

    group.value = MakeText(group, "value")
    LayoutHelpers.FromLeftIn(group.value, group, 0.75)
    LayoutHelpers.AtTopIn(group.value, group)

    group.growth = MakeText(group, "growth")
    LayoutHelpers.FromLeftIn(group.growth, group, 0.9)
    LayoutHelpers.AtTopIn(group.growth, group)
    group.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            self:ApplyFunction(function(control)
                if not control.is_group then
                    control:SetColor(highlightColor)
                end
            end)
            return true
        elseif event.Type == 'MouseExit' then
            self:ApplyFunction(function(control)
                if not control.is_group then
                    control:SetColor(UIUtil.fontColor)
                end
            end)
            return true
        end
    end
    return group
end

function CreateTitle(parent, alignment)
    local group = Group(parent)
    group.Left:Set(parent.Left)
    group.Right:Set(parent.Right)
    group.Top:Set(alignment.Top)
    LayoutHelpers.SetHeight(group, 20)

    local font = UIUtil.titleFont
    local color = 'ffF1F382'
    group.name = UIUtil.CreateText(group, "function", 16, font, false)
    group.name:SetColor(color)
    LayoutHelpers.AtLeftIn(group.name, group, 10)
    LayoutHelpers.AtTopIn(group.name, group, 0.0)

    group.source = UIUtil.CreateText(group, "source", 16, font, false)
    group.source:SetColor(color)
    LayoutHelpers.FromLeftIn(group.source, group, 0.45)
    LayoutHelpers.AtTopIn(group.source, group, 0.0)

    group.scope = UIUtil.CreateText(group, "scope", 16, font, false)
    group.scope:SetColor(color)
    LayoutHelpers.FromLeftIn(group.scope, group, 0.60)
    LayoutHelpers.AtTopIn(group.scope, group, 0.0)

    group.value = UIUtil.CreateText(group, "value", 16, font, false)
    group.value:SetColor(color)
    LayoutHelpers.FromLeftIn(group.value, group, 0.75)
    LayoutHelpers.AtTopIn(group.value, group, 0.0)

    group.growth = UIUtil.CreateText(group, "growth", 16, font, false)
    group.growth:SetColor(color)
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

function DepopulateDefaultElement(element)
    element:ApplyFunction(function(control)
        if not control.is_group then
            control:SetText("")
        end
    end)
end

---@class ProfilerScrollArea : Group
ProfilerScrollArea = ClassUI(Group) {
    __init = function(self, parent)
        Group.__init(self, parent)
        self.bg = Bitmap(self)
        self.bg:SetSolidColor('ff000000')
        LayoutHelpers.DepthUnderParent(self.bg, self)
        LayoutHelpers.FillParent(self.bg, self)
        self.bg:SetAlpha(0.5)
        self._scrollable = false
    end,

    InitScrollableContent = function(self)
        local elements = {}

        -- compute size of an element
        local title = CreateTitle(self, self)
        local dummy = CreateDefaultElement(self, self)
        local width = dummy.Width()
        local height = dummy.Height()
        dummy:Destroy()
        local n = math.floor((self.Height() - title.Height()) / height)

        -- make list of elements

        local previous = title
        for k = 1, n do
            elements[k] = CreateDefaultElement(self, previous)
            previous = elements[k]
        end

        UIUtil.CreateLobbyVertScrollbar(self, -- calls functions on this
        0, -- offset right
        0, -- offset bottom
        0 -- offset top
        )

        -- populate it a bit
        self.UIElements = elements
        self.NumberOfUIElements = n
        self.Elements = {}
        self.NumberOfElements = 0
        self.First = 0
        self._scrollable = true
    end,

    ProvideElements = function(self, elements, count)
        self.Elements = elements
        self.NumberOfElements = count
    end,

    -- rangeMin, rangeMax, visibleMin, visibleMax
    GetScrollValues = function(self, axis)
        return 0, self.NumberOfElements, self.First,
            math.min(self.First + self.NumberOfUIElements, self.NumberOfElements)
    end,

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta))
    end,

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.First + math.floor(delta) * self.NumberOfUIElements)
    end,

    -- called when the scrollbar wants to set a new visible top line
    ScrollSetTop = function(self, axis, top)

        -- compute where we end up
        local size = self.NumberOfElements
        local first = math.max(math.min(size - self.NumberOfUIElements, math.floor(top)), 0)

        -- check if it is different
        if first == self.First then
            return
        end

        -- if so, store it and compute what is visible
        self.First = first
        self:CalcVisible()
    end,

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    IsScrollable = function(self, axis)
        return self._scrollable
    end,

    CalcVisible = function(self)
        for k = 1, self.NumberOfUIElements do
            local index = k + self.First
            if index <= self.NumberOfElements then
                PopulateDefaultElement(self.UIElements[k], self.Elements[index])
            else
                DepopulateDefaultElement(self.UIElements[k])
            end
        end
    end,

    HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' and self:IsScrollable() then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
        end
    end

}
