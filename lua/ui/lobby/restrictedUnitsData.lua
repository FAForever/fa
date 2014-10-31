-----------------------------------------------------------------------------------------
-- Contains the mapping of restriction types to restriction data in the following format:
--  type = {
--      categories = {"cat1", "cat2", etc...},
--      name = "name to display in list",
--      tooltip = tooltipID,
--  }
-- 
-- You can get the UnitID here : http://content.faforever.com/faf/unitsDB/
-----------------------------------------------------------------------------------------

restrictedUnits = {
    EYED = {
	    categories = {"xab3301", "xrb3301"},
        name = "No Eye of Rhianne and Soothsayer",
        tooltip = {text='No Eye of Rhianne and Soothsayer', body='Remove the T3 Optics Aeon and T3 Perimeter Cybran (by Xinnony)'},
    },
	TRYENGISTATION = {
        categories = {"xeb0104", "xrb0104"},
		enhancement = {"LeftPod", "RightPod", "LeftPodRemove", "RightPodRemove", "Pod", "PodRemove"},
        name = "TRY No Engineering Station + Enhancement Drone (SACU NOT WORK)",
        tooltip = {text='TRY No Engineering Station + Enhancement Drone (SACU NOT WORK)', body='Remove Kennel, Hive and Drone S/ACU [SACU NOT WORK] (by Xinnony)'},
        --"No Kennel and Hive (Engineering Station) by Xinnony",
    },
	ENGISTATION = {
        categories = {"xeb0104", "xrb0104"},
        name = "<LOC restricted_units_data_023>No Engineering Stations",
        tooltip = {text = 'No Engineering Stations', body = 'Removes the Kennel and Hive'},
    },
    SALVAMAVOSCATH = {
        categories = {"xab2307", "ueb2401", "url0401"},
        name = "<LOC restricted_units_data_024>No Super-Artillery",
        tooltip = {text = 'No Super-Artillery', body = 'Removes Salvation, Mavor and Scathis'},
    },
    PARAGON = {
        categories = {"xab1401"},
        name = "<LOC restricted_units_data_025>No Paragon",
        tooltip = {text = 'No Paragon', body = 'Removes the Paragon, the Aeon Experimental Infinite Resource Generator'},
    },
    SATELLITE = {
        categories = {"xeb2402"},
        name = "<LOC restricted_units_data_026>No Satellite",
        tooltip = {text = 'No Satellite', body = 'Removes the UEF Novax Satellite'},
    },
    TELE = {
        enhancement = {"Teleporter", "TeleporterRemove"},
        name = "<LOC restricted_units_data_027>No Teleporting",
        tooltip = {text = 'No Teleporting', body = 'Removes the ability to upgrade ACUs and sACUs with Teleporters'},
    },
    BILLY = {
        enhancement = {"TacticalNukeMissile", "TacticalNukeMissileRemove"},
        name = "<LOC restricted_units_data_028>No Billy",
        tooltip = {text = 'No Billy', body = 'Prevents UEF commanders from upgrading their ACU to have the "billy" tactical nuke upgrade'},
    },
    T1 = {
        categories = {"TECH1"},
        name = "<LOC restricted_units_data_0000>No Tech 1",
        tooltip = {text = 'No Tech 1', body = 'Prevents all T1 units being built'},
    },
    T2 = {
        categories = {"TECH2"},
        name = "<LOC restricted_units_data_0001>No Tech 2",
        tooltip = {text = 'No Tech 2', body = 'Prevents all T2 units being built'},
    },
    T3 = {
        categories = {"TECH3"},
        name = "<LOC restricted_units_data_0002>No Tech 3",
        tooltip = {text = 'No Tech 3', body = 'Prevents all T3 units being built'},
    },
    EXPERIMENTAL = {
        categories = {"EXPERIMENTAL"},
        name = "<LOC restricted_units_data_0003>No Experimentals",
        tooltip = {text = 'No Experimental', body = 'Prevents all Experimentals being built'},
    },
    NAVAL = {
        categories = {"NAVAL"},
        name = "<LOC restricted_units_data_0004>No Naval",
        tooltip = {text = 'No Naval', body = 'Prevents all Naval units being built'},
    },
    LAND = {
        categories = {"LAND"},
        name = "<LOC restricted_units_data_0005>No Land",
        tooltip = {text = 'No Land', body = 'Prevents all Land units being built'},
    },
    AIR = {
        categories = {"AIR"},
        name = "<LOC restricted_units_data_0006>No Air",
        tooltip = {text = 'No Air', body = 'Prevents all Air units being built. Does not count UEF Novax Satellite'},
    },
    UEF = {
        categories = {"UEF"},
        name = "<LOC restricted_units_data_0007>No UEF",
        tooltip = {text = 'No UEF', body = 'Prevents all UEF units being built'},
    },
    CYBRAN = {
        categories = {"CYBRAN"},
        name = "<LOC restricted_units_data_0008>No Cybran",
        tooltip = {text = 'No Cybran', body = 'Prevents all Cybran units being built'},
    },
    AEON = {
        categories = {"AEON"},
        name = "<LOC restricted_units_data_0009>No Aeon",
        tooltip = {text = 'No UEF', body = 'Prevents all Aeon units being built'},
    },
    SERAPHIM = {
        categories = {"SERAPHIM"},
        name = "<LOC restricted_units_data_0010>No Seraphim",
        tooltip = {text = 'No UEF', body = 'Prevents all Seraphim units being built'},
    },
    NUKE = {
        categories = {"uab2305", "ueb2305", "urb2305", "xsb2305", "xsb2401", "xss0302", "xsb4302", "ueb4302", "urb4302", "uab4302", "uas0304", "urs0304", "ues0304"},
        name = "<LOC restricted_units_data_0011>No Nukes",
        tooltip = {text = 'No Nukes', body = 'Prevents all Nukes being built, apart from the UEF "Billy" nuke'},
    },
    GAMEENDERS = {
                                ---ArtyAEO---ArtyUEF---ArtyCYB-------ArtySER-----Paragon----Salvation---Scathis------Satellite------Mavor---Yolona Oss
        categories = {"uab2302", "urb2302", "ueb2302", "xsb2302", "xab1401", "xab2307", "url0401", "xeb2402", "ueb2401", "xsb2401"},
        name = "<LOC restricted_units_data_0012>No Game Enders",
        tooltip = {text = 'No Game Enders', body = 'Restricts access to Heavy Artilley, Paragon, Novax Satellite and Yolona Oss'},
    },
    BUBBLES = {
        categories = {"uel0307", "ual0307", "xsl0307", "xes0205", "ueb4202", "urb4202", "uab4202", "xsb4202", "ueb4301", "uab4301", "xsb4301"},
        name = "<LOC restricted_units_data_0013>No Bubble Shields",
        tooltip = {text = 'No Bubble Shields', body = 'Removes all non-upgrade Bubble Shields'},
    },
    INTEL = {
        categories = {"OMNI", "uab3101", "uab3201", "ueb3101", "ueb3201", "urb3101", "urb3201", "xsb3101", "xsb3201", "uab3102", "uab3202", "ueb3102", "ueb3202", "urb3102", "urb3202", "xsb3102", "xsb3202", "xab3301", "xrb3301", "ues0305", "uas0305", "urs0305"},
        name = "<LOC restricted_units_data_0014>No Intel Structures",
        tooltip = {text = 'No Intel Structures', body = 'Prevents players from constructing Sonar, Radar, or Stealth structures'},
    },
    SUPCOM = {
        categories = {"SUBCOMMANDER"},
        name = "<LOC restricted_units_data_0015>No Support Commanders",
        tooltip = {text = 'No Support Commanders', body = 'Prevents players from summoning Support Armored Command Units'},
    },
    PRODSC1 = {
        categories = {"PRODUCTSC1"},
        name = "<LOC restricted_units_data_0016>No Vanilla",
        tooltip = {text = 'No Vanilla', body = 'Removes all units which were found in the original Supreme Commander'},
    },
    PRODFA = {
        categories = {"PRODUCTFA"},
        name = "<LOC restricted_units_data_0017>No Forged Alliance",
        tooltip = {text = 'No Forged Alliance', body = 'Removes all units which were introduced in the Forged Alliance expansion'},
    },
    PRODDL = {
        categories = {"PRODUCTDL"},
        name = "<LOC restricted_units_data_0018>No Downloaded",
        tooltip = {text = 'No Downloaded', body = 'Prevents players building units introduced as DLC'},
    },
    FABS = {
        categories = {"ueb1104", "ueb1303", "urb1104", "urb1303", "uab1104", "uab1303", "xsb1104", "xsb1303"},
        name = "<LOC restricted_units_data_0019>No Mass Fabrication",
        tooltip = {text = 'No Mass Fabrication', body = 'Prevents players building Mass Fabricators'},
    },
    SUPPFAC = {
        categories = {"SUPPORTFACTORY"},
        name = "<LOC restricted_units_data_0020>No Support Factories",
        tooltip = {text = 'No Support Factories', body = 'Prevents players from building fresh Support Factories, effectively disabling the "Engiemod" changes'},
    },
    T3MOBILEAA = {
        categories = {"dalk003","delk002", "drlk001", "drlk005", "dslk004"},
        name = "<LOC restricted_units_data_0021>No T3 Mobile Anti-Air",
        tooltip = {text = 'No T3 Mobile Anti-Air', body = 'Prevents players being able to build the new T3 MAA units'},
    },
    WALL = {
        categories = {"WALL"},
        name = "<LOC restricted_units_data_022>No Walls",
        tooltip = {text = 'No Walls', body = 'Prevents players being able to build Walls'},
    },
}

sortOrder = {
    "GAMEENDERS",
    "NUKE",
    "T3MOBILEAA",
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
    "SUPPFAC",
    "TELE",
    "BILLY",
    "ENGISTATION",
    "SALVAMAVOSCATH",
    "PARAGON",
    "SATELLITE",
    "WALL",
	"TRYENGISTATION",
	"EYED",
}
