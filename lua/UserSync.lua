# The global sync table is copied from the sim layer every time the main and sim threads are
# synchronized on the sim beat (which is like a tick but happens even when the game is paused)
Sync = {}

# The PreviousSync table holds just what you'd expect it to, the sync table from the previous
# beat.
PreviousSync = {}

# Unit specific data that's been sync'd. Data changes are accumulated by merging
# the Sync.UnitData table into this table each sync (if there's new data)
UnitData = {}

# Here's an opportunity for user side script to examine the Sync table for the new tick
function OnSync()

    if Sync.RequestingExit then
        #LOG("Got it")
        ExitGame()
    end

    #Play Sounds
    for k, v in Sync.Sounds do
        PlaySound(Sound{ Bank=v.Bank, Cue=v.Cue })
    end

    if Sync.ToggleGamePanels then
        ConExecute('UI_ToggleGamePanels')
    end

    if Sync.ToggleLifeBarsOff then
        ConExecute('UI_RenderUnitBars false')
    end

    if Sync.ToggleLifeBarsOn then
        ConExecute('UI_RenderUnitBars true')
    end
	
	if not table.empty(Sync.AIChat) then
		for k, v in Sync.AIChat do
			import('/lua/AIChatSorian.lua').AIChat(v.group, v.text, v.sender)
		end
	end

    if Sync.UserConRequests then
        for num, execRequest in Sync.UserConRequests do
            ConExecute(execRequest)
        end
    end
    
    if not table.empty(Sync.UnitData) then
        UnitData = table.merged(UnitData,Sync.UnitData)
    end
    
    for id,v in Sync.ReleaseIds do
        UnitData[id] = nil
    end
end
