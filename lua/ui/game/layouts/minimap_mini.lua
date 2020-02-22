
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')

function SetLayout()
    local controls = import('/lua/ui/game/minimap.lua').controls
    
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
    
    controls.miniMap.GlowTL.Top:Set(function() return controls.displayGroup:GetClientGroup().Top() - 4 end)
    controls.miniMap.GlowTL.Left:Set(function() return controls.displayGroup:GetClientGroup().Left() - 0 end)
    controls.miniMap.GlowTL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowTL:DisableHitTest()
    
    controls.miniMap.GlowTR.Top:Set(function() return controls.displayGroup:GetClientGroup().Top() - 4 end)
    controls.miniMap.GlowTR.Right:Set(function() return controls.displayGroup:GetClientGroup().Right() - 0 end)
    controls.miniMap.GlowTR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowTR:DisableHitTest()
    controls.miniMap.GlowBR.Bottom:Set(function() return controls.displayGroup:GetClientGroup().Bottom() + 2 end)
    controls.miniMap.GlowBR.Right:Set(function() return controls.displayGroup:GetClientGroup().Right() - 0 end)
    controls.miniMap.GlowBR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowBR:DisableHitTest()
    controls.miniMap.GlowBL.Bottom:Set(function() return controls.displayGroup:GetClientGroup().Bottom() + 2 end)
    controls.miniMap.GlowBL.Left:Set(function() return controls.displayGroup:GetClientGroup().Left() + 0 end)
    controls.miniMap.GlowBL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowBL:DisableHitTest()
    controls.miniMap.GlowL.Left:Set(function() return controls.miniMap.GlowTL.Left() + 2 end)
    controls.miniMap.GlowL.Top:Set(controls.miniMap.GlowTL.Bottom)
    controls.miniMap.GlowL.Bottom:Set(controls.miniMap.GlowBL.Top)
    controls.miniMap.GlowL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowL:DisableHitTest()
    controls.miniMap.GlowR.Right:Set(function() return controls.miniMap.GlowTR.Right() - 2 end)
    controls.miniMap.GlowR.Top:Set(controls.miniMap.GlowTR.Bottom)
    controls.miniMap.GlowR.Bottom:Set(controls.miniMap.GlowBR.Top)
    controls.miniMap.GlowR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowR:DisableHitTest()
    controls.miniMap.GlowT.Right:Set(controls.miniMap.GlowTR.Left)
    controls.miniMap.GlowT.Left:Set(controls.miniMap.GlowTL.Right)
    controls.miniMap.GlowT.Top:Set(function() return controls.miniMap.GlowTL.Top() + 1 end)
    controls.miniMap.GlowT:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowT:DisableHitTest()
    controls.miniMap.GlowB.Right:Set(controls.miniMap.GlowBR.Left)
    controls.miniMap.GlowB.Left:Set(controls.miniMap.GlowBL.Right)
    controls.miniMap.GlowB.Bottom:Set(function() return controls.miniMap.GlowBL.Bottom() - 1 end)
    controls.miniMap.GlowB:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.GlowB:DisableHitTest()
    
    controls.miniMap.DragTL.Left:Set(function() return controls.displayGroup.Left() - 27 end)
    controls.miniMap.DragTL.Top:Set(function() return controls.displayGroup.Top() - 10 end)
    controls.miniMap.DragTL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragTL:DisableHitTest()
    
    controls.miniMap.DragTR.Right:Set(function() return controls.displayGroup.Right() + 22 end)
    controls.miniMap.DragTR.Top:Set(function() return controls.displayGroup.Top() - 10 end)
    controls.miniMap.DragTR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragTR:DisableHitTest()
    
    controls.miniMap.DragBL.Left:Set(function() return controls.displayGroup.Left() - 27 end)
    controls.miniMap.DragBL.Bottom:Set(function() return controls.displayGroup.Bottom() + 8 end)
    controls.miniMap.DragBL:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragBL:DisableHitTest()
    
    controls.miniMap.DragBR.Right:Set(function() return controls.displayGroup.Right() + 22 end)
    controls.miniMap.DragBR.Bottom:Set(function() return controls.displayGroup.Bottom() + 8 end)
    controls.miniMap.DragBR:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.miniMap.DragBR:DisableHitTest()
    
    controls.miniMap.DragTL.Depth:Set(function() return controls.displayGroup.Depth() + 2 end)
    controls.miniMap.DragTR.Depth:Set(controls.miniMap.DragTL.Depth)
    controls.miniMap.DragBL.Depth:Set(controls.miniMap.DragTL.Depth)
    controls.miniMap.DragBR.Depth:Set(controls.miniMap.DragTL.Depth)
        
    controls.miniMap.Left:Set(function() return controls.displayGroup:GetClientGroup().Left() + 8 end)
    controls.miniMap.Top:Set(function() return controls.displayGroup:GetClientGroup().Top() + 4 end)
    controls.miniMap.Right:Set(function() return controls.displayGroup:GetClientGroup().Right() - 8 end)
    controls.miniMap.Bottom:Set(function() return controls.displayGroup:GetClientGroup().Bottom() - 6 end)
end