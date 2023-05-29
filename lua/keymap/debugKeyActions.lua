-- This file outlines the interaction between the 'command' (Bound to a key) and the behaviour of that command
-- format is:
--  key - The string referenced by a bound key
--  action - The console command to execute when the key is pressed
--  category - The category to list this action under in the key assign dialog
--  order - The sort order to list this action under its category
--  keyRepeat - A boolean flag that dictates when an action is one that can be held to extend its effect (eg - Zoom)

local keyActionsDebug = {
    ['toggle_map_utilities_window'] = {
        action = 'UI_Lua import("/lua/ui/game/maputilities.lua").OpenWindow()',
        category = 'debug',
    },
    ['toggle_ai_screen'] = {
        action = 'UI_Lua import("/lua/ui/dialogs/aiutilitiesview.lua").OpenWindow()',
        category = 'debug'
    },
    ['toggle_profiler'] = {
        action = 'UI_Lua import("/lua/ui/game/profiler.lua").ToggleProfiler()',
        category = 'debug'
    },
    ['toggle_profiler_window'] = {
        action = 'UI_Lua import("/lua/ui/game/profiler.lua").OpenWindow()',
        category = 'debug'
    },
    ['store_camera_settings'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").StoreCameraPosition()',
        category = 'debug',
    },
    ['restore_camera_settings'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").RestoreCameraPosition()',
        category = 'debug',
    },
    ['show_fps'] = {
        action = 'UI_Lua import("/lua/debug/uidebug.lua").ShowFPS()',
        category = 'debug',
    },
    ['show_network_stats'] = {
        action = 'ren_ShowNetworkStats',
        category = 'debug',
    },
    ['debug_navpath'] = {
        action = 'dbg navpath',
        category = 'debug',
    },
    ['debug_create_unit'] = {
        action = 'PopupCreateUnitMenu',
        category = 'debug',
    },
    ['debug_teleport'] = {
        action = 'TeleportSelectedUnits',
        category = 'debug',
    },
    ['debug_run_opponent_AI'] = {
        action = 'AI_RunOpponentAI',
        category = 'debug',
    },
    ['debug_blingbling'] = {
        action = 'BlingBling',
        category = 'debug',
    },
    ['debug_destroy_units'] = {
        action = 'DestroySelectedUnits',
        category = 'debug',
    },
    ['debug_graphics_fidelity_0'] = {
        action = 'graphics_Fidelity 0',
        category = 'debug',
    },
    ['debug_graphics_fidelity_2'] = {
        action = 'graphics_Fidelity 2',
        category = 'debug',
    },
    ['debug_scenario_method_f3'] = {
        action = 'ScenarioMethod OnF3',
        category = 'debug',
    },
    ['debug_scenario_method_shift_f3'] = {
        action = 'ScenarioMethod OnShiftF3',
        category = 'debug',
    },
    ['debug_scenario_method_ctrl_f3'] = {
        action = 'ScenarioMethod OnCtrlF3',
        category = 'debug',
    },
    ['debug_scenario_method_shift_f4'] = {
        action = 'ScenarioMethod OnShiftF4',
        category = 'debug',
    },
    ['debug_scenario_method_ctrl_f4'] = {
        action = 'ScenarioMethod OnCtrlF4',
        category = 'debug',
    },
    ['debug_scenario_method_ctrl_alt_f3'] = {
        action = 'ScenarioMethod OnCtrlAltF4',
        category = 'debug',
    },
    ['debug_scenario_method_f4'] = {
        action = 'ScenarioMethod OnF4',
        category = 'debug',
    },
    ['debug_scenario_method_f5'] = {
        action = 'ScenarioMethod OnF5',
        category = 'debug',
    },
    ['debug_scenario_method_shift_f5'] = {
        action = 'ScenarioMethod OnShiftF5',
        category = 'debug',
    },
    ['debug_scenario_method_ctrl_f5'] = {
        action = 'ScenarioMethod OnCtrlF5',
        category = 'debug',
    },
    ['debug_scenario_method_ctrl_alt_f5'] = {
        action = 'ScenarioMethod OnCtrlAltF5',
        category = 'debug',
    },
    ['debug_campaign_instawin'] = {
        action = 'ui_lua import("/lua/ui/campaign/campaignmanager.lua").InstaWin()',
        category = 'debug',
    },
    ['debug_create_entity'] = {
        action = 'SC_CreateEntityDialog',
        category = 'debug',
    },
    ['debug_show_stats'] = {
        action = 'ShowStats',
        category = 'debug',
    },
    ['debug_show_army_stats'] = {
        action = 'ShowArmyStats',
        category = 'debug',
    },
    ['debug_toggle_log_window'] = {
        action = 'WIN_ToggleLogDialog',
        category = 'debug',
    },
    ['debug_open_lua_debugger'] = {
        action = 'SC_LuaDebugger',
        category = 'debug',
    },
    ['debug_show_frame_stats'] = {
        action = 'ShowStats frame',
        category = 'debug',
    },
    ['debug_render_wireframe'] = {
        action = 'ren_ShowWireframe tog',
        category = 'debug',
    },
    ['debug_weapons'] = {
        action = 'dbg weapons',
        category = 'debug',
    },
    ['debug_grid'] = {
        action = 'dbg grid',
        category = 'debug',
    },
    ['debug_show_focus_ui_control'] = {
        action = 'UI_ShowControlUnderMouse tog',
        category = 'debug',
    },
    ['debug_dump_focus_ui_control'] = {
        action = 'UI_DumpControlsUnderCursor',
        category = 'debug',
    },
    ['debug_dump_ui_controls'] = {
        action = 'UI_DumpControls',
        category = 'debug',
    },
    ['debug_skeletons'] = {
        action = 'Ren_Showskeletons',
        category = 'debug',
    },
    ['debug_bones'] = {
        action = 'Ren_ShowBoneNames',
        category = 'debug',
    },
    ['debug_redo_console_command'] = {
        action = 'CON_ExecuteLastCommand',
        category = 'debug',
    },
    ['debug_copy_units'] = {
        action = 'CopySelectedUnitsToClipboard',
        category = 'debug',
    },
    ['debug_paste_units'] = {
        action = 'ExecutePasteBuffer',
        category = 'debug',
    },
    ['debug_nodamage'] = {
        action = 'Nodamage',
        category = 'debug',
    },
    ['debug_show_emmitter_window'] = {
        action = 'EFX_CreateEmitterWindow',
        category = 'debug',
    },
    ['debug_sally_shears'] = {
        action = 'SallyShears',
        category = 'debug',
    },
    ['debug_collision'] = {
        action = 'dbg Collision',
        category = 'debug',
    },
    ['debug_pause_single_step'] = {
        action = 'WLD_SingleStep',
        category = 'game',
    },
    ['debug_restart_session'] = {
        action = 'UI_Lua RestartSession()',
        category = 'debug',
    },
    ['debug_toggle_pannels'] = {
        action = 'UI_ToggleGamePanels',
        category = 'debug',
    },
}

local keyActionsDebugAI = {
    ['toggle_navui'] = {
        action = 'UI_Lua import("/lua/ui/game/navgenerator.lua").OpenWindow()',
        category = 'ai'
    },
    ['toggle_ai_reclaim_grid_ui'] = {
        action = 'UI_Lua import("/lua/ui/game/gridreclaim.lua").OpenWindow()',
        category = 'ai'
    },
    ['toggle_ai_presence_grid_ui'] = {
        action = 'UI_Lua import("/lua/ui/game/gridpresence.lua").OpenWindow()',
        category = 'ai'
    },
    ['toggle_ai_recon_grid_ui'] = {
        action = 'UI_Lua import("/lua/ui/game/gridrecon.lua").OpenWindow()',
        category = 'ai'
    },
    ['toggle_ai_economy_ui'] = {
        action = 'UI_Lua import("/lua/ui/game/AIBrainEconomyData.lua").OpenWindow()',
        category = 'ai'
    },
    ['toggle_platoon_behavior_silo'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").AssignPlatoonBehaviorSilo()',
        category = 'ai'
    },
    ['toggle_platoon_simple_raid'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").AIPlatoonSimpleRaidBehavior()',
        category = 'ai'
    },
    ['toggle_platoon_simple_structure'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").AIPlatoonSimpleStructureBehavior()',
        category = 'ai'
    },
}

debugKeyActions = table.combine(
    keyActionsDebug,
    keyActionsDebugAI
)
