
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local textures = {
    info = {
        left = 'panel-time-units_bmp_l.dds',
        right = 'panel-time-units_bmp_r.dds',
        middle = 'panel-time-units_bmp_m.dds',
    },
    objective = {
        left = 'panel-objectives_bmp_l.dds',
        right = 'panel-objectives_bmp_r.dds',
        middle = 'panel-objectives_bmp_m.dds',
    },
    squad = {
        left = 'panel-ping_bmp_l.dds',
        right = 'panel-ping_bmp_r.dds',
        middle = 'panel-ping_bmp_m.dds',
    },
}

function SetLayout()
    local controls = import('/lua/ui/game/objectives2.lua').controls
    
    LayoutHelpers.AtRightTopIn(controls.bg, controls.parent)
    
    LayoutHelpers.AtRightTopIn(controls.infoContainer, controls.bg, 13, 10)
    controls.infoContainer.Height:Set(controls.infoContainer.LeftBG.Height)
    controls.infoContainer.Width:Set(function() return controls.time.Width() + controls.units.Width() + 120 end)
    
    controls.objectiveContainer.Top:Set(function() return controls.infoContainer.Bottom() end)
    LayoutHelpers.AtRightIn(controls.objectiveContainer, controls.bg, 15)
    controls.objectiveContainer.Height:Set(controls.objectiveContainer.LeftBG.Height)
    controls.objectiveContainer.Width:Set(1)
    
    controls.squadContainer.Top:Set(function() return controls.objectiveContainer.Bottom() end)
    LayoutHelpers.AtRightIn(controls.squadContainer, controls.bg, 15)
    controls.squadContainer.Height:Set(controls.squadContainer.LeftBG.Height)
    controls.squadContainer.Width:Set(1)
    
    controls.timeIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
    controls.unitIcon:SetTexture(UIUtil.UIFile('/dialogs/score-overlay/tank_bmp.dds'))
    LayoutHelpers.AtLeftTopIn(controls.timeIcon, controls.infoContainer, 20, 2)
    LayoutHelpers.AtRightTopIn(controls.unitIcon, controls.infoContainer, 20, 2)
    LayoutHelpers.RightOf(controls.time, controls.timeIcon, 2)
    LayoutHelpers.LeftOf(controls.units, controls.unitIcon)
    
    controls.timeIcon.Height:Set(function() return controls.timeIcon.BitmapHeight() * .9 end)
    controls.timeIcon.Width:Set(function() return controls.timeIcon.BitmapWidth() * .9 end)
    controls.unitIcon.Height:Set(function() return controls.unitIcon.BitmapHeight() * .9 end)
    controls.unitIcon.Width:Set(function() return controls.unitIcon.BitmapWidth() * .9 end)
    
    LayoutContainerBG(controls.objectiveContainer, textures.objective)
    LayoutContainerBG(controls.squadContainer, textures.squad)
    LayoutContainerBG(controls.infoContainer, textures.info)
    
    controls.bg.bracketTop:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'))
    controls.bg.bracketBottom:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'))
    controls.bg.bracketStretch:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'))
    
    LayoutHelpers.AtRightTopIn(controls.bg.bracketTop, controls.bg)
    controls.bg.bracketBottom.Top:Set(function() return math.max(controls.bg.Bottom() - controls.bg.bracketBottom.Height(), controls.bg.bracketTop.Bottom()) end)
    LayoutHelpers.AtRightIn(controls.bg.bracketBottom, controls.bg)
    
    controls.bg.bracketStretch.Top:Set(controls.bg.bracketTop.Bottom)
    controls.bg.bracketStretch.Right:Set(function() return controls.bg.bracketTop.Right() - 7 end)
    controls.bg.bracketStretch.Bottom:Set(controls.bg.bracketBottom.Top)
    
    LayoutHelpers.AtTopIn(controls.collapseArrow, controls.bg, 22)
    LayoutHelpers.AtRightIn(controls.collapseArrow, controls.parent, -3)
    controls.collapseArrow.Depth:Set(function() return controls.bg.Depth() + 10 end)
    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_dis.dds'))
        
    controls.bg.Height:Set(function() 
        local height = 0
        if not controls.infoContainer:IsHidden() then
            height = height + controls.infoContainer.Height()
        end
        if not controls.objectiveContainer:IsHidden() then
            height = height + controls.objectiveContainer.Height()
        end
        if not controls.squadContainer:IsHidden() then
            height = height + controls.squadContainer.Height()
        end
        return height + 20
    end)
    controls.bg.Width:Set(function() return math.max(math.max(controls.infoContainer.Width(), controls.objectiveContainer.Width()), controls.squadContainer.Width()) end)
    
    local avatarGroup = import('/lua/ui/game/avatars.lua').controls.avatarGroup
    avatarGroup.Top:Set(controls.bg.bracketBottom.Bottom()+60)
end

function LayoutContainerBG(container, textures)
    container.LeftBG:SetTexture(UIUtil.UIFile('/game/pda-panel/'..textures.left))
    container.RightBG:SetTexture(UIUtil.UIFile('/game/pda-panel/'..textures.right))
    container.StretchBG:SetTexture(UIUtil.UIFile('/game/pda-panel/'..textures.middle))
    
    container.LeftBG.Depth:Set(container.Depth)
    container.RightBG.Depth:Set(container.Depth)
    container.StretchBG.Depth:Set(container.Depth)

    LayoutHelpers.AtRightTopIn(container.RightBG, container)
    
    container.LeftBG.Right:Set(function() return math.min(container.RightBG.Left(), container.Left() + container.LeftBG.Width()) end)
    container.LeftBG.Top:Set(function() return container.RightBG.Top() - 2 end)
    
    container.StretchBG.Top:Set(container.RightBG.Top)
    container.StretchBG.Left:Set(container.LeftBG.Right)
    container.StretchBG.Right:Set(container.RightBG.Left)
end