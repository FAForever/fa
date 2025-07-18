-- ****************************************************************************
-- **  File     :  lua/modules/ui/help/lua
-- **  Author(s):  Ted Snook
-- **
-- **  Summary  :  Strings and images for the tooltips System
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

Tooltips = {
    -- *******************
    -- ** Orders Strings
    -- *******************
    move = {
        title = "<LOC tooltipui0000>Move",
        description = "",
        keyID = "move",
    },
    attack = {
        title = "<LOC tooltipui0002>Attack",
        description = "<LOC tooltipui0003>Left click for attack order. Right click to toggle target priorities for sniping.",
        keyID = "attack",
    },
    attack_move = {
        title = "<LOC tooltipui0010>Attack Move",
        description = "<LOC tooltipui0011>Move units toward target while engaging all enemies they encounter. Engineers will reclaim everything along the way instead. Factories can't use this button but you can use the shortcut instead : Alt + RMB",
        keyID = "attackmove",
    },
    patrol = {
        title = "<LOC tooltipui0004>Patrol",
        description = "",
        keyID = "patrol",
    },
    stop = {
        title = "<LOC tooltipui0006>Stop",
        description = "",
        keyID = "stop",
    },
    assist = {
        title = "<LOC tooltipui0008>Assist",
        description = "",
        keyID = "guard",
    },
    mode_hold = {
        title = "<LOC tooltipui0299>Hold Fire",
        description = "<LOC tooltipui0300>Units will not engage enemies",
        keyID = "mode",
    },
    mode_return_fire = {
        title = "<LOC tooltipui0303>Return Fire",
        description = "<LOC tooltipui0304>Units will move and engage normally",
        keyID = "mode",
    },
    mode_mixed = {
        title = "<LOC tooltipui0305>Mixed Modes",
        description = "<LOC tooltipui0306>You have selected units that have multiple fire states",
        keyID = "mode",
    },
    mode_hold_fire = {
        title = "<LOC tooltipui0299>Hold Fire",
        description = "<LOC tooltipui0300>Units will not engage enemies",
        keyID = "mode",
    },
    mode_hold_ground = {
        title = "<LOC tooltipui0421>Ground Fire",
        description = "<LOC tooltipui0422>Units will attack targeted positions rather than attack-move",
        keyID = "mode",
    },
    mode_aggressive = {
        title = "<LOC tooltipui0504>Aggressive",
        description = "<LOC tooltipui0505>Units will actively return fire and pursue enemies",
        keyID = "mode",
    },
    build_tactical = {
        title = "<LOC tooltipui0012>Build Missile",
        description = "<LOC tooltipui0013>Right-click to toggle Auto-Build",
    },
    build_tactical_auto = {
        title = "<LOC tooltipui0335>Build Missile (Auto)",
        description = "<LOC tooltipui0336>Auto-Build Enabled",
    },
    build_nuke = {
        title = "<LOC tooltipui0014>Build Strategic Missile",
        description = "<LOC tooltipui0015>Right-click to toggle Auto-Build",
    },
    build_nuke_auto = {
        title = "<LOC tooltipui0337>Build Strategic Missile (Auto)",
        description = "<LOC tooltipui0338>Auto-Build Enabled",
    },
    overcharge = {
        title = "<LOC tooltipui0016>Overcharge",
        description = "<LOC tooltipui0017>Needs 7500 energy in storage to activate. Right click to toggle auto-fire",
        keyID = "overcharge",
    },
    transport = {
        title = "<LOC tooltipui0018>Transport",
        description = "<LOC tooltipui0019>Left click for transport order. Right click to load into transports.",
        keyID = "transport",
    },
    fire_nuke = {
        title = "<LOC tooltipui0020>Launch Strategic Missile",
        description = "",
        keyID = "nuke",
    },
    fire_billy = {
        title = "<LOC tooltipui0664>Launch Advanced Tactical Missile",
        description = "",
        keyID = "nuke",
    },
    build_billy = {
        title = "<LOC tooltipui0665>Build Advanced Tactical Missile",
        description = "<LOC tooltipui0013>",
    },
    build_billy_auto = {
        title = "<LOC tooltipui0665>Build Advanced Tactical Missile",
        description = "<LOC tooltipui0013>",
    },
    fire_tactical = {
        title = "<LOC tooltipui0022>Launch Missile",
        description = "",
        keyID = "launch_tactical",
    },
    teleport = {
        title = "<LOC tooltipui0024>Teleport",
        description = "",
        keyID = "teleport",
    },
    ferry = {
        title = "<LOC tooltipui0026>Ferry",
        description = "",
        keyID = "ferry",
    },
    sacrifice = {
        title = "<LOC tooltipui0028>Sacrifice",
        description = "",
    },
    dive = {
        title = "<LOC tooltipui0030>Surface/Dive Toggle",
        description = "<LOC tooltipui0423>Right-click to toggle auto-surface",
        keyID = "dive",
    },
    dive_auto = {
        title = "<LOC tooltipui0030>Surface/Dive Toggle",
        description = "<LOC tooltipui0424>Auto-surface enabled",
        keyID = "dive",
    },
    dock = {
        title = "<LOC tooltipui0425>Dock",
        description = "<LOC tooltipui0477>Recall aircraft to nearest air staging facility for refueling and repairs. Right-click to only recall aircraft below 90% health.",
        keyID = "dock",
    },
    deploy = {
        title = "<LOC tooltipui0478>Deploy",
        description = "",
    },
    reclaim = {
        title = "<LOC tooltipui0032>Reclaim",
        description = "",
        keyID = "reclaim",
    },
    capture = {
        title = "<LOC tooltipui0034>Capture",
        description = "",
        keyID = "capture",
    },
    repair = {
        title = "<LOC tooltipui0036>Repair",
        description = "",
        keyID = "repair",
    },
    pause = {
        title = "<LOC tooltipui0038>Pause Construction",
        description = "<LOC tooltipui0506>Pause/unpause current construction order",
        keyID = "pause_unit",
    },
    toggle_amphibious = {
        title = "<LOC tooltipui0697>Amphibious Mode Toggle",
        description = "",
    },
    toggle_omni = {
        title = "<LOC tooltipui0479>Omni Toggle",
        description = "<LOC tooltipui0480>Turn the selected units omni on/off",
    },
    toggle_shield = {
        title = "<LOC tooltipui0040>Shield Toggle",
        description = "<LOC tooltipui0481>Turn the selected units shields on/off",
    },
    toggle_shield_dome = {
        title = "<LOC tooltipui0482>Shield Dome Toggle",
        description = "<LOC tooltipui0483>Turn the selected units shield dome on/off",
    },
    toggle_shield_personal = {
        title = "<LOC tooltipui0484>Personal Shield Toggle",
        description = "<LOC tooltipui0485>Turn the selected units personal shields on/off",
    },
    toggle_sniper = {
        title = "<LOC tooltipui0647>Sniper Toggle",
        description = "<LOC tooltipui0648>Toggle sniper mode. Range, accuracy and damage are enhanced, but rate of fire is decreased when enabled",
    },
    toggle_weapon = {
        title = "<LOC tooltipui0361>Weapon Toggle",
        description = "<LOC tooltipui0362>Toggle between air and ground weaponry",
    },
    toggle_jamming = {
        title = "<LOC tooltipui0044>Radar Jamming Toggle",
        description = "<LOC tooltipui0486>Turn the selected units radar jamming on/off",
    },
    toggle_intel = {
        title = "<LOC tooltipui0046>Intelligence Toggle",
        description = "<LOC tooltipui0487>Turn the selected units radar, sonar or Omni on/off",
    },
    toggle_radar = {
        title = "<LOC tooltipui0488>Radar Toggle",
        description = "<LOC tooltipui0489>Turn the selection units radar on/off",
    },
    toggle_sonar = {
        title = "<LOC tooltipui0490>Sonar Toggle",
        description = "<LOC tooltipui0491>Turn the selection units sonar on/off",
    },
    toggle_production = {
        title = "<LOC tooltipui0048>Production Toggle",
        description = "<LOC tooltipui0492>Turn the selected units production capabilities on/off",
    },
    toggle_area_assist = {
        title = "<LOC tooltipui0503>Area-Assist Toggle",
        description = "<LOC tooltipui0564>Turn the engineering area assist capabilities on/off",
    },
    toggle_scrying = {
        title = "<LOC tooltipui0494>Scrying Toggle",
        description = "<LOC tooltipui0495>Turn the selected units scrying capabilities on/off",
    },
    scry_target = {
        title = "<LOC tooltipui0496>Scry",
        description = "<LOC tooltipui0497>View an area of the map",
    },
    vision_toggle = {
        title = "<LOC tooltipui0498>Vision Toggle",
        description = "",
    },
    toggle_stealth_field = {
        title = "<LOC tooltipui0499>Stealth Field Toggle",
        description = "<LOC tooltipui0500>Turn the selected units stealth field on/off",
    },
    toggle_stealth_personal = {
        title = "<LOC tooltipui0501>Personal Stealth Toggle",
        description = "<LOC tooltipui0502>Turn the selected units personal stealth field on/off",
    },
    toggle_cloak = {
        title = "<LOC tooltipui0339>Personal Cloak",
        description = "<LOC tooltipui0342>Turn the selected units cloaking on/off",
    },

    toggle_generic = {
        title = "<LOC tooltipui0053>Pause Toggle",
        description = "",
    },
    toggle_special = {
        title = "<LOC tooltipui0054>Fire Black Sun",
        description = "<LOC tooltipui0343>End the Infinite War",
    },
    first_helptip = {
        title = "<LOC tooltipui0307>Help Tips",
        description = "<LOC tooltipui0344>Click on the question mark icon to view detailed suggestions on how to play Supreme Commander: Forged Alliance",
    },
    external_factory = {
        title = "<LOC tooltipui0750>Mobile Factory",
        description = "<LOC tooltipui0751>Select attached factory",
    },
    external_factory_unit = {
        title = "<LOC tooltipui0750>Mobile Factory",
        description = "<LOC tooltipui0752>Select base unit",
    },
    auto_deploy = {
        title = "<LOC tooltipui0478>Deploy",
        description = "<LOC tooltipui0753>Right click to automatically deploy constructed units",
    },
    drone = {
        title = "<LOC tooltipui0411>Select Drone",
        description = "<LOC tooltipui0412>Right click to toggle auto-assist",
    },
    drone_station = {
        title = "<LOC tooltipui0655>Select Station",
        description = "<LOC tooltipui0656>Right click to toggle auto-assist",
    },
    drone_ACU = {
        title = "<LOC tooltipui0657>Select ACU",
        description = "<LOC tooltipui0658>Right click to toggle auto-assist",
    },
    drone_SACU = {
        title = "<LOC tooltipui0659>Select SACU",
        description = "<LOC tooltipui0660>Right click to toggle auto-assist",
    },
    avatar_Avatar_ACU = {
        title = "<LOC tooltipui0347>ACU",
        description = "<LOC tooltipui0348>Left-click to select your ACU. Right-click to select and zoom to your ACU.",
    },

    avatar_Engineer_t1 = {
        title = "<LOC tooltipui0349>Tech 1 Engineers",
        description = "<LOC tooltipui0350>Right-click to cycle through idle T1 Engineers",
    },

    avatar_Engineer_t2 = {
        title = "<LOC tooltipui0351>Tech 2 Engineers",
        description = "<LOC tooltipui0352>Right-click to cycle through idle T2 Engineers",
    },

    avatar_Engineer_t3 = {
        title = "<LOC tooltipui0353>Tech 3 Engineers",
        description = "<LOC tooltipui0354>Right-click to cycle through idle T3 Engineers",
    },
    avatar_Engineer_t4 = {
        title = "<LOC tooltipui0413>Sub Commanders",
        description = "<LOC tooltipui0414>Right-click to cycle through idle Sub Commanders",
    },
    avatar_toggle = {
        title = "<LOC tooltipui0363>Toggle Avatars",
        description = "<LOC tooltipui0364>Click here to toggle avatars on or off",
    },
    avatar_group = {
        title = "<LOC tooltipui0365>Group [-- ]",
        description = "<LOC tooltipui0366>Click or press %s to select this group",
    },
    marker_move = {
        title = "<LOC key_desc_0065>",
        description = "",
    },
    marker_rename = {
        title = "<LOC _Rename>Rename",
        description = "",
    },
    marker_delete = {
        title = "<LOC _Delete>Delete",
        description = "",
    },
    xsl0101_toggle = {
        title = "<LOC xsl0101_toggle>Toggle Selection Priority",
        description = "<LOC xsl0101_toggle_description>Toggles selection priority",
    },

    -- **********************
    -- ** Chat Strings
    -- **********************
    chat_config = {
        title = "<LOC tooltipui0385>Configure Chat",
        description = "<LOC tooltipui0386>Click here to configure various chat options.",
    },
    chat_pin = {
        title = "<LOC tooltipui0387>AutoHide (Enabled)",
        description = "<LOC tooltipui0388>Click here to disable automatic hiding of this window.",
    },
    chat_pinned = {
        title = "<LOC tooltipui0389>AutoHide (Disabled)",
        description = "<LOC tooltipui0390>Click here to enable automatic hiding of this window.",
    },
    chat_close = {
        title = "<LOC tooltipui0391>Close",
        description = "<LOC tooltipui0392>Click here to close this window.",
    },
    chat_camera = {
        title = "<LOC tooltipui0393>Camera Link Toggle",
        description = "<LOC tooltipui0394>Adds a camera link to the end of your messages",
    },
    chat_private = {
        title = "<LOC tooltipui0395>Private Message",
        description = "<LOC tooltipui0396>Click here to choose a private message recipient.",
    },
    chat_allies = {
        title = "<LOC tooltipui0397>Allied Chat",
        description = "<LOC tooltipui0398>Click here to send your message to all of your allies.",
    },
    chat_all = {
        title = "<LOC tooltipui0399>All Chat",
        description = "<LOC tooltipui0400>Click here to send your message to all players.",
    },
    chat_filter = {
        title = "<LOC tooltipui0401>Chat Filters",
        description = "<LOC tooltipui0402>Show or hide messages and paintings from players",
    },
    chat_color = {
        title = "<LOC tooltipui0403>Chat Color",
        description = "<LOC tooltipui0404>Change the font color for various messages",
    },
    chat_fontsize = {
        title = "<LOC tooltipui0405>Font Size",
        description = "<LOC tooltipui0406>Set the font size of your messages",
    },
    chat_fadetime = {
        title = "<LOC tooltipui0407>Fade Time",
        description = "<LOC tooltipui0408>Set the fade time of the chat window",
    },
    chat_alpha = {
        title = "<LOC tooltipui0409>Window Alpha",
        description = "<LOC tooltipui0410>Set the alpha of the chat window",
    },
    chat_reset = {
        title = "<LOC tooltipui0540>Reset Chat Window",
        description = "<LOC tooltipui0541>Resets the position and layout of the chat window",
    },
    chat_feed_background = {
        title = 'Chat Feed Background',
        description = "Adds a black bar behind chat lines when the chat window is closed",
    },
    chat_feed_persist = {
        title = "Persist Chat Feed Timeout",
        description = "Allows chat to timeout normally in the chat feed after closing the chat window",
    },
    chat_send_type = {
        title = "<LOC chat_send_type_title>Default recipient: allies",
        description = "<LOC chat_send_type_description>When enabled, enter sends messages to allies and holding shift + enter sends to all. When not enabled, the behavior is reversed.",
    },
    minimap_reset = {
        title = "<LOC tooltipui0649>Reset Minimap Window",
        description = "<LOC tooltipui0650>Resets the position and layout of the minimap window",
    },
    minimap_pin = {
        title = "<LOC tooltipui0800>Pin Minimap Window",
        description = "<LOC tooltipui0801>Locks the position and layout of the minimap window",
    },
    toggle_cartographic = {
        title = "<LOC tooltipui0415>Cartographic Mode",
        description = "<LOC tooltipui0416>Display the terrain using a topographic visualization",
    },
    toggle_resource_icons = {
        title = "<LOC tooltipui0417>View Resources",
        description = "<LOC tooltipui0418>Toggle the display of resource locations",
    },
    toggle_mini_expanded_options = {
        title = "<LOC tooltipui0419>Toggle Option Buttons",
        description = "<LOC tooltipui0420>Toggles option and MFD buttons on or off.",
    },
    drone_rebuild = {
        title = "<LOC tooltipui0690>Drone Auto-Rebuild",
        description = "<LOC tooltipui0691>Toggle if this drone rebuilds upon death",
    },

    -- **********************
    -- ** AI Strings
    -- **********************
    aitype_easy = {
        title = "<LOC lobui_0347>AI: Easy",
        description = "<LOC lobui_0348>An AI for beginners",
    },
    aitype_medium = {
        title = "<LOC lobui_0349>AI: Normal",
        description = "<LOC lobui_0350>An average AI",
    },
    aitype_supreme = { -- needed?
        title = "<LOC lobui_0351>AI: Supreme",
        description = "<LOC lobui_0352>A very difficult AI",
    },
    aitype_unleashed = { -- needed?
        title = "<LOC lobui_0353>AI: Unleashed",
        description = "<LOC lobui_0354>The most difficult AI that follows its own rules",
    },
    aitype_adaptive = {
        title = "<LOC lobui_0368>AI: Adaptive",
        description = "<LOC lobui_0369>A very difficult AI that shifts between offense and defense as the game progresses",
    },
    aitype_rush = {
        title = "<LOC lobui_0360>AI: Rush",
        description = "<LOC lobui_0361>A very difficult aggressive AI that balances land, air and naval forces",
    },
    aitype_rushair = {
        title = "<LOC lobui_0364>AI: Air Rush",
        description = "<LOC lobui_0365>A very difficult aggressive AI that prefers air forces",
    },
    aitype_rushland = {
        title = "<LOC lobui_0362>AI: Land Rush",
        description = "<LOC lobui_0363>A very difficult aggressive AI that prefers land forces",
    },
    aitype_rushnaval = {
        title = "<LOC lobui_0377>AI: Naval Rush",
        description = "<LOC lobui_0378>A very difficult aggressive AI that prefers naval forces",
    },
    aitype_turtle = {
        title = "<LOC lobui_0372>AI: Turtle",
        description = "<LOC lobui_0373>A very difficult AI that favors defense and careful expansion",
    },
    aitype_tech = {
        title = "<LOC lobui_0370>AI: Tech",
        description = "<LOC lobui_0371>A very difficult AI that aggressively persues high tier units",
    },
    aitype_adaptivecheat = {
        title = "<LOC lobui_0379>AIx: Adaptive",
        description = "<LOC lobui_0387>An extremely difficult cheating AI that shifts between offense and defense as the game progresses",
    },
    aitype_rushcheat = {
        title = "<LOC lobui_0380>AIx: Rush",
        description = "<LOC lobui_0388>An extremely difficult cheating AI that balances land, air and naval forces",
    },
    aitype_rushaircheat = {
        title = "<LOC lobui_0381>AIx: Air Rush",
        description = "<LOC lobui_0389>An extremely difficult cheating AI that prefers air forces",
    },
    aitype_rushlandcheat = {
        title = "<LOC lobui_0382>AIx: Land Rush",
        description = "<LOC lobui_0390>An extremely difficult cheating AI that prefers land forces",
    },
    aitype_rushnavalcheat = {
        title = "<LOC lobui_0383>AIx: Naval Rush",
        description = "<LOC lobui_0386>An extremely difficult cheating AI that prefers naval forces",
    },
    aitype_turtlecheat = {
        title = "<LOC lobui_0384>AIx: Turtle",
        description = "<LOC lobui_0391>An extremely difficult cheating AI that favors defense and careful expansion",
    },
    aitype_techcheat = {
        title = "<LOC lobui_0385>AIx: Tech",
        description = "<LOC lobui_0392>An extremely difficult cheating AI that aggressively persues high tier units",
    },
    aitype_random = {
        title = "<LOC lobui_0374>AI: Random",
        description = "<LOC lobui_0375>Randomly chooses an AI type",
    },
    aitype_randomcheat = {
        title = "<LOC lobui_0393>AIx: Random",
        description = "<LOC lobui_0394>Randomly chooses one of the cheating AI types",
    },


    -- **********************
    -- ** Economy Strings
    -- **********************
    mass_rate = {
        title = "<LOC tooltipui0099>Economic Mass Rate",
        description = "<LOC tooltipui0100>Toggle between income-per-second and efficiency rating values",
    },
    energy_rate = {
        title = "<LOC tooltipui0542>Economic Energy Rate",
        description = "<LOC tooltipui0543>Toggle between income per second and efficiency rating values",
    },
    mass_storage = {
        title = "<LOC tooltipui0101>Mass Storage",
        description = "<LOC tooltipui0102>Current and maximum Mass storage values",
    },
    energy_storage = {
        title = "<LOC tooltipui0544>Energy Storage",
        description = "<LOC tooltipui0545>Current and maximum Energy storage values",
    },
    mass_income_display = {
        title = "<LOC tooltipui0103>Mass Income/Expense",
        description = "<LOC tooltipui0104>Mass being generated and spent per second",
    },
    energy_income_display = {
        title = "<LOC tooltipui0546>Energy Income and Expense",
        description = "<LOC tooltipui0547>Energy being generated and spent per second",
    },
    mass_reclaim_display = {
        title = "<LOC tooltipui0700>Mass Reclaimed",
        description = "<LOC tooltipui0701>Mass income due to reclaim, and total mass reclaimed so far",
    },
    energy_reclaim_display = {
        title = "<LOC tooltipui0702>Energy Reclaimed",
        description = "<LOC tooltipui0703>Energy income due to reclaim, and total energy reclaimed so far",
    },
    overall = {
        title = "<LOC tooltipui0129>Build Efficiency",
        description = "<LOC tooltipui0130>Your overall Economic Efficiency",
    },
    -- **********************
    -- ** Mass Fabs panel Strings
    -- **********************
    mf_mass_income_display = {
        title = "<LOC tooltipui1000>Mass Income",
        description = "<LOC tooltipui1001>Mass being generated with mass fabricators per second",
    },
    mf_energy_expense_display = {
        title = "<LOC tooltipui1002>Energy Expense",
        description = "<LOC tooltipui1003>Energy being spent with mass fabricators per second",
    },
    mf_active_amount = {
        title = "<LOC tooltipui1004>Active mass fabricators",
        description = "<LOC tooltipui1005>Amount of active mass fabricators",
    },
    mf_inactive_amount = {
        title = "<LOC tooltipui1006>Inactive mass fabricators",
        description = "<LOC tooltipui1007>Amount of inactive mass fabricators",
    },
    mf_energy_required = {
        title = "<LOC tooltipui1008>Energy Required",
        description = "<LOC tooltipui1009>Amount of required energy for mass fabricators to work",
    },

    -- **********************
    -- ** Options Strings
    -- **********************

    options_commands_ignore_mode = {
        title = "<LOC OPTIONS_0319>Ignore Mode",
        description = "<LOC OPTIONS_0320>When enabled, ignores any other command but move commands when you hold {i properkeyname_0123}. This can help to guarantee that you issue a move command, instead of (accidentally) starting a reclaim or attack command.\r\n\r\nThis is disabled when holding {i properkeyname_0009}.",
    },

    options_selection_threshold_regular = {
        title = "<LOC OPTIONS_0312>Default Selection Threshold",
        description = "<LOC OPTIONS_0316>The higher the value, the easier it becomes to select and target units or props. The value is in (screen) pixels. This can help you select individual units or props, especially on displays with higher resolutions.\r\n\r\nInteraction with units take precedence over props.\r\n\r\nWhen multiple entities are in range, the one nearest to the mouse location has precedence.",
    },

    options_selection_threshold_reclaim = {
        title = "<LOC OPTIONS_0313>Reclaim Mode Selection Threshold",
        description = "<LOC OPTIONS_0317>The higher the value, the easier it becomes to select and target units or props. The value is in (screen) pixels. This threshold is specifically used when you are in reclaim mode. It makes it easier to hit all of your clicks, reducing the amount of fake reclaim orders.\r\n\r\nInteraction with units take precedence over props.\r\n\r\nWhen multiple entities are in range, the one nearest to the mouse location has precedence.",
    },

    options_selection_threshold_replay = {
        title = "<LOC OPTIONS_0314>Replay Selection Threshold",
        description = "<LOC OPTIONS_0318>The higher the value, the easier it becomes to select and target units or props. The value is in (screen) pixels. This threshold is specifically used when watching a replay, it makes it easier to hover over units.\r\n\r\nInteraction with units take precedence over props.\r\n\r\nWhen multiple entities are in range, the one nearest to the mouse location has precedence.",
    },

    options_painting = {
        title = "<LOC options_painting_title>Painting",
        description = "<LOC options_painting_description>When enabled, you can send and receive brush strokes to or from other players.\r\nYou can create a brush stroke using the right mouse button. Painting is disabled when you have a unit selection or when you hold shift. You can delete a brush stroke by holding ALT while drawing. You can mute a player by holding CTRL and ALT while drawing.",
    },

    options_painting_duration = {
        title = "<LOC options_painting_duration_title>Duration of paintings",
        description = "<LOC options_painting_duration_description>The higher the value, the longer it takes for a painting to decay and be removed.",
    },

    options_wheel_sensitivity = {
        title = "<LOC OPTIONS_0001>Zoom Wheel Sensitivity",
        description = "<LOC OPTIONS_0035>Sets the Zoom Speed when using the Mouse Wheel",
    },
    options_quick_exit = {
        title = "<LOC OPTIONS_0125>Quick Exit",
        description = "<LOC OPTIONS_0126>When close box or alt-f4 are pressed, no confirmation dialog is shown",
    },
    options_help_prompts = {
        title = "<LOC OPTIONS_0002>Help Prompts",
        description = "<LOC OPTIONS_0036>Toggles display of In-game Help and Tutorial Prompts",
    },
    options_mainmenu_bgmovie = {
        title = "<LOC OPTIONS_0208>Main Menu Background Movie",
        description = "<LOC OPTIONS_0209>Toggles the movie playing in the background of the main menu",
    },
    options_reset_help_prompts = {
        title = "<LOC OPTIONS_0080>Reset Help Prompts",
        description = "<LOC OPTIONS_0081>Sets all In-game Help Prompts as unread",
    },
    options_stratview = {
        title = "<LOC OPTIONS_0113>Strategic View",
        description = "<LOC OPTIONS_0114>Sets whether or not the mini-map is automatically on or off",
    },
    options_strat_icons_always_on = {
        title = "<LOC OPTIONS_0115>Always Render Strategic Icons",
        description = "<LOC OPTIONS_0116>Strategic icons are always shown, regardless of zoom distance",
    },
    options_strat_icon_scale = {
        title = "<LOC OPTIONS_STRATEGIC_ICON_SCALE_TITLE>Scale strategic icons",
        description = "<LOC OPTIONS_STRATEGIC_ICON_SCALE_DESCRIPTION>Increase the size of strategic icons. Also scales the pause and stun icons. Can be useful on monitors with a high pixel density. \r\n\r\n100%: the default scale.\r\n150%: may distort the strategic icons slightly.\r\n200%: does not distort the strategic icons, but the strategic icons can be quite large even on a minotor with a high pixel density. ",
    },
    options_camera_shake_intensity = {
        title = "<LOC OPTIONS_CAMERA_SHAKE_TITLE>Adjust shake intensity of camera",
        description = "<LOC OPTIONS_CAMERA_SHAKE_DESCRIPTION>Adjusts the shake intensity: 0% is no shaking at all and 100% is the default shake behavior. \r\nLarge explosions and units can shake the camera to improve immersion, but practically it can be annoying.",
    },
    options_uvd_format = {
        title = "<LOC OPTIONS_0107>Construction Tooltip Information",
        description = "<LOC OPTIONS_0118>Shows full, partial or no description when the unit icon is moused over",
    },
    options_assist_to_upgrade = {
        title = "<LOC ASSIST_TO_UPGRADE_TITLE>Assist to Upgrade",
        description = "<LOC ASSIST_TO_UPGRADE_DESCRIPTION>When enabled structures automatically queue and pause their upgrade when you issue an assist order",
    },

    options_alt_to_force_attack_move = {
        title = "<LOC ALT_TO_FORCE_ATTACK_MOVE_TITLE>Hold alt to force attack move",
        description = "<LOC ALT_TO_FORCE_ATTACK_MOVE_DESCRIPTION>When enabled holding alt will always turn orders into an attack move order, except when holding Ctrl"
    },

    options_area_commands_button = {
        title = "<LOC area_commands_button_title>Button to trigger area commands",
        description = "<LOC area_commands_button_description>When holding this button you'll trigger area command interface as you issue a command in command mode."
    },

    options_assist_to_unpause = {
        title = "<LOC ASSIST_TO_UNPAUSE_TITLE>Assist to Unpause",
        description = "<LOC ASSIST_TO_UNPAUSE_DESCRIPTION>When enabled structures automatically unpause as engineers start assisting it.",
    },

    options_assist_to_copy_command_queue = {
        title = "<LOC ASSIST_TO_COPY_TITLE>Assist to copy command queue",
        description = "<LOC ASSIST_TO_COPY_DESCRIPTION>When enabled, engineers in the selection will try to copy the command queue of the engineer you issue an assist order for. \r\n\r\nRequires you to hold 'Control'",
    },

    options_mp_taunt_head = {
        title = "<LOC OPTIONS_0119>MP Taunt Head",
        description = "<LOC OPTIONS_0120>Select which 3D head is displayed when taunts are used in multiplayer",
    },
    options_mp_taunt_head_enabled = {
        title = "<LOC OPTIONS_0102>Multiplayer Taunts",
        description = "<LOC OPTIONS_0122>Turns taunts on and off in multiplayer",
    },
    options_dual_mon_edge = {
        title = "<LOC OPTIONS_0003>Dual Monitor Screen Edge",
        description = "<LOC OPTIONS_0037>Toggles the Edge between 2 Monitors as blocking Mouse Movement or allowing a Cursor Transition",
    },
    options_tooltips = {
        title = "<LOC OPTIONS_0005>Display Tooltips",
        description = "<LOC OPTIONS_0039>Toggles whether or not Tooltips are displayed",
    },
    options_tooltip_delay = {
        title = "<LOC OPTIONS_0078>Tooltip Delay",
        description = "<LOC OPTIONS_0079>Sets the Delay before Tooltips are displayed",
    },
    options_loading_tips = {
        title = "<LOC OPTIONS_0009>Show Loading Tips",
        description = "<LOC OPTIONS_0011>Toggles whether or not tips are displayed on the loading screen",
    },
    options_persistent_built_mode = {
        title = "<LOC OPTIONS_0205>Persistent Build Mode",
        description = "<LOC OPTIONS_0206>Toggles whether build mode is cancelled after pressing a key for a unit",
    },
    options_econ_warnings = {
        title = "<LOC OPTIONS_0076>Economy Warnings",
        description = "<LOC OPTIONS_0077>Shows automatic alerts when the economy is performing poorly",
    },
    options_ui_animation = {
        title = "<LOC OPTIONS_0062>UI Animation",
        description = "<LOC OPTIONS_0063>Toggles whether or not Interface Animations are shown",
    },
    options_primary_adapter = {
        title = "<LOC OPTIONS_0010>Primary Adapter",
        description = "<LOC OPTIONS_0045>Sets the Resolution or Display Mode for the Primary Monitor (1024x768 = fastest)",
    },
    options_fidelity_presets = {
        title = "<LOC OPTIONS_0127>Fidelity Presets",
        description = "<LOC OPTIONS_0128>Preset values for video options (low = fastest)",
    },
    options_bg_image = {
        title = "<LOC OPTIONS_0017>Background Image",
        description = "<LOC OPTIONS_0048>Toggles display of the Image under the World Map (off = fastest)",
    },
    options_fidelity = {
        title = "<LOC OPTIONS_0018>Fidelity",
        description = "<LOC OPTIONS_0049>Sets Rendering Fidelity for Objects, Terrain, and Water (low = fastest)",
    },
    options_shadow_quality = {
        title = "<LOC OPTIONS_0024>Shadow Fidelity",
        description = "<LOC OPTIONS_0056>Sets Rendering Fidelity for Shadows (off = fastest)",
    },
    options_shadow_resolution = {
        title = "<LOC OPTIONS_SHADOW_RESOLUTION_TITLE>Shadow Resolution",
        description = "<LOC OPTIONS_SHADOW_RESOLUTION_DESCRIPTION>Sets resolution of shadows (lower = faster). High values require more VRAM.",
    },
    options_shadow_render_distance = {
        title = "<LOC OPTIONS_SHADOW_RENDER_DISTANCE_TITLE>Shadow Resolution",
        description = "<LOC OPTIONS_SHADOW_RENDER_DISTANCE_DESCRIPTION>Sets the rendering distance (level of detail) of shadows (lower = faster). High values can have a significant impact on your framerate.",
    },
    options_antialiasing = {
        title = "<LOC OPTIONS_0015>Anti-Aliasing",
        description = "<LOC OPTIONS_0050>Toggles Full Scene Anti-Aliasing (off = fastest)",
    },
    options_texture_level = {
        title = "<LOC OPTIONS_0019>Texture Detail",
        description = "<LOC OPTIONS_0051>Sets the number of Mip Levels that are not Rendered (low = fastest)",
    },
    options_level_of_detail = {
        title = "<LOC OPTIONS_0129>Level Of Detail",
        description = "<LOC OPTIONS_0130>Set the rate at which objects LOD out (low = fastest)",
    },
    options_master_volume = {
        title = "<LOC OPTIONS_0028>Master Volume",
        description = "<LOC OPTIONS_0061>Sets the Games overall Volume Level",
    },
    options_fx_volume = {
        title = "<LOC OPTIONS_0026>FX Volume",
        description = "<LOC OPTIONS_0059>Sets the Volume of the Game Sound Effects",
    },
    options_music_volume = {
        title = "<LOC OPTIONS_0027>Music Volume",
        description = "<LOC OPTIONS_0060>Sets the Volume of the Game Music",
    },
    options_ui_volume = {
        title = "<LOC OPTIONS_0064>Interface Volume",
        description = "<LOC OPTIONS_0065>Sets the Volume of all Interface Sounds",
    },
    options_vo_volume = {
        title = "<LOC OPTIONS_0066>VO Volume",
        description = "<LOC OPTIONS_0067>Sets the Volume of all Voice and Movie Sounds",
    },
    options_credits = {
        title = "<LOC OPTIONS_0073>Credits",
        description = "<LOC OPTIONS_0074>View the Game Credits",
    },
    options_eula = {
        title = "<LOC OPTIONS_0086>EULA",
        description = "<LOC OPTIONS_0087>View the End-User License Agreement",
    },
    options_show_help_prompts_now = {
        title = "<LOC OPTIONS_0083>Show Help Now",
        description = "<LOC OPTIONS_0084>View Help Prompts",
    },

    options_tab_gameplay = {
        title = "<LOC OPTIONS_0131>Gameplay",
        description = "<LOC OPTIONS_0132>View and adjust Game options",
    },

    options_tab_video = {
        title = "<LOC OPTIONS_0133>Video",
        description = "<LOC OPTIONS_0134>View and adjust Display and Graphic options",
    },

    options_tab_sound = {
        title = "<LOC OPTIONS_0135>Sound",
        description = "<LOC OPTIONS_0136>View and adjust Sound and Volume options",
    },

    options_tab_about = {
        title = "<LOC OPTIONS_0137>About",
        description = "<LOC OPTIONS_0138>View the EULA and Credits",
    },

    options_tab_apply = {
        title = "<LOC OPTIONS_0139>Apply",
        description = "<LOC OPTIONS_0140>Save any Changes",
    },

    options_reset_all = {
        title = "<LOC OPTIONS_0141>Reset",
        description = "<LOC OPTIONS_0142>Restore original Game Settings",
    },
    map_select_sizeoption = {
        title = "<LOC OPTIONS_0143>Map Size",
        description = "",
    },
    map_select_size = {
        title = "<LOC OPTIONS_0143>Map Size",
        description = "<LOC OPTIONS_0144>Sort by Battlefield size",
    },
    map_select_maxplayers = {
        title = "<LOC OPTIONS_0145>Max. Players",
        description = "",
    },
    map_select_supportedplayers = {
        title = "<LOC MAPSEL_0009>Supported Players",
        description = "<LOC OPTIONS_0146>Sort by the maximum number of Players allowed",
    },
    options_vsync = {
        title = "<LOC OPTIONS_0149>Vertical Sync",
        description = "<LOC OPTIONS_0150>Sync to vertical refresh of monitor",
    },
    options_frametime = {
        title = "<LOC OPTIONS_FRAMETIME_TITLE>Minimum frametime",
        description = "<LOC OPTIONS_FRAMETIME_DESCRIPTION>Allows you to manipulate the minimum frametime. Incompatible with vertical sync, which is automatically disabled when you move the slider and apply the settings. May introduce image tearing. Option exists to give players a way to try to match the refresh rate of modern monitors. Note that the framerate is often CPU limited and not GPU limited, especially during visually intense fights. A list of values that map to common refresh rates: \r\n\r\n  - 16 = 60hz\r\n  - 10 = 100hz\r\n  - 8 = 120hz\r\n  - 7 = 144hz\r\n  - 6 = 165hz",
    },
    options_selectedlanguage = {
        title = "<LOC OPTIONS_0007>Language selection",
        description = "<LOC OPTIONS_0008>Select original or custom languages. Also changes voices if available. (needs game restart)",
    },
    options_ui_scale = {
        title = "<LOC OPTIONS_0283>UI Scale",
        description = "<LOC OPTIONS_0284>Changes the size of all UI elements. (requires game restart)",
    },
    options_subtitles = {
        title = "<LOC OPTIONS_0151>Display Subtitles",
        description = "<LOC OPTIONS_0152>Toggles the display of subtitles during movies",
    },
    options_world_border = {
        title = "<LOC OPTIONS_0224>Display World Border",
        description = "<LOC OPTIONS_0225>Toggles the display of the holographic image surrounding the world",
    },
    options_screen_edge_pans_main_view = {
        title = "<LOC OPTIONS_0153>Screen Edge Pans Main View",
        description = "<LOC OPTIONS_0154>Toggles the ability to pan the main map view by moving the mouse to the edge of the screen in full screen mode",
    },
    options_arrow_keys_pan_main_view = {
        title = "<LOC OPTIONS_0155>Arrow Keys Pan Main View",
        description = "<LOC OPTIONS_0156>Toggles the ability to pan the main map view by holding down the arrow keys",
    },
    options_secondary_adapter = {
        title = "<LOC OPTIONS_0147>Secondary Adapter",
        description = "<LOC OPTIONS_0157>If available on your system, sets the resolution or display mode for the secondary monitor (full screen only)",
    },
    options_keyboard_pan_accelerate_multiplier = {
        title = "<LOC OPTIONS_0170>Accelerated Pan Speed Multiplier",
        description = "<LOC OPTIONS_0171>This multiplies the pan speed of camera when the ctrl key is held down",
    },
    options_keyboard_pan_speed = {
        title = "<LOC OPTIONS_0172>Pan Speed",
        description = "<LOC OPTIONS_0173>This dictates how fast the map scrolls when pressing the arrow keys or moving your mouse to the edge of the screen",
    },
    options_keyboard_rotate_speed = {
        title = "<LOC OPTIONS_0174>Keyboard Rotation Speed",
        description = "<LOC OPTIONS_0175>This dictates how fast the map rotates",
    },
    options_keyboard_rotate_accelerate_multiplier = {
        title = "<LOC OPTIONS_0176>Accelerated Keyboard Rotate Speed Multiplier",
        description = "<LOC OPTIONS_0177>This multiplies the rotation speed of the camera when the ctrl key is held down",
    },
    options_lock_fullscreen_cursor_to_window = {
        title = "<LOC OPTIONS_0178>Lock Full Screen Cursor to Window",
        description = "<LOC OPTIONS_0179>This will prevent the cursor from going outside of the game window while in full screen mode",
    },
    options_kill_confirm = {
        title = "<LOC OPTIONS_0180>Confirm Unit Self-Destruction",
        description = "<LOC OPTIONS_0181>This will prompt you before issuing the self-destruction order",
    },
    options_render_skydome = {
        title = "<LOC OPTIONS_0182>Render Sky",
        description = "<LOC OPTIONS_0183>Toggles rendering of the sky when the camera is tilted (off = fastest)",
    },
    options_bloom_render = {
        title = "<LOC OPTIONS_0184>Bloom Render",
        description = "<LOC OPTIONS_0185>Toggles a glow type effect that is used on many weapon effects and some UI elements (off = fastest)",
    },
    options_bloom_intensity = {
        title = "<LOC OPTIONS_BLOOM_INTENSITY>Bloom Intensity",
        description = "<LOC OPTIONS_BLOOM_INTENSITY_DESCRIPTION>Allows you to adjust the bloom intensity. Ranges from 10 (essentially no bloom) to 17 (more bright than usual). The standard value is 15.\r\n\r\nThis feature only works when bloom is enabled.",
    },
    options_experimental_graphics = {
        title = "<LOC OPTIONS_EXP_GRAPHICS_01>Experimental graphics",
        description = "<LOC OPTIONS_EXP_GRAPHICS_02>Requires fidelity set to 'High'.\r\n\r\nIntroduces experimental graphics that high-end hardware should be able to support.\r\n\r\nThis feature may be unstable - use at your own risk.",
    },
    options_use_mydocuments = {
        title = "<LOC OPTIONS_0186>Save Games and Replays in My Documents",
        description = "<LOC OPTIONS_0187>When on, changes the location where save games and replays get stored (My Documents\\My Games\\Supreme Commander Forged Alliance\\). Note that you will only see save games and replays in the active directory. Also, files saved to the alternate location will not be removed when the game is uninstalled.",
    },
    options_display_eta = {
        title = "<LOC OPTIONS_0215>Show Waypoint ETAs",
        description = "<LOC OPTIONS_0216>Toggles the display of ETA numbers when waypoint lines are visible",
    },
    options_accept_build_templates = {
        title = "<LOC OPTIONS_0212>Accept Build Templates",
        description = "<LOC OPTIONS_0217>Allows other players to send you build templates over the network",
    },
    options_structure_capping_feature_01 = {
        title = "<LOC options_structure_capping_feature_01_title>Assist to cap",
        description = "<LOC options_structure_capping_feature_01_description>Assist an extractor to cap it with storages",
    },
    options_structure_ringing_extractors_fabs = {
        title = "<LOC options_structure_ringing_extractors_fabs_title>Assist to cap",
        description = "<LOC options_structure_ringing_extractors_fabs_description>Assist an extractor to cap it with 4 or 8 fabricators",
    },
    options_structure_ringing_artillery = {
        title = "<LOC options_structure_ringing_artillery_title>Assist to cap",
        description = "<LOC options_structure_ringing_artillery_description>Assist a tech 2 artillery to cap it with tech 1 power generators",
    },
    options_structure_ringing_radar = {
        title = "<LOC options_structure_ringing_radar_title>Assist to cap",
        description = "<LOC options_structure_ringing_radar_description>Assist a radar or omni to cap it with tech 1 power generators",
    },
    options_structure_ringing_artillery_end_game = {
        title = "<LOC options_structure_ringing_artillery_end_game_title>Assist to cap",
        description = "<LOC options_structure_ringing_artillery_end_game_description>Assist an end game artillery to cap it with tech 3 power generators. Does not apply to the salvation",
    },
    options_automex = {
        title = "<LOC OPTIONS_0285>Automatic Extractor Selection",
        description = "<LOC OPTIONS_0286>After selecting an engineer, hover the mouse over a mass extractor spot to autopreselect a mass extractor for building",
    },
    options_show_attached_unit_lifebars = {
        title = "<LOC OPTIONS_0222>Show Lifebars of Attached Units",
        description = "<LOC OPTIONS_0219>Toggles the visibility of lifebars of on screen units (lifebars will still show in tooltip information)",
    },
    options_skin_change_on_start = {
        title = "<LOC OPTIONS_0211>Use Factional UI Skin",
        description = "<LOC OPTIONS_0220>When on, the UI skin will change to match the faction you are playing",
    },
    options_faction_font_color = {
        title = "<LOC OPTIONS_0279>Use Factional UI Font Color",
        description = "<LOC OPTIONS_0280>When on, the UI font color will change to match the faction you are playing",
    },
    options_hotbuild_cycle_preview = {
        title = "<LOC OPTIONS_0247>Enable Cycle Preview for Hotbuild",
        description = "<LOC OPTIONS_0248>When on, you can cycle the Hotbuild preview",
    },
    options_hotbuild_cycle_reset_time = {
        title = "<LOC OPTIONS_0251>Cycle Reset Time",
        description = "<LOC OPTIONS_0252>Time in milliseconds until hotbuild cycle will reset",
    },
    options_maximum_reclaim_count = { -- unused
        title = "<LOC OPTIONS_0275>Maximum Reclaim Label Count",
        description = "<LOC OPTIONS_0276>When showing the reclaim label overlay, no more than this many labels will be shown",
    },
    options_minimum_reclaim_amount = { -- unused
        title = "<LOC OPTIONS_0277>Minimum Reclaim Label Amount",
        description = "<LOC OPTIONS_0278>When showing the reclaim label overlay, items with mass values less than this won't be shown",
    },
    options_show_hotkeylabels = {
        title = "<LOC OPTIONS_0281>Hotkey Labels",
        description = "<LOC OPTIONS_0282>Displays associated keybindings on the buttons for commands and building units or structures"
    },

    options_gui_bigger_strat_build_icons = {
        title = '<LOC OPTIONS_0228>Bigger Strategic Build Icons',
        description = '<LOC OPTIONS_0253>Replaces the default strategic build icons with something more visible.',
    },
    options_gui_template_rotator = {
        title = '<LOC OPTIONS_0229>Template Rotation',
        description = '<LOC OPTIONS_0256>Allows build templates to be rotated with the middle mouse button.',
    },
    options_gui_draggable_queue = {
        title = '<LOC OPTIONS_0231>Draggable Build Queue',
        description = '<LOC OPTIONS_0258>Allows factory build queues to be reordered with drag and drop.',
    },
    options_gui_queue_on_hover_02 = {
        title = '<LOC OPTIONS_0246>Show Factory Queue on Hover',
        description = '<LOC OPTIONS_0249>Shows Factory queue above unit description when hover over unit with mouse.',
    },
    options_gui_idle_engineer_avatars = {
        title = '<LOC OPTIONS_0232>Middle Click Avatars',
        description = '<LOC OPTIONS_0259>Allows middle clicking idle engineer avatars to select all idle engineers on screen.',
    },
    options_gui_all_race_templates = {
        title = '<LOC OPTIONS_0233>All Faction Templates',
        description = '<LOC OPTIONS_0260>Allows build templates to be used across all 4 factions.',
    },
    options_gui_enhanced_unitview = {
        title = '<LOC OPTIONS_0234>Single Unit Selected Info',
        description = '<LOC OPTIONS_0261>Replaces fuel bar with progress bar, and causes the unitview to always be shown for a 1 unit selection.',
    },
    options_gui_enhanced_unitrings = {
        title = '<LOC OPTIONS_0235>Single Unit Selected Rings',
        description = '<LOC OPTIONS_0262>When a single unit is selected, show that units range rings.',
    },
    options_gui_templates_factory = {
        title = '<LOC OPTIONS_0237>Factory Build Queue Templates',
        description = '<LOC OPTIONS_0263>Allows creation of factory build queue templates.',
    },
    options_gui_seperate_idle_builders = {
        title = '<LOC OPTIONS_0238>Separate Idle Builders',
        description = '<LOC OPTIONS_0264>Use a seperate icon for idle Engineers and other builders.',
    },
    options_gui_visible_template_names = {
        title = '<LOC OPTIONS_0239>Visible Template Names',
        description = '<LOC OPTIONS_0265>Displays template name below template icon.',
    },
    options_gui_template_name_cutoff = {
        title = '<LOC OPTIONS_0240>Template Name Cutoff',
        description = '<LOC OPTIONS_0266>The first 7 characters are displayed (default). Number of characters omitted can be customized. (Needs restart for effects to be visible.)',
    },
    options_gui_detailed_unitview = {
        title = '<LOC OPTIONS_0241>Display More Unit Stats',
        description = '<LOC OPTIONS_0267>Displays Shield Hp, Regen rate, Hp Regen rate and Build rate. Adapted from Total Veterancy by Eni.',
    },
    options_gui_render_custom_names = {
        title = '<LOC OPTIONS_0242>Always Show Custom Names',
        description = '<LOC OPTIONS_0268>Toggle display of custom names. Enabled by default.',
    },
    options_gui_render_enemy_lifebars = {
        title = '<LOC OPTIONS_0243>Always Show Enemy Lifebars',
        description = '<LOC OPTIONS_0269>Force rendering enemy lifebars. Disabled by default',
    },
    options_gui_render_armament_detail = {
        title = '<LOC OPTIONS_0244>Show Armament Build in Factory Menu',
        description = '<LOC tooltipui0692>Shows detailed information about the weapons a unit has from the build menu',
    },
    options_gui_improved_unit_deselection = {
        title = '<LOC OPTIONS_0245>Improved Unit Deselection',
        description = '<LOC OPTIONS_0270>Reduce the number of selected units by shift(-1) or ctrl(-5) or ctrl+shift(-10) right-click in group selection. Enabled by default',
    },
    options_gui_zoom_pop_distance = {
        title = '<LOC OPTIONS_0236>Zoom Pop Distance',
        description = '<LOC OPTIONS_0288>Adjusts distance to which Zoom Pop zooms to.',
    },
    options_reclaim_overview_size_scale = {
        title = '<LOC OPTIONS_0289>Reclaim Label Scaling Factor',
        description = '<LOC OPTIONS_0290>Scales the text of the reclaim label to its value',
    },
    options_reclaim_overview_batching = {
        title = '<LOC OPTIONS_0291>Reclaim Batching',
        description = '<LOC OPTIONS_0292>Combines nearby reclaim labels as you zoom out. Does not work properly with reclaim labels scaled 30% or more.\r\n\r\nSignificantly improves performance. Recommended for lower end systems.',
    },
    options_steal_from_other_control_groups = {
        title = "<LOC OPTIONS_0293>Unique Control Groups",
        description = "<LOC OPTIONS_0294>When on, a unit can only be part of one control group. A unit will be transferred from any previously assigned control groups to the new control group.",
    },
    options_add_to_factory_control_group = {
        title= "<LOC OPTIONS_0295>Transitive Control Groups of Factories",
        description= "<LOC OPTIONS_0296>When on, a unit inherits the control group of the factory it is produced by."
    },
    options_selection_sets_double_tap_behavior = {
        title = "<LOC OPTIONS_0297>Successive Control Group Select Behavior",
        description = "<LOC OPTIONS_0298>Defines the behavior when you successively select the same control group."
    },
    options_selection_sets_double_tap_decay = {
        title = "<LOC OPTIONS_0299>Threshold for Successive Control Group Selecting",
        description = "<LOC OPTIONS_0300>Time in milliseconds between selection calls.",
    },
    options_cursor_splash_damage = {
        title = "<LOC OPTIONS_0301>Splash Damage Indicator",
        description = "<LOC OPTIONS_0302>Shows a splash damage indicator when an attack command is possible, usually when you attempt to ground-fire with a unit with splash damage, like a bomber.\r\n\r\nDoes not interfere with how the attack command is processed, this is merely a visual change.",
    },
    options_cursor_depth_scanning = {
        title = "<LOC WATER_DEPTH_ASSISTANCE_TITLE>Water depth indication",
        description = "<LOC WATER_DEPTH_ASSISTANCE_DESCRIPTION>When enabled, adds visual elements to visualize the offset between the water surface and the ocean floor at the position of the cursor. A separate indicator turns red when naval units are guaranteed to not be able to path at the location due to lack of depth.",
    },
    options_cursor_hover_scanning = {
        title = "<LOC PLANE_HEIGHT_ASSISTANCE_TITLE>Plane height indication",
        description = "<LOC PLANE_HEIGHT_ASSISTANCE_DESCRIPTION>When enabled, adds visual elements to visualize the offset between the terrain surface and the (expected) height of the selected air unit at the position of the cursor. \r\nIs only applied when you have one unit selected.",
    },
    options_share_mouse = {
        title = '<LOC OPTIONS_0305>Show Player Cursor Locations for Observers',
        description = '<LOC OPTIONS_0306>Shows the cursor locations of alive players and other observers as you observe a game.\r\nDoes not apply for replays, including live ones.',
    },
    -- **********************
    -- ** Lobby Strings
    -- **********************
    Lobby_BuildRestrict_Option = {
        title = "<LOC tooltipui0666>Build Restrictions Enabled",
        description = "<LOC tooltipui0667>The host has enabled build restrictions. Be sure to check the restriction manager.",
    },
    Lobby_Mods = {
        title = "<LOC tooltipui0169>Mod Manager",
        description = "<LOC tooltipui0170>View, enable and disable all available Mods",
    },
    Lobby_Mod_Option = {
        title = "<LOC tooltipui0668>Mods Enabled",
        description = "<LOC tooltipui0669>The host has enabled mods. Be sure to check the mod manager.",
    },
    Lobby_patchnotes = {
        title = "<LOC tooltipui2000>Patchnotes",
        description = "<LOC tooltipui2001>Access to all previous patch notes made by and for the community",
    },
    Lobby_Load = {
        title = "<LOC tooltipui0171>Load",
        description = "<LOC tooltipui0172>Load a previously saved skirmish game",
    },
    Lobby_Launch = {
        title = "<LOC tooltipui0173>Launch Game",
        description = "<LOC tooltipui0174>Launch the Game with the Current Settings",
    },
    lob_slot = {
        title = "<LOC tooltipui0121>Player Slot",
        description = "<LOC tooltipui0122>Context sensitive menu which allows you to modify the player or AI for a given slot",
    },
    lob_color = {
        title = "<LOC tooltipui0123>Color",
        description = "<LOC tooltipui0124>Choose your Team Color",
    },
    lob_faction = {
        title = "<LOC tooltipui0125>Faction",
        description = "<LOC tooltipui0126>Choose your Team Faction",
    },
    lob_team = {
        title = "<LOC tooltipui0127>Team",
        description = "<LOC tooltipui0128>Players with the same Team will start off Allied with each other",
    },
    lob_curated_maps = {
        title = "<LOC tooltipui0712>Curated Maps",
        description = "<LOC tooltipui0713>Open a web page in your browser to view curated maps",
    },
    lob_select_map = {
        title = "<LOC tooltipui0332>Game Options",
        description = "<LOC tooltipui0333>Choose a map to play on and adjust game settings",
    },
    Lobby_Gen_GameSpeed = {
        title = "<LOC gamesel_0014>Game Speed",
        description = "<LOC tooltipui0360>Set how quickly the Game runs",
    },
    lob_cybran = {
        title = "<LOC _Cybran>",
        description = ''
    },
    lob_uef = {
        title = "<LOC _UEF>",
        description = ''
    },
    lob_aeon = {
        title = "<LOC _Aeon>",
        description = ''
    },
    lob_seraphim = {
        title = "<LOC _Seraphim>",
        description = ''
    },
    lob_random = {
        title = '<LOC lobui_0090>',
        description = '',
    },
    ['Give Units'] = {
        title = '<LOC tooltips_0000>Give Units',
        description = '',
    },
    ['Give Resources'] = {
        title = '<LOC tooltips_0001>Give Resources',
        description = '',
    },
    lob_become_observer = {
        title = "<LOC lobui_0288>Become Observer",
        description = "<LOC lobui_0289>When clicked, a player will become an observer",
    },
    lob_RestrictedUnits = {
        title = "<LOC lobui_0332>Unit Manager",
        description = "<LOC lobui_0333>View and set unit restrictions for this game (The AI may behave unexpectedly with these options set)",
    },
    lob_RestrictedUnitsClient = {
        title = "<LOC lobui_0337>Unit Manager",
        description = "<LOC lobui_0338>View what units are allowed to be played in game",
    },

    -- **********************
    -- ** Power lobby Strings
    -- **********************
    lob_click_randmap = {
        title = "<LOC lobui_0501>Random Map",
        description = "<LOC lobui_0502>When clicked, a random map will be selected",
    },
    lob_auto_tvsb = {
        title = "<LOC lobui_0597>Top vs Bottom",
        description = "<LOC lobui_0598>Slots in the upper half of the map against those in the lower half",
    },
    lob_auto_lvsr = {
        title = "<LOC lobui_0606>Left vs Right",
        description = "<LOC lobui_0599>Slots in the left half of the map against those in the right half",
    },
    lob_auto_pvsi = {
        title = "<LOC lobui_0600>Odd vs Even",
        description = "<LOC lobui_0601>Odd numbered slots vs even numbered slots. Subject to map design, your mileage may vary",
    },
    lob_auto_manual = {
        title = "<LOC lobui_0604>Manual Autoteams",
        description = "<LOC lobui_0605>Start positions are bound to teams in a way defined by the host by clicking on the positions on the map. This only works when random spawns are enabled.",
    },
    lob_auto_none = {
        title = "<LOC lobui_0602>Off",
        description = "<LOC lobui_0603>No automatic teams",
    },
    lob_click_rankedoptions = {
        title = "<LOC lobui_0523>Ranked Settings",
        description = "<LOC lobui_0524>When clicked, all the main game options will be reset to ranked settings",
    },
    lob_rerun_benchmark = {
        title='<LOC lobui_0752>Rerun CPU Benchmark',
        description='<LOC lobui_0753>Recalculates your CPU rating.'
    },
    lob_close_empty_slots = {
        title='<LOC lobui_0774>Close/Open Empty Slots',
        description='<LOC lobui_0775>Closes all empty open slots. If all empty slots are already closed, then it opens them. Right-click for close - spawn mex. Hold Ctrl to reset.'
    },
    map_type = {
        title = "<LOC MAPSEL_0032>Map Type",
        description = "<LOC lobui_0584>Sort by official or custom maps",
    },
    lob_disable_allmods = {
        title = "<LOC lobui_0600>Disable All Mods",
        description = "<LOC lobui_0601>Click to disable all the mods at once",
    },
    lob_click_LargeMapPreview = {
        title = "<LOC lobui_0618>Large Preview",
        description = "<LOC lobui_0619>Click to show a large map preview showing all the mass and hydrocarbon spots",
    },
    lobby_click_Settings = {
        title = "<LOC lobui_0611>Lobby Settings",
        description = "<LOC lobui_0612>Change your lobby background or chat font size.",
    },
    num_games = {
        title = '<LOC lobui_0748>Number of Games',
        description = '<LOC lobui_0749>Number of games played in global ladder.',
    },
    rating = {
        title = '<LOC lobui_0750>Rating',
        description = '<LOC lobui_0751>Global ladder rating.',
    },
    slot_number = {
        title = '<LOC lobui_0754>Slot',
        description = '<LOC lobui_0755>Player slot number, useful for moving players around as host',
    },
    map_ai_markers = {
        title = '<LOC lobui_0585>AI Markers',
        description = '<LOC lobui_0586>Select maps with AI Markers.',
    },
    map_obsolete = {
        title = '<LOC MAPSEL_0035>Hide Obsolete',
        description = '<LOC MAPSEL_0036>Hides maps which have been replaced by new versions',
    },

    -- **********************
    -- ** Profile Strings
    -- **********************
    Profile_name = {
        title = "<LOC tooltipui0183>Name",
        description = "<LOC tooltipui0184>The Name of this Profile",
    },
    Profile_create = {
        title = "<LOC tooltipui0185>Create",
        description = "<LOC tooltipui0186>Generate a New Profile",
    },
    Profile_cancel = {
        title = "<LOC tooltipui0187>Cancel",
        description = "<LOC tooltipui0188>Exit this screen without changing Profiles",
    },
    Profile_delete = {
        title = "<LOC tooltipui0189>Delete",
        description = "<LOC tooltipui0190>Delete the Selected Profile",
    },
    Profile_ok = {
        title = "<LOC tooltipui0191>Ok",
        description = "<LOC tooltipui0192>Continue with the Selected Profile",
    },
    Profile_profilelist = {
        title = "<LOC tooltipui0193>Profile List",
        description = "<LOC tooltipui0194>All saved Profiles",
    },

    -- **********************
    -- ** Options Strings
    -- **********************
    exit_menu = {
        title = "<LOC tooltipui0056>Menu",
        description = "<LOC tooltipui0057>Opens the Game Menu",
        keyID = "toggle_main_menu",
    },
    objectives = {
        title = "<LOC tooltipui0058>Objectives",
        description = "<LOC tooltipui0059>Shows all current and completed Objectives",
        keyID = "toggle_objective_screen",
    },
    map_info = {
        title = "<LOC sel_map_0000>",
        description = "",
        keyID = "toggle_objective_screen",
    },
    inbox = {
        title = "<LOC tooltipui0060>Transmission Log",
        description = "<LOC tooltipui0061>Replay any Received Transmissions",
        keyID = "toggle_transmission_screen",
    },
    score = {
        title = "<LOC tooltipui0062>Score",
        description = "<LOC tooltipui0063>Shows the Score, -- of Units, and Elapsed Time",
        keyID = "toggle_score_screen",
    },
    diplomacy = {
        title = "<LOC tooltipui0064>Diplomacy",
        description = "<LOC tooltipui0065>Access all Diplomacy Options",
        keyID = "toggle_diplomacy_screen",
    },
    options_Pause = {
        title = "<LOC tooltipui0066>Pause",
        description = "",
    },
    options_Play = {
        title = "<LOC tooltipui0098>Play",
        description = "",
    },

    -- **********************
    -- ** Construction Manager
    -- **********************
    construction_tab_t1 = {
        title = "<LOC tooltipui0426>Tech 1",
        description = "",
    },
    construction_tab_t1_dis = {
        title = "<LOC tooltipui0427>Tech 1",
        description = "<LOC tooltipui0428>Unit's tech level is insufficient. Unable to access this technology.",
    },
    construction_tab_t2 = {
        title = "<LOC tooltipui0429>Tech 2",
        description = "",
    },
    construction_tab_t2_dis = {
        title = "<LOC tooltipui0430>Tech 2",
        description = "<LOC tooltipui0431>Unit's tech level is insufficient. Unable to access this technology.",
    },
    construction_tab_t3 = {
        title = "<LOC tooltipui0432>Tech 3",
        description = "",
    },
    construction_tab_t3_dis = {
        title = "<LOC tooltipui0433>Tech 3",
        description = "<LOC tooltipui0434>Unit's tech level is insufficient. Unable to access this technology.",
    },
    construction_tab_t4 = {
        title = "<LOC tooltipui0435>Experimental Tech",
        description = "",
    },
    construction_tab_t4_dis = {
        title = "<LOC tooltipui0436>Experimental Tech",
        description = "<LOC tooltipui0437>Unit's tech level is insufficient. Unable to access this technology.",
    },
    construction_tab_selection = {
        title = "<LOC tooltipui0438>Selected Units",
        description = "",
    },
    construction_tab_construction = {
        title = "<LOC tooltipui0548>Construction",
        description = "<LOC tooltipui0549>Allows you to build new units with the selected units",
    },
    construction_tab_construction_dis = {
        title = "<LOC tooltipui0550>Construction",
        description = "The selected units can't build other units",
    },
    construction_tab_enhancement = {
        title = "<LOC tooltipui0551>Enhancements",
        description = "<LOC tooltipui0552>Manage enhancements for the selected units",
    },
    construction_tab_enhancment_dis = {
        title = "<LOC tooltipui0553>Enhancements",
        description = "<LOC tooltipui0567>No enhancements available for the selected units",
    },
    construction_tab_enhancment_left = {
        title = "<LOC tooltipui0568>Customize [Left Arm]",
        description = "",
    },
    construction_tab_enhancment_back = {
        title = "<LOC tooltipui0569>Customize [Back]",
        description = "",
    },
    construction_tab_enhancment_right = {
        title = "<LOC tooltipui0570>Customize [Right Arm]",
        description = "",
    },
    construction_tab_attached = {
        title = "<LOC tooltipui0439>Selection and Storage",
        description = "<LOC tooltipui0440>Displays selected and stored or attached units",
    },
    construction_tab_attached_dis = {
        title = "<LOC tooltipui0441>Selection and Storage",
        description = "<LOC tooltipui0442>The selected unit(s) do not have any units attached to them",
    },
    construction_tab_templates = {
        title = "<LOC tooltipui0554>Build Templates",
        description = "<LOC tooltipui0555>Display the build templates manager",
    },
    construction_tab_templates_dis = {
        title = "<LOC tooltipui0556>Build Templates (no templates)",
        description = "<LOC tooltipui0557>Display the build templates manager",
    },
    construction_infinite = {
        title = "<LOC tooltipui0443>Infinite Build",
        description = "<LOC tooltipui0444>Toggle the infinite construction of the current queue",
    },
    construction_pause = {
        title = "<LOC tooltipui0445>Pause Construction",
        description = "<LOC tooltipui0446>[Pause/Unpause] the current construction order",
    },


    -- **********************
    -- ** In Game Replay Manager
    -- **********************
    esc_return = {
        title = "<LOC tooltipui0651>Return to Game",
        description = "<LOC tooltipui0652>Closes the menu and returns you to the current game",
    },
    esc_save = {
        title = "<LOC tooltipui0277>Save Menu",
        description = "<LOC tooltipui0278>Save your Current Game",
    },
    esc_resume = {
        title = "<LOC tooltipui0279>Resume",
        description = "<LOC tooltipui0280>Continue your Current Game",
    },
    esc_quit = {
        title = "<LOC tooltipui0281>Surrender",
        description = "<LOC tooltipui0282>Exit to the Main Menu",
    },
    esc_restart = {
        title = "<LOC tooltipui0283>Restart",
        description = "<LOC tooltipui0284>Begin this Game again",
    },
    esc_rehost = {
        title = "<LOC tooltipui0696>Rehost",
        description = "<LOC tooltipui0284>Begin this Game again",
    },
    esc_exit = {
        title = "<LOC tooltipui0285>Exit",
        description = "<LOC tooltipui0286>Close Supreme Commander: Forged Alliance",
    },
    esc_options = {
        title = "<LOC tooltipui0287>Options Menu",
        description = "<LOC tooltipui0288>Adjust Gameplay, Video and Sound Options",
    },
    esc_conn = {
        title = "<LOC tooltipui0293>Connectivity Menu",
        description = "<LOC tooltipui0294>Adjust Connectivity Options",
    },
    esc_load = {
        title = "<LOC tooltipui0340>Load",
        description = "<LOC tooltipui0341>Continue a Previously Saved Game",
    },

    -- **********************
    -- ** In Game Replay Manager
    -- **********************
    replay_pause = {
        title = "<LOC tooltipui0195>Pause",
        description = "<LOC tooltipui0196>Pause or Resume the Replay",
    },
    replay_speed = {
        title = "<LOC tooltipui0197>Game Speed",
        description = "<LOC tooltipui0198>Sets the Replay Speed",
    },
    replay_team = {
        title = "<LOC tooltipui0199>Team Focus",
        description = "<LOC tooltipui0200>Select which Army to focus on",
    },
    replay_progress = {
        title = "<LOC tooltipui0201>Progress",
        description = "<LOC tooltipui0202>Indicates your Position in the Replay",
    },
    replay_restart = {
        title = "<LOC tooltipui0203>Restart",
        description = "<LOC tooltipui0204>Plays the Current Replay from the Beginning",
    },

    -- **********************
    -- ** Post Game Score Screen
    -- **********************
    PostScore_campaign = {
        title = "<LOC tooltipui0653>Campaign",
        description = "<LOC tooltipui0654>Shows the Campaign Debriefing and Objectives",
    },
    PostScore_Grid = {
        title = "<LOC tooltipui0205>Players",
        description = "<LOC tooltipui0206>Shows the Players and Scores",
    },
    PostScore_Graph = {
        title = "<LOC tooltipui0207>Graph",
        description = "<LOC tooltipui0208>Shows a Timeline of the Game",
    },
    PostScore_general = {
        title = "<LOC tooltipui0209>General",
        description = "<LOC tooltipui0210>Shows the Overall Performance of each Player",
    },
    PostScore_units = {
        title = "<LOC tooltipui0211>Units",
        description = "<LOC tooltipui0212>Shows the Performance of each Players Military",
    },
    PostScore_resources = {
        title = "<LOC tooltipui0213>Resources",
        description = "<LOC tooltipui0214>Show the Efficiency of each Players Economy",
    },
    PostScore_Player = {
        title = "<LOC tooltipui0215>Player",
        description = "<LOC tooltipui0216>Sort by Player Name",
    },
    PostScore_Team = {
        title = "<LOC tooltipui0217>Team",
        description = "<LOC tooltipui0218>Sort by Team",
    },
    PostScore_score = {
        title = "<LOC tooltipui0219>Score",
        description = "<LOC tooltipui0220>Sort by Overall Performance",
    },
    PostScore_cdr = {
        title = "<LOC tooltipui0231>Command Units",
        description = "<LOC tooltipui0232>Sort by Command Units",
    },
    PostScore_land = {
        title = "<LOC tooltipui0233>Land Units",
        description = "<LOC tooltipui0234>Sort by Land Units",
    },
    PostScore_naval = {
        title = "<LOC tooltipui0235>Naval",
        description = "<LOC tooltipui0236>Sort by Naval Units",
    },
    PostScore_air = {
        title = "<LOC tooltipui0237>Air",
        description = "<LOC tooltipui0238>Sort by Air Units",
    },
    PostScore_structures = {
        title = "<LOC tooltipui0239>Structures",
        description = "<LOC tooltipui0240>Sort by Structures",
    },
    PostScore_experimental = {
        title = "<LOC tooltipui0241>Experimental",
        description = "<LOC tooltipui0242>Sort by Experimental Units",
    },
    PostScore_massin = {
        title = "<LOC tooltipui0245>Mass Collected",
        description = "<LOC tooltipui0246>Sort by Mass Collected",
    },
    PostScore_massover = {
        title = "<LOC tooltipui0295>Mass Wasted",
        description = "<LOC tooltipui0296>Sort by Mass Wasted",
    },
    PostScore_massout = {
        title = "<LOC tooltipui0247>Mass Spent",
        description = "<LOC tooltipui0248>Sort by Mass Spent",
    },
    PostScore_energyin = {
        title = "<LOC tooltipui0249>Energy Collected",
        description = "<LOC tooltipui0250>Sort by Energy Collected",
    },
    PostScore_energyout = {
        title = "<LOC tooltipui0297>Energy Spent",
        description = "<LOC tooltipui0298>Sort by Energy Spent",
    },
    PostScore_energyover = {
        title = "<LOC tooltipui0251>Energy Wasted",
        description = "<LOC tooltipui0252>Sort by Energy Wasted",
    },
    PostScore_total = {
        title = "<LOC tooltipui0253>Total",
        description = "<LOC tooltipui0254>Sort by Totals",
    },
    PostScore_rate = {
        title = "<LOC tooltipui0255>Rate",
        description = "<LOC tooltipui0256>Sort by Rates",
    },
    PostScore_kills = {
        title = "<LOC tooltipui0257>Kills",
        description = "<LOC tooltipui0258>Sort by Kills",
    },
    PostScore_built = {
        title = "<LOC tooltipui0259>Built",
        description = "<LOC tooltipui0260>Sort by Units Built",
    },
    PostScore_lost = {
        title = "<LOC tooltipui0261>Losses",
        description = "<LOC tooltipui0262>Sort by Units Lost",
    },
    PostScore_count = {
        title = "<LOC tooltipui0263>Count",
        description = "<LOC tooltipui0264>Sort by Total Units Built",
    },
    PostScore_mass = {
        title = "<LOC tooltipui0265>Mass",
        description = "<LOC tooltipui0266>Sort by Total Mass Collected",
    },
    PostScore_energy = {
        title = "<LOC tooltipui0267>Energy",
        description = "<LOC tooltipui0268>Sort by Total Energy Collected",
    },
    PostScore_Replay = {
        title = "<LOC tooltipui0269>Replay",
        description = "<LOC tooltipui0270>Save the Replay of this Match",
    },
    PostScore_Quit = {
        title = "<LOC tooltipui0271>Continue",
        description = "<LOC tooltipui0272>Exit the Score Screen",
    },
    LadderScore_Feedback = {
        title = "<LOC tooltipui0707>Post Feedback",
        description = "<LOC tooltipui0709>Open a web page to share your opinion about the current ladder map pool",
    },

    -- **********************
    -- ** Campaign Score
    -- **********************

    CampaignScore_Skip = {
        title = "<LOC tooltipui0381>Skip",
        description = "<LOC tooltipui0382>Skip this operation and continue to the next",
    },
    CampaignScore_Restart = {
        title = "<LOC tooltipui0383>Restart",
        description = "<LOC tooltipui0384>Restart this Operation from the beginning",
    },
    CampaignScore_Feedback = {
        title = "<LOC tooltipui0707>Post Feedback",
        description = "<LOC tooltipui0708>Open a forum thread about this mission",
    },

    -- **********************
    -- ** MFD Strings
    -- **********************
    mfd_military = {
        title = "<LOC tooltipui0076>Strategic Overlay Toggle",
        description = "<LOC tooltipui0077>View weapon and intelligence ranges",
        keyID = "tog_military",
    },
    mfd_military_dropout = {
        title = "<LOC tooltipui0447>Strategic Overlay Menu",
        description = "<LOC tooltipui0448>Select the ranges to display for the Strategic Overlay Toggle",
    },
    mfd_defense = {
        title = "<LOC tooltipui0078>Player Colors",
        description = "<LOC tooltipui0636>Toggle unit coloring between player and allegiance colors:\nYour Units\nAllied Units\nNeutral Units\nEnemy Units",
        keyID = "tog_defense",
    },
    mfd_economy = {
        title = "<LOC tooltipui0080>Economy Overlay",
        description = "<LOC tooltipui0081>Toggle income and expense overlays over units",
        keyID = "tog_econ",
    },
    mfd_intel = {
        title = "<LOC tooltipui0082>Intel",
        description = "<LOC tooltipui0083>Toggle the Intelligence Overlay. This shows the ranges of your intelligence and counter-intelligence structures",
        keyID = "tog_intel",
    },
    mfd_control = {
        title = "<LOC tooltipui0084>Control",
        description = "<LOC tooltipui0085>Toggle the Control Overlay",
    },
    mfd_idle_engineer = {
        title = "<LOC tooltipui0086>Idle Engineers",
        description = "<LOC tooltipui0087>Select Idle Engineers",
    },
    mfd_idle_factory = {
        title = "<LOC tooltipui0088>Idle Factories",
        description = "<LOC tooltipui0089>Select Idle Factories",
    },
    mfd_army = {
        title = "<LOC tooltipui0090>Land",
        description = "<LOC tooltipui0091>Target all Land Forces",
    },
    mfd_airforce = {
        title = "<LOC tooltipui0092>Air",
        description = "<LOC tooltipui0093>Target all Air Forces",
    },
    mfd_navy = {
        title = "<LOC tooltipui0094>Navy",
        description = "<LOC tooltipui0095>Target all Naval Forces",
    },
    mfd_strat_view = {
        title = "<LOC tooltipui0316>Map Options",
        description = "<LOC tooltipui0317>Adjust different viewport and map display options",
    },
    mfd_attack_ping = {
        title = "<LOC tooltipui0449>Attack Signal",
        description = "<LOC tooltipui0450>Place an allied attack request at a specific location",
        keyID = "ping_attack",
    },
    mfd_alert_ping = {
        title = "<LOC tooltipui0451>Assist Signal",
        description = "<LOC tooltipui0452>Place an allied assist request at a specific location",
        keyID = "ping_alert",
    },
    mfd_move_ping = {
        title = "<LOC tooltipui0453>Move Signal",
        description = "<LOC tooltipui0454>Request your allies move to a location",
        keyID = "ping_move",
    },
    mfd_marker_ping = {
        title = "<LOC tooltipui0455>Message Marker",
        description = "<LOC tooltipui0456>Place a message marker on the map (Shift + Control + right-click to delete)",
        keyID = "ping_marker",
    },

    -- **********************
    -- ** Misc Strings
    -- **********************
    infinite_toggle = {
        title = "<LOC tooltipui0096>Infinite Build",
        description = "<LOC tooltipui0097>Toggle infinite construction on/off for current build queue",
    },
    dip_send_alliance = {
        title = "<LOC tooltipui0289>Send Alliance Offer",
        description = "<LOC tooltipui0290>Check this box to send an Alliance Offer to this Player",
    },
    dip_share_resources = {
        title = "<LOC tooltipui0457>Share Resources",
        description = "<LOC tooltipui0458>Toggle the distribution of excess mass and energy to your allies",
    },
    dip_allied_victory = {
        title = "<LOC tooltipui0459>Allied Victory",
        description = "<LOC tooltipui0460>Toggle between individual or team victory/defeat conditions",
    },
    dip_give_resources = {
        title = "<LOC tooltipui0461>Give Resources",
        description = "<LOC tooltipui0462>Send Mass and/or Energy from storage to specified player",
    },
    dip_offer_draw = {
        title = "<LOC tooltipui0463>Propose Draw",
        description = "<LOC tooltipui0464>Propose ending the game in a draw.  All players must click this to accept.",
    },
    dip_recall_request = {
        title = "<LOC tooltipui0722>Recall",
        description = "<LOC tooltipui0723>Signal to your allies that you are ready to recall from battle.",
    },
    dip_recall_request_dis_active = {
        title = "<LOC tooltipui0724>Recall Requested",
        description = "<LOC tooltipui0725>Your team has been notified of your request to recall from battle.",
    },
    dip_recall_request_dis_scenario = {
        title = "<LOC tooltipui0726>Cannot Recall",
        description = "<LOC tooltipui0727>You cannot recall from battle in this scenario.",
    },
    dip_recall_request_dis_gate = {
        title = "<LOC tooltipui0726>Cannot Recall",
        description = "<LOC tooltipui0728>You cannot recall from battle within 5 minutes of gating in.",
    },
    dip_recall_request_dis_ai = {
        title = "<LOC tooltipui0726>Cannot Recall",
        description = "<LOC tooltipui0729>There are AI armies on your team that will not recall.",
    },
    dip_recall_request_dis_request = {
        title = "<LOC tooltipui0726>Cannot Recall",
        description = "<LOC tooltipui0730>You have sent a recall request too recently.",
    },
    dip_recall_request_dis_vote = {
        title = "<LOC tooltipui0726>Cannot Recall",
        description = "<LOC tooltipui0731>Your team has had a recall vote too recently.",
    },
    dip_recall_request_yes = {
        title = "<LOC tooltipui0732>Yes Vote",
        description = "<LOC tooltipui0733>Vote yes to your team recalling from battle as a defeat.",
    },
    dip_recall_request_no = {
        title = "<LOC tooltipui0734>No Vote",
        description = "<LOC tooltipui0735>Vote no to your team recalling from battle as a defeat.",
    },
    dip_give_units = {
        title = "<LOC tooltipui0465>Give Units",
        description = "<LOC tooltipui0466>Give currently selected units to specified player",
    },
    dip_break_alliance = {
        title = "<LOC tooltipui0467>Break Alliance",
        description = "<LOC tooltipui0468>Cancel the alliance with specified player",
    },
    dip_offer_alliance = {
        title = "<LOC tooltipui0469>Propose Alliance",
        description = "<LOC tooltipui0470>Offer an alliance to specified player",
    },
    dip_accept_alliance = {
        title = "<LOC tooltipui0471>Accept Alliance",
        description = "<LOC tooltipui0472>Specified player has offered an alliance to you",
    },
    dip_alliance_proposed = {
        title = "<LOC tooltipui0571>Alliance Proposed",
        description = "<LOC tooltipui0572>You have proposed an alliance to specified player",
    },

    score_time = {
        title = "<LOC tooltipui0473>Game Time",
        description = "",
    },
    score_units = {
        title = "<LOC tooltipui0474>Unit Count",
        description = "<LOC tooltipui0507>Current and maximum unit counts",
    },
    score_collapse = {
        title = "<LOC tooltipui0475>[Hide/Show] Score Bar",
        description = "",
        keyID = "toggle_score_screen",
    },
    fabricator_collapse = {
        title = "<LOC tooltipui0736>[Hide/Show] Mass Fabricator Panel",
        description = "",
        keyID = "toggle_mass_fabricator_panel",
    },
    voting_collapse = {
        title = "<LOC tooltipui0737>[Hide/Show] Voting Panel",
        description = "",
        keyID = "toggle_voting_panel",
    },
    econ_collapse = {
        title = "<LOC tooltipui0558>[Hide/Show] Resource Bar",
        description = "",
    },
    control_collapse = {
        title = "<LOC tooltipui0559>[Hide/Show] Control Group Bar",
        description = "",
    },
    mfd_collapse = {
        title = "<LOC tooltipui0560>[Hide/Show] Multifunction Bar",
        description = "",
    },
    objectives_collapse = {
        title = "<LOC tooltipui0561>[Hide/Show] Objectives Bar",
        description = "",
        keyID = "toggle_score_screen",
    },
    menu_collapse = {
        title = "<LOC tooltipui0562>[Hide/Show] Menu Bar",
        description = "",
    },
    avatars_collapse = {
        title = "<LOC tooltipui0563>[Hide/Show] Avatars Bar",
        description = "",
    },

    -- **********************
    -- ** Front End Strings
    -- **********************
    mainmenu_exit = {
        title = "<LOC tooltipui0133>Exit Game",
        description = "<LOC tooltipui0134>Close Supreme Commander: Forged Alliance",
    },
    mainmenu_campaign = {
        title = "<LOC tooltipui0135>Campaign",
        description = "<LOC tooltipui0136>Start a new campaign or continue a previous one",
    },
    mainmenu_mp = {
        title = "<LOC tooltipui0137>Multiplayer",
        description = "<LOC tooltipui0138>Join or host a multiplayer game",
    },
    mainmenu_skirmish = {
        title = "<LOC tooltipui0139>Skirmish Mode",
        description = "<LOC tooltipui0140>Play a quick game against one or more AI Opponents",
    },
    mainmenu_replay = {
        title = "<LOC tooltipui0141>Replay",
        description = "<LOC tooltipui0142>List and play any available replays",
    },
    mainmenu_options = {
        title = "<LOC tooltipui0143>Options",
        description = "<LOC tooltipui0144>View and adjust Gameplay, Interface, Video, and Sound options",
    },
    mainmenu_mod = {
        title = "<LOC tooltipui0145>Mods",
        description = "<LOC tooltipui0146>View, enable and disable all available Mods",
    },
    mainmenu_tutorial = {
        title = "<LOC tooltipui0318>Tutorial",
        description = "<LOC tooltipui0319>Learn to play Supreme Commander: Forged Alliance",
    },
    mainmenu_extras = {
        title = "<LOC tooltipui0355>Extras",
        description = "<LOC tooltipui0356>Access additional SupCom content and functionality",
    },
    profile = {
        title = "<LOC tooltipui0147>Profile",
        description = "<LOC tooltipui0148>Manage your Profiles",
    },
    mpselect_observe = {
        title = "<LOC tooltipui0149>Observe",
        description = "<LOC tooltipui0150>Watch a Game being played",
    },
    mpselect_join = {
        title = "<LOC tooltipui0151>Join",
        description = "<LOC tooltipui0152>Play on the Selected Server",
    },
    mpselect_gpgnet = {
        title = "<LOC tooltipui0153>GPGNet",
        description = "<LOC tooltipui0154>Log into GPGNet",
    },
         mpselect_lan = {
        title = "<LOC OPTIONS_0123>LAN",
        description = "<LOC OPTIONS_0124>Host, Join or Observe a LAN Game",
    },
    mpselect_connect = {
        title = "<LOC tooltipui0155>Direct Connect",
        description = "<LOC tooltipui0156>Join a Game by supplying the IP Address and Port",
    },
    mpselect_create = {
        title = "<LOC tooltipui0157>Create Game",
        description = "<LOC tooltipui0158>Host a new LAN Game",
    },
    mpselect_exit = {
        title = "<LOC tooltipui0159>Back",
        description = "",
    },
    mpselect_serverinfo = {
        title = "<LOC tooltipui0161>Server Information",
        description = "<LOC tooltipui0162>Displays the Status of the Currently Selected Server",
    },
    mpselect_serverlist = {
        title = "<LOC tooltipui0163>Server List",
        description = "<LOC tooltipui0164>Displays available LAN Games",
    },
    mpselect_name = {
        title = "<LOC tooltipui0165>Name",
        description = "<LOC tooltipui0166>Sets your Multiplayer Nickname",
    },
    mainmenu_quickcampaign = {
        title = "<LOC tooltipui0320>Quick Campaign",
        description = "<LOC tooltipui0321>Launches the most recent saved campaign",
    },
    mainmenu_quicklanhost = {
        title = "<LOC tooltipui0322>Quick LAN",
        description = "<LOC tooltipui0323>Launches a LAN lobby with your last settings",
    },
    mainmenu_quickipconnect = {
        title = "<LOC tooltipui0324>Direct Connect",
        description = "<LOC tooltipui0325>Direct connect to another computer using an IP address and port value",
    },
    mainmenu_quickgpgnet = {
        title = "<LOC tooltipui0326>Quick GPGNet",
        description = "<LOC tooltipui0327>Log into GPGNet",
    },
    mainmenu_quickskirmishload = {
        title = "<LOC tooltipui0328>Quick Skirmish Load",
        description = "<LOC tooltipui0329>Loads the last saved skirmish game",
    },
    mainmenu_quickreplay = {
        title = "<LOC tooltipui0330>Quick Replay",
        description = "<LOC tooltipui0331>Loads and plays the last saved replay",
    },
    modman_controlled_by_host = {
        title = "<LOC uimod_0007>Gameplay mod",
        description = "<LOC uimod_0008>This mod can only be selected by the game host",
        image = ""
    },
    modman_some_missing = {
        title = "<LOC uimod_0007>Gameplay mod",
        description = "<LOC uimod_0009>Not all players have this mod",
        image = ""
    },
    campaignselect_continue = {
        title = "<LOC tooltipui0371>Continue",
        description = "<LOC tooltipui0372>Play the latest Operation in this factions Campaign",
        image = ""
    },
    campaignselect_replay = {
        title = "<LOC tooltipui0373>Replay Op",
        description = "<LOC tooltipui0374>Replay this Operation",
        image = ''
    },
    campaignselect_fmv = {
        title = "<LOC tooltipui0375>Playback",
        description = "<LOC tooltipui0376>Watch this video then return to this screen",
        image = ''
    },
    campaignselect_select = {
        title = "<LOC tooltipui0377>Select",
        description = "<LOC tooltipui0378>Select this operation and enter the briefing room",
        image = ''
    },
    campaignselect_movie = {
        title = "<LOC tooltipui0661>Play Movie",
        description = "<LOC tooltipui0662>Watch the selected movie",
        image = ''
    },
    campaignselect_tutorial = {
        title = "<LOC tooltipui0663>Play Tutorial",
        description = "<LOC tooltipui0319>",
        image = ''
    },
    campaignselect_restart = {
        title = "<LOC tooltipui0379>Restart",
        description = "<LOC tooltipui0380>Restart the [Campaign/Skirmish] game",
        image = ''
    },
    campaignselect_load = {
        title = "<LOC tooltipui0573>Load",
        description = "<LOC tooltipui0574>Load a previously saved campaign game",
    },

    -- **********************
    -- ** Campaign briefing
    -- **********************
    campaignbriefing_restart = {
        title = "<LOC tooltipui0575>Restart",
        description = "<LOC tooltipui0576>Start the briefing from the beginning",
    },
    campaignbriefing_pause = {
        title = "<LOC tooltipui0577>Pause",
        description = "<LOC tooltipui0578>Pause the briefing",
    },
    campaignbriefing_skip = {
        title = "<LOC tooltipui0637>Skip",
        description = "<LOC tooltipui0638>Skip to the end of the briefing",
    },
    campaignbriefing_play = {
        title = "<LOC tooltipui0579>Play",
        description = "<LOC tooltipui0580>Continue playing the briefing",
    },
    campaignbriefing_launch = {
        title = "<LOC tooltipui0581>Launch",
        description = "<LOC tooltipui0582>Start the operation",
    },


    -- **********************
    -- ** Restricted Units
    -- **********************
    restricted_units_T1 = {
        title = "<LOC tooltipui0508>No Tech 1",
        description = "<LOC tooltipui0509>Prevents all T1 units being built",
    },
    restricted_units_T2 = {
        title = "<LOC tooltipui0510>No Tech 2",
        description = "<LOC tooltipui0511>Prevents all T2 units being built",
    },
    restricted_units_T3 = {
        title = "<LOC tooltipui0512>No Tech 3",
        description = "<LOC tooltipui0513>Prevents all T3 units being built",
    },
    restricted_units_experimental = {
        title = "<LOC tooltipui0514>No Experimental",
        description = "<LOC tooltipui0515>Prevents all Experimentals being built",
    },
    restricted_units_land = {
        title = "<LOC tooltipui0516>No Land",
        description = "<LOC tooltipui0517>Prevents all Land units being built",
    },
    restricted_units_air = {
        title = "<LOC tooltipui0518>No Air",
        description = "<LOC tooltipui0519>Prevents all Air units being built. Does not count UEF Novax Satellite",
    },
    restricted_units_air_t3 = {
        title = "<LOC restricted_units_data_0030>No T3 Air",
        description = "<LOC tooltipui0693>Prevents T3 Air being built.",
    },
    restricted_units_naval = {
        title = "<LOC tooltipui0520>No Naval",
        description = "<LOC tooltipui0521>Prevents all Naval units being built",
    },
    restricted_units_uef = {
        title = "<LOC tooltipui0522>No UEF",
        description = "<LOC tooltipui0523>Prevents all UEF units being built",
    },
    restricted_units_cybran = {
        title = "<LOC tooltipui0524>No Cybran",
        description = "<LOC tooltipui0525>Prevents all Cybran units being built",
    },
    restricted_units_aeon = {
        title = "<LOC tooltipui0526>No Aeon",
        description = "<LOC tooltipui0527>Prevents all Aeon units being built",
    },
    restricted_units_seraphim = {
        title = "<LOC tooltipui0528>No Seraphim",
        description = "<LOC tooltipui0529>Prevents all Seraphim units being built",
    },
    restricted_units_nukes = {
        title = "<LOC tooltipui0530>No Nukes",
        description = "<LOC tooltipui0531>Prevents all Nukes being built, apart from the UEF 'Billy' nuke",
    },
    restricted_units_gameenders = {
        title = "<LOC tooltipui0532>No Game Enders",
        description = "<LOC tooltipui0533>Restricts access to Heavy Artilley, Paragon, Novax Satellite and Yolona Oss",
    },
    restricted_units_bubbles = {
        title = "<LOC tooltipui0534>No Bubbles",
        description = "<LOC tooltipui0535>Removes all non-upgrade Bubble Shields",
    },
    restricted_units_intel = {
        title = "<LOC tooltipui0536>No Intel Structures",
        description = "<LOC tooltipui0537>Prevents players from constructing Sonar, Radar, or Optical Sensor structures",
    },
    restricted_units_supcom = {
        title = "<LOC tooltipui0538>No Support Commanders",
        description = "<LOC tooltipui0539>Prevents players from summoning Support Armored Command Units",
    },
    restricted_units_hover = {
        title = "<LOC restricted_units_data_0016>No Hover Units",
        description = "<LOC tooltipui0640>Removes units which hover"
    },
    restricted_units_forgedalliance = {
        title = "<LOC tooltipui0641>No Forged Alliance",
        description = "<LOC tooltipui0642>Removes all units which were introduced in the Forged Alliance expansion"
    },
    restricted_units_downloaded = {
        title = "<LOC tooltipui0643>No Downloaded",
        description = "<LOC tooltipui0644>Prevents players building units introduced as DLC"
    },
    restricted_units_massfab = {
        title = "<LOC tooltipui0645>No Mass Fabrication",
        description = "<LOC tooltipui0646>Prevents players building Mass Fabricators"
    },
    -- Added for FAF
    restricted_units_supportfactory = {
        title = "<LOC tooltipui0670>No Support Factories",
        description = "<LOC tooltipui0671>Prevents players from building fresh Support Factories, effectively disabling the 'Engiemod' changes"
    },
    restricted_units_t3mobileaa = {
        title = "<LOC tooltipui0672>No T3 Mobile Anti-Air",
        description = "<LOC tooltipui0673>Prevents players being able to build the new T3 MAA units"
    },
    restricted_units_wall = {
        title = "<LOC tooltipui0674>No Walls",
        description = "<LOC tooltipui0675>Prevents players being able to build Walls"
    },
    restricted_units_engineeringstation = {
        title = "<LOC tooltipui0676>No Engineering Stations",
        description = "<LOC tooltipui0677>Removes the Kennel and Hive"
    },
    restricted_units_superarty = {
        title = "<LOC tooltipui0678>No Super-Artillery",
        description = "<LOC tooltipui0679>Removes Salvation, Mavor and Scathis"
    },
    restricted_units_paragon = {
        title = "<LOC tooltipui0680>No Paragon",
        description = "<LOC tooltipui0681>Removes the Paragon, the Aeon Experimental Infinite Resource Generator"
    },
    restricted_units_satellite = {
        title = "<LOC tooltipui0682>No Satellite",
        description = "<LOC tooltipui0683>Removes the UEF Novax Satellite"
    },
    restricted_units_teleport = {
        title = "<LOC tooltipui0684>No Teleporting",
        description = "<LOC tooltipui0685>Removes the ability to upgrade ACUs and sACUs with Teleporters"
    },
    restricted_units_billy = {
        title = "<LOC tooltipui0686>No Billy",
        description = "<LOC tooltipui0687>Prevents UEF commanders from upgrading their ACU to have the 'Billy' tactical nuke upgrade"
    },
    restricted_units_eye = {
        title = "<LOC tooltipui0688>No Super-Intel",
        description = "<LOC tooltipui0689>Removes the Aeon Eye of Rhianne and the Cybran Soothsayer"
    },
    Lobby_presetDescription = {
        title = "<LOC tooltipui0694>Lobby Presets",
        description = "<LOC tooltipui0695>Save and load presets for game settings and maps"
    },

    -- **********************
    -- ** Strategic overlay
    -- **********************
    overlay_conditions = {
        title = "<LOC tooltipui0583>Conditional Overlays",
        description = "<LOC tooltipui0584>Toggle all conditional overlays",
    },
    overlay_rollover = {
        title = "<LOC tooltipui0585>Rollover Range Overlay",
        description = "<LOC tooltipui0586>Toggle the range overlay of the unit you are mousing over",
    },
    overlay_selection = {
        title = "<LOC tooltipui0587>Selection Range Overlay",
        description = "<LOC tooltipui0588>Toggle the range overlay of the unit(s) you have selected",
    },
    overlay_build_preview = {
        title = "<LOC tooltipui0589>Build Preview",
        description = "<LOC tooltipui0590>Toggle the range overlay of the unit you are about to build",
    },
    overlay_military = {
        title = "<LOC tooltipui0591>Military Overlays",
        description = "<LOC tooltipui0592>Toggle all military overlays ",
    },
    overlay_direct_fire = {
        title = "<LOC tooltipui0593>Direct Fire",
        description = "<LOC tooltipui0594>Toggle the range overlays of your point defenses, tanks and other direct-fire weaponry ",
    },
    overlay_indirect_fire = {
        title = "<LOC tooltipui0595>Indirect Fire",
        description = "<LOC tooltipui0596>Toggle the range overlays of your artillery and missile weaponry",
    },
    overlay_anti_air = {
        title = "<LOC tooltipui0597>Anti-Air",
        description = "<LOC tooltipui0598>Toggle the range overlays of your AA weaponry",
    },
    overlay_anti_navy = {
        title = "<LOC tooltipui0599>Anti-Navy",
        description = "<LOC tooltipui0600>Toggle the range overlays of your torpedo weaponry",
    },
    overlay_defenses = {
        title = "<LOC tooltipui0601>Countermeasure",
        description = "<LOC tooltipui0602>Toggle the range overlays of your shields and other countermeasure defenses",
    },
    overlay_misc = {
        title = "<LOC tooltipui0603>Miscellaneous",
        description = "<LOC tooltipui0604>Toggle the range overlays of your air staging platforms and engineering stations",
    },
    overlay_combine_military = {
        title = "<LOC tooltipui0605>Combine Military",
        description = "<LOC tooltipui0606>Combine all sub-filters into a single overlay",
    },
    overlay_intel = {
        title = "<LOC tooltipui0607>Intelligence Overlays",
        description = "<LOC tooltipui0608>Toggle all intelligence overlays ",
    },
    overlay_radar = {
        title = "<LOC tooltipui0609>Radar",
        description = "<LOC tooltipui0610>Toggle the range overlays of your radar",
    },
    overlay_sonar = {
        title = "<LOC tooltipui0611>Sonar",
        description = "<LOC tooltipui0612>Toggle the range overlays of your sonar",
    },
    overlay_omni = {
        title = "<LOC tooltipui0613>Omni",
        description = "<LOC tooltipui0614>Toggle the range overlays of your Omni sensors",
    },
    overlay_counter_intel = {
        title = "<LOC tooltipui0615>Counter-Intelligence",
        description = "<LOC tooltipui0616>Toggle the range overlays of your stealth and jamming equipment",
    },
    overlay_combine_intel = {
        title = "<LOC tooltipui0617>Combine Intelligence",
        description = "<LOC tooltipui0618>Combine all sub-filters into a single overlay",
    },

    -- **********************
    -- ** Faction select
    -- **********************
    faction_select_uef = {
        title = "<LOC tooltipui0619>UEF",
        description = "<LOC tooltipui0620>Play campaign as a UEF Commander",
    },
    faction_select_cybran = {
        title = "<LOC tooltipui0621>Cybran",
        description = "<LOC tooltipui0622>Play campaign as a Cybran Commander",
    },
    faction_select_aeon = {
        title = "<LOC tooltipui0623>Aeon",
        description = "<LOC tooltipui0624>Play campaign as an Aeon Commander",
    },

    -- **********************
    -- ** Misc
    -- **********************
    no_rush_clock = {
        title = "<LOC tooltipui0627>No Rush Clock",
        description = "<LOC tooltipui0628>Displays time remaining in the no rush clock",
    },
    save_template = {
        title = "<LOC tooltipui0629>Save Template",
        description = "<LOC tooltipui0630>Creates construction template by saving units/structures and their position",
    },
    minimap_mesh = {
        description = "<LOC tooltipui0720>Disables the rendering of meshes of units and props on the minimap to reduce the burden on the rendering thread. Can potentially improve your framerate.",
    },

    profiler_print_to_log = {
        title = "<LOC profiler_0013>Print to log",
        description = "<LOC profiler_0014>Print function bytecode to log",
    },
    profiler_benchmark_baseline_mode_none = {
        title = "<LOC profiler_0031>No baseline data",
        description = "<LOC profiler_0032>Ignore each samples' baseline",
    },
    profiler_benchmark_baseline_mode_paired = {
        title = "<LOC profiler_0033>Paired baseline data",
        description = "<LOC profiler_0034>Divide each samples' baseline into itself",
    },
    profiler_benchmark_baseline_mode_ratio = {
        title = "<LOC profiler_0035>Baseline data ratio",
        description = "<LOC profiler_0036>Treat the data and its baselines independently and perform a ratio test",
    },
    profiler_benchmark_clear_stats = {
        title = "<LOC profiler_0041>Clear stats",
        description = "<LOC profiler_0042>Clear all samples for this benchmark",
    },
}
