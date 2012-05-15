	
local Teams = {}
local Rating = {}
local Player = {}
local Matrix = {}


Teams.__index = Teams
Rating.__index = Rating
Player.__index = Player
Matrix.__index = Matrix

local function make_list(size)
    	mylist = {}
    	for i=1,size do

        	mylist[i] = 0
	end
    
	return mylist
end


local function make_matrix(rows, cols)
    -- Create a 2D >matrix as a list of rows number of lists
    -- where the lists are cols in size
    -- resulting matrix contains zeros
 
    local mmatrix= {}
    for i =1,rows do

        mmatrix[i] = make_list(cols)
    end
    return mmatrix
end


function Matrix.create(rows, colums)
 	local mtx = {}
	setmetatable(mtx,Matrix)
	mtx.rowCount = rows
	mtx.columnCount = colums
	mtx.matrix = make_matrix(rows, colums)
	return mtx
end


function Matrix:transpose()
	transposeMatrix =  Matrix.create(self.columnCount, self.rowCount)
	
	for currentRowTransposeMatrix =1,self.columnCount do
		for currentColumnTransposeMatrix=1,self.rowCount do
			transposeMatrix.matrix[currentRowTransposeMatrix][currentColumnTransposeMatrix] = self.matrix[currentColumnTransposeMatrix][currentRowTransposeMatrix]
		end
	end

	return transposeMatrix
	
	
end

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

	for i,v in ipairs(self.players) do

		if j == num then
			return v
		end
	j = j + 1
	end
	
end




local function DiagonalMatrix(diagonalValues)

	local diagonalCount = table.getn(diagonalValues)
	
	
	

	local mmatrix = Matrix.create(diagonalCount,diagonalCount)
	
	for currentRow = 1,diagonalCount do
		for currentCol = 1, diagonalCount do
			if currentRow == currentCol then
				mmatrix.matrix[currentRow][currentCol] = diagonalValues[currentRow]
			end

		end 
	end
	
	return mmatrix
	
end



local function Vector(vectorValues)
	local columnValues = {}
	local vector = Matrix.create(table.getn(vectorValues),1)
	
	for i,v in ipairs(vectorValues) do
		vector.matrix[i][1] =  v
		
	end

	
	
	return vector

end


local function fromColumnValues(rows, columns, columnValues)
	
	for i,v in ipairs(columnValues) do 
		for j,w in ipairs(v) do

		end 
	end	


       	result =  Matrix.create(rows,columns)
	
	for currentColumn=1,columns do
		local currentColumnData = columnValues[currentColumn]
		
            
		for currentRow=1,rows do

			result.matrix[currentRow][currentColumn] = currentColumnData[currentRow]

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

local function matrixmult(left, right)


	resultRows = left.rowCount
	resultColumns = right.columnCount

	
	resultMatrix = Matrix.create(resultRows, resultColumns)
	
	for currentRow=1, resultRows do
		for currentColumn=1, resultColumns do
			
			productValue = 0
			for vectorIndex = 1,left.columnCount do 
			
				leftValue = left.matrix[currentRow][vectorIndex]
				rightValue = right.matrix[vectorIndex][currentColumn]
				
				
				
				vectorIndexProduct = leftValue*rightValue
				productValue = productValue + vectorIndexProduct
				
			end
			
			resultMatrix.matrix[currentRow][currentColumn] = productValue
			
		end
	end
	
	return resultMatrix
end

local function scalarMultiply(mtx, scalarValue)

        rows = mtx.rowCount
        columns = mtx.columnCount
        newValues = Matrix.create(rows, columns)

        for currentRow=1, rows do
            for currentColumn=1,columns do
                newValues.matrix[currentRow][currentColumn] = scalarValue*mtx.matrix[currentRow][currentColumn]
			end
		end

        return newValues

end

local function getMinorMatrix(mtx, rowToRemove, columnToRemove) 

	result = {}
	actualRow = 0

	for currentRow=1,mtx.rowCount do

		if not currentRow == rowToRemove then

		actualCol = 0
			table.insert(result, actualRow, {})
			
			for currentColumn=1, mtx.columnCount do

				table.insert(result[actualRow],actualCol,0)
				if not currentColumn == columnToRemove then

					result[actualRow][actualCol] = mtx.matrix[currentRow][currentColumn]

					actualCol = actualCol + 1

					actualRow = actualRow + 1 
				end
			end
		end
		
	end
	
	val = Matrix.create(mtx.rowCount - 1, mtx.columnCount - 1)
	val.matrix =  result
	
	return val

end


local function getCofactor(mtx, rowToRemove, columnToRemove) 
        
        sum = rowToRemove + columnToRemove

		local modulo = sum - math.floor(sum/2)*2
		
		if modulo == 0 then
            return mtx.getMinorMatrix(rowToRemove, columnToRemove).getDeterminant()
			
        else 
            return -1.0* mtx.getMinorMatrix(rowToRemove, columnToRemove).getDeterminant()
		end
			
end
			
local function getDeterminant(mtx)
	if mtx.rowCount == 1 then
		return mtx.matrix[1][1]
	end
	
	if mtx.rowCount == 2 then
		a = mtx.matrix[1][1]
		b = mtx.matrix[1][2]
		c = mtx.matrix[2][1]
		d = mtx.matrix[2][2]
		return a*d - b*c
	end
	
	result = 0.0


	for currentColumn=1, mtx.columnCount do
		firstRowColValue =  mtx.matrix[1][currentColumn]
		cofactor = self.getCofactor(0, currentColumn)
		itemToAdd = firstRowColValue*cofactor
		result = result + itemToAdd
	end
	
	return result
	
end



local function getAdjugate(mtx)

	if (mtx.rowCount == 2) then
	        a = mtx.matrix[0][0]
            b = mtx.matrix[0][1]
            c = mtx.matrix[1][0]
            d = mtx.matrix[1][1]
			
			allValues = {a,b,c,d}
			
			rows = 2
			cols = 2
			
			matrixData = Matrix.create(rows, cols)
			allValuesIndex = 1
			for currentRow=1,rows do
				for currentColumn=1,cols do
					 matrixData.matrix[currentRow][currentColumn] = allValues[allValuesIndex]
					 allValuesIndex  = allValuesIndex + 1
				end
			end
			
			return matrixData
	end

end

local function matrixInvert(mtx)


        if mtx.rowCount == 1 and mtx.columnCount == 1 then
			result = Matrix.create(1,1)
			result.matrix[1][1] = 1.0/mtx.matrix[1][1]
			return result

		
		end
        
		determinantInverse = 1.0 / getDeterminant(mtx)
        adjugate = mtx.getAdjugate()

		return scalarMultiply(determinantInverse, adjugate)
		
end


local function matrixAdd(left, right)

	resultMatrix = Matrix.create(left.rowCount, right.columnCount)

	 for currentRow=1,left.rowCount do
		 for currentColumn=1, right.columnCount do
			resultMatrix.matrix[currentRow][currentColumn] = left.matrix[currentRow][currentColumn] + right.matrix[currentRow][currentColumn]
		 
		 
		 end
	end
	
	return resultMatrix

end

function testTs()

player1 = Player.create("play1", Rating.create(1500,500))
player2 = Player.create("play2", Rating.create(1500,500))

player3 = Player.create("play3", Rating.create(1500,500))
player4 = Player.create("play4", Rating.create(1500,500))

--print (player1:getName())
--print (player1:getRating():getMean())

team =  Teams.create(1, player1)
team:addPlayer(1, player2)
team:addPlayer(2, player2)
team:addPlayer(2, player4)



local skillsMatrix = getPlayerCovarianceMatrix(team)
local meanVector = getPlayerMeansVector(team)

local meanVectorTranspose = meanVector:transpose()

local playerTeamAssignmentsMatrix = createPlayerTeamAssignmentMatrix(team, meanVector.rowCount)
 
local  playerTeamAssignmentsMatrixTranspose = playerTeamAssignmentsMatrix:transpose()

local betaSquared = 250 * 250
local start = matrixmult(meanVectorTranspose, playerTeamAssignmentsMatrix)
local aTa = matrixmult(scalarMultiply(playerTeamAssignmentsMatrixTranspose, betaSquared), playerTeamAssignmentsMatrix)
local tmp = matrixmult(playerTeamAssignmentsMatrixTranspose, skillsMatrix)
local aTSA =  matrixmult(tmp, playerTeamAssignmentsMatrix)
local middle = matrixAdd(aTa, aTSA)
local middleInverse = matrixInvert(middle)
local theend = matrixmult(playerTeamAssignmentsMatrixTranspose, meanVector)
local expPartMatrix = scalarMultiply((matrixmult(matrixmult(start, middleInverse), theend)), -0.5)
local expPart = getDeterminant(expPartMatrix)

local sqrtPartNumerator = getDeterminant(aTa)
local sqrtPartDenominator = getDeterminant(middle)
local sqrtPart = sqrtPartNumerator / sqrtPartDenominator

local result = math.exp(expPart) * math.sqrt(sqrtPart)

	LOG ("result " .. result)
	
end