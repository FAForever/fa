
--*****************************************************************************
--* File: lua/modules/ui/game/gameresult.lua
--* Summary: Victory and Defeat behavior
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local OtherArmyResultStrings = {
    victory = '<LOC usersync_0001>%s wins!',
    defeat = '<LOC usersync_0002>%s has been defeated!',
    draw = '<LOC usersync_0003>%s receives a draw.',
    gameOver = '<LOC usersync_0004>Game Over.',
}

local MyArmyResultStrings = {
    victory = "<LOC GAMERESULT_0000>Victory!",
    defeat = "<LOC GAMERESULT_0001>You have been defeated!",
    draw = "<LOC GAMERESULT_0002>It's a draw.",
    replay = "<LOC GAMERESULT_0003>Replay Finished.",
}

function OnReplayEnd()
    import('/lua/ui/game/tabs.lua').TabAnnouncement('main', LOC(MyArmyResultStrings.replay))
    import('/lua/ui/game/tabs.lua').AddModeText("<LOC _Score>", function() import('/lua/ui/dialogs/score.lua').CreateDialog(true) end)
end

local announced = {}

function DoGameResult(armyIndex, result)

	LOG("GAMERESULT : ", result)
    local condPos = string.find(result, " ")
	if condPos != 0 then
		result = string.sub(result, 1, condPos - 1)
	end

	if result != 'score' then
	
		if not announced[armyIndex] then
			if armyIndex == GetFocusArmy() then
				local armies = GetArmiesTable().armiesTable
				if result == 'defeat' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
				elseif result == 'victory' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
				elseif result == 'draw' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
				end
			else
				local armies = GetArmiesTable().armiesTable
				if result == 'defeat' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Loser=armies[armyIndex].nickname},} , true)
				elseif result == 'victory' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Winner=armies[armyIndex].nickname},} , true)
				elseif result == 'draw' then
					SimCallback({Func="GiveResourcesToPlayer", Args={ From=GetFocusArmy(), To=GetFocusArmy(), Mass=0, Energy=0, Draw=armies[armyIndex].nickname},} , true)
				end
			end

			announced[armyIndex] = true
			if armyIndex == GetFocusArmy() then
				if SessionIsObservingAllowed() then
					SetFocusArmy(-1)
				end
				
				if result == 'victory' then
					PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Victory'}))
				else
					PlaySound(Sound({Bank = 'Interface', Cue = 'UI_END_Game_Fail'}))
				end
				
				local victory = true
				if result == 'defeat' then
					victory = false
				end

                local tabs = import('/lua/ui/game/tabs.lua')
				tabs.OnGameOver()
				tabs.TabAnnouncement('main', LOC(MyArmyResultStrings[result]))


                local score = import('/lua/ui/dialogs/score.lua')
                tabs.AddModeText("<LOC _Score>", function()
                        UIUtil.QuickDialog(GetFrame(0),
                            "<LOC EXITDLG_0003>Are you sure you'd like to exit?",
                            "<LOC _Yes>", function()
                                score.CreateDialog(victory)
                            end,
                            "<LOC _No>", nil,
                            nil, nil,
                            true,
                            {escapeButton = 2, enterButton = 1, worldCover = true})
                end)


			else
				local armies = GetArmiesTable().armiesTable
				import('/lua/ui/game/score.lua').ArmyAnnounce(armyIndex, LOCF(OtherArmyResultStrings[result], armies[armyIndex].nickname))
			end
		end
	end
end