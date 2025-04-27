--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local OutputDirectory = "D:/faf-development/fa-total-mayhem.wiki/"
local WikiGeneratorDirectory = "D:/faf-development/BrewWikiGen/"

EnvironmentData = {
    name = 'Forged Alliance',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
    location = 'D:/faf-development/fa/',

    GenerateWikiPages = false,
    RebuildBlueprints = true,
    RunSanityChecks = false,

    base64 = {
        UnitIcons = false,
    },

    Lua = 'D:/faf-development/fa/',
    LOC = 'D:/faf-development/fa/',

    PreModBlueprints = {},
    PostModBlueprints = {
        "BatchProcessProps"
    },

    LoadExtraBlueprints = {
        Beam = true,
        Mesh = true,
        Prop = true,
        Emitter = true,
        TrailEmitter = true,
    },
}

WikiOptions = {
    Language = 'US', -- These are not ISO_639-1. As an Englishman I am offended.

    GenerateHomePage = false,
    GenerateSidebar = false,
    GenerateModPages = false,
    GenerateUnitPages = false,
    GenerateProjectilesPage = false,
    GenerateCategoryPages = false,

    -- Unit page options
    IncludeStrategicIcon = false,
    AbilityDescriptions = false,
    BalanceNote = '<LOC wiki_balance_stats_steam>Displayed stats are from when launched on the steam/retail version of the game.',
    ConstructionNote = '<LOC wiki_builders_note_steam>Build times from the Steam/retail version of the game:',
    BuildListSaysModUnits = false,

    OnlineRepoUnitPageBlueprintLink = 'https://github.com/The-Balthazar/BrewLAN/tree/master/',
    LocalRepuUnitPageBlueprintLink = 'D:/faf-development/fa/',
}

RebuildBlueprintOptions = {
    RebuildBpFiles = {
        Unit = true,
        Beam = false,
        Mesh = false,
        Prop = false,
        Emitter = false,
        Projectile = false,
        TrailEmitter = false,
    },
    RemoveUnusedValues = false,
    CleanupBuildOnLayerCaps = false,
    CleanupGeneralBackgroundIcon = false,
    CleanupWreckageLayers = false,
    CleanupCommandCaps = false,
    CleanupIntelOverlayCategories = false,
    RemoveMilitaryOverlayCategories = false,
    RemoveProductCategories = false,
    RecalculateThreat = false,
}

CleanupOptions = {
    CleanUnitBpFiles = false,
    CleanUnitBpGeneral = false,
    CleanUnitBpDisplay = false,
    CleanUnitBpInterface = false,
    CleanUnitBpUseOOBTestZoom = false,
    CleanUnitBpThreat = false,
}

ModDirectories = { -- In order
    -- 'C:/BrewLAN/mods/BrewLAN/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewAir/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewIntel/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewMonsters/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewResearch/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewShields/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewTeaParty/',
    -- 'C:/BrewLAN/mods/BrewLAN_Units/BrewTurrets/',
}

BlueprintExclusions = {
    '/z[^/]*_unit%.bp', --bp files that start with z
    '/op[ec][^/]*_unit%.bp', --bp files like OPE2001
    '/[ux][arse]c[^/]*_unit%.bp', --Exclude civilian units.
}

BlueprintIdExclusions = { -- Excludes blueprints with any of these IDs (case insensitive)
    'seb0105',
    'srl0000',
    'srl0001',
    'srl0002',
    'srl0003',
    'srl0004',
    'srl0005',
    'srl0006',
    'ssb2380',
    'ura0001', --Cybran build effect
    'uea0001', -- UEF ACU drone
    'uea0003', -- UEF ACU drone
}

FooterCategories = { -- In order
    'UEF',          'AEON',         'CYBRAN',       'SERAPHIM',
    'TECH1',        'TECH2',        'TECH3',        'EXPERIMENTAL',
    'MOBILE',
    'ANTIAIR',      'ANTINAVY',     'DIRECTFIRE',
    'AIR',          'LAND',         'NAVAL',
    'HOVER',
    'ECONOMIC',
    'SHIELD',       'PERSONALSHIELD',
    'BOMBER',       'TORPEDOBOMBER',
    'MINE',
    'COMMAND',      'SUBCOMMANDER', 'ENGINEER',     'FIELDENGINEER',
    'TRANSPORTATION',               'AIRSTAGINGPLATFORM',
    'SILO',
    'FACTORY',
    'ARTILLERY',
    'STRUCTURE',
}

Logging = { -- Functional logs
    LogEmojiSupported  = false,

    LocalisationLoaded = false,
    HelpStringsLoaded  = false,
    BuffsLoaded        = false,
    SCMLoadIssues      = false,
    SandboxedFileLogs  = {
        Debug = false, -- SPEW
        Log   = true, -- LOG, _ALERT, print
        Warn  = true, -- WARN
    },

    ExcludedBlueprints = false,
    BlueprintTotals    = true,
    MissingUnitImage   = true,

    ChangeDiscarded    = true,
    NewFileWrites      = true,
    FileAppendWrites   = true,
    FileUpdateWrites   = false,
    FileAssetCopies    = true,

    ThreatCalculationWarnings = false,
}
Sanity = { -- Advice logs
    BlueprintChecks         = false,
    BlueprintPedanticChecks = false,
    BlueprintStrategicIconChecks = false,
}
Info = { -- Misc data logs
    UnitLODCounts = false,
    ProjectileBlueprintCounts = false,
}

dofile(WikiGeneratorDirectory.."Main.lua")
GeneratorMain(OutputDirectory)

