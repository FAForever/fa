historyInterval = 10
scoreInterval = 1
resourcesInterval = 0.1
alliesScore = true

local Victory = import('/lua/victory.lua')
local ScoreHistory = {}
local BpStatsToCollect = {}
local ScoreEnabled = (ScenarioInfo.Options.Score or 'no') == 'no'
local SentOnVictory = false
local IsObserver = false


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

local armyStatsToCollect = {
    ['general.mass']                  = 'Economy_Stored_Mass',
    ['general.energy']                = 'Economy_Stored_Energy',

    ['general.currentunits.count']    = 'UnitCap_Current',
    ['general.currentcap.count']      = 'UnitCap_MaxCap',
    ['general.kills.count']           = 'Enemies_Killed',
    ['general.kills.mass']            = 'Enemies_MassValue_Destroyed',
    ['general.kills.energy']          = 'Enemies_EnergyValue_Destroyed',
    ['general.kills.commander']       = 'Enemies_Commander_Destroyed',

    ['general.built.count']           = 'Units_History',
    ['general.built.mass']            = 'Units_MassValue_Built',
    ['general.built.energy']          = 'Units_EnergyValue_Built',
    ['general.lost.count']            = 'Units_Killed',
    ['general.lost.mass']             = 'Units_MassValue_Lost',
    ['general.lost.energy']           = 'Units_EnergyValue_Lost',

    ['damage.total.dealt']            = 'DamageStats_TotalDamageDealt',
    ['damage.total.received']         = 'DamageStats_TotalDamageReceived',
    ['damage.units.dealt']            = 'Units_TotalDamageDealt',
    ['damage.units.received']         = 'Units_TotalDamageReceived',

    ['resources.massin.rate']         = 'Economy_Income_Mass',
    ['resources.massin.total']        = 'Economy_TotalProduced_Mass',
    ['resources.massout.rate']        = 'Economy_Output_Mass',
    ['resources.massout.total']       = 'Economy_TotalConsumed_Mass',
    ['resources.massover.total']      = 'Economy_AccumExcess_Mass',
    ['resources.massreclaim.total']   = 'Economy_Reclaimed_Mass',
    ['resources.energyin.total']      = 'Economy_TotalProduced_Energy',
    ['resources.energyin.rate']       = 'Economy_Input_Energy',
    ['resources.energyout.total']     = 'Economy_TotalConsumed_Energy',
    ['resources.energyout.rate']      = 'Economy_Output_Energy',
    ['resources.energyover.total']    = 'Economy_AccumExcess_Energy',
    ['resources.energyreclaim.total'] = 'Economy_Reclaimed_Energy',
}

for categoryName, category in categoriesToCollect do
    for k, v in {kills='Enemies_Killed', built='Units_History', lost='Units_Killed'} do
        BpStatsToCollect[string.format("blueprints.%s.%s", categoryName, k)] = {name=v, category=category}
    end
end

function CalculateBrainScore(brain)
    local commanderKills = brain:GetArmyStat("Enemies_Commanders_Destroyed", 0).Value
    local massSpent = brain:GetArmyStat("Economy_TotalConsumed_Mass", 0).Value
    local energySpent = brain:GetArmyStat("Economy_TotalConsumed_Energy", 0).Value
    local massValueDestroyed = brain:GetArmyStat("Enemies_MassValue_Destroyed", 0).Value
    local massValueLost = brain:GetArmyStat("Units_MassValue_Lost", 0).Value
    local energyValueDestroyed = brain:GetArmyStat("Enemies_EnergyValue_Destroyed", 0).Value
    local energyValueLost = brain:GetArmyStat("Units_EnergyValue_Lost", 0).Value

    local energyValueCoefficient = 20

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

function CalculateAllScores(armyScore)
    for army, score in armyScore do
        if score['general.score'] == -1 then
            score['general.score'] = CalculateBrainScore(ArmyBrains[army])
        end
    end
end

local lastHistoryValues = {}
function StoreScoreInHistory(armyScore, second)
    local lastValues = lastHistoryValues
    for army, score in armyScore do
        local brain = ArmyBrains[army]

        for key, value in score do
            if not ScoreHistory[key] then
                ScoreHistory[key] = {}
            end

            if not ScoreHistory[key][army] then
                ScoreHistory[key][army] = {}
            end

            if not lastValues[key] then
                lastValues[key] = {}
            end

            if key == 'general.score' and value == -1 then
                value = CalculateBrainScore(brain)
            end

            if lastValues[key][army] ~= value then
                ScoreHistory[key][army][second] = value
                lastValues[key][army] = value
            end
        end
    end
end

function ScoreThread()
    local armyScore = {}

    for index, brain in ArmyBrains do
        if not ArmyIsCivilian(index) then
            armyScore[index] = {
                faction = brain:GetFactionIndex(),
                name = brain.Nickname,
                type = brain.BrainType,
            }
        end
    end

    local SCORE_WAIT = math.max(0.1, scoreInterval - table.getsize(armyScore) * 0.1)
    local last_tick = {}
    local nextHistorySecond = 0
    
    while true do
        local calcScore = ScoreEnabled or IsObserver

        for army, t in armyScore do
            local brain = ArmyBrains[army]
            if brain:IsDefeated() then continue end
            
            local tick = GetGameTick()
            
            if calcScore then
                t['general.score'] = CalculateBrainScore(brain)
            else
                t['general.score'] = -1
            end

            local lastReclaimMass = t['general.massreclaim.total'] or 0
            local lastReclaimEnergy = t['general.energyreclaim.total'] or 0

            for k, s in armyStatsToCollect do
                t[k] = brain:GetArmyStat(s, 0).Value
            end

            local tick_diff = tick - (last_tick[army] or 0)
            local reclaimRate

            -- Subtract reclaim from mass income
            reclaimRate = (t['resources.massreclaim.total'] - lastReclaimMass) / tick_diff
            t['resources.massin.rate'] = t['resources.massin.rate'] - reclaimRate
            t['resources.massover.rate'] = t['resources.massin.rate'] - t['resources.massout.rate']
            t['resources.massreclaim.rate'] = reclaimRate

            -- Subtract reclaim from energy income
            reclaimRate = (t['resources.energyreclaim.total'] - lastReclaimEnergy) / tick_diff
            t['resources.energyin.rate'] = t['resources.energyin.rate'] - reclaimRate
            t['resources.energyover.rate'] = t['resources.energyin.rate'] - t['resources.energyout.rate']
            t['resources.energyreclaim.rate'] = reclaimRate

            last_tick[army] = tick

            WaitSeconds(0.1)
        end

        local currentSecond = GetGameTick() / 10
        if nextHistorySecond <= currentSecond then
            StoreScoreInHistory(armyScore, nextHistorySecond)
            nextHistorySecond = nextHistorySecond + historyInterval
        end

        SyncScores(armyScore)
        WaitSeconds(SCORE_WAIT)
    end
end

function SyncScores(armyScore)
    local myArmyIndex = GetFocusArmy()

    IsObserver = IsObserver or myArmyIndex == -1 or SessionIsReplay()
    if IsObserver or Victory.gameOver then
        SyncFullScore(armyScore)
    else
        SyncCurrentScore(armyScore)
    end
end

function SyncCurrentScore(armyScore)
    local myArmyIndex = GetFocusArmy()
    local scoreEnabled = ScoreEnabled
    Sync.Score = {}

    for index, score in armyScore do
        local brain = ArmyBrains[index]
        if brain.Result and not brain.StatsSent then
            SyncStats(armyScore)
            brain.StatsSent = true
        end

        local syncScore
        if (myArmyIndex == index) or (alliesScore and IsAlly(myArmyIndex, index) and not ArmyIsCivilian(index)) then
            syncScore = score
        else 
            syncScore = {}
        end

        if not scoreEnabled then
            syncScore['general.score'] = -1
        else
            syncScore['general.score'] = score['general.score']
        end

        Sync.Score[index] = syncScore
    end
end

function SyncFullScore(armyScore)
    -- We don't want to report full stats / history to server unless game over
    if Victory.gameOver and not SentOnVictory then
        CalculateAllScores(armyScore)
        SyncStats(armyScore)
        SyncHistory()
        SentOnVictory = true
    end

    Sync.FullScoreSync = true
    Sync.Score = armyScore
end

function SyncStats(armyScore)
    local sendStats = {}

    for index, score in armyScore do
        local brain = ArmyBrains[index]
        local t = {}

        for unitId, stats in brain.UnitStats do
            for statName, value in stats do
                t[string.format("units.%s.%s", unitId, statName)] = value
            end
        end

        for k, stat in BpStatsToCollect do
            t[k] = brain:GetBlueprintStat(stat.name, stat.category)
        end

        sendStats[index] = t
    end

    Sync.StatsToSend = sendStats
end

function SyncHistory()
    local jsonOptions = {keyorder={}}
    local lastSecond = math.round(GetGameTick() / 10)
    local i

    for i=0, lastSecond, historyInterval do
        table.insert(jsonOptions.keyorder, i)
    end

    -- Rebuild history to old format so hotstats doesn't break
    local finalHistory = {}
    local currentValues = {}
    for i=0, lastSecond, historyInterval do
        local history = {}
        for k, armies in ScoreHistory do
            for army, values in armies do
                local value

                if not history[army] then
                    history[army] = {}
                end

                if not currentValues[army] then
                    currentValues[army] = {}
                end

                if values[i] ~= nil then
                    currentValues[army][k] = values[i]
                end

                history[army][k] = currentValues[army][k]
            end
        end

        table.insert(finalHistory, history)
    end

    Sync.ScoreHistory = finalHistory
    --local json = import('/lua/system/dkson.lua').json.encode(ScoreHistory, jsonOptions)
    --SPEW(json)
end

function init()
    ForkThread(ScoreThread)
end
