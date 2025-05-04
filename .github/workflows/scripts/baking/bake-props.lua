--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local OutputDirectory = "D:/faf-development/fa.wiki/"
local WikiGeneratorDirectory = "D:/faf-development/BrewWikiGen/"
local FADirectory = "D:/faf-development/fa/"

--#region This section deals with overriding the OutputDirectory and WikiGeneratorDirectory if required by command-line arguments

local function parse_args(arg)
    local args = {}
    for i = 1, #arg do
        local key, value = arg[i]:match("--([^=]+)=(.*)")
        if key and value then
            key = key:gsub("^%-+", "")  -- Remove leading '-' characters
            args[key] = value
        end
    end
    return args
end

local args = parse_args(arg)

-- Overwrite default values if provided as command-line arguments
if args["OutputDirectory"] then
    OutputDirectory = args["OutputDirectory"]
end
if args["WikiGeneratorDirectory"] then
    WikiGeneratorDirectory = args["WikiGeneratorDirectory"]
end
if args["FADirectory"] then
    FADirectory = args["FADirectory"]
end

print("Directories set")
print("Output Directory: " ..OutputDirectory)
print("Wiki Generator Directory: " ..WikiGeneratorDirectory)
print("FA Directory: " ..FADirectory)
--#endregion

EnvironmentData = {
    name = 'Forged Alliance',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
    location = FADirectory,

    GenerateWikiPages = false,
    RebuildBlueprints = true,
    RunSanityChecks = false,

    base64 = {
        UnitIcons = false,
    },

    Lua = FADirectory,
    LOC = FADirectory,

    PreModBlueprints = {},
    PostModBlueprints = {
        "BakePropBlueprints"
    },

    LoadExtraBlueprints = {
        Beam = false,
        Mesh = false,
        Prop = true,
        Emitter = false,
        TrailEmitter = false,
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
    LocalRepuUnitPageBlueprintLink = FADirectory,
}

RebuildBlueprintOptions = {
    RebuildBpFiles = {
        Unit = false,
        Beam = false,
        Mesh = false,
        Prop = true,
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
    '/op[ec][^/]*_unit%.bp', --bp files like OPE2001
    '/[ux][arse]c[^/]*_unit%.bp', --Exclude civilian units.
}

BlueprintIdExclusions = { -- Excludes blueprints with any of these IDs (case insensitive)
    "zxa0001",      -- Dummy unit
    "zxa0002",      -- Dummy unit for external/mobile factory units
    "zxa0003",      -- Dummy unit 
    "ura0001O",     -- Cybran build drone
    "ura0002O",     -- Cybran build drone
    "ura0003O",     -- Cybran build drone
    "XRO4001",      -- Remains of Dostya
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

