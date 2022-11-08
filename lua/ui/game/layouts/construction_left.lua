local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Grid = import("/lua/maui/grid.lua").Grid
local Button = import("/lua/maui/button.lua").Button
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox


function SetLayout()
    local textures = {
        midBtn = {
            up = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/mid_btn_up.dds'),
            down = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/mid_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/mid_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/mid_btn_dis.dds')
        },
        minBtn = {
            up = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/top_btn_up.dds'),
            down = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/top_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/top_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/top_btn_dis.dds')
        },
        maxBtn = {
            up = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/bottom_btn_up.dds'),
            down = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/bottom_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/bottom_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/bottom_btn_dis.dds')
        },
        minIcon = {
            on = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/up_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/up_off.dds')
        },
        maxIcon = {
            on = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/down_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/down_off.dds')
        },
        pageMinIcon = {
            on = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/home_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/home_off.dds')
        },
        pageMaxIcon = {
            on = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/end_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_nav_horiz_btn/end_off.dds')
        }
    }
    local controls = import("/lua/ui/game/construction.lua").controls
    local ordersControl = import("/lua/ui/game/construction.lua").ordersControl
    local controlClusterGroup = import("/lua/ui/game/construction.lua").controlClusterGroup
    controls.constructionGroup.Left:Set(controlClusterGroup.Left)
    LayoutHelpers.AtBottomIn(controls.constructionGroup, controlClusterGroup, 5)
    if ordersControl then
        LayoutHelpers.AnchorToBottom(controls.constructionGroup, ordersControl, 2)
    else
        LayoutHelpers.AtTopIn(controls.constructionGroup, controlClusterGroup, 2)
    end
    controls.constructionGroup.Right:Set(controlClusterGroup.Right)

    controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/construct-panel_bmp_t.dds'))
    LayoutHelpers.AtTopIn(controls.minBG, controls.constructionGroup, 36)
    LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 21)
    LayoutHelpers.ResetRight(controls.minBG)
    LayoutHelpers.ResetBottom(controls.minBG)

    controls.leftBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_t.dds'))
    controls.leftBracketMin.Left:Set(controls.constructionGroup.Left)
    LayoutHelpers.AtTopIn(controls.leftBracketMin, controls.constructionGroup, 1)

    controls.leftBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))
    controls.leftBracketMax.Left:Set(controls.constructionGroup.Left)
    LayoutHelpers.AtBottomIn(controls.leftBracketMax, controls.constructionGroup, -4)

    controls.leftBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.leftBracketMid, controls.constructionGroup, 7)
    controls.leftBracketMid.Bottom:Set(controls.leftBracketMax.Top)
    controls.leftBracketMid.Top:Set(controls.leftBracketMin.Bottom)

    controls.rightBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMin, controls.minBG, -11)
    LayoutHelpers.AtTopIn(controls.rightBracketMin, controls.constructionGroup, 6)

    controls.rightBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMax, controls.minBG, -11)
    LayoutHelpers.AtBottomIn(controls.rightBracketMax, controls.constructionGroup, -1)

    controls.rightBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMid, controls.minBG, -11)
    controls.rightBracketMid.Bottom:Set(controls.rightBracketMax.Top)
    controls.rightBracketMid.Top:Set(controls.rightBracketMin.Bottom)

    controls.maxBG:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/construct-panel_bmp_b.dds'))
    LayoutHelpers.AtBottomIn(controls.maxBG, controls.constructionGroup, 1)
    LayoutHelpers.AtLeftIn(controls.maxBG, controls.minBG)
    LayoutHelpers.ResetRight(controls.maxBG)
    LayoutHelpers.ResetTop(controls.maxBG)

    if controls.midBG1 then
        controls.midBG1:Destroy()
        controls.midBG1 = false
    end
    if controls.midBG2 then
        controls.midBG2:Destroy()
        controls.midBG2 = false
    end

    controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/construct-panel_bmp_m.dds'))
    controls.midBG3.Left:Set(controls.minBG.Left)
    controls.midBG3.Top:Set(controls.minBG.Bottom)
    controls.midBG3.Bottom:Set(controls.maxBG.Top)
    LayoutHelpers.SetWidth(controls.midBG3, controls.midBG3.BitmapWidth())
    --controls.midBG3:SetTiled(true) -- TODO: Now it breaks if the layout changes left to bottom, but stable as long as it doesnt change.
    LayoutHelpers.ResetRight(controls.midBG3)
    LayoutHelpers.ResetHeight(controls.midBG3)

    LayoutHelpers.AtTopIn(controls.choices, controls.constructionGroup, 100)
    LayoutHelpers.AtBottomIn(controls.choices, controls.constructionGroup, 38)
    LayoutHelpers.AtLeftIn(controls.choices, controls.minBG, 10)
    LayoutHelpers.SetWidth(controls.choices, 56)
    controls.choices:SetToVertical(true)
    LayoutHelpers.ResetHeight(controls.choices)
    LayoutHelpers.ResetRight(controls.choices)

    controls.choicesBGMin:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_t.dds'))
    LayoutHelpers.AtLeftTopIn(controls.choicesBGMin, controls.choices, 1, -30)
    controls.choicesBGMax:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_b.dds'))
    LayoutHelpers.AtLeftIn(controls.choicesBGMax, controls.choices)
    LayoutHelpers.AtBottomIn(controls.choicesBGMax, controls.choices, -30)
    LayoutHelpers.ResetTop(controls.choicesBGMax)
    LayoutHelpers.ResetRight(controls.choicesBGMax)
    controls.choicesBGMid:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.choicesBGMid, controls.choices)
    controls.choicesBGMid.Top:Set(controls.choicesBGMin.Bottom)
    controls.choicesBGMid.Bottom:Set(controls.choicesBGMax.Top)
    LayoutHelpers.ResetRight(controls.choicesBGMid)

    controls.choicesBGMax.Depth:Set(function() return controls.choices.Depth() - 2 end)
    controls.choicesBGMid.Depth:Set(function() return controls.choices.Depth() - 2 end)
    controls.choicesBGMin.Depth:Set(function() return controls.choices.Depth() - 2 end)

    controls.scrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.scrollMin:SetTexture(textures.midBtn.up)
    LayoutHelpers.Above(controls.scrollMin, controls.choices, 2)
    LayoutHelpers.AtLeftIn(controls.scrollMin, controls.choices, -1)
    LayoutHelpers.ResetRight(controls.scrollMin)
    LayoutHelpers.ResetTop(controls.scrollMin)

    controls.scrollMinIcon:SetTexture(textures.minIcon.on)
    LayoutHelpers.AtCenterIn(controls.scrollMinIcon, controls.scrollMin)
    controls.scrollMinIcon:DisableHitTest()
    controls.scrollMin.OnDisable = function(self)
        controls.scrollMinIcon:SetTexture(textures.minIcon.off)
        Button.OnDisable(self)
    end
    controls.scrollMin.OnEnable = function(self)
        controls.scrollMinIcon:SetTexture(textures.minIcon.on)
        Button.OnEnable(self)
    end

    controls.scrollMax:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.scrollMax:SetTexture(textures.midBtn.up)
    LayoutHelpers.Above(controls.scrollMax, controls.pageMax, 1)
    LayoutHelpers.ResetRight(controls.scrollMax)
    LayoutHelpers.ResetTop(controls.scrollMax)

    controls.scrollMaxIcon:SetTexture(textures.maxIcon.on)
    LayoutHelpers.AtCenterIn(controls.scrollMaxIcon, controls.scrollMax)
    controls.scrollMaxIcon:DisableHitTest()
    controls.scrollMax.OnDisable = function(self)
        controls.scrollMaxIcon:SetTexture(textures.maxIcon.off)
        Button.OnDisable(self)
    end
    controls.scrollMax.OnEnable = function(self)
        controls.scrollMaxIcon:SetTexture(textures.maxIcon.on)
        Button.OnEnable(self)
    end

    controls.pageMin:SetNewTextures(textures.minBtn.up, textures.minBtn.down, textures.minBtn.over, textures.minBtn.dis)
    controls.pageMin:SetTexture(textures.minBtn.up)
    LayoutHelpers.Above(controls.pageMin, controls.scrollMin, 1)
    LayoutHelpers.ResetRight(controls.pageMin)
    LayoutHelpers.ResetTop(controls.pageMin)

    controls.pageMinIcon:SetTexture(textures.pageMinIcon.on)
    LayoutHelpers.AtCenterIn(controls.pageMinIcon, controls.pageMin)
    controls.pageMinIcon:DisableHitTest()
    controls.pageMin.OnDisable = function(self)
        controls.pageMinIcon:SetTexture(textures.pageMinIcon.off)
        Button.OnDisable(self)
    end
    controls.pageMin.OnEnable = function(self)
        controls.pageMinIcon:SetTexture(textures.pageMinIcon.on)
        Button.OnEnable(self)
    end

    controls.pageMax:SetNewTextures(textures.maxBtn.up, textures.maxBtn.down, textures.maxBtn.over, textures.maxBtn.dis)
    controls.pageMax:SetTexture(textures.maxBtn.up)
    LayoutHelpers.AtBottomIn(controls.pageMax, controls.choicesBGMax, -1)
    LayoutHelpers.AtLeftIn(controls.pageMax, controls.choicesBGMax, -1)
    LayoutHelpers.ResetRight(controls.pageMax)
    LayoutHelpers.ResetTop(controls.pageMax)


    controls.pageMaxIcon:SetTexture(textures.pageMaxIcon.on)
    LayoutHelpers.AtCenterIn(controls.pageMaxIcon, controls.pageMax)
    controls.pageMaxIcon:DisableHitTest()
    controls.pageMax.OnDisable = function(self)
        controls.pageMaxIcon:SetTexture(textures.pageMaxIcon.off)
        Button.OnDisable(self)
    end
    controls.pageMax.OnEnable = function(self)
        controls.pageMaxIcon:SetTexture(textures.pageMaxIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryChoices.Top:Set(controls.choices.Top)
    controls.secondaryChoices.Bottom:Set(controls.choices.Bottom)
    LayoutHelpers.AnchorToRight(controls.secondaryChoices, controls.choices, 4)
    LayoutHelpers.AnchorToLeft(controls.secondaryChoices, controls.secondaryChoices, -56)
    controls.secondaryChoices:SetToVertical(true)

    controls.secondaryChoicesBGMin:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_t.dds'))
    LayoutHelpers.AtLeftTopIn(controls.secondaryChoicesBGMin, controls.secondaryChoices, 1, -30)
    controls.secondaryChoicesBGMax:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_b.dds'))
    LayoutHelpers.AtLeftIn(controls.secondaryChoicesBGMax, controls.secondaryChoices)
    LayoutHelpers.AtBottomIn(controls.secondaryChoicesBGMax, controls.secondaryChoices, -30)
    LayoutHelpers.ResetRight(controls.secondaryChoicesBGMax)
    LayoutHelpers.ResetTop(controls.secondaryChoicesBGMax)
    controls.secondaryChoicesBGMid:SetTexture(UIUtil.UIFile('/game/construct-panel_vert/que-panel_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.secondaryChoicesBGMid, controls.secondaryChoices)
    controls.secondaryChoicesBGMid.Top:Set(controls.secondaryChoicesBGMin.Bottom)
    controls.secondaryChoicesBGMid.Bottom:Set(controls.secondaryChoicesBGMax.Top)
    LayoutHelpers.ResetRight(controls.secondaryChoicesBGMid)

    controls.secondaryChoicesBGMin.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)
    controls.secondaryChoicesBGMax.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)
    controls.secondaryChoicesBGMid.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)

    LayoutHelpers.AtLeftIn(controls.secondaryProgress, controls.secondaryChoices, 8)
    LayoutHelpers.AtTopIn(controls.secondaryProgress, controls.secondaryChoices, 42)
    LayoutHelpers.ResetBottom(controls.secondaryProgress)
    controls.secondaryProgress.Depth:Set(function() return controls.secondaryChoices.Depth() + 5 end)
    LayoutHelpers.SetDimensions(controls.secondaryProgress, 40, 4)

    controls.secondaryScrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.secondaryScrollMin:SetTexture(textures.midBtn.up)
    LayoutHelpers.Above(controls.secondaryScrollMin, controls.secondaryChoices, 2)
    LayoutHelpers.AtLeftIn(controls.secondaryScrollMin, controls.secondaryChoices, -1)
    LayoutHelpers.ResetRight(controls.secondaryScrollMin)
    LayoutHelpers.ResetTop(controls.secondaryScrollMin)

    controls.secondaryScrollMinIcon:SetTexture(textures.minIcon.on)
    LayoutHelpers.AtCenterIn(controls.secondaryScrollMinIcon, controls.secondaryScrollMin)
    controls.secondaryScrollMinIcon:DisableHitTest()
    controls.secondaryScrollMin.OnDisable = function(self)
        controls.secondaryScrollMinIcon:SetTexture(textures.minIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryScrollMin.OnEnable = function(self)
        controls.secondaryScrollMinIcon:SetTexture(textures.minIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryScrollMax:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.secondaryScrollMax:SetTexture(textures.midBtn.up)
    LayoutHelpers.Above(controls.secondaryScrollMax, controls.secondaryPageMax, 1)
    LayoutHelpers.ResetRight(controls.secondaryScrollMax)
    LayoutHelpers.ResetTop(controls.secondaryScrollMax)

    controls.secondaryScrollMaxIcon:SetTexture(textures.maxIcon.on)
    LayoutHelpers.AtCenterIn(controls.secondaryScrollMaxIcon, controls.secondaryScrollMax)
    controls.secondaryScrollMaxIcon:DisableHitTest()
    controls.secondaryScrollMax.OnDisable = function(self)
        controls.secondaryScrollMaxIcon:SetTexture(textures.maxIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryScrollMax.OnEnable = function(self)
        controls.secondaryScrollMaxIcon:SetTexture(textures.maxIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryPageMin:SetNewTextures(textures.minBtn.up, textures.minBtn.down, textures.minBtn.over, textures.minBtn.dis)
    controls.secondaryPageMin:SetTexture(textures.minBtn.up)
    LayoutHelpers.Above(controls.secondaryPageMin, controls.secondaryScrollMin, 1)
    LayoutHelpers.ResetRight(controls.secondaryPageMin)
    LayoutHelpers.ResetTop(controls.secondaryPageMin)

    controls.secondaryPageMinIcon:SetTexture(textures.pageMinIcon.on)
    LayoutHelpers.AtCenterIn(controls.secondaryPageMinIcon, controls.secondaryPageMin)
    controls.secondaryPageMinIcon:DisableHitTest()
    controls.secondaryPageMin.OnDisable = function(self)
        controls.secondaryPageMinIcon:SetTexture(textures.pageMinIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryPageMin.OnEnable = function(self)
        controls.secondaryPageMinIcon:SetTexture(textures.pageMinIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryPageMax:SetNewTextures(textures.maxBtn.up, textures.maxBtn.down, textures.maxBtn.over, textures.maxBtn.dis)
    controls.secondaryPageMax:SetTexture(textures.maxBtn.up)
    LayoutHelpers.AtBottomIn(controls.secondaryPageMax, controls.secondaryChoicesBGMax, -1)
    LayoutHelpers.AtLeftIn(controls.secondaryPageMax, controls.secondaryChoicesBGMax, -1)
    LayoutHelpers.ResetRight(controls.secondaryPageMax)
    LayoutHelpers.ResetTop(controls.secondaryPageMax)

    controls.secondaryPageMaxIcon:SetTexture(textures.pageMaxIcon.on)
    LayoutHelpers.AtCenterIn(controls.secondaryPageMaxIcon, controls.secondaryPageMax)
    controls.secondaryPageMaxIcon:DisableHitTest()
    controls.secondaryPageMax.OnDisable = function(self)
        controls.secondaryPageMaxIcon:SetTexture(textures.pageMaxIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryPageMax.OnEnable = function(self)
        controls.secondaryPageMaxIcon:SetTexture(textures.pageMaxIcon.on)
        Button.OnEnable(self)
    end

    controls.extraBtn1:SetNewTextures(UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_up.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_selected.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_over.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_over.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_dis.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_dis.dds'))
    controls.extraBtn2:SetNewTextures(UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_up.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_selected.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_over.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_over.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_dis.dds'),
        UIUtil.UIFile('/game/construct-sm_horiz_btn/que_btn_dis.dds'))
    LayoutHelpers.AtLeftTopIn(controls.extraBtn1, controls.minBG, 9, 5)
    LayoutHelpers.RightOf(controls.extraBtn2, controls.extraBtn1, 3)

    controls.constructionGroup:DisableHitTest()
    LayoutTabs(import("/lua/ui/game/construction.lua").controls)
    controls.constructionGroup:Hide()
end

function LayoutTabs(controls)
    local prevControl = false

    local tabFiles = {
        construction = '/game/construct-tab_top_btn/top_tab_btn_',
        selection = '/game/construct-tab_top_btn/mid_tab_btn_',
        enhancement = '/game/construct-tab_top_btn/bot_tab_btn_',
    }
    local techFiles = {
        t1 = '/game/construct-tech_btn/t1_btn_',
        t2 = '/game/construct-tech_btn/t2_btn_',
        t3 = '/game/construct-tech_btn/t3_btn_',
        t4 = '/game/construct-tech_btn/t4_btn_',
        templates = '/game/construct-tech_btn/template_btn_',
        LCH = '/game/construct-tech_btn/left_upgrade_btn_',
        RCH = '/game/construct-tech_btn/r_upgrade_btn_',
        Back = '/game/construct-tech_btn/m_upgrade_btn_',
    }

    local function GetTabTextures(id)
        if tabFiles[id] then
            local pre = tabFiles[id]
            return UIUtil.UIFile(pre..'up_bmp.dds'), UIUtil.UIFile(pre..'sel_bmp.dds'),
                UIUtil.UIFile(pre..'over_bmp.dds'), UIUtil.UIFile(pre..'down_bmp.dds'),
                UIUtil.UIFile(pre..'dis_bmp.dds'), UIUtil.UIFile(pre..'dis_bmp.dds')
        elseif techFiles[id] then
            local pre = techFiles[id]
            return UIUtil.UIFile(pre..'up.dds'), UIUtil.UIFile(pre..'selected.dds'),
                UIUtil.UIFile(pre..'over.dds'), UIUtil.UIFile(pre..'down.dds'),
                UIUtil.UIFile(pre..'dis.dds'), UIUtil.UIFile(pre..'dis.dds')
        end
    end

    local function SetupTab(control)
        control:SetNewTextures(GetTabTextures(control.ID))
        control:UseAlphaHitTest(false)

        control.OnDisable = function(self)
            self.disabledGroup:Enable()
            Checkbox.OnDisable(self)
        end

        LayoutHelpers.SetDimensions(control.disabledGroup, 40, 25)
        LayoutHelpers.AtCenterIn(control.disabledGroup, control)

        control.OnEnable = function(self)
            self.disabledGroup:Disable()
            Checkbox.OnEnable(self)
        end
    end

    if not table.empty(controls.tabs) then
        for id, control in controls.tabs do
            SetupTab(control)

            if not prevControl then
                LayoutHelpers.AtLeftTopIn(control, controls.minBG, 134, 60)
            else
                local offset = 0
                LayoutHelpers.Below(control, prevControl, offset)
            end

            prevControl = control
        end
    end

    SetupTab(controls.constructionTab)
    LayoutHelpers.AtLeftTopIn(controls.constructionTab, controls.constructionGroup, 20, 7)
    SetupTab(controls.selectionTab)
    LayoutHelpers.RightOf(controls.selectionTab, controls.constructionTab, 0)
    SetupTab(controls.enhancementTab)
    LayoutHelpers.RightOf(controls.enhancementTab, controls.selectionTab, 0)
end

function OnTabChangeLayout(type)
    local controls = import("/lua/ui/game/construction.lua").controls
    if type == 'construction' or type == 'templates' then
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/infinite_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/infinite_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end

    elseif type == 'selection' then
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/template_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
    else
        controls.extraBtn1.icon:Hide()
        controls.extraBtn1.icon:SetSolidColor('00000000')
    end
end

function OnSelection(empty)
    local controls = import("/lua/ui/game/construction.lua").controls
    if empty then
        if not controls.constructionGroup:IsHidden() then
            controls.constructionGroup:Hide()
        end
    else
        if controls.constructionGroup:IsHidden() then
            controls.constructionGroup:Show()
        end
    end
end