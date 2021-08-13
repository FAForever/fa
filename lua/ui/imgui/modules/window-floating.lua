
local UIUtil = import('/lua/ui/uiutil.lua')
local Slider = import('/lua/maui/slider.lua').Slider
local Window = import('/lua/maui/window.lua').Window

function WindowConstructFloating(identifier)

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

    local defPosition = {Left = 10, Top = 157, Bottom = 367, Right = 237}

    return Window(
        GetFrame(0),            -- parent
        identifier,             -- title
        nil,                    -- icon
        false,                  -- pin
        true,                   -- config
        false,                  -- lockSize
        false,                  -- lockPosition
        'mini_ui_minimap',      -- prefID
        defPosition,            -- default position
        windowTextures          -- textureTable
    )

end