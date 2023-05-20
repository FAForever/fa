local UiUtilsS = import("/lua/uiutilssorian.lua")
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EffectHelpers = import("/lua/maui/effecthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Checkbox = import("/lua/ui/controls/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local Text = import("/lua/maui/text.lua").Text
local Edit = import("/lua/maui/edit.lua").Edit
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Window = import("/lua/maui/window.lua").Window
local BitmapCombo = import("/lua/ui/controls/combo.lua").BitmapCombo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider
local Prefs = import("/lua/user/prefs.lua")
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Tooltip = import("/lua/ui/game/tooltip.lua")
local UIMain = import("/lua/ui/uimain.lua")
--[[ LOC Strings
<LOC chat_win_0001>To %s:
<LOC chat_win_0002>Chat (%d - %d of %d lines)
--]]

local AddUnicodeCharToEditText = import("/lua/utf.lua").AddUnicodeCharToEditText

local CHAT_INACTIVITY_TIMEOUT = 15  -- in seconds
local savedParent = false
local chatHistory = {}

local commandHistory = {}

local ChatTo = import("/lua/lazyvar.lua").Create()

local defOptions = { all_color = 1,
        allies_color = 2,
        priv_color = 3,
        link_color = 4,
        notify_color = 8,
        font_size = 14,
        fade_time = 15,
        win_alpha = 1,
        feed_background = false,
        feed_persist = true}

local ChatOptions = Prefs.GetFromCurrentProfile("chatoptions") or {}
for option, value in defOptions do
     if ChatOptions[option] == nil then
        ChatOptions[option] = value
    end
end

GUI = import("/lua/ui/controls.lua").Get()
GUI.chatLines = GUI.chatLines or {}

local FactionsIcon = {}
local Factions = import("/lua/factions.lua").Factions
for k, FactionData in Factions do
    table.insert(FactionsIcon, FactionData.Icon)
end
table.insert(FactionsIcon, '/widgets/faction-icons-alpha_bmp/observer_ico.dds')


local chatColors = {'ffffffff', 'ffff4242', 'ffefff42','ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb', 'ffff9f42'}

local ToStrings = {
    to = {text = '<LOC chat_0000>to', caps = '<LOC chat_0001>To', colorkey = 'all_color'},
    allies = {text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'allies_color'},
    all = {text = '<LOC chat_0004>to all:', caps = '<LOC chat_0005>To All:', colorkey = 'all_color'},
    private = {text = '<LOC chat_0006>to you:', caps = '<LOC chat_0007>To You:', colorkey = 'priv_color'},
    notify = {text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'notify_color'},
}

function SetLayout()
    import(UIUtil.GetLayoutFilename('chat')).SetLayout()
end

function CreateChatBackground()
    local location = {Top = function() return GetFrame(0).Bottom() - LayoutHelpers.ScaleNumber(393) end,
        Left = function() return GetFrame(0).Left() + LayoutHelpers.ScaleNumber(8) end,
        Right = function() return GetFrame(0).Left() + LayoutHelpers.ScaleNumber(430) end,
        Bottom = function() return GetFrame(0).Bottom() - LayoutHelpers.ScaleNumber(238) end}
    local bg = Window(GetFrame(0), '', nil, true, true, nil, nil, 'chat_window', location)
    bg.Depth:Set(200)

    bg.DragTL = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    bg.DragTR = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    bg.DragBL = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    bg.DragBR = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

    local controlMap = {
        tl = {bg.DragTL},
        tr = {bg.DragTR},
        bl = {bg.DragBL},
        br = {bg.DragBR},
        mr = {bg.DragBR,bg.DragTR},
        ml = {bg.DragBL,bg.DragTL},
        tm = {bg.DragTL,bg.DragTR},
        bm = {bg.DragBL,bg.DragBR},
    }

    bg.RolloverHandler = function(control, event, xControl, yControl, cursor, controlID)
        if bg._lockSize then return end
        local styles = import("/lua/maui/window.lua").styles
        if not bg._sizeLock then
            if event.Type == 'MouseEnter' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.over)
                    end
                end
                GetCursor():SetTexture(styles.cursorFunc(cursor))
            elseif event.Type == 'MouseExit' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.up)
                    end
                end
                GetCursor():Reset()
            elseif event.Type == 'ButtonPress' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.down)
                    end
                end
                bg.StartSizing(event, xControl, yControl)
                bg._sizeLock = true
            end
        end
    end

    bg.OnResizeSet = function(control)
        bg.DragTL:SetTexture(bg.DragTL.textures.up)
        bg.DragTR:SetTexture(bg.DragTR.textures.up)
        bg.DragBL:SetTexture(bg.DragBL.textures.up)
        bg.DragBR:SetTexture(bg.DragBR.textures.up)
    end

    LayoutHelpers.AtLeftTopIn(bg.DragTL, bg, -26, -6)
    bg.DragTL.Depth:Set(220)
    bg.DragTL:DisableHitTest()

    LayoutHelpers.AtRightTopIn(bg.DragTR, bg, -22, -8)
    bg.DragTR.Depth:Set(bg.DragTL.Depth)
    bg.DragTR:DisableHitTest()

    LayoutHelpers.AtLeftBottomIn(bg.DragBL, bg, -26, -8)
    bg.DragBL.Depth:Set(bg.DragTL.Depth)
    bg.DragBL:DisableHitTest()

    LayoutHelpers.AtRightBottomIn(bg.DragBR, bg, -22, -8)
    bg.DragBR.Depth:Set(bg.DragTL.Depth)
    bg.DragBR:DisableHitTest()

    bg.ResetPositionBtn = Button(bg,
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_up.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_down.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_over.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_dis.dds'))
    LayoutHelpers.LeftOf(bg.ResetPositionBtn, bg._configBtn)
    bg.ResetPositionBtn.Depth:Set(function() return bg.Depth() + 10 end)
    bg.ResetPositionBtn.OnClick = function(self, modifiers)
        for index, position in location do
            local i = index
            local pos = position
            bg[i]:Set(pos)
        end
        CreateChatLines()
        bg:SaveWindowLocation()
    end

    Tooltip.AddButtonTooltip(bg.ResetPositionBtn, 'chat_reset')

    bg:SetMinimumResize(400, 160)
    return bg
end

function CreateChatLines()
    local function CreateChatLine()
        local line = Group(GUI.chatContainer)

        -- Draw the faction icon with a colour representing the team behind it.
        line.teamColor = Bitmap(line)
        line.teamColor:SetSolidColor('00000000')
        line.teamColor.Height:Set(line.Height)
        line.teamColor.Width:Set(line.Height)
        LayoutHelpers.AtLeftTopIn(line.teamColor, line)

        line.factionIcon = Bitmap(line.teamColor)
        line.factionIcon:SetSolidColor('00000000')
        LayoutHelpers.FillParent(line.factionIcon, line.teamColor)

        -- Player name
        line.name = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial Bold")
        LayoutHelpers.CenteredRightOf(line.name, line.teamColor, 4)
        line.name.Depth:Set(function() return line.Depth() + 10 end)
        line.name:SetColor('ffffffff')
        line.name:DisableHitTest()
        line.name:SetDropShadow(true)
        line.name.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if line.chatID then
                    if GUI.bg:IsHidden() then GUI.bg:Show() end
                    ChatTo:Set(line.chatID)
                    if GUI.chatEdit.edit then
                        GUI.chatEdit.edit:AcquireFocus()
                    end
                    if GUI.chatEdit.private then
                        GUI.chatEdit.private:SetCheck(true)
                    end
                end
            end
        end

        line.text = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial")
        line.text.Depth:Set(function() return line.Depth() + 10 end)
        line.text.Left:Set(function() return line.name.Right() + 2 end)
        line.text.Right:Set(line.Right)
        line.text:SetClipToWidth(true)
        line.text:DisableHitTest()
        line.text:SetColor('ffc2f6ff')
        line.text:SetDropShadow(true)
        LayoutHelpers.AtVerticalCenterIn(line.text, line.teamColor)
        line.text.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if line.cameraData then
                    GetCamera('WorldCamera'):RestoreSettings(line.cameraData)
                end
            end
        end

        -- A background for the line that persists after the chat panel is closed (to help with
        -- readability against the simulation)
        line.lineStickybg = Bitmap(line)
        line.lineStickybg:DisableHitTest()
        line.lineStickybg:SetSolidColor('aa000000')
        LayoutHelpers.FillParent(line.lineStickybg, line)
        LayoutHelpers.DepthUnderParent(line.lineStickybg, line)
        line.lineStickybg:Hide()

        return line
    end
    if GUI.chatContainer then
        local curEntries = table.getsize(GUI.chatLines)
        local neededEntries = math.floor(GUI.chatContainer.Height() / (GUI.chatLines[1].Height() + 0))
        if curEntries - neededEntries == 0 then
            return
        elseif curEntries - neededEntries < 0 then
            for i = curEntries + 1, neededEntries do
                local index = i
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 0)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 2 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        elseif curEntries - neededEntries > 0 then
            for i = neededEntries + 1, curEntries do
                if GUI.chatLines[i] then
                    GUI.chatLines[i]:Destroy()
                    GUI.chatLines[i] = nil
                end
            end
        end
    else
        local clientArea = GUI.bg:GetClientGroup()
        GUI.chatContainer = Group(clientArea)
        LayoutHelpers.AtLeftIn(GUI.chatContainer, clientArea, 10)
        LayoutHelpers.AtTopIn(GUI.chatContainer, clientArea, 2)
        LayoutHelpers.AtRightIn(GUI.chatContainer, clientArea, 38)
        LayoutHelpers.AnchorToTop(GUI.chatContainer, GUI.chatEdit, 10)

        SetupChatScroll()

        if not GUI.chatLines[1] then
            GUI.chatLines[1] = CreateChatLine()
            LayoutHelpers.AtLeftTopIn(GUI.chatLines[1], GUI.chatContainer, 0, 0)
            GUI.chatLines[1].Height:Set(function() return GUI.chatLines[1].name.Height() + 2 end)
            GUI.chatLines[1].Right:Set(GUI.chatContainer.Right)
        end
        local index = 1
        while GUI.chatLines[index].Bottom() + GUI.chatLines[1].Height() < GUI.chatContainer.Bottom() do
            index = index + 1
            if not GUI.chatLines[index] then
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 0)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 2 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        end
    end
end

function OnNISBegin()
    CloseChat()
end

function SetupChatScroll()
    GUI.chatContainer.top = 1
    GUI.chatContainer.scroll = UIUtil.CreateVertScrollbarFor(GUI.chatContainer)

    local numLines = function() return table.getsize(GUI.chatLines) end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0

    local function IsValidEntry(entryData)
        if entryData.camera then
            return ChatOptions.links and ChatOptions[entryData.armyID]
        end

        return ChatOptions[entryData.armyID]
    end

    local function DataSize()
        if GUI.chatContainer.prevtabsize ~= table.getn(chatHistory) then
            local size = 0
            for i, v in chatHistory do
                if IsValidEntry(v) then
                    size = size + table.getn(v.wrappedtext)
                end
            end
            GUI.chatContainer.prevtabsize = table.getn(chatHistory)
            GUI.chatContainer.prevsize = size
        end
        return GUI.chatContainer.prevsize
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.chatContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines(), size))
        return 1, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.chatContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.chatContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.chatContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines()+1, top), 1)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.chatContainer.IsScrollable = function(self, axis)
        return true
    end

    GUI.chatContainer.ScrollToBottom = function(self)
        --LOG(DataSize())
        GUI.chatContainer:ScrollSetTop(nil, DataSize())
    end

    -- determines what controls should be visible or not
    GUI.chatContainer.CalcVisible = function(self)
        GUI.bg.curTime = 0
        local index = 1
        local tempTop = self.top
        local curEntry = 1
        local curTop = 1
        local tempsize = 0

        if GUI.bg:IsHidden() then
            tempTop = math.max(DataSize() - numLines()+1, 1)
        end

        for i, v in chatHistory do
            if IsValidEntry(v) then
                if tempsize + table.getsize(v.wrappedtext) < tempTop then
                    tempsize = tempsize + table.getsize(v.wrappedtext)
                else
                    curEntry = i
                    for h, x in v.wrappedtext do
                        if h + tempsize == tempTop then
                            curTop = h
                            break
                        end
                    end
                    break
                end
            end
        end
        while GUI.chatLines[index] do
            local line = GUI.chatLines[index]

            if not chatHistory[curEntry].wrappedtext[curTop] then
                if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
                curTop = 1
                curEntry = curEntry + 1
                while chatHistory[curEntry] and not IsValidEntry(chatHistory[curEntry]) do
                    curEntry = curEntry + 1
                end
            end
            if chatHistory[curEntry] then
                local Index = index
                if curTop == 1 then
                    line.name:SetText(chatHistory[curEntry].name)
                    if chatHistory[curEntry].armyID == GetFocusArmy() then
                        line.name:Disable()
                    else
                        line.name:Enable()
                    end
                    line.text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
                    line.teamColor:SetSolidColor(chatHistory[curEntry].color)
                    line.factionIcon:SetTexture(UIUtil.UIFile(FactionsIcon[chatHistory[curEntry].faction]))
                    line.IsTop = true
                    line.chatID = chatHistory[curEntry].armyID
                    if chatHistory[curEntry].camera and not line.camIcon then
                        line.camIcon = Bitmap(line.text, UIUtil.UIFile('/game/camera-btn/pinned_btn_up.dds'))
                        LayoutHelpers.SetDimensions(line.camIcon, 20, 16)
                        LayoutHelpers.AtVerticalCenterIn(line.camIcon, line.teamColor)
                        LayoutHelpers.RightOf(line.camIcon, line.name, 4)
                        LayoutHelpers.RightOf(line.text, line.camIcon, 4)
                    elseif not chatHistory[curEntry].camera and line.camIcon then
                        line.camIcon:Destroy()
                        line.camIcon = false
                        LayoutHelpers.RightOf(line.text, line.name, 2)
                    end
                else
                    line.name:Disable()
                    line.name:SetText('')
                    line.text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
                    line.teamColor:SetSolidColor('00000000')
                    line.factionIcon:SetSolidColor('00000000')
                    line.IsTop = false
                    if line.camIcon then
                        line.camIcon:Destroy()
                        line.camIcon = false
                        LayoutHelpers.RightOf(line.text, line.name, 2)
                    end
                end
                if chatHistory[curEntry].camera then
                    line.cameraData = chatHistory[curEntry].camera
                    line.text:Enable()
                    line.text:SetColor(chatColors[ChatOptions.link_color])
                else
                    line.text:Disable()
                    line.text:SetColor('ffc2f6ff')
                    line.text:SetColor(chatColors[ChatOptions[chatHistory[curEntry].tokey]])
                end

                line.EntryID = curEntry

                if GUI.bg:IsHidden() then

                    line.curHistory = chatHistory[curEntry]
                    if line.curHistory.new or line.curHistory.time == nil then
                        line.curHistory.time = 0
                    end

                    if line.curHistory.time < ChatOptions.fade_time then
                        line:Show()

                        UIUtil.setVisible(line.lineStickybg, ChatOptions.feed_background)

                        if line.name:GetText() == '' then
                            line.teamColor:Hide()
                        end
                        if line.curHistory.wrappedtext[curTop+1] == nil then
                            line.OnFrame = function(self, delta)
                                self.curHistory.time = self.curHistory.time + delta
                                if self.curHistory.time > ChatOptions.fade_time then
                                    if GUI.bg:IsHidden() then
                                        self:Hide()
                                    end
                                    self:SetNeedsFrameUpdate(false)
                                end
                            end
                        -- Don't increment time on lines with wrapped text
                        else
                            line.OnFrame = function(self, delta)
                                if self.curHistory.time > ChatOptions.fade_time then
                                    if GUI.bg:IsHidden() then
                                        self:Hide()
                                    end
                                    self:SetNeedsFrameUpdate(false)
                                end
                            end
                        end
                        line:SetNeedsFrameUpdate(true)
                    end

                end
            else
                line.name:Disable()
                line.name:SetText('')
                line.text:SetText('')
                line.teamColor:SetSolidColor('00000000')
            end
            line:SetAlpha(ChatOptions.win_alpha, true)
            curTop = curTop + 1
            index = index + 1
        end
        if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
    end
end

function FindClients(id)
    local t = GetArmiesTable()
    local focus = t.focusArmy
    local result = {}
    if focus == -1 then
        for index,client in GetSessionClients() do
            if not client.connected then
                continue
            end
            local playerIsObserver = true
            for id, player in GetArmiesTable().armiesTable do
                if player.outOfGame and player.human and player.nickname == client.name then
                    table.insert(result, index)
                    playerIsObserver = false
                    break
                elseif player.nickname == client.name then
                    playerIsObserver = false
                    break
                end
            end
            if playerIsObserver then
                table.insert(result, index)
            end
        end
    else
        local srcs = {}
        for army,info in t.armiesTable do
            if id then
                if army == id then
                    for k,cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                    break
                end
            else
                if IsAlly(focus, army) then
                    for k,cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                end
            end
        end
        for index,client in GetSessionClients() do
            for k,cmdsrc in client.authorizedCommandSources do
                if srcs[cmdsrc] then
                    table.insert(result, index)
                    break
                end
            end
        end
    end
    return result
end

local RunChatCommand = import("/lua/ui/notify/commands.lua").RunChatCommand
function CreateChatEdit()
    local parent = GUI.bg:GetClientGroup()
    local group = Group(parent)

    group.Bottom:Set(parent.Bottom)
    group.Right:Set(parent.Right)
    group.Left:Set(parent.Left)
    group.Top:Set(function() return group.Bottom() - group.Height() end)

    local toText = UIUtil.CreateText(group, '', 14, 'Arial')
    LayoutHelpers.AtBottomIn(toText, group, 1)
    LayoutHelpers.AtLeftIn(toText, group, 35)

    ChatTo.OnDirty = function(self)
        if ToStrings[self()] then
            toText:SetText(LOC(ToStrings[self()].caps))
        else
            toText:SetText(LOCF('%s %s:', ToStrings['to'].caps, GetArmyData(self()).nickname))
        end
    end

    group.edit = Edit(group)
    LayoutHelpers.AnchorToRight(group.edit, toText, 5)
    LayoutHelpers.AtRightIn(group.edit, group, 38)
    group.edit.Depth:Set(function() return GUI.bg:GetClientGroup().Depth() + 200 end)
    LayoutHelpers.AtBottomIn(group.edit, group, 1)
    group.edit.Height:Set(function() return group.edit:GetFontHeight() end)
    UIUtil.SetupEditStd(group.edit, "ff00ff00", nil, "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    group.edit:SetDropShadow(true)
    group.edit:ShowBackground(false)

    group.edit:SetText('')

    group.Height:Set(function() return group.edit.Height() end)

    local function CreateTestBtn(text)
        local btn = UIUtil.CreateCheckbox(group, '/dialogs/toggle_btn/toggle')
        btn.Depth:Set(function() return group.Depth() + 10 end)
        btn.OnClick = function(self, modifiers)
            if self._checkState == "unchecked" then
                self:ToggleCheck()
            end
        end
        btn.txt = UIUtil.CreateText(btn, text, 12, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(btn.txt, btn)
        btn.txt:SetColor('ffffffff')
        btn.txt:DisableHitTest()
        return btn
    end

    group.camData = Checkbox(group,
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))

    LayoutHelpers.AtRightIn(group.camData, group, 5)
    LayoutHelpers.AtVerticalCenterIn(group.camData, group.edit, -1)

    group.chatBubble = Button(group,
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))
    group.chatBubble.OnClick = function(self, modifiers)
        if not self.list then
            self.list = CreateChatList(self)
            LayoutHelpers.Above(self.list, self, 15)
            LayoutHelpers.AtLeftIn(self.list, self, 15)
        else
            self.list:Destroy()
            self.list = nil
        end
    end

    toText.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            group.chatBubble:OnClick(event.Modifiers)
        end
    end

    LayoutHelpers.AtLeftIn(group.chatBubble, group, 3)
    LayoutHelpers.AtVerticalCenterIn(group.chatBubble, group.edit)

    group.edit.OnNonTextKeyPressed = function(self, charcode, event)
        if AddUnicodeCharToEditText(self, charcode) then
            return
        end
        GUI.bg.curTime = 0
        local function RecallCommand(entryNumber)
            self:SetText(commandHistory[self.recallEntry].text)
            if commandHistory[self.recallEntry].camera then
                self.tempCam = commandHistory[self.recallEntry].camera
                group.camData:Disable()
                group.camData:SetCheck(true)
            else
                self.tempCam = nil
                group.camData:Enable()
                group.camData:SetCheck(false)
            end
        end
        if charcode == UIUtil.VK_NEXT then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageDown(mod)
            return true
        elseif charcode == UIUtil.VK_PRIOR then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageUp(mod)
            return true
        elseif charcode == UIUtil.VK_UP then
            if not table.empty(commandHistory) then
                if self.recallEntry then
                    self.recallEntry = math.max(self.recallEntry-1, 1)
                else
                    self.recallEntry = table.getsize(commandHistory)
                end
                RecallCommand(self.recallEntry)
            end
        elseif charcode == UIUtil.VK_DOWN then
            if not table.empty(commandHistory) then
                if self.recallEntry then
                    self.recallEntry = math.min(self.recallEntry+1, table.getsize(commandHistory))
                    RecallCommand(self.recallEntry)
                    if self.recallEntry == table.getsize(commandHistory) then
                        self.recallEntry = nil
                    end
                else
                    self:SetText('')
                end
            end
        else
            return true
        end
    end

    group.edit.OnCharPressed = function(self, charcode)
        local charLim = self:GetMaxChars()
        if charcode == 9 then
            return true
        end
        GUI.bg.curTime = 0
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    group.edit.OnEnterPressed = function(self, text)
        -- Analyse for any commands entered for Notify toggling
        if string.len(text) > 1 and string.sub(text, 1, 1) == "/" then
            local args = {}

            for word in string.gfind(string.sub(text, 2), "%S+") do
                table.insert(args, string.lower(word))
            end

            -- We've done the command, exit without sending the message to other players
            if RunChatCommand(args) then
                return
            end
        end

        GUI.bg.curTime = 0
        if group.camData:IsDisabled() then
            group.camData:Enable()
        end
        if text == "" then
            ToggleChat()
        else
            local gnBegin, gnEnd = string.find(text, "%s+")
            if gnBegin and (gnBegin == 1 and gnEnd == string.len(text)) then
                return
            end
            if import("/lua/ui/game/taunt.lua").CheckForAndHandleTaunt(text) then
                return
            end

            msg = { to = ChatTo(), Chat = true }
            if self.tempCam then
                msg.camera = self.tempCam
            elseif group.camData:IsChecked() then
                msg.camera = GetCamera('WorldCamera'):SaveSettings()
            end
            msg.text = text
            if ChatTo() == 'allies' then
                if GetFocusArmy() ~= -1 then
                    SessionSendChatMessage(FindClients(), msg)
                else
                    msg.Observer = true
                    SessionSendChatMessage(FindClients(), msg)
                end
            elseif type(ChatTo()) == 'number' then
                if GetFocusArmy() ~= -1 then
                    SessionSendChatMessage(FindClients(ChatTo()), msg)
                    msg.echo = true
                    msg.from = GetArmyData(GetFocusArmy()).nickname
                    ReceiveChat(GetArmyData(ChatTo()).nickname, msg)
                end
            else
                if GetFocusArmy() == -1 then
                    msg.Observer = true
                    SessionSendChatMessage(FindClients(), msg)
                else
                    SessionSendChatMessage(msg)
                end
            end
            table.insert(commandHistory, msg)
            self.recallEntry = nil
            self.tempCam = nil
        end
    end

    ChatTo:Set('all')
    group.edit:AcquireFocus()

    return group
end

function ChatPageUp(mod)
    if GUI.bg:IsHidden() then
        ForkThread(function() ToggleChat() end)
    else
        local newTop = GUI.chatContainer.top - mod
        GUI.chatContainer:ScrollSetTop(nil, newTop)
    end
end

function ChatPageDown(mod)
    local oldTop = GUI.chatContainer.top
    local newTop = GUI.chatContainer.top + mod
    GUI.chatContainer:ScrollSetTop(nil, newTop)
    if GUI.bg:IsHidden() or oldTop == GUI.chatContainer.top then
        ForkThread(function() ToggleChat() end)
    end
end

function ReceiveChat(sender, msg)
    if not msg.ConsoleOutput then
        SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Sender=sender, Msg=msg},} , true)
    end
    if not SessionIsReplay() then
        ReceiveChatFromSim(sender, msg)
    end

end

function ReceiveChatFromSim(sender, msg)
    sender = sender or "nil sender"
    if msg.ConsoleOutput then
        print(LOCF("%s %s", sender, msg.ConsoleOutput))
        return
    end

    if not msg.Chat then
        return
    end

    if msg.to == 'notify' and not import("/lua/ui/notify/notify.lua").processIncomingMessage(sender, msg) then
        return
    end

    if type(msg) == 'string' then
        msg = { text = msg }
    elseif type(msg) ~= 'table' then
        msg = { text = repr(msg) }
    end

    local armyData = GetArmyData(sender)
    if not armyData and GetFocusArmy() ~= -1 and not SessionIsReplay() then
        return
    end

    local towho = LOC(ToStrings[msg.to].text) or LOC(ToStrings['private'].text)
    local tokey = ToStrings[msg.to].colorkey or ToStrings['private'].colorkey
    if msg.Observer then
        towho = LOC("<LOC lobui_0692>to observers:")
        tokey = "link_color"
        if armyData.faction then
            armyData.faction = table.getn(FactionsIcon) - 1
        end
    end

    if type(msg.to) == 'number' and SessionIsReplay() then
        towho = string.format("%s %s:", LOC(ToStrings.to.text), GetArmyData(msg.to).nickname)
    end
    local name = sender .. ' ' .. towho

    if msg.echo then
        if msg.from and SessionIsReplay() then
            name = string.format("%s %s %s:", msg.from, LOC(ToStrings.to.text), GetArmyData(msg.to).nickname)
        else
            name = string.format("%s %s:", LOC(ToStrings.to.caps), sender)
        end
    end
    local tempText = WrapText({text = msg.text, name = name})
    -- if text wrap produces no lines (ie text is all white space) then add a blank line
    if table.empty(tempText) then
        tempText = {""}
    end
    local entry = {
        name = name,
        tokey = tokey,
        color = (armyData.color or "ffffffff"),
        armyID = (armyData.ArmyID or 1),
        faction = (armyData.faction or (table.getn(FactionsIcon)-1))+1,
        text = msg.text,
        wrappedtext = tempText,
        new = true,
        camera = msg.camera
    }

    table.insert(chatHistory, entry)
    if ChatOptions[entry.armyID] then
        if table.getsize(chatHistory) == 1 then
            GUI.chatContainer:CalcVisible()
        else
            GUI.chatContainer:ScrollToBottom()
        end
    end
    if SessionIsReplay() then
        PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Diplomacy_Close'}))
    end
end

function ToggleChat()
    if GUI.bg:IsHidden() then
        GUI.bg:Show()
        GUI.chatEdit.edit:AcquireFocus()
        if not GUI.bg.pinned then
            GUI.bg:SetNeedsFrameUpdate(true)
            GUI.bg.curTime = 0
        end
        for i, v in GUI.chatLines do
            v:SetNeedsFrameUpdate(false)
            v:Show()
            v.lineStickybg:Hide()
        end
        GUI.chatContainer:CalcVisible()
    else
        GUI.bg:Hide()
        GUI.chatEdit.edit:AbandonFocus()
        GUI.bg:SetNeedsFrameUpdate(false)

        if ChatOptions.feed_persist then
            GUI.chatContainer:CalcVisible()
        else
            for i, v in GUI.chatLines do
                if v.curHistory and v.curHistory.time ~= nil then
                    v.curHistory.time = ChatOptions.fade_time + 1
                end
            end
        end
    end
end

function ActivateChat(modifiers)
    if type(ChatTo()) ~= 'number' then
        if (not modifiers.Shift) == (ChatOptions['send_type'] or false) then
            ChatTo:Set('allies')
        else
            ChatTo:Set('all')
        end
    end
    ToggleChat()
end

---------------------
--Added for sorian ai
---------------------

function CreateChatList(parent)
    local armies = GetArmiesTable()
    local container = Group(GUI.chatEdit)
    container:DisableHitTest()
    container.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    container.entries = {}
    local function CreatePlayerEntry(data)
        if not data.human and not data.civilian then
            data.nickname = UiUtilsS.trim(string.gsub(data.nickname,'%b()', ''))
        end
        local text = UIUtil.CreateText(container, data.nickname, 12, "Arial")
        text:SetColor('ffffffff')
        text:DisableHitTest()

        text.BG = Bitmap(text)
        text.BG:SetSolidColor('ff000000')
        text.BG.Depth:Set(function() return text.Depth() - 1 end)
        text.BG.Left:Set(function() return text.Left() - 6 end)
        text.BG.Top:Set(function() return text.Top() - 1 end)
        text.BG.Width:Set(function() return container.Width() + 8 end)
        text.BG.Bottom:Set(function() return text.Bottom() + 1 end)

        text.BG.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff666666')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('ff000000')
            elseif event.Type == 'ButtonPress' then
                ChatTo:Set(data.armyID)
                container:Destroy()
                parent.list = nil
                GUI.chatEdit.edit:Enable()
                GUI.chatEdit.edit:AcquireFocus()
            end
            GUI.bg.curTime = 0
        end
        return text
    end

    local entries = {
        {nickname = ToStrings.all.caps, armyID = 'all'},
        {nickname = ToStrings.allies.caps, armyID = 'allies'},
    }

    for armyID, armyData in armies.armiesTable do
        if armyID ~= armies.focusArmy and not armyData.civilian then
            table.insert(entries, {nickname = armyData.nickname, armyID = armyID})
        end
    end

    local maxWidth = 0
    local height = 0
    for index, data in entries do
        local i = index
        table.insert(container.entries, CreatePlayerEntry(data))
        if container.entries[i].Width() > maxWidth then
            maxWidth = container.entries[i].Width() + 8
        end
        height = height + container.entries[i].Height()
        if i > 1 then
            LayoutHelpers.Above(container.entries[i], container.entries[i-1])
        else
            LayoutHelpers.AtLeftIn(container.entries[i], container)
            LayoutHelpers.AtBottomIn(container.entries[i], container)
        end
    end
    container.Width:Set(maxWidth + 40)
    container.Height:Set(height)

    container.LTBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
    container.LTBG:DisableHitTest()
    container.LTBG.Right:Set(container.Left)
    container.LTBG.Bottom:Set(container.Top)

    container.RTBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
    container.RTBG:DisableHitTest()
    container.RTBG.Left:Set(container.Right)
    container.RTBG.Bottom:Set(container.Top)

    container.RBBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
    container.RBBG:DisableHitTest()
    container.RBBG.Left:Set(container.Right)
    container.RBBG.Top:Set(container.Bottom)

    container.RLBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
    container.RLBG:DisableHitTest()
    container.RLBG.Right:Set(container.Left)
    container.RLBG.Top:Set(container.Bottom)

    container.LBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
    container.LBG:DisableHitTest()
    container.LBG.Right:Set(container.Left)
    container.LBG.Top:Set(container.Top)
    container.LBG.Bottom:Set(container.Bottom)

    container.RBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
    container.RBG:DisableHitTest()
    container.RBG.Left:Set(container.Right)
    container.RBG.Top:Set(container.Top)
    container.RBG.Bottom:Set(container.Bottom)

    container.TBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
    container.TBG:DisableHitTest()
    container.TBG.Left:Set(container.Left)
    container.TBG.Right:Set(container.Right)
    container.TBG.Bottom:Set(container.Top)

    container.BBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
    container.BBG:DisableHitTest()
    container.BBG.Left:Set(container.Left)
    container.BBG.Right:Set(container.Right)
    container.BBG.Top:Set(container.Bottom)

    function DestroySelf()
        parent:OnClick()
    end

    UIMain.AddOnMouseClickedFunc(DestroySelf)

    container.OnDestroy = function(self)
        UIMain.RemoveOnMouseClickedFunc(DestroySelf)
    end

    return container
end

function SetupChatLayout(mapGroup)
    savedParent = mapGroup
    CreateChat()
    import("/lua/ui/game/gamemain.lua").RegisterChatFunc(ReceiveChat, 'Chat')
end

function CreateChat()
    if GUI.bg then
        GUI.bg.OnClose()
    end
    GUI.bg = CreateChatBackground()
    GUI.chatEdit = CreateChatEdit()
    GUI.bg.OnResize = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
    end
    GUI.bg.OnResizeSet = function(self)
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
        RewrapLog()
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
    end
    GUI.bg.OnMove = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
    end
    GUI.bg.OnMoveSet = function(self)
        GUI.chatEdit.edit:AcquireFocus()
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnMouseWheel = function(self, rotation)
        local newTop = GUI.chatContainer.top - math.floor(rotation / 100)
        GUI.chatContainer:ScrollSetTop(nil, newTop)
    end
    GUI.bg.OnClose = function(self)
        ToggleChat()
    end
    GUI.bg.OnOptionsSet = function(self)
        GUI.chatContainer:Destroy()
        GUI.chatContainer = false
        for i, v in GUI.chatLines do
            v:Destroy()
        end
        GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
        GUI.chatLines = {}
        CreateChatLines()
        RewrapLog()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
        if not GUI.bg.pinned then
            GUI.bg.curTime = 0
            GUI.bg:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnHideWindow = function(self, hidden)
        if not hidden then
            for i, v in GUI.chatLines do
                v:SetNeedsFrameUpdate(false)
            end
        end
    end
    GUI.bg.curTime = 0
    GUI.bg.pinned = false
    GUI.bg.OnFrame = function(self, delta)
        self.curTime = self.curTime + delta
        if self.curTime > ChatOptions.fade_time then
            ToggleChat()
        end
    end
    GUI.bg.OnPinCheck = function(self, checked)
        GUI.bg.pinned = checked
        GUI.bg:SetNeedsFrameUpdate(not checked)
        GUI.bg.curTime = 0
        GUI.chatEdit.edit:AcquireFocus()
        if checked then
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pinned')
        else
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
        end
    end
    GUI.bg.OnConfigClick = function(self, checked)
        if GUI.config then GUI.config:Destroy() GUI.config = false return end
        CreateConfigWindow()
        GUI.bg:SetNeedsFrameUpdate(false)

    end
    for i, v in GetArmiesTable().armiesTable do
        if not v.civilian then
            ChatOptions[i] = true
        end
    end
    GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
    Tooltip.AddButtonTooltip(GUI.bg._closeBtn, 'chat_close')
    GUI.bg.OldHandleEvent = GUI.bg.HandleEvent
    GUI.bg.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" and self:IsHidden() then
            import("/lua/ui/game/worldview.lua").ForwardMouseWheelInput(event)
            return true
        else
            return GUI.bg.OldHandleEvent(self, event)
        end
    end

    Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
    Tooltip.AddControlTooltip(GUI.bg._configBtn, 'chat_config')
    Tooltip.AddControlTooltip(GUI.bg._closeBtn, 'chat_close')
    Tooltip.AddCheckboxTooltip(GUI.chatEdit.camData, 'chat_camera')

    ChatOptions['links'] = ChatOptions.links or true
    CreateChatLines()
    RewrapLog()
    GUI.chatContainer:CalcVisible()
    ToggleChat()
end

function RewrapLog()
    local tempSize = 0
    for i, v in chatHistory do
        v.wrappedtext = WrapText(v)
        tempSize = tempSize + table.getsize(v.wrappedtext)
    end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0
    GUI.chatContainer:ScrollSetTop(nil, tempSize)
end

function WrapText(data)
    return import("/lua/maui/text.lua").WrapText(data.text,
            function(line)
                local firstLine = GUI.chatLines[1]
                if line == 1 then
                    return firstLine.Right() - (firstLine.name.Left() + firstLine.name:GetStringAdvance(data.name) + 4)
                else
                    return firstLine.Right() - (firstLine.name.Left() + 4)
                end
            end,
            function(text)
                return GUI.chatLines[1].text:GetStringAdvance(text)
            end)
end

function GetArmyData(army)
    local armies = GetArmiesTable()
    local result = nil
    if type(army) == 'number' then
        if armies.armiesTable[army] then
            result = armies.armiesTable[army]
        end
    elseif type(army) == 'string' then
        for i, v in armies.armiesTable do
            if v.nickname == army then
                result = v
                result.ArmyID = i
                break
            end
        end
    end
    return result
end

function CloseChat()
    if not GUI.bg:IsHidden() then
        ToggleChat()
    end
    if GUI.config then
        GUI.config:Destroy()
        GUI.config = nil
    end
end

function CreateConfigWindow()
    import("/lua/ui/game/multifunction.lua").CloseMapDialog()
    local windowTextures = {
        tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
        tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
        tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
        ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
        m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
        mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
        bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
        bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
        br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
        borderColor = 'ff415055',
    }

    local defPosition = Prefs.GetFromCurrentProfile('chat_config') or nil
    GUI.config = Window(GetFrame(0), '<LOC chat_0008>Chat Options', nil, nil, nil, true, true, 'chat_config', defPosition, windowTextures)
    GUI.config.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.config._closeBtn, 'chat_close')
    LayoutHelpers.AnchorToBottom(GUI.config, GetFrame(0), -700)
    LayoutHelpers.SetWidth(GUI.config, 300)
    LayoutHelpers.AtHorizontalCenterIn(GUI.config, GetFrame(0))
    LayoutHelpers.ResetRight(GUI.config)

    GUI.config.DragTL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.config.DragTR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.config.DragBL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.config.DragBR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

    LayoutHelpers.AtLeftTopIn(GUI.config.DragTL, GUI.config, -24, -8)

    LayoutHelpers.AtRightTopIn(GUI.config.DragTR, GUI.config, -22, -8)

    LayoutHelpers.AtLeftIn(GUI.config.DragBL, GUI.config, -24)
    LayoutHelpers.AtBottomIn(GUI.config.DragBL, GUI.config, -8)

    LayoutHelpers.AtRightIn(GUI.config.DragBR, GUI.config, -22)
    LayoutHelpers.AtBottomIn(GUI.config.DragBR, GUI.config, -8)

    GUI.config.DragTL.Depth:Set(function() return GUI.config.Depth() + 10 end)
    GUI.config.DragTR.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBL.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBR.Depth:Set(GUI.config.DragTL.Depth)

    GUI.config.DragTL:DisableHitTest()
    GUI.config.DragTR:DisableHitTest()
    GUI.config.DragBL:DisableHitTest()
    GUI.config.DragBR:DisableHitTest()

    GUI.config.OnClose = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end

    local options = {
        filters = {{type = 'filter', name = '<LOC _Links>Links', key = 'links', tooltip = 'chat_filter'}},
        winOptions = {
                {type = 'color', name = '<LOC _All>', key = 'all_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Allies>', key = 'allies_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Private>', key = 'priv_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Links>', key = 'link_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC notify_0033>', key = 'notify_color', tooltip = 'chat_color'},
                {type = 'splitter'},
                {type = 'slider', name = '<LOC chat_0009>Chat Font Size', key = 'font_size', tooltip = 'chat_fontsize', min = 12, max = 18, inc = 1},
                {type = 'slider', name = '<LOC chat_0010>Window Fade Time', key = 'fade_time', tooltip = 'chat_fadetime', min = 5, max = 30, inc = 1},
                {type = 'slider', name = '<LOC chat_0011>Window Alpha', key = 'win_alpha', tooltip = 'chat_alpha', min = 20, max = 100, inc = 1},
                {type = 'splitter'},
                {type = 'filter', name = '<LOC chat_send_type_title>Default recipient: allies', key = 'send_type', tooltip = 'chat_send_type'},
                {type = 'filter', name = '<LOC chat_0014>Show Feed Background', key = 'feed_background', tooltip = 'chat_feed_background'},
                {type = 'filter', name = '<LOC chat_0015>Persist Feed Timeout', key = 'feed_persist', tooltip = 'chat_feed_persist'},
        },
    }

    local optionGroup = Group(GUI.config:GetClientGroup())
    LayoutHelpers.FillParent(optionGroup, GUI.config:GetClientGroup())
    optionGroup.options = {}
    local tempOptions = {}

    local function UpdateOption(key, value)
        if key == 'win_alpha' then
            value = value / 100
        end
        tempOptions[key] = value
    end

    local function CreateSplitter()
        local splitter = Bitmap(optionGroup)
        splitter:SetSolidColor('ff000000')
        splitter.Left:Set(optionGroup.Left)
        splitter.Right:Set(optionGroup.Right)
        splitter.Height:Set(2)
        return splitter
    end

    local function CreateEntry(data)
        local group = Group(optionGroup)
        if data.type == 'filter' then
            group.check = UIUtil.CreateCheckbox(group, '/dialogs/check-box_btn/', data.name, true)
            LayoutHelpers.AtLeftTopIn(group.check, group)
            group.check.key = data.key
            group.Height:Set(group.check.Height)
            group.Width:Set(function() return group.check.Width() end)
            group.check.OnCheck = function(self, checked)
                UpdateOption(self.key, checked)
            end
            if ChatOptions[data.key] then
                group.check:SetCheck(ChatOptions[data.key], true)
            end
        elseif data.type == 'color' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            local defValue = ChatOptions[data.key] or 1
            group.color = BitmapCombo(group, chatColors, defValue, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
            LayoutHelpers.AtLeftTopIn(group.color, group)
            LayoutHelpers.RightOf(group.name, group.color, 5)
            LayoutHelpers.AtVerticalCenterIn(group.name, group.color)
            LayoutHelpers.SetWidth(group.color, 55)
            group.color.key = data.key
            group.Height:Set(group.color.Height)
            group.Width:Set(group.color.Width)
            group.color.OnClick = function(self, index)
                UpdateOption(self.key, index)
            end
        elseif data.type == 'slider' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            LayoutHelpers.AtLeftTopIn(group.name, group)
            group.slider = IntegerSlider(group, false,
                data.min, data.max,
                data.inc, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
            LayoutHelpers.Below(group.slider, group.name)
            group.slider.key = data.key
            group.Height:Set(function() return group.name.Height() + group.slider.Height() end)
            group.slider.OnValueSet = function(self, newValue)
                UpdateOption(self.key, newValue)
            end
            group.value = UIUtil.CreateText(group, '', 14, "Arial")
            LayoutHelpers.RightOf(group.value, group.slider)
            group.slider.OnValueChanged = function(self, newValue)
                group.value:SetText(string.format('%3d', newValue))
            end
            local defValue = ChatOptions[data.key] or 1
            if data.key == 'win_alpha' then
                defValue = defValue * 100
            end
            group.slider:SetValue(defValue)
            LayoutHelpers.SetWidth(group, 200)
        elseif data.type == 'splitter' then
            group.split = CreateSplitter()
            LayoutHelpers.AtTopIn(group.split, group)
            group.Width:Set(group.split.Width)
            group.Height:Set(group.split.Height)
        end
        if data.type ~= 'splitter' then
            Tooltip.AddControlTooltip(group, data.tooltip or 'chat_filter')
        end
        return group
    end

    local armyData = GetArmiesTable()
    for i, v in armyData.armiesTable do
        if not v.civilian then
            table.insert(options.filters, {type = 'filter', name = v.nickname, key = i})
        end
    end

    local filterTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0012>Message Filters', 14, "Arial Bold")
    LayoutHelpers.AtLeftTopIn(filterTitle, optionGroup, 5, 5)
    Tooltip.AddControlTooltip(filterTitle, 'chat_filter')
    local index = 1
    for i, v in options.filters do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Left:Set(filterTitle.Left)
        optionGroup.options[index].Right:Set(optionGroup.Right)
        if index == 1 then
            LayoutHelpers.Below(optionGroup.options[index], filterTitle, 5)
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], -2)
        end
        index = index + 1
    end
    local splitIndex = index
    local splitter = CreateSplitter()
    splitter.Top:Set(function() return optionGroup.options[splitIndex-1].Bottom() + 5 end)

    local WindowTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0013>Message Colors', 14, "Arial Bold")
    LayoutHelpers.Below(WindowTitle, splitter, 5)
    WindowTitle.Left:Set(filterTitle.Left)
    Tooltip.AddControlTooltip(WindowTitle, 'chat_color')

    local firstOption = true
    local optionIndex = 1
    for i, v in options.winOptions do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Data = v
        if firstOption then
            LayoutHelpers.Below(optionGroup.options[index], WindowTitle, 5)
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            firstOption = false
        elseif v.type == 'color' then
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            if math.mod(optionIndex, 2) == 1 then
                LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-2], 2)
            else
                LayoutHelpers.RightOf(optionGroup.options[index], optionGroup.options[index-1])
            end
        elseif v.type == 'filter' then
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], 4)
            LayoutHelpers.AtLeftIn(optionGroup.options[index], WindowTitle)
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], 4)
            LayoutHelpers.AtHorizontalCenterIn(optionGroup.options[index], optionGroup)
        end
        optionIndex = optionIndex + 1
        index = index + 1
    end

    local applyBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC OPTIONS_0139>', 16)
    LayoutHelpers.Below(applyBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtLeftIn(applyBtn, optionGroup)
    applyBtn.OnClick = function(self)
        ChatOptions = table.merged(ChatOptions, tempOptions)
        Prefs.SetToCurrentProfile("chatoptions", ChatOptions)
        GUI.bg:OnOptionsSet()
    end

    local resetBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Reset>', 16)
    LayoutHelpers.Below(resetBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtRightIn(resetBtn, optionGroup)
    LayoutHelpers.ResetLeft(resetBtn)
    resetBtn.OnClick = function(self)
        for option, value in defOptions do
            for i, control in optionGroup.options do
                if control.Data.key == option then
                    if control.Data.type == 'slider' then
                        if control.Data.key == 'win_alpha' then
                            value = value * 100
                        end
                        control.slider:SetValue(value)
                    elseif control.Data.type == 'color' then
                        control.color:SetItem(value)
                    elseif control.Data.type == 'filter' then
                        control.check:SetCheck(value, true)
                    end
                    UpdateOption(option, value)
                    break
                end
            end
        end
    end

    local okBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Ok>', 16)
    LayoutHelpers.Below(okBtn, resetBtn, 4)
    LayoutHelpers.AtLeftIn(okBtn, optionGroup)
    okBtn.OnClick = function(self)
        ChatOptions = table.merged(ChatOptions, tempOptions)
        Prefs.SetToCurrentProfile("chatoptions", ChatOptions)
        GUI.bg:OnOptionsSet()
        GUI.config:Destroy()
        GUI.config = false
    end

    local cancelBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Cancel>', 16)
    LayoutHelpers.Below(cancelBtn, resetBtn, 4)
    LayoutHelpers.AtRightIn(cancelBtn, optionGroup)
    LayoutHelpers.ResetLeft(cancelBtn)
    cancelBtn.OnClick = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end


    GUI.config.Bottom:Set(function() return okBtn.Bottom() + 5 end)
    if defPosition ~= nil then
        GUI.config.Top:Set(defPosition.top)
        GUI.config.Left:Set(defPosition.left)
    else
        GUI.config.Top:Set(function() return LayoutHelpers.ScaleNumber(90) end)
    end
    GUI.config:SetPositionLock(false) -- allow window to be draggable, didn't worked in Window() call
end

function CloseChatConfig()
    if GUI.config then
        GUI.config:Destroy()
        GUI.config = nil
    end
end
