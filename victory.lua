
function CheckVictory(scenarioInfo)

    local categoryCheck = nil
    if scenarioInfo.Options.Victory == 'demoralization' then
        # You're dead if you have no commanders
        categoryCheck = categories.COMMAND
    elseif scenarioInfo.Options.Victory == 'domination' then
        # You're dead if all structures and engineers are destroyed
        categoryCheck = categories.STRUCTURE + categories.ENGINEER - categories.WALL
    elseif scenarioInfo.Options.Victory == 'eradication' then
        # You're dead if you have no units
        categoryCheck = categories.ALLUNITS - categories.WALL
    else
        # no victory condition
        return
    end

    # tick number we are going to issue a victory on.  Or nil if we are not.
    local victoryTime = nil
    local potentialWinners = {}

    while true do

        # Look for newly defeated brains and tell them they're dead
        local stillAlive = {}
        for index,brain in ArmyBrains do
            if not brain:IsDefeated() and not ArmyIsCivilian(brain:GetArmyIndex()) then
                if brain:GetCurrentUnits(categoryCheck) == 0 then
                    brain:OnDefeat()
                    CallEndGame(false, true)
                else
                    table.insert(stillAlive, brain)
                end
            end
        end

        # uh-oh, there is nobody alive... It's a draw.
        if table.empty(stillAlive) then
            CallEndGame(true, false)
            return
        end

        # check to see if everyone still alive is allied and is requesting an allied victory.
        local win = true
        local draw = true
        for index,brain in stillAlive do
            for index2,other in stillAlive do
                if index != index2 then
                    if not brain.RequestingAlliedVictory or not IsAlly(brain:GetArmyIndex(), other:GetArmyIndex()) then
                        win = false
                    end
                end
            end
            if not brain.OfferingDraw then
                draw = false
            end
        end

        if win then
            if table.equal(stillAlive, potentialWinners) then
                if GetGameTimeSeconds() > victoryTime then
                    # It's a win!
                    for index,brain in stillAlive do
                        brain:OnVictory()
                    end
                    CallEndGame(true, true)
                    return
                end
            else
                victoryTime = GetGameTimeSeconds() + 5
                potentialWinners = stillAlive
            end
        elseif draw then
            for index,brain in stillAlive do
                brain:OnDraw()
            end
            CallEndGame(true, true)
            return
        else
            victoryTime = nil
            potentialWinners = {}
        end

        WaitSeconds(3.0)
    end
end

function CallEndGame(callEndGame, submitXMLStats)
    if submitXMLStats then
        SubmitXMLArmyStats()
    end
    if callEndGame then
        gameOver = true
        ForkThread(function()
            WaitSeconds(3)
            EndGame()
        end)
    end
end

gameOver = false