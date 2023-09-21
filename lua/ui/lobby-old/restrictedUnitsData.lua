--[[
Contains the mapping of restriction types to restriction data in the following format:

type = {
    categories = {"cat1", "cat2", etc...},
    name = "name to display in list",
    tooltip = tooltipID,
}
--]]

restrictedUnits = {
    T1 = {
        categories = {"TECH1"},
        name = "<LOC restricted_units_data_0000>No Tech 1",
        tooltip = "restricted_uints_T1",
    },
    T2 = {
        categories = {"TECH2"},
        name = "<LOC restricted_units_data_0001>No Tech 2",
        tooltip = "restricted_uints_T2",
    },
    T3 = {
        categories = {"TECH3"},
        name = "<LOC restricted_units_data_0002>No Tech 3",
        tooltip = "restricted_uints_T3",
    },
    EXPERIMENTAL = {
        categories = {"EXPERIMENTAL"},
        name = "<LOC restricted_units_data_0003>No Experimental",
        tooltip = "restricted_uints_experimental",
    },
    NAVAL = {
        categories = {"NAVAL"},
        name = "<LOC restricted_units_data_0004>No Naval",
        tooltip = "restricted_uints_naval",
    },
    LAND = {
        categories = {"LAND"},
        name = "<LOC restricted_units_data_0005>No Land",
        tooltip = "restricted_uints_land",
    },
    AIR = {
        categories = {"AIR"},
        name = "<LOC restricted_units_data_0006>No Air",
        tooltip = "restricted_uints_air",
    },
    UEF = {
        categories = {"UEF"},
        name = "<LOC restricted_units_data_0007>No UEF",
        tooltip = "restricted_uints_uef",
    },
    CYBRAN = {
        categories = {"CYBRAN"},
        name = "<LOC restricted_units_data_0008>No Cybran",
        tooltip = "restricted_uints_cybran",
    },
    AEON = {
        categories = {"AEON"},
        name = "<LOC restricted_units_data_0009>No Aeon",
        tooltip = "restricted_uints_aeon",
    },
    SERAPHIM = {
        categories = {"SERAPHIM"},
        name = "<LOC restricted_units_data_0010>No Seraphim",
        tooltip = "restricted_uints_seraphim",
    },
    NUKE = {
        categories = {"uab2305", "ueb2305", "urb2305", "xsb2305", "xsb2401", "xss0302", "xsb4302", "ueb4302", "urb4302", "uab4302", "uas0304", "urs0304", "ues0304" },
        name = "<LOC restricted_units_data_0011>No Nukes",
        tooltip = "restricted_uints_nukes",
    },
    GAMEENDERS = {
        categories = {"uab2302", "urb2302", "ueb2302", "xsb2302", "xab1401", "xab2307", "url0401", "xeb2402", "ueb2401", "xsb2401"},
        name = "<LOC restricted_units_data_0012>No Game Enders",
        tooltip = "restricted_uints_gameenders",
    },
    BUBBLES = {
        categories = {"uel0307", "ual0307", "xsl0307", "deb4303", "xes0205", "ueb4202", "urb4202", "uab4202", "xsb4202", "ueb4301", "uab4301", "xsb4301", },
        name = "<LOC restricted_units_data_0013>No Bubbles",
        tooltip = "restricted_uints_bubbles",
    },
    INTEL = {
        categories = {"OMNI", "uab3101", "uab3201", "ueb3101", "ueb3201", "urb3101", "urb3201", "xsb3101", "xsb3201", "uab3102", "uab3202", "ueb3102", "ueb3202", "urb3102", "urb3202", "xsb3102", "xsb3202", "xab3301", "xrb3301", "ues0305", "uas0305", "urs0305", },
        name = "<LOC restricted_units_data_0014>No Intel Structures",
        tooltip = "restricted_uints_intel",
    },
    SUPCOM = {
        categories = {"SUBCOMMANDER", },
        name = "<LOC restricted_units_data_0015>No Support Commanders",
        tooltip = "restricted_uints_supcom",
    },
    PRODSC1 = {
        categories = {"PRODUCTSC1", },
        name = "<LOC restricted_units_data_0016>No Supreme Commander",
        tooltip = "restricted_units_supremecommander",
    },
    PRODFA = {
        categories = {"PRODUCTFA", },
        name = "<LOC restricted_units_data_0017>No Forged Alliance",
        tooltip = "restricted_units_forgedalliance",
    },
    PRODDL = {
        categories = {"PRODUCTDL", },
        name = "<LOC restricted_units_data_0018>No Downloaded",
        tooltip = "restricted_units_downloaded",
    },
    FABS = {
        categories = {"ueb1104", "ueb1303", "urb1104", "urb1303", "uab1104", "uab1303", "xsb1104", "xsb1303", },
        name = "<LOC restricted_units_data_0019>No Mass Fabrication",
        tooltip = "restricted_units_massfab",
    },
}

sortOrder = {
    "GAMEENDERS",
    "NUKE",
    "PRODSC1",
    "PRODFA",
    "PRODDL",
    "UEF",
    "CYBRAN",
    "AEON",
    "SERAPHIM",
    "T1",
    "T2",
    "T3",
    "EXPERIMENTAL",
    "NAVAL",
    "LAND",
    "AIR",
    "BUBBLES",
    "INTEL",
    "SUPCOM",
    "FABS",
}