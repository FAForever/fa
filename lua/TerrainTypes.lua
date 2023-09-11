----[                                                                             ]--
----[  File     : TerrainTypes.lua                                                ]--
----[  Author(s): Bob Berry, Gordon Duclos                                        ]--
----[                                                                             ]--
----[  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.             ]--

--[[ 
    Each terrain type has a type code that must be unique, with a max of 255. If you
    modify a terrain type you will modify all maps using that type, so be careful.
    Also note that changes in these values can could potentially affect the 
    simulation (for example, he `Bumpiness` field could jostle a unit's orientation as it 
    is driving).
     
    In script use GetTerrainType() with the current map o-grid position, to get access
    to the terrain type type table at that location. Position (-1, -1) will return the 
    'Default' terrain type.

- Terrain type code ranges -
    002-079 reserved for dirt, dust, and sand
    080-149 reserved for vegetation
    150-189 reserved for rocky
    190-199 reserved for tarmacs
    200-219 reserved for snowy
    220-255 reserved for water
 
- Map Style List (7)-
    Desert
    Evergreen
    Geothermal
    Lava
    RedRock
    Tropical
    Tundra    
 
- Effect mapping key descriptions -

    These type mappings map to effect 'Type' names, mapped in unit display 
    blueprints. If there is no effects defined for a specific terrain, the 'Default' 
    terrain type will be used. This is list of effect types and a brief description
    of what they are used for.

    Idle:
        Hover02                 - Hover jet effect, used on UEA0305
        SeaIdle01               - 
        SeaIdle02               - 
        SonarBouy01             - Sonar buoy pulse ring effect
        Radar01                 - Radar ambient effect
        Jammer01                - Radar Jammer ambient effects
        Hover01                 - Hover effect used by hover tanks.
        Hover04                 - Hover exhaust for Cybran gunships, URA0203, XRA0105, XRA0305
        Hover03                 - Large hover exhaust for URA0401 Cybran Reaver
        AeonGroundFX01          - Aeon factional hover energy unit effect
        AeonGroundFXT1Engineer  - Aeon factional hover exhaust effect 
        AeonGroundFXT2Engineer  - Aeon factional hover exhaust effect 2
        UnderWater01            -
        SeraphimGroundFX01      - Seraphim factional hover energy unit effect
        SeraphimGroundFX02      - Seraphim factional hover energy unit effect for XSL0305
    Impact:     
        Small01                 - Small projectile impact effect, z-axis aligned for directional impact, used on UAL0101
        Small02                 - Small projectile impact effect, y-axis aligned for bomb impacts, used on URA0103
        Medium01                - Medium sized impact effect, y-axis aligned for bomb impacts, used on UAA0103
        Medium02                - Medium sized impact effect, for projectiles with low impact rate, 
                                  z-axis aligned for directional impact, used on UEL0201
        Medium03                - Medium sized impact effect, for projectiles with high impact rate, 
                                  z-axis aligned for directional impact, used on UEA0203
        Large01                 - Large radial impact effect, uaa0304
        LargeBeam01             - Large static beam impact effect, infinite lifetime emitter, UAL0401
        LargeBeam02             - Huge static beam impact effect, infinite lifetime emitter, C.Z.A.R
    LayerChange:
        TakeOff01               - Air unit takeoff effects
        Landing01               - Air unit landing effects
    MotionChange:
        Submerge01              -
        Submerge02              -
        Surface01               - 
        Surface02               -
        GroundKickup02          - Large Rear tread kickup, used on UEL0401
        GroundKickup03          - Medium unit dirt.debris kickup effects, used on UAL0202
        GroundKickup04          - Front tread kickup, used on UEL0401
        FootFall01              - Large walking unit footfalls effects, used on SpiderBot, Galactic C.
        FootFall02              - Small walker unit footfall effects, used on Commander units
        Hover01                 - Hover unit terrain effects, used on UEL0203
        Hover04                 - Hover exhaust for Cybran gunships, URA0203, XRA0105, XRA0305    
        Hover03                 - Large hover exhaust for URA0401 Cybran Reaver        
        AeonGroundFX01          - Aeon factional hover energy unit effect
        AeonGroundFXT1Engineer  - Aeon factional hover exhaust effect 
        AeonGroundFXT2Engineer  - Aeon factional hover exhaust effect 2
        AirMoveExhaust01        - Air unit movement effects 
        AirMoveExhaust02        - Air unit movement effects
        AirMoveExhaust03        - Air unit movement effects, Seraphim
        BackWake                - Sea unit rear movement effects. (water/underwater)
        LeftFrontWake           - Sea unit left wake movement effect
        RightFrontWake          - Sea unit right wake movement effect
        SeraphimGroundFX01      - Seraphim factional hover energy unit effect
        SeraphimGroundFX02      - Seraphim factional hover energy unit effect for XSL0305
--]]

---@alias TerrainStyle
---| "Desert"
---| "Evergreen"
---| "Geothermal"
---| "Lava"
---| "RedRock"
---| "Tropical"
---| "Tundra"

---@alias TerrainTreadType "Default" | "None"


---@alias TerrainEffectType
---| LayerTerrainEffectType  # block type `Layer`
---| "FXImpact"              # block type `ImpactType`
---| "FXMotionChange"        # block type `MotionChangeType`
---| "FXLayerChange"         # block type `LayerChangeType`
---@alias LayerTerrainEffectType
---| "FXIdle"
---| "FXMovement"
---| "FXOther"

---@class TerrainType
---@field Name string
---@field TypeCode integer
---@field Color Color
---@field Description string
---@field Style TerrainStyle
---@field Slippery number
---@field Bumpiness number
---@field Blocking boolean
---@field FXIdle table<Layer, table<IdleEffectType, FileName[]>>
---@field FXImpact table<ImpactType, table<ImpactEffectType, FileName[]>>
---@field FXLayerChange table<LayerChangeType, table<LayerChangeEffectType, FileName[]>>
---@field FXMotionChange table<MotionChangeType, table<MotionChangeEffectType, FileName[]>>
---@field FXMovement table<Layer, table<MovementEffectType, FileName[]>>
---@field FXOther table<Layer, table<OtherEffectType, FileName[]>>
---@field Treads? TerrainTreadType

local EmitterBasePath = '/effects/emitters/'


--- Terrain type definitions
---@type TerrainType[]
TerrainTypes = {
    {
        Name = 'Default',
        TypeCode = 1,
        Color = '00000000',
        Description = 'Default',
        Style = 'Default',
        Slippery = 0,
        Bumpiness = 0,
        Blocking = false,
        FXIdle = {
            Air = {
                Hover03 = { EmitterBasePath .. 'air_hover_exhaust_01_emit.bp', },
                Hover04 = { EmitterBasePath .. 'cybran_hover_01_emit.bp', },
            },
            Land = {
                AeonGroundFX01 = { EmitterBasePath .. 'aeon_groundfx_emit.bp', },
                AeonGroundFXT1Engineer = { EmitterBasePath .. 'aeon_t1eng_groundfx01_emit.bp', },
                AeonGroundFXT2Engineer = {
                    EmitterBasePath .. 'aeon_t2eng_groundfx01_emit.bp',
                    EmitterBasePath .. 'aeon_t2eng_groundfx02_emit.bp',
                },
                Jammer01 = {
                    EmitterBasePath .. 'jammer_ambient_01_emit.bp',
                    EmitterBasePath .. 'jammer_ambient_02_emit.bp',
                },
                Cloak01 = {
                    EmitterBasePath .. 'cloak_ambient_01_emit.bp',
                },
                Radar01 = { EmitterBasePath .. 'radar_ambient_01_emit.bp', },
                SeraphimGroundFX01 = {
                    EmitterBasePath .. 'seraphim_groundfx_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_02_emit.bp',
                },
                SeraphimGroundFX02 = {
                    EmitterBasePath .. 'seraphim_groundfx_03_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_04_emit.bp',
                },
            },
            Sub = {
                UnderWater01 = { EmitterBasePath .. 'underwater_idle_bubbles_01_emit.bp', },
            },
            Seabed = {
                UnderWater01 = { EmitterBasePath .. 'underwater_idle_bubbles_01_emit.bp', },
            },
            Water = {
                AeonGroundFX01 = { EmitterBasePath .. 'aeon_groundfx_emit.bp', },
                AeonGroundFXT1Engineer = { EmitterBasePath .. 'aeon_t1eng_groundfx01_emit.bp', },
                AeonGroundFXT2Engineer = {
                    EmitterBasePath .. 'aeon_t2eng_groundfx01_emit.bp',
                    EmitterBasePath .. 'aeon_t2eng_groundfx02_emit.bp',
                },
                Hover01 = { EmitterBasePath .. 'tt_water_hover01_01_emit.bp', },
                SeaIdleGunship01 = { EmitterBasePath .. 'water_idle_ripples_gunship_01.bp', },
                SeaIdleGunship02 = { 
                    EmitterBasePath .. 'water_idle_ripples_gunship_01.bp',
                    EmitterBasePath .. 'aeon_being_built_ambient_03_emit.bp' 
                },
                SeaIdle01 = { EmitterBasePath .. 'water_idle_ripples_02_emit.bp', },
                SeaIdle02 = { EmitterBasePath .. 'water_idle_ripples_03_emit.bp', },
                SonarBuoy01 = { EmitterBasePath .. 'water_sonarbuoyring_01_emit.bp', },
                SeraphimGroundFX01 = {
                    EmitterBasePath .. 'seraphim_groundfx_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_02_emit.bp',
                },
                SeraphimGroundFX02 = {
                    EmitterBasePath .. 'seraphim_groundfx_03_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_04_emit.bp',
                },
            },
        },
        FXImpact = {
            Terrain = {
                LargeBeam02 = {
                    EmitterBasePath .. 'dust_cloud_01_emit.bp',
                    EmitterBasePath .. 'quantum_generator_end_02_emit.bp',
                },
            },
            UnderWater = {
                Small01 = {
                    EmitterBasePath .. 'destruction_underwater_explosion_flash_01_emit.bp',
                    EmitterBasePath .. 'tti_default_underwater_hit_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
            },
            UnitUnderwater = {
                Small01 = {
                    EmitterBasePath .. 'destruction_underwater_explosion_flash_01_emit.bp',
                    EmitterBasePath .. 'tti_default_underwater_hit_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
            },
            Water = {
                Small01 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
                Small02 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
                Medium01 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
                Medium02 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
                Medium03 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
                Large01 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_01_emit.bp',
                    EmitterBasePath .. 'water_splash_plume_02_emit.bp',
                },
            },
        },
        FXLayerChange = {
            AirWater = {
                Landing01 = { EmitterBasePath .. 'tt_water_landing01_emit.bp', },
            },
            -- WaterAir = {
            --     TakeOff01 = { EmitterBasePath .. 'tt_water_takeoff_01_emit.bp', },
            -- },
        },
        FXMotionChange = {
            SubBottomUp = {
                Surface01 = {
                    EmitterBasePath .. 'tt_water_surface01_01_emit.bp',
                    EmitterBasePath .. 'tt_water_surface01_02_emit.bp',
                },
                Surface02 = {
                    EmitterBasePath .. 'tt_water_surface02_01_emit.bp',
                    EmitterBasePath .. 'tt_water_surface02_02_emit.bp',
                    EmitterBasePath .. 'tt_water_surface02_03_emit.bp',
                },
            },
            WaterTopDown = {
                Submerge01 = { EmitterBasePath .. 'tt_water_submerge01_01_emit.bp', },
                Submerge02 = { EmitterBasePath .. 'tt_water_submerge02_01_emit.bp', },
            },
        },
        FXMovement = {
            Air = {
                AirMoveExhaust01 = { EmitterBasePath .. 'contrail_delayed_mist_01_emit.bp', },
                AirMoveExhaust02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
                AirMoveExhaust03 = { EmitterBasePath .. 'seraphim_airmoveexhaust_01_emit.bp', },
                Hover04 = { EmitterBasePath .. 'cybran_hover_01_emit.bp', },
                Hover03 = { EmitterBasePath .. 'air_hover_exhaust_01_emit.bp', },
                SerOHWAirMoveExhaust01 = {
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_01_emit.bp', -- faint blue
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_02_emit.bp', -- faint rings
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_03_emit.bp', -- distortion
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_04_emit.bp', -- bright blue, shorter lifetime
                },
                SerOHWAirMoveExhaust02 = {
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_05_emit.bp', -- bright blue, shorter lifetime
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_06_emit.bp', -- faint blue
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_07_emit.bp', -- distortion
                    EmitterBasePath .. 'seraphim_ohwalli_strategic_flight_fxtrails_08_emit.bp', -- bright spot
                },
            },
            Land = {
                AeonGroundFX01 = { EmitterBasePath .. 'aeon_groundfx_emit.bp', },
                AeonGroundFXT1Engineer = { EmitterBasePath .. 'aeon_t1eng_groundfx01_emit.bp', },
                AeonGroundFXT2Engineer = {
                    EmitterBasePath .. 'aeon_t2eng_groundfx01_emit.bp',
                    EmitterBasePath .. 'aeon_t2eng_groundfx02_emit.bp',
                },
                SeraphimGroundFX01 = {
                    EmitterBasePath .. 'seraphim_groundfx_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_02_emit.bp',
                },
                SeraphimGroundFX02 = {
                    EmitterBasePath .. 'seraphim_groundfx_03_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_04_emit.bp',
                },
            },
            Sub = {
                BackWake = { EmitterBasePath .. 'underwater_move_trail_01_emit.bp', },
            },
            Seabed = {
                UnderWater01 = { EmitterBasePath .. 'underwater_bubbles_01_emit.bp', },
            },
            Water = {
                AeonGroundFX01 = { EmitterBasePath .. 'aeon_groundfx_emit.bp', },
                AeonGroundFXT1Engineer = { EmitterBasePath .. 'aeon_t1eng_groundfx01_emit.bp', },
                AeonGroundFXT2Engineer = {
                    EmitterBasePath .. 'aeon_t2eng_groundfx01_emit.bp',
                    EmitterBasePath .. 'aeon_t2eng_groundfx02_emit.bp',
                },
                BackWake = {
                    EmitterBasePath .. 'water_move_trail_back_02_emit.bp',
                    EmitterBasePath .. 'water_move_trail_back_03_emit.bp',
                    EmitterBasePath .. 'water_move_trail_back_04_emit.bp',
                },
                Hover01 = { EmitterBasePath .. 'tt_water_hover01_01_emit.bp', },
                LeftFrontWake = { EmitterBasePath .. 'water_move_wake_front_l_01_emit.bp', },
                RightFrontWake = { EmitterBasePath .. 'water_move_wake_front_r_01_emit.bp', },
                SeraphimGroundFX01 = {
                    EmitterBasePath .. 'seraphim_groundfx_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_02_emit.bp',
                },
                SeraphimGroundFX02 = {
                    EmitterBasePath .. 'seraphim_groundfx_03_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_04_emit.bp',
                },
            },
        },
        FXOther = {
            Land = {
                TreeRootDirt01 = { EmitterBasePath .. 'tree_uproot_01_emit.bp', },
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_05_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt01',
        TypeCode = 2,
        Color = 'FFFF0000',
        Description = 'Default Dirt',
        Slippery = 0,
        Bumpiness = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt02',
        TypeCode = 3,
        Color = 'FF440707',
        Description = 'Red/brown/biege dirt, with slight vegetation',
        Style = 'Evergreen',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_dirt02_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_dirt02_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_largebeam01_02_emit.bp',
                },
                LargeBeam02 = {
                    EmitterBasePath .. 'dust_cloud_01_emit.bp',
                    EmitterBasePath .. 'quantum_generator_end_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_dirt02_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt02_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt02_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt02_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt02_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt02_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt02_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_dirt02_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt02_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_dirt02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt02_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_dirt02_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt02_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt02_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt03',
        TypeCode = 4,
        Color = 'FF88BBF8',
        Description = 'Brown/gray earth',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt05',
        TypeCode = 5,
        Color = 'FF880066',
        Description = 'Red earth',
        Style = 'RedRock',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt05_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_dirt05_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt05_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_dirt05_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt05_largebeam01_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_dirt05_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt05_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt05_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt05_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt05_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt05_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt05_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_dirt05_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt05_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_dirt05_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt05_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_dirt05_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt05_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt05_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt05_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt05_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_07_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt06',
        TypeCode = 6,
        Color = 'FF886611',
        Description = 'darker red/brown earth',
        Style = 'RedRock',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt05_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_dirt05_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt05_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_dirt05_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt05_largebeam01_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_dirt05_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt05_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt05_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt05_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt05_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt05_landing01_01_emit.bp' },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt05_takeoff01_01_emit.bp' },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_dirt05_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt05_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_dirt05_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt05_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_dirt05_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt05_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt05_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt05_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt05_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt07',
        TypeCode = 7,
        Color = 'FF882d62',
        Description = 'White/Beige Desert',
        Style = 'Desert',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt07_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_dirt07_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_dirt07_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_dirt07_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt07_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt07_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt07_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt07_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt07_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt07_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_dirt07_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_dirt07_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt07_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_dirt07_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt07_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt07_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt07_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_06_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt08',
        TypeCode = 8,
        Color = 'FF58bd56',
        Description = 'Beige/Brown Rocky Desert',
        Style = 'Desert',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp' },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt07_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_dirt07_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_dirt07_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_dirt07_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt07_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt07_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt07_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt07_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt07_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt07_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_dirt07_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_dirt07_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt07_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_dirt07_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt07_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt07_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt07_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_06_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Dirt09',
        TypeCode = 9,
        Blocking = true,
        Color = 'FF642727',
        Description = 'Blocking variant of Red/brown/biege dirt, with slight vegetation (Dirt02)',
        Style = 'Evergreen',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_dirt02_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_dirt02_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_largebeam01_02_emit.bp',
                },
                LargeBeam02 = {
                    EmitterBasePath .. 'dust_cloud_01_emit.bp',
                    EmitterBasePath .. 'quantum_generator_end_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_dirt02_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt02_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt02_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt02_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt02_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt02_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt02_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_dirt02_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt02_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_dirt02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt02_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_dirt02_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt02_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt02_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Sand01',
        TypeCode = 40,
        Color = 'FFFFFFFF',
        Description = 'White sand',
        Style = 'Tropical',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_sand01_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_sand01_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_sand01_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_sand01_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_sand01_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_sand01_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_sand01_small01_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_sand01_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_sand01_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_sand01_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_sand01_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_sand01_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_sand01_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_sand01_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_sand01_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_sand01_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_06_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Sand02',
        TypeCode = 41,
        Color = 'FFDEDEB9',
        Description = 'Sand grassy',
        Style = 'Evergreen',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_06_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Vegetation01',
        TypeCode = 80,
        Color = 'FF00FF00',
        Description = 'Default Vegetation',
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_08_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Vegetation02',
        TypeCode = 81,
        Color = 'FF00FFFF',
        Description = 'Rocky grass',
        Style = 'Evergreen',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_dirt02_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_dirt02_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_dirt02_largebeam01_02_emit.bp',
                },
                LargeBeam02 = {
                    EmitterBasePath .. 'dust_cloud_01_emit.bp',
                    EmitterBasePath .. 'quantum_generator_end_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_dirt02_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_dirt02_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_dirt02_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_dirt02_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_dirt02_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_dirt02_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_dirt02_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_dirt02_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_dirt02_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_dirt02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_dirt02_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_dirt02_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_dirt02_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_dirt02_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_dirt02_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_08_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Vegetation03',
        TypeCode = 82,
        Color = 'FF900000',
        Description = 'Light green olive vegetation',
        Style = 'Evergreen',
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_vegetation03_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_vegetation05_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_vegetation05_large01_02_emit.bp',
                },
                LargeBeam01 = { EmitterBasePath .. 'tti_vegetation05_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_vegetation05_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_vegetation05_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_vegetation05_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_vegetation05_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_vegetation05_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_vegetation05_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_vegetation05_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_vegetation03_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_vegetation03_footfall02_01_emit.bp', },
                GroundKickup01 = {
                    EmitterBasePath .. 'tt_vegetation03_groundkickup01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_groundkickup01_02_emit.bp',
                },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_vegetation03_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_vegetation03_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_vegetation03_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_vegetation03_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_08_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Vegetation04',
        TypeCode = 83,
        Color = 'FFFF2222',
        Description = 'Dark Green olive vegetation',
        Style = 'Evergreen',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_vegetation05_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_vegetation05_large01_02_emit.bp',
                },
                LargeBeam01 = { EmitterBasePath .. 'tti_vegetation05_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_vegetation05_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_vegetation05_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_vegetation05_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_vegetation05_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_vegetation05_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_vegetation05_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_vegetation05_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_vegetation03_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_vegetation03_footfall02_01_emit.bp', },
                GroundKickup01 = {
                    EmitterBasePath .. 'tt_vegetation03_groundkickup01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_groundkickup01_02_emit.bp',
                },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_vegetation03_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation03_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_vegetation03_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_vegetation03_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_vegetation03_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_08_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Vegetation05',
        TypeCode = 84,
        Color = 'FF338822',
        Description = 'Green olive vegetation',
        Style = 'Tropical',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_vegetation05_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_vegetation05_large01_02_emit.bp',
                },
                LargeBeam01 = { EmitterBasePath .. 'tti_vegetation05_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_vegetation05_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_vegetation05_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_vegetation05_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_vegetation05_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_vegetation05_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_vegetation05_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_vegetation05_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_vegetation05_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation05_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_vegetation05_footfall02_01_emit.bp', },
                GroundKickup01 = {
                    EmitterBasePath .. 'tt_vegetation05_groundkickup01_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation05_groundkickup01_02_emit.bp',
                },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_vegetation05_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation05_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = {
                    EmitterBasePath .. 'tt_vegetation05_groundkickup03_01_emit.bp',
                    EmitterBasePath .. 'tt_vegetation05_groundkickup01_02_emit.bp',
                },
                GroundKickup04 = { EmitterBasePath .. 'tt_vegetation05_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_vegetation05_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_08_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky01',
        TypeCode = 150,
        Color = 'FFFF66FF',
        Description = 'Default Rocky',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Concrete01',
        TypeCode = 151,
        Color = 'FF220022',
        Description = 'Concrete',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'None',
    },
    {
        Name = 'Rocky02',
        TypeCode = 152,
        Color = 'FFFF33FF',
        Description = 'Gray rock',
        Style = 'Evergreen',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky03',
        TypeCode = 153,
        Color = 'FF992299',
        Description = 'Icy Black/Gray Rocky',
        Style = 'Tundra',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky04',
        TypeCode = 154,
        Color = 'FF880000',
        Description = 'Red rock',
        Style = 'RedRock',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky05',
        TypeCode = 155,
        Color = 'FF880000',
        Description = 'Beige dusty rock',
        Style = 'Desert',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky06',
        TypeCode = 156,
        Color = 'FF6660BB',
        Description = 'Light Lava Rock',
        Style = 'Lava',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky06_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_rocky06_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky06_large01_02_emit.bp',
                },
                LargeBeam01 = { EmitterBasePath .. 'tti_rocky06_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_rocky06_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky06_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky06_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky06_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_rocky06_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_rocky06_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_rocky06_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_rocky06_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky06_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_rocky06_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_rocky06_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_rocky06_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky06_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky06_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky07',
        TypeCode = 157,
        Color = 'FF228822',
        Description = 'Dark Lava Rock',
        Style = 'Lava',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky06_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_rocky06_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_rocky06_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_rocky06_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky06_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky06_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky06_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_rocky06_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_rocky06_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_rocky06_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_rocky06_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky06_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_rocky07_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_rocky06_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_rocky07_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky06_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky06_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky08',
        TypeCode = 158,
        Color = 'FF1111FF',
        Description = 'Green rock',
        Style = 'Evergreen',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky09',
        TypeCode = 159,
        Color = 'FF111155',
        Description = 'Green/gray/block rock w/ vegetation',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky09_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_rocky09_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_rocky09_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_rocky09_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky09_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky09_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky09_small01_01_emit.bp', },
            },
        },
        FXMovement = {
            Air = {
                AirMoveExhaust01 = { EmitterBasePath .. 'contrail_delayed_mist_01_emit.bp', },
                AirMoveExhaust02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
                AirMoveExhaust03 = { EmitterBasePath .. 'seraphim_airmoveexhaust_01_emit.bp', },
            },
            Land = {
                AeonGroundFX01 = { EmitterBasePath .. 'aeon_groundfx_emit.bp', },
                AeonGroundFXT1Engineer = { EmitterBasePath .. 'aeon_t1eng_groundfx01_emit.bp', },
                AeonGroundFXT2Engineer = {
                    EmitterBasePath .. 'aeon_t2eng_groundfx01_emit.bp',
                    EmitterBasePath .. 'aeon_t2eng_groundfx02_emit.bp',
                },
                FootFall01 = { EmitterBasePath .. 'tt_rocky09_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky09_footfall01_01_emit.bp', },
                GroundKickup01 = {
                    EmitterBasePath .. 'tt_rocky09_groundkickup01_01_emit.bp',
                    EmitterBasePath .. 'tt_rocky09_groundkickup01_02_emit.bp',
                },
                GroundKickup02 = { EmitterBasePath .. 'tt_rocky06_groundkickup02_01_emit.bp', },
                GroundKickup03 = {
                    EmitterBasePath .. 'tt_rocky09_groundkickup01_01_emit.bp',
                    EmitterBasePath .. 'tt_rocky09_groundkickup01_02_emit.bp',
                },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky06_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky09_hover01_01_emit.bp', },
                SeraphimGroundFX01 = {
                    EmitterBasePath .. 'seraphim_groundfx_emit.bp',
                    EmitterBasePath .. 'seraphim_groundfx_02_emit.bp',
                },

            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky10',
        TypeCode = 160,
        Color = 'FF333333',
        Description = 'Gray/brown rock, cliffsides',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky11',
        TypeCode = 161,
        Color = 'FF333333',
        Description = 'Geothermal dark green/gray rock',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky11_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_rocky11_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky11_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_rocky11_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky11_largebeam01_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_rocky11_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky11_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky11_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky11_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_rocky11_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_rocky11_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_rocky11_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_rocky11_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky11_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_rocky11_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_rocky11_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_rocky11_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_rocky11_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky11_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky11_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky12',
        TypeCode = 162,
        Color = 'FF333388',
        Description = 'Geothermal gray rock',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky12_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_rocky12_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky12_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_rocky12_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky12_largebeam01_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_rocky12_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky12_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky12_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky12_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_rocky12_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_rocky12_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_rocky12_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_rocky12_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky12_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_rocky12_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_rocky12_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_rocky12_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_rocky12_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky12_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky12_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky13',
        TypeCode = 163,
        Color = 'FF883388',
        Description = 'Geothermal light gray/green rock',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_rocky13_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_rocky13_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky13_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_rocky13_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_rocky13_largebeam01_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_rocky13_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_rocky13_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_rocky13_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_rocky13_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_rocky13_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_rocky13_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_rocky13_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = { EmitterBasePath .. 'tt_rocky13_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_rocky13_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_rocky13_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_rocky13_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_rocky13_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_rocky13_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_rocky13_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_rocky13_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky14',
        TypeCode = 164,
        Color = 'FF0000FF',
        Description = 'Blue Crystal',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_crystal_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = {
                    EmitterBasePath .. 'tti_crystal_large01_01_emit.bp',
                    EmitterBasePath .. 'tti_crystal_large01_02_emit.bp',
                },
                LargeBeam01 = {
                    EmitterBasePath .. 'tti_crystal_largebeam01_01_emit.bp',
                    EmitterBasePath .. 'tti_crystal_largebeam01_02_emit.bp',
                },
                LargeBeam02 = {
                    EmitterBasePath .. 'dust_cloud_07_emit.bp',
                    EmitterBasePath .. 'quantum_generator_end_02_emit.bp',
                },
                Medium01 = { EmitterBasePath .. 'tti_crystal_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_crystal_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_crystal_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_crystal_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_crystal_small01_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_crystal_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_crystal_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                GroundKickup01 = { EmitterBasePath .. 'tt_crystal_groundkickup01_01_emit.bp', },
                GroundKickup02 = { EmitterBasePath .. 'tt_crystal_groundkickup02_01_emit.bp', },
                GroundKickup03 = { EmitterBasePath .. 'tt_crystal_groundkickup03_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_crystal_groundkickup04_01_emit.bp', },
                FootFall01 = { EmitterBasePath .. 'tt_crystal_footfall01_01_emit.bp', },
                FootFall02 = { EmitterBasePath .. 'tt_crystal_footfall02_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_crystal_hover01_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Rocky15',
        TypeCode = 165,
        Color = 'FFFF1212',
        Description = 'Cyber Strata',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'TarmacUEF',
        TypeCode = 190,
        Color = 'FFFF00FF',
        Description = 'UEF Tarmac',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'None',
    },
    {
        Name = 'TarmacAeon',
        TypeCode = 191,
        Color = 'FFFF00FF',
        Description = 'Aeon Tarmac',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'None',
    },
    {
        Name = 'TarmacCybran',
        TypeCode = 192,
        Color = 'FFFF00FF',
        Description = 'Cybran Tarmac',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'None',
    },
    {
        Name = 'Snowy01',
        TypeCode = 200,
        Color = 'FF9999FF',
        Description = 'Snowy, dark blue, hard ice',
        Style = 'Tundra',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_snowy01_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_snowy01_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_snowy01_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_snowy01_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_snowy01_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_snowy01_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_snowy01_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_snowy01_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_snowy01_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_snowy01_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_snowy01_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy01_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_snowy02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_snowy01_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_snowy01_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy01_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_snowy01_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_snowy01_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_snowy01_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_09_emit.bp', },
            },
        },
    },
    {
        Name = 'Snowy02',
        TypeCode = 201,
        Color = 'FFBBBBBB',
        Description = 'Snowy, light blue snow pack',
        Style = 'Tundra',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_snowy02_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_snowy02_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_snowy02_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_snowy02_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_snowy02_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_snowy02_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_snowy02_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_snowy01_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_snowy02_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_snowy02_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_snowy02_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy02_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_snowy02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_snowy02_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_snowy02_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy02_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_snowy02_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_snowy02_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_snowy02_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_09_emit.bp', },
            },
        },
    },
    {
        Name = 'Snowy03',
        TypeCode = 202,
        Color = 'FF995599',
        Description = 'Snowy, high albedo, bright white snow',
        Style = 'Tundra',
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                Hover01 = { EmitterBasePath .. 'tt_snowy02_hover01_01_emit.bp', },
            },
        },
        FXImpact = {
            Terrain = {
                Large01 = { EmitterBasePath .. 'tti_snowy02_large01_01_emit.bp', },
                LargeBeam01 = { EmitterBasePath .. 'tti_snowy02_largebeam01_01_emit.bp', },
                Medium01 = { EmitterBasePath .. 'tti_snowy02_medium01_01_emit.bp', },
                Medium02 = { EmitterBasePath .. 'tti_snowy02_medium02_01_emit.bp', },
                Medium03 = { EmitterBasePath .. 'tti_snowy02_medium03_01_emit.bp', },
                Small01 = { EmitterBasePath .. 'tti_snowy02_small01_01_emit.bp', },
                Small02 = { EmitterBasePath .. 'tti_snowy01_small02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            AirLand = {
                Landing01 = { EmitterBasePath .. 'tt_snowy02_landing01_01_emit.bp', },
            },
            LandAir = {
                TakeOff01 = { EmitterBasePath .. 'tt_snowy02_takeoff01_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                FootFall01 = {
                    EmitterBasePath .. 'tt_snowy02_footfall01_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy02_footfall01_02_emit.bp',
                },
                FootFall02 = { EmitterBasePath .. 'tt_snowy02_footfall02_01_emit.bp', },
                GroundKickup01 = { EmitterBasePath .. 'tt_snowy02_groundkickup01_01_emit.bp', },
                GroundKickup02 = {
                    EmitterBasePath .. 'tt_snowy02_groundkickup02_01_emit.bp',
                    EmitterBasePath .. 'tt_snowy02_groundkickup02_02_emit.bp',
                },
                GroundKickup03 = { EmitterBasePath .. 'tt_snowy02_groundkickup01_01_emit.bp', },
                GroundKickup04 = { EmitterBasePath .. 'tt_snowy02_groundkickup04_01_emit.bp', },
                Hover01 = { EmitterBasePath .. 'tt_snowy02_hover01_01_emit.bp', },
            },
        },
        FXOther = {
            Land = {
                ThauTerrainMuzzle = { EmitterBasePath .. 'seraphim_tau_cannon_muzzle_flash_09_emit.bp', },
            },
        },
    },
    {
        Name = 'Water01',
        TypeCode = 220,
        Color = 'FFFFFF00',
        Description = 'Default Water',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
    },
    {
        Name = 'Water02',
        TypeCode = 221,
        Color = 'FF808000',
        Description = 'Shoreline water',
        Style = 'Evergreen',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
            Land = {
                SeaIdle02 = { EmitterBasePath .. 'tt_water02_seaidle02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            SeabedLand = {
                Surface01 = { EmitterBasePath .. 'tt_water_shoreline_surface01_01_emit.bp', },
                Surface02 = { EmitterBasePath .. 'tt_water_shoreline_surface02_01_emit.bp', },
            },
            WaterLand = {
                Surface01 = { EmitterBasePath .. 'tt_water02_surface03_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                Shoreline01 = { EmitterBasePath .. 'tt_water02_shoreline01_01_emit.bp', },
                FootFall01 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_02_emit.bp',
                    EmitterBasePath .. 'tt_water02_footfall01_01_emit.bp',
                },
            },
            Seabed = {
                Shoreline01 = { EmitterBasePath .. 'tt_water02_shoreline01_01_emit.bp', },
            },
        },
    },
    {
        Name = 'Water03',
        TypeCode = 222,
        Color = 'FF208044',
        Description = 'Deep Dark Blue Ocean Water',
        Style = 'Evergreen',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
    },
    {
        Name = 'Water04',
        TypeCode = 223,
        Color = 'FF88c894',
        Description = 'Shallow Light Blue Water',
        Style = 'Evergreen',
        Bumpiness = 0,
        Slippery = 0,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        FXLayerChange = {
            SeabedLand = {
                Surface01 = { EmitterBasePath .. 'tt_water_shoreline_surface01_01_emit.bp', },
                Surface02 = { EmitterBasePath .. 'tt_water_shoreline_surface02_01_emit.bp', },
            },
        },
    },
    {
        Name = 'Water05',
        TypeCode = 224,
        Color = 'FF88c894',
        Description = 'Shoreline red rock water',
        Style = 'RedRock',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water06',
        TypeCode = 225,
        Color = 'FF992254',
        Description = 'Deep default red rock water',
        Style = 'RedRock',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water07',
        TypeCode = 226,
        Color = 'FF992254',
        Description = 'Tropical Shoreline',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
        FXLayerChange = {
            SeabedLand = {
                Surface01 = { EmitterBasePath .. 'tt_water_shoreline_surface01_01_emit.bp', },
                Surface02 = { EmitterBasePath .. 'tt_water_shoreline_surface02_01_emit.bp', },
            },
            WaterLand = {
                Surface01 = { EmitterBasePath .. 'tt_water02_surface03_01_emit.bp', },
            },
        },
        FXMovement = {
            Land = {
                Shoreline01 = { EmitterBasePath .. 'tt_water02_shoreline01_01_emit.bp', },
                FootFall01 = {
                    EmitterBasePath .. 'water_splash_ripples_ring_02_emit.bp',
                    EmitterBasePath .. 'tt_water02_footfall01_01_emit.bp',
                },
            },
            Seabed = {
                Shoreline01 = { EmitterBasePath .. 'tt_water02_shoreline01_01_emit.bp', },
            },
        },
    },
    {
        Name = 'Water08',
        TypeCode = 227,
        Color = 'FF88c894',
        Description = 'Tropical light blue water shallows',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water09',
        TypeCode = 228,
        Color = 'FF208044',
        Description = 'Tropical mid-depth blue',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water10',
        TypeCode = 229,
        Color = 'FF104014',
        Description = 'Tropical deep water, dark blue',
        Style = 'Tropical',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Lava01',
        TypeCode = 230,
        Blocking = true,
        Color = 'FFCC2254',
        Description = 'Lava',
        Style = 'Lava',
        Bumpiness = 0,
        Slippery = 0,
        HeightOffset = -0.15,
        HealthEffectPerSecond = -0.02,
        FXIdle = {
            Air = {
                Hover02 = { EmitterBasePath .. 'tt_airhover_exhaust02_01_emit.bp', },
            },
        },
        Treads = 'Default',
    },
    {
        Name = 'Water11',
        TypeCode = 231,
        Color = 'FF208044',
        Description = 'Desert shoreline water',
        Style = 'Desert',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water12',
        TypeCode = 232,
        Color = 'FF104014',
        Description = 'Desert deep water',
        Style = 'Desert',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water13',
        TypeCode = 233,
        Color = 'FF208084',
        Description = 'Tundra shoreline water',
        Style = 'Tundra',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water14',
        TypeCode = 234,
        Color = 'FF104014',
        Description = 'Tundra deep water, blue',
        Style = 'Tundra',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water15',
        TypeCode = 235,
        Color = 'FF10C014',
        Description = 'Tundra mid-level water, aquamarine',
        Style = 'Tundra',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water16',
        TypeCode = 236,
        Color = 'FF10C014',
        Description = 'Lava water shoreline',
        Style = 'Lava',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water17',
        TypeCode = 237,
        Color = 'FF104014',
        Description = 'Lava water',
        Style = 'Lava',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water18',
        TypeCode = 238,
        Color = 'FF104014',
        Description = 'Geothermal shoreline water',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water19',
        TypeCode = 239,
        Color = 'FF904014',
        Description = 'Geothermal olive water',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
    },
    {
        Name = 'Water20',
        TypeCode = 240,
        Color = 'FF904094',
        Description = 'Geothermal mint water',
        Style = 'Geothermal',
        Bumpiness = 0,
        Slippery = 0,
    },
}

-- These are the names of the columns to create and populate (in order) in the editor's
-- TerrainType tool.
EditorColumns = {
    'Name',
    'TypeCode',
    'Blocking',
    'Style',
    'Description',
}
