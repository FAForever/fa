--*****************************************************************************
--* File: lua/modules/ui/dialogs/score.lua
--* Author: Chris Blackwell
--* Summary: Post game score dialog
--*
--* Copyright © :005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EffectHelpers = import("/lua/maui/effecthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Movie = import("/lua/maui/movie.lua").Movie
local WrapText = import("/lua/maui/text.lua").WrapText
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local RadioGroup = import("/lua/maui/mauiutil.lua").RadioGroup
local Tooltip = import("/lua/ui/game/tooltip.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Prefs = import("/lua/user/prefs.lua")
local hotstats = import("/lua/ui/dialogs/hotstats.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

dialog = false
local currentPage = nil
local curGrid = nil
local curInfo = nil
local elapsedTime = nil
local curType = nil
local curSortCol = nil
local curSortDescending = true
local savedGameTime = nil
local curScore = nil

local campaignScore = ''

scoreScreenActive = false

-- '<LOC SCORE_0058>Debrief'
-- '<LOC SCORE_0059>Combat Report'

local tabs = {
    {
        title = "<LOC SCORE_0030>Campaign",
        button = "campaign",
        scoreKey = 'campaign',
        -- TODO: This is here to get loc tags in to database, will make more sense in line when campaign score is done
        text = {
            "<LOC SCORE_0031>Restart",
            "<LOC SCORE_0032>Load",
            "<LOC SCORE_0033>Continue",
            "<LOC SCORE_0034>Replay",
            "<LOC SCORE_0035>Load Replay",
            "<LOC SCORE_0045>Sort By Team",
        }
    },
    {
        title = "<LOC SCORE_0000>General",
        button = "general",
        scoreKey = 'general',
        columns = {
          {title = "<LOC SCORE_0001>Score", scoreKey = 'score',},
          {title = "<LOC SCORE_0002>Kills", scoreKey = 'kills',},
          {title = "<LOC SCORE_0003>Built", scoreKey = 'built',},
          {title = "<LOC SCORE_0004>Losses", scoreKey = 'lost',},
          {title = "<LOC SCORE_0005>Mass", scoreKey = 'mass',},
          {title = "<LOC SCORE_0006>Energy", scoreKey = 'energy',},
        },
        types = {
            {title = "<LOC SCORE_0007>Count", scoreKey = 'count',},
            {title = "<LOC SCORE_0008>Mass Value", scoreKey = 'mass',},
            {title = "<LOC SCORE_0009>Energy Value", scoreKey = 'energy',},
        },
        grid = true,
    },
    {
        title = "<LOC SCORE_0010>Units",
        button = "units",
        scoreKey = 'units',
        columns = {
            {title = "<LOC SCORE_0011>CDR", scoreKey = 'cdr',},
            {title = "<LOC SCORE_0012>Land", scoreKey = 'land',},
            {title = "<LOC SCORE_0013>Naval", scoreKey = 'naval',},
            {title = "<LOC SCORE_0014>Air", scoreKey = 'air',},
            {title = "<LOC SCORE_0015>Structures", scoreKey = 'structures',},
            {title = "<LOC SCORE_0016>Experimental", scoreKey = 'experimental',},
        },
        types = {
            {title = "<LOC SCORE_0017>Kills", scoreKey = 'kills',},
            {title = "<LOC SCORE_0003>Built", scoreKey = 'built',},
            {title = "<LOC SCORE_0019>Losses", scoreKey = 'lost',},
        },
        grid = true,
    },
    {
        title = "<LOC SCORE_0020>Resources",
        button = "resources",
        scoreKey = 'resources',
        columns = {
            {title = "<LOC SCORE_0021>Mass Collected", scoreKey = 'massin',},
            {title = "<LOC SCORE_0022>Mass Spent", scoreKey = 'massout',},
            {title = "<LOC SCORE_0023>Mass Wasted", scoreKey = 'massover',},
            {title = "<LOC SCORE_0024>Energy Collected", scoreKey = 'energyin',},
            {title = "<LOC SCORE_0025>Energy Spent", scoreKey = 'energyout',},
            {title = "<LOC SCORE_0026>Energy Wasted", scoreKey = 'energyover',},
        },
        types = {
            {title = "<LOC SCORE_0027>Total", scoreKey = 'total',},
            {title = "<LOC SCORE_0028>Rate", scoreKey = 'rate',},
        },
        grid = true,
    },
}

local prefix = {
    Cybran = {texture = '/icons/comm_cybran.dds', cue = 'UI_Comm_CYB'},
    Aeon = {texture = '/icons/comm_aeon.dds', cue = 'UI_Comm_AEON'},
    UEF = {texture = '/icons/comm_uef.dds', cue = 'UI_Comm_UEF'},
    Seraphim = {texture = '/icons/comm_seraphim.dds', cue = 'UI_Comm_SER'},
    NONE = {texture = '/icons/comm_allied.dds', cue = 'UI_Comm_UEF'}
}

-- determine which data to show based on current page, data type and column
local function UpdateDisplay()
    -- show elapsed time
    elapsedTime:SetText(GetGameTime())

    -- check for campaign, handled differently
    if currentPage.tabData.button == "campaign" then
        return
    end

    if not curInfo or not curInfo.scoreData then
        return
    end

    -- set the current score page key
    local curScoreKey = currentPage.tabData.scoreKey

    -- set up a small table to sort by the current sort value
    local sortOrder = {}
    for index, info in ipairs(curInfo) do
        sortOrder[index] = {}
        sortOrder[index].infoIndex = index

        local PlayerData = curInfo.scoreData.current[index]
        PlayerData.general.mass = PlayerData.resources.massin.total
        PlayerData.general.energy = PlayerData.resources.energyin.total
        PlayerData.resources.massover = {}
        PlayerData.resources.energyover = {}
        PlayerData.resources.massover.total = PlayerData.resources.massout.excess
        PlayerData.resources.energyover.total = PlayerData.resources.energyout.excess
        PlayerData.resources.massover.rate = math.max(0, PlayerData.resources.massin.rate -
            PlayerData.resources.massout.rate + PlayerData.resources.massin.reclaimRate +
            PlayerData.resources.storage.storedMass - PlayerData.resources.storage.maxMass)
        PlayerData.resources.energyover.rate = math.max(0, PlayerData.resources.energyin.rate -
            PlayerData.resources.energyout.rate + PlayerData.resources.energyin.reclaimRate +
            PlayerData.resources.storage.storedEnergy - PlayerData.resources.storage.maxEnergy)

        sortOrder[index].sortKey = PlayerData[curScoreKey][curSortCol][curType]
                                or PlayerData[curScoreKey][curSortCol]
    end

    table.sort(sortOrder, function(first, second)
        if not first.sortKey or not second.sortKey then
            return false
        elseif type(first.sortKey) ~= "number" or type(second.sortKey) ~= "number" then
            return false
        end
        if curSortDescending then
            return (first.sortKey > second.sortKey)
        else
            return (first.sortKey < second.sortKey)
        end
    end)

    if curGrid then
        for index, gridRow in ipairs(curGrid) do
            local curPlayerIndex = sortOrder[index].infoIndex
            local info = curInfo[curPlayerIndex]
            gridRow.color:SetSolidColor(info.color)
            gridRow.factionIcon:SetTexture(UIUtil.SkinnableFile(UIUtil.GetFactionIcon(info.faction)))
            gridRow.playerName:SetText(info.name)
            --gridRow.teamName:SetText(info.teamName)

            for curCol, colData in currentPage.tabData.columns do
                -- check if data sub-type otherwise use parent value
                curGrid[index].cols[curCol]:SetText(tostring(math.floor(
                    curInfo.scoreData.current[curPlayerIndex][curScoreKey][colData.scoreKey][curType] or
                    curInfo.scoreData.current[curPlayerIndex][curScoreKey][colData.scoreKey] or 0)))
            end
        end
    end
end

local function SortByColumn(colKey)
    if curSortCol == colKey then
        curSortDescending = not curSortDescending
    else
        curSortCol = colKey
        curSortDescending = true
    end

    UpdateDisplay()
end

local function SetDataType(dataType)
    curType = dataType

    -- TODO coordinate buttons?
    UpdateDisplay()
end

function UpdateData()

    -- clear curInfo
    curInfo = {}

    -- first get army info and place it in the
    local armiesTable = GetArmiesTable().armiesTable

    local index = 1
    -- popluate data in to cur info
    for i, armyInfo in armiesTable do
        if not armyInfo.civilian and armyInfo.showScore then
            -- set basic info from armies table
            curInfo[index] = {}
            curInfo[index].name = hotstats.scoreData.current[i].name
            curInfo[index].faction = armyInfo.faction
            curInfo[index].color = armyInfo.color
            --curInfo[index].teamName = index --TODO we need to get team data in here
            index = index + 1
        end
    end

    -- set score data
    curInfo.scoreData = hotstats.scoreData
end

function CreateDialog(victory, showCampaign, operationVictoryTable, midGame)
    if midGame then
        ExitGame()
        return
    end
    scoreScreenActive = true
    SessionEndGame()
    DisableWorldSounds()
    StopAllSounds()
    ForkThread(function()
        while not(hotstats.scoreData.interval and hotstats.scoreData.current and hotstats.scoreData.history) do
            WaitSeconds(0.5)
        end
        CreateDialog2(victory, showCampaign, operationVictoryTable, midGame)
    end)
end

function CreateDialog2(victory, showCampaign, operationVictoryTable, midGame)
    UpdateData()

    campaignScore = tostring(curInfo.scoreData.current[1].general.score)

    if showCampaign then
        Prefs.SetToCurrentProfile('last_faction', operationVictoryTable.faction)
        ConExecute("ren_Oblivion true")
        local successKey = 'failure'
        if operationVictoryTable.success then
            successKey = 'success'
        end
        if operationVictoryTable.opData.opMovies.postOpMovies[successKey] then
            GetCursor():Hide()
            local subtitleThread = nil
            function DisplaySubtitles(textControl,captions)
                if subtitleThread then
                    KillThread(subtitleThread)
                end
                subtitleThread = ForkThread(
                    function()
                        -- Display subtitles
                        local lastOff = 0
                        for k,v in captions do
                            WaitSeconds(v.offset - lastOff)
                            textControl:DeleteAllItems()
                            locText = LOC(v.text)
                            local lines = WrapText(locText, textControl.Width(), function(text) return textControl:GetStringAdvance(text) end)
                            for i,line in lines do
                                textControl:AddItem(line)
                            end
                            textControl:ScrollToBottom()
                            lastOff = v.offset
                        end
                        subtitleThread = false
                    end
                )
            end

            -- Pick a faction movie table of the default one
            local movies = {}
            if operationVictoryTable.opData.opMovies.postOpMovies.factionDependant then
                movies = operationVictoryTable.opData.opMovies.postOpMovies[successKey][operationVictoryTable.faction]
            else
                movies = operationVictoryTable.opData.opMovies.postOpMovies[successKey]
            end

            local parent = UIUtil.CreateScreenGroup(GetFrame(0), "Campaign Movie ScreenGroup")
            parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
            AddInputCapture(parent)

            local background = Bitmap(parent)
            LayoutHelpers.FillParent(background, parent)
            background:SetSolidColor('black')

            local textArea = ItemList(background)
            textArea:SetFont(UIUtil.bodyFont, 13)

            textArea:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  UIUtil.highlightColor)

            local movie = Movie(background)
            LayoutHelpers.FillParentPreserveAspectRatio(movie, parent)
            movie.curMovie = 1

            local height = 6 * textArea:GetRowHeight()
            textArea.Height:Set(height)
            textArea.Top:Set(function() return movie.Bottom() end)
            textArea.Width:Set(function() return movie.Width() / 2 end)
            LayoutHelpers.AtHorizontalCenterIn(textArea,parent)
            textArea.Depth:Set(function() return movie.Depth() + 5 end)

            movie:DisableHitTest()    -- get clicks to parent group

            local subtitleSource = import("/lua/ui/game/vo_fmv.lua")
            movie.OnLoaded = function(self)
                movie:Play()
                GetCursor():Hide()
                if Prefs.GetOption('subtitles') and movies[movie.curMovie].subtitles then
                    -- default is only for original campaign
                    if movies[movie.curMovie].subtitles == 'default' then
                        DisplaySubtitles(textArea, subtitleSource[movies[movie.curMovie].voice].captions)
                    else
                        DisplaySubtitles(textArea, movies[movie.curMovie].subtitles)
                    end
                end
            end

            local function LeaveMovie()
                -- Plays all movies from the <movies> table, then creates score screen
                if movies[movie.curMovie + 1] then
                    movie.curMovie = movie.curMovie + 1
                    -- Play sfx and voice sounds only if available
                    if movies[movie.curMovie].sfx and movies[movie.curMovie].voice then
                        movie:Set(movies[movie.curMovie].vid,
                                  Sound({Cue = movies[movie.curMovie].sfx, Bank = movies[movie.curMovie].sfxBank}),
                                  Sound({Cue = movies[movie.curMovie].voice, Bank = movies[movie.curMovie].voiceBank}))
                    elseif movies[movie.curMovie].sfx then
                        movie:Set(movies[movie.curMovie].vid,
                                  Sound({Cue = movies[movie.curMovie].sfx, Bank = movies[movie.curMovie].sfxBank}))
                    elseif movies[movie.curMovie].voice then
                        movie:Set(movies[movie.curMovie].vid,
                                  Sound({Cue = movies[movie.curMovie].voice, Bank = movies[movie.curMovie].voiceBank}))
                    else
                        movie:Set(movies[movie.curMovie].vid)
                    end
                else
                    GetCursor():Show()
                    if subtitleThread then
                        KillThread(subtitleThread)
                        subtitleThread = false
                    end
                    RemoveInputCapture(parent)
                    movie:Stop()
                    parent:Destroy()
                    CreateSkirmishScreen(victory, showCampaign, operationVictoryTable)
                end
            end

            parent.HandleEvent = function(self, event)
                -- cancel movie playback on mouse click or key hit
                if event.Type == "ButtonPress" or event.Type == "KeyDown" then
                    if event.KeyCode then
                        if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == UIUtil.VK_SPACE or event.KeyCode == 1  or event.KeyCode == 3 then
                        else
                            return true
                        end
                    end
                    LeaveMovie()
                    return true
                end
            end

            movie.OnFinished = function(self)
                LeaveMovie()
            end

            -- Playe the first movie
            movie.curMovie = 0
            LeaveMovie()
        else
            CreateSkirmishScreen(victory, showCampaign, operationVictoryTable)
        end
    else
        CreateSkirmishScreen(victory, showCampaign, operationVictoryTable)
    end
end

function CreateSkirmishScreen(victory, showCampaign, operationVictoryTable)
    if dialog then return end

    GetCursor():Show()
    local factions = import("/lua/factions.lua").Factions
    UIUtil.SetCurrentSkin(factions[1].DefaultSkin)

    -- create the dialog
    dialog = Bitmap(GetFrame(0))
    dialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth()+1)
    dialog:SetNeedsFrameUpdate(true)
    dialog:SetSolidColor('FF000000')
    dialog.OnFrame = function(self, delta)
        self:SetNeedsFrameUpdate(false)
    end

    -- No way to set ambient sound volumes, so let's at least turn it off if music is off.
    if (GetVolume("Music") > 0) then
        local ambientSounds = PlaySound(Sound({Cue = "AMB_SER_OP_Briefing", Bank = "AmbientTest",}))
        dialog.OnDestroy = function(self)
            StopSound(ambientSounds)
        end
    end

    movieBG = Movie(dialog, '/movies/menu_background.sfd')

    local bg = Bitmap(movieBG, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(bg, GetFrame(0))

    bg.brackets = UIUtil.CreateDialogBrackets(bg, 40, 30, 40, 30)

    LayoutHelpers.FillParent(dialog, GetFrame(0))

    movieBG.Height:Set(GetFrame(0).Height)
    movieBG.Width:Set(function()
        local ratio = GetFrame(0).Height() / 1024
        return 1824 * ratio
    end)
    movieBG.OnLoaded = function(self)
        self:Loop(true)
        self:Play()
    end
    LayoutHelpers.AtCenterIn(movieBG, GetFrame(0))
    movieBG:DisableHitTest()

    bg.title = UIUtil.CreateText(bg, "", 20, UIUtil.titleFont)
    LayoutHelpers.AtHorizontalCenterIn(bg.title, bg)
    LayoutHelpers.AtTopIn(bg.title, bg, 28)

    -- set controls that are global to the dialog
    if HasCommandLineArg("/gpgnet") then
        bg.continueBtn = UIUtil.CreateButtonStd(bg, '/scx_menu/large-no-bracket-btn/large', "<LOC _Exit_to_Windows>Exit to FAF", 22, 2, 0, "UI_Menu_MouseDown", "UI_Opt_Affirm_Over")
        Tooltip.AddButtonTooltip(bg.continueBtn, 'esc_exit')
    else
        bg.continueBtn = UIUtil.CreateButtonStd(bg, '/scx_menu/large-no-bracket-btn/large', "<LOC _Continue>", 22, 2, 0, "UI_Menu_MouseDown", "UI_Opt_Affirm_Over")
        Tooltip.AddButtonTooltip(bg.continueBtn, 'PostScore_Quit')
    end

    LayoutHelpers.AtRightIn(bg.continueBtn, bg, -10)
    LayoutHelpers.AtBottomIn(bg.continueBtn, bg, 20)
    bg.continueBtn:UseAlphaHitTest(false)

    bg.continueBtn.glow = Bitmap(bg.continueBtn, UIUtil.UIFile('/scx_menu/large-no-bracket-btn/large_btn_glow.dds'))
    LayoutHelpers.AtCenterIn(bg.continueBtn.glow, bg.continueBtn)
    bg.continueBtn.glow:SetAlpha(0)
    bg.continueBtn.glow:DisableHitTest()

    bg.continueBtn.pulse = Bitmap(bg.continueBtn, UIUtil.UIFile('/scx_menu/large-no-bracket-btn/large_btn_glow.dds'))
    LayoutHelpers.AtCenterIn(bg.continueBtn.pulse, bg.continueBtn)
    bg.continueBtn.pulse:DisableHitTest()
    bg.continueBtn.pulse:SetAlpha(.5)

    EffectHelpers.Pulse(bg.continueBtn.pulse, 2, .5, 1)

    bg.continueBtn.OnRolloverEvent = function(self, event)
        if event == 'enter' then
            EffectHelpers.FadeIn(self.glow, .25, 0, 1)
            self.label:SetColor('black')
        elseif event == 'down' then
            self.label:SetColor('black')
        else
            EffectHelpers.FadeOut(self.glow, .25, 1, 0)
            self.label:SetColor('FFbadbdb')
        end
    end

    bg.continueBtn.OnClick = function(self, modifiers)
        hotstats.clean_view()
        ConExecute("ren_Oblivion false")
        if HasCommandLineArg("/gpgnet") then
            -- Quit to desktop
            EscapeHandler.SafeQuit()
        else
            -- Back to main menu
            ExitGame()
        end
    end

     -- Rehost button in case of failure
    -- if showCampaign and not operationVictoryTable.success then
    --     bg.rehostBtn = UIUtil.CreateButtonStd(bg, '/scx_menu/large-no-bracket-btn/large', "<LOC _Rehost_Game>Rehost Game", 22, 2, 0, "UI_Menu_MouseDown", "UI_Opt_Affirm_Over")
    --     LayoutHelpers.LeftOf(bg.rehostBtn, bg.continueBtn, -40)
    --     bg.continueBtn:UseAlphaHitTest(false)

    --     bg.rehostBtn.glow = Bitmap(bg.rehostBtn, UIUtil.UIFile('/scx_menu/large-no-bracket-btn/large_btn_glow.dds'))
    --     LayoutHelpers.AtCenterIn(bg.rehostBtn.glow, bg.rehostBtn)
    --     bg.rehostBtn.glow:SetAlpha(0)
    --     bg.rehostBtn.glow:DisableHitTest()

    --     bg.rehostBtn.pulse = Bitmap(bg.rehostBtn, UIUtil.UIFile('/scx_menu/large-no-bracket-btn/large_btn_glow.dds'))
    --     LayoutHelpers.AtCenterIn(bg.rehostBtn.pulse, bg.rehostBtn)
    --     bg.rehostBtn.pulse:DisableHitTest()
    --     bg.rehostBtn.pulse:SetAlpha(.5)

    --     EffectHelpers.Pulse(bg.rehostBtn.pulse, 2, .5, 1)

    --     bg.rehostBtn.OnRolloverEvent = function(self, event)
    --         if event == 'enter' then
    --             EffectHelpers.FadeIn(self.glow, .25, 0, 1)
    --             self.label:SetColor('black')
    --         elseif event == 'down' then
    --             self.label:SetColor('black')
    --         else
    --             EffectHelpers.FadeOut(self.glow, .25, 1, 0)
    --             self.label:SetColor('FFbadbdb')
    --         end
    --     end

    --     bg.rehostBtn.OnClick = function(self, modifiers)
    --         ConExecute("ren_Oblivion false")
    --         GpgNetSend('Rehost')
    --         EscapeHandler.SafeQuit()
    --     end
    --     Tooltip.AddButtonTooltip(bg.rehostBtn, 'esc_rehost')
    -- end

    UIUtil.MakeInputModal(dialog, function() bg.continueBtn:OnClick() end, function() bg.continueBtn:OnClick() end)

    local elapsedTimeLabel = UIUtil.CreateText(bg, "<LOC SCORE_0029>Game Time:", 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(elapsedTimeLabel, bg, 760, 75)

    elapsedTime = UIUtil.CreateText(bg, "", 16, UIUtil.bodyFont)
    LayoutHelpers.RightOf(elapsedTime, elapsedTimeLabel, 5)

    -- Create a Feedback button with a link to the specified web page
    local feedbackButtonData = {
        ladder = {
            tooltip = 'LadderScore_Feedback',
            url = 'http://voting.faforever.com/vote',
        },
        campaign = {
            tooltip = 'CampaignScore_Feedback',
            url = "http://discord.gg/ayzAVr9JUV",
        },
    }

    local feedbackType = false
    if showCampaign then
        feedbackType = 'campaign'
    elseif GetCommandLineArg('/init', 1)[1] == 'init_ladder1v1.lua' then
        feedbackType = 'ladder'
    end

    if feedbackType then
        bg.feedbackButton = UIUtil.CreateButtonStd(bg, '/scx_menu/medium-no-br-btn/medium-uef', '<LOC _Feedback>Post Feedback', 14, 2)
        LayoutHelpers.AtLeftIn(bg.feedbackButton, bg, 5)
        LayoutHelpers.AtBottomIn(bg.feedbackButton, bg, 20)
        Tooltip.AddButtonTooltip(bg.feedbackButton, feedbackButtonData[feedbackType].tooltip)
        -- Add an URL to the button, else disable it
        if feedbackButtonData[feedbackType].url then
            bg.feedbackButton.OnClick = function(self, modifiers)
                OpenURL(feedbackButtonData[feedbackType].url)
            end
        else
            bg.feedbackButton:Disable()
        end
    end

    -- when a new page is selected, create the page and deal with the tab correctly
    function SetNewPage(tabControl)
        -- kill any other page
        if currentPage then
            currentPage.tabBitmap:Destroy()
            currentPage.tabButton:Show()
            currentPage:Destroy()
        end

        -- store the tab data for this tab for easy access
        local tabData = tabControl.tabData

        -- page is a big as group to make placement easy, and destruction of the page easy
        currentPage = Group(bg, "currentScorePageGroup")
        currentPage.tabData = tabData
        LayoutHelpers.FillParent(currentPage, bg)

        -- show the "selected" state of the tab, which hides the button and shows a bitmap
        currentPage.tabButton = tabControl
        currentPage.tabButton:Hide()
        currentPage.tabBitmap = Bitmap(bg, UIUtil.UIFile('/scx_menu/tab_btn/tab_btn_selected.dds'))
        currentPage.tabBitmap.Depth:Set(function() return bg.Depth() + 100 end)
        LayoutHelpers.AtCenterIn(currentPage.tabBitmap, currentPage.tabButton)
        local tabLabel = UIUtil.CreateText(currentPage.tabBitmap, tabData.title, 16, UIUtil.titleFont)
        LayoutHelpers.AtCenterIn(tabLabel, currentPage.tabBitmap)

        if bg.voHandle then
            StopSound(bg.voHandle)
        end

        -- if there's a grid to be shown, set it up
        -- Note: currently, only campaign score page won't have a grid
        if tabData.grid then
            -- create the grid group/bg
            local gridGroup = Group(currentPage, "scoreGridGroup")
            -- no layout info for these sub pages, so position manually
            LayoutHelpers.AtLeftTopIn(gridGroup, currentPage, 43, 102)
            LayoutHelpers.SetDimensions(gridGroup, 743, 257)

            local gridBG = Bitmap(gridGroup, UIUtil.SkinnableFile('/scx_menu/score-victory-defeat/totals-back_bmp.dds'))
            LayoutHelpers.AtLeftTopIn(gridBG, bg, 34, 114)

            -- set up labels (no layout info yet, so store x values in a table)
            -- note the numbers are colmun num, for easy access
            local labelXPos = {
                icon = 6,
                player = 38,
                team = 259,
                [1] = 312,
                [2] = 416,
                [3] = 520,
                [4] = 624,
                [5] = 728,
                [6] = 832,
            }

            local playerText = MultiLineText(gridBG, UIUtil.bodyFont, 16, UIUtil.fontColor)
            LayoutHelpers.SetDimensions(playerText, 250, 35)
            LayoutHelpers.AtLeftTopIn(playerText, gridBG, labelXPos.icon + 5, 12)   -- note this is at icon as there is none in the label
            playerText:SetText(LOC("<LOC _Player>"))

            -- local teamText = MultiLineText(gridBG, UIUtil.titleFont, 16, UIUtil.fontColor)
            -- teamText.Width:Set(80)
            -- teamText.Height:Set(35)
            -- LayoutHelpers.AtLeftTopIn(teamText, gridBG, labelXPos.team, 12)
            -- teamText:SetText(LOC("<LOC _Team>"))

            local sortButtons = {}
            for index, colName in tabData.columns do
                local Index = index
                sortButtons[index] = {}
                sortButtons[index].checkbox = Checkbox(gridBG
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-d_btn_up.dds')
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-s_btn_up.dds')
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-d_btn_over.dds')
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-s_btn_over.dds')
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-d_btn_dis.dds')
                    , UIUtil.SkinnableFile('/scx_menu/toggle-lg_btn/toggle-s_btn_dis.dds')
                    , "UI_Tab_Click_02", "UI_Tab_Rollover_02")
                LayoutHelpers.AtLeftTopIn(sortButtons[index].checkbox, gridBG, labelXPos[index] - 30, -4)
                sortButtons[index].checkbox.toolTip = colName.scoreKey

                sortButtons[index].label = {}
                sortButtons[index].label[1] = UIUtil.CreateText(sortButtons[index].checkbox, '', 11, UIUtil.bodyFont)
                sortButtons[index].label[1]:DisableHitTest()

                local wrappedText = import("/lua/maui/text.lua").WrapText(LOC(colName.title),
                    80,
                    function(text)
                        return sortButtons[Index].label[1]:GetStringAdvance(text)
                    end)

                if table.getn(wrappedText) > 1 then
                    sortButtons[index].label[1]:SetText(wrappedText[1])
                    LayoutHelpers.AtTopIn(sortButtons[index].label[1], sortButtons[index].checkbox, 12)
                    LayoutHelpers.AtHorizontalCenterIn(sortButtons[index].label[1], sortButtons[index].checkbox)
                    for i = 2, table.getn(wrappedText) do
                        local lineIndex = i
                        sortButtons[index].label[lineIndex] = UIUtil.CreateText(sortButtons[index].checkbox, wrappedText[lineIndex], 11, UIUtil.bodyFont)
                        sortButtons[index].label[lineIndex]:DisableHitTest()
                        LayoutHelpers.Below(sortButtons[index].label[lineIndex], sortButtons[index].label[lineIndex-1], -2)
                        LayoutHelpers.AtHorizontalCenterIn(sortButtons[index].label[lineIndex], sortButtons[index].checkbox)
                    end
                else
                    sortButtons[index].label[1]:SetText(wrappedText[1])
                    LayoutHelpers.AtCenterIn(sortButtons[index].label[1], sortButtons[index].checkbox)
                end

                sortButtons[index].checkbox._sortCol = colName.scoreKey
            end

            local sortGroup = RadioGroup(sortButtons)
            sortGroup.OnClick = function(self, index, item)
                SortByColumn(item.checkbox._sortCol)
                return true
            end
            sortGroup:SetCheckboxEventHandler(function(self, event)
                if event.Type == 'MouseEnter' then
                    Tooltip.CreateMouseoverDisplay(self, "PostScore_"..self.toolTip, nil, true)
                elseif event.Type == 'MouseExit' then
                    Tooltip.DestroyMouseoverDisplay()
                end
                return true
            end)

            --default sort col
            -- TODO should this be set elsewhere?
            curSortCol = tabData.columns[1].scoreKey

            -- clear out existing grid so we can have fresh data
            curGrid = {}

            -- set up a row for each player (well each army at least)
            -- layouts may have to change based on team?
            local armiesInfo = GetArmiesTable()

            local prev = false
            local index = 1
            for i, armyInfo in armiesInfo.armiesTable do
                if not armyInfo.civilian and armyInfo.showScore then
                    local armyBg = Bitmap(gridGroup, UIUtil.SkinnableFile('/scx_menu/score-victory-defeat/player-back_bmp.dds'))
                    if prev then
                        LayoutHelpers.Below(armyBg, prev, -5)
                    else
                        LayoutHelpers.AtLeftTopIn(armyBg, gridGroup, -10, 50)
                    end
                    prev = armyBg

                    curGrid[index] = {}

                    curGrid[index].color = Bitmap(armyBg)
                    LayoutHelpers.SetDimensions(curGrid[index].color, 21, 20)
                    LayoutHelpers.AtLeftTopIn(curGrid[index].color, armyBg, labelXPos.icon, 6)

                    curGrid[index].factionIcon = Bitmap(curGrid[index].color)
                    LayoutHelpers.FillParent(curGrid[index].factionIcon, curGrid[index].color)

                    local INDEX = index
                    curGrid[index].playerName = UIUtil.CreateText(armyBg, "", 16, UIUtil.bodyFont)
                    LayoutHelpers.AtLeftTopIn(curGrid[index].playerName, armyBg, labelXPos.player, 6)
                    LayoutHelpers.AnchorToLeft(curGrid[index].playerName, curGrid[INDEX].playerName, -220)
                    curGrid[index].playerName:SetClipToWidth(true)

                    --curGrid[index].teamName = UIUtil.CreateText(armyBg, "", 16, UIUtil.bodyFont)
                    --LayoutHelpers.AtLeftTopIn(curGrid[index].teamName, armyBg, labelXPos.team, 6)

                    curGrid[index].cols = {}
                    for col = 1, 6 do
                        curGrid[index].cols[col] = UIUtil.CreateText(armyBg, "", 14, UIUtil.bodyFont)
                        LayoutHelpers.AtVerticalCenterIn(curGrid[index].cols[col], armyBg)
                        LayoutHelpers.AtHorizontalCenterIn(curGrid[index].cols[col], sortButtons[col].checkbox)
                    end
                    index = index + 1
                end
            end

            -- set up data type buttons
            local typeButtons = {}
            local prevButton = false
            local typeGroup = Group(gridGroup)
            local width = 0
            for index, dataType in tabData.types do
                local i = index
                typeButtons[index] = {}
                typeButtons[index].checkbox = Checkbox(typeGroup
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_up.dds')
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_over.dds')
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_down.dds')
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_down.dds')
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_dis.dds')
                    , UIUtil.SkinnableFile('/scx_menu/small-btn/small_btn_dis.dds')
                    , "UI_Tab_Click_02", "UI_Tab_Rollover_02")

                if prevButton then
                    LayoutHelpers.RightOf(typeButtons[index].checkbox, prevButton)
                else
                    LayoutHelpers.AtLeftTopIn(typeButtons[index].checkbox, typeGroup)
                end
                prevButton = typeButtons[index].checkbox
                width = typeButtons[index].checkbox.Width() + width
                typeButtons[index].checkbox.toolTip = dataType.scoreKey

                typeButtons[index].label = {}
                typeButtons[index].label[1] = UIUtil.CreateText(sortButtons[index].checkbox, LOC(dataType.title), 14, UIUtil.bodyFont)
                typeButtons[index].label[1]:DisableHitTest()
                LayoutHelpers.AtCenterIn(typeButtons[index].label[1], typeButtons[index].checkbox, 2)

                typeButtons[index].checkbox.OnCheck = function(self, checked)
                    if checked then
                        typeButtons[i].label[1]:SetColor('ff000000')
                    else
                        typeButtons[i].label[1]:SetColor(UIUtil.fontColor)
                    end
                    Checkbox.OnCheck(self, checked)
                end

                typeButtons[index].checkbox._dataType = dataType.scoreKey
            end
            typeGroup.Width:Set(width)
            LayoutHelpers.SetHeight(typeGroup, 1)
            LayoutHelpers.AtTopIn(typeGroup, gridGroup, 316)
            LayoutHelpers.AtHorizontalCenterIn(typeGroup, bg)

            local typesGroup = RadioGroup(typeButtons)
            typesGroup.OnClick = function(self, index, item)
                SetDataType(item.checkbox._dataType)
                return true
            end
            typesGroup:SetCheckboxEventHandler(function(self, event)
                if event.Type == 'MouseEnter' then
                    Tooltip.CreateMouseoverDisplay(self, "PostScore_"..self.toolTip, nil, true)
                elseif event.Type == 'MouseExit' then
                    Tooltip.DestroyMouseoverDisplay()
                end
            end)

            -- TODO default type? also when these become checkboxes, need to depress type
            -- maybe call SetDataType, but have an updateDisplay function so we don't call UpdateDisplay while creating
            curType = tabData.types[1].scoreKey
        elseif tabData.button == "campaign" then
            -- Set up campaign display
            local opData = operationVictoryTable.opData

            local movieGroup = CreateBorderGroup(currentPage)
            LayoutHelpers.AtLeftTopIn(movieGroup, currentPage, 40, 120)
            LayoutHelpers.SetDimensions(movieGroup, 330, 290)

            -- Set debriefing dialogue if it exists
            local debriefData = {text = '<NO DATA AVAILABLE>', faction = 'NONE'}
            if operationVictoryTable.success and opData.opDebriefingSuccess then
                debriefData = opData.opDebriefingSuccess[1]
            elseif not operationVictoryTable.success and opData.opDebriefingFailure then
                debriefData = opData.opDebriefingFailure[1]
            end

            local opDebriefMovie = Movie(movieGroup)
            LayoutHelpers.AtTopIn(opDebriefMovie, movieGroup, 2)
            LayoutHelpers.AtHorizontalCenterIn(opDebriefMovie, movieGroup)
            LayoutHelpers.SetDimensions(opDebriefMovie, 192, 192)

            local hasVideo = false
            if debriefData.vid and GetMovieDuration('/movies/' .. debriefData.vid) ~= 0 then
                hasVideo = true
            end

            if hasVideo then
                opDebriefMovie:Set('/movies/'..debriefData.vid)
            end

            local opDebriefBitmap = Bitmap(opDebriefMovie, UIUtil.UIFile(prefix[debriefData.faction].texture))
            LayoutHelpers.FillParent(opDebriefBitmap, opDebriefMovie)
            opDebriefBitmap.time = 0
            opDebriefBitmap.first = true
            if hasVideo then
                opDebriefBitmap.OnFrame = function(self, delta)
                    self.time = self.time + delta
                    if self.first then
                        PlaySound(Sound({Bank='Interface', Cue=prefix[debriefData.faction].cue..'_In'}))
                        self.first = false
                    end
                    if self.time > 1 then
                        self:Hide()
                        self:SetNeedsFrameUpdate(false)
                        opDebriefMovie:Play()
                        bg.voHandle = PlayVoice(Sound({Cue = debriefData.cue, Bank = debriefData.bank}))
                    end
                end

                opDebriefMovie.OnLoaded = function(self)
                    opDebriefBitmap:SetNeedsFrameUpdate(true)
                end

                opDebriefMovie.OnFinished = function()
                    opDebriefBitmap:Show()
                    PlaySound(Sound({Bank='Interface', Cue=prefix[debriefData.faction].cue..'_Out'}))
                end
            end

            local movieBorder = Bitmap(opDebriefMovie, UIUtil.UIFile('/scx_menu/score-victory-defeat/video-frame_bmp.dds'))
            LayoutHelpers.AtCenterIn(movieBorder, opDebriefMovie)

            local debriefText = UIUtil.CreateTextBox(movieGroup)
            LayoutHelpers.AtBottomIn(debriefText, movieGroup)
            LayoutHelpers.AtHorizontalCenterIn(debriefText, movieGroup, -15)
            debriefText.Width:Set(function() return movieGroup.Width() - LayoutHelpers.ScaleNumber(30) end)
            LayoutHelpers.SetHeight(debriefText, 90)

            UIUtil.SetTextBoxText(debriefText, debriefData.text)

            local scoreGroup = CreateBorderGroup(currentPage)
            LayoutHelpers.AtTopIn(scoreGroup, currentPage, 120)
            LayoutHelpers.SetDimensions(scoreGroup, 150, 50)

            local opScoreLabel = UIUtil.CreateText(scoreGroup, LOC("<LOC SCORE_0043>Operation Score"), 14, UIUtil.bodyFont)
            LayoutHelpers.AtTopIn(opScoreLabel, scoreGroup, 5)
            LayoutHelpers.AtHorizontalCenterIn(opScoreLabel, scoreGroup)

            local opScore = UIUtil.CreateText(scoreGroup, campaignScore, 14, UIUtil.bodyFont)
            LayoutHelpers.Below(opScore, opScoreLabel, 4)
            LayoutHelpers.AtHorizontalCenterIn(opScore, scoreGroup)

            local objGroup = CreateBorderGroup(currentPage)
            LayoutHelpers.AtLeftTopIn(objGroup, currentPage, 395, 190)
            LayoutHelpers.SetDimensions(objGroup, 535, 220)

            LayoutHelpers.AtHorizontalCenterIn(scoreGroup, objGroup)

            local sortedObjectives = {}
            local tempObjectives = {}
            local obTable = import('/lua/ui/game/objectives2.lua').GetCurrentObjectiveTable()
            local hasPrimaries = false
            local hasSecondaries = false
            local hasBonuses = false
            if obTable then
                for key, objective in obTable do
                    local compStr
                    local compColor = 'ffff0000'
                    local objTitle = objective.title
                    local objDescription = objective.description
                    if objective.complete == 'complete' then
                        compStr = "<LOC SCORE_0038>Accomplished"
                        compColor = 'ff00ff00'
                    elseif objective.complete == 'failed' then
                        compStr = "<LOC SCORE_0039>Failed"
                        compColor = 'ffff0000'
                    else
                        compStr = "<LOC SCORE_0054>Incomplete"
                        compColor = 'ff0000ff'
                    end
                    if objective.type == 'primary' then
                        hasPrimaries = true
                    elseif objective.type == 'secondary' then
                        hasSecondaries = true
                    elseif objective.type == 'bonus' then
                        hasBonuses = true
                    end
                    -- Show title and description of hidden objectives only if they're completed
                    if objective.hidden and objective.complete ~= 'complete' then
                        objTitle = "<LOC SCORE_0042>Not Discovered"
                        objDescription = "<LOC SCORE_0048>This objective will be revealed only after it's completion"
                        compStr = "<LOC SCORE_0054>Incomplete"
                        compColor = 'ff0000ff'
                    end
                    table.insert(tempObjectives, {title = LOC(objTitle), description = objDescription, complete = LOC(compStr), completeColor = compColor, type = objective.type})
                end
            end

            if hasPrimaries then
                table.insert(sortedObjectives, {title = LOC("<LOC SCORE_0037>Primary Objectives"), type = 'header'})
                for i, v in tempObjectives do
                    if v.type == 'primary' then
                        table.insert(sortedObjectives, v)
                    end
                end
            end

            if hasSecondaries then
                table.insert(sortedObjectives, {title = LOC("<LOC SCORE_0040>Secondary Objectives"), type = 'header'})
                for i, v in tempObjectives do
                    if v.type == 'secondary' then
                        table.insert(sortedObjectives, v)
                    end
                end
            end

            if hasBonuses then
                table.insert(sortedObjectives, {title = LOC("<LOC SCORE_0041>Bonus Objectives"), type = 'header'})
                for i, v in tempObjectives do
                    if v.type == 'bonus' then
                        table.insert(sortedObjectives, v)
                    end
                end
            end

            objContainer = Group(objGroup)
            objContainer.Height:Set(function() return objGroup.Height() + 0 end)
            objContainer.Width:Set(function() return objGroup.Width() - LayoutHelpers.ScaleNumber(30) end)
            objContainer.top = 0

            LayoutHelpers.AtLeftTopIn(objContainer, objGroup)
            UIUtil.CreateVertScrollbarFor(objContainer)

            local objEntries = {}

            local function CreateElement(index)
                objEntries[index] = {}
                objEntries[index].bg = Bitmap(objContainer)
                objEntries[index].bg.Left:Set(objContainer.Left)
                objEntries[index].bg.Right:Set(objContainer.Right)

                objEntries[index].title = UIUtil.CreateText(objEntries[1].bg, '', 16, UIUtil.bodyFont)
                objEntries[index].title:DisableHitTest()

                objEntries[index].result = UIUtil.CreateText(objEntries[1].bg, '', 16, UIUtil.bodyFont)
                objEntries[index].result:DisableHitTest()

                objEntries[index].bg.Height:Set(function() return objEntries[index].title.Height() + LayoutHelpers.ScaleNumber(4) end)

                LayoutHelpers.AtVerticalCenterIn(objEntries[index].title, objEntries[index].bg)
                LayoutHelpers.AtVerticalCenterIn(objEntries[index].result, objEntries[index].bg)
                LayoutHelpers.AtLeftIn(objEntries[index].title, objEntries[index].bg)
                LayoutHelpers.AtRightIn(objEntries[index].result, objEntries[index].bg, 5)
            end

            CreateElement(1)
            LayoutHelpers.AtTopIn(objEntries[1].bg, objContainer)

            local index = 2
            while objEntries[table.getsize(objEntries)].bg.Top() + (2 * objEntries[1].bg.Height()) < objContainer.Bottom() do
                CreateElement(index)
                LayoutHelpers.Below(objEntries[index].bg, objEntries[index-1].bg)
                index = index + 1
            end

            local numLines = function() return table.getsize(objEntries) end

            local function DataSize()
                return table.getn(sortedObjectives)
            end

            -- called when the scrollbar for the control requires data to size itself
            -- GetScrollValues must return 4 values in this order:
            -- rangeMin, rangeMax, visibleMin, visibleMax
            -- aixs can be "Vert" or "Horz"
            objContainer.GetScrollValues = function(self, axis)
                local size = DataSize()
                --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
                return 0, size, self.top, math.min(self.top + numLines(), size)
            end

            -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
            objContainer.ScrollLines = function(self, axis, delta)
                self:ScrollSetTop(axis, self.top + math.floor(delta))
            end

            -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
            objContainer.ScrollPages = function(self, axis, delta)
                self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
            end

            -- called when the scrollbar wants to set a new visible top line
            objContainer.ScrollSetTop = function(self, axis, top)
                top = math.floor(top)
                if top == self.top then return end
                local size = DataSize()
                self.top = math.max(math.min(size - numLines() , top), 0)
                self:CalcVisible()
            end

            -- called to determine if the control is scrollable on a particular access. Must return true or false.
            objContainer.IsScrollable = function(self, axis)
                return true
            end
            -- determines what controls should be visible or not
            objContainer.CalcVisible = function(self)
                local function SetTextLine(line, data, lineID)
                    if data.type == 'header' then
                        LayoutHelpers.AtHorizontalCenterIn(line.title, objContainer)
                        line.bg:SetSolidColor('ff506268')
                        line.title:SetText(data.title)
                        line.title:SetFont(UIUtil.titleFont, 16)
                        line.title:SetColor(UIUtil.fontColor)
                        line.result:SetText('')
                    else
                        LayoutHelpers.AtLeftIn(line.title, line.bg, 5)
                        line.bg:SetSolidColor('00000000')
                        line.title:SetText(data.title)
                        line.title:SetColor('ffffffff')
                        line.title:SetFont(UIUtil.bodyFont, 14)
                        line.result:SetText(data.complete or "<LOC key_binding_0001>No action text")
                        line.result:SetColor(data.completeColor)
                        Tooltip.AddControlTooltip(line.bg, {text = data.title, body = data.description})
                    end
                end
                for i, v in objEntries do
                    if sortedObjectives[i + self.top] then
                        SetTextLine(v, sortedObjectives[i + self.top], i + self.top)
                    else
                        v.bg:SetSolidColor('00000000')
                        v.title:SetText('')
                        v.result:SetText('')
                    end
                end
            end
            objContainer.HandleEvent = function(control, event)
                if event.Type == 'WheelRotation' then
                    local lines = 1
                    if event.WheelRotation > 0 then
                        lines = -1
                    end
                    control:ScrollLines(nil, lines)
                end
            end
            objContainer:CalcVisible()
        end

        local victoryString
        if operationVictoryTable then
            if operationVictoryTable.success then
                victoryString = "<LOC SCORE_0055>Operation Successful"
            else
                victoryString = "<LOC SCORE_0056>Operation Failed"
            end
        else
            if victory != nil then
                if victory then
                    victoryString = "<LOC SCORE_0046>Victory"
                else
                    victoryString = "<LOC SCORE_0047>Defeat"
                end
            else
                victoryString = "<LOC _Score>"
            end

        end

        -- sets the score dialog box title to the appropriate string
        bg.title:SetText(LOC(victoryString))

        UpdateDisplay()
    end

    -- set up top level tabs
    local prev = false
    local defaultTab = false
    for index, value in tabs do
        -- don't show campaign button normally
        if value.button == "campaign" and not showCampaign then
            continue
        end

        local curButton = UIUtil.CreateButtonStd(bg, '/scx_menu/tab_btn/tab', value.title, 16, nil, nil, "UI_Tab_Click_02", "UI_Tab_Rollover_02")
        if prev then
            --curButton.Left:Set(function() return prev.Right() + 0 end)
            --curButton.Bottom:Set(function() return prev.Bottom() end)
            LayoutHelpers.RightOf(curButton, prev, -5)
        else
            --LayoutHelpers.RelativeTo(curButton, bg,
            --    UIUtil.SkinnableFile('/dialogs/score-victory-defeat/score-victory-defeat_layout.lua'),
            --    'l_general_btn', 'panel_bmp', -10)
            LayoutHelpers.AtLeftTopIn(curButton, bg, 17, 57)
            defaultTab = curButton
        end
        prev = curButton

        curButton.OnClick = function(self, modifiers)
            SetNewPage(self)
        end
        local tempKey = value.scoreKey
        curButton.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, "PostScore_" .. tempKey, nil, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            Button.HandleEvent(self, event)
        end

        curButton.tabData = value
    end
    SetNewPage(defaultTab)

    hotstats.Set_graph(victory, showCampaign, operationVictoryTable, dialog, bg)
end

function CreateBorderGroup(parent)
    local group = Group(parent)

    group.tl = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_ul.dds'))
    group.tm = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_um.dds'))
    group.tr = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_ur.dds'))
    group.l = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_vert_l.dds'))
    group.r = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_vert_r.dds'))
    group.bl = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_ll.dds'))
    group.bm = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_lm.dds'))
    group.br = Bitmap(group, UIUtil.UIFile('/scx_menu/score-victory-defeat/panel-campaign_brd_lr.dds'))

    group.tl.Bottom:Set(group.Top)
    group.tl.Right:Set(group.Left)

    group.tr.Bottom:Set(group.Top)
    group.tr.Left:Set(group.Right)

    group.tm.Bottom:Set(group.Top)
    group.tm.Left:Set(group.Left)
    group.tm.Right:Set(group.Right)

    group.bl.Top:Set(group.Bottom)
    group.bl.Right:Set(group.Left)

    group.br.Top:Set(group.Bottom)
    group.br.Left:Set(group.Right)

    group.bm.Top:Set(group.Bottom)
    group.bm.Left:Set(group.Left)
    group.bm.Right:Set(group.Right)

    group.l.Top:Set(group.Top)
    group.l.Bottom:Set(group.Bottom)
    group.l.Right:Set(group.Left)

    group.r.Top:Set(group.Top)
    group.r.Bottom:Set(group.Bottom)
    group.r.Left:Set(group.Right)

    return group
end

-- kept for mod backwards compatibility
local CampaignManager = import("/lua/ui/campaign/campaignmanager.lua")
local Text = import("/lua/maui/text.lua").Text