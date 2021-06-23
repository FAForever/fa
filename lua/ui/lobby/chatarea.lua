local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local Emojis =  import('/lua/ui/lobby/emojis.lua')



--- Represents a control that keep tracks and displays chat messages and their author's names
ChatArea = Class(Group){

    __init = function(self, parent, width, height)
        Group.__init(self, parent)

        -- initializing some tables for managing and storing chat lines that will display messages

        -- this table stores lines that are represented using multiple UI Group classes.
        -- Each line can have multiple TextFields and each TextField can have its own style
        -- All chat lines are indexed by the order in which they were created - so older messages are first
        self.ChatLines = {} -- for example:
        -- ChatLines = {
        --   { TextFields = { { text = "Mike" }, { text = "Hi Dave, How are you?" } } },
        --   { TextFields = { { text = "Dave" }, { text = "I'm fine, how are you" } } }
        --}

        -- this table stores all messages added to the ChatArea and the ReflowLines() will use this table
        -- to re-create and layout ChatLines if size of the ChatArea is changed or if fontSize is changed in lobby
        -- The chat history is indexed by the order in which they were added - so older messages are first
        self.ChatHistory = {} -- for example:
        -- ChatHistory = {
        --   { authorName = "Mike", messageText = "Hi Dave, How are you?" },
        --   { authorName = "Dave", messageText = "I'm fine, how are you?" },
        --}

        -- specifies whether or not to save new messages in chat history
        self.ChatHistoryActive = true

        self.Style = self:GetDefaultStyle()
        self.Parent = parent

        -- iInitial width and height are necessary to dodge partial-initialization/re-flow weirdness.
        self.Width:Set(width)
        self.Height:Set(height)

        -- re-flow chat lines when the width is changed.
        self.Width.OnDirty = function()
            LOG('chatArea dirty Width')
            self:ReflowLines()
        end
        self.Height.OnDirty = function()
            LOG('chatArea dirty Height')
            self:ReflowLines()
        end

        LayoutHelpers.AtLeftTopIn(self, parent, 0, 0)
    end,

    GetDefaultStyle = function(self)
        return {
            -- storing style values in a flat table for easy access
            fontColor = 'FFFFFFFF', --#FFFFFFFF
            fontFamily = UIUtil.bodyFont,
            fontSize = tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14,

            shadow = false,
            lineSpacing = 1, -- don't use higher values because chat looks strange with small fonts
            padding = { left = 0, top = 3, right = 3, bottom = 3 },
        }
    end,

    --- posts a new chat message and its author name using optional styling tables
    PostMessage = function(self, messageText, authorName, messageStyle, authorStyle)

        -- WARNING
        -- The author style must be _roughly_ the same in font size and weight than the text style.
        -- Too different values might break the text wrapping, because the Text.Wrap method doesn't take style as a parameter.

        local defaultStyle = self:GetDefaultStyle()
        -- ensure we have a style for the message text
        if messageStyle == nil then
           messageStyle = self:GetDefaultStyle()
        else
            -- ensure message style has all required values otherwise use values of default style
            for k,v in pairs(defaultStyle) do
                if messageStyle[k] == nil then
                   messageStyle[k] = defaultStyle[k]
                end
            end
        end

        -- ensure we have a style for the author name
        if authorStyle == nil then
            authorStyle = self:GetDefaultStyle()
            authorStyle.fontFamily = "Arial Gras"
        else
            -- ensure author style has all required values otherwise use values of default style
            for k,v in pairs(defaultStyle) do
                if authorStyle[k] == nil then
                   authorStyle[k] = defaultStyle[k]
                end
            end
        end
        -- avoid waste horizontal space
        authorStyle.padding.left = 0
        authorStyle.padding.right = 0

        -- always use bolder font for the Author name

        -- keep track of chat history by storing messages and their authors
        if self.ChatHistoryActive then
            local entry = {}
            entry.authorName = authorName
            entry.authorStyle = authorStyle
            entry.messageText = messageText
            entry.messageStyle = messageStyle
            table.insert(self.ChatHistory, entry)
        end

        

        if authorName == nil then
            authorName = ''
        else
            authorName = '['..authorName..'] '
        end
        if messageText == nil then
            messageText = ''
        end
        local contents = self:WrapContents({
                                                text = Emojis.CheckEmojis(messageText,Prefs.GetFromCurrentProfile("ChatLobbyEmojis")),
                                                style = messageStyle
                                            },
                                            {
                                                text = authorName,
                                                style = authorStyle
                                            },
                                            self.Width() - self.Style.padding.left - self.Style.padding.right)
        -- If no author provided, we're simply going to skip it. Else we're going to style it
        
        
        

        -- group wrapped text in to lines and text fields
        for i = 1, table.getn(contents) do
            if (i == 1 and string.len(authorName) > 0) then
                self:CreateLine(contents[i],messageStyle,authorName,authorStyle)
            else
                self:CreateLine(contents[i],messageStyle)
            end
        end 
    end,

    
    
    --- create a new line and arranges its layout position based on line's index
    CreateLine = function(self,contents,messageStyle,authorName,authorStyle)
    
        local line = Group(self)
        local lineSpacing = self.Style.lineSpacing/2
        line.Height:Set(messageStyle.fontSize + self.Style.lineSpacing)
        line.Width:Set(self.Width)
        line:DisableHitTest()
        line.index = table.getsize(self.ChatLines) + 1
        
        line.name = UIUtil.CreateText(line, '', messageStyle.fontSize, messageStyle.fontFamily)
        LayoutHelpers.AtLeftTopIn(line.name, line)
        
        line.name:DisableHitTest()
        if authorName then
            line.name:SetText(authorName)
            line.name:SetColor(authorStyle.fontColor)
            line.name:SetFont(authorStyle.fontFamily,authorStyle.fontSize)
        end
        --line.contents = Group(line)
        local parent = nil
        for _,content in contents do
            if content.text then --TEXT
                if parent then
                    parent.child = UIUtil.CreateText(parent, content.text, messageStyle.fontSize, messageStyle.fontFamily)
                    LayoutHelpers.RightOf(parent.child, parent,2)
                    LayoutHelpers.AtVerticalCenterIn(parent.child, parent,lineSpacing)
                    parent.child:DisableHitTest()
                    parent.child:SetColor(messageStyle.fontColor)
                    parent.child:SetClipToWidth()
                    parent = parent.child
                else    
                    line.contents = UIUtil.CreateText(line, content.text, messageStyle.fontSize, messageStyle.fontFamily)
                    LayoutHelpers.RightOf(line.contents, line.name)
                    LayoutHelpers.AtVerticalCenterIn(line.contents, line.name,lineSpacing)
                    line.contents:DisableHitTest()
                    line.contents:SetColor(messageStyle.fontColor)
                    line.contents:SetClipToWidth()
                    parent = line.contents
                end

            elseif content.emoji then--EMOJIES
                if parent then
                   
                    parent.child = Bitmap(parent,UIUtil.UIFile(Emojis.emojis_textures .. content.emoji .. '.dds'))
                    LayoutHelpers.RightOf(parent.child, parent,2)
                    LayoutHelpers.AtVerticalCenterIn(parent.child, parent,lineSpacing)
                    parent.child.Height:Set(line.Height)
                    parent.child.Width:Set(line.Height)
                    parent = parent.child
                   
                else
                    line.contents = Bitmap(line, UIUtil.UIFile(Emojis.emojis_textures .. content.emoji .. '.dds'))
                    LayoutHelpers.RightOf(line.contents, line.name)
                    LayoutHelpers.AtVerticalCenterIn(line.contents, line.name,lineSpacing)
                    line.contents.Height:Set(line.Height)
                    line.contents.Width:Set(line.Height)
                    parent = line.contents
                end
            end
        end

        -- layout the new line based on its index
        if line.index == 1 then
           LayoutHelpers.AtLeftTopIn(line, self, 0, self.Style.padding.top)
        else
           -- putting the line below previous line
           line.previous = self.ChatLines[line.index - 1]
           line.Left:Set(function() return self.Left() end)
           LayoutHelpers.Below(line, line.previous)
        end
        -- store the new line so we can destroy all lines later
        table.insert(self.ChatLines, line)

        -- keep track of the last line so we do not need to search for it
        self.lastLine = line
        return line
    end,

    --- shows lines between specified indexes and hides all other lines
    ShowLines = function(self, topIndex, bottomIndex)
        local visibleIndex = 1
        for _, line in ipairs(self.ChatLines) do
            if visibleIndex < topIndex or visibleIndex >= bottomIndex then
                line:Hide() -- hide lines outside top and bottom index
            else
                line:Show() -- show lines between top and bottom index
                local i = visibleIndex
                local c = line
                -- calculate top position of a line based on its visible index
                line.Top:Set(function() return self.Top() + ((i - topIndex) * (c.Height() + 2)) end)
            end
            visibleIndex = visibleIndex + 1
        end
    end,

    --- clears existing chat history and its UI representation
    ClearHistory = function(self)
        self:ClearLines()
        self.ChatHistory = {}
    end,

    --- clears existing chat lines by destroying and dereferencing its UI elements
    ClearLines = function(self)
       -- LOG('chatArea ClearLines')
        for l, line in self.ChatLines or {} do
            line:Destroy()
            line = nil
        end
        self.ChatLines = {}
        self.lastLine = nil
    end,

    --- recreates the old lines with the newly-wrapped chat messages
    ReflowLines = function(self)
        self:ClearLines()

        -- temporary deactivate Chat history while re-creating chat lines
        self.ChatHistoryActive = false
        for _, chat in self.ChatHistory or {} do
            self:PostMessage(chat.messageText, chat.authorName,
                               chat.messageStyle, chat.authorStyle)
        end
        self.ChatHistoryActive = true
    end,

    --- sets font family and/or font size in all chat messages
    --- @param - fontFamily is optional parameter
    --- @param - fontSize is optional parameter
    SetFont = function(self, fontFamily, fontSize)
        local hasFontFamily = type(fontFamily) == 'string'
        local hasFontSize = type(fontSize) == 'number'

        if self.fontSize == fontSize and
           self.fontFamily == fontFamily then 
           return -- skip if the font did not changed
        else
            self.fontSize = fontSize
            self.fontFamily = fontFamily
        end
        -- updating styles of authors and messages
        for _, chat in self.ChatHistory or {} do
            if hasFontFamily then
                chat.authorStyle.fontFamily = fontFamily
                chat.messageStyle.fontFamily = fontFamily
            end
            if hasFontSize then
                chat.authorStyle.fontSize = fontSize
                chat.messageStyle.fontSize = fontSize
            end
        end
        -- recreate chat lines with new font family and font size
        self:ReflowLines()
    end,

    --- gets the width of text field that would displayed the string passed as argument
    AdvanceFunction = function(self, str, strStyle)
        -- Creates a dummy text to measure width
        dummy = Text.Text(self.Parent)
        dummy:Hide()
        dummy:SetFont(strStyle.fontFamily, strStyle.fontSize)
        dummy:SetText(str)
        local width = dummy:Width()
        dummy:Destroy()
        return width
    end,

    --- destroys safely all current chat lines and chat history
    OnDestroy = function(self)
        self:ClearLines()
        self.ChatLines = nil
        self.ChatHistory = nil
        Group.OnDestroy(self)
    end,

    WrapContents = function(self,contents,name,linewidth)
        return self:FitContentsInLine(contents.text, contents.style.fontSize + self.Style.lineSpacing,
            function(line)
                if line == 1 then
                    return linewidth - self:AdvanceFunction(name.text, name.style) - 4
                else
                    return linewidth - 4
                end
            end, 
            function(text)
                return self:AdvanceFunction(text, contents.style)
            end)
    end,

    FitContentsInLine = function (self,contents, lineHeight, lineWidth, GetStringAdvance)
        local result_lines = {}
        local result_line = {}
        local lineIndex = 1
        local CurShift = 0
        for _,content in contents do
            if content.text then
                local textWidth = GetStringAdvance(content.text)
                if CurShift + textWidth + 2 < lineWidth(lineIndex) then
                    table.insert(result_line, content)
                    CurShift = CurShift + textWidth + 2
                    continue
                else
                    local fittedText = import('/lua/maui/text.lua').WrapText(content.text,
                                                        function(line)
                                                            if line == 1 then
                                                                return lineWidth(lineIndex) - CurShift - 2
                                                            else
                                                                return lineWidth(lineIndex + 1)
                                                            end
                                                        end,
                                                    GetStringAdvance)
                    local fitTextNum = table.getn(fittedText)
                    table.insert(result_line, {text = fittedText[1]})
                    table.insert(result_lines, result_line)
                    lineIndex = 2
                    for i = 2,fitTextNum-1 do
                        table.insert(result_lines, {{text = fittedText[i]}})
                    end
                    CurShift = GetStringAdvance(fittedText[fitTextNum]) + 2
                    result_line = {{text = fittedText[fitTextNum]}}
                    continue
                end
            elseif content.emoji then
                if CurShift + lineHeight + 2 < lineWidth(lineIndex) then
                    table.insert(result_line, content)
                    CurShift = CurShift + lineHeight + 2
                    continue
                else
                    table.insert(result_lines, result_line)
                    result_line = {content}
                    CurShift =  lineHeight + 2
                    lineIndex = 2
                end
            end
        end
        table.insert(result_lines, result_line)
        return result_lines
    end,
}