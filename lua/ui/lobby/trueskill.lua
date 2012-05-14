local matrix = require "matrix"


local Teams = {}
local Rating = {}
local Player = {}

Rating.__index = Rating
Player.__index = Player
Teams.__index = Teams

function Rating.create(mean, deviation)
 	local rtg = {}
	setmetatable(rtg,Rating)
	rtg.mean = mean
	rtg.deviation = deviation
	return rtg
end


function Rating:getMean()
   return self.mean
end

function Rating:getDeviation()
   return self.deviation
end


function Player.create(name, rating)
 	local play = {}
	setmetatable(play,Player)
	play.name = name
	play.rating = rating
	return play

end

function Player:getName()
	return self.name
end

function Player:getRating()
	return self.rating

end

function Teams.create(team, player)
 	local tm = {}
	setmetatable(tm,Teams)
	tm.players = {}
	tm.players[team] = {player}
	return tm
end

function Teams:addPlayer(team, player)

	if self.players[team] == nil then
		self.players[team] = {player}
	else
		table.insert(self.players[team], player)
 	end	
end

function Teams:getTeams()
	return self.players
end

function Teams:getTeam(num)
	local j = 0

	print ("getting " .. num)
	for i,v in ipairs(self.players) do

		if j == num then
			return v
		end
	j = j + 1
	end
	
end


local function make_list(size)
    	mylist = {}
    	for i=0,size do
        	mylist[i] = 0
	end
    
	return mylist
end


local function make_matrix(rows, cols)
    -- Create a 2D >matrix as a list of rows number of lists
    -- where the lists are cols in size
    -- resulting matrix contains zeros
 
    local mmatrix= {}
    for i =0,rows do
        mmatrix[i] = make_list(cols)
    end
    return mmatrix
end

local function DiagonalMatrix(diagonalValues)

	local diagonalCount = table.getn(diagonalValues)
	local mmatrix = make_matrix(diagonalCount,diagonalCount)
	
	for currentRow = 0,diagonalCount do
		for currentCol = 0, diagonalCount do
		
			if currentRow == currentCol then
				mmatrix[currentRow][currentCol] = diagonalValues[currentRow]
			end

		end 
	end
	
	return matrix:new(mmatrix)
	
end



local function Vector(vectorValues)
	local columnValues = {}

	for i,v in ipairs(vectorValues) do
		local list = {v}
		columnValues[i] = list
	end


	return matrix:new( columnValues )

end


local function fromColumnValues(rows, columns, columnValues)
	
	for i,v in ipairs(columnValues) do 
		for j,w in ipairs(v) do
			print(w)
		end 
	end	


       	result =  matrix (rows,columns)
	
	for currentColumn=1,columns do
		local currentColumnData = columnValues[currentColumn]
		
            
		for currentRow=1,rows do

			print (currentColumnData[currentRow])
			matrix.setelement(result, currentRow, currentColumn, currentColumnData[currentRow])

		end
	end


        return result

end

local function createPlayerTeamAssignmentMatrix(teamAssignmentsList, totalPlayers)

        -- The team assignment matrix is often referred to as the "A" matrix. It's a matrix whose rows represent the players
        -- and the columns represent teams. At Matrix[row, column] represents that player[row] is on team[col]
        -- Positive values represent an assignment and a negative value means that we subtract the value of the next
        -- team since we're dealing with pairs. This means that this matrix always has teams - 1 columns.
        -- The only other tricky thing is that values represent the play percentage.

        -- For example, consider a 3 team game where team1 is just player1, team 2 is player 2 and player 3, and
        -- team3 is just player 4. Furthermore, player 2 and player 3 on team 2 played 25% and 75% of the time
        -- (e.g. partial play), the A matrix would be:

        -- A = this 4x2 matrix:
        -- |  1.00  0.00 |
        -- | -0.25  0.25 |
        -- | -0.75  0.75 |
        -- |  0.00 -1.00 |


	playerAssignments = {}
        local totalPreviousPlayers = 0

	local teamAssignmentsListCount = table.getn(teamAssignmentsList:getTeams())
	

	local currentColumn = 1
	
	

  	for i =0,teamAssignmentsListCount-2 do
		

		local currentTeam = teamAssignmentsList:getTeam(i)


            -- Need to add in 0's for all the previous players, since they're not
            -- on this team
		local result = {}
             	if totalPreviousPlayers > 0 then
			for i=0, totalPreviousPlayers do
				table.insert(result,0)
				
			end

		end


		table.insert(playerAssignments, result)
		
		
		for i,currentPlayer in ipairs(currentTeam) do
			table.insert( playerAssignments[currentColumn], 1)
			totalPreviousPlayers = totalPreviousPlayers + 1
		end

		rowsRemaining = totalPlayers - totalPreviousPlayers
		

		local nextTeam =  teamAssignmentsList:getTeam(i + 1)


		for i,nextTeamPlayer in ipairs(nextTeam) do
			-- Add a -1 * playing time to represent the difference
			table.insert(playerAssignments[currentColumn], ( -1 * 1))
			rowsRemaining = rowsRemaining - 1
		end 



		for ixAdditionalRow=0,rowsRemaining do
			--Pad with zeros
			playerAssignments[currentColumn][ixAdditionalRow]= 0
		end

		currentColumn = currentColumn + 1

	end



	return fromColumnValues(totalPlayers, teamAssignmentsListCount - 1, playerAssignments)


end

--    // Helper function that gets a list of values for all player ratings

local function getPlayerRatingValues(teamAssignmentsList, playerRatingFunction)
        playerRatingValues = {}
        for i,currentTeam in ipairs(teamAssignmentsList:getTeams()) do 
            	for j,currentRating in ipairs(currentTeam) do
			if playerRatingFunction == "mean" then
				table.insert(playerRatingValues, currentRating:getRating():getMean()) 	
			else
				table.insert(playerRatingValues, currentRating:getRating():getDeviation() * currentRating:getRating():getDeviation())			
			end
	    	end

	end
	--for i,v in ipairs(playerRatingValues) do print(i,v) end
	
        return playerRatingValues

end



local function getPlayerCovarianceMatrix(teamAssignmentsList)


	return DiagonalMatrix(getPlayerRatingValues(teamAssignmentsList, "deviation"))

        -- This is a square matrix whose diagonal values represent the variance (square of standard deviation) of all
        -- players.
	
	--return DiagonalMatrix(self.getPlayerRatingValues(teamAssignmentsList, self.getRatingStandardDeviation))

end


local function getPlayerMeansVector(teamAssignmentsList)
	
        -- A simple vector of all the player means.
        return Vector(getPlayerRatingValues(teamAssignmentsList, "mean"))

end


player1 = Player.create("play1", Rating.create(1500,500))
player2 = Player.create("play2", Rating.create(1500,500))

player3 = Player.create("play3", Rating.create(1500,500))
player4 = Player.create("play4", Rating.create(1500,500))

--print (player1:getName())
--print (player1:getRating():getMean())

team =  Teams.create(1, player1)
--team:addPlayer(1, player2)
team:addPlayer(2, player2)
--team:addPlayer(2, player4)



local skillsMatrix = getPlayerCovarianceMatrix(team)
local meanVector = getPlayerMeansVector(team)

print (skillsMatrix)
print (meanVector)

local meanVectorTranspose = matrix.transpose(meanVector)

local playerTeamAssignmentsMatrix = createPlayerTeamAssignmentMatrix(team, matrix.rows(meanVector))
 

local  playerTeamAssignmentsMatrixTranspose = matrix.transpose(playerTeamAssignmentsMatrix)

local betaSquared = 250 * 250
local start = matrix.mul(meanVectorTranspose, playerTeamAssignmentsMatrix)
local aTa = matrix.mul(matrix.mulnum(playerTeamAssignmentsMatrixTranspose, betaSquared), playerTeamAssignmentsMatrix)
local aTSA =  matrix.mul((matrix.mul(playerTeamAssignmentsMatrixTranspose, skillsMatrix)), playerTeamAssignmentsMatrix)
local middle = matrix.add(aTa, aTSA)
local middleInverse = matrix.invert(middle)
local theend = matrix.mul(playerTeamAssignmentsMatrixTranspose, meanVector)
local expPartMatrix = matrix.mulnum((matrix.mul(matrix.mul(start, middleInverse), theend)), -0.5)
local expPart = matrix.det (expPartMatrix)

local sqrtPartNumerator = matrix.det(aTa)
local sqrtPartDenominator = matrix.det(middle)
local sqrtPart = sqrtPartNumerator / sqrtPartDenominator

local result = math.exp(expPart) * math.sqrt(sqrtPart)

print (result)