--*****************************************************************************
--* File: lua/modules/ui/campaign/operationbriefing.lua
--* Author: Chris Blackwell, Evan Pongress
--* Summary: campaign operations view
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Movie = import('/lua/maui/movie.lua').Movie
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Group = import('/lua/maui/group.lua').Group
local WrapText = import('/lua/maui/text.lua').WrapText
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Button = import('/lua/maui/button.lua').Button
local Prefs = import('/lua/user/prefs.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local CampaignManager = import('/lua/ui/campaign/campaignmanager.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

local mapErrorDialog = false
local activePopupButton = false
local streamThread = false
local faction = false
local difficulty = false

local backgrounds = false

function CreateBackground(parent)
    local table = {}
    
    table.top = Bitmap(parent, UIUtil.UIFile('/scx_menu/operation-briefing/border-console-top_bmp.dds'))
    LayoutHelpers.AtTopIn(table.top, parent)
    LayoutHelpers.AtHorizontalCenterIn(table.top, parent)
    
    table.bottom = Bitmap(parent, UIUtil.UIFile('/scx_menu/operation-briefing/border-console-bot_bmp.dds'))
    LayoutHelpers.AtBottomIn(table.bottom, parent)
    LayoutHelpers.AtHorizontalCenterIn(table.bottom, parent)
    
    return table
end

function CreateUI(operationID, briefingData)
    local parent = Group(GetFrame(0))
    LayoutHelpers.FillParent(parent, GetFrame(0))
    parent:DisableHitTest()
    local playing = false
    
    local ambientSounds = PlaySound(Sound({Cue = "AMB_SER_OP_Briefing", Bank = "AmbientTest",}))
    
    local currentBriefingText = {}
    local fmv_time = 0
    local fmv_playing = false
    Prefs.SetToCurrentProfile('Last_Op_Selected', {id = operationID})
    
    local briefingGroup = Group(parent)
    briefingGroup.Depth:Set(function() return parent.Depth() + 5 end)
    LayoutHelpers.FillParent(briefingGroup, parent)
    briefingGroup:DisableHitTest()
    
    backgrounds = CreateBackground(parent)
    
    local backBtn = UIUtil.CreateButtonStd(briefingGroup, '/scx_menu/small-btn/small', "<LOC opbrief_0002>Back", 16, 2)
    LayoutHelpers.AtLeftIn(backBtn, backgrounds.bottom, 25)
    LayoutHelpers.AtBottomIn(backBtn, backgrounds.bottom, -4)
    backBtn.OnClick = function(self)
        parent:Destroy()
        import('/lua/ui/campaign/selectcampaign.lua').CreateUI()
    end

    import('/lua/ui/uimain.lua').SetEscapeHandler(function() backBtn.OnClick() end)
    
    local launchBtn = UIUtil.CreateButtonStd(briefingGroup, '/scx_menu/medium-no-br-btn/medium-uef', "<LOC opbrief_0003>Launch", 20, 2)
    LayoutHelpers.AtRightIn(launchBtn, backgrounds.bottom, 20)
    LayoutHelpers.AtBottomIn(launchBtn, backgrounds.bottom, 2)
    Tooltip.AddButtonTooltip(launchBtn, 'campaignbriefing_launch')
    launchBtn.OnClick = function(self)
        local scenario = MapUtil.LoadScenario(briefingData.opMap)
        if scenario then
            local function TryLaunch()
                local factionToIndex = import('/lua/factions.lua').FactionIndexMap
                LaunchSinglePlayerSession(import('/lua/SinglePlayerLaunch.lua').SetupCampaignSession(scenario, difficulty, factionToIndex[faction], 
                    {opKey = operationID, campaignID = faction, difficulty = difficulty}, false))
                parent:Destroy()
                MenuCommon.MenuCleanup()
            end
            local ok,msg = pcall(TryLaunch)
            if not ok then
                if mapErrorDialog then mapErrorDialog:Destroy() end
                mapErrorDialog = UIUtil.ShowInfoDialog(briefingGroup, LOC("<LOC opbrief_0000>Error loading map") .. ': ' .. msg, "<LOC _Ok>")
                mapErrorDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
            end
        else
            if mapErrorDialog then mapErrorDialog:Destroy() end
            mapErrorDialog = UIUtil.ShowInfoDialog(briefingGroup, LOCF("<LOC opbrief_0001>Unknown map: %s", opMap), "<LOC _Ok>")
            mapErrorDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
        end
    end
    
    local briefMovie = Movie(parent)
    briefMovie.Depth:Set(parent.Depth)
    briefMovie.Height:Set(parent.Height)
    briefMovie.Width:Set(function()
        local ratio = parent.Height() / 1024
        return 1824 * ratio
    end)
    LayoutHelpers.AtCenterIn(briefMovie, parent)
    briefMovie:Set('/movies/'..briefingData.opMovies.briefing.movies[1],
                   Sound(briefingData.opMovies.briefing.bgsound[1]),
                   Sound(briefingData.opMovies.briefing.voice[1]))
    briefMovie:DisableHitTest()
    
    local movieBG = Bitmap(parent, UIUtil.UIFile('/scx_menu/campaign-select/bg.dds'))
    movieBG.Height:Set(parent.Height)
    movieBG.Width:Set(function()
        local ratio = parent.Height() / 1024
        return 1824 * ratio
    end)
    LayoutHelpers.AtCenterIn(movieBG, parent)
    movieBG.Depth:Set(function() return briefMovie.Depth() - 1 end)
    
    local briefBG = Bitmap(briefingGroup, UIUtil.UIFile('/scx_menu/operation-briefing/text-panel_bmp.dds'))
    
    local briefGlow = Bitmap(briefBG, UIUtil.UIFile('/scx_menu/operation-briefing/emiter-bar_bmp.dds'))
    briefGlow.Bottom:Set(function() return backgrounds.bottom.Top() + 5 end)
    LayoutHelpers.AtHorizontalCenterIn(briefGlow, backgrounds.bottom)
    briefGlow.Depth:Set(function() return briefingGroup.Depth() + 1 end)
    
    briefBG.Depth:Set(function() return briefGlow.Depth() + 1 end)
    briefBG.Bottom:Set(function() return briefGlow.Top() + 50 end)
    LayoutHelpers.AtHorizontalCenterIn(briefBG, briefGlow)
    
    local title = UIUtil.CreateText(briefingGroup, LOC(briefingData.long_name), 24)
    LayoutHelpers.AtTopIn(title, backgrounds.top, 10)
    LayoutHelpers.AtHorizontalCenterIn(title, backgrounds.top)
    
    local briefText = ItemList(briefBG)
    briefText:SetFont(UIUtil.bodyFont, 14)
    briefText:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  "00000000")
    briefText:ShowMouseoverItem(false)
    briefText.Width:Set(function() return briefBG.Width() - 60 end)
    briefText.Height:Set(function() return briefBG.Height() - 30 end)
    LayoutHelpers.AtLeftTopIn(briefText, briefBG, 15, 15)
    
    UIUtil.CreateVertScrollbarFor(briefText)
    
    local onStr = "<LOC op_briefing_0000>Hide Log"
    local offStr = "<LOC op_briefing_0001>Show Log"
    
    local subtitleChk = Checkbox(briefingGroup,
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_off.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_on.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_off_over.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_on_over.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_off.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/subtitle_btn_on.dds'),
        'UI_Tab_Click_01', 'UI_Tab_Rollover_01')
    LayoutHelpers.AtLeftTopIn(subtitleChk, backgrounds.bottom, 276, 16)
        
    subtitleChk.label = UIUtil.CreateText(subtitleChk, LOC(onStr), 14, UIUtil.bodyFont)
    subtitleChk.label:DisableHitTest()
    LayoutHelpers.AtCenterIn(subtitleChk.label, subtitleChk)
    
    subtitleChk.OnCheck = function(self, checked)
        if checked then
            self.label:SetText(LOC(onStr))
            briefBG:Show()
        else
            self.label:SetText(LOC(offStr))
            briefBG:Hide()
        end
        Prefs.SetToCurrentProfile('briefing_log', checked)
    end
    
    local showLog = Prefs.GetFromCurrentProfile('briefing_log')
    if showLog == nil then
        showLog = true
    end
    
    subtitleChk:SetCheck(showLog)
    
    local playpauseBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-pause', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    LayoutHelpers.AtLeftTopIn(playpauseBtn, backgrounds.bottom, 345, 56)
    Tooltip.AddButtonTooltip(playpauseBtn, 'options_Pause')
    
    local restartMovBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-back', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    LayoutHelpers.LeftOf(restartMovBtn, playpauseBtn)
    Tooltip.AddButtonTooltip(restartMovBtn, 'campaignbriefing_restart')
    
    local skipMovBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-end', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    LayoutHelpers.RightOf(skipMovBtn, playpauseBtn)
    Tooltip.AddButtonTooltip(skipMovBtn, 'campaignbriefing_skip')
    
    briefText.StreamInLines = function(self, startingline)
        self:SetNeedsFrameUpdate(true)
        self:DeleteAllItems()
        for i = 1, startingline-1 do
            self:AddItem(currentBriefingText[i])
        end
        local currentLine = startingline
        local currentChar = 0
        self.OnFrame = function(self, delta)
            if currentChar == 0 then
                self:AddItem('')
                self:ScrollToBottom()
            else
                self:ModifyItem(currentLine-1, string.sub(currentBriefingText[currentLine], 1, currentChar))
            end
            currentChar = currentChar + 1
            if currentChar > string.len(currentBriefingText[currentLine]) then
                if currentBriefingText[currentLine + 1] then
                    currentLine = currentLine + 1
                    currentChar = 0
                else
                    self:SetNeedsFrameUpdate(false)
                end
            end
        end
    end
    
    local statusBar = StatusBar(parent, 0, 100, false, false, 
        UIUtil.UIFile('/scx_menu/operation-briefing/status-bar-back_bmp.dds'), 
        UIUtil.UIFile('/scx_menu/operation-briefing/status-bar_bmp.dds'), false)
    statusBar.Left:Set(function() return backgrounds.bottom.Left() + 260 end)
    statusBar.Right:Set(function() return statusBar.Left() + 200 end)
    statusBar.Bottom:Set(function() return backgrounds.bottom.Bottom() - 37 end)
    statusBar.OnFrame = function(self, delta)
        fmv_time = fmv_time + delta
        local perc = MATH_Lerp(fmv_time, 0, briefMovie:GetLength(), 0, 100)
        self:SetValue(perc)
    end
    
    statusBar.border = {}
    
    statusBar.border.t = Bitmap(statusBar)
    statusBar.border.t:SetSolidColor('aabadbdb')
    statusBar.border.t.Bottom:Set(statusBar.Top)
    statusBar.border.t.Left:Set(statusBar.Left)
    statusBar.border.t.Right:Set(statusBar.Right)
    statusBar.border.t.Height:Set(1)
    
    statusBar.border.b = Bitmap(statusBar)
    statusBar.border.b:SetSolidColor('aabadbdb')
    statusBar.border.b.Top:Set(statusBar.Bottom)
    statusBar.border.b.Left:Set(statusBar.Left)
    statusBar.border.b.Right:Set(statusBar.Right)
    statusBar.border.b.Height:Set(1)
    
    statusBar.border.l = Bitmap(statusBar)
    statusBar.border.l:SetSolidColor('aabadbdb')
    statusBar.border.l.Top:Set(statusBar.border.t.Top)
    statusBar.border.l.Bottom:Set(statusBar.border.b.Bottom)
    statusBar.border.l.Right:Set(statusBar.border.t.Left)
    statusBar.border.l.Width:Set(1)
    
    statusBar.border.r = Bitmap(statusBar)
    statusBar.border.r:SetSolidColor('aabadbdb')
    statusBar.border.r.Top:Set(statusBar.border.t.Top)
    statusBar.border.r.Bottom:Set(statusBar.border.b.Bottom)
    statusBar.border.r.Left:Set(statusBar.border.t.Right)
    statusBar.border.r.Width:Set(1)
    
    function loopOnLoaded(self)
        playing = true
        self:Play()
    end
    
    function CreateLogThread()
        local thread = ForkThread(function()
            local nextCueTime = 0
            local nextSection = 1
            while parent do
                if fmv_playing then
                    local data = briefingData.opBriefingText
                    if fmv_time > nextCueTime and data[nextSection] then
                        local inText = LOCF("%s: %s", data[nextSection].character, data[nextSection].text)
                        local text = import('/lua/maui/text.lua').WrapText(inText, briefText.Width(),
                            function(text)
                                return briefText:GetStringAdvance(text)
                            end)
                        local beginningLine = table.getsize(currentBriefingText) + 1
                        for i, line in text do
                            table.insert(currentBriefingText, line)
                        end
                        table.insert(currentBriefingText, '')
                        briefText:StreamInLines(beginningLine)
                        nextSection = nextSection + 1
                        nextCueTime = nextCueTime + (string.len(inText) * .06)
                    end
                end
                WaitSeconds(.1)
            end
        end)
        return thread
    end
    
    function briefOnLoaded(self)
        playing = true
        fmv_time = 0
        statusBar:SetNeedsFrameUpdate(true)
        self:Play()
        fmv_playing = true
        if streamThread then
            KillThread(streamThread)
        end
        briefText:SetNeedsFrameUpdate(false)
        briefText:DeleteAllItems()
        currentBriefingText = {}
        streamThread = CreateLogThread()
    end
    
    local factionData = {
        {name = '<LOC _UEF>', icon = '/dialogs/logo-btn/logo-uef', key = 'uef', color = 'ff00d7ff', tooltip = 'faction_select_uef', disabled = not CampaignManager.IsOperationSelectable('uef', operationID)},
        {name = '<LOC _Aeon>', icon = '/dialogs/logo-btn/logo-aeon', key = 'aeon', color = 'ffb5ff39', tooltip = 'faction_select_aeon', disabled = not CampaignManager.IsOperationSelectable('aeon', operationID)},
        {name = '<LOC _Cybran>', icon = '/dialogs/logo-btn/logo-cybran', key = 'cybran', color = 'ffff0000', tooltip = 'faction_select_cybran', disabled = not CampaignManager.IsOperationSelectable('cybran', operationID)}
    }
    local itemArray = {
        {name = '<LOC opbrief_0004>Easy', key = 1},
        {name = '<LOC opbrief_0005>Normal', key = 2},
        {name = '<LOC opbrief_0006>Hard', key = 3}}
    
    local disablefaction = false
    local defaultFaction = Prefs.GetFromCurrentProfile('last_faction') or 'uef'
    if operationID == 'X1CA_001' then
        disablefaction = true
        defaultFaction = 'uef'
    elseif not defaultFaction or not CampaignManager.IsOperationSelectable(defaultFaction, operationID) then
        if CampaignManager.IsOperationSelectable('uef', operationID) then
            defaultFaction = 'uef'
        elseif CampaignManager.IsOperationSelectable('aeon', operationID) then
            defaultFaction = 'aeon'
        elseif CampaignManager.IsOperationSelectable('cybran', operationID) then
            defaultFaction = 'cybran'
        end
    end
    local difficultyOption = CreateOptionGroup(briefingGroup, "<LOC opbrief_0007>Difficulty:", itemArray, Prefs.GetFromCurrentProfile("campaign.difficulty") or 2)
    local factionOption = CreateOptionGroup(briefingGroup, "<LOC opbrief_0008>Faction:", factionData, defaultFaction, disablefaction)
    
    difficulty = Prefs.GetFromCurrentProfile("campaign.difficulty") or 2
    faction = defaultFaction
    
    difficultyOption.button.OnPopupChosen = OnDifficultyChosen
    factionOption.button.OnPopupChosen = OnFactionChosen
    
    LayoutHelpers.AtLeftTopIn(difficultyOption, backgrounds.bottom, 535, 16)
    LayoutHelpers.AtLeftTopIn(factionOption, backgrounds.bottom, 535, 50)
        
    playpauseBtn.OnClick = function(self)
        if fmv_playing then
            Tooltip.SetTooltipText(self, LOC('<LOC tooltipui0098>'))
            Tooltip.AddButtonTooltip(self, 'options_Play')
            self:SetTexture(UIUtil.UIFile('/dialogs/movie-control/nav-play_btn_up.dds'))
            self:SetNewTextures(UIUtil.UIFile('/dialogs/movie-control/nav-play_btn_up.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-play_btn_down.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-play_btn_over.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-play_btn_dis.dds'))
            briefMovie:Stop()
            PauseSound('Op_Briefing', true)
            PauseVoice('VO', true)
            statusBar:SetNeedsFrameUpdate(false)
        else
            Tooltip.SetTooltipText(self, LOC('<LOC tooltipui0066>'))
            Tooltip.AddButtonTooltip(self, 'options_Pause')
            self:SetTexture(UIUtil.UIFile('/dialogs/movie-control/nav-pause_btn_up.dds'))
            self:SetNewTextures(UIUtil.UIFile('/dialogs/movie-control/nav-pause_btn_up.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-pause_btn_down.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-pause_btn_over.dds'),
                UIUtil.UIFile('/dialogs/movie-control/nav-pause_btn_dis.dds'))
            briefMovie:Play()
            PauseSound('Op_Briefing', false)
            PauseVoice('VO', false)
            statusBar:SetNeedsFrameUpdate(true)
        end
        fmv_playing = not fmv_playing
    end
    
    restartMovBtn.OnClick = function(self)
        if playing then
            playing = false
            briefMovie:Set('/movies/'..briefingData.opMovies.briefing.movies[1],
                           Sound(briefingData.opMovies.briefing.bgsound[1]),
                           Sound(briefingData.opMovies.briefing.voice[1]))
            briefMovie:Loop(false)
            briefMovie.OnLoaded = briefOnLoaded
        end
    end
    
    skipMovBtn.OnClick = function(self)
        fmv_playing = false
        briefMovie:Loop(true)
        briefMovie:Set('/movies/menu_background.sfd')
        briefMovie.OnLoaded = loopOnLoaded
        statusBar:SetValue(100)
        statusBar:SetNeedsFrameUpdate(false)
        briefText:DeleteAllItems()
        briefText:SetNeedsFrameUpdate(false)
        local data = briefingData.opBriefingText
        for i, v in data do
            local inText = LOCF("%s: %s", v.character, v.text)
            local text = import('/lua/maui/text.lua').WrapText(inText, briefText.Width(),
                function(text)
                    return briefText:GetStringAdvance(text)
                end)
            for _, line in text do
                briefText:AddItem(line)
            end
            briefText:AddItem('')
            briefText:ScrollToBottom()
        end
    end
    
    local textThread = false
    
    briefMovie.OnLoaded = briefOnLoaded
    
    briefMovie.OnFinished = function(self)
        self:Loop(true)
        self:Set('/movies/menu_background.sfd')
        self.OnLoaded = loopOnLoaded
    end
    
    parent.OnDestroy = function(self)
        if textThread then KillThread(textThread) end
        StopSound(ambientSounds)
    end
end

function OnFactionChosen(self, data)
    self.popup:Destroy()
    self.popup = nil
    self.label:SetText(LOC(data.name))
    faction = data.key
    Prefs.SetToCurrentProfile('last_faction', data.key)
end

function OnDifficultyChosen(self, data)
    self.popup:Destroy()
    self.popup = nil
    self.label:SetText(LOC(data.name))
    difficulty = data.key
    Prefs.SetToCurrentProfile('campaign.difficulty', data.key)
end

function CreateOptionGroup(parent, label, optionData, default, disabled)
    local group = Group(parent)
    group.label = UIUtil.CreateText(group, LOC(label), 10, UIUtil.bodyFont)
    
    group.button = Button(group, UIUtil.UIFile('/scx_menu/operation-briefing/popup_btn_up.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/popup_btn_down.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/popup_btn_over.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/popup_btn_dis.dds'))
        
    if disabled then
        group.button:Disable()
        group.label:SetColor('ff888888')
    else
        group.button.label = UIUtil.CreateText(group.button, '', 12, UIUtil.bodyFont)
        group.button.label:DisableHitTest()
        
        LayoutHelpers.AtCenterIn(group.button.label, group.button)
        
        group.button.data = optionData
        group.button.OnRolloverEvent = function(self, event)
            if event == 'enter' then
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Rollover_01'}))
            end
        end
        group.button.OnClick = function(self)
            if self.popup then
                self.popup:Destroy()
                self.popup = nil
            else
                if activePopupButton.popup then
                    activePopupButton.popup:Destroy()
                    activePopupButton.popup = nil
                end
                self.popup = CreatePopup(self, self.data)
                self.popup.Bottom:Set(function() return backgrounds.bottom.Top() - 2 end)
                self.popup.Left:Set(function() return backgrounds.bottom.Left() + 556 end)
                activePopupButton = self
            end
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_01'}))
        end
        
        for i, v in optionData do
            if v.key == default then
                group.button.label:SetText(LOC(v.name))
                break
            end
        end
    end
    
    LayoutHelpers.AtLeftIn(group.label, group)
    LayoutHelpers.AtVerticalCenterIn(group.label, group)
    
    LayoutHelpers.AtRightIn(group.button, group)
    LayoutHelpers.AtVerticalCenterIn(group.button, group)
    
    group.Height:Set(30)
    group.Width:Set(150)
    
    return group
end

function CreatePopup(parent, data)
    local bg = CreatePopupBackground(parent)
    bg.Depth:Set(function() return parent.Depth() + 20 end)
    bg:DisableHitTest(true)
    bg.items = {}
    for index, v in data do
        local i = index
        local item = Bitmap(bg)
        item.text = UIUtil.CreateText(item, LOC(v.name), 14, UIUtil.bodyFont)
        item.text:DisableHitTest()
        
        item.data = v
        item.HandleEvent = function(self, event)
            local eventHandled = false
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('77ffffff')
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Rollover_01'}))
                eventHandled = true
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
                eventHandled = true
            elseif event.Type == 'ButtonPress' then
                parent:OnPopupChosen(self.data)
                PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Tab_Click_01'}))
                eventHandled = true
            end
            return eventHandled
        end
        
        if v.icon then
            local texture = v.icon..'_btn_up.dds'
            if v.disabled then
                texture = v.icon..'_btn_dis.dds'
                item.text:SetColor('ff888888')
                item:DisableHitTest()
            end
            item.icon = Bitmap(item, UIUtil.UIFile(texture))
            item.icon:DisableHitTest()
            item.icon.Height:Set(function() return item.icon.BitmapHeight() * .5 end)
            item.icon.Width:Set(function() return item.icon.BitmapWidth() * .5 end)
            LayoutHelpers.AtLeftTopIn(item.icon, item)
            LayoutHelpers.AtLeftIn(item.text, item, 40)
            LayoutHelpers.AtVerticalCenterIn(item.text, item)
            item.Height:Set(item.icon.Height)
        else
            LayoutHelpers.AtCenterIn(item.text, item)
            item.Height:Set(20)
        end
        item.Width:Set(100)
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(item, bg)
        else
            LayoutHelpers.Below(item, bg.items[i-1])
        end
        table.insert(bg.items, item)
    end
    bg.Height:Set(function()
        local height = 0
        for i, v in bg.items do
            height = height + v.Height()
        end
        return height
    end)
    bg.Width:Set(100)
    return bg
end

function CreatePopupBackground(parent)
    local bg = Bitmap(parent, UIUtil.UIFile('/game/chat_brd/drop-box_brd_m.dds'))
    bg.tl = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
    bg.tm = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
    bg.tr = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
    bg.l = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
    bg.r = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
    bg.bl = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
    bg.bm = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
    bg.br = Bitmap(bg, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
    
    bg.tl.Bottom:Set(bg.Top)
    bg.tl.Right:Set(bg.Left)
    
    bg.tr.Bottom:Set(bg.Top)
    bg.tr.Left:Set(bg.Right)
    
    bg.bl.Top:Set(bg.Bottom)
    bg.bl.Right:Set(bg.Left)
    
    bg.br.Top:Set(bg.Bottom)
    bg.br.Left:Set(bg.Right)
    
    bg.tm.Left:Set(bg.Left)
    bg.tm.Right:Set(bg.Right)
    bg.tm.Bottom:Set(bg.Top)
    
    bg.bm.Left:Set(bg.Left)
    bg.bm.Right:Set(bg.Right)
    bg.bm.Top:Set(bg.Bottom)
    
    bg.l.Top:Set(bg.Top)
    bg.l.Bottom:Set(bg.Bottom)
    bg.l.Right:Set(bg.Left)
    
    bg.r.Top:Set(bg.Top)
    bg.r.Bottom:Set(bg.Bottom)
    bg.r.Left:Set(bg.Right)
    
    return bg
end
