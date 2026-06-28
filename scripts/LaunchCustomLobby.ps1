# ******************************************************************************************************
# ** Copyright (c) 2026 FAForever
# **
# ** Permission is hereby granted, free of charge, to any person obtaining a copy
# ** of this software and associated documentation files (the "Software"), to deal
# ** in the Software without restriction, including without limitation the rights
# ** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# ** copies of the Software, and to permit persons to whom the Software is
# ** furnished to do so, subject to the following conditions:
# **
# ** The above copyright notice and this permission notice shall be included in all
# ** copies or substantial portions of the Software.
# **
# ** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# ** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# ** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# ** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# ** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# ** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# ** SOFTWARE.
# ******************************************************************************************************

# Launches one or more instances straight into the REGULAR custom-game lobby (not the
# autolobby), so the lobby UI can be developed and debugged quickly.
#
# How the lobby is reached (see lua\ui\uimain.lua):
#   - host  -> /hostgame <protocol> <port> <playerName> <gameName> <mapFile>  -> StartHostLobbyUI
#   - join  -> /joingame <protocol> <address> <playerName>                    -> StartJoinLobbyUI
# Both pick the AUTOLOBBY only when `/players >= 2` is present. This script deliberately
# omits `/players`, so they fall through to the regular lobby (lua\ui\lobby\lobby.lua).
#
# Quick UI iteration:   .\LaunchCustomLobby.ps1 -players 1     (host only, single window)
# Networked lobby test: .\LaunchCustomLobby.ps1 -players 2     (host + 1 joining client)
#
# Style and conventions follow scripts\LaunchBotSession.ps1 and scripts\LaunchFAInstances.ps1.

param (
    [int]$players = 2,                                              # 1 = host only (fast UI debug); 2+ = host + joining clients
    [string]$map = "/maps/scmp_009/SCMP_009_scenario.lua",         # default map: Seton's Clutch
    [int]$port = 15000                                             # host listen port
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

$hostProtocol = "udp"
$hostPlayerName = "HostPlayer_1"
$gameName = "DevLobby"

# Random pools to draw per-player info from (mirrors scripts\LaunchFAInstances.ps1).
$factions = @("uef", "aeon", "cybran", "seraphim")
$clans = @("Yps", "Nom", "Cly", "Mad", "Gol", "Kur", "Row", "Jip", "Bal", "She")
$countries = @("us", "gb", "de", "fr", "nl", "ru", "ca", "au", "br", "pl")
$divisions = @("bronze", "silver", "gold", "diamond", "master", "grandmaster", "unlisted")
$subdivisions = @("I", "II", "III", "IV", "V")

# Returns a randomised set of per-player arguments, mirroring what the FAF client passes for a
# real player. The custom lobby reads these when it builds the local player (see
# CustomLobbyController.CreateLocalPlayer). The host preserves them when seating a joining peer.
#   * rating: the displayed rating (PL) is derived as mean - 3 * deviation. The deviation is kept low
#     (most lobby players are established, deviation ~50-120; a fresh account would be ~500), so PL
#     sits close to the mean and stays positive/realistic.
#   * faction: a flag arg (/uef, /aeon, …) — no value.
#   * team: 2 or 3 (shown as T1 / T2), so the team-aware layouts have a split to render.
#   * grandmaster/unlisted have no subdivision (mirrors LaunchFAInstances).
function Get-PlayerArgs {
    $mean = Get-Random -Minimum 800 -Maximum 2400
    $deviation = Get-Random -Minimum 25 -Maximum 120
    $numGames = Get-Random -Minimum 0 -Maximum 2000
    $team = Get-Random -Minimum 2 -Maximum 4

    $playerArgs = @(
        "/mean", $mean, "/deviation", $deviation, "/numgames", $numGames,
        "/$($factions | Get-Random)",
        "/team", $team,
        "/clan", ($clans | Get-Random),
        "/country", ($countries | Get-Random)
    )

    $division = $divisions | Get-Random
    $playerArgs += @("/division", $division)
    if ($division -ne "unlisted" -and $division -ne "grandmaster") {
        $playerArgs += @("/subdivision", ($subdivisions | Get-Random))
    }

    return $playerArgs
}

# Arguments shared by every instance. Note: NO `/players` argument — that is what keeps us
# on the regular lobby instead of the autolobby.
$commonArgs = @(
    "/init", "init_local_development.lua",
    "/nobugreport",
    "/EnableDiskWatch",
    "/nomovie",
    "/showlog"
)

# Window grid layout (so instances don't stack). The session refuses to launch below 1024x768.
Add-Type -AssemblyName System.Windows.Forms
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height
$columns = [math]::Ceiling([math]::Sqrt($players))
$rows = [math]::Ceiling($players / $columns)
$windowWidth = [math]::Max([math]::Floor($screenWidth / $columns), 1024)
$windowHeight = [math]::Max([math]::Floor($screenHeight / $rows), 768)

function Launch-LobbyInstance {
    param (
        [int]$instanceNumber,
        [int]$xPos,
        [int]$yPos,
        [string[]]$arguments
    )

    $arguments += @("/position", $xPos, $yPos, "/size", $windowWidth, $windowHeight)

    try {
        Start-Process -FilePath $gameExecutable -ArgumentList $arguments -NoNewWindow
        Write-Host "Launched instance $instanceNumber at ($xPos, $yPos) size ($windowWidth, $windowHeight)"
    } catch {
        Write-Host "Failed to launch instance ${instanceNumber}: $_"
    }
}

# Host instance (top-left). Positional order for /hostgame is protocol, port, name, gameName, map.
$hostArgs = @(
    "/log", "host_lobby_1.log",
    "/debug",
    "/hostgame", $hostProtocol, $port, $hostPlayerName, $gameName, $map
) + $commonArgs + (Get-PlayerArgs)
Launch-LobbyInstance -instanceNumber 1 -xPos 0 -yPos 0 -arguments $hostArgs

# Joining client instances. Positional order for /joingame is protocol, address, name.
for ($i = 1; $i -lt $players; $i++) {
    $row = [math]::Floor($i / $columns)
    $col = $i % $columns
    $xPos = $col * $windowWidth
    $yPos = $row * $windowHeight

    $clientName = "ClientPlayer_$($i + 1)"
    $clientArgs = @(
        "/log", "client_lobby_$($i + 1).log",
        "/joingame", $hostProtocol, "localhost:$port", $clientName
    ) + $commonArgs + (Get-PlayerArgs)
    Launch-LobbyInstance -instanceNumber ($i + 1) -xPos $xPos -yPos $yPos -arguments $clientArgs
}

Write-Host "$players instance(s) launched into the regular custom lobby. Host on port $port."
