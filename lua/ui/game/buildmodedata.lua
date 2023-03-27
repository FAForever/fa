-- Maps specific builders to what keys will do in build mode

local AeonT1Eng = {
    ['L'] = 'uab0101',
    ['A'] = 'uab0102',
    ['S'] = 'uab0103',
    ['E'] = 'uab1103',
    ['X'] = 'uab1106',
    ['P'] = 'uab1101',
    ['H'] = 'uab1102',
    ['Y'] = 'uab1105',
    ['W'] = 'uab5101',
    ['D'] = 'uab2101',
    ['N'] = 'uab2104',
    ['T'] = 'uab2109',
    ['I'] = 'uab3101',
    ['O'] = 'uab3102',
    ['G'] = 'uab5202',
}

local AeonT2Eng = {
    ['L'] = 'zab9501',
    ['A'] = 'zab9502',
    ['S'] = 'zab9503',
    ['E'] = 'uab1202',
    ['P'] = 'uab1201',
    ['D'] = 'uab2301',
    ['N'] = 'uab2204',
    ['F'] = 'uab1104',
    ['T'] = 'uab2205',
    ['R'] = 'uab2303',
    ['M'] = 'uab2108',
    ['K'] = 'uab4201',
    ['V'] = 'uab4202',
    ['C'] = 'uab4203',
    ['I'] = 'uab3201',
    ['O'] = 'uab3202',
}

local AeonT3Eng = {
    ['L'] = 'zab9601',
    ['A'] = 'zab9602',
    ['S'] = 'zab9603',
    ['E'] = 'uab1302',
    ['D'] = 'xab2307',
    ['C'] = 'xab3301',
    ['F'] = 'uab1303',
    ['P'] = 'uab1301',
    ['N'] = 'uab2304',
    ['R'] = 'uab2302',
    ['M'] = 'uab2305',
    ['K'] = 'uab4302',
    ['V'] = 'uab4301',
    ['O'] = 'uas0305',
    ['I'] = 'uab3104',
    ['Q'] = 'uab0304',
}

local AeonT4Eng = {
    ['Z'] = 'uaa0310',
    ['Q'] = 'xab1401',
    ['T'] = 'uas0401',
    ['C'] = 'ual0401',
}

local AeonT1Land = {
    ['E'] = 'ual0105',
    ['S'] = 'ual0101',
    ['O'] = 'ual0106',
    ['T'] = 'ual0201',
    ['R'] = 'ual0103',
    ['N'] = 'ual0104',
}

local AeonT2Land = {
    ['A'] = 'xal0203',
    ['E'] = 'ual0208',
    ['T'] = 'ual0202',
    ['M'] = 'ual0111',
    ['N'] = 'ual0205',
    ['V'] = 'ual0307',
}

local AeonT3Land = {
    ['D'] = 'dal0310',
    ['S'] = 'xal0305',
    ['E'] = 'ual0309',
    ['O'] = 'ual0303',
    ['R'] = 'ual0304',
	['N'] = 'dalk003',
}

local AeonT1Air = {
    ['E'] = 'ual0105',
    ['S'] = 'uaa0101',
    ['F'] = 'uaa0102',
    ['O'] = 'uaa0103',
    ['T'] = 'uaa0107',
}

local AeonT2Air = {
    ['E'] = 'ual0208',
    ['X'] = 'daa0206',
    ['F'] = 'xaa0202',
    ['P'] = 'uaa0204',
    ['G'] = 'uaa0203',
    ['T'] = 'uaa0104',
}

local AeonT3Air = {
    ['A'] = 'xaa0305',
    ['P'] = 'xaa0306',
    ['E'] = 'ual0309',
    ['S'] = 'uaa0302',
    ['F'] = 'uaa0303',
    ['O'] = 'uaa0304',
}

local AeonT1Sea = {
    ['E'] = 'ual0105',
    ['T'] = 'uas0102',
    ['S'] = 'uas0203',
    ['F'] = 'uas0103',
}

local AeonT2Sea = {
    ['E'] = 'ual0208',
    ['S'] = 'xas0204',
    ['C'] = 'uas0202',
    ['D'] = 'uas0201',
}

local AeonT3Sea = {
    ['E'] = 'ual0309',
    ['T'] = 'uas0302',
    ['M'] = 'xas0306',
    ['A'] = 'uas0303',
    ['S'] = 'uas0304',
}

local UEFT1Eng = {
    ['L'] = 'ueb0101',
    ['A'] = 'ueb0102',
    ['S'] = 'ueb0103',
    ['E'] = 'ueb1103',
    ['X'] = 'ueb1106',
    ['P'] = 'ueb1101',
    ['H'] = 'ueb1102',
    ['Y'] = 'ueb1105',
    ['W'] = 'ueb5101',
    ['D'] = 'ueb2101',
    ['N'] = 'ueb2104',
    ['T'] = 'ueb2109',
    ['I'] = 'ueb3101',
    ['O'] = 'ueb3102',
    ['G'] = 'ueb5202',
}

local UEFT2Eng = {
    ['L'] = 'zeb9501',
    ['A'] = 'zeb9502',
    ['S'] = 'zeb9503',
    ['Q'] = 'xeb0104',
    ['E'] = 'ueb1202',
    ['P'] = 'ueb1201',
    ['D'] = 'ueb2301',
    ['N'] = 'ueb2204',
    ['F'] = 'ueb1104',
    ['T'] = 'ueb2205',
    ['R'] = 'ueb2303',
    ['M'] = 'ueb2108',
    ['K'] = 'ueb4201',
    ['V'] = 'ueb4202',
    ['C'] = 'ueb4203',
    ['I'] = 'ueb3201',
    ['O'] = 'ueb3202',
}
 
local UEFT3Eng = {
    ['L'] = 'zeb9601',
    ['A'] = 'zeb9602',
    ['S'] = 'zeb9603',    
    ['D'] = 'xeb2306',
    ['E'] = 'ueb1302',
    ['F'] = 'ueb1303',
    ['P'] = 'ueb1301',
    ['N'] = 'ueb2304',
    ['R'] = 'ueb2302',
    ['M'] = 'ueb2305',
    ['K'] = 'ueb4302',
    ['V'] = 'ueb4301',
    ['O'] = 'ues0305',
    ['I'] = 'ueb3104',
    ['Q'] = 'ueb0304',
}

local UEFT4Eng = {
    ['S'] = 'xeb2402',
    ['F'] = 'uel0401',
    ['A'] = 'ues0401',
    ['M'] = 'ueb2401',
}

local UEFT1Land = {
    ['E'] = 'uel0105',
    ['S'] = 'uel0101',
    ['O'] = 'uel0106',
    ['T'] = 'uel0201',
    ['R'] = 'uel0103',
    ['N'] = 'uel0104',
}

local UEFT2Land = {
    ['O'] = 'del0204',
    ['E'] = 'uel0208',
    ['F'] = 'xel0209',
    ['T'] = 'uel0202',
    ['M'] = 'uel0111',
    ['N'] = 'uel0205',
    ['P'] = 'uel0203',
    ['V'] = 'uel0307',
}

local UEFT3Land = {
    ['A'] = 'xel0305',
    ['M'] = 'xel0306',
    ['E'] = 'uel0309',
    ['O'] = 'uel0303',
    ['R'] = 'uel0304',
    ['N'] = 'delk002',
}

local UEFT1Air = {
    ['E'] = 'uel0105',
    ['S'] = 'uea0101',
    ['F'] = 'uea0102',
    ['O'] = 'uea0103',
    ['T'] = 'uea0107',
}

local UEFT2Air = {
    ['J'] = 'dea0202',
    ['F'] = 'xel0209',
    ['E'] = 'uel0208',
    ['P'] = 'uea0204',
    ['G'] = 'uea0203',
    ['T'] = 'uea0104',
}

local UEFT3Air = {
    ['T'] = 'xea0306',
    ['E'] = 'uel0309',
    ['S'] = 'uea0302',
    ['F'] = 'uea0303',
    ['O'] = 'uea0304',
    ['G'] = 'uea0305',
}

local UEFT1Sea = {
    ['O'] = 'xes0102',
    ['E'] = 'uel0105',
    ['S'] = 'ues0203',
    ['F'] = 'ues0103',
}

local UEFT2Sea = {
    ['V'] = 'xes0205',
    ['E'] = 'uel0208',
    ['F'] = 'xel0209',
    ['O'] = 'xes0102',
    ['C'] = 'ues0202',
    ['D'] = 'ues0201',
}

local UEFT3Sea = {
    ['D'] = 'xes0307',
    ['E'] = 'uel0309',
    ['T'] = 'ues0302',
    ['S'] = 'ues0304',
}

local CybranT1Eng = {
    ['L'] = 'urb0101',
    ['A'] = 'urb0102',
    ['S'] = 'urb0103',
    ['E'] = 'urb1103',
    ['X'] = 'urb1106',
    ['P'] = 'urb1101',
    ['H'] = 'urb1102',
    ['Y'] = 'urb1105',
    ['W'] = 'urb5101',
    ['D'] = 'urb2101',
    ['N'] = 'urb2104',
    ['T'] = 'urb2109',
    ['I'] = 'urb3101',
    ['O'] = 'urb3102',
    ['G'] = 'urb5202',
}

local CybranT2Eng = {
    ['L'] = 'zrb9501',
    ['A'] = 'zrb9502',
    ['S'] = 'zrb9503',     
    ['Q'] = 'xrb0104',
    ['E'] = 'urb1202',
    ['P'] = 'urb1201',
    ['D'] = 'urb2301',
    ['N'] = 'urb2204',
    ['T'] = 'urb2205',
    ['R'] = 'urb2303',
    ['F'] = 'urb1104',
    ['M'] = 'urb2108',
    ['K'] = 'urb4201',
    ['V'] = 'urb4202',
    ['C'] = 'urb4203',
    ['I'] = 'urb3201',
    ['O'] = 'urb3202',
}

local CybranT3Eng = {
    ['L'] = 'zrb9601',
    ['A'] = 'zrb9602',
    ['S'] = 'zrb9603',      
    ['C'] = 'xrb3301',
    ['T'] = 'xrb2308',
    ['E'] = 'urb1302',
    ['F'] = 'urb1303',
    ['P'] = 'urb1301',
    ['N'] = 'urb2304',
    ['R'] = 'urb2302',
    ['M'] = 'urb2305',
    ['K'] = 'urb4302',
    ['V'] = 'urb4206',
    ['O'] = 'urs0305',
    ['I'] = 'urb3104',
    ['Q'] = 'urb0304',
}

local CybranT4Eng = {
    ['S'] = 'url0402',
    ['M'] = 'xrl0403',
    ['R'] = 'ura0401',
    ['C'] = 'url0401',
}

local CybranT1Land = {
    ['E'] = 'url0105',
    ['S'] = 'url0101',
    ['O'] = 'url0106',
    ['T'] = 'url0107',
    ['R'] = 'url0103',
    ['N'] = 'url0104',
}

local CybranT2Land = {
    ['X'] = 'xrl0302',
    ['E'] = 'url0208',
    ['T'] = 'url0202',
    ['M'] = 'url0111',
    ['O'] = 'drl0204',
    ['N'] = 'url0205',
    ['P'] = 'url0203',
    ['C'] = 'url0306',
}

local CybranT3Land = {
    ['A'] = 'xrl0305',
    ['E'] = 'url0309',
    ['O'] = 'url0303',
    ['R'] = 'url0304',
	['N'] = 'drlk001',
}

local CybranT1Air = {
    ['G'] = 'xra0105',
    ['E'] = 'url0105',
    ['S'] = 'ura0101',
    ['F'] = 'ura0102',
    ['O'] = 'ura0103',
    ['T'] = 'ura0107',
}

local CybranT2Air = {
    ['F'] = 'dra0202',
    ['E'] = 'url0208',
    ['P'] = 'ura0204',
    ['G'] = 'ura0203',
    ['T'] = 'ura0104',
}

local CybranT3Air = {
    ['G'] = 'xra0305',
    ['E'] = 'url0309',
    ['S'] = 'ura0302',
    ['F'] = 'ura0303',
    ['O'] = 'ura0304',
}

local CybranT1Sea = {
    ['I'] = 'drs0102',
    ['E'] = 'url0105',
    ['S'] = 'urs0203',
    ['F'] = 'urs0103',
}

local CybranT2Sea = {
    ['S'] = 'xrs0204',
    ['I'] = 'xrs0205',
    ['E'] = 'url0208',
    ['C'] = 'urs0202',
    ['D'] = 'urs0201',
}

local CybranT3Sea = {
    ['E'] = 'url0309',
    ['T'] = 'urs0302',
    ['A'] = 'urs0303',
    ['S'] = 'urs0304',
}

local CybranCrabBot = {
    ['E'] = 'xrl0002',
    ['A'] = 'xrl0003',
    ['R'] = 'xrl0005',
    ['N'] = 'drlk001',
}

local SeraphimT1Eng = {
    ['L'] = 'xsb0101',
    ['A'] = 'xsb0102',
    ['S'] = 'xsb0103',
    ['E'] = 'xsb1103',
    ['X'] = 'xsb1106',
    ['P'] = 'xsb1101',
    ['H'] = 'xsb1102',
    ['Y'] = 'xsb1105',
    ['W'] = 'xsb5101',
    ['D'] = 'xsb2101',
    ['N'] = 'xsb2104',
    ['T'] = 'xsb2109',
    ['I'] = 'xsb3101',
    ['O'] = 'xsb3102',
    ['G'] = 'xsb5202',
}

local SeraphimT2Eng = {
    ['L'] = 'zsb9501',
    ['A'] = 'zsb9502',
    ['S'] = 'zsb9503',    
    ['E'] = 'xsb1202',
    ['P'] = 'xsb1201',
    ['D'] = 'xsb2301',
    ['N'] = 'xsb2204',
    ['T'] = 'xsb2205',
    ['R'] = 'xsb2303',
    ['M'] = 'xsb2108',
    ['F'] = 'xsb1104',
    ['K'] = 'xsb4201',
    ['V'] = 'xsb4202',
    ['C'] = 'xsb4203',
    ['I'] = 'xsb3201',
    ['O'] = 'xsb3202',
}

local SeraphimT3Eng = {
    ['L'] = 'zsb9601',
    ['A'] = 'zsb9602',
    ['S'] = 'zsb9603',  
    ['E'] = 'xsb1302',
    ['F'] = 'xsb1303',
    ['P'] = 'xsb1301',
    ['N'] = 'xsb2304',
    ['R'] = 'xsb2302',
    ['M'] = 'xsb2305',
    ['K'] = 'xsb4302',
    ['O'] = 'xss0305',
    ['V'] = 'xsb4301',
    ['I'] = 'xsb3104',
    ['Q'] = 'xsb0304',
}

local SeraphimT4Eng = {
    ['M'] = 'xsb2401',
    ['B'] = 'xsa0402',
    ['O'] = 'xsl0401',
}

local SeraphimT1Land = {
    ['E'] = 'xsl0105',
    ['S'] = 'xsl0101',
    ['O'] = 'xsl0106',
    ['T'] = 'xsl0201',
    ['R'] = 'xsl0103',
    ['N'] = 'xsl0104',
}

local SeraphimT2Land = {
    ['E'] = 'xsl0208',
    ['T'] = 'xsl0202',
    ['M'] = 'xsl0111',
    ['N'] = 'xsl0205',
    ['P'] = 'xsl0203',
    ['C'] = 'xsl0306',
}

local SeraphimT3Land = {
    ['E'] = 'xsl0309',
    ['O'] = 'xsl0303',
    ['R'] = 'xsl0304',
    ['S'] = 'xsl0305',
    ['V'] = 'xsl0307',
	['N'] = 'dslk004',
}

local SeraphimT1Air = {
    ['E'] = 'xsl0105',
    ['S'] = 'xsa0101',
    ['F'] = 'xsa0102',
    ['O'] = 'xsa0103',
    ['T'] = 'xsa0107',
}

local SeraphimT2Air = {
    ['E'] = 'xsl0208',
    ['P'] = 'xsa0204',
    ['G'] = 'xsa0203',
    ['F'] = 'xsa0202',
    ['T'] = 'xsa0104',
}

local SeraphimT3Air = {
    ['E'] = 'xsl0309',
    ['S'] = 'xsa0302',
    ['F'] = 'xsa0303',
    ['O'] = 'xsa0304',
}

local SeraphimT1Sea = {
    ['E'] = 'xsl0105',
    ['S'] = 'xss0203',
    ['F'] = 'xss0103',
}

local SeraphimT2Sea = {
    ['E'] = 'xsl0208',
    ['C'] = 'xss0202',
    ['D'] = 'xss0201',
}

local SeraphimT3Sea = {
    ['E'] = 'xsl0309',
    ['T'] = 'xss0302',
    ['A'] = 'xss0303',
    ['S'] = 'xss0304',
}

buildModeKeys = {
--Aeon
    -- commander
    ['ual0001'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander
    ['ual0301'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },    
    -- subcommander - ras preset
    ['ual0301_ras'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander - combatant preset
    ['ual0301_simplecombat'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander - engineer preset
    ['ual0301_engineer'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander - nano combatant preset
    ['ual0301_nanocombat'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander - shield combatant preset
    ['ual0301_shieldcombat'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- subcommander - rambo preset
    ['ual0301_rambo'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- T1 engineer
    ['ual0105'] = {
        [1] = AeonT1Eng,
    },
    -- T2 engineer
    ['ual0208'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
    },
    -- T3 engineer
    ['ual0309'] = {
        [1] = AeonT1Eng,
        [2] = AeonT2Eng,
        [3] = AeonT3Eng,
        [4] = AeonT4Eng,
    },
    -- T1 Land Factory
    ['uab0101'] = {
        [1] = AeonT1Land,
        ['U'] = 'uab0201',
    },
    -- T1 Air Factory
    ['uab0102'] = {
        [1] = AeonT1Air,
        ['U'] = 'uab0202',
    },
    -- T1 Naval Factory
    ['uab0103'] = {
        [1] = AeonT1Sea,
        ['U'] = 'uab0203',
    },
    -- T2 Land Factory
    ['uab0201'] = {
        [1] = AeonT1Land,
        [2] = AeonT2Land,
        ['U'] = 'uab0301',
    },
    -- T2 Air Factory
    ['uab0202'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        ['U'] = 'uab0302',
    },
    -- T2 Naval Factory
    ['uab0203'] = {
        [1] = AeonT1Sea,
        [2] = AeonT2Sea,
        ['U'] = 'uab0303',
    },
    -- T2 Land Factory
    ['zab9501'] = {
        [1] = AeonT1Land,
        [2] = AeonT2Land,
        ['U'] = 'zab9601',
    },
    -- T2 Air Factory
    ['zab9502'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        ['U'] = 'zab9602',
    },
    -- T2 Naval Factory
    ['zab9503'] = {
        [1] = AeonT1Sea,
        [2] = AeonT2Sea,
        ['U'] = 'zab9603',
    },
    -- T3 Land Factory
    ['uab0301'] = {
        [1] = AeonT1Land,
        [2] = AeonT2Land,
        [3] = AeonT3Land,
    },
    -- T3 Air Factory
    ['uab0302'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        [3] = AeonT3Air,
    },
    -- T3 Naval Factory
    ['uab0303'] = {
        [1] = AeonT1Sea,
        [2] = AeonT2Sea,
        [3] = AeonT3Sea,
    },
    -- T3 Land Factory
    ['zab9601'] = {
        [1] = AeonT1Land,
        [2] = AeonT2Land,
        [3] = AeonT3Land,
    },
    -- T3 Air Factory
    ['zab9602'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        [3] = AeonT3Air,
    },
    -- T3 Naval Factory
    ['zab9603'] = {
        [1] = AeonT1Sea,
        [2] = AeonT2Sea,
        [3] = AeonT3Sea,
    },
    -- Quantum Gateway
    ['uab0304'] = {
        [3] = {
            ['C'] = 'ual0301',
            ['F'] = 'ual0301_ras',
            ['T'] = 'ual0301_simplecombat',
            ['E'] = 'ual0301_engineer',
            ['N'] = 'ual0301_nanocombat',
            ['S'] = 'ual0301_shieldcombat',
            ['R'] = 'ual0301_rambo',
        },
    },
    -- T1 Mass Extractor
    ['uab1103'] = {
        ['U'] = 'uab1202',
    },
    -- T2 Mass Extractor
    ['uab1202'] = {
        ['U'] = 'uab1302',
    },
    -- T1 Radar
    ['uab3101'] = {
        ['U'] = 'uab3201',
    },
    -- T2 Radar
    ['uab3201'] = {
        ['U'] = 'uab3104',
    },
    -- T1 Sonar
    ['uab3102'] = {
        ['U'] = 'uab3202',
    },
    -- T2 Sonar
    ['uab3202'] = {
        ['U'] = 'uas0305',
    },
    -- Aircraft Carrier
    ['uas0303'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        [3] = AeonT3Air,
    },
    -- CZAR
    ['uaa0310'] = {
        [1] = AeonT1Air,
        [2] = AeonT2Air,
        [3] = AeonT3Air,
    },
    -- Submersible Battleship
    ['uas0401'] = {
        [1] = AeonT1Sea,
        [2] = AeonT2Sea,
        [3] = {
            ['E'] = 'ual0309',
        },
    },

-- UEF
    -- commander
    ['uel0001'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander
    ['uel0301'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - resource allocation preset
    ['uel0301_ras'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - combatant preset
    ['uel0301_combat'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - engineer preset
    ['uel0301_engineer'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - rambo preset
    ['uel0301_rambo'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - shield preset
    ['uel0301_bubbleshield'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- subcommander - intel jammer preset
    ['uel0301_inteljammer'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- T1 engineer
    ['uel0105'] = {
        [1] = UEFT1Eng,
    },
    -- T2 engineer
    ['uel0208'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
    },
    -- T2 field engineer
    ['xel0209'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
    },
    -- T3 engineer
    ['uel0309'] = {
        [1] = UEFT1Eng,
        [2] = UEFT2Eng,
        [3] = UEFT3Eng,
        [4] = UEFT4Eng,
    },
    -- T1 Land Factory
    ['ueb0101'] = {
        [1] = UEFT1Land,
        ['U'] = 'ueb0201',
    },
    -- T1 Air Factory
    ['ueb0102'] = {
        [1] = UEFT1Air,
        ['U'] = 'ueb0202',
    },
    -- T1 Naval Factory
    ['ueb0103'] = {
        [1] = UEFT1Sea,
        ['U'] = 'ueb0203',
    },
    -- T2 Land Factory
    ['ueb0201'] = {
        [1] = UEFT1Land,
        [2] = UEFT2Land,
        ['U'] = 'ueb0301',
    },
    -- T2 Air Factory
    ['ueb0202'] = {
        [1] = UEFT1Air,
        [2] = UEFT2Air,
        ['U'] = 'ueb0302',
    },
    -- T2 Naval Factory
    ['ueb0203'] = {
        [1] = UEFT1Sea,
        [2] = UEFT2Sea,
        ['U'] = 'ueb0303',
    },
    -- T2 Land Factory
    ['zeb9501'] = {
        [1] = UEFT1Land,
        [2] = UEFT2Land,
        ['U'] = 'zeb9601',
    },
    -- T2 Air Factory
    ['zeb9502'] = {
        [1] = UEFT1Air,
        [2] = UEFT2Air,
        ['U'] = 'zeb9602',
    },
    -- T2 Naval Factory
    ['zeb9503'] = {
        [1] = UEFT1Sea,
        [2] = UEFT2Sea,
        ['U'] = 'zeb9603',
    },
    -- T3 Land Factory
    ['ueb0301'] = {
        [1] = UEFT1Land,
        [2] = UEFT2Land,
        [3] = UEFT3Land,
    },
    -- T3 Air Factory
    ['ueb0302'] = {
        [1] = UEFT1Air,
        [2] = UEFT2Air,
        [3] = UEFT3Air,
    },
    -- T3 Naval Factory
    ['ueb0303'] = {
        [1] = UEFT1Sea,
        [2] = UEFT2Sea,
        [3] = UEFT3Sea,
    },
    -- T3 Land Factory
    ['zeb9601'] = {
        [1] = UEFT1Land,
        [2] = UEFT2Land,
        [3] = UEFT3Land,
    },
    -- T3 Air Factory
    ['zeb9602'] = {
        [1] = UEFT1Air,
        [2] = UEFT2Air,
        [3] = UEFT3Air,
    },
    -- T3 Naval Factory
    ['zeb9603'] = {
        [1] = UEFT1Sea,
        [2] = UEFT2Sea,
        [3] = UEFT3Sea,
    },
    -- Quantum Gateway
    ['ueb0304'] = {
        [3] = {
            ['C'] = 'uel0301',
            ['F'] = 'uel0301_ras',
            ['T'] = 'uel0301_combat',
            ['E'] = 'uel0301_engineer',
            ['R'] = 'uel0301_rambo',
            ['S'] = 'uel0301_bubbleshield',
            ['J'] = 'uel0301_inteljammer',

        },
    },
    -- T1 Mass Extractor
    ['ueb1103'] = {
        ['U'] = 'ueb1202',
    },
    -- T2 Mass Extractor
    ['ueb1202'] = {
        ['U'] = 'ueb1302',
    },
    -- T1 Radar
    ['ueb3101'] = {
        ['U'] = 'ueb3201',
    },
    -- T2 Radar
    ['ueb3201'] = {
        ['U'] = 'ueb3104',
    },
    -- T1 Sonar
    ['ueb3102'] = {
        ['U'] = 'ueb3202',
    },
    -- T2 Sonar
    ['ueb3202'] = {
        ['U'] = 'ues0305',
    },
    -- T2 Shield
    ['ueb4202'] = {
        ['U'] = 'ueb4301',
    },
    -- Submersible Aircraft Carrier
    ['ues0401'] = {
        [1] = UEFT1Air,
        [2] = UEFT2Air,
        [3] = UEFT3Air,
    },
    -- Mobile factory
    ['uel0401'] = {
        [1] = UEFT1Land,
        [2] = UEFT2Land,
        [3] = UEFT3Land,
    },

-- Cybran
    -- commander
    ['url0001'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander
    ['url0301'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - ras preset
    ['url0301_ras'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - combatant preset
    ['url0301_combat'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - engineer preset
    ['url0301_engineer'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - rambo preset
    ['url0301_rambo'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - stealth preset
    ['url0301_stealth'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - cloak preset
    ['url0301_cloak'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- subcommander - anti-air preset
    ['url0301_antiair'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- T1 engineer
    ['url0105'] = {
        [1] = CybranT1Eng,
    },
    -- T2 engineer
    ['url0208'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
    },
    -- T3 engineer
    ['url0309'] = {
        [1] = CybranT1Eng,
        [2] = CybranT2Eng,
        [3] = CybranT3Eng,
        [4] = CybranT4Eng,
    },
    -- T1 Land Factory
    ['urb0101'] = {
        [1] = CybranT1Land,
        ['U'] = 'urb0201',
    },
    -- T1 Air Factory
    ['urb0102'] = {
        [1] = CybranT1Air,
        ['U'] = 'urb0202',
    },
    -- T1 Naval Factory
    ['urb0103'] = {
        [1] = CybranT1Sea,
        ['U'] = 'urb0203',
    },
    -- T2 Land Factory
    ['urb0201'] = {
        [1] = CybranT1Land,
        [2] = CybranT2Land,
        ['U'] = 'urb0301',
    },
    -- T2 Air Factory
    ['urb0202'] = {
        [1] = CybranT1Air,
        [2] = CybranT2Air,
        ['U'] = 'urb0302',
    },
    -- T2 Naval Factory
    ['urb0203'] = {
        [1] = CybranT1Sea,
        [2] = CybranT2Sea,
        ['U'] = 'urb0303',
    },
	    -- T2 Land Factory
    ['zrb9501'] = {
        [1] = CybranT1Land,
        [2] = CybranT2Land,
        ['U'] = 'zrb9601',
    },
    -- T2 Air Factory
    ['zrb9502'] = {
        [1] = CybranT1Air,
        [2] = CybranT2Air,
        ['U'] = 'zrb9602',
    },
    -- T2 Naval Factory
    ['zrb9503'] = {
        [1] = CybranT1Sea,
        [2] = CybranT2Sea,
        ['U'] = 'zrb9603',
    },
    -- T3 Land Factory
    ['urb0301'] = {
        [1] = CybranT1Land,
        [2] = CybranT2Land,
        [3] = CybranT3Land,
    },
    -- T3 Air Factory
    ['urb0302'] = {
        [1] = CybranT1Air,
        [2] = CybranT2Air,
        [3] = CybranT3Air,
    },
    -- T3 Naval Factory
    ['urb0303'] = {
        [1] = CybranT1Sea,
        [2] = CybranT2Sea,
        [3] = CybranT3Sea,
    },
    -- T3 Land Factory
    ['zrb9601'] = {
        [1] = CybranT1Land,
        [2] = CybranT2Land,
        [3] = CybranT3Land,
    },
    -- T3 Air Factory
    ['zrb9602'] = {
        [1] = CybranT1Air,
        [2] = CybranT2Air,
        [3] = CybranT3Air,
    },
    -- T3 Naval Factory
    ['zrb9603'] = {
        [1] = CybranT1Sea,
        [2] = CybranT2Sea,
        [3] = CybranT3Sea,
    },
    -- Quantum Gateway
    ['urb0304'] = {
        [3] = {
            ['C'] = 'url0301',
            ['F'] = 'url0301_ras',
            ['T'] = 'url0301_combat',
            ['E'] = 'url0301_engineer',
            ['R'] = 'url0301_rambo',
            ['S'] = 'url0301_stealth',
            ['K'] = 'url0301_cloak',
            ['A'] = 'url0301_antiair',
        },
    },
    -- T1 Mass Extractor
    ['urb1103'] = {
        ['U'] = 'urb1202',
    },
    -- T2 Mass Extractor
    ['urb1202'] = {
        ['U'] = 'urb1302',
    },
    -- T1 Radar
    ['urb3101'] = {
        ['U'] = 'urb3201',
    },

    -- T2 Radar
    ['urb3201'] = {
        ['U'] = 'urb3104',
    },
    -- T1 Sonar
    ['urb3102'] = {
        ['U'] = 'urb3202',
    },
    -- T2 Sonar
    ['urb3202'] = {
        ['U'] = 'urs0305',
    },
    -- Shield Generators
    ['urb4202'] = {
        ['U'] = 'urb4204',
    },
    ['urb4204'] = {
        ['U'] = 'urb4205',
    },
    ['urb4205'] = {
        ['U'] = 'urb4206',
    },
    ['urb4206'] = {
        ['U'] = 'urb4207',
    },
    -- Aircraft Carrier
    ['urs0303'] = {
        [1] = CybranT1Air,
        [2] = CybranT2Air,
        [3] = CybranT3Air,
    },
    --Megabot
    ['xrl0403'] = {
        [2] = CybranCrabBot,
        [3] = CybranCrabBot,
    },

-- Seraphim
    -- commander
    ['xsl0001'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander
    ['xsl0301'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - combatant preset
    ['xsl0301_combat'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - engineer preset
    ['xsl0301_engineer'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - nano combatant preset
    ['xsl0301_nanocombat'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - advanced combatant preset
    ['xsl0301_advancedcombat'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - rambo preset
    ['xsl0301_rambo'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- subcommander - missile preset
    ['xsl0301_missile'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- T1 engineer
    ['xsl0105'] = {
        [1] = SeraphimT1Eng,
    },
    -- T2 engineer
    ['xsl0208'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
    },
    -- T3 engineer
    ['xsl0309'] = {
        [1] = SeraphimT1Eng,
        [2] = SeraphimT2Eng,
        [3] = SeraphimT3Eng,
        [4] = SeraphimT4Eng,
    },
    -- T1 Land Factory
    ['xsb0101'] = {
        [1] = SeraphimT1Land,
        ['U'] = 'xsb0201',
    },
    -- T1 Air Factory
    ['xsb0102'] = {
        [1] = SeraphimT1Air,
        ['U'] = 'xsb0202',
    },
    -- T1 Naval Factory
    ['xsb0103'] = {
        [1] = SeraphimT1Sea,
        ['U'] = 'xsb0203',
    },
    -- T2 Land Factory
    ['xsb0201'] = {
        [1] = SeraphimT1Land,
        [2] = SeraphimT2Land,
        ['U'] = 'xsb0301',
    },
    -- T2 Air Factory
    ['xsb0202'] = {
        [1] = SeraphimT1Air,
        [2] = SeraphimT2Air,
        ['U'] = 'xsb0302',
    },
    -- T2 Naval Factory
    ['xsb0203'] = {
        [1] = SeraphimT1Sea,
        [2] = SeraphimT2Sea,
        ['U'] = 'xsb0303',
    },
    -- T2 Land Factory
    ['zsb9501'] = {
        [1] = SeraphimT1Land,
        [2] = SeraphimT2Land,
        ['U'] = 'zsb9601',
    },
    -- T2 Air Factory
    ['zsb9502'] = {
        [1] = SeraphimT1Air,
        [2] = SeraphimT2Air,
        ['U'] = 'zsb9602',
    },
    -- T2 Naval Factory
    ['zsb9503'] = {
        [1] = SeraphimT1Sea,
        [2] = SeraphimT2Sea,
        ['U'] = 'zsb9603',
    },
    -- T3 Land Factory
    ['xsb0301'] = {
        [1] = SeraphimT1Land,
        [2] = SeraphimT2Land,
        [3] = SeraphimT3Land,
    },
    -- T3 Air Factory
    ['xsb0302'] = {
        [1] = SeraphimT1Air,
        [2] = SeraphimT2Air,
        [3] = SeraphimT3Air,
    },
    -- T3 Naval Factory
    ['xsb0303'] = {
        [1] = SeraphimT1Sea,
        [2] = SeraphimT2Sea,
        [3] = SeraphimT3Sea,
    },
    -- T3 Land Factory
    ['zsb9601'] = {
        [1] = SeraphimT1Land,
        [2] = SeraphimT2Land,
        [3] = SeraphimT3Land,
    },
    -- T3 Air Factory
    ['zsb9602'] = {
        [1] = SeraphimT1Air,
        [2] = SeraphimT2Air,
        [3] = SeraphimT3Air,
    },
    -- T3 Naval Factory
    ['zsb9603'] = {
        [1] = SeraphimT1Sea,
        [2] = SeraphimT2Sea,
        [3] = SeraphimT3Sea,
    },
    -- Quantum Gateway
    ['xsb0304'] = {
        [3] = {
            ['C'] = 'xsl0301',
            ['T'] = 'xsl0301_combat',
            ['E'] = 'xsl0301_engineer',
            ['N'] = 'xsl0301_nanocombat',
            ['A'] = 'xsl0301_advancedcombat',
            ['R'] = 'xsl0301_rambo',
            ['M'] = 'xsl0301_missile',
        },
    },
    -- T1 Mass Extractor
    ['xsb1103'] = {
        ['U'] = 'xsb1202',
    },
    -- T2 Mass Extractor
    ['xsb1202'] = {
        ['U'] = 'xsb1302',
    },
    -- T1 Radar
    ['xsb3101'] = {
        ['U'] = 'xsb3201',
    },

    -- T2 Radar
    ['xsb3201'] = {
        ['U'] = 'xsb3104',
    },
    -- T1 Sonar
    ['xsb3102'] = {
        ['U'] = 'xsb3202',
    },
    -- T2 Sonar
--    ['xsb3202'] = {
--        ['U'] = 'xss0305', -- unit xsb3202 can't upgrade to xsb0305 (building does not exist).
--    },
    -- Shield Generators
    ['xsb4202'] = {
        ['U'] = 'xsb4204',
    },
    ['xsb4204'] = {
        ['U'] = 'xsb4205',
    },
    ['xsb4205'] = {
        ['U'] = 'xsb4206',
    },
    ['xsb4206'] = {
        ['U'] = 'xsb4207',
    },
    -- Aircraft Carrier
    ['xss0303'] = {
        [1] = SeraphimT1Air,
        [2] = SeraphimT2Air,
        [3] = SeraphimT3Air,
    },
}