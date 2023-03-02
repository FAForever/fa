
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Prefs = import("/lua/user/prefs.lua")

function SetLayout()
    local GUI = import("/lua/ui/game/chat.lua").GUI
    
    local windowTextures = {
        tl = UIUtil.UIFile('/game/chat_brd/chat_brd_ul.dds'),
        tr = UIUtil.UIFile('/game/chat_brd/chat_brd_ur.dds'),
        tm = UIUtil.UIFile('/game/chat_brd/chat_brd_horz_um.dds'),
        ml = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_l.dds'),
        m = UIUtil.UIFile('/game/chat_brd/chat_brd_m.dds'),
        mr = UIUtil.UIFile('/game/chat_brd/chat_brd_vert_r.dds'),
        bl = UIUtil.UIFile('/game/chat_brd/chat_brd_ll.dds'),
        bm = UIUtil.UIFile('/game/chat_brd/chat_brd_lm.dds'),
        br = UIUtil.UIFile('/game/chat_brd/chat_brd_lr.dds'),
        borderColor = 'ff415055',
    }
    
    GUI.bg:ApplyWindowTextures(windowTextures)
    
    GUI.bg.DragTL:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.bg.DragTR:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.bg.DragBL:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.bg.DragBR:SetTexture(UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))
    
    GUI.bg.DragTL.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_over.dds')}
            
    GUI.bg.DragTR.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_over.dds')}
            
    GUI.bg.DragBL.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_over.dds')}
            
    GUI.bg.DragBR.textures = {up = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'),
            down = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_down.dds'),
            over = UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_over.dds')}
end