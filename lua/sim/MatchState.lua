--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************

local SyncGameResult = import("/lua/simsyncutils.lua").SyncGameResult

local Conditions = {
    demoralization = categories.COMMAND,
    domination = categories.STRUCTURE + categories.ENGINEER - categories.WALL,
    eradication = categories.ALLUNITS - categories.WALL,
}

--- Ends the game, processing all events including sending score and statistics to the UI
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
---@param aliveBrains AIBrain[]         # Table of brains that are relevant to check for defeat
---@param condition EntityCategory      # Categories to check for units that are required to remain in the game
---@param delay number                  # Delay between each brain to spread the load over various ticks
---@return AIBrain[]                    # Table of brains that are considered defeated, can be empty
local function CollectDefeatedBrains(aliveBrains, condition, delay)
    local defeatedBrains = { }
    for k, brain in aliveBrains do
        local criticalUnits = brain:GetListOfUnits(condition)
        if (not brain:IsDefeated()) and (criticalUnits) then
            -- critical units found, make sure they all exist properly
            local oneCriticalUnitAlive = false
            for _, unit in criticalUnits do
                if (not IsDestroyed(unit)) and (unit:GetFractionComplete() == 1) then
                    oneCriticalUnitAlive = true
                    break
                end
            end

            -- no critical units alive or finished, brain is defeated
            if not oneCriticalUnitAlive then
                defeatedBrains[k] = brain
            end

        -- no critical units found, brain is defeated
        else
            defeatedBrains[k] = brain
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

    if not condition then
        if ScenarioInfo.Options.Victory ~= 'sandbox' then
            SPEW("Unknown victory condition supplied: " .. ScenarioInfo.Options.Victory .. ", victory condition defaults to sandbox.")
        end

        return
    end

    -- consider all non-civilian brains to be alive and kicking
    local aliveBrains = { }
    for _, brain in ArmyBrains do
        local index = brain:GetArmyIndex()
        if (not ArmyIsCivilian(index)) and (not ArmyIsOutOfGame(index)) then
            aliveBrains[index] = brain
        end
    end

    -- keep scanning the gamestate for changes in alliances and brain state
    while true do
        -- check for defeat
        local defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 1)
        local defeatedBrainsCount = table.getsize(defeatedBrains)
        if defeatedBrainsCount > 0 then

            -- take into account cascading effects
            local lastDefeatedBrainsCount
            repeat
                lastDefeatedBrainsCount = defeatedBrainsCount

                -- re-compute the defeated brains until it no longer increases
                defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 1)
                defeatedBrainsCount = table.getsize(defeatedBrains)
            until defeatedBrainsCount == lastDefeatedBrainsCount

            -- call them out as being defeated and exclude them
            for k, brain in defeatedBrains do
                -- take the army out of the game, adjust command sources
                SetArmyOutOfGame(k)
                ObserverAfterDeath(k)

                -- process on defeat logic of brain
                brain:OnDefeat()
                SPEW("Matchstate - defeated: " .. brain.Nickname)

                -- communicate to the server that this brain has been defeated
                SyncGameResult({ k, "defeat -10" })

                -- stop considering it a brain that is still alive
                aliveBrains[k] = nil
            end
        end

        -- loop through the brains that are still alive to check for alliance differences

        if table.getsize(aliveBrains) > 0 then

            -- check for draw
            local draw = true
            for _, brain in aliveBrains do
                draw = draw and brain.OfferingDraw
            end

            if draw then
                for k, brain in aliveBrains do
                    -- take the army out of the game, adjust command sources
                    SetArmyOutOfGame(k)
                    ObserverAfterDeath(k)

                    -- process on draw logic of brain
                    brain:OnDraw()
                    SPEW("Matchstate - drawed: " .. brain.Nickname)

                    -- communicate to the server that this brain has been defeated
                    SyncGameResult({ k, "draw 0" })

                    -- stop considering it a brain that is still alive
                    aliveBrains[k] = nil
                end

                CallEndGame()
                break
            end

            -- check for win
            local win = true
            for k, brain in aliveBrains do
                for l, _ in aliveBrains do
                    if k ~= l then
                        win = win and IsAlly(k, l) and brain.RequestingAlliedVictory
                    end
                end
            end

            if win then
                for k, brain in aliveBrains do
                    -- take the army out of the game, adjust command sources
                    SetArmyOutOfGame(k)
                    ObserverAfterDeath(k)

                    -- process on draw logic of brain
                    brain:OnVictory()
                    SPEW("Matchstate - won: " .. brain.Nickname)

                    -- communicate to the server that this brain has been defeated
                    SyncGameResult({ k, "victory 10" })

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

        WaitTicks(4)
    end

end

function Setup()
    ForkThread(MatchStateThread)
end
