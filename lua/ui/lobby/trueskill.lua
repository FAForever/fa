Teams = {}
Rating = {}
Player = {}
Matrix = {}

Teams.__index = Teams
Rating.__index = Rating
Player.__index = Player
Matrix.__index = Matrix

-- Construct a list full of zeros of the given size.
local function make_list(size)
    local mylist = {}
    for i = 1, size do
        mylist[i] = 0
    end

    return mylist
end

-- Create a 2D >matrix as a list of rows number of lists
-- where the lists are cols in size
-- resulting matrix contains zeros
local function make_matrix(rows, cols)
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
    local transposeMatrix =  Matrix.create(self.columnCount, self.rowCount)

    for currentRowTransposeMatrix =1, self.columnCount do
        for currentColumnTransposeMatrix=1,self.rowCount do
            transposeMatrix.matrix[currentRowTransposeMatrix][currentColumnTransposeMatrix] = self.matrix[currentColumnTransposeMatrix][currentRowTransposeMatrix]
        end
    end

    return transposeMatrix
 end

function Matrix:getMinorMatrix(rowToRemove, columnToRemove)
    local result = Matrix.create(self.rowCount - 1, self.columnCount - 1)

    local actualRow = 1
    local doNotIncrement = 0
    for currentRow=1,self.rowCount do
        if not (currentRow == rowToRemove) then
            local actualCol = 1
            table.insert(result.matrix, actualRow, {})
            for currentColumn=1, self.columnCount do
                table.insert(result.matrix[actualRow],actualCol,0)
                if not currentColumn == columnToRemove then
                    doNotIncrement = 0
                    result.matrix[actualRow][actualCol] = self.matrix[currentRow][currentColumn]
                    actualCol = actualCol + 1
                else
                    doNotIncrement = 1
                end
            end

            if doNotIncrement == 0 then
                actualRow = actualRow + 1
            end
        end
    end

    return result
end

function Matrix:getCofactor(rowToRemove, columnToRemove)
    local sum = rowToRemove + columnToRemove

    local modulo = sum - math.floor(sum/2)*2
    if modulo == 0 then
        return self:getMinorMatrix(rowToRemove, columnToRemove):getDeterminant()
    else
        local matrix = self:getMinorMatrix(rowToRemove, columnToRemove)
        return -1.0* matrix:getDeterminant()
    end
end

function  Matrix:getDeterminant()
    if self.rowCount == 1 then
        return self.matrix[1][1]
    end

    if self.rowCount == 2 then
        local a = self.matrix[1][1]
        local  b = self.matrix[1][2]
        local c = self.matrix[2][1]
        local d = self.matrix[2][2]
        return a*d - b*c
    end

    local value = 0

    for currentColumn = 1,self.columnCount do
        local firstRowColValue =  self.matrix[1][currentColumn]
        local cofact = self:getCofactor(1, currentColumn)
        value = value + firstRowColValue * cofact
    end

    return value
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

--- Create an empty Teams object
function Teams.create()
    local tm = {}
    setmetatable(tm,Teams)
    -- Maps team numbers to lists of Players.
    tm.teams = {}
    return tm
end

function Teams:addPlayer(team, player)
    if self.teams[team] == nil then
        self.teams[team] = {player}
    else
        table.insert(self.teams[team], player)
    end
end

function Teams:getTeams()
    return self.teams
end

function Teams:getTeam(num)
    return self.teams[num]
end

local function DiagonalMatrix(diagonalValues)
    local diagonalCount = table.getn(diagonalValues)

    local mmatrix = Matrix.create(diagonalCount,diagonalCount)
    for currentRow = 1, diagonalCount do
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
    local vector = Matrix.create(table.getn(vectorValues), 1)
    for i, v in ipairs(vectorValues) do
        vector.matrix[i][1] =  v
    end

    return vector
end

local function fromColumnValues(rows, columns, columnValues)
    local result =  Matrix.create(rows,columns)
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


    local playerAssignments = {}
    local totalPreviousPlayers = 0

    local teamAssignmentsListCount = table.getn(teamAssignmentsList:getTeams())

    local currentColumn = 1

    for i = 1, teamAssignmentsListCount - 1 do
        local currentTeam = teamAssignmentsList:getTeam(i)

        -- Need to add in 0's for all the previous players, since they're not
        -- on this team
        local result = {}
        if totalPreviousPlayers > 0 then
            for k=1, totalPreviousPlayers do
                table.insert(result,0)
            end
        end

        table.insert(playerAssignments, currentColumn, result)
        for _, currentPlayer in ipairs(currentTeam) do
            table.insert(playerAssignments[currentColumn], 1)
            totalPreviousPlayers = totalPreviousPlayers + 1
        end

        local rowsRemaining = totalPlayers - totalPreviousPlayers
        local nextTeam =  teamAssignmentsList:getTeam(i+1)

        if nextTeam then
            for _,nextTeamPlayer in ipairs(nextTeam) do
                -- Add a -1 * playing time to represent the difference
                table.insert(playerAssignments[currentColumn], (-1 * 1))
                rowsRemaining = rowsRemaining - 1
            end
        end

        for ixAdditionalRow=1, rowsRemaining do
            --Pad with zeros
            table.insert(playerAssignments[currentColumn], 0)
        end

        currentColumn = currentColumn + 1
    end

    return fromColumnValues(totalPlayers, teamAssignmentsListCount-1 , playerAssignments)
end

-- Helper function that gets a list of values for all player ratings
local function getPlayerRatingValues(teamAssignmentsList, playerRatingFunction)
    local hop = 1
    local playerRatingValues = {}
    for i,currentTeam in ipairs(teamAssignmentsList:getTeams()) do
        for j,currentRating in ipairs(currentTeam) do
            if playerRatingFunction == "mean" then
                table.insert(playerRatingValues, currentRating:getRating():getMean())
                hop = hop + 1
            else
                table.insert(playerRatingValues, currentRating:getRating():getDeviation() * currentRating:getRating():getDeviation())
                hop = hop + 1
            end
        end
    end

    return playerRatingValues
end

-- This is a square matrix whose diagonal values represent the variance (square of standard deviation) of all
-- players.
local function getPlayerCovarianceMatrix(teamAssignmentsList)
    return DiagonalMatrix(getPlayerRatingValues(teamAssignmentsList, "deviation"))
end

local function getPlayerMeansVector(teamAssignmentsList)
    -- A simple vector of all the player means.
    return Vector(getPlayerRatingValues(teamAssignmentsList, "mean"))
end

local function matrixmult(left, right)
    local resultRows = left.rowCount
    local resultColumns = right.columnCount

    local resultMatrix = Matrix.create(resultRows, resultColumns)
    for currentRow=1, resultRows do
        for currentColumn=1, resultColumns do
            local productValue = 0
            for vectorIndex = 1,left.columnCount do
                local leftValue = left.matrix[currentRow][vectorIndex]
                local rightValue = right.matrix[vectorIndex][currentColumn]
                local vectorIndexProduct = leftValue * rightValue
                productValue = productValue + vectorIndexProduct
            end

            resultMatrix.matrix[currentRow][currentColumn] = productValue
        end
    end

    return resultMatrix
end

local function scalarMultiply(mtx, scalarValue)
    local rows = mtx.rowCount
    local columns = mtx.columnCount
    local newValues = Matrix.create(rows, columns)

    for currentRow=1, rows do
        for currentColumn=1,columns do
            newValues.matrix[currentRow][currentColumn] = scalarValue*mtx.matrix[currentRow][currentColumn]
        end
    end

    return newValues
end

local function getAdjugate(mtx)
    if (mtx.rowCount == 2) then
        local a = mtx.matrix[1][1]
        local b = mtx.matrix[1][2]
        local c = mtx.matrix[2][1]
        local d = mtx.matrix[2][2]
        local allValues = {a, b, c, d}
        local rows = 2
        local cols = 2
        local matrixData = Matrix.create(rows, cols)
        local allValuesIndex = 1
        for currentRow=1,rows do
            for currentColumn=1,cols do
                matrixData.matrix[currentRow][currentColumn] = allValues[allValuesIndex]
                allValuesIndex  = allValuesIndex + 1
            end
        end

        return matrixData
    end

    -- The idea is that it's the transpose of the cofactors
    local mtresult = Matrix.create(mtx.columnCount, mtx.rowCount)

    for currentColumn=1, mtx.columnCount do
        for currentRow=1, mtx.rowCount do
            mtresult.matrix[currentColumn][currentRow] = mtx:getCofactor(currentRow, currentColumn)
        end
    end

    return mtresult
end

local function matrixInvert(mtx)
    if mtx.rowCount == 1 and mtx.columnCount == 1 then
        local result = Matrix.create(1,1)
        result.matrix[1][1] = 1.0/mtx.matrix[1][1]
        return result
    end

    local determinantInverse = 1.0 / mtx:getDeterminant()
    local adjugate = getAdjugate(mtx)
    return scalarMultiply(adjugate, determinantInverse)
end


local function matrixAdd(left, right)
    local resultMatrix = Matrix.create(left.rowCount, right.columnCount)

    for currentRow=1,left.rowCount do
        for currentColumn=1, right.columnCount do
            resultMatrix.matrix[currentRow][currentColumn] = left.matrix[currentRow][currentColumn] + right.matrix[currentRow][currentColumn]
        end
    end

    return resultMatrix
end

function assignToTeam(num)
    -- return the team of the player based on his place/rating
    local even = 0
    while num>0 do
        local rest = math.mod(num, 2)
        if rest == 1 then
            even = even + 1
        end

        num = (num - rest) / 2
    end

    if math.mod(even, 2) == 0 then
        return 1
    else
        return 2
    end
end

function round(num, idp)
    local mult = math.pow(10, (idp or 0))
    return math.floor(num * mult + 0.5) / mult
end

function round2(num)
    return math.floor(num + 0.5)
end

function computeQuality(team)

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

    if middle:getDeterminant() == 0 then return -1 end

    local middleInverse = matrixInvert(middle)

    local theend = matrixmult(playerTeamAssignmentsMatrixTranspose, meanVector)
    local part1 = matrixmult(start, middleInverse)
    local part2 = matrixmult(part1, theend)
    local expPartMatrix = scalarMultiply(part2, -0.5)
    local expPart = expPartMatrix:getDeterminant()

    local sqrtPartNumerator = aTa:getDeterminant()
    local sqrtPartDenominator = middle:getDeterminant()
    local sqrtPart = sqrtPartNumerator / sqrtPartDenominator


    local result = math.exp(expPart) * math.sqrt(sqrtPart)
    return round((result * 100), 2)
end
