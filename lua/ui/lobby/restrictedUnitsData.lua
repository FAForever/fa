-----------------------------------------------------------------------------------------
-- Contains the mapping of restriction types to restriction data in the following format:
--  type = {
--      categoryExpression = {"cat1 + cat2", etc...},
--      name = "name to display in list",
--      tooltip = tooltipID,
--  }
-- 
-- You can get the UnitID here : http://content.faforever.com/faf/unitsDB/
-----------------------------------------------------------------------------------------
-- The categories object only exists in the sim, so here we store a representation of the category
-- expression we want to have constructed later.
-- It appears ParseEntityCategory can't handle subtraction :/

restrictedUnits = {    
    T1 = {
        categoryExpression = "TECH1",
        name = "<LOC restricted_units_data_0000>No Tech 1",
        tooltip = "restricted_units_T1",
    },
    T2 = {
        categoryExpression = "TECH2",
        name = "<LOC restricted_units_data_0001>No Tech 2",
        tooltip = "restricted_units_T2",
    },
    T3 = {
        categoryExpression = "TECH3",
        name = "<LOC restricted_units_data_0002>No Tech 3",
        tooltip = "restricted_units_T3",
    },
    EXPERIMENTAL = {
        categoryExpression = "EXPERIMENTAL",
        name = "<LOC restricted_units_data_0003>No Experimentals",
        tooltip = "restricted_units_experimental",
    },
    LAND = {
        categoryExpression = "LAND",
        name = "<LOC restricted_units_data_0005>No Land",
        tooltip = "restricted_units_land",
    },
    AIR = {
        categoryExpression = "AIR",
        name = "<LOC restricted_units_data_0006>No Air",
        tooltip = "restricted_units_air",
    },
    NAVAL = {
        categoryExpression = "NAVAL",
        name = "<LOC restricted_units_data_0004>No Naval",
        tooltip = "restricted_units_naval",
    },
    UEF = {
        categoryExpression = "UEF",
        name = "<LOC restricted_units_data_0007>No UEF",
        tooltip = "restricted_units_uef",
    },
    CYBRAN = {
        categoryExpression = "CYBRAN",
        name = "<LOC restricted_units_data_0008>No Cybran",
        tooltip = "restricted_units_cybran",
    },
    AEON = {
        categoryExpression = "AEON",
        name = "<LOC restricted_units_data_0009>No Aeon",
        tooltip = "restricted_units_aeon",
    },
    SERAPHIM = {
        categoryExpression = "SERAPHIM",
        name = "<LOC restricted_units_data_0010>No Seraphim",
        tooltip = "restricted_units_seraphim",
    },
    NUKE = {
        categoryExpression = "uab2305 + ueb2305 + urb2305 + xsb2305 + xsb2401 + xss0302 + xsb4302 + ueb4302 + urb4302 + uab4302 + uas0304 + urs0304 + ues0304",
        name = "<LOC restricted_units_data_0011>No Nukes",
        tooltip = "restricted_units_nukes",
    },
    GAMEENDERS = {
                                ---ArtyAEO---ArtyUEF---ArtyCYB-------ArtySER-----Paragon----Salvation---Scathis------Satellite------Mavor---Yolona Oss
        categoryExpression = "uab2302 + urb2302 + ueb2302 + xsb2302 + xab1401 + xab2307 + url0401 + xeb2402 + ueb2401 + xsb2401",
        name = "<LOC restricted_units_data_0012>No Game Enders",
        tooltip = "restricted_units_gameenders",
    },
    BUBBLES = {
        categoryExpression = "uel0307 + ual0307 + xsl0307 + xes0205 + ueb4202 + urb4202 + uab4202 + xsb4202 + ueb4301 + uab4301 + xsb4301",
        name = "<LOC restricted_units_data_0013>No Bubble Shields",
        tooltip = "restricted_units_bubbles",
    },
    INTEL = {
        categoryExpression = "OMNI + uab3101 + uab3201 + ueb3101 + ueb3201 + urb3101 + urb3201 + xsb3101 + xsb3201 + uab3102 + uab3202 + ueb3102 + ueb3202 + urb3102 + urb3202 + xsb3102 + xsb3202 + xab3301 + xrb3301 + ues0305 + uas0305 + urs0305",
        name = "<LOC restricted_units_data_0014>No Intel Structures",
        tooltip = "restricted_units_intel",
    },
    SUPCOM = {
        categoryExpression = "SUBCOMMANDER",
        name = "<LOC restricted_units_data_0015>No Support Commanders",
        tooltip = "restricted_units_supcom",
    },
    PRODSC1 = {
        categoryExpression = "PRODUCTSC1",
        name = "<LOC restricted_units_data_0016>No Vanilla",
        tooltip = "restricted_units_supremecommander",
    },
    PRODFA = {
        categoryExpression = "PRODUCTFA",
        name = "<LOC restricted_units_data_0017>No Forged Alliance",
        tooltip = "restricted_units_forgedalliance",
    },
    PRODDL = {
        categoryExpression = "PRODUCTDL",
        name = "<LOC restricted_units_data_0018>No Downloaded",
        tooltip = "restricted_units_downloaded",
    },
    FABS = {
        categoryExpression = "ueb1104 + ueb1303 + urb1104 + urb1303 + uab1104 + uab1303 + xsb1104 + xsb1303",
        name = "<LOC restricted_units_data_0019>No Mass Fabrication",
        tooltip = "restricted_units_massfab",
    },
    -- Added for FAF
    SUPPFAC = {
        categoryExpression = "SUPPORTFACTORY",
        name = "<LOC restricted_units_data_0020>No Support Factories",
        tooltip = "restricted_units_supportfactory",
    },
    T3MOBILEAA = {
        categoryExpression = "dalk003 + delk002 + drlk001 + drlk005 + dslk004",
        name = "<LOC restricted_units_data_0021>No T3 Mobile Anti-Air",
        tooltip = "restricted_units_t3mobileaa",
    },
    WALL = {
        categoryExpression = "WALL",
        name = "<LOC restricted_units_data_022>No Walls",
        tooltip = "restricted_units_wall",
    },
    ENGISTATION = {
        categoryExpression = "xeb0104 + xrb0104",
        name = "<LOC restricted_units_data_023>No Engineering Stations",
        tooltip = "restricted_units_engineeringstation",
    },
    SUPERGAMEENDERS = {
        categoryExpression = "xab2307 + ueb2401 + url0401 + xsb2401",
        name = "<LOC restricted_units_data_024>No Super-Game-Enders",
        tooltip = "restricted_units_superarty",
    },
    PARAGON = {
        categoryExpression = "xab1401",
        name = "<LOC restricted_units_data_025>No Paragon",
        tooltip = "restricted_units_paragon",
    },
    SATELLITE = {
        categoryExpression = "xeb2402",
        name = "<LOC restricted_units_data_026>No Satellite",
        tooltip = "restricted_units_satellite",
    },
    TELE = {
        enhancement = {"Teleporter", "TeleporterRemove"},
        name = "<LOC restricted_units_data_027>No Teleporting",
        tooltip = "restricted_units_teleport",
    },
    BILLY = {
        enhancement = {"TacticalNukeMissile", "TacticalNukeMissileRemove"},
        name = "<LOC restricted_units_data_028>No Billy",
        tooltip = "restricted_units_billy",
    },
    EYE = {
        categoryExpression = "xab3301 + xrb3301",
        name = "<LOC restricted_units_data_029>No Super-Intel",
        tooltip = "restricted_units_eye"
    },
}

sortOrder = {
    "T1",
    "T2",
    "T3",
    "EXPERIMENTAL",
    "LAND",
    "AIR",
    "NAVAL",
    "UEF",
    "CYBRAN",
    "AEON",
    "SERAPHIM",
    "NUKE",
    "GAMEENDERS",    
    "BUBBLES",
    "INTEL",
    "SUPCOM",
    "PRODSC1",
    "PRODFA",
    "PRODDL",
    "FABS",
    "SUPPFAC",
    "T3MOBILEAA",
    "WALL",
    "ENGISTATION",
    "SUPERGAMEENDERS",
    "PARAGON",
    "SATELLITE",    
    "TELE",
    "BILLY",
    "EYE",
}

