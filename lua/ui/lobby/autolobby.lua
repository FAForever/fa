--*****************************************************************************
--* File: lua/modules/ui/lobby/autolobby.lua
--* Author: Sam Demulling
--* Summary: Autolaunching games from GPGNet.  This is intentionally designed
--* to have no user options as GPGNet is setting them for the player.
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local LobbyComm = import('/lua/ui/lobby/lobbyComm.lua')
local gameColors = import('/lua/gameColors.lua').GameColors





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
        GameSpeed = 'normal',
        FogOfWar = 'explored',
        UnitCap = '1000',
        Ranked = true,
        PrebuiltUnits = 'Off',
    },
    PlayerOptions = {},
    Observers = {},
    GameMods = {},
}

local Strings = LobbyComm.Strings

local lobbyComm = false


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
    result.Rank = tonumber(GetCommandLineArg("/rank", 1)[1])
	result.StartSpot = tonumber(GetCommandLineArg("/StartSpot", 1)[1])
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

local function HostAddPlayer(senderId, playerInfo)
    playerInfo.OwnerID = senderId

    #the slot is not random...
    local slot = playerInfo.StartSpot

    -- while gameInfo.PlayerOptions[slot] do
    --     slot = slot + 1
    -- end

    playerInfo.PlayerName = lobbyComm:MakeValidPlayerName(playerInfo.OwnerID,playerInfo.PlayerName)

    # figure out a reasonable default color
    for colorIndex,colorVal in gameColors.PlayerColors do
        if IsColorFree(colorIndex) then
            playerInfo.PlayerColor = colorIndex
            break
        end
    end

    gameInfo.PlayerOptions[slot] = playerInfo
end


local function CheckForLaunch()

    local important = {}
    for slot,player in gameInfo.PlayerOptions do
        GpgNetSend('PlayerOption', string.format("startspot %s %d %s", player.PlayerName, slot, slot))
        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end

    #counts the number of players in the game.  Include yourself by default.
    local playercount = 1
    for k,id in important do
        if id != localPlayerID then
            local peer = lobbyComm:GetPeer(id)
            if peer.status != 'Established' then
                LOG("No connection to a player")
                return
            end
            if not table.find(peer.establishedPeers, localPlayerID) then
                LOG("No establishedPeers to a player")
                return
            end
            playercount = playercount + 1
            for k2,other in important do
                if id != other and not table.find(peer.establishedPeers, other) then
                    LOG("No establishedPeers between two players")
                    return
                end
            end
        end
    end

    if playercount < requiredPlayers then
        LOG("No enough players in the game")
       return
    end
    
    local allRanks = {}
    for k,v in gameInfo.PlayerOptions do
        if v.Human and v.Rank then
            allRanks[v.PlayerName] = v.Rank
        end
    end
    gameInfo.GameOptions['Ranks'] = allRanks

    LOG("Host launching game.")
    lobbyComm:BroadcastData( { Type = 'Launch', GameInfo = gameInfo } )
    LOG(repr(gameInfo))
    lobbyComm:LaunchGame(gameInfo)
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
    controlGroup.Width:Set(970)
    controlGroup.Height:Set(670)

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
        if connectingDialog then
            connectingDialog:Destroy()
        end

        connectionFailedDialog = UIUtil.ShowInfoDialog(controlGroup, LOCF(Strings.ConnectionFailed, reason), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        if connectingDialog then
            connectingDialog:Destroy()
        end

        local failedDlg = UIUtil.ShowInfoDialog(controlGroup, LOCF(Strings.LaunchFailed,LOC(reasonKey)), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.Ejected = function(self)
        if connectingDialog then
            connectingDialog:Destroy()
        end

        local failedDlg = UIUtil.ShowInfoDialog(controlGroup, Strings.Ejected, CleanupAndExit)
    end

    lobbyComm.ConnectionToHostEstablished = function(self,myID,newLocalName,theHostID)
        LOG('********** ConnectionToHostEstablished() called')
		
        if connectingDialog then
            connectingDialog:Destroy()
        end
        hostID = theHostID
        localPlayerName = newLocalName
        localPlayerID = myID

		GpgNetSend('connectedToHost', string.format("%d", hostID))
		
        # Ok, I'm connected to the host. Now request to become a player
        lobbyComm:SendData( hostID, { Type = 'AddPlayer', PlayerInfo = MakeLocalPlayerInfo(newLocalName), } )
    end

    lobbyComm.DataReceived = function(self,data)
        LOG('DATA RECEIVED: ', repr(data))

        if lobbyComm:IsHost() then
            # Host Messages
            if data.Type == 'AddPlayer' then
                HostAddPlayer( data.SenderID, data.PlayerInfo )
            end
        else
            # Non-Host Messages
            if data.Type == 'Launch' then
                LOG(repr(data.GameInfo))
                lobbyComm:LaunchGame(data.GameInfo)
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
		GpgNetSend('Connected', string.format("%d", uid))
        if self:IsHost() then
            CheckForLaunch()
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
        #LOG("requiredPlayers was set to: "..requiredPlayers)
    end

    
    -- For GW, the scenario file is automatically generated.
    lobbyComm.desiredScenario = '/maps/gwScenario/gw_scenario.lua'


    lobbyComm:HostGame()
end

-- join an already existing lobby
function JoinGame(address, asObserver, playerName, uid)
    CreateUI()

    lobbyComm:JoinGame(address, playerName, uid);
end

function ConnectToPeer(addressAndPort,name,uid)
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    lobbyComm:DisconnectFromPeer(uid)
end

