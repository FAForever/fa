--need a button for f_fairestTeam()
--NOTE may need to run in a new thread
local Trueskill = import('/lua/ui/lobby/trueskill.lua')
function f_fairestTeam()
	local playerArray = {} -- human players
	local arrayStart = 0; --start position of the player array
	local arrayEnd = 0; --the length of the player array
	local fairestTeam = nil -- the teams with the highest computeQuality
	local players = GetPlayerCount() + 1 -- number of players
	local lastScore = 0 -- the last computeQuality
		for i = 0, players do --adding players to the player array
			if gameInfo.PlayerOptions[i].Human then --check if player is human
				playerArray[i] = gameInfo.PlayerOptions[i] --add player options to playerArray
			end --if
		end --for
	f_mutate(playerArray,arrayStart,i,lastScore)
	
	function f_mutate(playerArray,arrayStart,arrayEnd,lastScore)
		local currentComputeQuality = 0 --the computeQuality for this calculation
		if arrayStart == arrayEnd then 
			local teams = nil --reset the teams
			teams = Teams.create() -- create new teams	
			local currentPosition = arrayEnd + 1 --update array position
			for i = 0, currentPosition do
				if i < (currentPosition * 0.5) then -- sort players into teams
					teams:addPlayer(0, playerArray[i]) -- team 1
				else
					teams:addPlayer(1, playerArray[i]) -- team 2
				end	--else
			end --for
			
			local currentComputeQuality = Trueskill.computeQuality(teams) --get current Compute Quality from Trueskill
			if currentComputeQuality > lastScore then -- check if the current Quality is better then the last Quality
				lastScore = currentComputeQuality --update new Quality
				fairestTeam = teams --set the fairest team
			end --if
			return
		end --end if

		for k = start, arrayEnd do
			if currentComputeQuality == 100 then return end --if a perfect balance has been found stop calculation
			--reposition the players in the playerArray
			local tempArray = playerArray[start]
			playerArray[start] = playerArray[k]
			playerArray[k] = tempArray
			f_mutate(playerArray, start + 1, arrayEnd) --calculate 
			--reposition the players in the playerArray
			tempArray = playerArray[start]
			playerArray[start] = playerArray[k]
			playerArray[k] = tempArray
		end
	end
end --f_fairestTeam
--fairestTeam now holds the fairestTeam
--The GUI now needs to be updated
