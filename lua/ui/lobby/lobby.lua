--*****************************************************************************
--* File: lua/modules/ui/lobby/lobby.lua
--* Author: Chris Blackwell
--* Summary: Game selection UI
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
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
local teamIcons = {'/lobby/team_icons/team_no_icon.dds',
    '/lobby/team_icons/team_1_icon.dds',
    '/lobby/team_icons/team_2_icon.dds',
    '/lobby/team_icons/team_3_icon.dds',
    '/lobby/team_icons/team_4_icon.dds',
	'/lobby/team_icons/team_5_icon.dds',
	'/lobby/team_icons/team_6_icon.dds'}

local connectedTo = {}	
	
local availableMods = {} # map from peer ID to set of available mods; each set is a map from "mod id"->true
local selectedMods = nil

local commandQueueIndex = 0
local commandQueue = {}

local launchThread = false
local quickRandMap = false

local lastUploadedMap = nil

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
    local delimStart = string.find(params, ":")
    if delimStart then
        local name = string.sub(params, 1, delimStart-1)
        local targID = FindIDForName(name)
        if targID then
            PrivateChat(targID, string.sub(params, delimStart+1))
        else
            AddChatText(LOC("<LOC lobby_0007>Invalid whisper target."))
        end
    else
        AddChatText(LOC("<LOC lobby_0008>You must have a colon (:) after the whisper target's name."))
    end
end

local commands = {
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


local slotMenuStrings = {
	open = "<LOC lobui_0219>Open",
	close = "<LOC lobui_0220>Close",
	closed = "<LOC lobui_0221>Closed",
	occupy = "<LOC lobui_0222>Occupy",
	pm = "<LOC lobui_0223>Private Message",
	remove_to_kik = "Remove Player",
	remove_to_observer = "Move Player to Observer",
	move_slot_to_slot1 = "Move Player to slot 1",
	move_slot_to_slot2 = "Move Player to slot 2",
	move_slot_to_slot3 = "Move Player to slot 3",
	move_slot_to_slot4 = "Move Player to slot 4",
	move_slot_to_slot5 = "Move Player to slot 5",
	move_slot_to_slot6 = "Move Player to slot 6",
	move_slot_to_slot7 = "Move Player to slot 7",
	move_slot_to_slot8 = "Move Player to slot 8",
	move_slot_to_slot9 = "Move Player to slot 9",
	move_slot_to_slot10 = "Move Player to slot 10",
	move_slot_to_slot11 = "Move Player to slot 11",
	move_slot_to_slot12 = "Move Player to slot 12",
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
			'move_slot_to_slot1',
			'move_slot_to_slot2',
			'move_slot_to_slot3',
			'move_slot_to_slot4',
			'move_slot_to_slot5',
			'move_slot_to_slot6',
			'move_slot_to_slot7',
			'move_slot_to_slot8',
			'move_slot_to_slot9',
			'move_slot_to_slot10',
			'move_slot_to_slot11',
			'move_slot_to_slot12',
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
                lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID), RequestedSlot =  slot})
            end
        elseif IsObserver(localPlayerID) then
            if lobbyComm:IsHost() then
				requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
				requestedPL = playerRating
				requestedRC = ratingColor
				requestedNG = numGames
                HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID), slot, requestedFaction, requestedPL, requestedRC, requestedNG)
            else
                lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName, ObserverSlot = FindObserverSlotForID(localPlayerID), PlayerSlot = slot, requestedFaction = Prefs.GetFromCurrentProfile('LastFaction'), requestedPL = playerRating, requestedRC = ratingColor, requestedNG = numGames})
            end
        end
    elseif key == 'pm' then
        if gameInfo.PlayerOptions[slot].Human then
            GUI.chatEdit:SetText(string.format("/whisper %s:", gameInfo.PlayerOptions[slot].PlayerName))
        end
--// Move player slot to slot -- Xinnony
	elseif key == 'move_slot_to_slot1' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[1].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[1].PlayerName
				LAST_id = gameInfo.PlayerOptions[1].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[1].Faction
				LAST_numgame = gameInfo.PlayerOptions[1].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[1].OwnerID, gameInfo.PlayerOptions[1].PlayerName, 1) -- move slot 1 to observer
				ClearSlotInfo(1)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 1) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 1)
			end
		end
	elseif key == 'move_slot_to_slot2' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[2].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[2].PlayerName
				LAST_id = gameInfo.PlayerOptions[2].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[2].Faction
				LAST_numgame = gameInfo.PlayerOptions[2].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[2].OwnerID, gameInfo.PlayerOptions[2].PlayerName, 2) -- move slot 1 to observer
				ClearSlotInfo(2)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 2) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 2)
			end
		end
	elseif key == 'move_slot_to_slot3' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[3].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[3].PlayerName
				LAST_id = gameInfo.PlayerOptions[3].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[3].Faction
				LAST_numgame = gameInfo.PlayerOptions[3].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[3].OwnerID, gameInfo.PlayerOptions[3].PlayerName, 3) -- move slot 1 to observer
				ClearSlotInfo(3)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 3) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 3)
			end
		end
	elseif key == 'move_slot_to_slot4' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[4].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[4].PlayerName
				LAST_id = gameInfo.PlayerOptions[4].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[4].Faction
				LAST_numgame = gameInfo.PlayerOptions[4].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[4].OwnerID, gameInfo.PlayerOptions[4].PlayerName, 4) -- move slot 1 to observer
				ClearSlotInfo(4)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 4) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 4)
			end
		end
	elseif key == 'move_slot_to_slot5' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[5].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[5].PlayerName
				LAST_id = gameInfo.PlayerOptions[5].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[5].Faction
				LAST_numgame = gameInfo.PlayerOptions[5].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[5].OwnerID, gameInfo.PlayerOptions[5].PlayerName, 5) -- move slot 1 to observer
				ClearSlotInfo(5)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 5) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 5)
			end
		end
	elseif key == 'move_slot_to_slot6' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[6].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[6].PlayerName
				LAST_id = gameInfo.PlayerOptions[6].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[6].Faction
				LAST_numgame = gameInfo.PlayerOptions[6].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[6].OwnerID, gameInfo.PlayerOptions[6].PlayerName, 6) -- move slot 1 to observer
				ClearSlotInfo(6)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 6) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 6)
			end
		end
	elseif key == 'move_slot_to_slot7' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[7].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[7].PlayerName
				LAST_id = gameInfo.PlayerOptions[7].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[7].Faction
				LAST_numgame = gameInfo.PlayerOptions[7].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[7].OwnerID, gameInfo.PlayerOptions[7].PlayerName, 7) -- move slot 1 to observer
				ClearSlotInfo(7)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 7) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 7)
			end
		end
	elseif key == 'move_slot_to_slot8' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[8].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[8].PlayerName
				LAST_id = gameInfo.PlayerOptions[8].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[8].Faction
				LAST_numgame = gameInfo.PlayerOptions[8].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[8].OwnerID, gameInfo.PlayerOptions[8].PlayerName, 8) -- move slot 1 to observer
				ClearSlotInfo(8)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 8) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 8)
			end
		end
	elseif key == 'move_slot_to_slot9' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[9].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[9].PlayerName
				LAST_id = gameInfo.PlayerOptions[9].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[9].Faction
				LAST_numgame = gameInfo.PlayerOptions[9].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[9].OwnerID, gameInfo.PlayerOptions[9].PlayerName, 9) -- move slot 1 to observer
				ClearSlotInfo(9)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 9) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 9)
			end
		end
	elseif key == 'move_slot_to_slot10' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[10].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[10].PlayerName
				LAST_id = gameInfo.PlayerOptions[10].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[10].Faction
				LAST_numgame = gameInfo.PlayerOptions[10].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[10].OwnerID, gameInfo.PlayerOptions[10].PlayerName, 10) -- move slot 1 to observer
				ClearSlotInfo(10)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 10) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 10)
			end
		end
	elseif key == 'move_slot_to_slot11' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[11].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[11].PlayerName
				LAST_id = gameInfo.PlayerOptions[11].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[11].Faction
				LAST_numgame = gameInfo.PlayerOptions[11].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[11].OwnerID, gameInfo.PlayerOptions[11].PlayerName, 11) -- move slot 1 to observer
				ClearSlotInfo(11)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 11) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 11)
			end
		end
	elseif key == 'move_slot_to_slot12' then
		if gameInfo.PlayerOptions[slot].Human then
			if gameInfo.PlayerOptions[12].Human then -- If destination slot player exist
				LAST_name = gameInfo.PlayerOptions[12].PlayerName
				LAST_id = gameInfo.PlayerOptions[12].OwnerID
				tmpLAST_rating_color = GetCommandLineArg("/ratingcolor", 1)
				LAST_rating_color = tostring(tmpLAST_rating_color[1])
				tmpLAST_mean = GetCommandLineArg("/mean", 1)
				LAST_mean = tonumber(tmpLAST_mean[1])
				tmpLAST_deviation = GetCommandLineArg("/deviation", 1)
				LAST_deviation = tonumber(tmpLAST_deviation[1])
				LAST_rating = math.floor(LAST_mean - 3 * LAST_deviation)
                LAST_faction = gameInfo.PlayerOptions[12].Faction
				LAST_numgame = gameInfo.PlayerOptions[12].NG
				--***
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[12].OwnerID, gameInfo.PlayerOptions[12].PlayerName, 12) -- move slot 1 to observer
				ClearSlotInfo(12)
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 12) -- move select slot to slot 1
				ClearSlotInfo(slot)
                HostConvertObserverToPlayer(LAST_id, LAST_name, FindObserverSlotForID(LAST_id), slot, LAST_faction, LAST_rating, LAST_rating_color, LAST_numgame)
			else -- destination slot is empty
				HostTryMovePlayer(gameInfo.PlayerOptions[slot].OwnerID, slot, 12)
			end
		end
--\\ Stop Move player slot to slot
--// Move Player slot to Observer -- Xinnony
    elseif key == 'remove_to_observer' then
		if gameInfo.PlayerOptions[slot].Human then
            --UIUtil.QuickDialog(GUI, "<LOC lobui_0166>Are you sure?",
				--"Move", function()
				HostConvertPlayerToObserver(gameInfo.PlayerOptions[slot].OwnerID, gameInfo.PlayerOptions[slot].PlayerName, slot)
				--end,
                --"<LOC _Cancel>", nil, 
                --nil, nil, 
                --true,
                --{worldCover = false, enterButton = 1, escapeButton = 2})
        end
--\\ Stop Move Player slot to Observer
	elseif key == 'remove_to_kik' then
        if gameInfo.PlayerOptions[slot].Human then
            UIUtil.QuickDialog(GUI, "<LOC lobui_0166>Are you sure?",
                "<LOC lobui_0167>Kick Player", function() lobbyComm:EjectPeer(gameInfo.PlayerOptions[slot].OwnerID, "KickedByHost") end,
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
end

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
function CreateLobby(protocol, localPort, desiredPlayerName, localPlayerUID, natTraversalProvider, over, exitBehavior, playerHasSupcom)
    
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
    lobbyComm:ConnectToPeer(addressAndPort,name,uid)
end

function DisconnectFromPeer(uid)
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
    GUI.slots[slot].ratingText:SetText(playerInfo.PL or "")
	GUI.slots[slot].ratingText:SetColor(playerInfo.RC or "ffffffff")
	
	GUI.slots[slot].numGamesGroup:Show()
    GUI.slots[slot].numGamesText:SetText(playerInfo.NG or "")
	
    GUI.slots[slot].name:Show()
    GUI.slots[slot].name:SetTitleText(LOC(playerInfo.PlayerName))

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
            GUI.slots[slot].pingGroup:Show()
        end
    end

    if isLocallyOwned and playerInfo.Human then
		Prefs.SetToCurrentProfile('LastColor', playerInfo.PlayerColor)
        Prefs.SetToCurrentProfile('LastFaction', playerInfo.Faction)
    end
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
    else
        GUI.slots[slot].name:SetTitleTextColor(UIUtil.fontColor)
    end
    if lobbyComm:IsHost() and (stateKey == 'open' or stateKey == 'ai') then
        Tooltip.AddComboTooltip(GUI.slots[slot].name, GetAITooltipList())
    else
        Tooltip.RemoveComboTooltip(GUI.slots[slot].name)
    end

    -- hide these to clear slot of visible data
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
            AddChatText(LOC("<LOC lobui_0241>There must be more than one player or team or the Victory Condition must be set to Sandbox. "))
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
				UIUtil.QuickDialog(GUI, "<LOC lobui_0521>There are players for a team game and allow observers is enabled.  Do you still wish to launch?",
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
			if totalPlayers > 3 and not stillAllowLockedTeams and totalPlayers != n and gameInfo.GameOptions['AutoTeams'] == 'none' then
				UIUtil.QuickDialog(GUI, "<LOC lobui_0526>There are players for a team game and teams are locked.  Do you still wish to launch?",
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
                UIUtil.QuickDialog(GUI, "<LOC lobui_0278>There are players who are not assigned slots and observers are not allowed.  Launching will cause them to be ejected.  Do you still wish to launch?",
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

    if singlePlayer or HasCommandLineArg('/gpgnet') then
        LaunchGame()
    else
        launchThread = ForkThread(function()
            GUI.launchGameButton.label:SetText(LOC("<LOC PROFILE_0005>"))
            GUI.launchGameButton.OnClick = function(self)
                CancelLaunch()
                self.OnClick = function(self) TryLaunch(false) end
                GUI.launchGameButton.label:SetText(LOC("<LOC lobui_0212>Launch"))
            end
			if gameInfo.GameOptions['RandomMap'] != 'Off' then
				local rMapSizeFil = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFil
				local rMapSizeFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFilLim
				local rMapPlayersFil = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFil
				local rMapPlayersFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFilLim
				SendSystemMessage("-------------------------------------------------------------------------------------------------------------------")
				if rMapSizeFilLim == 'equal' then
					rMapSizeFilLim = '='
				end
				if rMapSizeFilLim == 'less' then
					rMapSizeFilLim = '<='
				end
				if rMapSizeFilLim == 'greater' then
					rMapSizeFilLim = '>='
				end
				if rMapPlayersFilLim == 'equal' then
					rMapPlayersFilLim = '='
				end
				if rMapPlayersFilLim == 'less' then
					rMapPlayersFilLim = '<='
				end
				if rMapPlayersFilLim == 'greater' then
					rMapPlayersFilLim = '>='
				end
				if rMapSizeFil != 0 and rMapPlayersFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0558>Random Map enabled: Map Size is %s %dkm and Number of Players are %s %d", rMapSizeFilLim, rMapSizeFil, rMapPlayersFilLim, rMapPlayersFil))
				elseif rMapSizeFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0559>Random Map enabled: Map Size is %s %dkm and Number of Players are ALL", rMapSizeFilLim, rMapSizeFil))
				elseif rMapPlayersFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0560>Random Map enabled: Map Size is ALL and Number of Players are %s %d", rMapPlayersFilLim, rMapPlayersFil))
				else
					SendSystemMessage(LOC("<LOC lobui_0561>Random Map enabled: Map Size is ALL and Number of Players are ALL"))
				end
				SendSystemMessage("-------------------------------------------------------------------------------------------------------------------")			
			end
            local timer = 5
            while timer > 0 do
                local text = LOCF('%s %d', "<LOC lobby_0001>Game will launch in", timer)
                SendSystemMessage(text)
                timer = timer - 1
                WaitSeconds(1)
            end			
            LaunchGame()
        end)
    end
end

function CancelLaunch()
    if launchThread then 
        KillThread(launchThread)
        launchThread = false
        GUI.launchGameButton.label:SetText(LOC("<LOC lobui_0212>Launch"))
        GUI.launchGameButton.OnClick = function(self)
            TryLaunch(false)
        end
        if GetPlayersNotReady() then
            local msg = LOCF('<LOC lobui_0308>Launch sequence has been aborted by %s.', GetPlayersNotReady()[1])
            SendSystemMessage(msg)
        else
            SendSystemMessage(LOC('<LOC lobui_0309>Host has cancelled the launch sequence.'))
        end
    end
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
        if gameInfo.PlayerOptions[playerSlot] and gameInfo.PlayerOptions[playerSlot].Faction != 4 and not IsObserver(localPlayerID) then
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
        GUI.changeMapButton:Show()
		GUI.launchGameButton:Show()
		
        if GUI.allowObservers then
            GUI.allowObservers:Show()
        end
		if not singlePlayer then
			if quickRandMap then				
				GUI.randMap:Enable()
			else
				GUI.randMap:Disable()
			end
		end
    else
        GUI.changeMapButton.label:SetText(LOC('<LOC tooltipui0145>'))
        GUI.changeMapButton.OnClick = function(self, modifiers)
            modstatus = ModManager.ClientModStatus(gameInfo.GameMods)
            ModManager.CreateDialog(GUI, true, OnModsChanged, true, modstatus)
        end
        Tooltip.AddButtonTooltip(GUI.changeMapButton, 'Lobby_Mods')
        GUI.launchGameButton:Hide()
        if GUI.allowObservers then
            GUI.allowObservers:Show()
			GUI.allowObservers:Disable()
        end
		if gameInfo.GameOptions.AllowObservers then
			GUI.allowObservers:SetCheck(true)
		else
			GUI.allowObservers:SetCheck(false)
		end		
    end
	
    if GUI.becomeObserver then
        if IsObserver(localPlayerID) then
			GUI.becomeObserver:Hide()
            GUI.becomeObserver:Disable()
        else
            GUI.becomeObserver:Show()
            GUI.becomeObserver:Enable()
        end
    end
	
    local localPlayerSlot = FindSlotForID(localPlayerID)
    if localPlayerSlot then
        if gameInfo.PlayerOptions[localPlayerSlot].Ready then
            GUI.becomeObserver:Disable()
			GUI.LargeMapPreview:Disable()
        else
			GUI.LargeMapPreview:Enable()
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


	if scenarioInfo and scenarioInfo.map and (scenarioInfo.map != "") then
	
		if not GUI.mapView:SetTexture(scenarioInfo.preview) then
			GUI.mapView:SetTextureFromMap(scenarioInfo.map)
		end
		--GUI.mapName:SetText(LOC(scenarioInfo.name)) -- Add mapname above option lobby (replace with Ranked Label)
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
				GUI.allowObservers:Disable()
                GUI.changeMapButton:Disable()
				GUI.rankedOptions:Disable()
                GUI.becomeObserver:Disable()
				GUI.randMap:Disable()
				GUI.randTeam:Disable()
                GUI.launchGameButton:Enable()				
            else
				GUI.allowObservers:Enable()
                GUI.changeMapButton:Enable()
				GUI.rankedOptions:Enable()
                GUI.becomeObserver:Enable()
				GUI.randTeam:Enable()              
                if launchThread then CancelLaunch() end
                
                GUI.launchGameButton:Disable()
            end
			
			if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") and 2 < 1 then -- 2 < 1 is to disable the button
				if scenarioInfo and scenarioInfo.map and scenarioInfo.map != '' then
					if (lastUploadedMap != gameInfo.GameOptions.ScenarioFile) then
						GUI.uploadMapButton:Show()
					else
						GUI.uploadMapButton:Hide()
					end
				else
					GUI.uploadMapButton:Hide()
				end
			else
				GUI.uploadMapButton:Hide()
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
	
	

	if gameInfo.GameOptions['TeamSpawn'] != 'random' and math.mod(numPlayers,2) == 0 and gameInfo.GameOptions['AutoTeams'] != 'manual' and gameInfo.GameOptions['AutoTeams'] != 'none' then
		
		local teams = nil
		local teamcreated = false
		correct = true
	
		for i = 1, LobbyComm.maxPlayerSlots do
			if gameInfo.PlayerOptions[i] then
			
				if  gameInfo.PlayerOptions[i].Human then
					if gameInfo.PlayerOptions[i].MEAN and gameInfo.PlayerOptions[i].DEV then
						player = Player.create(gameInfo.PlayerOptions[i].PlayerName, Rating.create(gameInfo.PlayerOptions[i].MEAN, gameInfo.PlayerOptions[i].DEV))
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
				--local randmapText = UIUtil.CreateText(GUI.panel, "current game quality : " .. quality .. " %", 17, UIUtil.titleFont)
				if scenarioInfo.map_version then
					randmapText:SetText(scenarioInfo.name.." [v."..scenarioInfo.map_version.."] (Game quality : "..quality.."%)") -- Set the map name and quality at the top right corner in lobby -- Xinnony
				else
					randmapText:SetText(scenarioInfo.name.." (Game quality : "..quality.."%)") -- Set the map name and quality at the top right corner in lobby -- Xinnony
				end
				--LayoutHelpers.AtRightTopIn(randmapText, GUI.panel, 50, 41)
			else
				if scenarioInfo.map_version then
					randmapText:SetText(scenarioInfo.name.." [v."..scenarioInfo.map_version.."] (Game quality : N/A)") -- Set the map name and quality at the top right corner in lobby -- Xinnony
				else
					randmapText:SetText(scenarioInfo.name.." (Game quality : N/A)") -- Set the map name and quality at the top right corner in lobby -- Xinnony
				end
			end
		else
			if scenarioInfo.map_version then
				randmapText:SetText(scenarioInfo.name.." [v."..scenarioInfo.map_version.."]") -- Set the map name and quality at the top right corner in lobby -- Xinnony
			else
				randmapText:SetText(scenarioInfo.name) -- Set the map name and quality at the top right corner in lobby -- Xinnony
			end
		end
	else
		if scenarioInfo.map_version then
			randmapText:SetText(scenarioInfo.name.." [v."..scenarioInfo.map_version.."]") -- Set the map name and quality at the top right corner in lobby -- Xinnony
		else
			randmapText:SetText(scenarioInfo.name) -- Set the map name and quality at the top right corner in lobby -- Xinnony
		end
	end
end

-- Update our local gameInfo.GameMods from selected map name and selected mods, then
-- notify other clients about the change.
local function HostUpdateMods(newPlayerID)
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
				reason = (LOCF('<LOC lobui_0588>You were automaticly removed from the lobby because you don\'t have the following mod:\n%s \nPlease, install the mod before you join the game lobby', modnames))				
			else
				reason = (LOCF('<LOC lobui_0589>You were automaticly removed from the lobby because you don\'t have the following mods:\n%s \nPlease, install the mods before you join the game lobby', modnames))
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
function HostTryAddPlayer( senderID, slot, requestedPlayerName, human, aiPersonality, requestedColor, requestedFaction, requestedTeam, requestedPL, requestedRC, requestedNG, requestedMEAN, requestedDEV )	

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
        gameInfo.PlayerOptions[newSlot].Faction = requestedFaction or gameInfo.PlayerOptions[newSlot].Faction -- already assigned a default, but use requested if avail
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
    gameInfo.PlayerOptions[newSlot].PlayerColor = nil   -- clear out player color first so default color isn't blocked from color free list
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

function HostConvertObserverToPlayer(senderID, name, fromObserverSlot, toPlayerSlot, requestedFaction, requestedPL, requestedRC, requestedNG)
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
            gameInfo.PlayerOptions[toPlayerSlot].PlayerColor = colorIndex
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

function uploadNewMap()
	if gameInfo.GameOptions.ScenarioFile and (gameInfo.GameOptions.ScenarioFile != "") then
		lastUploadedMap = gameInfo.GameOptions.ScenarioFile		
		local scenarioInfo = import('/lua/ui/maputil.lua').LoadScenario(gameInfo.GameOptions.ScenarioFile)				
		#LOG("scbserverhostuploadmap"..gameInfo.GameOptions.ScenarioFile)
		#GpgNetSend("uploadmap", string.format("%s", gameInfo.GameOptions.ScenarioFile))
		#SendSystemMessage(LOCF("<LOC lobui_0735>The host is uploading the map %s to server.", scenarioInfo.name))		
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
    local Combo = import('/lua/ui/controls/combo.lua').Combo
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
    local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
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
        GUI.background = MenuCommon.SetupBackground(GetFrame(0))
    elseif singlePlayer then
        title = "<LOC _Skirmish_Setup>"
    else
        title = "<LOC _LAN_Game_Lobby>"
    end

    ---------------------------------------------------------------------------
    -- Set up main control panels
    ---------------------------------------------------------------------------
    if singlePlayer then
        GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/power_panel-skirmish_bmp.dds"))
    else
        GUI.panel = Bitmap(GUI, UIUtil.SkinnableFile("/scx_menu/lan-game-lobby/power_panel_bmp.dds"))
    end
    LayoutHelpers.AtCenterIn(GUI.panel, GUI)
    GUI.panel.brackets = UIUtil.CreateDialogBrackets(GUI.panel, 18, 17, 18, 15)

    local titleText = UIUtil.CreateText(GUI.panel, title, 26, UIUtil.titleFont)
    LayoutHelpers.AtLeftTopIn(titleText, GUI.panel, 50, 36)
	
	randmapText = UIUtil.CreateText(GUI.panel, "", 17, UIUtil.titleFont)
	LayoutHelpers.AtRightTopIn(randmapText, GUI.panel, 50, 41)
	
	--// Credits -- Xinnony
	local Credits = "New functions added by Xinnony | Power Lobby 2.0 by Moritz"
	--***********************
	Credits_Shadows1 = UIUtil.CreateText(GUI.panel, Credits, 17, UIUtil.titleFont)
    Credits_Shadows1:SetFont(UIUtil.titleFont, 12)
    Credits_Shadows1:SetColor("000000")
	LayoutHelpers.AtBottomIn(Credits_Shadows1, GUI.panel, 1)
	LayoutHelpers.AtRightIn(Credits_Shadows1, GUI.panel, 99)
	Credits_Shadows2 = UIUtil.CreateText(GUI.panel, Credits, 17, UIUtil.titleFont)
    Credits_Shadows2:SetFont(UIUtil.titleFont, 12)
    Credits_Shadows2:SetColor("000000")
	LayoutHelpers.AtBottomIn(Credits_Shadows2, GUI.panel, -1)
	LayoutHelpers.AtRightIn(Credits_Shadows2, GUI.panel, 101)
	Credits_Shadows3 = UIUtil.CreateText(GUI.panel, Credits, 17, UIUtil.titleFont)
    Credits_Shadows3:SetFont(UIUtil.titleFont, 12)
    Credits_Shadows3:SetColor("000000")
	LayoutHelpers.AtBottomIn(Credits_Shadows3, GUI.panel, -1)
	LayoutHelpers.AtRightIn(Credits_Shadows3, GUI.panel, 99)
	Credits_Shadows4 = UIUtil.CreateText(GUI.panel, Credits, 17, UIUtil.titleFont)
    Credits_Shadows4:SetFont(UIUtil.titleFont, 12)
    Credits_Shadows4:SetColor("000000")
	LayoutHelpers.AtBottomIn(Credits_Shadows4, GUI.panel, 1)
	LayoutHelpers.AtRightIn(Credits_Shadows4, GUI.panel, 101)
	Credits_Text = UIUtil.CreateText(GUI.panel, Credits, 17, UIUtil.titleFont)
    Credits_Text:SetFont(UIUtil.titleFont, 12)
    Credits_Text:SetColor("FFFFFF")
	LayoutHelpers.AtBottomIn(Credits_Text, GUI.panel, 0)
	LayoutHelpers.AtRightIn(Credits_Text, GUI.panel, 100)
	--\\ Stop Credits

    GUI.playerPanel = Group(GUI.panel, "playerPanel")
    LayoutHelpers.AtLeftTopIn(GUI.playerPanel, GUI.panel, 40, 66)
    GUI.playerPanel.Width:Set(706)
    GUI.playerPanel.Height:Set(307)

    GUI.observerPanel = Group(GUI.panel, "observerPanel")
    LayoutHelpers.AtLeftTopIn(GUI.observerPanel, GUI.panel, 40, 378)
    GUI.observerPanel.Width:Set(706)
    GUI.observerPanel.Height:Set(114)

    GUI.chatPanel = Group(GUI.panel, "chatPanel")
    LayoutHelpers.AtLeftTopIn(GUI.chatPanel, GUI.panel, 40, 521)
    GUI.chatPanel.Width:Set(705)
    GUI.chatPanel.Height:Set(150)

    GUI.mapPanel = Group(GUI.panel, "mapPanel")
    LayoutHelpers.AtLeftTopIn(GUI.mapPanel, GUI.panel, 750, 68)
    GUI.mapPanel.Width:Set(238)
    GUI.mapPanel.Height:Set(600)

    GUI.optionsPanel = Group(GUI.panel, "optionsPanel")
    LayoutHelpers.AtLeftTopIn(GUI.optionsPanel, GUI.panel, 746, 600)
    GUI.optionsPanel.Width:Set(238)
    GUI.optionsPanel.Height:Set(260)

    GUI.launchPanel = Group(GUI.panel, "controlGroup")
    LayoutHelpers.AtLeftTopIn(GUI.launchPanel, GUI.panel, 735, 668)
    GUI.launchPanel.Width:Set(238)
    GUI.launchPanel.Height:Set(66)

    ---------------------------------------------------------------------------
    -- set up map panel
    ---------------------------------------------------------------------------
    local mapOverlay = Bitmap(GUI.mapPanel, UIUtil.SkinnableFile("/lobby/lan-game-lobby/map-pane-border_bmp.dds"))
    LayoutHelpers.AtLeftTopIn(mapOverlay, GUI.panel, 750, 74)
    mapOverlay:DisableHitTest()

    GUI.mapView = MapPreview(GUI.mapPanel)
	LayoutHelpers.AtCenterIn(GUI.mapView, mapOverlay)
	GUI.mapView.Width:Set(195)
	GUI.mapView.Height:Set(195)

    mapOverlay.Depth:Set(function() return GUI.mapView.Depth() + 10 end)
	
	--if lobbyComm:IsHost() then
		--start of close slots code by Moritz	
		GUI.LargeMapPreview = UIUtil.CreateButtonStd(GUI.observerPanel, '/lobby/lan-game-lobby/toggle', "<LOC lobui_0617>Large Preview", 10, 0)
		LayoutHelpers.CenteredBelow(GUI.LargeMapPreview, GUI.mapView, 6)
		
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
	--end

    GUI.mapName = UIUtil.CreateText(GUI.mapPanel, "", 16, UIUtil.titleFont)
    GUI.mapName:SetColor(UIUtil.bodyColor)
    LayoutHelpers.CenteredBelow(GUI.mapName, mapOverlay, 10)

    GUI.changeMapButton = UIUtil.CreateButtonStd(GUI.mapPanel, '/scx_menu/small-btn/small', "<LOC map_sel_0000>Game Options", 12, 2)
    LayoutHelpers.AtBottomIn(GUI.changeMapButton, GUI.mapPanel, -6)
    LayoutHelpers.AtHorizontalCenterIn(GUI.changeMapButton, GUI.mapPanel)

    Tooltip.AddButtonTooltip(GUI.changeMapButton, 'lob_select_map')

    GUI.changeMapButton.OnClick = function(self)
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
    GUI.launchGameButton = UIUtil.CreateButtonStd(GUI.launchPanel, '/scx_menu/large-no-bracket-btn/large', "<LOC lobui_0212>Launch", 18, 4)
    GUI.exitButton = UIUtil.CreateButtonStd(GUI.launchPanel, '/scx_menu/small-btn/small', "", 18, 4)

    if GpgNetActive() then
        GUI.exitButton.label:SetText(LOC("<LOC _Exit>"))
    else
        GUI.exitButton.label:SetText(LOC("<LOC _Back>"))
    end
    
    import('/lua/ui/uimain.lua').SetEscapeHandler(function() GUI.exitButton.OnClick(GUI.exitButton) end)

    LayoutHelpers.AtCenterIn(GUI.launchGameButton, GUI.launchPanel, -1, -22)
    LayoutHelpers.AtLeftIn(GUI.exitButton, GUI.chatPanel, 10)
    LayoutHelpers.AtVerticalCenterIn(GUI.exitButton, GUI.launchGameButton)

    GUI.launchGameButton:UseAlphaHitTest(false)
    GUI.launchGameButton.glow = Bitmap(GUI.launchGameButton, UIUtil.UIFile('/menus/main03/large_btn_glow.dds'))
    LayoutHelpers.AtCenterIn(GUI.launchGameButton.glow, GUI.launchGameButton)
    GUI.launchGameButton.glow:SetAlpha(0)
    GUI.launchGameButton.glow:DisableHitTest()
    GUI.launchGameButton.OnRolloverEvent = function(self, event) 
           if event == 'enter' then
            EffectHelpers.FadeIn(self.glow, .25, 0, 1)
            self.label:SetColor('black')
        elseif event == 'down' then
            self.label:SetColor('black')
        else
            EffectHelpers.FadeOut(self.glow, .4, 1, 0)
            self.label:SetColor(UIUtil.fontColor)
        end
    end
    
    GUI.launchGameButton.pulse = Bitmap(GUI.launchGameButton, UIUtil.UIFile('/menus/main03/large_btn_glow.dds'))
    LayoutHelpers.AtCenterIn(GUI.launchGameButton.pulse, GUI.launchGameButton)
    GUI.launchGameButton.pulse:DisableHitTest()
    GUI.launchGameButton.pulse:SetAlpha(.5)
    EffectHelpers.Pulse(GUI.launchGameButton.pulse, 2, .5, 1)
    
    Tooltip.AddButtonTooltip(GUI.launchGameButton, 'Lobby_Launch')


    -- hide unless we're the game host
    GUI.launchGameButton:Hide()

    GUI.launchGameButton.OnClick = function(self)
                                       TryLaunch(false)
                                   end

    ---------------------------------------------------------------------------
    -- set up chat display
    ---------------------------------------------------------------------------
    GUI.chatEdit = Edit(GUI.chatPanel)
    LayoutHelpers.AtLeftTopIn(GUI.chatEdit, GUI.panel, 84, 634)
    GUI.chatEdit.Width:Set(640)
    GUI.chatEdit.Height:Set(14)
    GUI.chatEdit:SetFont(UIUtil.bodyFont, 16)
    GUI.chatEdit:SetForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:SetHighlightBackgroundColor('00000000')
    GUI.chatEdit:SetHighlightForegroundColor(UIUtil.fontColor)
    GUI.chatEdit:ShowBackground(false)
    GUI.chatEdit:AcquireFocus()

    GUI.chatDisplay = ItemList(GUI.chatPanel)
    GUI.chatDisplay:SetFont(UIUtil.bodyFont, 14)
    GUI.chatDisplay:SetColors(UIUtil.fontColor(), "00000000", UIUtil.fontColor(), "00000000")
    LayoutHelpers.AtLeftTopIn(GUI.chatDisplay, GUI.panel, 50, 504)
    GUI.chatDisplay.Bottom:Set(function() return GUI.chatEdit.Top() - 15 end)
    GUI.chatDisplay.Right:Set(function() return GUI.chatPanel.Right() - 40 end)
    GUI.chatDisplay.Height:Set(function() return GUI.chatDisplay.Bottom() - GUI.chatDisplay.Top() end)
    GUI.chatDisplay.Width:Set(function() return GUI.chatDisplay.Right() - GUI.chatDisplay.Left() end)

    GUI.chatDisplayScroll = UIUtil.CreateVertScrollbarFor(GUI.chatDisplay)

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
    GUI.OptionContainer.Height:Set(254)
    GUI.OptionContainer.Width:Set(182)
    GUI.OptionContainer.top = 0
    LayoutHelpers.AtLeftTopIn(GUI.OptionContainer, GUI.mapPanel, 15, 280)
    
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
        while GUI.OptionDisplay[table.getsize(GUI.OptionDisplay)].Bottom() + GUI.OptionDisplay[1].Height() < GUI.OptionContainer.Bottom() do
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
    
    UIUtil.CreateVertScrollbarFor(GUI.OptionContainer)
    
    if singlePlayer then
        GUI.loadButton = UIUtil.CreateButtonStd(GUI.optionsPanel, '/scx_menu/small-btn/small', "<LOC lobui_0176>Load", 18, 2)
        LayoutHelpers.LeftOf(GUI.loadButton, GUI.launchGameButton, 10)
        LayoutHelpers.AtVerticalCenterIn(GUI.loadButton, GUI.launchGameButton)
        GUI.loadButton.OnClick = function(self, modifiers)
            import('/lua/ui/dialogs/saveload.lua').CreateLoadDialog(GUI)
        end
        Tooltip.AddButtonTooltip(GUI.loadButton, 'Lobby_Load')
    elseif not lobbyComm:IsHost() then
        GUI.restrictedUnitsButton = UIUtil.CreateButtonStd(GUI.optionsPanel, '/scx_menu/small-btn/small', "<LOC lobui_0376>Unit Manager", 14, 2)
        LayoutHelpers.LeftOf(GUI.restrictedUnitsButton, GUI.launchGameButton, 10)
        LayoutHelpers.AtVerticalCenterIn(GUI.restrictedUnitsButton, GUI.launchGameButton)
        GUI.restrictedUnitsButton.OnClick = function(self, modifiers)
            import('/lua/ui/lobby/restrictedUnitsDlg.lua').CreateDialog(GUI.panel, gameInfo.GameOptions.RestrictedCategories, function() end, function() end, false)
        end
        Tooltip.AddButtonTooltip(GUI.restrictedUnitsButton, 'lob_RestrictedUnitsClient')
    end
    ---------------------------------------------------------------------------
    -- set up player grid
    ---------------------------------------------------------------------------

    -- set up player "slots" which is the line representing a player and player specific options
    local prev = nil

    local slotColumnSizes = {
		rating = {x = 48, width = 51},
		games = {x = 103, width = 51},
        player = {x = 157, width = 251},
        color = {x = 417, width = 59},
        faction = {x = 485, width = 59},
        team = {x = 553, width = 60},
        ping = {x = 620, width = 62},
        ready = {x = 685, width = 51},
    }

    GUI.labelGroup = Group(GUI.playerPanel)
    GUI.labelGroup.Width:Set(690)
    GUI.labelGroup.Height:Set(21)

    LayoutHelpers.AtLeftTopIn(GUI.labelGroup, GUI.playerPanel, 5, 5)	
		
	GUI.ratingLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC _Rating>Rating", 14, UIUtil.titleFont)
	LayoutHelpers.AtLeftIn(GUI.ratingLabel, GUI.panel, slotColumnSizes.rating.x)
	LayoutHelpers.AtVerticalCenterIn(GUI.ratingLabel, GUI.labelGroup, 5)
	Tooltip.AddControlTooltip(GUI.ratingLabel, 'rating')
	
	GUI.numGamesLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC _Games>Games", 14, UIUtil.titleFont)
	LayoutHelpers.AtLeftIn(GUI.numGamesLabel, GUI.panel, slotColumnSizes.games.x - 4)
	LayoutHelpers.AtVerticalCenterIn(GUI.numGamesLabel, GUI.labelGroup, 5)
	Tooltip.AddControlTooltip(GUI.numGamesLabel, 'num_games')

    GUI.nameLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0213>Player Name", 14, UIUtil.titleFont)
    LayoutHelpers.AtLeftIn(GUI.nameLabel, GUI.panel, slotColumnSizes.player.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.nameLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.nameLabel, 'lob_slot')

    GUI.colorLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0214>Color", 14, UIUtil.titleFont)
    LayoutHelpers.AtLeftIn(GUI.colorLabel, GUI.panel, slotColumnSizes.color.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.colorLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.colorLabel, 'lob_color')

    GUI.factionLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0215>Faction", 14, UIUtil.titleFont)
    LayoutHelpers.AtLeftIn(GUI.factionLabel, GUI.panel, slotColumnSizes.faction.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.factionLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.factionLabel, 'lob_faction')

    GUI.teamLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0216>Team", 14, UIUtil.titleFont)
    LayoutHelpers.AtLeftIn(GUI.teamLabel, GUI.panel, slotColumnSizes.team.x)
    LayoutHelpers.AtVerticalCenterIn(GUI.teamLabel, GUI.labelGroup, 5)
    Tooltip.AddControlTooltip(GUI.teamLabel, 'lob_team')

    if not singlePlayer then
        GUI.pingLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0217>Ping", 14, UIUtil.titleFont)
        LayoutHelpers.AtLeftIn(GUI.pingLabel, GUI.panel, slotColumnSizes.ping.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.pingLabel, GUI.labelGroup, 5)
		--Tooltip.AddControlTooltip(GUI.pingLabel, '') -- NEED INFO (write tooltip in "\lua\ui\help\tooltips.lua")

        GUI.readyLabel = UIUtil.CreateText(GUI.labelGroup, "<LOC lobui_0218>Ready", 14, UIUtil.titleFont)
        LayoutHelpers.AtLeftIn(GUI.readyLabel, GUI.panel, slotColumnSizes.ready.x)
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
		
        GUI.slots[i].ratingGroup = Group(bg)
		GUI.slots[i].ratingGroup.Width:Set(slotColumnSizes.rating.width)
		GUI.slots[i].ratingGroup.Height:Set(GUI.slots[curRow].Height)
		LayoutHelpers.AtLeftIn(GUI.slots[i].ratingGroup, GUI.panel, slotColumnSizes.rating.x)
		LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].ratingGroup, GUI.slots[i], 6)

		GUI.slots[i].ratingText = UIUtil.CreateText(GUI.slots[i].ratingGroup, "", 14, UIUtil.bodyFont)
		LayoutHelpers.AtBottomIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup)
		LayoutHelpers.AtRightIn(GUI.slots[i].ratingText, GUI.slots[i].ratingGroup, 9)
		
		GUI.slots[i].numGamesGroup = Group(bg)
		GUI.slots[i].numGamesGroup.Width:Set(slotColumnSizes.games.width)
		GUI.slots[i].numGamesGroup.Height:Set(GUI.slots[curRow].Height)
		LayoutHelpers.AtLeftIn(GUI.slots[i].numGamesGroup, GUI.panel, slotColumnSizes.games.x)
		LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].numGamesGroup, GUI.slots[i], 6)

		GUI.slots[i].numGamesText = UIUtil.CreateText(GUI.slots[i].numGamesGroup, "", 14, UIUtil.bodyFont)
		LayoutHelpers.AtBottomIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup)
		LayoutHelpers.AtRightIn(GUI.slots[i].numGamesText, GUI.slots[i].numGamesGroup, 9)

        GUI.slots[i].name = Combo(bg, 16, 10, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
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

        GUI.slots[i].color = BitmapCombo(bg, gameColors.PlayerColors, 1, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].color, GUI.panel, slotColumnSizes.color.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].color, GUI.slots[i], 8)
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

        GUI.slots[i].faction = BitmapCombo(bg, factionBmps, table.getn(factionBmps), nil, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].faction, GUI.panel, slotColumnSizes.faction.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].faction, GUI.slots[i], 8)
        GUI.slots[i].faction.Width:Set(slotColumnSizes.faction.width)
        GUI.slots[i].faction.OnClick = function(self, index)
            SetPlayerOption(self.row,'Faction',index)
            Tooltip.DestroyMouseoverDisplay()
        end
        Tooltip.AddControlTooltip(GUI.slots[i].faction, 'lob_faction')
        Tooltip.AddComboTooltip(GUI.slots[i].faction, factionTooltips)
        GUI.slots[i].faction.row = i
        GUI.slots[i].faction.OnEvent = GUI.slots[curRow].name.OnEvent
        if not hasSupcom then
            GUI.slots[i].faction:SetItem(4)
        end

        GUI.slots[i].team = BitmapCombo(bg, teamIcons, 1, false, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
        LayoutHelpers.AtLeftIn(GUI.slots[i].team, GUI.panel, slotColumnSizes.team.x)
        LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].team, GUI.slots[i], 8)
        GUI.slots[i].team.Width:Set(slotColumnSizes.team.width)
        GUI.slots[i].team.row = i
        GUI.slots[i].team.OnClick = function(self, index, text)
            Tooltip.DestroyMouseoverDisplay()
            SetPlayerOption(self.row,'Team',index)
        end
        Tooltip.AddControlTooltip(GUI.slots[i].team, 'lob_team')
        Tooltip.AddComboTooltip(GUI.slots[i].team, teamTooltips)
        GUI.slots[i].team.OnEvent = GUI.slots[curRow].name.OnEvent

        if not singlePlayer then
            GUI.slots[i].pingGroup = Group(bg)
            GUI.slots[i].pingGroup.Width:Set(slotColumnSizes.ping.width)
            GUI.slots[i].pingGroup.Height:Set(GUI.slots[curRow].Height)
            LayoutHelpers.AtLeftIn(GUI.slots[i].pingGroup, GUI.panel, slotColumnSizes.ping.x)
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[i].pingGroup, GUI.slots[i], 8)

            GUI.slots[i].pingText = UIUtil.CreateText(GUI.slots[i].pingGroup, "xx", 14, UIUtil.bodyFont)
            LayoutHelpers.AtBottomIn(GUI.slots[i].pingText, GUI.slots[i].pingGroup)
            LayoutHelpers.AtHorizontalCenterIn(GUI.slots[i].pingText, GUI.slots[i].pingGroup)

            GUI.slots[i].pingStatus = StatusBar(GUI.slots[i].pingGroup, 0, 1000, false, false,
                UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
                true)
            LayoutHelpers.AtTopIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup)
            LayoutHelpers.AtLeftIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 5)
            LayoutHelpers.AtRightIn(GUI.slots[i].pingStatus, GUI.slots[i].pingGroup, 5)
            GUI.slots[i].pingStatus.Bottom:Set(GUI.slots[curRow].pingText.Top)
        end

        -- depending on if this is single player or multiplayer this displays different info
        GUI.slots[i].multiSpace = Group(bg, "multiSpace " .. tonumber(i))
        GUI.slots[i].multiSpace.Width:Set(slotColumnSizes.ready.width)
        GUI.slots[i].multiSpace.Height:Set(GUI.slots[curRow].Height)
        LayoutHelpers.AtLeftIn(GUI.slots[i].multiSpace, GUI.panel, slotColumnSizes.ready.x)
        GUI.slots[i].multiSpace.Top:Set(GUI.slots[curRow].Top)

        if not singlePlayer then
            GUI.slots[i].ready = UIUtil.CreateCheckboxStd(GUI.slots[i].multiSpace, '/dialogs/check-box_btn/radio')
            GUI.slots[i].ready.row = i
            LayoutHelpers.AtVerticalCenterIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 8)
            LayoutHelpers.AtLeftIn(GUI.slots[curRow].ready, GUI.slots[curRow].multiSpace, 10)
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
	
        GUI.observerLabel = UIUtil.CreateText(GUI.observerPanel, "<LOC lobui_0275>Observers", 14, UIUtil.bodyFont)
        LayoutHelpers.AtLeftTopIn(GUI.observerLabel, GUI.observerPanel, 5, 6)

        Tooltip.AddControlTooltip(GUI.observerLabel, 'lob_describe_observers')

        GUI.allowObservers = UIUtil.CreateCheckboxStd(GUI.observerPanel, '/dialogs/check-box_btn/radio')
        LayoutHelpers.CenteredRightOf(GUI.allowObservers, GUI.observerLabel, 0)

        Tooltip.AddControlTooltip(GUI.allowObservers, 'lob_observers_allowed')

        GUI.allowObservers:SetCheck(false)
        if lobbyComm:IsHost() then
            SetGameOption("AllowObservers",false)
            GUI.allowObservers.OnCheck = function(self, checked)
                SetGameOption("AllowObservers",checked)
            end
		end

        GUI.becomeObserver = UIUtil.CreateButtonStd(GUI.observerPanel, '/lobby/lan-game-lobby/toggle', "<LOC lobui_0228>Observe", 10, 0)
        LayoutHelpers.CenteredRightOf(GUI.becomeObserver, GUI.allowObservers, 5)

        Tooltip.AddButtonTooltip(GUI.becomeObserver, 'lob_become_observer')
        
        GUI.becomeObserver.OnClick = function(self, modifiers)
            if IsPlayer(localPlayerID) then
                if lobbyComm:IsHost() then
                    HostConvertPlayerToObserver(hostID, localPlayerName, FindSlotForID(localPlayerID))
                else
                    lobbyComm:SendData(hostID, {Type = 'RequestConvertToObserver', RequestedName = localPlayerName, RequestedSlot =  FindSlotForID(localPlayerID)})
                end
            end
        end		
		
		if lobbyComm:IsHost() then
			--start of auto teams code by Moritz	
			GUI.randTeam = UIUtil.CreateButtonStd(GUI.observerPanel, '/lobby/lan-game-lobby/toggle', "<LOC lobui_0506>Auto Teams", 10, 0)
			LayoutHelpers.CenteredRightOf(GUI.randTeam, GUI.becomeObserver, 5)
			
			Tooltip.AddButtonTooltip(GUI.randTeam, 'lob_click_randteam')
			
			GUI.randTeam.OnClick = function(self, modifiers)								
				if gameInfo.GameOptions['AutoTeams'] == 'none' then
					Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 2)
					SetGameOption('AutoTeams', 'tvsb')
				elseif gameInfo.GameOptions['AutoTeams'] == 'tvsb' then
					Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 3)
					SetGameOption('AutoTeams', 'lvsr')
				elseif gameInfo.GameOptions['AutoTeams'] == 'lvsr' then
					Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 4)
					SetGameOption('AutoTeams', 'pvsi')
				elseif gameInfo.GameOptions['AutoTeams'] == 'pvsi' then
					Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 5)
					SetGameOption('AutoTeams', 'manual')
				else
					Prefs.SetToCurrentProfile('Lobby_Auto_Teams', 1)
					SetGameOption('AutoTeams', 'none')
				end				
			end
			--end of auto teams code
			--start of random map code by Moritz
			GUI.randMap = UIUtil.CreateButtonStd(GUI.observerPanel, '/lobby/lan-game-lobby/toggle', "<LOC lobui_0503>Random Map", 10, 0)
			LayoutHelpers.CenteredRightOf(GUI.randMap, GUI.randTeam, 5)
			
			Tooltip.AddButtonTooltip(GUI.randMap, 'lob_click_randmap')
			
			GUI.randMap.OnClick = function()
				local randomMap
				randomMap = import('/lua/ui/dialogs/mapselect.lua').randomLobbyMap()
			end
			
			function sendRandMapMessage()
				local rMapName = import('/lua/ui/dialogs/mapselect.lua').rMapName	
				local rMapSize1 = import('/lua/ui/dialogs/mapselect.lua').rMapSize1
				local rMapSize2 = import('/lua/ui/dialogs/mapselect.lua').rMapSize2
				local rMapSizeFil = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFil
				local rMapSizeFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapSizeFilLim
				local rMapPlayersFil = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFil
				local rMapPlayersFilLim = import('/lua/ui/dialogs/mapselect.lua').rMapPlayersFilLim
				local rMapTypeFil = import('/lua/ui/dialogs/mapselect.lua').rMapTypeFil
				SendSystemMessage("---------------------------------------------------------------------------------------------------")			
				SendSystemMessage(LOCF('%s %s', "<LOC lobui_0504>Randomly selected map: ", rMapName))
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
					SendSystemMessage(LOCF("<LOC lobui_0516>Filters: Map Size is %s %dkm and Number of Players are %s %d", rMapSizeFilLim, rMapSizeFil, rMapPlayersFilLim, rMapPlayersFil))
				elseif rMapSizeFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0517>Filters: Map Size is %s %dkm and Number of Players are ALL", rMapSizeFilLim, rMapSizeFil))
				elseif rMapPlayersFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0518>Filters: Map Size is ALL and Number of Players are %s %d", rMapPlayersFilLim, rMapPlayersFil))
				end
				if rMapTypeFil != 0 then
					SendSystemMessage(LOCF("<LOC lobui_0578>Map Type: %s", rMapTypeFil))
				end
				SendSystemMessage("---------------------------------------------------------------------------------------------------")
				if not quickRandMap then
					quickRandMap = true
					UpdateGame()
				end
			end		
		--end of random map code
		--start of ranked options code
			GUI.rankedOptions = UIUtil.CreateButtonStd(GUI.observerPanel, '/lobby/lan-game-lobby/toggle', "<LOC lobui_0522>Default Settings", 10, 0)
			LayoutHelpers.CenteredRightOf(GUI.rankedOptions, GUI.randMap, 5)
			
			Tooltip.AddButtonTooltip(GUI.rankedOptions, 'lob_click_rankedoptions')
			   
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
		
		
		
		
		
		--start of auto kick code -- Modified by Xinnony
		if lobbyComm:IsHost() then
			GUI.autoKickLabel = UIUtil.CreateText(GUI.observerPanel, "Auto kick", 14, UIUtil.bodyFont)
				LayoutHelpers.CenteredRightOf(GUI.autoKickLabel, GUI.rankedOptions, 5)
				Tooltip.AddControlTooltip(GUI.autoKickLabel, 'lob_auto_kick')
			GUI.autoKick = UIUtil.CreateCheckboxStd(GUI.observerPanel, '/dialogs/check-box_btn/radio')
				LayoutHelpers.CenteredRightOf(GUI.autoKick, GUI.autoKickLabel, 0)
				Tooltip.AddControlTooltip(GUI.autoKick, 'lob_auto_kick')
			GUI.autoKick:SetCheck(false)
			autoKick = false
			GUI.autoKick.OnCheck = function(self, checked)
				autoKick = checked
				UpdateGame()
			end
		end
		--end of auto kick code
		
        GUI.observerList = ItemList(GUI.observerPanel, "observer list")
        GUI.observerList:SetFont(UIUtil.bodyFont, 14)
        GUI.observerList:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontOverColor, UIUtil.highlightColor, "ffbcfffe")
        LayoutHelpers.Below(GUI.observerList, GUI.observerLabel, 8)
        GUI.observerList.Left:Set(function() return GUI.observerLabel.Left() + 5 end)
        GUI.observerList.Bottom:Set(function() return GUI.observerPanel.Bottom() - 12 end)
        GUI.observerList.Right:Set(function() return GUI.observerPanel.Right() - 40 end)
        
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

        UIUtil.CreateVertScrollbarFor(GUI.observerList)
		
		if lobbyComm:IsHost() then
			GUI.uploadMapButton = UIUtil.CreateButtonStd(GUI.launchPanel, '/scx_menu/small-btn/small', "", 14, 2)
			GUI.uploadMapButton.label:SetText(LOC("<LOC lobui_0734>Upload Map"))
			Tooltip.AddControlTooltip(GUI.uploadMapButton, 'lob_upload_map')
			LayoutHelpers.CenteredRightOf(GUI.uploadMapButton, GUI.exitButton)    

			GUI.uploadMapButton.OnClick = function()
				uploadNewMap()
				UpdateGame()
			end		
		end

    else

        -- observers are always allowed in skirmish games.
        SetGameOption("AllowObservers",true)

    end
	
	

    ---------------------------------------------------------------------------
    -- other logic, including lobby callbacks
    ---------------------------------------------------------------------------
    GUI.posGroup = false

--  control behvaior
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

-- get ping times
    GUI.pingThread = ForkThread(
        function()
            while true and lobbyComm do
                for slot,player in gameInfo.PlayerOptions do
                    if player.Human and player.OwnerID != localPlayerID then
                        local peer = lobbyComm:GetPeer(player.OwnerID)
                        local ping = peer.ping and math.floor(peer.ping)
                        GUI.slots[slot].pingText:SetText(tostring(ping))
                        GUI.slots[slot].pingText:SetColor(CalcConnectionStatus(peer))
                        if ping then
                            GUI.slots[slot].pingStatus:SetValue(ping)
                            GUI.slots[slot].pingStatus:Show()
                        else
                            GUI.slots[slot].pingStatus:Hide()
                        end
                    end
                end
                for slot, observer in gameInfo.Observers do
                    if observer and (observer.OwnerID != localPlayerID) and observer.ObserverListIndex then
                        local peer = lobbyComm:GetPeer(observer.OwnerID)
                        local ping = math.floor(peer.ping)
                        GUI.observerList:ModifyItem(observer.ObserverListIndex, observer.PlayerName  .. LOC("<LOC lobui_0240> (Ping = ") .. tostring(ping) .. ")")
                    end
                end
                WaitSeconds(1)
            end
        end
    )

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
--		AddChatText('Welcome to Forged Alliance Forever MOD'..getInit)
		local getVictory = gameInfo.GameOptions['Victory'] -- 'demoralization'
		local getCheat = gameInfo.GameOptions['CheatsEnabled'] -- 'false'
		local getSpeed = gameInfo.GameOptions['GameSpeed'] -- 'normal'
		local getFog = gameInfo.GameOptions['FogOfWar'] -- 'explored'
		local getPrebui = gameInfo.GameOptions['PrebuiltUnits'] -- 'Off'
		local getNorush = gameInfo.GameOptions['NoRushOption'] -- 'Off'
		local getNumbMod = table.getn(Mods.GetGameMods(gameInfo.GameMods)) -- 0 for the purposes of this function
		local getRstric = gameInfo.GameOptions.RestrictedCategories -- can be nil or a table, even if no unit restrictions are present
--~ 			AddChatText(tostring(cRstr))
		if getVictory == 'demoralization' and getCheat == 'false' and getSpeed == 'normal'
		and getFog == 'explored' and getPrebui == 'Off' and getNorush == 'Off' and getNumbMod == 0 and getRstric == nil then
			--table.insert(formattedOptions, {text = 'Ranking',
				--value = 'Ranked',
				--green = true,
				--tooltip = {text='Ranked',body='This game is Ranked !'}})
			GUI.mapName:SetText("Game is Ranked")
			GUI.mapName:SetColor("77ff77")
			--Tooltip.AddControlTooltip(GUI.mapName, '')
		else
			if getVictory == 'demoralization' and getCheat == 'false' and getSpeed == 'normal'
			and getFog == 'explored' and getPrebui == 'Off' and getNorush == 'Off' and getNumbMod == 0 and table.getn(getRstric) == 0 then
				--table.insert(formattedOptions, {text = 'Ranking',
					--value = 'Ranked',
					--green = true,
					--tooltip = {text='Ranked',body='This game is Ranked !'}})
				GUI.mapName:SetText("Game is Ranked")
				GUI.mapName:SetColor("77ff77")
				--Tooltip.AddControlTooltip(GUI.mapName, '')
			else
				--table.insert(formattedOptions, {text = 'Ranking',
					--value = 'Unranked',
					--red = true,
					--tooltip = {text='Unranked',body='This game is NOT Ranked !'}})
				GUI.mapName:SetText("Game is not Ranked")
				GUI.mapName:SetColor("ff7777")
				--Tooltip.AddControlTooltip(GUI.mapName, '')
			end
		end
	else
--~ 		if getInit == "init_blackops.lua" then
--~ 			AddChatText('Welcome to BlackOps MOD')
--~ 		elseif getInit == "init_labwars.lua" then
--~ 			AddChatText('Welcome to Labwars MOD')
--~ 		elseif getInit == "init_ladder1v1.lua" then
--~ 			AddChatText('Welcome to Ladder 1v1 MOD')
--~ 		elseif getInit == "init_nomads.lua" then
--~ 			AddChatText('Welcome to Nomads MOD')
--~ 		elseif getInit == "init_phantomx.lua" then
--~ 			AddChatText('Welcome to PhantomX MOD')
--~ 		elseif getInit == "init_supremeDestruction.lua" then
--~ 			AddChatText('Welcome to SupremeDestruction MOD')
--~ 		elseif getInit == "init_xtremewars.lua" then
--~ 			AddChatText('Welcome to XtremeWars MOD')
--~ 		end
		--table.insert(formattedOptions, {text = 'Ranking',
			--value = 'Unranked',
			--red = true,
			--tooltip = {text='Unranked',body='This game is NOT Ranked !'}})
		GUI.mapName:SetText("Game is not Ranked")
		GUI.mapName:SetColor("ff7777")
		--Tooltip.AddControlTooltip(GUI.mapName, '')
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
--// Check MapSize & MaxPlayer active
    if scenarioInfo then
        table.insert(formattedOptions, {text = '<LOC MAPSEL_0024>', 
            value = LOCF("<LOC map_select_0008>%dkm x %dkm", scenarioInfo.size[1]/50, scenarioInfo.size[2]/50),
            tooltip = 'map_select_sizeoption',
            valueTooltip = 'map_select_sizeoption'})
        table.insert(formattedOptions, {text = '<LOC MAPSEL_0031>Max Players', 
            value = LOCF("<LOC map_select_0009>%d", table.getsize(scenarioInfo.Configurations.standard.teams[1].armies)),
            tooltip = 'map_select_maxplayers',
            valueTooltip = 'map_select_maxplayers'})
    end
--\\ Stop Check MapSize & MaxPlayer active
--// Check other options active
    for i, v in gameInfo.GameOptions do
        local option = false
        local mpOnly = false
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
            end
        end
    end
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
								lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID), RequestedSlot =  self.Slot})
							end
						elseif IsObserver(localPlayerID) then
							if lobbyComm:IsHost() then
								requestedFaction = Prefs.GetFromCurrentProfile('LastFaction')
								requestedPL = playerRating
								requestedRC = ratingColor
								requestedNG = numGames
								HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID), self.Slot, requestedFaction, requestedPL, requestedRC, requestedNG)
							else
								lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName, ObserverSlot = FindObserverSlotForID(localPlayerID), PlayerSlot = self.Slot, requestedFaction = Prefs.GetFromCurrentProfile('LastFaction'), requestedPL = playerRating, requestedRC = ratingColor, requestedNG = numGames})
							end
						end
					end
				else
					if gameInfo.GameOptions['AutoTeams'] and lobbyComm:IsHost() then
						if gameInfo.GameOptions['AutoTeams'] == 'manual' then							
							if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
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
				if not gameInfo.ClosedSlots[slot] and (gameInfo.PlayerOptions[slot] or gameInfo.GameOptions['TeamSpawn'] == 'random') then
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
					if slot == 1 or slot == 3 or slot == 5 or slot == 7 or slot == 9 or slot == 11 then
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
    end

    lobbyComm.ConnectionFailed = function(self, reason)
        LOG("CONNECTION FAILED ",reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI.panel, LOCF(Strings.ConnectionFailed, Strings[reason] or reason), "<LOC _OK>", ReturnToMenu)

        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.LaunchFailed = function(self,reasonKey)
        AddChatText(LOC(Strings[reasonKey] or reasonKey))
    end

    lobbyComm.Ejected = function(self,reason)
        LOG("EJECTED ",reason)

        GUI.connectionFailedDialog = UIUtil.ShowInfoDialog(GUI, LOCF(Strings.Ejected, Strings[reason] or reason), "<LOC _OK>", ReturnToMenu)
        lobbyComm:Destroy()
        lobbyComm = nil
    end

    lobbyComm.ConnectionToHostEstablished = function(self,myID,myName,theHostID)		

        hostID = theHostID
        localPlayerID = myID
        localPlayerName = myName

        lobbyComm:SendData(hostID, { Type = 'SetAvailableMods', Mods = GetLocallyAvailableMods() } )

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
				RequestedDEV = playerDeviation
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
        end

        if lobbyComm:IsHost() then
            -- Host only messages

            if data.Type == 'GetGameInfo' then
                lobbyComm:SendData( data.SenderID, {Type = 'GameInfo', GameInfo = gameInfo} )

            elseif data.Type == 'AddPlayer' then
                -- create empty slot if possible and give it to the player
                HostTryAddPlayer( data.SenderID, data.RequestedSlot, data.RequestedPlayerName, data.Human, data.AIPersonality, data.RequestedColor, data.RequestedFaction, nil, data.RequestedPL, data.RequestedRC, data.RequestedNG, data.RequestedMEAN, data.RequestDEV )
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
                HostConvertObserverToPlayer(data.SenderID, data.RequestedName, data.ObserverSlot, data.PlayerSlot, data.requestedFaction, data.requestedPL, data.requestedRC, data.requestedNG)

            elseif data.Type == 'RequestColor' then
                if IsColorFree(data.Color) then
                    -- Color is available, let everyone else know
                    gameInfo.PlayerOptions[data.Slot].PlayerColor = data.Color
                    lobbyComm:BroadcastData( { Type = 'SetColor', Color = data.Color, Slot = data.Slot } )
                    UpdateGame()
                else
                    -- Sorry, it's not free. Force the player back to the color we have for him.
                    lobbyComm:SendData( data.SenderID, { Type = 'SetColor', Color = gameInfo.PlayerOptions[data.Slot].PlayerColor, Slot = data.Slot } )
                end
            elseif data.Type == 'ClearSlot' then
                if gameInfo.PlayerOptions[data.Slot].OwnerID == data.SenderID then
                    HostRemoveAI(data.Slot)
                else
                    WARN("Attempt to clear unowned slot")
                end
            elseif data.Type == 'SetAvailableMods' then
                availableMods[data.SenderID] = data.Mods				
                HostUpdateMods(data.SenderID)
            elseif data.Type == 'MissingMap' then
                HostPlayerMissingMapAlert(data.Id)
            end
        else
            -- Non-host only messages
            if data.Type == 'SystemMessage' then
                AddChatText(data.Text)

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
            IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyMappings(gameInfo.GameOptions['CheatsEnabled'] == 'true'))
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
                            SendSystemMessage(LOCF(Strings.TimedOut,peer.name))
                            lobbyComm:EjectPeer(peer.id,'TimedOutToHost')
                        end
                    end
                    WaitSeconds(1)
                end
            end
        )

        CreateUI(LobbyComm.maxPlayerSlots)
        UpdateGame()

        if not singlePlayer and not GpgNetActive() then
            AddChatText(LOCF('<LOC lobui_0290>Hosting on port %d', lobbyComm:GetLocalPort()))
        end
    end

    lobbyComm.PeerDisconnected = function(self,peerName,peerID)
        --LOG('PeerDisconnected : ', peerName, ' ', peerID)
        --LOG('GameInfo = ', repr(gameInfo))

        local slot = FindSlotForID(peerID)
        if slot then
			PlayVoice(Sound{Bank = 'XGG',Cue = 'XGG_Computer__04717'}, true)
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


--------------------------------------------------------------------  Big Map Preview  --------------------------------------------------------------------
-------------------------------------------------------------------- (Code by ThaPear) --------------------------------------------------------------------

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
	
	LrgMap.CloseBtn = UIUtil.CreateButtonStd(LrgMap, '/dialogs/close_btn/close', "", 12, 2, 0, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
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
		LrgMap.massmarkers[i].Left:Set(LrgMap.Left() + massmarkers[i].position[1]/scenarioInfo.size[1]*LrgMap.Width() - LrgMap.massmarkers[i].Width()/2)
		LrgMap.massmarkers[i].Top:Set(LrgMap.Top() + massmarkers[i].position[3]/scenarioInfo.size[2]*LrgMap.Height() - LrgMap.massmarkers[i].Height()/2)
	end
	LrgMap.hydros = {}
	for i = 1, table.getn(hydromarkers) do
		LrgMap.hydros[i] = Bitmap(LrgMap, UIUtil.SkinnableFile("/game/build-ui/icon-energy_bmp.dds"))
		LrgMap.hydros[i].Width:Set(14)
		LrgMap.hydros[i].Height:Set(14)
		LrgMap.hydros[i].Left:Set(LrgMap.Left() + hydromarkers[i].position[1]/scenarioInfo.size[1]*LrgMap.Width() - LrgMap.hydros[i].Width()/2)
		LrgMap.hydros[i].Top:Set(LrgMap.Top() + hydromarkers[i].position[3]/scenarioInfo.size[2]*LrgMap.Height() - LrgMap.hydros[i].Height()/2)
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
							lobbyComm:SendData(hostID, {Type = 'MovePlayer', CurrentSlot = FindSlotForID(localPlayerID), RequestedSlot =  self.Slot})
						end
					elseif IsObserver(localPlayerID) then
						if lobbyComm:IsHost() then
							HostConvertObserverToPlayer(hostID, localPlayerName, FindObserverSlotForID(localPlayerID), self.Slot)
						else
							lobbyComm:SendData(hostID, {Type = 'RequestConvertToPlayer', RequestedName = localPlayerName, ObserverSlot = FindObserverSlotForID(localPlayerID), PlayerSlot = self.Slot})
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
		LrgMap.markers[slot].Indicator = Bitmap(LrgMap.markers[slot].marker, UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
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