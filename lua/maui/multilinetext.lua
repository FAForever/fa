local Control = import("/lua/maui/control.lua").Control
local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua").Text
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local LazyVar = import("/lua/lazyvar.lua")

--TODO make scrollable
--TODO word wrap

---@class MultiLineText : Group
MultiLineText = ClassUI(Group) {
    __init = function(self, parent, font, pointSize, color)
        Group.__init(self, parent)

        self._numLines = LazyVar.Create()
        self._font = font
        self._pointSize = pointSize
        self._color = color
        self._dropShadow = false
        self._text = {}
        self._centered = false
        -- set up first text line as it will be used for calculations as well as there must always be one line
        self._text[1] = Text(parent)
        LayoutHelpers.AtLeftTopIn(self._text[1], self)
        if self._centered then
            LayoutHelpers.AtHorizontalCenterIn(self._text[line], self)
        end
        self._text[1]:SetFont(font, pointSize)
        self._text[1]:SetText("")
        self._text[1]:SetColor(color)
        self._text[1]:SetDropShadow(self._dropShadow)

        -- when numLines changes, we need create/destroy lines
        self._numLines.OnDirty = function(var)
            local newNumLines = var()
            local curNumLines = table.getn(self._text)
            if curNumLines > newNumLines then
                -- remove lines
                for line = newNumLines + 1, curNumLines do
                    self._text[line]:Destroy()
                    self._text[line] = nil
                end
            elseif curNumLines < newNumLines then
                -- add lines
                for line = curNumLines + 1, newNumLines do
                    self._text[line] = Text(parent)
                    self._text[line]:SetFont(self._font, self._pointSize)
                    self._text[line]:SetText("")
                    self._text[line]:SetColor(self._color)
                    self._text[line]:SetDropShadow(self._dropShadow)
                    if self:IsHitTestDisabled() then
                        self._text[line]:DisableHitTest()
                    end
                    if self._centered then
                        LayoutHelpers.CenteredBelow(self._text[line], self._text[line - 1])
                    else
                        LayoutHelpers.Below(self._text[line], self._text[line - 1])
                    end
                end
            end
        end

        -- our height will always be at least the height of line one
        self.Height:Set(self._text[1].Height)
        
        -- always at least one line, but don't show partial lines
        self._numLines:Set(function() return math.floor(self.Height() / self._text[1].Height()) or 1 end)
    end,

    SetText = function(self, text)
        self:Clear()
        local wrappedText = import("/lua/maui/text.lua").WrapText(text, self:Width(), 
            function(text) 
                return self._text[1]:GetStringAdvance(text) 
            end)
        self._numLines:Set(table.getsize(wrappedText))
--        LOG(self._numLines(), ":", table.getsize(wrappedText))
--        for i, v in self._numLines do
--            LOG("NumLines:",i,":",v)
--        end
        for line = 1, self._numLines() do
            if wrappedText[line] then
                self._text[line]:SetText(wrappedText[line])
            else
                break
            end
        end
    end,
    
    SetCenteredHorizontally = function(self, isCentered)
        self._centered = isCentered
        for line = 1, self._numLines() do
            if line == 1 then
                if self._numLines() == 1 and self._centered then
                    LayoutHelpers.AtCenterIn(self._text[1], self)
                else
                    LayoutHelpers.AtLeftTopIn(self._text[1], self)
                end
            else
                LayoutHelpers.Below(self._text[line], self._text[line - 1])
            end
            if self._centered then
                LayoutHelpers.AtHorizontalCenterIn(self._text[line], self)
            end
        end
    end,
    
    Clear = function(self)
        for line = 1, self._numLines() do
            self._text[line]:SetText("")
        end
    end,

    SetColor = function(self, color)
        for line = 1, self._numLines() do
            self._text[line]:SetColor(color)
        end
    end,

    -- sets the last line of text to specified string, and moves all other lines of text up
    PushTextBottom = function(self, text)
        for line = 1, self._numLines() - 1 do
            self._text[line]:SetText(self._text[line + 1]:GetText())
        end
        self._text[self._numLines()]:SetText(text)
    end,

    DisableHitTest = function(self)
        Group.DisableHitTest(self)
        for line = 1, self._numLines() do
            self._text[line]:DisableHitTest()
        end
    end,

    EnableHitTest = function(self)
        Group.EnableHitTest(self)
        for line = 1, self._numLines() do
            self._text[line]:EnableHitTest()
        end
    end,

    SetDropShadow = function(self,bval)
        self._dropShadow = bval
        for line = 1, self._numLines() do
            self._text[line]:SetDropShadow(bval)
        end
    end,
    
    GetLineHeight = function(self)
        return self._text[1].FontAscent() + self._text[1].FontDescent()
    end,
}
