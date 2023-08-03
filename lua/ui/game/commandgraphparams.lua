-- Lists the textures and colors used to draw the command graph
-- waypoints and order lines.
--
-- If any value is not supplied for a particular type of order but
-- there is an 'inherit_from' key, the value is inherited from the
-- order named by the inherit_from key.  If there is no inherit_from
-- key, the 'default' entry is used.
--
-- Note: because of the way order lines are rendered, they can't use
-- the texture batcher, so having different textures for order lines
-- is very expensive.  Only do it if necessary.

CommandGraphParams = {
    default = {
        orderline_texture = '/textures/ui/common/game/orderline/orderline_generic.dds',
        orderline_uv_aspect_ratio = 1.0,
        orderline_anim_rate = 0.0,
        orderline_color = '3300ffff',
        orderline_selected_color = 'dd00ffff',
        orderline_highlight_color = 'ff47ffff',
        orderline_glow = 0.0,
        orderline_selected_glow = 0.06,
        orderline_highlight_glow = 0.12,

        waypoint_color = '44ffffff',
        waypoint_selected_color = '88ffffff',
        waypoint_highlight_color = 'ffffffff',
        waypoint_scale = 1,
        waypoint_selected_scale = 1,
        waypoint_highlight_scale = 1,

        arrowhead_cap_offset = -0.1,
    },

-- Attack Orders
    default_AttackColors = {
        orderline_color = '33ff0000',
        orderline_selected_color = 'ddff0000',
        orderline_highlight_color = 'ffff4444',
    },
    UNITCOMMAND_Attack = {
        inherit_from = 'default_AttackColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/attack_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Retaliate = {inherit_from = 'UNITCOMMAND_Attack'},
    UNITCOMMAND_FormAttack = {inherit_from = 'UNITCOMMAND_Attack'},
    UNITCOMMAND_Tactical = {inherit_from = 'UNITCOMMAND_Attack'},
    UNITCOMMAND_Script = {inherit_from = 'UNITCOMMAND_Attack'},
    UNITCOMMAND_AggressiveMove = {
        inherit_from = 'default_AttackColors',
        orderline_texture = '/textures/ui/common/game/orderline/orderline_arrow02.dds',
        orderline_anim_rate = 0.25,
        orderline_uv_aspect_ratio = 0.2,
        waypoint_texture = '/textures/ui/common/game/waypoints/attack_move_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_FormAggressiveMove = {inherit_from = 'UNITCOMMAND_AggressiveMove',},
    UNITCOMMAND_Nuke = {
        inherit_from = 'default_AttackColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/nuke_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },

-- Move Orders
    default_MoveColors = {
        orderline_color = '3300ffff',
        orderline_selected_color = 'dd00ffff',
        orderline_highlight_color = 'ff47ffff',
    },
    UNITCOMMAND_Move = {
        inherit_from = 'default_MoveColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/move_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_FormMove = {inherit_from = 'UNITCOMMAND_Move'},
    UNITCOMMAND_CoordinatedMove = {inherit_from = 'UNITCOMMAND_Move'},
    UNITCOMMAND_Patrol = {
        inherit_from = 'default_MoveColors',
        orderline_texture = '/textures/ui/common/game/orderline/orderline_arrow02.dds',
        orderline_anim_rate = 0.25,
        orderline_uv_aspect_ratio = 0.2,
        waypoint_texture = '/textures/ui/common/game/waypoints/patrol_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_FormPatrol = {inherit_from = 'UNITCOMMAND_Patrol'},

-- Transport Orders
    default_TransportColors = {
        orderline_color = 'aa654bc2',
        orderline_selected_color = 'dd654bc2',
        orderline_highlight_color = 'ff7558e2',
    },
    UNITCOMMAND_TransportLoadUnits = {
        inherit_from = 'default_TransportColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/load_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_TransportReverseLoadUnits = {inherit_from = 'UNITCOMMAND_TransportLoadUnits'},

    UNITCOMMAND_TransportUnloadUnits = {
        inherit_from = 'default_TransportColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/unload_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_TransportUnloadSpecificUnits = {inherit_from = 'UNITCOMMAND_TransportUnloadUnits'},
    UNITCOMMAND_DetachFromTransport = {inherit_from = 'UNITCOMMAND_TransportUnloadUnits'},
    UNITCOMMAND_AssistMove = {inherit_from = 'UNITCOMMAND_TransportUnloadUnits'},
    UNITCOMMAND_Ferry = {
        inherit_from = 'default_TransportColors',
        orderline_texture = '/textures/ui/common/game/orderline/orderline_arrow-big.dds',
        orderline_anim_rate = 0.20,
        orderline_uv_aspect_ratio = 0.50,
        waypoint_texture = '/textures/ui/common/game/waypoints/ferry_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Teleport = {
        inherit_from = 'default_TransportColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/teleport_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },

 -- Engineering Orders
     default_EngineeringColors = {
        orderline_color = '33ffff00',
        orderline_selected_color = 'ddffff00',
        orderline_highlight_color = 'ffffff44',
    },

-- Factory Sharing the queue of another factory
    UNITCOMMAND_BuildAssist = {inherit_from = 'default_EngineeringColors'},

-- Enginer construction
    UNITCOMMAND_BuildMobile = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/repair_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Guard = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/guard_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Reclaim = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/reclaim_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Repair = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/repair_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Dock = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/repair_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_Capture = {
        inherit_from = 'default_EngineeringColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/convert_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },

-- Special Orders
    default_SpecialColors = {
        orderline_color = '3300ff00',
        orderline_selected_color = 'dd00ff00',
        orderline_highlight_color = 'ff44ff44',
    },
    UNITCOMMAND_Sacrifice = {
        inherit_from = 'default_SpecialColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/sacrifice_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },
    UNITCOMMAND_OverCharge = {
        inherit_from = 'default_SpecialColors',
        waypoint_texture = '/textures/ui/common/game/waypoints/attack_btn_up.dds',
        arrowhead_texture = '/textures/ui/common/game/orderline/orderline_arrow04.dds',
    },

-- These are here if they need to be used in the future
-- They are not displayed right now
    UNITCOMMAND_Dive = {inherit_from = 'default'},
    UNITCOMMAND_Stop = {inherit_from = 'default'},
    UNITCOMMAND_Land = {inherit_from = 'default'},
    UNITCOMMAND_Upgrade = {inherit_from = 'default'},
    UNITCOMMAND_AssistCommander = {inherit_from = 'default'},
    UNITCOMMAND_KillSelf = {inherit_from = 'default'},
    UNITCOMMAND_DestroySelf = {inherit_from = 'default'},
    UNITCOMMAND_BuildSilo = {inherit_from = 'default'},
    UNITCOMMAND_BuildFactory = {inherit_from = 'default'},
}
