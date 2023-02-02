local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Group = import("/lua/maui/group.lua").Group
local Movie = import("/lua/maui/movie.lua").Movie
local WrapText = import("/lua/maui/text.lua").WrapText
local Button = import("/lua/maui/button.lua").Button
local Prefs = import("/lua/user/prefs.lua")
local Tooltip = import("/lua/ui/game/tooltip.lua")

local CampaignManager = import("/lua/ui/campaign/campaignmanager.lua")

local factionData = {
    {name = '<LOC _Cybran>', icon = '/dialogs/logo-btn/logo-cybran', key = 'cybran', color = 'ffff0000', sound = 'UI_Cybran_Rollover'},
    {name = '<LOC _Aeon>', icon = '/dialogs/logo-btn/logo-aeon', key = 'aeon', color = 'ffb5ff39', sound = 'UI_AEON_Rollover'},
    {name = '<LOC _UEF>', icon = '/dialogs/logo-btn/logo-uef', key = 'uef', color = 'ff00d7ff', sound = 'UI_UEF_Rollover'}
}

local factionCredits = {
    uef = {fmv = 'Credits_UEF', cue = 'X_FMV_UEF_Credits', voice = 'SCX_UEF_Credits_VO'},
    cybran = {fmv = 'Credits_Cybran', cue = 'X_FMV_Cybran_Credits', voice = 'SCX_Cybran_Credits_VO'},
    aeon = {fmv = 'Credits_Aeon', cue = 'X_FMV_Aeon_Credits', voice = 'SCX_Aeon_Credits_VO'},
}


local creditsAvailable = {}
local GUI = {}

function CreateBackground(parent)
    local table = {}

    table.bg = Bitmap(parent, UIUtil.UIFile('/scx_menu/campaign-select/bg.dds'))
    table.bg.Depth:Set(function() return parent.Depth() - 1 end)
    LayoutHelpers.AtCenterIn(table.bg, parent)
    table.bg.Height:Set(parent.Height)
    table.bg.Width:Set(function()
        local ratio = table.bg.Height() / table.bg.BitmapHeight()
        return table.bg.BitmapWidth() * ratio
    end)

    table.bgfmv = Movie(table.bg, '/movies/menu_background.sfd')
    table.bgfmv:Loop(true)
    table.bgfmv:Play()
    LayoutHelpers.FillParent(table.bgfmv, table.bg)

    table.top = Bitmap(parent, UIUtil.UIFile('/scx_menu/campaign-select/border-console-top_bmp.dds'))
    table.top.Depth:Set(parent.Depth)
    LayoutHelpers.AtTopIn(table.top, parent)
    LayoutHelpers.AtHorizontalCenterIn(table.top, parent)

    table.bottom = Bitmap(parent, UIUtil.UIFile('/scx_menu/campaign-select/border-console-bot_bmp.dds'))
    table.bottom.Depth:Set(parent.Depth)
    LayoutHelpers.AtBottomIn(table.bottom, parent)
    LayoutHelpers.AtHorizontalCenterIn(table.bottom, parent)

    return table
end

function CreateUI()
    if not Prefs.GetFromCurrentProfile('ViewedTimeline') then
        Prefs.SetToCurrentProfile('ViewedTimeline', true)
        return TimelineFMV()
    end
    creditsAvailable = {}
    GUI.parent = Group(GetFrame(0))
    LayoutHelpers.FillParent(GUI.parent, GetFrame(0))
    GUI.parent:DisableHitTest()

    local ambientSounds = PlaySound(Sound({Cue = "AMB_SER_OP_Briefing", Bank = "AmbientTest",}))
    GUI.parent.OnDestroy = function(self)
        StopSound(ambientSounds)
    end

    GUI.backgrounds = CreateBackground(GUI.parent)

    GUI.backBtn = UIUtil.CreateButtonStd(GUI.parent, '/scx_menu/small-btn/small', "<LOC sel_campaign_0012>Back", 16, 2)
    LayoutHelpers.AtLeftIn(GUI.backBtn, GUI.backgrounds.bottom, 25)
    LayoutHelpers.AtBottomIn(GUI.backBtn, GUI.backgrounds.bottom, -4)
    GUI.backBtn.OnClick = function(self)
        GUI.parent:Destroy()
        import("/lua/ui/menus/main.lua").CreateUI()
    end

    GUI.title = UIUtil.CreateText(GUI.backgrounds.top, LOC('<LOC sel_campaign_0018>Select Operation'), 24)
    LayoutHelpers.AtHorizontalCenterIn(GUI.title, GUI.backgrounds.top)
    LayoutHelpers.AtTopIn(GUI.title, GUI.backgrounds.top, 10)

    import("/lua/ui/uimain.lua").SetEscapeHandler(function() GUI.backBtn.OnClick() end)

    GUI.selectBtn = UIUtil.CreateButtonStd(GUI.parent, '/scx_menu/medium-no-br-btn/medium-uef', "<LOC sel_campaign_0013>Select", 20, 2)
    LayoutHelpers.AtRightIn(GUI.selectBtn, GUI.backgrounds.bottom, 20)
    LayoutHelpers.AtBottomIn(GUI.selectBtn, GUI.backgrounds.bottom, 2)

    GUI.loadBtn = UIUtil.CreateButtonStd(GUI.parent, '/scx_menu/small-btn/small', "<LOC sel_campaign_0014>Load", 16, 2)
    LayoutHelpers.AtLeftIn(GUI.loadBtn, GUI.backgrounds.bottom, 232)
    LayoutHelpers.AtBottomIn(GUI.loadBtn, GUI.backgrounds.bottom, -4)
    GUI.loadBtn.OnClick = function(self, modifiers)
        import("/lua/ui/dialogs/saveload.lua").CreateLoadDialog(GUI.parent, nil, 'CampaignSave')
    end
    Tooltip.AddButtonTooltip(GUI.loadBtn, 'campaignselect_load')

    GUI.OpSelectionGroup = Bitmap(GUI.parent, UIUtil.UIFile('/scx_menu/campaign-select/panel-list_bmp.dds'))
    LayoutHelpers.AtHorizontalCenterIn(GUI.OpSelectionGroup, GUI.parent, 230)
    LayoutHelpers.AtVerticalCenterIn(GUI.OpSelectionGroup, GUI.parent, -10)
    GUI.OpSelectionGroup:DisableHitTest()

    GUI.OpSelectionGroup.brackets = Brackets(GUI.OpSelectionGroup)

    GUI.OpSelectionGroup.Items = {}
    GUI.OpSelectionGroup.SelectionIcons = {}
    local defaultControl = false
    local lastOp = Prefs.GetFromCurrentProfile('Last_Op_Selected')

    local function CreateSelectionEntry(data)
        local item = Bitmap(GUI.OpSelectionGroup)
        LayoutHelpers.SetDimensions(item, 370, 34)

        item.disabled = false
        item.checked = true

        item.HandleEvent = function(self, event)
            if not self.disabled then
                if event.Type == 'MouseEnter' then
                    if not self.checked then
                        self.highlight:SetAlpha(.5, true)
                        PlaySound(Sound({Cue = "UI_Tab_Rollover_01", Bank = "Interface",}))
                    end
                elseif event.Type == 'MouseExit' then
                    if not self.checked then
                        self.highlight:SetAlpha(0, true)
                    end
                elseif event.Type == 'ButtonPress' then
                    if not self.checked then
                        self:SetCheck(true)
                        PlaySound(Sound({Cue = "UI_Tab_Click_01", Bank = "Interface",}))
                    end
                end
            end
        end

        item.SetCheck = function(self, checked)
            self.checked = checked
            if checked then
                for i, control in GUI.OpSelectionGroup.Items do
                    if control ~= self and control.checked then
                        control:SetCheck(false)
                    end
                end
                self.highlight:SetAlpha(1, true)
                SelectOperation(data)
            else
                self.highlight:SetAlpha(0, true)
            end
        end

        local buttons = {}
        if data.factionIcons then
            local disabled = {}
            for i, facData in factionData do
                local index = i
                data.buttonID = index
                buttons[index] = Bitmap(item, UIUtil.UIFile(facData.icon..'_btn_up.dds'))
                LayoutHelpers.SetDimensions(buttons[index], buttons[index].BitmapWidth() * .5, buttons[index].BitmapHeight() * .5)
                if index == 1 then
                    LayoutHelpers.AtRightIn(buttons[index], item, 4)
                    LayoutHelpers.AtTopIn(buttons[index], item, -2)
                else
                    LayoutHelpers.LeftOf(buttons[index], buttons[index-1], -2)
                end
                if not data[facData.key] then
                    disabled[index] = true
                    buttons[index]:SetTexture(UIUtil.UIFile(facData.icon..'_btn_dis.dds'))
                end
            end
            if disabled[1] and disabled[2] and disabled[3] then
                item.disabled = true
            end
        else
            local texture = '/scx_menu/campaign-select/icon-video_bmp.dds'
            if data.enabled == false then
                texture = '/scx_menu/campaign-select/icon-video-dis_bmp.dds'
            end
            buttons[1] = Bitmap(item, UIUtil.UIFile(texture))
            LayoutHelpers.AtRightIn(buttons[1], item, 46)
            LayoutHelpers.AtTopIn(buttons[1], item, 6)
        end

        local opTitle = UIUtil.CreateText(item, LOC(data.name), 16, UIUtil.bodyFont)
        LayoutHelpers.AtLeftIn(opTitle, item, 15)
        LayoutHelpers.AtVerticalCenterIn(opTitle, item)
        if data.enabled == false or item.disabled then
            opTitle:SetColor('ffaaaaaa')
        end

        item.highlight = Bitmap(item, UIUtil.UIFile('/scx_menu/campaign-select/select_bmp.dds'))
        LayoutHelpers.AtLeftIn(item.highlight, item, -3)
        LayoutHelpers.AtVerticalCenterIn(item.highlight, opTitle)
        item.highlight.Depth:Set(item.Depth)

        item.highlightBox = Bitmap(item.highlight)
        item.highlightBox:SetSolidColor('aa7d9d9d')
        LayoutHelpers.AtLeftIn(item.highlightBox, item, 2)
        LayoutHelpers.AnchorToLeft(item.highlightBox, item, -230)
        LayoutHelpers.AtTopIn(item.highlightBox, item, 2)
        LayoutHelpers.AtBottomIn(item.highlightBox, item, 2)
        LayoutHelpers.DepthUnderParent(item.highlightBox, item)

        item.highlightIconBox = Bitmap(item.highlight)
        item.highlightIconBox:SetSolidColor('aa7d9d9d')
        LayoutHelpers.AtLeftIn(item.highlightIconBox, item, 250)
        LayoutHelpers.AtRightIn(item.highlightIconBox, item, 2)
        LayoutHelpers.AtTopIn(item.highlightIconBox, item, 2)
        LayoutHelpers.AtBottomIn(item.highlightIconBox, item, 2)
        LayoutHelpers.DepthUnderParent(item.highlightIconBox, item)

        item.boxTop = Bitmap(item)
        item.boxTop:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtLeftIn(item.boxTop, item)
        LayoutHelpers.AnchorToLeft(item.boxTop, item, -232)
        LayoutHelpers.AnchorToTop(item.boxTop, item)
        LayoutHelpers.SetHeight(item.boxTop, 1)
        LayoutHelpers.DepthUnderParent(item.boxTop, item)

        item.boxBottom = Bitmap(item)
        item.boxBottom:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtLeftIn(item.boxBottom, item)
        LayoutHelpers.AnchorToLeft(item.boxBottom, item, -232)
        LayoutHelpers.AnchorToBottom(item.boxBottom, item)
        LayoutHelpers.SetHeight(item.boxBottom, 1)
        LayoutHelpers.DepthUnderParent(item.boxBottom, item)

        item.boxLeft = Bitmap(item)
        item.boxLeft:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtTopIn(item.boxLeft, item.boxTop)
        LayoutHelpers.AtBottomIn(item.boxLeft, item.boxBottom)
        LayoutHelpers.AnchorToLeft(item.boxLeft, item.boxTop)
        LayoutHelpers.SetWidth(item.boxLeft, 1)
        LayoutHelpers.DepthUnderParent(item.boxLeft, item)

        item.boxRight = Bitmap(item)
        item.boxRight:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtTopIn(item.boxRight, item.boxTop)
        LayoutHelpers.AtBottomIn(item.boxRight, item.boxBottom)
        LayoutHelpers.AnchorToRight(item.boxRight, item.boxTop)
        LayoutHelpers.SetWidth(item.boxRight, 1)
        LayoutHelpers.DepthUnderParent(item.boxRight, item)

        item.boxIconTop = Bitmap(item)
        item.boxIconTop:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtLeftIn(item.boxIconTop, item, 248)
        LayoutHelpers.AtRightIn(item.boxIconTop, item)
        LayoutHelpers.AnchorToTop(item.boxIconTop, item)
        LayoutHelpers.SetHeight(item.boxIconTop, 1)
        LayoutHelpers.DepthUnderParent(item.boxIconTop, item)

        item.boxIconBottom = Bitmap(item)
        item.boxIconBottom:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtLeftIn(item.boxIconBottom, item, 248)
        LayoutHelpers.AtRightIn(item.boxIconBottom, item)
        LayoutHelpers.AnchorToBottom(item.boxIconBottom, item)
        LayoutHelpers.SetHeight(item.boxIconBottom, 1)
        LayoutHelpers.DepthUnderParent(item.boxIconBottom, item)

        item.boxIconLeft = Bitmap(item)
        item.boxIconLeft:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtTopIn(item.boxIconLeft, item.boxIconTop)
        LayoutHelpers.AtBottomIn(item.boxIconLeft, item.boxIconBottom)
        LayoutHelpers.AnchorToLeft(item.boxIconLeft, item.boxIconBottom)
        LayoutHelpers.SetWidth(item.boxIconLeft, 1)
        LayoutHelpers.DepthUnderParent(item.boxIconLeft, item)

        item.boxIconRight = Bitmap(item)
        item.boxIconRight:SetSolidColor('ff7d9d9d')
        LayoutHelpers.AtTopIn(item.boxIconRight, item.boxIconTop)
        LayoutHelpers.AtBottomIn(item.boxIconRight, item.boxIconBottom)
        LayoutHelpers.AnchorToRight(item.boxIconRight, item.boxIconBottom)
        LayoutHelpers.SetWidth(item.boxIconRight, 1)
        LayoutHelpers.DepthUnderParent(item.boxIconRight, item)

        item:DisableHitTest(true)
        if data.enabled ~= nil then
            if data.enabled then
                item:EnableHitTest()
            else
                item.disabled = true
            end
        else
            item:EnableHitTest()
        end

        table.insert(GUI.OpSelectionGroup.Items, item)
        local index = table.getn(GUI.OpSelectionGroup.Items)
        GUI.OpSelectionGroup.SelectionIcons[index] = buttons
        if index == 1 then
            LayoutHelpers.AtLeftTopIn(GUI.OpSelectionGroup.Items[index], GUI.OpSelectionGroup, 24, 29)
        else
            LayoutHelpers.Below(GUI.OpSelectionGroup.Items[index], GUI.OpSelectionGroup.Items[index-1], 9)
        end

        if lastOp and lastOp.id == data.id then
            if not item.disabled then
                defaultControl = item
            end
        elseif data.id == 'X1CA_001' then
            defaultControl = item
        end
    end

    local campaignSequence = CampaignManager.GetCampaignSequence('uef')

    CreateSelectionEntry({name = '<LOC sel_campaign_0000>Tutorial',
        factionIcons = true,
        uef = true,
        cybran = false,
        aeon = false,
        desc = '<LOC sel_campaign_0019>UEF Brigadier General Fletcher teaches you how to play Supreme Commander: Forged Alliance.',
        launchType = 'tutorial'})

    CreateSelectionEntry({name = '<LOC sel_campaign_0002>Introduction Movie',
        launchType = 'movie',
        id = 'introfmv',
        fmvName = 'FMV_SCX_Intro',
        cueName = 'X_FMV_Intro',
        voiceName = 'SCX_INTRO_VO',
        desc = '<LOC sel_campaign_0020>Chronicles the events leading up to the Forged Alliance campaign.',
        factionIcons = false})

    CreateSelectionEntry({name = '<LOC sel_campaign_0004>Timeline Movie',
        launchType = 'movie',
        id = 'timelinefmv',
        fmvName = 'timeline',
        cueName = 'X_Timeline',
        desc = '<LOC sel_campaign_0021>Detailed breakdown of the time between the end of the Infinite War and the start of Forged Alliance.',
        factionIcons = false})

    for i, v in campaignSequence do
        local index = i
        local opData = import('/maps/'..v..'/'..v..'_operation.lua')
        local uefBtn = CampaignManager.IsOperationSelectable('uef', v)
        local aeonBtn = CampaignManager.IsOperationSelectable('aeon', v)
        local cybranBtn = CampaignManager.IsOperationSelectable('cybran', v)
        local factionicons = true
        local default = false
        if index == 1 then
            default = true
            uefBtn = true
            aeonBtn = true
            cybranBtn = true
        elseif index == 6 then
            creditsAvailable = {
                uef = CampaignManager.IsOperationFinished('uef', v),
                aeon = CampaignManager.IsOperationFinished('aeon', v),
                cybran = CampaignManager.IsOperationFinished('cybran', v),
            }
        end
        local itemData = {name = opData.operationData.long_name,
            desc = opData.opDesc,
            id = opData.opID,
            launchType = 'operation',
            briefingData = opData.operationData,
            factionIcons = factionicons,
            default = default,
            uef = uefBtn,
            aeon = aeonBtn,
            cybran = cybranBtn}
        CreateSelectionEntry(itemData)
    end

    local enableOutros = creditsAvailable.uef or creditsAvailable.aeon or creditsAvailable.cybran
    CreateSelectionEntry({name = '<LOC sel_campaign_0006>Conclusion Movie',
        launchType = 'movie',
        id = 'outrofmv',
        fmvName = 'FMV_SCX_Outro',
        cueName = 'X_FMV_Outro',
        voiceName = 'SCX_Outro_VO',
        desc = '<LOC sel_campaign_0022>The ending of Forged Alliance.',
        factionIcons = false,
        enabled = enableOutros,})

    CreateSelectionEntry({name = '<LOC sel_campaign_0008>Credits',
        launchType = 'movie',
        id = 'credits',
        desc = '<LOC sel_campaign_0023>All of the fine folks that made Forged Alliance a reality.',
        factionIcons = false,
        fmvName = 'FMV_Credits',
        enabled = enableOutros})

    CreateSelectionEntry({name = '<LOC sel_campaign_0010>Post-Credits Movie',
        launchType = 'movie',
        id = 'postoutrofmv',
        fmvName = 'FMV_SCX_Post_Outro',
        cueName = 'X_FMV_Post_Outro',
        voiceName = 'SCX_Post_Outro_VO',
        desc = '<LOC sel_campaign_0024>The End?',
        factionIcons = false,
        enabled = enableOutros,})

    GUI.briefingBG = Bitmap(GUI.parent, UIUtil.UIFile('/scx_menu/campaign-select/panel_bmp.dds'))
    LayoutHelpers.AtHorizontalCenterIn(GUI.briefingBG, GUI.parent, -230)
    LayoutHelpers.AtVerticalCenterIn(GUI.briefingBG, GUI.parent)

    GUI.briefingBG.brackets = Brackets(GUI.briefingBG)

    GUI.selOpTitle = UIUtil.CreateText(GUI.parent, 'yaaaar', 20)
    LayoutHelpers.AtHorizontalCenterIn(GUI.selOpTitle, GUI.briefingBG)
    LayoutHelpers.AtTopIn(GUI.selOpTitle, GUI.briefingBG, 22)

    GUI.selOpDescription = ItemList(GUI.parent)
    GUI.selOpDescription:SetFont(UIUtil.bodyFont, 14)
    GUI.selOpDescription:SetColors(UIUtil.fontColor, "00000000", "FF000000", "00000000", "FF000000")
    GUI.selOpDescription:ShowMouseoverItem(false)
    LayoutHelpers.AtTopIn(GUI.selOpDescription, GUI.briefingBG, 68)
    LayoutHelpers.AtLeftIn(GUI.selOpDescription, GUI.briefingBG, 20)
    LayoutHelpers.AtRightIn(GUI.selOpDescription, GUI.briefingBG, 50)
    LayoutHelpers.AtBottomIn(GUI.selOpDescription, GUI.briefingBG, 30)

    GUI.selOpDescription.scroll = UIUtil.CreateVertScrollbarFor(GUI.selOpDescription)
    GUI.selOpDescription.scroll:Hide()

    if defaultControl then
        defaultControl:SetCheck(true)
    end
end

function Brackets(parent)
    local brackets = {}

    brackets.tl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-ul_bmp.dds'))
    brackets.tr = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-ur_bmp.dds'))
    brackets.bl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-ll_bmp.dds'))
    brackets.br = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-lr_bmp.dds'))

    brackets.tlG = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-glow-ul_bmp.dds'))
    brackets.trG = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-glow-ur_bmp.dds'))
    brackets.blG = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-glow-ll_bmp.dds'))
    brackets.brG = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brackets/bracket-glow-lr_bmp.dds'))

    LayoutHelpers.AtLeftTopIn(brackets.tl, parent, -42, -30)

    LayoutHelpers.AtRightTopIn(brackets.tr, parent, -40, -30)

    LayoutHelpers.AtLeftIn(brackets.bl, parent, -42)
    LayoutHelpers.AtBottomIn(brackets.bl, parent, -30)

    LayoutHelpers.AtRightIn(brackets.br, parent, -40)
    LayoutHelpers.AtBottomIn(brackets.br, parent, -30)

    LayoutHelpers.AtCenterIn(brackets.tlG, brackets.tl)
    LayoutHelpers.AtCenterIn(brackets.trG, brackets.tr)
    LayoutHelpers.AtCenterIn(brackets.blG, brackets.bl)
    LayoutHelpers.AtCenterIn(brackets.brG, brackets.br)

    brackets.tl.Depth:Set(function() return parent.Depth() + 5 end)
    brackets.tr.Depth:Set(function() return parent.Depth() + 5 end)
    brackets.bl.Depth:Set(function() return parent.Depth() + 5 end)
    brackets.br.Depth:Set(function() return parent.Depth() + 5 end)

    brackets.tlG.Depth:Set(function() return brackets.tl.Depth() - 1 end)
    brackets.trG.Depth:Set(function() return brackets.tr.Depth() - 1 end)
    brackets.blG.Depth:Set(function() return brackets.bl.Depth() - 1 end)
    brackets.brG.Depth:Set(function() return brackets.br.Depth() - 1 end)

    brackets.tl:DisableHitTest()
    brackets.tr:DisableHitTest()
    brackets.bl:DisableHitTest()
    brackets.br:DisableHitTest()

    brackets.tlG:DisableHitTest()
    brackets.trG:DisableHitTest()
    brackets.blG:DisableHitTest()
    brackets.brG:DisableHitTest()

    return brackets
end

function SelectOperation(opData)
    local desc = LOC(opData.desc)
    local title = LOC(opData.name) or 'no title'
    GUI.selOpTitle:SetText(title)
    if desc == '' then
        desc = 'This is where the description for this operation would go if this operation\'s operation file had one defined!'
    end
    local text = import("/lua/maui/text.lua").WrapText(desc, GUI.selOpDescription.Width(),
        function(text)
            return GUI.selOpDescription:GetStringAdvance(text)
        end)
    GUI.selOpDescription:DeleteAllItems()
    for i, v in text do
        GUI.selOpDescription:AddItem(v)
    end
    if table.getn(text) > 10 then
        GUI.selOpDescription.scroll:Show()
    else
        GUI.selOpDescription.scroll:Hide()
    end
    if opData.launchType == 'operation' then
        GUI.selectBtn.label:SetText(LOC("<LOC sel_campaign_0015>Select"))
        GUI.selectBtn.OnClick = function(self)
            GUI.parent:Destroy()
            import("/lua/ui/campaign/operationbriefing.lua").CreateUI(nil, opData.briefingData.opMap)
        end
        Tooltip.AddButtonTooltip(GUI.selectBtn, 'campaignselect_select')
    elseif opData.launchType == 'movie' then
        GUI.selectBtn.label:SetText(LOC("<LOC sel_campaign_0016>Play Movie"))
        if opData.fmvName == 'timeline' then
            GUI.selectBtn.OnClick = function(self)
                GUI.parent:Destroy()
                TimelineFMV(true)
            end
        elseif opData.fmvName == 'FMV_Credits' then
            GUI.selectBtn.OnClick = function(self)
                CreditsChooser()
            end
        else
            GUI.selectBtn.OnClick = function(self)
                GUI.parent:Destroy()
                import("/lua/ui/campaign/campaignmovies.lua").PlayCampaignMovie(
                    opData.fmvName,
                    GetFrame(0),
                    function()
                    	import("/lua/ui/campaign/selectcampaign.lua").CreateUI()
                    end,
                    opData.cueName,
                    opData.voiceName)
            end
        end
        Tooltip.AddButtonTooltip(GUI.selectBtn, 'campaignselect_movie')
    elseif opData.launchType == 'tutorial' then
        Tooltip.AddButtonTooltip(GUI.selectBtn, 'campaignselect_tutorial')
        GUI.selectBtn.label:SetText(LOC("<LOC sel_campaign_0017>Launch Tutorial"))
        GUI.selectBtn.OnClick = function(self)
            GUI.parent:Destroy()
            Prefs.SetToCurrentProfile('LoadingFaction', 1)
            LaunchSinglePlayerSession(
                import("/lua/singleplayerlaunch.lua").SetupCampaignSession(
                    import("/lua/ui/maputil.lua").LoadScenario('/maps/X1CA_TUT/X1CA_TUT_scenario.lua'),
                    2, nil, nil, true
                )
            )
        end
    end
end

function CreditsChooser()
    local bg = Bitmap(GUI.parent)
    bg.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    bg:SetSolidColor('aa000000')
    LayoutHelpers.FillParent(bg, GUI.parent)

    local panel = Bitmap(bg, UIUtil.UIFile('/scx_menu/game-select-faction-panel/panel_bmp.dds'))
    LayoutHelpers.AtCenterIn(panel, GUI.parent)

    local title = UIUtil.CreateText(panel, LOC('<LOC sel_campaign_0025>Choose Your Faction'), 16)
    LayoutHelpers.AtHorizontalCenterIn(title, panel)
    LayoutHelpers.AtTopIn(title, panel, 30)

    local lastBtn = false
    for i, v in factionData do
        local index = i
        local button = Button(panel, UIUtil.UIFile(v.icon..'_btn_up.dds'),
            UIUtil.UIFile(v.icon..'_btn_sel.dds'),
            UIUtil.UIFile(v.icon..'_btn_over.dds'),
            UIUtil.UIFile(v.icon..'_btn_dis.dds'))
        if not lastBtn then
            LayoutHelpers.AtRightIn(button, panel, 44)
            LayoutHelpers.AtTopIn(button, panel, 70)
        else
            LayoutHelpers.LeftOf(button, lastBtn, 6)
        end
        lastBtn = button
        button.faction = v.key
        button.cue = v.sound
        button.OnRolloverEvent = function(self, event)
            if event == 'enter' then
                PlaySound(Sound({Bank = 'Interface', Cue = self.cue}))
            end
        end
        button.OnClick = function(self)
            PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Menu_MouseDown'}))
            GUI.parent:Destroy()
            import("/lua/ui/campaign/campaignmovies.lua").PlayCampaignMovie(
                factionCredits[self.faction].fmv,
                GetFrame(0),
                function()
                	import("/lua/ui/campaign/selectcampaign.lua").CreateUI()
                end,
                factionCredits[self.faction].cue,
                factionCredits[self.faction].voice)
        end
        if not creditsAvailable[button.faction] then
            button:Disable()
        end
    end

    import("/lua/ui/uimain.lua").SetEscapeHandler(function()
        bg:Destroy()
        import("/lua/ui/uimain.lua").SetEscapeHandler(function()
            GUI.parent:Destroy()
            import("/lua/ui/menus/main.lua").CreateUI()
        end)
    end)
end

function DisplaySubtitles(textControl,captions)
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

function TimelineFMV(toOpSelect)
    local parent = GetFrame(0)
    local nisBG = Bitmap(parent)
    nisBG:SetSolidColor('FF000000')
    LayoutHelpers.FillParent(nisBG, parent)
    nisBG.Depth:Set(99998)
    local nis = Movie(parent, "/movies/timeline.sfd", Sound({Cue = 'X_Timeline', Bank = 'FMV_BG'}))
    nis.Depth:Set(99999)
    LayoutHelpers.FillParentPreserveAspectRatio(nis, parent)

    local textArea = ItemList(parent)
    textArea:SetFont(UIUtil.bodyFont, 13)

    local height = 6 * textArea:GetRowHeight()
    textArea.Height:Set( height )
    textArea.Top:Set( function() return nis.Bottom() end )
    textArea.Width:Set( function() return nis.Width() / 2 end )
    LayoutHelpers.AtHorizontalCenterIn(textArea,parent)

    textArea:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor,  UIUtil.highlightColor)
    textArea.Depth:Set(100000)

    local strings = import("/lua/ui/game/fmv_timeline.lua").timeline_captions
    AddInputCapture(nis)

    local loading = true
    local subtitleThread = nil

    nis.OnLoaded = function(self)
        GetCursor():Hide()
        nis:Play()
        if Prefs.GetOption('subtitles') then
            DisplaySubtitles(textArea, strings)
        end
        loading = false
    end

    function DoExit(onFMVFinished)
        nis:Stop()
        GetCursor():Show()
        if subtitleThread then
            KillThread(subtitleThread)
            subtitleThread = false
        end
        nisBG:Destroy()
        RemoveInputCapture(nis)
        nis:Destroy()
        if textArea then
            textArea:Destroy()
        end
        if toOpSelect then
            CreateUI()
        else
            local opData = import('/maps/X1CA_001/X1CA_001_operation.lua').operationData
            import("/lua/ui/campaign/operationbriefing.lua").CreateUI('X1CA_001', opData)
        end
    end

    nis.OnFinished = function(self)
        DoExit(true)
    end

    nis.HandleEvent = function(self, event)
        if loading then
            return false
        end
        -- cancel movie playback on mouse click or key hit
        if event.Type == "ButtonPress" or event.Type == "KeyDown" then
            if event.KeyCode == UIUtil.VK_ESCAPE or event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == UIUtil.VK_SPACE or event.KeyCode == 1  or event.KeyCode == 3 then
            else
                return true
            end
            DoExit()
            return true
        end
    end
end

-- kept for mod backwards compatibility
local PlayCampaignMovie = import("/lua/ui/campaign/campaignmovies.lua").PlayCampaignMovie