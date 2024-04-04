----------------------------------------------------------------------------
--
--  File     :  /lua/AI/sorianutilities.lua
--  Author(s): Michael Robbins aka Sorian
--
--  Summary  : Utility functions for the Sorian AIs
--
----------------------------------------------------------------------------

local SyncAIChat = import('/lua/simsyncutils.lua').SyncAIChat
local AIUtils = import("/lua/ai/aiutilities.lua")
local AIAttackUtils = import("/lua/ai/aiattackutilities.lua")
local Utils = import("/lua/utilities.lua")
local AIChatText = import("/lua/ai/sorianlang.lua").AIChatText

-- Table of AI taunts orginized by faction
local AITaunts = {
    {3,4,5,6,7,8,9,10,11,12,14,15,16}, -- Aeon
    {19,21,23,24,26,27,28,29,30,31,32}, -- UEF
    {33,34,35,36,37,38,39,40,41,43,46,47,48}, -- Cybran
    {49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64}, -- Seraphim
}

---@param aiBrain AIBrain
function T4Timeout(aiBrain)
    WaitSeconds(30)
    aiBrain.T4Building = false
end

---@param str string
---@param delimiter string
---@return table
function split(str, delimiter)
    local result = { }
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from , delim_from-1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

--- Gets the distance squared between 2 points.
---@param v1 Vector
---@param v2 Vector
---@return number|boolean # Distance
function XZDistanceTwoVectorsSq(v1, v2)
    if not v1 or not v2 then return false end
    return VDist2Sq(v1[1], v1[3], v2[1], v2[3])
end

---@param aiBrain AIBrain
function AICheckForWeakEnemyBase(aiBrain)
    if aiBrain:GetCurrentEnemy() and table.empty(aiBrain.AirAttackPoints) then
        local enemy = aiBrain:GetCurrentEnemy()
        local x,z = enemy:GetArmyStartPos()
        local enemyBaseThreat = aiBrain:GetThreatAtPosition({x,0,z}, 1, true, 'AntiAir', enemy:GetArmyIndex())
        local bomberThreat = 0
        local bombers = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.AIR * (categories.BOMBER + categories.GROUNDATTACK), {x,0,z}, 10000)
        for k, unit in bombers do
            bomberThreat = bomberThreat + unit:GetBlueprint().Defense.SurfaceThreatLevel
        end
        if bomberThreat > enemyBaseThreat then
            table.insert(aiBrain.AirAttackPoints,
                {
                Position = {x,0,z},
                }
            )
            aiBrain:ForkThread(aiBrain.AirAttackPointsTimeout, {x,0,z}, enemy)
        end
    end
end

--- Lets the AI handle intel data.
---@param aiBrain AIBrain
function AIHandleIntelData(aiBrain)
    local numchecks = 0
    local checkspertick = 5
    for _, intel in aiBrain.InterestList.HighPriority do
        numchecks = numchecks + 1
        if intel.Type == 'StructuresNotMex' then
            AIHandleStructureIntel(aiBrain, intel)
        elseif intel.Type == 'Commander' then
            AIHandleACUIntel(aiBrain, intel)
        -- elseif intel.Type == 'Experimental' then
        --  AIHandleT4Intel(aiBrain, intel)
        elseif intel.Type == 'Artillery' then
            AIHandleArtilleryIntel(aiBrain, intel)
        elseif intel.Type == 'Land' then
            AIHandleLandIntel(aiBrain, intel)
        end
        -- Reduce load on game
        if numchecks > checkspertick then
            WaitTicks(1)
            numchecks = 0
        end
    end
end

---@param aiBrain AIBrain
---@param intel table Table of intel data
function AIHandleStructureIntel(aiBrain, intel)
    for subk, subv in aiBrain.BaseMonitor.AlertsTable do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for subk, subv in aiBrain.AttackPoints do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for k,v in aiBrain.BuilderManagers do
        local basePos = v.EngineerManager:GetLocationCoords()
        -- If intel is within 300 units of a base
        if VDist2Sq(intel.Position[1], intel.Position[3], basePos[1], basePos[3]) < 90000 then
            -- Bombard the location
            table.insert(aiBrain.AttackPoints,
                {
                Position = intel.Position,
                }
            )
            aiBrain:ForkThread(aiBrain.AttackPointsTimeout, intel.Position)
            -- Set an alert for the location
            table.insert(aiBrain.BaseMonitor.AlertsTable,
                {
                Position = intel.Position,
                Threat = 350,
                }
            )
            aiBrain.BaseMonitor.AlertSounded = true
            aiBrain:ForkThread(aiBrain.BaseMonitorAlertTimeout, intel.Position, 'Overall')
            aiBrain.BaseMonitor.ActiveAlerts = aiBrain.BaseMonitor.ActiveAlerts + 1
        end
    end
end

--- Handles ACU intel.
---@param aiBrain AIBrain
---@param intel table
function AIHandleACUIntel(aiBrain, intel)
    local bombard = true
    local attack = true
    for subk, subv in aiBrain.BaseMonitor.AlertsTable do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            attack = false
            break
        end
    end
    for subk, subv in aiBrain.AttackPoints do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            bombard = false
            break
        end
    end
    if bombard then
        -- Bombard the location
        table.insert(aiBrain.AttackPoints,
            {
            Position = intel.Position,
            }
        )
        aiBrain:ForkThread(aiBrain.AttackPointsTimeout, intel.Position)
    end
    if attack then
        local bomberThreat = 0
        local bombers = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.AIR * (categories.BOMBER + categories.GROUNDATTACK), intel.Position, 500)
        for k, unit in bombers do
            bomberThreat = bomberThreat + unit:GetBlueprint().Defense.SurfaceThreatLevel
        end
        -- If AntiAir threat level is less than our bomber threat around the ACU
        if aiBrain:GetThreatAtPosition(intel.Position, 1, true, 'AntiAir') < bomberThreat then
            -- Set an alert for the location
            table.insert(aiBrain.BaseMonitor.AlertsTable,
                {
                Position = intel.Position,
                Threat = 350,
                }
            )
            aiBrain.BaseMonitor.AlertSounded = true
            aiBrain:ForkThread(aiBrain.BaseMonitorAlertTimeout, intel.Position)
            aiBrain.BaseMonitor.ActiveAlerts = aiBrain.BaseMonitor.ActiveAlerts + 1
        end
    end
end

--- Handles Artillery intel.
---@param aiBrain AIBrain
---@param intel table
function AIHandleArtilleryIntel(aiBrain, intel)
    for subk, subv in aiBrain.BaseMonitor.AlertsTable do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for subk, subv in aiBrain.AttackPoints do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for k,v in aiBrain.BuilderManagers do
        local basePos = v.EngineerManager:GetLocationCoords()
        -- If intel is within 950 units of a base
        if VDist2Sq(intel.Position[1], intel.Position[3], basePos[1], basePos[3]) < 902500 then
            -- Bombard the location
            table.insert(aiBrain.AttackPoints,
                {
                Position = intel.Position,
                }
            )
            aiBrain:ForkThread(aiBrain.AttackPointsTimeout, intel.Position)
            -- Set an alert for the location
            table.insert(aiBrain.BaseMonitor.AlertsTable,
                {
                Position = intel.Position,
                Threat = intel.Threat,
                }
            )
            aiBrain.BaseMonitor.AlertSounded = true
            aiBrain:ForkThread(aiBrain.BaseMonitorAlertTimeout, intel.Position, 'Economy')
            aiBrain.BaseMonitor.ActiveAlerts = aiBrain.BaseMonitor.ActiveAlerts + 1
        end
    end
end

--- Handles land unit intel.
---@param aiBrain any
---@param intel any
function AIHandleLandIntel(aiBrain, intel)
    for subk, subv in aiBrain.BaseMonitor.AlertsTable do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for subk, subv in aiBrain.TacticalBases do
        if intel.Position[1] == subv.Position[1] and intel.Position[3] == subv.Position[3] then
            return
        end
    end
    for k,v in aiBrain.BuilderManagers do
        local basePos = v.EngineerManager:GetLocationCoords()
        -- If intel is within 100 units of a base we don't want this spot
        if VDist2Sq(intel.Position[1], intel.Position[3], basePos[1], basePos[3]) < 10000 then
            return
        end
    end
    -- Mark location for a defensive point
    local nextBase = (table.getn(aiBrain.TacticalBases) + 1)
    table.insert(aiBrain.TacticalBases,
        {
        Position = intel.Position,
        Name = 'IntelBase'..nextBase,
        }
)
    -- Set an alert for the location
    table.insert(aiBrain.BaseMonitor.AlertsTable,
        {
        Position = intel.Position,
        Threat = intel.Threat,
        }
)
    aiBrain.BaseMonitor.AlertSounded = true
    aiBrain:ForkThread(aiBrain.BaseMonitorAlertTimeout, intel.Position)
    aiBrain.BaseMonitor.ActiveAlerts = aiBrain.BaseMonitor.ActiveAlerts + 1
end

--- Checks for threat level at a location and allows filtering of threat types.
---@param aiBrain AIBrain
---@param pos Vector
---@param rings number
---@param ttype string
---@param threatFilters table
---@param enemyIndex number
---@return number
function GetThreatAtPosition(aiBrain, pos, rings, ttype, threatFilters, enemyIndex)
    local threat
    if enemyIndex then
        threat = aiBrain:GetThreatAtPosition(pos, rings, true, ttype, enemyIndex)
    else
        threat = aiBrain:GetThreatAtPosition(pos, rings, true, ttype)
    end
    for k,v in threatFilters do
        local rthreat
        if enemyIndex then
            rthreat = aiBrain:GetThreatAtPosition(pos, rings, true, v, enemyIndex)
        else
            rthreat = aiBrain:GetThreatAtPosition(pos, rings, true, v)
        end
        threat = threat - rthreat
    end
    return threat
end

--- Checks to see if the current enemy has a much higher threat. this can indicate inflated threat or
--- that the AI is close to death. This can allow the AI to send units even if the threat is bugged
--- or give the AI a last stand ability. Throttled to check every 10 seconds at most.
---@param aiBrain AIBrain
---@return boolean
function ThreatBugcheck(aiBrain)
    if not aiBrain:GetCurrentEnemy() then return false end
    if aiBrain.LastThreatBugCheckTime and aiBrain.LastThreatBugCheckTime + 10 > GetGameTimeSeconds() then
        return aiBrain.LastThreatBugCheckResult
    end
    local myStartX, myStartZ = aiBrain:GetArmyStartPos()
    local myIndex = aiBrain:GetArmyIndex()

    local estartX, estartZ = aiBrain:GetCurrentEnemy():GetArmyStartPos()
    local enemyIndex = aiBrain:GetCurrentEnemy():GetArmyIndex()

    local enemyThreat = aiBrain:GetThreatAtPosition({estartX, 0, estartZ}, 1, true, 'Overall', enemyIndex)
    local myThreat = 0 --aiBrain:GetThreatAtPosition({myStartX, 0, myStartZ}, 1, true, 'Overall', myIndex)
    local unitThreat = 0
    local units = AIUtils.GetOwnUnitsAroundPoint(aiBrain, categories.ALLUNITS, {myStartX, 0, myStartZ}, 200)
    for k,v in units do
        if not v.Dead then
            unitThreat = (v:GetBlueprint().Defense.SurfaceThreatLevel or 0) + (v:GetBlueprint().Defense.AirThreatLevel or 0) + (v:GetBlueprint().Defense.SubThreatLevel or 0) + (v:GetBlueprint().Defense.EconomyThreatLevel or 0)
            myThreat = myThreat + unitThreat
        end
    end
    -- LOG('*AI DEBUG: ThreatBugcheck Units: '..table.getn(units)..' Me: '..myThreat..' Enemy: '..enemyThreat)
    aiBrain.LastThreatBugCheckTime = GetGameTimeSeconds()
    aiBrain.LastThreatBugCheckResult = enemyThreat * 3 > myThreat
    if enemyThreat > myThreat * 3 then
        --LOG('*AI DEBUG: Threat is bugged!')
        return true
    end
    return false
end

--- Checks for Land Path Node map marker to verify the map has the appropriate AI markers.
---@param aiBrain AIBrain
---@return boolean
function CheckForMapMarkers(aiBrain)
    local startX, startZ = aiBrain:GetArmyStartPos()
    local LandMarker = AIUtils.AIGetClosestMarkerLocation(aiBrain, 'Land Path Node', startX, startZ)
    if not LandMarker then
        return false
    end
    return true
end

--- Adds support for custom units.
---@param aiBrain AIBrain
function AddCustomUnitSupport(aiBrain)
    aiBrain.CustomUnits = {}
    -- Loop through active mods
    for i, m in __active_mods do
        -- If mod has a CustomUnits folder
        local CustomUnitFiles = DiskFindFiles(m.location..'/lua/CustomUnits', '*.lua')
        -- Loop through files in CustomUnits folder
        for k, v in CustomUnitFiles do
            local tempfile = import(v).UnitList
            -- Add each files entry into the appropriate table
            for plat, tbl in tempfile do
                for fac, entry in tbl do
                    if aiBrain.CustomUnits[plat] and aiBrain.CustomUnits[plat][fac] then
                        table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                    elseif aiBrain.CustomUnits[plat] then
                        aiBrain.CustomUnits[plat][fac] = {}
                        table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                    else
                        aiBrain.CustomUnits[plat] = {}
                        aiBrain.CustomUnits[plat][fac] = {}
                        table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                    end
                end
            end
        end
    end
    -- FAF addition start, adds custom unit support to .scd mods
    local CustomUnitFiles = DiskFindFiles('/lua/CustomUnits', '*.lua')
    for k, v in CustomUnitFiles do
        local tempfile = import(v).UnitList
        -- Add each files entry into the appropriate table
        for plat, tbl in tempfile do
            for fac, entry in tbl do
                if aiBrain.CustomUnits[plat] and aiBrain.CustomUnits[plat][fac] then
                    table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                elseif aiBrain.CustomUnits[plat] then
                    aiBrain.CustomUnits[plat][fac] = {}
                    table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                else
                    aiBrain.CustomUnits[plat] = {}
                    aiBrain.CustomUnits[plat][fac] = {}
                    table.insert(aiBrain.CustomUnits[plat][fac], { entry[1], entry[2] })
                end
            end
        end
    end
    -- FAF addition end
end

--- Unused (used for Nomads)
---@param aiBrain AIBrain
function AddCustomFactionSupport(aiBrain)
    aiBrain.CustomFactions = {}
    for i, m in __active_mods do
        -- LOG('*AI DEBUG: Checking mod: '..m.name..' for custom factions')
        local CustomFacFiles = DiskFindFiles(m.location..'/lua/CustomFactions', '*.lua')
        -- LOG('*AI DEBUG: Custom faction files found: '..repr(CustomFacFiles))
        for k, v in CustomFacFiles do
            local tempfile = import(v).FactionList
            for x, z in tempfile do
                -- LOG('*AI DEBUG: Adding faction: '..z.cat)
                table.insert(aiBrain.CustomFactions, z)
            end
        end
    end
end

--- Finds a custom engineer built unit to replace a default one.
---@param aiBrain AIBrain
---@param building Unit
---@param faction string
---@param buildingTmpl string
---@return boolean|table
function GetTemplateReplacement(aiBrain, building, faction, buildingTmpl)
    local retTemplate = false
    local templateData = aiBrain.CustomUnits[building]
    -- check if we have an original building
    local BuildingExist = nil
    for k,v in buildingTmpl do
        if v[1] == building then
            BuildingExist = true
            break
        end
    end
    -- If there are Custom Units for this unit type and faction
    if templateData and templateData[faction] then
        local rand = Random(1,100)
        local possibles = {}
        -- Add all the possibile replacements into a table
        for k,v in templateData[faction] do
            if rand <= v[2] or not BuildingExist then
                table.insert(possibles, v[1])
            end
        end
        -- If we found a possibility
        if not table.empty(possibles) then
            rand = Random(1,table.getn(possibles))
            local customUnitID = possibles[rand]
            retTemplate = { { building, customUnitID, } }
        end
    end
    return retTemplate
end

---@param engineer Unit
---@return string|boolean
function GetEngineerFaction(engineer)
    if EntityCategoryContains(categories.UEF, engineer) then
        return 'UEF'
    elseif EntityCategoryContains(categories.AEON, engineer) then
        return 'Aeon'
    elseif EntityCategoryContains(categories.CYBRAN, engineer) then
        return 'Cybran'
    elseif EntityCategoryContains(categories.SERAPHIM, engineer) then
        return 'Seraphim'
    elseif EntityCategoryContains(categories.NOMADS, engineer) then
        return 'Nomads'
    else
        return false
    end
end

---@param platoonUnits Unit
---@return boolean|number
function GetPlatoonTechLevel(platoonUnits)
    local highest = false
    for k,v in platoonUnits do
        if EntityCategoryContains(categories.TECH3, v) then
            highest = 3
        elseif EntityCategoryContains(categories.TECH2, v) and highest < 3 then
            highest = 2
        elseif EntityCategoryContains(categories.TECH1, v) and highest < 2 then
            highest = 1
        end
        if highest == 3 then break end
    end
    return highest
end

--- Checks to see if the platoon can attack units in the distress area.
---@param aiBrain AIBrain
---@param location Vector
---@param platoon Platoon
---@return boolean
function CanRespondEffectively(aiBrain, location, platoon)
    -- Get units in area
    local targets = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, location, 32, 'Enemy')
    -- If threat of platoon is the same as the threat in the distess area
    if AIAttackUtils.GetAirThreatOfUnits(platoon) > 0 and aiBrain:GetThreatAtPosition(location, 0, true, 'Air') > 0 then
        return true
    elseif AIAttackUtils.GetSurfaceThreatOfUnits(platoon) > 0 and (aiBrain:GetThreatAtPosition(location, 0, true, 'Land') > 0 or aiBrain:GetThreatAtPosition(location, 0, true, 'Naval') > 0) then
        return true
    end
    -- If no visible targets go anyway
    if table.empty(targets) then
        return true
    end
    return false
end

--- Function to handle AI map pings.
---@param position Vector
---@param pingType string
---@param army Army
function AISendPing(position, pingType, army)
    local PingTypes = {
       alert = {Lifetime = 6, Mesh = 'alert_marker', Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UEF_Select_Radar'},
       move = {Lifetime = 6, Mesh = 'move', Ring = '/game/marker/ring_blue02-blur.dds', ArrowColor = 'blue', Sound = 'Cybran_Select_Radar'},
       attack = {Lifetime = 6, Mesh = 'attack_marker', Ring = '/game/marker/ring_red02-blur.dds', ArrowColor = 'red', Sound = 'Aeon_Select_Radar'},
       marker = {Lifetime = 5, Ring = '/game/marker/ring_yellow02-blur.dds', ArrowColor = 'yellow', Sound = 'UI_Main_IG_Click', Marker = true},
   }
    local data = {Owner = army - 1, Type = pingType, Location = position}
    data = table.merged(data, PingTypes[pingType])
    import("/lua/simping.lua").SpawnPing(data)
end

---@param aigroup string
---@param ainickname string
---@param aiaction string
---@param targetnickname string
---@param delaytime number
function AIDelayChat(aigroup, ainickname, aiaction, targetnickname, delaytime)
    WaitSeconds(delaytime)
    AISendChat(aigroup, ainickname, aiaction, targetnickname)
end

--- Function to handle AI sending chat messages.
---@param aigroup string
---@param ainickname string
---@param aiaction string
---@param targetnickname string
---@param extrachat string
function AISendChat(aigroup, ainickname, aiaction, targetnickname, extrachat)
    if aigroup and not GetArmyData(ainickname):IsDefeated() and (aigroup ~='allies' or AIHasAlly(GetArmyData(ainickname))) then
        if aiaction and AIChatText[aiaction] then
            local ranchat = Random(1, table.getn(AIChatText[aiaction]))
            local chattext
            if targetnickname then
                if IsAIArmy(targetnickname) then
                    targetnickname = trim(string.gsub(targetnickname,'%b()', ''))
                end
                chattext = string.gsub(AIChatText[aiaction][ranchat],'%[target%]', targetnickname)
            elseif extrachat then
                chattext = string.gsub(AIChatText[aiaction][ranchat],'%[extra%]', extrachat)
            else
                chattext = AIChatText[aiaction][ranchat]
            end

            SyncAIChat({group=aigroup, text=chattext, sender=ainickname})
        else
            SyncAIChat({group=aigroup, text=aiaction, sender=ainickname})
        end
    end
end

--- Randmonly chooses a taunt and sends it to AISendChat.
---@param aiBrain AIBrain
function AIRandomizeTaunt(aiBrain)
    local factionIndex = aiBrain:GetFactionIndex()
    local tauntid = Random(1,table.getn(AITaunts[factionIndex]))
    aiBrain.LastVocTaunt = GetGameTimeSeconds()
    AISendChat('all', aiBrain.Nickname, '/'..AITaunts[factionIndex][tauntid])
end

--- Sends a response to a human ally's chat message.
---@param data table
function FinishAIChat(data)
    local aiBrain = GetArmyBrain(data.Army)
    if data.NewTarget then
        if data.NewTarget == 'at will' then
            aiBrain.targetoveride = false
            AISendChat('allies', aiBrain.Nickname, 'Targeting at will')
        else
            if IsEnemy(data.NewTarget, data.Army) then
                aiBrain:SetCurrentEnemy(ArmyBrains[data.NewTarget])
                aiBrain.targetoveride = true
                AISendChat('allies', aiBrain.Nickname, 'tcrespond', ArmyBrains[data.NewTarget].Nickname)
            elseif IsAlly(data.NewTarget, data.Army) then
                AISendChat('allies', aiBrain.Nickname, 'tcerrorally', ArmyBrains[data.NewTarget].Nickname)
            end
        end
    elseif data.NewFocus then
        aiBrain.Focus = data.NewFocus
        AISendChat('allies', aiBrain.Nickname, 'genericchat')
    elseif data.CurrentFocus then
        local focus = 'nothing'
        if aiBrain.Focus then
            focus = aiBrain.Focus
        end
        AISendChat('allies', aiBrain.Nickname, 'focuschat', nil, focus)
    elseif data.GiveEngineer and not GetArmyBrain(data.ToArmy):IsDefeated() then
        local cats = {categories.TECH3, categories.TECH2, categories.TECH1}
        local given = false
        for _, cat in cats do
            local engies = aiBrain:GetListOfUnits(categories.ENGINEER * cat - categories.COMMAND - categories.SUBCOMMANDER - categories.ENGINEERSTATION, false)
            for k,v in engies do
                if not v.Dead and v:GetParent() == v then
                    if v.PlatoonHandle and aiBrain:PlatoonExists(v.PlatoonHandle) then
                        v.PlatoonHandle:RemoveEngineerCallbacksSorian()
                        v.PlatoonHandle:Stop()
                        v.PlatoonHandle:PlatoonDisbandNoAssign()
                    end
                    if v.NotBuildingThread then
                        KillThread(v.NotBuildingThread)
                        v.NotBuildingThread = nil
                    end
                    if v.ProcessBuild then
                        KillThread(v.ProcessBuild)
                        v.ProcessBuild = nil
                    end
                    v.BuilderManagerData.EngineerManager:RemoveUnit(v)
                    IssueStop({v})
                    IssueClearCommands({v})
                    AISendPing(v:GetPosition(), 'move', data.Army)
                    AISendChat(data.ToArmy, aiBrain.Nickname, 'giveengineer')
                    ChangeUnitArmy(v,data.ToArmy)
                    given = true
                    break
                end
            end
            if given then break end
        end
    elseif data.Command then
        if data.Text == 'target' then
            AISendChat(data.ToArmy, aiBrain.Nickname, 'target <enemy>: <enemy> is the name of the enemy you want me to attack or \'at will\' if you want me to choose targets myself.')
        elseif data.Text == 'focus' then
            AISendChat(data.ToArmy, aiBrain.Nickname, 'focus <strat>: <strat> is the name of the strategy you want me to use or \'at will\' if you want me to choose strategies myself. Available strategies: rush arty, rush nuke, air.')
        else
            AISendChat(data.ToArmy, aiBrain.Nickname, 'Available Commands: focus <strat or at will>, target <enemy or at will>, current focus, give me an engineer, command <target or strat>.')
        end
    end
end

--- Handles the AIs reaction to a human ally's ping.
---@param aiBrain AIBrain
---@param pingData table
function AIHandlePing(aiBrain, pingData)
    if pingData.Type == 'move' then
        local nextping = (table.getn(aiBrain.TacticalBases) + 1)
        table.insert(aiBrain.TacticalBases,
            {
            Position = pingData.Location,
            Name = 'BasePing'..nextping,
            }
        )
        AISendChat('allies', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'genericchat')
    elseif pingData.Type == 'attack' then
        table.insert(aiBrain.AttackPoints,
            {
            Position = pingData.Location,
            }
        )
        aiBrain:ForkThread(aiBrain.AttackPointsTimeout, pingData.Location)
        AISendChat('allies', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'genericchat')
    elseif pingData.Type == 'alert' then
        table.insert(aiBrain.BaseMonitor.AlertsTable,
            {
            Position = pingData.Location,
            Threat = 80,
            }
        )
        aiBrain.BaseMonitor.AlertSounded = true
        aiBrain:ForkThread(aiBrain.BaseMonitorAlertTimeout, pingData.Location)
        aiBrain.BaseMonitor.ActiveAlerts = aiBrain.BaseMonitor.ActiveAlerts + 1
        AISendChat('allies', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'genericchat')
    end
end

--- Finds the closest unit to attack that is not obstructed by terrain.
---@param aiBrain AIBrain
---@param platoon Platoon
---@param squad string
---@param maxRange number
---@param atkCat string
---@param selectedWeaponArc any
---@param turretPitch any
---@return boolean
function FindClosestUnitPosToAttack(aiBrain, platoon, squad, maxRange, atkCat, selectedWeaponArc, turretPitch)
    local position = platoon:GetPlatoonPosition()
    if not aiBrain or not position or not maxRange then
        return false
    end
    local targetUnits = aiBrain:GetUnitsAroundPoint(atkCat, position, maxRange, 'Enemy')
    local retUnit = false
    local distance = 999999
    for num, unit in targetUnits do
        if not unit.Dead then
            local unitPos = unit:GetPosition()
            -- If unit is close enough, can be attacked, and not obstructed
            if (not retUnit or Utils.XZDistanceTwoVectors(position, unitPos) < distance) and platoon:CanAttackTarget(squad, unit) and (not turretPitch or not CheckBlockingTerrain(position, unitPos, selectedWeaponArc, turretPitch)) then
                retUnit = unit -- :GetPosition()
                distance = Utils.XZDistanceTwoVectors(position, unitPos)
            end
        end
    end
    if retUnit then
        return retUnit
    end
    return false
end

--- Allows the TML to lead a target to hit them while moving.
--- #### TML Specs(MU = Map Units): 
---     - Max Speed: 12MU/sec
---     - Acceleration: 3MU/sec/sec
---     - Launch Time: ~3 seconds
---@param platoon Platoon
---@param target Unit
---@return Vector
function LeadTarget(platoon, target)
    -- Get launcher and target position
    local LauncherPos = platoon:GetPlatoonPosition()
    local TargetPos = target:GetPosition()
    -- Get target position in 1 second intervals.
    -- This allows us to get speed and direction from the target
    local TargetStartPosition=0
    local Target1SecPos=0
    local Target2SecPos=0
    local XmovePerSec=0
    local YmovePerSec=0
    local XmovePerSecCheck=-1
    local YmovePerSecCheck=-1
    -- Check if the target is runing straight or circling
    -- If x/y and xcheck/ycheck are equal, we can be sure the target is moving straight
    -- in one direction. At least for the last 2 seconds.
    local LoopSaveGuard = 0
    while (XmovePerSec ~= XmovePerSecCheck or YmovePerSec ~= YmovePerSecCheck) and LoopSaveGuard < 10 do
        -- 1st position of target
        TargetPos = target:GetPosition()
        TargetStartPosition = {TargetPos[1], 0, TargetPos[3]}
        WaitTicks(10)
        -- 2nd position of target after 1 second
        TargetPos = target:GetPosition()
        Target1SecPos = {TargetPos[1], 0, TargetPos[3]}
        XmovePerSec = (TargetStartPosition[1] - Target1SecPos[1])
        YmovePerSec = (TargetStartPosition[3] - Target1SecPos[3])
        WaitTicks(10)
        -- 3rd position of target after 2 seconds to verify straight movement
        TargetPos = target:GetPosition()
        Target2SecPos = {TargetPos[1], TargetPos[2], TargetPos[3]}
        XmovePerSecCheck = (Target1SecPos[1] - Target2SecPos[1])
        YmovePerSecCheck = (Target1SecPos[3] - Target2SecPos[3])
        --We leave the while-do check after 10 loops (20 seconds) and try collateral damage
        --This can happen if a player try to fool the targetingsystem by circling a unit.
        LoopSaveGuard = LoopSaveGuard + 1
    end
    -- Get launcher position height
    local fromheight = GetTerrainHeight(LauncherPos[1], LauncherPos[3])
    if GetSurfaceHeight(LauncherPos[1], LauncherPos[3]) > fromheight then
        fromheight = GetSurfaceHeight(LauncherPos[1], LauncherPos[3])
    end
    -- Get target position height
    local toheight = GetTerrainHeight(Target2SecPos[1], Target2SecPos[3])
    if GetSurfaceHeight(Target2SecPos[1], Target2SecPos[3]) > toheight then
        toheight = GetSurfaceHeight(Target2SecPos[1], Target2SecPos[3])
    end
    -- Get height difference between launcher position and target position
    -- Adjust for height difference by dividing the height difference by the missiles max speed
    local HeightDifference = math.abs(fromheight - toheight) / 12
    -- Speed up time is distance the missile will travel while reaching max speed (~22.47 MapUnits)
    -- divided by the missiles max speed (12) which is equal to 1.8725 seconds flight time
    local SpeedUpTime = 22.47 / 12
    --  Missile needs 3 seconds to launch
    local LaunchTime = 3
    -- Get distance from launcher position to targets starting position and position it moved to after 1 second
    local dist1 = VDist2(LauncherPos[1], LauncherPos[3], Target1SecPos[1], Target1SecPos[3])
    local dist2 = VDist2(LauncherPos[1], LauncherPos[3], Target2SecPos[1], Target2SecPos[3])
    -- Missile has a faster turn rate when targeting targets < 50 MU away, so it will level off faster
    local LevelOffTime = 0.25
    local CollisionRangeAdjust = 0
    if dist2 < 50 then
        LevelOffTime = 0.02
        CollisionRangeAdjust = 2
    end
    -- Divide both distances by missiles max speed to get time to impact
    local time1 = (dist1 / 12) + LaunchTime + SpeedUpTime + LevelOffTime + HeightDifference
    local time2 = (dist2 / 12) + LaunchTime + SpeedUpTime + LevelOffTime + HeightDifference
    -- Get the missile travel time by extrapolating speed and time from dist1 and dist2
    local MissileTravelTime = (time2 + (time2 - time1)) + ((time2 - time1) * time2)
    -- Now adding all times to get final missile flight time to the position where the target will be
    local MissileImpactTime = MissileTravelTime + LaunchTime + SpeedUpTime + LevelOffTime + HeightDifference
    -- Create missile impact corrdinates based on movePerSec * MissileImpactTime
    local MissileImpactX = Target2SecPos[1] - (XmovePerSec * MissileImpactTime)
    local MissileImpactY = Target2SecPos[3] - (YmovePerSec * MissileImpactTime)
    -- Adjust for targets CollisionOffsetY. If the hitbox of the unit is above the ground
    -- we nedd to fire "behind" the target, so we hit the unit in midair.
    local TargetCollisionBoxAdjust = 0
    local TargetBluePrint = target:GetBlueprint()
    if TargetBluePrint.CollisionOffsetY and TargetBluePrint.CollisionOffsetY > 0 then
        -- if the unit is far away we need to target farther behind the target because of the projectile flight angel
        local DistanceOffset = (100 / 256 * dist2) * 0.06
        TargetCollisionBoxAdjust = TargetBluePrint.CollisionOffsetY * CollisionRangeAdjust + DistanceOffset
    end
    -- To calculate the Adjustment behind the target we use a variation of the Pythagorean theorem. (Percent scale technique)
    -- (a²+b²=c²) If we add x% to c² then also a² and b² are x% larger. (a²)*x% + (b²)*x% = (c²)*x%
    local Hypotenuse = VDist2(LauncherPos[1], LauncherPos[3], MissileImpactX, MissileImpactY)
    local HypotenuseScale = 100 / Hypotenuse * TargetCollisionBoxAdjust
    local aLegScale = (MissileImpactX - LauncherPos[1]) / 100 * HypotenuseScale
    local bLegScale = (MissileImpactY - LauncherPos[3]) / 100 * HypotenuseScale
    -- Add x percent (behind) the target coordinates to get our final missile impact coordinates
    MissileImpactX = MissileImpactX + aLegScale
    MissileImpactY = MissileImpactY + bLegScale
    -- Add some optional randomization to make the AI easier
    local TMLRandom = tonumber(ScenarioInfo.Options.TMLRandom) or 0
    MissileImpactX = MissileImpactX + (Random(0, TMLRandom) - TMLRandom / 2) / 5
    MissileImpactY = MissileImpactY + (Random(0, TMLRandom) - TMLRandom / 2) / 5
    -- Cancel firing if target is outside map boundries
    if MissileImpactX < 0 or MissileImpactY < 0 or MissileImpactX > ScenarioInfo.size[1] or MissileImpactY > ScenarioInfo.size[2] then
        return false
    end
    -- Also cancel if target would be out of weaponrange or inside minimum range.
    local maxRadius = 256
    local minRadius = 15
    local dist3 = VDist2(LauncherPos[1], LauncherPos[3], MissileImpactX, MissileImpactY)
    if dist3 < minRadius or dist3 > maxRadius then
        return false
    end
    -- return extrapolated target position / missile impact coordinates
    return Vector(MissileImpactX, Target2SecPos[2], MissileImpactY)
end

--- Checks to see if there is terrain blocking a unit from hiting a target.
---@param pos Vector
---@param targetPos Vector
---@param firingArc any
---@param turretPitch any
---@return boolean
function CheckBlockingTerrain(pos, targetPos, firingArc, turretPitch)
    -- High firing arc indicates Artillery unit
    if firingArc == 'high' then
        return false
    end
    -- Distance to target
    local distance = VDist2Sq(pos[1], pos[3], targetPos[1], targetPos[3])
    distance = math.sqrt(distance)

    -- This allows us to break up the distance into 5 points so we can check
    -- 5 points between the unit and target
    local step = math.ceil(distance / 5)
    local xstep = (pos[1] - targetPos[1]) / step
    local ystep = (pos[3] - targetPos[3]) / step

    -- Loop through the 5 points to check for blocking terrain
    -- Start at zero in case there is only 1 step. if we start at 1 with 1 step it wont check it
    for i = 0, step do
        if i > 0 then
            -- We want to check the slope and angle between one point along the path and the next point
            local lastPos = {pos[1] - (xstep * (i - 1)), 0, pos[3] - (ystep * (i - 1))}
            local nextpos = {pos[1] - (xstep * i), 0, pos[3] - (ystep * i)}

            -- Get height for both points
            local lastPosHeight = GetTerrainHeight(lastPos[1], lastPos[3])
            local nextposHeight = GetTerrainHeight(nextpos[1], nextpos[3])
            if GetSurfaceHeight(lastPos[1], lastPos[3]) > lastPosHeight then
                lastPosHeight = GetSurfaceHeight(lastPos[1], lastPos[3])
            end
            if GetSurfaceHeight(nextpos[1], nextpos[3]) > nextposHeight then
                nextposHeight = GetSurfaceHeight(nextpos[1], nextpos[3])
            else
                nextposHeight = nextposHeight + .5
            end
            -- Get the slope and angle between the 2 points
            local angle, slope = GetSlopeAngle(lastPos, nextpos, lastPosHeight, nextposHeight)
            -- There is an obstruction
            if angle > turretPitch then
                return true
            end
        end
    end
    return false
end

--- Gets the slope and angle between 2 points.
---@param pos Vector
---@param targetPos Vector
---@param posHeight number
---@param targetHeight number
---@return number
---@return number
function GetSlopeAngle(pos, targetPos, posHeight, targetHeight)
    -- Distance between points
    local distance = VDist2Sq(pos[1], pos[3], targetPos[1], targetPos[3])
    distance = math.sqrt(distance)

    local heightDif

    -- If heights are the same return 0
    -- Otherwise we want the absolute value of the height difference
    if targetHeight == posHeight then
        return 0
    else
        heightDif = math.abs(targetHeight - posHeight)
    end

    -- Get the slope and angle between the points
    local slope = heightDif / distance
    local angle = math.deg(math.atan(slope))

    return angle, slope
end

--- Gets number of units assisting a unit.
---@param aiBrain AIBrain
---@param Unit Unit
---@return number
function GetGuards(aiBrain, Unit)
    local engs = aiBrain:GetUnitsAroundPoint(categories.ENGINEER - categories.POD, Unit:GetPosition(), 10, 'Ally')
    local count = 0
    local UpgradesFrom = Unit:GetBlueprint().General.UpgradesFrom
    for k,v in engs do
        if v.UnitBeingBuilt == Unit then
            count = count + 1
        end
    end
    if UpgradesFrom and UpgradesFrom ~= 'none' then -- Used to filter out upgrading units
        local oldCat = ParseEntityCategory(UpgradesFrom)
        local oldUnit = aiBrain:GetUnitsAroundPoint(oldCat, Unit:GetPosition(), 0, 'Ally')
        if oldUnit then
            count = count + 1
        end
    end
    return count
end

--- Gets the number of units guarding a unit.
---@param aiBrain AIBrain
---@param Unit Unit
---@param cat EntityCategory
---@return number
function GetGuardCount(aiBrain, Unit, cat)
    local guards = Unit:GetGuards()
    local count = 0
    for k,v in guards do
        if not v.Dead and EntityCategoryContains(cat, v) then
            count = count + 1
        end
    end
    return count
end

--- Finds targets for the AIs nuke launchers and fires them all simultaneously.
---@param aiBrain AIBrain
function Nuke(aiBrain)
    local atkPri = { 'STRUCTURE STRATEGIC EXPERIMENTAL', 'EXPERIMENTAL ARTILLERY OVERLAYINDIRECTFIRE', 'EXPERIMENTAL ORBITALSYSTEM', 'STRUCTURE ARTILLERY TECH3', 'STRUCTURE NUKE TECH3', 'EXPERIMENTAL ENERGYPRODUCTION STRUCTURE', 'COMMAND', 'TECH3 MASSFABRICATION STRUCTURE', 'TECH3 ENERGYPRODUCTION STRUCTURE', 'TECH2 STRATEGIC STRUCTURE', 'TECH3 DEFENSE STRUCTURE', 'TECH2 DEFENSE STRUCTURE', 'TECH2 ENERGYPRODUCTION STRUCTURE' }
    local maxFire = false
    local Nukes = aiBrain:GetListOfUnits(categories.NUKE * categories.SILO * categories.STRUCTURE * categories.TECH3, true)
    local nukeCount = 0
    local launcher
    local bp
    local weapon
    local maxRadius
    -- This table keeps a list of all the nukes that have fired this round
    local fired = {}
    for k, v in Nukes do
        if not maxFire then
            bp = v:GetBlueprint()
            weapon = bp.Weapon[1]
            maxRadius = weapon.MaxRadius
            launcher = v
            maxFire = true
        end
        -- Add launcher to the fired table with a value of false
        fired[v] = false
        if v:GetNukeSiloAmmoCount() > 0 then
            nukeCount = nukeCount + 1
        end
    end
    -- If we have nukes
    if nukeCount > 0 then
        -- This table keeps track of all targets fired at this round to keep from firing multiple nukes
        -- at the same target unless we have to to overwhelm anti-nukes.
        local oldTarget = {}
        local target
        local fireCount = 0
        local aitarget
        local tarPosition
        local antiNukes
        -- Repeat until all launchers have fired or we run out of targets
        repeat
            -- Get a target and target position. This function also ensures that we fire at a new target
            -- and one that we have enough nukes to hit the target
            target, tarPosition, antiNukes = AIUtils.AIFindBrainNukeTargetInRangeSorian(aiBrain, launcher, maxRadius, atkPri, nukeCount, oldTarget)
            if target then
                -- Send a message to allies letting them know we are letting nukes fly
                -- Also ping the map where we are targeting
                aitarget = target:GetAIBrain():GetArmyIndex()
                AISendChat('allies', ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'nukechat', ArmyBrains[aitarget].Nickname)
                AISendPing(tarPosition, 'attack', aiBrain:GetArmyIndex())
                -- Randomly taunt the enemy
                if Random(1,5) == 3 and (not aiBrain.LastTaunt or GetGameTimeSeconds() - aiBrain.LastTaunt > 90) then
                    aiBrain.LastTaunt = GetGameTimeSeconds()
                    AISendChat(aitarget, ArmyBrains[aiBrain:GetArmyIndex()].Nickname, 'nuketaunt')
                end
                -- Get anti-nukes int the area
                -- local antiNukes = aiBrain:GetNumUnitsAroundPoint(categories.ANTIMISSILE * categories.TECH3 * categories.STRUCTURE, tarPosition, 90, 'Enemy')
                local nukesToFire = {}
                for k, v in Nukes do
                    -- If we have nukes that have not fired yet
                    if v:GetNukeSiloAmmoCount() > 0 and not fired[v] then
                        table.insert(nukesToFire, v)
                        nukeCount = nukeCount - 1
                        fireCount = fireCount + 1
                        fired[v] = true
                    end
                    -- If we fired enough nukes at the target, or we are out of nukes
                    if fireCount > (antiNukes + 2) or nukeCount == 0 or (fireCount > 0 and antiNukes == 0) then
                        break
                    end
                end
                aiBrain:ForkThread(LaunchNukesTimed, nukesToFire, tarPosition)
            end
            -- Keep track of old targets
            table.insert(oldTarget, target)
            fireCount = 0
            -- WaitSeconds(15)
        until nukeCount <= 0 or target == false
    end
end

---@param aiBrain AIBrain
---@param pos Vector
---@param massCost number
---@return boolean
function CheckCost(aiBrain, pos, massCost)
    if massCost == 0 then
        massCost = 12000
    end
    local units = aiBrain:GetUnitsAroundPoint(categories.ALLUNITS, pos, 30, 'Enemy')
    local massValue = 0
    for k,v in units do
        if not v.Dead then
            local unitValue = (v:GetBlueprint().Economy.BuildCostMass * v:GetFractionComplete())
            massValue = massValue + unitValue
        end
        if massValue > massCost then return true end
    end
    return false
end

--- Launches nukes so that they all reach the target at about the same time.
---@param aiBrain AIBrain
---@param nukesToFire table
---@param target Unit
function LaunchNukesTimed(aiBrain, nukesToFire, target)
    local nukes = {}
    for k,v in nukesToFire do
        local pos = v:GetPosition()
        local timeToTarget = Round(math.sqrt(VDist2Sq(target[1], target[3], pos[1], pos[3]))/40)
        table.insert(nukes,{unit = v, flightTime = timeToTarget})
    end
    table.sort(nukes, function(a,b) return a.flightTime > b.flightTime end)
    local lastFT = nukes[1].flightTime
    for k,v in nukes do
        WaitSeconds(lastFT - v.flightTime)
        IssueNuke({v.unit}, target)
        lastFT = v.flightTime
    end
end

--- Finds unifinished units in an area.
---@param aiBrain AIBrain
---@param locationType string
---@param buildCat EntityCategory
---@return boolean
function FindUnfinishedUnits(aiBrain, locationType, buildCat)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local unfinished = aiBrain:GetUnitsAroundPoint(buildCat, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    local retUnfinished = false
    for num, unit in unfinished do
        local donePercent = unit:GetFractionComplete()
        if donePercent < 1 and GetGuards(aiBrain, unit) < 1 and not unit:IsUnitState('Upgrading') then
            retUnfinished = unit
            break
        end
    end
    return retUnfinished
end

--- Finds damaged shields in an area.
---@param aiBrain AIBrain
---@param locationType string
---@param buildCat EntityCategory
---@return boolean
function FindDamagedShield(aiBrain, locationType, buildCat)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager
    local shields = aiBrain:GetUnitsAroundPoint(buildCat, engineerManager:GetLocationCoords(), engineerManager.Radius, 'Ally')
    local retShield = false
    for num, unit in shields do
        if not unit.Dead and unit:ShieldIsOn() then
            local shieldPercent = (unit.MyShield:GetHealth() / unit.MyShield:GetMaxHealth())
            if shieldPercent < 1 and GetGuards(aiBrain, unit) < 3 then
                retShield = unit
                break
            end
        end
    end
    return retShield
end

--- Counts units between 2 points.
---@param aiBrain AIBrain
---@param start number
---@param finish number
---@param unitCat EntityCategory
---@param stepby any
---@param alliance string
---@return number
function NumberofUnitsBetweenPoints(aiBrain, start, finish, unitCat, stepby, alliance)
    if type(unitCat) == 'string' then
        unitCat = ParseEntityCategory(unitCat)
    end

    local returnNum = 0

    -- Get distance between the points
    local distance = math.sqrt(VDist2Sq(start[1], start[3], finish[1], finish[3]))
    local steps = math.floor(distance / stepby)

    local xstep = (start[1] - finish[1]) / steps
    local ystep = (start[3] - finish[3]) / steps
    -- For each point check to see if the destination is close
    for i = 0, steps do
        local numUnits = aiBrain:GetNumUnitsAroundPoint(unitCat, {finish[1] + (xstep * i),0 , finish[3] + (ystep * i)}, stepby, alliance)
        returnNum = returnNum + numUnits
    end

    return returnNum
end

--- Checks to see if the destination is between the 2 given path points.
---@param destination Vector
---@param start Vector
---@param finish Vector
---@return boolean
function DestinationBetweenPoints(destination, start, finish)
    -- Get distance between the points
    local distance = VDist2Sq(start[1], start[3], finish[1], finish[3])
    distance = math.sqrt(distance)

    -- This allows us to break the distance up and check points every 100 MU
    local step = math.ceil(distance / 100)
    local xstep = (start[1] - finish[1]) / step
    local ystep = (start[3] - finish[3]) / step
    -- For each point check to see if the destination is close
    for i = 1, step do
        -- DrawCircle({start[1] - (xstep * i), 0, start[3] - (ystep * i)}, 5, '0000ff')
        -- DrawCircle({start[1] - (xstep * i), 0, start[3] - (ystep * i)}, 100, '0000ff')
        if VDist2Sq(start[1] - (xstep * i), start[3] - (ystep * i), finish[1], finish[3]) <= 10000 then break end
        if VDist2Sq(start[1] - (xstep * i), start[3] - (ystep * i), destination[1], destination[3]) < 10000 then
            return true
        end
    end
    return false
end

--- Gets the number of AIs in the game.
---@param aiBrain AIBrain
---@return number
function GetNumberOfAIs(aiBrain)
    local numberofAIs = 0
    for k,v in ArmyBrains do
        if not v:IsDefeated() and not ArmyIsCivilian(v:GetArmyIndex()) and v:GetArmyIndex() ~= aiBrain:GetArmyIndex() then
            numberofAIs = numberofAIs + 1
        end
    end
    return numberofAIs
end

--- Rounds a number to the specifed places.
---@param x number Number to round
---@param places number Number of places to round to
---@return number
function Round(x, places)
    local result
    local shift
    if places then
        shift = math.pow(10, places)
        result = math.floor(x * shift + 0.5) / shift
        return result
    else
        result = math.floor(x + 0.5)
        return result
    end
end

--- Trims blank spaces around a string.
---@param s string
---@return string
function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

---@param aiBrain AIBrain
---@return any
---@return any
function GetRandomEnemyPos(aiBrain)
    for k, v in ArmyBrains do
        if IsEnemy(aiBrain:GetArmyIndex(), v:GetArmyIndex()) and not v:IsDefeated() then
            if v:GetArmyStartPos() then
                local ePos = v:GetArmyStartPos()
                return ePos[1], ePos[3]
            end
        end
    end
    return false
end

--- Returns army data for an army.
---@param army Army
---@return table
function GetArmyData(army)
    local result
    if type(army) == 'string' then
        for i, v in ArmyBrains do
            if v.Nickname == army then
                result = v
                break
            end
        end
    end
    return result
end

--- Checks to see if the army is an AI.
---@param army Army
---@return boolean
function IsAIArmy(army)
    if type(army) == 'string' then
        for i, v in ArmyBrains do
            if v.Nickname == army and v.BrainType == 'AI' then
                return true
            end
        end
    elseif type(army) == 'number' then
        if ArmyBrains[army].BrainType == 'AI' then
            return true
        end
    end
    return false
end

--- Checks to see if an AI has an ally.
---@param army Army
---@return boolean
function AIHasAlly(army)
    for k, v in ArmyBrains do
        if IsAlly(army:GetArmyIndex(), v:GetArmyIndex()) and army:GetArmyIndex() ~= v:GetArmyIndex() and not v:IsDefeated() then
            return true
        end
    end
    return false
end

--- Converts seconds into eaier to read time.
---@param seconds number
---@return string
function TimeConvert(seconds)
    local MathFloor = math.floor
    local hours = MathFloor(seconds / 3600)
    seconds = seconds - hours * 3600
    local minutes = MathFloor(seconds / 60)
    seconds = seconds - minutes * 60
    return ("%02d:%02d:%02d"):format(hours, minutes, seconds)
end

-- Small function the draw intel points on the map for debugging
---@param aiBrain AIBrain
function DrawIntel(aiBrain)
    threatColor = {
        -- ThreatType = { ARGB value }
        StructuresNotMex = 'ff00ff00', -- Green
        Commander = 'ff00ffff', -- Cyan
        Experimental = 'ffff0000', -- Red
        Artillery = 'ffffff00', -- Yellow
        Land = 'ffff9600', -- Orange
    }
    while true do
        if aiBrain:GetArmyIndex() == GetFocusArmy() then
            for k, v in aiBrain.InterestList.HighPriority do
                if threatColor[v.Type] then
                    DrawCircle(v.Position, 1, threatColor[v.Type])
                    DrawCircle(v.Position, 3, threatColor[v.Type])
                    DrawCircle(v.Position, 5, threatColor[v.Type])
                end
            end
        end
        WaitSeconds(2)
    end
end

-- Deprecated functions / unused
function GiveAwayMyCrap(aiBrain)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function GiveAwayMyCrap() called.')
end
function AIMicro(aiBrain, platoon, target, threatatLocation, mySurfaceThreat)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function AIMicro() called.')
end
function CircleAround(aiBrain, platoon, target)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function CircleAround() called.')
end
function OrderedRetreat(aiBrain, platoon)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function OrderedRetreat() called.')
end
function LeadTargetArtillery(platoon, unit, target)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function LeadTargetArtillery() called.')
end
function MajorLandThreatExists(aiBrain)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function MajorLandThreatExists() called.')
end
function MajorAirThreatExists(aiBrain)
    WARN('[sorianutilities.lua '..debug.getinfo(1).currentline..'] - Deprecated function MajorAirThreatExists() called.')
end

-- Kept for mod support
local Mods = import("/lua/mods.lua")