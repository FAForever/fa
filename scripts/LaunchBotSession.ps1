param (
    [string]$map = "/maps/scmp_009/SCMP_009_scenario.lua",  # Default map: Seton's Clutch
    [string]$ai = "rush" # Same keys as used in lua\ui\lobby\aitypes.lua (and in lua\aibrains\index.lua)
)

# Base path to the bin directory
$binPath = "C:\ProgramData\FAForever\bin"

# Paths to the potential executables within the base path
$debuggerExecutable = Join-Path $binPath "FAFDebugger.exe"
$regularExecutable = Join-Path $binPath "ForgedAlliance.exe"

# Check for the existence of the executables and choose accordingly
if (Test-Path $debuggerExecutable) {
    $gameExecutable = $debuggerExecutable
    Write-Output "Using debugger executable: $gameExecutable"
} elseif (Test-Path $regularExecutable) {
    $gameExecutable = $regularExecutable
    Write-Output "Debugger not found, using regular executable: $gameExecutable"
} else {
    Write-Output "Neither debugger nor regular executable found in $binPath. Exiting script."
    exit 1
}

# Build argument list
$args = @(
    "/init", "init_local_development.lua",
    "/nobugreport",
    "/EnableDiskWatch",

    "/log", "dev-bot-session.log",
    "/showlog",

    # Seed to use for randomness
    "/seed", "1",

    # Enable cheats
    "/cheats",

    # Indicates to the engine that we want to quickly start a scenario, skipping the lobby.
    "/scenario", $map,

    # Indicates to the startup sequence that we want to observe as a player. You start with the focus army set to a bot.
    "/observe",

    # List of all available (sim) mods. There should be no spaces.
    # Format: "/gamemods", "mod_id:mod_name"

    # "/gamemods", "joe-ai-01:AverageJoeAI"

    # Bot configuration. There should be no spaces.
    # Format: "/gameais", "1:ai_name", "2:ai_name"

    "/gameais", "1:$ai", "2:$ai",

    # Lobby option configuration. There should be no spaces.
    # Format: "/gameoptions", "option_key:option_value"

    "/gameoptions", "UnitCap:750", "GameSpeed:adjustable",

    # Game option to run the skirmish as fast as possible. 
    # the `wld_RunWithTheWind` console command in the background.

    "/runWithTheWind"
)

Write-Host "Launching map: $map with AIs: $ai"
Start-Process -FilePath $gameExecutable -ArgumentList $args
