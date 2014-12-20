
local UIUtil = import('/lua/ui/uiutil.lua')

styles = {
    backgrounds = {
        notitle = {
            tl = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_ul.dds'),
            tr = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_ur.dds'),
            tm = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_horz_um.dds'),
            ml = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_vert_l.dds'),
            m = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_m.dds'),
            mr = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_vert_r.dds'),
            bl = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_ll.dds'),
            bm = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_lm.dds'),
            br = UIUtil.UIFile('/game/mini-map-brd01/mini-map_brd_lr.dds'),
            borderColor = 'ff415055',
        },
        title = {
            tl = UIUtil.UIFile('/game/options_brd/options_brd_ul.dds'),
            tr = UIUtil.UIFile('/game/options_brd/options_brd_ur.dds'),
            tm = UIUtil.UIFile('/game/options_brd/options_brd_horz_um.dds'),
            ml = UIUtil.UIFile('/game/options_brd/options_brd_vert_l.dds'),
            m = UIUtil.UIFile('/game/options_brd/options_brd_m.dds'),
            mr = UIUtil.UIFile('/game/options_brd/options_brd_vert_r.dds'),
            bl = UIUtil.UIFile('/game/options_brd/options_brd_ll.dds'),
            bm = UIUtil.UIFile('/game/options_brd/options_brd_lm.dds'),
            br = UIUtil.UIFile('/game/options_brd/options_brd_lr.dds'),
            borderColor = 'ff415055',
        },
    },
    closeButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/close_btn_up.dds'),
        down = UIUtil.SkinnableFile('/game/menu-btns/close_btn_down.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/close_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/close_btn_dis.dds'),
    },
    pinButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_up.dds'),
        upSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_up.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_over.dds'),
        overSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/pin_btn_dis.dds'),
        disSel = UIUtil.SkinnableFile('/game/menu-btns/pinned_btn_dis.dds'),
    },
    configButton = {
        up = UIUtil.SkinnableFile('/game/menu-btns/config_btn_up.dds'),
        down = UIUtil.SkinnableFile('/game/menu-btns/config_btn_down.dds'),
        over = UIUtil.SkinnableFile('/game/menu-btns/config_btn_over.dds'),
        dis = UIUtil.SkinnableFile('/game/menu-btns/config_btn_dis.dds'),
    },
    title = {
        font = UIUtil.titleFont,
        color = UIUtil.fontColor,
        size = 14,
    },
    cursorFunc = UIUtil.GetCursor,
}
