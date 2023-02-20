local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Grid = import("/lua/maui/grid.lua").Grid
local Button = import("/lua/maui/button.lua").Button
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox


function SetLayout()
    local textures = {
        midBtn = {
            up = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_up.dds'),
            selected = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_selected.dds'),
            down = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_btn/mid_btn_dis.dds')
        },
        minBtn = {
            up = UIUtil.UIFile('/game/construct-sm_btn/left_btn_up.dds'),
            down = UIUtil.UIFile('/game/construct-sm_btn/left_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_btn/left_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_btn/left_btn_dis.dds')
        },
        maxBtn = {
            up = UIUtil.UIFile('/game/construct-sm_btn/right_btn_up.dds'),
            down = UIUtil.UIFile('/game/construct-sm_btn/right_btn_over.dds'),
            over = UIUtil.UIFile('/game/construct-sm_btn/right_btn_over.dds'),
            dis = UIUtil.UIFile('/game/construct-sm_btn/right_btn_dis.dds')
        },
        minIcon = {
            on = UIUtil.UIFile('/game/construct-sm_btn/back_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_btn/back_off.dds')
        },
        maxIcon = {
            on = UIUtil.UIFile('/game/construct-sm_btn/forward_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_btn/forward_off.dds')
        },
        pageMinIcon = {
            on = UIUtil.UIFile('/game/construct-sm_btn/rewind_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_btn/rewind_off.dds')
        },
        pageMaxIcon = {
            on = UIUtil.UIFile('/game/construct-sm_btn/fforward_on.dds'),
            off = UIUtil.UIFile('/game/construct-sm_btn/fforward_off.dds')
        }
    }
    local controls = import("/lua/ui/game/construction.lua").controls
    local ordersControl = import("/lua/ui/game/construction.lua").ordersControl
    local controlClusterGroup = import("/lua/ui/game/construction.lua").controlClusterGroup
    LayoutHelpers.AtTopIn(controls.constructionGroup, controlClusterGroup, 12)
    controls.constructionGroup.Bottom:Set(controlClusterGroup.Bottom)
    if ordersControl then
        LayoutHelpers.AnchorToLeft(controls.constructionGroup, ordersControl, 14)
    else
        controls.constructionGroup.Right:Set(controlClusterGroup.Right)
    end
    LayoutHelpers.AtLeftIn(controls.constructionGroup, controlClusterGroup, 8)

    controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
    LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 4)
    LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 67)
    LayoutHelpers.ResetRight(controls.minBG)
    LayoutHelpers.ResetTop(controls.minBG)
    LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight())
    --controls.minBG.Width:Set(controls.minBG.BitmapWidth)
    --controls.minBG.Height:Set(controls.minBG.BitmapHeight)

    controls.leftBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_t.dds'))
    LayoutHelpers.AtLeftIn(controls.leftBracketMin, controls.constructionGroup, -8)
    LayoutHelpers.AtTopIn(controls.leftBracketMin, controls.constructionGroup, 17)

    controls.leftBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))
    controls.leftBracketMax.Left:Set(controls.leftBracketMin.Left)
    LayoutHelpers.AtBottomIn(controls.leftBracketMax, controls.constructionGroup)

    controls.leftBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    LayoutHelpers.AtLeftIn(controls.leftBracketMid, controls.leftBracketMin, 7)
    controls.leftBracketMid.Bottom:Set(controls.leftBracketMax.Top)
    controls.leftBracketMid.Top:Set(controls.leftBracketMin.Bottom)

    controls.rightBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMin, controls.maxBG, -10)
    LayoutHelpers.AtTopIn(controls.rightBracketMin, controls.maxBG, -1)

    controls.rightBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMax, controls.maxBG, -10)
    LayoutHelpers.AtBottomIn(controls.rightBracketMax, controls.maxBG, -2)

    controls.rightBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    LayoutHelpers.AtRightIn(controls.rightBracketMid, controls.maxBG, -10)
    controls.rightBracketMid.Bottom:Set(controls.rightBracketMax.Top)
    controls.rightBracketMid.Top:Set(controls.rightBracketMin.Bottom)

    controls.maxBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_r.dds'))
    LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 1)
    LayoutHelpers.AtRightIn(controls.maxBG, controls.constructionGroup, 2)
    LayoutHelpers.ResetLeft(controls.maxBG)
    LayoutHelpers.ResetTop(controls.maxBG)

    if not controls.midBG1 then
        controls.midBG1 = Bitmap(controls.constructionGroup)
    end
    controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
    controls.midBG1.Left:Set(controls.minBG.Right)
    controls.midBG1.Bottom:Set(controls.minBG.Bottom)
    LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight())
    --controls.midBG1.Height:Set(controls.midBG1.BitmapHeight)
    --controls.midBG1.Width:Set(controls.midBG1.BitmapWidth)
    LayoutHelpers.ResetTop(controls.midBG1)

    if not controls.midBG2 then
        controls.midBG2 = Bitmap(controls.constructionGroup)
    end
    controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
    controls.midBG2.Left:Set(controls.midBG1.Right)
    controls.midBG2.Bottom:Set(controls.minBG.Bottom)
    LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight())
    --controls.midBG2.Height:Set(controls.midBG2.BitmapHeight)
    --controls.midBG2.Width:Set(controls.midBG2.BitmapWidth)
    LayoutHelpers.ResetTop(controls.midBG2)

    controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'))
    controls.midBG3.Left:Set(controls.midBG2.Right)
    controls.midBG3.Right:Set(controls.maxBG.Left)
    controls.midBG3.Bottom:Set(controls.maxBG.Bottom)
    --controls.midBG3:SetTiled(true)
    LayoutHelpers.SetHeight(controls.midBG3, controls.midBG3.BitmapHeight())
    --controls.midBG3.Height:Set(controls.midBG3.BitmapHeight)
    LayoutHelpers.ResetWidth(controls.midBG3)
    LayoutHelpers.ResetTop(controls.midBG3)
    LayoutHelpers.SetHeight(controls.midBG3, controls.midBG3.BitmapHeight())
    --controls.midBG3.Height:Set(controls.midBG3.BitmapHeight)

    LayoutHelpers.AtTopIn(controls.choices, controls.minBG, 5)
    LayoutHelpers.SetHeight(controls.choices, 50)
    controls.choices:SetToVertical(false)
    LayoutHelpers.AtLeftIn(controls.choices, controls.minBG, 26)
    LayoutHelpers.AtRightIn(controls.choices, controls.maxBG, 25)
    LayoutHelpers.ResetWidth(controls.choices)
    LayoutHelpers.ResetBottom(controls.choices)

    controls.choicesBGMin:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_l.dds'))
    LayoutHelpers.AtLeftTopIn(controls.choicesBGMin, controls.choices, -46)
    controls.choicesBGMax:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_r.dds'))
    LayoutHelpers.AtRightTopIn(controls.choicesBGMax, controls.choices, -43)
    LayoutHelpers.ResetLeft(controls.choicesBGMax)
    LayoutHelpers.ResetBottom(controls.choicesBGMax)
    controls.choicesBGMid:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_m.dds'))
    LayoutHelpers.AtTopIn(controls.choicesBGMid, controls.choices)
    LayoutHelpers.ResetBottom(controls.choicesBGMid)
    controls.choicesBGMid.Left:Set(controls.choicesBGMin.Right)
    controls.choicesBGMid.Right:Set(controls.choicesBGMax.Left)

    controls.choicesBGMax.Depth:Set(function() return controls.choices.Depth() - 1 end)
    controls.choicesBGMid.Depth:Set(function() return controls.choices.Depth() - 1 end)
    controls.choicesBGMin.Depth:Set(function() return controls.choices.Depth() - 1 end)

    controls.scrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.scrollMin:SetTexture(textures.midBtn.up)
    LayoutHelpers.AnchorToLeft(controls.scrollMin, controls.choices, 4)
    LayoutHelpers.AtVerticalCenterIn(controls.scrollMin, controls.choices)
    LayoutHelpers.ResetLeft(controls.scrollMin)
    LayoutHelpers.ResetBottom(controls.scrollMin)
    LayoutHelpers.SetDimensions(controls.scrollMin, controls.scrollMin.BitmapWidth(), controls.scrollMin.BitmapHeight())
    --controls.scrollMin.Height:Set(controls.scrollMin.BitmapHeight)
    --controls.scrollMin.Width:Set(controls.scrollMin.BitmapWidth)

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
    controls.scrollMax.Left:Set(controls.choices.Right)
    LayoutHelpers.AtVerticalCenterIn(controls.scrollMax, controls.choices)
    LayoutHelpers.ResetRight(controls.scrollMax)
    LayoutHelpers.ResetBottom(controls.scrollMax)

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
    controls.pageMin.Right:Set(controls.scrollMin.Left)
    LayoutHelpers.AtVerticalCenterIn(controls.pageMin, controls.choices)
    LayoutHelpers.ResetLeft(controls.pageMin)
    LayoutHelpers.ResetBottom(controls.pageMin)

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
    controls.pageMax.Left:Set(controls.scrollMax.Right)
    LayoutHelpers.AtVerticalCenterIn(controls.pageMax, controls.choices)
    LayoutHelpers.ResetRight(controls.pageMax)
    LayoutHelpers.ResetBottom(controls.pageMax)

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

    LayoutHelpers.AnchorToBottom(controls.secondaryChoices, controls.choices, 1)
    LayoutHelpers.AnchorToTop(controls.secondaryChoices, controls.secondaryChoices, -50)
    controls.secondaryChoices.Left:Set(controls.choices.Left)
    controls.secondaryChoices.Right:Set(controls.choices.Right)
    controls.secondaryChoices:SetToVertical(false)

    controls.secondaryChoicesBGMin:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_l.dds'))
    LayoutHelpers.AtLeftTopIn(controls.secondaryChoicesBGMin, controls.secondaryChoices, -46)
    controls.secondaryChoicesBGMax:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_r.dds'))
    LayoutHelpers.AtRightTopIn(controls.secondaryChoicesBGMax, controls.secondaryChoices, -43)
    LayoutHelpers.ResetLeft(controls.secondaryChoicesBGMax)
    LayoutHelpers.ResetBottom(controls.secondaryChoicesBGMax)
    controls.secondaryChoicesBGMid:SetTexture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_m.dds'))
    LayoutHelpers.AtTopIn(controls.secondaryChoicesBGMid, controls.secondaryChoices)
    controls.secondaryChoicesBGMid.Left:Set(controls.secondaryChoicesBGMin.Right)
    controls.secondaryChoicesBGMid.Right:Set(controls.secondaryChoicesBGMax.Left)
    LayoutHelpers.ResetBottom(controls.secondaryChoicesBGMid)

    controls.secondaryChoicesBGMin.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)
    controls.secondaryChoicesBGMax.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)
    controls.secondaryChoicesBGMid.Depth:Set(function() return controls.secondaryChoices.Depth() - 1 end)

    LayoutHelpers.AtLeftIn(controls.secondaryProgress, controls.secondaryChoices, 5)
    LayoutHelpers.AtTopIn(controls.secondaryProgress, controls.secondaryChoices, 43)
    controls.secondaryProgress.Depth:Set(function() return controls.secondaryChoices.Depth() + 5 end)
    LayoutHelpers.SetDimensions(controls.secondaryProgress, 40, 4)

    controls.secondaryScrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    controls.secondaryScrollMin:SetTexture(textures.midBtn.up)
    LayoutHelpers.AnchorToLeft(controls.secondaryScrollMin, controls.secondaryChoices, 4)
    LayoutHelpers.AtVerticalCenterIn(controls.secondaryScrollMin, controls.secondaryChoices)
    LayoutHelpers.ResetLeft(controls.secondaryScrollMin)
    LayoutHelpers.ResetBottom(controls.secondaryScrollMin)

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
    controls.secondaryScrollMax.Left:Set(controls.secondaryChoices.Right)
    LayoutHelpers.AtVerticalCenterIn(controls.secondaryScrollMax, controls.secondaryChoices)
    LayoutHelpers.ResetRight(controls.secondaryScrollMax)
    LayoutHelpers.ResetBottom(controls.secondaryScrollMax)

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
    controls.secondaryPageMin.Right:Set(controls.secondaryScrollMin.Left)
    LayoutHelpers.AtVerticalCenterIn(controls.secondaryPageMin, controls.secondaryChoices)
    LayoutHelpers.ResetBottom(controls.secondaryPageMin)
    LayoutHelpers.ResetLeft(controls.secondaryPageMin)

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
    controls.secondaryPageMax.Left:Set(controls.scrollMax.Right)
    LayoutHelpers.AtVerticalCenterIn(controls.secondaryPageMax, controls.secondaryChoices)
    LayoutHelpers.ResetBottom(controls.secondaryPageMax)

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

    controls.extraBtn1:SetNewTextures(textures.midBtn.up, textures.midBtn.selected, textures.midBtn.over,
        textures.midBtn.over, textures.midBtn.dis, textures.midBtn.dis)
    controls.extraBtn2:SetNewTextures(textures.midBtn.up, textures.midBtn.selected, textures.midBtn.over,
        textures.midBtn.over, textures.midBtn.dis, textures.midBtn.dis)
    LayoutHelpers.AtLeftTopIn(controls.extraBtn1, controls.minBG, 10, 31)
    LayoutHelpers.Below(controls.extraBtn2, controls.extraBtn1, 1)

    controls.constructionGroup:DisableHitTest()
    LayoutTabs(import("/lua/ui/game/construction.lua").controls)
    controls.constructionGroup:Hide()
end

function LayoutTabs(controls)
    local prevControl = false

    local tabFiles = {
        construction = '/game/construct-tab_btn/top_tab_btn_',
        selection = '/game/construct-tab_btn/mid_tab_btn_',
        enhancement = '/game/construct-tab_btn/bot_tab_btn_',
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
                LayoutHelpers.AtLeftTopIn(control, controls.minBG, 82, 0)
            else
                local offset = 0
                LayoutHelpers.RightOf(control, prevControl, offset)
            end

            prevControl = control
        end
        controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
        controls.midBG1.Right:Set(prevControl.Right)
        controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
        controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'))
        controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
        LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO: This is an ugly hack for the problem described above
        LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
        LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
        LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
        LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 67)
        LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 1)
        LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 4)
    else
        controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_l.dds'))
        LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO
        LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
        LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
        LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
        LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 69)
        LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 0)
        LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 5)
    end

    SetupTab(controls.constructionTab)
    LayoutHelpers.AtLeftTopIn(controls.constructionTab, controls.constructionGroup, 0, 14)
    SetupTab(controls.selectionTab)
    LayoutHelpers.Below(controls.selectionTab, controls.constructionTab, -16)
    SetupTab(controls.enhancementTab)
    LayoutHelpers.Below(controls.enhancementTab, controls.selectionTab, -16)

end

function OnTabChangeLayout(type)
    local controls = import("/lua/ui/game/construction.lua").controls
    if type ~= 'selection' then
        LayoutHelpers.AtLeftIn(controls.choices, controls.minBG, 85)
        LayoutHelpers.AtRightIn(controls.choices, controls.maxBG, 49)
    end
    if type == 'construction' or type == 'templates' then
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/infinite_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/infinite_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
        LayoutHelpers.AtTopIn(controls.choices, controls.minBG, 31)
        LayoutHelpers.AtLeftTopIn(controls.extraBtn1, controls.minBG, 10, 31)
    elseif type == 'selection' then
        controls.extraBtn1.icon.OnTexture = UIUtil.UIFile('/game/construct-sm_btn/template_on.dds')
        controls.extraBtn1.icon.OffTexture = UIUtil.UIFile('/game/construct-sm_btn/template_off.dds')
        if controls.extraBtn1:IsDisabled() then
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OffTexture)
        else
            controls.extraBtn1.icon:SetTexture(controls.extraBtn1.icon.OnTexture)
        end
        LayoutHelpers.AtTopIn(controls.choices, controls.minBG, 4)
        LayoutHelpers.AtLeftTopIn(controls.extraBtn1, controls.minBG, 8, 4)
        LayoutHelpers.AtLeftIn(controls.choices, controls.minBG, 83)
        LayoutHelpers.AtRightIn(controls.choices, controls.maxBG, 49)
    else
        LayoutHelpers.AtTopIn(controls.choices, controls.minBG, 31)
        LayoutHelpers.AtLeftTopIn(controls.extraBtn1, controls.minBG, 10, 31)
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