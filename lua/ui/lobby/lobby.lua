--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Chris Blackwell
--* Summary: Game selection UI
--*
--* Copyright © 2005 Gas Powered Games, Inc. All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local Prefs = import('/lua/user/prefs.lua')
local MapUtil = import('/lua/ui/maputil.lua')
local Group = import('/lua/maui/group.lua').Group
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Edit = import('/lua/maui/edit.lua').Edit
local LobbyComm = import('/lua/ui/lobby/lobbyComm.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Mods = import('/lua/mods.lua')
local ModManager = import('/lua/ui/dialogs/modmanager.lua')
local FactionData = import('/lua/factions.lua')
local Text = import('/lua/maui/text.lua').Text
local Trueskill = import('/lua/ui/lobby/trueskill.lua')
local Player = import('/lua/ui/lobby/trueskill.lua').Player
local Rating = import('/lua/ui/lobby/trueskill.lua').Rating
local Teams = import('/lua/ui/lobby/trueskill.lua').Teams

local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOpts = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts
local gameColors = import('/lua/gameColors.lua').GameColors
local numOpenSlots = LobbyComm.maxPlayerSlots
local formattedOptions = {}
local teamIcons = {
    '/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
    '/lobby/team_icons/team_5_icon.dds',
    '/lobby/team_icons/team_6_icon.dds',
}

--// Xinnony DEBUG
XinnonyDebug = 0
-- 0 = NO DEBUG (Default)
-- -1 = DEBUG OTHER
-- 1 = DEBUG Country
-- 2 = DEBUG RuleTitle
-- 3 = DEBUG PeerDisconnected
-- 4 = DEBUG Background
--\\ Xinnony DEBUG
--// Table of Tooltip Country - Xinnony
local PrefLanguageTooltipTitle={}
local PrefLanguageTooltipText={}
--\\ Stop - Table of Tooltip Country
--// Get a value on /Country CommandLine in FA.exe - Xinnony
local PrefLanguage = GetCommandLineArg("/country", 1)
if PrefLanguage[1] == '' then
    LOG('COUNTRY - Country has not been found')
    PrefLanguage[1] = "world"
elseif PrefLanguage[1] == nil then
    LOG('COUNTRY - Country has not been found')
    PrefLanguage = "world"
else
    PrefLanguage = tostring(string.lower(PrefLanguage[1]))
end
--\\ Stop - Get a value on /Country CommandLine in FA.exe

local LASTXinnoBackground = '' -- For prevent the infinite loop to Background

local connectedTo = {}

local availableMods = {} # map from peer ID to set of available mods; each set is a map from "mod id"->true
local selectedMods = nil

local commandQueueIndex = 0
local commandQueue = {}

local launchThread = false
local quickRandMap = true

local lastUploadedMap = nil

local CPU_BenchmarkList = {} -- Stores CPU benchmark data

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

local playerRating = math.floor(playerMean - 3 * playerDeviation)

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

--// Menu in Slot select -- Add new function by Xinnony
function FuncSlotMenuData()
    slotMenuStrings = {
        open = "<LOC lobui_0219>Open",
        close = "<LOC lobui_0220>Close",
        closed = "<LOC lobui_0221>Closed",
        occupy = "<LOC lobui_0222>Occupy",
        pm = "<LOC lobui_0223>Private Message",
        remove_to_kik = "Remove Player",
        remove_to_observer = "Move Player to Observer",
        move_player_to_slot1 = "Move Player to slot 1",
        move_player_to_slot2 = "Move Player to slot 2",
        move_player_to_slot3 = "Move Player to slot 3",
        move_player_to_slot4 = "Move Player to slot 4",
        move_player_to_slot5 = "Move Player to slot 5",
        move_player_to_slot6 = "Move Player to slot 6",
        move_player_to_slot7 = "Move Player to slot 7",
        move_player_to_slot8 = "Move Player to slot 8",
        move_player_to_slot9 = "Move Player to slot 9",
        move_player_to_slot10 = "Move Player to slot 10",
        move_player_to_slot11 = "Move Player to slot 11",
        move_player_to_slot12 = "Move Player to slot 12",
    }
    slotMenuData = {
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
    for i = 1, numOpenSlots, 1 do
        table.insert(slotMenuData.player.host, 'move_player_to_slot'..i)
    end
end
FuncSlotMenuData()
--\\ Stop Menu in Slot select

local function GetAITooltipList()
    local aitypes = import('/lua/ui/lobby/aitypes.lua').aitypes
    local retTable = {}
    #this is to fix tooltip problem
    for i = 1, 2 do
            table.insert(retTable, nil)
    end
    #end new faf part
    for i, v in aitypes do
        table.insert(retTable, 'aitype_'..v.key)
    end
    return retTable
end

local function GetSlotMenuTables(stateKey, hostKey)
    local keys = {}
    local strings = {}

    if not slotMenuData[stateKey] then
        ERROR("Invalid slot menu state selected: " .. stateKey)
    end

    if not slotMenuData[stateKey][hostKey] then
        ERROR("Invalid slot menu host key selected: " .. hostKey)
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

local function HandleSlotSwitches(moveFrom, moveTo) -- Xinnony (Factored by Vicarian)
    local pOpts = gameInfo.PlayerOptions -- rename for readability
    local toName = pOpts[moveTo].PlayerName
    local toID = pOpts[moveTo].OwnerID
    local toRatingColor = pOpts[moveTo].RC
    local toRating = pOpts[moveTo].PL
    local toFaction = pOpts[moveTo].Faction
    local toNumGame = pOpts[moveTo].NG

    local fromName = pOpts[moveFrom].PlayerName
    local fromID = pOpts[moveFrom].OwnerID
    local fromRatingColor = pOpts[moveFrom].RC
    local fromRating = pOpts[moveFrom].PL
    local fromFaction = pOpts[moveFrom].Faction
    local fromNumGame = pOpts[moveFrom].NG

    if pOpts[moveFrom].Human and moveFrom != moveTo then -- IF Player moveFrom is Human and Player moveFrom NOT in moveTo
        -- IF Slot moveToSlot is Human and NOT Ready, AND IF Player moveFromSlot is NOT Ready
        if pOpts[moveTo].Human and not pOpts[moveTo].Ready and not pOpts[moveFrom].Ready then
            HostConvertPlayerToObserver(toID, toName, moveTo) -- Move Slot moveTo to Observer
            ClearSlotInfo(moveTo)
            HostTryMovePlayer(fromID, moveFrom, moveTo) -- Move Player moveFrom to Slot moveTo
            ClearSlotInfo(moveFrom)
            HostConvertObserverToPlayer(toID, toName, FindObserverSlotForID(toID), moveFrom, toFaction, toRating,
                                        toRatingColor, toNumGame)
        -- IF Player X is Human and Ready and Slot Ready
        elseif pOpts[moveFrom].Human and pOpts[moveTo].Human and pOpts[moveFrom].Ready and pOpts[moveTo].Ready then
            AddChatText('You cannot move the player in slot '..moveFrom..' to slot '..moveTo..' because the players in slots '
                        ..moveFrom..' and '..moveTo..' are ready.') -- (for the moment (reasons: hide bug))')
        elseif pOpts[moveFrom].Human and pOpts[moveFrom].Ready then -- IF Player X is Human and Ready
            AddChatText('You cannot move the player in slot '..moveFrom..' to slot '..moveTo..' because the player in slot '
                        ..moveFrom..' is ready.') -- (for the moment (reasons: hide bug))')
        elseif pOpts[moveTo].Human and pOpts[moveTo].Ready then -- IF Slot 1 is Human and Ready
            AddChatText('You cannot move the player in slot '..moveFrom..' to slot '..moveTo..' because the player in slot '
                        ..moveTo..' is ready.') -- (for the moment (reasons: hide bug))')
        elseif not pOpts[moveTo].Human and not pOpts[moveTo].Ready then -- IF Slot 1 is NOT Human and NOT Ready
            HostTryMovePlayer(pOpts[moveFrom].OwnerID, moveFrom, moveTo)
        else
            AddChatText('You cannot move the player in slot '..moveFrom..'.')
        end
    else
        AddChatText('You cannot move the Player in slot '..moveFrom..' to Slot '..moveTo..'.')
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
                requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
                requestedPL = playerRating
                requestedRC = ratingColor
                requestedNG = numGames
                HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID), slot,
                                            requestedFaction, requestedPL, requestedRC, requestedNG)
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

    --// Move player slot to slot -- Xinnony (Factored by Vicarian)
    elseif key == 'move_player_to_slot1' then
        HandleSlotSwitches(slot, 1)
    elseif key == 'move_player_to_slot2' then
        HandleSlotSwitches(slot, 2)
    elseif key == 'move_player_to_slot3' then
        HandleSlotSwitches(slot,3)
    elseif key == 'move_player_to_slot4' then
        HandleSlotSwitches(slot,4)
    elseif key == 'move_player_to_slot5' then
        HandleSlotSwitches(slot,5)
    elseif key == 'move_player_to_slot6' then
        HandleSlotSwitches(slot,6)
    elseif key == 'move_player_to_slot7' then
        HandleSlotSwitches(slot,7)
    elseif key == 'move_player_to_slot8' then
        HandleSlotSwitches(slot,8)
    elseif key == 'move_player_to_slot9' then
        HandleSlotSwitches(slot,9)
    elseif key == 'move_player_to_slot10' then
        HandleSlotSwitches(slot,10)
    elseif key == 'move_player_to_slot11' then
        HandleSlotSwitches(slot,11)
    elseif key == 'move_player_to_slot12' then
        HandleSlotSwitches(slot,12)
    --\\ Stop Move player slot to slot
    --// Move Player slot to Observer -- Xinnony
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
                HostRemoveAI( slot)
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

    InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)

    -- Store off the validated playername
    localPlayerName = lobbyComm:GetLocalPlayerName()
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
    if string.find(addressAndPort, '127.0.0.1') then
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..")")
    else
        LOG("ConnectToPeer (name=" .. name .. ", uid=" .. uid .. ", address=" .. addressAndPort ..", USE PROXY)")
    end
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
    LOG("DisconnectFromPeer (uid=" .. uid ..")")
    if wasConnected(uid) then table.remove(connectedTo, uid) end
    lobbyComm:DisconnectFromPeer(uid)
end

function SetHasSupcom(supcomInstalled)
    hasSupcom = supcomInstalled
end

function SetHasForgedAlliance(faInstalled)
    hadFA = faInstalled
end

function FindSlotForID(id)
    for k,player in gameInfo.PlayerOptions do
        if player.OwnerID == id and player.Human then
            return k
        end
    end
    return nil
end

function FindNameForID(id) -- Xinnony
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
    return FindSlotForID(id) != nil
end

function IsObserver(id)
    return FindObserverSlotForID(id) != nil
end


-- update the data in a player slot
function SetSlotInfo(slot, playerInfo)
    local isLocallyOwned
    if IsLocallyOwned(slot) then
        if gameInfo.PlayerOptions[slot]['Ready'] then
            DisableSlot(slot, true)
        else
            EnableSlot(slot)
        end
        isLocallyOwned = true
        if not hasSupcom then
            GUI.slots[slot].faction:Disable()
        end
    else
        DisableSlot(slot)
        isLocallyOwned = false
    end

    local hostKey
    if lobbyComm:IsHost() then
        hostKey = 'host'
    else
        hostKey = 'client'
    end

    if not playerInfo.Human and lobbyComm:IsHost() then
    end

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
        if lobbyComm:IsHost() and (slotState == 'open' or slotState == 'ai') then
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
        --GUI.slots[slot].ratingText:SetColor('Crimson') --= #dc143c
    --else
        GUI.slots[slot].ratingText:SetText(playerInfo.PL or '')
    --end
    GUI.slots[slot].ratingText:SetColor(playerInfo.RC or 'ffffffff')

    GUI.slots[slot].numGamesGroup:Show()
    GUI.slots[slot].numGamesText:SetText(playerInfo.NG or "")

    GUI.slots[slot].name:Show()
    GUI.slots[slot].name:SetTitleText(LOC(playerInfo.PlayerName))
    
    --// Color the Name in Slot by State - Xinnony & Vicarian
    if slotState == 'ai' then
        GUI.slots[slot].name:SetTitleTextColor("dbdbb9") -- Beige Color for AI
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    elseif slotState == 'player' then
        GUI.slots[slot].name:SetTitleTextColor("64d264") -- Green Color for Players
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
    elseif slotState == 'open' then
        GUI.slots[slot].name:SetTitleTextColor('B9BFB9')--UIUtil.fontColor) -- Normal Color for Open Slot
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    elseif isLocallyOwned then
        GUI.slots[slot].name:SetTitleTextColor("6363d2") -- Blue Color for You
        GUI.slots[slot].name._text:SetFont('Arial Gras', 15)
    else
        GUI.slots[slot].name:SetTitleTextColor(UIUtil.fontColor) -- Normal Color for Other
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    end
    if FindSlotForID(hostID) then
        GUI.slots[FindSlotForID(hostID)].name:SetTitleTextColor("ffc726") -- Orange Color for Host
        GUI.slots[FindSlotForID(hostID)].name._text:SetFont('Arial Gras', 15)
    end
    --\\ Stop - Color the Name in Slot by State

    GUI.slots[slot].faction:Show()
    GUI.slots[slot].faction:SetItem(playerInfo.Faction)

    GUI.slots[slot].color:Show()
    GUI.slots[slot].color:SetItem(playerInfo.PlayerColor)

    GUI.slots[slot].team:Show()
    GUI.slots[slot].team:SetItem(playerInfo.Team)

    if lobbyComm:IsHost() then
        GpgNetSend('PlayerOption', string.format("faction %s %d %s", playerInfo.PlayerName, slot, playerInfo.Faction))
        GpgNetSend('PlayerOption', string.format("color %s %d %s", playerInfo.PlayerName, slot, playerInfo.PlayerColor))
        GpgNetSend('PlayerOption', string.format("team %s %d %s", playerInfo.PlayerName, slot, playerInfo.Team))
        GpgNetSend('PlayerOption', string.format("startspot %s %d %s", playerInfo.PlayerName, slot, slot))
    end
    if GUI.slots[slot].ready then
        if playerInfo.Human then
            GUI.slots[slot].ready:Show()
            GUI.slots[slot].ready:SetCheck(playerInfo.Ready, true)
        else
            GUI.slots[slot].ready:Hide()
        end
    end

    if GUI.slots[slot].pingGroup then
        if isLocallyOwned or not playerInfo.Human then
            GUI.slots[slot].pingGroup:Hide()
        else
            GUI.slots[slot].pingGroup:Hide() -- Temporary - Should be show - request by ZePilOt
        end
    end

    if isLocallyOwned and playerInfo.Human then
        Prefs.SetToCurrentProfile('LastColor', playerInfo.PlayerColor)
        Prefs.SetToCurrentProfile('LastFaction', playerInfo.Faction)
    end

    --// Change the background according to the chosen Faction - Xinnony
    --ChangeBackgroundLobby(slot, Prefs.GetFromCurrentProfile('LastFaction'))
    --\\ Stop - Change the background according to the chosen Faction
    --// Show the Country Flag in slot - Xinnony
    SetSlotCountryFlag(slot, playerInfo.COUNTRY)
    --\\ Stop - Show the Country Flag in slot

    --CPU Benchmark code
    SetSlotCPUBar(slot, playerInfo) --Update the slot CPU bar
    --End CPU Benchmark code
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
    if stateKey == 'closed' then
        GUI.slots[slot].name:SetTitleTextColor("Crimson")
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    else
        GUI.slots[slot].name:SetTitleTextColor('B9BFB9')--UIUtil.fontColor)
        GUI.slots[slot].name._text:SetFont('Arial Gras', 12)
    end
    if lobbyComm:IsHost() and (stateKey == 'open' or stateKey == 'ai') then
        Tooltip.AddComboTooltip(GUI.slots[slot].name, GetAITooltipList())
    else
        Tooltip.RemoveComboTooltip(GUI.slots[slot].name)
    end

    -- hide these to clear slot of visible data
    GUI.slots[slot].KinderCountry:Hide() -- Hide the Country Flag
    GUI.slots[slot].ratingGroup:Hide()
    GUI.slots[slot].numGamesGroup:Hide()
    GUI.slots[slot].faction:Hide()
    GUI.slots[slot].color:Hide()
    GUI.slots[slot].team:Hide()
    GUI.slots[slot].multiSpace:Hide()
    if GUI.slots[slot].pingGroup then
        GUI.slots[slot].pingGroup:Hide()
    end
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

local function shuffle( a )
        local c = table.getn(a)
        for i = 1, c do
                local ndx0 = math.random( 1, c )
                a[ ndx0 ], a[ i ] = a[ i ], a[ ndx0 ]
        end
        return a
end

local function AssignRandomStartSpots(gameInfo)
    if gameInfo.GameOptions['TeamSpawn'] == 'random' then
        local numAvailStartSpots = nil
        local scenarioInfo = nil
        if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") then
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

        local norating = false
        local ratingTable = {}

        for i = 1, numAvailStartSpots do
            if gameInfo.PlayerOptions[i] then
                if gameInfo.PlayerOptions[i].PL then
                    rating = gameInfo.PlayerOptions[i].PL
                    ratingTable[rating] = i
                else
                    norating = true
                end
            end
        end

        a = {}
        for n in pairs(ratingTable) do table.insert(a, n) end
        table.sort(a)

        team1 = {}
        team2 = {}
        for i = 1, numAvailStartSpots do
            if gameInfo.ClosedSlots[i] == nil then
                if gameInfo.GameOptions['AutoTeams'] == 'lvsr' then

                    local midLine = GUI.mapView.Left() + (GUI.mapView.Width() / 2)
                    local markerPos = GUI.markers[i].marker.Left()

                    if markerPos < midLine then
                        table.insert(team1, i)
                    else
                        table.insert(team2, i)
                    end

                elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
                    local midLine = GUI.mapView.Top() + (GUI.mapView.Height() / 2)
                    local markerPos = GUI.markers[i].marker.Top()

                    if markerPos < midLine then
                        table.insert(team1, i)
                    else
                        table.insert(team2, i)
                    end

                elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
                    if i == 1 or i == 3 or i == 5 or i == 7 or i == 9 or i == 11 then
                        table.insert(team1, i)
                    else
                        table.insert(team2, i)
                    end
                end
            end
        end

        -- shuffle the array for randomness.
        team1 = shuffle(team1)
        team2 = shuffle(team2)

        local team1Increment = 1
        local team2Increment = 1

        for i = 1, numAvailStartSpots do
            if gameInfo.PlayerOptions[i] then
                -- don't select closed slots for random pick
                local randSlot
                local goodteam = nil
                for k,n in ipairs(a) do
                    if a[n] == i then
                        goodteam = Trueskill.assignToTeam(k-1)

                    end
                end

                repeat

                    if gameInfo.GameOptions['AutoTeams'] == 'manual' or gameInfo.GameOptions['AutoTeams'] == 'none' then
                        randSlot = math.random(1,numAvailStartSpots)
                    else
                        if goodteam and norating == false then
                            if goodteam == 1 then
                                randSlot = team1[team1Increment]
                                team1Increment = team1Increment + 1
                            else
                                randSlot = team2[team2Increment]
                                team2Increment = team2Increment + 1
                            end
                        else
                            randSlot = math.random(1,numAvailStartSpots)
                        end
                    end


                until gameInfo.ClosedSlots[randSlot] == nil


                local temp = nil
                if gameInfo.PlayerOptions[randSlot] then
                    temp = table.deepcopy(gameInfo.PlayerOptions[randSlot])
                end

                gameInfo.PlayerOptions[randSlot] = table.deepcopy(gameInfo.PlayerOptions[i])
                gameInfo.PlayerOptions[i] = temp
            end
        end
    end

end

-- This fonction is used to double check the observers.
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
    if gameInfo.GameOptions['AutoTeams'] == 'pvsi' or gameInfo.GameOptions['RandomMap'] != 'Off' then
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

local function SendSystemMessage(text)
    local data = {
        Type = "SystemMessage",
        Text = text,
    }
    lobbyComm:BroadcastData(data)
    AddChatText(text)
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
    if targetID != localPlayerID then
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
    if numOpenSlots != numAvailStartSpots then
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
            if not moreThanOneTeam and lastTeam and lastTeam != player.Team then
                moreThanOneTeam = true
            end
            if player.Team != 1 then
                allFFA = false
            end
            lastTeam = player.Team
        end
    end

    if gameInfo.GameOptions['Victory'] != 'sandbox' then
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
                if gameInfo.PlayerOptions[i].Team != 1 and gameInfo.PlayerOptions[i].Team != nil then
                    n = n + 1
                end
                i = i + 1
            until i == 9
            if totalPlayers > 3 and not stillAllowLockedTeams and totalPlayers != n and gameInfo.GameOptions['AutoTeams']
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

        if gameInfo.GameOptions['RandomMap'] != 'Off' then
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
        lobbyComm:LaunchGame(gameInfo)
    end

    --if singlePlayer then--or HasCommandLineArg('/gpgnet') then
        LaunchGame()
    --else
    --// This code is a pre-launch timer, disable by a community
        --launchThread = ForkThread(function()
            --GUI.launchGameButton.label:SetText(LOC("<LOC PROFILE_0005>"))
            --GUI.launchGameButton.OnClick = function(self)
                --CancelLaunch()
                --self.OnClick = function(self) TryLaunch(false) end
                --GUI.launchGameButton.label:SetText(LOC("<LOC lobui_0212>Launch"))
            --end
            --if gameInfo.GameOptions['RandomMap'] != 'Off' then
                --local rMapSizeFil = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFil
                --local rMapSizeFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFilLim
                --local rMapPlayersFil = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFil
                --local rMapPlayersFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFilLim
                --SendSystemMessage("-------------------------------------------------------------------------------------------------------------------")
                --if rMapSizeFilLim == 'equal' then
                    --rMapSizeFilLim = '='
                --end
                --if rMapSizeFilLim == 'less' then
                    --rMapSizeFilLim = '<='
                --end
                --if rMapSizeFilLim == 'greater' then
                    --rMapSizeFilLim = '>='
                --end
                --if rMapPlayersFilLim == 'equal' then
                    --rMapPlayersFilLim = '='
                --end
                --if rMapPlayersFilLim == 'less' then
                    --rMapPlayersFilLim = '<='
                --end
                --if rMapPlayersFilLim == 'greater' then
                    --rMapPlayersFilLim = '>='
                --end
                --if rMapSizeFil != 0 and rMapPlayersFil != 0 then
                    --SendSystemMessage(LOCF("<LOC lobui_0558>Random Map enabled: Map Size is %s %dkm and Number of Players" ..
                    --                       " are %s %d", rMapSizeFilLim, rMapSizeFil, rMapPlayersFilLim, rMapPlayersFil))
                --elseif rMapSizeFil != 0 then
                    --SendSystemMessage(LOCF("<LOC lobui_0559>Random Map enabled: Map Size is %s %dkm and Number of Players" ..
                    --                       " are ALL", rMapSizeFilLim, rMapSizeFil))
                --elseif rMapPlayersFil != 0 then
                    --SendSystemMessage(LOCF("<LOC lobui_0560>Random Map enabled: Map Size is ALL and Number of Players " ..
                    --                       "are %s %d", rMapPlayersFilLim, rMapPlayersFil))
                --else
                    --SendSystemMessage(LOC("<LOC lobui_0561>Random Map enabled: Map Size is ALL and Number of Players are " ..
                    --                      " ALL"))
                --end
                --SendSystemMessage("-------------------------------------------------------------------------------------" ..
                --                  "------------------------------")
            --end
            --local timer = 5
            --while timer > 0 do
                --local text = LOCF('%s %d', "<LOC lobby_0001>Game will launch in", timer)
                --SendSystemMessage(text)
                --timer = timer - 1
                --WaitSeconds(1)
            --end
            --LaunchGame()
        --end)
    --end
end

local function AlertHostMapMissing()
    if lobbyComm:IsHost() then
        HostPlayerMissingMapAlert(localPlayerID)
    else
        lobbyComm:SendData(hostID, {Type = 'MissingMap', Id = localPlayerID})
    end
end

local function UpdateGame()
    -- if anything happens to switch a no SupCom player to a faction other than Seraphim, switch them back
    local playerSlot = FindSlotForID(localPlayerID)

    if not gameInfo.PlayerOptions[playerSlot].MEAN then
        SetPlayerOption(playerSlot, 'MEAN', playerMean)
    end

    if not gameInfo.PlayerOptions[playerSlot].DEV then
        SetPlayerOption(playerSlot, 'DEV', playerDeviation)
    end

    if not gameInfo.PlayerOptions[playerSlot].COUNTRY then
        SetPlayerOption(playerSlot, 'COUNTRY', PrefLanguage)
    end

    if not gameInfo.PlayerOptions[playerSlot].PL then
        SetPlayerOption(playerSlot, 'PL', playerRating)
    end

    if not gameInfo.PlayerOptions[playerSlot].RC then
        SetPlayerOption(playerSlot, 'RC', ratingColor)
    end

    if not gameInfo.PlayerOptions[playerSlot].NG then
        SetPlayerOption(playerSlot, 'NG', numGames)
    end

    if not hasSupcom then
        local playerSlot = FindSlotForID(localPlayerID)
        if gameInfo.PlayerOptions[playerSlot] and gameInfo.PlayerOptions[playerSlot].Faction != 4 and not
               IsObserver(localPlayerID) then
            SetPlayerOption(playerSlot, 'Faction', 4)
            return
        end
    end

    local scenarioInfo = nil

    if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)

        if scenarioInfo and scenarioInfo.map and scenarioInfo.map != '' then
            local mods = Mods.GetGameMods(gameInfo.GameMods)
            PrefetchSession(scenarioInfo.map, mods, true)
        else
            AlertHostMapMissing()
        end
    end

    if not GUI.uiCreated then return end

    if lobbyComm:IsHost() then
        GUI.gameoptionsButton:Show()
        GUI.launchGameButton:Show()

        --if GUI.allowObservers then
            --GUI.allowObservers:Show()
        --end
        if not singlePlayer then
            if quickRandMap then
                GUI.randMap:Enable()
            else
                GUI.randMap:Disable()
            end
        end
    else
        --GUI.gameoptionsButton.label:SetText(LOC('<LOC tooltipui0145>'))
        GUI.gameoptionsButton.OnClick = function(self, modifiers)
            modstatus = ModManager.ClientModStatus(gameInfo.GameMods)
            ModManager.CreateDialog(GUI, true, OnModsChanged, true, modstatus)
        end
        Tooltip.AddButtonTooltip(GUI.gameoptionsButton, 'Lobby_Mods')
        GUI.launchGameButton:Hide()
        --if GUI.allowObservers then
            --GUI.allowObservers:Show()
            --GUI.allowObservers:Disable()
            --GUI.observerLabel:Disable()
        --end
        if gameInfo.GameOptions.AllowObservers then
            GUI.allowObservers:SetCheck(true, true) -- XinnoTest
        else
            GUI.allowObservers:SetCheck(false, true) -- XinnoTest
        end
    end

    if GUI.becomeObserver then
        if IsObserver(localPlayerID) then
            --GUI.becomeObserver:Hide()
            GUI.becomeObserver:Disable()
        else
            --GUI.becomeObserver:Show()
            GUI.becomeObserver:Enable()
        end
    end

    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        if gameInfo.PlayerOptions[localPlayerSlot].Ready then
            if GUI.becomeObserver then
                GUI.becomeObserver:Disable()
            end
            GUI.LargeMapPreview:Disable()
            TEST1factionPanel:Disable()
            TEST2factionPanel:Disable()
            TEST3factionPanel:Disable()
            TEST4factionPanel:Disable()
            TEST5factionPanel:Disable()
        else
            if GUI.becomeObserver then
                GUI.becomeObserver:Enable()
            end
            GUI.LargeMapPreview:Enable()
            TEST1factionPanel:Enable()
            TEST2factionPanel:Enable()
            TEST3factionPanel:Enable()
            TEST4factionPanel:Enable()
            TEST5factionPanel:Enable()
        end
    end

    if GUI.observerList then
        -- clear every update and repopulate
        GUI.observerList:DeleteAllItems()

        for index, observer in gameInfo.Observers do
            observer.ObserverListIndex = GUI.observerList:GetItemCount() # Pin-head William made this zero-based
            GUI.observerList:AddItem(observer.PlayerName)
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
        if not GUI.slots[i].closed then
            if gameInfo.PlayerOptions[i] then
                SetSlotInfo(i, gameInfo.PlayerOptions[i])
            else
                ClearSlotInfo(i)
            end
        end
    end

    -- Change the Slot Background by Slot State -- Xinnony
    for i = 1, LobbyComm.maxPlayerSlots do
        if GUI.slots[i].closed then
            GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-dis.dds'))
        else
            if gameInfo.PlayerOptions[i] then
                GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player.dds'))
            else
                GUI.slots[i].SlotBackground:SetTexture(UIUtil.UIFile('/SLOT/slot-player_other.dds'))
            end
        end
    end
    
    -- Add tooltip (mean and dev rating) in player rating column -- Xinnony
    for i = 1, LobbyComm.maxPlayerSlots do
        --if not GUI.slots[i].tooltiprating then
        if not GUI.slots[i].closed and gameInfo.PlayerOptions[i].Human then
            if gameInfo.PlayerOptions[i].Human then
                if gameInfo.PlayerOptions[i].MEAN and gameInfo.PlayerOptions[i].DEV then
                    local mean = math.floor(gameInfo.PlayerOptions[i].MEAN) or 'N/A'
                    local dev = math.floor(gameInfo.PlayerOptions[i].DEV) or 'N/A'
                    Tooltip.AddControlTooltip(GUI.slots[i].ratingText, {text='Rating', body='- Mean : '..mean..'\n - Dev : '..dev})
                else
                    local mean =  'N/A'
                    local dev = 'N/A'
                    Tooltip.AddControlTooltip(GUI.slots[i].ratingText, {text='Rating', body='- Mean : N/A'..'\n - Dev : N/A'})
                end
            else
                Tooltip.AddControlTooltip(GUI.slots[i].ratingText, '')
            end
        end
    end
    
    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map != "") then
        if not GUI.mapView:SetTexture(scenarioInfo.preview) then
            GUI.mapView:SetTextureFromMap(scenarioInfo.map)
        end
        --GUI.RankedLabel:SetText(LOC(scenarioInfo.name)) -- Add RankedLabel above option lobby (replace with Ranked Label)
        ShowMapPositions(GUI.mapView,scenarioInfo,numPlayers)
    else
        GUI.mapView:ClearTexture()
        ShowMapPositions(nil, false)
    end


    -- deal with options display
    if lobbyComm:IsHost() then
        -- disable options when all players are marked ready
        if not singlePlayer then
            local allPlayersReady = true
            if GetPlayersNotReady() != false then
                allPlayersReady = false
            end

            if allPlayersReady then
                --GUI.allowObservers:Disable()
                GUI.gameoptionsButton:Disable()
                GUI.rankedOptions:Disable()
                --GUI.becomeObserver:Disable()
                GUI.randMap:Disable()
                --GUI.randTeam:Disable()
                GUI.launchGameButton:Enable()
            else
                --GUI.allowObservers:Enable()
                GUI.gameoptionsButton:Enable()
                GUI.rankedOptions:Enable()
                --GUI.becomeObserver:Enable()
                GUI.randMap:Enable()
                --GUI.randTeam:Enable()
                if launchThread then CancelLaunch() end

                GUI.launchGameButton:Disable()
            end
        end
    end
    if LrgMap then
        scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
        CreateBigPreview(501, GUI.mapPanel)
    end
    RefreshOptionDisplayData(scenarioInfo)
    -- Send autoteams infos to server.
    AssignRandomTeams(gameInfo)

    if LASTXinnoBackground == 'Map' then ChangeBackgroundLobby(nil, nil) end-- For update map background

    if gameInfo.GameOptions['TeamSpawn'] != 'random' and math.mod(numPlayers,2) == 0 and gameInfo.GameOptions['AutoTeams'] !=
        'manual' and gameInfo.GameOptions['AutoTeams'] != 'none' then

        local teams = nil
        local teamcreated = false
        correct = true

        for i = 1, LobbyComm.maxPlayerSlots do
            if gameInfo.PlayerOptions[i] then

                if  gameInfo.PlayerOptions[i].Human then
                    if gameInfo.PlayerOptions[i].MEAN and gameInfo.PlayerOptions[i].DEV then
                        player = Player.create(gameInfo.PlayerOptions[i].PlayerName,
                                 Rating.create(gameInfo.PlayerOptions[i].MEAN, gameInfo.PlayerOptions[i].DEV))
                        team = gameInfo.PlayerOptions[i].Team
                        if team == 2 then
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
        if correct and teams != nil then
            local quality = Trueskill.computeQuality(teams)
            if quality and quality > 0 then
                gameInfo.GameOptions['Quality'] = quality
                --#local randmapText = UIUtil.CreateText(GUI.panel, "current game quality : " .. quality .. " %", 17, UIUtil.titleFont)
                --#LayoutHelpers.AtRightTopIn(randmapText, GUI.panel, 50, 41)
                if randmapText and scenarioInfo.name then
                    -- Set the map name and quality at the top right corner in lobby -- Xinnony
                    SetText2(randmapText, scenarioInfo.name, 10)
                end
                if randmapText2 then
                    SetText2(randmapText2, "Game quality : "..quality.."%", 10)
                end
            else
                if randmapText and scenarioInfo.name then
                    -- Set the map name and quality at the top right corner in lobby -- Xinnony
                    SetText2(randmapText, scenarioInfo.name, 10)
                end
                if randmapText2 then
                    SetText2(randmapText2, "Game quality N/A", 10)
                end
            end
        else
            if randmapText and scenarioInfo.name then
                -- Set the map name and quality at the top right corner in lobby -- Xinnony
                SetText2(randmapText, scenarioInfo.name, 10)
            end
            if randmapText2 then
                randmapText2:SetText("")
            end
        end
    else
        if randmapText and scenarioInfo.name then
            -- Set the map name and quality at the top right corner in lobby -- Xinnony
            SetText2(randmapText, scenarioInfo.name, 10)
        end
        if randmapText2 then
            randmapText2:SetText("")
        end
    end
    --// Add Tooltip info on Map Name Label -- Xinnony
    if randmapText and randmapText2 and scenarioInfo then
        if scenarioInfo.map_version then
            TTips_map_version = scenarioInfo.map_version
        else
            TTips_map_version = "N/A"
        end
        --
        local ArmySize = table.getsize(scenarioInfo.Configurations.standard.teams[1].armies)
        if ArmySize then
            TTips_army = ArmySize
        else
            TTips_army = "N/A"
        end
        --
        if scenarioInfo.size then
            TTips_sizeX = scenarioInfo.size[1]/51.2
            TTips_sizeY = scenarioInfo.size[2]/51.2
        else
            TTips_sizeX = "N/A"
            TTips_sizeY = "N/A"
        end
        --
        --if scenarioInfo.description then
            --TTips_description = scenarioInfo.description
        --else
            --TTips_description = "N/A"
        --end
        --
        Tooltip.AddControlTooltip(randmapText,{text=scenarioInfo.name, body='- Map version : '..TTips_map_version..'\n '..
            '- Max Players : '..TTips_army..' max'..'\n '..
            '- Map Size : '..TTips_sizeX..'km x '..TTips_sizeY..'km'})
            --'- Map Description :\n'..TTips_description})
        Tooltip.AddControlTooltip(randmapText2,{text=scenarioInfo.name, body='- Map version : '..TTips_map_version..'\n '..
            '- Max Players : '..TTips_army..' max'..'\n '..
            '- Map Size : '..TTips_sizeX..'km x '..TTips_sizeY..'km'})
            --'- Map Description :\n'..TTips_description})
    else
        if randmapText then
            Tooltip.AddControlTooltip(randmapText,{text="N/A", body='- Map version : N/A'..'\n '..
                '- Max Players : N/A max'..'\n '..
                '- Map Size : N/Akm x N/Akm'})
            Tooltip.AddControlTooltip(randmapText2,{text="N/A", body='- Map version : N/A'..'\n '..
                '- Max Players : N/A max'..'\n '..
                '- Map Size : N/Akm x N/Akm'})
        end
    end
    --\\ Stop -- Add Tooltip info on Map Name Label
    --// For refresh menu in slot -- Xinnony
    FuncSlotMenuData()
    --\\ Stop -- For refresh menu in slot
end

-- Update our local gameInfo.GameMods from selected map name and selected mods, then
-- notify other clients about the change.
local function HostUpdateMods(newPlayerID, newPlayerName)
    if lobbyComm:IsHost() then
        if gameInfo.GameOptions['RankedGame'] and gameInfo.GameOptions['RankedGame'] != 'Off' then
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
            local reason = ""
            if table.getn(missingmods) == 1 then
                reason = (LOCF('<LOC lobui_0588>You were automaticly removed from the lobby because you ' ..
                               'don\'t have the following mod:\n%s \nPlease, install the mod before you join the game lobby',
                               modnames))
            else
                reason = (LOCF('<LOC lobui_0589>You were automaticly removed from the lobby because you ' ..
                               'don\'t have the following mods:\n%s \nPlease, install the mods before you join the game lobby',
                               modnames))
            end
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
function OnModsChanged(modlist)
    if modlist then
        Mods.SetSelectedMods(modlist)
        if lobbyComm:IsHost() then
            selectedMods = table.map(function (m) return m.uid end, Mods.GetGameMods())
            HostUpdateMods()
        end
        UpdateGame()
    end
end

-- host makes a specific slot closed to players
function HostCloseSlot(senderID, slot)
    -- don't close an already closed slot or an occupied slot
    if gameInfo.ClosedSlots[slot] != nil or gameInfo.PlayerOptions[slot] != nil then
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
    --// RULE TITLE - Xinnony
    if not singlePlayer then
        RuleTitle_SendMSG()
    end
    --\\ Stop RULE TITLE
    -- CPU benchmark code
    if human and not singlePlayer then
        for i,benchmark in CPU_BenchmarkList do
            -- If we're getting a new player, send them all our benchmark data for players who have joined already
            lobbyComm:SendData(senderID, { Type = 'CPUBenchmark', PlayerName=benchmark.PlayerName, Result = benchmark.Result} )
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
            HostTryAddObserver(senderID, requestedPlayerName)
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

    if gameInfo.ClosedSlots[requestedSlot] != nil then
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

function HostTryAddObserver( senderID, requestedObserverName )
    local index = 1
    while gameInfo.Observers[index] do
        index = index + 1
    end

    local observerName = lobbyComm:MakeValidPlayerName(senderID,requestedObserverName)
    gameInfo.Observers[index] = {
        PlayerName = observerName,
        OwnerID = senderID,
    }

    lobbyComm:BroadcastData(
        {
            Type = 'ObserverAdded',
            Slot = index,
            Options = gameInfo.Observers[index],
        }
    )
    SendSystemMessage(LOCF("<LOC lobui_0202>%s has joined as an observer.",observerName))
    UpdateGame()
end

function HostConvertPlayerToObserver(senderID, name, playerSlot)
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
        oldColor = gameInfo.PlayerOptions[playerSlot].PlayerColor, -- Vicarian
        oldFaction = gameInfo.PlayerOptions[playerSlot].Faction, -- Vicarian
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

    SendSystemMessage(LOCF("<LOC lobui_0226>%s has switched from a player to an observer.", name))

    UpdateGame()
end

function HostConvertObserverToPlayer(senderID, name, fromObserverSlot, toPlayerSlot, requestedFaction,
                                     requestedPL, requestedRC, requestedNG)
    if gameInfo.Observers[fromObserverSlot] == nil then
        return
    end

    if gameInfo.PlayerOptions[toPlayerSlot] != nil then
        return
    end

    if gameInfo.ClosedSlots[toPlayerSlot] != nil then
        return
    end

    gameInfo.PlayerOptions[toPlayerSlot] = LobbyComm.GetDefaultPlayerOptions(name)
    gameInfo.PlayerOptions[toPlayerSlot].OwnerID = senderID

    if requestedFaction then
        --gameInfo.PlayerOptions[toPlayerSlot].Faction = gameInfo.Observers[fromObserverSlot].oldFaction or requestedFaction
        gameInfo.PlayerOptions[toPlayerSlot].Faction = requestedFaction
    end

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

    SendSystemMessage(LOCF("<LOC lobui_0227>%s has switched from an observer to player.", name))
    UpdateGame()
end

function HostClearPlayer(uid)

    local slot = FindSlotForID(peerID)
    if slot then
        ClearSlotInfo( slot )
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

function HostRemoveAI( slot )
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
    local Combo = import('/lua/ui/controls/combo.lua').Combo2
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
    local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo2
    local EffectHelpers = import('/lua/maui/effecthelpers.lua')
    local ItemList = import('/lua/maui/itemlist.lua').ItemList
    local Prefs = import('/lua/user/prefs.lua')

    UIUtil.SetCurrentSkin('uef')

    if (GUI.connectdialog != false) then
        MenuCommon.MenuCleanup()
        GUI.connectdialog:Destroy()
        GUI.connectdialog = false
    end

    local title
    if GpgNetActive() then
        title = "FA FOREVER GAME LOBBY"
        --
        XinnoBackgroundStretch = Prefs.GetFromCurrentProfile('XinnoBackgroundStretch') or 'true'
        GUI.background = Bitmap(GUI, UIUtil.SkinnableFile('')) -- Background faction or art
            LayoutHelpers.AtCenterIn(GUI.background, GUI)
            if XinnoBackgroundStretch == 'true' then
                LayoutHelpers.FillParent(GUI.background, GUI)
            else
                LayoutHelpers.FillParentPreserveAspectRatio(GUI.background, GUI)
            end
        GUI.background2 = MapPreview(GUI) -- Background map
            LayoutHelpers.AtCenterIn(GUI.background2, GUI)
            GUI.background2.Width:Set(400)
            GUI.background2.Height:Set(400)
            if XinnoBackgroundStretch == 'true' then
                LayoutHelpers.FillParent(GUI.background2, GUI)
            else
                LayoutHelpers.FillParentPreserveAspectRatio(GUI.background2, GUI)
            end
    elseif singlePlayer then
        title = "<LOC _Skirmish_Setup>"
    else
        title = "<LOC _LAN_Game_Lobby>"
    end

    ---------------------------------------------------------------------------
    -- Set up main control panels
    ---------------------------------------------------------------------------
    --if singlePlayer then
        --GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/power_panel-skirmish_bmp.dds"))
    --else
        GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[ran]power_panel_bmp.dds"))
    --end
    LayoutHelpers.AtCenterIn(GUI.panel, GUI)
    --GUI.panel.brackets = UIUtil.CreateDialogBrackets(GUI.panel, 18, 17, 18, 15)
    
    --// RULE TITLE -- Xinnony
    RuleTitle_HostCanEditTitle()
    --\\ Stop RULE TITLE
    
    randmapText = UIUtil.CreateText(GUI.panel, "", 17, 'Arial Gras') -- Map Name Label
        SetText2(randmapText, "Loading ...", 10)
        LayoutHelpers.AtRightTopIn(randmapText, GUI.panel, 50, 41)
        randmapText:SetColor('B9BFB9')
        randmapText:SetDropShadow(true)
    randmapText2 = UIUtil.CreateText(GUI.panel, "", 13, 'Arial Gras') -- Game Quality Label
        LayoutHelpers.AtRightTopIn(randmapText2, GUI.panel, 50, 61)
        randmapText2:SetColor('B9BFB9')
        randmapText2:SetDropShadow(true)
    --Tooltip.AddButtonTooltip(randmapText,{text='', body=''})
    randmapText3 = UIUtil.CreateText(GUI.panel, "", 13, 'Arial Gras') -- MOD Label
        LayoutHelpers.AtLeftTopIn(randmapText3, GUI.panel, 50, 61)
        randmapText3:SetColor('B9BFB9')
        randmapText3:SetDropShadow(true)
    
    --// Credits panel -- Xinnony
    GUI.Credits = UIUtil.CreateButtonStd2(GUI.panel, '/BUTTON/small/', "Lobby Options", 10, -1)
        LayoutHelpers.AtTopIn(GUI.Credits, GUI.panel, 10)
        LayoutHelpers.AtHorizontalCenterIn(GUI.Credits, GUI, 0)
    GUI.Credits.OnClick = function()
        CreateOptionLobbyDialog()
    end
    --// Credits footer -- Xinnony
    local Credits = 'New Skin by Xinnony and Barlots (v1.9)'
    local Credits_Text_X = 11
    Credits_Text = UIUtil.CreateText(GUI.panel, '', 17, UIUtil.titleFont)
    SetText2(Credits_Text, Credits, 10)
    Credits_Text:SetFont(UIUtil.titleFont, 12)
    Credits_Text:SetColor("FFFFFF")
    LayoutHelpers.AtBottomIn(Credits_Text, GUI.panel, 0)
    LayoutHelpers.AtRightIn(Credits_Text, GUI.panel, Credits_Text_X)
    Credits_Text:SetDropShadow(true)
    --\\ Stop Credits

    -- FOR SEE THE GROUP POSITION, LOOK THIS SCREENSHOOT : http://img402.imageshack.us/img402/8826/falobbygroup.png - Xinnony
    GUI.playerPanel = Group(GUI.panel, "playerPanel") -- RED Square in Screenshoot
    LayoutHelpers.AtLeftTopIn(GUI.playerPanel, GUI.panel, 40, 66+40-4)
    GUI.playerPanel.Width:Set(706)
    GUI.playerPanel.Height:Set(307)

    GUI.buttonPanelTop = Group(GUI.panel, "buttonPanelTop") -- GREEN Square in Screenshoot - Added group for Button - Xinnony
    LayoutHelpers.AtLeftTopIn(GUI.buttonPanelTop, GUI.panel, 40, 383+48)
    GUI.buttonPanelTop.Width:Set(706)
    GUI.buttonPanelTop.Height:Set(19)

    GUI.buttonPanelRight = Group(GUI.panel, "buttonPanelRight") -- PURPLE Square in Screenshoot - Added group for Button - Xinnony
    LayoutHelpers.AtLeftTopIn(GUI.buttonPanelRight, GUI.panel, 481, 401+24)
    GUI.buttonPanelRight.Width:Set(265)
    GUI.buttonPanelRight.Height:Set(89)

    GUI.factionPanel = Group(GUI.panel, "factionPanel") -- Faction Selector
    LayoutHelpers.AtLeftTopIn(GUI.factionPanel, GUI.panel, 410, 36) --Right:615
    GUI.factionPanel.Width:Set(205)
    GUI.factionPanel.Height:Set(60)

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
    
    GUI.NEWlaunchPanel = Group(GUI.panel, "NEWlaunchPanel") -- BLACK Square in Screenshoot - Added group for Button - Xinnony
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

    --start of close slots code by Moritz
    GUI.LargeMapPreview = UIUtil.CreateButtonStd2(GUI.mapView, '/BUTTON/zoom/', "", 8, 0)
        LayoutHelpers.AtRightIn(GUI.LargeMapPreview, GUI.mapView, -3)
        LayoutHelpers.AtBottomIn(GUI.LargeMapPreview, GUI.mapView, -3)
        Tooltip.AddButtonTooltip(GUI.LargeMapPreview, 'lob_click_LargeMapPreview')
        GUI.LargeMapPreview.OnClick = function()
            --for i = 1, LobbyComm.maxPlayerSlots do
                --if not gameInfo.ClosedSlots[i] and not gameInfo.PlayerOptions[i] then
                    --HostCloseSlot(localPlayerID, i)
                --end
            --end
            CreateBigPreview(501, GUI.mapPanel)
        end
    --end of close slots code

    -- Ranked label --
    GUI.RankedLabel = UIUtil.CreateText(GUI.mapPanel, "", 16, UIUtil.titleFont)
        GUI.RankedLabel:SetColor(UIUtil.bodyColor)
        LayoutHelpers.AtTopIn(GUI.RankedLabel, GUI.optionsPanel, 5)
        LayoutHelpers.AtHorizontalCenterIn(GUI.RankedLabel, GUI.optionsPanel, -8)
        GUI.RankedLabel:SetFont('Arial Gras', 13)
        LayoutHelpers.AtRightTopIn(GUI.RankedLabel, randmapText3, 0, 0)--GUI.panel, 50, 61+14)
        LayoutHelpers.RightOf(GUI.RankedLabel, randmapText3, 0)
        --GUI.RankedLabel:SetColor('ff7777') -- 77ff77
        GUI.RankedLabel:SetDropShadow(true)
    
    -- XinnonyWork -- Checkbox Show changed Options
    cbox_ShowChangedOption = UIUtil.CreateCheckboxStd(GUI.optionsPanel, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftTopIn(cbox_ShowChangedOption, GUI.optionsPanel, 3, 0)
        --LayoutHelpers.AtHorizontalCenterIn(cbox_ShowChangedOption, GUI.optionsPanel, -8)
        cbox_ShowChangedOption_TEXT = UIUtil.CreateText(cbox_ShowChangedOption, 'Hide unchanged Options', 11, 'Arial')
            cbox_ShowChangedOption_TEXT:SetColor('B9BFB9')
            cbox_ShowChangedOption_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_ShowChangedOption_TEXT, cbox_ShowChangedOption, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_ShowChangedOption_TEXT, cbox_ShowChangedOption)
            cbox_ShowChangedOption:Disable()
            Tooltip.AddButtonTooltip(cbox_ShowChangedOption_TEXT, {text='Show only changed Options', body='Not working yet, coming soon!'})
            cbox_ShowChangedOption.OnCheck = function(self, checked)
                if checked then
                    cbox_ShowChangedOption:SetCheck(false, true)
                else
                end
            end
    -- XinnonyWork -- Checkbox Show changed Options

    -- GAME OPTIONS // MODS MANAGER BUTTON --
    if lobbyComm:IsHost() then     -- GAME OPTION
        GUI.gameoptionsButton = UIUtil.CreateButtonStd2(GUI.optionsPanel, '/BUTTON/medium/', "Game Options", 12, -1)
    else                                        -- MODS MANAGER
        GUI.gameoptionsButton = UIUtil.CreateButtonStd2(GUI.optionsPanel, '/BUTTON/medium/', "Mods Manager", 12, -1)
    end
    LayoutHelpers.AtBottomIn(GUI.gameoptionsButton, GUI.optionsPanel, -55)
    LayoutHelpers.AtHorizontalCenterIn(GUI.gameoptionsButton, GUI.optionsPanel)
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

    ---------------------------------------------------------------------------
    -- set up launch panel
    ---------------------------------------------------------------------------
    -- LAUNCH THE GAME BUTTON --
    GUI.launchGameButton = UIUtil.CreateButtonStd2(GUI.launchPanel, '/BUTTON/large/', "Launch the Game", 16, -1)
        LayoutHelpers.AtCenterIn(GUI.launchGameButton, GUI.launchPanel, 20, -345)
        Tooltip.AddButtonTooltip(GUI.launchGameButton, 'Lobby_Launch')
        GUI.launchGameButton:Hide() -- hide unless we're the game host
        GUI.launchGameButton.OnClick = function(self)
            TryLaunch(false)
        end
    
    -- EXIT BUTTON --
    GUI.exitButton = UIUtil.CreateButtonStd2(GUI.launchPanel, '/BUTTON/medium/','Exit', 11, -1)--, textOffsetHorz, clickCue, rolloverCue)
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
            {worldCover = true, enterButton = 1, escapeButton = 2})
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
        GUI.chatDisplay:SetFont(UIUtil.bodyFont, 14)
        GUI.chatDisplay:SetColors(UIUtil.fontColor(), "00000000", UIUtil.fontColor(), "00000000")
        LayoutHelpers.AtLeftTopIn(GUI.chatDisplay, GUI.chatPanel, 8, 4) --Right, Top
        GUI.chatDisplay.Bottom:Set(function() return GUI.chatEdit.Top() -6 end)
        GUI.chatDisplay.Right:Set(function() return GUI.chatPanel.Right() -0 end)
        GUI.chatDisplay.Height:Set(function() return GUI.chatDisplay.Bottom() - GUI.chatDisplay.Top() end)
        GUI.chatDisplay.Width:Set(function() return GUI.chatDisplay.Right() - GUI.chatDisplay.Left() -20 end)

    GUI.chatDisplayScroll = UIUtil.CreateVertScrollbarFor2(GUI.chatDisplay, -21, nil, 30)

    # OnlineProvider.RegisterChatDisplay(GUI.chatDisplay)

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
        if text != "" then
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
                if commandQueueIndex != 1 then
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
    RefreshOptionDisplayData()

    local function CreateOptionElements()
        local function CreateElement(index)
            GUI.OptionDisplay[index] = Group(GUI.OptionContainer)
            GUI.OptionDisplay[index].Height:Set(36)
            GUI.OptionDisplay[index].Width:Set(GUI.OptionContainer.Width)
            GUI.OptionDisplay[index].Depth:Set(function() return GUI.OptionContainer.Depth() + 10 end)
            GUI.OptionDisplay[index]:DisableHitTest()

            GUI.OptionDisplay[index].text = UIUtil.CreateText(GUI.OptionDisplay[index], '', 14, "Arial")
            GUI.OptionDisplay[index].text:SetColor(UIUtil.fontColor)
            GUI.OptionDisplay[index].text:DisableHitTest()
            LayoutHelpers.AtLeftTopIn(GUI.OptionDisplay[index].text, GUI.OptionDisplay[index], 5)

            GUI.OptionDisplay[index].value = UIUtil.CreateText(GUI.OptionDisplay[index], '', 14, "Arial")
            GUI.OptionDisplay[index].value:SetColor(UIUtil.fontOverColor)
            GUI.OptionDisplay[index].value:DisableHitTest()
            LayoutHelpers.AtRightTopIn(GUI.OptionDisplay[index].value, GUI.OptionDisplay[index], 5, 16)

            GUI.OptionDisplay[index].value.bg = Bitmap(GUI.OptionDisplay[index])
            GUI.OptionDisplay[index].value.bg:SetSolidColor('ff333333')
            GUI.OptionDisplay[index].value.bg.Left:Set(GUI.OptionDisplay[index].Left)
            GUI.OptionDisplay[index].value.bg.Right:Set(GUI.OptionDisplay[index].Right)
            GUI.OptionDisplay[index].value.bg.Bottom:Set(function() return GUI.OptionDisplay[index].value.Bottom() + 2 end)
            GUI.OptionDisplay[index].value.bg.Top:Set(GUI.OptionDisplay[index].Top)
            GUI.OptionDisplay[index].value.bg.Depth:Set(function() return GUI.OptionDisplay[index].Depth() - 2 end)

            GUI.OptionDisplay[index].value.bg2 = Bitmap(GUI.OptionDisplay[index])
            GUI.OptionDisplay[index].value.bg2:SetSolidColor('ff000000')
            GUI.OptionDisplay[index].value.bg2.Left:Set(function() return GUI.OptionDisplay[index].value.bg.Left() + 1 end)
            GUI.OptionDisplay[index].value.bg2.Right:Set(function() return GUI.OptionDisplay[index].value.bg.Right() - 1 end)
            GUI.OptionDisplay[index].value.bg2.Bottom:Set(function() return GUI.OptionDisplay[index].value.bg.Bottom() - 1 end)
            GUI.OptionDisplay[index].value.bg2.Top:Set(function() return GUI.OptionDisplay[index].value.Top() + 0 end)
            GUI.OptionDisplay[index].value.bg2.Depth:Set(function() return GUI.OptionDisplay[index].value.bg.Depth() + 1 end)
        end

        CreateElement(1)
        LayoutHelpers.AtLeftTopIn(GUI.OptionDisplay[1], GUI.OptionContainer)

        local index = 2
        while GUI.OptionDisplay[table.getsize(GUI.OptionDisplay)].Bottom() + GUI.OptionDisplay[1].Height() <
              GUI.OptionContainer.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(GUI.OptionDisplay[index], GUI.OptionDisplay[index-1])
            index = index + 1
        end
    end
    CreateOptionElements()

    local numLines = function() return table.getsize(GUI.OptionDisplay) end

    local function DataSize()
        return table.getn(formattedOptions)
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
                line.text:SetColor('ffff7777')
                LayoutHelpers.AtHorizontalCenterIn(line.text, line, 5)
                LayoutHelpers.AtHorizontalCenterIn(line.value, line, 5, 16)
                LayoutHelpers.ResetRight(line.value)
            elseif data.red then
                line.text:SetColor('ff7777')
                LayoutHelpers.AtHorizontalCenterIn(line.text, line, 5)
                LayoutHelpers.AtHorizontalCenterIn(line.value, line, 5, 16)
                LayoutHelpers.ResetRight(line.value)
            elseif data.green then
                line.text:SetColor('77ff77')
                LayoutHelpers.AtHorizontalCenterIn(line.text, line, 5)
                LayoutHelpers.AtHorizontalCenterIn(line.value, line, 5, 16)
                LayoutHelpers.ResetRight(line.value)
            else
                line.text:SetColor(UIUtil.fontColor)
                LayoutHelpers.AtLeftTopIn(line.text, line, 5)
                LayoutHelpers.AtRightTopIn(line.value, line, 5, 16)
                LayoutHelpers.ResetLeft(line.value)
            end
            line.text:SetText(LOC(data.text))
            line.value:SetText(LOC(data.value))
            line.value.bg.HandleEvent = Group.HandleEvent
            line.value.bg2.HandleEvent = Bitmap.HandleEvent
            if data.tooltip then
                Tooltip.AddControlTooltip(line.value.bg, data.tooltip)
                Tooltip.AddControlTooltip(line.value.bg2, data.valueTooltip)
            end
        end
        for i, v in GUI.OptionDisplay do
            if formattedOptions[i + self.top] then
                SetTextLine(v, formattedOptions[i + self.top], i + self.top)
            end
        end
    end

    GUI.OptionContainer:CalcVisible()

    GUI.OptionContainer.HandleEvent = function(self, event)
        if event.Type == 'WheelRotation' then
            local lines = 1
            if event.WheelRotation > 0 then
                lines = -1
            end
            self:ScrollLines(nil, lines)
        end
    end

    UIUtil.CreateVertScrollbarFor2(GUI.OptionContainer, 1, nil, -9, -24)

    if singlePlayer then
        GUI.loadButton = UIUtil.CreateButtonStd(GUI.optionsPanel, '/scx_menu/small-btn/small',"<LOC lobui_0176>Load", 18, 2)
            LayoutHelpers.LeftOf(GUI.loadButton, GUI.launchGameButton, 10)
            LayoutHelpers.AtVerticalCenterIn(GUI.loadButton, GUI.launchGameButton)
            GUI.loadButton.OnClick = function(self, modifiers)
                import('/lua/ui/dialogs/saveload.lua').CreateLoadDialog(GUI)
            end
            Tooltip.AddButtonTooltip(GUI.loadButton, 'Lobby_Load')
    elseif not lobbyComm:IsHost() then
        --GUI.gameoptionsButton = UIUtil.CreateButtonStd2(GUI.optionsPanel, '/BUTTON/gameoptions/gameoptions', "", 8, 0)
        GUI.restrictedUnitsButton = UIUtil.CreateButtonStd2(GUI.optionsPanel, '/BUTTON/medium/', "Unit Manager", 14, 0)--"<LOC lobui_0376>Unit Manager", 14, 2)
            GUI.restrictedUnitsButton.label:SetColor('B9BFB9')
            GUI.restrictedUnitsButton.label:SetDropShadow(true)
            LayoutHelpers.AtHorizontalCenterIn(GUI.restrictedUnitsButton, GUI.gameoptionsButton)
            LayoutHelpers.AtVerticalCenterIn(GUI.restrictedUnitsButton, GUI.exitButton)
            GUI.restrictedUnitsButton.OnClick = function(self, modifiers)
                import('/lua/ui/lobby/restrictedUnitsDlg.lua').CreateDialog(GUI.panel, gameInfo.GameOptions.RestrictedCategories, function() end, function() end, false)
            end
            Tooltip.AddButtonTooltip(GUI.restrictedUnitsButton, 'lob_RestrictedUnitsClient')
    end
    
    ---------------------------------------------------------------------------
    -- Faction Selector -- Xinnony
    ---------------------------------------------------------------------------
    CreateUI_Faction_Selector()
    SetEvent_Faction_Selector()
    SetCurrentFactionTo_Faction_Selector()
    
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

    GUI.ratingLabel = UIUtil.CreateText(GUI.labelGroup, "R", 14, 'Arial Gras')--UIUtil.titleFont) 14 SIZE
        GUI.ratingLabel:SetColor('B9BFB9')
        GUI.ratingLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.ratingLabel, GUI.panel, slotColumnSizes.rating.x+20) -- Offset Right
        LayoutHelpers.AtVerticalCenterIn(GUI.ratingLabel, GUI.labelGroup, 5) -- Offset Down
        Tooltip.AddControlTooltip(GUI.ratingLabel, 'rating')

    GUI.numGamesLabel = UIUtil.CreateText(GUI.labelGroup, "G", 14, 'Arial Gras')--UIUtil.titleFont)
        GUI.numGamesLabel:SetColor('B9BFB9')
        GUI.numGamesLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.numGamesLabel, GUI.panel, slotColumnSizes.games.x - 4 + 24)
        LayoutHelpers.AtVerticalCenterIn(GUI.numGamesLabel, GUI.labelGroup, 5)
        Tooltip.AddControlTooltip(GUI.numGamesLabel, 'num_games')

    GUI.nameLabel = UIUtil.CreateText(GUI.labelGroup, "Nickname", 14, 'Arial Gras')--UIUtil.titleFont)
        GUI.nameLabel:SetColor('B9BFB9')
        GUI.nameLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.nameLabel, GUI.panel, slotColumnSizes.player.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.nameLabel, GUI.labelGroup, 5)
        Tooltip.AddControlTooltip(GUI.nameLabel, 'lob_slot')

    GUI.colorLabel = UIUtil.CreateText(GUI.labelGroup, "Color", 14, 'Arial Gras')--UIUtil.titleFont)
        GUI.colorLabel:SetColor('B9BFB9')
        GUI.colorLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.colorLabel, GUI.panel, slotColumnSizes.color.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.colorLabel, GUI.labelGroup, 5)
        Tooltip.AddControlTooltip(GUI.colorLabel, 'lob_color')

    GUI.factionLabel = UIUtil.CreateText(GUI.labelGroup, "Faction", 14, 'Arial Gras')--UIUtil.titleFont)
        GUI.factionLabel:SetColor('B9BFB9')
        GUI.factionLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.factionLabel, GUI.panel, slotColumnSizes.faction.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.factionLabel, GUI.labelGroup, 5)
        Tooltip.AddControlTooltip(GUI.factionLabel, 'lob_faction')

    GUI.teamLabel = UIUtil.CreateText(GUI.labelGroup, "Team", 14, 'Arial Gras')--UIUtil.titleFont)
        GUI.teamLabel:SetColor('B9BFB9')
        GUI.teamLabel:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(GUI.teamLabel, GUI.panel, slotColumnSizes.team.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.teamLabel, GUI.labelGroup, 5)
        Tooltip.AddControlTooltip(GUI.teamLabel, 'lob_team')

    if not singlePlayer then
        GUI.pingLabel = UIUtil.CreateText(GUI.labelGroup, "Ping/CPU", 14, 'Arial Gras')--UIUtil.titleFont)
            GUI.pingLabel:SetColor('B9BFB9')
            GUI.pingLabel:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(GUI.pingLabel, GUI.panel, slotColumnSizes.ping.x-18+3)
            LayoutHelpers.AtVerticalCenterIn(GUI.pingLabel, GUI.labelGroup, 5)
            --Tooltip.AddControlTooltip(GUI.pingLabel, '') -- NEED INFO (write tooltip in "\lua\ui\help\tooltips.lua")

        GUI.readyLabel = UIUtil.CreateText(GUI.labelGroup, "Ready", 14, 'Arial Gras')--UIUtil.titleFont)
            GUI.readyLabel:SetColor('B9BFB9')
            GUI.readyLabel:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(GUI.readyLabel, GUI.panel, slotColumnSizes.ready.x-3+3)
            LayoutHelpers.AtVerticalCenterIn(GUI.readyLabel, GUI.labelGroup, 5)
            --Tooltip.AddControlTooltip(GUI.readyLabel, '') -- NEED INFO (write tooltip in "\lua\ui\help\tooltips.lua")
    end
    
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
                if gameInfo.GameOptions['TeamSpawn'] != 'random' and GUI.markers[curRow].Indicator then
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
        
        --// COUNTRY - Xinnony
        -- Added a bitmap on the left of Rating, the bitmap is a Flag of Country
        GUI.slots[i].KinderCountry = Bitmap(bg, UIUtil.SkinnableFile("/countries/world.dds"))
        GUI.slots[i].KinderCountry.Width:Set(20)
        GUI.slots[i].KinderCountry.Height:Set(17-2) -- 15=2pix marging || 17=1pix marging
        LayoutHelpers.AtBottomIn(GUI.slots[i].KinderCountry, GUI.slots[i], -4) -- -5
        LayoutHelpers.AtLeftIn(GUI.slots[i].KinderCountry, GUI.slots[i], 2) -- 1
        --Tooltip.AddControlTooltip(GUI.slots[i].KinderCountry, '')
        --\\ Stop COUNTRY

        --// Rating
        GUI.slots[i].ratingGroup = Group(bg)
            GUI.slots[i].ratingGroup.Width:Set(slotColumnSizes.rating.width)
            GUI.slots[i].ratingGroup.Height:Set(GUI.slots[curRow].Height)
            LayoutHelpers.AtLeftIn(GUI.slots[i].ratingGroup, GUI.panel, slotColumnSizes.rating.x)
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].ratingGroup, GUI.slots[i], 6)
        GUI.slots[i].ratingText = UIUtil.CreateText(GUI.slots[i].ratingGroup, "", 14, 'Arial')--14, UIUtil.bodyFont)
            LayoutHelpers.AtBottomIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup, 2)
            LayoutHelpers.AtRightIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup, 9)
            GUI.slots[i].tooltiprating = Tooltip.AddControlTooltip(GUI.slots[i].ratingText, '')

        --// NumGame
        GUI.slots[i].numGamesGroup = Group(bg)
            GUI.slots[i].numGamesGroup.Width:Set(slotColumnSizes.games.width)
            GUI.slots[i].numGamesGroup.Height:Set(GUI.slots[curRow].Height)
            LayoutHelpers.AtLeftIn(GUI.slots[i].numGamesGroup, GUI.panel, slotColumnSizes.games.x)
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].numGamesGroup, GUI.slots[i], 6)
        GUI.slots[i].numGamesText = UIUtil.CreateText(GUI.slots[i].numGamesGroup, "", 14, 'Arial')--14, UIUtil.bodyFont)
            GUI.slots[i].numGamesText:SetColor('B9BFB9')
            GUI.slots[i].numGamesText:SetDropShadow(true)
            LayoutHelpers.AtBottomIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup, 2)
            LayoutHelpers.AtRightIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup, 9)

        --// Name
        GUI.slots[i].name = Combo(bg, 15, 10, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
            GUI.slots[i].name._text:SetFont('Arial Gras', 15)
            GUI.slots[i].name._text:SetDropShadow(true)
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].name, GUI.slots[i], 8)
            LayoutHelpers.AtLeftIn(GUI.slots[i].name, GUI.panel, slotColumnSizes.player.x)
            GUI.slots[i].name.Width:Set(slotColumnSizes.player.width)
            GUI.slots[i].name.row = i
        -- left deal with name clicks
        GUI.slots[i].name.OnClick = function(self, index, text)
            DoSlotBehavior(self.row, self.slotKeys[index], text)
        end
        GUI.slots[i].name.OnEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] != 'random' and GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                if GUI.markers[curRow].Indicator then
                    GUI.markers[curRow].Indicator:Stop()
                end
            end
        end

        --// Color
        GUI.slots[i].color = BitmapCombo(bg, gameColors.PlayerColors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].color, GUI.panel, slotColumnSizes.color.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].color, GUI.slots[i], 9)
        GUI.slots[i].color.Width:Set(slotColumnSizes.color.width)
        GUI.slots[i].color.row = i
        GUI.slots[i].color.OnClick = function(self, index)
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
            if XinnonyDebug == -1 then SendSystemMessage(curRow..' and '..FindSlotForID(FindIDForName(localPlayerName))) end
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

        --// Ping
        if not singlePlayer then
            GUI.slots[i].pingGroup = Group(bg)
                GUI.slots[i].pingGroup.Width:Set(slotColumnSizes.ping.width)
                GUI.slots[i].pingGroup.Height:Set(GUI.slots[curRow].Height)
                LayoutHelpers.AtLeftIn(GUI.slots[i].pingGroup, GUI.panel, slotColumnSizes.ping.x)
                LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].pingGroup, GUI.slots[i], 6)

            GUI.slots[i].pingText = UIUtil.CreateText(GUI.slots[i].pingGroup, "xx", 14, UIUtil.bodyFont)
                GUI.slots[i].pingText:Hide()
            --LayoutHelpers.AtBottomIn(GUI.slots[i].pingText, GUI.slots[i].pingGroup)
            --LayoutHelpers.AtHorizontalCenterIn(GUI.slots[i].pingText, GUI.slots[i].pingGroup)

            GUI.slots[i].pingStatus = StatusBar(GUI.slots[i].pingGroup, 0, 1000, false, false,
                UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
                true)
                LayoutHelpers.AtTopIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 4)
                LayoutHelpers.AtLeftIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 0)
                LayoutHelpers.AtRightIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 0)
            --GUI.slots[i].pingStatus.Bottom:Set(GUI.slots[curRow].pingText.Top)
        end

        -- // Ready Checkbox
        -- depending on if this is single player or multiplayer this displays different info
        GUI.slots[i].multiSpace = Group(bg, "multiSpace " .. tonumber(i))
        GUI.slots[i].multiSpace.Width:Set(slotColumnSizes.ready.width)
        GUI.slots[i].multiSpace.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].multiSpace, GUI.panel, slotColumnSizes.ready.x)
        GUI.slots[i].multiSpace.Top:Set(GUI.slots[curRow].Top)

        if not singlePlayer then
            GUI.slots[i].ready = UIUtil.CreateCheckboxStd(GUI.slots[i].multiSpace, '/CHECKBOX/radio')
            GUI.slots[i].ready.row = i
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 8)
            LayoutHelpers.AtLeftIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 0)
            GUI.slots[i].ready.OnCheck = function(self, checked)
                if checked then
                    DisableSlot(self.row, true)
                    if GUI.becomeObserver then
                        GUI.becomeObserver:Disable()
                    end

                else
                    EnableSlot(self.row)
                    if GUI.becomeObserver then
                        GUI.becomeObserver:Enable()
                    end
                end
                SetPlayerOption(self.row,'Ready',checked)
            end
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
        if GUI.slots[slot].ready then
            GUI.slots[slot].ready:Enable()
        end
    end

    function DisableSlot(slot, exceptReady)
        GUI.slots[slot].team:Disable()
        GUI.slots[slot].color:Disable()
        GUI.slots[slot].faction:Disable()
        if GUI.slots[slot].ready and not exceptReady then
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

    GUI.allowObservers = nil
    GUI.observerList = nil

    -- FIXME : this is not needed anymore.
    if lobbyComm:IsHost() then
        SetGameOption('RandomMap', 'Off') --make sure always create lobby with Random Map off
        SetGameOption('RankedGame', 'Off') --make sure always create lobby with Ranked Game off
    end

    if not singlePlayer then
        uef = true
        aeon = true
        cybran = true
        seraphim = true

        GUI.allowObservers = UIUtil.CreateCheckboxStd(GUI.buttonPanelTop, '/CHECKBOX/radio')
            LayoutHelpers.CenteredLeftOf(GUI.allowObservers, GUI.buttonPanelTop, -30)
            Tooltip.AddControlTooltip(GUI.allowObservers, 'lob_observers_allowed')
        GUI.observerLabel = UIUtil.CreateText(GUI.allowObservers, 'Observers in Game', 11, 'Arial')--14, UIUtil.bodyFont)--"<LOC lobui_0275>Observers", 14, UIUtil.bodyFont)
            GUI.observerLabel:SetColor('B9BFB9')
            GUI.observerLabel:SetDropShadow(true)
            LayoutHelpers.CenteredRightOf(GUI.observerLabel, GUI.allowObservers, 0)
            Tooltip.AddControlTooltip(GUI.observerLabel, 'lob_describe_observers')
        GUI.allowObservers:SetCheck(false)
        if lobbyComm:IsHost() then
            SetGameOption("AllowObservers", false)
            GUI.allowObservers.OnCheck = function(self, checked)
                SetGameOption("AllowObservers", checked)
            end
        else
            GUI.allowObservers:Disable()
            GUI.observerLabel:Disable()
        end

        -- GO OBSERVER BUTTON --
        GUI.becomeObserver = UIUtil.CreateButtonStd2(GUI.buttonPanelRight, '/BUTTON/observer/', '', 11, 19)
            GUI.becomeObserver.label:SetFont('Arial', 11)
            LayoutHelpers.AtLeftTopIn(GUI.becomeObserver, GUI.buttonPanelRight, -40+4, 25)
            Tooltip.AddButtonTooltip(GUI.becomeObserver, 'lob_become_observer')
            GUI.becomeObserver.OnClick = function()
                if IsPlayer(localPlayerID) then
                    if lobbyComm:IsHost() then
                        HostConvertPlayerToObserver(hostID, localPlayerName, FindSlotForID(localPlayerID))
                        GUI.becomeObserver:Disable()
                    else
                        lobbyComm:SendData(hostID, {Type = 'RequestConvertToObserver', RequestedName = localPlayerName, RequestedSlot = FindSlotForID(localPlayerID)})
                        GUI.becomeObserver:Disable()
                    end
                end
            end
            GUI.becomeObserver.OnRolloverEvent = function(self, state)
                if state == 'enter' then
                    GUI.becomeObserver.label:SetText('Go Observer')
                    if GUI.becomeObserver:IsDisabled() then
                        GUI.becomeObserver:Disable()
                    end
                elseif state == 'exit' then
                    GUI.becomeObserver.label:SetText('')
                    if GUI.becomeObserver:IsDisabled() then
                        GUI.becomeObserver:Disable()
                    end
                end
            end

        -- AUTO TEAM BUTTON -- start of auto teams code by Moritz
        GUI.randTeam = UIUtil.CreateButtonStd2(GUI.buttonPanelRight, '/BUTTON/autoteam/')
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
        GUI.rankedOptions = UIUtil.CreateButtonStd2(GUI.buttonPanelRight, '/BUTTON/defaultoption/')
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
                    SetGameOption('Victory', 'demoralization')
                    SetGameOption('Timeouts', '3')
                    SetGameOption('CheatsEnabled', 'false')
                    SetGameOption('CivilianAlliance', 'enemy')
                    SetGameOption('GameSpeed', 'normal')
                    SetGameOption('FogOfWar', 'explored')
                    SetGameOption('UnitCap', '1000')
                    SetGameOption('PrebuiltUnits', 'Off')
                    SetGameOption('NoRushOption', 'Off')
                    --gameInfo.GameMods["656b7af6-9a56-47c5-8182-3a896dc6f4b7"] = true
                    --lobbyComm:BroadcastData { Type = "ModsChanged", GameMods = gameInfo.GameMods }
                    UpdateGame()
                end
            end
        --end of ranked options code

        -- CPU BENCH BUTTON --
        GUI.rerunBenchmark = UIUtil.CreateButtonStd2(GUI.observerPanel, '/BUTTON/cputest/', '', 10, 0)
            GUI.rerunBenchmark:Disable()
            LayoutHelpers.CenteredRightOf(GUI.rerunBenchmark, GUI.rankedOptions, 0)
            Tooltip.AddButtonTooltip(GUI.rerunBenchmark,{text='Run CPU Benchmark Test', body='Recalculates your CPU rating.'})

        -- RANDOM MAP BUTTON -- start of random map code by Moritz
        GUI.randMap = UIUtil.CreateButtonStd2(GUI.buttonPanelRight, '/BUTTON/randommap/', '', 10, 0)
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
                    if rMapSizeFil != 0 and rMapPlayersFil != 0 then
                        SendSystemMessage(LOCF("<LOC lobui_0516>Filters: Map Size is %s %dkm and Number of Players are %s %d",
                                               rMapSizeFilLim, rMapSizeFil, rMapPlayersFilLim, rMapPlayersFil))
                    elseif rMapSizeFil != 0 then
                        SendSystemMessage(LOCF("<LOC lobui_0517>Filters: Map Size is %s %dkm and Number of Players are ALL",
                                               rMapSizeFilLim, rMapSizeFil))
                    elseif rMapPlayersFil != 0 then
                        SendSystemMessage(LOCF("<LOC lobui_0518>Filters: Map Size is ALL and Number of Players are %s %d",
                                               rMapPlayersFilLim, rMapPlayersFil))
                    end
                    if rMapTypeFil != 0 then
                        SendSystemMessage(LOCF("<LOC lobui_0578>Map Type: %s", rMapTypeFil))
                    end
                    SendSystemMessage("---------------------------------------------------------------------------------------"..
                                      "------------")
                    if not quickRandMap then
                        quickRandMap = true
                        UpdateGame()
                    end
                end
            end
        --end of random map code
        
        -- TEXT for DefaultOpt, CPUBench, RandomMap, AutoTeam --
        ButtonsPanelText = UIUtil.CreateText(GUI.buttonPanelTop, '', 11, 'Arial')--Open Sans Bold')--'Zeroes Three')
            ButtonsPanelText:SetColor('B9BFB9')
            ButtonsPanelText:SetDropShadow(true)
            ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (ButtonsPanelText.Width() / 2)))
            LayoutHelpers.AtVerticalCenterIn(ButtonsPanelText, GUI.randTeam, 25)
            GUI.randTeam.OnRolloverEvent = function(self, state)
                if state == 'enter' then
                    ButtonsPanelText:SetText('Random Team')
                    ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (ButtonsPanelText.Width() / 2)))
                elseif state == 'exit' then
                    ButtonsPanelText:SetText('')
                end
            end
            GUI.rankedOptions.OnRolloverEvent = function(self, state)
                if state == 'enter' then
                    ButtonsPanelText:SetText('Set Ranked Options')
                    ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (ButtonsPanelText.Width() / 2)))
                elseif state == 'exit' then
                    ButtonsPanelText:SetText('')
                end
            end
            GUI.rerunBenchmark.OnRolloverEvent = function(self, state)
                if state == 'enter' then
                    ButtonsPanelText:SetText('Re-run CPU Benchmark')
                    ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (ButtonsPanelText.Width() / 2)))
                elseif state == 'exit' then
                    ButtonsPanelText:SetText('')
                end
            end
            GUI.randMap.OnRolloverEvent = function(self, state)
                if state == 'enter' then
                    ButtonsPanelText:SetText('Random Map')
                    ButtonsPanelText.Left:Set(math.floor(GUI.rerunBenchmark.Left() - (ButtonsPanelText.Width() / 2)))
                elseif state == 'exit' then
                    ButtonsPanelText:SetText('')
                end
            end

        --start of auto kick code -- Modified by Xinnony
        if lobbyComm:IsHost() then
            GUI.autoKick = UIUtil.CreateCheckboxStd(GUI.buttonPanelTop, '/CHECKBOX/radio')
                LayoutHelpers.CenteredRightOf(GUI.autoKick, GUI.observerLabel, 10)
                Tooltip.AddControlTooltip(GUI.autoKick, 'lob_auto_kick')
            GUI.autoKickLabel = UIUtil.CreateText(GUI.autoKick, "Auto kick", 11, 'Arial')--14, UIUtil.bodyFont)
                GUI.autoKickLabel:SetColor('B9BFB9')
                GUI.autoKickLabel:SetDropShadow(true)
                GUI.autoKickLabel:SetDropShadow(true)
                LayoutHelpers.CenteredRightOf(GUI.autoKickLabel, GUI.autoKick, 0)
                Tooltip.AddControlTooltip(GUI.autoKickLabel, 'lob_auto_kick')
                autoKick = true
                GUI.autoKick.OnCheck = function(self, checked)
                    autoKick = checked
                    UpdateGame()
                end
                GUI.autoKick:SetCheck(true)
        end
        --end of auto kick code

        GUI.observerList = ItemList(GUI.observerPanel, "observer list")
            GUI.observerList:SetFont(UIUtil.bodyFont, 14)
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
                    {worldCover = false, enterButton = 1, escapeButton = 2})
            end
        end
        UIUtil.CreateVertScrollbarFor2(GUI.observerList, -15, nil, -1)

    else

        -- observers are always allowed in skirmish games.
        SetGameOption("AllowObservers",true)

    end



    ---------------------------------------------------------------------------
    -- other logic, including lobby callbacks
    ---------------------------------------------------------------------------
    GUI.posGroup = false

    -- get ping times
    GUI.pingThread = ForkThread(
        function()
            while true and lobbyComm do
                for slot, player in gameInfo.PlayerOptions do
                    if player.Human and player.OwnerID != localPlayerID then
                        local peer = lobbyComm:GetPeer(player.OwnerID)
                        local ping = peer.ping and math.floor(peer.ping)
                        local pingcolor = CalcConnectionStatus(peer)
                        --GUI.slots[slot].pingText:SetText(tostring(ping))
                        --GUI.slots[slot].pingText:SetColor(pingcolor)
                        if ping and GUI.slots[slot].pingStatus then
                            GUI.slots[slot].pingStatus:SetValue(ping)
                            GUI.slots[slot].pingStatus:Show()
                            if pingcolor == 'red' then
                                GUI.slots[slot].pingStatus._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-03_bmp.dds'))
                            elseif pingcolor == 'green' then
                                GUI.slots[slot].pingStatus._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-02_bmp.dds'))
                            elseif pingcolor == 'yellow' then
                                GUI.slots[slot].pingStatus._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'))
                            end
                        else
                            GUI.slots[slot].pingStatus:Hide()
                        end
                    end
                end
                for slot, observer in gameInfo.Observers do
                    if observer and (observer.OwnerID != localPlayerID) and observer.ObserverListIndex then
                        local peer = lobbyComm:GetPeer(observer.OwnerID)

                        --Lobby "bug" fix.  This should fix the problem where the lobby pings get bugged.
                        -- -Duck42
                        local ping = 0
                        if peer.ping != nil then
                            ping = math.floor(peer.ping)
                        end


                        -- CPU benchmark modified code
                        local score_CPU =  FindBenchmarkForName(observer.PlayerName)
                        local cputext = ""
                        if score_CPU then
                            cputext = ", CPU = "..tostring(score_CPU.Result)
                        end
                        pingtext = LOC("<LOC lobui_0240> (Ping = ")..tostring(ping)
                        ratingtext = ", Rating = " .. tostring(observer.PL)
                        --PlayerName (Ping = xxx, Rating = xxx, CPU = xxx)
                        GUI.observerList:ModifyItem(observer.ObserverListIndex, observer.PlayerName .. pingtext ..
                                                    ratingtext .. cputext .. ")")
                    elseif observer.OwnerID == localPlayerID then

                        local score_CPU =  FindBenchmarkForName(observer.PlayerName)
                        local cputext = ""
                        if score_CPU then
                            cputext = ", CPU = "..tostring(score_CPU.Result)
                        end
                        pingtext = ""
                        ratingtext = " (Rating = "..tostring(observer.PL)
                        --PlayerName (Rating = xxx, CPU = xxx)
                        GUI.observerList:ModifyItem(observer.ObserverListIndex, observer.PlayerName..ratingtext .. cputext..")")
                        -- End CPU benchmark modified code
                    end
                end
                WaitSeconds(1)
            end
        end
    )

    -- CPU Benchmark code
    if not singlePlayer then
        CreateCPUMetricUI()
        ForkThread(function() StressCPU(10) end)
    end
    -- End CPU Benchmark code

    GUI.uiCreated = true
end

function RefreshOptionDisplayData(scenarioInfo)
    local globalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
    local teamOptions = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
    local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts
    formattedOptions = {}

--// Check Ranked active -- Xinnony & Vicarian
    local getInit = GetCommandLineArg("/init", 1)
    getInit = tostring(getInit[1])
    if getInit == "init_faf.lua" then
        SetText2(randmapText3, 'FA Forever - ', 10)
        --AddChatText('Welcome to Forged Alliance Forever MOD'..getInit)
        local getVictory = gameInfo.GameOptions['Victory'] -- 'demoralization'
        local getCheat = gameInfo.GameOptions['CheatsEnabled'] -- 'false'
        local getSpeed = gameInfo.GameOptions['GameSpeed'] -- 'normal'
        local getFog = gameInfo.GameOptions['FogOfWar'] -- 'explored'
        local getPrebui = gameInfo.GameOptions['PrebuiltUnits'] -- 'Off'
        local getNorush = gameInfo.GameOptions['NoRushOption'] -- 'Off'
        local getNumbMod = table.getn(Mods.GetGameMods(gameInfo.GameMods)) -- 0 for the purposes of this function
        local getRstric = gameInfo.GameOptions.RestrictedCategories --can be nil or a table, even if no restrictions are present
--~             AddChatText(tostring(cRstr))
        if getVictory == 'demoralization' and getCheat == 'false' and getSpeed == 'normal' and getFog == 'explored' and getPrebui == 'Off' and getNorush == 'Off' and getNumbMod == 0 and getRstric == (nil or 0) then
            --table.insert(formattedOptions, {text = 'Ranking',
                --value = 'Ranked',
                --green = true,
                --tooltip = {text='Ranked',body='This game is Ranked !'}})
            SetText2(GUI.RankedLabel, "game is Ranked", 10)
            GUI.RankedLabel:SetColor("77ff77")
            --Tooltip.AddControlTooltip(GUI.RankedLabel, '')
        else
            --table.insert(formattedOptions, {text = 'Ranking',
                --value = 'Unranked',
                --red = true,
                --tooltip = {text='Unranked',body='This game is NOT Ranked !'}})
            SetText2(GUI.RankedLabel, "not Ranked", 10)
            GUI.RankedLabel:SetColor("ff7777")
            --Tooltip.AddControlTooltip(GUI.RankedLabel, '')
        end
    else
        if getInit == "init_blackops.lua" then
            SetText2(randmapText3, 'BlackOps MOD - ', 10)
        elseif getInit == "init_balancetesting.lua" then
            SetText2(randmapText3, 'Balance Testing - ', 10)
        elseif getInit == "init_gw.lua" then
            SetText2(randmapText3, 'Galactic War - ', 10)
        elseif getInit == "init_labwars.lua" then
            SetText2(randmapText3, 'Labwars MOD - ', 10)
        elseif getInit == "init_ladder1v1.lua" then
            SetText2(randmapText3, 'Ladder 1v1 - ', 10)
        elseif getInit == "init_nomads.lua" then
            SetText2(randmapText3, 'Nomads MOD - ', 10)
        elseif getInit == "init_phantomx.lua" then
            SetText2(randmapText3, 'PhantomX MOD - ', 10)
        elseif getInit == "init_supremedestruction.lua" then
            SetText2(randmapText3, 'SupremeDestruction MOD - ', 10)
        elseif getInit == "init_xtremewars.lua" then
            SetText2(randmapText3, 'XtremeWars MOD - ', 10)
        --else
            --randmapText3:SetText('')
        end
        --table.insert(formattedOptions, {text = 'Ranking',
            --value = 'Unranked',
            --red = true,
            --tooltip = {text='Unranked',body='This game is NOT Ranked !'}})
        SetText2(GUI.RankedLabel, "not Ranked", 10)
    
        GUI.RankedLabel:SetColor("ff7777")
        --Tooltip.AddControlTooltip(GUI.RankedLabel, '')
    end
--\\ Stop Check Ranked active
--// Check Mod active
    local modNum = table.getn(Mods.GetGameMods(gameInfo.GameMods))
    if modNum > 0 then
        local modStr = '<LOC lobby_0002>%d Mods Enabled'
        if modNum == 1 then
            modStr = '<LOC lobby_0004>%d Mod Enabled'
        end
        table.insert(formattedOptions, {text = LOCF(modStr, modNum),
            value = LOC('<LOC lobby_0003>Check Mod Manager'),
            mod = true,
            tooltip = 'Lobby_Mod_Option',
            valueTooltip = 'Lobby_Mod_Option'})
    end
--\\ Stop Check Mod active
--// Check RestrictedUnit active
    if gameInfo.GameOptions.RestrictedCategories != nil then
        if table.getn(gameInfo.GameOptions.RestrictedCategories) != 0 then
            table.insert(formattedOptions, {text = LOC("<LOC lobby_0005>Build Restrictions Enabled"),
            value = LOC("<LOC lobby_0006>Check Unit Manager"),
            mod = true,
            tooltip = 'Lobby_BuildRestrict_Option',
            valueTooltip = 'Lobby_BuildRestrict_Option'})
        end
    end
--\\ Stop Check RestrictedUnit active
--// Check MapSize & MaxPlayer active -- Disable because is Added in Tooltip on RankedLabel Label (randmapText)
    --if scenarioInfo then
        --table.insert(formattedOptions, {text = '<LOC MAPSEL_0024>',
            --value = LOCF("<LOC map_select_0008>%dkm x %dkm", scenarioInfo.size[1]/50, scenarioInfo.size[2]/50),
            --tooltip = 'map_select_sizeoption',
            --valueTooltip = 'map_select_sizeoption'})
        --table.insert(formattedOptions, {text = '<LOC MAPSEL_0031>Max Players',
            --value = LOCF("<LOC map_select_0009>%d", table.getsize(scenarioInfo.Configurations.standard.teams[1].armies)),
            --tooltip = 'map_select_maxplayers',
            --valueTooltip = 'map_select_maxplayers'})
    --end
--\\ Stop Check MapSize & MaxPlayer active
--// Check other options active
    for i, v in gameInfo.GameOptions do
        local option = false
        local mpOnly = false
        --RankedOptions
        --Mod Options
        --Unit Manager
        --globalOpts
        --teamOptions
        --AIOpts
        --AdvancedOptions
        for index, optData in globalOpts do
            if i == optData.key then
                mpOnly = optData.mponly or false
                option = {text = optData.label, tooltip = optData.pref}
                for _, val in optData.values do
                    if val.key == v then
                        option.value = val.text
                            option.valueTooltip = 'lob_'..optData.key..'_'..val.key
                        break
                    end
                end
                break
            end
        end
        if not option then
            for index, optData in teamOptions do
                if i == optData.key then
                    option = {text = optData.label, tooltip = optData.pref}
                    for _, val in optData.values do
                        if val.key == v then
                            option.value = val.text
                            option.valueTooltip = 'lob_'..optData.key..'_'..val.key
                            break
                        end
                    end
                    break
                end
            end
        end
        if not option then
            for index, optData in AIOpts do
                if i == optData.key then
                    option = {text = optData.label, tooltip = optData.pref}
                    for _, val in optData.values do
                        if val.key == v then
                            option.value = val.text
                            option.valueTooltip = 'lob_'..optData.key..'_'..val.key
                            break
                        end
                    end
                    break
                end
            end
        end
        if not option and scenarioInfo.options then
            for index, optData in scenarioInfo.options do
                if i == optData.key then
                    option = {text = optData.label, tooltip = optData.pref}
                    for _, val in optData.values do
                        if val.key == v then
                            option.value = val.text
                            option.valueTooltip = 'lob_'..optData.key..'_'..val.key
                            break
                        end
                    end
                    break
                end
            end
        end
        if option then
            if not mpOnly or not singlePlayer then
                table.insert(formattedOptions, option)
                --table.removeByValue(formattedOptions, option.value)
                --AddChatText("__opt__"..option.value)
            end
        end
    end

    -- XinnonyWork
    --Remove_Unchanged_Options()
    -- XinnonyWork

-- Disable before separate AI option on GlobalOption, but the order can set on lobbyOptions.lua - Xinnony
--    table.sort(formattedOptions,
--        function(a, b)
--            if a.mod or b.mod then
--                return a.mod or false
--            else
--                return LOC(a.text) < LOC(b.text)
--            end
--        end)
    if GUI.OptionContainer.CalcVisible then
        GUI.OptionContainer:CalcVisible()
    end
end

function wasConnected(peer)
    for _,v in pairs(connectedTo) do
        if v == peer then
            return true
        end
    end
    return false
end

function CalcConnectionStatus(peer)
    if peer.status != 'Established' then
        return 'red'
    else
        if not wasConnected(peer.id) then
            table.insert(connectedTo, peer.id)
            GpgNetSend('Connected', string.format("%d", peer.id))
        end

        if not table.find(peer.establishedPeers, lobbyComm:GetLocalPlayerID()) then
            -- they haven't reported that they can talk to us?
            return 'yellow'
        end

        local peers = lobbyComm:GetPeers()
        for k,v in peers do
            if v.id != peer.id and v.status == 'Established' then
                if not table.find(peer.establishedPeers, v.id) then
                    -- they can't talk to someone we can talk to.
                    return 'yellow'
                end
            end
        end
        return 'green'
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
        if id != localPlayerID then
            local peer = lobbyComm:GetPeer(id)
            for k2,other in important do
                if id != other and not table.find(peer.establishedPeers, other) then
                    result = false
                    AddChatText(LOCF("<LOC lobui_0299>%s doesn't have an established connection to %s",
                                     peer.name,
                                     lobbyComm:GetPeer(other).name))
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
        GUI.markers[slot].marker:SetSolidColor('ff777777')

        GUI.markers[slot].teamIndicator = Bitmap(GUI.markers[slot].marker)
        LayoutHelpers.AnchorToRight(GUI.markers[slot].teamIndicator, GUI.markers[slot].marker, 1)
        LayoutHelpers.AtTopIn(GUI.markers[slot].teamIndicator, GUI.markers[slot].marker, 5)
        GUI.markers[slot].teamIndicator:DisableHitTest()

        if gameInfo.GameOptions['AutoTeams'] and not gameInfo.AutoTeams[slot] and lobbyComm:IsHost() then
            gameInfo.AutoTeams[slot] = 2
        end

        GUI.markers[slot].markerOverlay = Button(GUI.markers[slot].marker,
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'))
        LayoutHelpers.AtCenterIn(GUI.markers[slot].markerOverlay, GUI.markers[slot].marker)
        GUI.markers[slot].markerOverlay.Slot = slot
        GUI.markers[slot].markerOverlay.OnClick = function(self, modifiers)
            if modifiers.Left then
                if gameInfo.GameOptions['TeamSpawn'] != 'random' then
                    if FindSlotForID(localPlayerID) != self.Slot and gameInfo.PlayerOptions[self.Slot] == nil then
                        if IsPlayer(localPlayerID) then
                            if lobbyComm:IsHost() then
                                HostTryMovePlayer(hostID, FindSlotForID(localPlayerID), self.Slot)
                            else
                                lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID),
                                                            RequestedSlot =  self.Slot})
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
                            if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or
                                                                   gameInfo.GameOptions['TeamSpawn'] == 'random') then
                                if gameInfo.AutoTeams[slot] == 7 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                                    gameInfo.AutoTeams[slot] = 2
                                elseif gameInfo.AutoTeams[slot] == 2 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                                    gameInfo.AutoTeams[slot] = 3
                                elseif gameInfo.AutoTeams[slot] == 3 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[4]))
                                    gameInfo.AutoTeams[slot] = 4
                                elseif gameInfo.AutoTeams[slot] == 4 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[5]))
                                    gameInfo.AutoTeams[slot] = 5
                                elseif gameInfo.AutoTeams[slot] == 5 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[6]))
                                    gameInfo.AutoTeams[slot] = 6
                                elseif gameInfo.AutoTeams[slot] == 6 then
                                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[7]))
                                    gameInfo.AutoTeams[slot] = 7
                                end
                                lobbyComm:BroadcastData(
                                    {
                                        Type = 'AutoTeams',
                                        Slot = slot,
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
                if gameInfo.GameOptions['TeamSpawn'] != 'random' then
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
        GUI.markers[slot].Indicator = Bitmap(GUI.markers[slot].marker, UIUtil.UIFile(
                                                                                '/game/beacons/beacon-quantum-gate_btn_up.dds'))
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
            GUI.markers[slot].marker:SetSolidColor("ff777777")
        else
            if gameInfo.PlayerOptions[slot] then
                GUI.markers[slot].marker:SetSolidColor(gameColors.PlayerColors[gameInfo.PlayerOptions[slot].PlayerColor])
                if gameInfo.PlayerOptions[slot].Team == 1 then
                    GUI.markers[slot].teamIndicator:SetSolidColor('00000000')
                else
                    GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.PlayerOptions[slot].Team]))
                end
            else
                GUI.markers[slot].marker:SetSolidColor("ff777777")
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
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or
                                                       gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    local markerPos = GUI.markers[slot].marker.Top()
                    if markerPos < midLine then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                    else
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or
                                                       gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    if slot == 1 or slot == 3 or slot == 5 or slot == 7 or slot == 9 or slot == 11 then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[2]))
                    else
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[3]))
                    end
                end
            elseif gameInfo.GameOptions['AutoTeams'] == 'manual' and gameInfo.GameOptions['TeamSpawn'] == 'random' then
                if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or
                                                       gameInfo.GameOptions['TeamSpawn'] == 'random') then
                    if gameInfo.AutoTeams[slot] then
                        GUI.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.AutoTeams[slot]]))
                    else
                        GUI.markers[slot].teamIndicator:SetSolidColor('00000000')
                    end
                end
            end
        end

        if gameInfo.ClosedSlots[slot] != nil then
            local textOverlay = Text(GUI.markers[slot].markerOverlay)
            textOverlay:SetFont(UIUtil.bodyFont, 14)
            textOverlay:SetColor("Crimson")
            textOverlay:SetText("X")
            LayoutHelpers.AtCenterIn(textOverlay, GUI.markers[slot].markerOverlay)
        end
    end
end

-- LobbyComm Callbacks
function InitLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    lobbyComm = LobbyComm.CreateLobbyComm(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider)
    if not lobbyComm then
        error('Failed to create lobby using port ' .. tostring(localPort))
    --else
        --if GUI.chatDisplay then
            --AddChatText(">> InitLobbyComm : OK !")
        --end
    end
    
    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED ",reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI.panel, LOCF(Strings.ConnectionFailed, Strings[reason] or reason),
                                                           "<LOC _OK>", ReturnToMenu)

        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        AddChatText(LOC(Strings[reasonKey] or reasonKey))
    end

    lobbyComm.Ejected = function(self,reason)
        LOG("EJECTED ",reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI, LOCF(Strings.Ejected, Strings[reason] or reason),
                                                           "<LOC _OK>", ReturnToMenu)
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
            lobbyComm:SendData( hostID, { Type = 'AddObserver', RequestedObserverName = localPlayerName, } )
        else
            -- Ok, I'm connected to the host. Now request to become a player
            local requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
            if (requestedFaction == nil) or (requestedFaction > table.getn(FactionData.Factions)) then
                requestedFaction = table.getn(FactionData.Factions) + 1
            end

            if hasSupcom == false then
                requestedFaction = 4
            end

            lobbyComm:SendData( hostID, {
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
                } )
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
        end
        GUI.keepAliveThread = ForkThread(KeepAliveThreadFunc)

        CreateUI(LobbyComm.maxPlayerSlots)
    end

    lobbyComm.DataReceived = function(self,data)
        --LOG('DATA RECEIVED: ', repr(data))

        -- Messages anyone can receive
        if data.Type == 'PlayerOption' then
            if gameInfo.PlayerOptions[data.Slot].OwnerID != data.SenderID then
                WARN("Attempt to set option on unowned slot.")
                return
            end
            gameInfo.PlayerOptions[data.Slot][data.Key] = data.Value
            UpdateGame()
        elseif data.Type == 'PublicChat' then
            AddChatText("["..data.SenderName.."] "..data.Text)
        elseif data.Type == 'PrivateChat' then
            AddChatText("<<"..data.SenderName..">> "..data.Text)
        --// RULE TITLE - Xinnony
        elseif data.Type == 'Rule_Title_MSG' then
            if XinnonyDebug == 2 then LOG(">> RECEIVE MSG Rule_Title_MSG : result="..(data.Result or "?")) end
            if XinnonyDebug == 2 then AddChatText(">> RECEIVE MSG Rule_Title_MSG : result="..data.Result) end
            RuleTitle_SetText(data.Result or "")
        --\\ Stop RULE TITLE
        -- CPU benchmark code
        elseif data.Type == 'CPUBenchmark' then
            --LOG("CPU Data: "..(data.PlayerName or "?")..", ".. (data.Result or "?"))
            AddPlayerBenchmark(data)
            local playerId = FindIDForName(data.PlayerName)
            local playerSlot = FindSlotForID(playerId)
            if playerSlot != nil then
                 SetSlotCPUBar(playerSlot, gameInfo.PlayerOptions[playerSlot])
            end
        -- End CPU benchmark code
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
                    HostTryAddObserver( data.SenderID, data.RequestedObserverName )
                else
                    lobbyComm:EjectPeer(data.SenderID, 'NoObservers');
                end

            elseif data.Type == 'RequestConvertToObserver' then
                HostConvertPlayerToObserver(data.SenderID, data.RequestedName, data.RequestedSlot)

            elseif data.Type == 'RequestConvertToPlayer' then
                HostConvertObserverToPlayer(data.SenderID, data.RequestedName, data.ObserverSlot, data.PlayerSlot,
                                            data.requestedFaction, data.requestedPL, data.requestedRC, data.requestedNG)

            elseif data.Type == 'RequestColor' then
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
        else
            -- Non-host only messages
            if data.Type == 'SystemMessage' then
                AddChatText(data.Text)

            elseif data.Type == 'Peer_Really_Disconnected' then
                if XinnonyDebug == 3 then AddChatText('>> DATA RECEIVE : Peer_Really_Disconnected (slot:'..data.Slot..')') end
                if XinnonyDebug == 3 then LOG('>> DATA RECEIVE : Peer_Really_Disconnected (slot:'..data.Slot..')') end
                if data.Options.OwnerID == localPlayerID then
                    lobbyComm:SendData( hostID, {Type = "GetGameInfo"} )
                else
                    if data.Observ == false then
                        gameInfo.PlayerOptions[data.Slot] = nil
                    elseif data.Observ == true then
                        gameInfo.Observers[data.Slot] = nil
                    end
                    --gameInfo.Observers[data.NewSlot] = data.Options
                    --gameInfo.PlayerOptions[data.OldSlot] = nil
                end
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
                UpdateGame()

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
                gameInfo.PlayerOptions[data.Slot].PlayerColor = data.Color
                gameInfo.PlayerOptions[data.Slot].ArmyColor = data.Color
                UpdateGame()

            elseif data.Type == 'GameInfo' then
                -- Note: this nukes whatever options I may have set locally
                gameInfo = data.GameInfo
                --LOG('Got GameInfo: ', repr(gameInfo))
                UpdateGame()

            elseif data.Type == 'GameOption' then
                gameInfo.GameOptions[data.Key] = data.Value
                UpdateGame()

            elseif data.Type == 'Launch' then
                local info = data.GameInfo
                info.GameMods = Mods.GetGameMods(info.GameMods)
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
                ModManager.UpdateClientModStatus(gameInfo.GameMods)

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
            SetGameOption(option.key,option.values[defValue].key)
        end

        for index, option in teamOpts do
            local defValue = Prefs.GetFromCurrentProfile(option.pref) or option.default
            SetGameOption(option.key,option.values[defValue].key)
        end

        for index, option in AIOpts do
            local defValue = Prefs.GetFromCurrentProfile(option.pref) or option.default
            SetGameOption(option.key,option.values[defValue].key)
        end

        if self.desiredScenario and self.desiredScenario != "" then
            Prefs.SetToCurrentProfile('LastScenario', self.desiredScenario)
            SetGameOption('ScenarioFile',self.desiredScenario)
        else
            local scen = Prefs.GetFromCurrentProfile('LastScenario')
            if scen and scen != "" then
                SetGameOption('ScenarioFile',scen)
            end
        end

        GUI.keepAliveThread = ForkThread(
            -- Eject players who haven't sent a heartbeat in a while
            function()
                while true and lobbyComm do
                    local peers = lobbyComm:GetPeers()
                    for k,peer in peers do
                        if peer.quiet > LobbyComm.quietTimeout then
                            lobbyComm:EjectPeer(peer.id,'TimedOutToHost')
                            SendSystemMessage(LOCF(Strings.TimedOut,peer.name))
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

    lobbyComm.PeerDisconnected = function(self,peerName,peerID)
        LOG('>DEBUG> PeerDisconnected : peerName='..peerName..' peerID='..peerID)
        --AddChatText('>debug> PeerDisconnected : peerName='..peerName..' peerID='..peerID) -- XINNONY -- Here this message always show the player quit !!!
        if XinnonyDebug == 3 then AddChatText('>> PeerDisconnected : peerName='..peerName..' peerID='..peerID) end -- XINNONY -- Here this message always show the player quit !!!
        if XinnonyDebug == 3 then LOG('GameInfo = ', repr(gameInfo)) end
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
                ClearSlotInfo( slot )
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

function SetPlayerOption(slot, key, val)
    if not IsLocallyOwned(slot) then
        WARN("Hey you can't set a player option on a slot you don't own.")
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
    UpdateGame()
end

function SetGameOption(key, val, ignoreNilValue)
    ignoreNilValue = ignoreNilValue or false

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

        LOG('SetGameOption(key='..repr(key)..',val='..repr(val))

        -- don't want to send all restricted categories to gpgnet, so just send bool
        -- note if more things need to be translated to gpgnet, a translation table would be a better implementation
        -- but since there's only one, we'll call it out here
        if key == 'RestrictedCategories' then
            local restrictionsEnabled = false
            if val != nil then
                if table.getn(val) != 0 then
                    restrictionsEnabled = true
                end
            end
            GpgNetSend('GameOption', key, restrictionsEnabled)
        elseif key == 'ScenarioFile' then
            GpgNetSend('GameOption', key, val)
             if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") then
                scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
                if scenarioInfo then
                    GpgNetSend('GameOption', 'Slots', table.getsize(scenarioInfo.Configurations.standard.teams[1].armies))
                end
            end
        else
            GpgNetSend('GameOption', key, val)
        end

        UpdateGame()
    else
        WARN('Attempt to set game option by a non-host')
    end
end

function DebugDump()
    if lobbyComm then
        lobbyComm:DebugDump()
    end
end


-------------------------------------------------------  Big Map Preview  ------------------------------------------------------
------------------------------------------------------- (Code by ThaPear) ------------------------------------------------------

LrgMap = false
function CreateBigPreview(depth, parent)
    local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview

    if LrgMap then
        CloseBigPreview()
    end
    LrgMap = MapPreview(parent)
    LrgMap.OnDestroy = function(self) LrgMap = false end
    LrgMap.Width:Set(710)
    LrgMap.Height:Set(710)
    LrgMap.Depth:Set(depth)
    LrgMap:Show() -- for accessibility from mapselect.lua
    LrgMap.Overlay = Bitmap(LrgMap, UIUtil.SkinnableFile("/lobby/lan-game-lobby/map-pane-border_bmp.dds"))
    LrgMap.Overlay.Height:Set(830)
    LrgMap.Overlay.Width:Set(830)

    LrgMap.Top:Set(function() return GetFrame(0).Height()/2-LrgMap.Overlay.Height()/2 + 60 end)
    LrgMap.Left:Set(function() return GetFrame(0).Width()/2-LrgMap.Overlay.Width()/2 + 60 end)
    LrgMap.Overlay.Top:Set(function() return LrgMap.Top() - 60 end)
    LrgMap.Overlay.Left:Set(function() return LrgMap.Left() - 60 end)

    LrgMap.Overlay.Depth:Set(function() return LrgMap.Depth()+1 end)

    LrgMap.CloseBtn = UIUtil.CreateButtonStd(LrgMap, '/dialogs/close_btn/close', "", 12, 2, 0, "UI_Tab_Click_01",
                                             "UI_Tab_Rollover_01")
    LayoutHelpers.AtRightTopIn(LrgMap.CloseBtn, LrgMap, -15, -10)
    LrgMap.CloseBtn.Depth:Set(function() return LrgMap.Overlay.Depth()+1 end)
    LrgMap.CloseBtn.OnClick = function()
        CloseBigPreview()
    end

    scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    if scenarioInfo and scenarioInfo.map and (scenarioInfo.map != "") then
        if not LrgMap:SetTexture(scenarioInfo.preview) then
            LrgMap:SetTextureFromMap(scenarioInfo.map)
        end
    end

    local mapdata = {}
    doscript('/lua/dataInit.lua', mapdata) -- needed for the format of _save files
    doscript(scenarioInfo.save, mapdata) -- ...

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

    LrgMap.massmarkers = {}
    for i = 1, table.getn(massmarkers) do
        LrgMap.massmarkers[i] = Bitmap(LrgMap, UIUtil.SkinnableFile("/game/build-ui/icon-mass_bmp.dds"))
        LrgMap.massmarkers[i].Width:Set(10)
        LrgMap.massmarkers[i].Height:Set(10)
        LrgMap.massmarkers[i].Left:Set(LrgMap.Left() + massmarkers[i].position[1]/scenarioInfo.size[1]*LrgMap.Width() -
                                       LrgMap.massmarkers[i].Width()/2)
        LrgMap.massmarkers[i].Top:Set(LrgMap.Top() + massmarkers[i].position[3]/scenarioInfo.size[2]*LrgMap.Height() -
                                      LrgMap.massmarkers[i].Height()/2)
    end
    LrgMap.hydros = {}
    for i = 1, table.getn(hydromarkers) do
        LrgMap.hydros[i] = Bitmap(LrgMap, UIUtil.SkinnableFile("/game/build-ui/icon-energy_bmp.dds"))
        LrgMap.hydros[i].Width:Set(14)
        LrgMap.hydros[i].Height:Set(14)
        LrgMap.hydros[i].Left:Set(LrgMap.Left() + hydromarkers[i].position[1]/scenarioInfo.size[1]*LrgMap.Width() -
                                  LrgMap.hydros[i].Width()/2)
        LrgMap.hydros[i].Top:Set(LrgMap.Top() + hydromarkers[i].position[3]/scenarioInfo.size[2]*LrgMap.Height() -
                                 LrgMap.hydros[i].Height()/2)
    end

    -- start positions
    LrgMap.markers = {}
    NewShowMapPositions(LrgMap,scenarioInfo,GetPlayerCount())
end -- CreateBigPreview(...)

function CloseBigPreview()
    if LrgMap then
        LrgMap.CloseBtn:Destroy()
        LrgMap.Overlay:Destroy()
        for i = 1, table.getn(LrgMap.massmarkers) do
            LrgMap.massmarkers[i]:Destroy()
        end
        for i = 1, table.getn(LrgMap.hydros) do
            LrgMap.hydros[i]:Destroy()
        end
        LrgMap:Destroy()
        LrgMap = false
    end
end -- CloseBigPreview()

local posGroup = false
 -- copied from the old lobby.lua, needed to change GUI. into LrgMap. for a separately handled set of markers
function NewShowMapPositions(mapCtrl, scenario, numPlayers)
    if scenario.starts == nil then scenario.starts = true end

    if posGroup then
        posGroup:Destroy()
        posGroup = false
    end

    if LrgMap.markers and table.getn(LrgMap.markers) > 0 then
        for i, v in LrgMap.markers do
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
        LrgMap.markers[slot] = {}
        LrgMap.markers[slot].marker = Bitmap(posGroup)
        LrgMap.markers[slot].marker.Height:Set(10)
        LrgMap.markers[slot].marker.Width:Set(8)
        LrgMap.markers[slot].marker.Depth:Set(function() return posGroup.Depth() + 10 end)
        LrgMap.markers[slot].marker:SetSolidColor('ff777777')

        LrgMap.markers[slot].teamIndicator = Bitmap(LrgMap.markers[slot].marker)
        LayoutHelpers.AnchorToRight(LrgMap.markers[slot].teamIndicator, LrgMap.markers[slot].marker, 1)
        LayoutHelpers.AtTopIn(LrgMap.markers[slot].teamIndicator, LrgMap.markers[slot].marker, 5)
        LrgMap.markers[slot].teamIndicator:DisableHitTest()

        LrgMap.markers[slot].markerOverlay = Button(LrgMap.markers[slot].marker,
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'),
            UIUtil.UIFile('/dialogs/mapselect02/commander_alpha.dds'))
        LayoutHelpers.AtCenterIn(LrgMap.markers[slot].markerOverlay, LrgMap.markers[slot].marker)
        LrgMap.markers[slot].markerOverlay.Slot = slot
        LrgMap.markers[slot].markerOverlay.OnClick = function(self, modifiers)
            if modifiers.Left then
                if FindSlotForID(localPlayerID) != self.Slot and gameInfo.PlayerOptions[self.Slot] == nil then
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
        LrgMap.markers[slot].markerOverlay.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if gameInfo.GameOptions['TeamSpawn'] != 'random' then
                    GUI.slots[self.Slot].name.HandleEvent(self, event)
                    LrgMap.markers[self.Slot].Indicator:Play()
                end
            elseif event.Type == 'MouseExit' then
                GUI.slots[self.Slot].name.HandleEvent(self, event)
                LrgMap.markers[self.Slot].Indicator:Stop()
            end
            Button.HandleEvent(self, event)
        end
        LayoutHelpers.AtLeftTopIn(LrgMap.markers[slot].marker, posGroup,
            ((pos[1] / mWidth) * cWidth) - (LrgMap.markers[slot].marker.Width() / 2),
            ((pos[2] / mHeight) * cHeight) - (LrgMap.markers[slot].marker.Height() / 2))

        local index = slot
        LrgMap.markers[slot].Indicator = Bitmap(LrgMap.markers[slot].marker,
                                         UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
        LayoutHelpers.AtCenterIn(LrgMap.markers[slot].Indicator, LrgMap.markers[slot].marker)
        LrgMap.markers[slot].Indicator.Height:Set(function() return LrgMap.markers[index].Indicator.BitmapHeight() * .3 end)
        LrgMap.markers[slot].Indicator.Width:Set(function() return LrgMap.markers[index].Indicator.BitmapWidth() * .3 end)
        LrgMap.markers[slot].Indicator.Depth:Set(function() return LrgMap.markers[index].marker.Depth() - 1 end)
        LrgMap.markers[slot].Indicator:Hide()
        LrgMap.markers[slot].Indicator:DisableHitTest()
        LrgMap.markers[slot].Indicator.Play = function(self)
            self:SetAlpha(1)
            self:Show()
            self:SetNeedsFrameUpdate(true)
            self.time = 0
            self.OnFrame = function(control, time)
                control.time = control.time + (time*4)
                control:SetAlpha(MATH_Lerp(math.sin(control.time), -.5, .5, 0.3, 0.5))
            end
        end
        LrgMap.markers[slot].Indicator.Stop = function(self)
            self:SetAlpha(0)
            self:Hide()
            self:SetNeedsFrameUpdate(false)
        end

        if gameInfo.GameOptions['TeamSpawn'] == 'random' then
            LrgMap.markers[slot].marker:SetSolidColor("ff777777")
        else
            if gameInfo.PlayerOptions[slot] then
                LrgMap.markers[slot].marker:SetSolidColor(gameColors.PlayerColors[gameInfo.PlayerOptions[slot].PlayerColor])
                if gameInfo.PlayerOptions[slot].Team == 1 then
                    LrgMap.markers[slot].teamIndicator:SetSolidColor('00000000')
                else
                    LrgMap.markers[slot].teamIndicator:SetTexture(UIUtil.UIFile(teamIcons[gameInfo.PlayerOptions[slot].Team]))
                end
            else
                LrgMap.markers[slot].marker:SetSolidColor("ff777777")
                LrgMap.markers[slot].teamIndicator:SetSolidColor('00000000')
            end
        end

        if gameInfo.ClosedSlots[slot] != nil then
            local textOverlay = Text(LrgMap.markers[slot].markerOverlay)
            textOverlay:SetFont(UIUtil.bodyFont, 14)
            textOverlay:SetColor("Crimson")
            textOverlay:SetText("X")
            LayoutHelpers.AtCenterIn(textOverlay, LrgMap.markers[slot].markerOverlay)
        end
    end
end -- NewShowMapPositions(...)

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------  Duck_42 Wall  --------------------------------------------------------
--******************************************************************************************************
-- CPU Benchmark Code
-- Author: Duck_42
-- Date: 2013.04.05
--******************************************************************************************************
local benchmarkLength = 5 --5.0 Seconds

--CPU Status Bar Configuration
local barMax = 450
local barMin = 150
local greenBarMax = 300
local yellowBarMax = 375
local scoreSkew1 = -25 --Skews all CPU scores up or down by the amount specified (0 = no skew)
local scoreSkew2 = 1.0 --Skews all CPU scores specified coefficient (1.0 = no skew)

--Variables for CPU Test
local running
local loopCount
local firstCPUTest = true

--------------------------------------------------
--  CPU Benchmark Storage and Retrieval Functions
--------------------------------------------------
function AddPlayerBenchmark(data)
    --This function stores CPU benchmark results from the host
    --and/or other players in the appropriate table.
    --    data: The benchamark data to store {PlayerName, Result}
    local alreadyExists = false
    for i,benchmark in CPU_BenchmarkList do
        if data.PlayerName == benchmark.PlayerName then
            alreadyExists = true
            CPU_BenchmarkList[i].Result = data.Result
        end
    end
    if not alreadyExists then
        table.insert(CPU_BenchmarkList, {PlayerName = data.PlayerName, Result = data.Result})
    end
end

function FindBenchmarkForName(name)
    --Given a playername, this function looks up the corresponding benchmark in the table and returns it
    --A value of false is returned if the name is not in the benchmark table
    for i,benchmark in CPU_BenchmarkList do
        if name == benchmark.PlayerName then
            return benchmark
        end
    end
    return false
end

--------------------------------------------------
--  CPU Benchmarking Functions
--------------------------------------------------
function CPUBenchmark()
    --This function gives the CPU some busy work to do.
    --CPU score is determined by how many times it can loop through
    --the set of busy work before the timer in the CPUTimer function expires.
    while running do
         for i = 1.0, 2.0, .000008 do 
            j = i + i
            k = i * i
            l = k / j
            m = j - i
        end
        loopCount = loopCount + 1
        --This is necessary in order to make this 'thread' yield so other things can be done (namely the CPUTimer function).
        WaitSeconds(0)
     end
end

function CPUTimer()
    --This function handles the benchmark timer.  When this function completes, the benchmark is stopped.
    WaitSeconds(benchmarkLength)
    running = false
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
                    UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                    UIUtil.SkinnableFile('/game/unit_bmp/bar02_bmp.dds'),
                    true)
                LayoutHelpers.AtBottomIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 1)
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

function StressCPU(waitTime)
    --This function instructs the PC to do a CPU score benchmark.
    --It handles the necessary UI updates during the benchmark, sends
    --the benchmark result to other players when finished, and it updates the local
    --user's UI with their new result.
    --    waitTime: The delay in seconds that this function should wait before starting the benchmark.

    for i = waitTime, 1, -1 do
        GUI.rerunBenchmark.label:SetText(i..'s')
        WaitSeconds(1)
    end

    --Get our last benchmark (if there was one)
    local currentBestBenchmark = FindBenchmarkForName(localPlayerName)
    if currentBestBenchmark == false then
        currentBestBenchmark = 10000
    end

    --LOG('Beginning CPU benchmark')
    GUI.rerunBenchmark.label:SetText('. . .')

    --Run three benchmarks and keep the best one
    for i=1, 3, 1 do
        loopCount = 0
        running = true
        ForkThread(CPUTimer)
        CPUBenchmark()

        --Invert scale for display purposes
        --With .01 sec wait intervals the max number of loops should be 100 * benchmarkLength
        loopCount = (benchmarkLength * 100) - math.min(scoreSkew2 * loopCount + scoreSkew1, (benchmarkLength * 100))

        --LOG('CPU benchmark #'..i..' complete: '.. loopCount )

        --If this benchmark was better than our best so far...
        if loopCount < currentBestBenchmark then
            --Make this our best benchmark
            currentBestBenchmark = loopCount

            --Send it to the other players
            lobbyComm:BroadcastData( { Type = 'CPUBenchmark', PlayerName = localPlayerName, Result = currentBestBenchmark} )

            --Add the benchmark to the local benchmark table
            AddPlayerBenchmark({PlayerName = localPlayerName, Result = currentBestBenchmark})

            --Update the UI bar
            UpdateCPUBar(localPlayerName)
        end
    end

    --Show message if player's score is very low
    if currentBestBenchmark >= 450 and firstCPUTest then
        AddChatText(LOCF('<LOC lobui_0901>SYSTEM: Your CPU score is unusually low.'))
        AddChatText(LOCF('<LOC lobui_0902>SYSTEM: This can be caused by using ALT-TAB or minimizing the game after joining.'))
        AddChatText(LOCF('<LOC lobui_0903>SYSTEM: Certain CPU power saving features can also cause this.'))
        AddChatText(LOCF('<LOC lobui_0903>SYSTEM: After joining the lobby, please wait 15 seconds before using ALT-TAB or '..
                         'minimizing.'))
        AddChatText(LOCF('<LOC lobui_0903>SYSTEM: If you continue to see this message anyway, please let us know on the FAF '..
                         'forums.'))
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
    if playerSlot != nil then
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
            local b = FindBenchmarkForName(playerInfo.PlayerName)
            if b then
                -- For display purposes, the bar has a higher minimum that the actual barMin value.
                -- This is to ensure that the bar is visible for very small values
                local clampedResult =  math.max(math.min(b.Result, barMax), barMin + math.floor(.04 * (barMax - barMin)))
                GUI.slots[slot].CPUSpeedBar:SetValue(clampedResult)
                
                --For the tooltip, we use the actual clamped value
                GUI.slots[slot].CPUSpeedBar.CPUActualValue = b.Result
                GUI.slots[slot].CPUSpeedBar:Show()

                GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar02_bmp.dds'))

                -- if clampedResult <= greenBarMax then
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-02_bmp.dds'))
                -- elseif clampedResult <= yellowBarMax then
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'))
                -- else
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-03_bmp.dds'))
                -- end
            end
        end
    end
end



##########################################################################
################################  Xinnony Wall  ################################
--------------------------------------------------
-- CountryFlag Functions                            --
-- Author : Xinnony                                --
--------------------------------------------------
function SetSlotCountryFlag(slot, COUNTRY)
    if GUI.slots[slot].KinderCountry then
        if COUNTRY == nil then -- No flag
            GUI.slots[slot].KinderCountry:Hide()
        elseif COUNTRY == '' then -- No flag
            GUI.slots[slot].KinderCountry:Show()
            GUI.slots[slot].KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..'world'..'.dds'))
            Country_GetTooltipValue(COUNTRY, slot)
            Country_AddControlTooltip(GUI.slots[slot].KinderCountry, 0, slot)
        --elseif COUNTRY == ('xxx' or 'xxx') then -- Here you can put the missing texture Flag
            --GUI.slots[slot].KinderCountry:Show()
            --GUI.slots[slot].KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..'world'..'.dds'))
        else
            GUI.slots[slot].KinderCountry:Show()
            GUI.slots[slot].KinderCountry:SetTexture(UIUtil.UIFile('/countries/'..COUNTRY..'.dds'))
            Country_GetTooltipValue(COUNTRY, slot)
            Country_AddControlTooltip(GUI.slots[slot].KinderCountry, 0, slot)
        end
    end
end

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
    local CountryOverrideTooltipSpecial = import('/lua/ui/help/tooltips-country.lua').tooltipSpecial
        local find = 0
        for index, option in CountryOverrideTooltip do
            if option.value == CountryResult and find == 0 then
                PrefLanguageTooltipTitle[slot] = option.title
                PrefLanguageTooltipText[slot] = option.text
                find = 1
            end
        end
        for index, option in CountryOverrideTooltipSpecial do
            if option.value == CountryResult and find == 0 then
                PrefLanguageTooltipTitle[slot] = option.title
                PrefLanguageTooltipText[slot] = option.text
                find = 1
            end
        end
end--]]

--------------------------------------------------
-- Change the title for to say the rule        --
-- Author : Xinnony                                --
--------------------------------------------------
function RuleTitle_SendMSG()
    if titleText and lobbyComm:IsHost() then
        if XinnonyDebug == 2 then AddChatText(">> SENDING MSG Rule_Title_MSG : "..titleText:GetText()) end
        lobbyComm:BroadcastData( { Type = 'Rule_Title_MSG', Result = titleText:GetText() } )
    end
end

function RuleTitle_SetText(Title_Data)
    if titleText and not lobbyComm:IsHost() then
        titleText:SetText(Title_Data)
    end
end

function RuleTitle_HostCanEditTitle()
    -- TITRE de la Rule
    --local First_Rule_Change = 0
    titleText = UIUtil.CreateText(GUI.panel, "", 17, 'Arial Gras')--UIUtil.titleFont)
        if lobbyComm:IsHost() then
            LayoutHelpers.AtLeftTopIn(titleText, GUI.panel, 50+24, 41)--36+3) -- Décaler pour le Bouton
        else
            LayoutHelpers.AtLeftTopIn(titleText, GUI.panel, 50, 41)--36+3) -- Caler a gauche
        end
        titleText.Width:Set(20)
        SetText2(titleText, "FA FOREVER GAME LOBBY", 10)
        titleText:SetColor('B9BFB9')
        titleText:SetDropShadow(true)
        
    -- BOUTON
    if lobbyComm:IsHost() then
        NoteBTN = UIUtil.CreateButtonStd(GUI.panel, '/dialogs/config_btn/config', "", 0, 0)
        LayoutHelpers.AtLeftTopIn(NoteBTN, GUI.panel, 50, 36+4)
        Tooltip.AddButtonTooltip(NoteBTN, {text='Click for set the Ruler label', body='This will allow you to view other players you want the rule to apply'})
    end
    
    -- EDITBOX
    if lobbyComm:IsHost() then
        GUI.RuleEdit = Edit(GUI.panel)
            LayoutHelpers.AtLeftTopIn(GUI.RuleEdit, GUI.panel, 50+23, 36+2)
            --LayoutHelpers.AtLeftTopIn(GUI.RuleEdit, GUI.panel, 50, 36+2)
            GUI.RuleEdit.Width:Set(640)
            GUI.RuleEdit.Height:Set(14+6+6)
            --GUI.RuleEdit:SetFont(UIUtil.bodyFont, 16)
            GUI.RuleEdit:SetFont(UIUtil.titleFont, 22)
            GUI.RuleEdit:SetForegroundColor('FFFFFF')--UIUtil.fontColor) -- Couleur de Text
            GUI.RuleEdit:SetBackgroundColor('000000')--UIUtil.fontColor) -- Couleur de Fond
            GUI.RuleEdit:SetHighlightBackgroundColor('000000') -- Fond de Selection
            GUI.RuleEdit:SetHighlightForegroundColor('FFFFFF')--UIUtil.fontColor) -- Text de Selection
            GUI.RuleEdit:ShowBackground(false)
            GUI.RuleEdit:SetMaxChars(60)
            GUI.RuleEdit:Hide() -- TEST
        
        -- FONCTION
        GUI.RuleEdit.OnLoseKeyboardFocus = function(self)
            titleText:Show()
            NoteBTN:Show()
            GUI.RuleEdit:Hide()
            GUI.RuleEdit:ShowBackground(false)
            GUI.chatEdit:AcquireFocus()
        end
        
        NoteBTN.OnClick = function(self, modifiers)
            titleText:Hide()
            NoteBTN:Hide()
            GUI.RuleEdit:Show()
            GUI.RuleEdit:ShowBackground(true)
            GUI.RuleEdit:AcquireFocus()
            --if First_Rule_Change == 0 then
                --GUI.RuleEdit:SetText('RULE:') -- First change, the text 'FA FOREVER GAME LOBBY' replace with 'RULE:'
            --else
                GUI.RuleEdit:SetText(titleText:GetText())
            --end
        end
        
        GUI.RuleEdit.OnCharPressed = function(self, charcode)
            --titleText:Hide()
            --NoteBTN:Hide()
            --GUI.RuleEdit:Show()
            --GUI.RuleEdit:ShowBackground(true)
            --GUI.RuleEdit:SetText(titleText:GetText())
            --GUI.RuleEdit:SetText('RULER:')
            if charcode == UIUtil.VK_TAB then
                return true
            end
            local charLim = self:GetMaxChars()
            if STR_Utf8Len(self:GetText()) >= charLim then
                local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
                PlaySound(sound)
            end
        end
        
        GUI.RuleEdit.OnEscPressed = function(self, text)
            titleText:Show()
            NoteBTN:Show()
            GUI.RuleEdit:Hide()
            GUI.RuleEdit:ShowBackground(false)
        end
        
        GUI.RuleEdit.OnEnterPressed = function(self, text)
            titleText:Show()
            NoteBTN:Show()
            GUI.RuleEdit:Hide()
            GUI.RuleEdit:ShowBackground(false)
            --First_Rule_Change = 1
            if text != "" then
                --GpgNetSend('Chat', text)
                SetText2(titleText, ""..text, 10)
                RuleTitle_SendMSG()
                GUI.chatEdit:AcquireFocus()
            --elseif text == 'RULE:' then -- not working ??...
                --titleText:SetText("FA FOREVER GAME LOBBY (RULE Title)")
            end
        end
    end
end

--------------------------------------------------
-- Create a Faction easy selector                --
-- Author : Xinnony                                --
--------------------------------------------------
function CreateUI_Faction_Selector()
        TEST1factionPanel = Bitmap(GUI.factionPanel, UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
            --LayoutHelpers.AtTopIn(TEST1factionPanel, GUI.factionPanel, 0)
            LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel)
            LayoutHelpers.AtVerticalCenterIn(TEST1factionPanel, GUI.factionPanel)
        TEST2factionPanel = Bitmap(GUI.factionPanel, UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
            --LayoutHelpers.AtTopIn(TEST2factionPanel, GUI.factionPanel, 10)
            LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
            LayoutHelpers.AtVerticalCenterIn(TEST2factionPanel, GUI.factionPanel, 0)
        TEST3factionPanel = Bitmap(GUI.factionPanel, UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
            --LayoutHelpers.AtTopIn(TEST3factionPanel, GUI.factionPanel, 0)
            LayoutHelpers.AtHorizontalCenterIn(TEST3factionPanel, GUI.factionPanel, 0)
            LayoutHelpers.AtVerticalCenterIn(TEST3factionPanel, GUI.factionPanel, 0)
        TEST4factionPanel = Bitmap(GUI.factionPanel, UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
            --LayoutHelpers.AtTopIn(TEST4factionPanel, GUI.factionPanel, 10)
            LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
            LayoutHelpers.AtVerticalCenterIn(TEST4factionPanel, GUI.factionPanel, 0)
        TEST5factionPanel = Bitmap(GUI.factionPanel, UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
            --LayoutHelpers.AtTopIn(TEST5factionPanel, GUI.factionPanel, 0)
            LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
            LayoutHelpers.AtVerticalCenterIn(TEST5factionPanel, GUI.factionPanel, 0)
    end

function SetEvent_Faction_Selector()
    -- set up control logic
        --if not IsObserver(localPlayerID) then
        --if IsPlayer(localPlayerID) then
        TEST1factionPanel.HandleEvent = function(ctrl, event)
        local faction = Prefs.GetFromCurrentProfile('LastFaction')
            local eventHandled = false
            if faction == 2 then
                TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico-large.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, -15)
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                        TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico-hover.dds"))
                        LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                        TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
                        LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true
                    
                    Prefs.SetToCurrentProfile('LastFaction', 2)
                    GUI.slots[FindSlotForID(localPlayerID)].faction:SetItem(2)
                    SetPlayerOption(FindSlotForID(localPlayerID), 'Faction', 2)
                    gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Faction = 2
                    
                    SetCurrentFactionTo_Faction_Selector(2)
                end
                --TEST1factionPanel:OnEvent(event)
            end
            return eventHandled
        end
        --end
        
        --if IsPlayer(localPlayerID) then
        TEST2factionPanel.HandleEvent = function(ctrl, event)
        local faction = Prefs.GetFromCurrentProfile('LastFaction')
            local eventHandled = false
            if faction == 3 then
                TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico-large.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45-15)
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                        TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico-hover.dds"))
                        LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                        TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
                        LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true
                    
                    Prefs.SetToCurrentProfile('LastFaction', 3)
                    GUI.slots[FindSlotForID(localPlayerID)].faction:SetItem(3)
                    SetPlayerOption(FindSlotForID(localPlayerID), 'Faction', 3)
                    gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Faction = 3
                    
                    SetCurrentFactionTo_Faction_Selector(3)
                end
                --TEST2factionPanel:OnEvent(event)
            end
            return eventHandled
        end
        --end
        
        --if IsPlayer(localPlayerID) then
        TEST3factionPanel.HandleEvent = function(ctrl, event)
        local faction = Prefs.GetFromCurrentProfile('LastFaction')
            local eventHandled = false
            if faction == 1 then
                TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico-large.dds"))
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                        TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico-hover.dds"))
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                        TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true
                    
                    Prefs.SetToCurrentProfile('LastFaction', 1)
                    GUI.slots[FindSlotForID(localPlayerID)].faction:SetItem(1)
                    SetPlayerOption(FindSlotForID(localPlayerID), 'Faction', 1)
                    gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Faction = 1
                    
                    SetCurrentFactionTo_Faction_Selector(1)
                end
                --TEST3factionPanel:OnEvent(event)
            end
            return eventHandled
        end
        --end
        
        --if IsPlayer(localPlayerID) then
        TEST4factionPanel.HandleEvent = function(ctrl, event)
        local faction = Prefs.GetFromCurrentProfile('LastFaction')
            local eventHandled = false
            if faction == 4 then
                TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico-large.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45-15)
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                        TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico-hover.dds"))
                        LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                        TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
                        LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true
                    
                    Prefs.SetToCurrentProfile('LastFaction', 4)
                    GUI.slots[FindSlotForID(localPlayerID)].faction:SetItem(4)
                    SetPlayerOption(FindSlotForID(localPlayerID), 'Faction', 4)
                    gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Faction = 4
                    
                    SetCurrentFactionTo_Faction_Selector(4)
                end
                --TEST4factionPanel:OnEvent(event)
            end
            return eventHandled
        end
        --end
        
        --if IsPlayer(localPlayerID) then
        TEST5factionPanel.HandleEvent = function(ctrl, event)
        local faction = Prefs.GetFromCurrentProfile('LastFaction')
            local eventHandled = false
            if faction == 5 then
                TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico-large.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, -15)
            elseif IsPlayer(localPlayerID) then
                if event.Type == 'MouseEnter' then
                        TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico-hover.dds"))
                        LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
                    eventHandled = true
                elseif event.Type == 'MouseExit' then
                        TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
                        LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
                    eventHandled = true
                elseif event.Type == 'ButtonPress' then
                    eventHandled = true
                    
                    Prefs.SetToCurrentProfile('LastFaction', 5)
                    GUI.slots[FindSlotForID(localPlayerID)].faction:SetItem(5)
                    SetPlayerOption(FindSlotForID(localPlayerID), 'Faction', 5)
                    gameInfo.PlayerOptions[FindSlotForID(localPlayerID)].Faction = 5
                    
                    SetCurrentFactionTo_Faction_Selector(5)
                end
                --TEST5factionPanel:OnEvent(event)
            end
            return eventHandled
        end
    end

function SetCurrentFactionTo_Faction_Selector(input_faction)
    local faction = input_faction or Prefs.GetFromCurrentProfile('LastFaction')
        if TEST1factionPanel and TEST2factionPanel and TEST3factionPanel and TEST4factionPanel and TEST5factionPanel then
        if faction == 1 then
            ChangeSkinByFaction(1)
            ChangeSkinButtonByFaction(1)
            ChangeBackgroundLobby(nil, 1)
            TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico-large.dds"))
            TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
            TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
            TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
            TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
        elseif faction == 2 then
            ChangeSkinByFaction(2)
            ChangeSkinButtonByFaction(2)
            ChangeBackgroundLobby(nil, 2)
            TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico-large.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, -15)
            TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
            TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
            TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
            TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
        elseif faction == 3 then
            ChangeSkinByFaction(3)
            ChangeSkinButtonByFaction(3)
            ChangeBackgroundLobby(nil, 3)
            TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico-large.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45-15)
            TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
            TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
            TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
            TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
        elseif faction == 4 then
            ChangeSkinByFaction(4)
            ChangeSkinButtonByFaction(4)
            ChangeBackgroundLobby(nil, 4)
            TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico-large.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45-15)
            TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
            TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
            TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
            TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, 0)
        elseif faction == 5 then
            ChangeSkinByFaction(5)
            ChangeSkinButtonByFaction(5)
            ChangeBackgroundLobby(nil, 5)
            TEST5factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/random_ico-large.dds"))
                LayoutHelpers.AtRightIn(TEST5factionPanel, GUI.factionPanel, -15)
            TEST1factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/aeon_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST1factionPanel, GUI.factionPanel, 0)
            TEST2factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/cybran_ico.dds"))
                LayoutHelpers.AtLeftIn(TEST2factionPanel, GUI.factionPanel, 45)
            TEST3factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/uef_ico.dds"))
            TEST4factionPanel:SetTexture(UIUtil.SkinnableFile("/FACTIONSELECTOR/seraphim_ico.dds"))
                LayoutHelpers.AtRightIn(TEST4factionPanel, GUI.factionPanel, 45)
        end
        end
    end
    
function ChangeSkinByFaction(input_faction)
    local faction = input_faction or Prefs.GetFromCurrentProfile('LastFaction')
    if GUI.panel then
    if faction == 1 then
        GUI.panel:SetTexture(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[uef]power_panel_bmp.dds"))
    elseif faction == 2 then
        GUI.panel:SetTexture(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[aeo]power_panel_bmp.dds"))
    elseif faction == 3 then
        GUI.panel:SetTexture(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[cyb]power_panel_bmp.dds"))
    elseif faction == 4 then
        GUI.panel:SetTexture(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[ser]power_panel_bmp.dds"))
    elseif faction == 5 then
        GUI.panel:SetTexture(UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/[ran]power_panel_bmp.dds"))
    --else
    end
    end
end

--------------------------------------------------
-- New skin 2013                                    --
-- Author : Xinnony                                --
--------------------------------------------------

function ForceApplyNewSkin()
    if not GUI.Credits:IsDisabled() then
        GUI.Credits:SetTexture(UIUtil.UIFile('/BUTTON/small/_up.dds'))
    else
        GUI.Credits:SetTexture(UIUtil.UIFile('/BUTTON/small/_dis.dds'))
    end
    -- Exit button
    if GUI.exitButton:IsDisabled() then
        GUI.exitButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_dis.dds'))
    else
        GUI.exitButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_up.dds'))
    end
    -- StartGame show only if you Host and Enable only if All Player is Ready.
    if lobbyComm:IsHost() then
        if not GUI.launchGameButton:IsDisabled() then--and GetPlayersNotReady() then
            if GetPlayersNotReady() then
                GUI.launchGameButton:SetTexture(UIUtil.UIFile('/BUTTON/large/_dis.dds'))
            else
                GUI.launchGameButton:SetTexture(UIUtil.UIFile('/BUTTON/large/_up.dds'))
            end
        elseif GUI.launchGameButton:IsDisabled() then--and not GetPlayersNotReady() then
            GUI.launchGameButton:SetTexture(UIUtil.UIFile('/BUTTON/large/_dis.dds'))
        end
    end
    -- GameOption show only if you Host, else ModManager is show.
    if lobbyComm:IsHost() then
        if not GUI.gameoptionsButton:IsDisabled() then
            GUI.gameoptionsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_up.dds'))
        elseif GUI.gameoptionsButton:IsDisabled() then
            GUI.gameoptionsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_dis.dds'))
        end
    end
    if not lobbyComm:IsHost() then
        if not GUI.gameoptionsButton:IsDisabled() then
            GUI.gameoptionsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_up.dds'))
        elseif GUI.gameoptionsButton:IsDisabled() then
            GUI.gameoptionsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_dis.dds'))
        end
    end
    -- Restricted Unit show only if not Your Host
    if not lobbyComm:IsHost() then
        if not GUI.restrictedUnitsButton:IsDisabled() then
            GUI.restrictedUnitsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_up.dds'))
        elseif GUI.restrictedUnitsButton:IsDisabled() then
            GUI.restrictedUnitsButton:SetTexture(UIUtil.UIFile('/BUTTON/medium/_dis.dds'))
        end
    end
    -- Observer, AutoTeam, RankedOpts, CPUBench, RandomMap
    if GUI.becomeObserver then
        if not GUI.becomeObserver:IsDisabled() then
            GUI.becomeObserver:SetTexture(UIUtil.UIFile('/BUTTON/observer/_up.dds'))
        elseif GUI.becomeObserver:IsDisabled() then
            GUI.becomeObserver:SetTexture(UIUtil.UIFile('/BUTTON/observer/_dis.dds'))
        end
    end
    if GUI.randTeam then
        if not GUI.randTeam:IsDisabled() then
            GUI.randTeam:SetTexture(UIUtil.UIFile('/BUTTON/autoteam/_up.dds'))
        elseif GUI.randTeam:IsDisabled() then
            GUI.randTeam:SetTexture(UIUtil.UIFile('/BUTTON/autoteam/_dis.dds'))
        end
    end
    if GUI.rankedOptions then
        if not GUI.rankedOptions:IsDisabled() then
            GUI.rankedOptions:SetTexture(UIUtil.UIFile('/BUTTON/defaultoption/_up.dds'))
        elseif GUI.rankedOptions:IsDisabled() then
            GUI.rankedOptions:SetTexture(UIUtil.UIFile('/BUTTON/defaultoption/_dis.dds'))
        end
    end
    if GUI.rerunBenchmark then
        if not GUI.rerunBenchmark:IsDisabled() then
            GUI.rerunBenchmark:SetTexture(UIUtil.UIFile('/BUTTON/cputest/_up.dds'))
        elseif GUI.rerunBenchmark:IsDisabled() then
            GUI.rerunBenchmark:SetTexture(UIUtil.UIFile('/BUTTON/cputest/_dis.dds'))
        end
    end
    if GUI.randMap then
        if not GUI.randMap:IsDisabled() then
            GUI.randMap:SetTexture(UIUtil.UIFile('/BUTTON/randommap/_up.dds'))
        elseif GUI.randMap:IsDisabled() then
            GUI.randMap:SetTexture(UIUtil.UIFile('/BUTTON/randommap/_dis.dds'))
        end
    end
end

function ChangeSkinButtonByFaction(input_faction)
    local faction = input_faction or Prefs.GetFromCurrentProfile('LastFaction')
    if GUI.panel then
    local skins = import('/lua/skins/skins.lua').skins
    
    if faction == 1 then
        skins.uef.texturesPath = "/textures/ui/uef"
        ForceApplyNewSkin()
    
    elseif faction == 2 then
        skins.uef.texturesPath = "/textures/ui/aeon"
        ForceApplyNewSkin()
    
    elseif faction == 3 then
        skins.uef.texturesPath = "/textures/ui/cybran"
        ForceApplyNewSkin()
    
    elseif faction == 4 then
        skins.uef.texturesPath = "/textures/ui/seraphim"
        ForceApplyNewSkin()
    
    elseif faction == 5 then
        skins.uef.texturesPath = "/textures/ui/random"
        ForceApplyNewSkin()
    end
    end
end

function ChangeBackgroundLobby(slot, faction)
    XinnoBackground = Prefs.GetFromCurrentProfile('XinnoBackground') or 'Factions'
    if GUI.background and GUI.background2 then--and FindSlotForID(localPlayerID) == slot then
        if XinnoBackground == 'Factions' then--and LASTBackgroundSelected != BackgroundSelected then
            if XinnonyDebug == 4 then AddChatText(">> Background FACTION") end
            GUI.background:Show()
            GUI.background2:Hide()
            faction = faction or Prefs.GetFromCurrentProfile('LastFaction')
            if faction == 1 then
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_uef_bmp.dds"))
            elseif faction == 2 then
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_aion_bmp.dds"))
            elseif faction == 3 then
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_cybran_bmp.dds"))
            elseif faction == 4 then
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_seraphim_bmp.dds"))
            elseif faction == 5 then
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_random_bmp.dds"))
            else
                GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/faction-background-paint_black_bmp.dds"))
            end
            LASTXinnoBackground = 'Factions'
        
        elseif XinnoBackground == 'ConceptArt' then--and LASTBackgroundSelected != BackgroundSelected then
            if XinnonyDebug == 4 then AddChatText(">> Background ART") end
            GUI.background:Show()
            GUI.background2:Hide()
            GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/art-background-paint0"..math.random(1, 5).."_bmp.dds"))
            LASTXinnoBackground = 'ConceptArt'
            
        elseif XinnoBackground == 'Screenshoot' then--and LASTBackgroundSelected != BackgroundSelected then
            if XinnonyDebug == 4 then AddChatText(">> Background SCREENSHOOT") end
            GUI.background:Show()
            GUI.background2:Hide()
            GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/scrn-background-paint"..math.random(1, 14).."_bmp.dds"))
            LASTXinnoBackground = 'Screenshoot'
        
        elseif XinnoBackground == 'Map' then--and LASTBackgroundSelected != BackgroundSelected then -- LASTBac... is for avoided loop set texture, when you change faction
            if XinnonyDebug == 4 then AddChatText(">> Background MAP") end
            GUI.background:Hide()
            GUI.background2:Show()
            local MapPreview = import('/lua/ui/controls/mappreview.lua').MapPreview
            if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") then
                scenarioInfo = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
            end
            if scenarioInfo and scenarioInfo.map and (scenarioInfo.map != "") then
                if not GUI.background2:SetTexture(scenarioInfo.preview) then
                    GUI.background2:SetTextureFromMap(scenarioInfo.map)
                end
            else
                GUI.background2:ClearTexture()
            end
            LASTXinnoBackground = 'Map'
        
        elseif XinnoBackground == 'No' and LASTXinnoBackground != XinnoBackground then -- LASTBac... is for avoided loop set texture, when you change faction
            if XinnonyDebug == 4 then AddChatText(">> Background NOTHING") end
            GUI.background:Hide()
            GUI.background2:Hide()
            GUI.background:SetTexture(UIUtil.UIFile("/BACKGROUND/background-paint_black_bmp.dds"))
            LASTXinnoBackground = 'No'
        end
    end
end

function CreateOptionLobbyDialog()
    local dialog = Group(GUI)
        LayoutHelpers.AtCenterIn(dialog, GUI)
        dialog.Depth:Set(999) -- :GetTopmostDepth() + 1
    local background = Bitmap(dialog, UIUtil.SkinnableFile('/scx_menu/lan-game-lobby/optionlobby.dds'))
        dialog.Width:Set(background.Width)
        dialog.Height:Set(background.Height)
        LayoutHelpers.FillParent(background, dialog)
    local dialog2 = Group(dialog)
        dialog2.Width:Set(536)
        dialog2.Height:Set(400)
        LayoutHelpers.AtCenterIn(dialog2, dialog)
        
        
    ---------------------------
    -- CheckBox Options --
    cbox_BG_Factions = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_BG_Factions, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_BG_Factions, dialog2, 20)
        cbox_BG_Factions_TEXT = UIUtil.CreateText(cbox_BG_Factions, 'Factions Backgrounds', 14, 'Arial')
            cbox_BG_Factions_TEXT:SetColor('B9BFB9')
            cbox_BG_Factions_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_BG_Factions_TEXT, cbox_BG_Factions, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_BG_Factions_TEXT, cbox_BG_Factions)
            Tooltip.AddButtonTooltip(cbox_BG_Factions_TEXT, {text='Factions Background', body='Show the Factions Backgrounds in the Lobby'})
            cbox_BG_Factions.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackground', 'Factions')
                    cbox_BG_ConceptArt:SetCheck(false, true)
                    cbox_BG_Screenshoot:SetCheck(false, true)
                    cbox_BG_Map:SetCheck(false, true)
                    cbox_BG_No:SetCheck(false, true)
                    ChangeBackgroundLobby(nil, nil)
                else
                    cbox_BG_Factions:SetCheck(true, true)
                end
            end
    cbox_BG_ConceptArt = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_BG_ConceptArt, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_BG_ConceptArt, dialog2, 40)
        cbox_BG_ConceptArt_TEXT = UIUtil.CreateText(cbox_BG_ConceptArt, 'Concept Art Backgrounds', 14, 'Arial')
            cbox_BG_ConceptArt_TEXT:SetColor('B9BFB9')
            cbox_BG_ConceptArt_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_BG_ConceptArt_TEXT, cbox_BG_ConceptArt, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_BG_ConceptArt_TEXT, cbox_BG_ConceptArt)
            Tooltip.AddButtonTooltip(cbox_BG_ConceptArt_TEXT, {text='ConceptArt Background', body='Show the Concept Art Backgrounds in the Lobby'})
            cbox_BG_ConceptArt.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackground', 'ConceptArt')
                    cbox_BG_Factions:SetCheck(false, true)
                    cbox_BG_Screenshoot:SetCheck(false, true)
                    cbox_BG_Map:SetCheck(false, true)
                    cbox_BG_No:SetCheck(false, true)
                    ChangeBackgroundLobby(nil, nil)
                else
                    cbox_BG_ConceptArt:SetCheck(true, true)
                end
            end
    cbox_BG_Screenshoot = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_BG_Screenshoot, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_BG_Screenshoot, dialog2, 60)
        cbox_BG_Screenshoot_TEXT = UIUtil.CreateText(cbox_BG_Screenshoot, 'Screenshot Backgrounds', 14, 'Arial')
            cbox_BG_Screenshoot_TEXT:SetColor('B9BFB9')
            cbox_BG_Screenshoot_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_BG_Screenshoot_TEXT, cbox_BG_Screenshoot, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_BG_Screenshoot_TEXT, cbox_BG_Screenshoot)
            Tooltip.AddButtonTooltip(cbox_BG_Screenshoot_TEXT, {text='Screenshoot Background', body='Show some Screenshot Backgrounds in the Lobby'})
            cbox_BG_Screenshoot.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackground', 'Screenshoot')
                    cbox_BG_Factions:SetCheck(false, true)
                    cbox_BG_ConceptArt:SetCheck(false, true)
                    cbox_BG_Map:SetCheck(false, true)
                    cbox_BG_No:SetCheck(false, true)
                    ChangeBackgroundLobby(nil, nil)
                else
                    cbox_BG_Screenshoot:SetCheck(true, true)
                end
            end
    cbox_BG_Map = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_BG_Map, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_BG_Map, dialog2, 80)
        cbox_BG_Map_TEXT = UIUtil.CreateText(cbox_BG_Map, 'Map Preview', 14, 'Arial')
            cbox_BG_Map_TEXT:SetColor('B9BFB9')
            cbox_BG_Map_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_BG_Map_TEXT, cbox_BG_Map, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_BG_Map_TEXT, cbox_BG_Map)
            Tooltip.AddButtonTooltip(cbox_BG_Map_TEXT, {text='Map Background', body='Show the Map Preview in the Lobby'})
            cbox_BG_Map.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackground', 'Map')
                    cbox_BG_Factions:SetCheck(false, true)
                    cbox_BG_ConceptArt:SetCheck(false, true)
                    cbox_BG_Screenshoot:SetCheck(false, true)
                    cbox_BG_No:SetCheck(false, true)
                    ChangeBackgroundLobby(nil, nil)
                else
                    cbox_BG_Map:SetCheck(true, true)
                end
            end
    cbox_BG_No = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtLeftIn(cbox_BG_No, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_BG_No, dialog2, 100)
        cbox_BG_No_TEXT = UIUtil.CreateText(cbox_BG_No, 'No Background', 14, 'Arial')
            cbox_BG_No_TEXT:SetColor('B9BFB9')
            cbox_BG_No_TEXT:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(cbox_BG_No_TEXT, cbox_BG_No, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_BG_No_TEXT, cbox_BG_No)
            Tooltip.AddButtonTooltip(cbox_BG_No_TEXT, {text='No Background', body='No background in the Lobby'})
            cbox_BG_No.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackground', 'No')
                    cbox_BG_Factions:SetCheck(false, true)
                    cbox_BG_ConceptArt:SetCheck(false, true)
                    cbox_BG_Screenshoot:SetCheck(false, true)
                    cbox_BG_Map:SetCheck(false, true)
                    ChangeBackgroundLobby(nil, nil)
                else
                    cbox_BG_No:SetCheck(true, true)
                end
            end
    --
    cbox_Skin_Dark = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtRightIn(cbox_Skin_Dark, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_Skin_Dark, dialog2, 20)
        cbox_Skin_Dark_TEXT = UIUtil.CreateText(cbox_Skin_Dark, 'Dark Skin', 14, 'Arial')
            cbox_Skin_Dark_TEXT:SetColor('B9BFB9')
            cbox_Skin_Dark_TEXT:SetDropShadow(true)
            LayoutHelpers.AtRightIn(cbox_Skin_Dark_TEXT, cbox_Skin_Dark, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_Skin_Dark_TEXT, cbox_Skin_Dark)
            Tooltip.AddButtonTooltip(cbox_Skin_Dark_TEXT, {text='Dark Skin', body='Apply the Dark Skin in the Lobby'})
            cbox_Skin_Dark.OnCheck = function(self, checked)
                if checked then
                else
                    cbox_Skin_Dark:SetCheck(true, true)
                end
            end
    local cbox6_0 = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtRightIn(cbox6_0, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox6_0, dialog2, 40)
        local cbox6_1 = UIUtil.CreateText(cbox6_0, 'White Skin', 14, 'Arial')
            cbox6_1:SetColor('B9BFB9')
            cbox6_1:SetDropShadow(true)
            LayoutHelpers.AtRightIn(cbox6_1, cbox6_0, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox6_1, cbox6_0)
            Tooltip.AddButtonTooltip(cbox6_1, {text='White Skin', body='White Skin is not available yet'})
            cbox6_0:Disable()
            cbox6_0.OnClick = function(self, checked)
                cbox6_0:SetCheck(false, true)
            end
    --
    local cbox_StretchBG = UIUtil.CreateCheckboxStd(dialog2, '/CHECKBOX/radio')
        LayoutHelpers.AtRightIn(cbox_StretchBG, dialog2, 20)
        LayoutHelpers.AtTopIn(cbox_StretchBG, dialog2, 80)
        local cbox_StretchBG_TEXT = UIUtil.CreateText(cbox_StretchBG, 'Stretch Background', 14, 'Arial')
            cbox_StretchBG_TEXT:SetColor('B9BFB9')
            cbox_StretchBG_TEXT:SetDropShadow(true)
            LayoutHelpers.AtRightIn(cbox_StretchBG_TEXT, cbox_StretchBG, 25)
            LayoutHelpers.AtVerticalCenterIn(cbox_StretchBG_TEXT, cbox_StretchBG)
            Tooltip.AddButtonTooltip(cbox_StretchBG_TEXT, {text='Stretch Background', body='...'})
            cbox_StretchBG.OnCheck = function(self, checked)
                if checked then
                    Prefs.SetToCurrentProfile('XinnoBackgroundStretch', 'true')
                    LayoutHelpers.FillParent(GUI.background, GUI)
                    LayoutHelpers.FillParent(GUI.background2, GUI)
                else
                    Prefs.SetToCurrentProfile('XinnoBackgroundStretch', 'false')
                    LayoutHelpers.FillParentPreserveAspectRatio(GUI.background, GUI)
                    LayoutHelpers.FillParentPreserveAspectRatio(GUI.background2, GUI)
                end
            end
    --------------------
    -- Warning text --
    local text9 = UIUtil.CreateText(dialog2, "If you have a problem with the new Lobby Skin, I can't help you without Screen and Log !", 10, 'Arial')
        text9:SetColor('B9BFB9')
        text9:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(text9, dialog2, 20)
        LayoutHelpers.AtBottomIn(text9, dialog2, 220)
        local text10 = UIUtil.CreateText(dialog2, "And your silence will not solve anything :)", 10, 'Arial')
            text10:SetColor('B9BFB9')
            text10:SetDropShadow(true)
            LayoutHelpers.AtLeftIn(text10, dialog2, 20)
            LayoutHelpers.AtBottomIn(text10, dialog2, 205)
    ----------------------
    -- Devlopper box --
    local text0 = UIUtil.CreateText(dialog2, 'Lobby Developpers :', 17, 'Arial')
        text0:SetColor('B9BFB9')
        text0:SetDropShadow(true)
        LayoutHelpers.AtLeftIn(text0, dialog2, 20)
        LayoutHelpers.AtBottomIn(text0, dialog2, 130)
        -- Ask to Xinnony for add your name and work correctly
    local text = {}
    local ttext = {'- Xinnony : New Skin (with Barlots), Faction Selector, Country Flag, Move Player to,',
                        'Color State in Nickname, Custom Title, Sort option, Game is/not Ranked label, bugs fixing.',
                        '- Vicarian : Contribute with Xinnony, Rating Observer, bugs fixing.',
                        '- Duck_42 : CPU Bench, Ping Nuke.',
                        '- Moritz : Power Lobby 2.0.',}
    for i, v in ttext do
        text[i] = UIUtil.CreateText(dialog2, v, 10, 'Arial')
        text[i]:SetColor('B9BFB9')
        text[i]:SetDropShadow(true)
        if i == 2 then
            LayoutHelpers.AtLeftIn(text[2], dialog2, 40) -- Manual set the SubLine position
            LayoutHelpers.AtBottomIn(text[2], dialog2, 95)
        else
            LayoutHelpers.AtLeftIn(text[i], dialog2, 20)
            LayoutHelpers.AtBottomIn(text[i], dialog2, 120-(15*i))
        end
    end
    ------------------
    -- Quit button --
    local QuitButton = UIUtil.CreateButtonStd2(dialog2, '/BUTTON/medium/', "Thank You !", 12, -1)
        LayoutHelpers.AtHorizontalCenterIn(QuitButton, dialog2, 0)
        LayoutHelpers.AtBottomIn(QuitButton, dialog2, 10)
        QuitButton.OnClick = function(self)
            dialog:Destroy()
            dialog2:Destroy()
        end
    --------------------------------------
    -- Apply the State in Checkbox --
    local XinnoBackground = Prefs.GetFromCurrentProfile('XinnoBackground') or 'Factions'
    if XinnoBackground == 'Factions' then
        cbox_BG_Factions:SetCheck(true, true)
        cbox_BG_ConceptArt:SetCheck(false, true)
        cbox_BG_Screenshoot:SetCheck(false, true)
        cbox_BG_Map:SetCheck(false, true)
        cbox_BG_No:SetCheck(false, true)
    elseif XinnoBackground == 'ConceptArt' then
        cbox_BG_Factions:SetCheck(false, true)
        cbox_BG_ConceptArt:SetCheck(true, true)
        cbox_BG_Screenshoot:SetCheck(false, true)
        cbox_BG_Map:SetCheck(false, true)
        cbox_BG_No:SetCheck(false, true)
    elseif XinnoBackground == 'Screenshoot' then
        cbox_BG_Factions:SetCheck(false, true)
        cbox_BG_ConceptArt:SetCheck(false, true)
        cbox_BG_Screenshoot:SetCheck(true, true)
        cbox_BG_Map:SetCheck(false, true)
        cbox_BG_No:SetCheck(false, true)
    elseif XinnoBackground == 'Map' then
        cbox_BG_Factions:SetCheck(false, true)
        cbox_BG_ConceptArt:SetCheck(false, true)
        cbox_BG_Screenshoot:SetCheck(false, true)
        cbox_BG_Map:SetCheck(true, true)
        cbox_BG_No:SetCheck(false, true)
    elseif XinnoBackground == 'No' then
        cbox_BG_Factions:SetCheck(false, true)
        cbox_BG_ConceptArt:SetCheck(false, true)
        cbox_BG_Screenshoot:SetCheck(false, true)
        cbox_BG_Map:SetCheck(false, true)
        cbox_BG_No:SetCheck(true, true)
    end
    --
    local XinnoSkin = Prefs.GetFromCurrentProfile('XinnoSkin') or 'Dark'
    if XinnoSkin == 'Dark' then
        cbox_Skin_Dark:SetCheck(true, true)
    else
        cbox_Skin_Dark:SetCheck(false, true)
    end
    --
    local XinnoBackgroundStretch = Prefs.GetFromCurrentProfile('XinnoBackgroundStretch') or 'true'
    if XinnoBackgroundStretch == 'true' then
        cbox_StretchBG:SetCheck(true, true)
    else
        cbox_StretchBG:SetCheck(false, true)
    end
end

##########################################################################
#####################################.#####################################

function Remove_Unchanged_Options()
    --table.find(formattedOptions, VAL) -- Table, Val
    --table.remove()
end

SetText2 = function(self, text, delay)
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