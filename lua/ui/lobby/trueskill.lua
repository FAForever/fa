local Matrix = import('/lua/shared/matrix.lua')

Teams = {}
Rating = {}
Player = {}

Teams.__index = Teams
Rating.__index = Rating
Player.__index = Player

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

    return Matrix.CopyTranspose(playerAssignments, totalPlayers, teamAssignmentsListCount - 1)
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
    return Matrix.Diagonal(getPlayerRatingValues(teamAssignmentsList, "deviation"))
end

local function getPlayerMeansVector(teamAssignmentsList)
    -- A simple vector of all the player means.
    return Matrix.Vector(getPlayerRatingValues(teamAssignmentsList, "mean"))
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
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function round2(num)
    return math.floor(num + 0.5)
end

function computeQuality(team)
    local skillsMatrix = getPlayerCovarianceMatrix(team)
    local meanVector = getPlayerMeansVector(team)
    local meanVectorTranspose = meanVector:transpose()
    local playerTeamAssignmentsMatrix = createPlayerTeamAssignmentMatrix(team, meanVector.rows)
    local playerTeamAssignmentsMatrixTranspose = playerTeamAssignmentsMatrix:transpose()

    local betaSquared = 250 * 250
    local start = meanVectorTranspose:Mult(playerTeamAssignmentsMatrix)
    local aTa = playerTeamAssignmentsMatrixTranspose:Scale(betaSquared):Mult(playerTeamAssignmentsMatrix)
    local tmp = playerTeamAssignmentsMatrixTranspose:Mult(skillsMatrix)
    local aTSA = tmp:Mult(playerTeamAssignmentsMatrix)
    local middle = aTa:Add(aTSA)

    local middleInverse = middle:Inverse()
    if not middleInverse then
        return -1
    end

    local theend = playerTeamAssignmentsMatrixTranspose:Mult(meanVector)
    local part1 = start:Mult(middleInverse)
    local part2 = part1:Mult(theend)
    local expPartMatrix = part2:Scale(-0.5)
    local expPart = expPartMatrix:Determinant()

    local sqrtPartNumerator = aTa:Determinant()
    local sqrtPartDenominator = middle:Determinant()
    local sqrtPart = sqrtPartNumerator / sqrtPartDenominator


    local result = math.exp(expPart) * math.sqrt(sqrtPart)
    return round(result * 100, 2)
end
