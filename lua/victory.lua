gameOver = false

local victoryCategories = {
    demoralization=categories.COMMAND,
    domination=categories.STRUCTURE + categories.ENGINEER - categories.WALL,
    eradication=categories.ALLUNITS - categories.WALL,
}

function AllUnitsInCategoryDead(brain,categoryCheck)
    local ListOfUnits = brain:GetListOfUnits(categoryCheck, false)
    for index, unit in ListOfUnits do
        if unit.CanBeKilled and not unit.Dead and unit:GetFractionComplete() == 1 then
            return false
        end
    end
    return true
end

function ObserverAfterDeath(armyIndex)
    if not ScenarioInfo.Options.AllowObservers then return end
    local humans = {}
    local humanIndex = 0
    for i, data in ArmyBrains do
        if data.BrainType == 'Human' then
            if IsAlly(armyIndex, i) then
                if not ArmyIsOutOfGame(i) then
                    return
                end
                table.insert(humans, humanIndex)
            end
            humanIndex = humanIndex + 1
        end
    end

    for _, index in humans do
        for i in ArmyBrains do
            SetCommandSource(i - 1, index, false)
        end
    end
end

function CallEndGame()
    gameOver = true
    ForkThread(function()
        WaitSeconds(2.9)
        for _, v in GameOverListeners do
            v()
        end
        Sync.GameEnded = true
        WaitSeconds(0.1)
        EndGame()
    end)
end

function CheckVictory(scenarioInfo)
    local categoryCheck = victoryCategories[scenarioInfo.Options.Victory]
    if not categoryCheck then return end

    -- tick number we are going to issue a victory on.  Or nil if we are not.
    local victoryTime = nil
    local potentialWinners = {}

    while true do
        -- Look for newly defeated brains and tell them they're dead
        local stillAlive = {}
        for _, brain in ArmyBrains do
            if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
                if AllUnitsInCategoryDead(brain,categoryCheck) then
                    brain:OnDefeat()
                    ObserverAfterDeath(brain:GetArmyIndex())
                else
                    table.insert(stillAlive, brain)
                end
            end
        end

        -- uh-oh, there is nobody alive... It's a draw.
        if table.empty(stillAlive) then
            CallEndGame()
            return
        end

        -- check to see if everyone still alive is allied and is requesting an allied victory.
        local win = true
        local draw = true
        for i, brain in stillAlive do
            if not brain.OfferingDraw then
                draw = false
            end

            if not (draw or win) then break end

            for j, other in stillAlive do
                if i ~= j then
                    if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
                        win = false
                        break
                    end
                end
            end
        end

        local callback = nil
        if win then
            local equal = table.equal(stillAlive, potentialWinners)
            if not equal then
                victoryTime = GetGameTimeSeconds() + 5
                potentialWinners = stillAlive
            end

            if equal and GetGameTimeSeconds() >= victoryTime then
                callback = 'OnVictory'
            end
        elseif draw then
            callback = 'OnDraw'
        else
            victoryTime = nil
            potentialWinners = {}
        end

        if callback then
            for _, brain in stillAlive do
                brain[callback](brain)
            end

            CallEndGame()
            return
        end

        WaitSeconds(3)
    end
end