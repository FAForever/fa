--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Chris Blackwell
--* Summary: Game selection UI
--*
--* Copyright © 2005 Gas Powered Games, Inc. All rights reserved.
--*****************************************************************************

LOBBYversion = import('/lua/version.lua').GetLobbyVersion()
LOG('Lobby version : '..LOBBYversion)

local UIUtil = import('/lua/ui/uiutil.lua')
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local Prefs = import('/lua/user/prefs.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local Group = import('/lua/maui/group.lua').Group
local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local LobbyComm = import('/lua/ui/lobby/lobbyComm.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Mods = import('/lua/mods.lua')
--local ModManager = import('/lua/ui/dialogs/modmanager.lua')
local FactionData = import('/lua/factions.lua')
local Text = import('/lua/maui/text.lua').Text
local Trueskill = import('/lua/ui/lobby/trueskill.lua')
local round = import('/lua/ui/lobby/trueskill.lua').round
local Player = import('/lua/ui/lobby/trueskill.lua').Player
local Rating = import('/lua/ui/lobby/trueskill.lua').Rating
local Teams = import('/lua/ui/lobby/trueskill.lua').Teams

local IsSyncReplayServer = false

if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") then
    IsSyncReplayServer = true
end

local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOpts = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts
local gameColors = import('/lua/gameColors.lua').GameColors
local numOpenSlots = LobbyComm.maxPlayerSlots

-- Maps faction identifiers to their names.
local FACTION_NAMES = {[1] = "uef", [2] = "aeon", [3] = "cybran", [4] = "seraphim", [5] = "random"}

local formattedOptions = {}
local nonDefaultFormattedOptions = {}
local Warning_MAP = false

local teamIcons = {
    '/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
    '/lobby/team_icons/team_5_icon.dds',
    '/lobby/team_icons/team_6_icon.dds',
}

DebugEnabled = Prefs.GetFromCurrentProfile('LobbyDebug') or ''
local HideDefaultOptions = Prefs.GetFromCurrentProfile('LobbyHideDefaultOptions') == 'true'
function LOGX(text, ttype)
	-- onlyChat = for debug only in the Chat
	-- onlyLOG = for debug only in the LOG
	-- CLEAR = for disable the debug
	-- Country, RuleTitle, Background
	-- Disconnected, Connecting, UpdateGame
	local text = tostring(text)
	local onlyLOG = string.find(DebugEnabled, 'onlyLOG') or nil
	local onlyChat = string.find(DebugEnabled, 'onlyChat') or nil
	if ttype == nil then
		LOG(text)
	else
		if string.find(DebugEnabled, ttype) and ttype ~= nil then
			if onlyLOG ~= nil then
				LOG(text)
			elseif onlyChat ~= nil then
				AddChatText(text)
			else
				LOG(text)
				AddChatText(text)
			end
		end
	end
end
-- Table of Tooltip Country
local PrefLanguageTooltipTitle={}
local PrefLanguageTooltipText={}

local FACTION_PANELS = {}

local PrefLanguage = GetCommandLineArg("/country", 1)
if PrefLanguage[1] == '' or PrefLanguage[1] == '/init' or PrefLanguage == nil or PrefLanguage == false then
    LOG('COUNTRY - Country has not been found "'..tostring(PrefLanguage[1])..'"')
    PrefLanguage = "world"
else
    PrefLanguage = tostring(string.lower(PrefLanguage[1]))
end

local connectedTo = {} -- by UID
CurrentConnection = {} -- by Name
ConnectionEstablished = {} -- by Name
ConnectedWithProxy = {} -- by UID

Avail_Color = {} -- Color Only Availaible
BASE_ALL_Color = gameColors.PlayerColors -- Copy color table

local availableMods = {} -- map from peer ID to set of available mods; each set is a map from "mod id"->true
local selectedMods = nil

local commandQueueIndex = 0
local commandQueue = {}

local quickRandMap = true

local lastUploadedMap = nil

local CPU_Benchmarks = {} -- Stores CPU benchmark data

local playerMean = GetCommandLineArg("/mean", 1)
local playerDeviation = GetCommandLineArg("/deviation", 1)

local ratingColor = GetCommandLineArg("/ratingcolor", 1)
local numGames = GetCommandLineArg("/numgames", 1)


if ratingColor then
    ratingColor = tostring(ratingColor[1])
else
    ratingColor = "ffffffff"
end

if numGames then
    numGames = tonumber(numGames[1])
else
    numGames = 0
end

if playerMean then
    playerMean = tonumber(playerMean[1])
else
    playerMean = 1500
end

if playerDeviation then
    playerDeviation = tonumber(playerDeviation[1])
else
    playerDeviation = 500
end



local playerRating = math.floor( Trueskill.round2((playerMean - 3 * playerDeviation) / 100.0) * 100 )

-- builds the faction tables, and then adds random faction icon to the end
local factionBmps = {}
local factionTooltips = {}
for index, tbl in FactionData.Factions do
    factionBmps[index] = tbl.SmallIcon
    factionTooltips[index] = tbl.TooltipID
end
local teamTooltips = {
    'lob_team_none',
    'lob_team_one',
    'lob_team_two',
    'lob_team_three',
    'lob_team_four',
    'lob_team_five',
    'lob_team_six',
}
table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
table.insert(factionTooltips, 'lob_random')

local teamNumbers = {
    "<LOC _No>",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
}

local function ParseWhisper(params)
    local delimStart = string.find(params, " ")
    if delimStart then
        local name = string.sub(params, 1, delimStart-1)
        local targID = FindIDForName(name)
        if targID then
            PrivateChat(targID, string.sub(params, delimStart+1))
        else
            AddChatText(LOC("<LOC lobby_0007>Invalid whisper target."))
        end
    end
end

local function LOGXWhisper(params)
	-- Exemple : Country Background useChat'
	if string.find(params, 'CLEAR') then
		DebugEnabled = ''
		Prefs.SetToCurrentProfile('LobbyDebug', '')
		AddChatText('Debug disabled')
	else
        DebugEnabled = params
		Prefs.SetToCurrentProfile('LobbyDebug', params)
		AddChatText('Debug actived : '..params)
	end
end

local commands = {
    {
        key = 'pm',
        action = ParseWhisper,
    },
    {
        key = 'private',
        action = ParseWhisper,
    },
    {
        key = 'w',
        action = ParseWhisper,
    },
    {
        key = 'whisper',
        action = ParseWhisper,
    },
	{
        key = 'debug',
        action = LOGXWhisper,
    },
}

local Strings = LobbyComm.Strings

local lobbyComm = false
local wantToBeObserver = false
local localPlayerName = ""
local gameName = ""
local hostID = false
local singlePlayer = false
local GUI = false
local localPlayerID = false
local gameInfo = false
local pmDialog = false

local hasSupcom = true
local hasFA = true

local defaultMode =(HasCommandLineArg("/windowed") and "windowed") or Prefs.GetFromCurrentProfile('options').primary_adapter
local windowedMode = defaultMode == "windowed" or (HasCommandLineArg("/windowed"))

function SetWindowedLobby(windowed)
    -- Dont change resolution if user already using windowed mode
    if windowed == windowedMode or defaultMode == 'windowed' then
        return
    end

    if windowed then
        ConExecute('SC_PrimaryAdapter windowed')
    else
        ConExecute('SC_PrimaryAdapter ' .. tostring(defaultMode))
    end

    windowedMode = windowed
end

-- String from which to build the various "Move player to slot" labels.
-- TODO: This probably needs localising.
local move_player_to_slot = "Move Player to slot "
local slotMenuStrings = {
    open = "<LOC lobui_0219>Open",
    close = "<LOC lobui_0220>Close",
    closed = "<LOC lobui_0221>Closed",
    occupy = "<LOC lobui_0222>Occupy",
    pm = "<LOC lobui_0223>Private Message",
    remove_to_kik = "Remove Player",
    remove_to_observer = "Move Player to Observer",
}
local slotMenuData = {
    open = {
        host = {
            'close',
            'occupy',
            'ailist',
        },
        client = {
            'occupy',
        },
    },
    closed = {
        host = {
            'open',
        },
        client = {
        },
    },
    player = {
        host = {
            'pm',
            'remove_to_observer',
            'remove_to_kik',
        },
        client = {
            'pm',
        },
    },
    ai = {
        host = {
            'remove_to_kik',
            'ailist',
        },
        client = {
        },
    },
}

-- Populate the tables with the "move player to slot X" entries.
for i = 1, numOpenSlots, 1 do
    table.insert(slotMenuData.player.host, 'move_player_to_slot'..i)
    slotMenuStrings['move_player_to_slot' .. i] = move_player_to_slot .. i
end

local function GetAITooltipList()
    local aitypes = import('/lua/ui/lobby/aitypes.lua').aitypes
    local retTable = {}
    --this is to fix tooltip problem
    for i = 1, 2 do
        table.insert(retTable, nil)
    end
    --end new faf part
    for i, v in aitypes do
        table.insert(retTable, 'aitype_'..v.key)
    end
    return retTable
end

local function GetSlotMenuTables(stateKey, hostKey)
    local keys = {}
    local strings = {}

    if not slotMenuData[stateKey] then
        WARN("Invalid slot menu state selected: " .. stateKey)
        return nil
    end

    if not slotMenuData[stateKey][hostKey] then
        WARN("Invalid slot menu host key selected: " .. hostKey)
        return nil
    end

    local isPlayerReady = false
    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        if gameInfo.PlayerOptions[localPlayerSlot].Ready then
            isPlayerReady = true
        end
    end

    for index, key in slotMenuData[stateKey][hostKey] do
        if key == 'ailist' then
            local aitypes = import('/lua/ui/lobby/aitypes.lua').aitypes
            for aiindex, aidata in aitypes do
                table.insert(keys, aidata.key)
                table.insert(strings, aidata.name)
            end
        else
            if not (isPlayerReady and key == 'occupy') then
                table.insert(keys, key)
                table.insert(strings, slotMenuStrings[key])
            end
        end
    end

    return keys, strings
end

-- Called by the host when a "move player to slot X" option is clicked.
local function HandleSlotSwitches(moveFrom, moveTo)
    -- Bail out early for the stupid cases.
    if moveFrom == moveTo then
        AddChatText('You cannot move the Player in slot '..moveFrom..' to the same slot!')
        return
    end

    local fromOpts = gameInfo.PlayerOptions[moveFrom]
    local toOpts = gameInfo.PlayerOptions[moveTo]

    if not fromOpts.Human then
        AddChatText('You cannot move the Player in slot '..moveFrom..' because they are not human.')
        return
    end

    -- If we're moving a human onto an AI, evict the AI and move the player into the space.
    if not toOpts.Human then
        HostRemoveAI(moveTo)
        HostTryMovePlayer(fromOpts.OwnerID, moveFrom, moveTo)
        return
    end

    -- So we're switching two humans. (or moving a human to a blank).
    -- Clear the ready flag for both targets.
    setPlayerNotReady(moveTo)
    setPlayerNotReady(moveFrom)

    HostConvertPlayerToObserver(toOpts.OwnerID, toOpts.PlayerName, moveTo, false) -- Move Slot moveTo to Observer
    HostTryMovePlayer(fromOpts.OwnerID, moveFrom, moveTo) -- Move Player moveFrom to Slot moveTo
    HostConvertObserverToPlayer(toOpts.OwnerID, toOpts.PlayerName, FindObserverSlotForID(toOpts.OwnerID), moveFrom, toOpts.Faction, toOpts.PL, toOpts.RC, toOpts.NG, false)
    SendSystemMessage(fromOpts.PlayerName..' has switched with '..toOpts.PlayerName, 'switch')
end

-- Instruct a player to unset their "ready" status. Should be called only by the host.
local function setPlayerNotReady(slot)
    local slotOptions = gameInfo.PlayerOptions[slot]
    if slotOptions.Ready then
        if not IsLocallyOwned(slot) then
            lobbyComm:SendData(slotOptions.OwnerID, {Type = 'SetPlayerNotReady', Slot = slot})
        end
        gameInfo.PlayerOptions[slot]['Ready'] = false
    end
end

local function DoSlotBehavior(slot, key, name)
    if key == 'open' then
        if lobbyComm:IsHost() then
            HostOpenSlot(hostID, slot)
        end
    elseif key == 'close' then
        if lobbyComm:IsHost() then
            HostCloseSlot(hostID, slot)
        end
    elseif key == 'occupy' then
        if IsPlayer(localPlayerID) then
            if lobbyComm:IsHost() then
                HostTryMovePlayer(hostID, FindSlotForID(localPlayerID), slot)
            else
                lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID),
                                   RequestedSlot = slot})
            end
        elseif IsObserver(localPlayerID) then
            if lobbyComm:IsHost() then
                local requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
                HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID), slot,
                                            requestedFaction, playerRating, ratingColor, numGames)
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName, ObserverSlot =
                                   FindObserverSlotForID(localPlayerID), PlayerSlot = slot, requestedFaction =
                                   Prefs.GetFromCurrentProfile('LastFaction'), requestedPL = playerRating,
                                   requestedRC = ratingColor, requestedNG = numGames})
            end
        end
    elseif key == 'pm' then
        if gameInfo.PlayerOptions[slot].Human then
            GUI.chatEdit:SetText(string.format("/whisper %s ", gameInfo.PlayerOptions[slot].PlayerName))
        end
    -- Handle the various "Move to slot X" options.
    elseif string.sub(key, 1, 19) == 'move_player_to_slot' then
        HandleSlotSwitches(slot, tonumber(string.sub(key, 20)))
    elseif key == 'remove_to_observer' then
        if gameInfo.PlayerOptions[slot].Human then
            HostConvertPlayerToObserver(gameInfo.PlayerOptions[slot].OwnerID, gameInfo.PlayerOptions[slot].PlayerName, slot)
        end
        --\\ Stop Move Player slot to Observer
    elseif key == 'remove_to_kik' then
        if gameInfo.PlayerOptions[slot].Human then
            UIUtil.QuickDialog(GUI, "<LOC lobui_0166>Are you sure?",
                               "<LOC lobui_0167>Kick Player",
                               function() lobbyComm:EjectPeer(gameInfo.PlayerOptions[slot].OwnerID, "KickedByHost") end,
                               "<LOC _Cancel>", nil,
                               nil, nil,
                               true,
                               {worldCover = false, enterButton = 1, escapeButton = 2})
        else
            if lobbyComm:IsHost() then
                HostRemoveAI(slot)
            else
                lobbyComm:SendData( hostID, { Type = 'ClearSlot', Slot = slot } )
            end
        end
    else
        if lobbyComm:IsHost() then
            local color = false
            local faction = false
            local team = false
            if gameInfo.PlayerOptions[slot] then
                color = gameInfo.PlayerOptions[slot].PlayerColor
                team = gameInfo.PlayerOptions[slot].Team
                faction = gameInfo.PlayerOptions[slot].Faction
            end
            HostTryAddPlayer(hostID, slot, name, false, key, color, faction, team)
        end
    end
end --\\ End DoSlotBehavior()

local function GetLocallyAvailableMods()
    local result = {}
    for k,mod in Mods.AllMods() do
        if not mod.ui_only then
            result[mod.uid] = true
        end
    end
    return result
end

local function IsModAvailable(modId)
    for k,v in availableMods do
        if not v[modId] then
            return false
        end
    end
    return true
end


function Reset()
    lobbyComm = false
    wantToBeObserver = false
    localPlayerName = ""
    gameName = ""
    hostID = false
    singlePlayer = false
    GUI = false
    localPlayerID = false
    availableMods = {}
    selectedMods = nil
    numOpenSlots = LobbyComm.maxPlayerSlots
    gameInfo = {
        GameOptions = {},
        PlayerOptions = {},
        Observers = {},
        ClosedSlots = {},
        GameMods = {},
        AutoTeams = {},
    }
end

-- Create a new unconnected lobby.
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior,
                     playerHasSupcom)
    if IsSyncReplayServer then
        SetFrontEndData('syncreplayid',localPlayerUID)
        dl = UIUtil.QuickDialog(GetFrame(0), "Downloading the replay file...")
        LaunchReplaySession('gpgnet://' .. GetCommandLineArg('/gpgnet',1)[1] .. '/' .. import('/lua/user/prefs.lua').GetFromCurrentProfile('Name'))
        dl:Destroy()
        UIUtil.QuickDialog(GetFrame(0), "You dont have this map.", "Exit", function() ExitApplication() end)
    else
        -- default to true, if the param is nil, then not playing through GPGnet
        if playerHasSupcom == nil or playerHasSupcom == true then
            hasSupcom = true
        else
            hasSupcom = true
        end

        Reset()

        if GUI then
            WARN('CreateLobby called but I already have one setup...?')
            GUI:Destroy()
        end

        GUI = UIUtil.CreateScreenGroup(over, "CreateLobby ScreenGroup")


        GUI.exitBehavior = exitBehavior


        GUI.optionControls = {}
        GUI.slots = {}

        GUI.connectdialog = UIUtil.ShowInfoDialog(GUI, Strings.TryingToConnect, Strings.AbortConnect, ReturnToMenu)
		GUI.connectdialog.Depth:Set(GetFrame(GUI:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 999)

        InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

        -- Store off the validated playername
        localPlayerName = lobbyComm:GetLocalPlayerName()
        local Prefs = import('/lua/user/prefs.lua')
        local windowed = Prefs.GetFromCurrentProfile('WindowedLobby') or 'false'
        SetWindowedLobby(windowed == 'true')
    end
end


-- create the lobby as a host
function HostGame(desiredGameName, scenarioFileName, inSinglePlayer)
    singlePlayer = inSinglePlayer
    gameName = lobbyComm:MakeValidGameName(desiredGameName)
    lobbyComm.desiredScenario = string.gsub(scenarioFileName, ".v%d%d%d%d_scenario.lua", "_scenario.lua")
    lobbyComm:HostGame()
end

-- join an already existing lobby
function JoinGame(address, asObserver, playerName, uid)
    wantToBeObserver = asObserver
    lobbyComm:JoinGame(address, playerName, uid);
end

function ConnectToPeer(addressAndPort,name,uid)
    if not string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
		LOGX('>> ConnectToPeer > name='..tostring(name), 'Connecting')
    else
        DisconnectFromPeer(uid)
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
		LOGX('>> ConnectToPeer > name='..tostring(name)..' (with PROXY)', 'Connecting')
        table.insert(ConnectedWithProxy, uid)
    end
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if wasConnected(uid) then
        table.remove(connectedTo, uid)
    end
	LOGX('>> DisconnectFromPeer > name='..tostring(FindNameForID(uid)), 'Disconnected')
    GpgNetSend('Disconnected', string.format("%d", uid))
    lobbyComm:DisconnectFromPeer(uid)
end

function SetHasSupcom(cmd)
    if IsSyncReplayServer then
        if cmd == 0 then
            SessionResume()
        elseif cmd == 1 then
            SessionRequestPause()
        end
    else
        hasSupcom = cmd -- was: supcomInstalled
    end
end

function SetHasForgedAlliance(speed)
    if IsSyncReplayServer then
        if GetGameSpeed() ~= speed then
            SetGameSpeed(speed)
        end
    else
        hadFA = speed -- was: faInstalled
    end
end

function FindSlotForID(id)
    for k,player in gameInfo.PlayerOptions do
        if player.OwnerID == id and player.Human then
            return k
        end
    end
    return nil
end

function FindNameForID(id)
    for k,player in gameInfo.PlayerOptions do
        if player.OwnerID == id and player.Human then
            return player.PlayerName
        end
    end
    return nil
end

function FindIDForName(name)
    for k,player in gameInfo.PlayerOptions do
        if player.PlayerName == name and player.Human then
            return player.OwnerID
        end
    end
    return nil
end

function FindObserverSlotForID(id)
    for k,observer in gameInfo.Observers do
        if observer.OwnerID == id then
            return k
        end
    end
    return nil
end

function IsLocallyOwned(slot)
    return (gameInfo.PlayerOptions[slot].OwnerID == localPlayerID)
end

function IsPlayer(id)
    return FindSlotForID(id) ~= nil
end

function IsObserver(id)
    return FindObserverSlotForID(id) ~= nil
end

-- Returns true if system messages are enabled.
function SystemMessagesEnabled()
    local LobbySystemMessagesEnabled = Prefs.GetFromCurrentProfile('LobbySystemMessagesEnabled') or 'true'
    return LobbySystemMessagesEnabled == 'true'
end


-- update the data in a player slot
function SetSlotInfo(slot, playerInfo)
	if (GUI.connectdialog ~= false) then -- Remove the ConnectDialog
		GUI.connectdialog:Destroy()
		GUI.connectdialog = false
	end
	local isLocallyOwned = IsLocallyOwned(slot)
    if isLocallyOwned then
        if gameInfo.PlayerOptions[slot]['Ready'] then
            DisableSlot(slot, true)
        else
            EnableSlot(slot)
        end
        if not hasSupcom then
            GUI.slots[slot].faction:Disable()
        end
    else
        DisableSlot(slot)
    end

    local hostKey
    if lobbyComm:IsHost() then
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    -- These states are used to select the appropriate strings with GetSlotMenuTables.
    local slotState
    if not playerInfo.Human then
        slotState = 'ai'
    elseif not isLocallyOwned then
        slotState = 'player'
    else
        slotState = nil
    end

    GUI.slots[slot].name:ClearItems()

    if slotState then
        GUI.slots[slot].name:Enable()
        local slotKeys, slotStrings = GetSlotMenuTables(slotState, hostKey)
        GUI.slots[slot].name.slotKeys = slotKeys
        if lobbyComm:IsHost() and slotState == 'ai' then
            Tooltip.AddComboTooltip(GUI.slots[slot].name, GetAITooltipList())
        else
            Tooltip.RemoveComboTooltip(GUI.slots[slot].name)
        end
        if table.getn(slotKeys) > 0 then
            GUI.slots[slot].name:AddItems(slotStrings)
            GUI.slots[slot].name:Enable()
        else
            GUI.slots[slot].name.slotKeys = nil
            GUI.slots[slot].name:Disable()
        end
    else
        -- no slotState indicate this must be ourself, and you can't do anything to yourself
        GUI.slots[slot].name.slotKeys = nil
        GUI.slots[slot].name:Disable()
    end

    GUI.slots[slot].ratingGroup:Show()
    --if playerInfo.MEAN == '-9999' then -- The player is a Smurf (Banned)
    --GUI.slots[slot].ratingText:SetText('Banned')
    --GUI.slots[slot].ratingText:SetColor('Crimson') --= --dc143c
    --else
    GUI.slots[slot].ratingText:SetText(playerInfo.PL or '')
    --end
    GUI.slots[slot].ratingText:SetColor(playerInfo.RC or 'ffffffff')

    GUI.slots[slot].numGamesGroup:Show()
    GUI.slots[slot].numGamesText:SetText(playerInfo.NG or "")

    GUI.slots[slot].name:Show()
    -- Color the Name in Slot by State
    if slotState == 'ai' then
        GUI.slots[slot].name:SetTitleTextColor("dbdbb9") -- Beige Color for AI
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    elseif FindSlotForID(hostID) == slot then
        GUI.slots[slot].name:SetTitleTextColor("ffc726") -- Orange Color for Host
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
    elseif slotState == 'player' then
        GUI.slots[slot].name:SetTitleTextColor("64d264") -- Green Color for Players
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
    elseif isLocallyOwned then
        GUI.slots[slot].name:SetTitleTextColor("6363d2") -- Blue Color for You
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
    else
        GUI.slots[slot].name:SetTitleTextColor(UIUtil.fontColor) -- Normal Color for Other
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    end

    --\\ Stop - Color the Name in Slot by State
    if wasConnected(playerInfo.OwnerID) or isLocallyOwned then
        GUI.slots[slot].name:SetTitleText(playerInfo.PlayerName)
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
        if SystemMessagesEnabled() then
            if not table.find(ConnectionEstablished, playerInfo.PlayerName) then
                if playerInfo.Human and not isLocallyOwned then
                    if table.find(ConnectedWithProxy, playerInfo.OwnerID) then
                        AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", playerInfo.PlayerName)..' (FAF Proxy)', "Engine0004")
                    else
                        AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", playerInfo.PlayerName), "Engine0004")
                    end
                    table.insert(ConnectionEstablished, playerInfo.PlayerName)
                    for k, v in CurrentConnection do -- Remove PlayerName in this Table
                        if v == playerInfo.PlayerName then
                            CurrentConnection[k] = nil
                            break
                        end
                    end
                end
            end
        end
    else
        GUI.slots[slot].name:SetTitleText('Connecting to ... ' .. playerInfo.PlayerName)
        GUI.slots[slot].name._text:SetFont('Arial Gras', 11)
        if SystemMessagesEnabled() then
            if not table.find(CurrentConnection, playerInfo.PlayerName) then
                AddChatText('Connecting to '..playerInfo.PlayerName..' ...')
                table.insert(CurrentConnection, playerInfo.PlayerName)
            end
        end
    end

    GUI.slots[slot].faction:Show()
    GUI.slots[slot].faction:SetItem(playerInfo.Faction)

    GUI.slots[slot].color:Show()
    Check_Availaible_Color(GUI.slots[slot].color, slot)
    --GUI.slots[slot].color:SetItem(playerInfo.PlayerColor)

    GUI.slots[slot].team:Show()
    GUI.slots[slot].team:SetItem(playerInfo.Team)

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', string.format("faction %s %d %s", playerInfo.PlayerName, slot, playerInfo.Faction))
        GpgNetSend('PlayerOption', string.format("color %s %d %s", playerInfo.PlayerName, slot, playerInfo.PlayerColor))
        GpgNetSend('PlayerOption', string.format("team %s %d %s", playerInfo.PlayerName, slot, playerInfo.Team))
        GpgNetSend('PlayerOption', string.format("startspot %s %d %s", playerInfo.PlayerName, slot, slot))
    end

    UIUtil.setVisible(GUI.slots[slot].ready, playerInfo.Human and not singlePlayer)
    GUI.slots[slot].ready:SetCheck(playerInfo.Ready, true)

    if isLocallyOwned and playerInfo.Human then
        Prefs.SetToCurrentProfile('LastColor', playerInfo.PlayerColor)
        Prefs.SetToCurrentProfile('LastFaction', playerInfo.Faction)
    end

    -- Show the player's nationality
    if playerInfo.Country == nil or playerInfo.Country == '' then
        GUI.slots[slot].KinderCountry:Hide()
    else
        GUI.slots[slot].KinderCountry:Show()
        GUI.slots[slot].KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..playerInfo.Country..'.dds'))
        Country_GetTooltipValue(playerInfo.Country, slot)
        Country_AddControlTooltip(GUI.slots[slot].KinderCountry, 0, slot)
    end
    
    -- Set the CPU bar
    SetSlotCPUBar(slot, playerInfo)
end

function ClearSlotInfo(slot)
    local hostKey
    if lobbyComm:IsHost() then
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    local stateKey
    local stateText
    if gameInfo.ClosedSlots[slot] then
        stateKey = 'closed'
        stateText = slotMenuStrings.closed
    else
        stateKey = 'open'
        stateText = slotMenuStrings.open
    end

    local slotKeys, slotStrings = GetSlotMenuTables(stateKey, hostKey)

    -- set the text appropriately
    GUI.slots[slot].name:ClearItems()
    GUI.slots[slot].name:SetTitleText(LOC(stateText))
    if table.getn(slotKeys) > 0 then
        GUI.slots[slot].name.slotKeys = slotKeys
        GUI.slots[slot].name:AddItems(slotStrings)
        GUI.slots[slot].name:Enable()
    else
        GUI.slots[slot].name.slotKeys = nil
        GUI.slots[slot].name:Disable()
    end

    GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    if stateKey == 'closed' then
        GUI.slots[slot].name:SetTitleTextColor("Crimson")
    else
        GUI.slots[slot].name:SetTitleTextColor('B9BFB9')--UIUtil.fontColor)
    end

    if lobbyComm:IsHost() and stateKey == 'open' then
        Tooltip.AddComboTooltip(GUI.slots[slot].name, GetAITooltipList())
    else
        Tooltip.RemoveComboTooltip(GUI.slots[slot].name)
    end

    -- hide these to clear slot of visible data
    GUI.slots[slot].KinderCountry:Hide()
    GUI.slots[slot].ratingGroup:Hide()
    GUI.slots[slot].numGamesGroup:Hide()
    GUI.slots[slot].faction:Hide()
    GUI.slots[slot].color:Hide()
    GUI.slots[slot].team:Hide()
    GUI.slots[slot].multiSpace:Hide()
    GUI.slots[slot].pingGroup:Hide()
end

function IsColorFree(colorIndex)
    for id,player in gameInfo.PlayerOptions do
        if player.PlayerColor == colorIndex then
            return false
        end
    end

    return true
end

function GetPlayerCount()
    local numPlayers = 0
    for k,player in gameInfo.PlayerOptions do
        if player.Team >= 0 then
            numPlayers = numPlayers + 1
        end
    end
    return numPlayers
end

local function GetPlayersNotReady()
    local notReady = false
    for k,v in gameInfo.PlayerOptions do
        if v.Human and not v.Ready then
            if not notReady then
                notReady = {}
            end
            table.insert(notReady,v.PlayerName)
        end
    end
    return notReady
end

local function GetRandomFactionIndex()
    local randomfaction = nil
    local counter = 50
    while counter > 0 do
        counter = (counter - 1)
        randomfaction = math.random(1, table.getn(FactionData.Factions))
    end
    return randomfaction
end


local function AssignRandomFactions(gameInfo)
    local randomFactionID = table.getn(FactionData.Factions) + 1
    for index, player in gameInfo.PlayerOptions do
        -- note that this doesn't need to be aware if player has supcom or not since they would only be able to select
        -- the random faction ID if they have supcom
        if player.Faction >= randomFactionID then
            player.Faction = GetRandomFactionIndex()
        end
    end
end

---------------------------
-- autobalance functions --
---------------------------
local function team_sort_by_sum(t1, t2)
    return t1['sum'] < t2['sum']
end

local function autobalance_bestworst(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local best = true
    local teams = {}

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots), sum=0})
    end

    -- teams first picks best player and then worst player, repeat
    while table.getn(players) > 0 do
        for i, t in teams do
            local team = t['team']
            local slots = t['slots']
            local slot = table.remove(slots, 1)
            local player

            if(best) then
                player = table.remove(players, 1)
            else
                player = table.remove(players)
            end

            if(not player) then break end

            teams[i]['sum'] = teams[i]['sum'] + player['rating']
            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
        end

        best = not best
        if(best) then
            table.sort(teams, team_sort_by_sum)
        end
    end

    return result
end

local function autobalance_avg(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local teams = {}
    local max_sum = 0

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots), sum=0})
    end

    while table.getn(players) > 0 do
        local first_team = true
        for i, t in teams do
            local team = t['team']
            local slots = t['slots']
            local slot = table.remove(slots, 1)
            local player
            local player_key

            for j, p in players do
                player_key = j
                if(first_team or t['sum'] + p['rating'] <= max_sum) then
                    break
                end
            end

            player = table.remove(players, player_key)
            if(not player) then break end

            teams[i]['sum'] = teams[i]['sum'] + player['rating']
            max_sum = math.max(max_sum, teams[i]['sum'])
            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
            first_team = false
        end

        table.sort(teams, team_sort_by_sum)
    end

    return result
end

local function autobalance_rr(players, teams)
    local players = table.deepcopy(players)
    local teams = table.deepcopy(teams)
    local result = {}

    local team_picks = {
        {},
        {1,2,  2,1,  2,1,  1,2,  1,2,  2,1},
        {1,2,3,  3,2,1,  2,1,3,  2,3,1},
        {1,2,3,4,  4,3,2,1,  3,1,4,2},
    }

    local picks = team_picks[table.getn(teams)]

    if(not picks or table.getsize(picks) == 0) then
        return
    end

    i = 1
    while (table.getn(players) > 0) do
        local player = table.remove(players, 1)
        local team = table.remove(picks, 1)
        local slot = table.remove(teams[team], 1)
        if(not player) then break end

        table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
    end

    return result
end

local function autobalance_random(players, teams_arg)
    local players = table.deepcopy(players)
    local result = {}
    local teams = {}

    players = table.shuffle(players)

    for t, slots in teams_arg do
        table.insert(teams, {team=t, slots=table.deepcopy(slots)})
    end

    while(table.getn(players) > 0) do

        for _, t in teams do
            local team = t['team']
            local slot = table.remove(t['slots'], 1)
            local player = table.remove(players, 1)

            if(not player) then break end

            table.insert(result, {player=player['pos'], rating=player['rating'], team=team, slot=slot})
        end
    end

    return result
end

function autobalance_quality(players)
    local teams = nil
    local quality = nil

    for _, p in players do
        local i = p['player']
        local team = p['team']
        local player = Player.create(gameInfo.PlayerOptions[i].PlayerName,
                                     Rating.create(gameInfo.PlayerOptions[i].MEAN or 1500, gameInfo.PlayerOptions[i].DEV or 500))

        if(not teams) then
            teams = Teams.create(team, player)
        else
            teams:addPlayer(team, player)
        end
    end

    if(teams) then
        quality = Trueskill.computeQuality(teams)
    end

    return quality
end

local function AssignRandomStartSpots(gameInfo)
    function teamsAddSpot(teams, team, spot)
        if(not teams[team]) then
            teams[team] = {}
        end
        table.insert(teams[team], spot)
    end

    if gameInfo.GameOptions['TeamSpawn'] == 'random' then
        local numAvailStartSpots = nil
        local scenarioInfo = nil
        if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
            scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
        end
        if scenarioInfo then
            local armyTable = MapUtil.GetArmies(scenarioInfo)
            if armyTable then
                if gameInfo.GameOptions['RandomMap'] == 'Off' then
                    numAvailStartSpots = table.getn(armyTable)
                else
                    numAvailStartSpots = numberOfPlayers
                end
            end
        else
            WARN("Can't assign random start spots, no scenario selected.")
            return
        end

        local autoTeams = gameInfo.GameOptions['AutoTeams']
        local teams = {}
        for i = 1, numAvailStartSpots do
            if gameInfo.ClosedSlots[i] == nil then
                local team = nil

                if autoTeams == 'lvsr' then
                    local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                    if(not GUI.markers[i].marker) then return end
                    local markerPos = GUI.markers[i].marker.Left()

                    if markerPos < midLine then
                        team = 2
                    else
                        team = 3
                    end
                elseif autoTeams == 'tvsb' then
                    local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                    local markerPos = GUI.markers[i].marker.Top()

                    if markerPos < midLine then
                        team = 2
                    else
                        team = 3
                    end
                elseif autoTeams == 'pvsi' then
                    if math.mod(i, 2) ~= 0 then
                        team = 2
                    else
                        team = 3
                    end
                elseif autoTeams == 'manual' then
                    team = gameInfo.AutoTeams[i]
                else -- none
                    team = gameInfo.PlayerOptions[i].Team
                end

                if team ~= nil then
                    teamsAddSpot(teams, team, i)
                end
            end
        end
        -- shuffle the array for randomness.
        for i, team in teams do
            teams[i] = table.shuffle(team)
        end
        teams = table.shuffle(teams)

        local ratingTable = {}
        for i = 1, numAvailStartSpots do
            if gameInfo.PlayerOptions[i] then
                if(not gameInfo.PlayerOptions[i].MEAN) then
                    gameInfo.PlayerOptions[i].MEAN = 1500
                end

                if(not gameInfo.PlayerOptions[i].DEV) then
                    gameInfo.PlayerOptions[i].DEV = 500
                end

                table.insert(ratingTable, {pos=i, rating=gameInfo.PlayerOptions[i].MEAN-gameInfo.PlayerOptions[i].DEV*3})
            end
        end

        ratingTable = table.shuffle(ratingTable) -- random order for people with same rating
        table.sort(ratingTable, function(a, b) return a['rating'] > b['rating'] end)

        local functions = {
            rr=autobalance_rr,
            bestworst=autobalance_bestworst,
            avg=autobalance_avg,
        }

        local best = {quality=0, result=nil}
        local r, q
        for fname, f in functions do
            r = f(ratingTable, teams)
            if r then
                q = autobalance_quality(r)

                -- when all functions fail, use one as default
                if q > best.quality or best.result == nil then
                    best.result = r
                    best.quality = q
                end
            end
        end

        local results = {}
        table.insert(results, best)

        -- add 100 random compositions and keep 3 with at least 90% of best quality
        for i=1, 100 do
            r = autobalance_random(ratingTable, teams)
            q = autobalance_quality(r)

            if(q > best.quality*0.9) then
                table.insert(results, {quality=q, result=r})

                if(table.getsize(results) > 4) then break end
            end
        end

        results = table.shuffle(results)
        best = table.remove(results, 1)
        gameInfo.GameOptions['Quality'] = best.quality

        local orgPlayerOptions = table.deepcopy(gameInfo.PlayerOptions)
        for k, p in gameInfo.PlayerOptions do
            orgPlayerOptions[k] = table.deepcopy(p)
        end

        gameInfo.PlayerOptions = {}
        for _, r in best.result do
            local slot = r['slot']
            local player = r['player']
            local team = r['team']
            gameInfo.PlayerOptions[slot] = table.deepcopy(orgPlayerOptions[player])
            gameInfo.PlayerOptions[slot].StartSpot = slot
            gameInfo.PlayerOptions[slot].Team = team
        end
    end
end

-- This function is used to double check the observers.
local function sendObserversList(gameInfo)
    for k,observer in gameInfo.Observers do
        GpgNetSend('PlayerOption', string.format("team %s %d %s", observer.PlayerName, -1, 0))
    end
end

local function AssignRandomTeams(gameInfo)
    -- first, send all observers

    sendObserversList(gameInfo)

    if gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
        local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                local markerPos = GUI.markers[i].marker.Left()
                if markerPos < midLine then
                    gameInfo.PlayerOptions[i].Team = 2
                else
                    gameInfo.PlayerOptions[i].Team = 3
                end
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
        local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                local markerPos = GUI.markers[i].marker.Top()
                if markerPos < midLine then
                    gameInfo.PlayerOptions[i].Team = 2
                else
                    gameInfo.PlayerOptions[i].Team = 3
                end
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    elseif gameInfo.GameOptions['AutoTeams'] == 'manual' and gameInfo.GameOptions['TeamSpawn'] == 'random' then
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                gameInfo.PlayerOptions[i].Team = gameInfo.AutoTeams[i]
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    end
    if gameInfo.GameOptions['AutoTeams'] == 'pvsi' or gameInfo.GameOptions['RandomMap'] ~= 'Off' then
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                if i == 1 or i == 3 or i == 5 or i == 7 or i == 9 or i == 11 then
                    gameInfo.PlayerOptions[i].Team = 2
                else
                    gameInfo.PlayerOptions[i].Team = 3
                end
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    end

    if gameInfo.GameOptions['AutoTeams'] == 'none' then
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            end
        end
    end

end

local function AssignAINames(gameInfo)
    local aiNames = import('/lua/ui/lobby/aiNames.lua').ainames
    local nameSlotsTaken = {}
    for index, faction in FactionData.Factions do
        nameSlotsTaken[index] = {}
    end
    for index, player in gameInfo.PlayerOptions do
        if player.Human == false then
            local factionNames = aiNames[FactionData.Factions[player.Faction].Key]
            local ranNum
            repeat
                ranNum = math.random(1, table.getn(factionNames))
            until nameSlotsTaken[player.Faction][ranNum] == nil
            nameSlotsTaken[player.Faction][ranNum] = true
            local newName = factionNames[ranNum]
            player.PlayerName = newName .. " (" .. player.PlayerName .. ")"
        end
    end
end


-- call this whenever the lobby needs to exit and not go in to the game
function ReturnToMenu(reconnect)
    if lobbyComm then
        lobbyComm:Destroy()
        lobbyComm = false
    end

    local exitfn = GUI.exitBehavior

    GUI:Destroy()
    GUI = false

    if not reconnect then
        exitfn()
    else
        local ipnumber = GetCommandLineArg("/joincustom", 1)[1]
        import('/lua/ui/uimain.lua').StartJoinLobbyUI("UDP", ipnumber, localPlayerName)
    end
end

-- Display, if appropriate, a system message.
function DisplaySystemMessage(data)
    -- If the message is related to use connectivity and the user has turned off system messages,
    -- don't display the message.'

    --switch = Player switched with other Player
    --lobui_0202 = Joined as a Observer
    --lobui_0226 = Move Player to Observer
    --lobui_0227 = Move Observer to Player
    --lobui_0205 = Timed Out
    if data.Id == 'lobui_0202' or data.Id == 'lobui_0226' or data.Id == 'lobui_0227' or data.Id == 'lobui_0205' or data.Id == 'switch' then
        if not SystemMessagesEnabled() then
            return
        end
    end

    AddChatText(data.Text)
end

function SendSystemMessage(text, id)
    local data = {
        Type = "SystemMessage",
        Text = text,
        Id = id or '',
    }
    lobbyComm:BroadcastData(data)
    DisplaySystemMessage(data)
end

function PublicChat(text)
    lobbyComm:BroadcastData(
        {
            Type = "PublicChat",
            Text = text,
        }
        )
    AddChatText("["..localPlayerName.."] " .. text)
end

function PrivateChat(targetID,text)
    if targetID ~= localPlayerID then
        lobbyComm:SendData(
            targetID,
            {
                Type = 'PrivateChat',
                Text = text,
            }
            )
    end
    AddChatText("<<"..localPlayerName..">> " .. text)
end

function UpdateAvailableSlots( numAvailStartSpots )
    if numAvailStartSpots > LobbyComm.maxPlayerSlots then
        WARN("Lobby requests " .. numAvailStartSpots .. " but there are only " .. LobbyComm.maxPlayerSlots .. " available")
    end

    -- if number of available slots has changed, update it
    if numOpenSlots ~= numAvailStartSpots then
        numOpenSlots = numAvailStartSpots
        for i = 1, LobbyComm.maxPlayerSlots do
            if i <= numAvailStartSpots then
                if GUI.slots[i].closed then
                    GUI.slots[i].closed = false
                    GUI.slots[i]:Show()
                    if not gameInfo.PlayerOptions[i] then
                        ClearSlotInfo(i)
                    end
                    if not gameInfo.PlayerOptions[i]['Ready'] then
                        EnableSlot(i)
                    end
                end
            else
                if not GUI.slots[i].closed then
                    if lobbyComm:IsHost() and gameInfo.PlayerOptions[i] then
                        local info = gameInfo.PlayerOptions[i]
                        if info.Human then
                            HostConvertPlayerToObserver(info.OwnerID, info.PlayerName, i)
                        else
                            HostRemoveAI(i)
                        end
                    end
                    DisableSlot(i)
                    GUI.slots[i]:Hide()
                    GUI.slots[i].closed = true
                end
            end
        end
    end
end

local function TryLaunch(stillAllowObservers, stillAllowLockedTeams, skipNoObserversCheck)
    if not singlePlayer then
        local notReady = GetPlayersNotReady()
        if notReady then
            for k,v in notReady do
                AddChatText(LOCF("<LOC lobui_0203>%s isn't ready.",v))
            end
            return
        end
    end

    -- make sure there are some players (could all be observers?)
    -- Also count teams. There needs to be at least 2 teams (or all FFA) represented
    local totalPlayers = 0
    local totalHumanPlayers = 0
    local lastTeam = false
    local allFFA = true
    local moreThanOneTeam = false
    for slot, player in gameInfo.PlayerOptions do
        if player then
            totalPlayers = totalPlayers + 1
            if player.Human then
                totalHumanPlayers = totalHumanPlayers + 1
            end
            if not moreThanOneTeam and lastTeam and lastTeam ~= player.Team then
                moreThanOneTeam = true
            end
            if player.Team ~= 1 then
                allFFA = false
            end
            lastTeam = player.Team
        end
    end

    if gameInfo.GameOptions['Victory'] ~= 'sandbox' then
        local valid = true
        if totalPlayers == 1 then
            valid = false
        end
        if not allFFA and not moreThanOneTeam then
            valid = false
        end
        if not valid then
            AddChatText(LOC("<LOC lobui_0241>There must be more than one player or team or the Victory Condition must be set "..
                            "to Sandbox."))
            return
        end
    end

    if totalPlayers == 0 then
        AddChatText(LOC("<LOC lobui_0233>There are no players assigned to player slots, can not continue"))
        return
    end


    if totalHumanPlayers == 0 and table.empty(gameInfo.Observers) then
        AddChatText(LOC("<LOC lobui_0239>There must be at least one non-ai player or one observer, can not continue"))
        return
    end


    if not EveryoneHasEstablishedConnections() then
        return
    end

    if not singlePlayer then
        if gameInfo.GameOptions.AllowObservers then
            if totalPlayers > 3 and not stillAllowObservers then
                UIUtil.QuickDialog(GUI, "<LOC lobui_0521>There are players for a team game and allow observers is enabled. "..
                                   "Do you still wish to launch?",
                                   "<LOC _Yes>", function()
                                       TryLaunch(true, false, false)
                                       stillAllowObservers = true
                                   end,
                                   "<LOC _No>",
                                   nil,
                                   nil, nil,
                                   true,
                                   {worldCover = false, enterButton = 1, escapeButton = 2}
                                   )
                return
            end
        end
        if gameInfo.GameOptions['TeamLock'] == 'locked' then
            local i = 1
            local n = 0
            repeat
                if gameInfo.PlayerOptions[i].Team ~= 1 and gameInfo.PlayerOptions[i].Team ~= nil then
                    n = n + 1
                end
                i = i + 1
            until i == 9
            if totalPlayers > 3 and not stillAllowLockedTeams and totalPlayers ~= n and gameInfo.GameOptions['AutoTeams']
                == 'none' then
                UIUtil.QuickDialog(GUI, "<LOC lobui_0526>There are players for a team game and teams are locked.  Do you " ..
                                   "still wish to launch?",
                                   "<LOC _Yes>", function()
                                       TryLaunch(true, true, false)
                                       stillAllowLockedTeams = true
                                   end,
                                   "<LOC _No>",
                                   nil,
                                   nil, nil,
                                   true,
                                   {worldCover = false, enterButton = 1, escapeButton = 2}
                                   )
                return
            end
        end
    end

    if not gameInfo.GameOptions.AllowObservers then
        local hostIsObserver = false
        local anyOtherObservers = false
        for k,observer in gameInfo.Observers do
            if observer.OwnerID == localPlayerID then
                hostIsObserver = true
            else
                anyOtherObservers = true
            end
        end

        if hostIsObserver then
            AddChatText(LOC("<LOC lobui_0277>Cannot launch if the host isn't assigned a slot and observers are not allowed."))
            return
        end

        if anyOtherObservers then
            if skipNoObserversCheck then
                -- we send the observer list before kicking the players, in case they are not registered as observer
                -- and won't disconnect correctly before the game launch.
                sendObserversList(gameInfo)
                for k,observer in gameInfo.Observers do
                    lobbyComm:EjectPeer(observer.OwnerID, "KickedByHost")
                end
                gameInfo.Observers = {}
            else
                UIUtil.QuickDialog(GUI, "<LOC lobui_0278>There are players who are not assigned slots and observers are not " ..
                                   "allowed.  Launching will cause them to be ejected.  Do you still wish to launch?",
                                   "<LOC _Yes>", function() TryLaunch(true, true, true) end,
                                   "<LOC _No>", nil,
                                   nil, nil,
                                   true,
                                   {worldCover = false, enterButton = 1, escapeButton = 2}
                                   )
                return
            end
        end
    end

    numberOfPlayers = totalPlayers

    local function LaunchGame()

        -- Send observer list again, just by precaution.
        sendObserversList(gameInfo)

        if gameInfo.GameOptions['RandomMap'] ~= 'Off' then
            autoRandMap = true
            autoMap()
        end

        SetFrontEndData('NextOpBriefing', nil)
        -- assign random factions just as game is launched
        AssignRandomFactions(gameInfo)
        AssignRandomStartSpots(gameInfo)
        --assign the teams just before launch
        AssignRandomTeams(gameInfo)
        randstring = randomString(16, "%l%d")
        gameInfo.GameOptions['ReplayID'] = randstring
        gameInfo.GameOptions['Rule'] = GUI.RuleLabel:GetItem(0)..GUI.RuleLabel:GetItem(1)
        AssignAINames(gameInfo)
        local allRatings = {}
        for k,v in gameInfo.PlayerOptions do
            if v.Human and v.PL then
                allRatings[v.PlayerName] = v.PL
            end
        end
        gameInfo.GameOptions['Ratings'] = allRatings

        -- Tell everyone else to launch and then launch ourselves.
        lobbyComm:BroadcastData( { Type = 'Launch', GameInfo = gameInfo } )

        -- set the mods
        gameInfo.GameMods = Mods.GetGameMods(gameInfo.GameMods)

        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
        SetWindowedLobby(false)
        lobbyComm:LaunchGame(gameInfo)
    end

    LaunchGame()
end

local function AlertHostMapMissing()
    if lobbyComm:IsHost() then
        HostPlayerMissingMapAlert(localPlayerID)
    else
        lobbyComm:SendData(hostID, {Type = 'MissingMap', Id = localPlayerID})
    end
end

-- Set the faction selector icons appropriately for the given selected faction.
local function updateFactionSelectorIcons(enabled, faction)
    -- Possibly bolt "-dis" onto the pathname.
    local dis = ""
    if not enabled then
        dis = "-dis"
    end

    -- Set everything to the small version.
    for k, v in pairs(FACTION_PANELS) do
        v:SetTexture("/textures/ui/common/FACTIONSELECTOR/" .. FACTION_NAMES[k] .. "_ico" .. dis .. ".png")
    end

    -- Set the selection faction icon to the large version.
    FACTION_PANELS[faction]:SetTexture("/textures/ui/common/FACTIONSELECTOR/" .. FACTION_NAMES[faction] .. "_ico-large.png")
end

-- Set the enabledness state of the faction selector to the given value.
-- The faction argument specifies the selected faction (the corresponding icon is shown larger than
-- the others.
local function Faction_Selector_Set_Enabled(enabled, faction)
    -- Update the images to reflect the new enabled state.
    updateFactionSelectorIcons(enabled, faction)

    -- Set the enabled state of the panel.
    for k , v in pairs(FACTION_PANELS) do
        UIUtil.setEnabled(v, enabled)
    end
end

-- Refresh (with a sledgehammer) all the items in the observer list.
local function refreshObserverList()
    GUI.observerList:DeleteAllItems()

    for slot, observer in gameInfo.Observers do
        observer.ObserverListIndex = GUI.observerList:GetItemCount() -- Pin-head William made this zero-based

        -- Create a label for this observer of the form:
        -- PlayerName (R:xxx, P:xxx, C:xxx)
        -- Such conciseness is necessary as the field in the UI is rather narrow...
        local observer_label = observer.PlayerName .. " (R:" .. observer.PL

        -- Add the ping only if this entry refers to a different client.
        if observer and (observer.OwnerID ~= localPlayerID) and observer.ObserverListIndex then
            local peer = lobbyComm:GetPeer(observer.OwnerID)

            local ping = 0
            if peer.ping ~= nil then
                ping = math.floor(peer.ping)
            end

            observer_label = observer_label .. ", P:" .. ping
        end

        -- Add the CPU score if one is available.
        local score_CPU = CPU_Benchmarks[observer.PlayerName]
        if score_CPU then
            observer_label = observer_label .. ", C:" .. score_CPU
        end
        observer_label = observer_label .. ")"

        GUI.observerList:AddItem(observer_label)
    end
end

local function UpdateGame()
    LOGX('>> UpdateGame', 'UpdateGame')
    local scenarioInfo = nil

    if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)

        if scenarioInfo and scenarioInfo.map and scenarioInfo.map ~= '' then
            local mods = Mods.GetGameMods(gameInfo.GameMods)
            PrefetchSession(scenarioInfo.map, mods, true)
        else
            AlertHostMapMissing()
        end
    end

    -- This allows us to assume the existence of UI elements throughout.
    if not GUI.uiCreated then
        return
    end

    local isHost = lobbyComm:IsHost()

    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        local playerOptions = gameInfo.PlayerOptions[localPlayerSlot]

        -- if anything happens to switch a no SupCom player to a faction other than Seraphim, switch them back
        if not hasSupcom then
            if playerOptions.Faction ~= 4 and not
            IsObserver(localPlayerID) then
                SetPlayerOption(localPlayerSlot, 'Faction', 4, true)
                return
            end
        end

        -- Disable some controls if the user is ready.
        local notReady = not playerOptions.Ready

        UIUtil.setEnabled(GUI.becomeObserver, notReady)
        UIUtil.setEnabled(GUI.restrictedUnitsOrPresetsBtn, isHost and notReady)

        UIUtil.setEnabled(GUI.LargeMapPreview, notReady)
        Faction_Selector_Set_Enabled(notReady, playerOptions.Faction)

        -- Set the info in a Slot
        -- TODO: Since these stats are all constants, we should figure out the right place to do this
        -- job once.
        if not playerOptions.MEAN then
            SetPlayerOption(localPlayerSlot, 'MEAN', playerMean, true)
        end
        if not playerOptions.DEV then
            SetPlayerOption(localPlayerSlot, 'DEV', playerDeviation, true)
        end
        if not playerOptions.COUNTRY then
            SetPlayerOption(localPlayerSlot, 'COUNTRY', PrefLanguage, true)
        end
        if not playerOptions.PL then
            SetPlayerOption(localPlayerSlot, 'PL', playerRating, true)
        end
        if not playerOptions.RC then
            SetPlayerOption(localPlayerSlot, 'RC', ratingColor, true)
        end
        if not playerOptions.NG then
            SetPlayerOption(localPlayerSlot, 'NG', numGames, true)
        end
    end

    local numPlayers = GetPlayerCount()

    local numAvailStartSpots = LobbyComm.maxPlayerSlots
    if scenarioInfo then
        local armyTable = MapUtil.GetArmies(scenarioInfo)
        if armyTable then
            numAvailStartSpots = table.getn(armyTable)
        end
    end

    UpdateAvailableSlots(numAvailStartSpots)

    for i = 1, LobbyComm.maxPlayerSlots do
        if GUI.slots[i].closed then
            GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-dis.dds')) -- Change the Slot Background by Slot State
        else
            if gameInfo.PlayerOptions[i] then
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
                GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player.dds'))
            else
                ClearSlotInfo(i)
                GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player_other.dds'))
            end
        end
    end

    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= "") then
        if not GUI.mapView:SetTexture(scenarioInfo.preview) then
            GUI.mapView:SetTextureFromMap(scenarioInfo.map)
        end
        ShowMapPositions(GUI.mapView,scenarioInfo,numPlayers)
    else
        GUI.mapView:ClearTexture()
        ShowMapPositions(nil, false)
    end

    if not singlePlayer then
        refreshObserverList()
    end

    -- deal with options display
    if isHost then
        -- disable options when all players are marked ready
        -- Is at least one person not ready?
        local playerNotReady = GetPlayersNotReady() ~= false

        UIUtil.setEnabled(GUI.gameoptionsButton, playerNotReady)
        UIUtil.setEnabled(GUI.rankedOptions, playerNotReady)
        UIUtil.setEnabled(GUI.randMap, playerNotReady)

        -- Launch button enabled if everyone is ready.
        UIUtil.setEnabled(GUI.launchGameButton, not playerNotReady)
        UIUtil.setEnabled(GUI.randMap, quickRandMap)
    end

    GUI.allowObservers:SetCheck(gameInfo.GameOptions.AllowObservers, true)

    RefreshOptionDisplayData(scenarioInfo)
    -- Send autoteams infos to server.
    AssignRandomTeams(gameInfo)

    -- Update the map background to reflect the possibly-changed map.
    if Prefs.GetFromCurrentProfile('LobbyBackground') == 4 then
        ChangeBackgroundLobby()
    end

    -- Set the map name at the top right corner in lobby
    if scenarioInfo.name then
        SetText2(GUI.MapNameLabel, scenarioInfo.name, 10)
    end

    -- Auto-team logic.
    if gameInfo.GameOptions['TeamSpawn'] ~= 'random' and
       math.mod(numPlayers,2) == 0 and
       gameInfo.GameOptions['AutoTeams'] ~= 'manual' and
       gameInfo.GameOptions['AutoTeams'] ~= 'none' then

        local teams = nil
        local teamcreated = false
        local correct = true

        for i = 1, LobbyComm.maxPlayerSlots do
            local playerOptions = gameInfo.PlayerOptions[i]
            if playerOptions then

                if playerOptions.Human then
                    if playerOptions.MEAN and playerOptions.DEV then
                        local player = Player.create(playerOptions.PlayerName,
                                               Rating.create(playerOptions.MEAN, playerOptions.DEV))

                        if playerOptions.Team == 2 then
                            if teamcreated then
                                teams:addPlayer(1, player)
                            else
                                teams = Teams.create(1, player)
                                teamcreated = true
                            end
                        else
                            if teamcreated then
                                teams:addPlayer(2, player)
                            else
                                teams = Teams.create(2, player)
                                teamcreated = true
                            end
                        end
                    end
                else
                    correct = false
                end
            end
        end

        if correct and teams ~= nil then
            local quality = Trueskill.computeQuality(teams)

            if quality > 0 then
                gameInfo.GameOptions['Quality'] = quality
                SetText2(GUI.GameQualityLabel, "Game quality : "..quality.."%", 10)
            else
                SetText2(GUI.GameQualityLabel, "Game quality N/A", 10)
            end
        else
            GUI.GameQualityLabel:SetText("")
        end
    else
        GUI.GameQualityLabel:SetText("")
    end

    -- Add Tooltip info on Map Name Label
    if GUI.GameQualityLabel and scenarioInfo then
        local TTips_map_version = scenarioInfo.map_version or "1"
        local TTips_army = table.getsize(scenarioInfo.Configurations.standard.teams[1].armies) or "N/A"
        local TTips_sizeX = scenarioInfo.size[1] / 51.2 or "N/A"
        local TTips_sizeY = scenarioInfo.size[2] / 51.2 or "N/A"

        local mapTooltip = {
            text = scenarioInfo.name,
            body = '- Map version : '..TTips_map_version..'\n '..
                   '- Max Players : '..TTips_army..' max'..'\n '..
                   '- Map Size : '..TTips_sizeX..'km x '..TTips_sizeY..'km'
        }

        Tooltip.AddControlTooltip(GUI.MapNameLabel, mapTooltip)
        Tooltip.AddControlTooltip(GUI.GameQualityLabel, mapTooltip)
    else
        local mapTooltip = {
            text="N/A",
            body='- Map version : N/A\n '..
                 '- Max Players : N/A max\n '..
                 '- Map Size : N/Akm x N/Akm'
        }
        Tooltip.AddControlTooltip(GUI.MapNameLabel, mapTooltip)
        Tooltip.AddControlTooltip(GUI.GameQualityLabel, mapTooltip)
    end
end

-- Update our local gameInfo.GameMods from selected map name and selected mods, then
-- notify other clients about the change.
local function HostUpdateMods(newPlayerID, newPlayerName)
    if lobbyComm:IsHost() then
        if gameInfo.GameOptions['RankedGame'] and gameInfo.GameOptions['RankedGame'] ~= 'Off' then
            gameInfo.GameMods = {}
            gameInfo.GameMods = Mods.GetGameMods(gameInfo.GameMods)
            lobbyComm:BroadcastData { Type = "ModsChanged", GameMods = gameInfo.GameMods }
            return
        end
        local newmods = {}
        local missingmods = {}
        for k,modId in selectedMods do
            if IsModAvailable(modId) then
                newmods[modId] = true
            else
                table.insert(missingmods, modId)
            end
        end
        if not table.equal(gameInfo.GameMods, newmods) and (not newPlayerID or not autoKick) then
            gameInfo.GameMods = newmods
            lobbyComm:BroadcastData { Type = "ModsChanged", GameMods = gameInfo.GameMods }

            local nummods = 0
            local uids = ""

            for k in gameInfo.GameMods do
                nummods = nummods + 1
                if uids == "" then
                    uids =  k
                else
                    uids = string.format("%s %s", uids, k)
                end

            end
            GpgNetSend('GameMods', "activated", nummods)

            if nummods > 0 then
                GpgNetSend('GameMods', "uids", uids)
            end


        elseif not table.equal(gameInfo.GameMods, newmods) and newPlayerID and autoKick then
            local modnames = ""
            local totalMissing = table.getn(missingmods)
            local totalListed = 0
            if totalMissing > 0 then
                for index, id in missingmods do
                    for k,mod in Mods.GetGameMods() do
                        if mod.uid == id then
                            totalListed = totalListed + 1
                            if totalMissing == totalListed then
                                modnames = modnames .. " " .. mod.name
                            else
                                modnames = modnames .. " " .. mod.name .. " + "
                            end
                        end
                    end
                end
            end
            local reason = (LOCF('<LOC lobui_0588>You were automaticly removed from the lobby because you ' ..
                               'don\'t have the following mod(s):\n%s \nPlease, install the mod before you join the game lobby',
                               modnames))
            if FindNameForID(newPlayerID) then
                AddChatText(FindNameForID(newPlayerID)..' is Auto Kicked because he not have this mod : '..modnames) -- not working ? -- XinnonyTest
            else
                if newPlayerName then
                    AddChatText(newPlayerName..' is Auto Kicked because he not have this mod : '..modnames) -- not working ? -- XinnonyTest
                else
                    AddChatText('The last player is Auto Kicked because he not have this mod : '..modnames)
                end
            end
            lobbyComm:EjectPeer(newPlayerID, reason)
        end
    end
end

-- callback when Mod Manager dialog finishes (modlist==nil on cancel)
-- FIXME: The mod manager should be given a list of game mods set by the host, which
-- clients can look at but not changed, and which don't get saved in our local prefs.
function OnModsChanged(modlist, ignoreRefresh)
    if modlist then
        Mods.SetSelectedMods(modlist)
        if lobbyComm:IsHost() then
            selectedMods = table.map(function (m) return m.uid end, Mods.GetGameMods())
            HostUpdateMods()
        end
        if not ignoreRefresh then
            UpdateGame()
        end
    end
end

-- host makes a specific slot closed to players
function HostCloseSlot(senderID, slot)
    -- don't close an already closed slot or an occupied slot
    if gameInfo.ClosedSlots[slot] ~= nil or gameInfo.PlayerOptions[slot] ~= nil then
        return
    end

    gameInfo.ClosedSlots[slot] = true

    lobbyComm:BroadcastData(
        {
            Type = 'SlotClose',
            Slot = slot,
        }
    )

    UpdateGame()

end

-- host makes a specific slot open for players
function HostOpenSlot(senderID, slot)
    -- don't try to open an already open slot
    if gameInfo.ClosedSlots[slot] == nil then
        return
    end

    gameInfo.ClosedSlots[slot] = nil

    lobbyComm:BroadcastData(
        {
            Type = 'SlotOpen',
            Slot = slot,
        }
    )

    UpdateGame()
end

-- slot less than 1 means try to find a slot
function HostTryAddPlayer(senderID, slot, requestedPlayerName, human, aiPersonality, requestedColor, requestedFaction, requestedTeam, requestedPL, requestedRC, requestedNG, requestedMEAN, requestedDEV, requestedCOUNTRY)
    LOGX('>> HostTryAddPlayer > requestedPlayerName='..tostring(requestedPlayerName), 'Connecting')
    --// RULE TITLE
    if not singlePlayer then
        RuleTitle_SendMSG()
    end
    --\\ Stop RULE TITLE
    -- CPU benchmark code
    if human and not singlePlayer then
        for name, benchmark in pairs(CPU_Benchmarks) do
            -- If we're getting a new player, send them all our benchmark data for players who have joined already
            lobbyComm:SendData(senderID, { Type = 'CPUBenchmark', PlayerName = name, Result = benchmark })
        end
    end
    -- End CPU benchmark code

    local newSlot = slot

    if not slot or slot < 1 then
        newSlot = -1
        for i = 1, numOpenSlots do
            if gameInfo.PlayerOptions[i] == nil and gameInfo.ClosedSlots[i] == nil then
                newSlot = i
                break
            end
        end
    else
        if newSlot > numOpenSlots then
            newSlot = -1
        end
    end

    -- if no slot available, and human, try to make them an observer
    if newSlot == -1 then
        PrivateChat( senderID, LOC("<LOC lobui_0237>No slots available, attempting to make you an observer"))
        if human then
			HostTryAddObserver( senderID, requestedPlayerName, requestedPL, requestedColor, requestedFaction, requestedCOUNTRY )
        end
        return
    end

    local playerName = lobbyComm:MakeValidPlayerName(senderID,requestedPlayerName)

    gameInfo.PlayerOptions[newSlot] = LobbyComm.GetDefaultPlayerOptions(playerName)
    gameInfo.PlayerOptions[newSlot].Human = human
    gameInfo.PlayerOptions[newSlot].OwnerID = senderID
    if hasSupcom then
        -- already assigned a default, but use requested if avail
        gameInfo.PlayerOptions[newSlot].Faction = requestedFaction or gameInfo.PlayerOptions[newSlot].Faction
    else
        gameInfo.PlayerOptions[newSlot].Faction = 4
    end

    if requestedTeam then
        gameInfo.PlayerOptions[newSlot].Team = requestedTeam
    end
    if not human and aiPersonality then
        gameInfo.PlayerOptions[newSlot].AIPersonality = aiPersonality
    end

    -- if a color is requested, attempt to use that color if available, otherwise, assign first available
    -- clear out player color first so default color isn't blocked from color free list
    gameInfo.PlayerOptions[newSlot].PlayerColor = nil
    if requestedColor and IsColorFree(requestedColor) then
        gameInfo.PlayerOptions[newSlot].PlayerColor = requestedColor
    else
        for colorIndex,colorVal in gameColors.PlayerColors do
            if IsColorFree(colorIndex) then
                gameInfo.PlayerOptions[newSlot].PlayerColor = colorIndex
                break
            end
        end
    end

    if requestedMEAN then
        gameInfo.PlayerOptions[newSlot].MEAN = requestedMEAN
    end

    if requestedDEV then
        gameInfo.PlayerOptions[newSlot].DEV = requestedDEV
    end

    if requestedPL then
        gameInfo.PlayerOptions[newSlot].PL = requestedPL
    end

    if requestedRC then
        gameInfo.PlayerOptions[newSlot].RC = requestedRC
    end

    if requestedNG then
        gameInfo.PlayerOptions[newSlot].NG = requestedNG
    end

    if requestedCOUNTRY then
        gameInfo.PlayerOptions[newSlot].Country = requestedCOUNTRY
    end
    
    lobbyComm:BroadcastData(
        {
            Type = 'SlotAssigned',
            Slot = newSlot,
            Options = gameInfo.PlayerOptions[newSlot],
        }
        )
    UpdateGame()
end

function HostTryMovePlayer(senderID, currentSlot, requestedSlot)
    LOG("SenderID: " .. senderID .. " currentSlot: " .. currentSlot .. " requestedSlot: " .. requestedSlot)

    if gameInfo.PlayerOptions[currentSlot].Ready == true then
        LOG("HostTryMovePlayer: player is marked ready and can not move")
        return
    end

    if gameInfo.PlayerOptions[requestedSlot] then
        LOG("HostTryMovePlayer: requested slot " .. requestedSlot .. " already occupied")
        return
    end

    if gameInfo.ClosedSlots[requestedSlot] ~= nil then
        LOG("HostTryMovePlayer: requested slot " .. requestedSlot .. " is closed")
        return
    end

    if requestedSlot > numOpenSlots or requestedSlot < 1 then
        LOG("HostTryMovePlayer: requested slot " .. requestedSlot .. " is out of range")
        return
    end

    gameInfo.PlayerOptions[requestedSlot] = gameInfo.PlayerOptions[currentSlot]
    gameInfo.PlayerOptions[currentSlot] = nil
    ClearSlotInfo(currentSlot)

    lobbyComm:BroadcastData(
        {
            Type = 'SlotMove',
            OldSlot = currentSlot,
            NewSlot = requestedSlot,
            Options = gameInfo.PlayerOptions[requestedSlot],
        }
    )

    UpdateGame()
end

function HostTryAddObserver( senderID, requestedObserverName, RequestedPL, RequestedColor, RequestedFaction, RequestedCOUNTRY )
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    LOGX('>> HostTryAddObserver > requestedObserverName='..tostring(requestedObserverName), 'Connecting')
	local observerName = lobbyComm:MakeValidPlayerName(senderID,requestedObserverName)
    gameInfo.Observers[index] = {
        PlayerName = observerName,
        OwnerID = senderID,
		PL = RequestedPL,
		oldColor = RequestedColor,
        oldFaction = RequestedFaction,
		oldCountry= RequestedCOUNTRY,
    }

    lobbyComm:BroadcastData(
        {
            Type = 'ObserverAdded',
            Slot = index,
            Options = gameInfo.Observers[index],
        }
    )
    SendSystemMessage(LOCF("<LOC lobui_0202>%s has joined as an observer.",observerName), "lobui_0202")
    refreshObserverList()
end

function HostConvertPlayerToObserver(senderID, name, playerSlot, ignoreMsg)
    -- make sure player exists
    if not gameInfo.PlayerOptions[playerSlot] then
        return
    end

    -- find a free observer slot
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    gameInfo.Observers[index] = {
        PlayerName = name,
        OwnerID = senderID,
        PL = gameInfo.PlayerOptions[playerSlot].PL,
        oldColor = gameInfo.PlayerOptions[playerSlot].PlayerColor,
        oldFaction = gameInfo.PlayerOptions[playerSlot].Faction,
        oldCountry = gameInfo.PlayerOptions[playerSlot].Country,
    }

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', string.format("team %s %d %s", name, -1, 0))
    end


    gameInfo.PlayerOptions[playerSlot] = nil
    ClearSlotInfo(playerSlot)

    lobbyComm:BroadcastData(
        {
            Type = 'ConvertPlayerToObserver',
            OldSlot = playerSlot,
            NewSlot = index,
            Options = gameInfo.Observers[index],
        }
    )

    if ignoreMsg then
        SendSystemMessage(LOCF("<LOC lobui_0226>%s has switched from a player to an observer.", name), "lobui_0226")
    end
    UpdateGame()
end

function HostConvertObserverToPlayer(senderID, name, fromObserverSlot, toPlayerSlot, requestedFaction, requestedPL, requestedRC, requestedNG, ignoreMsg)
    if gameInfo.Observers[fromObserverSlot] == nil then -- IF no Observer on the current slot : QUIT
        return
    elseif gameInfo.PlayerOptions[toPlayerSlot] ~= nil then -- IF Player is in the target slot : QUIT
        return
    elseif gameInfo.ClosedSlots[toPlayerSlot] ~= nil then -- IF target slot is Closed : QUIT
        return
    end

    gameInfo.PlayerOptions[toPlayerSlot] = LobbyComm.GetDefaultPlayerOptions(name)
    gameInfo.PlayerOptions[toPlayerSlot].OwnerID = senderID

    gameInfo.PlayerOptions[toPlayerSlot].Country = gameInfo.Observers[fromObserverSlot].oldCountry or 'world'
    --if requestedFaction then
    gameInfo.PlayerOptions[toPlayerSlot].Faction = gameInfo.Observers[fromObserverSlot].oldFaction or requestedFaction or 5
    --end
    if requestedPL then
        gameInfo.PlayerOptions[toPlayerSlot].PL = requestedPL
    end
    if requestedRC then
        gameInfo.PlayerOptions[toPlayerSlot].RC = requestedRC
    end
    if requestedNG then
        gameInfo.PlayerOptions[toPlayerSlot].NG = requestedNG
    end
    for colorIndex,colorVal in gameColors.PlayerColors do
        if IsColorFree(colorIndex) then
            gameInfo.PlayerOptions[toPlayerSlot].PlayerColor = gameInfo.Observers[fromObserverSlot].oldColor or colorIndex
            break
        end
    end

    gameInfo.Observers[fromObserverSlot] = nil

    lobbyComm:BroadcastData(
        {
            Type = 'ConvertObserverToPlayer',
            OldSlot = fromObserverSlot,
            NewSlot = toPlayerSlot,
            Options =  gameInfo.PlayerOptions[toPlayerSlot],
        }
    )

    if ignoreMsg then
        SendSystemMessage(LOCF("<LOC lobui_0227>%s has switched from an observer to player.", name), "lobui_0227")
    end
    UpdateGame()
end

function HostConvertObserverToPlayerWithoutSlot(senderID, name, fromObserverSlot, requestedFaction, requestedPL, requestedRC, requestedNG, ignoreMsg)
    local newSlot = -1
    for i = 1, numOpenSlots do
        if gameInfo.PlayerOptions[i] == nil and gameInfo.ClosedSlots[i] == nil then
            newSlot = i
            break
        else
        end
    end
    if newSlot == -1 then
        return
    end
    local toPlayerSlot = newSlot

    HostConvertObserverToPlayer(senderID, name, fromObserverSlot, toPlayerSlot, requestedFaction, requestedPL, requestedRC, requestedNG, ignoreMsg)
end

function HostClearPlayer(uid)

    local slot = FindSlotForID(peerID)
    if slot then
        ClearSlotInfo(slot)
        gameInfo.PlayerOptions[slot] = nil
        UpdateGame()
    else
        slot = FindObserverSlotForID(peerID)
        if slot then
            gameInfo.Observers[slot] = nil
            UpdateGame()
        end
    end

    availableMods[peerID] = nil
    HostUpdateMods()
end

function HostRemoveAI(slot)
    if gameInfo.PlayerOptions[slot].Human then
        WARN('Use EjectPlayer to remove humans')
        return
    end

    ClearSlotInfo(slot)
    gameInfo.PlayerOptions[slot] = nil
    lobbyComm:BroadcastData(
        {
            Type = 'ClearSlot',
            Slot = slot,
        }
    )
    UpdateGame()
end

function autoMap()
    local randomAutoMap
    if gameInfo.GameOptions['RandomMap'] == 'Official' then
        randomAutoMap = import('/lua/ui/dialogs/mapselect.lua').randomAutoMap(true)
    else
        randomAutoMap = import('/lua/ui/dialogs/mapselect.lua').randomAutoMap(false)
    end
end

function randomString(Length, CharSet)
    -- Length (number)
    -- CharSet (string, optional); e.g. %l%d for lower case letters and digits
    local Chars = {}
    for Loop = 0, 255 do
        Chars[Loop+1] = string.char(Loop)
    end
    local String = table.concat(Chars)

    local Built = {['.'] = Chars}

    local AddLookup = function(CharSet)
        local Substitute = string.gsub(String, '[^'..CharSet..']', '')
        local Lookup = {}
        for Loop = 1, string.len(Substitute) do
            Lookup[Loop] = string.sub(Substitute, Loop, Loop)
        end
        Built[CharSet] = Lookup
        return Lookup
    end

    local CharSet = CharSet or '.'

    if CharSet == '' then
        return ''
    else
        local Result = {}
        local Lookup = Built[CharSet] or AddLookup(CharSet)
        local Range = table.getn(Lookup)

        for Loop = 1,Length do
            Result[Loop] = Lookup[math.random(1, Range)]
        end

        return table.concat(Result)
    end
end


function HostPlayerMissingMapAlert(id)
    local slot = FindSlotForID(id)
    local name = ""
    local needMessage = false
    if slot then
        name = gameInfo.PlayerOptions[slot].PlayerName
        if not gameInfo.PlayerOptions[slot].BadMap then needMessage = true end
        gameInfo.PlayerOptions[slot].BadMap = true
    else
        slot = FindObserverSlotForID(id)
        if slot then
            name = gameInfo.Observers[slot].PlayerName
            if not gameInfo.Observers[slot].BadMap then needMessage = true end
            gameInfo.Observers[slot].BadMap = true
        end
    end

    if needMessage then
        SendSystemMessage(LOCF("<LOC lobui_0330>%s is missing map %s.", name, gameInfo.GameOptions.ScenarioFile))
        LOG('>> '..name..' is missing map '..gameInfo.GameOptions.ScenarioFile)
        if name == localPlayerName then
            LOG('>> '..gameInfo.GameOptions.ScenarioFile..' replaced with '..'SCMP_009')
            SetGameOption('ScenarioFile', '/maps/scmp_009/scmp_009_scenario.lua')
        end
    end
end

function ClientsMissingMap()
    local ret = nil

    for index, player in gameInfo.PlayerOptions do
        if player.BadMap == true then
            if not ret then ret = {} end
            table.insert(ret, player.PlayerName)
        end
    end

    for index, observer in gameInfo.Observers do
        if observer.BadMap == true then
            if not ret then ret = {} end
            table.insert(ret, observer.PlayerName)
        end
    end

    return ret
end

function ClearBadMapFlags()
    for index, player in gameInfo.PlayerOptions do
        player.BadMap = nil
    end

    for index, observer in gameInfo.Observers do
        observer.BadMap = nil
    end
end

-- create UI won't typically be called directly by another module
function CreateUI(maxPlayers)
    local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
    local Text = import('/lua/maui/text.lua').Text
    local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
    local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
    local Combo = import('/lua/ui/controls/combo.lua').Combo
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
    local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
    local EffectHelpers = import('/lua/maui/effecthelpers.lua')
    local ItemList = import('/lua/maui/itemlist.lua').ItemList
    local Prefs = import('/lua/user/prefs.lua')

    UIUtil.SetCurrentSkin('uef')

    if (GUI.connectdialog ~= false) then
        MenuCommon.MenuCleanup()
    end

    local title
    if GpgNetActive() then
        title = "FA FOREVER GAME LOBBY"
    elseif singlePlayer then
        title = LOC("<LOC _Skirmish_Setup>")
    else
        title = LOC("<LOC _LAN_Game_Lobby>")
    end

    -- Setup custom backgrounds.
    local LobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    GUI.background = Bitmap(GUI, UIUtil.SkinnableFile('/BACKGROUND/background-paint_black_bmp.png')) -- Background faction or art
    LayoutHelpers.AtCenterIn(GUI.background, GUI)
    if LobbyBackgroundStretch == 'true' then
        LayoutHelpers.FillParent(GUI.background, GUI)
    else
        LayoutHelpers.FillParentPreserveAspectRatio(GUI.background, GUI)
    end
    GUI.background2 = MapPreview(GUI) -- Background map
    LayoutHelpers.AtCenterIn(GUI.background2, GUI)
    GUI.background2.Width:Set(400)
    GUI.background2.Height:Set(400)
    if LobbyBackgroundStretch == 'true' then
        LayoutHelpers.FillParent(GUI.background2, GUI)
    else
        LayoutHelpers.FillParentPreserveAspectRatio(GUI.background2, GUI)
    end
    ---------------------------------------------------------------------------
    -- Set up main control panels
    ---------------------------------------------------------------------------
    GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/lobby.dds"))
    LayoutHelpers.AtCenterIn(GUI.panel, GUI)
    GUI.panelWideLeft = Bitmap(GUI, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/wide.dds'))
    LayoutHelpers.CenteredLeftOf(GUI.panelWideLeft, GUI.panel, -11)
    GUI.panelWideLeft.Left:Set(function() return GUI.Left() end)
    GUI.panelWideRight = Bitmap(GUI, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/wide.dds'))
    LayoutHelpers.CenteredRightOf(GUI.panelWideRight, GUI.panel, -11)
    GUI.panelWideRight.Right:Set(function() return GUI.Right() end)

    -- Create a label with a given size and initial text
    local function makeLabel(text, size)
        return UIUtil.CreateText(GUI.panel, text, size, 'Arial Gras', true)
    end

    -- Title Label
    GUI.titleText = makeLabel(title, 17)
    LayoutHelpers.AtLeftTopIn(GUI.titleText, GUI.panel, 50, 41)

    -- Map Name Label TODO: Localise!
    GUI.MapNameLabel = makeLabel("Loading...", 17)
    LayoutHelpers.AtRightTopIn(GUI.MapNameLabel, GUI.panel, 50, 41)

    -- Game Quality Label
    GUI.GameQualityLabel = makeLabel("", 13)
    LayoutHelpers.AtRightTopIn(GUI.GameQualityLabel, GUI.panel, 50, 61)

    -- Rule Label
    GUI.RuleLabel = ItemList(GUI.panel)
    GUI.RuleLabel:SetFont('Arial Gras', 11)
    GUI.RuleLabel:SetColors("B9BFB9", "00000000", "B9BFB9", "00000000") -- colortxt, bg, colortxt selec, bg selec?
    LayoutHelpers.AtLeftTopIn(GUI.RuleLabel, GUI.panel, 50, 81) --Right, Top
    GUI.RuleLabel.Height:Set(34)
    GUI.RuleLabel.Width:Set(350)
    GUI.RuleLabel:DeleteAllItems()
    local tmptext
    if lobbyComm:IsHost() then
        tmptext = 'No Rules: Click to add rules'
        GUI.RuleLabel:SetColors("FFCC00")
    else
        tmptext = 'Rule : no rule.'
    end
    GUI.RuleLabel:AddItem(tmptext or '')
    GUI.RuleLabel:AddItem('')
    if lobbyComm:IsHost() then
        GUI.RuleLabel.OnClick = function(self)
            RuleTitle_INPUT()
        end
    end

    -- Mod Label
    GUI.ModFeaturedLabel = makeLabel("", 13)
    LayoutHelpers.AtLeftTopIn(GUI.ModFeaturedLabel, GUI.panel, 50, 61)

    local getInit = GetCommandLineArg("/init", 1)
    getInit = tostring(getInit[1])
    if getInit == "init_faf.lua" then
        SetText2(GUI.ModFeaturedLabel, 'FA Forever', 10)
    elseif getInit == "init_blackops.lua" then
        SetText2(GUI.ModFeaturedLabel, 'BlackOps MOD', 10)
    elseif getInit == "init_coop.lua" then
        SetText2(GUI.ModFeaturedLabel, 'COOP', 10)
    elseif getInit == "init_balancetesting.lua" then
        SetText2(GUI.ModFeaturedLabel, 'Balance Testing', 10)
    elseif getInit == "init_gw.lua" then
        SetText2(GUI.ModFeaturedLabel, 'Galactic War', 10)
    elseif getInit == "init_labwars.lua" then
        SetText2(GUI.ModFeaturedLabel, 'Labwars MOD', 10)
    elseif getInit == "init_ladder1v1.lua" then
        SetText2(GUI.ModFeaturedLabel, 'Ladder 1v1', 10)
    elseif getInit == "init_nomads.lua" then
        SetText2(GUI.ModFeaturedLabel, 'Nomads MOD', 10)
    elseif getInit == "init_phantomx.lua" then
        SetText2(GUI.ModFeaturedLabel, 'PhantomX MOD', 10)
    elseif getInit == "init_supremedestruction.lua" then
        SetText2(GUI.ModFeaturedLabel, 'SupremeDestruction MOD', 10)
    elseif getInit == "init_xtremewars.lua" then
        SetText2(GUI.ModFeaturedLabel, 'XtremeWars MOD', 10)
    end
    --\\
    --// Lobby options panel
    GUI.LobbyOptions = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/BUTTON/small/', "Lobby Options", -1)
    LayoutHelpers.AtTopIn(GUI.LobbyOptions, GUI.panel, 10)
    LayoutHelpers.AtHorizontalCenterIn(GUI.LobbyOptions, GUI, 0)
    GUI.LobbyOptions.OnClick = function()
        CreateOptionLobbyDialog()
    end
    --\\
    --// Credits footer
    -- TODO: Localise or exterminate.
    local Credits = 'New Skin by Xinnony and Barlots (Lobby version : '..LOBBYversion..')'
    GUI.Credits_Text = UIUtil.CreateText(GUI.panel, Credits, 12, UIUtil.titleFont, true)
    SetText2(GUI.Credits_Text, Credits, 10)
    GUI.Credits_Text:SetColor("FFFFFF")
    LayoutHelpers.AtBottomIn(GUI.Credits_Text, GUI, 0)
    LayoutHelpers.AtRightIn(GUI.Credits_Text, GUI, 11)
    --\\

    -- FOR SEE THE GROUP POSITION, LOOK THIS SCREENSHOOT : http://img402.imageshack.us/img402/8826/falobbygroup.png
    GUI.playerPanel = Group(GUI.panel, "playerPanel") -- RED Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.playerPanel, GUI.panel, 40, 66+40-4)
    GUI.playerPanel.Width:Set(706)
    GUI.playerPanel.Height:Set(307)

    GUI.buttonPanelTop = Group(GUI.panel, "buttonPanelTop") -- GREEN Square in Screenshoot - Added group for Button
    LayoutHelpers.AtLeftTopIn(GUI.buttonPanelTop, GUI.panel, 40, 383+48)
    GUI.buttonPanelTop.Width:Set(706)
    GUI.buttonPanelTop.Height:Set(19)

    GUI.buttonPanelRight = Group(GUI.panel, "buttonPanelRight") -- PURPLE Square in Screenshoot - Added group for Button
    LayoutHelpers.AtLeftTopIn(GUI.buttonPanelRight, GUI.panel, 481, 401+24)
    GUI.buttonPanelRight.Width:Set(265)
    GUI.buttonPanelRight.Height:Set(89)

    GUI.observerPanel = Group(GUI.panel, "observerPanel") -- PINK Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.observerPanel, GUI.panel, 458, 519)
    GUI.observerPanel.Width:Set(280)
    GUI.observerPanel.Height:Set(152)

    GUI.chatPanel = Group(GUI.panel, "chatPanel") -- BLUE Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.chatPanel, GUI.panel, 49, 458)
    GUI.chatPanel.Width:Set(388)
    GUI.chatPanel.Height:Set(184)

    GUI.mapPanel = Group(GUI.panel, "mapPanel") -- YELLOW Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.mapPanel, GUI.panel, 763, 106)
    GUI.mapPanel.Width:Set(208)
    GUI.mapPanel.Height:Set(208+2)

    GUI.optionsPanel = Group(GUI.panel, "optionsPanel") -- ORANGE Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.optionsPanel, GUI.panel, 762, 353)
    GUI.optionsPanel.Width:Set(209)
    GUI.optionsPanel.Height:Set(284)

    GUI.launchPanel = Group(GUI.panel, "controlGroup") -- BROWN Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.launchPanel, GUI.panel, 735, 668)
    GUI.launchPanel.Width:Set(238)
    GUI.launchPanel.Height:Set(66)

    GUI.NEWlaunchPanel = Group(GUI.panel, "NEWlaunchPanel") -- BLACK Square in Screenshoot - Added group for Button
    LayoutHelpers.AtLeftTopIn(GUI.NEWlaunchPanel, GUI.panel, 40, 667)
    GUI.NEWlaunchPanel.Width:Set(948)
    GUI.NEWlaunchPanel.Height:Set(68)

    ---------------------------------------------------------------------------
    -- set up map panel
    ---------------------------------------------------------------------------
    GUI.mapView = MapPreview(GUI.mapPanel)
    LayoutHelpers.AtLeftTopIn(GUI.mapView, GUI.mapPanel, 5, 6)--mapOverlay)
    GUI.mapView.Width:Set(196+2)
    GUI.mapView.Height:Set(194)

    GUI.LargeMapPreview = UIUtil.CreateButtonWithDropshadow(GUI.mapView, '/BUTTON/zoom/', "", 0)
    LayoutHelpers.AtRightIn(GUI.LargeMapPreview, GUI.mapView, -3)
    LayoutHelpers.AtBottomIn(GUI.LargeMapPreview, GUI.mapView, -3)
    Tooltip.AddButtonTooltip(GUI.LargeMapPreview, 'lob_click_LargeMapPreview')
    GUI.LargeMapPreview.OnClick = function()
        CreateBigPreview(501, GUI)
    end

    -- Checkbox Show changed Options
    local cbox_ShowChangedOption = UIUtil.CreateCheckboxStd(GUI.optionsPanel, '/CHECKBOX/radio')
    LayoutHelpers.AtLeftTopIn(cbox_ShowChangedOption, GUI.optionsPanel, 3, 0)
    -- TODO: Localise!

    Tooltip.AddCheckboxTooltip(cbox_ShowChangedOption, {text='Hide default Options', body='Show only changed Options and Advanced Map Options'})
    local cbox_ShowChangedOption_TEXT = UIUtil.CreateText(cbox_ShowChangedOption, 'Hide default Options', 11, 'Arial', true)
    cbox_ShowChangedOption_TEXT:SetColor('B9BFB9')
    LayoutHelpers.AtLeftIn(cbox_ShowChangedOption_TEXT, cbox_ShowChangedOption, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_ShowChangedOption_TEXT, cbox_ShowChangedOption)
    cbox_ShowChangedOption.OnCheck = function(self, checked)
        HideDefaultOptions = checked
        RefreshOptionDisplayData()
        GUI.OptionContainer.ScrollSetTop(GUI.OptionContainer, 'Vert', 0)
        Prefs.SetToCurrentProfile('LobbyHideDefaultOptions', tostring(checked))
    end

    -- GAME OPTIONS // MODS MANAGER BUTTON --
    if lobbyComm:IsHost() then     -- GAME OPTION
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "Game Options", -1)
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'lob_select_map')
        GUI.gameoptionsButton.OnClick = function(self)
            local mapSelectDialog

            autoRandMap = false
            quickRandMap = false
            local function selectBehavior(selectedScenario, changedOptions, restrictedCategories)
                if autoRandMap then
                    Prefs.SetToCurrentProfile('LastScenario', selectedScenario.file)
                    gameInfo.GameOptions['ScenarioFile'] = selectedScenario.file
                else
                    Prefs.SetToCurrentProfile('LastScenario', selectedScenario.file)
                    mapSelectDialog:Destroy()
                    GUI.chatEdit:AcquireFocus()
                    for optionKey, data in changedOptions do
                        Prefs.SetToCurrentProfile(data.pref, data.index)
                        SetGameOption(optionKey, data.value)
                    end
                    --SendSystemMessage(selectedScenario.file)

                    SetGameOption('ScenarioFile',selectedScenario.file)

                    SetGameOption('RestrictedCategories', restrictedCategories, true)
                    ClearBadMapFlags()  -- every new map, clear the flags, and clients will report if a new map is bad
                    HostUpdateMods()
                    UpdateGame()
                end
            end

            local function exitBehavior()
                mapSelectDialog:Destroy()
                GUI.chatEdit:AcquireFocus()
                UpdateGame()
            end

            GUI.chatEdit:AbandonFocus()

            mapSelectDialog = import('/lua/ui/dialogs/mapselect.lua').CreateDialog(
                selectBehavior,
                exitBehavior,
                GUI,
                singlePlayer,
                gameInfo.GameOptions.ScenarioFile,
                gameInfo.GameOptions,
                availableMods,
                OnModsChanged
            )
        end
    else
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "Mods Manager", -1)
        GUI.gameoptionsButton.OnClick = function(self, modifiers)
            import('/lua/ui/lobby/ModsManager.lua').NEW_MODS_GUI(GUI, false, gameInfo.GameMods)
        end
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'Lobby_Mods')
    end

    LayoutHelpers.AtBottomIn(GUI.gameoptionsButton, GUI.optionsPanel, -55)
    LayoutHelpers.AtHorizontalCenterIn(GUI.gameoptionsButton, GUI.optionsPanel)

    ---------------------------------------------------------------------------
    -- set up launch panel
    ---------------------------------------------------------------------------
    -- LAUNCH THE GAME BUTTON --
    GUI.launchGameButton = UIUtil.CreateButtonWithDropshadow(GUI.launchPanel, '/BUTTON/large/', "Launch the Game", -1)
    LayoutHelpers.AtCenterIn(GUI.launchGameButton, GUI.launchPanel, 20, -345)
    Tooltip.AddButtonTooltip(GUI.launchGameButton, 'Lobby_Launch')
    UIUtil.setVisible(GUI.launchGameButton, lobbyComm:IsHost())
    GUI.launchGameButton.OnClick = function(self)
        TryLaunch(false)
    end

    -- EXIT BUTTON --
    GUI.exitButton = UIUtil.CreateButtonWithDropshadow(GUI.launchPanel, '/BUTTON/medium/','Exit', -1)
    if GpgNetActive() then
        GUI.exitButton.label:SetText(LOC("<LOC _Exit>"))
    else
        GUI.exitButton.label:SetText(LOC("<LOC _Back>"))
    end
    import('/lua/ui/uimain.lua').SetEscapeHandler(function() GUI.exitButton.OnClick(GUI.exitButton) end)
    LayoutHelpers.AtLeftIn(GUI.exitButton, GUI.chatPanel, 22)
    LayoutHelpers.AtVerticalCenterIn(GUI.exitButton, GUI.launchGameButton)
    GUI.exitButton.OnClick = function(self)
        GUI.chatEdit:AbandonFocus()
        UIUtil.QuickDialog(GUI,
                            "<LOC lobby_0000>Exit game lobby?",
                            "<LOC _Yes>", function()
                                ReturnToMenu(false)
                            end,
                            "<LOC _Cancel>", function()
                                GUI.chatEdit:AcquireFocus()
                            end,
                            nil, nil,
                            true,
                            {worldCover = true, enterButton = 1, escapeButton = 2}
        )
    end

    ---------------------------------------------------------------------------
    -- set up chat display
    ---------------------------------------------------------------------------
    GUI.chatEdit = Edit(GUI.chatPanel)
    LayoutHelpers.AtLeftTopIn(GUI.chatEdit, GUI.chatPanel, 0+13, 184+7)
    GUI.chatEdit.Width:Set(334)
    GUI.chatEdit.Height:Set(24)
    GUI.chatEdit:SetFont(UIUtil.bodyFont, 16)
    GUI.chatEdit:SetForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:SetHighlightBackgroundColor('00000000')
    GUI.chatEdit:SetHighlightForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:ShowBackground(false)
    GUI.chatEdit:AcquireFocus()

    GUI.chatDisplay = ItemList(GUI.chatPanel)
    GUI.chatDisplay:SetFont(UIUtil.bodyFont, tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14)
    GUI.chatDisplay:SetColors(UIUtil.fontColor(), "00000000", UIUtil.fontColor(), "00000000")
    LayoutHelpers.AtLeftTopIn(GUI.chatDisplay, GUI.chatPanel, 8, 4) --Right, Top
    GUI.chatDisplay.Bottom:Set(function() return GUI.chatEdit.Top() -6 end)
    GUI.chatDisplay.Right:Set(function() return GUI.chatPanel.Right() -0 end)
    GUI.chatDisplay.Height:Set(function() return GUI.chatDisplay.Bottom() - GUI.chatDisplay.Top() end)
    GUI.chatDisplay.Width:Set(function() return GUI.chatDisplay.Right() - GUI.chatDisplay.Left() -20 end)

    GUI.chatDisplayScroll = UIUtil.CreateLobbyVertScrollbar(GUI.chatDisplay, -21, nil, 30)

    -- OnlineProvider.RegisterChatDisplay(GUI.chatDisplay)

    GUI.chatEdit:SetMaxChars(200)
    GUI.chatEdit.OnCharPressed = function(self, charcode)
        if charcode == UIUtil.VK_TAB then
            return true
        end

        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end

    GUI.chatEdit.OnLoseKeyboardFocus = function(self)
        GUI.chatEdit:AcquireFocus()
    end

    GUI.chatEdit.OnEnterPressed = function(self, text)
        if text ~= "" then
            GpgNetSend('Chat', text)
            table.insert(commandQueue, 1, text)
            commandQueueIndex = 0
            if GUI.chatDisplay then
                    --this next section just removes /commmands from broadcasting.
                if string.sub(text, 1, 1) == '/' then
                    local spaceStart = string.find(text, " ") or string.len(text)
                    local comKey = string.sub(text, 2, spaceStart - 1)
                    local params = string.sub(text, spaceStart + 1)
                    local found = false
                    for i, command in commands do
                        if command.key == string.lower(comKey) then
                            command.action(params)
                            found = true
                            break
                        end
                    end
                    if not found then
                        AddChatText(LOCF("<LOC lobui_0396>Command Not Known: %s", comKey))
                    end
                else
                    PublicChat(text)
                end
            end
        end
    end

    GUI.chatEdit.OnNonTextKeyPressed = function(self, keyCode)
        if commandQueue and table.getsize(commandQueue) > 0 then
            if keyCode == 38 then
                if commandQueue[commandQueueIndex + 1] then
                    commandQueueIndex = commandQueueIndex + 1
                    self:SetText(commandQueue[commandQueueIndex])
                end
            end
            if keyCode == 40 then
                if commandQueueIndex ~= 1 then
                    if commandQueue[commandQueueIndex - 1] then
                        commandQueueIndex = commandQueueIndex - 1
                        self:SetText(commandQueue[commandQueueIndex])
                    end
                else
                    commandQueueIndex = 0
                    self:ClearText()
                end
            end
        end
    end


    ---------------------------------------------------------------------------
    -- Option display
    ---------------------------------------------------------------------------
    GUI.OptionContainer = Group(GUI.optionsPanel)
    GUI.OptionContainer.Height:Set(260)
    GUI.OptionContainer.Width:Set(209-9-17-1)
    GUI.OptionContainer.top = 0
    LayoutHelpers.AtLeftTopIn(GUI.OptionContainer, GUI.optionsPanel, 0+4+1, 30-2) -- -24

    GUI.OptionDisplay = {}

    function CreateOptionElements()
        local function CreateElement(index)
            local element = Group(GUI.OptionContainer)

            element.Height:Set(36)
            element.Width:Set(GUI.OptionContainer.Width)
            element.Depth:Set(function() return GUI.OptionContainer.Depth() + 10 end)
            element:DisableHitTest()

            element.text = UIUtil.CreateText(element, '', 14, "Arial")
            element.text:SetColor(UIUtil.fontColor)
            element.text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(element.text, element, 5)

            element.value = UIUtil.CreateText(element, '', 14, "Arial")
            element.value:SetColor(UIUtil.fontOverColor)
            element.value:DisableHitTest()
            LayoutHelpers.AtRightTopIn(element.value, element, 5, 16)

            element.value.bg = Bitmap(element)
            element.value.bg:SetSolidColor('ff333333')
            element.value.bg.Left:Set(element.Left)
            element.value.bg.Right:Set(element.Right)
            element.value.bg.Bottom:Set(function() return element.value.Bottom() + 2 end)
            element.value.bg.Top:Set(element.Top)
            element.value.bg.Depth:Set(function() return element.Depth() - 2 end)

            element.value.bg2 = Bitmap(element)
            element.value.bg2:SetSolidColor('ff000000')
            element.value.bg2.Left:Set(function() return element.value.bg.Left() + 1 end)
            element.value.bg2.Right:Set(function() return element.value.bg.Right() - 1 end)
            element.value.bg2.Bottom:Set(function() return element.value.bg.Bottom() - 1 end)
            element.value.bg2.Top:Set(function() return element.value.Top() + 0 end)
            element.value.bg2.Depth:Set(function() return element.value.bg.Depth() + 1 end)

            GUI.OptionDisplay[index] = element
        end

        CreateElement(1)
        LayoutHelpers.AtLeftTopIn(GUI.OptionDisplay[1], GUI.OptionContainer)

        local index = 2
        while index ~= 8 do
            CreateElement(index)
            LayoutHelpers.Below(GUI.OptionDisplay[index], GUI.OptionDisplay[index-1])
            index = index + 1
        end
    end
    CreateOptionElements()

    local numLines = function() return table.getsize(GUI.OptionDisplay) end

    local function DataSize()
        if HideDefaultOptions then
            return table.getn(nonDefaultFormattedOptions)
        else
            return table.getn(formattedOptions)
        end
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.OptionContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines, size))
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.OptionContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.OptionContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.OptionContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.OptionContainer.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    GUI.OptionContainer.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            if data.mod then
                -- The special label at the top stating the number of mods.
                line.text:SetColor('ffff7777')
                LayoutHelpers.AtHorizontalCenterIn(line.text, line, 5)
                LayoutHelpers.AtHorizontalCenterIn(line.value, line, 5, 16)
                LayoutHelpers.ResetRight(line.value)
            else
                -- Game options.
                line.text:SetColor(UIUtil.fontColor)
                LayoutHelpers.AtLeftTopIn(line.text, line, 5)
                LayoutHelpers.AtRightTopIn(line.value, line, 5, 16)
                LayoutHelpers.ResetLeft(line.value)
            end
            line.text:SetText(LOC(data.text))
            line.value.bg:Show()
            line.value:SetText(LOC(data.value))
            line.value.bg2:Show()
            line.value.bg.HandleEvent = Group.HandleEvent
            line.value.bg2.HandleEvent = Bitmap.HandleEvent
            if data.tooltip then
                Tooltip.AddControlTooltip(line.value.bg, data.tooltip)
                Tooltip.AddControlTooltip(line.value.bg2, data.valueTooltip)
            end
        end

        local optionsToUse
        if HideDefaultOptions then
            optionsToUse = nonDefaultFormattedOptions
        else
            optionsToUse = formattedOptions
        end

        for i, v in GUI.OptionDisplay do
            if optionsToUse[i + self.top] then
                SetTextLine(v, optionsToUse[i + self.top], i + self.top)
            else
                v.text:SetText('')
                v.value:SetText('')
                v.value.bg:Hide()
                v.value.bg2:Hide()
            end
        end
    end

    GUI.OptionContainer.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end

    RefreshOptionDisplayData()

    UIUtil.CreateLobbyVertScrollbar(GUI.OptionContainer, 1, nil, -9, -24)

    -- Create skirmish mode's "load game" button.
    GUI.loadButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/small/',"<LOC lobui_0176>Load")
    UIUtil.setVisible(GUI.loadButton, singlePlayer)
    LayoutHelpers.LeftOf(GUI.loadButton, GUI.launchGameButton, 10)
    LayoutHelpers.AtVerticalCenterIn(GUI.loadButton, GUI.launchGameButton)
    GUI.loadButton.OnClick = function(self, modifiers)
        import('/lua/ui/dialogs/saveload.lua').CreateLoadDialog(GUI)
    end
    Tooltip.AddButtonTooltip(GUI.loadButton, 'Lobby_Load')

    -- Create the "Lobby presets" button for the host. If not the host, the same field is occupied
    -- instead by the read-only "Unit Manager" button.
    GUI.restrictedUnitsOrPresetsBtn = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "", 0)

    if singlePlayer then
        GUI.restrictedUnitsOrPresetsBtn:Hide()
    elseif lobbyComm:IsHost() then
        -- TODO: Localise!
        GUI.restrictedUnitsOrPresetsBtn.label:SetText("Lobby Presets")
        GUI.restrictedUnitsOrPresetsBtn.OnClick = function(self, modifiers)
            GUI_PRESET()
        end
        -- TODO: Localise!
        Tooltip.AddButtonTooltip(GUI.restrictedUnitsOrPresetsBtn, 'Lobby_presetDescription')
    else
        -- TODO: Localise!
        GUI.restrictedUnitsOrPresetsBtn.label:SetText("Unit Manager")
        GUI.restrictedUnitsOrPresetsBtn.OnClick = function(self, modifiers)
            import('/lua/ui/lobby/restrictedUnitsDlg.lua').CreateDialog(GUI.panel, gameInfo.GameOptions.RestrictedCategories, function() end, function() end, false)
        end
        Tooltip.AddButtonTooltip(GUI.restrictedUnitsOrPresetsBtn, 'lob_RestrictedUnitsClient')
    end
    LayoutHelpers.AtHorizontalCenterIn(GUI.restrictedUnitsOrPresetsBtn, GUI.gameoptionsButton)
    LayoutHelpers.AtVerticalCenterIn(GUI.restrictedUnitsOrPresetsBtn, GUI.exitButton)

    ---------------------------------------------------------------------------
    -- Checkbox Show changed Options
    ---------------------------------------------------------------------------
    cbox_ShowChangedOption:SetCheck(HideDefaultOptions, false)

    ---------------------------------------------------------------------------
    -- set up : player grid
    ---------------------------------------------------------------------------

    -- set up player "slots" which is the line representing a player and player specific options
    local prev = nil

    local slotColumnSizes = {
        rating = {x = 68, width = 45},
        games = {x = 114, width = 45},
        player = {x = 161, width = 264},
        color = {x = (161+264)+11, width = 59},
        faction = {x = (161+264+11+59)+11, width = 59},
        team = {x =(161+264+11+59+11+59)+11, width = 59},
        ping = {x = (161+264+11+59+11+59+11+59)+11, width = 62},
        ready = {x = (161+264+11+59+11+59+11+59+11)+62, width = 51},
    }

    GUI.labelGroup = Group(GUI.playerPanel)
    GUI.labelGroup.Width:Set(690)
    GUI.labelGroup.Height:Set(21)
    LayoutHelpers.AtLeftTopIn(GUI.labelGroup, GUI.playerPanel, 5, 5)

    GUI.ratingLabel = makeLabel("R", 14)
    LayoutHelpers.AtLeftIn(GUI.ratingLabel, GUI.panel, slotColumnSizes.rating.x+20) -- Offset Right
    LayoutHelpers.AtVerticalCenterIn(GUI.ratingLabel, GUI.labelGroup, 5) -- Offset Down
    Tooltip.AddControlTooltip(GUI.ratingLabel, 'rating')

    GUI.numGamesLabel = makeLabel("G", 14)
    LayoutHelpers.AtLeftIn(GUI.numGamesLabel, GUI.panel, slotColumnSizes.games.x - 4 + 24)
    LayoutHelpers.AtVerticalCenterIn(GUI.numGamesLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.numGamesLabel, 'num_games')

    GUI.nameLabel = makeLabel("Nickname", 14)
    LayoutHelpers.AtLeftIn(GUI.nameLabel, GUI.panel, slotColumnSizes.player.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.nameLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.nameLabel, 'lob_slot')

    GUI.colorLabel = makeLabel("Color", 14)
    LayoutHelpers.AtLeftIn(GUI.colorLabel, GUI.panel, slotColumnSizes.color.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.colorLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.colorLabel, 'lob_color')

    GUI.factionLabel = makeLabel("Faction", 14)
    LayoutHelpers.AtLeftIn(GUI.factionLabel, GUI.panel, slotColumnSizes.faction.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.factionLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.factionLabel, 'lob_faction')

    GUI.teamLabel = makeLabel("Team", 14)
    LayoutHelpers.AtLeftIn(GUI.teamLabel, GUI.panel, slotColumnSizes.team.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.teamLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.teamLabel, 'lob_team')

    GUI.pingLabel = makeLabel("Ping/CPU", 14)
    LayoutHelpers.AtLeftIn(GUI.pingLabel, GUI.panel, slotColumnSizes.ping.x-18+3)
    LayoutHelpers.AtVerticalCenterIn(GUI.pingLabel, GUI.labelGroup, 5)

    GUI.readyLabel = makeLabel("Ready", 14)
    LayoutHelpers.AtLeftIn(GUI.readyLabel, GUI.panel, slotColumnSizes.ready.x-3+3)
    LayoutHelpers.AtVerticalCenterIn(GUI.readyLabel, GUI.labelGroup, 5)

    for i= 1, LobbyComm.maxPlayerSlots do
        -- capture the index in the current closure so it's accessible on callbacks
        local curRow = i

        GUI.slots[i] = Group(GUI.playerPanel, "playerSlot " .. tostring(i))
        GUI.slots[i].closed = false
        --TODO these need layout from art when available
        GUI.slots[i].Width:Set(GUI.labelGroup.Width)
        GUI.slots[i].Height:Set(GUI.labelGroup.Height)
        GUI.slots[i]._slot = i
        GUI.slots[i].HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' and GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                if GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Stop()
                end
            end
            return Group.HandleEvent(self, event)
        end

        local bg = GUI.slots[i]

        --// Slot Background
        GUI.slots[i].SlotBackground = Bitmap(GUI, UIUtil.SkinnableFile("/SLOT/slot-dis.dds"))
        LayoutHelpers.AtBottomIn(GUI.slots[i].SlotBackground, GUI.slots[i], -6)
        LayoutHelpers.AtLeftIn(GUI.slots[i].SlotBackground, GUI.slots[i], 0)
        --\\ Stop Slot Background

        --// COUNTRY
        -- Added a bitmap on the left of Rating, the bitmap is a Flag of Country
        GUI.slots[i].KinderCountry = Bitmap(bg, UIUtil.SkinnableFile("/countries/world.dds"))
        GUI.slots[i].KinderCountry.Width:Set(20)
        GUI.slots[i].KinderCountry.Height:Set(17-2) -- 15=2pix marging || 17=1pix marging
        LayoutHelpers.AtBottomIn(GUI.slots[i].KinderCountry, GUI.slots[i], -4) -- -5
        LayoutHelpers.AtLeftIn(GUI.slots[i].KinderCountry, GUI.slots[i], 2) -- 1
        --\\ Stop COUNTRY

        -- TODO: Factorise this boilerplate.
        --// Rating
        GUI.slots[i].ratingGroup = Group(bg)
        GUI.slots[i].ratingGroup.Width:Set(slotColumnSizes.rating.width)
        GUI.slots[i].ratingGroup.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].ratingGroup, GUI.panel, slotColumnSizes.rating.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].ratingGroup, GUI.slots[i], 6)
        GUI.slots[i].ratingText = UIUtil.CreateText(GUI.slots[i].ratingGroup, "", 14, 'Arial')--14, UIUtil.bodyFont)
        GUI.slots[i].ratingText:SetColor('B9BFB9')
        GUI.slots[i].ratingText:SetDropShadow(true)
        LayoutHelpers.AtBottomIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup, 2)
        LayoutHelpers.AtRightIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup, 9)
        GUI.slots[i].tooltiprating = Tooltip.AddControlTooltip(GUI.slots[i].ratingText, 'rating')

        --// NumGame
        GUI.slots[i].numGamesGroup = Group(bg)
        GUI.slots[i].numGamesGroup.Width:Set(slotColumnSizes.games.width)
        GUI.slots[i].numGamesGroup.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].numGamesGroup, GUI.panel, slotColumnSizes.games.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].numGamesGroup, GUI.slots[i], 6)
        GUI.slots[i].numGamesText = UIUtil.CreateText(GUI.slots[i].numGamesGroup, "", 14, 'Arial')--14, UIUtil.bodyFont)
        GUI.slots[i].numGamesText:SetColor('B9BFB9')
        GUI.slots[i].numGamesText:SetDropShadow(true)
        Tooltip.AddControlTooltip(GUI.slots[i].numGamesText, 'num_games')
        LayoutHelpers.AtBottomIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup, 2)
        LayoutHelpers.AtRightIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup, 9)

        --// Name
        GUI.slots[i].name = Combo(bg, 14, 12, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        GUI.slots[i].name._text:SetFont('Arial Gras', 15)
        GUI.slots[i].name._text:SetDropShadow(true)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].name, GUI.slots[i], 8)
        LayoutHelpers.AtLeftIn(GUI.slots[i].name, GUI.panel, slotColumnSizes.player.x)
        GUI.slots[i].name.Width:Set(slotColumnSizes.player.width)
        GUI.slots[i].name.row = i
        -- left deal with name clicks
        GUI.slots[i].name.OnEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' and GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                if GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Stop()
                end
            elseif event.Type == 'ButtonDClick' then
                DoSlotBehavior(curRow, 'occupy', '')
            end
        end
        GUI.slots[i].name.OnClick = function(self, index, text)
            DoSlotBehavior(self.row, self.slotKeys[index], text)
        end

        -- Color
        GUI.slots[i].color = BitmapCombo(bg, BASE_ALL_Color, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].color, GUI.panel, slotColumnSizes.color.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].color, GUI.slots[i], 9)
        GUI.slots[i].color.Width:Set(slotColumnSizes.color.width)
        GUI.slots[i].color.row = i
        GUI.slots[i].color.OnClick = function(self, index)
            Get_IndexColor_by_CompleteTable(index, i)
            Tooltip.DestroyMouseoverDisplay()
            if not lobbyComm:IsHost() then
                lobbyComm:SendData(hostID, { Type = 'RequestColor', Color = index, Slot = self.row } )
                gameInfo.PlayerOptions[self.row].PlayerColor = index
                gameInfo.PlayerOptions[self.row].ArmyColor = index

                UpdateGame()
            else
                if IsColorFree(index) then
                    lobbyComm:BroadcastData( { Type = 'SetColor', Color = index, Slot = self.row } )
                    gameInfo.PlayerOptions[self.row].PlayerColor = index
                    gameInfo.PlayerOptions[self.row].ArmyColor = index

                    UpdateGame()
                else
                    self:SetItem( gameInfo.PlayerOptions[self.row].PlayerColor )
                end
            end
        end
        GUI.slots[i].color.OnEvent = GUI.slots[curRow].name.OnEvent
        Tooltip.AddControlTooltip(GUI.slots[i].color, 'lob_color')
        GUI.slots[i].color.row = i

        --// Faction
        GUI.slots[i].faction = BitmapCombo(bg, factionBmps, table.getn(factionBmps), nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].faction, GUI.panel, slotColumnSizes.faction.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].faction, GUI.slots[i], 9)
        GUI.slots[i].faction.Width:Set(slotColumnSizes.faction.width)
        GUI.slots[i].faction.OnClick = function(self, index)
            SetPlayerOption(self.row,'Faction',index)
            if curRow == FindSlotForID(FindIDForName(localPlayerName)) then
                SetCurrentFactionTo_Faction_Selector()
            end
            Tooltip.DestroyMouseoverDisplay()
        end
        Tooltip.AddControlTooltip(GUI.slots[i].faction, 'lob_faction')
        Tooltip.AddComboTooltip(GUI.slots[i].faction, factionTooltips)
        GUI.slots[i].faction.row = i
        GUI.slots[i].faction.OnEvent = GUI.slots[curRow].name.OnEvent
        if not hasSupcom then
            GUI.slots[i].faction:SetItem(4)
        end

        --// Team
        GUI.slots[i].team = BitmapCombo(bg, teamIcons, 1, false, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].team, GUI.panel, slotColumnSizes.team.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].team, GUI.slots[i], 9)
        GUI.slots[i].team.Width:Set(slotColumnSizes.team.width)
        GUI.slots[i].team.row = i
        GUI.slots[i].team.OnClick = function(self, index, text)
            Tooltip.DestroyMouseoverDisplay()
            SetPlayerOption(self.row,'Team',index)
        end
        Tooltip.AddControlTooltip(GUI.slots[i].team, 'lob_team')
        Tooltip.AddComboTooltip(GUI.slots[i].team, teamTooltips)
        GUI.slots[i].team.OnEvent = GUI.slots[curRow].name.OnEvent

        -- Ping
        GUI.slots[i].pingGroup = Group(bg)
        GUI.slots[i].pingGroup.Width:Set(slotColumnSizes.ping.width)
        GUI.slots[i].pingGroup.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].pingGroup, GUI.panel, slotColumnSizes.ping.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].pingGroup, GUI.slots[i], 6)

        GUI.slots[i].pingStatus = StatusBar(GUI.slots[i].pingGroup, 0, 1000, false, false,
                                            UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                                            UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
                                            true)
        LayoutHelpers.AtTopIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 5)
        LayoutHelpers.AtLeftIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 0)
        LayoutHelpers.AtRightIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 0)

        -- depending on if this is single player or multiplayer this displays different info
        GUI.slots[i].multiSpace = Group(bg, "multiSpace " .. tonumber(i))
        GUI.slots[i].multiSpace.Width:Set(slotColumnSizes.ready.width)
        GUI.slots[i].multiSpace.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].multiSpace, GUI.panel, slotColumnSizes.ready.x)
        GUI.slots[i].multiSpace.Top:Set(GUI.slots[curRow].Top)

        -- Ready Checkbox
        GUI.slots[i].ready = UIUtil.CreateCheckboxStd(GUI.slots[i].multiSpace, '/CHECKBOX/radio')
        GUI.slots[i].ready.row = i
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 8)
        LayoutHelpers.AtLeftIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 0)
        GUI.slots[i].ready.OnCheck = function(self, checked)
            UIUtil.setEnabled(GUI.becomeObserver, not checked)
            if checked then
                DisableSlot(self.row, true)
            else
                EnableSlot(self.row)
            end
            SetPlayerOption(self.row,'Ready',checked)
        end

        if singlePlayer then
            -- TODO: Use of groups may allow this to be simplified...
            GUI.slots[i].ready:Hide()
            GUI.slots[i].pingGroup:Hide()
            GUI.slots[i].pingStatus:Hide()
        end


        if i == 1 then
            LayoutHelpers.Below(GUI.slots[i], GUI.labelGroup, -5)
        else
            LayoutHelpers.Below(GUI.slots[i], GUI.slots[i - 1], 3)
        end
    end

    function EnableSlot(slot)
        GUI.slots[slot].team:Enable()
        GUI.slots[slot].color:Enable()
        GUI.slots[slot].faction:Enable()
        GUI.slots[slot].ready:Enable()
    end

    function DisableSlot(slot, exceptReady)
        GUI.slots[slot].team:Disable()
        GUI.slots[slot].color:Disable()
        GUI.slots[slot].faction:Disable()
        if not exceptReady then
            GUI.slots[slot].ready:Disable()
        end
    end

    -- Initially clear all slots
    for slot = 1, maxPlayers do
        ClearSlotInfo(slot)
    end
    ---------------------------------------------------------------------------
    -- set up observer and limbo grid
    ---------------------------------------------------------------------------

    -- FIXME : this is not needed anymore.
    if lobbyComm:IsHost() then
        SetGameOption('RandomMap', 'Off', false, true) --make sure always create lobby with Random Map off
        SetGameOption('RankedGame', 'Off', false, true) --make sure always create lobby with Ranked Game off
    end

    GUI.allowObservers = UIUtil.CreateCheckboxStd(GUI.buttonPanelTop, '/CHECKBOX/radio')
    LayoutHelpers.CenteredLeftOf(GUI.allowObservers, GUI.buttonPanelTop, -30)
    Tooltip.AddControlTooltip(GUI.allowObservers, 'lob_observers_allowed')
    GUI.observerLabel = UIUtil.CreateText(GUI.allowObservers, 'Observers in Game', 11, 'Arial', true)
    LayoutHelpers.CenteredRightOf(GUI.observerLabel, GUI.allowObservers, 0)
    Tooltip.AddControlTooltip(GUI.observerLabel, 'lob_describe_observers')
    GUI.allowObservers:SetCheck(false)
    if lobbyComm:IsHost() then
        SetGameOption("AllowObservers", false, false, true)
        GUI.allowObservers.OnCheck = function(self, checked)
            SetGameOption("AllowObservers", checked)
        end
    else
        GUI.allowObservers:Disable()
        GUI.observerLabel:Disable()
    end

    -- GO OBSERVER BUTTON --
    GUI.becomeObserver = UIUtil.CreateButtonWithDropshadow(GUI.buttonPanelRight, '/BUTTON/observer/', '', 19)
    LayoutHelpers.AtLeftTopIn(GUI.becomeObserver, GUI.buttonPanelRight, -40+4, 25)
    Tooltip.AddButtonTooltip(GUI.becomeObserver, 'lob_become_observer')
    GUI.becomeObserver.OnClick = function()
        if IsPlayer(localPlayerID) then
            if lobbyComm:IsHost() then
                HostConvertPlayerToObserver(hostID, localPlayerName, FindSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToObserver', RequestedName = localPlayerName, RequestedSlot = FindSlotForID(localPlayerID)})
            end
        elseif IsObserver(localPlayerID) then
            if lobbyComm:IsHost() then
                HostConvertObserverToPlayerWithoutSlot(hostID, localPlayerName, FindObserverSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayerWithoutSlot', RequestedName = localPlayerName, ObserverSlot = FindObserverSlotForID(localPlayerID)})
            end
        end
    end

    -- AUTO TEAM BUTTON -- start of auto teams code.
    GUI.randTeam = UIUtil.CreateButtonWithDropshadow(GUI.buttonPanelRight, '/BUTTON/autoteam/')
    LayoutHelpers.AtLeftTopIn(GUI.randTeam, GUI.buttonPanelRight, 40+8, 25)
    Tooltip.AddButtonTooltip(GUI.randTeam, 'lob_click_randteam')
    if not lobbyComm:IsHost() then
        GUI.randTeam:Disable()
    else
        GUI.randTeam.OnClick = function(self, modifiers)
            if gameInfo.GameOptions['AutoTeams'] == 'none' then
                Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 2)
                SetGameOption('AutoTeams', 'tvsb')
                SendSystemMessage("Auto Teams option set: Top vs Bottom")
            elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
                Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 3)
                SetGameOption('AutoTeams', 'lvsr')
                SendSystemMessage("Auto Teams option set: Left vs Right")
            elseif gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
                Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 4)
                SetGameOption('AutoTeams', 'pvsi')
                SendSystemMessage("Auto Teams option set: Even Slots vs Odd Slots")
            elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
                Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 5)
                SetGameOption('AutoTeams', 'manual')
                SendSystemMessage("Auto Teams option set: Manual Select")
            else
                Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 1)
                SetGameOption('AutoTeams', 'none')
                SendSystemMessage("Auto Teams option set: None")
            end
        end
    end
    --end of auto teams code

    -- DEFAULT OPTION BUTTON -- start of ranked options code
    GUI.rankedOptions = UIUtil.CreateButtonWithDropshadow(GUI.buttonPanelRight, '/BUTTON/defaultoption/')
    LayoutHelpers.CenteredRightOf(GUI.rankedOptions, GUI.randTeam, 0)
    Tooltip.AddButtonTooltip(GUI.rankedOptions, 'lob_click_rankedoptions')
    if not lobbyComm:IsHost() then
        GUI.rankedOptions:Disable()
    else
        GUI.rankedOptions.OnClick = function()
            Prefs.SetToCurrentProfile('Lobby_Gen_Victory', 1)
            Prefs.SetToCurrentProfile('Lobby_Gen_Timeouts', 2)
            Prefs.SetToCurrentProfile('Lobby_Gen_CheatsEnabled', 1)
            Prefs.SetToCurrentProfile('Lobby_Gen_Civilians', 1)
            Prefs.SetToCurrentProfile('Lobby_Gen_GameSpeed', 1)
            Prefs.SetToCurrentProfile('Lobby_Gen_Fog', 1)
            Prefs.SetToCurrentProfile('Lobby_Gen_Cap', 8)
            Prefs.SetToCurrentProfile('Lobby_Prebuilt_Units', 1)
            Prefs.SetToCurrentProfile('Lobby_NoRushOption', 1)
            SetGameOption('Victory', 'demoralization', false, true)
            SetGameOption('Timeouts', '3', false, true)
            SetGameOption('CheatsEnabled', 'false', false, true)
            SetGameOption('CivilianAlliance', 'enemy', false, true)
            SetGameOption('GameSpeed', 'normal', false, true)
            SetGameOption('FogOfWar', 'explored', false, true)
            SetGameOption('UnitCap', '1000', false, true)
            SetGameOption('PrebuiltUnits', 'Off', false, true)
            SetGameOption('NoRushOption', 'Off', false, true)
            lobbyComm:BroadcastData( { Type = "SetAllPlayerNotReady" } )
            UpdateGame()
        end
    end

    -- CPU BENCH BUTTON --
    GUI.rerunBenchmark = UIUtil.CreateButtonWithDropshadow(GUI.observerPanel, '/BUTTON/cputest/', '', 0)
    GUI.rerunBenchmark:Disable()
    LayoutHelpers.CenteredRightOf(GUI.rerunBenchmark, GUI.rankedOptions, 0)
    Tooltip.AddButtonTooltip(GUI.rerunBenchmark,{text='Run CPU Benchmark Test', body='Recalculates your CPU rating.'})

    -- RANDOM MAP BUTTON -- start of random map code by Moritz
    GUI.randMap = UIUtil.CreateButtonWithDropshadow(GUI.buttonPanelRight, '/BUTTON/randommap/', '', 0)
    LayoutHelpers.CenteredRightOf(GUI.randMap, GUI.rerunBenchmark, 0)
    Tooltip.AddButtonTooltip(GUI.randMap, 'lob_click_randmap')
    if not lobbyComm:IsHost() then
        GUI.randMap:Disable()
    else
        GUI.randMap.OnClick = function()
            local randomMap
            local mapSelectDialog

            --In order for the RandMap button to work on lobby init, the PC needs a copy of the mapSelectDialog in memory.
            --Destroy the window after it's loaded, so the player never sees it when clicking the random map button.
            autoRandMap = false
            quickRandMap = false
            local function selectBehavior(selectedScenario, changedOptions, restrictedCategories)
                if autoRandMap then
                    Prefs.SetToCurrentProfile('LastScenario', selectedScenario.file)
                    gameInfo.GameOptions['ScenarioFile'] = selectedScenario.file
                else
                    Prefs.SetToCurrentProfile('LastScenario', selectedScenario.file)
                    mapSelectDialog:Destroy()
                    GUI.chatEdit:AcquireFocus()
                    for optionKey, data in changedOptions do
                        Prefs.SetToCurrentProfile(data.pref, data.index)
                        SetGameOption(optionKey, data.value)
                    end

                    SetGameOption('ScenarioFile',selectedScenario.file)

                    SetGameOption('RestrictedCategories', restrictedCategories, true)
                    ClearBadMapFlags()  -- every new map, clear the flags, and clients will report if a new map is bad
                    HostUpdateMods()
                    UpdateGame()
                end
            end

            local function exitBehavior()
                mapSelectDialog:Destroy()
                GUI.chatEdit:AcquireFocus()
                UpdateGame()
            end

            GUI.chatEdit:AbandonFocus()

            mapSelectDialog = import('/lua/ui/dialogs/mapselect.lua').CreateDialog(
                selectBehavior,
                exitBehavior,
                GUI,
                singlePlayer,
                gameInfo.GameOptions.ScenarioFile,
                gameInfo.GameOptions,
                availableMods,
                OnModsChanged
            )
            mapSelectDialog:Destroy()
            GUI.chatEdit:AcquireFocus()
            randomMap = import('/lua/ui/dialogs/mapselect.lua').randomLobbyMap()
        end
                    --
        function sendRandMapMessage()
            local rRankedLabel = import('/lua/ui/dialogs/mapselect.lua').rRankedLabel
            local rMapSize1 = import('/lua/ui/dialogs/mapselect.lua').rMapSize1
            local rMapSize2 = import('/lua/ui/dialogs/mapselect.lua').rMapSize2
            local rMapSizeFil = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFil
            local rMapSizeFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFilLim
            local rMapPlayersFil = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFil
            local rMapPlayersFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFilLim
            local rMapTypeFil = import('/lua/ui/dialogs/mapselect.lua').rMapTypeFil
            SendSystemMessage("-------------------------------------------------------------------------------"..
            "--------------------")
            SendSystemMessage(LOCF('%s %s', "<LOC lobui_0504>Randomly selected map: ", rRankedLabel))
            SendSystemMessage(LOCF("<LOC map_select_0000>Map Size: %dkm x %dkm", rMapSize1, rMapSize2))
            if rMapSizeFilLim == 'equal' then
                rMapSizeFilLim = '='
            elseif rMapSizeFilLim == 'less' then
                rMapSizeFilLim = '<='
            elseif rMapSizeFilLim == 'greater' then
                rMapSizeFilLim = '>='
            end
            if rMapPlayersFilLim == 'equal' then
                rMapPlayersFilLim = '='
            elseif rMapPlayersFilLim == 'less' then
                rMapPlayersFilLim = '<='
            elseif rMapPlayersFilLim == 'greater' then
                rMapPlayersFilLim = '>='
            end
            if rMapTypeFil == 1 then
                rMapTypeFil = "<LOC lobui_0576>Official"
            elseif rMapTypeFil == 2 then
                rMapTypeFil = "<LOC lobui_0577>Custom"
            end
            if rMapSizeFil ~= 0 and rMapPlayersFil ~= 0 then
                SendSystemMessage(LOCF("<LOC lobui_0516>Filters: Map Size is %s %dkm and Number of Players are %s %d",
                    rMapSizeFilLim, rMapSizeFil, rMapPlayersFilLim, rMapPlayersFil))
            elseif rMapSizeFil ~= 0 then
                SendSystemMessage(LOCF("<LOC lobui_0517>Filters: Map Size is %s %dkm and Number of Players are ALL",
                    rMapSizeFilLim, rMapSizeFil))
            elseif rMapPlayersFil ~= 0 then
                SendSystemMessage(LOCF("<LOC lobui_0518>Filters: Map Size is ALL and Number of Players are %s %d",
                    rMapPlayersFilLim, rMapPlayersFil))
            end
            if rMapTypeFil ~= 0 then
                SendSystemMessage(LOCF("<LOC lobui_0578>Map Type: %s", rMapTypeFil))
            end
            SendSystemMessage("---------------------------------------------------------------------------------------"..
                "------------")
            if not quickRandMap then
                quickRandMap = true
                UpdateGame()
            end
        end
    end --end of random map code

    -- TEXT for DefaultOpt, CPUBench, RandomMap, AutoTeam --
    GUI.ButtonsPanelText = UIUtil.CreateText(GUI.buttonPanelTop, '', 11, 'Arial', true)
    GUI.ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (GUI.ButtonsPanelText.Width() / 2)))
    LayoutHelpers.AtVerticalCenterIn(GUI.ButtonsPanelText, GUI.randTeam, 25)

    -- Manufacture a rollover event that sets the ButtonsPanelText's text to label and clears
    -- it on rollout.
    local function getButtonPanelRollover(label)
        return function(self, state)
            if state == 'enter' then
                GUI.ButtonsPanelText:SetText(label)
                GUI.ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (GUI.ButtonsPanelText.Width() / 2)))
            elseif state == 'exit' then
                GUI.ButtonsPanelText:SetText('')
            end
        end
    end

    -- TODO: Localise!
    -- Disabling for now, they weren't positioning properly - IceDreamer
    
    --[[
    GUI.randTeam.OnRolloverEvent = getButtonPanelRollover("Random Team")
    GUI.rankedOptions.OnRolloverEvent = getButtonPanelRollover("Set Ranked Options")
    GUI.rerunBenchmark.OnRolloverEvent = getButtonPanelRollover("Re-run CPU Benchmark")
    GUI.randMap.OnRolloverEvent = getButtonPanelRollover("Random Map")
    --]]

    --start of auto kick code
    if lobbyComm:IsHost() and not singlePlayer then
        GUI.autoKick = UIUtil.CreateCheckboxStd(GUI.buttonPanelTop, '/CHECKBOX/radio')
        LayoutHelpers.CenteredRightOf(GUI.autoKick, GUI.observerLabel, 10)
        Tooltip.AddControlTooltip(GUI.autoKick, 'lob_auto_kick')
        GUI.autoKickLabel = UIUtil.CreateText(GUI.autoKick, "Auto kick", 11, 'Arial', true)
        LayoutHelpers.CenteredRightOf(GUI.autoKickLabel, GUI.autoKick, 0)
        Tooltip.AddControlTooltip(GUI.autoKickLabel, 'lob_auto_kick')
        autoKick = true
        GUI.autoKick.OnCheck = function(self, checked)
            autoKick = checked
            UpdateGame()
        end
        GUI.autoKick:SetCheck(true)
    end

    GUI.observerList = ItemList(GUI.observerPanel, "observer list")
    GUI.observerList:SetFont(UIUtil.bodyFont, 12)
    GUI.observerList:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontOverColor, UIUtil.highlightColor, "ffbcfffe")
    GUI.observerList.Left:Set(function() return GUI.observerPanel.Left() + 6 end)
    GUI.observerList.Bottom:Set(function() return GUI.observerPanel.Bottom() - 4 end)
    GUI.observerList.Top:Set(function() return GUI.observerPanel.Top() + 4 end)
    GUI.observerList.Right:Set(function() return GUI.observerPanel.Right() - 6 end)
    GUI.observerList.OnClick = function(self, row, event)
        if lobbyComm:IsHost() and event.Modifiers.Right then
            UIUtil.QuickDialog(GUI, "<LOC lobui_0166>Are you sure?",
                                    "<LOC lobui_0167>Kick Player", function()
                                        lobbyComm:EjectPeer(gameInfo.Observers[row+1].OwnerID, "KickedByHost")
                                    end,
                                    "<LOC _Cancel>", nil,
                                    nil, nil,
                                    true,
                                    {worldCover = false, enterButton = 1, escapeButton = 2}
            )
        end
    end
    UIUtil.CreateLobbyVertScrollbar(GUI.observerList, -15, nil, -1)

    if singlePlayer then
        -- observers are always allowed in skirmish games.
        SetGameOption("AllowObservers",true)
        -- Hide all the multiplayer-only UI elements (we still create them because then we get to
        -- mostly forget that we're in single-player mode everywhere else (stuff silently becomes a
        -- nop, instead of needing to keep checking if UI controls actually exist...

        GUI.allowObservers:Hide()
        GUI.becomeObserver:Hide()
        GUI.observerLabel:Hide()
        GUI.randTeam:Hide()
        GUI.rankedOptions:Hide()
        GUI.rerunBenchmark:Hide()
        GUI.randMap:Hide()
        GUI.observerList:Hide()
        GUI.pingLabel:Hide()
        GUI.readyLabel:Hide()
    end

    -- Setup large pretty faction selector.
    CreateUI_Faction_Selector()
    SetCurrentFactionTo_Faction_Selector()

    ---------------------------------------------------------------------------
    -- other logic, including lobby callbacks
    ---------------------------------------------------------------------------
    GUI.posGroup = false
    -- get ping times
    GUI.pingThread = ForkThread(
    function()
        while lobbyComm do
            for slot, player in gameInfo.PlayerOptions do
                if player.Human and player.OwnerID ~= localPlayerID then
                    local peer = lobbyComm:GetPeer(player.OwnerID)
                    local ping = peer.ping and math.floor(peer.ping)
                    local connectionStatus = CalcConnectionStatus(peer)
                    if ping then
                        GUI.slots[slot].pingStatus:SetValue(ping)
                        UIUtil.setEnabled(GUI.slots[slot].pingStatus, ping >= 500 or connectionStatus ~= 3)

                        -- Set the ping bar to a colour representing the status of our connection.
                        GUI.slots[slot].pingStatus._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-0' .. connectionStatus .. '_bmp.dds'))
                    else
                        GUI.slots[slot].pingStatus:Hide()
                    end
                end
            end
            WaitSeconds(1)
        end
    end)

    -- CPU Benchmark code
    if not singlePlayer then
        CreateCPUMetricUI()
        ForkThread(function() StressCPU(10) end)
    end
    -- End CPU Benchmark code

    GUI.uiCreated = true

    if Need_Changelog() then
        GUI_Changelog()
    end
end

function RefreshOptionDisplayData(scenarioInfo)
    local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
    local teamOptions = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
    local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts
    if not scenarioInfo and gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    end
    formattedOptions = {}
    nonDefaultFormattedOptions = {}

    --// Check Mod active
    local modStr = false
    local modNum = table.getn(Mods.GetGameMods(gameInfo.GameMods)) or 0
    local modNumUI = table.getn(Mods.GetUiMods()) or 0
    if modNum > 0 and modNumUI > 0 then
        modStr = modNum..' Mods (and '..modNumUI..' UI Mods)'
        if modNum == 1 and modNumUI > 1 then
            modStr = modNum..' Mod (and '..modNumUI..' UI Mods)'
        elseif modNum > 1 and modNumUI == 1 then
            modStr = modNum..' Mods (and '..modNumUI..' UI Mod)'
        elseif modNum == 1 and modNumUI == 1 then
            modStr = modNum..' Mod (and '..modNumUI..' UI Mod)'
        else
            modStr = modNum..' Mods (and '..modNumUI..' UI Mods)'
        end
    elseif modNum > 0 and modNumUI == 0 then
        modStr = modNum..' Mods'
        if modNum == 1 then
            modStr = modNum..' Mod'
        end
    elseif modNum == 0 and modNumUI > 0 then
        modStr = modNumUI..' UI Mods'
        if modNum == 1 then
            modStr = modNumUI..' UI Mod'
        end
    end
    if modStr then
        local option = {
            text = modStr,
            value = LOC('<LOC lobby_0003>Check Mod Manager'),
            mod = true,
            tooltip = 'Lobby_Mod_Option',
            valueTooltip = 'Lobby_Mod_Option'
        }

        table.insert(formattedOptions, option)
        table.insert(nonDefaultFormattedOptions, option)
    end
    --\\ Stop Check Mod active

    -- Update the unit restrictions display.
    if gameInfo.GameOptions.RestrictedCategories ~= nil then
        local restrNum = table.getn(gameInfo.GameOptions.RestrictedCategories)
        if restrNum ~= 0 then
            -- TODO: Localise label.
            local restrictLabel
            if restrNum == 1 then -- just 1
                restrictLabel = "1 Build Restriction"
            else
                restrictLabel = restrNum.." Build Restrictions"
            end

            local option = {
                text = restrictLabel,
                value = "Check Unit Manager",
                mod = true,
                tooltip = 'Lobby_BuildRestrict_Option',
                valueTooltip = 'Lobby_BuildRestrict_Option'
            }

            table.insert(formattedOptions, option)
            table.insert(nonDefaultFormattedOptions, option)
        end
    end

    -- Add an option to the formattedOption lists
    local function addFormattedOption(optData, gameOption)
        -- Don't show multiplayer-only options in single-player
        if optData.mponly and singlePlayer then
            return
        end

        -- Verify that the map contains sane defaults.
        if not Warning_MAP and (optData.default == 0 or optData.default > table.getsize(optData.values)) then
            Warning_MAP = true
            AddChatText('The options included in this map are not compliant.')
            AddChatText('Please contact the author of the map.')
        end

        local option = {
            text = optData.label,
            tooltip = { text = optData.label, body = optData.help }
        }

        -- Options are stored as keys from values array in optData. We want to display the
        -- descriptive string in the UI, so let's go dig it out.

        -- If the is value is unset, it is definitely its default so we directly lookup what we want.
        if not gameOption then
            local val = optData.values[optData.default]

            option.value = val.text
            option.valueTooltip = {text = optData.label, body = val.help }

            table.insert(formattedOptions, option)
        else
            -- Scan the values array to find the one with the key matching our value for that option.
            for k, val in optData.values do
                if val.key == gameOption then
                    option.value = val.text
                    option.valueTooltip = {text = optData.label, body = val.help }

                    table.insert(formattedOptions, option)

                    -- Add this option to the non-default set for the UI.
                    if k ~= optData.default then
                        table.insert(nonDefaultFormattedOptions, option)
                    end

                    break
                end
            end
        end
    end

    -- Add options from globalOpts to the formattedOption lists.
    for index, optData in globalOpts do
        local gameOption = gameInfo.GameOptions[optData.key]
        addFormattedOption(optData, gameOption)
    end

    -- Add options from the scenario object, if any are provided.
    if scenarioInfo.options then
        for index, optData in scenarioInfo.options do
            addFormattedOption(optData, gameInfo.GameOptions[optData.key])
        end
    end

    GUI.OptionContainer:CalcVisible()
end

function wasConnected(peer)
    for _,v in pairs(connectedTo) do
        if v == peer then
            return true
        end
    end
    return false
end

-- Return a status code representing the status of our connection to a peer.
-- 1: no connection
-- 2: half-duplex established or peer reports no connection to a peer we are connected to.
-- 3: full-duplex connection established
function CalcConnectionStatus(peer)
    if peer.status ~= 'Established' then
        return 1
    else
        if not wasConnected(peer.id) then
            GUI.slots[FindSlotForID(peer.id)].name:SetTitleText(peer.name)
            GUI.slots[FindSlotForID(peer.id)].name._text:SetFont('Arial Gras', 15)
            if SystemMessagesEnabled() then
                if not table.find(ConnectionEstablished, peer.name) then
                    if gameInfo.PlayerOptions[FindSlotForID(peer.id)].Human and not IsLocallyOwned(FindSlotForID(peer.id)) then
                        if table.find(ConnectedWithProxy, peer.id) then
                            AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", peer.name)..' (FAF Proxy)', "Engine0004")
                        else
                            AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", peer.name), "Engine0004")
                        end
                        table.insert(ConnectionEstablished, peer.name)
                        for k, v in CurrentConnection do -- Remove PlayerName in this Table
                            if v == peer.name then
                                CurrentConnection[k] = nil
                                break
                            end
                        end
                    end
                end
            end

            table.insert(connectedTo, peer.id)
            GpgNetSend('Connected', string.format("%d", peer.id))
        end
        if not table.find(peer.establishedPeers, lobbyComm:GetLocalPlayerID()) then
            -- they haven't reported that they can talk to us?
            return 2
        end

        local peers = lobbyComm:GetPeers()
        for k,v in peers do
            if v.id ~= peer.id and v.status == 'Established' then
                if not table.find(peer.establishedPeers, v.id) then
                    -- they can't talk to someone we can talk to.
                    return 2
                end
            end
        end
        return 3
    end
end

function EveryoneHasEstablishedConnections()
    local important = {}
    for slot,player in gameInfo.PlayerOptions do
        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end
    for slot,observer in gameInfo.Observers do
        if not table.find(important, observer.OwnerID) then
            table.insert(important, observer.OwnerID)
        end
    end
    local result = true
    for k,id in important do
        if id ~= localPlayerID then
        local peer = lobbyComm:GetPeer(id)
        for k2,other in important do
            if id ~= other and not table.find(peer.establishedPeers, other) then
                result = false
                AddChatText(LOCF("<LOC lobui_0299>%s doesn't have an established connection to %s",
                                 peer.name,
                                 lobbyComm:GetPeer(other).name
                ))
            end
        end
    end
end
return result
end


function AddChatText(text)
    if not GUI.chatDisplay then
        LOG("Can't add chat text -- no chat display")
        LOG("text=" .. repr(text))
        return
    end
    local textBoxWidth = GUI.chatDisplay.Width()
    local wrapped = import('/lua/maui/text.lua').WrapText(text, textBoxWidth,
    function(curText) return GUI.chatDisplay:GetStringAdvance(curText) end)
    for i, line in wrapped do
        GUI.chatDisplay:AddItem(line)
    end
    GUI.chatDisplay:ScrollToBottom()
end

function ShowMapPositions(mapCtrl, scenario, numPlayers)
    if nil == scenario.starts then
        scenario.starts = true
    end

    if GUI.posGroup then
        GUI.posGroup:Destroy()
        GUI.posGroup = false
    end

    if GUI.markers and table.getn(GUI.markers) > 0 then
        for i, v in GUI.markers do
            v.marker:Destroy()
        end
    end
    GUI.markers = {}
    if not scenario.starts then
        return
    end

    if not scenario.size then
        LOG("Lobby: Can't show map positions as size field isn't in scenario yet (must be resaved with new editor!)")
        return
    end

    GUI.posGroup = Group(mapCtrl)
    LayoutHelpers.FillParent(GUI.posGroup, mapCtrl)

    local startPos = MapUtil.GetStartPositions(scenario)

    local cHeight = GUI.posGroup:Height()
    local cWidth = GUI.posGroup:Width()

    local mWidth = scenario.size[1]
    local mHeight = scenario.size[2]

    local playerArmyArray = MapUtil.GetArmies(scenario)

    for inSlot, army in playerArmyArray do
        local pos = startPos[army]
        local slot = inSlot
        GUI.markers[slot] = {}
        GUI.markers[slot].marker = Bitmap(GUI.posGroup)
        GUI.markers[slot].marker.Height:Set(10)
        GUI.markers[slot].marker.Width:Set(8)
        GUI.markers[slot].marker.Depth:Set(function() return GUI.posGroup.Depth() + 10 end)
        GUI.markers[slot].marker:SetSolidColor('00777777')

        GUI.markers[slot].teamIndicator = Bitmap(GUI.markers[slot].marker)
        LayoutHelpers.AnchorToRight(GUI.markers[slot].teamIndicator, GUI.markers[slot].marker, 1)
        LayoutHelpers.AtTopIn(GUI.markers[slot].teamIndicator, GUI.markers[slot].marker, 5)
        GUI.markers[slot].teamIndicator:DisableHitTest()

        if gameInfo.GameOptions['AutoTeams'] and not gameInfo.AutoTeams[slot] and lobbyComm:IsHost() then
            gameInfo.AutoTeams[slot] = 2
        end

        local buttonImage = UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds')
        GUI.markers[slot].markerOverlay = Button(GUI.markers[slot].marker,
                                                 buttonImage, buttonImage, buttonImage, buttonImage)
        LayoutHelpers.AtCenterIn(GUI.markers[slot].markerOverlay, GUI.markers[slot].marker)
        GUI.markers[slot].markerOverlay.Slot = slot
        GUI.markers[slot].markerOverlay.OnClick = function(self, modifiers)
            if modifiers.Left then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' then
                    if FindSlotForID(localPlayerID) ~= self.Slot and gameInfo.PlayerOptions[self.Slot] == nil then
                        if IsPlayer(localPlayerID) then
                            if lobbyComm:IsHost() then
                                HostTryMovePlayer(hostID, FindSlotForID(localPlayerID), self.Slot)
                            else
                                lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID), RequestedSlot =  self.Slot})
                            end
                        elseif IsObserver(localPlayerID) then
                            if lobbyComm:IsHost() then
                                requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
                                requestedPL = playerRating
                                requestedRC = ratingColor
                                requestedNG = numGames
                                HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID),
                                                            self.Slot, requestedFaction, requestedPL, requestedRC, requestedNG)
                            else
                                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName,
                                                                      ObserverSlot = FindObserverSlotForID(localPlayerID), PlayerSlot =
                                                                      self.Slot, requestedFaction =
                                                                      Prefs.GetFromCurrentProfile('LastFaction'),
                                                                      requestedPL = playerRating, requestedRC = ratingColor,
                                                                      requestedNG = numGames})
                            end
                        end
                    end
                else
                    if gameInfo.GameOptions['AutoTeams'] and lobbyComm:IsHost() then
                        if gameInfo.GameOptions['AutoTeams'] == 'manual' then
                            if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
                                local targetTeam
                                if gameInfo.AutoTeams[slot] == 7 then
                                    targetTeam = 2
                                else
                                    targetTeam = gameInfo.AutoTeams[slot] + 1
                                end

                                GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[targetTeam]))
                                gameInfo.AutoTeams[slot] = targetTeam

                                lobbyComm:BroadcastData(
                                    {
                                        Type = 'AutoTeams',
                                        Slots = slot,
                                        Team = gameInfo.AutoTeams[slot],
                                    }
                                )
                                UpdateGame()
                            end
                        end
                    end
                end
            elseif modifiers.Right then
                if lobbyComm:IsHost() then
                    if gameInfo.ClosedSlots[self.Slot] == nil then
                        HostCloseSlot(hostID, self.Slot)
                    else
                        HostOpenSlot(hostID, self.Slot)
                    end
                end
            end
        end
        GUI.markers[slot].markerOverlay.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' then
                    GUI.slots[self.Slot].name.HandleEvent(self, event)
                elseif gameInfo.GameOptions['AutoTeams'] == 'manual' and lobbyComm:IsHost() then
                    GUI.markers[slot].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                GUI.slots[self.Slot].name.HandleEvent(self, event)
                if gameInfo.GameOptions['AutoTeams'] == 'manual' and lobbyComm:IsHost() then
                    GUI.markers[slot].Indicator:Stop()
                end
            end
            Button.HandleEvent(self, event)
        end
        LayoutHelpers.AtLeftTopIn(GUI.markers[slot].marker, GUI.posGroup,
            ((pos[1] / mWidth) * cWidth) - (GUI.markers[slot].marker.Width() / 2),
            ((pos[2] / mHeight) * cHeight) - (GUI.markers[slot].marker.Height() / 2))

        local index = slot
        GUI.markers[slot].Indicator = Bitmap(GUI.markers[slot].marker, UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
        LayoutHelpers.AtCenterIn(GUI.markers[slot].Indicator, GUI.markers[slot].marker)
        GUI.markers[slot].Indicator.Height:Set(function() return GUI.markers[index].Indicator.BitmapHeight() * .3 end)
        GUI.markers[slot].Indicator.Width:Set(function() return GUI.markers[index].Indicator.BitmapWidth() * .3 end)
        GUI.markers[slot].Indicator.Depth:Set(function() return GUI.markers[index].marker.Depth() - 1 end)
        GUI.markers[slot].Indicator:Hide()
        GUI.markers[slot].Indicator:DisableHitTest()
        GUI.markers[slot].Indicator.Play = function(self)
            self:SetAlpha(1)
            self:Show()
            self:SetNeedsFrameUpdate(true)
            self.time = 0
            self.OnFrame = function(control, time)
                control.time = control.time + (time*4)
                control:SetAlpha(MATH_Lerp(math.sin(control.time), -.5, .5, 0.3, 0.5))
            end
        end
        GUI.markers[slot].Indicator.Stop = function(self)
            self:SetAlpha(0)
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end

        if gameInfo.GameOptions['TeamSpawn'] == 'random' then
            GUI.markers[slot].marker:SetSolidColor("00777777")
        else
            if gameInfo.PlayerOptions[slot] then
                GUI.markers[slot].marker:SetSolidColor(gameColors.PlayerColors[gameInfo.PlayerOptions[slot].PlayerColor])
                if gameInfo.PlayerOptions[slot].Team == 1 then
                    GUI.markers[slot].teamIndicator:SetSolidColor('00000000')
                else
                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.PlayerOptions[slot].Team]))
                end
            else
                GUI.markers[slot].marker:SetSolidColor("00777777")
                GUI.markers[slot].teamIndicator:SetSolidColor('00000000')
            end
        end

        if gameInfo.GameOptions['AutoTeams'] then
            if gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
                local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or
                    gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    local markerPos = GUI.markers[slot].marker.Left()
                    if markerPos < midLine then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                    else
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
                local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    local markerPos = GUI.markers[slot].marker.Top()
                    if markerPos < midLine then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                    else
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    if math.floor(slot, 2) ~= 0 then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                    else
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'manual' and gameInfo.GameOptions['TeamSpawn'] == 'random' then
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    if gameInfo.AutoTeams[slot] then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.AutoTeams[slot]]))
                    else
                        GUI.markers[slot].teamIndicator:SetSolidColor('00000000')
                    end
                end
            end
        end

        if gameInfo.ClosedSlots[slot] ~= nil then
            local textOverlay = Text(GUI.markers[slot].markerOverlay)
            textOverlay:SetFont(UIUtil.bodyFont, 14)
            textOverlay:SetColor("Crimson")
            textOverlay:SetText("X")
            LayoutHelpers.AtCenterIn(textOverlay, GUI.markers[slot].markerOverlay)
        end
    end
end -- ShowMapPositions

-- LobbyComm Callbacks
function InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    lobbyComm = LobbyComm.CreateLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    if not lobbyComm then
        error('Failed to create lobby using port ' .. tostring(localPort))
    end

    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED " .. reason)
        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI.panel, LOCF(Strings.ConnectionFailed, Strings[reason] or reason),
                                                           "<LOC _OK>", ReturnToMenu)

        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        AddChatText(LOC(Strings[reasonKey] or reasonKey))
    end

    lobbyComm.Ejected = function(self,reason)
        LOG("EJECTED " .. reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI, LOCF(Strings.Ejected, Strings[reason] or reason), "<LOC _OK>", ReturnToMenu)
        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.ConnectionToHostEstablished = function(self,myID,myName,theHostID)
        LOG("CONNECTED TO HOST")
        hostID = theHostID
        localPlayerID = myID
        localPlayerName = myName

        GpgNetSend('connectedToHost', string.format("%d", hostID))
        lobbyComm:SendData(hostID, { Type = 'SetAvailableMods', Mods = GetLocallyAvailableMods(), Name = localPlayerName} )

        if wantToBeObserver then
            -- Ok, I'm connected to the host. Now request to become an observer
            lobbyComm:SendData( hostID, { Type = 'AddObserver', RequestedObserverName = localPlayerName, RequestedPL = playerRating, RequestedColor = Prefs.GetFromCurrentProfile('LastColor'), RequestedFaction = requestedFaction, RequestedCOUNTRY = PrefLanguage, } )
			LOGX('>> ConnectionToHostEstablished//SendData//playerRating='..tostring(playerRating), 'Connecting')
        else
            -- Ok, I'm connected to the host. Now request to become a player
            local requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
            if (requestedFaction == nil) or (requestedFaction > table.getn(FactionData.Factions)) then
                requestedFaction = table.getn(FactionData.Factions) + 1
            end

            if hasSupcom == false then
                requestedFaction = 4
            end

            lobbyComm:SendData( hostID,
                {
                    Type = 'AddPlayer',
                    RequestedSlot = -1,
                    RequestedPlayerName = localPlayerName,
                    Human = true,
                    RequestedColor = Prefs.GetFromCurrentProfile('LastColor'),
                    RequestedFaction = requestedFaction,
                    RequestedPL = playerRating,
                    RequestedRC = ratingColor,
                    RequestedNG = numGames,
                    RequestedMEAN = playerMean,
                    RequestedDEV = playerDeviation,
                    RequestedCOUNTRY = PrefLanguage
                }
            )
        end

        local function KeepAliveThreadFunc()
            local threshold = LobbyComm.quietTimeout
            local active = true
            local prev = 0
            while lobbyComm do
                local host = lobbyComm:GetPeer(hostID)
                if active and host.quiet > threshold then
                    active = false
                    local function OnRetry()
                        host = lobbyComm:GetPeer(hostID)
                        threshold = host.quiet + LobbyComm.quietTimeout
                        active = true
                    end
                    UIUtil.QuickDialog(GUI, "<LOC lobui_0266>Connection to host timed out.",
                                            "<LOC lobui_0267>Keep Trying", OnRetry,
                                            "<LOC lobui_0268>Give Up", ReturnToMenu,
                                            nil, nil,
                                            true,
                                            {worldCover = false, escapeButton = 2})
                elseif host.quiet < prev then
                    threshold = LobbyComm.quietTimeout
                end
                prev = host.quiet
                WaitSeconds(1)
            end
        end -- KeepAliveThreadFunc

        GUI.keepAliveThread = ForkThread(KeepAliveThreadFunc)
        CreateUI(LobbyComm.maxPlayerSlots)
    end

    lobbyComm.DataReceived = function(self,data)
        -- Messages anyone can receive
        if data.Type == 'PlayerOption' then
            if gameInfo.PlayerOptions[data.Slot].OwnerID ~= data.SenderID then
                WARN("Attempt to set option on unowned slot.")
                return
            end
            gameInfo.PlayerOptions[data.Slot][data.Key] = data.Value
            UpdateGame()
        elseif data.Type == 'PublicChat' then
            AddChatText("["..data.SenderName.."] "..data.Text)
        elseif data.Type == 'PrivateChat' then
            AddChatText("<<"..data.SenderName..">> "..data.Text)
            --// RULE TITLE
        elseif data.Type == 'Rule_Title_MSG' then
			LOGX('>> RECEIVE MSG Rule_Title_MSG : result='..data.Result1..' result2='..data.Result2, 'RuleTitle')
            RuleTitle_SetText(data.Result1 or "", data.Result2 or "")
            --\\ Stop RULE TITLE
            -- CPU benchmark code
        elseif data.Type == 'CPUBenchmark' then
            --LOG("CPU Data: "..(data.PlayerName or "?")..", ".. (data.Result or "?"))
            CPU_Benchmarks[data.PlayerName] = data.Result
            local playerId = FindIDForName(data.PlayerName)
            local playerSlot = FindSlotForID(playerId)
            if playerSlot ~= nil then
                SetSlotCPUBar(playerSlot, gameInfo.PlayerOptions[playerSlot])
            end
            -- End CPU benchmark code
        elseif data.Type == 'SetPlayerNotReady' then
            EnableSlot(data.Slot)
            GUI.becomeObserver:Enable()

            SetPlayerOption(data.Slot, 'Ready', false)
        end

        if lobbyComm:IsHost() then
            -- Host only messages
            if data.Type == 'GetGameInfo' then
                lobbyComm:SendData( data.SenderID, {Type = 'GameInfo', GameInfo = gameInfo} )
            elseif data.Type == 'AddPlayer' then
                -- create empty slot if possible and give it to the player
                HostTryAddPlayer(data.SenderID, data.RequestedSlot, data.RequestedPlayerName, data.Human, data.AIPersonality,
                                 data.RequestedColor, data.RequestedFaction, nil, data.RequestedPL, data.RequestedRC,
                                 data.RequestedNG, data.RequestedMEAN, data.RequestDEV, data.RequestedCOUNTRY)
                PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04716'}, true)
            elseif data.Type == 'MovePlayer' then
                -- attempt to move a player from current slot to empty slot
                HostTryMovePlayer(data.SenderID, data.CurrentSlot, data.RequestedSlot)
            elseif data.Type == 'AddObserver' then
                -- create empty slot if possible and give it to the observer
                if gameInfo.GameOptions.AllowObservers then
                    HostTryAddObserver( data.SenderID, data.RequestedObserverName, data.RequestedPL, data.RequestedColor, data.RequestedFaction, data.RequestedCOUNTRY )
                else
                    lobbyComm:EjectPeer(data.SenderID, 'NoObservers');
                end
            elseif data.Type == 'RequestConvertToObserver' then
                HostConvertPlayerToObserver(data.SenderID, data.RequestedName, data.RequestedSlot)
            elseif data.Type == 'RequestConvertToPlayer' then
                HostConvertObserverToPlayer(data.SenderID, data.RequestedName, data.ObserverSlot, data.PlayerSlot,
                                            data.requestedFaction, data.requestedPL, data.requestedRC, data.requestedNG)
            elseif data.Type == 'RequestConvertToPlayerWithoutSlot' then
                HostConvertObserverToPlayerWithoutSlot(data.SenderID, data.RequestedName, data.ObserverSlot,
                                                    data.requestedFaction, data.requestedPL, data.requestedRC, data.requestedNG)
            elseif data.Type == 'RequestColor' then
                data.Color = Get_IndexColor_by_CompleteTable(data.Color)
                if IsColorFree(data.Color) then
                    -- Color is available, let everyone else know
                    gameInfo.PlayerOptions[data.Slot].PlayerColor = data.Color
                    lobbyComm:BroadcastData( { Type = 'SetColor', Color = data.Color, Slot = data.Slot } )
                    UpdateGame()
                else
                -- Sorry, it's not free. Force the player back to the color we have for him.
                    lobbyComm:SendData( data.SenderID, { Type = 'SetColor', Color =
                    gameInfo.PlayerOptions[data.Slot].PlayerColor, Slot = data.Slot } )
                end
            elseif data.Type == 'ClearSlot' then
                if gameInfo.PlayerOptions[data.Slot].OwnerID == data.SenderID then
                    HostRemoveAI(data.Slot)
                else
                    WARN("Attempt to clear unowned slot")
                end
            elseif data.Type == 'SetAvailableMods' then
                availableMods[data.SenderID] = data.Mods
                HostUpdateMods(data.SenderID, data.Name)
            elseif data.Type == 'MissingMap' then
                HostPlayerMissingMapAlert(data.Id)
            end
        else -- Non-host only messages
            if data.Type == 'SystemMessage' then
                DisplaySystemMessage(data)
            elseif data.Type == 'SetAllPlayerNotReady' then
                EnableSlot(FindSlotForID(FindIDForName(localPlayerName)))
                GUI.becomeObserver:Enable()
                SetPlayerOption(FindSlotForID(FindIDForName(localPlayerName)), 'Ready', false)
            elseif data.Type == 'Peer_Really_Disconnected' then
				LOGX('>> DATA RECEIVE : Peer_Really_Disconnected (slot:'..data.Slot..')', 'Disconnected')
                if data.Options.OwnerID == localPlayerID then
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    if data.Observ == false then
                        gameInfo.PlayerOptions[data.Slot] = nil
                    elseif data.Observ == true then
                        gameInfo.Observers[data.Slot] = nil
                    end
                end
                AddChatText(LOCF("<LOC Engine0003>Lost connection to %s.", data.Options.PlayerName), "Engine0003")
                ClearSlotInfo(data.Slot)
                UpdateGame()
            elseif data.Type == 'SlotAssigned' then
                if data.Options.OwnerID == localPlayerID and data.Options.Human then
                    -- The new slot is for us. Request the full game info from the host
                    localPlayerName = data.Options.PlayerName -- validated by server
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    -- The new slot was someone else, just add that info.
                    gameInfo.PlayerOptions[data.Slot] = data.Options
                    PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04716'}, true)
                end
                UpdateGame()
            elseif data.Type == 'SlotMove' then
                if data.Options.OwnerID == localPlayerID and data.Options.Human then
                    localPlayerName = data.Options.PlayerName -- validated by server
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    gameInfo.PlayerOptions[data.OldSlot] = nil
                    gameInfo.PlayerOptions[data.NewSlot] = data.Options
                end
                ClearSlotInfo(data.OldSlot)
                UpdateGame()
            elseif data.Type == 'ObserverAdded' then
                if data.Options.OwnerID == localPlayerID then
                    -- The new slot is for us. Request the full game info from the host
                    localPlayerName = data.Options.PlayerName -- validated by server
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    -- The new slot was someone else, just add that info.
                    gameInfo.Observers[data.Slot] = data.Options
                end
                refreshObserverList()
            elseif data.Type == 'ConvertObserverToPlayer' then
                if data.Options.OwnerID == localPlayerID then
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    gameInfo.Observers[data.OldSlot] = nil
                    gameInfo.PlayerOptions[data.NewSlot] = data.Options
                end
                UpdateGame()
            elseif data.Type == 'ConvertPlayerToObserver' then
                if data.Options.OwnerID == localPlayerID then
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    gameInfo.Observers[data.NewSlot] = data.Options
                    gameInfo.PlayerOptions[data.OldSlot] = nil
                end
                ClearSlotInfo(data.OldSlot)
                UpdateGame()
            elseif data.Type == 'SetColor' then
                data.Color = Get_IndexColor_by_CompleteTable(data.Color)
                gameInfo.PlayerOptions[data.Slot].PlayerColor = data.Color
                gameInfo.PlayerOptions[data.Slot].ArmyColor = data.Color
                UpdateGame()
            elseif data.Type == 'GameInfo' then
                -- Note: this nukes whatever options I may have set locally
                gameInfo = data.GameInfo
                UpdateGame()
            elseif data.Type == 'GameOption' then
                gameInfo.GameOptions[data.Key] = data.Value
                UpdateGame()
            elseif data.Type == 'Launch' then
                local info = data.GameInfo
                info.GameMods = Mods.GetGameMods(info.GameMods)
                SetWindowedLobby(false)
                lobbyComm:LaunchGame(info)
            elseif data.Type == 'ClearSlot' then
                ClearSlotInfo(data.Slot)
                gameInfo.PlayerOptions[data.Slot] = nil
                UpdateGame()
            elseif data.Type == 'ClearObserver' then
                gameInfo.Observers[data.Slot] = nil
                UpdateGame()
            elseif data.Type == 'ModsChanged' then
                gameInfo.GameMods = data.GameMods
                UpdateGame()
                import('/lua/ui/lobby/ModsManager.lua').UpdateClientModStatus(gameInfo.GameMods)
            elseif data.Type == 'SlotClose' then
                gameInfo.ClosedSlots[data.Slot] = true
                UpdateGame()
            elseif data.Type == 'SlotOpen' then
                gameInfo.ClosedSlots[data.Slot] = nil
                UpdateGame()
            elseif data.Type == 'AutoTeams' then
                gameInfo.AutoTeams[data.Slot] = data.Team
                UpdateGame()
            end
        end
    end

    lobbyComm.SystemMessage = function(self, text)
        AddChatText(text)
    end

    lobbyComm.GameLaunched = function(self)
        local player = lobbyComm:GetLocalPlayerID()
        for i, v in gameInfo.PlayerOptions do
            if v.Human and v.OwnerID == player then
                Prefs.SetToCurrentProfile('LoadingFaction', v.Faction)
                break
            end
        end
        GpgNetSend('GameState', 'Launching')
        if GUI.pingThread then
            KillThread(GUI.pingThread)
        end
        if GUI.keepAliveThread then
            KillThread(GUI.keepAliveThread)
        end
        GUI:Destroy()
        GUI = false
        MenuCommon.MenuCleanup()
        lobbyComm:Destroy()
        lobbyComm = false

        -- determine if cheat keys should be mapped
        if not DebugFacilitiesEnabled() then
            IN_ClearKeyMap()
            IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyMappings(gameInfo.GameOptions['CheatsEnabled']=='true'))
        end
    end

    lobbyComm.Hosting = function(self)
        localPlayerID = lobbyComm:GetLocalPlayerID()
        hostID = localPlayerID
        selectedMods = table.map(function (m) return m.uid end, Mods.GetGameMods())
        HostUpdateMods()

        -- Give myself the first slot
        gameInfo.PlayerOptions[1] = LobbyComm.GetDefaultPlayerOptions(localPlayerName)
        gameInfo.PlayerOptions[1].OwnerID = localPlayerID
        gameInfo.PlayerOptions[1].Human = true
        gameInfo.PlayerOptions[1].PlayerColor = Prefs.GetFromCurrentProfile('LastColor') or 1
        gameInfo.PlayerOptions[1].ArmyColor = Prefs.GetFromCurrentProfile('LastColor') or 1
        gameInfo.PlayerOptions[1].Country = PrefLanguage or 'world'

        local requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
        if (requestedFaction == nil) or (requestedFaction > table.getn(FactionData.Factions)) then
            requestedFaction = table.getn(FactionData.Factions) + 1
        end
        if hasSupcom then
            gameInfo.PlayerOptions[1].Faction = requestedFaction
        else
            gameInfo.PlayerOptions[1].Faction = 4
        end

        -- set default lobby values
        for index, option in globalOpts do
            local defValue = Prefs.GetFromCurrentProfile(option.pref) or option.default
            SetGameOption(option.key,option.values[defValue].key, false, true)
        end

        for index, option in teamOpts do
            local defValue = Prefs.GetFromCurrentProfile(option.pref) or option.default
            SetGameOption(option.key,option.values[defValue].key, false, true)
        end

        for index, option in AIOpts do
            local defValue = Prefs.GetFromCurrentProfile(option.pref) or option.default
            SetGameOption(option.key,option.values[defValue].key, false, true)
        end

        if self.desiredScenario and self.desiredScenario ~= "" then
            Prefs.SetToCurrentProfile('LastScenario', self.desiredScenario)
            SetGameOption('ScenarioFile',self.desiredScenario, false, true)
        else
            local scen = Prefs.GetFromCurrentProfile('LastScenario')
            if scen and scen ~= "" then
                SetGameOption('ScenarioFile',scen, false, true)
            end
        end

        UpdateGame()

        GUI.keepAliveThread = ForkThread(
        -- Eject players who haven't sent a heartbeat in a while
        function()
            while true and lobbyComm do
                local peers = lobbyComm:GetPeers()
                for k,peer in peers do
                    if peer.quiet > LobbyComm.quietTimeout then
                        lobbyComm:EjectPeer(peer.id,'TimedOutToHost')
                        SendSystemMessage(LOCF("<LOC lobui_0226>%s timed out.", peer.name), "lobui_0205")
                        --SendSystemMessage(LOCF(Strings.TimedOut,peer.name), "lobui_0205")
                        --AddChatText('TIMEOUT !')
                        
                        -- Search and Remove the peer disconnected
                        for k, v in CurrentConnection do
                            if v == peer.name then
                                CurrentConnection[k] = nil
                                break
                            end
                        end
                        for k, v in ConnectionEstablished do
                            if v == peer.name then
                                ConnectionEstablished[k] = nil
                                break
                            end
                        end
                        for k, v in ConnectedWithProxy do
                            if v == peer.id then
                                ConnectedWithProxy[k] = nil
                                break
                            end
                        end
                    end
                end
                WaitSeconds(1)
            end
        end
        )

        CreateUI(LobbyComm.maxPlayerSlots)
        UpdateGame()

        --if not singlePlayer and not GpgNetActive() then
        --AddChatText('Hosting on port :'..lobbyComm:GetLocalPort())
        --AddChatText('protocol : '..protocol)
        --AddChatText('localPort : '..localPort)
        --AddChatText('desiredPlayerName : '..desiredPlayerName)
        --AddChatText('localPlayerUID : '..localPlayerUID)
        --AddChatText('NatTraversalProvider : '..natTraversalProvider) -- Bug here
        --end
    end

    lobbyComm.PeerDisconnected = function(self,peerName,peerID) -- Lost connection or try connect with proxy
		LOGX('>> PeerDisconnected : peerName='..peerName..' peerID='..peerID, 'Disconnected')
        
         -- Search and Remove the peer disconnected
        for k, v in CurrentConnection do
            if v == peerName then
                CurrentConnection[k] = nil
                break
            end
        end
        for k, v in ConnectionEstablished do
            if v == peerName then
                ConnectionEstablished[k] = nil
                break
            end
        end
        for k, v in ConnectedWithProxy do
            if v == peerID then
                ConnectedWithProxy[k] = nil
                break
            end
        end
        
        if IsPlayer(peerID) then
            local slot = FindSlotForID(peerID)
            if slot and lobbyComm:IsHost() then
                PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04717'}, true)
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.PlayerOptions[slot],
                    Slot = slot,
                    Observ = false,
                }
                )
                ClearSlotInfo(slot)
                gameInfo.PlayerOptions[slot] = nil
                UpdateGame()
            end
        elseif IsObserver(peerID) then
            local slot2 = FindObserverSlotForID(peerID)
            if slot2 and lobbyComm:IsHost() then
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.PlayerOptions[slot2], -- Possible BUG, gameInfo.Observers[slot2] ???
                    Slot = slot2,
                    Observ = true,
                }
                )
                gameInfo.Observers[slot2] = nil
                UpdateGame()
            end
        end

        availableMods[peerID] = nil
        HostUpdateMods()
    end

    lobbyComm.GameConfigRequested = function(self)
        return {
            Options = gameInfo.GameOptions,
            HostedBy = localPlayerName,
            PlayerCount = GetPlayerCount(),
            GameName = gameName,
            ProductCode = import('/lua/productcode.lua').productCode,
        }
    end
end

function SetPlayerOption(slot, key, val, ignoreRefresh)
    ignoreRefresh = ignoreRefresh or false

    if not IsLocallyOwned(slot) then
        WARN("Hey you can't set a player option on a slot you don't own. (slot:"..tostring(slot).." / key:"..tostring(key).." / val:"..tostring(val)..")")
        return
    end

    if not hasSupcom then
        if key == 'Faction' then
            val = 4
        end
    end

    gameInfo.PlayerOptions[slot][key] = val

    lobbyComm:BroadcastData(
    {
        Type = 'PlayerOption',
        Key = key,
        Value = val,
        Slot = slot,
    }
    )
    if not ignoreRefresh then
        UpdateGame()
    end
end

function SetGameOption(key, val, ignoreNilValue, ignoreRefresh)
    local scenarioInfo = nil
    ignoreNilValue = ignoreNilValue or false
    ignoreRefresh = ignoreRefresh or false

    if (not ignoreNilValue) and ((key == nil) or (val == nil)) then
        WARN('Attempt to set nil lobby game option: ' .. tostring(key) .. ' ' .. tostring(val))
        return
    end

    if lobbyComm:IsHost() then
        gameInfo.GameOptions[key] = val

        lobbyComm:BroadcastData {
            Type = 'GameOption',
            Key = key,
            Value = val,
        }

        LOG('SetGameOption(key='..repr(key)..',val='..repr(val)..')')

        -- don't want to send all restricted categories to gpgnet, so just send bool
        -- note if more things need to be translated to gpgnet, a translation table would be a better implementation
        -- but since there's only one, we'll call it out here
        if key == 'RestrictedCategories' then
            local restrictionsEnabled = false
            if val ~= nil then
                if table.getn(val) ~= 0 then
                    restrictionsEnabled = true
                end
            end
            GpgNetSend('GameOption', key, restrictionsEnabled)
        elseif key == 'ScenarioFile' then
            GpgNetSend('GameOption', key, val)
            if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= '') then
                scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') then
                    GpgNetSend('GameOption', 'Slots', table.getsize(scenarioInfo.Configurations.standard.teams[1].armies))
                end
            end
        else
            GpgNetSend('GameOption', key, val)
        end

        if not ignoreRefresh then
            UpdateGame()
        end
    else
        WARN('Attempt to set game option by a non-host')
    end
end

function DebugDump()
    if lobbyComm then
        lobbyComm:DebugDump()
    end
end

local LrgMap = false
function CreateBigPreview(depth, parent)
    -- Size of the border image around the large map.
    local MAP_PREVIEW_BORDER_SIZE = 754

    -- Size of the actual map preview to generate.
    local MAP_PREVIEW_SIZE = 713

    -- The size of the mass/hydrocarbon icons
    local HYDROCARBON_ICON_SIZE = 14
    local MASS_ICON_SIZE = 10

    LrgMap = Group(parent)
    LrgMap.Width:Set(MAP_PREVIEW_BORDER_SIZE)
    LrgMap.Height:Set(MAP_PREVIEW_BORDER_SIZE)

    -- Center the map group on the screen
    LayoutHelpers.AtHorizontalCenterIn(LrgMap, parent)
    LayoutHelpers.AtVerticalCenterIn(LrgMap, parent)

    LrgMap.Depth:Set(depth)

    -- Create the map preview
    local mapPreview = MapPreview(LrgMap)
    mapPreview.Width:Set(MAP_PREVIEW_SIZE)
    mapPreview.Height:Set(MAP_PREVIEW_SIZE)
    LayoutHelpers.AtLeftTopIn(mapPreview, LrgMap, 19, 20)

    -- Place the border inside the group at the origin.
    local border = Bitmap(LrgMap, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/map-pane-border-large.png"))
    LayoutHelpers.AtLeftTopIn(border, LrgMap)
    LayoutHelpers.DepthOverParent(border, mapPreview, 1)

    local closeBtn = UIUtil.CreateButtonStd(LrgMap, '/dialogs/close_btn/close', "", 12, 2, 0, "UI_Tab_Click_01",
    "UI_Tab_Rollover_01")
    LayoutHelpers.AtRightTopIn(closeBtn, LrgMap, 20, 17)
    closeBtn.OnClick = function()
        CloseBigPreview()
    end

    -- Keep the close button on top of the border (which is itself on top of the map preview)
    LayoutHelpers.DepthOverParent(closeBtn, border, 1)

    -- Load the mass/hydrocarbon points and put them on the map.
    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') then
        if not mapPreview:SetTexture(scenarioInfo.preview) then
            mapPreview:SetTextureFromMap(scenarioInfo.map)
        end
    end

    local mapdata = {}
    doscript('/lua/dataInit.lua', mapdata) -- needed for the format of _save files
    doscript(scenarioInfo.save, mapdata)

    local allmarkers = mapdata.Scenario.MasterChain['_MASTERCHAIN_'].Markers -- get the markers from the save file
    local massmarkers = {}
    local hydromarkers = {}

    for markname in allmarkers do
        if allmarkers[markname]['type'] == "Mass" then
            table.insert(massmarkers, allmarkers[markname])
        elseif allmarkers[markname]['type'] == "Hydrocarbon" then
            table.insert(hydromarkers, allmarkers[markname])
        end
    end

    -- Add the mass points.
    local masses = {}
    for i = 1, table.getn(massmarkers) do
        masses[i] = Bitmap(mapPreview, UIUtil.SkinnableFile("/game/build-ui/icon-mass_bmp.dds"))
        masses[i].Width:Set(MASS_ICON_SIZE)
        masses[i].Height:Set(MASS_ICON_SIZE)

        LayoutHelpers.AtLeftTopIn(masses[i], mapPreview,
            massmarkers[i].position[1] / scenarioInfo.size[1] * MAP_PREVIEW_SIZE - MASS_ICON_SIZE / 2,
            massmarkers[i].position[3] / scenarioInfo.size[2] * MAP_PREVIEW_SIZE - MASS_ICON_SIZE / 2)
    end
    mapPreview.massmarkers = masses

    -- Add the hydrocarbon points.
    local hydros = {}
    for i = 1, table.getn(hydromarkers) do
        hydros[i] = Bitmap(mapPreview, UIUtil.SkinnableFile("/game/build-ui/icon-energy_bmp.dds"))
        hydros[i].Width:Set(HYDROCARBON_ICON_SIZE)
        hydros[i].Height:Set(HYDROCARBON_ICON_SIZE)

        LayoutHelpers.AtLeftTopIn(hydros[i], mapPreview,
            hydromarkers[i].position[1] / scenarioInfo.size[1] * MAP_PREVIEW_SIZE - HYDROCARBON_ICON_SIZE / 2,
            hydromarkers[i].position[3] / scenarioInfo.size[2]*  MAP_PREVIEW_SIZE - HYDROCARBON_ICON_SIZE / 2)
    end
    mapPreview.hydros = hydros

    -- start positions
    mapPreview.markers = {}
    -- TODO: DIE DIE DIE.
    NewShowMapPositions(mapPreview, scenarioInfo, GetPlayerCount())
end

function CloseBigPreview()
    LrgMap:Hide()
end

local posGroup = false
-- copied from the old lobby.lua, needed to change GUI. into LrgMap. for a separately handled set of markers
-- TODO: We have these things called "function parameters".
function NewShowMapPositions(mapCtrl, scenario, numPlayers)
    if scenario.starts == nil then scenario.starts = true end

    if posGroup then
        posGroup:Destroy()
        posGroup = false
    end

    if mapCtrl.markers and table.getn(mapCtrl.markers) > 0 then
        for i, v in mapCtrl.markers do
            v.marker:Destroy()
        end
    end

    if not scenario.starts or not scenario.size then return end

    local posGroup = Group(mapCtrl)
    LayoutHelpers.FillParent(posGroup, mapCtrl)

    local startPos = MapUtil.GetStartPositions(scenario)

    local cHeight = posGroup:Height()
    local cWidth = posGroup:Width()

    local mWidth = scenario.size[1]
    local mHeight = scenario.size[2]

    local playerArmyArray = MapUtil.GetArmies(scenario)

    for inSlot, army in playerArmyArray do
        local pos = startPos[army]
        local slot = inSlot
        mapCtrl.markers[slot] = {}
        mapCtrl.markers[slot].marker = Bitmap(posGroup)
        mapCtrl.markers[slot].marker.Height:Set(10)
        mapCtrl.markers[slot].marker.Width:Set(8)
        mapCtrl.markers[slot].marker.Depth:Set(function() return posGroup.Depth() + 10 end)
        mapCtrl.markers[slot].marker:SetSolidColor('00777777')

        mapCtrl.markers[slot].teamIndicator = Bitmap(mapCtrl.markers[slot].marker)
        LayoutHelpers.AnchorToRight(mapCtrl.markers[slot].teamIndicator, mapCtrl.markers[slot].marker, 1)
        LayoutHelpers.AtTopIn(mapCtrl.markers[slot].teamIndicator, mapCtrl.markers[slot].marker, 5)
        mapCtrl.markers[slot].teamIndicator:DisableHitTest()

        local buttonImage = UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds')
        mapCtrl.markers[slot].markerOverlay = Button(mapCtrl.markers[slot].marker, buttonImage, buttonImage, buttonImage, buttonImage)

        LayoutHelpers.AtCenterIn(mapCtrl.markers[slot].markerOverlay, mapCtrl.markers[slot].marker)
        mapCtrl.markers[slot].markerOverlay.Slot = slot
        mapCtrl.markers[slot].markerOverlay.OnClick = function(self, modifiers)
            if modifiers.Left then
                if FindSlotForID(localPlayerID) ~= self.Slot and gameInfo.PlayerOptions[self.Slot] == nil then
                    if IsPlayer(localPlayerID) then
                        if lobbyComm:IsHost() then
                            HostTryMovePlayer(hostID, FindSlotForID(localPlayerID), self.Slot)
                        else
                            lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID),
                            RequestedSlot =  self.Slot})
                        end
                    elseif IsObserver(localPlayerID) then
                        if lobbyComm:IsHost() then
                            HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID),
                            self.Slot)
                        else
                            lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName,
                            ObserverSlot = FindObserverSlotForID(localPlayerID),
                            PlayerSlot = self.Slot})
                        end
                    end
                end
            elseif modifiers.Right then
                if lobbyComm:IsHost() then
                    if gameInfo.ClosedSlots[self.Slot] == nil then
                        HostCloseSlot(hostID, self.Slot)
                    else
                        HostOpenSlot(hostID, self.Slot)
                    end
                end
            end
        end
        mapCtrl.markers[slot].markerOverlay.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' then
                    GUI.slots[self.Slot].name.HandleEvent(self, event)
                    mapCtrl.markers[self.Slot].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                GUI.slots[self.Slot].name.HandleEvent(self, event)
                mapCtrl.markers[self.Slot].Indicator:Stop()
            end
            Button.HandleEvent(self, event)
        end
        LayoutHelpers.AtLeftTopIn(mapCtrl.markers[slot].marker, posGroup,
        ((pos[1] / mWidth) * cWidth) - (mapCtrl.markers[slot].marker.Width() / 2),
        ((pos[2] / mHeight) * cHeight) - (mapCtrl.markers[slot].marker.Height() / 2))

        local index = slot
        mapCtrl.markers[slot].Indicator = Bitmap(mapCtrl.markers[slot].marker,
        UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
        LayoutHelpers.AtCenterIn(mapCtrl.markers[slot].Indicator, mapCtrl.markers[slot].marker)
        mapCtrl.markers[slot].Indicator.Height:Set(function() return mapCtrl.markers[index].Indicator.BitmapHeight() * .3 end)
        mapCtrl.markers[slot].Indicator.Width:Set(function() return mapCtrl.markers[index].Indicator.BitmapWidth() * .3 end)
        mapCtrl.markers[slot].Indicator.Depth:Set(function() return mapCtrl.markers[index].marker.Depth() - 1 end)
        mapCtrl.markers[slot].Indicator:Hide()
        mapCtrl.markers[slot].Indicator:DisableHitTest()
        mapCtrl.markers[slot].Indicator.Play = function(self)
            self:SetAlpha(1)
            self:Show()
            self:SetNeedsFrameUpdate(true)
            self.time = 0
            self.OnFrame = function(control, time)
                control.time = control.time + (time*4)
                control:SetAlpha(MATH_Lerp(math.sin(control.time), -.5, .5, 0.3, 0.5))
            end
        end
        mapCtrl.markers[slot].Indicator.Stop = function(self)
            self:SetAlpha(0)
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end

        if gameInfo.GameOptions['TeamSpawn'] == 'random' then
            mapCtrl.markers[slot].marker:SetSolidColor("00777777")
        else
            if gameInfo.PlayerOptions[slot] then
                mapCtrl.markers[slot].marker:SetSolidColor(gameColors.PlayerColors[gameInfo.PlayerOptions[slot].PlayerColor])
                if gameInfo.PlayerOptions[slot].Team == 1 then
                    mapCtrl.markers[slot].teamIndicator:SetSolidColor('00000000')
                else
                    mapCtrl.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.PlayerOptions[slot].Team]))
                end
            else
                mapCtrl.markers[slot].marker:SetSolidColor("00777777")
                mapCtrl.markers[slot].teamIndicator:SetSolidColor('00000000')
            end
        end

        if gameInfo.ClosedSlots[slot] ~= nil then
            local textOverlay = Text(mapCtrl.markers[slot].markerOverlay)
            textOverlay:SetFont(UIUtil.bodyFont, 14)
            textOverlay:SetColor("Crimson")
            textOverlay:SetText("X")
            LayoutHelpers.AtCenterIn(textOverlay, mapCtrl.markers[slot].markerOverlay)
        end
    end
end -- NewShowMapPositions(...)

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------  Duck_42 Wall  --------------------------------------------------------
--******************************************************************************************************
-- CPU Benchmark Code
-- Author: Duck_42
-- Date: 2013.04.05
--
-- 2013.09.24 - Significant change to benchmark logic.  This should improve accuracy and eliminate some
--              problems.
-- 2013.10.04 - Reverting back to previous CPU benchmark.  The new one doesn't appear to be
--              as accurate as the old one.
-- 2013.11.04 - Second attempt at improving the CPU benchmark.  This one has been tested much more and
--              should produce the desired results.
--******************************************************************************************************

--CPU Status Bar Configuration
local barMax = 450
local barMin = 0
local greenBarMax = 300
local yellowBarMax = 375
local scoreSkew1 = 0 --Skews all CPU scores up or down by the amount specified (0 = no skew)
local scoreSkew2 = 1.0 --Skews all CPU scores specified coefficient (1.0 = no skew)

--Variables for CPU Test
local firstCPUTest = true
local BenchTime

--------------------------------------------------
--  CPU Benchmarking Functions
--------------------------------------------------
function CPUBenchmark()
    --This function gives the CPU some busy work to do.
    --CPU score is determined by how quickly the work is completed.
    local totalTime = 0
    local lastTime
    local currTime
    local countTime = 0
    --Make everything a local variable
    --This is necessary because we don't want LUA searching through the globals as part of the benchmark
    local h
    local i
    local j
    local k
    local l
    local m
    for h = 1, 48, 1 do
        -- If the need for the benchmark no longer exists, abort it now.
        if not lobbyComm then
            return
        end

        lastTime = GetSystemTimeSeconds()
        for i = 1.0, 25.0, 0.0008 do
            --This instruction set should cover most LUA operators
            j = i + i   --Addition
            k = i * i   --Multiplication
            l = k / j   --Division
            m = j - i   --Subtraction
            j = i ^ 4   --Power
            l = -i      --Negation
            m = {'One', 'Two', 'Three'} --Create Table
            table.insert(m, 'Four')     --Insert Table Value
            table.remove(m, 1)          --Remove Table Value
            l = table.getn(m)           --Get Table Length
            k = i < j   --Less Than
            k = i == j  --Equality
            k = i <= j  --Less Than or Equal to
            k = not k
        end
        currTime = GetSystemTimeSeconds()
        totalTime = totalTime + currTime - lastTime

        if totalTime > countTime then
            --This is necessary in order to make this 'thread' yield so other things can be done.
            countTime = totalTime + .125
            WaitSeconds(0)
        end
    end
    BenchTime = math.ceil(totalTime * 100)
end

--------------------------------------------------
--  CPU GUI Functions
--------------------------------------------------
function CreateCPUMetricUI()
    --This function handles creation of the CPU benchmark UI elements (statusbars, buttons, tooltips, etc)
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
    if not singlePlayer then
        for i= 1, LobbyComm.maxPlayerSlots do
            GUI.slots[i].CPUSpeedBar = StatusBar(GUI.slots[i].pingGroup, barMin, barMax, false, false,
            UIUtil.UIFile('/game/unit_bmp/bar_black_bmp.dds'),
            UIUtil.UIFile('/game/unit_bmp/bar_purple_bmp.dds'),
            true)
            LayoutHelpers.AtBottomIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 2)
            LayoutHelpers.AtLeftIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 0)
            LayoutHelpers.AtRightIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 0)
            CPU_AddControlTooltip(GUI.slots[i].CPUSpeedBar, 0, i)
            GUI.slots[i].CPUSpeedBar.CPUActualValue = 450

        end

        GUI.rerunBenchmark.OnClick = function(self, modifiers)
            GUI.rerunBenchmark:Disable()
            ForkThread(function() StressCPU(1) end)
        end
    end
end

function CPU_AddControlTooltip(control, delay, slotNumber)
    --This function creates the benchmark tooltip for a slot along with necessary mouseover function.
    --It is called during the UI creation.
    --    control: The control to which the tooltip is to be added.
    --    delay: Amount of time to delay before showing tooltip.  See Tooltip.CreateMouseoverDisplay for info.
    --  slotNumber: The slot number associated with the control.
    if not control.oldHandleEvent then
        control.oldHandleEvent = control.HandleEvent
    end
    control.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            local slot = slotNumber
            Tooltip.CreateMouseoverDisplay(self, {text='CPU Rating: '..GUI.slots[slot].CPUSpeedBar.CPUActualValue,
            body='0=Fastest, 450=Slowest'}, delay, true)
        elseif event.Type == 'MouseExit' then
            Tooltip.DestroyMouseoverDisplay()
        end
        return self.oldHandleEvent(self, event)
    end
end


-- This function instructs the PC to do a CPU score benchmark.
-- It handles the necessary UI updates during the benchmark, sends
-- the benchmark result to other players when finished, and it updates the local
-- user's UI with their new result.
--    waitTime: The delay in seconds that this function should wait before starting the benchmark.
function StressCPU(waitTime)

    for i = waitTime, 1, -1 do
        GUI.rerunBenchmark.label:SetText(i..'s')
        WaitSeconds(1)

        -- lobbyComm is destroyed when the lobby is exited. If the user left the lobby, we no longer
        -- want to run the benchmark (it just introduces lag as the user is trying to do something
        -- else.
        if not lobbyComm then
            return
        end
    end

    --Get our last benchmark (if there was one)
    local currentBestBenchmark = CPU_Benchmarks[localPlayerName]
    if currentBestBenchmark == nil then
        currentBestBenchmark = 10000
    end

    --LOG('Beginning CPU benchmark')
    if GUI.rerunBenchmark.label then GUI.rerunBenchmark.label:SetText('. . .') end

    --Run three benchmarks and keep the best one
    for i=1, 3, 1 do
        BenchTime = 0
        CPUBenchmark()

        BenchTime = scoreSkew2 * BenchTime + scoreSkew1

        --If this benchmark was better than our best so far...
        if BenchTime < currentBestBenchmark then
            --Make this our best benchmark
            currentBestBenchmark = BenchTime

            --Send it to the other players
            if lobbyComm then
                lobbyComm:BroadcastData( { Type = 'CPUBenchmark', PlayerName = localPlayerName, Result = currentBestBenchmark} )
            end

            --Add the benchmark to the local benchmark table
            CPU_Benchmarks[localPlayerName] = currentBestBenchmark

            --Update the UI bar
            UpdateCPUBar(localPlayerName)
        end
    end

    --Set this flag so we'll know later
    firstCPUTest = false

    --Reset Button UI
    GUI.rerunBenchmark:Enable()
    GUI.rerunBenchmark.label:SetText('')
end

function UpdateCPUBar(playerName)
    --This function updates the UI with a CPU benchmark bar for the specified playerName.
    --    playerName: The name of the player whose benchmark should be updated.
    local playerId = FindIDForName(playerName)
    local playerSlot = FindSlotForID(playerId)
    if playerSlot ~= nil then
        SetSlotCPUBar(playerSlot, gameInfo.PlayerOptions[playerSlot])
    end
end

function SetSlotCPUBar(slot, playerInfo)
    --This function updates the UI with a CPU benchmark bar for the specified slot/playerInfo.
    --    slot: a numbered slot (1-however many slots there are for this map)
    --    playerInfo: The corresponding playerInfo object from gameInfo.PlayerOptions[slot].

    if GUI.slots[slot].CPUSpeedBar then
        GUI.slots[slot].CPUSpeedBar:Hide()
        if playerInfo.Human then
            local b = CPU_Benchmarks[playerInfo.PlayerName]
            if b then
                -- For display purposes, the bar has a higher minimum that the actual barMin value.
                -- This is to ensure that the bar is visible for very small values

                -- Lock values to the largest possible result.
                if b > barMax then
                    b = barMax
                end

                GUI.slots[slot].CPUSpeedBar:SetValue(b)
                GUI.slots[slot].CPUSpeedBar.CPUActualValue = b

                GUI.slots[slot].CPUSpeedBar:Show()
            end
        end
    end
end

-- Flags
function Country_AddControlTooltip(control, waitDelay, slotNumber)
    local self = control
    if not control.oldHandleEvent then
        control.oldHandleEvent = control.HandleEvent
    end
    control.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            local slot = slotNumber
            Tooltip.CreateMouseoverDisplay(self, {text=PrefLanguageTooltipTitle[slot], body=PrefLanguageTooltipText[slot]}, waitDelay, true)
        elseif event.Type == 'MouseExit' then
            Tooltip.DestroyMouseoverDisplay()
        end
        return self.oldHandleEvent(self, event)
    end
end

function Country_GetTooltipValue(CountryResult, slot)
    local CountryOverrideTooltip = import('/lua/ui/help/tooltips-country.lua').tooltip
    local find = 0
    for index, option in CountryOverrideTooltip do
        if option.value == CountryResult and find == 0 then
            PrefLanguageTooltipTitle[slot] = option.title or "Country"
            PrefLanguageTooltipText[slot] = option.text
            find = 1
        end
    end
end

-- Rule title

-- Update the title to display the rule.
function RuleTitle_SendMSG()
    if GUI.RuleLabel and lobbyComm:IsHost() then
        local getRule = {GUI.RuleLabel:GetItem(0), GUI.RuleLabel:GetItem(1)}
        if getRule[1]..getRule[2] == 'No Rules: Click to add rules' or getRule[1]..getRule[2] == 'No Rules: Click to add rules ' then
            getRule[1] = 'Rule : no rule.'
            getRule[2] = ''
        else
            getRule[1] = GUI.RuleLabel:GetItem(0)
            getRule[2] = GUI.RuleLabel:GetItem(1)
        end
        lobbyComm:BroadcastData( { Type = 'Rule_Title_MSG', Result1 = getRule[1], Result2 = getRule[2] } )
    end
end

function RuleTitle_SetText(Result1, Result2)
    if GUI.RuleLabel and not lobbyComm:IsHost() then
        GUI.RuleLabel:DeleteAllItems()
        GUI.RuleLabel:AddItem(Result1)
        GUI.RuleLabel:AddItem(Result2)
    end
end

function RuleTitle_INPUT()
    local GUI_Preset_InputBox = Group(GUI)
    LayoutHelpers.AtCenterIn(GUI_Preset_InputBox, GUI)
    GUI_Preset_InputBox.Depth:Set(1999)
    local background2 = Bitmap(GUI_Preset_InputBox, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/optionlobby-small.dds'))
    GUI_Preset_InputBox.Width:Set(background2.Width)
    GUI_Preset_InputBox.Height:Set(background2.Height)
    LayoutHelpers.FillParent(background2, GUI_Preset_InputBox)
    local GUI_Preset_InputBox2 = Group(GUI_Preset_InputBox)
    GUI_Preset_InputBox2.Width:Set(536)
    GUI_Preset_InputBox2.Height:Set(400-240)
    LayoutHelpers.AtCenterIn(GUI_Preset_InputBox2, GUI_Preset_InputBox)
    -----------
    -- Title --
    local text09 = UIUtil.CreateText(GUI_Preset_InputBox2, '', 17, 'Arial', true)
    LayoutHelpers.AtHorizontalCenterIn(text09, GUI_Preset_InputBox2)
    LayoutHelpers.AtTopIn(text09, GUI_Preset_InputBox2, 10)
    ----------
    -- Edit --
    local nameEdit = Edit(GUI_Preset_InputBox2)
    LayoutHelpers.AtHorizontalCenterIn(nameEdit, GUI_Preset_InputBox2)
    LayoutHelpers.AtVerticalCenterIn(nameEdit, GUI_Preset_InputBox2)
    nameEdit.Width:Set(334)
    nameEdit.Height:Set(24)
    nameEdit:AcquireFocus()
    nameEdit.OnEnterPressed = function(self, text)
        if text == '' then
            GUI_Preset_InputBox:Destroy()
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem('No Rules: Click to add rules')
            GUI.RuleLabel:SetColors("FFCC00")
            GUI.RuleLabel:AddItem('')
            RuleTitle_SendMSG()
        else
            GUI_Preset_InputBox:Destroy()
            wrapped = import('/lua/maui/text.lua').WrapText('Rule : '..text, 350, function(curText) return GUI.RuleLabel:GetStringAdvance(curText) end)
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem(wrapped[1] or '')
            GUI.RuleLabel:SetColors("B9BFB9")
            GUI.RuleLabel:AddItem(wrapped[2] or '')
            RuleTitle_SendMSG()
        end
    end
    -------------------
    -- Exit button --
    local ExitButton = UIUtil.CreateButtonWithDropshadow(GUI_Preset_InputBox2, '/BUTTON/medium/', "Cancel", -1)
    LayoutHelpers.AtLeftIn(ExitButton, GUI_Preset_InputBox2, 70)
    LayoutHelpers.AtBottomIn(ExitButton, GUI_Preset_InputBox2, 10)
    ExitButton.OnClick = function(self)
        GUI_Preset_InputBox:Destroy()
    end
    -------------------
    -- Ok button --
    local OKButton = UIUtil.CreateButtonWithDropshadow(GUI_Preset_InputBox2, '/BUTTON/medium/', "Ok", -1)
    LayoutHelpers.AtRightIn(OKButton, GUI_Preset_InputBox2, 70)
    LayoutHelpers.AtBottomIn(OKButton, GUI_Preset_InputBox2, 10)
    text09:SetText('Game Rules')
    OKButton.OnClick = function(self)
        local result = nameEdit:GetText()
        if result == '' then
            GUI_Preset_InputBox:Destroy()
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem('No Rules: Click to add rules')
            GUI.RuleLabel:SetColors("FFCC00")
            GUI.RuleLabel:AddItem('')
            RuleTitle_SendMSG()
        else
            GUI_Preset_InputBox:Destroy()
            wrapped = import('/lua/maui/text.lua').WrapText('Rule : '..result, 350, function(curText) return GUI.RuleLabel:GetStringAdvance(curText) end)
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem(wrapped[1] or '')
            GUI.RuleLabel:SetColors("B9BFB9")
            GUI.RuleLabel:AddItem(wrapped[2] or '')
            RuleTitle_SendMSG()
        end
    end
end

-- Faction selector
function CreateUI_Faction_Selector()
    local factionPanel = Group(GUI.panel, "factionPanel")
    LayoutHelpers.AtLeftTopIn(factionPanel, GUI.panel, 410, 36) --Right:615
    factionPanel.Width:Set(205)
    factionPanel.Height:Set(60)

    GUI.AeonFactionPanel = Bitmap(factionPanel, "/textures/ui/common/FACTIONSELECTOR/aeon_ico.png")
    LayoutHelpers.AtLeftTopIn(GUI.AeonFactionPanel, factionPanel, 0, 0)
    LayoutHelpers.AtVerticalCenterIn(GUI.AeonFactionPanel, factionPanel, 0)

    GUI.CybranFactionPanel = Bitmap(factionPanel, "/textures/ui/common/FACTIONSELECTOR/cybran_ico.png")
    LayoutHelpers.AtLeftTopIn(GUI.CybranFactionPanel, factionPanel, 45, 0)
    LayoutHelpers.AtVerticalCenterIn(GUI.CybranFactionPanel, factionPanel, 0)

    GUI.UEFFactionPanel = Bitmap(factionPanel, "/textures/ui/common/FACTIONSELECTOR/uef_ico.png")
    LayoutHelpers.AtHorizontalCenterIn(GUI.UEFFactionPanel, factionPanel, 0)
    LayoutHelpers.AtVerticalCenterIn(GUI.UEFFactionPanel, factionPanel, 0)

    GUI.SeraphimFactionPanel = Bitmap(factionPanel, "/textures/ui/common/FACTIONSELECTOR/seraphim_ico.png")
    LayoutHelpers.AtRightTopIn(GUI.SeraphimFactionPanel, factionPanel, 45, 0)
    LayoutHelpers.AtVerticalCenterIn(GUI.SeraphimFactionPanel, factionPanel, 0)

    GUI.RandomFactionPanel = Bitmap(factionPanel, "/textures/ui/common/FACTIONSELECTOR/random_ico.png")
    LayoutHelpers.AtRightTopIn(GUI.RandomFactionPanel, factionPanel, 0, 0)
    LayoutHelpers.AtVerticalCenterIn(GUI.RandomFactionPanel, factionPanel, 0)

    GUI.factionPanel = factionPanel

    -- Relate faction numbers to faction panels to simplify update.
    FACTION_PANELS = {[1] = GUI.UEFFactionPanel, [2] = GUI.AeonFactionPanel,
                      [3] = GUI.CybranFactionPanel, [4] = GUI.SeraphimFactionPanel, [5] = GUI.RandomFactionPanel }

    -- Get a closure suitable for use as the event listener on a faction selection button.
    -- targetFaction is the faction represented by the faction selection panel using this listener.
    -- targetPanel is that faction selection panel.
    local function getFactionEventListener(targetPanel, targetFaction)
        return function(ctrl, event)
            local faction = Prefs.GetFromCurrentProfile('LastFaction') or 1
            local eventHandled = false
            if faction == targetFaction then
                targetPanel:SetTexture("/textures/ui/common/FACTIONSELECTOR/" .. FACTION_NAMES[targetFaction] .. "_ico-large.png")
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                    targetPanel:SetTexture("/textures/ui/common/FACTIONSELECTOR/" .. FACTION_NAMES[targetFaction] .. "_ico-hover.png")
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                    targetPanel:SetTexture("/textures/ui/common/FACTIONSELECTOR/" .. FACTION_NAMES[targetFaction] .. "_ico.png")
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true

                    local localSlot = FindSlotForID(localPlayerID)
                    Prefs.SetToCurrentProfile('LastFaction', targetFaction)
                    GUI.slots[localSlot].faction:SetItem(targetFaction)
                    SetPlayerOption(localSlot, 'Faction', targetFaction)
                    gameInfo.PlayerOptions[localSlot].Faction = targetFaction

                    SetCurrentFactionTo_Faction_Selector(targetFaction)
                end
            end

            return eventHandled
        end
    end

    GUI.AeonFactionPanel.HandleEvent = getFactionEventListener(GUI.AeonFactionPanel, 2)
    GUI.CybranFactionPanel.HandleEvent = getFactionEventListener(GUI.CybranFactionPanel, 3)
    GUI.UEFFactionPanel.HandleEvent = getFactionEventListener(GUI.UEFFactionPanel, 1)
    GUI.SeraphimFactionPanel.HandleEvent = getFactionEventListener(GUI.SeraphimFactionPanel, 4)
    GUI.RandomFactionPanel.HandleEvent = getFactionEventListener(GUI.RandomFactionPanel, 5)
end

function SetCurrentFactionTo_Faction_Selector(input_faction)
    local faction = input_faction or Prefs.GetFromCurrentProfile('LastFaction') or 1

    UIUtil.SetCurrentSkin(FACTION_NAMES[faction])
    ChangeBackgroundLobby(faction)
    if faction == 1 then
        LayoutHelpers.AtLeftIn(GUI.AeonFactionPanel, GUI.factionPanel, 0)
        LayoutHelpers.AtLeftIn(GUI.CybranFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.SeraphimFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.RandomFactionPanel, GUI.factionPanel, 0)
    elseif faction == 2 then
        LayoutHelpers.AtLeftIn(GUI.AeonFactionPanel, GUI.factionPanel, -15)
        LayoutHelpers.AtLeftIn(GUI.CybranFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.SeraphimFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.RandomFactionPanel, GUI.factionPanel, 0)
    elseif faction == 3 then
        LayoutHelpers.AtLeftIn(GUI.AeonFactionPanel, GUI.factionPanel, 0)
        LayoutHelpers.AtLeftIn(GUI.CybranFactionPanel, GUI.factionPanel, 45-15)
        LayoutHelpers.AtRightIn(GUI.SeraphimFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.RandomFactionPanel, GUI.factionPanel, 0)
    elseif faction == 4 then
        LayoutHelpers.AtLeftIn(GUI.AeonFactionPanel, GUI.factionPanel, 0)
        LayoutHelpers.AtLeftIn(GUI.CybranFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.SeraphimFactionPanel, GUI.factionPanel, 45-15)
        LayoutHelpers.AtRightIn(GUI.RandomFactionPanel, GUI.factionPanel, 0)
    elseif faction == 5 then
        LayoutHelpers.AtLeftIn(GUI.AeonFactionPanel, GUI.factionPanel, 0)
        LayoutHelpers.AtLeftIn(GUI.CybranFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.SeraphimFactionPanel, GUI.factionPanel, 45)
        LayoutHelpers.AtRightIn(GUI.RandomFactionPanel, GUI.factionPanel, -15)
    end
end

function ChangeBackgroundLobby(faction)
    local LobbyBackground = Prefs.GetFromCurrentProfile('LobbyBackground') or 1
    if GUI.background and GUI.background2 then
        if LobbyBackground == 1 then -- Factions
			LOGX('>> Background FACTION', 'Background')
            GUI.background:Show()
            GUI.background2:Hide()
            faction = faction or Prefs.GetFromCurrentProfile('LastFaction') or 0
            -- Unknown faction
            if faction < 1 then
                GUI.background:SetTexture("/textures/ui/common/BACKGROUND/background-paint_black_bmp.dds")
            else
                GUI.background:SetTexture("/textures/ui/common/BACKGROUND/faction/faction-background-paint_" .. FACTION_NAMES[faction] .. "_bmp.dds")
            end

        elseif LobbyBackground == 2 then -- Concept art
			LOGX('>> Background ART', 'Background')
            GUI.background:Show()
            GUI.background2:Hide()
            GUI.background:SetTexture("/textures/ui/common/BACKGROUND/art/art-background-paint0"..math.random(1, 5).."_bmp.dds")

        elseif LobbyBackground == 3 then -- Screenshot
			LOGX('>> Background SCREENSHOT', 'Background')
            GUI.background:Show()
            GUI.background2:Hide()
            GUI.background:SetTexture("/textures/ui/common/BACKGROUND/scrn/scrn-background-paint"..math.random(1, 14).."_bmp.dds")

        elseif LobbyBackground == 4 then -- Map
            LOGX('>> Background MAP', 'Background')
            GUI.background:Hide()
            GUI.background2:Show()
            local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
            if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= '') then
                scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') and scenarioInfo.preview then
                    if not GUI.background2:SetTexture(scenarioInfo.preview) then
                        GUI.background2:SetTextureFromMap(scenarioInfo.map)
                    end
                else
                    GUI.background2:ClearTexture()
                end
            else
                GUI.background2:ClearTexture()
            end

        elseif LobbyBackground == 5 then -- None
            LOGX('>> Background NOTHING', 'Background')
            GUI.background:Hide()
            GUI.background2:Hide()
            GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/background-paint_black_bmp.dds"))

        elseif LobbyBackground == 6 then -- Extra
			LOGX('>> Background EXTRA', 'Background')
            GUI.background:Show()
            GUI.background2:Hide()
            faction = faction or Prefs.GetFromCurrentProfile('LastFaction') or 1
            if DiskGetFileInfo("/Mods/Lobby Background/mod_info.lua") then
                settings = import("/Mods/Lobby Background/mod_info.lua")
                if settings.BackgroundType == 1 then
                    if faction == 1 and settings.uef > 0 then
                        GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/uef"..math.random(1, settings.uef)..".png")
                    elseif faction == 2 and settings.aeon > 0 then
                        GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/aeo"..math.random(1, settings.aeon)..".png")
                    elseif faction == 3 and settings.cybran > 0 then
                        GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/cyb"..math.random(1, settings.cybran)..".png")
                    elseif faction == 4 and settings.seraphim > 0 then
                        GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/ser"..math.random(1, settings.seraphim)..".png")
                    elseif faction == 5 and settings.random > 0 then
                        GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/ran"..math.random(1, settings.random)..".png")
                    else
                        GUI.background:SetTexture("/textures/ui/common/BACKGROUND/background-paint_black_bmp.dds")
                    end
                elseif settings.BackgroundType == 2 then
                    GUI.background:SetTexture("/Mods/Lobby Background/BACKGROUND/"..math.random(1, settings.random)..".png")
                end
            else
                GUI.background:SetTexture("/textures/ui/common/BACKGROUND/background-paint_black_bmp.dds")
            end
        end
    end
end


function CreateOptionLobbyDialog()
    local dialog = Group(GUI)
    LayoutHelpers.AtCenterIn(dialog, GUI)
    dialog.Depth:Set(GetFrame(dialog:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)

    local background = Bitmap(dialog, '/textures/ui/common/scx_menu/lan-game-lobby/optionlobby.dds')
    dialog.Width:Set(background.Width)
    dialog.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, dialog)

    local dialog2 = Group(dialog)
    dialog2.Width:Set(526)
    dialog2.Height:Set(350)
    LayoutHelpers.AtCenterIn(dialog2, dialog)

    -- The provided radiobutton control doesn't allow satellite data, so we use the index in this
    -- list as our stored background mode value.
    local backgroundStates = {
        LOC("<LOC lobui_0406>"), -- Factions
        LOC("<LOC lobui_0407>"), -- Concept art
        LOC("<LOC lobui_0408>"), -- Screenshot
        LOC("<LOC lobui_0409>"), -- Map
        LOC("<LOC lobui_0410>"), -- None
    }
    local selectedBackgroundState = backgroundStates[Prefs.GetFromCurrentProfile("LobbyBackground") or 1]
    local backgroundRadiobutton = UIUtil.CreateRadioButtonsStd(dialog2, '/CHECKBOX/radio', LOC("<LOC lobui_0405>"), backgroundStates, selectedBackgroundState)

    LayoutHelpers.AtLeftTopIn(backgroundRadiobutton, dialog2, 20, 20)

    backgroundRadiobutton.OnChoose = function(self, button)
        local backgroundMode = indexOf(backgroundStates, button)
        Prefs.SetToCurrentProfile("LobbyBackground", backgroundMode)
        ChangeBackgroundLobby()
    end
	--
	local Slider = import('/lua/maui/slider.lua').Slider
	local currentFontSize = Prefs.GetFromCurrentProfile('LobbyChatFontSize') or 14
	local slider_Chat_SizeFont_TEXT = UIUtil.CreateText(dialog2, LOC("<LOC lobui_0404>").. currentFontSize, 14, 'Arial', true)
    LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont_TEXT, dialog2, 20, 155)

	local slider_Chat_SizeFont = Slider(dialog2, false, 9, 18, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))
    LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont, dialog2, 20, 170)
    slider_Chat_SizeFont:SetValue(currentFontSize)

	slider_Chat_SizeFont.OnValueChanged = function(self, newValue)
        local sliderValue = math.floor(slider_Chat_SizeFont._currentValue())
        slider_Chat_SizeFont_TEXT:SetText('Chat Size Font : '..sliderValue)
        GUI.chatDisplay:SetFont(UIUtil.bodyFont, sliderValue)
        Prefs.SetToCurrentProfile('LobbyChatFontSize', sliderValue)
	end
	--
    local cbox_WindowedLobby = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
    LayoutHelpers.AtRightIn(cbox_WindowedLobby, dialog2, 20)
    LayoutHelpers.AtTopIn(cbox_WindowedLobby, dialog2, 20)
    Tooltip.AddCheckboxTooltip(cbox_WindowedLobby, {text='Windowed mode', body=LOC("<LOC lobui_0403>")})
    local cbox_WindowedLobby_TEXT = UIUtil.CreateText(cbox_WindowedLobby, LOC("<LOC lobui_0402>"), 14, 'Arial', true)
    LayoutHelpers.AtRightIn(cbox_WindowedLobby_TEXT, cbox_WindowedLobby, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_WindowedLobby_TEXT, cbox_WindowedLobby)
    cbox_WindowedLobby.OnCheck = function(self, checked)
        local option
        if(checked) then
            option = 'true'
        else
            option = 'false'
        end
        Prefs.SetToCurrentProfile('WindowedLobby', option)
        SetWindowedLobby(checked)
    end
    --
    local cbox_StretchBG = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
    LayoutHelpers.AtRightTopIn(cbox_StretchBG, dialog2, 20, 60)
    Tooltip.AddCheckboxTooltip(cbox_StretchBG, {text='Stretch Background', body=LOC("<LOC lobui_0401>")})
    local cbox_StretchBG_TEXT = UIUtil.CreateText(cbox_StretchBG, LOC("<LOC lobui_0400>"), 14, 'Arial', true)
    LayoutHelpers.AtRightIn(cbox_StretchBG_TEXT, cbox_StretchBG, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_StretchBG_TEXT, cbox_StretchBG)
    cbox_StretchBG.OnCheck = function(self, checked)
        if checked then
            Prefs.SetToCurrentProfile('LobbyBackgroundStretch', 'true')
            LayoutHelpers.FillParent(GUI.background, GUI)
            LayoutHelpers.FillParent(GUI.background2, GUI)
        else
            Prefs.SetToCurrentProfile('LobbyBackgroundStretch', 'false')
            LayoutHelpers.FillParentPreserveAspectRatio(GUI.background, GUI)
            LayoutHelpers.FillParentPreserveAspectRatio(GUI.background2, GUI)
        end
    end
    --
    local cbox_SMsg = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
    LayoutHelpers.AtRightTopIn(cbox_SMsg, dialog2, 20, 100)
    Tooltip.AddCheckboxTooltip(cbox_SMsg, {text='Log to chat', body=LOC("<LOC lobui_0398>")})
    local cbox_SMsg_TEXT = UIUtil.CreateText(cbox_SMsg, LOC("<LOC lobui_0397>"), 14, 'Arial', true)
    LayoutHelpers.AtRightIn(cbox_SMsg_TEXT, cbox_SMsg, 25)
    LayoutHelpers.AtVerticalCenterIn(cbox_SMsg_TEXT, cbox_SMsg)
    cbox_SMsg.OnCheck = function(self, checked)
        if checked then
            Prefs.SetToCurrentProfile('LobbySystemMessagesEnabled', 'true')
        else
            Prefs.SetToCurrentProfile('LobbySystemMessagesEnabled', 'false')
        end
    end
    ----------------------
    -- Developer box --
    local devsHeader = UIUtil.CreateText(dialog2, LOC("<LOC lobui_0399>"), 17, 'Arial Gras', true)
    LayoutHelpers.AtLeftTopIn(devsHeader, dialog2, 20, 220)
    -- Ask to Xinnony for add your name and work correctly
    local text = {}
    local ttext = {'- Xinnony : New Skin (with Barlots), Preset Lobby, Faction Selector, Country Flag, Move Player to,',
    'Hide Unchanged option, Color State in Nickname, Custom Title, Sort option, Game Ranked label,',
    'Bugs Fixing and lots of mores.',
    '- Vicarian : Contribute with Xinnony, Rating Observer, bugs fixing.',
    '- Duck_42 : CPU Bench, Ping Nuke.',
    '- Moritz : Power Lobby 2.0.', }

    for i, v in ttext do
        text[i] = UIUtil.CreateText(dialog2, v, 10, 'Arial', true)
        if i == 2 then
            LayoutHelpers.AtLeftTopIn(text[2], dialog2, 40, 255)
        elseif i == 3 then
            LayoutHelpers.AtLeftTopIn(text[3], dialog2, 40, 265)
        else
            LayoutHelpers.AtLeftTopIn(text[i], dialog2, 20, 225+(15*i))
        end
    end
    ------------------
    -- Quit button --
    local QuitButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Thank You !", -1)
    LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialog2, 0)
    LayoutHelpers.AtBottomIn(QuitButton, dialog2, 10)
    QuitButton.OnClick = function(self)
        dialog:Destroy()
        dialog2:Destroy()
    end

    --
    local WindowedLobby = Prefs.GetFromCurrentProfile('WindowedLobby') or 'true'
    cbox_WindowedLobby:SetCheck(WindowedLobby == 'true', true)
	if defaultMode == 'windowed' then
		-- Already set Windowed in Game
		cbox_WindowedLobby:Disable()
		cbox_WindowedLobby_TEXT:Disable()
		cbox_WindowedLobby_TEXT:SetColor('5C5F5C')
	end
    --
    local LobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    cbox_StretchBG:SetCheck(LobbyBackgroundStretch == 'true', true)
    --
    cbox_SMsg:SetCheck(SystemMessagesEnabled(), true)
end

--------------------------------------------------------------------------------------
-------------------------- TEST Text Animation (Experimental) ------------------------


SetText2 = function(self, text, delay) -- Set Text with Animation
    --// Faire une variable qui evite deux droit SetText2 sur le même control de text en même temps.
    if self:GetText() == text then
        --self:SetText(text)
    else
        --if ANIM_TEXT_ALLOWED then
        self:StreamText(text, delay)
        --else
        --self:SetText(text)
        --end
    end
end 

--------------------------------------------------------------------------------------
-------------------------- TEST Save/Load Preset Game Lobby --------------------------
-- GUI
-- Load and Create Preset Lobby
function GUI_PRESET()
    local profiles = GetPreference("UserPresetLobby")

    GUI_Preset = Group(GUI)
    LayoutHelpers.AtCenterIn(GUI_Preset, GUI)
    GUI_Preset.Depth:Set(998) -- :GetTopmostDepth() + 1
    local background = Bitmap(GUI_Preset, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/optionlobby.dds'))
    GUI_Preset.Width:Set(background.Width)
    GUI_Preset.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, GUI_Preset)
    local dialog2 = Group(GUI_Preset)
    dialog2.Width:Set(536)
    dialog2.Height:Set(400)
    LayoutHelpers.AtCenterIn(dialog2, GUI_Preset)
    -----------
    -- Title --
    local text0 = UIUtil.CreateText(dialog2, 'Preset Lobby :', 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(text0, dialog2, 0)
    LayoutHelpers.AtTopIn(text0, dialog2, 10)
    ---------------
    -- Info text --
    local text1 = UIUtil.CreateText(dialog2, 'Note : Double click in the list for Edit', 9, 'Arial', true)
    text1:SetColor('FFCC00')
    text1:Hide()
    --------------------
    -- LOAD button --
    local LoadButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Load preset", -1)
    LayoutHelpers.AtLeftIn(LoadButton, dialog2, 0)
    LayoutHelpers.AtBottomIn(LoadButton, dialog2, 10)
    LoadButton.OnClick = function(self)
        LOAD_PRESET_IN_PREF()
    end
    ------------------
    -- Preset List --
    PresetList = ItemList(dialog2)
    PresetList:SetFont(UIUtil.bodyFont, 14)
    --InfoList:SetColors(UIUtil.fontColor, "00000000", "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    PresetList:ShowMouseoverItem(true)
    PresetList.Width:Set(210)
    PresetList.Height:Set(310)
    LayoutHelpers.DepthOverParent(PresetList, dialog2, 10)
    LayoutHelpers.AtLeftIn(PresetList, dialog2, 10)
    LayoutHelpers.AtTopIn(PresetList, dialog2, 38)
    UIUtil.CreateLobbyVertScrollbar(PresetList)
    --
    LOAD_PresetProfils_For_PresetList()
    PresetList:SetSelection(0)
    PresetList.OnClick = function(self, row)
        if PresetList:GetItemCount() == (row+1) then
            PresetList:SetSelection(row)
            LoadButton.label:SetText('Create new preset')
            LoadButton.OnClick = function(self)
                CREATE_PRESET_IN_PREF()
            end
            --
            InfoList:DeleteAllItems()
        else
            LoadButton.label:SetText('Load preset')
            LoadButton.OnClick = function(self)
                LOAD_PRESET_IN_PREF()
            end
            --
            PresetList:SetSelection(row)
            local profiles = GetPreference("UserPresetLobby")
            --AddChatText('> '..table.KeyByIndex(profiles, row)) -- Selected Profils : Preset1
            --AddChatText('> '..PresetList:GetItem(row)..' , '..(PresetList:GetSelection()+1)..' / '..PresetList:GetItemCount()) -- (itemname) , (currentitem) / (maxitem)
            --LOG('> '..(PresetList:GetSelection()+1)..' / '..PresetList:GetItemCount())
            LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, row)) -- Charge les infos sur la InfoList
        end
    end
    PresetList.OnDoubleClick = function(self, row)
        --if row == 0 then
        LOAD_PRESET_IN_PREF()
        --end
    end
    ---------------
    -- Info List --
    InfoList = ItemList(dialog2)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    --                                  foreground, background, selected_foreground, selected_background, mouseover_foreground, mouseover_background)
    InfoList:SetColors(nil, "00000000")--, "FF000000",  UIUtil.highlightColor, "ffbcfffe")
    InfoList:ShowMouseoverItem(true)
    InfoList.Width:Set(262)-- -16
    InfoList.Height:Set(300)
    LayoutHelpers.AtRightIn(InfoList, dialog2, 10+16)
    LayoutHelpers.AtTopIn(InfoList, dialog2, 38)
    LayoutHelpers.Below(text1, InfoList, 0)
    LayoutHelpers.AtHorizontalCenterIn(text1, InfoList, 0)
    --SetColors = function(self, foreground, background, selected_foreground, selected_background, mouseover_foreground, mouseover_background)
    UIUtil.CreateLobbyVertScrollbar(InfoList)
    --
    local profiles = GetPreference("UserPresetLobby")
    if profiles then
        LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, 0))
    end
    InfoList.OnDoubleClick = function(self, row)
        if row == 0 then
            GUI_PRESET_INPUT(1)
        elseif row == 1 then
            GUI_PRESET_INPUT(2)
        elseif row == 2 then
            GUI_PRESET_INPUT(3)
        end
    end
    InfoList.OnMouseoverItem = function(self, row) -- Show notice or Hide
        if row == 0 or row == 1 or row == 2 then
            text1:Show()
        else
            text1:Hide()
        end
    end
    -------------------
    -- QUIT button --
    local QuitButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Cancel", -1)
    LayoutHelpers.CenteredRightOf(QuitButton, LoadButton, -16)
    QuitButton.OnClick = function(self)
        GUI_Preset:Destroy()
    end
    --------------------
    -- SAVE button --
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/small/', "Save preset", -1)
    LayoutHelpers.AtRightIn(SaveButton, dialog2, 0)
    --LayoutHelpers.AtBottomIn(SaveButton, dialog2, 10)
    LayoutHelpers.AtVerticalCenterIn(SaveButton, LoadButton)
    SaveButton.OnClick = function(self)
        SAVE_PRESET_IN_PREF()
        local last_selected = PresetList:GetSelection()
        local profiles = GetPreference("UserPresetLobby")
        LOAD_PresetProfils_For_PresetList()
        PresetList:SetSelection(last_selected)
        LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, last_selected))
        SavePreferences()
    end
    -------------------
    -- Delete button --
    local DeleteButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/small/', "Delete preset", -1)
    LayoutHelpers.CenteredLeftOf(DeleteButton, SaveButton, -10)
    --LayoutHelpers.AtBottomIn(DeleteButton, dialog2, 10)
    LayoutHelpers.AtVerticalCenterIn(DeleteButton, LoadButton)
    DeleteButton.OnClick = function(self)
        local profiles = GetPreference("UserPresetLobby")
        local last_selected = table.KeyByIndex(profiles, PresetList:GetSelection()) -- Preset4
        profiles[last_selected] = nil -- Efface le Preset selectioner
        SetPreference('UserPresetLobby', profiles) -- ReInsert all preset without last deleted
        LOAD_PresetProfils_For_PresetList()
        PresetList:SetSelection(0)
        LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
        SavePreferences()
    end
    -------------
    -- Credit --
    local text99 = UIUtil.CreateText(dialog2, 'Xinnony', 9, 'Arial', true)
    text99:SetColor('808080')
    LayoutHelpers.AtRightIn(text99, dialog2, 0)
    LayoutHelpers.AtBottomIn(text99, dialog2, 2)
end

function GUI_PRESET_INPUT(tyype)
    local GUI_Preset_InputBox = Group(GUI)
    LayoutHelpers.AtCenterIn(GUI_Preset_InputBox, GUI)
    GUI_Preset_InputBox.Depth:Set(1999)
    local background2 = Bitmap(GUI_Preset_InputBox, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/optionlobby-small.dds'))
    GUI_Preset_InputBox.Width:Set(background2.Width)
    GUI_Preset_InputBox.Height:Set(background2.Height)
    LayoutHelpers.FillParent(background2, GUI_Preset_InputBox)
    local GUI_Preset_InputBox2 = Group(GUI_Preset_InputBox)
    GUI_Preset_InputBox2.Width:Set(536)
    GUI_Preset_InputBox2.Height:Set(400-240)
    LayoutHelpers.AtCenterIn(GUI_Preset_InputBox2, GUI_Preset_InputBox)
    -----------
    -- Title --
    local text09 = UIUtil.CreateText(GUI_Preset_InputBox2, '', 17, 'Arial', true)
    LayoutHelpers.AtHorizontalCenterIn(text09, GUI_Preset_InputBox2)
    LayoutHelpers.AtTopIn(text09, GUI_Preset_InputBox2, 10)
    ----------
    -- Edit --
    local nameEdit = Edit(GUI_Preset_InputBox2)
    LayoutHelpers.AtHorizontalCenterIn(nameEdit, GUI_Preset_InputBox2)
    LayoutHelpers.AtVerticalCenterIn(nameEdit, GUI_Preset_InputBox2)
    nameEdit.Width:Set(334)
    nameEdit.Height:Set(24)
    nameEdit:AcquireFocus()
    nameEdit.OnEnterPressed = function(self, text)
        if tyype == -1 then
            if text == '' then
                -- No word in nameEdit
            else
                applyCREATE_PRESET_IN_PREF(text)
                GUI_Preset_InputBox:Destroy()
            end
        elseif tyype == 0 then
            if text == '' then
                -- No word in nameEdit
            else
                applyCREATE_PRESET_IN_PREF(text)
                GUI_Preset_InputBox:Destroy()
            end
        elseif tyype == 1 then
            if text == '' then
                -- No word in nameEdit
            else
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.PresetName', tostring(text))
                local lastselect = PresetList:GetSelection()
                LOAD_PresetProfils_For_PresetList()
                PresetList:SetSelection(lastselect)
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        elseif tyype == 2 then
            if text == '' then
                -- No word in nameEdit
            else
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.FAF_Title', tostring(text))
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        elseif tyype == 3 then
            if text == '' then
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.Rule', 'no rule.')
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            else
                local profiles = GetPreference("UserPresetLobby")
                --AddChatText('rename> Profil?:'..table.KeyByIndex(profiles, PresetList:GetSelection())..' // selection:'..PresetList:GetSelection())
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.Rule', tostring(text))
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        end
    end
    -------------------
    -- Exit button --
    local ExitButton = UIUtil.CreateButtonWithDropshadow(GUI_Preset_InputBox2, '/BUTTON/medium/', "Cancel", -1)
    LayoutHelpers.AtLeftIn(ExitButton, GUI_Preset_InputBox2, 70)
    LayoutHelpers.AtBottomIn(ExitButton, GUI_Preset_InputBox2, 10)
    ExitButton.OnClick = function(self)
        GUI_Preset_InputBox:Destroy()
		if tyype == -1 then
			GUI_Preset:Destroy()
		end
    end
    -------------------
    -- Ok button --
    local OKButton = UIUtil.CreateButtonWithDropshadow(GUI_Preset_InputBox2, '/BUTTON/medium/', "Ok", -1)
    LayoutHelpers.AtRightIn(OKButton, GUI_Preset_InputBox2, 70)
    LayoutHelpers.AtBottomIn(OKButton, GUI_Preset_InputBox2, 10)
    if tyype == -1 then
        -- TODO: Localize this
        text09:SetText('No presets found, choose a name for a new preset:')
        OKButton.OnClick = function(self)
            local result = nameEdit:GetText()
            if result == '' then
                -- No word in nameEdit
            else
                applyCREATE_PRESET_IN_PREF(result)
                GUI_Preset_InputBox:Destroy()
            end
        end
    elseif tyype == 0 then
        text09:SetText('Set your preset name:')
        OKButton.OnClick = function(self)
            local result = nameEdit:GetText()
            if result == '' then
                -- No word in nameEdit
            else
                applyCREATE_PRESET_IN_PREF(result)
                GUI_Preset_InputBox:Destroy()
            end
        end
    elseif tyype == 1 then
        text09:SetText('Rename your preset:')
        OKButton.OnClick = function(self)
            local result = nameEdit:GetText()
            if result == '' then
                -- No word in nameEdit
            else
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.PresetName', tostring(result))
                local lastselect = PresetList:GetSelection()
                LOAD_PresetProfils_For_PresetList()
                PresetList:SetSelection(lastselect)
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        end
    elseif tyype == 2 then
        text09:SetText('Rename your FAF Title:')
        OKButton.OnClick = function(self)
            local result = nameEdit:GetText()
            if result == '' then
                -- No word in nameEdit
            else
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.FAF_Title', tostring(result))
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        end
    elseif tyype == 3 then
        text09:SetText('Rename your rule:')
        OKButton.OnClick = function(self)
            local result = nameEdit:GetText()
            if result == '' then
                local profiles = GetPreference("UserPresetLobby")
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.Rule', 'no rule.')
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            else
                local profiles = GetPreference("UserPresetLobby")
                --AddChatText('rename> Profil?:'..table.KeyByIndex(profiles, PresetList:GetSelection())..' // selection:'..PresetList:GetSelection())
                SetPreference('UserPresetLobby.'..table.KeyByIndex(profiles, (PresetList:GetSelection()))..'.Rule', tostring(result))
                LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, PresetList:GetSelection()))
                GUI_Preset_InputBox:Destroy()
            end
        end
    end
end

----------------------
-- Other function --
function table.KeyByIndex(tablle, index)
    local num = -1
    for k, v in tablle do
        num = num + 1
        --LOG('k : '..k) -- Preset1 / Preset2
        --LOG('v : '..v) -- Error : Table value
        if num == index then
            return k
        end
    end
    return false -- or maybe call error() here
end

function GetModNameWithUid(uid)
    local allMods = Mods.AllMods()
    return allMods[uid].name
end
function GetModUidExist(uid)
    local allMods = Mods.AllMods()
    if allMods[uid].name ~= nil then
        return true
    else
        return false
    end
end
function GetModUIorNotUIWithUid(uid)
    local allMods = Mods.AllMods()
    return allMods[uid].ui_only
end


-------------------
-- Refresh List --
function LOAD_PresetProfils_For_PresetList()
    local profiles = GetPreference("UserPresetLobby")
    PresetList:DeleteAllItems()
    --
    if profiles then
        for k, v in profiles do
            PresetList:AddItem(tostring(profiles[k].PresetName))
        end
    end
    PresetList:AddItem('> New Preset')
end
function LOAD_PresetSettings_For_InfoList(Selected_Preset)
    local profiles = GetPreference("UserPresetLobby")
    InfoList:DeleteAllItems()
    --
    --if Selected_Preset == '' then
    --AddChatText('ERROR !, Selected_Preset is nul')
    --elseif Selected_Preset == nil then
    --AddChatText('ERROR !, Selected_Preset is nul')
    --else
    --AddChatText('ERROR !, Selected_Preset is :'..Selected_Preset)
    --end
    InfoList:AddItem('Preset Name : '..profiles[Selected_Preset].PresetName)
    InfoList:AddItem('FAF Title : '..'(not working for the moment)')--profiles[Selected_Preset].FAF_Title)
    InfoList:AddItem('Rule : '..profiles[Selected_Preset].Rule)
    
    if check_Map_Exist(profiles[Selected_Preset].MapPath) == true then
        InfoList:AddItem('Map : '..profiles[Selected_Preset].MapName)
    else
        InfoList:AddItem('Map : NOT AVAILABLE ('..profiles[Selected_Preset].MapName..')')
        --InfoList.test = Bitmap(InfoList, UIUtil.SkinnableFile('/game/idle_mini_icon/idle_icon.dds'))
        --LayoutHelpers.AtLeftTopIn(InfoList.test, InfoList, -12, 3*InfoList:GetRowHeight()) -- left, top
        --InfoList.test.Width:Set(InfoList:GetRowHeight())
        --InfoList.test.Height:Set(InfoList:GetRowHeight())
        --Tooltip.AddControlTooltip(InfoList.test, {text='Map : '..profiles[Selected_Preset].MapName, body='MAP NOT AVAILABLE !'})
        --InfoList:ModifyItem(3, ' Map : '..profiles[Selected_Preset].MapName)
    end
    
    
    
    if profiles[Selected_Preset].Mods then
        InfoList:AddItem('')
        InfoList:AddItem('Mod :')
        for k, v in profiles[Selected_Preset].Mods do
            --k = (uids), v = true
            if GetModUidExist(k) == false then
                InfoList:AddItem('- NOT AVAILABLE ('..k..')')
            else
                if GetModUIorNotUIWithUid(k) then
                    InfoList:AddItem('- '..GetModNameWithUid(k)..' [Mod UI]')
                else
                    InfoList:AddItem('- '..GetModNameWithUid(k))
                end
            end
        end
    end
    if profiles[Selected_Preset].UnitsRestricts then
        InfoList:AddItem('')
        InfoList:AddItem('Unit Restrictions :')
        for k, v in profiles[Selected_Preset].UnitsRestricts do
            --k = (uids), v = true
            InfoList:AddItem('- '..k)
        end
    end
    if profiles[Selected_Preset].Settings then
        InfoList:AddItem('')
        InfoList:AddItem('Settings :')
        for k, v in profiles[Selected_Preset].Settings do
            --k = (uids), v = true
            InfoList:AddItem('- '..k..' : '..tostring(v))
        end
    end
end

-- Create Preset in Pref --
function CREATE_PRESET_IN_PREF()
    GUI_PRESET_INPUT(0)
end

function applyCREATE_PRESET_IN_PREF(presetname)
    local profiles = GetPreference("UserPresetLobby")
    if not profiles then -- SI aucun profils, création du premier
        SetPreference('UserPresetLobby.Preset1.PresetName', tostring(presetname))
        SetPreference('UserPresetLobby.Preset1.MapName', tostring(MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile).name))
        SetPreference('UserPresetLobby.Preset1.FAF_Title', '')
        SetPreference('UserPresetLobby.Preset1.Rule', '')
        SetPreference('UserPresetLobby.Preset1.MapPath', tostring(gameInfo.GameOptions.ScenarioFile))
        SavePreferences()
    else
        local num = 0
        while profiles do
            num = num + 1
            if not GetPreference("UserPresetLobby.Preset"..num) then -- SI preset n'existe pas avec cette index suivant, crée le nouveau avec cette index
                --AddChatText('> UserPresetLobby.Preset'..num)
                SetPreference('UserPresetLobby.Preset'..num..'.PresetName', tostring(presetname))
                SetPreference('UserPresetLobby.Preset'..num..'.MapName', tostring(MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile).name))
                SetPreference('UserPresetLobby.Preset'..num..'.FAF_Title', '')
                SetPreference('UserPresetLobby.Preset'..num..'.Rule', '')
                SetPreference('UserPresetLobby.Preset'..num..'.MapPath', tostring(gameInfo.GameOptions.ScenarioFile))
                SavePreferences()
                break
            else
                --AddChatText('> UserPresetLobby.Preset'..num)
            end
        end
    end
    LOAD_PresetProfils_For_PresetList()
    PresetList:SetSelection(0)
    local profiles = GetPreference("UserPresetLobby")
    LOAD_PresetSettings_For_InfoList(table.KeyByIndex(profiles, 0))
end

-- Load or Save Preset and Set or Get to Lobby --
function check_Map_Exist(map_path)
    if DiskGetFileInfo(map_path) then
        return true
    else
        return false
    end
end

function LOAD_PRESET_IN_PREF() -- GET OPTIONS IN PRESET AND SET TO LOBBY
    local profiles = GetPreference("UserPresetLobby")
    if profiles then
        local Selected_Preset = table.KeyByIndex(profiles, PresetList:GetSelection())
        --AddChatText('> PRESET > Name : '..Selected_Preset) -- Preset1
        --AddChatText('> PRESET > PresetName : '..profiles[Selected_Preset].PresetName)
        -- Set PresetName in list on Preset GUI
        --AddChatText('> PRESET > MapName : '..profiles[Selected_Preset].MapName)
        -- Set MapName in text on Preset GUI
        --AddChatText('> PRESET > FAF_Title : '..profiles[Selected_Preset].FAF_Title)
        -- Set Title on FAF Client
        --AddChatText('> PRESET > Rule : '..profiles[Selected_Preset].Rule)
        -- Set Rule Title in TextBox
        if profiles[Selected_Preset].Rule == '' or profiles[Selected_Preset].Rule == 'no rule.' then
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem('No Rules: Click to add rules')
            GUI.RuleLabel:SetColors("FFCC00")
            GUI.RuleLabel:AddItem('')
        else
            wrapped = import('/lua/maui/text.lua').WrapText('Rule : '..profiles[Selected_Preset].Rule, GUI.RuleLabel.Width(), function(curText) return GUI.RuleLabel:GetStringAdvance(curText) end)
            GUI.RuleLabel:DeleteAllItems()
            GUI.RuleLabel:AddItem(wrapped[1] or '')
            GUI.RuleLabel:SetColors("B9BFB9")
            GUI.RuleLabel:AddItem(wrapped[2] or '')
        end
        RuleTitle_SendMSG()
        --AddChatText('> PRESET > MapPath : '..profiles[Selected_Preset].MapPath)
        if check_Map_Exist(profiles[Selected_Preset].MapPath) == true then
            SetGameOption('ScenarioFile', profiles[Selected_Preset].MapPath, false, true)
        else
            AddChatText('MAP NOT EXIST !')
        end
        --gameInfo.GameOptions['ScenarioFile'] = profiles[Selected_Preset].MapPath
        --Prefs.SetToCurrentProfile('LastScenario', profiles[Selected_Preset].MapPath)

        --

        if profiles[Selected_Preset].UnitsRestricts then
            local urestrict = {}
            for k, v in profiles[Selected_Preset].UnitsRestricts do
                --k = (restric name), v = true
                --AddChatText('> PRESET > UnitsRestricts : '..k..' // v : '..tostring(v)) -- > PRESET > UnitsRestricts : NAVAL // v : true
                --AddChatText('> PRESET > UnitsRestricts : '..k..' // '..tostring(profiles[Selected_Preset].UnitsRestricts[k])) -->>> PRESET UnitsRestricts : AIR = true
                table.insert(urestrict, k)
            end
            SetGameOption('RestrictedCategories', urestrict, false, true)
        else
            -- Clear Restricted
            SetGameOption('RestrictedCategories', {}, false, true)
        end

        --

        if profiles[Selected_Preset].Mods then
            selectedMods = {}
            for k, v in profiles[Selected_Preset].Mods do
                --k = (uids), v = true
                --AddChatText('> PRESET > Mods : '..k..' // v : '..tostring(v)) -->>> PRESET Mods : ['d5c7af75-6944-490b-b647-47dc1efffdc7'] = true
                if GetModUidExist(k) == true then
                    SetPreference('active_mods.'..k, true)
                    selectedMods[k] = true
                else
                    --LOG('>> LOAD_PRESET_IN_PREF > Missing Mod : '..tostring(k))
                end
            end
            OnModsChanged(selectedMods, true)
            --UpdateGame() -- Rafraichie les mods (utile)
        end

        --

        if profiles[Selected_Preset].Settings then
            for k, v in profiles[Selected_Preset].Settings do
                -- k = (setting name), v = (value name), profiles[Selected_Preset].Settings[k] = (value name)
                --AddChatText('> PRESET > Settings : '..k..' // v : '..tostring(v)) -->>> PRESET Settings : UnitCap = disabled
                --LOG('> PRESET > Settings : '..k..' // v : '..tostring(v)) -->>> PRESET Settings : UnitCap = disabled
                if k == "AllowObservers" then
                    SetGameOption("AllowObservers", v, false, true)
                else
                    SetGameOption(k, v, false, true)
                end
            end
        end

        --

        UpdateGame()
        GUI_Preset:Destroy()
    end
end

function SAVE_PRESET_IN_PREF() -- GET OPTIONS ON LOBBY AND SAVE TO PRESET
    local profiles = GetPreference("UserPresetLobby")

    local Selected_Preset = table.KeyByIndex(profiles, PresetList:GetSelection())
    --AddChatText('> PRESET > Name : '..Selected_Preset) -- Preset1

    local Preset_Name = profiles[Selected_Preset].PresetName or 'ERROR, Set preset name here' -- Nom du PresetLobby
    local Title_FAF = profiles[Selected_Preset].Title_FAF or '' -- Title is for FAF Client title in "Find Games" tabs
    local Rule_Text = GUI.RuleLabel:GetItem(0)..GUI.RuleLabel:GetItem(1)
    if Rule_Text == 'No Rules: Click to add rules' then
        Rule_Text = 'no rule.'
    end
    Rule_Text = string.gsub(Rule_Text, 'Rule : ', '') or profiles[Selected_Preset].Rule_Text or '' -- Rule text showing in top of Lobby

    SetPreference('UserPresetLobby.'..Selected_Preset, {}) -- Delete all value

    SetPreference('UserPresetLobby.'..Selected_Preset..'.PresetName', tostring(Preset_Name))
    SetPreference('UserPresetLobby.'..Selected_Preset..'.MapName', tostring(MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile).name))
    SetPreference('UserPresetLobby.'..Selected_Preset..'.FAF_Title', tostring(Title_FAF))
    SetPreference('UserPresetLobby.'..Selected_Preset..'.Rule', tostring(Rule_Text))

    for k, v in gameInfo.GameOptions do
        if k == 'ScenarioFile' then -- MAP
            --AddChatText('<<< gameInfo.GameOptions : '..k..' = '..tostring(gameInfo.GameOptions[k])) --EX: gameInfo.GameOptions : UnitCap = 500
            SetPreference('UserPresetLobby.'..Selected_Preset..'.MapPath', gameInfo.GameOptions[k])

        elseif k == 'AllowObservers' then
            SetPreference('UserPresetLobby.'..Selected_Preset..'.Settings.AllowObservers', gameInfo.GameOptions[k])

        elseif k == 'RestrictedCategories' then -- RESTRICTED UNITS
            for kk, vv in gameInfo.GameOptions['RestrictedCategories'] do
                --AddChatText('<<< ... RestrictedCategories : '..kk..' = '..tostring(gameInfo.GameOptions['RestrictedCategories'][kk])) --EX: ... RestrictedCategories : 2 = SERAPHIM
                SetPreference('UserPresetLobby.'..Selected_Preset..'.UnitsRestricts.'..vv, true) -- Enregistre les Restriction dans le Game.prefs
                --SetPreference('UserPresetLobby.'..Selected_Preset..'.UnitsRestricts.'..kk, tostring(gameInfo.GameOptions['RestrictedCategories'][kk])) -- Enregistre les Restriction dans le Game.prefs
                --SetPreference('UserPresetLobby.'..Selected_Preset..'.UnitsRestricts', tostring(gameInfo.GameOptions[kk])) -- Enregistre les Restriction dans le Game.prefs
            end

        elseif k == 'Mods' then -- MODS
            --for kk, vv in gameInfo.GameOptions['Mods'] do
            --AddChatText('<<< ... Mods : '..kk..' = '..tostring(gameInfo.GameOptions['Mods'][kk]))
            --SetPreference('UserPresetLobby.'..Selected_Preset..'.UnitsRestricts.'..k, tostring(gameInfo.GameOptions[k]))
            --end

        else -- SETTINGS
            --AddChatText('<<< gameInfo.GameOptions : '..k..' = '..tostring(gameInfo.GameOptions[k])) --EX: gameInfo.GameOptions : UnitCap = 500
            SetPreference('UserPresetLobby.'..Selected_Preset..'.Settings.'..k, gameInfo.GameOptions[k]) -- Enregistre les Options dans le Game.prefs
        end
    end

    local mods = Mods.GetGameMods(gameInfo.GameMods)
    local modsUI = Mods.GetUiMods()
    local nummods = 0
    local uids = ""
    for k, v in mods do
        nummods = nummods + 1
        --AddChatText('Mod : '..v.name)
        --LOG('> k : '..k)
        SetPreference('UserPresetLobby.'..Selected_Preset..'.Mods.'..v.uid, true)
    end
    for k, v in modsUI do
        nummods = nummods + 1
        --AddChatText('Mod UI : '..v.name)
        --LOG('> k : '..k)
        SetPreference('UserPresetLobby.'..Selected_Preset..'.Mods.'..v.uid, true)
    end
    --LOG('> Num mods : '..nummods)
end

-- Show only available colours.

-- Get the true Index Color --

-- Find the key for the given value in a table.
-- Nil keys are not supported.
function indexOf(table, needle)
    for k, v in table do
        if v == needle then
            return k
        end
    end
    return nil
end

function Get_IndexColor_by_AvailableTable(index_limit, slot)
    for k, v in BASE_ALL_Color do
        if v == Avail_Color[slot][index_limit] then
            return k
        end
    end
    return index_limit
end

function Get_IndexColor_by_CompleteTable(index_limit, slot)
    for k, v in Avail_Color[slot] do
        if v == BASE_ALL_Color[index_limit] then
            return k
        end
    end
    return index_limit
end

-- Create the Available Color Table and Recreate the ComboBox --
function Check_Availaible_Color(self, slot)
    local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
    --
    Avail_Color[slot] = {}
    local num = 0
    --// CHECK COLOR ALREADY USED AND RECREATE TABLE WITH COLOR AVAILAIBLE ONLY \\
    for k, v in BASE_ALL_Color do
        local found = false
        for ii = 1, LobbyComm.maxPlayerSlots do
            if gameInfo.PlayerOptions[ii].PlayerColor then
                if slot ~= ii then
                    if gameInfo.PlayerOptions[ii].PlayerColor == k then
                        found = true
                        break
                    end
                end
            end
        end
        
        if found ~= true then
            num = num + 1
            Avail_Color[slot][num] = BASE_ALL_Color[k]
        end
        
    end
    --
    if num == 0 then
        return
    end
    --
    local yy = Get_IndexColor_by_CompleteTable(gameInfo.PlayerOptions[slot].PlayerColor, slot)
    --
    GUI.slots[slot].color:Destroy()
    -- TODO: There should be no need to rebuild the whole UI control here.
    GUI.slots[slot].color = BitmapCombo(GUI.slots[slot], Avail_Color[slot], yy, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
    LayoutHelpers.AtLeftIn(GUI.slots[slot].color, GUI.panel, (161+264)+11)
    LayoutHelpers.AtVerticalCenterIn(GUI.slots[slot].color, GUI.slots[slot], 9)
    GUI.slots[slot].color.Width:Set(59)
    GUI.slots[slot].color.row = slot
    --
    GUI.slots[slot].color.OnClick = function(self, index)
        local indexx = Get_IndexColor_by_AvailableTable(index, slot)
        --
        Tooltip.DestroyMouseoverDisplay()
        if not lobbyComm:IsHost() then
            lobbyComm:SendData(hostID, { Type = 'RequestColor', Color = indexx, Slot = self.row } )
            gameInfo.PlayerOptions[self.row].PlayerColor = indexx
            gameInfo.PlayerOptions[self.row].ArmyColor = indexx
            UpdateGame()
        else
            if IsColorFree(indexx) then
                lobbyComm:BroadcastData( { Type = 'SetColor', Color = indexx, Slot = self.row } )
                gameInfo.PlayerOptions[self.row].PlayerColor = indexx
                gameInfo.PlayerOptions[self.row].ArmyColor = indexx
                UpdateGame()
            else
                self:SetItem( gameInfo.PlayerOptions[self.row].PlayerColor )
            end
        end
    end 
    GUI.slots[slot].color.OnEvent = GUI.slots[slot].name.OnEvent
    Tooltip.AddControlTooltip(GUI.slots[slot].color, 'lob_color')
    GUI.slots[slot].color.row = slot
	--
	if IsLocallyOwned(slot) then
		if gameInfo.PlayerOptions[slot]['Ready'] then
			GUI.slots[slot].color:Disable()
		else
			GUI.slots[slot].color:Enable()
		end
	else
		GUI.slots[slot].color:Disable()
	end
end

-- Changelog dialog
function Need_Changelog()
	local Changelog = import('/lua/ui/lobby/changelog.lua').changelog
	local Last_Changelog_Version = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0
	local result = false
	for i, d in Changelog do
		if Last_Changelog_Version < d.version then
			result = true
			break
		end
	end
	return result
end

function GUI_Changelog()
    GROUP_Changelog = Group(GUI)
    LayoutHelpers.AtCenterIn(GROUP_Changelog, GUI)
    GROUP_Changelog.Depth:Set(GetFrame(GROUP_Changelog:GetRootFrame():GetTargetHead()):GetTopmostDepth() + 1)
    local background = Bitmap(GROUP_Changelog, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/optionlobby.dds'))
    GROUP_Changelog.Width:Set(background.Width)
    GROUP_Changelog.Height:Set(background.Height)
    LayoutHelpers.FillParent(background, GROUP_Changelog)
    local dialog2 = Group(GROUP_Changelog)
    dialog2.Width:Set(526)
    dialog2.Height:Set(350)
    LayoutHelpers.AtCenterIn(dialog2, GROUP_Changelog)
    -- Title --
    local text0 = UIUtil.CreateText(dialog2, LOC("<LOC lobui_0412>"), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(text0, dialog2, 0)
    LayoutHelpers.AtTopIn(text0, dialog2, 10)
    -- Info List --
    InfoList = ItemList(dialog2)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    InfoList:SetColors(nil, "00000000")
    InfoList.Width:Set(498)
    InfoList.Height:Set(260)
    LayoutHelpers.AtLeftIn(InfoList, dialog2, 10)
	LayoutHelpers.AtRightIn(InfoList, dialog2, 26)
    LayoutHelpers.AtTopIn(InfoList, dialog2, 38)
    UIUtil.CreateLobbyVertScrollbar(InfoList)
	InfoList.OnClick = function(self)
	end
	-- See only new Changelog by version
	local Changelog = import('/lua/ui/lobby/changelog.lua')
	local Last_Changelog_Version = Prefs.GetFromCurrentProfile('LobbyChangelog') or 0
	for i, d in Changelog.changelog do
		if Last_Changelog_Version < d.version then
			InfoList:AddItem(d.name)
			for k, v in d.description do
				InfoList:AddItem(v)
			end
			InfoList:AddItem('')
		end
	end
    -- OK button --
    local OkButton = UIUtil.CreateButtonWithDropshadow(dialog2, '/BUTTON/medium/', "Ok", -1)
	LayoutHelpers.AtLeftIn(OkButton, dialog2, 0)
    LayoutHelpers.AtBottomIn(OkButton, dialog2, 10)
    OkButton.OnClick = function(self)
        Prefs.SetToCurrentProfile('LobbyChangelog', Changelog.last_version)
		GROUP_Changelog:Destroy()
    end
    -- Credit --
    local text99 = UIUtil.CreateText(dialog2, 'Xinnony', 9, 'Arial', true)
    text99:SetColor('808080')
    LayoutHelpers.AtRightIn(text99, dialog2, 0)
    LayoutHelpers.AtBottomIn(text99, dialog2, 2)
end
