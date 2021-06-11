local UiUtilsS = import('/lua/UiUtilsSorian.lua')
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local EffectHelpers = import('/lua/maui/effecthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Checkbox = import('/lua/ui/controls/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Window = import('/lua/maui/window.lua').Window
local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Prefs = import('/lua/user/prefs.lua')
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIMain = import('/lua/ui/uimain.lua')
--[[ LOC Strings
<LOC chat_win_0001>To %s:
<LOC chat_win_0002>Chat (%d - %d of %d lines)
--]]
--this one from lobby mod manager
local CheckBox = import('/lua/maui/checkbox.lua').Checkbox
local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
local Emojis =  import('/lua/ui/lobby/emojis.lua')
local Packages =  Emojis.Packages
local lineHeight = 30

local AddUnicodeCharToEditText = import('/lua/UTF.lua').AddUnicodeCharToEditText

local CHAT_INACTIVITY_TIMEOUT = 15  -- in seconds
local savedParent = false
local chatHistory = {}

local commandHistory = {}

local ChatTo = import('/lua/lazyvar.lua').Create()

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

GUI = import('/lua/ui/controls.lua').Get()
GUI.chatLines = GUI.chatLines or {}

local FactionsIcon = {}
local Factions = import('/lua/factions.lua').Factions
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
    Emojis.ScanPackages()
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
        local styles = import('/lua/maui/window.lua').styles
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
        --LayoutHelpers.SetDimensions(line.teamColor,line.Height(),line.Height())
        -- LayoutHelpers need to be updated btw
        line.teamColor.Height:Set(line.Height)
        line.teamColor.Width:Set(line.Height)
        LayoutHelpers.AtLeftTopIn(line.teamColor, line)

        line.factionIcon = Bitmap(line.teamColor)
        line.factionIcon:SetSolidColor('00000000')
        LayoutHelpers.FillParent(line.factionIcon, line.teamColor)

        -- Player name
        line.name = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial Bold",true)
        LayoutHelpers.CenteredRightOf(line.name, line.teamColor, 4)
        LayoutHelpers.DepthOverParent(line.name,line,10)
        --line.name.Depth:Set(function() return line.Depth() + 10 end)
        line.name:SetColor('ffffffff')
        line.name:DisableHitTest()
       -- line.name:SetDropShadow(true)

        line.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if  event.KeyCode == 3 and self.camera then
                    GetCamera('WorldCamera'):RestoreSettings(self.camera)
                end
            end
        end
        line.name.HandleEvent = function(self, event)
            if event.Type == 'ButtonPress' then
                if  event.KeyCode == 1 then
                    if self.chatID then
                        if GUI.bg:IsHidden() then GUI.bg:Show() end
                        ChatTo:Set(self.chatID)
                        if GUI.chatEdit.edit then
                            GUI.chatEdit.edit:AcquireFocus()
                        end
                        if GUI.chatEdit.private then
                            GUI.chatEdit.private:SetCheck(true)
                        end
                    end
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
        line.contents = nil
        line.renderChatLine = function(self,entry,id)
            local Wcontents = entry.wrappedtext[id]
            if self.contents then
                self.contents:Destroy()
                self.contents = nil
            end
            if id == 1 then
                self.name.chatID = entry.armyID
                if self.name.chatID == GetFocusArmy() then 
                    self.name:Disable()
                else
                    self.name:Enable()
                end
                self.name:SetText(entry.name)
                self.camera = entry.camera
                if self.camera then
                    self.name:SetColor(chatColors[ChatOptions.link_color] )
                else
                    self.name:SetColor('ffffffff')
                end
                self.teamColor:SetSolidColor(entry.color)
                self.factionIcon:SetTexture(UIUtil.UIFile(FactionsIcon[entry.faction]))
            else
                self.name:Disable()
                self.name:SetText("")
                self.teamColor:SetSolidColor('00000000')
                self.factionIcon:SetSolidColor('00000000')
            end
            local parent = nil
            for _,content in Wcontents do
                if content.text then --TEXT
                    if parent then
                        parent.child = UIUtil.CreateText(parent, '', ChatOptions.font_size, "Arial",true)
                        LayoutHelpers.DepthOverParent(parent.child,self,10)
                        LayoutHelpers.RightOf(parent.child, parent,2)
                        
                        parent.child:DisableHitTest()
                        parent.child:SetColor(chatColors[ChatOptions[entry.tokey]])
                        LayoutHelpers.AtVerticalCenterIn(parent.child, self.teamColor)
                        parent.child:SetText(content.text)
                        parent.child:SetClipToWidth()
                        parent = parent.child
                    else    
                        self.contents = UIUtil.CreateText(self, '', ChatOptions.font_size, "Arial",true)
                        LayoutHelpers.DepthOverParent(self.contents,self,10)
                        LayoutHelpers.RightOf(self.contents, self.name,2)
                        self.contents:DisableHitTest()
                        self.contents:SetColor(chatColors[ChatOptions[entry.tokey]])
                        LayoutHelpers.AtVerticalCenterIn(self.contents, self.teamColor)
                        self.contents:SetText(content.text)
                        self.contents:SetClipToWidth()
                        parent = self.contents
                    end

                elseif content.emoji then--EMOJIS
                    if parent then
                       
                        parent.child = Bitmap(parent,UIUtil.UIFile(Emojis.emojis_textures .. content.emoji .. '.dds'))
                        LayoutHelpers.DepthOverParent(parent.child,self.name,0)
                        LayoutHelpers.CenteredRightOf(parent.child, parent,2)
                        parent.child.Height:Set(self.Height)
                        parent.child.Width:Set(self.Height)

                        parent = parent.child
                       
                    else
                        self.contents = Bitmap(self,UIUtil.UIFile(Emojis.emojis_textures .. content.emoji .. '.dds'))
                        LayoutHelpers.DepthOverParent(self.contents,self.name,0)
                        LayoutHelpers.CenteredRightOf(self.contents, self.name,2)
                        self.contents.Height:Set(self.Height)
                        self.contents.Width:Set(self.Height)
                        parent = self.contents
                    end
                end
            end
        end
        return line
    end
    
    if GUI.chatContainer then
        local curEntries = table.getsize(GUI.chatLines)
        local neededEntries = math.floor(GUI.chatContainer.Height() / (GUI.chatLines[1].Height() + 2))
        if curEntries - neededEntries == 0 then
            return
        elseif curEntries - neededEntries < 0 then
            for i = curEntries + 1, neededEntries do
                local index = i
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
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
            GUI.chatLines[1].Height:Set(function() return GUI.chatLines[1].name.Height() + 4 end)
            GUI.chatLines[1].Right:Set(GUI.chatContainer.Right)
        end
        local index = 1
        while GUI.chatLines[index].Bottom() + GUI.chatLines[1].Height() < GUI.chatContainer.Bottom() do
            index = index + 1
            if not GUI.chatLines[index] then
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
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
                
                line:renderChatLine(chatHistory[curEntry], curTop)
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
                line.teamColor:SetSolidColor('00000000')
                if line.contents then
                    line.contents:Destroy()
                    line.contents = nil
                end
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

local RunChatCommand = import('/lua/ui/notify/commands.lua').RunChatCommand
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
            if GUI.EmojiSelector then
                GUI.EmojiSelector:Highlight(true)
            elseif table.getsize(commandHistory) > 0 then
                if self.recallEntry then
                    self.recallEntry = math.max(self.recallEntry-1, 1)
                else
                    self.recallEntry = table.getsize(commandHistory)
                end
                RecallCommand(self.recallEntry)
            end
        elseif charcode == UIUtil.VK_DOWN then
            if GUI.EmojiSelector then
                GUI.EmojiSelector:Highlight(false)
            elseif table.getsize(commandHistory) > 0 then
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
    group.edit.OnTextChanged = function(self, newText, oldText)
        if   GUI.EmojiSelector and GUI.EmojiSelector.BeginPos then
            if  GUI.EmojiSelector.BeginPos > self:GetCaretPosition() then
                GUI.EmojiSelector:Destroy()
                GUI.EmojiSelector = nil
                return
            end
            local EmojiText = string.sub(newText, GUI.EmojiSelector.BeginPos +1, self:GetCaretPosition())
            UpdateEmojiSelector(EmojiText)
        end
    end
    group.edit.OnCharPressed = function(self, charcode)
        -- 58 is ':' code
        if charcode == 58 and ChatOptions.chat_emojis then
            if GUI.EmojiSelector  then
                GUI.EmojiSelector:Destroy()
                GUI.EmojiSelector = nil
            else
                CreateEmojiSelector()
                GUI.EmojiSelector.BeginPos = self:GetCaretPosition() + 1
            end
        end
        --

        local charLim = self:GetMaxChars()
        if charcode == 9 then--tab code
            if table.empty(GUI.EmojiSelector.FoundEmojis) then return true end
            local text =        self:GetText() 
            local CaretPos =    self:GetCaretPosition()
            
            local emojiname =  GUI.EmojiSelector.FoundEmojis[GUI.EmojiSelector.selectionIndex].pack..'/'.. GUI.EmojiSelector.FoundEmojis[GUI.EmojiSelector.selectionIndex].emoji

            self:SetText(string.sub(text, 1, GUI.EmojiSelector.BeginPos)..emojiname..':'..string.sub(text,CaretPos + 1, string.len(text)))
            self:SetCaretPosition(string.len(emojiname) + GUI.EmojiSelector.BeginPos + 1)
            GUI.EmojiSelector:Destroy()
            GUI.EmojiSelector = nil
            
            return true
        end
        GUI.bg.curTime = 0
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    group.edit.OnEnterPressed = function(self, text)
        if GUI.EmojiSelector then
            GUI.EmojiSelector:Destroy()
            GUI.EmojiSelector = nil
        end
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
            if import('/lua/ui/game/taunt.lua').CheckForAndHandleTaunt(text) then
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
    
    if msg.to == 'notify' and not import('/lua/ui/notify/notify.lua').processIncomingMessage(sender, msg) then
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
    local tempText = WrapContents({contents = Emojis.CheckEmojis(msg.text,ChatOptions.chat_emojis),name = name})
    --LOG(repr(tempText))
    -- if text wrap produces no lines (ie text is all white space) then add a blank line
    
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
        if modifiers.Shift then
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
    container.Width:Set(maxWidth)
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
    import('/lua/ui/game/gamemain.lua').RegisterChatFunc(ReceiveChat, 'Chat')
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
        UpdateEmojiSelector()
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
            import('/lua/ui/game/worldview.lua').ForwardMouseWheelInput(event)
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
        v.wrappedtext = WrapContents({contents = Emojis.CheckEmojis(v.text,ChatOptions.chat_emojis),name = v.name})
        
        --v.wrappedtext = WrapText(v)
        tempSize = tempSize + table.getsize(v.wrappedtext)
    end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0
    GUI.chatContainer:ScrollSetTop(nil, tempSize)
end


function CreatePackageManagerWindow()
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
    GUI.PackageManager = Window(GetFrame(0), 'Package Manager', nil, nil, nil, true, true, 'package_manager', nil, windowTextures)
    GUI.PackageManager.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.PackageManager._closeBtn, 'chat_close')


    LayoutHelpers.SetDimensions(GUI.PackageManager,500,500)
    LayoutHelpers.AtCenterIn(GUI.PackageManager, GetFrame(0))
    LayoutHelpers.AtHorizontalCenterIn(GUI.PackageManager._title, GUI.PackageManager)

    GUI.PackageManager.DragTL = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.PackageManager.DragTR = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.PackageManager.DragBL = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.PackageManager.DragBR = Bitmap(GUI.PackageManager, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))


    LayoutHelpers.AtLeftTopIn(GUI.PackageManager.DragTL, GUI.PackageManager, -24, -8)

    LayoutHelpers.AtRightTopIn(GUI.PackageManager.DragTR, GUI.PackageManager, -22, -8)

    LayoutHelpers.AtLeftIn(GUI.PackageManager.DragBL, GUI.PackageManager, -24)
    LayoutHelpers.AtBottomIn(GUI.PackageManager.DragBL, GUI.PackageManager, -8)

    LayoutHelpers.AtRightIn(GUI.PackageManager.DragBR, GUI.PackageManager, -22)
    LayoutHelpers.AtBottomIn(GUI.PackageManager.DragBR, GUI.PackageManager, -8)

    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragTL, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragTR, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragBL, GUI.PackageManager, 10)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.DragBR, GUI.PackageManager, 10)

    GUI.PackageManager.DragTL:DisableHitTest()
    GUI.PackageManager.DragTR:DisableHitTest()
    GUI.PackageManager.DragBL:DisableHitTest()
    GUI.PackageManager.DragBR:DisableHitTest()

    GUI.PackageManager.TopLine = 1
    GUI.PackageManager.SizeLine = table.getsize(Packages)
    GUI.PackageManager.scroll = UIUtil.CreateVertScrollbarFor(GUI.PackageManager, -43,nil,10,25) -- scroller
    LayoutHelpers.DepthOverParent(GUI.PackageManager.scroll , GUI.PackageManager, 10)

    GUI.PackageManager.OnClose = function(self) -- close button
        GUI.PackageManager:Destroy()
        GUI.PackageManager = nil
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.PackageManager.GetScrollValues = function(self, axis)
        --LOG( 1 ..' '.. self.SizeLine..' '..self.TopLine.. ' '.. math.min(self.TopLine + self.numLines, self.SizeLine))
        return 1, self.SizeLine ,self.TopLine , math.min(self.TopLine + self.numLines, self.SizeLine)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.PackageManager.ScrollLines = function(self, axis, delta)
        -- LOG(delta)
        -- LOG(self.TopLine)
        self:ScrollSetTop(axis, self.TopLine + delta)
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.PackageManager.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.TopLine + math.floor(delta) * self.numLines )
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.PackageManager.ScrollSetTop = function(self, axis, top)
        --top = math.floor(top)
        if top == self.TopLine then return end
        self.TopLine = math.max(math.min(self.SizeLine - self.numLines + 1, top), 1)
        self:CalcVisible()
    end

  
    

    GUI.PackageManager.ScrollToBottom = function(self)
        GUI.chatContainer:ScrollSetTop(nil, self.numLines)
    end

    -- determines what controls should be visible or not
    GUI.PackageManager.CalcVisible = function(self)
        local packIndex = 1
        local lineIndex = 1
        local dorender = false
        for id,pack in Packages do
            if packIndex == self.TopLine then  dorender = true end
            if dorender then
                self.LineGroup.Lines[lineIndex]:render(pack.info,id)
                if self.numLines == lineIndex then return end
                lineIndex = lineIndex + 1
            end
            packIndex = packIndex + 1
        end
        for ind = lineIndex, self.numLines do self.LineGroup.Lines[ind]:render() end
    end
    
      -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.PackageManager.IsScrollable = function(self, axis)
        return true
    end
    
    --scrlling
    GUI.PackageManager.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            if event.WheelRotation > 0 then
                self:ScrollLines(nil, -1)
            else
                self:ScrollLines(nil, 1)
            end
            return true
        end
        return false
    end

    GUI.PackageManager.LineGroup = Group(GUI.PackageManager) --group that contains PM data lines
    LayoutHelpers.AtLeftIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    LayoutHelpers.LeftOf(GUI.PackageManager.LineGroup, GUI.PackageManager.scroll, 5)
    LayoutHelpers.AtTopIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    LayoutHelpers.AtBottomIn(GUI.PackageManager.LineGroup, GUI.PackageManager.ClientGroup, 5)
    LayoutHelpers.DepthOverParent(GUI.PackageManager.LineGroup,GUI.PackageManager,10)
    GUI.PackageManager.LineGroup.Lines = {}



    

    local function CreatePackageManagerLines()
        local function CreatePackageManagerLine()
            local line = Group(GUI.PackageManager.LineGroup)
            LayoutHelpers.DepthOverParent(line,GUI.PackageManager.LineGroup,1)
            line.bg = CheckBox(line,
                        UIUtil.SkinnableFile('/MODS/blank.dds'),
                        UIUtil.SkinnableFile('/MODS/single.dds'),
                        UIUtil.SkinnableFile('/MODS/single.dds'),
                        UIUtil.SkinnableFile('/MODS/double.dds'),
                        UIUtil.SkinnableFile('/MODS/disabled.dds'),
                        UIUtil.SkinnableFile('/MODS/disabled.dds'),
                            'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
            LayoutHelpers.SetDimensions(line,80,80)
            LayoutHelpers.FillParent(line.bg, line)
            LayoutHelpers.DepthOverParent(line.bg,line,1)
            line.bg:Disable()
    
    
            line.name = UIUtil.CreateText(line, '', 14, UIUtil.bodyFont,true)
            line.name:SetColor('FFE9ECE9') 
            line.name:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(line.name, line, 5, 5)
    
            line.author = UIUtil.CreateText(line, '', 14, UIUtil.bodyFont,true)
            line.author:DisableHitTest()
            line.author:SetColor('FFE9ECE9') 
            LayoutHelpers.Below(line.author, line.name,5)
    
            line.desc = MultiLineText(line, UIUtil.bodyFont, 12, 'FFA2A5A2')
            line.desc:SetDropShadow(true)
            line.desc:DisableHitTest()
            LayoutHelpers.Below(line.desc, line.author,5)
            line.desc.Width:Set(line.Width() - 10)
           
            --data:
            -- name --package name
            -- description -- its description
            -- author -- its author
            -- isEnabled -- is pack active
    
            line.render = function(self, data, id)
                if data then
                    self.bg.id = id    
                    self.name:SetText(data.name)
                    self.author:SetText(data.author)
                    self.desc:SetText(data.description)
                    self.bg:Enable()
                    self.bg:SetCheck(data.isEnabled,true)
                else
                    self.name:SetText('')
                    self.author:SetText('')
                    self.desc:Clear()
                    self.bg:Disable()
                end
            end
            line.bg.OnCheck = function(self, checked)
                LOG('set '..repr(checked)..' on '..repr(self.id))
                Emojis.UpdatePacks(self.id, checked)
            end
    
            return line
        end
        local index = 1
        GUI.PackageManager.LineGroup.Lines[index]  = CreatePackageManagerLine()
        local parent = GUI.PackageManager.LineGroup.Lines[index] 
        LayoutHelpers.AtLeftTopIn( parent,GUI.PackageManager.LineGroup,5,5)
        LayoutHelpers.AtRightIn(parent,GUI.PackageManager.LineGroup,5)
        while GUI.PackageManager.LineGroup.Bottom() -  parent.Bottom() > 85 do
            index = index + 1 
            GUI.PackageManager.LineGroup.Lines[index] = CreatePackageManagerLine()
            LayoutHelpers.Below(GUI.PackageManager.LineGroup.Lines[index] ,parent ,5)
            LayoutHelpers.AtRightIn(GUI.PackageManager.LineGroup.Lines[index],parent)
            parent = GUI.PackageManager.LineGroup.Lines[index] 
        end
        GUI.PackageManager.numLines = index
    end
    CreatePackageManagerLines()
    GUI.PackageManager:CalcVisible()
 

end

function WrapText(data)
    return import('/lua/maui/text.lua').WrapText(data.text,
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
    if GUI.PackageManager then
        GUI.PackageManager:Destroy()
        GUI.PackageManager = nil
    end
    import('/lua/ui/game/multifunction.lua').CloseMapDialog()
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
    GUI.config = Window(GetFrame(0), '<LOC chat_0008>Chat Options', nil, nil, nil, true, true, 'chat_config', nil, windowTextures)
    GUI.config.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.config._closeBtn, 'chat_close')

    LayoutHelpers.AtTopIn(GUI.config, GetFrame(0), 100)
    --LayoutHelpers.AtTopIn(GUI.config, GetFrame(0))
    LayoutHelpers.SetWidth(GUI.config, 300)
    --LayoutHelpers.SetHeight(GUI.config, 300)
    LayoutHelpers.AtHorizontalCenterIn(GUI.config, GetFrame(0))
    --LayoutHelpers.AtCenterIn(GUI.config, GetFrame(0))
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
                {type = 'slider', name = '<LOC chat_0009>Chat Font Size', key = 'font_size', tooltip = 'chat_fontsize', min = 12, max = 18, inc = 2},
                {type = 'slider', name = '<LOC chat_0010>Window Fade Time', key = 'fade_time', tooltip = 'chat_fadetime', min = 5, max = 30, inc = 1},
                {type = 'slider', name = '<LOC chat_0011>Window Alpha', key = 'win_alpha', tooltip = 'chat_alpha', min = 20, max = 100, inc = 1},
                {type = 'splitter'},
                {type = 'filter', name = '<LOC chat_0014>Show Feed Background', key = 'feed_background', tooltip = 'chat_feed_background'},
                {type = 'filter', name = '<LOC chat_0015>Persist Feed Timeout', key = 'feed_persist', tooltip = 'chat_feed_persist'},
                {type = 'filter', name = 'Chat emojis', key = 'chat_emojis', tooltip = 'chat_emojis'},
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
            group.Width:Set(group.check.Width)
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

    local resetBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Reset>', 16)
    LayoutHelpers.Below(resetBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtLeftIn(resetBtn, optionGroup)
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

    local packageBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', 'Package Manager', 12)
    LayoutHelpers.Below(packageBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtRightIn(packageBtn, optionGroup)
    LayoutHelpers.ResetLeft(packageBtn)
    packageBtn.OnClick = function(self)
        CreatePackageManagerWindow()
        GUI.config:Destroy()
        GUI.config = false
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
    --LayoutHelpers.AtCenterIn(GUI.config, GetFrame(0))
end

function CloseChatConfig()
    if GUI.config then
        GUI.config:Destroy()
        GUI.config = nil
    end
end

function WrapContents(data)
    return FitContentsInLine(data.contents,GUI.chatLines[1].Height(), 
    function(line)
        local firstLine = GUI.chatLines[1]
        if line == 1 then
            return firstLine.Right() - (firstLine.name.Left() + firstLine.name:GetStringAdvance(data.name) + 4)
        else
            return firstLine.Right() - (firstLine.name.Left() + 4)
        end
    end, 
    function(text)
        return GUI.chatLines[1].name:GetStringAdvance(text)
    end)
end


--the most complicated thing here that fits in line elements
function FitContentsInLine(contents, lineHeight, lineWidth, GetStringAdvance)
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
                --LOG(repr(fittedText))
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
end



--window that appears on input ':'
function CreateEmojiSelector()
    GUI.EmojiSelector = Bitmap(GUI.bg)
    GUI.EmojiSelector:SetSolidColor('ff000000')
    LayoutHelpers.Above(GUI.EmojiSelector, GUI.chatEdit.edit, 2)
    LayoutHelpers.AtLeftIn(GUI.EmojiSelector,GUI.chatContainer)
    LayoutHelpers.AtTopIn(GUI.EmojiSelector,GUI.chatContainer)
    LayoutHelpers.AtRightIn(GUI.EmojiSelector,GUI.chatContainer)
    LayoutHelpers.DepthOverParent(GUI.EmojiSelector,GUI.chatContainer,100)
    GUI.EmojiSelector.curIndex = 1
    GUI.EmojiSelector.MaxSize = 0
    GUI.EmojiSelector.selectionIndex = 1
    GUI.EmojiSelector.Highlight = function (self,up)
        
        self.emojiLines.lines[self.selectionIndex].bg:SetSolidColor('ff000000')
        if up == true then
            if self.selectionIndex ~= table.getn(self.FoundEmojis) then
                if self.selectionIndex - self.curIndex == self.MaxSize - 1  then
                    self.curIndex = self.curIndex + 1
                    UpdateEmojiSelector()
                end
                self.selectionIndex = self.selectionIndex + 1
            end
        elseif up == false then
            if self.selectionIndex > 1 then
                if self.selectionIndex == self.curIndex then
                    self.curIndex = self.curIndex - 1
                    UpdateEmojiSelector()
                end
                self.selectionIndex = self.selectionIndex - 1
            end   
        end
        self.emojiLines.lines[self.selectionIndex].bg:SetSolidColor('ff202020')
    end
    GUI.EmojiSelector.HandleEvent = function(self,event)
        if event.WheelRotation ~= 0 then
            if event.WheelRotation > 0 then
                if GUI.EmojiSelector.MaxSize + GUI.EmojiSelector.curIndex <= table.getn(self.FoundEmojis) then
                    GUI.EmojiSelector.curIndex = GUI.EmojiSelector.curIndex + 1
                    GUI.EmojiSelector.selectionIndex = GUI.EmojiSelector.curIndex
                    GUI.bg.curTime = 0
                    UpdateEmojiSelector()
                end
            else
                if GUI.EmojiSelector.curIndex ~= 1 then
                    GUI.EmojiSelector.curIndex = GUI.EmojiSelector.curIndex - 1
                    GUI.EmojiSelector.selectionIndex = GUI.EmojiSelector.curIndex
                    GUI.bg.curTime = 0
                    UpdateEmojiSelector()
                end
            end

        end
    end
   
end


function UpdateEmojiSelector(emojiText)
    if GUI.EmojiSelector == nil then return end
    if emojiText then
        GUI.EmojiSelector.curIndex = 1
        GUI.EmojiSelector.emojiText = emojiText
        GUI.EmojiSelector.FoundEmojis = Emojis.processInput(emojiText)
        GUI.EmojiSelector.selectionIndex = 1   
    end
    local FoundEmojis = GUI.EmojiSelector.FoundEmojis
    if GUI.EmojiSelector.emojiLines then
        GUI.EmojiSelector.emojiLines:Destroy()
    end
    GUI.EmojiSelector.emojiLines = Group(GUI.EmojiSelector)
    LayoutHelpers.FillParentFixedBorder(GUI.EmojiSelector.emojiLines, GUI.EmojiSelector)
    GUI.EmojiSelector.emojiLines.lines = {}
    LayoutHelpers.DepthOverParent(GUI.EmojiSelector.emojiLines,GUI.EmojiSelector,10)
   
    if not table.empty(FoundEmojis) then
        local index = GUI.EmojiSelector.curIndex
        while index <= table.getn(FoundEmojis) do
            local emojiname = FoundEmojis[index].pack .. '/' .. FoundEmojis[index].emoji
            local path = UIUtil.UIFile(Emojis.emojis_textures .. emojiname .. '.dds')
            GUI.EmojiSelector.emojiLines.lines[index] = Group(GUI.EmojiSelector.emojiLines)
            local emojiLine = GUI.EmojiSelector.emojiLines.lines[index]
            
            emojiLine.HandleEvent = function(self, event)
                if event.Type == 'ButtonPress' then
                    local text =        GUI.chatEdit.edit:GetText() 
                    local CaretPos =    GUI.chatEdit.edit:GetCaretPosition()
                    
                    local newtext = string.sub(text, 1, GUI.EmojiSelector.BeginPos - 1)..self.emoji..string.sub(text,CaretPos + 1, string.len(text))
                    local oldtext = GUI.EmojiSelector.emojiText or ''
                    GUI.EmojiSelector:Destroy()
                    GUI.EmojiSelector = nil
                    GUI.chatEdit.edit:SetText(newtext)
                    GUI.chatEdit.edit:SetCaretPosition(CaretPos + string.len(self.emoji) - 1 - string.len(oldtext))
                    GUI.chatEdit.edit:AcquireFocus()
                    
                elseif event.Type == 'MouseEnter' then
                    for _,line in GUI.EmojiSelector.emojiLines.lines do
                        line.bg:SetSolidColor('ff000000') 
                    end
                    self.bg:SetSolidColor('ff202020')
                elseif event.Type == 'MouseExit' then
                    self.bg:SetSolidColor('ff000000')
                    GUI.EmojiSelector:Highlight()
                end
            end
            
            LayoutHelpers.DepthOverParent(emojiLine,GUI.EmojiSelector.emojiLines)
            

           
            
            LayoutHelpers.SetDimensions(emojiLine,lineHeight,lineHeight)
            
            
            
            if index == GUI.EmojiSelector.curIndex then
                LayoutHelpers.AtLeftBottomIn(emojiLine, GUI.EmojiSelector,2,2)
            else
                LayoutHelpers.Above(emojiLine, GUI.EmojiSelector.emojiLines.lines[index - 1], 2)
            end
            LayoutHelpers.AtRightIn(emojiLine,GUI.EmojiSelector.emojiLines,2)

            emojiLine.bg = Bitmap(emojiLine)
            emojiLine.bg:DisableHitTest()
            LayoutHelpers.FillParent( emojiLine.bg ,emojiLine)
            emojiLine.bg:SetSolidColor('ff000000')
          

            emojiLine.icon = Bitmap(emojiLine,path)
            emojiLine.icon:DisableHitTest()
           
            emojiLine.icon.Height:Set(emojiLine.Height)
            emojiLine.icon.Width:Set(emojiLine.Height)
            LayoutHelpers.AtLeftTopIn(emojiLine.icon, emojiLine)

            emojiLine.text = UIUtil.CreateText(emojiLine, '', 20, "Arial",true)
            emojiLine.text:DisableHitTest()
            LayoutHelpers.RightOf(emojiLine.text, emojiLine.icon, 2)
            emojiLine.text:SetText(':'..FoundEmojis[index].emoji ..':')

            emojiLine.emoji =':'.. emojiname..':'

            emojiLine.pack = UIUtil.CreateText(emojiLine, '', 20, "Arial",true)
            emojiLine.pack:DisableHitTest()
            LayoutHelpers.AtRightIn(emojiLine.pack,GUI.EmojiSelector.emojiLines, 5)
            LayoutHelpers.AtTopIn(emojiLine.pack,emojiLine )
            emojiLine.pack:SetText(FoundEmojis[index].pack)
            emojiLine.pack:SetColor('FF808080')
            index = index + 1
            if  emojiLine:Top() - GUI.chatContainer.Top() < lineHeight then
                LayoutHelpers.AtTopIn(GUI.EmojiSelector,GUI.chatContainer)
                GUI.EmojiSelector.MaxSize = index - GUI.EmojiSelector.curIndex
                if emojiText then GUI.EmojiSelector:Highlight() end
                
                return
            end
        end
        GUI.EmojiSelector.Top:Set(function()return GUI.EmojiSelector.emojiLines.lines[index - 1].Top() - 2 end)
        GUI.EmojiSelector.MaxSize = index - GUI.EmojiSelector.curIndex
        if emojiText then GUI.EmojiSelector:Highlight() end
    else
        GUI.EmojiSelector.Top:Set(GUI.EmojiSelector.Bottom)
    end
    
end

