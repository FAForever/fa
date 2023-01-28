-- Class methods:
-- SetNewFont(family, pointsize)
-- SetNewColor(color)
-- SetText(text)
-- string GetText()
-- SetDropShadow(bool)
-- SetNewClipToWidth(bool)
-- SetCenteredVertically(bool)
-- SetCenteredHorizontally(bool)

local Control = import("/lua/maui/control.lua").Control
local ScaleNumber = import("/lua/maui/layouthelpers.lua").ScaleNumber

---@class Text : moho.text_methods, Control, InternalObject
Text = ClassUI(moho.text_methods, Control) {

    __init = function(self, parent, debugname)
        InternalCreateText(self, parent)
        if debugname then
            self:SetName(debugname)
        end

        local LazyVar = import("/lua/lazyvar.lua")
        self._lockFontChanges = false
        self._font = {_family = LazyVar.Create(), _pointsize = LazyVar.Create()}
        self._font._family.OnDirty = function(var)
            self:_internalSetFont()
        end
        self._font._pointsize.OnDirty = function(var)
            self:_internalSetFont()
        end

        self._color = LazyVar.Create()
        self._color.OnDirty = function(var)
            self:SetNewColor(var())
        end
    end,

    OnInit = function(self)
        Control.OnInit(self)
        self.Height:Set(function() return math.floor(self.FontAscent() + self.FontDescent()) end)
        self:SetClipToWidth(false)
    end,

    SetClipToWidth = function(self, clipToWidth)
        if clipToWidth then
            self.Width:Set(function() return self.Right() - self.Left() end)
        else
            self.Width:Set(function() return math.floor(self.TextAdvance()) end)
        end
        self:SetNewClipToWidth(clipToWidth)
    end,

    -- lazy var support
    SetFont = function(self, family, pointsize)
        if self._font then
            self._lockFontChanges = true
            self._font._pointsize:Set(ScaleNumber(pointsize))
            self._font._family:Set(family)
            self._lockFontChanges = false
            self:_internalSetFont()
        end
    end,

    _internalSetFont = function(self)
        if not self._lockFontChanges then
            self:SetNewFont(self._font._family(), self._font._pointsize())
        end
    end,


    StreamText = function(self, text, speed)
        if not speed then speed = 20 end
        local goalText = text
        self:SetText('')
        self:SetNeedsFrameUpdate(true)
        self.ElapsedTime = 0
        self.OnFrame = function(self, deltaTime)
            self.ElapsedTime = self.ElapsedTime + deltaTime
            if STR_Utf8Len(goalText) > STR_Utf8Len(self:GetText()) then
                self:SetText(STR_Utf8SubString(goalText, 1, math.floor(self.ElapsedTime * speed)))
            else
                self:SetNeedsFrameUpdate(false)
            end
        end
    end,

    SetColor = function(self, color)
        if self._color then
            self._color:Set(color)
        end
    end,

    OnDestroy = function(self)
        if self._font then
            if self._font._family then
                self._font._family:Destroy()
            end
            if self._font._pointsize then
                self._font._pointsize:Destroy()
            end
            self._font = nil
        end
        if self._color then
            self._color:Destroy()
            self._color = nil
        end
    end,
}

-- Given line widths, break text in to strings that will fit each line, based completely on characters
-- and ignoring spaces (ie words may be broken up in the middle)
function FitText(text, lineWidth, advanceFunction)
    local lineWidthFunc
    if type(lineWidth) == 'number' then
        lineWidthFunc = function(line)
            return lineWidth
        end
    else
        lineWidthFunc = lineWidth
    end

    local result = {}
    local curLine = 1
    local textLen = STR_Utf8Len(text)
    local lineStartChar = 1
    if textLen > 1 then
        for ch = 2, textLen do
            local sub = STR_Utf8SubString(text, lineStartChar, (ch + 1) - lineStartChar)
            if math.ceil(advanceFunction(sub)) >= lineWidthFunc(curLine) then
                result[curLine] = STR_Utf8SubString(text, lineStartChar, ch - lineStartChar)
                curLine = curLine + 1
                lineStartChar = ch
            end
        end
        if lineStartChar < textLen then
            result[curLine] = STR_Utf8SubString(text, lineStartChar, textLen + 1 - lineStartChar)
        end
    else
        result[1] = text
    end

    return result
end

-- Wrap text given a set of inputs, returns a array of the text, each index representing a new line
-- text - the string to wrap
-- lineWidth - can be a number or function with the signature int function(lineNumber)
--  when it's a number, it represents how wide each line is in pixels
--  when it's a function, gets the line width for each line
-- advanceFunction - a function with the signature int function(string) which returns the width in pixels of the string passed in
function WrapText(text, lineWidth, advanceFunction)
    -- Chinese doesn't have spaces, so fit it in to lines without trying to wrap words
    if __language == 'cn' then
        return FitText(text, lineWidth, advanceFunction)
    end

    local result = {}
    local pos = 0
    local curLine = 1
    local spaceWidth = advanceFunction(" ")

    local lineWidthFunc = lineWidth
    if type(lineWidth) == 'number' then
        lineWidthFunc = function(line)
            return lineWidth
        end
    end

    -- the gfind here splits the text up in to a table of all the "words" in the string delineated by spaces or tabs
    -- then the word is checked to see if contains line feeds, and splits out all the words delineated by line feeds
    -- then each set of words is added to the result table, where each entry denotes a line of text
    for packedWord in string.gfind(text, "[^ \t]+") do
        local words = {}
        local lfStartIndex = string.find(packedWord, "\n")  -- the first line feed in the text (if any), prime the while pump
        local bytes = string.len(packedWord) -- the number of bytes in the packed word
        local curIndex = 1
        if lfStartIndex then
            -- split out new lines from packedWords and make them their own entry in the table
            while lfStartIndex do
                if lfStartIndex - curIndex > 0 then
                    -- found a word before this line feed, so get it and push in to the word list
                    table.insert(words, string.sub(packedWord, curIndex, lfStartIndex - 1))
                end
                -- add the line feed to the word list
                table.insert(words, "\n")
                -- pass the line feed
                curIndex = lfStartIndex + 1
                -- find the next line feed
                lfStartIndex = string.find(packedWord, "\n", curIndex)
                -- pick up any trailing word
                if not lfStartIndex and curIndex < bytes then
                    table.insert(words, string.sub(packedWord, curIndex, bytes))
                end
            end
        else
            -- if no line feeds, it's just a single word, so insert it to the words list
            table.insert(words, packedWord)
        end

        -- loop through the words found in this packed word
        for index, word in words do

            -- if the current word is a linefeed, just add an ampty string and update the line count
            if word == "\n" then
                if not result[curLine] then result[curLine] = "" end    -- result can't have nil lines
                curLine = curLine + 1
                pos = 0
                continue
            end

            -- calculate the pixel size of the current word
            local wordWidth = advanceFunction(word)

            -- if the word is longer than the max width, break it up in to multiple lines
            if wordWidth > lineWidthFunc(curLine) then
                if result[curLine] then
                    curLine = curLine + 1
                end

                wordWidth = 0
                local lineWidth = lineWidthFunc(curLine)
                local startIndex = 1
                local letterIndex = 1
                local letter = ""
                for letterIndex = 1, STR_Utf8Len(word) do
                    letter = STR_Utf8SubString(word, letterIndex, 1)
                    letterWidth = advanceFunction(letter)
                    if wordWidth + letterWidth > lineWidth then
                        result[curLine] = STR_Utf8SubString(word, startIndex, letterIndex - startIndex)
                        curLine = curLine + 1
                        startIndex = letterIndex
                        pos = 0
                        wordWidth = 0
                        lineWidth = lineWidthFunc(curLine)
                    end
                    wordWidth = wordWidth + letterWidth
                end
                local sLen = STR_Utf8Len(word)
                result[curLine] = STR_Utf8SubString(word, startIndex, sLen - startIndex + 1)
                pos = wordWidth
                if wordWidth + spaceWidth < lineWidth then
                    result[curLine] = result[curLine] .. " "
                    pos = pos + spaceWidth
                else
                    curLine = curLine + 1
                    pos = 0
                end
            else
                -- if the word will fit on this line, then add the word to the line
                -- otherwise, start the word on the next line
                if pos + wordWidth < lineWidthFunc(curLine) then
                    -- if the line exits, append to the line, otherwise make it the first word
                    if result[curLine] then
                        result[curLine] = result[curLine] .. word .. " "
                    else
                        result[curLine] = word .. " "
                    end
                else
                    curLine = curLine + 1
                    pos = 0
                    result[curLine] = word .. " "   -- note this is always on a new line
                end

                -- update the pixel position where the word is placing itself, and add a space
                pos = pos + wordWidth + spaceWidth
            end
        end
    end
    return result
end
