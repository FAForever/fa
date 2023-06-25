local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua").Text
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Edit = import("/lua/maui/edit.lua").Edit
local Prefs = import("/lua/user/prefs.lua")

-- maximum accepted file name size
maxFilenameSize = 30

-- error messages
errorMsg = {
    zero = "<LOC filepicker_0000>A filename must have at least one character",
    toolong = "<LOC filepicker_0001>A filename can contain no more than %d characters",
    invalidchars = "<LOC filepicker_0002>A filename can not contain the characters \\ / : * ? < > | \" ' .",
    invalidlast = "<LOC filepicker_0006>A filename can not begin or end with a space or a period",
    invalidname = "<LOC filepicker_0007>You have requested an invalid file name",
}

local invalidCharSet = {
    [9] = true,    -- tab
    [92] = true,   -- \
    [47] = true,   -- /
    [58] = true,   -- :
    [42] = true,   -- *
    [63] = true,   -- ?
    [60] = true,   -- <
    [62] = true,   -- >
    [124] = true,  -- |
    [39] = true,   -- '
    [34] = true,   -- "
    [46] = true,   -- .
}

local columConfigurations = {
    {
        {title = '<LOC _Name>', width = 435, sortby = 'name', key = 'name'},
        {title = '<LOC Date>', width = 130, sortby = 'TimeStamp', key = 'date'},
    },
    {
        {title = '<LOC _Name>', width = 267, sortby = 'name', key = 'name'},
        {title = '<LOC tooltipui0147>', width = 150, sortby = 'profile', key = 'owner'},
        {title = '<LOC Date>', width = 130, sortby = 'TimeStamp', key = 'date'},
    },
}

local invalidStringSet = {
    ['\\'] = true,
    ['/'] = true,
    [':'] = true,
    ['*'] = true,
    ['?'] = true,
    ['<'] = true,
    ['>'] = true,
    ['|'] = true,
    ["'"] = true,
    ['"'] = true,
    ['%.'] = true,
}

local invalidNameSet = {
    ["CON"] = true,
    ["PRN"] = true,
    ["AUX"] = true,
    ["CLOCK$"] = true,
    ["NUL"] = true,
    ["COM0"] = true,
    ["COM1"] = true,
    ["COM2"] = true,
    ["COM3"] = true,
    ["COM4"] = true,
    ["COM5"] = true,
    ["COM6"] = true,
    ["COM7"] = true,
    ["COM8"] = true,
    ["COM9"] = true,
    ["LPT0"] = true,
    ["LPT1"] = true,
    ["LPT2"] = true,
    ["LPT3"] = true,
    ["LPT4"] = true,
    ["LPT5"] = true,
    ["LPT6"] = true,
    ["LPT7"] = true,
    ["LPT8"] = true,
    ["LPT9"] = true,
}

-- this function tests a character to see if it's invalid in a file name
---@param charcode string
---@return boolean
function IsCharInvalid(charcode)
    return invalidCharSet[charcode] or false
end

-- tests a filename for several validity issues, returns error code key
---@param filename FileName
---@return string
function IsFilenameInvalid(filename)
    -- check for nil
    if not filename then
        return 'zero'
    end

    local len = STR_Utf8Len(filename)

    -- check length
    if len == 0 then
        return 'zero'
    end

    if len > maxFilenameSize then
        return 'toolong'
    end

    -- check for invalid chars
    for char, val in invalidStringSet do
        if string.find(filename, char) then
            return 'invalidchars'
        end
    end

    -- last characher may not be space or .
    local lastChar = string.sub(filename, len)
    if lastChar == " " or lastChar == "." then
        return 'invalidlast'
    end

    local firstChar = string.sub(filename, 1, 1)
    if firstChar == " " or firstChar == "." then
        return 'invalidlast'
    end

    -- check for invalid names
    if invalidNameSet[string.upper(filename)] then
        return 'invalidname'
    end

    return nil
end

---@class FilePicker : Group
FilePicker = ClassUI(Group) {
    ---@param self FilePicker
    ---@param parent Control
    ---@param fileType filetype
    ---@param onlyShowMine any
    ---@param selectAction any
    ---@param debugName any
    __init = function(self, parent, fileType, onlyShowMine, selectAction, debugName)
        Group.__init(self, parent)
        self:SetName(debugName or "FilePicker")

        self._fileType = fileType
        self._selectAction = selectAction

        self._hasSelection = false

        self._sortby = {field = 'name', ascending = true}

    --[[---------------------------------------------------------------------------
        LAYOUT
    --]]----------------------------------------------------------------------------

        self._filenameEdit = Edit(self)
        self._filenameEdit:SetForegroundColor(UIUtil.fontColor)
        self._filenameEdit:SetBackgroundColor("black")
        self._filenameEdit:SetHighlightForegroundColor("black")
        self._filenameEdit:SetHighlightBackgroundColor(UIUtil.fontColor)
        self._filenameEdit:ShowBackground(true)
        self._filenameEdit.Width:Set(self.Width)
        self._filenameEdit.Height:Set(function() return self._filenameEdit:GetFontHeight() end)
        LayoutHelpers.AtBottomIn(self._filenameEdit, self)
        LayoutHelpers.AtLeftIn(self._filenameEdit, self)
        self._filenameEdit:AcquireFocus()

        self._filenameLabel = UIUtil.CreateText(self, "<LOC uifilepicker_0000>Filename", 16, UIUtil.titleFont)
        LayoutHelpers.Above(self._filenameLabel, self._filenameEdit, 5)

        self._filenameErrorMsg = UIUtil.CreateText(self, "", 16, UIUtil.titleFont)
        LayoutHelpers.RightOf(self._filenameErrorMsg, self._filenameLabel, 5)

        if not onlyShowMine then
            self._onlyMineCheckbox = UIUtil.CreateCheckboxStd(self, '/dialogs/check-box_btn/radio')
            LayoutHelpers.AtTopIn(self._onlyMineCheckbox, self, -30)
            LayoutHelpers.AtRightIn(self._onlyMineCheckbox, self)

            self._onlyMineLabel = UIUtil.CreateText(self, "<LOC uifilepicker_0001>Show only my files", 12, UIUtil.titleFont)
            LayoutHelpers.CenteredLeftOf(self._onlyMineLabel, self._onlyMineCheckbox)
        end

        self._filelist = Group(self)
        LayoutHelpers.AtLeftTopIn(self._filelist, self, 0, 20)
        LayoutHelpers.AnchorToTop(self._filelist, self._filenameLabel, 5)
        self._filelist.Width:Set(function() return self.Width() - 2 end)
        self._filelist.top = 0

        self._tabs = {}

        ForkThread(function()
            self._filelistObjects = {}

            self._filelist.CreateOptionElements = function()
                if not table.empty(self._filelistObjects) then
                    for i, v in self._filelistObjects do
                        v:Destroy()
                    end
                end
                self._filelistObjects = {}
                local function CreateElement(index)
                    self._filelistObjects[index] = Bitmap(self._filelist)
                    if math.mod(index, 2) == 0 then
                        self._filelistObjects[index].baseColor = 'ff333333'
                    else
                        self._filelistObjects[index].baseColor = 'ff000000'
                    end
                    self._filelistObjects[index]:SetSolidColor(self._filelistObjects[index].baseColor)
                    self._filelistObjects[index].Height:Set(20)
                    self._filelistObjects[index].Width:Set(function() return self._filelist.Width() - 5 end)
                    self._filelistObjects[index].Depth:Set(function() return self._filelist.Depth() + 10 end)
                    self._filelistObjects[index].selected = false

                    for i, tab in self._tabs do
                        self._filelistObjects[index][tab.tabData.key] = UIUtil.CreateText(self._filelistObjects[index], '', 14, UIUtil.bodyFont)
                        self._filelistObjects[index][tab.tabData.key].Left:Set(tab.Left)
                        self._filelistObjects[index][tab.tabData.key].Right:Set(tab.Right)
                        self._filelistObjects[index][tab.tabData.key]:SetClipToWidth(true)
                        LayoutHelpers.AtVerticalCenterIn(self._filelistObjects[index][tab.tabData.key], self._filelistObjects[index])
                    end

                    self._filelistObjects[index].HandleEvent = function(control, event)
                        if event.Type == 'MouseEnter' then
                            if self._hasSelection == control.index then
                                control:SetSolidColor('ffbbbbbb')
                            else
                                control:SetSolidColor('ff777777')
                            end
                            control.name:SetColor('ff000000')
                            control.date:SetColor('ff000000')
                            if control.owner then
                                control.owner:SetColor('ff000000')
                            end
                        elseif event.Type == 'MouseExit' then
                            if self._hasSelection == control.index then
                                control:SetSolidColor('ffbbbbbb')
                                control.name:SetColor('ff000000')
                                control.date:SetColor('ff000000')
                                if control.owner then
                                    control.owner:SetColor('ff000000')
                                end
                            else
                                control:SetSolidColor(control.baseColor)
                                control.name:SetColor(UIUtil.fontColor)
                                control.date:SetColor(UIUtil.fontColor)
                                if control.owner then
                                    control.owner:SetColor(UIUtil.fontColor)
                                end
                            end
                        elseif event.Type == 'ButtonPress' then
                            if self._hasSelection and self._hasSelection == control.index then
                                self._hasSelection = false
                                self._filenameEdit:SetText('')
                                control:SetSolidColor(control.baseColor)
                                control.name:SetColor(UIUtil.fontColor)
                                control.date:SetColor(UIUtil.fontColor)
                                if control.owner then
                                    control.owner:SetColor(UIUtil.fontColor)
                                end
                            else
                                self._selectedIndex = control.lineIndex
                                self._hasSelection = control.index
                                self._filenameEdit:SetText(control.name:GetText())
                                self._currentProfile = control.profile
                            end
                        elseif event.Type == 'ButtonDClick' then
                            self:DoSelectBehavior()
                        end
                    end
                end

                CreateElement(1)
                LayoutHelpers.AtLeftTopIn(self._filelistObjects[1], self._filelist, 0, 10)

                local index = 2
                while self._filelistObjects[table.getsize(self._filelistObjects)].Bottom() + self._filelistObjects[1].Height() < self._filelist.Bottom() do
                    CreateElement(index)
                    LayoutHelpers.Below(self._filelistObjects[index], self._filelistObjects[index-1])
                    index = index + 1
                end
            end
            self:SetTabConfiguration(1)
            self._filelist.CreateOptionElements()

            local numLines = function() return table.getsize(self._filelistObjects) end

            local function DataSize()
                return table.getsize(self._currentFiles)
            end

            -- called when the scrollbar for the control requires data to size itself
            -- GetScrollValues must return 4 values in this order:
            -- rangeMin, rangeMax, visibleMin, visibleMax
            -- aixs can be "Vert" or "Horz"
            self._filelist.GetScrollValues = function(control, axis)
                local size = DataSize()
                --LOG(size, ":", self.top, ":", math.min(self._filelist.top + numLines(), size))
                return 0, size, self._filelist.top, math.min(self._filelist.top + numLines(), size)
            end

            -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
            self._filelist.ScrollLines = function(control, axis, delta)
                control:ScrollSetTop(axis, self._filelist.top + math.floor(delta))
            end

            -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
            self._filelist.ScrollPages = function(control, axis, delta)
                control:ScrollSetTop(axis, self._filelist.top + math.floor(delta) * numLines())
            end

            -- called when the scrollbar wants to set a new visible top line
            self._filelist.ScrollSetTop = function(control, axis, top)
                top = math.floor(top)
                if top == self.top then return end
                local size = DataSize()
                control.top = math.max(math.min(size - numLines() , top), 0)
                control:CalcVisible()
            end

            -- called to determine if the control is scrollable on a particular access. Must return true or false.
            self._filelist.IsScrollable = function(control, axis)
                return true
            end
            -- determines what controls should be visible or not
            self._filelist.CalcVisible = function(control)
                local function SetTextLine(line, data, lineID, index)
                    line.name:SetText(data[2])
                    local fileInfo = GetSpecialFileInfo(data[1], data[2], self._fileType)
                    line.date:SetText(string.format('%02d/%02d/%02d %02d:%02d:%02d',fileInfo.WriteTime.month,fileInfo.WriteTime.mday, fileInfo.WriteTime.year, fileInfo.WriteTime.hour, fileInfo.WriteTime.minute, fileInfo.WriteTime.second))
                    line.profile = data[1]
                    if line.owner then
                        line.owner:SetText(data[1])
                    end
                    line.index = lineID
                    line.lineIndex = index
                    line:Enable()
                    if self._hasSelection == lineID then
                        line:SetSolidColor('ffbbbbbb')
                        line.name:SetColor('ff000000')
                        line.date:SetColor('ff000000')
                        if line.owner then
                            line.owner:SetColor('ff000000')
                        end
                    else
                        line.name:SetColor(UIUtil.fontColor)
                        line.date:SetColor(UIUtil.fontColor)
                        if line.owner then
                            line.owner:SetColor(UIUtil.fontColor)
                        end
                        line:SetSolidColor(line.baseColor)
                    end
                end
                for i, v in self._filelistObjects do
                    if self._currentFiles[i + control.top] then
                        SetTextLine(v, self._currentFiles[i + control.top], i + control.top, i)
                    else
                        v.name:SetText('')
                        v.date:SetText('')
                        if v.owner then
                            v.owner:SetText('')
                        end
                        v:Disable()
                        v:SetSolidColor('00000000')
                    end
                end
            end


            self._filelist:CalcVisible()

            self._filelist.HandleEvent = function(control, event)
                if event.Type == 'WheelRotation' then
                    local lines = 1
                    if event.WheelRotation > 0 then
                        lines = -1
                    end
                    control:ScrollLines(nil, lines)
                end
            end

            UIUtil.CreateVertScrollbarFor(self._filelist)
            self._filenameEdit:SetFont(UIUtil.bodyFont, 14)
            if self._onlyMineCheckbox then
                self._onlyMineCheckbox:SetCheck(true) -- note that this will cause the initial list populate
            end
        end) -- end ForkThread

--[[---------------------------------------------------------------------------
        LOGIC
--]]----------------------------------------------------------------------------
        self._filelist.OnClick = function(control, row)
            self._filelistObjects:SetSelection(row)
            self._filenameEdit:SetText(self._currentFiles[row + 1][2])
            self._currentProfile = self._currentFiles[row + 1][1]
        end

        self._filelist.OnDoubleClick = function(control, row)
            self._filelistObjects.OnClick(control, row)
            self:DoSelectBehavior()
        end


        self._filenameEdit.OnCharPressed = function(control, charcode)
            if IsCharInvalid(charcode) then
                local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                PlaySound(sound)
                self._filenameErrorMsg:SetText(" : " .. LOC(errorMsg.invalidchars))
                return true
            else
                local charLim = control:GetMaxChars()
                if STR_Utf8Len(control:GetText()) >= charLim then
                    local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                    PlaySound(sound)
                end
                self._filenameErrorMsg:SetText("")
                return false
            end
        end

        self._filenameEdit.OnTextChanged = function(control, newText, oldText)
            if self._filelistObjects then
                local isNotExisting = true
                for i, v in self._filelistObjects do
                    if newText == v.name:GetText() and self._selectedIndex == i then
                        if not v:IsDisabled() then
                            v:SetSolidColor('ffbbbbbb')
                            v.name:SetColor('ff000000')
                            v.date:SetColor('ff000000')
                            if v.owner then
                                v.owner:SetColor('ff000000')
                            end
                        end
                        isNotExisting = false
                    else
                        if not v:IsDisabled() then
                            v:SetSolidColor(v.baseColor)
                            v.name:SetColor(UIUtil.fontColor)
                            v.date:SetColor(UIUtil.fontColor)
                            if v.owner then
                                v.owner:SetColor(UIUtil.fontColor)
                            end
                        end
                    end
                end
                if isNotExisting then
                    self._hasSelection = false
                end
            end
            if STR_Utf8Len(newText) > maxFilenameSize then
                local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                PlaySound(sound)
                self._filenameErrorMsg:SetText(" : " .. LOCF(errorMsg.toolong, maxFilenameSize))
                control:SetText(oldText)
            else
                self._filenameErrorMsg:SetText("")
            end
        end

        self._filenameEdit.OnEnterPressed = function(control, text)
            self._currentProfile = nil
            self:DoSelectBehavior()
            control:AbandonFocus()
            return true -- supress clear
        end

        if not onlyShowMine then
            self._onlyMineCheckbox.OnCheck = function(control, checked)
                local tabConfigID = 1
                if not checked then
                    tabConfigID = 2
                end
                self:SetTabConfiguration(tabConfigID)
                self:RepopulateList()
                self._filenameEdit:SetText('')
            end
        else
            self:RepopulateList()
        end
    end,

    ---@param self FilePicker
    ---@param configID number
    SetTabConfiguration = function(self, configID)
        if not table.empty(self._tabs) then
            for index, tab in self._tabs do
                tab:Destroy()
            end
        end
        self._tabs = {}
        local function CreateTab(data)
            local btn = Bitmap(self, UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_m.dds'))

            btn.lcap = Bitmap(btn, UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_l.dds'))
            btn.lcap.Depth:Set(btn.Depth)
            LayoutHelpers.LeftOf(btn.lcap, btn)

            btn.rcap = Bitmap(btn, UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_r.dds'))
            btn.rcap.Depth:Set(btn.Depth)
            LayoutHelpers.RightOf(btn.rcap, btn)

            btn.text = UIUtil.CreateText(btn, data.title, 18)
            btn.text:DisableHitTest()
            LayoutHelpers.AtLeftIn(btn.text, btn, 18)
            LayoutHelpers.AtVerticalCenterIn(btn.text, btn, 2)

            btn.arrow = Bitmap(btn, UIUtil.UIFile('/dialogs/sort_btn/sort-arrow-down_bmp.dds'))
            btn.arrow:DisableHitTest()
            LayoutHelpers.AtLeftIn(btn.arrow, btn.lcap, 4)
            LayoutHelpers.AtVerticalCenterIn(btn.arrow, btn.lcap)
            btn.arrow:Hide()

            btn._checked = false

            return btn
        end
        for index, tabData in columConfigurations[configID] do
            local i = index
            self._tabs[i] = CreateTab(tabData)
            self._tabs[i].tabData = tabData
            if index == 1 then
                LayoutHelpers.AtLeftTopIn(self._tabs[i], self)
            else
                LayoutHelpers.RightOf(self._tabs[i], self._tabs[i-1], 18)
            end
            if self._sortby.field == tabData.sortby then
                self._tabs[i]._checked = true
                self._tabs[i].arrow:Show()
                if self._sortby.ascending then
                    self._tabs[i].arrow:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort-arrow-down_bmp.dds'))
                else
                    self._tabs[i].arrow:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort-arrow-up_bmp.dds'))
                end
            end
            LayoutHelpers.SetWidth(self._tabs[i], tabData.width)
            self._tabs[i].Uncheck = function(control)
                control._checked = false
                control:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_m.dds'))
                control.lcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_l.dds'))
                control.rcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_r.dds'))
                control.arrow:Hide()
            end
            if tabData.sortby then
                self._tabs[i]._sortKey = tabData.sortby
                self._tabs[i].OnClick = function(control, event)
                    control.arrow:Show()
                    self._filenameEdit:SetText('')
                    self._hasSelection = false
                    self._sortby.field = control._sortKey
                    if control._checked then
                        self._sortby.ascending = not self._sortby.ascending
                    end
                    if self._sortby.ascending then
                        control.arrow:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort-arrow-down_bmp.dds'))
                    else
                        control.arrow:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort-arrow-up_bmp.dds'))
                    end
                    self:RepopulateList()
                end
                self._tabs[i].HandleEvent = function(control, event)
                    if event.Type == 'MouseEnter' then
                        control:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_over_m.dds'))
                        control.lcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_over_l.dds'))
                        control.rcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_over_r.dds'))
                        control.text:SetColor('ff333333')
                    elseif event.Type == 'MouseExit' then
                        control:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_m.dds'))
                        control.lcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_l.dds'))
                        control.rcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_up_r.dds'))
                        control.text:SetColor(UIUtil.fontColor)
                    elseif event.Type == 'ButtonPress' or event.Type == 'ButtonDClick' then
                        for index, tab in self._tabs do
                            if index == i then
                                tab:OnClick()
                            elseif tab.OnClick then
                                tab:Uncheck()
                            end
                        end
                        control._checked = true
                    end
                end
            else
                self._tabs[i]:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_dis_m.dds'))
                self._tabs[i].lcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_dis_l.dds'))
                self._tabs[i].rcap:SetTexture(UIUtil.UIFile('/dialogs/sort_btn/sort_btn_dis_r.dds'))
            end
        end
    end,

    ---@param self FilePicker
    ---@return boolean
    DoSelectBehavior = function(self)
        local err = IsFilenameInvalid(self._filenameEdit:GetText())
        if err then
            if err == 'toolong' then
                self._filenameErrorMsg:SetText(" : " .. LOCF(errorMsg[err], maxFilenameSize))
            else
                self._filenameErrorMsg:SetText(" : " .. LOC(errorMsg[err]))
            end
            return false
        end

        self._filenameErrorMsg:SetText("")

        if self._selectAction then
            self:_selectAction(self:GetFileInfo())
        end

        return true
    end,

    ---@param self FilePicker
    RepopulateList = function(self)
        local filesData = GetSpecialFiles(self._fileType)

        self._currentDir = filesData.directory
        self._currentExt = filesData.extension
        self._currentFiles = {}

        if (self._onlyMineCheckbox == nil) or self._onlyMineCheckbox:IsChecked() then
            -- find the current profile in a case insensitive manner
            local curProfileName = string.lower(Prefs.GetCurrentProfile().Name)
            for id, files in filesData.files do
                if string.lower(id) == curProfileName then
                    for index, file in files do
                        table.insert(self._currentFiles, {curProfileName, file})
                    end
                end
            end
        else
            for dir, files in filesData.files do
                for index, file in files do
                    table.insert(self._currentFiles, {dir, file})
                end
            end
        end
        table.sort(self._currentFiles, function(a, b)
            local aval = false
            local bval = false
            if self._sortby.field == 'name' then
                aval = a[2]
                bval = b[2]
            elseif self._sortby.field == 'profile' then
                aval = a[1]
                bval = b[1]
            else
                aval = GetSpecialFileInfo(a[1], a[2], self._fileType).TimeStamp;
                bval = GetSpecialFileInfo(b[1], b[2], self._fileType).TimeStamp;
            end
            if self._sortby.ascending then
                return aval < bval
            else
                return aval > bval
            end
        end)
        if self._filelistObjects then
            self._filelist.CreateOptionElements()
            self._filelist:CalcVisible()
        end
    end,

    ---@param self FilePicker
    ---@param newText string
    ---@param profile string
    SetFilename = function(self, newText, profile)
        self._currentProfile = profile or Prefs.GetCurrentProfile().Name
        self._filenameEdit:SetText(newText)
    end,

    ---@param self FilePicker
    ---@return any
    GetProfile = function(self)
        return self._currentProfile or Prefs.GetCurrentProfile().Name
    end,

    ---@param self FilePicker
    ---@return unknown
    GetBaseName = function(self)
        return self._filenameEdit:GetText()
    end,

    ---@param self FilePicker
    ---@return any
    GetExtension = function(self)
        return self._currentExt
    end,

    ---@param self FilePicker
    ---@return any
    GetDirectory = function(self)
        return self._currentDir
    end,

    ---@param self FilePicker
    ---@return table
    GetFileInfo = function(self)
        local useProfile = self._currentProfile or Prefs.GetCurrentProfile().Name
        local ret = {}
        ret.fspec = self._currentDir .. useProfile .. "/" .. self._filenameEdit:GetText() .. "." .. self._currentExt
        ret.fname = self._filenameEdit:GetText()
        ret.profile = useProfile
        ret.type = self._fileType
        return ret
    end,
}