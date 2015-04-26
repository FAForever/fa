--*****************************************************************************
--* File: lua/LobbyManager.lua
--* Author: Duck42
--*****************************************************************************

local Prefs = import('/lua/user/prefs.lua')
local config = {}

--Addidtional reasons can be added to the end of this table.
--Changing any of these values will affect 
reasonTable = {}
reasonTable[1] = 'Breaking Game Rules'
reasonTable[2] = 'Abusive Language and/or Profanity'
reasonTable[3] = 'Quitting Early and/or Abandoning Allies'
reasonTable[4] = 'Attacking Allies'
reasonTable[5] = 'Ghosting'
reasonTable[6] = 'Cheating and/or Using Exploits'
reasonTable[7] = 'Laggy Network Connection'
reasonTable[8] = 'Slow CPU'
reasonTable[9] = 'Bad Attitude and/or Annoying Behavior'
reasonTable[10] = 'Unspecified'


function Initialize()
	config = LoadConfig()
end

function SaveConfig(configToSave)
	Prefs.SetToCurrentProfile("LobbyManager_Settings", configToSave)
	Prefs.SavePreferences()
end

function LoadConfig()
	local savedPrefs = Prefs.GetFromCurrentProfile("LobbyManager_Settings")
	local rt = DefaultConfig(savedPrefs)
	return rt
end

function DefaultConfig(savedPrefs)
    if not savedPrefs then
        savedPrefs = {
            PromptBeforeKickBanned = false,
            ShowReasons = true,
            ShowNotes = true,
            LockBannedInObserver = true,
            AutoKickBannedPlayers = true,
        }
    end
    
    if not savedPrefs.BannedPlayers then
        savedPrefs.BannedPlayers = {}
    end
    if not savedPrefs.ProbationaryPlayers then
        savedPrefs.ProbationaryPlayers = {}
    end
    if not savedPrefs.NotedPlayers then
        savedPrefs.NotedPlayers = {}
    end
    if not savedPrefs.DelayBeforeEject then
        savedPrefs.DelayBeforeEject = 5
    end
	return savedPrefs
end

function AddBannedPlayer(peerid, reasons, note, originalname)
	--Remove them from the current lists (if they are there)
	RemoveProbationaryPlayer(peerid)
	RemoveBannedPlayer(peerid)
    RemoveNotedPlayer(peerid)
	
	local cfg = LoadConfig()
	local data = {UID = peerid, BanReasons = reasons, Notes = note, OriginalName = originalname}
	table.insert(cfg.BannedPlayers, data)
	SaveConfig(cfg)
end

function RemoveBannedPlayer(peerid)
	local cfg = LoadConfig()
	for i,v in cfg.BannedPlayers do
		if v.UID == peerid then
			table.remove(cfg.BannedPlayers, i)
		end
	end
	SaveConfig(cfg)
end

function ConvertToBan(peerid)
	local cfg = LoadConfig()
	for i,v in cfg.ProbationaryPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.ProbationaryPlayers, i)
			table.insert(cfg.BannedPlayers, data)
		end
	end
    
    for i,v in cfg.NotedPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.NotedPlayers, i)
			table.insert(cfg.BannedPlayers, data)
		end
	end
	SaveConfig(cfg)
end

function ConvertToProbation(peerid)
	local cfg = LoadConfig()
	for i,v in cfg.BannedPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.BannedPlayers, i)
			table.insert(cfg.ProbationaryPlayers, data)
		end
	end
    
    for i,v in cfg.NotedPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.NotedPlayers, i)
			table.insert(cfg.ProbationaryPlayers, data)
		end
	end
	SaveConfig(cfg)
end

function ConvertToNoted(peerid)
	local cfg = LoadConfig()
    for i,v in cfg.BannedPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.BannedPlayers, i)
			table.insert(cfg.NotedPlayers, data)
		end
	end
    
	for i,v in cfg.ProbationaryPlayers do
		if v.UID == peerid then
			local data = table.remove(cfg.ProbationaryPlayers, i)
			table.insert(cfg.NotedPlayers, data)
		end
	end
	SaveConfig(cfg)
end

function AddProbationaryPlayer(peerid, reasons, note, originalname)
	--Remove them from the current lists (if they are there)
	RemoveProbationaryPlayer(peerid)
	RemoveBannedPlayer(peerid)
    RemoveNotedPlayer(peerid)
	
	local cfg = LoadConfig()
	local data = {UID = peerid, BanReasons = reasons, Notes = note, OriginalName = originalname}
	table.insert(cfg.ProbationaryPlayers, data)
	SaveConfig(cfg)
end

function RemoveProbationaryPlayer(peerid)
	local cfg = LoadConfig()
	for i,v in cfg.ProbationaryPlayers do
		if v.UID == peerid then
			table.remove(cfg.ProbationaryPlayers, i)
		end
	end
	SaveConfig(cfg)
end

function AddNotedPlayer(peerid, reasons, note, originalname)
	--Remove them from the current lists (if they are there)
	RemoveProbationaryPlayer(peerid)
	RemoveBannedPlayer(peerid)
    RemoveNotedPlayer(peerid)
	
	local cfg = LoadConfig()
	local data = {UID = peerid, BanReasons = reasons, Notes = note, OriginalName = originalname}
	table.insert(cfg.NotedPlayers, data)
	SaveConfig(cfg)
end

function RemoveNotedPlayer(peerid)
	local cfg = LoadConfig()
	for i,v in cfg.NotedPlayers do
		if v.UID == peerid then
			table.remove(cfg.NotedPlayers, i)
		end
	end
	SaveConfig(cfg)
end

function GetPlayerInfo(peerid)
	local result = IsPlayerBanned(peerid)
	
	if result.code == 'N/A' then
		result = IsPlayerProbationary(peerid)
		if result.code == 'N/A' then
			result = IsPlayerNoted(peerid)
		end
	end
	return result
end

function IsPlayerBanned(peerid)
	local lmConfig = LoadConfig()
	
	local result = {}
	result.code = 'N/A'
	result.data = nil
	
	for i,v in lmConfig.BannedPlayers do 
		if v.UID == peerid then
			result.data = v
			result.code = 'banned'
		end
	end
	return result
end

function IsPlayerProbationary(peerid)
	local lmConfig = LoadConfig()
	
	local result = {}
	result.code = 'N/A'
	result.data = nil
	
	for i,v in lmConfig.ProbationaryPlayers do
		if v.UID == peerid then
			result.data = v
			result.code = 'probation'
		end
	end
	return result
end

function IsPlayerNoted(peerid)
	local lmConfig = LoadConfig()
	
	local result = {}
	result.code = 'N/A'
	result.data = nil
	
	for i,v in lmConfig.NotedPlayers do
		if v.UID == peerid then
			result.data = v
			result.code = 'note'
		end
	end
	return result
end