--NOTE may need to run in a new thread
local Trueskill = import('/lua/ui/lobby/trueskill.lua')
local Player = import('/lua/ui/lobby/trueskill.lua').Player
local Rating = import('/lua/ui/lobby/trueskill.lua').Rating
local Teams = import('/lua/ui/lobby/trueskill.lua').Teams
local gameInfo = false
local countRun = 0
local lastScore = 0 -- the last computeQuality
local fairestTeam = nil
	function f_mutate(playerArray,arrayStart,arrayEnd)
	
		countRun = countRun + 1
		if countRun > 100000 then LOG("Max")return end
		local currentComputeQuality = 0 --the computeQuality for this calculation
		local teams = nil --reset the teams
		if arrayStart == arrayEnd then 	
			teams = Teams.create() -- create new teams	
			local currentPosition = arrayEnd --update array position
			for i = 0, currentPosition do
				if i < (currentPosition * 0.5) then -- sort players into teams
					teams:addPlayer(1, playerArray[i]) -- team 1
				else
					teams:addPlayer(2, playerArray[i]) -- team 2
				end	--else
			end --for
			local currentComputeQuality = Trueskill.computeQuality(teams) --get current Compute Quality from Trueskill
			if currentComputeQuality > lastScore then -- check if the current Quality is better then the last Quality
				lastScore = currentComputeQuality --update new Quality
				fairestTeam = teams --set the fairest team
				LOG("UPDATE SCORE ".. lastScore)	
			end --if
			return
		end --end if
		
		for k = arrayStart, arrayEnd do
			if countRun > 100000 then break end
			if currentComputeQuality == 100 then return end --if a perfect balance has been found stop calculation
			--reposition the players in the playerArray
			local tempArray = playerArray[arrayStart]
			playerArray[arrayStart] = playerArray[k]
			playerArray[k] = tempArray
			f_mutate(playerArray, arrayStart + 1, arrayEnd) --calculate 
			--reposition the players in the playerArray
			tempArray = playerArray[arrayStart]
			playerArray[arrayStart] = playerArray[k]
			playerArray[k] = tempArray		
		end
	end
	
function f_fairestTeam(players)
	countRun = 0
	local playerArray = {} -- human players
	local arrayStart = 0; --start position of the player array
	local arrayEnd = 0; --the length of the player array
	--local fairestTeam = nil -- the teams with the highest computeQuality
	local getVal = 0
	local pLength = players -1
		for i = 0, pLength do --adding players to the player array
			--if gameInfo.PlayerOptions[i].Human then --check if player is human
				local playerInfo = gameInfo.PlayerOptions[i]
				local ran1 = math.random(1000,2000)
				local ran2 = math.random(1,500)
				LOG("ran1 ".. ran1)
				LOG("ran2 ".. ran2)
				local player = Player.create(playerInfo.PlayerName,Rating.create(ran1, ran2))
				playerArray[i]= player					 
		end --for
	f_mutate(playerArray,arrayStart,players)
	
	--LOG("team " .. fairestTeam)
--	local co = coroutine.create(function ()
--             f_mutate(playerArray,arrayStart,players)
--             coroutine.yield()
--         end)

end --f_fairestTeam

--fairestTeam now holds the fairestTeam
--The GUI now needs to be updated
