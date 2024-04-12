-- This file is used by hotbuild.lua
-- It is a hardcoded list of keybind categories. It maps each category to a unit ID, either directly or indirectly
-- TODO: Find a way to generate this table using categories or something enable mod compatibility

unitkeygroups = {

    -- hotbuild
    ["Builders"] = {
        "Land_Factory",
        "Air_Factory",
        "Naval_Factory",
        "Quantum_Gateway",

        "Support_Armored_Command_Unit",
        "T1_Engineer",
    },
    ["Sensors"] = {
        "Omni_Sensor",
        "Radar_System",
        "Sonar_Platform",
        "Sonar_System",
        "Perimeter_Monitoring_System",
        "Quantum_Optics_Facility",

        "T1_Land_Scout",
        "T1_Combat_Scout",

        "T1_Air_Scout",

        "T1_Attack_Submarine",
    },
    ["Shields"] = {
        "Heavy_Shield_Generator",
        "Shield_Generator",
        "Stealth_Field_Generator",

        "T1_Light_Assault_Bot",

        "T1_Interceptor",

        "T1_Frigate",
    },
    ["TMD"] = {
        "Tactical_Missile_Defense",
        "Strategic_Missile_Defense",

        "T1_Tank",
        "T1_Assault_Bot", -- Mantis

        "T1_Attack_Bomber",

        "T1_Attack_Boat", -- Aeon only
    },
    ["XP"] = {
        "Experimental",

        "T1_Mobile_Anti_Air_Gun",

        "T1_Light_Air_Transport",
    },
    ["Mobilearty"] = {
        "T1_Mobile_Light_Artillery",

        "T1_Light_Gunship",
    },
    -- Second Row
    ["Mass"] = {
        "Mass_Extractor",

        "T2_Engineer",
    },
    ["MassFab"] = {
        "Mass_Fabricator",

        "T2_Gatling_Bot",
        "T2_Rocket_Bot",
        "T2_Assault_Bot",

        "T2_Fighter/Bomber",
        "T2_Combat_Fighter",

        "T2_Submarine_Hunter",
        "T2_Torpedo_Boat",
        "T2_Submarine_Killer",
    },
    ["Pgen"] = {
        "Power_Generator",
        "Hydrocarbon_Power_Plant",

        "T2_Heavy_Tank",

        "T2_Torpedo_Bomber",

        "T2_Destroyer",
    },
    ["Templates"] = {
        "_templates", -- Special :)

        "T2_Hover_Tank",
        "T2_Assault_Tank",
        "T2_Amphibious_Tank",

        "T2_Gunship",

        "T2_Cruiser",
    },
    ["Cycle_Templates"] = {
        "_cycleTemplates", -- Special :)

        "T2_Hover_Tank",
        "T2_Assault_Tank",
        "T2_Amphibious_Tank",

        "T2_Gunship",

        "T2_Cruiser",
    },
    ["EngyStation"] = {
        "Engineering_Station",

        "T2_Mobile_Anti_Air_Cannon",
        "T2_Mobile_AA_Flak_Artillery",

        "T2_Air_Transport",

        "T2_Counter_Intelligence_Boat",
        "T2_Shield_Boat",
    },
    ["MML"] = {
        "T2_Mobile_Missile_Launcher",

        "T2_Guided_Missile",
    },
    ["MobileShield"] = {
        "T2_Mobile_Shield_Generator",
        "T2_Mobile_Stealth_Field_System",
    },
    ["FieldEngy"] = {
        "T2_Field_Engineer",
    },
    -- Row 3 XCVBNM
    ["Defense"] = {
        "Heavy_Point_Defense",
        "Point_Defense",
        "Wall_Section",

        "T3_Engineer",
    },
    ["AA"] = {
        "Anti_Air",
        "Air_Staging",

        "T3_Sniper_Bot",
        "T3_Siege_Assault_Bot", -- Loyalist & Titan

        "T3_Spy_Plane",

        "T3_Strategic_Missile_Submarine",
        "T3_Submarine_Hunter",
    },
    ["Torpedo"] = {
        "Torpedo_Ambushing_System",
        "Torpedo_Launcher",

        "T3_Armored_Assault_Bot", -- Brick & Percival
        "T3_Tank", -- Othumms & Harbinger

        "T3_Air_Superiority_Fighter",

        "T3_Battleship",
    },
    ["Arties"] = {
        "Artillery_Installation",
        "Heavy_Artillery_Installation",

        "T3_Strategic_Bomber",

        "T3_Mobile_Heavy_Artillery",

        "T3_Aircraft_Carrier",
        "T3_Battlecruiser",
    },
    ["TML"] = {
        "Tactical_Missile_Launcher",
        "Strategic_Missile_Launcher",

        "T3_Mobile_Missile_Platform",
        "T3_Shield_Disruptor",
        "T3_Mobile_Shield_Generator",

        "T3_Heavy_Gunship",
        "T3_AA_Gunship",

        "T3_Missile_Ship",
    },
    ["Upgrades"] = {
        "_upgrade",
        "T3_Mobile_AA",
        "T3_Heavy_Air_Transport",
        "T3_Torpedo_Bomber",
    },

    -- alternative hotbuild
    ["Alt_Builders"] = {
        "Land_Factory",
        "Air_Factory",
        "Naval_Factory",
        "Quantum_Gateway",
        "xrl0002", -- T3 engineer for Megalith

        "Support_Armored_Command_Unit",
        "T3_Engineer",
        "T2_Engineer",
        "T1_Engineer",
    },
    ["Alt_Radars"] = {
        "Omni_Sensor",
        "Radar_System",
        "Perimeter_Monitoring_System",
        "Quantum_Optics_Facility",

        "T1_Land_Scout",
        "T1_Combat_Scout",

        "T3_Spy_Plane",
        "T1_Air_Scout",
    },
    ["Alt_Shields"] = {
        "Heavy_Shield_Generator",
        "Shield_Generator",

        "T3_Shield_Disruptor",
        "T3_Mobile_Shield_Generator",
        "T2_Mobile_Shield_Generator",

        "T3_Heavy_Air_Transport",

        "T2_Shield_Boat",
    },
    ["Alt_TMD"] = {
        "Tactical_Missile_Defense",
        "Strategic_Missile_Defense",
    },
    ["Alt_XP"] = {
        "Experimental",

        "T2_Mobile_Bomb",

        "T2_Guided_Missile",
    },
    ["Alt_Sonars"] = {
        "Sonar_Platform",
        "Sonar_System",

        "T2_Hover_Tank",
        "T2_Assault_Tank",
        "T2_Amphibious_Tank",

        "T3_Heavy_Air_Transport",
        "T2_Air_Transport",
        "T1_Light_Air_Transport",
    },
    ["Alt_Mass"] = {
        "Mass_Extractor",
        "Mass_Fabricator",

        "xrl0003", -- Brick for Megalith
        "T3_Armored_Assault_Bot", -- Brick & Percival
        "T3_Tank", -- Othumms & Harbinger
        "T2_Heavy_Tank",
        "T2_Assault_Bot",
        "T1_Tank",
        "T1_Assault_Bot", -- Mantis

        "T3_Strategic_Bomber",
        "T2_Fighter/Bomber",
        "T1_Attack_Bomber",

        "T3_Battleship",
        "T3_Battlecruiser",
        "T2_Destroyer",
        "T1_Frigate",
    },
    ["Alt_Stealth"] = {
        "Stealth_Field_Generator",
        "urs0305", -- cybran sonar

        "T2_Mobile_Stealth_Field_System",

        "T2_Counter_Intelligence_Boat",
    },
    ["Alt_Pgen"] = {
        "Power_Generator",
        "Hydrocarbon_Power_Plant",
        "Energy_Storage",

        "T3_Sniper_Bot",
        "T3_Siege_Assault_Bot", -- Loyalist & Titan
        "T2_Gatling_Bot",
        "T2_Rocket_Bot",
        "T1_Light_Assault_Bot",

        "T3_Heavy_Gunship",
        "T3_AA_Gunship",
        "T2_Gunship",
        "T1_Light_Gunship",
    },
    ["Alt_Templates"] = {
        "_templates", -- Special :)

        "_factory_templates", -- Special :)
    },
    ["Alt_EngyStation"] = {
        "Engineering_Station",

        "T2_Field_Engineer",
    },
    ["Alt_Defense"] = {
        "Heavy_Point_Defense",
        "Point_Defense",
        "Wall_Section",

        "_upgrade",
    },
    ["Alt_AA"] = {
        "Anti_Air",
        "Air_Staging",

        "T3_Mobile_AA",
        "drlk005", -- T3 mobile anti air for Megalith
        "T2_Mobile_Anti_Air_Cannon",
        "T2_Mobile_AA_Flak_Artillery",
        "xrl0004", -- T2 flak for Megalith
        "T1_Mobile_Anti_Air_Gun",

        "T3_Air_Superiority_Fighter",
        "T2_Combat_Fighter",
        "T1_Interceptor",

        "T3_Aircraft_Carrier",
        "T2_Cruiser",
        "T1_Attack_Boat", -- Aeon only
    },
    ["Alt_Torpedo"] = {
        "Torpedo_Ambushing_System",
        "Torpedo_Launcher",

        "T3_Torpedo_Bomber",
        "T2_Torpedo_Bomber",

        "T3_Strategic_Missile_Submarine",
        "T3_Submarine_Hunter",
        "T2_Submarine_Hunter",
        "T2_Torpedo_Boat",
        "T2_Submarine_Killer",
        "T1_Attack_Submarine",
    },
    ["Alt_Arties"] = {
        "Heavy_Artillery_Installation",
        "Artillery_Installation",

        "T3_Mobile_Heavy_Artillery",
        "xrl0005", -- T3 arty for Megalith
        "T1_Mobile_Light_Artillery",
    },
    ["Alt_TML"] = {
        "Tactical_Missile_Launcher",
        "Strategic_Missile_Launcher",

        "T3_Mobile_Missile_Platform",
        "T2_Mobile_Missile_Launcher",

        "xss0302", -- sera battleship
        "T3_Strategic_Missile_Submarine",
        "T3_Missile_Ship",
        "xss0202", -- sera cruiser
        "ues0202", -- uef cruiser
    },

    -- extra hotkeys
    ["Experimental"] = {
        -- Aeon
        "ual0401", -- Galactic Colossus
        "uaa0310", -- Czar
        "uas0401", -- Tempest
        "xab1401", -- Paragon
        "xab2307", -- Salvation
        -- Cyb
        "url0402", -- Monkeylord
        "xrl0403", -- Megalith
        "url0401", -- Scathis
        "ura0401", -- Soulripper
        -- UEF
        "uel0401", -- Fatboy
        "ues0401", -- Atlantis
        "xeb2402", -- Novax
        "ueb2401", -- Mavor
        -- Sera
        "xsl0401", -- Ythotha
        "xsa0402", -- Bomber
        "xsb2401", -- SML
    },
    -- Buildings
    ["Land_Factory"] = {
        "xsb0101",
        "urb0101",
        "ueb0101",
        "uab0101",
    },
    ["Air_Factory"] = {
        "xsb0102",
        "urb0102",
        "ueb0102",
        "uab0102",
    },
    ["Naval_Factory"] = {
        "xsb0103",
        "urb0103",
        "ueb0103",
        "uab0103",
    },
    ["T2_Support_Factory"] = {
        "T2_Support_Land_Factory",
        "T2_Support_Air_Factory",
        "T2_Support_Naval_Factory",
    },
    ["T3_Support_Factory"] = {
        "T3_Support_Land_Factory",
        "T3_Support_Air_Factory",
        "T3_Support_Naval_Factory",
    },
    ["T2_Support_Land_Factory"] = {
        "zsb9501",
        "zrb9501",
        "zeb9501",
        "zab9501",
    },
    ["T2_Support_Air_Factory"] = {
        "zsb9502",
        "zrb9502",
        "zeb9502",
        "zab9502",
    },
    ["T2_Support_Naval_Factory"] = {
        "zsb9503",
        "zrb9503",
        "zeb9503",
        "zab9503",
    },
    ["T3_Support_Land_Factory"] = {
        "zsb9601",
        "zrb9601",
        "zeb9601",
        "zab9601",
    },
    ["T3_Support_Air_Factory"] = {
        "zsb9602",
        "zrb9602",
        "zeb9602",
        "zab9602",
    },
    ["T3_Support_Naval_Factory"] = {
        "zsb9603",
        "zrb9603",
        "zeb9603",
        "zab9603",
    },
    ["Quantum_Gateway"] = {
        "xsb0304",
        "urb0304",
        "ueb0304",
        "uab0304",
    },
    ["Power_Generator"] = {
        "xsb1301",
        "xsb1201",
        "xsb1101",
        "urb1301",
        "urb1201",
        "urb1101",
        "ueb1301",
        "ueb1201",
        "ueb1101",
        "uab1301",
        "uab1201",
        "uab1101",
    },
    ["Hydrocarbon_Power_Plant"] = {
        "xsb1102",
        "urb1102",
        "ueb1102",
        "uab1102",
    },
    ["Mass_Extractor"] = {
        "xsb1302",
        "xsb1202",
        "xsb1103",
        "urb1302",
        "urb1202",
        "urb1103",
        "ueb1302",
        "ueb1202",
        "ueb1103",
        "uab1302",
        "uab1202",
        "uab1103",
    },
    ["Mass_Fabricator"] = {
        "xsb1303",
        "xsb1104",
        "urb1303",
        "urb1104",
        "ueb1303",
        "ueb1104",
        "uab1303",
        "uab1104",
    },
    ["Energy_Storage"] = {
        "xsb1105",
        "urb1105",
        "ueb1105",
        "uab1105",
    },
    ["Mass_Storage"] = {
        "xsb1106",
        "urb1106",
        "ueb1106",
        "uab1106",
    },
    ["Point_Defense"] = {
        "xsb2301",
        "xsb2101",
        "urb2301",
        "urb2101",
        "ueb2301",
        "ueb2101",
        "uab2301",
        "uab2101",
    },
    ["Anti_Air"] = {
        "xsb2304",
        "xsb2204",
        "xsb2104",
        "urb2304",
        "urb2204",
        "urb2104",
        "ueb2304",
        "ueb2204",
        "ueb2104",
        "uab2304",
        "uab2204",
        "uab2104",
    },
    ["Tactical_Missile_Launcher"] = {
        "xsb2108",
        "urb2108",
        "ueb2108",
        "uab2108",
    },
    ["Torpedo_Launcher"] = {
        "xsb2205",
        "xsb2109",
        "urb2205",
        "urb2109",
        "ueb2205",
        "ueb2109",
        "uab2205",
        "uab2109",
    },
    ["Heavy_Artillery_Installation"] = {
        "xsb2302",
        "urb2302",
        "ueb2302",
        "uab2302",
    },
    ["Artillery_Installation"] = {
        "xsb2303",
        "urb2303",
        "ueb2303",
        "uab2303",
    },
    ["Strategic_Missile_Launcher"] = {
        "xsb2305",
        "urb2305",
        "ueb2305",
        "uab2305",
    },
    ["Radar_System"] = {
        "xsb3201",
        "xsb3101",
        "urb3201",
        "urb3101",
        "ueb3201",
        "ueb3101",
        "uab3201",
        "uab3101",
    },
    ["Sonar_System"] = {
        "xsb3202",
        "xsb3102",
        "urb3202",
        "urb3102",
        "ueb3202",
        "ueb3102",
        "uab3202",
        "uab3102",
    },
    ["Omni_Sensor"] = {
        "xsb3104",
        "urb3104",
        "ueb3104",
        "uab3104",
    },
    ["Tactical_Missile_Defense"] = {
        "xsb4201",
        "urb4201",
        "ueb4201",
        "uab4201",
    },
    ["Shield_Generator"] = {
        "xsb4202",
        "urb4202",
        "ueb4202",
        "uab4202",
    },
    ["Stealth_Field_Generator"] = {
        "xsb4203",
        "urb4203",
        "ueb4203",
        "uab4203",
    },
    ["Heavy_Shield_Generator"] = {
        "xsb4301",
        "urb4206",
        "ueb4301",
        "uab4301",
    },
    ["Strategic_Missile_Defense"] = {
        "xsb4302",
        "urb4302",
        "ueb4302",
        "uab4302",
    },
    ["Wall_Section"] = {
        "xsb5101",
        "urb5101",
        "ueb5101",
        "uab5101",
    },
    ["Aeon_Quantum_Gate_Beacon"] = {
        "uab5103",
    },
    ["Air_Staging"] = {
        "xsb5202",
        "urb5202",
        "ueb5202",
        "uab5202",
    },
    ["Sonar_Platform"] = {
        "urs0305",
        "ues0305",
        "uas0305",
    },
    ["Quantum_Optics_Facility"] = {
        "xab3301",
    },
    ["Engineering_Station"] = {
        "xrb0104",
        "xeb0104",
    },
    ["Heavy_Point_Defense"] = {
        "xeb2306",
    },
    ["Torpedo_Ambushing_System"] = {
        "xrb2308",
    },
    ["Perimeter_Monitoring_System"] = {
        "xrb3301",
    },
    -- units
    ["T2_Guided_Missile"] = {
    "daa0206",
    },
    ["T3_Shield_Disruptor"] = {
    "dal0310",
    },
    ["T2_Fighter/Bomber"] = {
        "dea0202",
        "dra0202",
        "xsa0202",
    },
    ["T2_Gatling_Bot"] = {
        "del0204",
    },
    ["T2_Rocket_Bot"] = {
        "drl0204",
    },
    ["T1_Air_Scout"] = {
        "uaa0101",
        "uea0101",
        "ura0101",
        "xsa0101",
    },
    ["T1_Interceptor"] = {
        "uaa0102",
        "uea0102",
        "ura0102",
        "xsa0102",
    },
    ["T1_Attack_Bomber"] = {
        "uaa0103",
        "uea0103",
        "ura0103",
        "xsa0103",
    },
    ["T2_Air_Transport"] = {
        "uaa0104",
        "uea0104",
        "ura0104",
        "xsa0104",
    },
    ["T1_Light_Air_Transport"] = {
        "uaa0107",
        "uea0107",
        "ura0107",
        "xsa0107",
    },
    ["T2_Gunship"] = {
        "uaa0203",
        "uea0203",
        "ura0203",
        "xsa0203",
    },
    ["T2_Torpedo_Bomber"] = {
        "uaa0204",
        "uea0204",
        "ura0204",
        "xsa0204",
    },
    ["T3_Spy_Plane"] = {
        "uaa0302",
        "uea0302",
        "ura0302",
        "xsa0302",
    },
    ["T3_Air_Superiority_Fighter"] = {
        "uaa0303",
        "uea0303",
        "ura0303",
        "xsa0303",
    },
    ["T3_Strategic_Bomber"] = {
        "uaa0304",
        "uea0304",
        "ura0304",
        "xsa0304",
    },
    ["T1_Land_Scout"] = {
        "ual0101",
        "uel0101",
        "url0101",
    },
    ["T1_Mobile_Light_Artillery"] = {
        "ual0103",
        "uel0103",
        "url0103",
        "xsl0103",
    },
    ["T1_Mobile_Anti_Air_Gun"] = {
        "ual0104",
        "uel0104",
        "url0104",
        "xsl0104",
    },
    ["T1_Engineer"] = {
        "ual0105",
        "uel0105",
        "url0105",
        "xsl0105",
    },
    ["T1_Light_Assault_Bot"] = {
        "ual0106",
        "uel0106",
        "url0106",
    },
    ["T2_Mobile_Missile_Launcher"] = {
        "ual0111",
        "uel0111",
        "url0111",
        "xsl0111",
    },
    ["T1_Tank"] = {
        "ual0201",
        "uel0201",
        "xsl0201",
    },
    ["T2_Heavy_Tank"] = {
        "ual0202",
        "uel0202",
        "url0202",
    },
    ["T2_Mobile_AA_Flak_Artillery"] = {
        "ual0205",
        "uel0205",
        "url0205",
    },
    ["T3_Mobile_AA"] = {
        "dalk003",
        "delk002",
        "drlk001",
        "dslk004",
    },
    ["T2_Engineer"] = {
        "ual0208",
        "uel0208",
        "url0208",
        "xsl0208",
    },
    ["T3_Tank"] = {
        "ual0303",
        "xsl0303",
    },
    ["T3_Mobile_Heavy_Artillery"] = {
        "ual0304",
        "uel0304",
        "url0304",
        "xsl0304",
    },
    ["T2_Mobile_Shield_Generator"] = {
        "ual0307",
        "uel0307",
    },
    ["T3_Engineer"] = {
        "ual0309",
        "uel0309",
        "url0309",
        "xsl0309",
    },
    ["T1_Attack_Boat"] = {
        "uas0102",
    },
    ["T1_Frigate"] = {
        "uas0103",
        "ues0103",
        "urs0103",
        "xss0103",
    },
    ["T2_Destroyer"] = {
        "uas0201",
        "ues0201",
        "urs0201",
        "xss0201",
    },
    ["T2_Cruiser"] = {
        "uas0202",
        "ues0202",
        "urs0202",
        "xss0202",
    },
    ["T1_Attack_Submarine"] = {
        "uas0203",
        "ues0203",
        "urs0203",
        "xss0203",
    },
    ["T3_Battleship"] = {
        "uas0302",
        "ues0302",
        "urs0302",
        "xss0302",
    },
    ["T3_Aircraft_Carrier"] = {
        "uas0303",
        "urs0303",
        "xss0303",
    },
    ["T3_Strategic_Missile_Submarine"] = {
        "uas0304",
        "ues0304",
        "urs0304",
    },
    ["T3_Heavy_Gunship"] = {
        "uea0305",
        "xra0305",
    },
    ["T2_Amphibious_Tank"] = {
        "uel0203",
        "url0203",
    },
    ["T1_Assault_Bot"] = {
        "url0107",
    },
    ["T3_Siege_Assault_Bot"] = {
        "url0303",
        "uel0303",
    },
    ["T2_Mobile_Stealth_Field_System"] = {
        "url0306",
    },
    ["T2_Combat_Fighter"] = {
        "xaa0202",
    },
    ["T3_AA_Gunship"] = {
        "xaa0305",
    },
    ["T3_Torpedo_Bomber"] = {
        "xaa0306",
    },
    ["T2_Assault_Tank"] = {
        "xal0203",
    },
    ["T3_Sniper_Bot"] = {
        "xal0305",
        "xsl0305",
    },
    ["T2_Submarine_Hunter"] = {
        "xas0204",
    },
    ["T3_Missile_Ship"] = {
        "xas0306",
    },
    ["T3_Heavy_Air_Transport"] = {
        "xea0306",
    },
    ["T2_Field_Engineer"] = {
        "xel0209",
    },
    ["T3_Armored_Assault_Bot"] = {
        "xel0305",
        "xrl0305",
    },
    ["T3_Mobile_Missile_Platform"] = {
        "xel0306",
    },
    ["T2_Torpedo_Boat"] = {
        "xes0102",
    },
    ["T2_Shield_Boat"] = {
        "xes0205",
    },
    ["T3_Battlecruiser"] = {
        "xes0307",
    },
    ["T1_Light_Gunship"] = {
        "xra0105",
    },
    ["T2_Mobile_Bomb"] = {
        "xrl0302",
    },
    ["T2_Submarine_Killer"] = {
        "xrs0204",
    },
    ["T2_Counter_Intelligence_Boat"] = {
        "xrs0205",
    },
    ["T1_Combat_Scout"] = {
        "xsl0101",
    },
    ["T2_Assault_Bot"] = {
        "xsl0202",
    },
    ["T2_Hover_Tank"] = {
        "xsl0203",
    },
    ["T2_Mobile_Anti_Air_Cannon"] = {
        "xsl0205",
    },
    ["T3_Mobile_Shield_Generator"] = {
        "xsl0307",
    },
    ["T3_Submarine_Hunter"] = {
        "xss0304",
    },
    ["Support_Armored_Command_Unit"] = {
        "url0301",
        "ual0301",
        "uel0301",
        "xsl0301",
    }
}
