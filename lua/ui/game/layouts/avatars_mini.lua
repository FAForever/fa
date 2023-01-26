local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

function SetLayout()
    local controls = import("/lua/ui/game/avatars.lua").controls

    LayoutHelpers.AtRightTopIn(controls.avatarGroup, controls.parent, 0, 200)
    LayoutHelpers.SetDimensions(controls.avatarGroup, 200, 0)

    controls.bgTop:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_t.dds'))
    controls.bgStretch:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_m.dds'))
    controls.bgBottom:SetTexture(UIUtil.UIFile('/game/bracket-right/bracket_bmp_b.dds'))

    LayoutHelpers.AtTopIn(controls.collapseArrow, controls.avatarGroup, 22)
    LayoutHelpers.AtRightIn(controls.collapseArrow, controls.parent, -3)

    LayoutHelpers.AtRightIn(controls.bgTop, controls.avatarGroup)
    LayoutHelpers.AtRightIn(controls.bgBottom, controls.avatarGroup)

    LayoutHelpers.AnchorToTop(controls.bgTop, controls.avatarGroup, -70)
    controls.bgBottom.Top:Set(function() return math.max(controls.bgTop.Bottom(), controls.avatarGroup.Bottom() + 0) end)
    LayoutHelpers.AnchorToBottom(controls.bgStretch, controls.bgTop)
    LayoutHelpers.AnchorToTop(controls.bgStretch, controls.bgBottom)
    LayoutHelpers.AtRightIn(controls.bgStretch, controls.bgTop, 7)

    LayoutHelpers.DepthOverParent(controls.collapseArrow, controls.bgTop)
    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_dis.dds'))

    LayoutAvatars()
end

function LayoutAvatars()
    local controls = import("/lua/ui/game/avatars.lua").controls

    local rightOffset, topOffset, space = 14, 14, -5

    local prevControl = false
    local height = 0
    for _, control in controls.avatars do
        if prevControl then
            LayoutHelpers.AnchorToBottom(control, prevControl, space)
            --control.Top:Set(function() return prevControl.Bottom() + space end)
            LayoutHelpers.AtRightIn(control, prevControl)
            height = height + (control.Bottom() - prevControl.Bottom())
        else
            LayoutHelpers.AtRightTopIn(control, controls.avatarGroup, rightOffset, topOffset)
            height = control.Height()
        end
        prevControl = control
    end
    if controls.idleEngineers then
        if prevControl then
            controls.idleEngineers.prevControl = prevControl
            LayoutHelpers.AnchorToBottom(controls.idleEngineers, controls.idleEngineers.prevControl, space)
            LayoutHelpers.AtRightIn(controls.idleEngineers, controls.idleEngineers.prevControl)
            height = height + (controls.idleEngineers.Bottom() - controls.idleEngineers.prevControl.Bottom())
        else
            LayoutHelpers.AtRightTopIn(controls.idleEngineers, controls.avatarGroup, rightOffset, topOffset)
            height = controls.idleEngineers.Height()
        end
        prevControl = controls.idleEngineers
    end
    if controls.idleFactories then
        if prevControl then
            controls.idleFactories.prevControl = prevControl
            LayoutHelpers.AnchorToBottom(controls.idleFactories, controls.idleFactories.prevControl, space)
            LayoutHelpers.AtRightIn(controls.idleFactories, controls.idleFactories.prevControl)
            height = height + (controls.idleFactories.Bottom() - controls.idleFactories.prevControl.Bottom())
        else
            LayoutHelpers.AtRightTopIn(controls.idleFactories, controls.avatarGroup, rightOffset, topOffset)
            height = controls.idleFactories.Height()
        end
    end

    controls.avatarGroup.Height:Set(function() return height - LayoutHelpers.ScaleNumber(5) end)
end
