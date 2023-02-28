--*****************************************************************************
--* File: lua/modules/ui/lobby/autolobby.lua
--* Author: Sam Demulling
--* Summary: Autolaunching games from GPGNet.  This is intentionally designed
--* to have no user options as GPGNet is setting them for the player.
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
--* FAF notes:
--* Automatch games are configured by the lobby server by sending parameters
--* to the FAF client which then relays that configuration to autolobby.lua
--* through command line arguments.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local MenuCommon = import("/lua/ui/menus/menucommon.lua")
local LobbyComm = import("/lua/ui/lobby/lobbycomm.lua")
local gameColors = import("/lua/gamecolors.lua").GameColors
local utils = import("/lua/system/utils.lua")

local ConnectionStatus = import("/lua/ui/lobby/autolobby-classes.lua").ConnectionStatus



local parent = false
local localPlayerName = false
local requiredPlayers = false

local currentDialog = false
local connectionStatusGUI = false 

local localPlayerID = false


--- The default game information for an automatch. This should typically never be changed directly
-- as the server can change game options as it wishes since PR 3385.
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
        UnitCap = '1500',
        PrebuiltUnits = 'Off',
        Share = 'FullShare',
        ShareUnitCap = 'allies',
        DisconnectionDelay02 = '90',

        -- yep, great
        Ranked = true,
        Unranked = 'No',
    },
    PlayerOptions = {},
    Observers = {},
    GameMods = {},
}

local Strings = LobbyComm.Strings

local lobbyComm = false

local connectedTo = {}
local peerLaunchStatuses = {}

-- Cancels automatching and closes the game
local function CleanupAndExit()
    if lobbyComm then
        lobbyComm:Destroy()
    end
    ExitApplication()
end

-- Replace the currently displayed dialog (there is only 1).
local function SetDialog(...)
    if currentDialog then
        currentDialog:Destroy()
    end

    currentDialog = UIUtil.ShowInfoDialog(unpack(arg))
end

-- Create PlayerInfo for our local player from command line options
local function MakeLocalPlayerInfo(name)
    local result = LobbyComm.GetDefaultPlayerOptions(name)
    result.Human = true

    local factionData = import("/lua/factions.lua")

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
    result.DIV = (GetCommandLineArg("/division", 1)[1]) or ""
    result.SUBDIV = (GetCommandLineArg("/subdivision", 1)[1]) or ""
    result.PL = math.floor(result.MEAN - 3 * result.DEV)
    LOG('Local player info: ' .. repr(result))
    return result
end

function wasConnected(peer)
    return table.find(connectedTo, peer) ~= nil
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
    playerInfo.PlayerColor = gameColors.TMMColorOrder[slot]

    gameInfo.PlayerOptions[slot] = playerInfo
end

--- Waits to receive confirmation from all players as to whether they share the same
-- game options. Is used to reject a game when this is not the case. Typically
-- this happens when the players do not share the same (FAF) client.
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

-- Check if we can launch the game and then do so. To launch the game we need
-- to be connected to the correct number of players as configured by the
-- command line args.
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

    -- counts the number of players in the game. Include yourself by default.
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
    local allDivisions = {}
    for k,v in gameInfo.PlayerOptions do
        if v.Human and v.PL then
            allRatings[v.PlayerName] = v.PL
            allDivisions[v.PlayerName]= v.DIV .. v.SUBDIV
            -- Initialize peer launch statuses
            peerLaunchStatuses[v.OwnerID] = false
        end
    end
    -- We don't need to wait for a launch status from ourselves
    peerLaunchStatuses[localPlayerID] = nil
    gameInfo.GameOptions['Ratings'] = allRatings
    gameInfo.GameOptions['Divisions'] = allDivisions

    LOG("Host launching game.")
    lobbyComm:BroadcastData({ Type = 'Launch', GameInfo = gameInfo })
    LOG(repr(gameInfo))

    ForkThread(function()
        if WaitLaunchAccepted() then
            lobbyComm:LaunchGame(gameInfo)
            return
        end

        LOG("Some players rejected the launch! " .. repr(peerLaunchStatuses))
        SetDialog(parent, Strings.LaunchRejected, "<LOC _Exit>", CleanupAndExit)
    end)
end


local function CreateUI()

    LOG("Don't mind me x2")

    if currentDialog ~= false then
        MenuCommon.MenuCleanup()
        currentDialog:Destroy()
        currentDialog = false
    end

    -- control layout
    if not parent then parent = UIUtil.CreateScreenGroup(GetFrame(0), "Lobby CreateUI ScreenGroup") end

    local background = MenuCommon.SetupBackground(GetFrame(0))

    SetDialog(parent, "<LOC lobui_0201>Setting up automatch...")

    -- construct the connection status GUI and position it right below the dialog
    connectionStatusGUI = ConnectionStatus(GetFrame(0))
    LayoutHelpers.CenteredBelow(connectionStatusGUI, currentDialog, 20)
    LayoutHelpers.DepthOverParent(connectionStatusGUI, background, 1)
end


--  LobbyComm Callbacks
local function InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    local LobCreateFunc = import("/lua/ui/lobby/lobbycomm.lua").CreateLobbyComm
    local lob = LobCreateFunc(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    if not lob then
        error('Creating lobby using protocol ' .. repr(protocol) .. ' and port ' .. tostring(localPort) .. ' failed.')
    end
    lobbyComm = lob

    lobbyComm.Connecting = function(self)
        SetDialog(parent, Strings.Connecting, "<LOC _Cancel>", CleanupAndExit)
    end

    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED " .. reason)
        SetDialog(parent, LOCF(Strings.ConnectionFailed, reason), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.LaunchFailed = function(self, reasonKey)
        LOG("LAUNCH FAILED")
        SetDialog(parent, LOCF(Strings.LaunchFailed,LOC(reasonKey)), "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.Ejected = function(self, reason)
        LOG("EJECTED " .. reason)
        SetDialog(parent, Strings.Ejected, "<LOC _OK>", CleanupAndExit)
    end

    lobbyComm.ConnectionToHostEstablished = function(self, myID, newLocalName, theHostID)
        LOG("CONNECTED TO HOST")
        hostID = theHostID
        localPlayerName = newLocalName
        localPlayerID = myID

        -- Ok, I'm connected to the host. Now request to become a player
        self:SendData(hostID, { Type = 'AddPlayer', PlayerInfo = MakeLocalPlayerInfo(newLocalName), })
    end

    lobbyComm.DataReceived = function(self, data)
        LOG('DATA RECEIVED: ', reprsl(data))

        if data.Type == 'LaunchStatus' then
            peerLaunchStatuses[data.SenderID] = data.Status
            return
        end

        if self:IsHost() then
            --  Host Messages
            if data.Type == 'AddPlayer' then
                HostAddPlayer(data.SenderID, data.PlayerInfo)
            end
        else
            --  Non-Host Messages
            if data.Type == 'Launch' then
                -- The client compares the game options with those of the host. They both look like the local 'gameInfo' as defined 
                -- above, but the host adds these fields upon launch (see: CheckForLaunch) so that we can display them on the scoreboard. 
                -- A client won't have this information attached, and therefore we remove it manually here
                local hostOptions = table.copy(data.GameInfo.GameOptions)
                hostOptions['Ratings'] = nil
                hostOptions['ScenarioFile'] = nil
                hostOptions['Divisions'] = nil

                -- This is a sanity check so we don't accidentally launch games
                -- with the wrong game settings because the host is using a
                -- client that doesn't support game options for matchmaker.
                if not table.equal(gameInfo.GameOptions, hostOptions) then
                    WARN("Game options missmatch!")

                    LOG("Client settings: ")
                    reprsl(gameInfo.GameOptions)

                    LOG("Host settings: ")
                    reprsl(hostOptions)

                    SetDialog(parent, Strings.LaunchRejected, "<LOC _Exit>", CleanupAndExit)

                    self:BroadcastData({ Type = 'LaunchStatus', Status = 'Rejected' })
                    -- To distinguish this from regular failed connections
                    GpgNetSend('LaunchStatus', 'Rejected')
                else
                    self:BroadcastData({ Type = 'LaunchStatus', Status = 'Accepted' })
                    self:LaunchGame(data.GameInfo)
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
        localPlayerID = self:GetLocalPlayerID()
        hostID = localPlayerID

        --  Give myself the first slot
        HostAddPlayer(hostID, MakeLocalPlayerInfo(localPlayerName))

        --  Fill in the desired scenario.
        gameInfo.GameOptions.ScenarioFile = self.desiredScenario
    end

    lobbyComm.EstablishedPeers = function(self, uid, peers)
        if not wasConnected(uid) then
            table.insert(connectedTo, uid)
        end

        -- update ui to inform players
        connectionStatusGUI:SetPlayersConnectedCount(table.getn(connectedTo))

        if self:IsHost() then
            CheckForLaunch()
        end
    end

    lobbyComm.PeerDisconnected = function(self, peerName, peerID)
        LOG('>DEBUG> PeerDisconnected : peerName='..peerName..' peerID='..peerID)
        if IsPlayer(peerID) then
            local slot = FindSlotForID(peerID)
            if slot and self:IsHost() then
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

    -- construct the initial dialog
    SetDialog(parent, Strings.TryingToConnect)

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

    -- update the connection status GUI
    connectionStatusGUI:SetTotalPlayersCount(requiredPlayers)

    -- The guys at GPG were unable to make a standard for map. We dirty-solve it.
    lobbyComm.desiredScenario = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua")

    lobbyComm:HostGame()
end

-- join an already existing lobby
function JoinGame(address, asObserver, playerName, uid)
    LOG("Joingame (name=" .. playerName .. ", uid=" .. uid .. ", address=" .. address ..")")
    CreateUI()

    -- TODO: I'm not sure if this argument is passed along when you are joining a lobby
    requiredPlayers = 2
    local args = GetCommandLineArg("/players", 1)
    if args then
        requiredPlayers = tonumber(args[1])
        LOG("requiredPlayers was set to: "..requiredPlayers)
    end

    SetGameOptionsFromCommandLine()

    -- update the connection status GUI
    connectionStatusGUI:SetTotalPlayersCount(requiredPlayers)

    lobbyComm:JoinGame(address, playerName, uid)
end

function ConnectToPeer(addressAndPort,name,uid)
    if not string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
    else
        DisconnectFromPeer(uid, true)
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
    end

    -- update ui to inform players
    connectionStatusGUI:AddConnectedPlayer()

    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid, doNotUpdateView)
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if wasConnected(uid) then
        table.remove(connectedTo, uid)
    end
    GpgNetSend('Disconnected', string.format("%d", uid))

    -- sometimes we disconnect immediately, but secretly connect through a proxy
    if not doNotUpdateView then 
        connectionStatusGUI:RemoveConnectedPlayer()
    end

    lobbyComm:DisconnectFromPeer(uid)
end


function SetGameOptionsFromCommandLine()
    for name, value in utils.GetCommandLineArgTable("/gameoptions") do
        if name and value then
            gameInfo.GameOptions[name] = value
        else
            LOG("Malformed gameoption. ignoring name: " .. repr(name) .. " and value: " .. repr(value))
        end
    end
end
