local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")
local LazyVar = import("/lua/lazyvar.lua")

local defaultStyle = {
    message = {
        fontColor = LazyVar.Create('FFFFFFFF'),
        fontFamily = LazyVar.Create(UIUtil.bodyFont),
    },
    author = {
        fontColor = LazyVar.Create('FFFFFFFF'),
        fontFamily = LazyVar.Create("Arial Gras"),
    },
    fontSize = LazyVar.Create(tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14),
    shadow = false,
    lineSpacing = 1,
    padding = {
        left = 3,
        top = 2,
        right = 3,
        bottom = 2
    }
}

---@class ChatArea : Group
ChatArea = ClassUI(Group) {

    __init = function(self, parent, width, height)
        Group.__init(self, parent)
        self.ChatHistory = {}
        self.ChatLines = {}
        self.ChatHistoryActive = true

        self.Parent = parent
        self.Style = defaultStyle

        self.Width:Set(width)
        self.Height:Set(height)

        self.Width.OnDirty = function(lazyvar)
            LOG('chatArea dirty Width')
            self:ReflowLines()
        end
        self.Height.OnDirty = function(lazyvar)
            LOG('chatArea dirty Height')
            self:ReflowLines()
        end

        LayoutHelpers.AtLeftTopIn(self, parent)
    end,

    PostMessage = function(self, messageText, authorName, messageStyle, authorStyle)

        messageStyle = table.merged(defaultStyle.message, messageStyle or {})
        authorStyle = table.merged(defaultStyle.author, authorStyle or {})

        if self.ChatHistoryActive then
            local entry = {
                authorName = authorName,
                authorStyle = authorStyle,
                messageText = messageText,
                messageStyle = messageStyle
            }
            table.insert(self.ChatHistory, entry)
        end
        local name = authorName
        if authorName == nil then
            authorName = ''
        else

            authorName = '[' .. authorName .. '] '
        end
        messageText = messageText or ''

        local chatText = authorName .. messageText
        local customAdvanceFunction = function(chatText)
            return self:AdvanceFunction(chatText, messageStyle)
        end

        local wrapLines = Text.WrapText(chatText, self.Width() - self.Style.padding.left - self.Style.padding.right,
            customAdvanceFunction)

        for i = 1, table.getn(wrapLines) do
            if (i == 1 and string.len(authorName) > 0) then
                local strText = string.sub(wrapLines[i], string.len(authorName) + 1)
                table.insert(self.ChatLines, {
                    author = {
                        text = authorName,
                        style = authorStyle,
                        name = name
                    },
                    message = {
                        text = strText,
                        style = messageStyle
                    }
                })

            else
                table.insert(self.ChatLines, {
                    message = {
                        text = wrapLines[i],
                        style = messageStyle
                    }
                })
            end
        end
        if self.ChatHistoryActive then
            self:ShowLines(self.Parent.top, self.Parent.bottom)
        end
    end,

    CreateLines = function(self)
        local linesGroup = Group(self)
        LayoutHelpers.FillParent(linesGroup, self)
        linesGroup.Lines = {}
        local index = 1
        linesGroup.Lines[index] = self:CreateLine(linesGroup)
        local previous = linesGroup.Lines[index]
        LayoutHelpers.AtLeftTopIn(previous, linesGroup, self.Style.padding.left, self.Style.padding.top)
        while previous.Bottom() + previous.Height() + self.Style.padding.bottom < linesGroup.Bottom() do
            index = index + 1
            linesGroup.Lines[index] = self:CreateLine(linesGroup)
            LayoutHelpers.Below(linesGroup.Lines[index], previous, 2)
            previous = linesGroup.Lines[index]
        end
        self.linesGroup = linesGroup
        self.Parent.LinesOnPage:Set(index)
    end,

    CreateLine = function(self, parent)
        local line = Group(parent)
        LayoutHelpers.SetHeight(line, self.Style.lineSpacing + self.Style.fontSize())
        line.Width:Set(parent.Width)
        line:DisableHitTest()

        line.author = UIUtil.CreateText(line, '', self.Style.fontSize(), self.Style.author.fontFamily())
        LayoutHelpers.AtLeftTopIn(line.author, line)
        line.message = UIUtil.CreateText(line, '', self.Style.fontSize(), self.Style.message.fontFamily())
        LayoutHelpers.RightOf(line.message, line.author)

        line.Render = function(control, message, author)
            if author then
                control.author.name = author.name
                control.author:SetText(author.text)
                control.author:SetColor(author.style.fontColor)
            else
                control.author.name = nil
                control.author:SetText('')
            end
            if message then
                control.message:SetText(message.text)
                control.message:SetColor(message.style.fontColor)
            else
                control.message:SetText('')
            end
        end
        line.author.HandleEvent = function(control, event)
            if event.Type == 'ButtonPress' and control.name then
                self.Parent.edit:SetText('/w '.. control.name..' ')
            end
        end
        line.author:EnableHitTest()
        return line
    end,

    ShowLines = function(self, topIndex, bottomIndex)
        if IsDestroyed(self.linesGroup) then
            self:CreateLines()
        end
        bottomIndex = bottomIndex or table.getn(self.ChatLines)
        local visibleIndex = 1
        for id = topIndex, bottomIndex do
            local entry = self.ChatLines[id]
            local line = self.linesGroup.Lines[visibleIndex]
            if line then
                if entry then
                    line:Render(entry.message, entry.author)
                else
                    line:Render()
                end
            end
            visibleIndex = visibleIndex + 1
        end
    end,

    ClearHistory = function(self)
        self:ClearLines()
        self.ChatHistory = {}
    end,

    ClearLines = function(self)
        self.ChatLines = {}
        if not IsDestroyed(self.linesGroup) then
            self.linesGroup:Destroy()
            self.linesGroup = nil
        end
    end,

    ReflowLines = function(self)
        self:ClearLines()
        self:CreateLines()
        self.ChatHistoryActive = false
        for _, message in self.ChatHistory do
            self:PostMessage(message.messageText, message.authorName, message.messageStyle, message.authorStyle)
        end
        self.ChatHistoryActive = true
        self:ShowLines(self.Parent.top, self.Parent.bottom)
    end,

    --- sets font family and/or font size in all chat messages
    --- @param - fontFamily is optional parameter
    --- @param - fontSize is optional parameter
    SetFont = function(self, fontFamily, fontSize)
        local hasFontFamily = type(fontFamily) == 'string'
        local hasFontSize = type(fontSize) == 'number'

        if hasFontFamily then
            self.Style.message.fontFamily:Set(fontFamily)
        end
        if hasFontSize then
            self.Style.fontSize:Set(fontSize)
            self:ReflowLines()
        end
    end,

    AdvanceFunction = function(self, str, strStyle)
        local dummy = Text.Text(self.Parent)
        dummy:Hide()
        dummy:SetFont(strStyle.fontFamily(), self.Style.fontSize())
        dummy:SetText(str)
        local width = dummy:Width()
        dummy:Destroy()
        return width
    end,

    OnDestroy = function(self)
        self:ClearLines()
        self.ChatHistory = nil
        Group.OnDestroy(self)
    end
}
