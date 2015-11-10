historyInterval = 10

local ArmyStats = {}
local statsData = {current={}, historical={}}
local scoreOption = ScenarioInfo.Options.Score or "no"

local brainArmyStats = {
    resources = {
        mass = {
            produced = "Economy_TotalProduced_Mass",
            consumed = "Econony_TotalConsumed_Mass",
            overflowed = "Economy_AccumExcess_Mass",
            income = "Economy_Income_Mass",
            usage = "Economy_Output_Mass",
        },
        energy = {
            produced = "Economy_TotalProduced_Energy",
            consumed = "Econony_TotalConsumed_Energy",
            overflowed = "Economy_AccumExcess_Energy",
            income = "Economy_Income_Energy",
            usage = "Economy_Output_Energy",
        },
    },
    units = {
        current = "UnitCap_Current",
        cap = "UnitCap_MaxCap",
    },
}

local brainBpStats = {
    total=0,
    land=categories.LAND,
    air=categories.AIR,
    naval=categories.NAVAL,
    command=categories.COMMAND,
    engineer=categories.ENGINEER,
    sacu=categories.SUBCOMMANDER,
    experimental=categories.EXPERIMENTAL,
    structure=categories.STRUCTURE,
    tech1=categories.TECH1,
    tech2=categories.TECH2,
    tech3=categories.TECH3,
}

function UpdateStatsData(newData)
    statsData.current = table.deepcopy(newData)
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
    local battleResults = (((massValueDestroyed - massValueLost- (commanderKills * 18000)) + ((energyValueDestroyed - energyValueLost - (commanderKills * 5000000)) / energyValueCoefficient)) / 2)
    if battleResults < 0 then
        battleResults = 0
    end

    -- score calculated
    local score = math.floor(resourceProduction + battleResults + (commanderKills * 5000))

    return score
end

function recursiveFillBrainArmyStats(brain, stats, stat)
    local t = type(stat)

    if t == 'table' then
        for k, v in stat do
            stats[k] = recursiveFillBrainArmyStats(brain, {}, v)
        end
        return stats
    elseif t == 'string' then
        return brain:GetArmyStat(stat, 0.0).Value
    else return stat end
end

function brainstat(brain, stat, cats)
    if cats ~= 0 then
        return brain:GetBlueprintStat(stat, cats)
    else
        return brain:GetArmyStat(stat, 0.0).Value
    end
end

function fillBrainBpStats(brain, stats)
    for key, cats in brainBpStats do
        stats.units[key] = {
            built = {
                count=brainstat(brain, "Units_History", cats),
                mass=brainstat(brain, "Units_MassValue_Built", cats),
                energy=brainstat(brain, "Units_EnergyValue_Built", cats),
            },
            lost = {
                count=brainstat(brain, "Units_Killed", cats),
                mass=brainstat(brain, "Units_MassValue_Lost", cats),
                energy=brainstat(brain, "Units_EnergyValue_Lost", cats),
            },
            killed = {
                count=brainstat(brain, "Enemies_Killed", cats),
                mass=brainstat(brain, "Units_MassValue_Destroyed", cats),
                energy=brainstat(brain, "Units_EnergyValue_Destroyed", cats),
            },
        }
    end
end

function fillBrainUnitStats(brain, stats)
    for unitId, stats in brain:GetUnitStats() do
        for statName, value in stats do
            stats.units[unitId][statName] = value
        end
    end
end

function UpdateBrainStats(brain)
    local army = brain:GetArmyIndex()
    if ArmyIsCivilian(army) then return end
    local stats = {}

    recursiveFillBrainArmyStats(brain, stats, brainArmyStats)
    -- subtract reclaim rate from income
    for _, t in {'Mass', 'Energy'} do
        local res = stats.resources[string.lower(t)]
        res.reclaimed = brain:GetArmyStat("Economy_Reclaimed_" .. t, 0.0).Value
        res.reclaim_rate = res.reclaimed - (res.last_reclaimed or 0)
        res.last_reclaimed = res.reclaimed
        res.income = res.income - res.reclaim_rate
    end
    fillBrainBpStats(brain, stats)
    stats.score = CalculateBrainScore(brain)
    ArmyStats[army] = stats
end

function StatsThread()
    while true do
        for index, brain in ArmyBrains do
            UpdateBrainStats(brain)
            WaitSeconds(0.1)
        end

        WaitSeconds(3)
        UpdateStatsData(ArmyStats)
        SyncStats()
    end
end

function StatsHistoryThread()
    while true do
        WaitSeconds(historyInterval)
        table.insert(statsData.historical, table.deepcopy(statsData.current))
    end
end

function SyncStats()
    local my_army = GetFocusArmy()

    if my_army == -1 or import('/lua/victory.lua').gameOver then
        Sync.FullScoreSync = true
        Sync.ScoreAccum = statsData
        Sync.Score = statsData.current
    else
        for index, brain in ArmyBrains do
            local stats = ArmyStats[index]

            if my_army == index or IsAlly(my_army, index) then
                Sync.Score[index] = {units={current = stats.units.current, cap=stats.units.cap}, resources=stats.resources}
            else
                Sync.Score[index] = {}
            end

            Sync.Score[index].score = scoreOption ~= 'no' and stats.score or -1
        end
    end
end

function init()
    ForkThread(StatsThread)
    ForkThread(StatsHistoryThread)
end
