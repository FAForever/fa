-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/UnitsRestrictions.lua
-- * Authors    : Gas Powered Games, FAF Community, HUSSAR
-- * Summary    : Contains mappings of restriction presets to restriction categories and/or enhancements
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ==========================================================================================

local presetsRestrictions = {}
-- NOTE this table has the following internal structure and it is generated/cached in GetPresetsData()
--   presetKey = {
--      key          = "presetKey",
--      name         = "localized name that will display in title of tooltip",
--      tooltip      = "tooltipID that will display in context of tooltip",
--      Icon         = "/textures/path/icon_name.dds",
--      categories   = "CATEGORY1 * CATEGORY2 + unitID", -- set using Expressions[presetKey]
--      enhancements = { "EnhancementName1", "EnhancementName2"},  -- set using Enhancements[presetKey]
--   }
-- --------------------------------------------------------------------------------------------
-- TODO fix categories for units:
-- add AIR, TECH, UEF to /units/uea0001_unit.bp Engineering Drone

-- TODO for next version of Units Manager:
-- use Categories of Weapon (see projectile blueprints) to restrict units
-- -------------------------------------------------------------------------------------------

--- defines expressions in single place for celerity and re-usability purpose in CreatePresets()
Expressions = {

-- NOTE use this process for defining new expressions that will restrict units in game and mods (units packs):
-- 1. Try using blueprint's categories only:                  "(TECH3 * NAVAL)"
-- 2. Try using blueprint's categories and unit IDs:          "(TECH3 * NAVAL) - xss0202"
-- 3. Try using list of multiple unit IDs:                    "dalk003 + delk002"
-- 4. Try using blueprint's categories and enhancement names:  "(SUBCOMMANDER * ResourceAllocation) - SCUs with RAS preset
-- You can get the UnitID here : http://content.faforever.com/faf/unitsDB/

-- NOTE that categories must be in UPPER case, blueprint IDs in lower case, and enhancement names in CamelCase
-- both categories and blueprint IDs can be used together or individually but
-- they need to be separated by the following operation symbols:
-- '*'  Intersection = CATEGORY1 and CATEGORY2 and ID1 and ID2
-- '+'  Union        = CATEGORY1 or CATEGORY2 or ID1 or ID2
-- '-'  Subtraction  = CATEGORY1 and not CATEGORY2
-- '()' Parenthesis  = (CATEGORY1 and CATEGORY2) or CATEGORY3

-- NOTE the following expression were carefully defined and each used category has a purpose!
-- be careful when editing them or you may brake restriction system in FA game

    -- excluding engineers, economy, and factories because players will not progress to higher tech levels
    T1          = "(TECH1 - (MOBILE * ENGINEER) - (STRUCTURE * FACTORY) - ECONOMIC)",
    T2          = "(TECH2 - (MOBILE * ENGINEER) - (STRUCTURE * FACTORY) - ECONOMIC + (TECH2 * CRABEGG))",
    T3          = "(TECH3 - (MOBILE * ENGINEER) - (STRUCTURE * FACTORY) - ECONOMIC + (TECH3 * CRABEGG) + SUBCOMMANDER)",
    T4          = "(EXPERIMENTAL - (MOBILE * ENGINEER))",
    -- excluding ACUs because game might crash if someone picks restricted faction
    UEF         = "(UEF - COMMAND)",
    CYBRAN      = "(CYBRAN - COMMAND)",
    AEON        = "(AEON - COMMAND)",
    SERAPHIM    = "(SERAPHIM - COMMAND)",
    NOMADS      = "(NOMADS - COMMAND)",

    T4ARTY      = "(ARTILLERY * EXPERIMENTAL) - FACTORY",  -- "xab2307 + url0401 + ueb2401"
    T3ARTY      = "(ARTILLERY * STRUCTURE * TECH3)",  -- "uab2302 + urb2302 + ueb2302 + xsb2302", Heavy Artillery
    T2ARTY      = "(ARTILLERY * STRUCTURE * TECH2)",
    T1ARTY      = "(ARTILLERY * STRUCTURE * TECH1)",

    SATELLITE   = "(SATELLITE + ORBITALSYSTEM)", --"(xeb2402 + xea0002)",

    NUKET4ML    = "(STRUCTURE * NUKE * EXPERIMENTAL)" , -- "xsb2401" -- SERA Yolona Oss
    NUKET3ML    = "(STRUCTURE * NUKE * TECH3 - MINE)",  -- "uab2305 + urb2305 + ueb2305 + xsb2305"
    NUKET3DEF   = "(STRUCTURE * ANTIMISSILE * (TECH3 + EXPERIMENTAL))",   -- "uab4302 + urb4302 + ueb4302 + xsb4302"
    NUKENAVAL   = "(NUKE * NAVAL)",                     -- "uas0304 + urs0304 + ues0304 + xss0302" -- SERA Battleship
    NUKESUBS    = "(NUKE * SUBMERSIBLE)",               -- "uas0304 + urs0304 + ues0304"

    -- unfortunate, some units must be restricted using their IDs unless their categories are updated with a new TML category
    TMLNAVAL    = "(NUKE * SUBMERSIBLE) + xss0303 + xss0202 + xas0306 + ues0202", -- SERA Carrier + SERA Cruiser + AEON Missile Ship + UEF Cruiser
    TMLDEF      = "(STRUCTURE * TECH2 * ANTIMISSILE)",
    TMLBASE     = "(STRUCTURE * TACTICALMISSILEPLATFORM)", -- xsb2108 + urb2108 + ueb2108 + uab2108
    TMLMOBILE   = "(MOBILE * LAND * INDIRECTFIRE * SILO)", -- XSL0111 + URL0111 + UEL0111 + UAL0111 + XEL0306

    -- added exclusion of engineers and structures because they are restricted by other presets
    LAND        = "(LAND - ENGINEER - STRUCTURE + SUBCOMMANDER)",
    -- added restriction of air staging structures because they are not needed when all air units are restricted
    AIR         = "(STRUCTURE * AIRSTAGINGPLATFORM) + (AIR - POD)",
    NAVAL       = "((STRUCTURE * NAVAL * FACTORY) + (NAVAL * MOBILE - MOBILESONAR))",
    HOVER       = "(HOVER - INSIGNIFICANTUNIT - ENGINEER)",
    AMPHIBIOUS  = "(AMPHIBIOUS)",
    SUBS        = "((NAVAL * SUBMERSIBLE) - STRUCTURE)",
    BOTS        = "(LAND * BOT)",
    BASE        = "(STRUCTURE - FACTORY - MASSEXTRACTION - MASSSTORAGE - MASSFABRICATION - ENERGYPRODUCTION - ENERGYSTORAGE + MOBILESONAR)",

    -- units buildable by CYBRAN T4 Megalith:
    -- xrl0002 Crab Egg (Engineer)
    -- xrl0003 Crab Egg (Brick)
    -- xrl0004 Crab Egg (Flak)
    -- xrl0005 Crab Egg (Artillery)
    -- drlk005 Crab Egg (Bouncer)
    CRABEGG       = '(xrl0002 + xrl0003 + xrl0004 + xrl0005 + drlk005)',
    -- added exclusion of aircraft carriers, Tzar, and Atlantis in T3_AIR expression since they can build air
    T3_AIR        = "(TECH3 * AIR - FACTORY)",
    T3_LAND       = "(TECH3 * LAND - FACTORY)",
    T3_SUBS       = "(TECH3 * SUBMERSIBLE - FACTORY)",

    T3_MOBILE_AA    = "(TECH3 * LAND * MOBILE * BUILTBYTIER3FACTORY * ANTIAIR) + drlk005",   -- + Crab Egg AA
    T3_MOBILE_ARTY  = "(TECH3 * LAND * MOBILE * BUILTBYTIER3FACTORY * ARTILLERY) + xrl0005", -- + Crab Egg Arty
    T3_AIR_GUNSHIPS = "(TECH3 * AIR * GROUNDATTACK)",
    T3_AIR_BOMBERS  = "(TECH3 * AIR * (ANTINAVY + BOMBER))",

    T1_LAND_SPAM  = "(TECH1 * LAND - STRUCTURE - ENGINEER)",
    T2_LAND_SPAM  = "(TECH2 * LAND - STRUCTURE - ENGINEER)",
    T3_LAND_SPAM  = "(TECH3 * LAND - STRUCTURE - ENGINEER)",
    T1_NAVY_SPAM  = "(TECH1 * NAVAL - STRUCTURE - ENGINEER - MOBILESONAR)",
    T2_NAVY_SPAM  = "(TECH2 * NAVAL - STRUCTURE - ENGINEER - MOBILESONAR)",
    T3_NAVY_SPAM  = "(TECH3 * NAVAL - STRUCTURE - ENGINEER - MOBILESONAR)",
    T1_AIR_SPAM   = "(TECH1 * AIR - STRUCTURE - ENGINEER - SCOUT - TRANSPORTATION + (TECH1 * GROUNDATTACK))",
    T2_AIR_SPAM   = "(TECH2 * AIR - STRUCTURE - ENGINEER - SCOUT - TRANSPORTATION + (TECH2 * GROUNDATTACK))",
    T3_AIR_SPAM   = "(TECH3 * AIR - STRUCTURE - ENGINEER - SCOUT - TRANSPORTATION + (TECH3 * GROUNDATTACK))",
    T1_BASE_SPAM  = "(TECH1 * STRUCTURE - FACTORY - MASSEXTRACTION - MASSSTORAGE - MASSFABRICATION - ENERGYPRODUCTION - ENERGYSTORAGE + (TECH1 * MOBILESONAR))",
    T2_BASE_SPAM  = "(TECH2 * STRUCTURE - FACTORY - MASSEXTRACTION - MASSSTORAGE - MASSFABRICATION - ENERGYPRODUCTION - ENERGYSTORAGE + (TECH2 * MOBILESONAR))",
    T3_BASE_SPAM  = "(TECH3 * STRUCTURE - FACTORY - MASSEXTRACTION - MASSSTORAGE - MASSFABRICATION - ENERGYPRODUCTION - ENERGYSTORAGE + (TECH3 * MOBILESONAR))",

    -- including Satellite, Soul Ripper, Czar, and Ahwassa and Ghetto-Gunship
    SNIPES_AIR    = "((AIR * (TECH2 + TECH3 + EXPERIMENTAL) * (GROUNDATTACK + BOMBER + ANTINAVY)) + uaa0310 + ual0106 + uel0106 + url0106)", -- CZAR and labs for GhetoGunship
    SNIPES_LAND   = "(LAND * MOBILE * BOMB)",
    SNIPES_BOTS   = "(LAND * SNIPER * BOT)",
    SNIPES_BASE   = "(STRUCTURE * MINE)", -- for mods that add LAND MINES

    ANTIAIR_FIGHTERS = "(ANTIAIR * AIR - EXPERIMENTAL - GROUNDATTACK)",
    ANTIAIR_NAVY     = "(ANTIAIR * NAVAL - EXPERIMENTAL - FRIGATE)", -- could include SERA T3 sub
    ANTIAIR_LAND     = "(ANTIAIR * LAND - EXPERIMENTAL + url0301_AntiAir)",
    ANTIAIR_BASE     = "(ANTIAIR * STRUCTURE)",

    TORPEDO_AIR   = "(ANTINAVY * AIR)", -- Include CZAR, as it has torpedo weapon
    TORPEDO_BOATS = "(ANTINAVY * NAVAL)",
    TORPEDO_LAND  = "(ANTINAVY * LAND)",
    TORPEDO_BASE  = "(ANTINAVY * STRUCTURE)",

    DIRECTFIRE_AIR      = "(BOMBER * AIR - ANTINAVY)",
    DIRECTFIRE_GUNSHIPS = "(GROUNDATTACK * AIR)",
    DIRECTFIRE_NAVY     = "(DIRECTFIRE * NAVAL)",
    DIRECTFIRE_LAND     = "(DIRECTFIRE * LAND - COMMAND + SUBCOMMANDER)",
    DIRECTFIRE_BOTS     = "(DIRECTFIRE * BOT)",
    DIRECTFIRE_BASE     = "(DIRECTFIRE * STRUCTURE)",
    DIRECTFIRE_BASE_T3  = "(DIRECTFIRE * STRUCTURE * TECH3)",
    DIRECTFIRE_BASE_T2  = "(DIRECTFIRE * STRUCTURE * TECH2)",
    DIRECTFIRE_BASE_T1  = "(DIRECTFIRE * STRUCTURE * TECH1)",

    SHIELD_AIR  = "(SHIELD * AIR)",
    SHIELD_NAVY = "(SHIELD * NAVAL)",
    SHIELD_LAND = "(SHIELD * LAND - TANK - BOT + uel0301_BubbleShield + uel0401)", -- excluding personal shields
    SHIELD_BASE = "(SHIELD * STRUCTURE)",

    AIR_TANSPORTS = "(AIR * TRANSPORTATION)",

    SUPPFAC      = "(SUPPORTFACTORY)",
    ENGISTATION  = "(STRUCTURE * ENGINEERSTATION)", -- no need to exclude pod drones
    ENGIDRONES   = "(STRUCTURE * ENGINEERSTATION * UEF) + (SUBCOMMANDER * Pod) + POD", -- UEF COM WITH DRONES
    ENGINEERS    = "(LAND * ENGINEER) - COMMAND - SUBCOMMANDER - Pod - POD + xrl0002", -- civil engineers + Crab Egg (Engineer)

    PARAGON      = "(EXPERIMENTAL * MASSPRODUCTION * ENERGYPRODUCTION)",
    FABS         = "(STRUCTURE * MASSFABRICATION) - EXPERIMENTAL",
    MASSINCOME   = "(STRUCTURE * MASSEXTRACTION) - EXPERIMENTAL",
    ENGYINCOME   = "(STRUCTURE * ENERGYPRODUCTION) - EXPERIMENTAL",

    SUPCOMS      = "(SUBCOMMANDER + GATE)",
    RAS          = "(SUBCOMMANDER * ResourceAllocation)",   -- RAS SCU PRESETS (url0301_ras + uel0301_ras + ual0301_ras)"
    TMLPACK      = "(SUBCOMMANDER * (Missile + RightRocket + LeftRocket))", -- TML SCU PRESET xsl0301_missile
    TELE         = "(SUBCOMMANDER * Teleporter)",           -- TML SCU PRESET with teleporter
    CLOAK        = "(SUBCOMMANDER * CloakingGenerator) + url0301_Cloak",

    INTEL_OPTICS = "(STRUCTURE * OPTICS)", -- "xab3301 + xrb3301",
    INTEL_SONAR  = "(STRUCTURE * SONAR) + MOBILESONAR",
    INTEL_BASE   = "(((OMNI + RADAR + SONAR) * STRUCTURE) + MOBILESONAR - DEFENSE)",
    INTEL_AIR    = "(((OMNI + RADAR + SONAR + SCOUT) * AIR) - BOMBER - DEFENSE - GROUNDATTACK - ANTIAIR - ANTINAVY)",
    INTEL_LAND   = "(((OMNI + RADAR + SONAR + SCOUT) * LAND) - COMMAND - DEFENSE - SUBCOMMANDER - ANTIAIR - ANTINAVY)",

    STEALTH_BASE = "(STEALTHFIELD * STRUCTURE)",
    STEALTH_AIR  = "(STEALTH * AIR)",
    STEALTH_LAND = "((STEALTH * LAND) + (STEALTHFIELD * LAND) + url0301_Stealth)",
    STEALTH_NAVY = "(STEALTHFIELD * NAVAL)",
}
--- note that enhancements are defined in tables and not in strings like category expressions are.
--- Use the same key in above and below table to combine units and enhancements into a single restriction preset
Enhancements = {
    TELE =    { "Teleporter",
                "TeleporterRemove"},
    BILLY =   { "TacticalNukeMissile",
                "TacticalNukeMissileRemove"},
    RAS =     { "ResourceAllocation",
                "ResourceAllocationRemove",
                "ResourceAllocationAdvanced",
                "ResourceAllocationAdvancedRemove"},
    TMLPACK = { "Missile",
                "MissileRemove",
                "TacticalMissile",
                "TacticalMissileRemove",
                "RightRocket",
                "RightRocketRemove",
                "LeftRocket",
                "LeftRocketRemove"},
    ENGIDRONES =  { "LeftPod",          -- ACU Engineering Drone C-D1
                    "LeftPodRemove",    -- ACU Engineering Drone C-D1
                    "RightPod",         -- ACU Engineering Drone C-D2
                    "RightPodRemove",   -- ACU Engineering Drone C-D2
                    "Pod",              -- SCU Engineering Drone C-D2
                    "PodRemove"},       -- SCU Engineering Drone C-D2
    STEALTH_LAND = { "StealthGenerator",
                     "StealthGeneratorRemove",
                     "CloakingGenerator",
                     "CloakingGeneratorRemove"},
    CLOAK =     { "CloakingGenerator",
                    "CloakingGeneratorRemove"},
    SHIELD_LAND = { "ShieldGeneratorField",
                    "ShieldGeneratorField" },
    ANTIAIR_LAND = { "NaniteMissileSystem",
                     "NaniteMissileSystemRemove"},
    TORPEDO_LAND = { "NaniteTorpedoTube",
                     "NaniteTorpedoTubeRemove"},
}
--- defines sorting of preset restrictions and used in UnitsManager.lua
local presetsOrder = {
    "", -- preset separator
    "T1",
    "T2",
    "T3",
    "T4",
    "", -- preset separator
    "HOVER",
    "AMPHIBIOUS",
    "SUBS",
    "BOTS",
    "AIR",
    "BASE",
    "NAVAL",
    "LAND",
    "", -- preset separator
    "T1_AIR_SPAM",
    "T1_BASE_SPAM",
    "T1_NAVY_SPAM",
    "T1_LAND_SPAM",
    "T2_AIR_SPAM",
    "T2_BASE_SPAM",
    "T2_NAVY_SPAM",
    "T2_LAND_SPAM",
    "T3_AIR_SPAM",
    "T3_BASE_SPAM",
    "T3_NAVY_SPAM",
    "T3_LAND_SPAM",
    "", -- preset separator
    "SHIELD_AIR",
    "SHIELD_BASE",
    "SHIELD_NAVY",
    "SHIELD_LAND",
    "STEALTH_AIR",
    "STEALTH_BASE",
    "STEALTH_NAVY",
    "STEALTH_LAND",
    "INTEL_AIR",
    "INTEL_BASE",
    "INTEL_SONAR",
    "INTEL_OPTICS",
    "", -- preset separator
    "SNIPES_AIR",
    "SNIPES_BASE",
    "SNIPES_BOTS",
    "SNIPES_LAND",
    --"", -- preset separator
    "ANTIAIR_FIGHTERS",
    "ANTIAIR_BASE",
    "ANTIAIR_NAVY",
    "ANTIAIR_LAND",
    --"", -- preset separator
    "TORPEDO_AIR",
    "TORPEDO_BASE",
    "TORPEDO_BOATS",
    "TORPEDO_LAND",
    --"", -- preset separator
    "DIRECTFIRE_AIR",
    "DIRECTFIRE_BASE",
    "DIRECTFIRE_NAVY",
    "DIRECTFIRE_LAND",
    "DIRECTFIRE_GUNSHIPS",
    "DIRECTFIRE_BOTS",
    "", -- preset separator
    "", -- preset separator
    "TMLDEF",
    "TMLBASE",
    "TMLNAVAL",
    "TMLMOBILE",
    "NUKET3DEF",
    "NUKET3ML",
    "NUKENAVAL",
    "NUKET4ML",
    "T1ARTY",
    "T2ARTY",
    "T3ARTY",
    "T4ARTY",
    "DIRECTFIRE_BASE_T1",
    "DIRECTFIRE_BASE_T2",
    "DIRECTFIRE_BASE_T3",
    "SATELLITE",
    "", -- preset separator
    "T3_AIR_BOMBERS",
    "T3_AIR_GUNSHIPS",
    "T3_MOBILE_AA",
    "T3_MOBILE_ARTY",
    "", -- preset separator
    "FABS",
    "MASSINCOME",
    "ENGYINCOME",
    "PARAGON",
    "", -- preset separator
    "ENGIDRONES",
    "ENGISTATION",
    "ENGINEERS",
    "SUPCOMS",
    "AIR_TANSPORTS",
    "SUPPFAC",
    "", -- preset separator
    "", -- preset separator
    "TELE",
    "RAS",
    "TMLPACK",
    "BILLY",
    "CLOAK",
    "", -- preset separator
    "SERAPHIM",
    "UEF",
    "CYBRAN",
    "AEON",
}
--- Creates restriction preset by looking up preset key in categories Expressions and Enhancements tables
local function CreatePreset(key, tooltip, name, icon)
    if presetsRestrictions[key]  then
        WARN('UnitsRestrictions detected duplicate preset with "' ..key.. '" key')
    elseif not Expressions[key] and not Enhancements[key] then
        WARN('UnitsRestrictions detected undefined restriction with "' ..key.. '" key')
    else
        local preset = {}
        preset.key = key
        preset.name = name
        preset.Icon = icon
        preset.tooltip = tooltip
        preset.categories = Expressions[key]
        preset.enhancements = Enhancements[key]
        -- add new preset
        presetsRestrictions[key] = preset
    end
end
--- Creates restriction preset from a list of restriction presets
--- by merging all category expressions and enhancements in passed preset keys
--- Note unit and enhancement restrictions will be combined when presetsKeys has the same key
--- in the Expressions and Enhancements tables defined at top of this file
local function CreatePresetGroup(presetsKeys, key, tooltip, name, icon)

    local presetMerging = false
    -- check if a preset already exists
    local preset = presetsRestrictions[key]
    if not preset then
        preset = {}
        preset.categories = nil
        preset.enhancements = nil
        presetMerging = true -- perform restrictions merge on a new preset
    end
    preset.key = key
    preset.groups = {}
    if not tooltip or not name or not icon then
        preset.visible = false
        preset.groups = { }
    else
        preset.visible = true
        preset.groups = { key }
        preset.name = name
        preset.Icon = icon
        preset.tooltip = tooltip
    end

    for _, presetKey in presetsKeys do
        local  restriction = presetsRestrictions[presetKey]
        if not restriction then
            WARN(' UnitManager Attempting to combine not existing preset: ' .. presetKey)
            --continue
        else
            if (presetMerging) then
                local expression = restriction.categories
                if expression then
                    preset.categories = table.concat({expression, preset.categories}, " + ")
                end
                local enhancements = restriction.enhancements
                if enhancements then
                    if not preset.enhancements then preset.enhancements = {} end
                    for _, enhancement in enhancements do
                        table.insert(preset.enhancements, enhancement)
                    end
                end
            end
            table.insert(preset.groups, presetKey)
        end
    end
    -- add group to restricted units
    presetsRestrictions[key] = preset
end
--- Initializes presets and groups some presets
--- Note that you need to copy LOCalization strings to \LOC\US\strings_db.lua file
--- if you make any changes to strings "<LOC restricted*>..." strings in this function
local function CreatePresets()
    -- FACTION restrictions
    CreatePreset("UEF",
        "<LOC restricted_units_info_UEF>Prevents all UEF units and structures, except ACU",
        "<LOC restricted_units_data_UEF>No UEF Units",
        "/textures/ui/common/faction_icon-lg/uef_ico.dds")
    CreatePreset("CYBRAN",
        "<LOC restricted_units_info_CYBRAN>Prevents all Cybran units and structures, except ACU",
        "<LOC restricted_units_data_CYBRAN>No Cybran Units",
        "/textures/ui/common/faction_icon-lg/cybran_ico.dds")
    CreatePreset("AEON",
        "<LOC restricted_units_info_AEON>Prevents all Aeon units and structures, except ACU",
        "<LOC restricted_units_data_AEON>No Aeon Units",
        "/textures/ui/common/faction_icon-lg/aeon_ico.dds")
    CreatePreset("SERAPHIM",
        "<LOC restricted_units_info_SERAPHIM>Prevents all Seraphim units and structures, except ACU",
        "<LOC restricted_units_data_SERAPHIM>No Seraphim Units",
        "/textures/ui/common/faction_icon-lg/seraphim_ico.dds")
    CreatePreset("NOMADS",
        "<LOC restricted_units_info_NOMADS>Prevents all Nomads units and structures, except ACU",
        "<LOC restricted_units_data_NOMADS>No Nomads Units",
        "/textures/ui/common/faction_icon-lg/nomads_ico.dds")
    -- TECH restrictions
    CreatePreset("T1",
        "<LOC restricted_units_info_T1>Prevents all T1 units and structures, except factories, engineers, and eco buildings",
        "<LOC restricted_units_data_T1>No T1 Units",
        "/textures/ui/common/icons/presets/tech-1.dds")
    CreatePreset("T2",
        "<LOC restricted_units_info_T2>Prevents all T2 units and structures, except factories, engineers, and eco buildings",
        "<LOC restricted_units_data_T2>No T2 Units",
        "/textures/ui/common/icons/presets/tech-2.dds")
    CreatePreset("T3",
        "<LOC restricted_units_info_T3>Prevents all T3 units and structures, except factories, engineers, and eco buildings",
        "<LOC restricted_units_data_T3>No T3 Units",
        "/textures/ui/common/icons/presets/tech-3.dds")
    CreatePreset("T4",
        "<LOC restricted_units_info_T4>Prevents all T4 (experimental) units, except factories, engineers, and eco buildings",
        "<LOC restricted_units_data_T4>No Experimental Units",
        "/textures/ui/common/icons/presets/tech-4.dds")
    -- TYPES restrictions
    CreatePreset("LAND",
        "<LOC restricted_units_info_LAND>Prevents all land units with weapons, except engineers, commanders, and structures",
        "<LOC restricted_units_data_LAND>No Land Units",
        "/textures/ui/common/icons/presets/type-land.dds")
    CreatePreset("AIR",
        "<LOC restricted_units_info_AIR>Prevents all air units (except drones), and air staging structures",
        "<LOC restricted_units_data_AIR>No Air Units",
        "/textures/ui/common/icons/presets/type-air.dds")
    CreatePreset("NAVAL",
        "<LOC restricted_units_info_NAVAL>Prevents all naval units",
        "<LOC restricted_units_data_NAVAL>No Naval Units",
        "/textures/ui/common/icons/presets/type-navy.dds")
    CreatePreset("BASE",
        "<LOC restricted_units_info_BASE>Prevents base structures except factories and economy buildings",
        "<LOC restricted_units_data_BASE>No Base Structures",
        "/textures/ui/common/icons/presets/type-base.dds")
    CreatePreset("HOVER",
        "<LOC restricted_units_info_HOVER>Prevents all hover units, except engineers",
        "<LOC restricted_units_data_HOVER>No Hover Units",
        "/textures/ui/common/icons/presets/type-hover.dds")
    CreatePreset("AMPHIBIOUS",
        "<LOC restricted_units_info_AMPHIBIOUS>Prevents all amphibious units",
        "<LOC restricted_units_data_AMPHIBIOUS>No Amphibious Units",
        "/textures/ui/common/icons/presets/type-amphibius.dds")
    CreatePreset("SUBS",
        "<LOC restricted_units_info_SUBS>Prevents all submersible units",
        "<LOC restricted_units_data_SUBS>No Submersible Units",
        "/textures/ui/common/icons/presets/type-subs.dds")
    CreatePreset("BOTS",
        "<LOC restricted_units_info_BOTS>Prevents all Bot units",
        "<LOC restricted_units_data_BOTS>No Bot Units",
        "/textures/ui/common/icons/presets/type-bots.dds")
    -- NUKES restrictions
    CreatePreset("NUKET4ML",
        "<LOC restricted_units_info_NUKET4ML>Prevents T4 structures with strategic missile launchers (SML)",
        "<LOC restricted_units_data_NUKET4ML>No T4 Nuke Launchers",
        "/textures/ui/common/icons/presets/nukes-t4-ml.dds")
    CreatePreset("NUKET3ML",
        "<LOC restricted_units_info_NUKET3ML>Prevents T3 structures with strategic missile launchers (SML)",
        "<LOC restricted_units_data_NUKET3ML>No T3 Nuke Launchers",
        "/textures/ui/common/icons/presets/nukes-t3-ml.dds")
    CreatePreset("NUKET3DEF",
        "<LOC restricted_units_info_NUKET3DEF>Prevents T3 structures with strategic missile defense (SMD) ",
        "<LOC restricted_units_data_NUKET3DEF>No T3 Nuke Defense",
        "/textures/ui/common/icons/presets/nukes-t3-def.dds")
    CreatePreset("NUKENAVAL",
        "<LOC restricted_units_info_NUKENAVAL>Prevents T3 naval ships with strategic missile launchers (nuke subs)",
        "<LOC restricted_units_data_NUKENAVAL>No Nuke Naval Launchers",
        "/textures/ui/common/icons/presets/nukes-ships.dds")
    CreatePreset("T2ARTY",
        "<LOC restricted_units_info_T2ARTY>Prevents T2 artillery structures",
        "<LOC restricted_units_data_T2ARTY>No T2 Artillery",
        "/textures/ui/common/icons/presets/arty-base-t2.dds")
    CreatePreset("T1ARTY",
        "<LOC restricted_units_info_T1ARTY>Prevents T1 artillery structures",
        "<LOC restricted_units_data_T1ARTY>No T1 Artillery",
        "/textures/ui/common/icons/presets/arty-base-t1.dds")
    -- GAME ENDERS restrictions
    CreatePreset("T3ARTY",
        "<LOC restricted_units_info_T3ARTY>Prevents T3 artillery structures",
        "<LOC restricted_units_data_T3ARTY>No Heavy Artillery",
        "/textures/ui/common/icons/presets/arty-base-t3.dds")
    CreatePreset("T4ARTY",
        "<LOC restricted_units_info_T4ARTY>Prevents T4 artillery structures, e.g. Salvation, Mavor, and Scathis",
        "<LOC restricted_units_data_T4ARTY>No Super Artillery",
        "/textures/ui/common/icons/presets/arty-base-t4.dds")
    CreatePreset("SATELLITE",
        "<LOC restricted_units_info_SATELLITE>Prevents satellites structures, e.g. UEF Novax Center",
        "<LOC restricted_units_data_SATELLITE>No Satellite",
        "/textures/ui/common/icons/presets/direct-fire-base-t4.dds")
    -- ADVANCED restrictions
    CreatePreset("AIR_TANSPORTS",
        "<LOC restricted_units_info_AIR_TANSPORTS>Prevents all air units capable of transporting other units",
        "<LOC restricted_units_data_AIR_TANSPORTS>No Transports",
        "/textures/ui/common/icons/presets/transport-air.dds")
    CreatePreset("T3_AIR_GUNSHIPS",
        "<LOC restricted_units_info_T3_AIR_GUNSHIPS>Prevents T3 gunships",
        "<LOC restricted_units_data_T3_AIR_GUNSHIPS>No T3 Gunships",
        "/textures/ui/common/icons/presets/air-t3-gunships.dds")
    CreatePreset("T3_AIR_BOMBERS",
        "<LOC restricted_units_info_T3_AIR_BOMBERS>Prevents T3 bombers",
        "<LOC restricted_units_data_T3_AIR_BOMBERS>No T3 Bombers",
        "/textures/ui/common/icons/presets/air-t3-bombers.dds")
    CreatePreset("T3_MOBILE_AA",
        "<LOC restricted_units_info_T3_MOBILE_AA>Prevents T3 mobile anti-air units",
        "<LOC restricted_units_data_T3_MOBILE_AA>No T3 Mobile Anti-Air",
        "/textures/ui/common/icons/presets/land-t3-anti-air.dds")
    CreatePreset("T3_MOBILE_ARTY",
        "<LOC restricted_units_info_T3_MOBILE_ARTY>Prevents T3 mobile artillery units",
        "<LOC restricted_units_data_T3_MOBILE_ARTY>No T3 Mobile Artillery",
        "/textures/ui/common/icons/presets/land-t3-arty.dds")

    -- SNIPES/MINE restrictions
     CreatePreset("SNIPES_AIR",
        "<LOC restricted_units_info_SNIPES_AIR>Prevents air units capable of sniping ACU from a long range or in a few flybys",
        "<LOC restricted_units_data_SNIPES_AIR>No Air Snipes",
        "/textures/ui/common/icons/presets/snipes-air.dds")
    CreatePreset("SNIPES_LAND",
        "<LOC restricted_units_info_SNIPES_LAND>Prevents land units capable of sniping ACU from by detonating bombs in close range",
        "<LOC restricted_units_data_SNIPES_LAND>No Mobile Bombs",
        "/textures/ui/common/icons/presets/snipes-land.dds")
    CreatePreset("SNIPES_BOTS",
        "<LOC restricted_units_info_SNIPES_BOTS>Prevents land units capable of sniping ACU from a long range",
        "<LOC restricted_units_data_SNIPES_BOTS>No Sniper Bots",
        "/textures/ui/common/icons/presets/snipes-bots.dds")
    CreatePreset("SNIPES_BASE",
        "<LOC restricted_units_info_SNIPES_BASE>Prevents structures capable of detonating mines in close proximity of enemy units",
        "<LOC restricted_units_data_SNIPES_BASE>No Land Mines",
        "/textures/ui/common/icons/presets/snipes-base.dds")

    -- LAND TECH restrictions
    CreatePreset("T1_LAND_SPAM",
        "<LOC restricted_units_info_T1_LAND_SPAM>Prevents construction of T1 land units, except engineers",
        "<LOC restricted_units_data_T1_LAND_SPAM>No T1 Land Units",
        "/textures/ui/common/icons/presets/type-land-t1.dds")
    CreatePreset("T2_LAND_SPAM",
        "<LOC restricted_units_info_T2_LAND_SPAM>Prevents construction of T2 land units, except engineers",
        "<LOC restricted_units_data_T2_LAND_SPAM>No T2 Land Units",
        "/textures/ui/common/icons/presets/type-land-t2.dds")
    CreatePreset("T3_LAND_SPAM",
        "<LOC restricted_units_info_T3_LAND_SPAM>Prevents construction of T3 land units, except engineers and support commanders",
        "<LOC restricted_units_data_T3_LAND_SPAM>No T3 Land Units",
        "/textures/ui/common/icons/presets/type-land-t3.dds")
    -- AIR TECH restrictions
    CreatePreset("T1_AIR_SPAM",
        "<LOC restricted_units_info_T1_AIR_SPAM>Prevents construction of T1 air units, except air scouts and transports",
        "<LOC restricted_units_data_T1_AIR_SPAM>No T1 Air Units",
        "/textures/ui/common/icons/presets/type-air-t1.dds")
    CreatePreset("T2_AIR_SPAM",
        "<LOC restricted_units_info_T2_AIR_SPAM>Prevents construction of T2 air units, except air scouts and transports",
        "<LOC restricted_units_data_T2_AIR_SPAM>No T2 Air Units",
        "/textures/ui/common/icons/presets/type-air-t2.dds")
    CreatePreset("T3_AIR_SPAM",
        "<LOC restricted_units_info_T3_AIR_SPAM>Prevents construction of T3 air units, except air scouts and transports",
        "<LOC restricted_units_data_T3_AIR_SPAM>No T3 Air Units",
        "/textures/ui/common/icons/presets/type-air-t3.dds")
    -- NAVY TECH restrictions
    CreatePreset("T1_NAVY_SPAM",
        "<LOC restricted_units_info_T1_NAVY_SPAM>Prevents construction of T1 naval units",
        "<LOC restricted_units_data_T1_NAVY_SPAM>No T1 Navy Units",
        "/textures/ui/common/icons/presets/type-navy-t1.dds")
    CreatePreset("T2_NAVY_SPAM",
        "<LOC restricted_units_info_T2_NAVY_SPAM>Prevents construction of T2 naval units",
        "<LOC restricted_units_data_T2_NAVY_SPAM>No T2 Navy Units",
        "/textures/ui/common/icons/presets/type-navy-t2.dds")
    CreatePreset("T3_NAVY_SPAM",
        "<LOC restricted_units_info_T3_NAVY_SPAM>Prevents construction of T3 naval units",
        "<LOC restricted_units_data_T3_NAVY_SPAM>No T3 Navy Units",
        "/textures/ui/common/icons/presets/type-navy-t3.dds")
    -- BASE TECH restrictions
    CreatePreset("T1_BASE_SPAM",
        "<LOC restricted_units_info_T1_BASE_SPAM>Prevents building T1 structures except factories and economy buildings",
        "<LOC restricted_units_data_T1_BASE_SPAM>No T1 Structures",
        "/textures/ui/common/icons/presets/type-base-t1.dds")
    CreatePreset("T2_BASE_SPAM",
        "<LOC restricted_units_info_T2_BASE_SPAM>Prevents building T2 structures except factories and economy buildings",
        "<LOC restricted_units_data_T2_BASE_SPAM>No T2 Structures",
        "/textures/ui/common/icons/presets/type-base-t2.dds")
    CreatePreset("T3_BASE_SPAM",
        "<LOC restricted_units_info_T3_BASE_SPAM>Prevents building T3 structures except factories and economy buildings",
        "<LOC restricted_units_data_T3_BASE_SPAM>No T3 Structures",
        "/textures/ui/common/icons/presets/type-base-t3.dds")

    -- SUPPORT restrictions
     CreatePreset("SUPCOMS",
        "<LOC restricted_units_info_SUPCOMS>Prevents all support commander units (SCUs) and quantum gateway structures",
        "<LOC restricted_units_data_SUPCOMS>No Support Commanders",
        "/textures/ui/common/icons/presets/eng-scus.dds")
     CreatePreset("SUPPFAC",
        "<LOC restricted_units_info_SUPPFAC>Prevents all factories from upgrading to support factories",
        "<LOC restricted_units_data_SUPPFAC>No Support Factories",
        "/textures/ui/common/icons/presets/eng-factory.dds")
     CreatePreset("ENGISTATION",
        "<LOC restricted_units_info_ENGISTATION>Prevents all engineering stations including UEF Kennel and Cybran Hive structures",
        "<LOC restricted_units_data_ENGISTATION>No Engineering Stations",
        "/textures/ui/common/icons/presets/eng-stations.dds")
     CreatePreset("ENGIDRONES",
        "<LOC restricted_units_info_ENGIDRONES>Prevents all upgrades that enable engineering drones and UEF Kennel structures",
        "<LOC restricted_units_data_ENGIDRONES>No Engineering Drones",
        "/textures/ui/common/icons/presets/eng-drones.dds")
     CreatePreset("ENGINEERS",
        "<LOC restricted_units_info_ENGINEERS>Prevents all civil engineering units",
        "<LOC restricted_units_data_ENGINEERS>No Civil Engineers",
        "/textures/ui/common/icons/presets/eng-civilans.dds")
    -- COMMANDER UPGRADES restrictions
    CreatePreset("TELE",
        "<LOC restricted_units_info_TELE>Prevents commander upgrades that provide teleporting ability",
        "<LOC restricted_units_data_TELE>No Teleporting",
        "/textures/ui/common/icons/presets/enh-tele-icon.dds")
    CreatePreset("BILLY",
        "<LOC restricted_units_info_BILLY>Prevents commander upgrades that provide tactical nuke launchers, UEF Billy Nuke",
        "<LOC restricted_units_data_BILLY>No Billy",
        "/textures/ui/common/icons/presets/enh-billy-icon.dds")
    CreatePreset("RAS",
        "<LOC restricted_units_info_RAS>Prevents commander upgrades that generate resources via resource allocation system (RAS)",
        "<LOC restricted_units_data_RAS>No Resource Allocation System",
        "/textures/ui/common/icons/presets/enh-ras-icon.dds")
    CreatePreset("TMLPACK",
        "<LOC restricted_units_info_TMLPACK>Prevents commander upgrades that enable tactical missile launchers (TML)",
        "<LOC restricted_units_data_TMLPACK>No Tactical Missile Pack",
        "/textures/ui/common/icons/presets/enh-tml-icon.dds")
        CreatePreset("CLOAK",
        "<LOC restricted_units_info_CLOAK>Prevents commander upgrades that enable Personal Cloak",
        "<LOC restricted_units_data_CLOAK>No Cloak",
        "/textures/ui/common/icons/presets/enh-cloak-icon.dds")
    -- INTEL restrictions
    CreatePreset("INTEL_BASE",
        "<LOC restricted_units_info_INTELBASIC>Prevents structures that provide basic intelligence such as radar, sonar, and omni",
        "<LOC restricted_units_data_INTELBASIC>No Basic-Intel Structures",
        "/textures/ui/common/icons/presets/intel-base.dds")
    CreatePreset("INTEL_OPTICS",
        "<LOC restricted_units_info_INTELOPTICS>Prevents structures that provide super intelligence such as large vision over battlefield, e.g. Aeon Eye of Rhianne and Cybran Soothsayer",
        "<LOC restricted_units_data_INTELOPTICS>No Super-Intel Structures",
        "/textures/ui/common/icons/presets/intel-optics.dds")
    CreatePreset("INTEL_AIR",
        "<LOC restricted_units_info_INTELAIR>Prevents air units that provide intelligence",
        "<LOC restricted_units_data_INTELAIR>No Aerial Intel",
        "/textures/ui/common/icons/presets/intel-air.dds")
    CreatePreset("INTEL_SONAR",
        "<LOC restricted_units_info_INTEL_SONAR>Prevents naval units and structures that provide intelligence",
        "<LOC restricted_units_data_INTEL_SONAR>No Naval Intel",
        "/textures/ui/common/icons/presets/intel-navy.dds")
    CreatePreset("INTEL_LAND",
        "<LOC restricted_units_info_INTEL_LAND>Prevents land units that provide intelligence",
        "<LOC restricted_units_data_INTEL_LAND>No Mobile Intel",
        "/textures/ui/common/icons/presets/intel-land.dds")

    -- TACTICAL MISSILES restrictions
    CreatePreset("TMLDEF",
        "<LOC restricted_units_info_TMLDEF>Prevents all structures that provide tactical missile defense (TMD) ability",
        "<LOC restricted_units_data_TMLDEF>No Tactical Missile Defense",
        "/textures/ui/common/icons/presets/tml-base-def.dds")
    CreatePreset("TMLBASE",
        "<LOC restricted_units_info_TMLBASE>Prevents all structures that provide tactical missile launch (TML) ability ",
        "<LOC restricted_units_data_TMLBASE>No Tactical Missile Launchers",
        "/textures/ui/common/icons/presets/tml-base.dds")
    CreatePreset("TMLMOBILE",
        "<LOC restricted_units_info_TMLMOBILE>Prevents all mobile missile launcher (MML)",
        "<LOC restricted_units_data_TMLMOBILE>No Mobile Missile Launchers",
        "/textures/ui/common/icons/presets/tml-land.dds")
    CreatePreset("TMLNAVAL",
        "<LOC restricted_units_info_TMLNAVAL>Prevents all naval ships that provide tactical missile launch (TML) ability ",
        "<LOC restricted_units_data_TMLNAVAL>No Tactical Missile Ships",
        "/textures/ui/common/icons/presets/tml-navy.dds")
    -- eco restrictions
    CreatePreset("MASSINCOME",
        "<LOC restricted_units_info_MASSINCOME>Prevents all structures that extract mass ",
        "<LOC restricted_units_data_MASSINCOME>No Mass Extractors",
        "/textures/ui/common/icons/presets/eco-base-mass.dds")
    CreatePreset("ENGYINCOME",
        "<LOC restricted_units_info_ENGYINCOME>Prevents all structures that generate energy ",
        "<LOC restricted_units_data_ENGYINCOME>No Energy Generators",
        "/textures/ui/common/icons/presets/eco-base-energy.dds")
    CreatePreset("FABS",
        "<LOC restricted_units_info_FABS>Prevents all structures that fabricate mass from energy ",
        "<LOC restricted_units_data_FABS>No Mass Fabrication",
        "/textures/ui/common/icons/presets/eco-base-fabs.dds")
    CreatePreset("PARAGON",
        "<LOC restricted_units_info_PARAGON>Prevents T4 structures that generate infinite mass and energy, e.g. Aeon Paragon",
        "<LOC restricted_units_data_PARAGON>No Paragon",
        "/textures/ui/common/icons/presets/eco-base-paragon.dds")

    -- STEALTH restrictions
    CreatePreset("STEALTH_AIR",
        "<LOC restricted_units_info_STEALTH_AIR>Prevents all air units that have personal stealth",
        "<LOC restricted_units_data_STEALTH_AIR>No Stealth Aircrafts",
        "/textures/ui/common/icons/presets/stealth-air.dds")
    CreatePreset("STEALTH_BASE",
        "<LOC restricted_units_info_STEALTH_BASE>Prevents all structures that provide stealth field for nearby units or structures",
        "<LOC restricted_units_data_STEALTH_BASE>No Stealth Field Structures",
        "/textures/ui/common/icons/presets/stealth-base.dds")
    CreatePreset("STEALTH_LAND",
        "<LOC restricted_units_info_STEALTH_LAND>Prevents all mobile land units that have personal stealth or provide stealth field for nearby units or structures",
        "<LOC restricted_units_data_STEALTH_LAND>No Mobile Stealth",
        "/textures/ui/common/icons/presets/stealth-land.dds")
    CreatePreset("STEALTH_NAVY",
        "<LOC restricted_units_info_STEALTH_NAVY>Prevents all naval units that provide stealth field for nearby units or structures",
        "<LOC restricted_units_data_STEALTH_NAVY>No Stealth Field Boats",
        "/textures/ui/common/icons/presets/stealth-navy.dds")

    -- ANTI-AIR restrictions
    CreatePreset("ANTIAIR_FIGHTERS",
        "<LOC restricted_units_info_ANTIAIR_FIGHTERS>Prevents air units with anti-air weapons: interceptors and air fighters",
        "<LOC restricted_units_data_ANTIAIR_FIGHTERS>No Anti-Air Fighters",
        "/textures/ui/common/icons/presets/antiair-fighters.dds")
    CreatePreset("ANTIAIR_NAVY",
        "<LOC restricted_units_info_ANTIAIR_NAVY>Prevents naval units with anti-air weapons:  cruisers and aircraft carriers",
        "<LOC restricted_units_data_ANTIAIR_NAVY>No Anti-Air Navy",
        "/textures/ui/common/icons/presets/antiair-navy.dds")
    CreatePreset("ANTIAIR_LAND",
        "<LOC restricted_units_info_ANTIAIR_LAND>Prevents land units with anti-air weapons",
        "<LOC restricted_units_data_ANTIAIR_LAND>No Anti-Air Land Units",
        "/textures/ui/common/icons/presets/antiair-land.dds")
    CreatePreset("ANTIAIR_BASE",
        "<LOC restricted_units_info_ANTIAIR_BASE>Prevents structures with anti-air weapons",
        "<LOC restricted_units_data_ANTIAIR_BASE>No Anti-Air Structures",
        "/textures/ui/common/icons/presets/antiair-base.dds")
    -- ANTI-NAVY restrictions
    CreatePreset("TORPEDO_AIR",
        "<LOC restricted_units_info_TORPEDO_AIR>Prevents air units with torpedo weapons",
        "<LOC restricted_units_data_TORPEDO_AIR>No Torpedo Bombers",
        "/textures/ui/common/icons/presets/torpedo-air.dds")
    CreatePreset("TORPEDO_BOATS",
        "<LOC restricted_units_info_TORPEDO_BOATS>Prevents naval units with torpedo weapons",
        "<LOC restricted_units_data_TORPEDO_BOATS>No Torpedo Boats",
        "/textures/ui/common/icons/presets/torpedo-navy.dds")
    CreatePreset("TORPEDO_LAND",
        "<LOC restricted_units_info_TORPEDO_LAND>Prevents land units with torpedo weapons",
        "<LOC restricted_units_data_TORPEDO_LAND>No Torpedo Land Units",
        "/textures/ui/common/icons/presets/torpedo-land.dds")
    CreatePreset("TORPEDO_BASE",
        "<LOC restricted_units_info_TORPEDO_BASE>Prevents structures with torpedo weapons",
        "<LOC restricted_units_data_TORPEDO_BASE>No Torpedo Structures",
        "/textures/ui/common/icons/presets/torpedo-base.dds")
    -- DIRECT FIRE restrictions
    CreatePreset("DIRECTFIRE_AIR",
        "<LOC restricted_units_info_DIRECTFIRE_AIR>Prevents air bombers with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_AIR>No Direct-Fire Bombers",
        "/textures/ui/common/icons/presets/direct-fire-air.dds")
    CreatePreset("DIRECTFIRE_GUNSHIPS",
        "<LOC restricted_units_info_DIRECTFIRE_GUNSHIPS>Prevents air gunships with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_GUNSHIPS>No Direct-Fire Gunships",
        "/textures/ui/common/icons/presets/direct-fire-gunships.dds")
    CreatePreset("DIRECTFIRE_NAVY",
        "<LOC restricted_units_info_DIRECTFIRE_NAVY>Prevents naval units with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_NAVY>No Direct-Fire Navy",
        "/textures/ui/common/icons/presets/direct-fire-navy.dds")
    CreatePreset("DIRECTFIRE_LAND",
        "<LOC restricted_units_info_DIRECTFIRE_LAND>Prevents land units with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_LAND>No Direct-Fire Land",
        "/textures/ui/common/icons/presets/direct-fire-land.dds")
    CreatePreset("DIRECTFIRE_BOTS",
        "<LOC restricted_units_info_DIRECTFIRE_BOTS>Prevents bots with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_BOTS>No Direct-Fire Bots",
        "/textures/ui/common/icons/presets/direct-fire-bots.dds")
    CreatePreset("DIRECTFIRE_BASE",
        "<LOC restricted_units_info_DIRECTFIRE_BASE>Prevents all structures with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_BASE>No Point Defenses",
        "/textures/ui/common/icons/presets/direct-fire-base.dds")
    CreatePreset("DIRECTFIRE_BASE_T1",
        "<LOC restricted_units_info_DIRECTFIRE_BASE_T1>Prevents T1 structures with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_BASE_T1>No T1 Point Defenses",
        "/textures/ui/common/icons/presets/direct-fire-base-t1.dds")
    CreatePreset("DIRECTFIRE_BASE_T2",
        "<LOC restricted_units_info_DIRECTFIRE_BASE_T2>Prevents T2 structures with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_BASE_T2>No T2 Point Defenses",
        "/textures/ui/common/icons/presets/direct-fire-base-t2.dds")
    CreatePreset("DIRECTFIRE_BASE_T3",
        "<LOC restricted_units_info_DIRECTFIRE_BASE_T3>Prevents T3 structures with direct-fire weapons",
        "<LOC restricted_units_data_DIRECTFIRE_BASE_T3>No T3 Point Defenses",
        "/textures/ui/common/icons/presets/direct-fire-base-t3.dds")
    -- SHIELD GENERATORS restrictions
    CreatePreset("SHIELD_AIR",
        "<LOC restricted_units_info_SHIELD_AIR>Prevents air units with shield generators",
        "<LOC restricted_units_data_SHIELD_AIR>No Air Shields",
        "/textures/ui/common/icons/presets/shields-air.dds")
    CreatePreset("SHIELD_NAVY",
        "<LOC restricted_units_info_SHIELD_BOATS>Prevents naval units with shield generators",
        "<LOC restricted_units_data_SHIELD_BOATS>No Naval Shields",
        "/textures/ui/common/icons/presets/shields-navy.dds")
    CreatePreset("SHIELD_LAND",
        "<LOC restricted_units_info_SHIELD_LAND>Prevents land units with shield generators, except personal shields",
        "<LOC restricted_units_data_SHIELD_LAND>No Land Shields",
        "/textures/ui/common/icons/presets/shields-land.dds")
    CreatePreset("SHIELD_BASE",
        "<LOC restricted_units_info_SHIELD_BASE>Prevents structures with shield generators",
        "<LOC restricted_units_data_SHIELD_BASE>No Shield Structures",
        "/textures/ui/common/icons/presets/shields-base.dds")
end
--- Generates restriction presets or returns cached presets
function GetPresetsData()
    if table.empty(presetsRestrictions) then
        CreatePresets()
    end
    return presetsRestrictions
end
--- Returns order of presets
function GetPresetsOrder()
    -- ensure restriction presets are generated before accessing order
    GetPresetsData()
    return presetsOrder
end
