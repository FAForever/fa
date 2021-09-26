--*****************************************************************************
--* File: lua/modules/ui/lobby/autolobby.lua
--* Author: Sam Demulling
--* Summary: Autolaunching games from GPGNet.  This is intentionally designed
--* to have no user options as GPGNet is setting them for the player.
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local LobbyComm = import('/lua/ui/lobby/lobbyComm.lua')
local gameColors = import('/lua/gameColors.lua').GameColors
local utils = import('/lua/system/utils.lua')





local connectdialog = false
local parent = false
local localPlayerName = false
local requiredPlayers = false

local connectingDialog = false
local connectionFailedDialog = false

local localPlayerID = false
local gameInfo = {
    GameOptions = {
        Score = 'no',
        TeamSpawn = 'fixed',
        TeamLock = 'locked',
        Victory = 'demoralization',
        Timeouts = '3',
        CheatsEnabled = 'false',
        CivilianAlliance = 'enemy',
        RevealCivilians = 'Yes',
        GameSpeed = 'normal',
        FogOfWar = 'explored',
        UnitCap = '1000',
        Ranked = true,
        PrebuiltUnits = 'Off',
        Share = 'FullShare',
    },
    PlayerOptions = {},
    Observers = {},
    GameMods = {},
}

local Strings = LobbyComm.Strings

local lobbyComm = false

local connectedTo = {}
local peerLaunchStatuses = {}

local function MakeLocalPlayerInfo(name)
    local result = LobbyComm.GetDefaultPlayerOptions(name)
    result.Human = true

    local factionData = import('/lua/factions.lua')

    for index, tbl in factionData.Factions do
        if HasCommandLineArg("/" .. tbl.Key) then
            result.Faction = index
            break
        end
    end

    result.Team = tonumber(GetCommandLineArg("/team", 1)[1])
    result.StartSpot = tonumber(GetCommandLineArg("/startspot", 1)[1]) or false

    result.DEV = tonumber(GetCommandLineArg("/deviation", 1)[1]) or ""
    result.MEAN = tonumber(GetCommandLineArg("/mean", 1)[1]) or ""
    result.NG = tonumber(GetCommandLineArg("/numgames", 1)[1]) or ""
    result.PL = math.floor(result.MEAN - 3 * result.DEV)
    LOG('Local player info: ' .. repr(result))
    return result
end


local function IsColorFree(colorIndex)
    for id,player in gameInfo.PlayerOptions do
        if player.PlayerColor == colorIndex then
            return false
        end
    end

    return true
end

function wasConnected(peer)
    for _,v in pairs(connectedTo) do
        if v == peer then
            return true
        end
    end
    return false
end

function FindSlotForID(id)
    for k,player in gameInfo.PlayerOptions do
        if player.OwnerID == id and player.Human then
            return k
        end
    end
    return nil
end

function IsPlayer(id)
    return FindSlotForID(id) ~= nil
end

local function HostAddPlayer(senderId, playerInfo)
    playerInfo.OwnerID = senderId

    local slot = playerInfo.StartSpot or 1
    if not playerInfo.StartSpot then
        while gameInfo.PlayerOptions[slot] do
            slot = slot + 1
        end
        playerInfo.StartSpot = slot
    end

    playerInfo.PlayerName = lobbyComm:MakeValidPlayerName(playerInfo.OwnerID,playerInfo.PlayerName)
    -- TODO: Should colors be based on teams?
    playerInfo.PlayerColor = slot

    gameInfo.PlayerOptions[slot] = playerInfo
end


local function WaitLaunchAccepted()
    while true do
        local allAccepted = true
        for _, status in peerLaunchStatuses do
            if status == 'Rejected' then
                return false
            elseif not status or status ~= 'Accepted' then
                allAccepted = false
                break
            end
        end
        if allAccepted then
            return true
        end
        WaitSeconds(1)
    end
end


local function CheckForLaunch()
    local important = {}
    for slot,player in gameInfo.PlayerOptions do
        GpgNetSend('PlayerOption', player.OwnerID, 'StartSpot', slot)
        GpgNetSend('PlayerOption', player.OwnerID, 'Army', slot)
        GpgNetSend('PlayerOption', player.OwnerID, 'Faction', player.Faction)
        GpgNetSend('PlayerOption', player.OwnerID, 'Color', player.PlayerColor)

        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end

    #counts the number of players in the game.  Include yourself by default.
    local playercount = 1
    for k,id in important do
        if id ~= localPlayerID then
            local peer = lobbyComm:GetPeer(id)
            if peer.status ~= 'Established' then
                return
            end
            if not table.find(peer.establishedPeers, localPlayerID) then
                return
            end
            playercount = playercount + 1
            for k2,other in important do
                if id ~= other and not table.find(peer.establishedPeers, other) then
                    return
                end
            end
        end
    end

    if playercount < requiredPlayers then
       return
    end

    local allRatings = {}
    for k,v in gameInfo.PlayerOptions do
        if v.Human and v.PL then
            allRatings[v.PlayerName] = v.PL
            -- Initialize peer launch statuses
            peerLaunchStatuses[v.OwnerID] = false
        end
    end
    -- We don't need to wait for a launch status from ourselves
    peerLaunchStatuses[localPlayerID] = nil
    gameInfo.GameOptions['Ratings'] = allRatings

    LOG("Host launching game.")
    lobbyComm:BroadcastData({ Type = 'Launch', GameInfo = gameInfo })
    LOG(repr(gameInfo))

    ForkThread(function()
        if WaitLaunchAccepted() then
            lobbyComm:LaunchGame(gameInfo)
            return
        end

        LOG("Some players rejected the launch! " .. repr(peerLaunchStatuses))
        -- TODO: Add UI element for match failed.
    end)
end


local function CreateUI()

    if (connectdialog != false) then
        MenuCommon.MenuCleanup()
        connectdialog:Destroy()
        connectdialog = false
    end

    -- control layout
    if not parent then parent = UIUtil.CreateScreenGroup(GetFrame(0), "Lobby CreateUI ScreenGroup") end

    local background = MenuCommon.SetupBackground(GetFrame(0))
    --local exitButton = MenuCommon.CreateExitMenuButton(parent, background, "<LOC _Exit>")

    ---------------------------------------------------------------------------
    -- set up map panel
    ---------------------------------------------------------------------------
    local controlGroup = Group(parent, "controlGroup")
    LayoutHelpers.AtCenterIn(controlGroup, parent)
    LayoutHelpers.SetDimensions(controlGroup, 970, 670)

    UIUtil.ShowInfoDialog(controlGroup, "<LOC lobui_0201>Setting up automatch...", "<LOC _Cancel>", ExitApplication)
end


# LobbyComm Callbacks
local function InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    local controlGroup = Group(parent, "controlGroup")
    local LobCreateFunc = import('/lua/ui/lobby/lobbyComm.lua').CreateLobbyComm
    local lob = LobCreateFunc(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    if not lob then
        error('Creating lobby using protocol ' .. repr(protocol) .. ' and port ' .. tostring(localPort) .. ' failed.')
    end
    lobbyComm = lob

    local function CleanupAndExit()
        lobbyComm:Destroy()
        ExitApplication()
    end

    lobbyComm.Connecting = function(self)
        connectingDialog = UIUtil.ShowInfoDialog(controlGroup, Strings.Connecting, "<LOC _Cancel>", CleanupAndExit)
    end

    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED " .. reason)
        if connectingDialog then
            connectingDialog:Destroy()
        end

        connectionFailedDialog = UIUtil.ShowInfoDialog(controlGroup, LOCF(Strings.ConnectionFailed, reason), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        LOG("LAUNCH FAILED")
        if connectingDialog then
            connectingDialog:Destroy()
        end

        local failedDlg = UIUtil.ShowInfoDialog(controlGroup, LOCF(Strings.LaunchFailed,LOC(reasonKey)), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.Ejected = function(self, reason)
        LOG("EJECTED " .. reason)
        if connectingDialog then
            connectingDialog:Destroy()
        end

        local failedDlg = UIUtil.ShowInfoDialog(controlGroup, Strings.Ejected, CleanupAndExit)
    end

    lobbyComm.ConnectionToHostEstablished = function(self,myID,newLocalName,theHostID)
        LOG("CONNECTED TO HOST")
        if currentDialog then
            currentDialog:Destroy()
        end
        hostID = theHostID
        localPlayerName = newLocalName
        localPlayerID = myID

        -- Ok, I'm connected to the host. Now request to become a player
        lobbyComm:SendData(hostID, { Type = 'AddPlayer', PlayerInfo = MakeLocalPlayerInfo(newLocalName), })
    end

    lobbyComm.DataReceived = function(self,data)
        LOG('DATA RECEIVED: ', repr(data))

        if data.Type == 'LaunchStatus' then
            peerLaunchStatuses[data.SenderID] = data.Status
            return
        end

        if lobbyComm:IsHost() then
            # Host Messages
            if data.Type == 'AddPlayer' then
                HostAddPlayer(data.SenderID, data.PlayerInfo)
            end
        else
            # Non-Host Messages
            if data.Type == 'Launch' then
                LOG(repr(data.GameInfo))
                local hostOptions = table.copy(data.GameInfo.GameOptions)
                -- The host options contain some extra data that we don't care about
                hostOptions['Ratings'] = nil
                hostOptions['ScenarioFile'] = nil
                -- This is a sanity check so we don't accidentally launch games
                -- with the wrong game settings because the host is using a
                -- client that doesn't support game options for matchmaker.
                if not table.equal(gameInfo.GameOptions, hostOptions) then
                    -- To distinguish this from regular failed connections
                    GpgNetSend('LaunchStatus', 'Rejected')

                    lobbyComm:BroadcastData({ Type = 'LaunchStatus', Status = 'Rejected' })
                    lobbyComm:LaunchFailed(Strings.MismatchedAutolobbyOptions)
                else
                    lobbyComm:BroadcastData({ Type = 'LaunchStatus', Status = 'Accepted' })
                    lobbyComm:LaunchGame(data.GameInfo)
                end
            end
        end
    end

    lobbyComm.SystemMessage = function(self, text)
        LOG("System: ",text)
    end

    lobbyComm.GameLaunched = function(self)
        GpgNetSend('GameState', 'Launching')
        parent:Destroy()
        parent = false
        MenuCommon.MenuCleanup()
        lobbyComm:Destroy()
        lobbyComm = false
    end

    lobbyComm.Hosting = function(self)
        localPlayerID = lobbyComm:GetLocalPlayerID()
        hostID = localPlayerID

        # Give myself the first slot
        HostAddPlayer(hostID, MakeLocalPlayerInfo(localPlayerName))

        # Fill in the desired scenario.

        gameInfo.GameOptions.ScenarioFile = self.desiredScenario
    end

    lobbyComm.EstablishedPeers = function(self, uid, peers)
        if not wasConnected(uid) then
            table.insert(connectedTo, uid)
        end
        if self:IsHost() then
            CheckForLaunch()
        end
    end

    lobbyComm.PeerDisconnected = function(self,peerName,peerID)
        LOG('>DEBUG> PeerDisconnected : peerName='..peerName..' peerID='..peerID)
        if IsPlayer(peerID) then
            local slot = FindSlotForID(peerID)
            if slot and lobbyComm:IsHost() then
                gameInfo.PlayerOptions[slot] = nil
            end
        end
    end

end


-- Create a new unconnected lobby.
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    if not parent then parent = UIUtil.CreateScreenGroup(GetFrame(0), "CreateLobby ScreenGroup") end
    -- don't parent background to screen group so it doesn't get destroyed until we leave the menus
    local background = MenuCommon.SetupBackground(GetFrame(0))
    local function OnAbort()
        MenuCommon.MenuCleanup()
        parent:Destroy()
        parent = false
        ExitApplication()
    end
    connectdialog = UIUtil.ShowInfoDialog(parent, Strings.TryingToConnect, Strings.AbortConnect, OnAbort)

    InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    localPlayerName = lobbyComm:GetLocalPlayerName()
end


-- create the lobby as a host
function HostGame(gameName, scenarioFileName, singlePlayer)
    CreateUI()

    requiredPlayers = 2
    local args = GetCommandLineArg("/players", 1)
    if args then
        requiredPlayers = tonumber(args[1])
        LOG("requiredPlayers was set to: "..requiredPlayers)
    end

    SetGameOptionsFromCommandLine()

    -- The guys at GPG were unable to make a standard for map. We dirty-solve it.
    lobbyComm.desiredScenario = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua")

    lobbyComm:HostGame()
end

-- join an already existing lobby
function JoinGame(address, asObserver, playerName, uid)
    LOG("Joingame (name=" .. playerName .. ", uid=" .. uid .. ", address=" .. address ..")")
    CreateUI()

    SetGameOptionsFromCommandLine()

    lobbyComm:JoinGame(address, playerName, uid)
end

function ConnectToPeer(addressAndPort,name,uid)
    if not string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
    else
        DisconnectFromPeer(uid)
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
    end
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if wasConnected(uid) then
        table.remove(connectedTo, uid)
    end
    GpgNetSend('Disconnected', string.format("%d", uid))
    lobbyComm:DisconnectFromPeer(uid)
end


function SetGameOptionsFromCommandLine()
    for name, value in GetCommandLineArgTable("/gameoptions") do
        if name and value then
            gameInfo.GameOptions[name] = value
        else
            LOG("Malformed gameoption. ignoring...")
        end
    end
end

-- Return a table parsed from key:value pairs passed on the command line
-- Example:
--  command line args: /arg key1:value1 key2:value2
--  GetCommandLineArgTable("/arg") -> {key1="value1", key2="value2"}
function GetCommandLineArgTable(option)
    -- Find total number of args
    local next = 1
    local args, nextArgs = nil, nil
    repeat
        nextArgs, args = GetCommandLineArg(option, next), nextArgs
        next = next + 1
    until not nextArgs

    -- Construct result table
    local result = {}
    if args then
        for _, arg in args do
            local pair = utils.StringSplit(arg, ":")
            local name, value = pair[1], pair[2]
            result[name] = value
        end
    end

    return result
end
