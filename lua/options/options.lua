--[[
This file contains a table which defines options available to the user in the options dialog

tab data is what populates each tab and defines each option in a tab
Each tab has:
    .title - the text that will appear on the tab
    .key - the key that will group the options (ie in the prefs file gameplay.help_prompts or video.resolution)
    .items - an array of the items for this key (this is an array rather than a genericly keyed table so display order can be imposed)
        .title - the text that will label the option line item
        .tip - the text that will appear in the tooltip for the item
        .key - the prefs key to identify this property
        .default - the default value of the property
        .restart - if true, setting the option will require a restart and the user will be notified
        .verify - if true, prompts the user to veryfiy the change for 15 seconds, otherwise defaults back to prior setting
        .populate - an optional function which when called, will repopulate the options custom data. The value passed in is the current value of the control (function(value))
        .set - an optional function that takes a value parameter and is responsible for determining what happens when the option is applied (function(key, value))
        .ignore - an optional function called when the option is set, checks the value, and wont change it from its former setting, and if former setting is invalid, uses return value for new value (function(value))
        .cancel - called when the option is cancelled
        .beginChange - an option function for sliders when user begins modification
        .endChange - an option function for sliders when user ends modification
        .update - a optional function that is called when the control has a new value, also receives the control (function(control, value)), not always used,
                  but if you need additonal control (say of other controls) when this value changes (for example one control may change other controls) you can
                  set up that behavior here
        .type - the type of control used to display this property
            valid types are:
            toggle - multi state toggle button (TODO - add list to replace more than 2 states?)
            button - momentary button (usually open another dialog)
            slider - a value slider
        .custom - a table of data required by the control type, different for each control type.
            slider
                .min - the minimum value for the slider
                .max - the maximum value for the slider
                .inc - the increment between slider detents, if 0 its "analog"
            toggle
                .states - table of states the toggle switch can have
                    .text = text for each state
                    .key = the key or value for each state to be stored in the pref
            button
                .text - the text label of the button

the optionsOrder table is just an array of keys in to the option table, and their order will determine what
order the tabs show in the dialog
--]]

optionsOrder = {
    "gameplay",
    "ui",
    "video",
    "sound",
}

local SetMusicVolume = import('/lua/UserMusic.lua').SetMusicVolume
local savedMasterVol = false
local savedFXVol = false
local savedMusicVol = false
local savedVOVol = false

function PlayTestSound()
    local sound = Sound{ Bank = 'Interface', Cue = 'UI_Action_MouseDown' }
    PlaySound(sound)
end

local voiceHandle = false
function PlayTestVoice()
    if not voiceHandle then
        local sound = Sound{ Bank = 'XGG', Cue = 'Computer_Computer_MissileLaunch_01351' }
        ForkThread(
            function()
                WaitSeconds(0.5)
                voiceHandle = false
            end
        )
        if voiceHandle then
            StopSound(voiceHandle)
        end
        voiceHandle = PlayVoice(sound)
    end
end

options = {
    gameplay = {
        title = "<LOC _Gameplay>",
        key = 'gameplay',
        items = {
            {
                title = "<LOC OPTIONS_0001>Zoom Wheel Sensitivity",
                key = 'wheel_sensitivity',
                type = 'slider',
                default = 40,
                set = function(key,value,startup)
                    ConExecute("cam_ZoomAmount " .. tostring(value / 100))
                end,
                custom = {
                    min = 1,
                    max = 100,
                    inc = 0,
                },
            },
            {
                title = "<LOC OPTIONS_0109>Always Render Strategic Icons",
                key = 'strat_icons_always_on',
                type = 'toggle',
                default = 0,
                set = function(key,value,startup)
                    ConExecute("ui_AlwaysRenderStrategicIcons " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0107>Construction Tooltip Information",
                tip = "<LOC OPTIONS_0108>Change the layout that information is displayed in the rollover window for units in the construction manager.",
                key = 'uvd_format',
                type = 'toggle',
                default = 'full',
                set = function(key,value,startup)
                    -- needs logic to set priority (do we really want to do this though?)
                end,
                custom = {
                    states = {
                        {text = "<LOC _Full>", key = 'full'},
                        {text = "<LOC _Limited>", key = 'limited'},
                        {text = "<LOC _Off>", key = 'off'},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0215>Show Waypoint ETAs",
                key = 'display_eta',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true,},
                        {text = "<LOC _Off>", key = false,},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0102>Multiplayer Taunts",
                tip = "<LOC OPTIONS_0103>Enable or Disable displaying taunts in multiplayer.",
                key = 'mp_taunt_head_enabled',
                type = 'toggle',
                default = 'true',
                set = function(key,value,startup)
                    -- needs logic to set priority (do we really want to do this though?)
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = 'true'},
                        {text = "<LOC _Off>", key = 'false'},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0158>Screen Edge Pans Main View",
                key = 'screen_edge_pans_main_view',
                type = 'toggle',
                default = 1,
                set = function(key,value,startup)
                    ConExecute("ui_ScreenEdgeScrollView " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0159>Arrow Keys Pan Main View",
                key = 'arrow_keys_pan_main_view',
                type = 'toggle',
                default = 1,
                set = function(key,value,startup)
                    ConExecute("ui_ArrowKeysScrollView " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0160>Pan Speed",
                key = 'keyboard_pan_speed',
                type = 'slider',
                default = 90,
                set = function(key,value,startup)
                    ConExecute("ui_KeyboardPanSpeed " .. tostring(value))
                end,
                custom = {
                    min = 1,
                    max = 200,
                    inc = 0,
                },
            },
            {
                title = "<LOC OPTIONS_0161>Accelerated Pan Speed Multiplier",
                key = 'keyboard_pan_accelerate_multiplier',
                type = 'slider',
                default = 4,
                set = function(key,value,startup)
                    ConExecute("ui_KeyboardPanAccelerateMultiplier " .. tostring(value))
                end,
                custom = {
                    min = 1,
                    max = 10,
                    inc = 1,
                },
            },
            {
                title = "<LOC OPTIONS_0174>Keyboard Rotation Speed",
                key = 'keyboard_rotate_speed',
                type = 'slider',
                default = 10,
                set = function(key,value,startup)
                    ConExecute("ui_KeyboardRotateSpeed " .. tostring(value))
                end,
                custom = {
                    min = 1,
                    max = 100,
                    inc = 0,
                },
            },
            {
                title = "<LOC OPTIONS_0163>Accelerated Keyboard Rotate Speed Multiplier",
                key = 'keyboard_rotate_accelerate_multiplier',
                type = 'slider',
                default = 2,
                set = function(key,value,startup)
                    ConExecute("ui_KeyboardRotateAccelerateMultiplier " .. tostring(value))
                end,
                custom = {
                    min = 1,
                    max = 10,
                    inc = 1,
                },
            },
            {
                title = "<LOC OPTIONS_0212>Accept Build Templates",
                key = 'accept_build_templates',
                type = 'toggle',
                default = 'yes',
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = 'yes' },
                        {text = "<LOC _Off>", key = 'no' },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0273>Assist Mex to Build Mass Storages",
                key = 'assist_mex',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = false},
                        {text = "<LOC _On>", key = true},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0285>Automatic Extractor Selection",
                key = 'automex',
                type = 'toggle',
                default = 'onlyT1',
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 'off'},
                        {text = "<LOC _OnlyT1>", key = 'onlyT1'},
                        {text = "<LOC _MaxTech>", key = 'maxTech'},
                    },
                },
            }
        },
    },
    ui = {
        title = "<LOC OPTIONS_0164>Interface",
        key = 'ui',
        items = {
            {
                title = "<LOC OPTIONS_0006>Language",
                key = 'selectedlanguage',
                type = 'toggle',
                restart = true,
                default = __language,
                custom = {
                    states = __installedlanguages,
                },
            },
            {
                title = "<LOC OPTIONS_0283>UI Scale",
                key = 'ui_scale',
                restart = true,
                type = 'toggle',
                default = 1.0,
                custom = {
                    states = {
                        {text = "80%", key = 0.8,},
                        {text = "100%", key = 1.0,},
                        {text = "125%", key = 1.25,},
                        {text = "150%", key = 1.5,},
                        {text = "175%", key = 1.75,},
                        {text = "200%", key = 2.0,},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0151>Display Subtitles",
                key = 'subtitles',
                type = 'toggle',
                default = false,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0223>Display World Border",
                key = 'world_border',
                type = 'toggle',
                default = true,
                set = function(key, value, startup)
                    import('/lua/ui/uiutil.lua').UpdateWorldBorderState(nil, value)
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0005>Display Tooltips",
                key = 'tooltips',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0009>Display Loading Tips",
                key = 'loading_tips',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0076>Economy Warnings",
                key = 'econ_warnings',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true,},
                        {text = "<LOC _Off>", key = false,},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0078>Tooltip Delay",
                key = 'tooltip_delay',
                type = 'slider',
                default = 0,
                set = function(key,value,startup)
                end,
                custom = {
                    min = 0,
                    max = 3,
                    inc = 0,
                },
            },
            {
                title = "<LOC OPTIONS_0125>Quick Exit",
                tip = "<LOC OPTIONS_0126>When close box or alt-f4 are pressed, no confirmation dialog is shown",
                key = 'quick_exit',
                type = 'toggle',
                default = 'false',
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = 'true'},
                        {text = "<LOC _Off>", key = 'false'},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0165>Lock Fullscreen Cursor To Window",
                key = 'lock_fullscreen_cursor_to_window',
                type = 'toggle',
                default = 0,
                set = function(key,value,startup)
                    ConExecute("SC_ToggleCursorClip " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0207>Main Menu Background Movie",
                key = 'mainmenu_bgmovie',
                type = 'toggle',
                default = true,
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = false },
                        {text = "<LOC _On>", key = true },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0210>Show Lifebars of Attached Units",
                key = 'show_attached_unit_lifebars',
                type = 'toggle',
                default = true,
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = false },
                        {text = "<LOC _On>", key = true },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0211>Use Factional UI Skin",
                key = 'skin_change_on_start',
                type = 'toggle',
                default = 'yes',
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = 'yes' },
                        {text = "<LOC _Off>", key = 'no' },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0279>Use Factional UI Font Color",
                key = 'faction_font_color',
                type = 'toggle',
                default = false,
                set = function(key,value,startup)
                    import('/lua/ui/uiutil.lua').UpdateCurrentSkin({faction_font_color = value})
                end,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0226>Enable Cycle Preview for Hotbuild",
                key = 'hotbuild_cycle_preview',
                type = 'toggle',
                default = 1,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
              title = "<LOC OPTIONS_0227>Cycle reset time (ms)",
              key = 'hotbuild_cycle_reset_time',
              type = 'slider',
              default = 1100,
              custom = {
                min = 100,
                max = 5000,
                inc = 100,
              },
            },
            {
                title = "<LOC OPTIONS_0228>Bigger Strategic Build Icons",
                key = 'gui_bigger_strat_build_icons',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC OPTIONS_0254>Bigger icons", key = 1 },
                        {text = "<LOC OPTIONS_0255>Bigger icons with TechMarker", key = 2 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0229>Template Rotation",
                key = 'gui_template_rotator',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0231>Draggable Build Queue",
                key = 'gui_draggable_queue',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0232>Middle Click Avatars",
                key = 'gui_idle_engineer_avatars',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0233>All Race Templates",
                key = 'gui_all_race_templates',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0234>Single Unit Selected Info",
                key = 'gui_enhanced_unitview',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0236>Zoom Pop Distance",
                key = 'gui_zoom_pop_distance',
                type = 'slider',
                default = 80,
                custom = {
                    min = 1,
                    max = 160,
                    inc = 1,
                },
            },

            {
                title = "<LOC OPTIONS_0237>Factory Build Queue Templates",
                key = 'gui_templates_factory',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0238>Seperate Idle Builders",
                key = 'gui_seperate_idle_builders',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0239>Visible Template Names",
                key = 'gui_visible_template_names',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0240>Template Name Cutoff",
                key = 'gui_template_name_cutoff',
                type = 'slider',
                default = 0,
                custom = {
                    min = 0,
                    max = 10,
                    inc = 1,
                },
            },

            {
                title = "<LOC OPTIONS_0241>Display more Unit Stats",
                key = 'gui_detailed_unitview',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0242>Always Render Custom Names",
                key = 'gui_render_custom_names',
                type = 'toggle',
                default = 0,
                set = function(key,value,startup)
                    ConExecute("ui_RenderCustomNames " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0243>Force Render Enemy Lifebars",
                key = 'gui_render_enemy_lifebars',
                type = 'toggle',
                default = 0,
                set = function(key,value,startup)
                    ConExecute("UI_ForceLifbarsOnEnemy " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0244>Show Armament Build in Factory Menu",
                key = 'gui_render_armament_detail',
                type = 'toggle',
                default = 1,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },

            {
                title = "<LOC OPTIONS_0245>Improved Unit deselection",
                key = 'gui_improved_unit_deselection',
                type = 'toggle',
                default = 0,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0275>Maximum Reclaim Label Count",
                tip = "<LOC OPTIONS_0276>When showing the reclaim label overlay, no more than this many labels will be shown",
                key = 'maximum_reclaim_count',
                type = 'slider',
                set = function(key, value, startup)
                    import('/lua/ui/game/reclaim.lua').updateMaxLabels(value)
                end,
                default = 1000,
                custom = {
                    min = 500,
                    max = 5000,
                    inc = 500,
                },
            },
            {
                title = "<LOC OPTIONS_0277>Minimum Reclaim Label Amount",
                tip = "<LOC OPTIONS_0278>When showing the reclaim label overlay, items with mass values less than this won't be shown",
                key = 'minimum_reclaim_amount',
                type = 'slider',
                set = function(key, value, startup)
                    import('/lua/ui/game/reclaim.lua').updateMinAmount(value)
                end,
                default = 10,
                custom = {
                    min = 10,
                    max = 300,
                    inc = 10,
                },
            },
            {
                title = "<LOC OPTIONS_0281>Hotkey Labels",
                key = 'show_hotkeylabels',
                type = 'toggle',
                default = true,
                custom = {
                    states = {
                        {text = "<LOC _On>", key = true},
                        {text = "<LOC _Off>", key = false},
                    },
                },
            },
        },
    },
    video = {
        title = "<LOC _Video>",
        key = 'video',
        items = {
            {
                title = "<LOC OPTIONS_0010>Primary Adapter",
                key = 'primary_adapter',
                type = 'toggle',
                default = '1024,768,60',
                verify = true,
                populate = function(value)
                    -- this is a bit odd, but the value of the primary determines how to populate the value of the secondary
                    ConExecute("SC_SecondaryAdapter " .. tostring('windowed' == value))
                end,
                update = function(control,value)
                    ConExecute("SC_SecondaryAdapter " .. tostring('windowed' == value))
                end,
                ignore = function(value)
                    if value == 'overridden' then
                        return '1024,768,60'
                    end
                end,
                set = function(key,value,startup)
                    if not startup then
                        ConExecute("SC_PrimaryAdapter " .. tostring(value))
                    end
                    ConExecute("SC_SecondaryAdapter " .. tostring('windowed' == value))
                end,
                custom = {
                    states = {
                        { text = "<LOC _Command_Line_Override>", key = 'overridden' },
                        { text = "<LOC OPTIONS_0070>Windowed", key = 'windowed' },
                        -- the remaining values are populated at runtime from device caps
                        -- what follows is just an example of the data which will be encountered
                        { text =  "1024x768(60)", key = '1024,768,60' },
                        { text = "1152x864(60)", key = '1152,864,60' },
                        { text = "1280x768(60)", key = '1280,768,60' },
                        { text = "1280x800(60)", key = '1280,800,60' },
                        { text = "1280x1024(60)", key = '1280,1024,60' },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0147>Secondary Adapter",
                key = 'secondary_adapter',
                type = 'toggle',
                default = 'disabled',
                restart = true,
                ignore = function(value)
                    if value == 'overridden' then
                        return 'disabled'
                    end
                end,
                custom = {
                    states = {
                        { text = "<LOC _Command_Line_Override>", key = 'overridden' },
                        { text = "<LOC _Disabled>", key = 'disabled' },
                        -- the remaining values are populated at runtime from device caps
                        -- what follows is just an example of the data which will be encountered
                        { text =  "1024x768(60)", key = '1024,768,60' },
                        { text = "1152x864(60)", key = '1152,864,60' },
                        { text = "1280x768(60)", key = '1280,768,60' },
                        { text = "1280x800(60)", key = '1280,800,60' },
                        { text = "1280x1024(60)", key = '1280,1024,60' },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_001>Fidelity Presets",
                key = 'fidelity_presets',
                type = 'toggle',
                default = 4,
                update = function(control,value)
                    logic = import('/lua/options/optionsLogic.lua')

                    aaoptions = GetAntiAliasingOptions()

                    aamax = 0
                    aamed = 0
                    if 0 < table.getn(aaoptions) then
                        aahigh = aaoptions[table.getn(aaoptions)]
                        aamed = aaoptions[math.ceil(table.getn(aaoptions)/2)]
                    end

                    if 0 == value then
                        logic.SetValue('fidelity',0,true)
                        logic.SetValue('shadow_quality',0,true)
                        logic.SetValue('texture_level',2,true)
                        logic.SetValue('antialiasing',0,true)
                        logic.SetValue('level_of_detail',0,true)
                        logic.SetValue('bloom_render',0,true)
                        logic.SetValue('render_skydome',0,true)
                    elseif 1 == value then
                        logic.SetValue('fidelity',1,true)
                        logic.SetValue('shadow_quality',1,true)
                        logic.SetValue('texture_level',1,true)
                        logic.SetValue('antialiasing',0,true)
                        logic.SetValue('level_of_detail',1,true)
                        logic.SetValue('bloom_render',0,true)
                        logic.SetValue('render_skydome',1,true)
                    elseif 2 == value then
                        logic.SetValue('fidelity',2,true)
                        logic.SetValue('shadow_quality',2,true)
                        logic.SetValue('texture_level',0,true)
                        logic.SetValue('antialiasing',aamed,true)
                        logic.SetValue('level_of_detail',2,true)
                        logic.SetValue('bloom_render',0,true)
                        logic.SetValue('render_skydome',1,true)
                    elseif 3 == value then
                        logic.SetValue('fidelity',2,true)
                        logic.SetValue('shadow_quality',3,true)
                        logic.SetValue('texture_level',0,true)
                        logic.SetValue('antialiasing',aahigh,true)
                        logic.SetValue('level_of_detail',2,true)
                        logic.SetValue('bloom_render',0,true)
                        logic.SetValue('render_skydome',1,true)
                    else
                    end
                end,
                set = function(key,value,startup)
                end,
                custom = {
                    states = {
                        { text = "<LOC _Low>", key = 0 },
                        { text = "<LOC _Medium>", key = 1 },
                        { text = "<LOC _High>", key = 2 },
                        { text = "<LOC _Ultra>", key = 3 },
                        { text = "<LOC _Custom>", key = 4 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0168>Render Sky",
                key = 'render_skydome',
                type = 'toggle',
                default = 1,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("ren_Skydome " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0018>Fidelity",
                key = 'fidelity',
                type = 'toggle',
                default = 1,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("graphics_Fidelity " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Low>", key = 0},
                        {text = "<LOC _Medium>", key = 1},
                        {text = "<LOC _High>", key = 2},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0024>Shadow Fidelity",
                key = 'shadow_quality',
                type = 'toggle',
                default = 1,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("shadow_Fidelity " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0},
                        {text = "<LOC _Low>", key = 1},
                        {text = "<LOC _Medium>", key = 2},
                        {text = "<LOC _High>", key = 3},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0015>Anti-Aliasing",
                key = 'antialiasing',
                type = 'toggle',
                default = 0,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    if not startup then
                        ConExecute("SC_AntiAliasingSamples " .. tostring(value))
                    end
                end,
                custom = {
                    states = {
                        {text = "<LOC OPTIONS_0029>Off", key = 0},
                        -- the remaining values are populated at runtime from device caps
                        -- what follows is just an example of the data which will be encountered
                        {text =  "2", key =  2},
                        {text =  "4", key =  4},
                        {text =  "8", key =  8},
                        {text = "16", key = 16},
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0019>Texture Detail",
                key = 'texture_level',
                type = 'toggle',
                default = 1,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("ren_MipSkipLevels " .. tostring(value))
                end,
                custom = {
                    states = {
                        { text = "<LOC OPTIONS_0112>Low", key = 2 },
                        { text = "<LOC OPTIONS_0111>Medium", key = 1 },
                        { text = "<LOC OPTIONS_0110>High", key = 0 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_002>Level Of Detail",
                key = 'level_of_detail',
                type = 'toggle',
                default = 1,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("SC_CameraScaleLOD " .. tostring(value))
                end,
                custom = {
                    states = {
                        { text = "<LOC _Low>", key = 0 },
                        { text = "<LOC _Medium>", key = 1 },
                        { text = "<LOC _High>", key = 2 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0148>Vertical Sync",
                key = 'vsync',
                type = 'toggle',
                default = 1,
                set = function(key,value,startup)
                    if not startup then
                        ConExecute("SC_VerticalSync " .. tostring(value))
                    end
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            },
            {
                title = "<LOC OPTIONS_0169>Bloom Render",
                key = 'bloom_render',
                type = 'toggle',
                default = 0,
                update = function(control,value)
                    import('/lua/options/optionsLogic.lua').SetValue('fidelity_presets',4,true)
                end,
                set = function(key,value,startup)
                    ConExecute("ren_bloom " .. tostring(value))
                end,
                custom = {
                    states = {
                        {text = "<LOC _Off>", key = 0 },
                        {text = "<LOC _On>", key = 1 },
                    },
                },
            }
        },
    },
    sound = {
        title = "<LOC _Sound>",
        items = {
            {
                title = "<LOC OPTIONS_0028>Master Volume",
                key = 'master_volume',
                type = 'slider',
                default = 100,

                init = function()
                    savedMasterVol = GetVolume("Global")
                end,

                cancel = function()
                    if savedMasterVol then
                        SetVolume("Global", savedMasterVol)
                    end
                end,

                set = function(key,value,startup)
                    SetVolume("Global", value / 100)
                    savedMasterVol = value/100
                end,
                update = function(control,value)
                    SetVolume("Global", value / 100)
                end,
                custom = {
                    min = 0,
                    max = 100,
                    inc = 1,
                },
            },
            {
                title = "<LOC OPTIONS_0026>FX Volume",
                key = 'fx_volume',
                type = 'slider',
                default = 100,

                init = function()
                    savedFXVol = GetVolume("World")
                end,

                cancel = function()
                    if savedFXVol then
                        SetVolume("World", savedFXVol)
                        SetVolume("Interface", savedFXVol)
                    end
                end,

                set = function(key,value,startup)
                    SetVolume("World", value / 100)
                    SetVolume("Interface", value / 100)
                    savedFXVol = value/100
                end,

                update = function(control,value)
                    SetVolume("World", value / 100)
                    SetVolume("Interface", value / 100)
                    PlayTestSound()
                end,

                custom = {
                    min = 0,
                    max = 100,
                    inc = 1,
                },
            },
            {
                title = "<LOC OPTIONS_0027>Music Volume",
                key = 'music_volume',
                type = 'slider',
                default = 100,

                init = function()
                    savedMusicVol = GetVolume("Music")
                    SetMusicVolume(savedMusicVol)
                end,

                cancel = function()
                    if savedMusicVol then
                        SetMusicVolume(savedMusicVol)
                    end
                end,

                set = function(key,value,startup)
                    SetMusicVolume(value / 100)
                    savedMusicVol = value/100
                end,
                update = function(key,value)
                    SetMusicVolume(value / 100)
                end,
                custom = {
                    min = 0,
                    max = 100,
                    inc = 1,
                },
            },
            {
                title = "<LOC OPTIONS_0066>VO Volume",
                key = 'vo_volume',
                type = 'slider',
                default = 100,

                init = function()
                    savedVOVol = GetVolume("VO")
                end,

                cancel = function()
                    if savedVOVol then
                        SetVolume("VO", savedVOVol)
                    end
                end,

                set = function(key,value,startup)
                    SetVolume("VO", value / 100)
                    savedVOVol = value/100
                end,
                update = function(key,value)
                    SetVolume("VO", value / 100)
                    PlayTestVoice()
                end,
                custom = {
                    min = 0,
                    max = 100,
                    inc = 1,
                },
            },
        },
    },
}
