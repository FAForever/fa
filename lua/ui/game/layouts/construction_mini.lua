local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
local Grid = import("/lua/maui/grid.lua").Grid
local Button = import("/lua/maui/button.lua").Button
local IconButton
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

    Layouter(controls.constructionGroup)
        :AtTopIn(controlClusterGroup, 12)
        :Bottom(controlClusterGroup.Bottom)
        :AtRightIn(controlClusterGroup, 18)
        :ResetLeft()
        :DisableHitTest()
    if ordersControl then
        LOG('we have orders control')
        Layouter(controls.constructionGroup):AnchorToRight(ordersControl, -6)
    else
        Layouter(controls.constructionGroup):Left(controlClusterGroup.Left)
    end
    Layouter(controls.constructionGroup):End()

    controls.choices:SetToVertical(false)
    Layouter(controls.choices)
        :AtTopIn(controls.minBG, 5)
        :Height(50)
        :AtLeftIn(controls.minBG, 26)
        :AtRightIn(controls.maxBG, 25)
        :ResetWidth()
        :ResetBottom()

    Layouter(controls.choicesBGMin)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_l.dds'))
        :AtLeftTopIn(controls.choices, -46)
        :Under(controls.choices, 1)

    Layouter(controls.choicesBGMax)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_r.dds'))
        :AtRightTopIn(controls.choices, -43)
        :ResetLeft()
        :ResetBottom()
        :Under(controls.choices, 1)

    Layouter(controls.choicesBGMid)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_m.dds'))
        :AtTopIn(controls.choices)
        :Left(controls.choicesBGMin.Right)
        :Right(controls.choicesBGMax.Left)
        :ResetBottom()
        :Under(controls.choices, 1)

    controls.scrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over,
        textures.midBtn.dis, textures.minIcon.on, textures.minIcon.off)
    Layouter(controls.scrollMin)
        :Texture(textures.midBtn.up)
        :AnchorToLeft(controls.choices, 4)
        :AtVerticalCenterIn(controls.choices)
        :ResetLeft()
        :ResetBottom()
        :Dimensions(controls.scrollMin.BitmapWidth(), controls.scrollMin.BitmapHeight())

    --Layouter(controls.scrollMinIcon)
    --    :Texture(textures.minIcon.on)
    --    :AtCenterIn(controls.scrollMin)
    --    :DisableHitTest()
    --controls.scrollMin.OnDisable = function(self)
    --    controls.scrollMinIcon:SetTexture(textures.minIcon.off)
    --    Button.OnDisable(self)
    --end
    --controls.scrollMin.OnEnable = function(self)
    --    controls.scrollMinIcon:SetTexture(textures.minIcon.on)
    --    Button.OnEnable(self)
    --end

    controls.scrollMax:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    Layouter(controls.scrollMax)
        :Texture(textures.midBtn.up)
        :Left(controls.choices.Right)
        :AtVerticalCenterIn(controls.choices)
        :ResetRight()
        :ResetBottom()

    Layouter(controls.scrollMaxIcon)
        :Texture(textures.maxIcon.on)
        :AtCenterIn(controls.scrollMax)
        :DisableHitTest()
    controls.scrollMax.OnDisable = function(self)
        controls.scrollMaxIcon:SetTexture(textures.maxIcon.off)
        Button.OnDisable(self)
    end
    controls.scrollMax.OnEnable = function(self)
        controls.scrollMaxIcon:SetTexture(textures.maxIcon.on)
        Button.OnEnable(self)
    end

    controls.pageMin:SetNewTextures(textures.minBtn.up, textures.minBtn.down, textures.minBtn.over, textures.minBtn.dis)
    Layouter(controls.pageMin)
        :Texture(textures.minBtn.up)
        :Right(controls.scrollMin.Left)
        :AtVerticalCenterIn(controls.choices)
        :ResetLeft()
        :ResetBottom()

    Layouter(controls.pageMinIcon)
        :Texture(textures.pageMinIcon.on)
        :AtCenterIn(controls.pageMin)
        :DisableHitTest()
    controls.pageMin.OnDisable = function(self)
        controls.pageMinIcon:SetTexture(textures.pageMinIcon.off)
        Button.OnDisable(self)
    end
    controls.pageMin.OnEnable = function(self)
        controls.pageMinIcon:SetTexture(textures.pageMinIcon.on)
        Button.OnEnable(self)
    end

    controls.pageMax:SetNewTextures(textures.maxBtn.up, textures.maxBtn.down, textures.maxBtn.over, textures.maxBtn.dis)
    Layouter(controls.pageMax)
        :Texture(textures.maxBtn.up)
        :Left(controls.scrollMax.Right)
        :AtVerticalCenterIn(controls.choices)
        :ResetRight()
        :ResetBottom()

    Layouter(controls.pageMaxIcon)
        :Texture(textures.pageMaxIcon.on)
        :AtCenterIn(controls.pageMax)
        :DisableHitTest()
    controls.pageMax.OnDisable = function(self)
        controls.pageMaxIcon:SetTexture(textures.pageMaxIcon.off)
        Button.OnDisable(self)
    end
    controls.pageMax.OnEnable = function(self)
        controls.pageMaxIcon:SetTexture(textures.pageMaxIcon.on)
        Button.OnEnable(self)
    end

    Layouter(controls.secondaryChoices)
        :AnchorToBottom(controls.choices, 1)
        :AnchorToTop(controls.secondaryChoices, -50)
        :Left(controls.choices.Left)
        :Right(controls.choices.Right)
    controls.secondaryChoices:SetToVertical(false)

    Layouter(controls.secondaryChoicesBGMin)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_l.dds'))
        :AtLeftTopIn(controls.secondaryChoices, -46)
        :Under(controls.secondaryChoices, 1)

    Layouter(controls.secondaryChoicesBGMax)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_r.dds'))
        :AtRightTopIn(controls.secondaryChoices, -43)
        :ResetLeft()
        :ResetBottom()
        :Under(controls.secondaryChoices, 1)

    Layouter(controls.secondaryChoicesBGMid)
        :Texture(UIUtil.UIFile('/game/construct-panel/que-panel_bmp_m.dds'))
        :AtTopIn(controls.secondaryChoices)
        :Left(controls.secondaryChoicesBGMin.Right)
        :Right(controls.secondaryChoicesBGMax.Left)
        :ResetBottom()
        :Under(controls.secondaryChoices, 1)

    Layouter(controls.secondaryProgress)
        :AtLeftIn(controls.secondaryChoices, 5)
        :AtTopIn(controls.secondaryChoices, 42)
        :Over(controls.secondaryChoices, 5)
        :Dimensions(40, 4)

    controls.secondaryScrollMin:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    Layouter(controls.secondaryScrollMin)
        :Texture(textures.midBtn.up)
        :AnchorToLeft(controls.secondaryChoices, 4)
        :AtVerticalCenterIn(controls.secondaryChoices)
        :ResetLeft()
        :ResetBottom()

    Layouter(controls.secondaryScrollMinIcon)
        :Texture(textures.minIcon.on)
        :AtCenterIn(controls.secondaryScrollMin)
        :DisableHitTest()
    controls.secondaryScrollMin.OnDisable = function(self)
        controls.secondaryScrollMinIcon:SetTexture(textures.minIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryScrollMin.OnEnable = function(self)
        controls.secondaryScrollMinIcon:SetTexture(textures.minIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryScrollMax:SetNewTextures(textures.midBtn.up, textures.midBtn.down, textures.midBtn.over, textures.midBtn.dis)
    Layouter(controls.secondaryScrollMax)
        :Texture(textures.midBtn.up)
        :Left(controls.secondaryChoices.Right)
        :AtVerticalCenterIn(controls.secondaryChoices)
        :ResetRight()
        :ResetBottom()

    Layouter(controls.secondaryScrollMaxIcon)
        :Texture(textures.maxIcon.on)
        :AtCenterIn(controls.secondaryScrollMax)
        :DisableHitTest()
    controls.secondaryScrollMax.OnDisable = function(self)
        controls.secondaryScrollMaxIcon:SetTexture(textures.maxIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryScrollMax.OnEnable = function(self)
        controls.secondaryScrollMaxIcon:SetTexture(textures.maxIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryPageMin:SetNewTextures(textures.minBtn.up, textures.minBtn.down, textures.minBtn.over, textures.minBtn.dis)
    Layouter(controls.secondaryPageMin)
        :Texture(textures.minBtn.up)
        :Right(controls.secondaryScrollMin.Left)
        :AtVerticalCenterIn(controls.secondaryChoices)
        :ResetBottom()
        :ResetLeft()

    Layouter(controls.secondaryPageMinIcon)
        :Texture(textures.pageMinIcon.on)
        :AtCenterIn(controls.secondaryPageMin)
        :DisableHitTest()
    controls.secondaryPageMin.OnDisable = function(self)
        controls.secondaryPageMinIcon:SetTexture(textures.pageMinIcon.off)
        Button.OnDisable(self)
    end
    controls.secondaryPageMin.OnEnable = function(self)
        controls.secondaryPageMinIcon:SetTexture(textures.pageMinIcon.on)
        Button.OnEnable(self)
    end

    controls.secondaryPageMax:SetNewTextures(textures.maxBtn.up, textures.maxBtn.down, textures.maxBtn.over, textures.maxBtn.dis)
    Layouter(controls.secondaryPageMax)
        :Texture(textures.maxBtn.up)
        :Left(controls.secondaryScrollMax.Right)
        :AtVerticalCenterIn(controls.secondaryChoices)
        :ResetBottom()

    Layouter(controls.secondaryPageMaxIcon)
        :Texture(textures.pageMaxIcon.on)
        :AtCenterIn(controls.secondaryPageMax)
        :DisableHitTest()
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
    Layouter(controls.extraBtn1)
        :AtLeftTopIn(controls.minBG, 10, 31)

    controls.extraBtn2:SetNewTextures(textures.midBtn.up, textures.midBtn.selected, textures.midBtn.over,
        textures.midBtn.over, textures.midBtn.dis, textures.midBtn.dis)
    Layouter(controls.extraBtn2)
        :Below(controls.extraBtn1, 1)

    LayoutTabs(import("/lua/ui/game/construction.lua").controls)
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
        --controls.constructionGroup:TechTabLayout(prevControl)
        -- controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m1.dds'))
        -- controls.midBG1.Right:Set(prevControl.Right)
        -- controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m2.dds'))
        -- controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_m3.dds'))
        -- controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_bmp_l.dds'))
        -- LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO: This is an ugly hack for the problem described above
        -- LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
        -- LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
        -- LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
        -- LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 67)
        -- LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 1)
        -- LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 4)
    else
        --controls.constructionGroup:TechTabLayout()
        -- controls.midBG1:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        -- controls.midBG2:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        -- controls.midBG3:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_m.dds'))
        -- controls.minBG:SetTexture(UIUtil.UIFile('/game/construct-panel/construct-panel_s_bmp_l.dds'))
        -- LayoutHelpers.SetDimensions(controls.minBG, controls.minBG.BitmapWidth(), controls.minBG.BitmapHeight()) -- TODO
        -- LayoutHelpers.SetDimensions(controls.midBG1, controls.midBG1.BitmapWidth(), controls.midBG1.BitmapHeight()) -- TODO
        -- LayoutHelpers.SetDimensions(controls.midBG2, controls.midBG2.BitmapWidth(), controls.midBG2.BitmapHeight()) -- TODO
        -- LayoutHelpers.SetDimensions(controls.midBG3, controls.midBG3.BitmapWidth(), controls.midBG3.BitmapHeight()) -- TODO
        -- LayoutHelpers.AtLeftIn(controls.minBG, controls.constructionGroup, 69)
        -- LayoutHelpers.AtBottomIn(controls.maxBG, controls.minBG, 0)
        -- LayoutHelpers.AtBottomIn(controls.minBG, controls.constructionGroup, 5)
    end

    -- SetupTab(controls.constructionTab)
    -- LayoutHelpers.AtLeftTopIn(controls.constructionTab, controls.constructionGroup, 0, 14)
    -- SetupTab(controls.selectionTab)
    -- LayoutHelpers.Below(controls.selectionTab, controls.constructionTab, -16)
    -- SetupTab(controls.enhancementTab)
    -- LayoutHelpers.Below(controls.enhancementTab, controls.selectionTab, -16)

end

function OnTabChangeLayout(type)
    local controls = import("/lua/ui/game/construction.lua").controls
    if type ~= 'selection' and type ~= "RCH" and type ~= "LCH" and type ~= "Back" then
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
        controls.extraBtn1.icon:Show()
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
        controls.extraBtn1.icon:Show()
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

local flipFlop = false

function OnSelection(empty)
    local controls = import("/lua/ui/game/construction.lua").controls
    if empty then
        if not controls.constructionGroup:IsHidden() then
            controls.constructionGroup:Hide()
        end
    else
        if controls.constructionGroup:IsHidden() then
            LOG('showing construction group')
            controls.constructionGroup:Show()
            if not flipFlop then
                flipFlop = true
                controls.constructionGroup:TechTabLayout(nil, 500)
            else
                flipFlop = false
                controls.constructionGroup:TechTabLayout()
            end
        end
    end
end