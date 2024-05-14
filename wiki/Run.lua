--------------------------------------------------------------------------------
-- Supreme Commander mod automatic unit wiki generation script for Github wikis
-- Copyright 2021-2022 Sean 'Balthazar' Wheeldon                      Lua 5.4.2
--------------------------------------------------------------------------------

--[{ ---------------------------------------------------------------------- ]]--
--[[ Inputs -- NOTE: Mod input files must be valid lua                      ]]--
--[[ ---------------------------------------------------------------------- ]]--
local OutputDirectory = "D:/faf-development/fa.wiki/"
local WikiGeneratorDirectory = "D:/faf-development/BrewWikiGen/"

-- This section deals with overriding the OutputDirectory and WikiGeneratorDirectory if required
local function parse_args(arg)
    local args = {}
    for i = 1, #arg do
        local key, value = arg[i]:match("--([^=]+)=(.*)")
        if key and value then
            args[key] = value
        end
    end
    return args
end

for i, v in ipairs(arg) do
    print(i, v)
end

print("Key and value pairs:")
for i = 1, #arg do
    local key, value = arg[i]:match("--([^=]+)=(.*)")
    print(key, value)
end


local args = parse_args(arg)


print("Output Directory: " .. tostring(args["OutputDirectory"]))
print("Wiki Generator Directory: " .. tostring(args["WikiGeneratorDirectory"]))

-- Overwrite default values if provided as command-line arguments
if args["OutputDirectory"] then
    OutputDirectory = args["OutputDirectory"]
end
if args["WikiGeneratorDirectory"] then
    WikiGeneratorDirectory = args["WikiGeneratorDirectory"]
end

print("Output Directory: " .. OutputDirectory)
print("Wiki Generator Directory: " .. WikiGeneratorDirectory)

EnvironmentData = {
    name = 'Forged Alliance Forever',
    author = 'Gas Powered Games',
    version = '1.6.6',
    icon = false,
    location = 'D:/faf-development/fa/',

    GenerateWikiPages = true,  --Generate pages for env blueprints
    RebuildBlueprints = true,  --Rebuild env blueprints
    RunSanityChecks = false,   --Sanity check env bps

    Lua = 'D:/faf-development/fa/',
    LOC = 'D:/faf-development/fa/',
    -- ExtraData = '',

    PreModBlueprints = {},
    PostModBlueprints = {},
}

WikiOptions = {
    Language = 'US', -- These are not ISO_639-1. As an Englishman I am offended.

    GenerateHomePage = true,
    GenerateSidebar = true,
    GenerateModPages = true,
    GenerateUnitPages = true,
    GenerateProjectilesPage = true,
    GenerateCategoryPages = true,

    -- Unit page options
    IncludeStrategicIcon = true,
    AbilityDescriptions = true,
    BalanceNote = 'Displayed stats are from the development branch of the game.',
    ConstructionNote = 'Build times from the development branch of the game:',
    BuildListSaysModUnits = true,

    OnlineRepoUnitPageBlueprintLink = 'https://github.com/FAForever/fa/',
    LocalRepuUnitPageBlueprintLink = 'D:/faf-development/fa/',
}

RebuildBlueprintOptions = {
    RebuildBpFiles = false,
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
    -- '/z[^/]*_unit%.bp', --bp files that start with z
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

