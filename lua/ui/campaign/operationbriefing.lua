-- File: lua/modules/ui/campaign/operationbriefing.lua
-- Author: Chris Blackwell, Evan Pongress
-- Summary: campaign operations view
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------
local UIUtil = import("/lua/ui/uiutil.lua")
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Movie = import("/lua/maui/movie.lua").Movie
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local WrapText = import('/lua/maui/text.lua').WrapText
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local Prefs = import("/lua/user/prefs.lua")
local MapUtil = import("/lua/ui/maputil.lua")
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local CampaignManager = import("/lua/ui/campaign/campaignmanager.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local mapErrorDialog = nil
local activePopupButton = nil
local streamThread = nil
local faction = nil
local difficulty = nil

local abmientSoundTable = {
    aeon = {Cue = 'AMB_AEON_OP_Briefing', Bank = 'AmbientTest_Vanilla'},
    cybran = {Cue = 'AMB_CYBRAN_OP_Briefing', Bank = 'AmbientTest_Vanilla'},
    uef = {Cue = 'AMB_UEF_OP_Briefing', Bank = 'AmbientTest_Vanilla'},
    fa = {Cue = "AMB_SER_OP_Briefing", Bank = "AmbientTest"},
}

local control = {}
-- Disables some original single player functionality like a Launch button or difficulty/faction selection
local originalBriefing = false

function CreateUI(parent, scenarioPath)
    operationData = import(string.gsub(scenarioPath, '_scenario.lua', '_operation.lua')).operationData
    -- Entering from Campaign select screen
    if not parent then
        parent = Group(GetFrame(0))
        LayoutHelpers.FillParent(parent, GetFrame(0))
        originalBriefing = true
        -- FAF missions use a slightly different format of the op table
        operationData.opBriefing = {
            text = operationData.opBriefingText,
            movies = operationData.opMovies.briefing.movies,
            bgsound = operationData.opMovies.briefing.bgsound,
            voice = operationData.opMovies.briefing.voice,
        }
    end
    local operationID = operationData.key
    -- Either vanilla faction specific UI or defaults to FA one.
    local factionStyle = operationData.opBriefing.style

    parent:DisableHitTest()
    local playing = false

    local ambientSounds
    local currentBriefingText = {}
    local fmv_time = 0
    local text_time = 0
    local fmv_playing = false
    Prefs.SetToCurrentProfile('Last_Op_Selected', {id = operationID})

    local briefingGroup = Group(parent)
    LayoutHelpers.DepthOverParent(briefingGroup, parent, 5)
    LayoutHelpers.FillParent(briefingGroup, parent)
    briefingGroup:DisableHitTest()

    local currentPhase = 1
    local briefMovie = Movie(parent)
    briefMovie.Depth:Set(parent.Depth)

    if factionStyle then
        -- Ambient sounds
        ambientSounds = PlaySound(Sound(abmientSoundTable[factionStyle]))

        -- background
        local background = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/background_bmp.dds'))
        LayoutHelpers.FillParent(background, parent)
        LayoutHelpers.DepthUnderParent(background, parent)

        if factionStyle == 'aeon' then
            local back_energy = Bitmap(background, UIUtil.UIFile('/campaign/operations-02/energy-field_bmp.dds'))
            LayoutHelpers.FillParent(back_energy, background)
            LayoutHelpers.DepthUnderParent(back_energy, parent)
        end

        -- Border - 12-piece
        -- bottom middle
        local btm_mid = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_lm.dds'))
        control.bottom = btm_mid
        LayoutHelpers.AtHorizontalCenterIn(btm_mid, parent)
        LayoutHelpers.AtBottomIn(btm_mid, parent)
        
        -- top middle
        local top_mid = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_um.dds'))
        control.top = top_mid
        LayoutHelpers.AtHorizontalCenterIn(top_mid, parent)
        LayoutHelpers.AtTopIn(top_mid, parent)
        
        -- bottom left corner
        local btm_left = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_ll.dds'))
        LayoutHelpers.AtLeftIn(btm_left, parent)
        LayoutHelpers.AtBottomIn(btm_left, parent)
        
        -- bottom right corner
        local btm_right = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_lr.dds'))
        LayoutHelpers.AtRightIn(btm_right, parent)
        LayoutHelpers.AtBottomIn(btm_right, parent)
        
        -- top left corner
        local top_left = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_ul.dds'))
        LayoutHelpers.AtLeftIn(top_left, parent)
        LayoutHelpers.AtTopIn(top_left, parent)
        
        -- top right corner
        local top_right = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_ur.dds'))
        LayoutHelpers.AtRightIn(top_right, parent)
        LayoutHelpers.AtTopIn(top_right, parent)
        
        -- lower left tile
        local tile_btm_left = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_lml.dds'))
        LayoutHelpers.AtBottomIn(tile_btm_left, parent)
        tile_btm_left.Left:Set(btm_left.Right)
        tile_btm_left.Right:Set(btm_mid.Left)
        
        -- lower right tile
        local tile_btm_right = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_lmr.dds'))
        LayoutHelpers.AtBottomIn(tile_btm_right, parent)
        tile_btm_right.Left:Set(btm_mid.Right)
        tile_btm_right.Right:Set(btm_right.Left)
        
        -- upper left tile
        local tile_top_left = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_uml.dds'))
        LayoutHelpers.AtTopIn(tile_top_left, parent)
        tile_top_left.Left:Set(top_left.Right)
        tile_top_left.Right:Set(top_mid.Left)
        
        -- upper right tile
        local tile_top_right = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_horz_umr.dds'))
        LayoutHelpers.AtTopIn(tile_top_right, parent)
        tile_top_right.Left:Set(top_mid.Right)
        tile_top_right.Right:Set(top_right.Left)
        
        -- left mid tile
        local tile_mid_left = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_vert_l.dds'))
        LayoutHelpers.AtLeftIn(tile_mid_left, parent)
        tile_mid_left.Top:Set(top_left.Bottom)
        tile_mid_left.Bottom:Set(btm_left.Top)
        
        -- right mid tile
        local tile_mid_right = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/back_brd_vert_r.dds'))
        LayoutHelpers.AtRightIn(tile_mid_right, parent)
        tile_mid_right.Top:Set(top_right.Bottom)
        tile_mid_right.Bottom:Set(btm_right.Top)

        -- main panel
        local main_panel = Group(background, "main_panel")
        LayoutHelpers.FillParent(main_panel, background)
        LayoutHelpers.DepthOverParent(main_panel, background, 2)
        -- Text area
        local briefBG = Group(main_panel, 'briefBG')
        control.briefBG = briefBG
        if factionStyle == 'aeon' then
            briefBG.Height:Set(function() return main_panel.Height() * .23 end)
            LayoutHelpers.AtHorizontalCenterIn(briefBG, main_panel)
            LayoutHelpers.AtLeftIn(briefBG, main_panel, 50)
            LayoutHelpers.AtRightIn(briefBG, main_panel, 50)
            LayoutHelpers.AtBottomIn(briefBG, main_panel, 115)
        elseif factionStyle == 'cybran' then
            briefBG.Height:Set(function() return main_panel.Height() * .26 end)
            LayoutHelpers.AtHorizontalCenterIn(briefBG, main_panel)
            LayoutHelpers.AtLeftIn(briefBG, main_panel, 40)
            LayoutHelpers.AtRightIn(briefBG, main_panel, 40)
            LayoutHelpers.AtBottomIn(briefBG, main_panel, 98)
        elseif factionStyle == 'uef' then
            LayoutHelpers.SetHeight(briefBG, 200)  -- uef text background is always the same size
            LayoutHelpers.AtHorizontalCenterIn(briefBG, main_panel)
            LayoutHelpers.AtLeftIn(briefBG, main_panel, 100)
            LayoutHelpers.AtRightIn(briefBG, main_panel, 100)
            LayoutHelpers.AtBottomIn(briefBG, main_panel, 160)
        end

        local briefBG_ul = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_ul.dds'))
        LayoutHelpers.AtLeftTopIn(briefBG_ul, briefBG)
        
        local briefBG_ur = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_ur.dds'))
        LayoutHelpers.AtRightTopIn(briefBG_ur, briefBG)
        
        local briefBG_um = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_horz_um.dds'))
        LayoutHelpers.AtTopIn(briefBG_um, briefBG)
        briefBG_um.Left:Set(briefBG_ul.Right)
        briefBG_um.Right:Set(briefBG_ur.Left)
        
        local briefBG_ll = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_ll.dds'))
        LayoutHelpers.AtBottomIn(briefBG_ll, briefBG)
        LayoutHelpers.AtLeftIn(briefBG_ll, briefBG)
        
        local briefBG_lr = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_lr.dds'))
        LayoutHelpers.AtBottomIn(briefBG_lr, briefBG)
        LayoutHelpers.AtRightIn(briefBG_lr, briefBG)
        
        local briefBG_lm = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_lm.dds'))
        LayoutHelpers.AtBottomIn(briefBG_lm, briefBG)
        briefBG_lm.Left:Set(briefBG_ll.Right)
        briefBG_lm.Right:Set(briefBG_lr.Left)
        
        local briefBG_l = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_vert_l.dds'))
        LayoutHelpers.AtLeftIn(briefBG_l, briefBG)
        briefBG_l.Top:Set(briefBG_ul.Bottom)
        briefBG_l.Bottom:Set(briefBG_ll.Top)
        
        local briefBG_r = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_vert_r.dds'))
        LayoutHelpers.AtRightIn(briefBG_r, briefBG)
        briefBG_r.Top:Set(briefBG_ur.Bottom)
        briefBG_r.Bottom:Set(briefBG_lr.Top)
        
        local briefBG_m = Bitmap(briefBG, UIUtil.UIFile('/campaign/text-panel/text-panel_brd_m.dds'))
        briefBG_m.Left:Set(briefBG_l.Right)
        briefBG_m.Right:Set(briefBG_r.Left)
        briefBG_m.Top:Set(briefBG_um.Bottom)
        briefBG_m.Bottom:Set(briefBG_lm.Top)

        -- Movie set up
        local movRatio, movMinTop, widthOffSet
        if factionStyle == 'aeon' then
            movRatio = 528 / 1168
            movMinTop = LayoutHelpers.ScaleNumber(50)
            widthOffSet = LayoutHelpers.ScaleNumber(0)
        elseif factionStyle == 'cybran' then
            movRatio = 528 / 1040
            movMinTop = LayoutHelpers.ScaleNumber(70)
            widthOffSet = LayoutHelpers.ScaleNumber(0)
        elseif factionStyle == 'uef' then
            movRatio = 528 / 1168
            movMinTop = LayoutHelpers.ScaleNumber(70)
            widthOffSet = LayoutHelpers.ScaleNumber(300)
        end

        function SetMovieSize()
            local movVSpace = control.briefBG.Top() - LayoutHelpers.ScaleNumber(20) - movMinTop
            local sizeHeight = movVSpace

            local sizeWidth = math.floor(sizeHeight / movRatio)
            if sizeWidth + widthOffSet > parent.Width() then
                sizeWidth = parent.Width() - widthOffSet
                sizeHeight = sizeWidth * movRatio
            end

            local movTop = math.floor((movVSpace - sizeHeight)/2 + movMinTop)
            briefMovie.Width:Set(sizeWidth)
            briefMovie.Height:Set(sizeHeight)

            return movTop
        end

        briefMovie.Top:Set(function()
            return SetMovieSize()
        end)
        --briefMovie.Top:Set(movTop)
        LayoutHelpers.AtHorizontalCenterIn(briefMovie, main_panel)

        -- Extra brackets around movies
        if factionStyle == 'cybran' then
            -- TODO: Check if parent is the correct parent
            local bracketRight = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/display-bracket-cybran-r_bmp.dds'))
            LayoutHelpers.AtRightTopIn(bracketRight, parent, 0, 50)

            local bracketLeft = Bitmap(parent, UIUtil.UIFile('/campaign/operations-02/display-bracket-cybran-l_bmp.dds'))
            LayoutHelpers.AtLeftIn(bracketLeft, parent)
            LayoutHelpers.AnchorToTop(bracketLeft, control.briefBG, 10)

            local QAIMovie = Movie(bracketRight)
            control.QAIMovie = QAIMovie
            LayoutHelpers.FromRightIn(QAIMovie, bracketRight, .021)
            LayoutHelpers.FromTopIn(QAIMovie, bracketRight, .052)
            QAIMovie.Width:Set(function() return math.floor(bracketRight.Width() * .918) end)
            QAIMovie.Height:Set(QAIMovie.Width)
            QAIMovie:Set('/movies/QAI_loop.sfd')
            QAIMovie:Play()
            QAIMovie:Loop(true)
        elseif factionStyle == 'uef' then
            local brackets = {}
            -- left bracket
            brackets.lBar_top = Bitmap(main_panel, UIUtil.UIFile('/campaign/display-bracket-l_bmp/display-bracket-l_bmp_r.dds'))
            LayoutHelpers.AnchorToLeft(brackets.lBar_top, briefMovie, -18)
            LayoutHelpers.AtTopIn(brackets.lBar_top, briefMovie, -15)
            LayoutHelpers.DepthOverParent(brackets.lBar_top, briefMovie, 2)

            brackets.lBar_btm = Bitmap(brackets.lBar_top, UIUtil.UIFile('/campaign/display-bracket-l_bmp/display-bracket-l_bmp_b.dds'))
            LayoutHelpers.AtRightIn(brackets.lBar_btm, brackets.lBar_top, 0)
            LayoutHelpers.AtBottomIn(brackets.lBar_btm, briefMovie, -8)
    
            brackets.lBar_bm = Bitmap(brackets.lBar_top, UIUtil.UIFile('/campaign/display-bracket-l_bmp/display-bracket-l_bmp_bm.dds'))
            LayoutHelpers.AtRightIn(brackets.lBar_bm, brackets.lBar_top, 2)
            brackets.lBar_bm.Top:Set(brackets.lBar_top.Bottom)
            brackets.lBar_bm.Bottom:Set(brackets.lBar_btm.Top)
            
            brackets.lBar_l = Bitmap(brackets.lBar_top, UIUtil.UIFile('/campaign/display-bracket-l_bmp/display-bracket-l_bmp_l.dds'))
            brackets.lBar_l.Left:Set(0)
            LayoutHelpers.AtTopIn(brackets.lBar_l, brackets.lBar_top, 91)
            
            brackets.lBar_lm = Bitmap(brackets.lBar_top, UIUtil.UIFile('/campaign/display-bracket-l_bmp/display-bracket-l_bmp_m.dds'))
            LayoutHelpers.AtTopIn(brackets.lBar_lm, brackets.lBar_top, 103)
            brackets.lBar_lm.Left:Set(brackets.lBar_l.Right)
            brackets.lBar_lm.Right:Set(brackets.lBar_top.Left)
            
            -- right bracket
            brackets.rBar_l = Bitmap(main_panel, UIUtil.UIFile('/campaign/display-bracket-r_bmp/display-bracket-l_bmp_r.dds'))
            LayoutHelpers.AnchorToRight(brackets.rBar_l, briefMovie, 18)
            LayoutHelpers.AtTopIn(brackets.rBar_l, briefMovie, -15)
            LayoutHelpers.DepthOverParent(brackets.rBar_l, briefMovie, 2)
    
            brackets.rBar_btm = Bitmap(brackets.rBar_l, UIUtil.UIFile('/campaign/display-bracket-r_bmp/display-bracket-l_bmp_b.dds'))
            LayoutHelpers.AtLeftIn(brackets.rBar_btm, brackets.rBar_l, 1)
            LayoutHelpers.AtBottomIn(brackets.rBar_btm, briefMovie, -8)
    
            brackets.rBar_bm = Bitmap(brackets.rBar_l, UIUtil.UIFile('/campaign/display-bracket-r_bmp/display-bracket-l_bmp_bm.dds'))
            LayoutHelpers.AtLeftIn(brackets.rBar_bm, brackets.rBar_l, 2)
            brackets.rBar_bm.Top:Set(brackets.rBar_l.Bottom)
            brackets.rBar_bm.Bottom:Set(brackets.rBar_btm.Top)
            
            brackets.rBar_r = Bitmap(brackets.rBar_l, UIUtil.UIFile('/campaign/display-bracket-r_bmp/display-bracket-l_bmp_l.dds'))
            brackets.rBar_r.Right:Set(parent.Width)
            LayoutHelpers.AtTopIn(brackets.rBar_r, brackets.rBar_l, 91)
            
            brackets.rBar_rm = Bitmap(brackets.rBar_l, UIUtil.UIFile('/campaign/display-bracket-r_bmp/display-bracket-l_bmp_m.dds'))
            LayoutHelpers.AtTopIn(brackets.rBar_rm, brackets.rBar_l, 103)
            brackets.rBar_rm.Left:Set(brackets.rBar_l.Right)
            brackets.rBar_rm.Right:Set(brackets.rBar_r.Left)
        end
    else
        -- Ambient sounds
        ambientSounds = PlaySound(Sound(abmientSoundTable.fa))

        control.top = Bitmap(parent, UIUtil.UIFile('/scx_menu/operation-briefing/border-console-top_bmp.dds'))
        LayoutHelpers.AtTopIn(control.top, parent)
        LayoutHelpers.AtHorizontalCenterIn(control.top, parent)

        control.bottom = Bitmap(parent, UIUtil.UIFile('/scx_menu/operation-briefing/border-console-bot_bmp.dds'))
        LayoutHelpers.AtBottomIn(control.bottom, parent)
        LayoutHelpers.AtHorizontalCenterIn(control.bottom, parent)

        -- Movie set up
        briefMovie.Height:Set(parent.Height)
        briefMovie.Width:Set(function()
            local ratio = parent.Height() / 1024
            return 1824 * ratio
        end)
        LayoutHelpers.AtCenterIn(briefMovie, parent)
        briefMovie:DisableHitTest()

        local movieBG = Bitmap(parent, UIUtil.UIFile('/scx_menu/campaign-select/bg.dds'))
        movieBG.Height:Set(parent.Height)
        movieBG.Width:Set(function()
            local ratio = parent.Height() / 1024
            return 1824 * ratio
        end)
        LayoutHelpers.AtCenterIn(movieBG, parent)
        LayoutHelpers.DepthUnderParent(movieBG, briefMovie)

        -- Text area
        local briefBG = Bitmap(briefingGroup, UIUtil.UIFile('/scx_menu/operation-briefing/text-panel_bmp.dds'))
        control.briefBG = briefBG
        -- bar below text area
        local briefGlow = Bitmap(briefBG, UIUtil.UIFile('/scx_menu/operation-briefing/emiter-bar_bmp.dds'))
        LayoutHelpers.AnchorToTop(briefGlow, control.bottom, -5)
        LayoutHelpers.AtHorizontalCenterIn(briefGlow, control.bottom)
        LayoutHelpers.DepthOverParent(briefGlow, briefingGroup)

        LayoutHelpers.DepthOverParent(briefBG, briefGlow)
        LayoutHelpers.AnchorToTop(briefBG, briefGlow, -50)
        LayoutHelpers.AtHorizontalCenterIn(briefBG, briefGlow)

        -- Show/Hide log button
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
        LayoutHelpers.AtLeftTopIn(subtitleChk, control.bottom, 276, 16)

        subtitleChk.label = UIUtil.CreateText(subtitleChk, LOC(onStr), 14, UIUtil.bodyFont)
        subtitleChk.label:DisableHitTest()
        LayoutHelpers.AtCenterIn(subtitleChk.label, subtitleChk)

        subtitleChk.OnCheck = function(self, checked)
            if checked then
                self.label:SetText(LOC(onStr))
                control.briefBG:Show()
            else
                self.label:SetText(LOC(offStr))
                control.briefBG:Hide()
            end
            Prefs.SetToCurrentProfile('briefing_log', checked)
        end

        local showLog = Prefs.GetFromCurrentProfile('briefing_log')
        if showLog == nil then
            showLog = true
        end

        subtitleChk:SetCheck(showLog)
    end

    local backBtn = UIUtil.CreateButtonStd(briefingGroup, '/scx_menu/small-btn/small', "<LOC opbrief_0002>Back", 16, 2)
    if factionStyle == 'aeon' then
        LayoutHelpers.AtLeftIn(backBtn, parent, 70)
        LayoutHelpers.AtBottomIn(backBtn, parent)
    elseif factionStyle == 'cybran' then
        LayoutHelpers.AtLeftIn(backBtn, parent, 40)
        LayoutHelpers.AtBottomIn(backBtn, parent, 5)
    elseif factionStyle == 'uef' then
        LayoutHelpers.AtLeftIn(backBtn, parent, 38)
        LayoutHelpers.AtBottomIn(backBtn, parent)
    else
        LayoutHelpers.AtLeftIn(backBtn, control.bottom, 25)
        LayoutHelpers.AtBottomIn(backBtn, control.bottom, -4)
    end
    backBtn.OnClick = function(self)
        parent:Destroy()
        if originalBriefing then
            import("/lua/ui/campaign/selectcampaign.lua").CreateUI()
        end
    end

    import("/lua/ui/uimain.lua").SetEscapeHandler(function() backBtn.OnClick() end)

    if originalBriefing then
        local launchBtn = UIUtil.CreateButtonStd(briefingGroup, '/scx_menu/medium-no-br-btn/medium-uef', "<LOC opbrief_0003>Launch", 20, 2)
        LayoutHelpers.AtRightIn(launchBtn, control.bottom, 20)
        LayoutHelpers.AtBottomIn(launchBtn, control.bottom, 2)
        Tooltip.AddButtonTooltip(launchBtn, 'campaignbriefing_launch')
        launchBtn.OnClick = function(self)
            local scenario = MapUtil.LoadScenario(operationData.opMap)
            if scenario then
                local function TryLaunch()
                    local factionToIndex = import("/lua/factions.lua").FactionIndexMap
                    LaunchSinglePlayerSession(import("/lua/singleplayerlaunch.lua").SetupCampaignSession(scenario, difficulty, factionToIndex[faction],
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
        launchBtn:Disable()
    end
    
    -- Mission name
    local title = UIUtil.CreateText(briefingGroup, operationData.opName, 24)
    if factionStyle == 'aeon' then
        LayoutHelpers.AtTopIn(title, control.top, 3)
    elseif factionStyle == 'cybran' then
        LayoutHelpers.AtTopIn(title, control.top, 5)
    elseif factionStyle == 'uef' then
        LayoutHelpers.AtTopIn(title, control.top, 9)
    else
        LayoutHelpers.AtTopIn(title, control.top, 10)
    end
    LayoutHelpers.AtHorizontalCenterIn(title, control.top)

    -- Streaming text container
    local briefText = ItemList(control.briefBG)
    briefText:SetFont(UIUtil.bodyFont, 14)
    briefText:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  "00000000")
    briefText:ShowMouseoverItem(false)

    if factionStyle == 'aeon' then
        LayoutHelpers.AtLeftIn(briefText, control.briefBG, 50)
        LayoutHelpers.AtRightIn(briefText, control.briefBG, 54)
        LayoutHelpers.AtBottomIn(briefText, control.briefBG, 43)
        LayoutHelpers.AtTopIn(briefText, control.briefBG, 27)
    elseif factionStyle == 'cybran' then
        LayoutHelpers.AtTopIn(briefText, control.briefBG, 40)
        LayoutHelpers.AtLeftIn(briefText, control.briefBG, 65)
        LayoutHelpers.AtRightIn(briefText, control.briefBG, 90)
        LayoutHelpers.AtBottomIn(briefText, control.briefBG, 43)
    elseif factionStyle == 'uef' then
        LayoutHelpers.AtLeftIn(briefText, control.briefBG, 20)
        LayoutHelpers.AtRightIn(briefText, control.briefBG, 42)
        LayoutHelpers.AtBottomIn(briefText, control.briefBG, 13)
        LayoutHelpers.AtTopIn(briefText, control.briefBG, 13)
    else
        briefText.Width:Set(function() return control.briefBG.Width() - LayoutHelpers.ScaleNumber(60) end)
        briefText.Height:Set(function() return control.briefBG.Height() - LayoutHelpers.ScaleNumber(30) end)
        LayoutHelpers.AtLeftTopIn(briefText, control.briefBG, 15, 15)
    end

    UIUtil.CreateVertScrollbarFor(briefText)

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

    -- Movie control buttons
    local playpauseBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-pause', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    if factionStyle then
        LayoutHelpers.AtHorizontalCenterIn(playpauseBtn, control.bottom)
        if factionStyle == 'aeon' then
            LayoutHelpers.AtBottomIn(playpauseBtn, control.bottom, 70)
        elseif factionStyle == 'cybran' then
            LayoutHelpers.AtBottomIn(playpauseBtn, control.bottom, 60)
        elseif factionStyle == 'uef' then
            LayoutHelpers.AtBottomIn(playpauseBtn, control.bottom, 87)
        end
    else
        LayoutHelpers.AtLeftTopIn(playpauseBtn, control.bottom, 345, 56)
    end
    Tooltip.AddButtonTooltip(playpauseBtn, 'options_Pause')

    local restartMovBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-back', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    LayoutHelpers.LeftOf(restartMovBtn, playpauseBtn)
    Tooltip.AddButtonTooltip(restartMovBtn, 'campaignbriefing_restart')

    local skipMovBtn = UIUtil.CreateButtonStd(briefingGroup, '/dialogs/movie-control/nav-end', nil, nil, nil, nil, 'UI_Economy_Rollover', 'UI_Opt_Mini_Button_Click')
    LayoutHelpers.RightOf(skipMovBtn, playpauseBtn)
    Tooltip.AddButtonTooltip(skipMovBtn, 'campaignbriefing_skip')

    -- Movie progress bar
    -- updates the times for the streaming text
    local statusBar = StatusBar(parent, 0, 100, false, false,
        UIUtil.UIFile('/scx_menu/operation-briefing/status-bar-back_bmp.dds'),
        UIUtil.UIFile('/scx_menu/operation-briefing/status-bar_bmp.dds'), false)
    LayoutHelpers.AtLeftIn(statusBar, control.bottom, 260)
    LayoutHelpers.AnchorToLeft(statusBar, statusBar, -200)
    LayoutHelpers.AtBottomIn(statusBar, control.bottom, 37)
    statusBar.OnFrame = function(self, delta)
        -- time updated for the streaming text
        fmv_time = fmv_time + delta
        text_time = text_time + delta
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

    if factionStyle then
        statusBar:Hide()
    end

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
                    local data = operationData.opBriefing.text
                    if text_time > nextCueTime and data[nextSection] then
                        local inText = LOCF("%s: %s", data[nextSection].character, data[nextSection].text)
                        local text = WrapText(inText, briefText.Width(),
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
    end

    function GetNextStageIndex()
        if operationData.opBriefing.movies[currentPhase + 1] then
            currentPhase = currentPhase + 1
            return currentPhase
        end

        return false
    end

    function SetMovieData(index)
        -- Set a next movie data
        if index then
            briefMovie:Set('/movies/'..operationData.opBriefing.movies[index],
                           Sound(operationData.opBriefing.bgsound[index]),
                           Sound(operationData.opBriefing.voice[index]))
            briefMovie:Loop(false)
            briefMovie:Show()
            briefMovie.OnLoaded = briefOnLoaded
        else
            -- Vanilla briefings hide the movie
            if factionStyle then
                briefMovie:Reset()
                briefMovie:Hide()
            else
                -- Default priefing has background movie on loop
                briefMovie:Loop(true)
                briefMovie:Set('/movies/menu_background.sfd')
                briefMovie.OnLoaded = loopOnLoaded
            end
        end
    end

    if originalBriefing then
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

        LayoutHelpers.AtLeftTopIn(difficultyOption, control.bottom, 535, 16)
        LayoutHelpers.AtLeftTopIn(factionOption, control.bottom, 535, 50)
    end

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
            currentPhase = 1
            text_time = 0
            SetMovieData(currentPhase)

            if streamThread then
                KillThread(streamThread)
            end
            briefText:SetNeedsFrameUpdate(false)
            briefText:DeleteAllItems()
            currentBriefingText = {}
            streamThread = CreateLogThread()
        end
    end

    skipMovBtn.OnClick = function(self)
        fmv_playing = false

        SetMovieData(false)

        statusBar:SetValue(100)
        statusBar:SetNeedsFrameUpdate(false)
        briefText:DeleteAllItems()
        briefText:SetNeedsFrameUpdate(false)
        local data = operationData.opBriefing.text
        for i, v in data do
            local inText = LOCF("%s: %s", v.character, v.text)
            local text = import("/lua/maui/text.lua").WrapText(inText, briefText.Width(),
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

    SetMovieData(currentPhase)
    streamThread = CreateLogThread()

    briefMovie.OnFinished = function(self)
        SetMovieData(GetNextStageIndex())
    end

    parent.OnDestroy = function(self)
        if streamThread then
            KillThread(streamThread)
        end

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
                LayoutHelpers.AnchorToTop(self.popup, control.bottom, 2)
                LayoutHelpers.AtLeftIn(self.popup, control.bottom, 556)
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

    LayoutHelpers.SetDimensions(group, 150, 30)

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
            LayoutHelpers.SetDimensions(item.icon, item.icon.BitmapWidth() * .5, item.icon.BitmapHeight() * .5)
            LayoutHelpers.AtLeftTopIn(item.icon, item)
            LayoutHelpers.AtLeftIn(item.text, item, 40)
            LayoutHelpers.AtVerticalCenterIn(item.text, item)
            item.Height:Set(item.icon.Height)
        else
            LayoutHelpers.AtCenterIn(item.text, item)
            LayoutHelpers.SetHeight(item, 20)
        end
        LayoutHelpers.SetWidth(item, 100)
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
    LayoutHelpers.SetWidth(bg, 100)
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
