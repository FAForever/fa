-- ****************************************************************************
-- * File		: lua/modules/ui/lobby/UnitsRestrictions.lua 
-- * Author(s)	: Gas Powered Games, FAF Community, HUSSAR
-- * Summary  	: Contains mappings of restriction presets to restriction categories and/or enhancements
-- * 
-- * Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- * 
-- ****************************************************************************

local presetsRestrictions = {}  
-- NOTE this table has the following internal structure and it is generated/cached in GetPresetsData()
--   presetKey = {
--      key 		 = "presetKey",
--      name 		 = "localized name that will display in title of tooltip",
--      tooltip 	 = "tooltipID that will display in context of tooltip",
--      Icon 		 = "/textures/path/icon_name.dds",
--      categories 	 = "CATEGORY1 * CATEGORY2 + unitID",
--      enhancements = { "EnhancementName1", "EnhancementName2"},
--   }  
-- --------------------------------------------------------------------------------------------
-- TODO fix categories for units:
-- add AIR, TECH, UEF to  	/units/uea0001_unit.bp Engineering Drone
 
-- TODO for next version of Units Manager:
-- Ideally, each Weapon in a blueprint should have a new Categories table that identifies type of weapon (e.g. tml)
-- This way, Units Manager could restrict units by type of weapon in addition to checking 
-- Categories of the blueprint. 
-- -------------------------------------------------------------------------------------------

-- defining expressions in single place for celerity and re-usability purpose in CreatePresets()
Expressions = {
	     
-- NOTE use this process for defining new expressions that will restrict units in game and mods (units packs):
-- 1. Try using blueprint's categories only:                  "(TECH3 * NAVAL)"
-- 2. Try using blueprint's categories and unit IDs:          "(TECH3 * NAVAL) - xss0202"  
-- 3. Try using list of multiple unit IDs:                    "dalk003 + delk002"
-- 4. Try using blueprint's categories and enhancement names:  "(SUBCOMMANDER * ResourceAllocation) - SCUs with RAS preset
-- You can get the UnitID here : http://content.faforever.com/faf/unitsDB/

-- NOTE that categories must be in upper case and blueprint IDs should be in lower case
-- both categories and blueprint IDs can be used together or individually but 
-- they need to be separated by the following operation symbols:
-- '*'  Intersection = CATEGORY1 and CATEGORY2 and ID1 and ID2 
-- '+'  Union 		 = CATEGORY1 or CATEGORY2 or ID1 or ID2 
-- '-'  Subtraction  = CATEGORY1 and not CATEGORY2 
-- '()' Parenthesis  = (CATEGORY1 and CATEGORY2) or CATEGORY3

-- NOTE the following expression were carefully defined and each used category has a purpose! 
-- be careful when editing them or you may brake restriction system in FA game
 
    -- excluding engineers and factories because players will not progress to higher tech levels
    T1          = "(TECH1 - (STRUCTURE * FACTORY) - ENGINEER - MASSEXTRACTION - ENERGYPRODUCTION)",
    T2          = "(TECH2 - (STRUCTURE * FACTORY) - ENGINEER - MASSEXTRACTION - ENERGYPRODUCTION)",
    T3          = "(TECH3 - (STRUCTURE * FACTORY) - ENGINEER - MASSEXTRACTION - ENERGYPRODUCTION)",
    T4          = "(EXPERIMENTAL)",
    -- excluding ACUs because game might crash if someone picks restricted faction
    UEF         = "(UEF - COMMAND)",
    CYBRAN      = "(CYBRAN - COMMAND)",
    AEON        = "(AEON - COMMAND)",
    SERAPHIM    = "(SERAPHIM - COMMAND)",
    NOMADS      = "(NOMADS - COMMAND)",
    -- Salvation is not categorized as EXPERIMENTAL like Scathis and Mavor so a bit complex expression
    T4ARTY		= "(ARTILLERY * SIZE20 * TECH3) + (ARTILLERY * EXPERIMENTAL) - FACTORY",  -- "xab2307 + url0401 + ueb2401"
    T3ARTY      = "(ARTILLERY * SIZE16 * TECH3)",  -- "uab2302 + urb2302 + ueb2302 + xsb2302", Heavy Artillery  
	T2ARTY      = "(ARTILLERY * STRUCTURE * TECH2)",  
	
	SATELLITE   = "(SATELLITE + ORBITALSYSTEM)", --"(xeb2402 + xea0002)",
	
	NUKET4ML    = "(STRUCTURE * NUKE * EXPERIMENTAL)" ,	-- "xsb2401" -- SERA Yolona Oss
	NUKET3ML    = "(STRUCTURE * NUKE * TECH3)", 		-- "uab2305 + urb2305 + ueb2305 + xsb2305"
	NUKET3DEF   = "(STRUCTURE * SILO * ANTIMISSILE)", 	-- "uab4302 + urb4302 + ueb4302 + xsb4302"
	NUKENAVAL   = "(NUKE * NAVAL)", 					-- "uas0304 + urs0304 + ues0304 + xss0302" -- SERA Battleship
	NUKESUBS    = "(NUKE * SUBMERSIBLE)", 				-- "uas0304 + urs0304 + ues0304"
	
    -- unfortunate, some units must be restricted using their IDs unless their categories are updated with a new TML category
	TMLNAVAL    = "(NUKE * SUBMERSIBLE) + xss0303 + xss0202 + xas0306 + ues0202", -- SERA Carrier + AEON Missile Ship + UEF Cruiser
	TMLDEF      = "(STRUCTURE * TECH2 * ANTIMISSILE)",
	TMLBASE     = "(STRUCTURE * TECH2 * TACTICALMISSILEPLATFORM)", -- xsb2108 + urb2108 + ueb2108 + uab2108
	TMLMOBILE   = "(MOBILE * LAND * INDIRECTFIRE * SILO)", -- XSL0111 + URL0111 + UEL0111 + UAL0111 + XEL0306
	
	-- added exclusion of engineers and structures because they are restricted by other presets 
	LAND        = "(LAND - ENGINEER - STRUCTURE)", 		
    -- added restriction of AA structures because they are not needed when all air units are out
	AIR         = "((STRUCTURE * (ANTIAIR + AIRSTAGINGPLATFORM)) + (AIR - POD - SATELLITE))", 			
	-- added restriction of anti-navy structures because they are not needed when all navy units are restricted
    NAVAL       = "((STRUCTURE * ANTINAVY) + NAVAL - (SONAR * TECH3))", 			
	HOVER       = "(HOVER - INSIGNIFICANTUNIT - ENGINEER)", 			
	AMPHIBIOUS  = "(AMPHIBIOUS)", -- requires adding AMPHIBIOUS category to appropriate units, e.g. Monkey Lord, CYBRIAN T2 Destroyer
    SUBS        = "(NAVAL * SUBMERSIBLE)", 			
	 
    DEF_LAND    = "(STRUCTURE * (DIRECTFIRE + WALL))",
    DEF_AIR     = "(STRUCTURE * ANTIAIR)",
    DEF_NAVY    = "(STRUCTURE * ANTINAVY)",
    DEF_SHIELD  = "(STRUCTURE * SHIELD)",  
	DEF_BUBBLES = "(STRUCTURE * SHIELD) + (MOBILE * SHIELD) - TANK - BOT - AIR", -- excluding personal shields
	DEF_WALLS   = "(STRUCTURE * WALL)", 			
    
    -- units buildable by CYBRAN T4 Megalith:
    -- xrl0002 Crab Egg (Engineer)
    -- xrl0003 Crab Egg (Brick)
    -- xrl0004 Crab Egg (Flak)
    -- xrl0005 Crab Egg (Artillery) 
    -- drlk005 Crab Egg (Bouncer) 
    CRABEGG       = '(xrl0002 + xrl0003 + xrl0004 + xrl0005 + drlk005)',

	-- added exclusion of aircraft carriers, Tzar, and Atlantis in T3_AIR expression since they can build air
	--T3_AIR        = "(TECH3 * AIR) + (TECH3 * CARRIER) + (EXPERIMENTAL * CARRIER) - SATELLITE - BATTLESHIP", 			
	T3_AIR        = "(TECH3 * AIR - FACTORY)", 			
	T3_LAND       = "(TECH3 * LAND - FACTORY)", 			
	T3_SUBS       = "(TECH3 * SUBMERSIBLE - FACTORY)", 			
	--             "dalk003 + delk002 + drlk001 + drlk005 + dslk004" 
    T3_MOBILE_AA    = "(TECH3 * LAND * MOBILE * BUILTBYTIER3FACTORY * ANTIAIR) + drlk005",   -- + Crab Egg AA 
    T3_MOBILE_ARTY  = "(TECH3 * LAND * MOBILE * BUILTBYTIER3FACTORY * ARTILLERY) + xrl0005", -- + Crab Egg Arty
    T3_AIR_GUNSHIPS = "(TECH3 * AIR * GROUNDATTACK)", 	 	
	T3_AIR_BOMBERS  = "(TECH3 * AIR * (ANTINAVY + BOMBER))", 			
	T3_DIRECT_SHIPS = "(TECH3 * NAVAL * DIRECTFIRE)", 

    T1_LAND_SPAM  = "(TECH1 * LAND - FACTORY - ENGINEER)", 			
	T1_NAVY_SPAM  = "(TECH1 * NAVAL - FACTORY - ENGINEER)", 			
	T1_AIR_SPAM   = "(TECH1 * AIR - FACTORY - ENGINEER - SCOUT - TRANSPORTATION)", 			
	 
    SNIPES        = "((AIR * (TECH2 + TECH3) * (GROUNDATTACK + BOMBER)) + (STRUCTURE * TACTICALMISSILEPLATFORM) + xrl0302 + xsl0305 + xal0305)", -- Beetle Bomb + Sniper Bots
    AIR_GUNSHIPS  = "(AIR * GROUNDATTACK - EXPERIMENTAL)", 			
	AIR_BOMBERS   = "(AIR * (ANTINAVY + BOMBER) - EXPERIMENTAL)", 			
	AIR_FIGHTERS  = "(AIR * ANTIAIR - EXPERIMENTAL - GROUNDATTACK)", 			
	AIR_TANSPORTS = "(AIR * TRANSPORTATION)", 			
	
    BOTS         = "(LAND * BOT)", 			
	TANKS        = "(LAND * TANK)", 			
	 
    SUPPFAC      = "SUPPORTFACTORY",
    ENGISTATION  = "(STRUCTURE * ENGINEERSTATION)", -- no need to exclude pod drones
    ENGIDRONES   = "(STRUCTURE * ENGINEERSTATION * UEF) + (SUBCOMMANDER * Pod) + POD", -- UEF COM WITH DRONES
     
    PARAGON      = "(EXPERIMENTAL * MASSPRODUCTION * ENERGYPRODUCTION)",
    FABS         = "(STRUCTURE * MASSFABRICATION) - EXPERIMENTAL", 
    MASSINCOME   = "(STRUCTURE * (MASSEXTRACTION + MASSSTORAGE) - EXPERIMENTAL)",
    ENGYINCOME   = "(STRUCTURE * (ENERGYPRODUCTION + ENERGYSTORAGE) - EXPERIMENTAL)",
    
	SUPCOMS      = "(SUBCOMMANDER + GATE)",
	RASCOMS      = "(SUBCOMMANDER * ResourceAllocation)", 	-- RAS SCU PRESETS (url0301_ras + uel0301_ras + ual0301_ras)" 
	TMLCOMS		 = "(SUBCOMMANDER * Missile)", 	            -- TML SCU PRESET xsl0301_missile
	
    --INTEL      = "(STRUCTURE * OPTICS) + (STRUCTURE * OMNI) + (STRUCTURE * RADAR) + (STRUCTURE * SONAR) + (NAVAL * SONAR * TECH3)",
	INTELBASIC   = "(STRUCTURE * (OMNI + RADAR + SONAR)) + MOBILESONAR",
	INTELOPTICS  = "(STRUCTURE * OPTICS)", -- "xab3301 + xrb3301", 
    INTELSONAR   = "(STRUCTURE * SONAR) + MOBILESONAR",
	INTELCOUNTER = "(STRUCTURE * COUNTERINTELLIGENCE)",
	INTELAIR     = "(AIR * (SCOUT + OMNI + RADAR + SONAR) - BOMBER - GROUNDATTACK - ANTIAIR - ANTINAVY)",
} 
-- note that enhancements are defined in tables and not in strings like category expressions are 
local enhancements = {
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
                "TacticalMissileRemove"},
    DRONES =  { "LeftPod",			-- ACU Engineering Drone C-D1  
                "LeftPodRemove",	-- ACU Engineering Drone C-D1  
                "RightPod",     	-- ACU Engineering Drone C-D2 
                "RightPodRemove",	-- ACU Engineering Drone C-D2 
                "Pod",     			-- SCU Engineering Drone C-D2   
                "PodRemove" 	   	-- SCU Engineering Drone C-D2  
	},
} 

-- defines sorting of preset restrictions and used in UnitsManager.lua
local presetsOrder = {
	"T1",
    "T2",
    "T3",
    "T4",
	"",	-- preset separator 
	"SERAPHIM",
    "UEF",
	"CYBRAN",
    "AEON",
    --"NOMADS", -- uncomment for NOMADS support 
	"",	-- preset separator 
    "AIR", 
    "LAND",
    "NAVAL",
    "HOVER",
    --"SUBS",    
    --"AMPHIBIOUS",
    "",	-- preset separator 
    --"NUKE",
	"NUKET3DEF",
	"NUKET3ML",
	"NUKET4ML",
	"NUKENAVAL",
    "",	-- preset separator 
    "T2ARTY",
    "T3ARTY",    
    "T4ARTY",    
    "SATELLITE",   
    "",	-- preset separator 
	"PARAGON",
    "ENGYINCOME",
    "MASSINCOME",
    "FABS",
    "",	-- preset separator 
	--"BOTS",
    --"TANKS",
    "T3_MOBILE_ARTY",
    "T3_MOBILE_AA",
    "T3_AIR_BOMBERS",
    "T3_AIR_GUNSHIPS",
    "",	-- preset separator 
	"TELE",
    "RAS",
    "TMLPACK",
    "BILLY",
    "",	-- preset separator 
	"SUPCOMS",
    "SUPPFAC",
    "ENGISTATION",
    "ENGIDRONES",
    "",	-- preset separator 
	"T1_AIR_SPAM",
    "T1_LAND_SPAM",
    "T1_NAVY_SPAM",
    "SNIPES",
      
    "",	-- preset separator 
	--"TML",
	"TMLDEF",
    "TMLBASE",
    "TMLMOBILE",
    "TMLNAVAL",
    "",	-- preset separator 
	"DEF_LAND",
	"DEF_AIR",
	"DEF_NAVY",
	"DEF_SHIELD",
	"",	-- preset separator 
	"INTELOPTICS",
    "INTELBASIC",
    "INTELCOUNTER",
	"INTELAIR",
    
    "",	-- preset separator 
	--"T3_AIR",
    "AIR_TANSPORTS",
    "AIR_FIGHTERS",
	"AIR_BOMBERS",
    "AIR_GUNSHIPS",
	----"WALL",
    ----"SUPERGAMEENDERS", 
}

--- Creates restriction preset from specified categories expression and/or enhancements list
local function CreatePreset(key, tooltip, name, icon, categories, enhancements)
	if presetsRestrictions[key]  then 
		WARN('*WARNING Preset with "' ..key.. '" name already exists')
	else
		local preset = {}
		preset.key = key
		preset.name = name
		preset.Icon = icon
		preset.tooltip = tooltip
		preset.categories = categories
		preset.enhancements = enhancements
		-- add new preset
		presetsRestrictions[key] = preset
	end
end

--- Creates restriction preset from a list of restriction presets 
--- by merging all category expressions and enhancements in passed presets
local function CreatePresetGroup(presetsKeys, key, tooltip, name, icon)
  
	local presetMerging = false
	-- check if a preset already exists 
	local preset = presetsRestrictions[key] 
	if not preset then 
		preset = {}
		preset.categories = nil
		preset.enhancements = nil
		presetMerging = true	-- perform restrictions merge on a new preset
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
local function CreatePresets()
	-- FACTIONS restrictions  
	CreatePreset("UEF", 
		"<LOC restricted_units_info_UEF>Prevents all UEF units and structures, except ACU",
		"<LOC restricted_units_data_UEF>No UEF Units", 
		"/textures/ui/common/faction_icon-lg/uef_ico.dds",
		Expressions.UEF, nil)
	CreatePreset("CYBRAN", 
		"<LOC restricted_units_info_CYBRAN>Prevents all Cybran units and structures, except ACU",
		"<LOC restricted_units_data_CYBRAN>No Cybran Units", 
		"/textures/ui/common/faction_icon-lg/cybran_ico.dds",
		Expressions.CYBRAN, nil)
	CreatePreset("AEON", 
		"<LOC restricted_units_info_AEON>Prevents all Aeon units and structures, except ACU",
		"<LOC restricted_units_data_AEON>No Aeon Units", 
		"/textures/ui/common/faction_icon-lg/aeon_ico.dds",
		Expressions.AEON, nil)
	CreatePreset("SERAPHIM", 
		"<LOC restricted_units_info_SERAPHIM>Prevents all Seraphim units and structures, except ACU",
		"<LOC restricted_units_data_SERAPHIM>No Seraphim Units", 
		"/textures/ui/common/faction_icon-lg/seraphim_ico.dds",
		Expressions.SERAPHIM, nil)
    CreatePreset("NOMADS", 
		"<LOC restricted_units_info_NOMADS>Prevents all Nomads units and structures, except ACU",
		"<LOC restricted_units_data_NOMADS>No Nomads Units", 
		"/textures/ui/common/faction_icon-lg/nomads_ico.dds",
		Expressions.NOMADS, nil)
	
	-- TECH restrictions
    CreatePreset("T1", 
		"<LOC restricted_units_info_T1>Prevents all T1 units and structures, except engineers and factories",
		"<LOC restricted_units_data_T1>No Tech 1 Units", 
		"/textures/ui/common/icons/presets/tech-1.dds",
		Expressions.T1, nil)
	CreatePreset("T2", 
		"<LOC restricted_units_info_T2>Prevents all T2 units and structures, except engineers and factories",
		"<LOC restricted_units_data_T2>No Tech 2 Units", 
		"/textures/ui/common/icons/presets/tech-2.dds",
		Expressions.T2, nil)
	CreatePreset("T3", 
		"<LOC restricted_units_info_T3>Prevents all T3 units and structures, except engineers and factories",
		"<LOC restricted_units_data_T3>No Tech 3 Units", 
		"/textures/ui/common/icons/presets/tech-3.dds",
		Expressions.T3, nil)
	CreatePreset("T4", 
		"<LOC restricted_units_info_T4>Prevents all T4 (experimental) units and structures",
		"<LOC restricted_units_data_T4>No Experimental Units", 
		"/textures/ui/common/icons/presets/tech-4.dds",
		Expressions.T4, nil)
 
 	-- TYPES restrictions
    CreatePreset("LAND", 
		"<LOC restricted_units_info_LAND>Prevents all land units and anti-land structures, except engineers and factories",
		"<LOC restricted_units_data_LAND>No Land Units", 
		"/textures/ui/common/icons/presets/type-land.dds",
		Expressions.LAND, nil)
	CreatePreset("AIR", 
		"<LOC restricted_units_info_AIR>Prevents all air units, air factories, and anti-air structures",
		"<LOC restricted_units_data_AIR>No Air Units", 
		"/textures/ui/common/icons/presets/type-air.dds",
		Expressions.AIR, nil)
	CreatePreset("NAVAL", 
		"<LOC restricted_units_info_NAVAL>Prevents all naval units naval factories, and anti-navy structures",
		"<LOC restricted_units_data_NAVAL>No Naval Units", 
		"/textures/ui/common/icons/presets/type-naval.dds",
		Expressions.NAVAL, nil)
	CreatePreset("HOVER", 
		"<LOC restricted_units_info_HOVER>Prevents all hover units, except engineers",
		"<LOC restricted_units_data_HOVER>No Hover Units", 
		"/textures/ui/common/icons/presets/type-hover.dds",
		Expressions.HOVER, nil)
    CreatePreset("AMPHIBIOUS", 
		"<LOC restricted_units_info_AMPHIBIOUS>Prevents all amphibious units",
		"<LOC restricted_units_data_AMPHIBIOUS>No Amphibious Units", 
		"/textures/ui/common/icons/presets/type-amphibius.dds",
		Expressions.AMPHIBIOUS, nil)
    CreatePreset("SUBS", 
		"<LOC restricted_units_info_.>Prevents all submersible units",
		"<LOC restricted_units_data_.>No Submersible Units", 
		"/textures/ui/common/icons/presets/type-subs.dds",
		Expressions.SUBS, nil)
         
	-- NUKES restrictions
	CreatePreset("NUKET4ML", 
		"<LOC restricted_units_info_NUKET4ML>Prevents T4 structures with strategic missile launchers (SML)",
		"<LOC restricted_units_data_NUKET4ML>No T4 Nuke Launchers", 
		"/textures/ui/common/icons/presets/nukes-t4-ml.dds",
		Expressions.NUKET4ML, nil)
	CreatePreset("NUKET3ML", 
		"<LOC restricted_units_info_NUKET3ML>Prevents T3 structures with strategic missile launchers (SML)",
		"<LOC restricted_units_data_NUKET3ML>No T3 Nuke Launchers", 
		"/textures/ui/common/icons/presets/nukes-t3-ml.dds",
		Expressions.NUKET3ML, nil)
	CreatePreset("NUKET3DEF", 
		"<LOC restricted_units_info_NUKET3DEF>Prevents T3 structures with strategic missile defense (SMD) ",
		"<LOC restricted_units_data_NUKET3DEF>No T3 Nuke Defense", 
		"/textures/ui/common/icons/presets/nukes-t3-def.dds",
		Expressions.NUKET3DEF, nil)
	CreatePreset("NUKENAVAL", 
		"<LOC restricted_units_info_NUKENAVAL>Prevents T3 naval ships with strategic missile launchers (nuke subs)",
		"<LOC restricted_units_data_NUKENAVAL>No Nuke Naval Launchers", 
		"/textures/ui/common/icons/presets/nukes-ships.dds",
		Expressions.NUKENAVAL, nil)
		 
	CreatePreset("T2ARTY", 
		"<LOC restricted_units_info_T2ARTY>Prevents T2 artillery structures",
		"<LOC restricted_units_data_T2ARTY>No Tech 2 Artillery", 
		"/textures/ui/common/icons/presets/base-t2-arty.dds",
		Expressions.T2ARTY, nil)
	-- GAME ENDERS restrictions 
	CreatePreset("T3ARTY", 
		"<LOC restricted_units_info_T3ARTY>Prevents T3 artillery structures",
		"<LOC restricted_units_data_T3ARTY>No Heavy Artillery", 
		"/textures/ui/common/icons/presets/base-t3-arty.dds",
		Expressions.T3ARTY, nil)
	CreatePreset("T4ARTY", 
		"<LOC restricted_units_info_T4ARTY>Prevents T4 artillery structures, e.g. Salvation, Mavor, and Scathis",
		"<LOC restricted_units_data_T4ARTY>No Super Artillery", 
		"/textures/ui/common/icons/presets/base-t4-arty.dds",
		Expressions.T4ARTY, nil)
	CreatePreset("SATELLITE", 
		"<LOC restricted_units_info_SATELLITE>Prevents satellites structures, e.g. UEF Novax Center",
		"<LOC restricted_units_data_SATELLITE>No Satellite", 
		"/textures/ui/common/icons/presets/base-satellites.dds",
		Expressions.SATELLITE, nil)
	      
	-- ADVANCED restrictions 
	CreatePreset("AIR_TANSPORTS", 
		"<LOC restricted_units_info_AIR_TANSPORTS>Prevents all transport units",
		"<LOC restricted_units_data_AIR_TANSPORTS>No Transports", 
		"/textures/ui/common/icons/presets/air-transports.dds",
		Expressions.AIR_TANSPORTS, nil)

	CreatePreset("AIR_GUNSHIPS", 
		"<LOC restricted_units_info_AIR_GUNSHIPS>Prevents all gunships",
		"<LOC restricted_units_data_AIR_GUNSHIPS>No All Gunships", 
		"/textures/ui/common/icons/presets/air-gunships.dds",
		Expressions.AIR_GUNSHIPS, nil)
    CreatePreset("T3_AIR_GUNSHIPS", 
		"<LOC restricted_units_info_T3_AIR_GUNSHIPS>Prevents T3 gunships", 
        "<LOC restricted_units_data_T3_AIR_GUNSHIPS>No T3 Gunships", 
		"/textures/ui/common/icons/presets/air-t3-gunships.dds",
		Expressions.T3_AIR_GUNSHIPS, nil)
        
	CreatePreset("AIR_BOMBERS", 
		"<LOC restricted_units_info_AIR_BOMBERS>Prevents all bombers",
		"<LOC restricted_units_data_AIR_BOMBERS>No Bombers", 
		"/textures/ui/common/icons/presets/air-bombers.dds",
		Expressions.AIR_BOMBERS, nil)
     CreatePreset("T3_AIR_BOMBERS", 
		"<LOC restricted_units_info_T3_AIR_BOMBERS>Prevents T3 bombers", 
        "<LOC restricted_units_data_T3_AIR_BOMBERS>No T3 Bombers", 
		"/textures/ui/common/icons/presets/air-t3-bombers.dds",
		Expressions.T3_AIR_BOMBERS, nil)
                
    CreatePreset("AIR_FIGHTERS", 
		"<LOC restricted_units_info_AIR_FIGHTERS>Prevents all interceptors and air fighters",
		"<LOC restricted_units_data_AIR_FIGHTERS>No Air Fighters", 
		"/textures/ui/common/icons/presets/air-fighters.dds",
		Expressions.AIR_FIGHTERS, nil)

    CreatePreset("T3_MOBILE_AA", 
		"<LOC restricted_units_info_T3_MOBILE_AA>Prevents T3 mobile anti-air units", 
        "<LOC restricted_units_data_T3_MOBILE_AA>No T3 Mobile Anti-Air", 
		"/textures/ui/common/icons/presets/land-t3-anti-air.dds",
		Expressions.T3_MOBILE_AA, nil)
	CreatePreset("T3_MOBILE_ARTY", 
		"<LOC restricted_units_info_T3_MOBILE_ARTY>Prevents T3 mobile artillery units", 
        "<LOC restricted_units_data_T3_MOBILE_ARTY>No T3 Mobile Artillery", 
		"/textures/ui/common/icons/presets/land-t3-arty.dds",
		Expressions.T3_MOBILE_ARTY, nil)
    CreatePreset("T3_DIRECT_SHIPS", 
		"<LOC restricted_units_info_T3_DIRECT_SHIPS>Prevents T3 direct fire Ships, e.g. battleships", 
        "<LOC restricted_units_data_T3_DIRECT_SHIPS>No T3 Direct Fire Ships", 
		"/textures/ui/common/icons/presets/ships-t3-directfire.dds",
		Expressions.T3_DIRECT_SHIPS, nil)
                     	
    CreatePreset("SNIPES", 
		"<LOC restricted_units_info_SNIPES>Prevents all units capable of sniping ACU or strategic structures from a long range or in a few flybys",
		"<LOC restricted_units_data_SNIPES>No Unit Snipers", 
		"/textures/ui/common/icons/presets/land-snipes.dds",
		Expressions.SNIPES, nil)
	 
    CreatePreset("T1_LAND_SPAM", 
		"<LOC restricted_units_info_T1_LAND_SPAM>Prevents spamming T1 land units ",
		"<LOC restricted_units_data_T1_LAND_SPAM>No T1 Land Spam", 
		"/textures/ui/common/icons/presets/land-t1-spam.dds",
		Expressions.T1_LAND_SPAM, nil)
	CreatePreset("T1_AIR_SPAM", 
		"<LOC restricted_units_info_T1_AIR_SPAM>Prevents spamming T1 air units ",
		"<LOC restricted_units_data_T1_AIR_SPAM>No T1 Air Spam", 
		"/textures/ui/common/icons/presets/air-t1-spam.dds",
		Expressions.T1_AIR_SPAM, nil)
	CreatePreset("T1_NAVY_SPAM", 
		"<LOC restricted_units_info_T1_NAVY_SPAM>Prevents spamming T1 naval units ",
		"<LOC restricted_units_data_T1_NAVY_SPAM>No T1 Navy Spam", 
		"/textures/ui/common/icons/presets/ships-t1-spam.dds",
		Expressions.T1_NAVY_SPAM, nil)

	-- SUPPORT restrictions
	 CreatePreset("SUPCOMS", 
		"<LOC restricted_units_info_SUPCOMS>Prevents all support commander units (SCUs) and quantum gateway structures", 
        "<LOC restricted_units_data_SUPCOMS>No Support Commanders", 
		"/textures/ui/common/icons/presets/eng-scus.dds",
		Expressions.SUPCOMS, nil)
	 CreatePreset("SUPPFAC", 
		"<LOC restricted_units_info_SUPPFAC>Prevents upgrading all factories to support factories",		
        "<LOC restricted_units_data_SUPPFAC>No Support Factories", 
		"/textures/ui/common/icons/presets/base-factory.dds",
		Expressions.SUPPFAC, nil)
	 CreatePreset("ENGISTATION", 
		"<LOC restricted_units_info_ENGISTATION>Prevents all engineering stations (UEF Kendel and Cybran Hive structures)",
		"<LOC restricted_units_data_ENGISTATION>No Engineering Stations", 
		"/textures/ui/common/icons/presets/eng-stations.dds",
		Expressions.ENGISTATION, nil)
	 CreatePreset("ENGIDRONES", 
		"<LOC restricted_units_info_ENGIDRONES>Prevents all upgrades enabling engineering drones and UEF Kendel structures",
		"<LOC restricted_units_data_ENGIDRONES>No Engineering Drones", 
		"/textures/ui/common/icons/presets/eng-drones.dds",
		Expressions.ENGIDRONES, enhancements.DRONES)
	       
    -- COMMANDER UPGRADES restrictions 	
	CreatePreset("TELE", 
		"<LOC restricted_units_info_TELE>Prevents commander upgrade that provides teleporting ability",
		"<LOC restricted_units_data_TELE>No Teleporting", 
		"/textures/ui/common/icons/presets/enh-tele-icon.dds",
		nil, enhancements.TELE)	  	
	CreatePreset("BILLY", 
		"<LOC restricted_units_info_BILLY>Prevents commander upgrade that provides tactical nuke launchers ",
		"<LOC restricted_units_data_BILLY>No Billy", 
		"/textures/ui/common/icons/presets/enh-billy-icon.dds",
		nil, enhancements.BILLY)	 
    CreatePreset("RAS", 
		"<LOC restricted_units_info_RAS>Prevents commander upgrade that generates resources via resource allocation system (RAS)",
		"<LOC restricted_units_data_RAS>No Resource Allocation System", 
		"/textures/ui/common/icons/presets/enh-ras-icon.dds",
		Expressions.RASCOMS, enhancements.RAS)	
	CreatePreset("TMLPACK", 
		"<LOC restricted_units_info_TMLPACK>Prevents commander upgrade that enables tactical missile launchers (TML)",
		"<LOC restricted_units_data_TMLPACK>No Tactical Missile Pack", 
		"/textures/ui/common/icons/presets/enh-tml-icon.dds",
		Expressions.TMLCOMS, enhancements.TMLPACK)
	         
	-- DEFENSE restrictions 
	CreatePreset("DEF_LAND", 
		"<LOC restricted_units_info_DEF_LAND>Prevents all structures for anti-land defense ",
		"<LOC restricted_units_data_DEF_LAND>No Land Defense", 
		"/textures/ui/common/icons/presets/base-def-land.dds",
		Expressions.DEF_LAND, nil)
	CreatePreset("DEF_AIR", 
		"<LOC restricted_units_info_DEF_AIR>Prevents all structures for anti-air defense ",
		"<LOC restricted_units_data_DEF_AIR>No Air Defense", 
		"/textures/ui/common/icons/presets/base-def-air.dds",
		Expressions.DEF_AIR, nil)
	CreatePreset("DEF_NAVY", 
		"<LOC restricted_units_info_DEF_NAVY>Prevents all structures for anti-navy defense ",
		"<LOC restricted_units_data_DEF_NAVY>No Navy Defense", 
		"/textures/ui/common/icons/presets/base-def-navy.dds",
		Expressions.DEF_NAVY, nil)
	CreatePreset("DEF_SHIELD", 
		"<LOC restricted_units_info_DEF_SHIELD>Prevents all structures generating force field defense ",
		"<LOC restricted_units_data_DEF_SHIELD>No Shields Defense", 
		"/textures/ui/common/icons/presets/base-def-shields.dds",
		Expressions.DEF_SHIELD, nil)

   	-- INTEL restrictions       
    CreatePreset("INTELBASIC", 
		"<LOC restricted_units_info_INTELBASIC>Prevents all structures that provide basic intelligence such as radar, sonar, and omni",
		"<LOC restricted_units_data_INTELBASIC>No Basic-Intel Structures", 
		"/textures/ui/common/icons/presets/base-intel-basic.dds",
		Expressions.INTELBASIC, nil)
    CreatePreset("INTELOPTICS", 
		"<LOC restricted_units_info_INTELOPTICS>Prevents all structures that provide super intelligence such as large vision over battlefield, e.g. Aeon Eye of Rhianne and Cybran Soothsayer",
		"<LOC restricted_units_data_INTELOPTICS>No Super-Intel Structures", 
		"/textures/ui/common/icons/presets/base-intel-optics.dds", 
		Expressions.INTELOPTICS, nil)		
    CreatePreset("INTELCOUNTER", 
		"<LOC restricted_units_info_INTELCOUNTER>Prevents all structures that provide stealth field for nearby units ",
		"<LOC restricted_units_data_INTELCOUNTER>No Stealth Structures", 
		"/textures/ui/common/icons/presets/base-intel-counter.dds",
		Expressions.INTELCOUNTER, nil)
    CreatePreset("INTELAIR", 
		"<LOC restricted_units_info_INTELAIR>Prevents all air units that provide intelligence",
		"<LOC restricted_units_data_INTELAIR>No Intel Aircrafts", 
		"/textures/ui/common/icons/presets/air-intel.dds",
		Expressions.INTELAIR, nil)
    
    -- TACTICAL MISSILES restrictions 
	CreatePreset("TMLDEF", 
		"<LOC restricted_units_info_TMLDEF>Prevents all structures that provide tactical missile defense (TMD) ability",
		"<LOC restricted_units_data_TMLDEF>No Tactical Missile Defense", 
		"/textures/ui/common/icons/presets/tml-def.dds",
		Expressions.TMLDEF, nil)
  	CreatePreset("TMLBASE", 
		"<LOC restricted_units_info_TMLBASE>Prevents all structures that provide tactical missile launch (TML) ability ",
		"<LOC restricted_units_data_TMLBASE>No Tactical Missile Launchers", 
		"/textures/ui/common/icons/presets/tml-base.dds",
		Expressions.TMLBASE, nil)
	CreatePreset("TMLMOBILE", 
		"<LOC restricted_units_info_TMLMOBILE>Prevents all mobile land units that provide tactical missile launch (TML) ability ",
		"<LOC restricted_units_data_TMLMOBILE>No Tactical Mobile Launchers", 
		"/textures/ui/common/icons/presets/tml-mobile.dds",
		Expressions.TMLMOBILE, nil)
	CreatePreset("TMLNAVAL", 
		"<LOC restricted_units_info_TMLNAVAL>Prevents all naval ships that provide tactical missile launch (TML) ability ",
		"<LOC restricted_units_data_TMLNAVAL>No Tactical Missile Ships", 
		"/textures/ui/common/icons/presets/tml-naval.dds",
		Expressions.TMLNAVAL, nil)
     
    -- eco restrictions
    CreatePreset("MASSINCOME", 
		"<LOC restricted_units_info_MASSINCOME>Prevents all structures that extract mass ",
		"<LOC restricted_units_data_MASSINCOME>No Mass Extractors", 
		"/textures/ui/common/icons/presets/base-mass-extactors.dds",
		Expressions.MASSINCOME, nil)
	CreatePreset("ENGYINCOME", 
		"<LOC restricted_units_info_ENGYINCOME>Prevents all structures that generate energy ",
		"<LOC restricted_units_data_ENGYINCOME>No Energy Generators", 
		"/textures/ui/common/icons/presets/base-energy.dds",
		Expressions.ENGYINCOME, nil)
	CreatePreset("FABS", 
		"<LOC restricted_units_info_FABS>Prevents all structures that fabricate mass from energy ",
		"<LOC restricted_units_data_FABS>No Mass Fabrication", 
		"/textures/ui/common/icons/presets/base-mass-fabs.dds",
		Expressions.FABS, nil)
    CreatePreset("PARAGON", 
		"<LOC restricted_units_info_PARAGON>Prevents T4 structures that generate infinite mass and energy, e.g. Aeon Paragon",
		"<LOC restricted_units_data_PARAGON>No Paragon", 
		"/textures/ui/common/icons/presets/base-paragon.dds",
		Expressions.PARAGON, nil)
	
    -- grouped presets 
	CreatePresetGroup({"TMLDEF", "TMLBASE", "TMLMOBILE", "TMLNAVAL", "TMLPACK"}, "TML", 
	    "<LOC restricted_units_info_TML>Prevents all units with tactical missile launchers (TML) and tactical missile defense structures (TMD) ", 
        "<LOC restricted_units_data_TML>No Tactical Missiles",
	    "/textures/ui/common/icons/presets/tml-all.dds")
	CreatePresetGroup({"NUKET3DEF", "NUKET3ML", "NUKET4ML", "NUKENAVAL"}, "NUKE", 
	    "<LOC restricted_units_info_NUKE>Prevents all units with strategic missile launchers (SML) and strategic missile defense (SMD) ", 
        "<LOC restricted_units_data_NUKE>No Nukes",
	    "/textures/ui/common/icons/presets/nukes-all.dds")

	--CreatePresetGroup({"T3ARTY", "T4ARTY", "SATELLITE", "PARAGON"}, "GAMEENDERS", 
	--"restricted_units_gameenders", "<LOC restricted_units_data_0012>No Game Enders",
	--"")
		
end
 
--- Generates restriction presets or returns cached presets 
function GetPresetsData()
	if table.getsize(presetsRestrictions) == 0 then
		CreatePresets()
	end
	return presetsRestrictions
end
function GetPresetsOrder()
	-- ensure restriction presets are generated before accessing order 
	GetPresetsData()
	return presetsOrder
end
