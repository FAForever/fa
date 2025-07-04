param (
    [int]$players = 2,  # Default to 2 instances (1 host, 1 client)
    [string]$map = "/maps/scmp_009/SCMP_009_scenario.lua",  # Default map: Seton's Clutch
    [int]$port = 15000,  # Default port for hosting the game
    [int]$teams = 2,  # Default to two teams, 0 for FFA
    [switch]$toLobby # launches into custom lobby
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

# Command-line arguments common for all instances
$baseArguments = '/init "init_dev.lua" /EnableDiskWatch /nomovie /RunWithTheWind /debugLobby /gameoptions CheatsEnabled:true GameSpeed:adjustable'
# Add the players argument if we want to use autolobby
if (-not $toLobby) {
    $baseArguments += " /players $players"
}

# Game-specific settings
$hostProtocol = "udp"
$hostPlayerName = "HostPlayer_1"
$gameName = "MyGame"

# Array of player data to choose from
$factions = @("UEF", "Seraphim", "Cybran", "Aeon")
$clans = @("Yps", "Nom", "Cly", "Mad", "Gol", "Kur", "Row", "Jip", "Bal", "She")
$divisions = @("bronze", "silver", "gold", "diamond", "master", "grandmaster", "unlisted")
$subdivisions = @("I", "II", "III", "IV", "V")

# Get the screen resolution (for placing and resizing the windows)
Add-Type -AssemblyName System.Windows.Forms
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height

# Calculate the number of rows and columns for the grid layout
$columns = [math]::Ceiling([math]::Sqrt($players))
$rows = [math]::Ceiling($players / $columns)

# Calculate the size of each window based on the grid
# Limit the window size to 1024x768 as the game session will not launch if it is smaller
$windowWidth = [math]::Max([math]::Floor($screenWidth / $columns), 1024)
$windowHeight = [math]::Max([math]::Floor($screenHeight / $rows), 768)

# Function to launch a single game instance
function Launch-GameInstance {
    param (
        [int]$instanceNumber,
        [int]$xPos,
        [int]$yPos,
        [string]$arguments
    )

    # Add window position and size arguments
    $arguments += " /position $xPos $yPos /size $windowWidth $windowHeight"
    
    try {
        Start-Process -FilePath $gameExecutable -ArgumentList $arguments -NoNewWindow
        Write-Host "Launched instance $instanceNumber at position ($xPos, $yPos) with size ($windowWidth, $windowHeight) and arguments: $arguments"
    } catch {
        Write-Host "Failed to launch instance ${instanceNumber}: $_"
    }
}

# Function to calculate team argument based on instance number and team configuration
function Get-TeamArgument {
    param (
        [int]$instanceNumber
    )
    
    if ($teams -eq 0) {
        return ""  # No team argument for FFA
    }
    
    # Calculate team number; additional +1 because player team indices start at 2
    return "/team $((($instanceNumber % $teams) + 1 + 1))"
}

function Get-DivisionArgText {
    $division = $($divisions | Get-Random)
    $argText = "/division $division"
    if ($division -ne "unlisted" -and $division -ne "grandmaster") {
        $argText += " /subdivision $($subdivisions | Get-Random)"
    }
    return $argText
}

# Prepare arguments and launch instances
if ($players -eq 1 -and -not $toLobby) {
    $logFile = "dev.log"
    Launch-GameInstance -instanceNumber 1 -xPos 0 -yPos 0 -arguments "/log $logFile /showlog /map $map $baseArguments"
} else {
    $hostLogFile = "host_dev_1.log"
    $hostFaction = $factions | Get-Random
    $hostTeamArgument = Get-TeamArgument -instanceNumber 0

    $divisionArgText = Get-DivisionArgText
    $hostArguments = "/log $hostLogFile /showlog /hostgame $hostProtocol $port $hostPlayerName $gameName $map /startspot 1 /$hostFaction $hostTeamArgument $baseArguments $divisionArgText /clan $($clans | Get-Random)"

    # Launch host game instance
    Launch-GameInstance -instanceNumber 1 -xPos 0 -yPos 0 -arguments $hostArguments

    # Client game instances
    for ($i = 1; $i -lt $players; $i++) {
        $row = [math]::Floor($i / $columns)
        $col = $i % $columns
        $xPos = $col * $windowWidth
        $yPos = $row * $windowHeight
        
        $clientLogFile = "client_dev_$($i + 1).log"
        $clientPlayerName = "ClientPlayer_$($i + 1)"
        $clientFaction = $factions | Get-Random
        $clientTeamArgument = Get-TeamArgument -instanceNumber $i
        $divisionArgText = Get-DivisionArgText
        $clientArguments = "/log $clientLogFile /joingame $hostProtocol localhost:$port $clientPlayerName /startspot $($i + 1) /$clientFaction $clientTeamArgument $baseArguments $divisionArgText /clan $($clans | Get-Random)"
        
        Launch-GameInstance -instanceNumber ($i + 1) -xPos $xPos -yPos $yPos -arguments $clientArguments
    }
}

Write-Host "$players instance(s) of the game launched. Host is running at port $port."
