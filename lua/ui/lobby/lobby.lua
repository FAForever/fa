--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Chris Blackwell
--* Summary: Game selection UI
--*
--* Copyright © 2005 Gas Powered Games, Inc. All rights reserved.
--*****************************************************************************

local GameVersion = import('/lua/version.lua').GetVersion
local UIUtil = import('/lua/ui/uiutil.lua')
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local Prefs = import('/lua/user/prefs.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local Group = import('/lua/maui/group.lua').Group
local RadioButton = import('/lua/ui/controls/radiobutton.lua').RadioButton
local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
local ResourceMapPreview = import('/lua/ui/controls/resmappreview.lua').ResourceMapPreview
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup
local InputDialog = import('/lua/ui/controls/popups/inputdialog.lua').InputDialog
local Slider = import('/lua/maui/slider.lua').Slider
local PlayerData = import('/lua/ui/lobby/data/playerdata.lua').PlayerData
local GameInfo = import('/lua/ui/lobby/data/gamedata.lua')
local WatchedValueArray = import('/lua/ui/lobby/data/watchedvalue/watchedvaluearray.lua').WatchedValueArray
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local LobbyComm = import('/lua/ui/lobby/lobbyComm.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Mods = import('/lua/mods.lua')
local FactionData = import('/lua/factions.lua')
local Text = import('/lua/maui/text.lua').Text
local Trueskill = import('/lua/ui/lobby/trueskill.lua')
local round = import('/lua/ui/lobby/trueskill.lua').round
local Player = import('/lua/ui/lobby/trueskill.lua').Player
local Rating = import('/lua/ui/lobby/trueskill.lua').Rating
local Teams = import('/lua/ui/lobby/trueskill.lua').Teams
local EscapeHandler = import('/lua/ui/dialogs/eschandler.lua')

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

local connectedTo = {} -- by UID
CurrentConnection = {} -- by Name
ConnectionEstablished = {} -- by Name
ConnectedWithProxy = {} -- by UID

-- The set of available colours for each slot. Each index in this table contains the set of colour
-- values that may appear in its combobox. Keys in the sub-tables are indexes into allColours,
-- values are the colour values.
availableColours = {}

local availableMods = {} -- map from peer ID to set of available mods; each set is a map from "mod id"->true
local selectedMods = nil

local commandQueueIndex = 0
local commandQueue = {}

local autoKick = true

local lastUploadedMap = nil

local CPU_Benchmarks = {} -- Stores CPU benchmark data

local function parseCommandlineArguments()
    local function GetCommandLineArgOrDefault(argname, default)
        local arg = GetCommandLineArg(argname, 1)
        if arg then
            return arg[1]
        end

        return default
    end

    return {
        PrefLanguage = tostring(string.lower(GetCommandLineArgOrDefault("/country", "world"))),
        initName = GetCommandLineArgOrDefault("/init", ""),
        ratingColor = GetCommandLineArgOrDefault("/ratingcolor", "ffffffff"),
        numGames = tonumber(GetCommandLineArgOrDefault("/numgames", 0)),
        playerMean = tonumber(GetCommandLineArgOrDefault("/mean", 1500)),
        playerDeviation = tonumber(GetCommandLineArgOrDefault("/deviation", 500)),
    }
end
local argv = parseCommandlineArguments()

local playerRating = math.floor( Trueskill.round2((argv.playerMean - 3 * argv.playerDeviation) / 100.0) * 100 )

local teamTooltips = {
    'lob_team_none',
    'lob_team_one',
    'lob_team_two',
    'lob_team_three',
    'lob_team_four',
    'lob_team_five',
    'lob_team_six',
}

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

-- Instruct a player to unset their "ready" status. Should be called only by the host.
local function setPlayerNotReady(slot)
    local slotOptions = gameInfo.PlayerOptions[slot]
    if slotOptions.Ready then
        if not IsLocallyOwned(slot) then
            lobbyComm:SendData(slotOptions.OwnerID, {Type = 'SetPlayerNotReady', Slot = slot})
        end
        slotOptions.Ready = false
    end
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

    HostConvertPlayerToObserver(toOpts.OwnerID, moveTo, false) -- Move Slot moveTo to Observer
    HostTryMovePlayer(fromOpts.OwnerID, moveFrom, moveTo) -- Move Player moveFrom to Slot moveTo
    HostConvertObserverToPlayer(toOpts.OwnerID, FindObserverSlotForID(toOpts.OwnerID), moveFrom)
    SendSystemMessage(fromOpts.PlayerName..' has switched with '..toOpts.PlayerName, 'switch')
end

--- Get a PlayerData object for the local player, configured using data from their profile.
function GetLocalPlayerData()
    return PlayerData(
        {
            PlayerName = localPlayerName,
            OwnerID = localPlayerID,
            Human = true,
            PlayerColor = Prefs.GetFromCurrentProfile('LastColor'),
            Faction = Prefs.GetFromCurrentProfile('LastFaction'),
            PL = playerRating,
            RC = argv.ratingColor,
            NG = argv.numGames,
            MEAN = argv.playerMean,
            DEV = argv.playerDeviation,
            Country = argv.PrefLanguage,
        }
    )
end

function GetAIPlayerData(name, AIPersonality)
    return PlayerData(
        {
            OwnerID = hostID,
            PlayerName = name,
            Ready = true,
            Human = false,
            AIPersonality = AIPersonality,
        }
    )
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
                HostConvertObserverToPlayer(hostID, FindObserverSlotForID(localPlayerID), slot)
            else
                lobbyComm:SendData(
                    hostID,
                    {
                        Type = 'RequestConvertToPlayer',
                        ObserverSlot = FindObserverSlotForID(localPlayerID),
                        PlayerSlot = slot
                    }
                )
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
        local playerInfo = gameInfo.PlayerOptions[slot]
        if playerInfo.Human then
            HostConvertPlayerToObserver(playerInfo.OwnerID, slot)
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
        -- We're adding an AI of some sort.
        if lobbyComm:IsHost() then
            HostTryAddPlayer(hostID, slot, GetAIPlayerData(name, key))
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
    gameInfo = GameInfo.CreateGameInfo(LobbyComm.maxPlayerSlots)
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
        Reset()

        if GUI then
            WARN('CreateLobby called but I already have one setup...?')
            GUI:Destroy()
        end

        GUI = UIUtil.CreateScreenGroup(over, "CreateLobby ScreenGroup")

        GUI.exitBehavior = exitBehavior

        GUI.optionControls = {}
        GUI.slots = {}

        -- Set up the base escape handler first: want this one at the bottom of the stack.
        GUI.exitLobbyEscapeHandler = function()
            WARN("Lobby escape handler called")
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
        EscapeHandler.PushEscapeHandler(GUI.exitLobbyEscapeHandler)

        GUI.connectdialog = UIUtil.ShowInfoDialog(GUI, Strings.TryingToConnect, Strings.AbortConnect, ReturnToMenu)
        -- Prevent the dialog from being closed due to user action.
        GUI.connectdialog.OnEscapePressed = function() end
        GUI.connectdialog.OnShadowClicked = function() end

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

-- These two are now exclusively used as an amusing hack to control synchronous replay watching.
function SetHasSupcom(cmd)
    if IsSyncReplayServer then
        if cmd == 0 then
            SessionResume()
        elseif cmd == 1 then
            SessionRequestPause()
        end
    end
end

function SetHasForgedAlliance(speed)
    if IsSyncReplayServer then
        if GetGameSpeed() ~= speed then
            SetGameSpeed(speed)
        end
    end
end

-- TODO: These functions are dumb. We have these things called "hashmaps".
function FindSlotForID(id)
    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.OwnerID == id and player.Human then
            return k
        end
    end
    return nil
end

function FindNameForID(id)
    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.OwnerID == id and player.Human then
            return player.PlayerName
        end
    end
    return nil
end

function FindIDForName(name)
    for k, player in gameInfo.PlayerOptions:pairs() do
        if player.PlayerName == name and player.Human then
            return player.OwnerID
        end
    end
    return nil
end

function FindObserverSlotForID(id)
    for k, observer in gameInfo.Observers:pairs() do
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

-- update the data in a player slot
-- TODO: With lazyvars, this function should be eliminated. Lazy-value-callbacks should be used
-- instead to incrementaly update things.
function SetSlotInfo(slotNum, playerInfo)
    -- Remove the ConnectDialog. It probably makes more sense to do this when we get the game state.
	if GUI.connectdialog then
		GUI.connectdialog:Close()
        GUI.connectdialog = nil

        -- Among other things, this clears uimain's override escape handler, allowing our escape
        -- handler manager to work.
        MenuCommon.MenuCleanup()

        -- Changelog, if necessary.
        if Need_Changelog() then
            GUI_Changelog()
        end
    end

	local isLocallyOwned = IsLocallyOwned(slotNum)
    if isLocallyOwned then
        if gameInfo.PlayerOptions[slotNum].Ready then
            DisableSlot(slotNum, true)
        else
            EnableSlot(slotNum)
        end
    else
        DisableSlot(slotNum)
    end

    local hostKey
    if lobbyComm:IsHost() then
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    local slot = GUI.slots[slotNum]

    -- These states are used to select the appropriate strings with GetSlotMenuTables.
    local slotState
    if not playerInfo.Human then
        slot.ratingGroup:Hide()
        slotState = 'ai'
    elseif not isLocallyOwned then
        slotState = 'player'
    else
        slotState = nil
    end

    slot.name:ClearItems()

    if slotState then
        slot.name:Enable()
        local slotKeys, slotStrings = GetSlotMenuTables(slotState, hostKey)
        slot.name.slotKeys = slotKeys
        if lobbyComm:IsHost() and slotState == 'ai' then
            Tooltip.AddComboTooltip(slot.name, GetAITooltipList())
        else
            Tooltip.RemoveComboTooltip(slot.name)
        end
        if table.getn(slotKeys) > 0 then
            slot.name:AddItems(slotStrings)
            slot.name:Enable()
        else
            slot.name.slotKeys = nil
            slot.name:Disable()
        end
    else
        -- no slotState indicate this must be ourself, and you can't do anything to yourself
        slot.name.slotKeys = nil
        slot.name:Disable()
    end

    slot.ratingGroup:Show()
    --if playerInfo.MEAN == '-9999' then -- The player is a Smurf (Banned)
    --GUI.slots[slot].ratingText:SetText('Banned')
    --GUI.slots[slot].ratingText:SetColor('Crimson') --= --dc143c
    --else
    slot.ratingText:SetText(playerInfo.PL)
    --end
    slot.ratingText:SetColor(playerInfo.RC)

    slot.numGamesGroup:Show()
    slot.numGamesText:SetText(playerInfo.NG)

    slot.name:Show()
    -- Color the Name in Slot by State
    if slotState == 'ai' then
        slot.name:SetTitleTextColor("dbdbb9") -- Beige Color for AI
        slot.name._text:SetFont('Arial Gras', 12)
    elseif FindSlotForID(hostID) == slotNum then
        slot.name:SetTitleTextColor("ffc726") -- Orange Color for Host
        slot.name._text:SetFont('Arial Gras', 15)
    elseif slotState == 'player' then
        slot.name:SetTitleTextColor("64d264") -- Green Color for Players
        slot.name._text:SetFont('Arial Gras', 15)
    elseif isLocallyOwned then
        slot.name:SetTitleTextColor("6363d2") -- Blue Color for You
        slot.name._text:SetFont('Arial Gras', 15)
    else
        slot.name:SetTitleTextColor(UIUtil.fontColor) -- Normal Color for Other
        slot.name._text:SetFont('Arial Gras', 12)
    end

    local playerName = playerInfo.PlayerName

    --\\ Stop - Color the Name in Slot by State
    if wasConnected(playerInfo.OwnerID) or isLocallyOwned then
        slot.name:SetTitleText(playerName)
        slot.name._text:SetFont('Arial Gras', 15)
        if not table.find(ConnectionEstablished, playerName) then
            if playerInfo.Human and not isLocallyOwned then
                if table.find(ConnectedWithProxy, playerInfo.OwnerID) then
                    AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", playerName)..' (FAF Proxy)', "Engine0004")
                else
                    AddChatText(LOCF("<LOC Engine0004>Connection to %s established.", playerName), "Engine0004")
                end

                table.insert(ConnectionEstablished, playerName)
                for k, v in CurrentConnection do -- Remove PlayerName in this Table
                    if v == playerName then
                        CurrentConnection[k] = nil
                        break
                    end
                end
            end
        end
    else
        -- TODO: Localise!
        slot.name:SetTitleText('Connecting to ... ' .. playerName)
        slot.name._text:SetFont('Arial Gras', 11)
    end

    slot.faction:Show()
    slot.faction:SetItem(playerInfo.Faction)

    slot.color:Show()
    Check_Availaible_Color(slotNum)

    slot.team:Show()
    slot.team:SetItem(playerInfo.Team)

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', string.format("faction %s %d %s", playerName, slotNum, playerInfo.Faction))
        GpgNetSend('PlayerOption', string.format("color %s %d %s", playerName, slotNum, playerInfo.PlayerColor))
        GpgNetSend('PlayerOption', string.format("team %s %d %s", playerName, slotNum, playerInfo.Team))
        GpgNetSend('PlayerOption', string.format("startspot %s %d %s", playerName, slotNum, slotNum))
    end

    UIUtil.setVisible(slot.ready, playerInfo.Human and not singlePlayer)
    slot.ready:SetCheck(playerInfo.Ready, true)

    if isLocallyOwned and playerInfo.Human then
        Prefs.SetToCurrentProfile('LastColor', playerInfo.PlayerColor)
        Prefs.SetToCurrentProfile('LastFaction', playerInfo.Faction)
    end

    -- Show the player's nationality
    if not playerInfo.Country then
        slot.KinderCountry:Hide()
    else
        slot.KinderCountry:Show()
        slot.KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..playerInfo.Country..'.dds'))
        Country_GetTooltipValue(playerInfo.Country, slotNum)
        Country_AddControlTooltip(slot.KinderCountry, 0, slotNum)
    end

    -- Disable team selection if "auto teams" is controlling it.
    local autoTeams = gameInfo.GameOptions['AutoTeams']
    UIUtil.setEnabled(slot.team,
        autoTeams == 'none' or
        (autoTeams == 'manual' and lobbyComm:IsHost())
    )

    -- Set the CPU bar
    SetSlotCPUBar(slotNum, playerInfo)
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
    for id, player in gameInfo.PlayerOptions:pairs() do
        if player.PlayerColor == colorIndex then
            return false
        end
    end

    return true
end

function GetPlayerCount()
    local numPlayers = 0
    for k,player in gameInfo.PlayerOptions:pairs() do
        if player.Team >= 0 then
            numPlayers = numPlayers + 1
        end
    end
    return numPlayers
end

local function GetPlayersNotReady()
    local notReady = false
    for k,v in gameInfo.PlayerOptions:pairs() do
        if v.Human and not v.Ready then
            if not notReady then
                notReady = {}
            end
            table.insert(notReady, v.PlayerName)
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
    for index, player in gameInfo.PlayerOptions:pairs() do
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
        local playerInfo = gameInfo.PlayerOptions[i]
        local player = Player.create(playerInfo.PlayerName,
                                     Rating.create(playerInfo.MEAN or 1500, playerInfo.DEV or 500))

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

        local AutoTeams = gameInfo.GameOptions['AutoTeams']
        local teams = {}
        for i = 1, numAvailStartSpots do
            if gameInfo.ClosedSlots[i] == nil then
                local team = nil

                if AutoTeams == 'lvsr' then
                    local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                    local markerPos = GUI.mapView.startPositions[i].Left()

                    if markerPos < midLine then
                        team = 2
                    else
                        team = 3
                    end
                elseif AutoTeams == 'tvsb' then
                    local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                    local markerPos = GUI.mapView.startPositions[i].Top()

                    if markerPos < midLine then
                        team = 2
                    else
                        team = 3
                    end
                elseif AutoTeams == 'pvsi' then
                    if math.mod(i, 2) ~= 0 then
                        team = 2
                    else
                        team = 3
                    end
                elseif AutoTeams == 'manual' then
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
            local playerInfo = gameInfo.PlayerOptions[i]
            if playerInfo then
                table.insert(ratingTable, { pos=i, rating = playerInfo.MEAN - playerInfo.DEV * 3 })
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

        -- add 100 random compositions and keep 3 with at least 95% of best quality
        for i=1, 100 do
            r = autobalance_random(ratingTable, teams)
            q = autobalance_quality(r)

            if(q > best.quality*0.95) then
                table.insert(results, {quality=q, result=r})

                if(table.getsize(results) > 4) then break end
            end
        end

        results = table.shuffle(results)
        best = table.remove(results, 1)
        gameInfo.GameOptions['Quality'] = best.quality

        -- TODO: LazyVars may very well have killed this. *ahem*.
        local orgPlayerOptions = table.deepcopy(gameInfo.PlayerOptions)
        for k, p in gameInfo.PlayerOptions:pairs() do
            orgPlayerOptions[k] = table.deepcopy(p)
        end

        gameInfo.PlayerOptions = WatchedValueArray(LobbyComm.maxPlayerSlots)
        for _, r in best.result do
            local slot = r['slot']
            local player = r['player']
            local team = r['team']
            gameInfo.PlayerOptions[slot] = table.deepcopy(orgPlayerOptions[player])
            -- TODO: Is this actually a field we want?
            gameInfo.PlayerOptions[slot].StartSpot = slot
            gameInfo.PlayerOptions[slot].Team = team
        end
    end
end

local function AssignAutoTeams(gameInfo)
    if gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
        local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                local markerPos = GUI.mapView.startPositions[i].Left()
                if markerPos < midLine then
                    SetPlayerOption(i, "Team", 2, true)
                else
                    SetPlayerOption(i, "Team", 3, true)
                end
            end
        end
    elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
        local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then
                local markerPos = GUI.mapView.startPositions[i].Top()
                if markerPos < midLine then
                    SetPlayerOption(i, "Team", 2, true)
                else
                    SetPlayerOption(i, "Team", 3, true)
                end
            end
        end
    elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' or gameInfo.GameOptions['RandomMap'] ~= 'Off' then
        for i = 1, LobbyComm.maxPlayerSlots do
            if not gameInfo.ClosedSlots[i] and gameInfo.PlayerOptions[i] then

                if math.mod(i, 2) ~= 0 then
                    SetPlayerOption(i, "Team", 2, true)
                else
                    SetPlayerOption(i, "Team", 3, true)
                end
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
    for index, player in gameInfo.PlayerOptions:pairs() do
        if not player.Human then
            local playerFaction = player.Faction
            local factionNames = aiNames[FactionData.Factions[playerFaction].Key]
            local ranNum
            repeat
                ranNum = math.random(1, table.getn(factionNames))
            until nameSlotsTaken[playerFaction][ranNum] == nil
            nameSlotsTaken[playerFaction][ranNum] = true
            player.PlayerName = factionNames[ranNum] .. " (" .. player.PlayerName .. ")"
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

function SendSystemMessage(text, id)
    local data = {
        Type = "SystemMessage",
        Text = text,
        Id = id or '',
    }
    lobbyComm:BroadcastData(data)
    AddChatText(data.Text)
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
                    if not gameInfo.PlayerOptions[i].Ready then
                        EnableSlot(i)
                    end
                end
            else
                if not GUI.slots[i].closed then
                    if lobbyComm:IsHost() and gameInfo.PlayerOptions[i] then
                        local info = gameInfo.PlayerOptions[i]
                        if info.Human then
                            HostConvertPlayerToObserver(info.OwnerID, i)
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
    for slot, player in gameInfo.PlayerOptions:pairs() do
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


    if totalHumanPlayers == 0 and gameInfo.Observers:isEmpty() then
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
                if gameInfo.PlayerOptions[i].Team ~= 1 then
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
        for k, observer in gameInfo.Observers:pairs() do
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
                for k,observer in gameInfo.Observers:pairs() do
                    lobbyComm:EjectPeer(observer.OwnerID, "KickedByHost")
                end
                gameInfo.Observers = WatchedValueArray(LobbyComm.maxPlayerSlots)
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
        if gameInfo.GameOptions['RandomMap'] ~= 'Off' then
            autoRandMap = true
            autoMap()
        end

        SetFrontEndData('NextOpBriefing', nil)
        -- assign random factions just as game is launched
        AssignRandomFactions(gameInfo)
        AssignRandomStartSpots(gameInfo)
        --assign the teams just before launch
        AssignAutoTeams(gameInfo)
        randstring = randomString(16, "%l%d")

        gameInfo.GameOptions['ReplayID'] = randstring
        AssignAINames(gameInfo)
        local allRatings = {}
        for k,v in gameInfo.PlayerOptions:pairs() do
            if v.Human and v.PL then
                allRatings[v.PlayerName] = v.PL
            end
        end
        gameInfo.GameOptions['Ratings'] = allRatings

        -- Eliminate the WatchedValue structures.
        gameInfo = GameInfo.Flatten(gameInfo)

        -- Tell everyone else to launch and then launch ourselves.
        -- TODO: Sending gamedata here isn't necessary unless lobbyComm is fucking stupid and allows
        -- out-of-order message delivery.
        lobbyComm:BroadcastData({ Type = 'Launch', GameInfo = gameInfo })

        -- set the mods
        gameInfo.GameMods = Mods.GetGameMods(gameInfo.GameMods)

        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
        SetWindowedLobby(false)

        table.print(gameInfo)
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

-- Refresh (with a sledgehammer) all the items in the observer list.
local function refreshObserverList()
    GUI.observerList:DeleteAllItems()

    for slot, observer in gameInfo.Observers:pairs() do
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
    -- This allows us to assume the existence of UI elements throughout.
    if not GUI.uiCreated then
        WARN(debug.traceback(nil, "UpdateGame() pointlessly called before UI creation!"))
        return
    end

    local scenarioInfo = nil

    if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile ~= "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)

        if scenarioInfo and scenarioInfo.map and scenarioInfo.map ~= '' then
            local mods = Mods.GetGameMods(gameInfo.GameMods)
            PrefetchSession(scenarioInfo.map, mods, true)
        else
            AlertHostMapMissing()
        end

        GUI.mapView:SetScenario(scenarioInfo)
    end


    local isHost = lobbyComm:IsHost()

    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        local playerOptions = gameInfo.PlayerOptions[localPlayerSlot]

        -- Disable some controls if the user is ready.
        local notReady = not playerOptions.Ready

        UIUtil.setEnabled(GUI.becomeObserver, notReady)
        -- This button is enabled for all non-host players to view the configuration, and for the
        -- host to select presets (rather confusingly, one object represents both potential buttons)
        UIUtil.setEnabled(GUI.restrictedUnitsOrPresetsBtn, not isHost or notReady)

        UIUtil.setEnabled(GUI.LargeMapPreview, notReady)
        UIUtil.setEnabled(GUI.factionSelector, notReady)

        -- Set the info in a Slot
        -- TODO: Since these stats are all constants, we should figure out the right place to do this
        -- job once.
        if not playerOptions.MEAN then
            local options = {
                MEAN = argv.playerMean,
                DEV = argv.playerDeviation,
                COUNTRY=argv.PrefLanguage,
                PL = playerRating,
                RC = argv.ratingColor,
                NG= argv.numGames,
            }

            SetPlayerOptions(localPlayerSlot, options, true)
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
        GUI.mapView:SetScenario(scenarioInfo)
        ShowMapPositions(GUI.mapView, scenarioInfo, numPlayers)
    else
        GUI.mapView:Clear()
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
        UIUtil.setEnabled(GUI.defaultOptions, playerNotReady)
        UIUtil.setEnabled(GUI.randMap, playerNotReady)

        -- Launch button enabled if everyone is ready.
        UIUtil.setEnabled(GUI.launchGameButton, singlePlayer or not playerNotReady)
    end

    GUI.allowObservers:SetCheck(gameInfo.GameOptions.AllowObservers, true)

    RefreshOptionDisplayData(scenarioInfo)

    -- Update the map background to reflect the possibly-changed map.
    if Prefs.GetFromCurrentProfile('LobbyBackground') == 4 then
        ChangeBackgroundLobby()
    end

    -- Set the map name at the top right corner in lobby
    if scenarioInfo.name then
        SetText2(GUI.MapNameLabel, scenarioInfo.name, 20)
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
                SetText2(GUI.GameQualityLabel, "Game quality : "..quality.."%", 20)
            else
                SetText2(GUI.GameQualityLabel, "Game quality N/A", 20)
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

    -- If the large map is shown, update it.
    RefreshLargeMap()
end

-- Update our local gameInfo.GameMods from selected map name and selected mods, then
-- notify other clients about the change.
local function HostUpdateMods(newPlayerID, newPlayerName)
    if lobbyComm:IsHost() then
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
            WARN("Sending ModsChanged...")
            lobbyComm:BroadcastData { Type = "ModsChanged", GameMods = gameInfo.GameMods }
            WARN("Sent ModsChanged")

            local mods = {}
            for uid, _ in gameInfo.GameMods do
                table.insert(mods, uid)
            end

            GpgNetSend('GameMods', unpack(mods))

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
            -- TODO: Verify this functionality
            if FindNameForID(newPlayerID) then
                AddChatText(FindNameForID(newPlayerID)..' kicked because he does not have this mod : '..modnames)
            else
                if newPlayerName then
                    AddChatText(newPlayerName..' kicked because he does not have this mod : '..modnames)
                else
                    AddChatText('The last player is kicked because he does not have this mod : '..modnames)
                end
            end
            lobbyComm:EjectPeer(newPlayerID, reason)
        end
    end
end

-- Holds some utility functions to do with game option management.
local OptionUtils = {
    -- Expresses which options are acceptable for a game to be considered ranked.
    -- A game is deemed "ranked" if, for every key k in gameOptions:
    --    RANKED_OPTIONS[k] == nil  or
    --    RANKED_OPTIONS[k] contains gameOptions[k]
    RANKED_OPTIONS = {
        Victory = {'demoralization'},
        CheatsEnabled = {'false'},
        CivilianAlliance = {'enemy'},
        GameSpeed = {'normal'},
        FogOfWar = {'explored'},
        UnitCap = {'1000'},
        PrebuiltUnits = {'Off'},
        NoRushOption = {'Off'},
        TeamSpawn = {'fixed'},
        TeamLock = {'locked'},
    },


    -- Set all game options to their default values.
    SetDefaults = function()
        local options
        for index, option in globalOpts do
            options[option.key] = option.values[option.default].key
        end

        for index, option in teamOpts do
            options[option.key] = option.values[option.default].key
        end

        for index, option in AIOpts do
            options[option.key] = option.values[option.default].key
        end

        SetGameOptions(options)
    end,

    -- Returns true if current game options are considered suitable for a ranked game, false
    -- otherwise.
    AreRanked = function(self)
        for k, v in gameInfo.GameOptions do
            if self.RANKED_OPTIONS[k] then
                if not indexOf(self.RANKED_OPTIONS[k], v) then
                    return false
                end
            end
        end

        return true
    end
}

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

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', slot, "Closed", true)
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

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', slot, "Closed", false)
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

function GetAvailableColor()
    for colorIndex, colorVal in gameColors.PlayerColors do
        if IsColorFree(colorIndex) then
            return colorIndex
        end
    end
end

--- This function is retarded.
-- Unfortunately, we're stuck with it.
-- The game requires both ArmyColor and PlayerColor be set. We don't want to have to write two fields
-- all the time, and the magic that makes PlayerData work precludes adding member functions to it.
-- So, we have this. Tough shit. :P
function SetPlayerColor(playerData, newColor)
    playerData.ArmyColor = newColor
    playerData.PlayerColor = newColor
end

--- Attempt to add a player to a slot. If no is available, add them as an observer.
--
-- @param senderID The peer ID of the player we're adding.
-- @param slot The slot to insert the player to. A value of less than 1 indicates "any slot"
-- @param playerData A PlayerData object representing the player to add.
function HostTryAddPlayer(senderID, slot, playerData)
    LOGX('>> HostTryAddPlayer > requestedPlayerName='..tostring(playerData.PlayerName), 'Connecting')

    -- CPU benchmark code
    if playerData.Human and not singlePlayer then
        lobbyComm:SendData(senderID, {Type='CPUBenchmark', Benchmarks=CPU_Benchmarks})
    end

    local newSlot = slot

    if not slot or slot < 1 or newSlot > numOpenSlots then
        newSlot = -1
        for i = 1, numOpenSlots do
            if gameInfo.PlayerOptions[i] == nil and gameInfo.ClosedSlots[i] == nil then
                newSlot = i
                break
            end
        end
    end

    -- if no slot available, and human, try to make them an observer
    if newSlot == -1 then
        PrivateChat(senderID, LOC("<LOC lobui_0237>No slots available, attempting to make you an observer"))
        if playerData.Human then
			HostTryAddObserver(senderID, playerData)
        end
        return
    end

    playerData.PlayerName = lobbyComm:MakeValidPlayerName(senderID, playerData.PlayerName)

    -- if a color is requested, attempt to use that color if available, otherwise, assign first available
    if not IsColorFree(playerData.PlayerColor) then
        SetPlayerColor(playerData, GetAvailableColor())
    end

    AssignAutoTeams(gameInfo)

    if lobbyComm:IsHost() then
        for k,v in playerData:pairs() do
            GpgNetSend('PlayerOption', newSlot, k, v)
        end
    end

    gameInfo.PlayerOptions[newSlot] = playerData
    lobbyComm:BroadcastData(
        {
            Type = 'SlotAssigned',
            Slot = newSlot,
            Options = playerData:AsTable(),
        }
    )
    UpdateGame()
end

function HostTryMovePlayer(senderID, currentSlot, requestedSlot)
    LOG("SenderID: " .. senderID .. " currentSlot: " .. currentSlot .. " requestedSlot: " .. requestedSlot)

    if gameInfo.PlayerOptions[currentSlot].Ready then
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

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', currentSlot, "StartSpot", requestedSlot)
    end

    gameInfo.PlayerOptions[requestedSlot] = gameInfo.PlayerOptions[currentSlot]
    gameInfo.PlayerOptions[currentSlot] = nil
    ClearSlotInfo(currentSlot)

    lobbyComm:BroadcastData(
        {
            Type = 'SlotMove',
            OldSlot = currentSlot,
            NewSlot = requestedSlot,
            Options = gameInfo.PlayerOptions[requestedSlot]:AsTable(),
        }
    )

    AssignAutoTeams(gameInfo)
    UpdateGame()
end

--- Add an observer
--
-- @param observerData A PlayerData object representing this observer.
function HostTryAddObserver(senderID, observerData)
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    LOGX('>> HostTryAddObserver > requestedObserverName='..tostring(observerData.PlayerName), 'Connecting')
    observerData.PlayerName = lobbyComm:MakeValidPlayerName(senderID, observerData.PlayerName)

    gameInfo.Observers[index] = observerData

    lobbyComm:BroadcastData(
        {
            Type = 'ObserverAdded',
            Slot = index,
            Options = observerData:AsTable(),
        }
    )
    SendSystemMessage(LOCF("<LOC lobui_0202>%s has joined as an observer.",observerName), "lobui_0202")
    refreshObserverList()
end

function HostConvertPlayerToObserver(senderID, playerSlot, ignoreMsg)
    -- make sure player exists
    if not gameInfo.PlayerOptions[playerSlot] then
        return
    end

    -- find a free observer slot
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    gameInfo.Observers[index] = gameInfo.PlayerOptions[playerSlot]
    gameInfo.PlayerOptions[playerSlot] = nil

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', playerSlot, "StartSpot", -index)
    end

    ClearSlotInfo(playerSlot)

    -- TODO: can probably avoid transmitting the options map here. The slot number should be enough.
    lobbyComm:BroadcastData(
        {
            Type = 'ConvertPlayerToObserver',
            OldSlot = playerSlot,
            NewSlot = index,
            Options = gameInfo.Observers[index]:AsTable(),
        }
    )

    if ignoreMsg then
        SendSystemMessage(LOCF("<LOC lobui_0226>%s has switched from a player to an observer.", gameInfo.Observers[index].PlayerName), "lobui_0226")
    end
    UpdateGame()
end

function HostConvertObserverToPlayer(senderID, fromObserverSlot, toPlayerSlot, ignoreMsg)
    if gameInfo.Observers[fromObserverSlot] == nil then -- IF no Observer on the current slot : QUIT
        return
    elseif gameInfo.PlayerOptions[toPlayerSlot] ~= nil then -- IF Player is in the target slot : QUIT
        return
    elseif gameInfo.ClosedSlots[toPlayerSlot] ~= nil then -- IF target slot is Closed : QUIT
        return
    end

    local incomingPlayer = gameInfo.Observers[fromObserverSlot]

    -- Give them a default colour if the one they already have isn't free.
    if not IsColorFree(incomingPlayer.PlayerColor) then
        local newColour = GetAvailableColor()
        SetPlayerColor(incomingPlayer, newColour)
    end

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', -fromObserverSlot, "StartSpot", toPlayerSlot)
    end

    gameInfo.PlayerOptions[toPlayerSlot] = incomingPlayer
    gameInfo.Observers[fromObserverSlot] = nil

    lobbyComm:BroadcastData(
        {
            Type = 'ConvertObserverToPlayer',
            OldSlot = fromObserverSlot,
            NewSlot = toPlayerSlot,
            Options =  gameInfo.PlayerOptions[toPlayerSlot]:AsTable(),
        }
    )

    if ignoreMsg then
        SendSystemMessage(LOCF("<LOC lobui_0227>%s has switched from an observer to player.", incomingPlayer.PlayerName), "lobui_0227")
    end
    UpdateGame()
end

function HostConvertObserverToPlayerWithoutSlot(senderID, fromObserverSlot, ignoreMsg)
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

    HostConvertObserverToPlayer(senderID, fromObserverSlot, toPlayerSlot, ignoreMsg)
end

function HostRemoveAI(slot)
    if gameInfo.PlayerOptions[slot].Human then
        WARN('Use EjectPlayer to remove humans')
        return
    end

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', slot, "Clear")
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
    local name
    local needMessage = false
    if slot then
        name = gameInfo.PlayerOptions[slot].PlayerName
        if not gameInfo.PlayerOptions[slot].BadMap then
            needMessage = true
        end
        gameInfo.PlayerOptions[slot].BadMap = true
    else
        slot = FindObserverSlotForID(id)
        if slot then
            name = gameInfo.Observers[slot].PlayerName
            if not gameInfo.Observers[slot].BadMap then
                needMessage = true
            end
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

    for index, player in gameInfo.PlayerOptions:pairs() do
        if player.BadMap then
            if not ret then ret = {} end
            table.insert(ret, player.PlayerName)
        end
    end

    for index, observer in gameInfo.Observers:pairs() do
        if observer.BadMap then
            if not ret then ret = {} end
            table.insert(ret, observer.PlayerName)
        end
    end

    return ret
end

function ClearBadMapFlags()
    for index, player in gameInfo.PlayerOptions:pairs() do
        player.BadMap = false
    end

    for index, observer in gameInfo.Observers:pairs() do
        observer.BadMap = false
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

-- set up player "slots" which is the line representing a player and player specific options
function CreateSlotsUI(makeLabel)
    local Combo = import('/lua/ui/controls/combo.lua').Combo
    local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar

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

        local newSlot = Group(GUI.playerPanel, "playerSlot " .. tostring(i))
        newSlot.closed = false
        --TODO these need layout from art when available
        newSlot.Width:Set(GUI.labelGroup.Width)
        newSlot.Height:Set(GUI.labelGroup.Height)

        -- Default mouse behaviours for the slot.
        local defaultHandler = function(self, event)
            if curRow > numOpenSlots then
                return
            end

            local associatedMarker = GUI.mapView.startPositions[curRow]
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] ~= 'random' then
                    associatedMarker.indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                associatedMarker.indicator:Stop()
            elseif event.Type == 'ButtonDClick' then
                DoSlotBehavior(curRow, 'occupy', '')
            end

            return Group.HandleEvent(self, event)
        end
        newSlot.HandleEvent = defaultHandler

        local bg = newSlot

        --// Slot Background
        newSlot.SlotBackground = Bitmap(GUI, UIUtil.SkinnableFile("/SLOT/slot-dis.dds"))
        LayoutHelpers.AtBottomIn(newSlot.SlotBackground, newSlot, -6)
        LayoutHelpers.AtLeftIn(newSlot.SlotBackground, newSlot, 0)
        --\\ Stop Slot Background

        --// COUNTRY
        -- Added a bitmap on the left of Rating, the bitmap is a Flag of Country
        local flag = Bitmap(bg, UIUtil.SkinnableFile("/countries/world.dds"))
        newSlot.KinderCountry = flag
        flag.Width:Set(20)
        flag.Height:Set(15)
        LayoutHelpers.AtBottomIn(flag, newSlot, -4)
        LayoutHelpers.AtLeftIn(flag, newSlot, 2)
        --\\ Stop COUNTRY

        -- TODO: Factorise this boilerplate.
        --// Rating
        local ratingGroup = Group(bg)
        newSlot.ratingGroup = ratingGroup
        ratingGroup.Width:Set(slotColumnSizes.rating.width)
        ratingGroup.Height:Set(newSlot.Height)
        LayoutHelpers.AtLeftIn(ratingGroup, GUI.panel, slotColumnSizes.rating.x)
        LayoutHelpers.AtVerticalCenterIn(ratingGroup, newSlot, 6)

        local ratingText = UIUtil.CreateText(ratingGroup, "", 14, 'Arial')
        newSlot.ratingText = ratingText
        ratingText:SetColor('B9BFB9')
        ratingText:SetDropShadow(true)
        LayoutHelpers.AtBottomIn(ratingText, ratingGroup, 2)
        LayoutHelpers.AtRightIn(ratingText, ratingGroup, 9)
        newSlot.tooltiprating = Tooltip.AddControlTooltip(ratingText, 'rating')

        --// NumGame
        local numGamesGroup = Group(bg)
        newSlot.numGamesGroup = numGamesGroup
        numGamesGroup.Width:Set(slotColumnSizes.games.width)
        numGamesGroup.Height:Set(newSlot.Height)
        LayoutHelpers.AtLeftIn(numGamesGroup, GUI.panel, slotColumnSizes.games.x)
        LayoutHelpers.AtVerticalCenterIn(numGamesGroup, newSlot, 6)

        local numGamesText = UIUtil.CreateText(numGamesGroup, "", 14, 'Arial')
        newSlot.numGamesText = numGamesText
        numGamesText:SetColor('B9BFB9')
        numGamesText:SetDropShadow(true)
        Tooltip.AddControlTooltip(numGamesText, 'num_games')
        LayoutHelpers.AtBottomIn(numGamesText, numGamesGroup, 2)
        LayoutHelpers.AtRightIn(numGamesText, numGamesGroup, 9)

        --// Name
        local nameLabel = Combo(bg, 14, 12, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.name = nameLabel
        nameLabel._text:SetFont('Arial Gras', 15)
        LayoutHelpers.AtVerticalCenterIn(nameLabel, newSlot, 8)
        LayoutHelpers.AtLeftIn(nameLabel, GUI.panel, slotColumnSizes.player.x)
        nameLabel.Width:Set(slotColumnSizes.player.width)
        -- left deal with name clicks
        nameLabel.OnEvent = defaultHandler
        nameLabel.OnClick = function(self, index, text)
            DoSlotBehavior(curRow, self.slotKeys[index], text)
        end

        -- Color
        local colorSelector = BitmapCombo(bg, gameColors.PlayerColors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.color = colorSelector

        LayoutHelpers.AtLeftIn(colorSelector, GUI.panel, slotColumnSizes.color.x)
        LayoutHelpers.AtVerticalCenterIn(colorSelector, newSlot, 8)
        colorSelector.Width:Set(slotColumnSizes.color.width)
        colorSelector.OnClick = function(self, index)
            if not lobbyComm:IsHost() then
                lobbyComm:SendData(hostID, { Type = 'RequestColor', Color = index, Slot = curRow } )
                gameInfo.PlayerOptions[curRow]:SetPlayerColor(index)
                UpdateGame()
            else
                if IsColorFree(index) then
                    lobbyComm:BroadcastData( { Type = 'SetColor', Color = index, Slot = curRow } )
                    gameInfo.PlayerOptions[curRow]:SetPlayerColor(index)
                    UpdateGame()
                else
                    self:SetItem( gameInfo.PlayerOptions[curRow].PlayerColor )
                end
            end
        end
        colorSelector.OnEvent = defaultHandler
        Tooltip.AddControlTooltip(colorSelector, 'lob_color')

        --// Faction
        -- builds the faction tables, and then adds random faction icon to the end
        local factionBmps = {}
        local factionTooltips = {}
        for index, tbl in FactionData.Factions do
            factionBmps[index] = tbl.SmallIcon
            factionTooltips[index] = tbl.TooltipID
        end
        table.insert(factionBmps, "/faction_icon-sm/random_ico.dds")
        table.insert(factionTooltips, 'lob_random')

        local factionSelector = BitmapCombo(bg, factionBmps, table.getn(factionBmps), nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.faction = factionSelector
        LayoutHelpers.AtLeftIn(factionSelector, GUI.panel, slotColumnSizes.faction.x)
        LayoutHelpers.AtVerticalCenterIn(factionSelector, newSlot, 8)
        factionSelector.Width:Set(slotColumnSizes.faction.width)
        factionSelector.OnClick = function(self, index)
            SetPlayerOption(curRow, 'Faction', index)
            if curRow == FindSlotForID(FindIDForName(localPlayerName)) then
                GUI.factionSelector:SetSelected(index)
            end

            Tooltip.DestroyMouseoverDisplay()
        end
        Tooltip.AddControlTooltip(factionSelector, 'lob_faction')
        Tooltip.AddComboTooltip(factionSelector, factionTooltips)
        factionSelector.OnEvent = defaultHandler

        --// Team
        local teamSelector = BitmapCombo(bg, teamIcons, 1, false, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        newSlot.team = teamSelector
        LayoutHelpers.AtLeftIn(teamSelector, GUI.panel, slotColumnSizes.team.x)
        LayoutHelpers.AtVerticalCenterIn(teamSelector, newSlot, 8)
        teamSelector.Width:Set(slotColumnSizes.team.width)
        teamSelector.OnClick = function(self, index, text)
            Tooltip.DestroyMouseoverDisplay()
            SetPlayerOption(curRow, 'Team', index)
        end
        Tooltip.AddControlTooltip(teamSelector, 'lob_team')
        Tooltip.AddComboTooltip(teamSelector, teamTooltips)
        teamSelector.OnEvent = defaultHandler

        -- Ping
        local pingGroup = Group(bg)
        newSlot.pingGroup = pingGroup
        pingGroup.Width:Set(slotColumnSizes.ping.width)
        pingGroup.Height:Set(newSlot.Height)
        LayoutHelpers.AtLeftIn(pingGroup, GUI.panel, slotColumnSizes.ping.x)
        LayoutHelpers.AtVerticalCenterIn(pingGroup, newSlot, 6)

        local pingStatus = StatusBar(pingGroup, 0, 1000, false, false,
            UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
            UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
            true)
        newSlot.pingStatus = pingStatus
        LayoutHelpers.AtTopIn(pingStatus, pingGroup, 5)
        LayoutHelpers.AtLeftIn(pingStatus, pingGroup, 0)
        LayoutHelpers.AtRightIn(pingStatus, pingGroup, 0)

        -- depending on if this is single player or multiplayer this displays different info
        newSlot.multiSpace = Group(bg, "multiSpace " .. tonumber(i))
        newSlot.multiSpace.Width:Set(slotColumnSizes.ready.width)
        newSlot.multiSpace.Height:Set(newSlot.Height)
        LayoutHelpers.AtLeftIn(newSlot.multiSpace, GUI.panel, slotColumnSizes.ready.x)
        newSlot.multiSpace.Top:Set(newSlot.Top)

        -- Ready Checkbox
        local readyBox = UIUtil.CreateCheckbox(newSlot.multiSpace, '/CHECKBOX/')
        newSlot.ready = readyBox
        LayoutHelpers.AtVerticalCenterIn(readyBox, newSlot.multiSpace, 8)
        LayoutHelpers.AtLeftIn(readyBox, newSlot.multiSpace, 0)
        readyBox.OnCheck = function(self, checked)
            UIUtil.setEnabled(GUI.becomeObserver, not checked)
            if checked then
                DisableSlot(curRow, true)
            else
                EnableSlot(curRow)
            end
            SetPlayerOption(curRow, 'Ready', checked)
        end

        if singlePlayer then
            -- TODO: Use of groups may allow this to be simplified...
            readyBox:Hide()
            pingGroup:Hide()
            pingStatus:Hide()
        end

        if i == 1 then
            LayoutHelpers.Below(newSlot, GUI.labelGroup, -5)
        else
            LayoutHelpers.Below(newSlot, GUI.slots[i - 1], 3)
        end

        GUI.slots[i] = newSlot

        ClearSlotInfo(i)
    end
end

-- create UI won't typically be called directly by another module
function CreateUI(maxPlayers)
    local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
    local Text = import('/lua/maui/text.lua').Text
    local ResourceMapPreview = import('/lua/ui/controls/resmappreview.lua').ResourceMapPreview
    local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
    local MultiLineText = import('/lua/maui/multilinetext.lua').MultiLineText
    local EffectHelpers = import('/lua/maui/effecthelpers.lua')
    local ItemList = import('/lua/maui/itemlist.lua').ItemList
    local Prefs = import('/lua/user/prefs.lua')
    local Tooltip = import('/lua/ui/game/tooltip.lua')

    local isHost = lobbyComm:IsHost()
    local lastFaction = Prefs.GetFromCurrentProfile('LastFaction') or 1
    UIUtil.SetCurrentSkin(FACTION_NAMES[lastFaction])

    -- Setup custom backgrounds.
    local LobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    GUI.background = Bitmap(GUI, UIUtil.SkinnableFile('/BACKGROUND/background-paint_black_bmp.dds')) -- Background faction or art
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

    -- Map Name Label TODO: Localise!
    GUI.MapNameLabel = makeLabel("Loading...", 17)
    LayoutHelpers.AtRightTopIn(GUI.MapNameLabel, GUI.panel, 50, 41)

    -- Game Quality Label
    GUI.GameQualityLabel = makeLabel("", 13)
    LayoutHelpers.AtRightTopIn(GUI.GameQualityLabel, GUI.panel, 50, 61)

    -- Title Label
    GUI.titleText = makeLabel("FAF Game Lobby", 17)
    LayoutHelpers.AtLeftTopIn(GUI.titleText, GUI.panel, 43, 46)
    
    -- Rule Label
    local RuleLabel = ItemList(GUI.panel)
    GUI.RuleLabel = RuleLabel
    RuleLabel:SetFont('Arial Gras', 11)
    RuleLabel:SetColors("B9BFB9", "00000000", "B9BFB9", "00000000")
    LayoutHelpers.AtLeftTopIn(RuleLabel, GUI.panel, 43, 83)
    RuleLabel.Height:Set(34)
    RuleLabel.Width:Set(350)
    RuleLabel:DeleteAllItems()
    local tmptext
    if isHost then
        tmptext = 'No Rules: Click to add rules'
        RuleLabel:SetColors("FFCC00")
    else
        tmptext = 'Rule: No Rule'
    end
    RuleLabel:AddItem(tmptext or '')
    RuleLabel:AddItem('')
    if isHost then
        RuleLabel.OnClick = function(self)
            ShowRuleDialog(RuleLabel)
        end
    end

    -- Mod Label
    GUI.ModFeaturedLabel = makeLabel("", 13)
    LayoutHelpers.AtLeftTopIn(GUI.ModFeaturedLabel, GUI.panel, 50, 61)

    -- Set the mod name to a value appropriate for the mod in use.
    local modLabels = {
        ["init_faf.lua"] = "FA Forever",
        ["init_blackops.lua"] = "BlackOps",
        ["init_coop.lua"] = "COOP",
        ["init_balancetesting.lua"] = "Balance Testing",
        ["init_gw.lua"] = "Galactic War",
        ["init_labwars.lua"] = "Labwars",
        ["init_ladder1v1.lua"] = "Ladder 1v1",
        ["init_nomads.lua"] = "Nomads Mod",
        ["init_phantomx.lua"] = "PhantomX",
        ["init_supremedestruction.lua"] = "SupremeDestruction",
        ["init_xtremewars.lua"] = "XtremeWars",

    }
    SetText2(GUI.ModFeaturedLabel, modLabels[argv.initName] or "", 20)

    -- Lobby options panel
    GUI.LobbyOptions = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/BUTTON/medium/', "Options")
    LayoutHelpers.AtTopIn(GUI.LobbyOptions, GUI.panel, 10)
    LayoutHelpers.AtHorizontalCenterIn(GUI.LobbyOptions, GUI, 1)
    GUI.LobbyOptions.OnClick = function()
        ShowLobbyOptionsDialog()
    end
    
    -- Logo
    GUI.logo = Bitmap(GUI, '/textures/ui/common/scx_menu/lan-game-lobby/logo.dds')
    LayoutHelpers.AtLeftTopIn(GUI.logo, GUI, 1, 1)
    
    -- Version texts
    local gameVersionText = UIUtil.CreateText(GUI, GameVersion(), 9, UIUtil.bodyFont)
    gameVersionText:SetColor('677983')
    LayoutHelpers.CenteredRightOf(gameVersionText, GUI.logo, 4)
    
    -- Player Slots
    GUI.playerPanel = Group(GUI.panel, "playerPanel")
    LayoutHelpers.AtLeftTopIn(GUI.playerPanel, GUI.panel, 39, 102)
    GUI.playerPanel.Width:Set(706)
    GUI.playerPanel.Height:Set(307)

    -- Observer section
    GUI.observerPanel = Group(GUI.panel, "observerPanel")
    UIUtil.SurroundWithBorder(GUI.observerPanel, '/scx_menu/lan-game-lobby/frame/')

    -- Scale the observer panel according to the buttons we are showing.
    local obsOffset
    local obsHeight
    if isHost then
        obsHeight = 134
        obsOffset = 544
    else
        obsHeight = 181
        obsOffset = 502
    end
    LayoutHelpers.AtLeftTopIn(GUI.observerPanel, GUI.panel, 460, obsOffset)
    GUI.observerPanel.Width:Set(278)
    GUI.observerPanel.Height:Set(obsHeight)

    -- Chat
    GUI.chatPanel = Group(GUI.panel, "chatPanel")
    UIUtil.SurroundWithBorder(GUI.chatPanel, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.AtLeftTopIn(GUI.chatPanel, GUI.panel, 49, 458)
    GUI.chatPanel.Width:Set(388)
    GUI.chatPanel.Height:Set(220)

    -- Map Preview
    GUI.mapPanel = Group(GUI.panel, "mapPanel")
    UIUtil.SurroundWithBorder(GUI.mapPanel, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.AtLeftTopIn(GUI.mapPanel, GUI.panel, 763, 106)
    GUI.mapPanel.Width:Set(198)
    GUI.mapPanel.Height:Set(198)
    LayoutHelpers.DepthOverParent(GUI.mapPanel, GUI.panel, 2)

    GUI.optionsPanel = Group(GUI.panel, "optionsPanel") -- ORANGE Square in Screenshoot
    UIUtil.SurroundWithBorder(GUI.optionsPanel, '/scx_menu/lan-game-lobby/frame/')
    LayoutHelpers.AtLeftTopIn(GUI.optionsPanel, GUI.panel, 763, 343)
    GUI.optionsPanel.Width:Set(198)
    GUI.optionsPanel.Height:Set(288)
    LayoutHelpers.DepthOverParent(GUI.optionsPanel, GUI.panel, 2)

    ---------------------------------------------------------------------------
    -- set up map panel
    ---------------------------------------------------------------------------
    GUI.mapView = ResourceMapPreview(GUI.mapPanel, 200, 3, 5)
    LayoutHelpers.AtLeftTopIn(GUI.mapView, GUI.mapPanel, -1, -1)
    LayoutHelpers.DepthOverParent(GUI.mapView, GUI.mapPanel, -1)

    GUI.LargeMapPreview = UIUtil.CreateButtonWithDropshadow(GUI.mapPanel, '/BUTTON/zoom/', "")
    LayoutHelpers.AtRightIn(GUI.LargeMapPreview, GUI.mapPanel, -1)
    LayoutHelpers.AtBottomIn(GUI.LargeMapPreview, GUI.mapPanel, -1)
    LayoutHelpers.DepthOverParent(GUI.LargeMapPreview, GUI.mapPanel, 2)
    Tooltip.AddButtonTooltip(GUI.LargeMapPreview, 'lob_click_LargeMapPreview')
    GUI.LargeMapPreview.OnClick = function()
        CreateBigPreview(GUI)
    end

    -- Checkbox Show changed Options
    -- TODO: Localise!
    local cbox_ShowChangedOption = UIUtil.CreateCheckbox(GUI.optionsPanel, '/CHECKBOX/', 'Hide default Options', true, 11)
    LayoutHelpers.AtLeftTopIn(cbox_ShowChangedOption, GUI.optionsPanel, 35, -32)

    Tooltip.AddCheckboxTooltip(cbox_ShowChangedOption, {text='Hide default Options', body='Show only changed Options and Advanced Map Options'})
    cbox_ShowChangedOption.OnCheck = function(self, checked)
        HideDefaultOptions = checked
        RefreshOptionDisplayData()
        GUI.OptionContainer.ScrollSetTop(GUI.OptionContainer, 'Vert', 0)
        Prefs.SetToCurrentProfile('LobbyHideDefaultOptions', tostring(checked))
    end

    -- GAME OPTIONS // MODS MANAGER BUTTON --
    if isHost then     -- GAME OPTION
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "Settings")
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'lob_select_map')
        GUI.gameoptionsButton.OnClick = function(self)
            local mapSelectDialog

            autoRandMap = false
            local function selectBehavior(selectedScenario, changedOptions, restrictedCategories)
                local options = {}
                if autoRandMap then
                    options['ScenarioFile'] = selectedScenario.file
                else
                    mapSelectDialog:Destroy()
                    GUI.chatEdit:AcquireFocus()
                    for optionKey, data in changedOptions do
                        options[optionKey] = data.value
                    end
                    options['ScenarioFile'] = selectedScenario.file
                    options['RestrictedCategories'] = restrictedCategories

                    -- every new map, clear the flags, and clients will report if a new map is bad
                    ClearBadMapFlags()
                    HostUpdateMods()
                    SetGameOptions(options)
                end
            end

            local function exitBehavior()
                mapSelectDialog:Close()
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
        GUI.gameoptionsButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "Mods Manager")
        GUI.gameoptionsButton.OnClick = function(self, modifiers)
            import('/lua/ui/lobby/ModsManager.lua').NEW_MODS_GUI(GUI, false, gameInfo.GameMods)
        end
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'Lobby_Mods')
    end

    LayoutHelpers.AtBottomIn(GUI.gameoptionsButton, GUI.optionsPanel, -52)
    LayoutHelpers.AtHorizontalCenterIn(GUI.gameoptionsButton, GUI.optionsPanel, 1)

    ---------------------------------------------------------------------------
    -- set up chat display
    ---------------------------------------------------------------------------
    GUI.chatDisplay = ItemList(GUI.chatPanel)
    GUI.chatDisplay:SetFont(UIUtil.bodyFont, tonumber(Prefs.GetFromCurrentProfile('LobbyChatFontSize')) or 14)
    GUI.chatDisplay:SetColors(UIUtil.fontColor(), "00000000", UIUtil.fontColor(), "00000000")
    LayoutHelpers.AtLeftTopIn(GUI.chatDisplay, GUI.chatPanel, 4, 2)
    GUI.chatDisplay.Height:Set(function() return GUI.chatPanel.Height() - GUI.chatBG.Height() - 2 end)
    -- Leave space for the scrollbar.
    GUI.chatDisplay.Width:Set(function() return GUI.chatPanel.Width() - 20 end)

    -- Annoying evil extra Bitmap to make chat box have padding inside its background.
    local chatBG = Bitmap(GUI.chatPanel)
    GUI.chatBG = chatBG
    chatBG:SetSolidColor('FF212123')
    LayoutHelpers.Below(chatBG, GUI.chatDisplay, 1)
    LayoutHelpers.AtLeftIn(chatBG, GUI.chatDisplay, -5)
    chatBG.Width:Set(GUI.chatPanel.Width() - 16)
    chatBG.Height:Set(24)

    GUI.chatEdit = Edit(GUI.chatPanel)
    LayoutHelpers.AtLeftTopIn(GUI.chatEdit, GUI.chatBG, 4, 3)
    GUI.chatEdit.Width:Set(GUI.chatBG.Width() - 9)
    GUI.chatEdit.Height:Set(22)
    GUI.chatEdit:SetFont(UIUtil.bodyFont, 16)
    GUI.chatEdit:SetForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:ShowBackground(false)
    GUI.chatEdit:SetDropShadow(true)
    GUI.chatEdit:AcquireFocus()

    GUI.chatDisplayScroll = UIUtil.CreateLobbyVertScrollbar(GUI.chatDisplay, 1, 24, -1)

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
    GUI.OptionContainer.Bottom:Set(function() return GUI.optionsPanel.Bottom() end)

    -- Leave space for the scrollbar.
    GUI.OptionContainer.Width:Set(function() return GUI.optionsPanel.Width() - 18 end)
    GUI.OptionContainer.top = 0
    LayoutHelpers.AtLeftTopIn(GUI.OptionContainer, GUI.optionsPanel, 1, 1)
    LayoutHelpers.DepthOverParent(GUI.OptionContainer, GUI.optionsPanel, -1)

    GUI.OptionDisplay = {}

    function CreateOptionElements()
        local function CreateElement(index)
            local element = Group(GUI.OptionContainer)

            element.bg = Bitmap(element)
            element.bg:SetSolidColor('ff333333')
            element.bg.Left:Set(element.Left)
            element.bg.Right:Set(element.Right)
            element.bg.Bottom:Set(function() return element.value.Bottom() + 2 end)
            element.bg.Top:Set(element.Top)

            element.bg2 = Bitmap(element)
            element.bg2:SetSolidColor('ff000000')
            element.bg2.Left:Set(function() return element.bg.Left() + 1 end)
            element.bg2.Right:Set(function() return element.bg.Right() - 1 end)
            element.bg2.Bottom:Set(function() return element.bg.Bottom() - 1 end)
            element.bg2.Top:Set(function() return element.value.Top() + 0 end)

            element.Height:Set(36)
            element.Width:Set(GUI.OptionContainer.Width)
            element:DisableHitTest()

            element.text = UIUtil.CreateText(element, '', 14, "Arial")
            element.text:SetColor(UIUtil.fontColor)
            element.text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(element.text, element, 5)

            element.value = UIUtil.CreateText(element, '', 14, "Arial")
            element.value:SetColor(UIUtil.fontOverColor)
            element.value:DisableHitTest()
            LayoutHelpers.AtRightTopIn(element.value, element, 5, 16)

            GUI.OptionDisplay[index] = element
        end

        CreateElement(1)
        LayoutHelpers.AtLeftTopIn(GUI.OptionDisplay[1], GUI.OptionContainer)

        local index = 2
        while index ~= 9 do
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
            line.bg:Show()
            line.value:SetText(LOC(data.value))
            line.bg2:Show()
            line.bg.HandleEvent = Group.HandleEvent
            line.bg2.HandleEvent = Bitmap.HandleEvent
            if data.tooltip then
                Tooltip.AddControlTooltip(line.bg, data.tooltip)
                Tooltip.AddControlTooltip(line.bg2, data.valueTooltip)
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
                v.bg:Hide()
                v.bg2:Hide()
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

    GUI.OptionContainerScroll = UIUtil.CreateLobbyVertScrollbar(GUI.OptionContainer, 2)
    LayoutHelpers.DepthOverParent(GUI.OptionContainerScroll, GUI.OptionContainer, 2)

    -- Create skirmish mode's "load game" button.
    GUI.loadButton = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/',"<LOC lobui_0176>Load")
    UIUtil.setVisible(GUI.loadButton, singlePlayer)
    LayoutHelpers.LeftOf(GUI.loadButton, GUI.launchGameButton, 10)
    LayoutHelpers.AtVerticalCenterIn(GUI.loadButton, GUI.launchGameButton)
    GUI.loadButton.OnClick = function(self, modifiers)
        import('/lua/ui/dialogs/saveload.lua').CreateLoadDialog(GUI)
    end
    Tooltip.AddButtonTooltip(GUI.loadButton, 'Lobby_Load')

    -- Create the "Lobby presets" button for the host. If not the host, the same field is occupied
    -- instead by the read-only "Unit Manager" button.
    GUI.restrictedUnitsOrPresetsBtn = UIUtil.CreateButtonWithDropshadow(GUI.optionsPanel, '/BUTTON/medium/', "")

    if singlePlayer then
        GUI.restrictedUnitsOrPresetsBtn:Hide()
    elseif isHost then
        -- TODO: Localise!
        GUI.restrictedUnitsOrPresetsBtn.label:SetText("Presets")
        GUI.restrictedUnitsOrPresetsBtn.OnClick = function(self, modifiers)
            ShowPresetDialog()
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
    LayoutHelpers.Below(GUI.restrictedUnitsOrPresetsBtn, GUI.gameoptionsButton, 7)

    ---------------------------------------------------------------------------
    -- Checkbox Show changed Options
    ---------------------------------------------------------------------------
    cbox_ShowChangedOption:SetCheck(HideDefaultOptions, false)

    ---------------------------------------------------------------------------
    -- set up : player grid
    ---------------------------------------------------------------------------

    -- For disgusting reasons, we pass the label factory as a parameter.
    CreateSlotsUI(makeLabel)
    ---------------------------------------------------------------------------
    -- set up observer and limbo grid
    ---------------------------------------------------------------------------
    
    GUI.allowObservers = UIUtil.CreateCheckbox(GUI.chatPanel, '/CHECKBOX/', 'Observers in Game', true, 11)
    LayoutHelpers.AtLeftTopIn(GUI.allowObservers, GUI.chatPanel, -11, -37)
    Tooltip.AddControlTooltip(GUI.allowObservers, 'lob_observers_allowed')
    GUI.allowObservers:SetCheck(false)
    if isHost then
        SetGameOption("AllowObservers", false, true)
        GUI.allowObservers.OnCheck = function(self, checked)
            SetGameOption("AllowObservers", checked)
        end
    else
        GUI.allowObservers:Disable()
    end
    
    -- Launch Button
    GUI.launchGameButton = UIUtil.CreateButtonWithDropshadow(GUI.chatPanel, '/BUTTON/large/', "Launch the Game")
    LayoutHelpers.AtCenterIn(GUI.launchGameButton, GUI.observerPanel, 103, -89)
    Tooltip.AddButtonTooltip(GUI.launchGameButton, 'Lobby_Launch')
    UIUtil.setVisible(GUI.launchGameButton, isHost)
    GUI.launchGameButton.OnClick = function(self)
        TryLaunch(false)
    end

    -- Exit Button
    GUI.exitButton = UIUtil.CreateButtonWithDropshadow(GUI.chatPanel, '/BUTTON/medium/','Exit')
    GUI.exitButton.label:SetText(LOC("<LOC _Exit>"))
    LayoutHelpers.AtLeftIn(GUI.exitButton, GUI.chatPanel, 38)
    LayoutHelpers.AtVerticalCenterIn(GUI.exitButton, GUI.launchGameButton, -3)
    GUI.exitButton.OnClick = GUI.exitLobbyEscapeHandler
    
    -- Small buttons are 100 wide, 44 tall
    
    -- Default option button
    GUI.defaultOptions = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/defaultoption/')
    -- If we're the host, position the buttons lower down (and eventually shrink the observer panel)
    if not isHost then
        GUI.defaultOptions:Hide()
    end
    LayoutHelpers.AtLeftTopIn(GUI.defaultOptions, GUI.observerPanel, 11, -94)

    Tooltip.AddButtonTooltip(GUI.defaultOptions, 'lob_click_rankedoptions')
    if not isHost then
        GUI.defaultOptions:Disable()
    else
        GUI.defaultOptions.OnClick = function()
            -- Return all options to their default values.
            OptionUtils.SetDefaults()
            lobbyComm:BroadcastData( { Type = "SetAllPlayerNotReady" } )
            UpdateGame()
        end
    end

    -- RANDOM MAP BUTTON --
    GUI.randMap = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/randommap/')
    LayoutHelpers.RightOf(GUI.randMap, GUI.defaultOptions, -19)
    Tooltip.AddButtonTooltip(GUI.randMap, 'lob_click_randmap')
    if not isHost then
        GUI.randMap:Hide()
    else
        GUI.randMap.OnClick = function()
            local randomMap
            local mapSelectDialog

            autoRandMap = false

            -- Load the set of all available maps, with a slight evil hack on the mapselect module.
            local mapDialog = import('/lua/ui/dialogs/mapselect.lua')
            local allMaps = mapDialog.LoadScenarios()  -- Result will be cached.

            -- Only include maps which have enough slots for the players we have.
            local filteredMaps = table.filter(allMaps,
                function(scenInfo)
                    local supportedPlayers = table.getsize(scenInfo.Configurations.standard.teams[1].armies)
                    return supportedPlayers >= GetPlayerCount()
                end
            )
            local mapCount = table.getn(filteredMaps)
            local selectedMap = filteredMaps[math.floor(math.random(1, mapCount))]

            -- Set the new map.
            SetGameOption('ScenarioFile', selectedMap.file)
            ClearBadMapFlags()
            UpdateGame()
        end
    end

    if isHost and not singlePlayer then
        local autoKickBox = UIUtil.CreateCheckbox(GUI.chatPanel, '/CHECKBOX/', "Auto kick", true, 11)
        LayoutHelpers.CenteredRightOf(autoKickBox, GUI.allowObservers, 10)
        Tooltip.AddControlTooltip(autoKickBox, 'lob_auto_kick')
        autoKick = true
        autoKickBox:SetCheck(true)
        autoKickBox.OnCheck = function(self, checked)
            autoKick = checked
        end
    end
    
    -- AUTO TEAM BUTTON -- start of auto teams code.
    GUI.autoTeams = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/autoteam/')
    LayoutHelpers.RightOf(GUI.autoTeams, GUI.randMap, -19)
    Tooltip.AddButtonTooltip(GUI.autoTeams, 'lob_click_randteam')
    if not isHost then
        GUI.autoTeams:Hide()
    else
        GUI.autoTeams.OnClick = function(self, modifiers)
            local next_states =
            {
                none = {'tvsb', 'Top vs Bottom', 2},
                tvsb = {'lvsr', 'Left vs Right', 3},
                lvsr = {'pvsi', 'Even Slots vs Odd Slots', 4},
                pvsi = {'manual', 'Manual Select', 5},
                manual = {'none', 'None', 1},
            }
            local next_state = next_states[gameInfo.GameOptions['AutoTeams']]

            Prefs.SetToCurrentProfile('Lobby_Auto_Teams', next_state[3])
            SetGameOption('AutoTeams', next_state[1])
            SendSystemMessage("Auto Teams option set: "..next_state[2])

            AssignAutoTeams(gameInfo)
            UpdateGame()
        end
    end
    
    -- GO OBSERVER BUTTON --
    GUI.becomeObserver = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/observer/')
    LayoutHelpers.AtLeftTopIn(GUI.becomeObserver, GUI.defaultOptions, 40, 47)
    Tooltip.AddButtonTooltip(GUI.becomeObserver, 'lob_become_observer')
    GUI.becomeObserver.OnClick = function()
        if IsPlayer(localPlayerID) then
            if isHost then
                HostConvertPlayerToObserver(hostID, FindSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToObserver', RequestedSlot = FindSlotForID(localPlayerID)})
            end
        elseif IsObserver(localPlayerID) then
            if isHost then
                HostConvertObserverToPlayerWithoutSlot(hostID, FindObserverSlotForID(localPlayerID))
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayerWithoutSlot', ObserverSlot = FindObserverSlotForID(localPlayerID)})
            end
        end
    end

    -- CPU BENCH BUTTON --
    GUI.rerunBenchmark = UIUtil.CreateButtonStd(GUI.observerPanel, '/BUTTON/cputest/', '', 11)
    LayoutHelpers.RightOf(GUI.rerunBenchmark, GUI.becomeObserver, -20)
    Tooltip.AddButtonTooltip(GUI.rerunBenchmark,{text='Run CPU Benchmark Test', body='Recalculates your CPU rating.'})

    -- Observer List
    GUI.observerList = ItemList(GUI.observerPanel, "observer list")
    GUI.observerList:SetFont(UIUtil.bodyFont, 12)
    GUI.observerList:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontOverColor, UIUtil.highlightColor, "ffbcfffe")
    GUI.observerList.Left:Set(function() return GUI.observerPanel.Left() + 4 end)
    GUI.observerList.Bottom:Set(function() return GUI.observerPanel.Bottom() end)
    GUI.observerList.Top:Set(function() return GUI.observerPanel.Top() + 2 end)
    GUI.observerList.Right:Set(function() return GUI.observerPanel.Right() - 15 end)
    GUI.observerList.OnClick = function(self, row, event)
        if isHost and event.Modifiers.Right then
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
    UIUtil.CreateLobbyVertScrollbar(GUI.observerList, 0, 0, -1)

    if singlePlayer then
        -- observers are always allowed in skirmish games.
        SetGameOption("AllowObservers",true)
        -- Hide all the multiplayer-only UI elements (we still create them because then we get to
        -- mostly forget that we're in single-player mode everywhere else (stuff silently becomes a
        -- nop, instead of needing to keep checking if UI controls actually exist...

        GUI.allowObservers:Hide()
        GUI.becomeObserver:Hide()
        GUI.autoTeams:Hide()
        GUI.defaultOptions:Hide()
        GUI.rerunBenchmark:Hide()
        GUI.randMap:Hide()
        GUI.observerPanel:Hide()
        GUI.pingLabel:Hide()
        GUI.readyLabel:Hide()
    end

    -- Setup large pretty faction selector and set the factional background to its initial value.
    local lastFaction = Prefs.GetFromCurrentProfile('LastFaction') or 1
    CreateUI_Faction_Selector(lastFaction)

    ChangeBackgroundLobby(lastFaction)

    ---------------------------------------------------------------------------
    -- other logic, including lobby callbacks
    ---------------------------------------------------------------------------
    GUI.posGroup = false
    -- get ping times
    GUI.pingThread = ForkThread(
    function()
        while lobbyComm do
            for slot, player in gameInfo.PlayerOptions:pairs() do
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

    if not singlePlayer then
        CreateCPUMetricUI()
        ForkThread(function() UpdateBenchmark() end)
    end

    GUI.uiCreated = true
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

        -- Options are stored as keys from the values array in optData. We want to display the
        -- descriptive string in the UI, so let's go dig it out.

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

--- Return a status code representing the status of our connection to a peer.
-- @param peer, native table as returned by lobbyComm:GetPeer()
-- @return A value describing the connectivity to given peer.
-- 1 means no connectivity, 2 means they haven't reported that they can talk to us, 3 means
--
-- @todo: This function has side effects despite the naming suggesting that it shouldn't.
--        These need to go away.
function CalcConnectionStatus(peer)
    if peer.status ~= 'Established' then
        return 1
    else
        if not wasConnected(peer.id) then
            local peerSlot = FindSlotForID(peer.id)
            GUI.slots[peerSlot].name:SetTitleText(peer.name)
            GUI.slots[peerSlot].name._text:SetFont('Arial Gras', 15)
            if not table.find(ConnectionEstablished, peer.name) then
                if gameInfo.PlayerOptions[peerSlot].Human and not IsLocallyOwned(peerSlot) then
                    if table.find(ConnectedWithProxy, peer.id) then
                        AddChatText(LOCF("<LOC Engine0032>Connected to %s via the FAF proxy.", peer.name), "Engine0032")
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
    for slot,player in gameInfo.PlayerOptions:pairs() do
        if not table.find(important, player.OwnerID) then
            table.insert(important, player.OwnerID)
        end
    end
    for slot,observer in gameInfo.Observers:pairs() do
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
    local startPos = MapUtil.GetStartPositions(scenario)
    local playerArmyArray = MapUtil.GetArmies(scenario)

    for inSlot, army in playerArmyArray do
        local pos = startPos[army]
        local slot = inSlot

        -- The ACUButton instance representing this slot.
        local marker = mapCtrl.startPositions[slot]

        if gameInfo.GameOptions['AutoTeams'] and not gameInfo.AutoTeams[slot] and lobbyComm:IsHost() then
            gameInfo.AutoTeams[slot] = 2
        end

        marker.OnClick = function(self)
            if gameInfo.GameOptions['TeamSpawn'] ~= 'random' then
                if FindSlotForID(localPlayerID) ~= slot and gameInfo.PlayerOptions[slot] == nil then
                    if IsPlayer(localPlayerID) then
                        if lobbyComm:IsHost() then
                            HostTryMovePlayer(hostID, FindSlotForID(localPlayerID), slot)
                        else
                            lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID), RequestedSlot = slot})
                        end
                    elseif IsObserver(localPlayerID) then
                        if lobbyComm:IsHost() then
                            local requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
                            HostConvertObserverToPlayer(hostID, FindObserverSlotForID(localPlayerID), slot)
                        else
                            lobbyComm:SendData(
                                hostID,
                                {
                                    Type = 'RequestConvertToPlayer',
                                    ObserverSlot = FindObserverSlotForID(localPlayerID),
                                    PlayerSlot = slot
                                }
                            )
                        end
                    end
                end
            else
                if gameInfo.GameOptions['AutoTeams'] and lobbyComm:IsHost() then
                    -- Handle the manual-mode reassignment of slots to teams.
                    if gameInfo.GameOptions['AutoTeams'] == 'manual' then
                        if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
                            local targetTeam
                            if gameInfo.AutoTeams[slot] == 7 then
                                -- 2 here corresponds to team 1, since a team value of 1 represents
                                -- "no team". Apparently GPG really, really didn't like zero.
                                targetTeam = 2
                            else
                                targetTeam = gameInfo.AutoTeams[slot] + 1
                            end

                            marker:SetTeam(targetTeam)
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
        end

        if lobbyComm:IsHost() then
            marker.OnRightClick = function(self)
                if gameInfo.ClosedSlots[slot] == nil then
                    HostCloseSlot(hostID, slot)
                else
                    HostOpenSlot(hostID, slot)
                end
            end
        end

        -- Nothing more for us to do for a closed slot.
        marker:SetClosed(gameInfo.ClosedSlots[slot] ~= nil)
        if gameInfo.ClosedSlots[slot] then
            return
        end

        if gameInfo.GameOptions['TeamSpawn'] == 'random' then
            marker:SetColor("00777777")
        else
            -- If spawns are fixed, show the colour/team of the person in this slot.
            if gameInfo.PlayerOptions[slot] then
                marker:SetColor(gameColors.PlayerColors[gameInfo.PlayerOptions[slot].PlayerColor])
                marker:SetTeam(gameInfo.PlayerOptions[slot].Team)
            else
                marker:Clear()
            end
        end

        if gameInfo.GameOptions['AutoTeams'] then
            if gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
                local midLine = mapCtrl.Left() + (mapCtrl.Width() / 2)
                if gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random' then
                    local markerPos = marker.Left()
                    if markerPos < midLine then
                        marker:SetTeam(2)
                    else
                        marker:SetTeam(3)
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
                local midLine = mapCtrl.Top() + (mapCtrl.Height() / 2)
                if gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random' then
                    local markerPos = marker.Top()
                    if markerPos < midLine then
                        marker:SetTeam(2)
                    else
                        marker:SetTeam(3)
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
                if gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random' then
                    if math.mod(slot, 2) ~= 0 then
                        marker:SetTeam(2)
                    else
                        marker:SetTeam(3)
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'manual' and gameInfo.GameOptions['TeamSpawn'] == 'random' then
                marker:SetTeam(gameInfo.AutoTeams[slot] or 1)
            end
        end
    end
end

function SendCompleteGameStateToPeer(peerId)
    lobbyComm:SendData(peerId, {Type = 'GameInfo', GameInfo = GameInfo.Flatten(gameInfo)})
end

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

        GpgNetSend('ConnectedToHost', hostID)
        lobbyComm:SendData(hostID, { Type = 'SetAvailableMods', Mods = GetLocallyAvailableMods(), Name = localPlayerName} )

        if wantToBeObserver then
            lobbyComm:SendData(hostID,
                {
                    Type = 'AddObserver',
                    PlayerOptions = GetLocalPlayerData():AsTable()
                }
            )
			LOGX('>> ConnectionToHostEstablished//SendData//playerRating='..tostring(playerRating), 'Connecting')
        else
            lobbyComm:SendData(hostID,
                {
                    Type = 'AddPlayer',
                    PlayerOptions = GetLocalPlayerData():AsTable()
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
        if data.Type == 'PlayerOption' or data.Type == 'PlayerOptions' then
            local options
            local isHost = lobbyComm:IsHost()
            
            if data.Type == 'PlayerOption' then
                options[data.Key] = data.Value
            else
                options = data.Options
            end

            for key, val in options do
                local valid = true

                if data.SenderID ~= hostID then
                    valid = false
                    if key == 'Team' and gameInfo.GameOption['AutoTeams'] ~= 'none' then
                        WARN("Attempt to set Team while Auto Teams are on.")
                    elseif gameInfo.PlayerOptions[data.Slot].OwnerID ~= data.SenderID then
                        WARN("Attempt to set option on unowned slot.")
                    else
                        valid = true
                    end
                end

                if valid then
                    gameInfo.PlayerOptions[data.Slot][key] = val
                    if isHost then
                        GpgNetSend('PlayerOption', data.Slot, data.Key, data.Value)
                    end
                end
            end
            UpdateGame()
        elseif data.Type == 'PublicChat' then
            AddChatText("["..data.SenderName.."] "..data.Text)
        elseif data.Type == 'PrivateChat' then
            AddChatText("<<"..data.SenderName..">> "..data.Text)
        elseif data.Type == 'CPUBenchmark' then
            -- CPU benchmark code
            local benchmarks = {}
            if data.PlayerName then
                benchmarks[data.PlayerName] = data.Result
            else
                benchmarks = data.Benchmarks
            end

            for name, result in benchmarks do
                CPU_Benchmarks[name] = result
                local id = FindIDForName(name)
                local slot = FindSlotForID(id)
                if slot ~= nil then
                    SetSlotCPUBar(slot, gameInfo.PlayerOptions[slot])
                end
            end
        elseif data.Type == 'SetPlayerNotReady' then
            EnableSlot(data.Slot)
            GUI.becomeObserver:Enable()

            SetPlayerOption(data.Slot, 'Ready', false)
        end

        if lobbyComm:IsHost() then
            -- Host only messages
            if data.Type == 'GetGameInfo' then
                SendCompleteGameStateToPeer(data.SenderID)
            elseif data.Type == 'AddPlayer' then
                -- create empty slot if possible and give it to the player
                SendCompleteGameStateToPeer(data.SenderID)
                HostTryAddPlayer(data.SenderID, 0, PlayerData(data.PlayerOptions))
                PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04716'}, true)
            elseif data.Type == 'MovePlayer' then
                -- attempt to move a player from current slot to empty slot
                HostTryMovePlayer(data.SenderID, data.CurrentSlot, data.RequestedSlot)
            elseif data.Type == 'AddObserver' then
                -- create empty slot if possible and give it to the observer
                if gameInfo.GameOptions.AllowObservers then
                    HostTryAddObserver(data.SenderID, PlayerData(data.PlayerOptions))
                else
                    lobbyComm:EjectPeer(data.SenderID, 'NoObservers');
                end
            elseif data.Type == 'RequestConvertToObserver' then
                HostConvertPlayerToObserver(data.SenderID, data.RequestedSlot)
            elseif data.Type == 'RequestConvertToPlayer' then
                HostConvertObserverToPlayer(data.SenderID, data.ObserverSlot, data.PlayerSlot)
                AssignAutoTeams(gameInfo)
                UpdateGame()
            elseif data.Type == 'RequestConvertToPlayerWithoutSlot' then
                HostConvertObserverToPlayerWithoutSlot(data.SenderID, data.ObserverSlot)
                AssignAutoTeams(gameInfo)
                UpdateGame()
            elseif data.Type == 'RequestColor' then
                if IsColorFree(data.Color) then
                    -- Color is available, let everyone else know
                    gameInfo.PlayerOptions[data.Slot]:SetPlayerColor(data.Color)
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
                AddChatText(data.Text)
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
                gameInfo.PlayerOptions[data.Slot] = PlayerData(data.Options)
                PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04716'}, true)
                UpdateGame()
            elseif data.Type == 'SlotMove' then
                gameInfo.PlayerOptions[data.OldSlot] = nil
                gameInfo.PlayerOptions[data.NewSlot] = PlayerData(data.Options)
                ClearSlotInfo(data.OldSlot)
                SetSlotInfo(data.NewSlot, gameInfo.PlayerOptions[data.NewSlot])
            elseif data.Type == 'ObserverAdded' then
                if data.Options.OwnerID == localPlayerID then
                    -- The new slot is for us. Request the full game info from the host
                    localPlayerName = data.Options.PlayerName -- validated by server
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    -- The new slot was someone else, just add that info.
                    gameInfo.Observers[data.Slot] = PlayerData(data.Options)
                end
                refreshObserverList()
            elseif data.Type == 'ConvertObserverToPlayer' then
                gameInfo.Observers[data.OldSlot] = nil
                gameInfo.PlayerOptions[data.NewSlot] = PlayerData(data.Options)
                refreshObserverList()
                SetSlotInfo(data.NewSlot, gameInfo.PlayerOptions[data.NewSlot])
            elseif data.Type == 'ConvertPlayerToObserver' then
                gameInfo.Observers[data.NewSlot] = PlayerData(data.Options)
                gameInfo.PlayerOptions[data.OldSlot] = nil
                ClearSlotInfo(data.OldSlot)
                refreshObserverList()
            elseif data.Type == 'SetColor' then
                gameInfo.PlayerOptions[data.Slot]:SetPlayerColor(data.Color)
                UpdateGame()
            elseif data.Type == 'GameInfo' then
                -- Completely update the game state.
                -- We should aim to use this exactly once: On first connection to the host. As-is,
                -- it makes incremental UI updates problematic.
                local hostFlatInfo = data.GameInfo
                table.print(hostFlatInfo)
                gameInfo = GameInfo.CreateGameInfo(LobbyComm.maxPlayerSlots, hostFlatInfo)
                UpdateGame()
            elseif data.Type == 'GameOption' then
                gameInfo.GameOptions[data.Key] = data.Value
                UpdateGame()
            elseif data.Type == 'GameOptions' then
                for key, value in data.Options do
                    gameInfo.GameOptions[key] = value
                end
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

                -- Set current skin to the actual faction you'll be playing as (the skin may not be
                -- correct if the player chose "random").
                UIUtil.SetCurrentSkin(FACTION_NAMES[v.faction])
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

        -- Given an option key, find the value stored in the profile (if any) and assign either it,
        -- or that option's default value, to the current game state.
        local setOptionsFromPref = function(option)
            local defValue = Prefs.GetFromCurrentProfile("LobbyOpt_" .. option.key) or option.values[option.default].key
            SetGameOption(option.key, defValue, true)
        end

        -- Give myself the first slot
        local myPlayerData = GetLocalPlayerData()

        for k,v in myPlayerData:pairs() do
            GpgNetSend('PlayerOption', 1, k, v)
        end
        gameInfo.PlayerOptions[1] = myPlayerData

        -- set default lobby values
        for index, option in globalOpts do
            setOptionsFromPref(option)
        end

        for index, option in teamOpts do
            setOptionsFromPref(option)
        end

        for index, option in AIOpts do
            setOptionsFromPref(option)
        end

        if self.desiredScenario and self.desiredScenario ~= "" then
            SetGameOption('ScenarioFile',self.desiredScenario, true)
        end

        GUI.keepAliveThread = ForkThread(
        -- Eject players who haven't sent a heartbeat in a while
        function()
            while true and lobbyComm do
                local peers = lobbyComm:GetPeers()
                for k,peer in peers do
                    if peer.quiet > LobbyComm.quietTimeout then
                        lobbyComm:EjectPeer(peer.id,'TimedOutToHost')
                        SendSystemMessage(LOCF("<LOC lobui_0226>%s timed out.", peer.name), "lobui_0205")
                        
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
                GpgNetSend('PlayerOption', slot, "Clear")
                PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04717'}, true)
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.PlayerOptions[slot]:AsTable(),
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
                GpgNetSend('PlayerOption', -slot2, "Clear")
                lobbyComm:BroadcastData(
                {
                    Type = 'Peer_Really_Disconnected',
                    Options =  gameInfo.Observers[slot2]:AsTable(),
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

function SetPlayerOptions(slot, options, ignoreRefresh)
    if not IsLocallyOwned(slot) and not lobbyComm:IsHost() then
        WARN("Hey you can't set a player option on a slot you don't own. (slot:"..tostring(slot).." / key:"..tostring(key).." / val:"..tostring(val)..")")
        return
    end

    local isHost = lobbyComm:IsHost()
    for key, val in options do
        gameInfo.PlayerOptions[slot][key] = val
        if isHost then
            GpgNetSend('PlayerOption', slot, key, val)
        end
    end
        
    lobbyComm:BroadcastData(
    {
        Type = 'PlayerOptions',
        Options = options,
        Slot = slot,
    })

    if not ignoreRefresh then
        UpdateGame()
    end
end

function SetPlayerOption(slot, key, val, ignoreRefresh)
    local options = {}
    options[key] = val
    SetPlayerOptions(slot, options, ignoreRefresh)
end

function SetGameOptions(options, ignoreRefresh)
    if not lobbyComm:IsHost() then
        WARN('Attempt to set game option by a non-host')
        return
    end

    for key, val in options do
        LOG('SetGameOption(key='..repr(key)..',val='..repr(val)..')')
        Prefs.SetToCurrentProfile('LobbyOpt_' .. key, val)
        gameInfo.GameOptions[key] = val

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
                -- Warn about attempts to load nonexistent maps.
                if not DiskGetFileInfo(gameInfo.GameOptions.ScenarioFile) then
                    AddChatText('The selected map does not exist.')
                else
                    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map ~= '') then
                        GpgNetSend('GameOption', 'Slots', table.getsize(scenarioInfo.Configurations.standard.teams[1].armies))
                    end
                end
            end
        elseif key == "GameRules" then
            -- Oh, the cargo-culting.
            SetRuleTitleText(val)
            GpgNetSend('GameOption', key, val)
        else
            GpgNetSend('GameOption', key, val)
        end
    end

    lobbyComm:BroadcastData {
        Type = 'GameOptions',
        Options = options
    }

    if not ignoreRefresh then
        UpdateGame()
    end
end

function SetGameOption(key, val, ignoreRefresh)
    local options = {}
    options[key] = val
    SetGameOptions(options, ignoreRefresh)
end

function DebugDump()
    if lobbyComm then
        lobbyComm:DebugDump()
    end
end


local LrgMap = false

-- Perform one-time setup of the large map preview
function CreateBigPreview(parent)
    if LrgMap then
        LrgMap.isHidden = false
        RefreshLargeMap()
        LrgMap:Show()
        return
    end

    -- Size of the map preview to generate.
    local MAP_PREVIEW_SIZE = 721

    -- The size of the mass/hydrocarbon icons
    local HYDROCARBON_ICON_SIZE = 14
    local MASS_ICON_SIZE = 10

    local dialogContent = Group(parent)
    dialogContent.Width:Set(MAP_PREVIEW_SIZE + 10)
    dialogContent.Height:Set(MAP_PREVIEW_SIZE + 10)

    LrgMap = Popup(parent, dialogContent)

    -- The LrgMap shouldn't be destroyed due to issues related to texture pooling. Evil hack ensues.
    local onTryMapClose = function()
        LrgMap:Hide()
        LrgMap.isHidden = true
    end
    LrgMap.OnEscapePressed = onTryMapClose
    LrgMap.OnShadowClicked = onTryMapClose

    -- Create the map preview
    local mapPreview = ResourceMapPreview(dialogContent, MAP_PREVIEW_SIZE, MASS_ICON_SIZE, HYDROCARBON_ICON_SIZE)
    dialogContent.mapPreview = mapPreview
    LayoutHelpers.AtCenterIn(mapPreview, dialogContent)

    local closeBtn = UIUtil.CreateButtonStd(dialogContent, '/dialogs/close_btn/close')
    LayoutHelpers.AtRightTopIn(closeBtn, dialogContent, 1, 1)
    closeBtn.OnClick = onTryMapClose

    -- Keep the close button on top of the border (which is itself on top of the map preview)
    LayoutHelpers.DepthOverParent(closeBtn, mapPreview, 2)

    RefreshLargeMap()
end

-- Refresh the large map preview (so it can update if something changes while it's open)
function RefreshLargeMap()
    if not LrgMap or LrgMap.isHidden then
        return
    end

    local scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    LrgMap.content.mapPreview:SetScenario(scenarioInfo)
    ShowMapPositions(LrgMap.content.mapPreview, scenarioInfo, GetPlayerCount())
end

--CPU Status Bar Configuration
local barMax = 450
local barMin = 0
local greenBarMax = 300
local yellowBarMax = 375
local scoreSkew1 = 0 --Skews all CPU scores up or down by the amount specified (0 = no skew)
local scoreSkew2 = 1.0 --Skews all CPU scores specified coefficient (1.0 = no skew)

--Variables for CPU Test
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
            ForkThread(function() UpdateBenchmark(true) end)
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

--- Get the CPU benchmark score for the local machine.
-- If a previously-calculated benchmark score is found in the profile, it is returned immediately.
-- Otherwise, a fresh score is calculated and stored (enjoy the lag!).
--
-- @param force If truthy, a fresh score is always calculated.
-- @return A benchmark score between 0 and 450, or nil if StressCPU returned nil (which occurs iff
--         the lobby is exited before the calculation is complete. Callers should abort gracefully
--         in this situation).
-- @see StressCPU
function GetBenchmarkScore(force)
    if force then
        return StressCPU(0)
    end

    -- Benchmark scores are associated with the machine, not the profile: hence SetPreference.
    local benchmark = GetPreference('CPUBenchmark')
    if not benchmark then
        -- We defer the calculation by 10s here because, often, non-forced requests are occurring on
        -- startup, and we want to give other tasks, such as connection negotiation, a fighting
        -- chance of completing before we ruin everything.
        benchmark = StressCPU(10)
        SetPreference('CPUBenchmark', benchmark)
    end

    return benchmark
end

--- Updates the displayed benchmark score for the local player.
--
-- @param force Passed as the `force` parameter to GetBenchmarkScore.
-- @see GetBenchmarkScore
function UpdateBenchmark(force)
    local benchmark = GetBenchmarkScore(force)

    if benchmark then
        CPU_Benchmarks[localPlayerName] = benchmark
        lobbyComm:BroadcastData({ Type = 'CPUBenchmark', PlayerName = localPlayerName, Result = benchmark })
        UpdateCPUBar(localPlayerName)
    end
end

-- This function instructs the PC to do a CPU score benchmark.
-- It handles the necessary UI updates during the benchmark, sends
-- the benchmark result to other players when finished, and it updates the local
-- user's UI with their new result.
--    waitTime: The delay in seconds that this function should wait before starting the benchmark.
function StressCPU(waitTime)
    GUI.rerunBenchmark:Disable()
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
    local currentBestBenchmark = 10000

    GUI.rerunBenchmark.label:SetText('. . .')

    --Run three benchmarks and keep the best one
    for i=1, 3, 1 do
        BenchTime = 0
        CPUBenchmark()

        BenchTime = scoreSkew2 * BenchTime + scoreSkew1

        -- The bench might have yeilded to a launcher, so we verify the lobbyComm is available when
        -- we need it in a moment here (as well as aborting if we're wasting our time more than usual)
        if not lobbyComm then
            return
        end

        --If this benchmark was better than our best so far...
        if BenchTime < currentBestBenchmark then
            currentBestBenchmark = BenchTime
        end
    end

    --Reset Button UI
    GUI.rerunBenchmark:Enable()
    GUI.rerunBenchmark.label:SetText('')

    return currentBestBenchmark
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
function SetRuleTitleText(rule)
    GUI.RuleLabel:SetColors("B9BFB9")
    if rule == '' then
        if lobbyComm:IsHost() then
            GUI.RuleLabel:SetColors("FFCC00")
            rule = 'No Rules: Click to add rules.'
        else
            rule = "No rules."
        end
    end

    GUI.RuleLabel:DeleteAllItems()
    -- We should probably use a TextField for this, but for now we do the slightly ridiculous thing
    -- of wrapping across two rows in an ItemList.
    local wrapped = import('/lua/maui/text.lua').WrapText('Rules: '..rule, 350, function(curText) return GUI.RuleLabel:GetStringAdvance(curText) end)
    GUI.RuleLabel:AddItem(wrapped[1] or '')
    GUI.RuleLabel:AddItem(wrapped[2] or '')
end

-- Show the rule change dialog.
function ShowRuleDialog(RuleLabel)
    local ruleDialog = InputDialog(GUI, 'Game Rules')
    GUI.ruleDialog = ruleDialog
    ruleDialog.OnInput = function(self, rules)
        SetGameOption("GameRules", rules, true)
    end
end

-- Faction selector
function CreateUI_Faction_Selector(lastFaction)
    -- Build a list of button objects from the list of defined factions. Each faction will use the
    -- faction key as its RadioButton texture path offset.
    local buttons = {}
    for i, faction in FactionData.Factions do
        buttons[i] = {
            texturePath = faction.Key
        }
    end

    -- Special-snowflaking for the random faction.
    table.insert(buttons, {
        texturePath = "random"
    })

    local factionSelector = RadioButton(GUI.panel, "/factionselector/", buttons, lastFaction, true)
    GUI.factionSelector = factionSelector
    LayoutHelpers.AtLeftTopIn(factionSelector, GUI.panel, 407, 69)
    factionSelector.OnChoose = function(self, targetFaction, key)
        local localSlot = FindSlotForID(localPlayerID)
        Prefs.SetToCurrentProfile('LastFaction', targetFaction)
        GUI.slots[localSlot].faction:SetItem(targetFaction)
        SetPlayerOption(localSlot, 'Faction', targetFaction)
        gameInfo.PlayerOptions[localSlot].Faction = targetFaction

        ChangeBackgroundLobby(targetFaction)
        UIUtil.SetCurrentSkin(FACTION_NAMES[targetFaction])
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
        end
    end
end

function ShowLobbyOptionsDialog()
    local dialogContent = Group(GUI)
    dialogContent.Width:Set(420)
    dialogContent.Height:Set(240)

    local dialog = Popup(GUI, dialogContent)
    GUI.lobbyOptionsDialog = dialog

    local buttons = {
        {
            label = LOC("<LOC lobui_0406>") -- Factions
        },
        {
            label = LOC("<LOC lobui_0407>")  -- Concept art
        },
        {
            label = LOC("<LOC lobui_0408>") -- Screenshot
        },
        {
            label = LOC("<LOC lobui_0409>") -- Map
        },
        {
            label = LOC("<LOC lobui_0410>") -- None
        }
    }

    -- Label shown above the background mode selection radiobutton.
    local backgroundLabel = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0405> "), 16, 'Arial', true)
    local selectedBackgroundState = Prefs.GetFromCurrentProfile("LobbyBackground") or 1
    local backgroundRadiobutton = RadioButton(dialogContent, '/RADIOBOX/', buttons, selectedBackgroundState, false, true)

    LayoutHelpers.AtLeftTopIn(backgroundLabel, dialogContent, 15, 15)
    LayoutHelpers.AtLeftTopIn(backgroundRadiobutton, dialogContent, 15, 40)

    backgroundRadiobutton.OnChoose = function(self, index, key)
        Prefs.SetToCurrentProfile("LobbyBackground", index)
        ChangeBackgroundLobby()
    end
	--
	local currentFontSize = Prefs.GetFromCurrentProfile('LobbyChatFontSize') or 14
	local slider_Chat_SizeFont_TEXT = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0404> ").. currentFontSize, 14, 'Arial', true)
    LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont_TEXT, dialogContent, 27, 136)

	local slider_Chat_SizeFont = Slider(dialogContent, false, 9, 18, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), UIUtil.SkinnableFile('/slider02/slider-back_bmp.dds'))
    LayoutHelpers.AtRightTopIn(slider_Chat_SizeFont, dialogContent, 20, 156)
    slider_Chat_SizeFont:SetValue(currentFontSize)

	slider_Chat_SizeFont.OnValueChanged = function(self, newValue)
        local sliderValue = math.floor(slider_Chat_SizeFont._currentValue())
        slider_Chat_SizeFont_TEXT:SetText(LOC("<LOC lobui_0404> ").. sliderValue)
        GUI.chatDisplay:SetFont(UIUtil.bodyFont, sliderValue)
        Prefs.SetToCurrentProfile('LobbyChatFontSize', sliderValue)
	end
	--
    local cbox_WindowedLobby = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0402>"))
    LayoutHelpers.AtRightTopIn(cbox_WindowedLobby, dialogContent, 20, 42)
    Tooltip.AddCheckboxTooltip(cbox_WindowedLobby, {text='Windowed mode', body=LOC("<LOC lobui_0403>")})
    cbox_WindowedLobby.OnCheck = function(self, checked)
        local option
        if checked then
            option = 'true'
        else
            option = 'false'
        end
        Prefs.SetToCurrentProfile('WindowedLobby', option)
        SetWindowedLobby(checked)
    end
    --
    local cbox_StretchBG = UIUtil.CreateCheckbox(dialogContent, '/CHECKBOX/', LOC("<LOC lobui_0400>"))
    LayoutHelpers.AtRightTopIn(cbox_StretchBG, dialogContent, 20, 68)
    Tooltip.AddCheckboxTooltip(cbox_StretchBG, {text='Stretch Background', body=LOC("<LOC lobui_0401>")})
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
    -- Quit button
    local QuitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Close")
    LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialogContent, 0)
    LayoutHelpers.AtBottomIn(QuitButton, dialogContent, 10)

    QuitButton.OnClick = function(self)
        dialog:Hide()
    end
    --
    local WindowedLobby = Prefs.GetFromCurrentProfile('WindowedLobby') or 'true'
    cbox_WindowedLobby:SetCheck(WindowedLobby == 'true', true)
	if defaultMode == 'windowed' then
		-- Already set Windowed in Game
		cbox_WindowedLobby:Disable()
	end
    --
    local LobbyBackgroundStretch = Prefs.GetFromCurrentProfile('LobbyBackgroundStretch') or 'true'
    cbox_StretchBG:SetCheck(LobbyBackgroundStretch == 'true', true)
end

-- Experimental Animated Text Function
SetText2 = function(self, text, delay)
    if self:GetText() ~= text then
        self:StreamText(text, delay)
    end
end

-- Load and return the current list of presets from persistent storage.
function LoadPresetsList()
    return Prefs.GetFromCurrentProfile("LobbyPresets") or {}
end

-- Write the given list of preset profiles to persistent storage.
function SavePresetsList(list)
    Prefs.SetToCurrentProfile("LobbyPresets", list)
    SavePreferences()
end

-- Show the lobby preset UI.
function ShowPresetDialog()
    local dialogContent = Group(GUI)
    dialogContent.Width:Set(600)
    dialogContent.Height:Set(530)

    local presetDialog = Popup(GUI, dialogContent)
    presetDialog.OnClosed = presetDialog.Destroy
    GUI.presetDialog = presetDialog

    -- Title
    local titleText = UIUtil.CreateText(dialogContent, 'Lobby Presets', 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(titleText, dialogContent, 0)
    LayoutHelpers.AtTopIn(titleText, dialogContent, 10)

    -- Preset List
    local PresetList = ItemList(dialogContent)
    PresetList:SetFont(UIUtil.bodyFont, 14)
    PresetList:ShowMouseoverItem(true)
    PresetList.Width:Set(265)
    PresetList.Height:Set(430)
    LayoutHelpers.DepthOverParent(PresetList, dialogContent, 10)
    LayoutHelpers.AtLeftIn(PresetList, dialogContent, 14)
    LayoutHelpers.AtTopIn(PresetList, dialogContent, 38)
    UIUtil.CreateLobbyVertScrollbar(PresetList, 2)

    -- Info List
    local InfoList = ItemList(dialogContent)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    InfoList:SetColors(nil, "00000000")
    InfoList:ShowMouseoverItem(true)
    InfoList.Width:Set(281)
    InfoList.Height:Set(430)
    LayoutHelpers.RightOf(InfoList, PresetList, 26)

    -- Quit button
    local QuitButton = UIUtil.CreateButtonStd(dialogContent, '/dialogs/close_btn/close')
    LayoutHelpers.AtRightIn(QuitButton, dialogContent, 1)
    LayoutHelpers.AtTopIn(QuitButton, dialogContent, 1)

    -- Load button
    local LoadButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Load")
    LayoutHelpers.AtLeftIn(LoadButton, dialogContent, -2)
    LayoutHelpers.AtBottomIn(LoadButton, dialogContent, 10)
    LoadButton:Disable()

    -- Create button. Occupies the same space as the load button, when available.
    local CreateButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Create")
    LayoutHelpers.RightOf(CreateButton, LoadButton, 28)

    -- Save button
    local SaveButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Save")
    LayoutHelpers.RightOf(SaveButton, CreateButton, 28)
    SaveButton:Disable()

    -- Delete button
    local DeleteButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Delete")
    LayoutHelpers.RightOf(DeleteButton, SaveButton, 28)
    DeleteButton:Disable()

    LoadButton.OnClick = function(self)
        LoadPreset(PresetList:GetSelection() + 1)
    end
    
    QuitButton.OnClick = function(self)
        presetDialog:Hide()
    end

    CreateButton.OnClick = function(self)
        local dialogComplete = function(self, presetName)
            if presetName == "" then
                return
            end
            local profiles = LoadPresetsList()
            table.insert(profiles, GetPresetFromSettings(presetName))
            SavePresetsList(profiles)

            RefreshAvailablePresetsList(PresetList)

            PresetList:SetSelection(0)
            PresetList:OnClick(0)
        end

        CreateInputDialog(GUI, "Select name for new preset", dialogComplete)
    end

    SaveButton.OnClick = function(self)
        local selectedPreset = PresetList:GetSelection() + 1

        SavePreset(selectedPreset)
        ShowPresetDetails(selectedPreset, InfoList)
    end

    DeleteButton.OnClick = function(self)
        local profiles = LoadPresetsList()

        -- Converting between zero-based indexing in the list and the table indexing...
        table.remove(profiles, PresetList:GetSelection() + 1)

        SavePresetsList(profiles)
        RefreshAvailablePresetsList(PresetList)

        -- And clear the detail view.
        InfoList:DeleteAllItems()
    end

    -- Called when the selected item in the preset list changes.
    local onListItemChanged = function(self, row)
        ShowPresetDetails(row + 1, InfoList)
        LoadButton:Enable()
        SaveButton:Enable()
        DeleteButton:Enable()
    end

    -- Because GPG's event model is painfully retarded..
    PresetList.OnKeySelect = onListItemChanged
    PresetList.OnClick = function(self, row, event)
        self:SetSelection(row)
        onListItemChanged(self, row)
    end

    PresetList.OnDoubleClick = function(self, row)
        LoadPreset(row + 1)
    end

    -- When the user double-clicks on a metadata field, give them a popup to change its value.
    InfoList.OnDoubleClick = function(self, row)
        -- Closure copy, accounting for zero-based indexing in ItemList.
        local theRow = row + 1

        local nameChanged = function(self, str)
            if str == "" then
                return
            end

            local profiles = LoadPresetsList()
            profiles[theRow].Name = str
            SavePresetsList(profiles)

            -- Update the name displayed in the presets list, preserving selection.
            local lastselect = PresetList:GetSelection()
            RefreshAvailablePresetsList(PresetList)
            PresetList:SetSelection(lastselect)

            ShowPresetDetails(theRow, InfoList)
        end

        if row == 0 then
            CreateInputDialog(GUI, "Rename your preset", nameChanged)
        end
    end

    -- Show the "Double-click to edit" tooltip when the user mouses-over an editable field.
    InfoList.OnMouseoverItem = function(self, row)
        -- Determine which metadata cell they moused-over, if any.
        local metadataType
        -- For now, only name is editable. A nice mechanism to edit game preferences seems plausible.
        if row == 0 then
            metadataType = "Preset name"
        else
            Tooltip.DestroyMouseoverDisplay()
            return
        end

        local tooltip = {
            text = metadataType,
            body = "Double-click to edit"
        }

        Tooltip.CreateMouseoverDisplay(self, tooltip, 0, true)
    end

    RefreshAvailablePresetsList(PresetList)
    if PresetList:GetItemCount() == 0 then
        CreateHelpWindow()
    end
end

function CreateHelpWindow()
    local dialogContent = Group(GUI)
    dialogContent.Width:Set(420)
    dialogContent.Height:Set(146)

    local helpWindow = Popup(GUI, dialogContent)

    -- Info List --
    local InfoList = ItemList(dialogContent)
    InfoList:SetFont(UIUtil.bodyFont, 14)
    InfoList:SetColors(nil, "00000000")
    InfoList.Width:Set(408)
    InfoList.Height:Set(120)
    LayoutHelpers.AtLeftIn(InfoList, dialogContent, 13)
    LayoutHelpers.AtTopIn(InfoList, dialogContent, 10)
    local helpText = import('/lua/ui/lobby/presetHelp.lua').helpText
    local wrapped = import('/lua/maui/text.lua').WrapText(helpText, InfoList.Width(),
        function(curText) return InfoList:GetStringAdvance(curText) end)
    for i, line in wrapped do
        InfoList:AddItem(line)
    end
    
    -- OK button
    local OkButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
	LayoutHelpers.AtLeftIn(OkButton, dialogContent, 145)
    LayoutHelpers.AtBottomIn(OkButton, dialogContent, 8)
    LayoutHelpers.DepthOverParent(OkButton, InfoList, 5)
    OkButton.OnClick = function(self)
        helpWindow:Close()
    end
end

-- Create an input dialog with the given title and listener function.
function CreateInputDialog(parent, title, listener)
    local dialog = InputDialog(parent, title, listener)
    dialog.OnInput = listener
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

-- Refresh list of presets
function RefreshAvailablePresetsList(PresetList)
    local profiles = LoadPresetsList()
    PresetList:DeleteAllItems()

    for k, v in profiles do
        table.print(v)
        PresetList:AddItem(v.Name)
    end
end

-- Update the right-hand panel of the preset dialog to show the contents of the currently selected
-- profile (passed by name as a parameter)
function ShowPresetDetails(preset, InfoList)
    local profiles = LoadPresetsList()
    InfoList:DeleteAllItems()
    InfoList:AddItem('Preset Name: ' .. profiles[preset].Name)

    if DiskGetFileInfo(profiles[preset].MapPath) then
        InfoList:AddItem('Map: ' .. profiles[preset].MapName)
    else
        InfoList:AddItem('Map: Unavailable (' .. profiles[preset].MapName .. ')')
    end

    InfoList:AddItem('')

    -- For each mod, look up its name and pretty-print it.
    local allMods = Mods.AllMods()
    for modId, v in profiles[preset].GameMods do
        if v then
            InfoList:AddItem('Mod: ' .. allMods[modId].name)
        end
    end

    InfoList:AddItem('')
    InfoList:AddItem('Settings :')
    for k, v in sortedpairs(profiles[preset].GameOptions) do
        InfoList:AddItem('- '..k..' : '..tostring(v))
    end
end

-- Create a preset table representing the current configuration.
function GetPresetFromSettings(presetName)
    return {
        Name = presetName,
        MapName = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile).name,
        MapPath = gameInfo.GameOptions.ScenarioFile,
        GameOptions = gameInfo.GameOptions,
        GameMods = gameInfo.GameMods
    }
end

-- Load the given preset
function LoadPreset(presetIndex)
    local preset = LoadPresetsList()[presetIndex]

    SetGameOptions(preset.GameOptions, true)
    
    -- gameInfo.GameMods is a map from mod identifiers to truthy values for every activated mod.
    -- Unfortunately, HostUpdateMods is painfully stupid and reads selectedMods, which is a list of
    -- mod identifiers to be activated.
    -- Ultimately, we want to make HostUpdateMods not be stupid, so presets just pickle the GameMods
    -- map directly. For now, though, that means we have the following stupid loop to keep the
    -- retarded HostUpdateMods working.
    --
    -- Thanks, William.
    selectedMods = {}
    for k, v in preset.GameMods do
        if v then
            table.insert(selectedMods, k)
        end
    end

    HostUpdateMods()

    GUI.presetDialog:Hide()
    UpdateGame()
end

-- Write the current settings to the given preset profile index
function SavePreset(index)
    local profiles = LoadPresetsList()

    local selectedPreset = index
    profiles[selectedPreset] = GetPresetFromSettings(profiles[selectedPreset].Name)

    SavePresetsList(profiles)
end

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

-- Update the combobox for the given slot so it correctly shows the set of available colours.
-- causes availableColours[slot] to be repopulated.
function Check_Availaible_Color(slot)
    availableColours[slot] = {}

    -- For each possible colour, scan the slots to try and find it and, if unsuccessful, add it to
    -- the available colour set.
    local allColours = gameColors.PlayerColors
    for k, v in allColours do
        local found = false
        for ii = 1, LobbyComm.maxPlayerSlots do
            -- Skip this slot and empty slots.
            if slot ~= ii and gameInfo.PlayerOptions[ii] then
                if gameInfo.PlayerOptions[ii].PlayerColor == k then
                    found = true
                    break
                end
            end
        end

        if not found then
            availableColours[slot][k] = allColours[k]
        end
    end
    --
    GUI.slots[slot].color:ChangeBitmapArray(availableColours[slot], true)
    GUI.slots[slot].color:SetItem(gameInfo.PlayerOptions[slot].PlayerColor)
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
    local dialogContent = Group(GUI)
    dialogContent.Width:Set(526)
    dialogContent.Height:Set(450)

    local Changelog = import('/lua/ui/lobby/changelog.lua')
    local changelogPopup = Popup(GUI, dialogContent)
    changelogPopup.OnClosed = function()
        Prefs.SetToCurrentProfile('LobbyChangelog', Changelog.last_version)
    end

    -- Title --
    local text0 = UIUtil.CreateText(dialogContent, LOC("<LOC lobui_0412>"), 17, 'Arial Gras', true)
    LayoutHelpers.AtHorizontalCenterIn(text0, dialogContent, 0)
    LayoutHelpers.AtTopIn(text0, dialogContent, 10)

    -- Info List --
    local InfoList = ItemList(dialogContent)
    InfoList:SetFont(UIUtil.bodyFont, 11)
    InfoList:SetColors(nil, "00000000")
    InfoList.Width:Set(498)
    InfoList.Height:Set(360)
    LayoutHelpers.AtLeftIn(InfoList, dialogContent, 10)
	LayoutHelpers.AtRightIn(InfoList, dialogContent, 26)
    LayoutHelpers.AtTopIn(InfoList, dialogContent, 38)
    UIUtil.CreateLobbyVertScrollbar(InfoList)
	InfoList.OnClick = function(self) end
	-- See only new Changelog by version
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
    local OkButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "Ok")
	LayoutHelpers.AtLeftIn(OkButton, dialogContent, 0)
    LayoutHelpers.AtBottomIn(OkButton, dialogContent, 10)
    OkButton.OnClick = changelogPopup.Close
end
