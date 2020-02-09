historyInterval = 10
scoreInterval = 1
resourcesInterval = 0.1
alliesScore = true

local scoreData = {current={}, historical={}}
local scoreOption = ScenarioInfo.Options.Score or "no"
local ArmyScore = {}

-- Some of these values pre-existed and are used in other places, that's why their naming is not consistent
local categoriesToCollect = {
    land=categories.LAND,
    air=categories.AIR,
    naval=categories.NAVAL,
    cdr=categories.COMMAND,
    sacu=categories.SUBCOMMANDER,
    engineer=categories.ENGINEER,
    tech1=categories.TECH1,
    tech2=categories.TECH2,
    tech3=categories.TECH3,
    experimental=categories.EXPERIMENTAL,
    structures=categories.STRUCTURE,
    transportation=categories.TRANSPORTATION
}


function UpdateScoreData(newData)
    scoreData.current = table.deepcopy(newData)
end

function CalculateBrainScore(brain)
    local commanderKills = brain:GetArmyStat("Enemies_Commanders_Destroyed",0).Value
    local massSpent = brain:GetArmyStat("Economy_TotalConsumed_Mass",0.0).Value
    local massProduced = brain:GetArmyStat("Economy_TotalProduced_Mass",0.0).Value -- not currently being used
    local energySpent = brain:GetArmyStat("Economy_TotalConsumed_Energy",0.0).Value
    local energyProduced = brain:GetArmyStat("Economy_TotalProduced_Energy",0.0).Value -- not currently being used
    local massValueDestroyed = brain:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
    local massValueLost = brain:GetArmyStat("Units_MassValue_Lost",0.0).Value
    local energyValueDestroyed = brain:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
    local energyValueLost = brain:GetArmyStat("Units_EnergyValue_Lost",0.0).Value

    -- helper variables to make equation more clear
    local excessMassProduced = massProduced - massSpent -- not currently being used
    local excessEnergyProduced = energyProduced - energySpent -- not currently being used
    local energyValueCoefficient = 20
    local commanderKillBonus = commanderKills + 1 -- not currently being used

    -- score components calculated
    local resourceProduction = ((massSpent) + (energySpent / energyValueCoefficient)) / 2
    local battleResults = (((massValueDestroyed - massValueLost- (commanderKills * 2000)) + ((energyValueDestroyed - energyValueLost - (commanderKills * 5000000)) / energyValueCoefficient)) / 2)
    if battleResults < 0 then
        battleResults = 0
    end

    -- score calculated
    local score = math.floor(resourceProduction + battleResults + (commanderKills * 5000))

    return score
end

function ScoreHistoryThread()
    while true do
        WaitSeconds(historyInterval)
        table.insert(scoreData.historical, table.deepcopy(scoreData.current))
    end
end

function ScoreThread()
    for index, brain in ArmyBrains do
        ArmyScore[index] = {
            faction = 0,
            name = '',
            type = '',
            general = {
                score = 0,
                mass = 0,
                lastReclaimedMass = 0,
                lastReclaimedEnergy = 0,
                energy = 0,
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
                currentunits = {
                    count = 0
                },
                currentcap = {
                    count = 0
                }
            },

            blueprints = {
                -- filled dynamically below
            },

            units = {
                -- filled dynamically below
            },

            resources = {
                massin = {
                    total = 0,
                    rate = 0
                },
                massout = {
                    total = 0,
                    rate = 0
                },
                energyin = {
                    total = 0,
                    rate = 0
                },
                energyout = {
                    total = 0,
                    rate = 0
                },
                massover = {
                    total = 0,
                    rate = 0
                },
                energyover = {
                    total = 0,
                    rate = 0
                },
                storage = {
                    storedMass = 0,
                    storedEnergy = 0,
                    maxMass = 0,
                    maxEnergy = 0,
                },
                MassReclaimRate = 0,
                EnergyReclaimRate = 0
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

    ForkThread(ScoreDisplayResourcesThread)

    while true do
        local updInterval = scoreInterval / table.getsize(ArmyBrains)
        for index, brain in ArmyBrains do
            ArmyScore[index].faction = brain:GetFactionIndex()
            ArmyScore[index].name = brain.Nickname
            ArmyScore[index].type = brain.BrainType
            ArmyScore[index].general.score = CalculateBrainScore(brain)

            ArmyScore[index].general.mass = brain:GetArmyStat("Economy_TotalProduced_Mass", 0.0).Value
            ArmyScore[index].general.energy = brain:GetArmyStat("Economy_TotalProduced_Energy", 0.0).Value
            ArmyScore[index].general.currentunits.count = brain:GetArmyStat("UnitCap_Current", 0.0).Value
            ArmyScore[index].general.currentcap.count = brain:GetArmyStat("UnitCap_MaxCap", 0.0).Value

            ArmyScore[index].general.kills.count = brain:GetArmyStat("Enemies_Killed", 0.0).Value
            ArmyScore[index].general.kills.mass = brain:GetArmyStat("Enemies_MassValue_Destroyed", 0.0).Value
            ArmyScore[index].general.kills.energy = brain:GetArmyStat("Enemies_EnergyValue_Destroyed", 0.0).Value

            ArmyScore[index].general.built.count = brain:GetArmyStat("Units_History", 0.0).Value
            ArmyScore[index].general.built.mass = brain:GetArmyStat("Units_MassValue_Built", 0.0).Value
            ArmyScore[index].general.built.energy = brain:GetArmyStat("Units_EnergyValue_Built", 0.0).Value
            ArmyScore[index].general.lost.count = brain:GetArmyStat("Units_Killed", 0.0).Value
            ArmyScore[index].general.lost.mass = brain:GetArmyStat("Units_MassValue_Lost", 0.0).Value
            ArmyScore[index].general.lost.energy = brain:GetArmyStat("Units_EnergyValue_Lost", 0.0).Value

            ArmyScore[index].resources.massin.total = brain:GetArmyStat("Economy_TotalProduced_Mass", 0.0).Value
            ArmyScore[index].resources.massout.total = brain:GetArmyStat("Economy_TotalConsumed_Mass", 0.0).Value
            ArmyScore[index].resources.massout.rate = brain:GetArmyStat("Economy_Output_Mass", 0.0).Value
            ArmyScore[index].resources.massover.total = brain:GetArmyStat("Economy_AccumExcess_Mass", 0.0).Value

            ArmyScore[index].resources.energyin.total = brain:GetArmyStat("Economy_TotalProduced_Energy", 0.0).Value
            ArmyScore[index].resources.energyout.total = brain:GetArmyStat("Economy_TotalConsumed_Energy", 0.0).Value
            ArmyScore[index].resources.energyout.rate = brain:GetArmyStat("Economy_Output_Energy", 0.0).Value
            ArmyScore[index].resources.energyover.total = brain:GetArmyStat("Economy_AccumExcess_Energy", 0.0).Value

            ArmyScore[index].resources.storage.storedMass = brain:GetEconomyStored('MASS')
            ArmyScore[index].resources.storage.storedEnergy = brain:GetEconomyStored('ENERGY')

            ArmyScore[index].resources.storage.maxMass = brain:GetArmyStat("Economy_MaxStorage_Mass", 0.0).Value
            ArmyScore[index].resources.storage.maxEnergy = brain:GetArmyStat("Economy_MaxStorage_Energy", 0.0).Value

            for unitId, stats in brain.UnitStats do
                if ArmyScore[index].blueprints[unitId] == nil then
                    ArmyScore[index].blueprints[unitId] = {}
                end

                for statName, value in stats do
                    ArmyScore[index].blueprints[unitId][statName] = value
                end
            end

            for categoryName, category in categoriesToCollect do
                ArmyScore[index].units[categoryName]['kills'] = brain:GetBlueprintStat("Enemies_Killed", category)
                ArmyScore[index].units[categoryName]['built'] = brain:GetBlueprintStat("Units_History", category)
                ArmyScore[index].units[categoryName]['lost'] = brain:GetBlueprintStat("Units_Killed", category)
            end

            WaitSeconds(updInterval)
        end

        UpdateScoreData(ArmyScore)
        SyncScores()
    end
end

function ScoreDisplayResourcesThread()
    -- For certain stats, we need to do this every tick. We can't for all because it is quite heavy CPU
    -- We don't need to sync every tick though, just make sure the number is right
    while true do
        for index, brain in ArmyBrains do
            local reclaimedMass = brain:GetArmyStat("Economy_Reclaimed_Mass", 0.0).Value
            local massReclaimRate = reclaimedMass - ArmyScore[index].general.lastReclaimedMass
            ArmyScore[index].resources.MassReclaimRate = massReclaimRate
            ArmyScore[index].resources.massin.rate = brain:GetArmyStat("Economy_Income_Mass", 0.0).Value - massReclaimRate
            ArmyScore[index].general.lastReclaimedMass = reclaimedMass
            ArmyScore[index].resources.massover.rate = ArmyScore[index].resources.massin.rate - ArmyScore[index].resources.massout.rate + ArmyScore[index].resources.MassReclaimRate

            local reclaimedEnergy = brain:GetArmyStat("Economy_Reclaimed_Energy", 0.0).Value
            local energyReclaimRate = reclaimedEnergy - ArmyScore[index].general.lastReclaimedEnergy
            ArmyScore[index].resources.EnergyReclaimRate = energyReclaimRate
            ArmyScore[index].resources.energyin.rate = brain:GetArmyStat("Economy_Income_Energy", 0.0).Value - energyReclaimRate
            ArmyScore[index].general.lastReclaimedEnergy = reclaimedEnergy
            ArmyScore[index].resources.energyover.rate = ArmyScore[index].resources.energyin.rate - ArmyScore[index].resources.energyout.rate + ArmyScore[index].resources.EnergyReclaimRate
        end
        WaitSeconds(resourcesInterval)
    end
end

local observer = false
function SyncScores()
    local myArmyIndex = GetFocusArmy()
    observer = myArmyIndex == -1

    local victory = import('/lua/victory.lua')
    if observer or victory.gameOver then
        Sync.FullScoreSync = true
        Sync.ScoreAccum = scoreData
        Sync.Score = scoreData.current

        -- We don't want to report full scores to server unless game over
        if victory.gameOver then
            Sync.StatsToSend = Sync.Score
        end
    else
        for index, brain in ArmyBrains do
            if brain.Result and not brain.StatsSent then
                Sync.StatsToSend = table.deepcopy(scoreData.current)
                brain.StatsSent = true
            end

            if (myArmyIndex == index) or (alliesScore and IsAlly(myArmyIndex, index)) then
                Sync.Score[index] = ArmyScore[index]
            else
                Sync.Score[index] = {}
                Sync.Score[index].general = {}
            end

            if scoreOption ~= 'no' then
                Sync.Score[index].general.score = ArmyScore[index].general.score
            else
                Sync.Score[index].general.score = -1
            end
        end

    end
end

function init()
    ForkThread(ScoreThread)
    ForkThread(ScoreHistoryThread)
end
