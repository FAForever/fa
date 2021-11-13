local aibrain_methodsGetBlueprintStat = moho.aibrain_methods.GetBlueprintStat
local GetFocusArmy = GetFocusArmy
local tableDeepcopy = table.deepcopy
local SessionIsReplay = SessionIsReplay
local ForkThread = ForkThread
local next = next
local tableInsert = table.insert
local ipairs = ipairs
local tableGetsize = table.getsize
local mathMax = math.max
local GetGameTimeSeconds = GetGameTimeSeconds
local mathFloor = math.floor
local aibrain_methodsGetEconomyStored = moho.aibrain_methods.GetEconomyStored
local ArmyIsCivilian = ArmyIsCivilian
local aibrain_methodsGetArmyStat = moho.aibrain_methods.GetArmyStat
local GetGameTick = GetGameTick
local IsAlly = IsAlly

historyInterval = 10
scoreInterval = 1
alliesScore = true

local ArmyScore = {}
local scoreOption = ScenarioInfo.Options.Score or "no"
scoreData = {interval = historyInterval, current = ArmyScore, history = {}}

local victory = import('/lua/victory.lua')
-- Some of these values pre-existed and are used in other places, that's why their naming is not consistent
local categoriesToCollect = {
    land = categories.LAND,
    air = categories.AIR,
    naval = categories.NAVAL,
    cdr = categories.COMMAND,
    sacu = categories.SUBCOMMANDER,
    engineer = categories.ENGINEER,
    tech1 = categories.TECH1,
    tech2 = categories.TECH2,
    tech3 = categories.TECH3,
    experimental = categories.EXPERIMENTAL,
    structures = categories.STRUCTURE,
    transportation = categories.TRANSPORTATION
}

function CalculateBrainScore(brain)
    local commanderKills = aibrain_methodsGetArmyStat(brain, "Enemies_Commanders_Destroyed", 0).Value
    local massSpent = aibrain_methodsGetArmyStat(brain, "Economy_TotalConsumed_Mass", 0).Value
    local energySpent = aibrain_methodsGetArmyStat(brain, "Economy_TotalConsumed_Energy", 0).Value
    local massValueDestroyed = aibrain_methodsGetArmyStat(brain, "Enemies_MassValue_Destroyed", 0).Value
    local massValueLost = aibrain_methodsGetArmyStat(brain, "Units_MassValue_Lost", 0).Value
    local energyValueDestroyed = aibrain_methodsGetArmyStat(brain, "Enemies_EnergyValue_Destroyed", 0).Value
    local energyValueLost = aibrain_methodsGetArmyStat(brain, "Units_EnergyValue_Lost", 0).Value

    -- helper variables to make equation more clear
    local energyValueCoefficient = 20

    -- score components calculated
    local resourceProduction = (massSpent + (energySpent / energyValueCoefficient)) / 2
    local battleResults = mathMax(0, ((massValueDestroyed - massValueLost - (commanderKills * 2000)) +
        ((energyValueDestroyed - energyValueLost - (commanderKills * 5000000)) / energyValueCoefficient)) / 2)

    -- score calculated
    return mathFloor(resourceProduction + battleResults + (commanderKills * 5000))
end

local function ScoreResourcesThread()
    while not victory.gameOver do
        WaitSeconds(1)
        for index, brain in ArmyBrains do
            if ArmyIsCivilian(index) then continue end
            if (ArmyScore[index].Defeated ~= nil) and (ArmyScore[index].Defeated < 0) then continue end
            local Score = ArmyScore[index]
            local CurTick = GetGameTick()
            TicksSinceLastUpdate = (CurTick - Score.general.lastupdatetick)
            Score.general.lastupdatetick = CurTick

            local lastReclaimedMass = Score.resources.massin.reclaimed
            Score.resources.massin.reclaimed = aibrain_methodsGetArmyStat(brain, "Economy_Reclaimed_Mass", 0).Value
            Score.resources.massin.reclaimRate = (Score.resources.massin.reclaimed - lastReclaimedMass) / TicksSinceLastUpdate
            local lastTotalMass = Score.resources.massin.total
            Score.resources.massin.total = aibrain_methodsGetArmyStat(brain, "Economy_TotalProduced_Mass", 0).Value
            Score.resources.massin.rate = (Score.resources.massin.total - lastTotalMass) / TicksSinceLastUpdate - Score.resources.massin.reclaimRate
            local lastConsumedMass = Score.resources.massout.total
            Score.resources.massout.total = aibrain_methodsGetArmyStat(brain, "Economy_TotalConsumed_Mass", 0).Value
            Score.resources.massout.rate = (Score.resources.massout.total - lastConsumedMass) / TicksSinceLastUpdate
            Score.resources.massout.excess = aibrain_methodsGetArmyStat(brain, "Economy_AccumExcess_Mass", 0).Value

            local lastReclaimedEnergy = Score.resources.energyin.reclaimed
            Score.resources.energyin.reclaimed = aibrain_methodsGetArmyStat(brain, "Economy_Reclaimed_Energy", 0).Value
            Score.resources.energyin.reclaimRate = (Score.resources.energyin.reclaimed - lastReclaimedEnergy) / TicksSinceLastUpdate
            local lastTotalEnergy = Score.resources.energyin.total
            Score.resources.energyin.total = aibrain_methodsGetArmyStat(brain, "Economy_TotalProduced_Energy", 0).Value
            Score.resources.energyin.rate = (Score.resources.energyin.total - lastTotalEnergy) / TicksSinceLastUpdate - Score.resources.energyin.reclaimRate
            local lastConsumedEnergy = Score.resources.energyout.total
            Score.resources.energyout.total = aibrain_methodsGetArmyStat(brain, "Economy_TotalConsumed_Energy", 0).Value
            Score.resources.energyout.rate = (Score.resources.energyout.total - lastConsumedEnergy) / TicksSinceLastUpdate
            Score.resources.energyout.excess = aibrain_methodsGetArmyStat(brain, "Economy_AccumExcess_Energy", 0).Value

            Score.resources.storage.storedMass = aibrain_methodsGetEconomyStored(brain, 'MASS')
            Score.resources.storage.storedEnergy = aibrain_methodsGetEconomyStored(brain, 'ENERGY')

            Score.resources.storage.maxMass = aibrain_methodsGetArmyStat(brain, "Economy_MaxStorage_Mass", 0).Value
            Score.resources.storage.maxEnergy = aibrain_methodsGetArmyStat(brain, "Economy_MaxStorage_Energy", 0).Value
        end
    end
end

local function ScoreHistoryThread()
    while not victory.gameOver do
        WaitSeconds(scoreData.interval)
        local data = {}
        for index, brain in ArmyBrains do
            local Score = scoreData.current[index]
            if ArmyIsCivilian(index) then continue end
            if (Score.Defeated ~= nil) and (Score.Defeated < 0) then continue end
            if (Score.Defeated ~= nil) and (Score.Defeated < GetGameTimeSeconds()) then
                Score.Defeated = -1
            end
            data[index] = tableDeepcopy(Score)
        end
        tableInsert(scoreData.history, data)
    end
end

local function ScoreThread()
    for index, brain in ArmyBrains do
        if ArmyIsCivilian(index) then continue end
        ArmyScore[index] = {
            faction = brain:GetFactionIndex(),
            name = brain.Nickname,
            type = '',
            general = {
                score = 0,
                lastupdatetick = 0,
                kills = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                built = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                lost = {
                    count = 0,
                    mass = 0,
                    energy = 0
                },
                currentunits = 0,
                currentcap = 0
            },
            blueprints = {}, -- filled dynamically below
            units = {},      -- filled dynamically below
            resources = {
                massin = {
                    total = 0,
                    rate = 0,
                    reclaimed = 0,
                    reclaimRate = 0
                },
                massout = {
                    total = 0,
                    rate = 0,
                    excess = 0
                },
                energyin = {
                    total = 0,
                    rate = 0,
                    reclaimed = 0,
                    reclaimRate = 0
                },
                energyout = {
                    total = 0,
                    rate = 0,
                    excess = 0
                },
                storage = {
                    storedMass = 0,
                    storedEnergy = 0,
                    maxMass = 0,
                    maxEnergy = 0
                }
            }
        }
        for categoryName, category in categoriesToCollect do
            ArmyScore[index].units[categoryName] = {
                kills = 0,
                built = 0,
                lost = 0
            }
        end
    end

    ForkThread(ScoreResourcesThread)
    ForkThread(ScoreHistoryThread)

    local NextTime = 0
    local lastTotalMass = 0
    local lastTotalEnergy = 0
    local lastReclaimedMass = 0
    local lastReclaimedEnergy = 0
    local lastConsumedMass = 0
    local lastConsumedEnergy = 0
    local estimatedTicksSinceLastUpdate = 0

    while not victory.gameOver do
        local updInterval = scoreInterval / tableGetsize(ArmyBrains)
        for index, brain in ArmyBrains do
            local CurTime = GetGameTimeSeconds()
            if CurTime < NextTime then
                WaitSeconds(updInterval)
            end
            NextTime = NextTime + updInterval
            local Score = ArmyScore[index]
            if ArmyIsCivilian(index) then continue end
            if (Score.Defeated ~= nil) and (Score.Defeated < 0) then continue end
            if (Score.Defeated == nil) and brain:IsDefeated() then
                Score.Defeated = CurTime + 15
            end
            Score.type = brain.BrainType
            Score.general.score = CalculateBrainScore(brain)

            Score.general.currentunits = aibrain_methodsGetArmyStat(brain, "UnitCap_Current", 0).Value
            Score.general.currentcap = aibrain_methodsGetArmyStat(brain, "UnitCap_MaxCap", 0).Value

            Score.general.kills.count = aibrain_methodsGetArmyStat(brain, "Enemies_Killed", 0).Value
            Score.general.kills.mass = aibrain_methodsGetArmyStat(brain, "Enemies_MassValue_Destroyed", 0).Value
            Score.general.kills.energy = aibrain_methodsGetArmyStat(brain, "Enemies_EnergyValue_Destroyed", 0).Value

            Score.general.built.count = aibrain_methodsGetArmyStat(brain, "Units_History", 0).Value
            Score.general.built.mass = aibrain_methodsGetArmyStat(brain, "Units_MassValue_Built", 0).Value
            Score.general.built.energy = aibrain_methodsGetArmyStat(brain, "Units_EnergyValue_Built", 0).Value
            Score.general.lost.count = aibrain_methodsGetArmyStat(brain, "Units_Killed", 0).Value
            Score.general.lost.mass = aibrain_methodsGetArmyStat(brain, "Units_MassValue_Lost", 0).Value
            Score.general.lost.energy = aibrain_methodsGetArmyStat(brain, "Units_EnergyValue_Lost", 0).Value

            for unitId, stats in brain.UnitStats do
                if Score.blueprints[unitId] == nil then
                    Score.blueprints[unitId] = {}
                end

                for statName, value in stats do
                    Score.blueprints[unitId][statName] = value
                end
            end

            for categoryName, category in categoriesToCollect do
                Score.units[categoryName]['kills'] = aibrain_methodsGetBlueprintStat(brain, "Enemies_Killed", category)
                Score.units[categoryName]['built'] = aibrain_methodsGetBlueprintStat(brain, "Units_History", category)
                Score.units[categoryName]['lost'] = aibrain_methodsGetBlueprintStat(brain, "Units_Killed", category)
            end
        end

        local myArmyIndex = GetFocusArmy()
        local observer = myArmyIndex == -1

        if observer or SessionIsReplay() then
            Sync.Score = ArmyScore
        else
            for index, brain in ArmyBrains do
                if ArmyIsCivilian(index) then continue end
                if brain:IsDefeated() then
                    Sync.Score[index] = {Defeated = true, general = {}}
                else
                    if (myArmyIndex == index) or (alliesScore and IsAlly(myArmyIndex, index)) then
                        Sync.Score[index] = tableDeepcopy(ArmyScore[index])
                    else
                        Sync.Score[index] = {general = {}}
                    end
                end

                if scoreOption ~= 'no' then
                    Sync.Score[index].general.score = ArmyScore[index].general.score
                else
                    Sync.Score[index].general.score = -1
                end
            end
        end
    end
end

function init()
    ForkThread(ScoreThread)
    tableInsert(GameOverListeners, function()
        Sync.ScoreAccum = scoreData
        if victory.gameOver then
            Sync.StatsToSend = ArmyScore
        end
    end)
end
