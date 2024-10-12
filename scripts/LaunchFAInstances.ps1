param (
    [int]$InstanceCount = 2,  # Default to 2 instances (1 host, 1 client)
    [string]$mapName = "/maps/scmp_009/SCMP_009_scenario.lua",  # Default map
    [int]$port = 15000  # Default port for hosting the game
)

Add-Type -AssemblyName System.Windows.Forms

# Path to the game executable
$gameExecutable = "C:\ProgramData\FAForever\bin\FAFDebugger.exe"

# Command-line arguments common for all instances
$baseArguments = '/init "init_dev.lua" /EnableDiskWatch /nomovie /RunWithTheWind'

# Game-specific settings
$hostProtocol = "udp"  # Protocol for hostgame and joingame
$hostPlayerName = "HostPlayer"
$gameName = "MyGame"
$numPlayers = $InstanceCount  # Total number of players equals the number of instances

# Array of factions to choose from
$factions = @("UEF", "Seraphim", "Cybran", "Aeon")

# Get the screen resolution (for placing and resizing the windows)
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Calculate the number of rows and columns for the grid layout
$columns = [math]::Ceiling([math]::Sqrt($InstanceCount))
$rows = [math]::Ceiling($InstanceCount / $columns)

# Calculate the size of each window based on the grid
# Limit the window size to 1024x768 as the game session will not launch if it is smaller
$windowWidth = [math]::Max([math]::Floor($screenWidth / $columns), 1024); 
$windowHeight = [math]::Max([math]::Floor($screenHeight / $rows), 768)

# Function to launch a single game instance
function Launch-GameInstance {
    param (
        [int]$instanceNumber,  # Instance number for identification
        [int]$xPos,            # X position for the window
        [int]$yPos,            # Y position for the window
        [string]$arguments     # Command-line arguments specific to this instance
    )

    # Add window position and size arguments
    $arguments += " /position $xPos $yPos /size $windowWidth $windowHeight"

    # Start the process
    Start-Process -FilePath $gameExecutable -ArgumentList $arguments -NoNewWindow
    Write-Host "Launched instance $instanceNumber at position ($xPos, $yPos) with size ($windowWidth, $windowHeight) and arguments: $arguments"
}

# Handle the case where only 1 instance is specified
if ($InstanceCount -eq 1) {
    $logFile = "dev.log"
    $arguments = "$baseArguments /log $logFile /showlog"
    Launch-GameInstance -instanceNumber 1 -xPos 0 -yPos 0 -arguments $arguments
} 
else {
    # Host game command-line arguments
    $hostLogFile = "host_dev.log"
    $hostFaction = $factions | Get-Random
    $hostArguments = "$baseArguments /log $hostLogFile /showlog /hostgame $hostProtocol $port $hostPlayerName $gameName $mapName /players $numPlayers /$hostFaction"

    # Client game instances
    for ($i = 0; $i -lt $InstanceCount; $i++) {
        $row = [math]::Floor($i / $columns)
        $col = $i % $columns

        # Calculate the position for this instance
        $xPos = $col * $windowWidth
        $yPos = $row * $windowHeight

        if ($i -eq 0) {
            # Launch the host game instance
            Launch-GameInstance -instanceNumber ($i + 1) -xPos $xPos -yPos $yPos -arguments $hostArguments
        }
        else {
            # Launch the client game instances
            $clientNumber = $i + 1
            $clientLogFile = "client_dev_$clientNumber.log"
            $clientPlayerName = "ClientPlayer_$clientNumber"
            $clientFaction = $factions | Get-Random
            $clientArguments = "$baseArguments /log $clientLogFile /joingame $hostProtocol localhost:$port $clientPlayerName /players $numPlayers /$clientFaction"
            Launch-GameInstance -instanceNumber $clientNumber -xPos $xPos -yPos $yPos -arguments $clientArguments
        }
    }
}

Write-Host "$InstanceCount instance(s) of the game launched. Host is running at port $port."
