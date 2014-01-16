# Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#
# This is the user-specific top-level lua initialization file. It is run at initialization time
# to set up all lua state for the user layer.

cheatStrings = {
	'dbg_'
}


# Init our language from prefs. This applies to both front-end and session init; for
# the Sim init, the engine sets __language for us.
__language = GetPreference('options_overrides.language', '')

# Do global init
doscript '/lua/globalInit.lua'

WaitFrames = coroutine.yield

function WaitSeconds(n)
    local later = CurrentTime() + n
    WaitFrames(1)
    while CurrentTime() < later do
        WaitFrames(1)
    end
end

# a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()

function IsCheat( cmd )
	-- returns false or the position a cheat was found (true)
	local cheatFound = false
	if cmd then
		cmd = string.lower(cmd)
		for _,cheat in cheatStrings do
			cheatFound = string.find( cmd , cheat )
			if cheatFound then break end
		end
	end
	return cheatFound
end

-- CATCH CONSOLE CHEATERS
local oldConExecute = ConExecute
function ConExecute( cmd )
	if IsCheat( cmd ) then
		SessionSendChatMessage({Taunt = false, data = "I'm an ugly cheater and I don't deserve to live. Please report me to an admin !"})
		ExitGame()
	else
		oldConExecute( cmd )
	end
end

local oldConExecuteSave = ConExecuteSave
function ConExecuteSave( cmd )
	if IsCheat( cmd ) then
		SessionSendChatMessage({Taunt = false, data = "I'm an ugly cheater and I don't deserve to live. Please report me to an admin !"})
		ExitGame()
	else
		oldConExecuteSave( cmd )
	end
end

-- STOP KEYBINDING CHEATERS
local oldIN_AddKeyMapTable = IN_AddKeyMapTable
function IN_AddKeyMapTable(keyMapTable)
	-- remove keys that activate cheats
	LOG('Clearing cheats from added keymap.')
	local newKeyMapTable = {}
	for key,data in keyMapTable do
		if IsCheat( data.action ) then
			LOG('Keybinding ['..key..'] = '..data.action..' removed because it contains a cheat.')
		else
			newKeyMapTable[key] = data
		end
	end
	oldIN_AddKeyMapTable( newKeyMapTable )
end

-- REMOVE BOUND KEY CHEATS
IN_ClearKeyMap()

-- Add back all mapped keys and user prefs (FA Version)
IN_AddKeyMapTable(import('/lua/keymap/keymapper.lua').GetKeyMappings(true))
