
local Conditions = {
    demoralization = categories.COMMAND,
    domination = categories.STRUCTURE + categories.ENGINEER - categories.WALL,
    eradication = categories.ALLUNITS - categories.WALL,
}

--- Ends the game
function CallEndGame()
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

--- Finds and collectors the brains that are defeated
---@param aliveBrains AIBrain[] # Table of brains that are relevant to check for defeat
---@param condition Categories  # Categories to check for units that are required to remain in the game
---@param delay number          # Delay between each brain to spread the load over various ticks
---@return AIBrain[]            # Table of brains that are considered defeated, can be empty
local function CollectDefeatedBrains(aliveBrains, condition, delay)
    local defeatedBrains = { }
    for k, brain in aliveBrains do

        local criticalUnits = brain:GetListOfUnits(brain, condition)
        if criticalUnits then 
            for k, unit in criticalUnits do 
                if not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                    defeatedBrains[k] = brain 
                    break
                end
            end
        end

        WaitTicks(delay)
    end

    return defeatedBrains
end

--- Determines observer behavior after an army is defeated
---@param armyIndex number
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

--- Continiously scans the game for brains being defeated or changes in alliances that can cause the game to end
local function MatchStateThread()

    -- determine game conditions
    local condition = Conditions[ScenarioInfo.Options.Victory]
    if not condition and not (ScenarioInfo.Options.Victory == 'sandbox') then
        SPEW("Unknown victory condition supplied: " .. ScenarioInfo.Options.Victory .. ", victory condition defaults to sandbox.")
        return
    end

    -- consider all non-civilian brains to be alive and kicking
    local aliveBrains = { }
    for k, brain in ArmyBrains do
        local index = brain:GetArmyIndex()
        if not ArmyIsCivilian(index) then
            aliveBrains[index] = brain
        end
    end

    -- keep scanning the gamestate for changes in alliances and brain state
    while true do

        -- check for defeat
        local defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 4)
        local defeatedBrainsCount = table.getn(defeatedBrains)
        if defeatedBrainsCount > 0 then

            -- take into account cascading effects
            local lastDefeatedBrainsCount = defeatedBrainsCount
            repeat 
                WaitTicks(4)
                -- re-compute the defeated brains until it no longer increases
                defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 1)
                defeatedBrainsCount = table.getn(defeatedBrains)
            until defeatedBrainsCount == lastDefeatedBrainsCount

            -- call them out as being defeated and exclude them
            for k, brain in defeatedBrains do

                -- take the army out of the game, adjust command sources
                SetArmyOutOfGame(k)
                ObserverAfterDeath(k)

                -- process on defeat logic of brain
                brain:OnDefeat()

                -- communicate to the server that this brain has been defeated
                table.insert(Sync.GameResult, { k, string.format("%s %i", 'defeat', -10) })

                -- stop considering it a brain that is still alive
                aliveBrains[k] = nil
            end
        end

        -- loop through the brains that are still alive to check for alliance differences

        if table.getn(aliveBrains) > 0 then 

            -- check for draw
            local draw = true
            for k, brain in aliveBrains do
                draw = draw and brain.OfferingDraw
            end

            if draw then
                for k, brain in aliveBrains do
                    -- take the army out of the game, adjust command sources
                    SetArmyOutOfGame(k)
                    ObserverAfterDeath(k)

                    -- process on draw logic of brain
                    brain:OnDraw()

                    -- communicate to the server that this brain has been defeated
                    table.insert(Sync.GameResult, { k, string.format("%s %i", 'draw', 0) })

                    -- stop considering it a brain that is still alive
                    aliveBrains[k] = nil
                end

                CallEndGame()
                break
            end

            -- check for win
            local win = true 
            for k, brain in aliveBrains do
                win = win and brain.RequestingAlliedVictory
            end

            for k, _ in aliveBrains do
                for l, _ in aliveBrains do
                    win = win and IsAlly(k, l)
                end
            end

            if win then 
                for k, brain in aliveBrains do
                    -- take the army out of the game, adjust command sources
                    SetArmyOutOfGame(k)
                    ObserverAfterDeath(k)

                    -- process on draw logic of brain
                    brain:OnVictory()

                    -- communicate to the server that this brain has been defeated
                    table.insert(Sync.GameResult, { k, string.format("%s %i", 'victory', 0) })

                    -- stop considering it a brain that is still alive
                    aliveBrains[k] = nil
                end

                CallEndGame()
                break
            end

        -- apparently no undefeated brains are left
        else 
            CallEndGame()
            break
        end

        WaitTicks(10)
    end

end

ForkThread(MatchStateThread)