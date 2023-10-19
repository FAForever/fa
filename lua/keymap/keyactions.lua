--- A key action allows a user to bind key bindings to an action. The format
--- of a key action is defined in the 'UIKeyAction' annotation class. Key
--- actions are defined in tables. The key of a key action acts as an
--- identifier. The same identifier is used to assign a description to the
--- key action

--- In an ideal world that description would be part of the key action
--- itself. The system in place is what we have however. The descriptions
--- of key actions can be found in `/lua/keymap/keydescriptions.lua`

--- Debug key actions can be found in `/lua/keymap/debugKeyactions.lua`

---@class UIKeyAction
---@field action string
---@field category string

---@type table<string, UIKeyAction>
local keyActionsCamera = {
    ['lock_zoom'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").lockZoom()',
        category = 'camera',
    },
    ['zoom_pop'] = {
        action = "UI_Lua import('/lua/ui/game/zoompopper.lua').ToggleZoomPop()",
        category = 'camera',
    },
    ['cam_free'] = {
        action = 'Cam_Free',
        category = 'camera',
    },
    ['RestorePreviousCameraPosition'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestorePreviousCameraPosition()',
        category = 'camera',
    },
    ['SaveCameraPosition1'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(1)',
        category = 'camera',
    },
    ['SaveCameraPosition2'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(2)',
        category = 'camera',
    },
    ['SaveCameraPosition3'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(3)',
        category = 'camera',
    },
    ['SaveCameraPosition4'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(4)',
        category = 'camera',
    },
    ['SaveCameraPosition5'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(5)',
        category = 'camera',
    },
    ['SaveCameraPosition6'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(6)',
        category = 'camera',
    },
    ['SaveCameraPosition7'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(7)',
        category = 'camera',
    },
    ['SaveCameraPosition8'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(8)',
        category = 'camera',
    },
    ['SaveCameraPosition9'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(9)',
        category = 'camera',
    },
    ['SaveCameraPosition0'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").SaveCameraPosition(0)',
        category = 'camera',
    },

    ['RestoreCameraPosition1'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(1)',
        category = 'camera',
    },
    ['RestoreCameraPosition2'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(2)',
        category = 'camera',
    },
    ['RestoreCameraPosition3'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(3)',
        category = 'camera',
    },
    ['RestoreCameraPosition4'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(4)',
        category = 'camera',
    },
    ['RestoreCameraPosition5'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(5)',
        category = 'camera',
    },
    ['RestoreCameraPosition6'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(6)',
        category = 'camera',
    },
    ['RestoreCameraPosition7'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(7)',
        category = 'camera',
    },
    ['RestoreCameraPosition8'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(8)',
        category = 'camera',
    },
    ['RestoreCameraPosition9'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(9)',
        category = 'camera',
    },
    ['RestoreCameraPosition0'] = {
        action = 'UI_Lua import("/lua/usercamera.lua").RestoreCameraPosition(0)',
        category = 'camera',
    },

    ['next_cam_position'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").RecallCameraPos()',
        category = 'camera',
    },
    ['add_cam_position'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").SaveCameraPos()',
        category = 'camera',
    },
    ['rem_cam_position'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").RemoveCamPos()',
        category = 'camera',
    },
    ['zoom_in'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").ZoomIn(.02)',
        category = 'camera',
    },
    ['zoom_out'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").ZoomOut(.02)',
        category = 'camera',
    },
    ['zoom_in_fast'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").ZoomIn(.08)',
        category = 'camera',
    },
    ['zoom_out_fast'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").ZoomOut(.08)',
        category = 'camera',
    },
    ['track_unit'] = {
        action = 'UI_TrackUnit WorldCamera',
        category = 'camera',
    },
    ['track_unit_minimap'] = {
        action = 'UI_TrackUnit MiniMap',
        category = 'camera',
    },
    ['track_unit_second_mon'] = {
        action = 'UI_TrackUnit CameraHead2',
        category = 'camera',
    },
    ['reset_camera'] = {
        action = 'UI_Lua import("/lua/ui/game/zoomslider.lua").ToggleWideView()',
        category = 'camera',
    },
}

---@type table<string, UIKeyAction>
local keyActionsSelection = {
    ['cycle_idle_factories'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").CycleIdleFactories()',
        category = 'selection',
    },
    ['cycle_unit_types_in_sel'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").CycleUnitTypesInSel()',
        category = 'selection',
    },
    ['create_template_factory'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").CreateTemplateFactory()',
        category = 'selection',
    },
}

---@type table<string, UIKeyAction>
local keyActionsSelectionQuickSelect = {
    ['select_upgrading_extractors'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SelectAllUpgradingExtractors()',
        category = 'selection',
    },
    ['select_air'] = {
        action = 'UI_SelectByCategory +excludeengineers AIR MOBILE',
        category = 'selection',
    },
    ['select_naval'] = {
        action = 'UI_SelectByCategory +excludeengineers NAVAL MOBILE',
        category = 'selection',
    },
    ['select_naval_no_mobile_sonar'] = {
        action = 'UI_Lua import("/lua/keymap/smartselection.lua").smartSelect("NAVAL MOBILE -MOBILESONAR")',
        category = 'selection',
    },
    ['select_land'] = {
        action = 'UI_SelectByCategory +excludeengineers LAND MOBILE',
        category = 'selection',
    },
    ['select_all_units_of_same_type'] = {
        action = 'UI_ExpandCurrentSelection',
        category = 'selection',
    },
    ['select_engineers'] = {
        action = 'UI_SelectByCategory ENGINEER',
        category = 'selection',
    },
    ['goto_engineer'] = {
        action = 'UI_SelectByCategory +nearest +idle +goto ENGINEER',
        category = 'selection',
    },
    ['select_idle_engineer'] = {
        action = 'UI_SelectByCategory +nearest +idle ENGINEER',
        category = 'selection',
    },
    ['select_idle_t1_engineer'] = {
        action = 'UI_SelectByCategory +nearest +idle ENGINEER TECH1',
        category = 'selection',
    },
    ['cycle_engineers'] = {
        action = 'UI_Lua import("/lua/ui/game/avatars.lua").GetEngineerGeneric()',
        category = 'selection',
    },
    ['goto_commander'] = {
        action = 'UI_SelectByCategory +nearest +goto COMMAND',
        category = 'selection',
    },
    ['select_commander'] = {
        action = 'UI_SelectByCategory +nearest COMMAND',
        category = 'selection',
    },
    ['select_all'] = {
        action = 'UI_SelectByCategory ALLUNITS',
        category = 'selection',
    },
    ['select_all_onscreen'] = {
        action = 'UI_SelectByCategory +inview ALLUNITS',
        category = 'selection',
    },
    ['select_all_eng_onscreen'] = {
        action = 'UI_SelectByCategory +inview ENGINEER',
        category = 'selection',
    },
    ['select_all_factory_onscreen'] = {
        action = 'UI_SelectByCategory +inview FACTORY',
        category = 'selection',
    },
    ['select_nearest_factory'] = {
        action = 'UI_SelectByCategory +nearest FACTORY',
        category = 'selection',
    },
    ['select_all_mobile_factory_onscreen'] = {
        action = 'UI_SelectByCategory +inview EXTERNALFACTORYUNIT',
        category = 'selection',
    },
    ['select_nearest_mobile_factory'] = {
        action = 'UI_SelectByCategory +nearest EXTERNALFACTORYUNIT',
        category = 'selection',
    },
    ['select_nearest_land_factory'] = {
        action = 'UI_SelectByCategory +nearest LAND FACTORY',
        category = 'selection',
    },
    ['select_nearest_air_factory'] = {
        action = 'UI_SelectByCategory +nearest AIR FACTORY',
        category = 'selection',
    },
    ['select_nearest_naval_factory'] = {
        action = 'UI_SelectByCategory +nearest NAVAL FACTORY',
        category = 'selection',
    },
    ['select_all_radars'] = {
        action = 'UI_SelectByCategory INTELLIGENCE STRUCTURE RADAR, INTELLIGENCE STRUCTURE OMNI',
        category = 'selection',
    },
    ['select_all_idle_eng_onscreen'] = {
        action = 'UI_SelectByCategory +inview +idle ENGINEER',
        category = 'selection',
    },
    ['select_all_building_eng'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SelectAllBuildingEngineers()',
        category = 'selection',
    },
    ['select_all_building_eng_onscreen'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SelectAllBuildingEngineers(true)',
        category = 'selection',
    },['select_all_resource_consumers'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SelectAllResourceConsumers()',
        category = 'selection',
    },
    ['select_all_resource_consumers_onscreen'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SelectAllResourceConsumers(true)',
        category = 'selection',
    },
    ['select_all_land_units_onscreen'] = {
        action = 'UI_SelectByCategory +inview +excludeengineers MOBILE LAND',
        category = 'selection',
    },
    ['select_all_air_units_onscreen'] = {
        action = 'UI_SelectByCategory +inview MOBILE AIR',
        category = 'selection',
    },
    ['select_all_naval_units_onscreen'] = {
        action = 'UI_SelectByCategory +inview MOBILE NAVAL',
        category = 'selection',
    },
    ['select_all_similar_units'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetSimilarUnits()',
        category = 'selection',
    },
    ['select_next_land_factory'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetNextLandFactory()',
        category = 'selection',
    },
    ['select_next_air_factory'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetNextAirFactory()',
        category = 'selection',
    },
    ['select_next_naval_factory'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetNextNavalFactory()',
        category = 'selection',
    },
    ['toggle_mdf_panel'] = {
        action = 'UI_Lua import("/lua/ui/game/multifunction.lua").ToggleMFDPanel()',
        category = 'ui',
    },
    ['toggle_tab_display'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleTabDisplay()',
        category = 'ui',
    },
    ['select_inview_idle_mex'] = {
        action = 'UI_SelectByCategory +inview +idle MASSEXTRACTION',
        category = 'selection',
    },
    ['select_all_mex'] = {
        action = 'UI_SelectByCategory MASSEXTRACTION',
        category = 'selection',
    },
    ['select_nearest_idle_lt_mex'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetNearestIdleLTMex()',
        category = 'selection',
    },
    ['acu_select_cg'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").ACUSelectCG()',
        category = 'selection',
    },
    ['acu_append_cg'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").ACUAppendCG()',
        category = 'selection',
    },
    ['select_nearest_idle_eng_not_acu'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").GetNearestIdleEngineerNotACU()',
        category = 'selection',
    },
    ['add_nearest_idle_engineers_seq'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").AddNearestIdleEngineersSeq()',
        category = 'selection',
    },
    ['select_gunships'] = {
        action = 'UI_SelectByCategory AIR GROUNDATTACK',
        category = 'selection',
    },
    ['select_bombers'] = {
        action = 'UI_SelectByCategory AIR BOMBER',
        category = 'selection',
    },
    ['select_anti_air_fighters'] = {
        action = 'UI_Lua import("/lua/keymap/smartselection.lua").smartSelect("AIR HIGHALTAIR ANTIAIR -BOMBER -EXPERIMENTAL")',
        category = 'selection',
    },
    ['select_nearest_idle_airscout'] = {
        action = 'UI_SelectByCategory AIR INTELLIGENCE +nearest +idle',
        category = 'selection',
    },
    ['select_all_idle_airscouts'] = {
        action = 'UI_SelectByCategory AIR INTELLIGENCE +idle',
        category = 'selection',
    },
    ['select_all_tml'] = {
        action = 'UI_SelectByCategory STRUCTURE TACTICALMISSILEPLATFORM',
        category = 'selection',
    },
    ['select_all_stationdrones'] = {
        action = 'UI_SelectByCategory AIR STATIONASSISTPOD',
        category = 'selection',
    },
    ['select_all_t2_podstations'] = {
        action = 'UI_SelectByCategory STRUCTURE PODSTAGINGPLATFORM TECH2',
        category = 'selection',
    },
    ['select_all_air_exp'] = {
        action = 'UI_SelectByCategory AIR EXPERIMENTAL',
        category = 'selection',
    },
    ['select_all_antinavy_subs'] = {
        action = 'UI_SelectByCategory SUBMERSIBLE OVERLAYANTINAVY',
        category = 'selection',
    },
    ['select_all_land_exp'] = {
        action = 'UI_SelectByCategory LAND MOBILE OVERLAYDIRECTFIRE EXPERIMENTAL',
        category = 'selection',
    },
    ['select_all_land_indirectfire'] = {
        action = 'UI_SelectByCategory LAND OVERLAYINDIRECTFIRE',
        category = 'selection',
    },
    ['select_all_land_directfire'] = {
        action = 'UI_SelectByCategory +excludeengineers LAND OVERLAYDIRECTFIRE',
        category = 'selection',
    },
    ['select_all_air_factories'] = {
        action = 'UI_SelectByCategory STRUCTURE FACTORY AIR',
        category = 'selection',
    },
    ['select_all_land_factories'] = {
        action = 'UI_SelectByCategory STRUCTURE FACTORY LAND',
        category = 'selection',
    },
    ['select_all_naval_factories'] = {
        action = 'UI_SelectByCategory STRUCTURE FACTORY NAVAL',
        category = 'selection',
    },
    ['select_all_t1_engineers'] = {
        action = 'UI_SelectByCategory LAND TECH1 ENGINEER',
        category = 'selection',
    },
    ['select_all_battleships'] = {
        action = 'UI_SelectByCategory NAVAL BATTLESHIP',
        category = 'selection',
    },
    ['select_air_no_transport'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").airNoTransports()',
        category = 'selection',
    },
    ['select_air_transport'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").airTransports()',
        category = 'selection', order = 65,
    },
}

---@type table<string, UIKeyAction>
local keyActionsSelectionSubgroups = {
    ['split_next'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitNext()',
        category = 'selectionSubgroups',
    },
    ['split_major_axis'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitMajorAxis()',
        category = 'selectionSubgroups',
    },
    ['split_minor_axis'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitMinorAxis()',
        category = 'selectionSubgroups',
    },
    ['split_mouse_axis'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitMouseAxis()',
        category = 'selectionSubgroups',
    },
    ['split_mouse_axis_orthogonal'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitMouseOrthogonalAxis()',
        category = 'selectionSubgroups',
    },
    ['split_engineer_tech'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitEngineerTech()',
        category = 'selectionSubgroups',
    },
    ['split_tech'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitTech()',
        category = 'selectionSubgroups',
    },
    ['split_layer'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitLayer()',
        category = 'selectionSubgroups',
    },
    ['split_into_groups_1'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitIntoGroups(1)',
        category = 'selectionSubgroups',
    },
    ['split_into_groups_2'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitIntoGroups(2)',
        category = 'selectionSubgroups',
    },
    ['split_into_groups_4'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitIntoGroups(4)',
        category = 'selectionSubgroups',
    },
    ['split_into_groups_8'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitIntoGroups(8)',
        category = 'selectionSubgroups',
    },
    ['split_into_groups_16'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").SplitIntoGroups(16)',
        category = 'selectionSubgroups',
    },
}

---@type table<string, UIKeyAction>
local keyActionsSelectionControupGroups = {
    ['revert_selection_set'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").RevertSelectionSet()',
        category = 'selectionControlGroups',
    },
    ['group1'] = {
        action = 'UI_ApplySelectionSet 1',
        category = 'selectionControlGroups',
    },
    ['group2'] = {
        action = 'UI_ApplySelectionSet 2',
        category = 'selectionControlGroups',
    },
    ['group3'] = {
        action = 'UI_ApplySelectionSet 3',
        category = 'selectionControlGroups',
    },
    ['group4'] = {
        action = 'UI_ApplySelectionSet 4',
        category = 'selectionControlGroups',
    },
    ['group5'] = {
        action = 'UI_ApplySelectionSet 5',
        category = 'selectionControlGroups',
    },
    ['group6'] = {
        action = 'UI_ApplySelectionSet 6',
        category = 'selectionControlGroups',
    },
    ['group7'] = {
        action = 'UI_ApplySelectionSet 7',
        category = 'selectionControlGroups',
    },
    ['group8'] = {
        action = 'UI_ApplySelectionSet 8',
        category = 'selectionControlGroups',
    },
    ['group9'] = {
        action = 'UI_ApplySelectionSet 9',
        category = 'selectionControlGroups',
    },
    ['group0'] = {
        action = 'UI_ApplySelectionSet 0',

        category = 'selectionControlGroups',
    },
    ['set_group1'] = {
        action = 'UI_MakeSelectionSet 1',
        category = 'selectionControlGroups',
    },
    ['set_group2'] = {
        action = 'UI_MakeSelectionSet 2',
        category = 'selectionControlGroups',
    },
    ['set_group3'] = {
        action = 'UI_MakeSelectionSet 3',
        category = 'selectionControlGroups',
    },
    ['set_group4'] = {
        action = 'UI_MakeSelectionSet 4',
        category = 'selectionControlGroups',
    },
    ['set_group5'] = {
        action = 'UI_MakeSelectionSet 5',
        category = 'selectionControlGroups',
    },
    ['set_group6'] = {
        action = 'UI_MakeSelectionSet 6',
        category = 'selectionControlGroups',
    },
    ['set_group7'] = {
        action = 'UI_MakeSelectionSet 7',
        category = 'selectionControlGroups',
    },
    ['set_group8'] = {
        action = 'UI_MakeSelectionSet 8',
        category = 'selectionControlGroups',
    },
    ['set_group9'] = {
        action = 'UI_MakeSelectionSet 9',
        category = 'selectionControlGroups',
    },
    ['set_group0'] = {
        action = 'UI_MakeSelectionSet 0',
        category = 'selectionControlGroups',
    },

    ['append_group1'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(1)',
        category = 'selectionControlGroups'
    },
    ['append_group2'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(2)',
        category = 'selectionControlGroups'
    },
    ['append_group3'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(3)',
        category = 'selectionControlGroups'
    },
    ['append_group4'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(4)',
        category = 'selectionControlGroups'
    },
    ['append_group5'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(5)',
        category = 'selectionControlGroups'
    },
    ['append_group6'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(6)',
        category = 'selectionControlGroups'
    },
    ['append_group7'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(7)',
        category = 'selectionControlGroups'
    },
    ['append_group8'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(8)',
        category = 'selectionControlGroups'
    },
    ['append_group9'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(9)',
        category = 'selectionControlGroups'
    },
    ['append_group0'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSetToSelection(0)',
        category = 'selectionControlGroups'
    },

    ['add_selection_to_selection_set1'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(1)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set2'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(2)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set3'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(3)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set4'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(4)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set5'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(5)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set6'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(6)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set7'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(7)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set8'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(8)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set9'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(9)',
        category = 'selectionControlGroups'
    },
    ['add_selection_to_selection_set0'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").AppendSelectionToSet(0)',
        category = 'selectionControlGroups'
    },

    ['combine_and_select_with_selection_set1'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(1)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set2'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(2)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set3'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(3)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set4'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(4)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set5'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(5)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set6'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(6)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set7'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(7)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set8'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(8)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set9'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(9)',
        category = 'selectionControlGroups'
    },
    ['combine_and_select_with_selection_set0'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").CombineSelectionAndSet(0)',
        category = 'selectionControlGroups'
    },

    ['fac_group1'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(1)',
        category = 'selectionControlGroups',
    },
    ['fac_group2'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(2)',
        category = 'selectionControlGroups',
    },
    ['fac_group3'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(3)',
        category = 'selectionControlGroups',
    },
    ['fac_group4'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(4)',
        category = 'selectionControlGroups',
    },
    ['fac_group5'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(5)',
        category = 'selectionControlGroups',
    },
    ['fac_group6'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(6)',
        category = 'selectionControlGroups',
    },
    ['fac_group7'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(7)',
        category = 'selectionControlGroups',
    },
    ['fac_group8'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(8)',
        category = 'selectionControlGroups',
    },
    ['fac_group9'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(9)',
        category = 'selectionControlGroups',
    },
    ['fac_group0'] = {
        action = 'UI_Lua import("/lua/ui/game/selection.lua").FactorySelection(0)',
        category = 'selectionControlGroups',
    },
}

---@type table<string, UIKeyAction>
local keyActionsHotBuild = {
    ['builders'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Builders")',
        category = 'hotbuilding',
    },
    ['sensors'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Sensors")',
        category = 'hotbuilding',
    },
    ['shields'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Shields")',
        category = 'hotbuilding',
    },
    ['tmd'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("TMD")',
        category = 'hotbuilding',
    },
    ['xp'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("XP")',
        category = 'hotbuilding',
    },
    ['mobilearty'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Mobilearty")',
        category = 'hotbuilding',
    },
    ['mass'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Mass")',
        category = 'hotbuilding',
    },
    ['massfab'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("MassFab")',
        category = 'hotbuilding',
    },
    ['pgen'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Pgen")',
        category = 'hotbuilding',
    },
    ['templates'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Templates")',
        category = 'hotbuilding',
    },
    ['cycle_templates'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Cycle_Templates")',
        category = 'hotbuilding',
    },
    ['engystation'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("EngyStation")',
        category = 'hotbuilding',
    },
    ['mml'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("MML")',
        category = 'hotbuilding',
    },
    ['mobileshield'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("MobileShield")',
        category = 'hotbuilding',
    },
    ['fieldengy'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("FieldEngy")',
        category = 'hotbuilding',
    },
    ['defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Defense")',
        category = 'hotbuilding',
    },
    ['aa'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("AA")',
        category = 'hotbuilding',
    },
    ['torpedo'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Torpedo")',
        category = 'hotbuilding',
    },
    ['arties'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Arties")',
        category = 'hotbuilding',
    },
    ['tml'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("TML")',
        category = 'hotbuilding',
    },
    ['upgrades'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Upgrades")',
        category = 'hotbuilding',
    },
}

---@type table<string, UIKeyAction>
local keyActionsHotBuildAlternative = {
    ['alt_builders'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Builders")',
        category = 'hotbuildingAlternative',
    },
    ['alt_radars'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Radars")',
        category = 'hotbuildingAlternative',
    },
    ['alt_shields'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Shields")',
        category = 'hotbuildingAlternative',
    },
    ['alt_tmd'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_TMD")',
        category = 'hotbuildingAlternative',
    },
    ['alt_xp'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_XP")',
        category = 'hotbuildingAlternative',
    },
    ['alt_sonars'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Sonars")',
        category = 'hotbuildingAlternative',
    },
    ['alt_mass'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Mass")',
        category = 'hotbuildingAlternative',
    },
    ['alt_stealth'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Stealth")',
        category = 'hotbuildingAlternative',
    },
    ['alt_pgen'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Pgen")',
        category = 'hotbuildingAlternative',
    },
    ['alt_templates'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Templates")',
        category = 'hotbuildingAlternative',
    },
    ['alt_engystation'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_EngyStation")',
        category = 'hotbuildingAlternative',
    },
    ['alt_defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Defense")',
        category = 'hotbuildingAlternative',
    },
    ['alt_aa'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_AA")',
        category = 'hotbuildingAlternative',
    },
    ['alt_torpedo'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Torpedo")',
        category = 'hotbuildingAlternative',
    },
    ['alt_arties'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_Arties")',
        category = 'hotbuildingAlternative',
    },
    ['alt_tml'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Alt_TML")',
        category = 'hotbuildingAlternative',
    },
}

---@type table<string, UIKeyAction>
local keyActionsHotBuildExtra = {
    ['land_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Land_Factory")',
        category = 'hotbuildingExtra',
    },
    ['air_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Air_Factory")',
        category = 'hotbuildingExtra',
    },
    ['naval_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Naval_Factory")',
        category = 'hotbuildingExtra',
    },
    ['quantum_gateway'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Quantum_Gateway")',
        category = 'hotbuildingExtra',
    },
    ['power_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Power_Generator")',
        category = 'hotbuildingExtra',
    },
    ['hydrocarbon_power_plant'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Hydrocarbon_Power_Plant")',
        category = 'hotbuildingExtra',
    },
    ['mass_extractor'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Mass_Extractor")',
        category = 'hotbuildingExtra',
    },
    ['mass_fabricator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Mass_Fabricator")',
        category = 'hotbuildingExtra',
    },
    ['energy_storage'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Energy_Storage")',
        category = 'hotbuildingExtra',
    },
    ['mass_storage'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Mass_Storage")',
        category = 'hotbuildingExtra',
    },
    ['point_defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Point_Defense")',
        category = 'hotbuildingExtra',
    },
    ['anti_air'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Anti_Air")',
        category = 'hotbuildingExtra',
    },
    ['tactical_missile_launcher'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Tactical_Missile_Launcher")',
        category = 'hotbuildingExtra',
    },
    ['torpedo_launcher'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Torpedo_Launcher")',
        category = 'hotbuildingExtra',
    },
    ['heavy_artillery_installation'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Heavy_Artillery_Installation")',
        category = 'hotbuildingExtra',
    },
    ['artillery_installation'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Artillery_Installation")',
        category = 'hotbuildingExtra',
    },
    ['strategic_missile_launcher'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Strategic_Missile_Launcher")',
        category = 'hotbuildingExtra',
    },
    ['radar_system'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Radar_System")',
        category = 'hotbuildingExtra',
    },
    ['sonar_system'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Sonar_System")',
        category = 'hotbuildingExtra',
    },
    ['omni_sensor'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Omni_Sensor")',
        category = 'hotbuildingExtra',
    },
    ['tactical_missile_defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Tactical_Missile_Defense")',
        category = 'hotbuildingExtra',
    },
    ['shield_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Shield_Generator")',
        category = 'hotbuildingExtra',
    },
    ['stealth_field_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Stealth_Field_Generator")',
        category = 'hotbuildingExtra',
    },
    ['heavy_shield_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Heavy_Shield_Generator")',
        category = 'hotbuildingExtra',
    },
    ['strategic_missile_defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Strategic_Missile_Defense")',
        category = 'hotbuildingExtra',
    },
    ['wall_section'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Wall_Section")',
        category = 'hotbuildingExtra',
    },
    ['aeon_quantum_gate_beacon'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Aeon_Quantum_Gate_Beacon")',
        category = 'hotbuildingExtra',
    },
    ['air_staging'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Air_Staging")',
        category = 'hotbuildingExtra',
    },
    ['sonar_platform'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Sonar_Platform")',
        category = 'hotbuildingExtra',
    },
    ['rapid_fire_artillery_installation'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Rapid_Fire_Artillery_Installation")',
        category = 'hotbuildingExtra',
    },
    ['quantum_optics_facility'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Quantum_Optics_Facility")',
        category = 'hotbuildingExtra',
    },
    ['engineering_station'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Engineering_Station")',
        category = 'hotbuildingExtra',
    },
    ['heavy_point_defense'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Heavy_Point_Defense")',
        category = 'hotbuildingExtra',
    },
    ['torpedo_ambushing_system'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Torpedo_Ambushing_System")',
        category = 'hotbuildingExtra',
    },
    ['perimeter_monitoring_system'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("Perimeter_Monitoring_System")',
        category = 'hotbuildingExtra',
    },
    ['t2_guided_missile'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Guided_Missile")',
        category = 'hotbuildingExtra',
    },
    ['t3_shield_disruptor'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Shield_Disruptor")',
        category = 'hotbuildingExtra',
    },
    ['t2_fighter/bomber'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Fighter/Bomber")',
        category = 'hotbuildingExtra',
    },
    ['t2_gatling_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Gatling_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t2_rocket_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Rocket_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t1_air_scout'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Air_Scout")',
        category = 'hotbuildingExtra',
    },
    ['t1_interceptor'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Interceptor")',
        category = 'hotbuildingExtra',
    },
    ['t1_attack_bomber'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Attack_Bomber")',
        category = 'hotbuildingExtra',
    },
    ['t2_air_transport'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Air_Transport")',
        category = 'hotbuildingExtra',
    },
    ['t1_light_air_transport'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Light_Air_Transport")',
        category = 'hotbuildingExtra',
    },
    ['t2_gunship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Gunship")',
        category = 'hotbuildingExtra',
    },
    ['t2_torpedo_bomber'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Torpedo_Bomber")',
        category = 'hotbuildingExtra',
    },
    ['t3_spy_plane'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Spy_Plane")',
        category = 'hotbuildingExtra',
    },
    ['t3_air_superiority_fighter'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Air_Superiority_Fighter")',
        category = 'hotbuildingExtra',
    },
    ['t3_strategic_bomber'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Strategic_Bomber")',
        category = 'hotbuildingExtra',
    },
    ['t1_land_scout'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Land_Scout")',
        category = 'hotbuildingExtra',
    },
    ['t1_mobile_light_artillery'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Mobile_Light_Artillery")',
        category = 'hotbuildingExtra',
    },
    ['t1_mobile_anti_air_gun'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Mobile_Anti_Air_Gun")',
        category = 'hotbuildingExtra',
    },
    ['t1_engineer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Engineer")',
        category = 'hotbuildingExtra',
    },
    ['t1_light_assault_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Light_Assault_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_missile_launcher'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_Missile_Launcher")',
        category = 'hotbuildingExtra',
    },
    ['t1_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t2_heavy_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Heavy_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_aa_flak_artillery'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_AA_Flak_Artillery")',
        category = 'hotbuildingExtra',
    },
    ['t2_engineer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Engineer")',
        category = 'hotbuildingExtra',
    },
    ['t3_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t3_mobile_heavy_artillery'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Mobile_Heavy_Artillery")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_shield_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_Shield_Generator")',
        category = 'hotbuildingExtra',
    },
    ['t3_engineer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Engineer")',
        category = 'hotbuildingExtra',
    },
    ['t1_attack_boat'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Attack_Boat")',
        category = 'hotbuildingExtra',
    },
    ['t1_frigate'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Frigate")',
        category = 'hotbuildingExtra',
    },
    ['t2_destroyer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Destroyer")',
        category = 'hotbuildingExtra',
    },
    ['t2_cruiser'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Cruiser")',
        category = 'hotbuildingExtra',
    },
    ['t1_attack_submarine'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Attack_Submarine")',
        category = 'hotbuildingExtra',
    },
    ['t3_battleship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Battleship")',
        category = 'hotbuildingExtra',
    },
    ['t3_aircraft_carrier'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Aircraft_Carrier")',
        category = 'hotbuildingExtra',
    },
    ['t3_strategic_missile_submarine'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Strategic_Missile_Submarine")',
        category = 'hotbuildingExtra',
    },
    ['t3_heavy_gunship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Heavy_Gunship")',
        category = 'hotbuildingExtra',
    },
    ['t2_amphibious_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Amphibious_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t1_assault_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Assault_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t3_siege_assault_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Siege_Assault_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_stealth_field_system'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_Stealth_Field_System")',
        category = 'hotbuildingExtra',
    },
    ['t2_combat_fighter'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Combat_Fighter")',
        category = 'hotbuildingExtra',
    },
    ['t3_aa_gunship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_AA_Gunship")',
        category = 'hotbuildingExtra',
    },
    ['t3_torpedo_bomber'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Torpedo_Bomber")',
        category = 'hotbuildingExtra',
    },
    ['t2_assault_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Assault_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t3_sniper_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Sniper_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t2_submarine_hunter'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Submarine_Hunter")',
        category = 'hotbuildingExtra',
    },
    ['t3_missile_ship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Missile_Ship")',
        category = 'hotbuildingExtra',
    },
    ['t3_heavy_air_transport'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Heavy_Air_Transport")',
        category = 'hotbuildingExtra',
    },
    ['t2_field_engineer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Field_Engineer")',
        category = 'hotbuildingExtra',
    },
    ['t3_armored_assault_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Armored_Assault_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t3_mobile_missile_platform'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Mobile_Missile_Platform")',
        category = 'hotbuildingExtra',
    },
    ['t2_torpedo_boat'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Torpedo_Boat")',
        category = 'hotbuildingExtra',
    },
    ['t2_shield_boat'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Shield_Boat")',
        category = 'hotbuildingExtra',
    },
    ['t3_battlecruiser'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Battlecruiser")',
        category = 'hotbuildingExtra',
    },
    ['t1_light_gunship'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Light_Gunship")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_bomb'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_Bomb")',
        category = 'hotbuildingExtra',
    },
    ['t2_submarine_killer'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Submarine_Killer")',
        category = 'hotbuildingExtra',
    },
    ['t2_counter_intelligence_boat'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Counter_Intelligence_Boat")',
        category = 'hotbuildingExtra',
    },
    ['t1_combat_scout'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T1_Combat_Scout")',
        category = 'hotbuildingExtra',
    },
    ['t2_assault_bot'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Assault_Bot")',
        category = 'hotbuildingExtra',
    },
    ['t2_hover_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Hover_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t2_mobile_anti_air_cannon'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Mobile_Anti_Air_Cannon")',
        category = 'hotbuildingExtra',
    },
    ['t3_siege_tank'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Siege_Tank")',
        category = 'hotbuildingExtra',
    },
    ['t3_mobile_shield_generator'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Mobile_Shield_Generator")',
        category = 'hotbuildingExtra',
    },
    ['t3_submarine_hunter'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Submarine_Hunter")',
        category = 'hotbuildingExtra',
    },
    ['t3_mobile_aa'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Mobile_AA")',
        category = 'hotbuildingExtra',
    },
    ['t2_support_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Support_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t2_support_land_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Support_Land_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t2_support_air_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Support_Air_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t2_support_naval_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T2_Support_Naval_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t3_support_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Support_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t3_support_land_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Support_Land_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t3_support_air_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Support_Air_Factory")',
        category = 'hotbuildingExtra',
    },
    ['t3_support_naval_factory'] = {
        action = 'UI_Lua import("/lua/keymap/hotbuild.lua").buildAction("T3_Support_Naval_Factory")',
        category = 'hotbuildingExtra',
    },
}

---@type table<string, UIKeyAction>
local keyActionsOrders = {

    ['repair'] = {
        action = 'StartCommandMode order RULEUCC_Repair',
        category = 'orders',
    },
    ['reclaim'] = {
        action = 'StartCommandMode order RULEUCC_Reclaim',
        category = 'orders',
    },
    ['patrol'] = {
        action = 'StartCommandMode order RULEUCC_Patrol',
        category = 'orders',
    },
    ['attack'] = {
        action = 'StartCommandMode order RULEUCC_Attack',
        category = 'orders',
    },
    ['capture'] = {
        action = 'StartCommandMode order RULEUCC_Capture',
        category = 'orders',
    },
    ['stop'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").Stop()',
        category = 'orders',
    },
    ['soft_stop'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").SoftStop()',
        category = 'orders',
    },
    ['dive'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").ToggleDiveOrder()',
        category = 'orders',
    },
    ['dive_all'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").DiveAll()',
        category = 'orders',
    },
    ['undive_all'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SurfaceAll()',
        category = 'orders',
    },
    ['shift_dive_all'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").DiveAll()',
        category = 'orders',
    },
    ['shift_undive_all'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").SurfaceAll()',
        category = 'orders',
    },
    ['ferry'] = {
        action = 'StartCommandMode order RULEUCC_Ferry',
        category = 'orders',
    },
    ['guard'] = {
        action = 'StartCommandMode order RULEUCC_Guard',
        category = 'orders',
    },
    ['transport'] = {
        action = 'StartCommandMode order RULEUCC_Transport',
        category = 'orders',
    },
    ['launch_tactical'] = {
        action = 'StartCommandMode order RULEUCC_Tactical',
        category = 'orders',
    },
    ['overcharge'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").EnterOverchargeMode()',
        category = 'orders',
    },
    ['move'] = {
        action = 'StartCommandMode order RULEUCC_Move',
        category = 'orders',
    },
    ['move_hard'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").ToggleHardMove()',
        category = 'orders',
    },
    ['nuke'] = {
        action = 'StartCommandMode order RULEUCC_Nuke',
        category = 'orders',
    },
    ['shift_repair'] = {
        action = 'StartCommandMode order RULEUCC_Repair',
        category = 'orders',
    },
    ['shift_reclaim'] = {
        action = 'StartCommandMode order RULEUCC_Reclaim',
        category = 'orders',
    },
    ['shift_patrol'] = {
        action = 'StartCommandMode order RULEUCC_Patrol',
        category = 'orders',
    },
    ['shift_attack'] = {
        action = 'StartCommandMode order RULEUCC_Attack',
        category = 'orders',
    },
    ['shift_capture'] = {
        action = 'StartCommandMode order RULEUCC_Capture',
        category = 'orders',
    },
    ['shift_stop'] = {
        action = 'IssueCommand Stop',
        category = 'orders',
    },
    ['shift_dive'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").ToggleDiveOrder()',
        category = 'orders',
    },
    ['shift_ferry'] = {
        action = 'StartCommandMode order RULEUCC_Ferry',
        category = 'orders',
    },
    ['shift_guard'] = {
        action = 'StartCommandMode order RULEUCC_Guard',
        category = 'orders',
    },
    ['shift_transport'] = {
        action = 'StartCommandMode order RULEUCC_Transport',
        category = 'orders',
    },
    ['shift_launch_tactical'] = {
        action = 'StartCommandMode order RULEUCC_Tactical',
        category = 'orders',
    },
    ['shift_overcharge'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").EnterOverchargeMode()',
        category = 'orders',
    },
    ['shift_move'] = {
        action = 'StartCommandMode order RULEUCC_Move',
        category = 'orders',
    },
    ['shift_nuke'] = {
        action = 'StartCommandMode order RULEUCC_Nuke',
        category = 'orders',
    },
    ['toggle_build_mode'] = {
        action = 'UI_Lua import("/lua/ui/game/buildmode.lua").ToggleBuildMode()',
        category = 'orders',
    },
    ['pause_unit'] = {
        action = 'UI_Lua import("/lua/ui/game/construction.lua").ToggleUnitPause()',
        category = 'orders',
    },
    ['pause_unit_all'] = {
        action = 'UI_Lua import("/lua/ui/game/construction.lua").ToggleUnitPauseAll()',
        category = 'orders',
    },
    ['unpause_unit_all'] = {
        action = 'UI_Lua import("/lua/ui/game/construction.lua").ToggleUnitUnpauseAll()',
        category = 'orders',
    },
    ['mode'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").CycleRetaliateStateUp()',
        category = 'orders',
    },
    ['suicide'] = {
        action = 'UI_Lua import("/lua/ui/game/confirmunitdestroy.lua").ConfirmUnitDestruction(false)',
        category = 'orders',
    },
    ['set_default_target_priority'] = {
        action = 'UI_LUA import("/lua/keymap/misckeyactions.lua").SetDefaultWeaponPriorities()',
        category = 'orders',
    },
    ['toggle_shield'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Shield")',
        category = 'orders',
    },
    ['toggle_weapon'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Weapon")',
        category = 'orders',
    },
    ['toggle_jamming'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Jamming")',
        category = 'orders',
    },
    ['toggle_intel'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Intel")',
        category = 'orders',
    },
    ['toggle_production'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Production")',
        category = 'orders',
    },
    ['toggle_stealth'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Stealth")',
        category = 'orders',
    },
    ['toggle_generic'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Generic")',
        category = 'orders',
    },
    ['toggle_special'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Special")',
        category = 'orders',
    },
    ['toggle_cloak'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleScript("Cloak")',
        category = 'orders',
    },
    ['toggle_all'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleAllScript()',
        category = 'orders',
    },
    ['teleport'] = {
        action = 'StartCommandMode order RULEUCC_Teleport',
        category = 'orders',
    },
    ['toggle_repeat_build'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").ToggleRepeatBuild()',
        category = 'orders',
    },
    ['toggle_cloakjammingstealth'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleCloakJammingStealthScript()',
        category = 'orders',
    },
    ['toggle_intelshield'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleIntelShieldScript()',
        category = 'orders',
    },
    ['Kill_Selected_Units'] = {
        action = 'UI_Lua import("/lua/ui/game/confirmunitdestroy.lua").ConfirmUnitDestruction(true)',
        category = 'orders',
    },
    ['Kill_All'] = {
        action = 'UI_Lua import("/lua/ui/game/confirmunitdestroy.lua").ConfirmUnitDestruction(true, true)',
        category = 'orders',
    },
    ['dock'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").Dock(true)',
        category = 'orders',
    },
    ['shift_dock'] = {
        action = 'UI_Lua import("/lua/ui/game/orders.lua").Dock(false)',
        category = 'orders',
    },
}

local keyActionsOrdersAdvanced = {
    ['load_transports'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/load-in-transport.lua").LoadIntoTransports(false)',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#load-into-transports'
    },
    ['load_transports_clear'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/load-in-transport.lua").LoadIntoTransports(true)',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#load-into-transports'
    },
    ['shift_load_transports'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/load-in-transport.lua").LoadIntoTransports(false)',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#load-into-transports'
    },
    ['shift_load_transports_clear'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/load-in-transport.lua").LoadIntoTransports(true)',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#load-into-transports'
    },
    ['filter_highest_engineer_and_assist'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/filter-engineers.lua").SelectHighestEngineerAndAssist()',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#filter-engineers'
    },
    ['shift_filter_highest_engineer_and_assist'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/filter-engineers.lua").SelectHighestEngineerAndAssist()',
        category = 'ordersAdvanced',
        wikiURL = 'Play/Game/Hotkeys/OrdersAdvanced#filter-engineers'
    },
}

local keyActionsOrdersQueueBased = {
    ['spreadattack'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/distribute-queue.lua").DistributeOrders(true)',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#distribute-orders'
    },
    ['shift_spreadattack'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/distribute-queue.lua").DistributeOrders(true)',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#distribute-orders'
    },
    ['spreadattack_context'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/distribute-queue.lua").DistributeOrdersOfMouseContext(true)',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#distribute-orders'
    },
    ['shift_spreadattack_context'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/distribute-queue.lua").DistributeOrdersOfMouseContext(true)',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#distribute-orders'
    },
    ['copy_orders'] = {
        action = 'UI_LUA import("/lua/ui/game/hotkeys/copy-queue.lua").CopyOrders()',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#copy-orders'
    },
    ['shift_copy_orders'] = {
        action = 'UI_LUA import("/lua/ui/game/hotkeys/copy-queue.lua").CopyOrders()',
        category = 'ordersQueueBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersQueueManipulation#copy-orders'
    },
}

local keyactionsOrdersContextBased = {
    ['cycle_context_based_templates'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/context-based-templates.lua").Cycle()',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#cycle-templates'
    },
    ['shift_cycle_context_based_templates'] = {
        action = 'UI_Lua import("/lua/ui/game/hotkeys/context-based-templates.lua").Cycle()',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#cycle-templates'
    },
    ['set_target_priority'] = {
        action = 'UI_LUA import("/lua/keymap/misckeyactions.lua").SetWeaponPrioritiesToUnitType()',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#apply-target-priorities'
    },
    ['shift_set_target_priority'] = {
        action = 'UI_LUA import("/lua/keymap/misckeyactions.lua").SetWeaponPrioritiesToUnitType()',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#apply-target-priorities'
    },

    ['cap'] = {
        action = 'UI_LUA import("/lua/ui/game/hotkeys/capping.lua").HotkeyToCap(true, true)',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#cap-a-structure'
    },

    ['shift_cap'] = {
        action = 'UI_LUA import("/lua/ui/game/hotkeys/capping.lua").HotkeyToCap(true, false)',
        category = 'ordersContextBased',
        wikiURL = 'Play/Game/Hotkeys/OrdersMouseContext#cap-a-structure'
    },

    ['upgrade_structure'] = { 
        action = 'UI_LUA import("/lua/ui/game/hotkeys/upgrade-structure.lua").UpgradeStructure()',
        category = 'ordersContextBased',
        wikiURL = '/Play/Game/Hotkeys/OrdersMouseContext#upgrade-a-structure'
    },

    ['shift_upgrade_structure'] = { 
        action = 'UI_LUA import("/lua/ui/game/hotkeys/upgrade-structure.lua").UpgradeStructure()',
        category = 'ordersContextBased',
        wikiURL = '/Play/Game/Hotkeys/OrdersMouseContext#upgrade-a-structure'
    },

    ['upgrade_structure_pause'] = { 
        action = 'UI_LUA import("/lua/ui/game/hotkeys/upgrade-structure.lua").UpgradeStructure(true)',
        category = 'ordersContextBased',
        wikiURL = '/Play/Game/Hotkeys/OrdersMouseContext#upgrade-a-structure'
    },

    ['shift_upgrade_structure_pause'] = { 
        action = 'UI_LUA import("/lua/ui/game/hotkeys/upgrade-structure.lua").UpgradeStructure(true)',
        category = 'ordersContextBased',
        wikiURL = '/Play/Game/Hotkeys/OrdersMouseContext#upgrade-a-structure'
    }
}

---@type table<string, UIKeyAction>
local keyActionsGame = {
    ['toggle_lifebars'] = {
        action = 'UI_RenderUnitBars',
        category = 'ui',
    },
    ['tog_military'] = {
        action = 'UI_Lua import("/lua/ui/game/multifunction.lua").ToggleMilitary()',
        category = 'ui',
    },
    ['tog_defense'] = {
        action = 'UI_Lua import("/lua/ui/game/multifunction.lua").ToggleDefense()',
        category = 'ui',
    },
    ['tog_econ'] = {
        action = 'UI_Lua import("/lua/ui/game/multifunction.lua").ToggleEconomy()',
        category = 'ui',
    },
    ['switch_layout_up'] = {
        action = 'UI_RotateLayout +',
        category = 'ui',
    },
    ['switch_layout_down'] = {
        action = 'UI_RotateLayout -',
        category = 'ui',
    },
    ['switch_skin_down'] = {
        action = 'UI_RotateSkin -',
        category = 'ui',
    },
    ['switch_skin_up'] = {
        action = 'UI_RotateSkin +',
        category = 'ui',
    },
    ['escape'] = {
        action = 'UI_Lua import("/lua/ui/uimain.lua").EscapeHandler()',
        category = 'ui',
    },
    ['pause'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").TogglePause()',
        category = 'ui',
    },
    ['Render_SelectionSet_Names'] = {
        action = 'ui_RenderSelectionSetNames',
        category = 'ui',
    },
    ['Render_Custom_Names'] = {
        action = 'ui_RenderCustomNames',
        category = 'ui',
    },
    ['Render_Unit_Bars'] = {
        action = 'ui_RenderUnitBars',
        category = 'ui',
    },
    ['Render_Icons'] = {
        action = 'ui_RenderIcons',
        category = 'ui',
    },
    ['Always_Render_Strategic_Icons'] = {
        action = 'ui_AlwaysRenderStrategicIcons',
        category = 'ui',
    },
    ['Show_Bandwidth_Usage'] = {
        action = 'ren_ShowBandwidthUsage',
        category = 'ui',
    },
    ['Execute_Paste_Buffer'] = {
        action = 'ExecutePasteBuffer',
        category = 'ui',
    },
    ['decrease_game_speed'] = {
        action = 'UI_Lua import("/lua/ui/uimain.lua").DecreaseGameSpeed()',
        category = 'game',
    },
    ['increase_game_speed'] = {
        action = 'UI_Lua import("/lua/ui/uimain.lua").IncreaseGameSpeed()',
        category = 'game',
    },
    ['reset_game_speed'] = {
        action = 'WLD_ResetSimRate',
        category = 'game',
    },
    ['quick_save'] = {
        action = 'UI_Lua import("/lua/ui/game/gamemain.lua").QuickSave(LOC("<LOC QuickSave>QuickSave"))',
        category = 'ui',
    },
    ['toggle_key_bindings'] = {
        action = 'UI_Lua import("/lua/ui/dialogs/keybindings.lua").CreateUI()',
        category = 'ui',
    },
    ['create_build_template'] = {
        action = 'UI_Lua import("/lua/ui/game/build_templates.lua").CreateBuildTemplate()',
        category = 'selection'
    },
    ['cap_frame'] = {
        action = 'Dump_Frame',
        category = 'ui',
    },
    ['military_overlay'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleOverlay("Military")',
        category = 'ui',
    },
    ['intel_overlay'] = {
        action = 'UI_Lua import("/lua/keymap/misckeyactions.lua").toggleOverlay("Intel")',
        category = 'ui',
    },
    ['show_enemy_life'] = {
        action = 'UI_ForceLifbarsOnEnemy',
        category = 'ui',
    },
}

---@type table<string, UIKeyAction>
local keyActionsChat = {
    ['chat_page_up'] = {
        action = 'UI_Lua import("/lua/ui/game/chat.lua").ChatPageUp(10)',
        category = 'chat',
    },
    ['chat_page_down'] = {
        action = 'UI_Lua import("/lua/ui/game/chat.lua").ChatPageDown(10)',
        category = 'chat',
    },
    ['chat_line_up'] = {
        action = 'UI_Lua import("/lua/ui/game/chat.lua").ChatPageUp(1)',
        category = 'chat',
    },
    ['chat_line_down'] = {
        action = 'UI_Lua import("/lua/ui/game/chat.lua").ChatPageDown(1)',
        category = 'chat',
    },
}

---@type table<string, UIKeyAction>
local keyActionsUI = {
    ['rename'] = {
        action = 'UI_ShowRenameDialog',
        category = 'ui',
    },
    ['split_screen_enable'] = {
        action = 'UI_Lua import("/lua/ui/game/borders.lua").SplitMapGroup(true)',
        category = 'ui',
    },
    ['split_screen_disable'] = {
        action = 'UI_Lua import("/lua/ui/game/borders.lua").SplitMapGroup(false)',
        category = 'ui',
    },
    ['toggle_notify_customiser'] = {
        action = 'UI_Lua import("/lua/ui/notify/customiser.lua").CreateUI()',
        category = 'ui',
    },
    ['toggle_score_screen'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleScore()',
        category = 'ui',
    },
    ['toggle_mass_fabricator_panel'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleMassFabricatorPanel()',
        category = 'ui',
    },
    ['toggle_voting_panel'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleVotingPanel()',
        category = 'ui',
    },
    ['toggle_diplomacy_screen'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleTab("diplomacy")',
        category = 'ui',
    },
    ['ping_alert'] = {
        action = 'UI_Lua import("/lua/ui/game/ping.lua").DoPing("alert")',
        category = 'ui',
    },
    ['ping_move'] = {
        action = 'UI_Lua import("/lua/ui/game/ping.lua").DoPing("move")',
        category = 'ui',
    },
    ['ping_attack'] = {
        action = 'UI_Lua import("/lua/ui/game/ping.lua").DoPing("attack")',
        category = 'ui',
    },
    ['ping_marker'] = {
        action = 'UI_Lua import("/lua/ui/game/ping.lua").DoPing("marker")',
        category = 'ui',
    },
    ['toggle_main_menu'] = {
        action = 'UI_Lua import("/lua/ui/game/tabs.lua").ToggleTab("main")',
        category = 'ui',
    },
    ['toggle_disconnect_screen'] = {
        action = 'UI_Lua import("/lua/ui/game/connectivity.lua").CreateUI()',
        category = 'ui',
    },
    ['toggle_reclaim_labels'] = {
        action = 'UI_Lua import("/lua/ui/game/reclaim.lua").ToggleReclaim()',
        category = 'ui'
    },
    ['show_objective_screen'] = {
        action = 'UI_Lua import("/lua/ui/game/objectivedetail.lua").ToggleDisplay()',
        category = 'ui'
    },
}

---@type table<string, UIKeyAction>
local keyActionsMisc = {

}

---@type table<string, UIKeyAction>
keyActions = table.combine(
    keyActionsCamera,
    keyActionsSelection,
    keyActionsSelectionQuickSelect,
    keyActionsSelectionSubgroups,
    keyActionsSelectionControupGroups,
    keyActionsHotBuild,
    keyActionsHotBuildAlternative,
    keyActionsHotBuildExtra,
    keyActionsOrders,
    keyActionsOrdersAdvanced,
    keyActionsOrdersQueueBased,
    keyactionsOrdersContextBased,
    keyActionsGame,
    keyActionsChat,
    keyActionsUI,
    keyActionsMisc
)
