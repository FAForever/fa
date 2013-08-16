-- This file defines skin directories as well as certain skin settings like fonts and colors
-- Each skin is a table entry in the skins table
-- it contains the following fields:
--  default: The skin to look at if we can't find a needed component in the current skin. Note that this cascades,
--           so if the component isn't in the default skin, it will check the defaults default, etc, until there are no more skins to check
--  texturesPath: where the textures (and currently layout files) are found in this skin
--  buttonFont: default font used for button faces
--  bodyFont: font used for all other text
--  fixedFont: font used for fixed width characters
--  fontColor: common font color
--  highlightColor: text highlight color
--  disabledColor: text disabled color
--  panelColor: default color when drawing a panel


skins = {
    uef = {
        default = "default",
        texturesPath = "/textures/ui/uef",
        imagerMesh = "/meshes/game/map-border_squ_uef_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_uef_mesh",
        buttonFont = "Zeroes Three",
	    factionFont = "Zeroes Three",
        bodyFont = "Arial",
        fixedFont = "Arial",
        titleFont = "Zeroes Three",
        fontColor = "FFbadbdb",
        bodyColor = "FF6FAFAF",
        dialogCaptionColor = "FFbadbdb",
        dialogColumnColor = "FF6FAFAF",
        dialogButtonColor = "FF69AB4D",
        dialogButtonFont = "Zeroes Three",
        highlightColor = "FF7FA8A4",
        disabledColor = "FF47555a",
        tooltipBorderColor = "FF7392a5",
        tooltipTitleColor = "FF004142",
        tooltipBackgroundColor = "FF000000",
        menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
    },
    aeon = {
        default = "uef",
        texturesPath = "/textures/ui/aeon",
        imagerMesh = "/meshes/game/map-border_squ_aeon_mesh",
        imagerMeshDetails = "/meshes/game/map-border_squ_aeon_a_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_aeon_mesh",
        imagerMeshDetailsHorz = "/meshes/game/map-border_hor_aeon_a_mesh",
        buttonFont = "Zeroes Three",
	    factionFont = "Zeroes Three",
        fixedFont = "Arial",
        titleFont = "Zeroes Three",
        fontColor = "FFc7e98a",
        bodyColor = "FFc7e98a",
	    factionFontOverColor = "FFa4ff00",
        factionFontDownColor = "FFFFFFFF",
        dialogCaptionColor = "FFbadbdb",
        dialogColumnColor = "FF6FAFAF",
        dialogButtonColor = "FF69AB4D",
        dialogButtonFont = "Zeroes Three",
        highlightColor = "FF7FA8A4",
        disabledColor = "FF3b5511",
        tooltipBorderColor = "FF609541",
        tooltipTitleColor = "FF283d10",
        tooltipBackgroundColor = "FF000000",
        menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
    },
    cybran = {
        default = "uef",
        texturesPath = "/textures/ui/cybran",
        imagerMesh = "/meshes/game/map-border_squ_cybran_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_cybran_mesh",
        buttonFont = "Zeroes Three",
	    factionFont = "Zeroes Three",
        bodyFont = "Arial",
        fixedFont = "Arial",
        titleFont = "Zeroes Three",
        fontColor = "FFe24f2d",
        bodyColor = "FFe24f2d",
        factionFontOverColor = "FFff0000",
        factionFontDownColor = "FFFFFFFF",
	    dialogCaptionColor = "FFbadbdb",
        dialogColumnColor = "FF6FAFAF",
        dialogButtonColor = "FF69AB4D",
        dialogButtonFont = "Zeroes Three",
        highlightColor = "FF7FA8A4",
        disabledColor = "FF640505",
        tooltipBorderColor = "FFb62929",
        tooltipTitleColor = "FF621917",
        tooltipBackgroundColor = "FF000000",
        menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
    },
    seraphim = {
        default = "uef",
        texturesPath = "/textures/ui/seraphim",
        imagerMesh = "/meshes/game/map-border_squ_sera_mesh",
        imagerMeshDetails = "/meshes/game/map-border_squ_sera_a_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_sera_mesh",
        imagerMeshDetailsHorz = "/meshes/game/map-border_hor_sera_a_mesh",
        buttonFont = "Zeroes Three",
	    factionFont = "Zeroes Three",
        bodyFont = "Arial",
        fixedFont = "Arial",
        titleFont = "Zeroes Three",
        fontColor = "FFffd700",
        bodyColor = "FFffd700",
        factionFontOverColor = "FFfffe84",
        factionFontDownColor = "FFFFFFFF",
	    dialogCaptionColor = "FFbadbdb",
        dialogColumnColor = "FF6FAFAF",
        dialogButtonColor = "FF69AB4D",
        dialogButtonFont = "Zeroes Three",
        highlightColor = "FF7FA8A4",
        disabledColor = "FF685f16",
        tooltipBorderColor = "FFeee274",
        tooltipTitleColor = "FF725b1a",
        tooltipBackgroundColor = "FF000000",
        menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
    },
	randomfaction = {
        default = "default",
        texturesPath = "/textures/ui/random",
        imagerMesh = "/meshes/game/map-border_squ_uef_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_uef_mesh",
        buttonFont = "Zeroes Three",
	    factionFont = "Zeroes Three",
        bodyFont = "Arial",
        fixedFont = "Arial",
        titleFont = "Zeroes Three",
		fontColor = "FFffffff", -- Couleur de texte
        bodyColor = "FFff0000", -- ??
		dialogCaptionColor = "FFffffff", -- Couleur de texte d'une boite de dialogue
        dialogColumnColor = "FFff0000", -- ??
        dialogButtonColor = "FFff0000", -- ??
        dialogButtonFont = "Zeroes Three", -- ??
		highlightColor = "FF767676", -- Cadre de selection
        disabledColor = "FF767676", -- Couleur de texte dont sa été désactivée
		tooltipBorderColor = "FF3b3b3b", -- Bordure du Tooltip
        tooltipTitleColor = "FF767676", -- Haut du Tooltip
        tooltipBackgroundColor = "FF000000", -- Bas du Tooltip
		menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
    },

    -- warning, do not change the name of this skin descriptor or things will break!
    default = {
        -- note, no default value here, so the "default chain" will get broken at this point, and you'll get file not found
        texturesPath = "/textures/ui/common",
        imagerMesh = "/meshes/game/map-border_mesh",
        buttonFont = "Zeroes Three",
        bodyFont = "Arial",
        fixedFont = "Andale Mono",
        titleFont = "Zeroes Three",
        fontColor = "FFbadbdb",
        fontOverColor = "FFFFFFFF",
        fontDownColor = "FF1a3c28",
        bodyColor = "FF6FAFAF",
        dialogCaptionColor = "FFbadbdb",
        dialogColumnColor = "FF6FAFAF",
        dialogButtonColor = "FF69AB4D",
        dialogButtonFont = "Zeroes Three",
        highlightColor = "FF7FA8A4",
        disabledColor = "FF47555a",
        panelColor = "FF4A5D6B",
        transparentPanelColor = "AA4A5D6B",
        consoleBGColor = "BB008080",
        consoleFGColor = "white",
        consoleTextBGColor = "80000000",
        menuFontSize = 18,
        layouts = {
            "bottom",
            "left",
            "right"
        },
        -- cursor format is: texture name, hotspotx, hotspoty, [optional] num frames, [optional] fps
        cursors = {
            RULEUCC_Attack = {'/textures/ui/common/game/cursors/attack-.dds', 15, 15, 11, 12},
            RULEUCC_CallTransport = {'/textures/ui/common/game/cursors/load-.dds', 15, 19, 14, 12},
            RULEUCC_Capture = {'/textures/ui/common/game/cursors/capture-.dds', 15, 15, 9, 12},
            RULEUCC_Ferry = {'/textures/ui/common/game/cursors/ferry.dds', 15, 15},
            RULEUCC_Guard = {'/textures/ui/common/game/cursors/guard-.dds', 15, 15, 10, 12},
            RULEUCC_Move = {'/textures/ui/common/game/cursors/move-.dds', 15, 15, 12, 12},
            RULEUCC_Nuke = {'/textures/ui/common/game/cursors/launch.dds', 15, 15},
            RULEUCC_Tactical = {'/textures/ui/common/game/cursors/launch.dds', 15, 15},
            RULEUCC_Overcharge = {'/textures/ui/common/game/cursors/overcharge-.dds', 15, 15, 8, 12},
            RULEUCC_SpecialAction = {'/textures/ui/common/game/cursors/attack-.dds', 15, 15, 11, 12},
            RULEUCC_Patrol = {'/textures/ui/common/game/cursors/patrol-.dds', 15, 15, 5, 12},
            RULEUCC_Reclaim = {'/textures/ui/common/game/cursors/reclaim02-.dds', 15, 15, 23, 12},
            RULEUCC_Repair = {'/textures/ui/common/game/cursors/repair-.dds', 15, 15, 7, 12},
            RULEUCC_Sacrifice = {'/textures/ui/common/game/cursors/sacrifice-.dds', 15, 15, 13, 12},
            RULEUCC_Transport = {'/textures/ui/common/game/cursors/unload-.dds', 15, 3, 14, 12},
            RULEUCC_Teleport = {'/textures/ui/common/game/cursors/transport.dds', 15, 15},
            RULEUCC_Script = {'/textures/ui/common/game/cursors/attack.dds', 15, 15},
            RULEUCC_Invalid = {'/textures/ui/common/game/cursors/attack-invalid.dds', 15, 15},
            COORDINATED_ATTACK = {'/textures/ui/common/game/cursors/attack_coordinated.dds', 15, 15},
            MESSAGE = {'/textures/ui/common/game/cursors/message-.dds', 15, 15, 11, 12},
            BUILD = {'/textures/ui/common/game/cursors/selectable-.dds', 2, 2, 7, 12},
            HOVERCOMMAND = {'/textures/ui/common/game/cursors/waypoint-hover.dds', 7, 7},
            DRAGCOMMAND = {'/textures/ui/common/game/cursors/waypoint-drag.dds', 7, 7},
            MOVE2PATROLCOMMAND = {'/textures/ui/common/game/cursors/patrol.dds', 15, 15},
            DEFAULT = {'/textures/ui/common/game/cursors/selectable.dds', 2, 2},
            NE_SW = {'/textures/ui/common/game/cursors/ne_sw.dds', 15, 15},
            NW_SE = {'/textures/ui/common/game/cursors/nw_se.dds', 15, 15},
            N_S = {'/textures/ui/common/game/cursors/n_s.dds', 15, 15},
            W_E = {'/textures/ui/common/game/cursors/w_e.dds', 15, 15},
            MOVE_WINDOW = {'/textures/ui/common/game/cursors/move_window.dds', 15, 15},
        },
    },
}