local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

function SetLayout()
    local controls = import("/lua/ui/game/minimap.lua").controls

    local windowTextures = {
        tl = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ul.dds'),
        tr = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ur.dds'),
        tm = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_horz_um.dds'),
        ml = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_vert_l.dds'),
        m = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_m.dds'),
        mr = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_vert_r.dds'),
        bl = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ll.dds'),
        bm = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_lm.dds'),
        br = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_lr.dds'),
        borderColor = 'ff415055',
    }

    controls.displayGroup:ApplyWindowTextures(windowTextures)

    controls.miniMap.GlowTL:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ul.dds'))
    controls.miniMap.GlowTR:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ur.dds'))
    controls.miniMap.GlowBR:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_lr.dds'))
    controls.miniMap.GlowBL:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_ll.dds'))
    controls.miniMap.GlowL:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_l.dds'))
    controls.miniMap.GlowR:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_vert_r.dds'))
    controls.miniMap.GlowT:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_horz_um.dds'))
    controls.miniMap.GlowB:SetTexture(UIUtil.UIFile('/game/mini-map-glow-brd/mini-map-glow_brd_lm.dds'))

    controls.miniMap.DragTL:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    controls.miniMap.DragTR:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    controls.miniMap.DragBL:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    controls.miniMap.DragBR:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

    controls.miniMap.DragTL.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_over.dds')}

    controls.miniMap.DragTR.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_over.dds')}

    controls.miniMap.DragBL.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_over.dds')}

    controls.miniMap.DragBR.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_over.dds')}

    local clientGroup = controls.displayGroup:GetClientGroup()
    LayoutHelpers.AtLeftTopIn(controls.miniMap.GlowTL, clientGroup, 0, -4)
    controls.miniMap.GlowTL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowTL:DisableHitTest()

    LayoutHelpers.AtRightTopIn(controls.miniMap.GlowTR, clientGroup, 0, -4)
    controls.miniMap.GlowTR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowTR:DisableHitTest()
    LayoutHelpers.AtRightBottomIn(controls.miniMap.GlowBR, clientGroup, 0, -2)
    controls.miniMap.GlowBR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowBR:DisableHitTest()
    LayoutHelpers.AtLeftBottomIn(controls.miniMap.GlowBL, clientGroup, 0, -2)
    controls.miniMap.GlowBL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowBL:DisableHitTest()
    LayoutHelpers.AtLeftIn(controls.miniMap.GlowL, controls.miniMap.GlowTL, 2)
    controls.miniMap.GlowL.Top:Set(controls.miniMap.GlowTL.Bottom)
    controls.miniMap.GlowL.Bottom:Set(controls.miniMap.GlowBL.Top)
    controls.miniMap.GlowL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowL:DisableHitTest()
    LayoutHelpers.AtRightIn(controls.miniMap.GlowR, controls.miniMap.GlowTR, 2)
    controls.miniMap.GlowR.Top:Set(controls.miniMap.GlowTR.Bottom)
    controls.miniMap.GlowR.Bottom:Set(controls.miniMap.GlowBR.Top)
    controls.miniMap.GlowR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowR:DisableHitTest()
    controls.miniMap.GlowT.Right:Set(controls.miniMap.GlowTR.Left)
    controls.miniMap.GlowT.Left:Set(controls.miniMap.GlowTL.Right)
    LayoutHelpers.AtTopIn(controls.miniMap.GlowT, controls.miniMap.GlowTL, 1)
    controls.miniMap.GlowT:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowT:DisableHitTest()
    controls.miniMap.GlowB.Right:Set(controls.miniMap.GlowBR.Left)
    controls.miniMap.GlowB.Left:Set(controls.miniMap.GlowBL.Right)
    LayoutHelpers.AtBottomIn(controls.miniMap.GlowB, controls.miniMap.GlowBL, 1)
    controls.miniMap.GlowB:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowB:DisableHitTest()

    LayoutHelpers.AtLeftTopIn(controls.miniMap.DragTL, controls.displayGroup, -27, -10)
    controls.miniMap.DragTL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragTL:DisableHitTest()

    LayoutHelpers.AtRightTopIn(controls.miniMap.DragTR, controls.displayGroup, -22, -10)
    controls.miniMap.DragTR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragTR:DisableHitTest()

    LayoutHelpers.AtLeftBottomIn(controls.miniMap.DragBL, controls.displayGroup, -27, -8)
    controls.miniMap.DragBL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragBL:DisableHitTest()

    LayoutHelpers.AtRightBottomIn(controls.miniMap.DragBR, controls.displayGroup, -22, -8)
    controls.miniMap.DragBR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragBR:DisableHitTest()

    controls.miniMap.DragTL.Depth:Set(function() return controls.displayGroup.Depth() + 2 end)
    controls.miniMap.DragTR.Depth:Set(controls.miniMap.DragTL.Depth)
    controls.miniMap.DragBL.Depth:Set(controls.miniMap.DragTL.Depth)
    controls.miniMap.DragBR.Depth:Set(controls.miniMap.DragTL.Depth)

    LayoutHelpers.AtLeftTopIn(controls.miniMap, clientGroup, 8, 4)
    LayoutHelpers.AtRightBottomIn(controls.miniMap, clientGroup, 8, 6)
end