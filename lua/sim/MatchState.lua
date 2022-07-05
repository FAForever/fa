
local Conditions = {
    demoralization = categories.COMMAND,
    domination = categories.STRUCTURE + categories.ENGINEER - categories.WALL,
    eradication = categories.ALLUNITS - categories.WALL,
}

local function CollectDefeatedBrains(aliveBrains, condition, delay)
    local defeatedBrains = { }
    for _, index in aliveBrains do

        local defeated = true
        local brain = allBrains[index]

        ---@type Unit[]
        local criticalUnits = brain:GetListOfUnits(brain, condition)
        if criticalUnits then 
            for k, unit in criticalUnits do 
                if not IsDestroyed(unit) and unit:GetFractionComplete() == 1 then
                    defeated = false
                    break
                end
            end
        end

        if defeated then
            defeatedBrains[index] = true 
        end

        WaitTicks(delay)
    end

    return defeatedBrains
end

local function MatchStateThread()

    local condition = Conditions[ScenarioInfo.Options.Victory]
    if not condition then
        SPEW("Unknown victory condition supplied: " .. ScenarioInfo.Options.Victory .. ", victory conditions defaults to sandbox.")
        return
    end

    local allBrains = ArmyBrains

    -- consider all non-civilian brains to be alive
    local aliveBrains = { }
    for k, brain in allBrains do
        local index = brain:GetArmyIndex()
        if not ArmyIsCivilian(index) then
            aliveBrains[index] = true
        end
    end

    -- keep scanning the gamestate
    while true do

        -- find brains that are defeated
        local defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 5)
        local defeatedBrainsCount = table.getn(defeatedBrains)
        if defeatedBrainsCount > 0 then

            -- take into account cascading effects
            local lastDefeatedBrainsCount = defeatedBrainsCount
            repeat 
                WaitTicks(4)
                -- re-compute the defeated brains until it no longer increases
                defeatedBrains = CollectDefeatedBrains(aliveBrains, condition, 2)
                defeatedBrainsCount = table.getn(defeatedBrains)
            until defeatedBrainsCount == lastDefeatedBrainsCount

            -- call them out as being defeated
            for brain, _ in defeatedBrains do
                brain:OnDefeat()
            end
        end

        WaitTicks(10)

    end

end

ForkThread(MatchStateThread())