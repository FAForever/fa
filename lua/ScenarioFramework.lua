-----------------------------------------------------------------
-- File       : /lua/scenarioFramework.lua
-- Authors    : John Comes, Drew Staltman
-- Summary    : Functions for use in the scenario scripts.
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@class Dialogue : SoundBlueprint
---@field duration number
---@field text string
---@field vid string
---@field delay number
---@field faction string

---@class DialogueTable : table<Dialogue>
---@field Callback? fun()
---@field Critical? boolean
---@field Flushed boolean

---@class MovieTable
---@field [1] string path/name
---@field [2] string bank
---@field [3] string cue
---@field [4] string faction

local SyncVoice = import("/lua/simsyncutils.lua").SyncVoice
local CategoryToString = import("/lua/sim/categoryutils.lua").ToString
local Cinematics = import("/lua/cinematics.lua")
local Game = import("/lua/game.lua")
local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local SimCamera = import("/lua/simcamera.lua").SimCamera
local SimUIVars = import("/lua/sim/simuistate.lua")
local TriggerFile = import("/lua/scenariotriggers.lua")
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker

Objectives = import("/lua/simobjectives.lua")
PingGroups = import("/lua/simpinggroup.lua")

---@class Team
---@field ArmyCount number
---@field Armies string[] names of armies in team
---@field LastRecallVoteTime number game tick of last recall vote


local PauseUnitDeathActive = false


--- Causes the game to exit immediately
function ExitGame()
    Sync.RequestingExit = true
end

--- Ends an operation
---@param success boolean instructs UI which dialog to show
---@param allPrimary boolean
---@param allSecondary boolean
---@param allBonus boolean
function EndOperation(success, allPrimary, allSecondary, allBonus)
    local opFile = string.gsub(ScenarioInfo.Options.ScenarioFile, 'scenario', 'operation')
    local opData
    if DiskGetFileInfo(opFile) then
        opData = import(opFile)
    end

    import("/lua/sim/matchstate.lua").CallEndGame() -- We need this here to populate the score screen

    ForkThread(function()
        WaitSeconds(3) -- Wait for the stats to be synced
        UnlockInput()
        EndOperationT {
            success = success,
            difficulty = ScenarioInfo.Options.Difficulty,
            allPrimary = allPrimary,
            allSecondary = allSecondary,
            allBonus = allBonus,
            faction = ScenarioInfo.LocalFaction,
            opData = opData.operationData
        }
    end)
end

---@alias FactionSelectData {Faction: "aeon" | "cybran" | "uef"}

local factionCallbacks = {}
--- Pops up a dialog to ask the user what faction they want to play
---@param callback fun(data: FactionSelectData)
function RequestPlayerFaction(callback)
    Sync.RequestPlayerFaction = true
    if callback then
        table.insert(factionCallbacks, callback)
    end
end

--- Hook for player requested faction
---@param data FactionSelectData
function OnFactionSelect(data)
    if ScenarioInfo.campaignInfo then
        ScenarioInfo.campaignInfo.campaignID = data.Faction
    end
    if not table.empty(factionCallbacks) then
        for _, callback in factionCallbacks do
            if callback then
                callback(data)
            end
        end
    else
        WARN('I chose ', data.Faction, ' but I dont have a callback set!')
    end
end

--- Ends an operation where the data is already provided in table form (just a wrapper for sync)
---@param opData table
function EndOperationT(opData)
    Sync.OperationComplete = opData
end

CreateAreaTrigger = TriggerFile.CreateAreaTrigger
CreateMultipleAreaTrigger = TriggerFile.CreateMultipleAreaTrigger

local timerThread = nil
--- Creates a timer that runs `callback` after `seconds` have passed, calling `onTickSecond` with
--- the current number of seconds left on the timer if `doOnTickSecond` is set. This includes the
--- starting duration, but also 0--note that this adds an extra second.
--- If `name` is supplied, the callback is called with TriggerManager and the name as arguments.
---@param callback function
---@param seconds number
---@param name? string
---@param doOnTickSecond? boolean
---@param onTickSecond? fun(seconds: number)
---@return thread
function CreateTimerTrigger(callback, seconds, name, doOnTickSecond, onTickSecond)
    timerThread = TriggerFile.CreateTimerTrigger(callback, seconds, name, doOnTickSecond, onTickSecond)
    return timerThread
end

--- Stops the last timer set by `CreateTimerTrigger` and resets the objective timer
function ResetUITimer()
    if timerThread then
        Sync.ObjectiveTimer = 0
        KillThread(timerThread)
    end
end

CreateUnitDamagedTrigger = TriggerFile.CreateUnitDamagedTrigger

---
---@param callback any
---@param aiBrain AIBrain
---@param category EntityCategory
---@param percent number
function CreateUnitPercentageBuiltTrigger(callback, aiBrain, category, percent)
    aiBrain:AddUnitBuiltPercentageCallback(callback, category, percent)
end

CreateUnitDeathTrigger = TriggerFile.CreateUnitDeathTrigger

--- Sets a unit's death to be paused. It is unpaused globally, since this usually only
--- happens to one unit at a time (e.g. the camera zooms in an ACU before it explodes)
---@param unit Unit
function PauseUnitDeath(unit)
    if unit and not unit.Dead then
        unit.OnKilled = OverrideKilled
        unit.CanBeKilled = false
        unit.DoTakeDamage = OverrideDoDamage
    end
end

--- An override for `Unit.DoTakeDamage` to hold on to the final blow and then release it
--- on the unit once its death is unpaused
---@param self Unit
---@param instigator Unit
---@param amount number
---@param vector any
---@param damageType DamageType
function OverrideDoDamage(self, instigator, amount, vector, damageType)
    local preAdjHealth = self:GetHealth()
    self:AdjustHealth(instigator, -amount)
    local health = self:GetHealth()
    if (health <= 0 or amount > preAdjHealth) and not self.KilledFlag then
        self.KilledFlag = true
        if damageType == 'Reclaimed' then
            self:Destroy()
        else
            local excessDamageRatio = 0.0
            -- Calculate the excess damage amount
            local excess = preAdjHealth - amount
            local maxHealth = self:GetMaxHealth()
            if excess < 0 and maxHealth > 0 then
                excessDamageRatio = -excess / maxHealth
            end
            IssueToUnitClearCommands(self)
            ForkThread(UnlockAndKillUnitThread, self, instigator, damageType, excessDamageRatio)
        end
    end
end
function UnlockAndKillUnitThread(self, instigator, damageType, excessDamageRatio)
    self:DoUnitCallbacks('OnKilled')
    while PauseUnitDeathActive do
        WaitSeconds(1)
    end
    self.CanBeKilled = true
    self:Kill(instigator, damageType, excessDamageRatio)
end

--- An override for `Unit.OnKilled` to make unit death pausing work
---@param self Unit
---@param instigator Unit
---@param type any
---@param overkillRatio number
function OverrideKilled(self, instigator, type, overkillRatio)
    if not self.CanBeKilled then
        self:DoTakeDamage(instigator, 1000000, nil, 'Normal')
        return
    end
    self.Dead = true

    local bp = self:GetBlueprint()
    if self.Layer == 'Water' and bp.Physics.MotionType == 'RULEUMT_Hover' then
        self:PlayUnitSound('HoverKilledOnWater')
    end

    if self.Layer == 'Land' and bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating' then
        self:PlayUnitSound('AmphibiousFloatingKilledOnLand')
    else
        self:PlayUnitSound('Killed')
    end

    -- If factory, destroy what I'm building if I die
    if EntityCategoryContains(categories.FACTORY, self) then
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() ~= 1 then
            self.UnitBeingBuilt:Kill()
        end
    end

    if self.PlayDeathAnimation and not self:IsBeingBuilt() then
        self:ForkThread(self.PlayAnimationThread, 'AnimationDeath')
        self:SetCollisionShape('None')
    end
    self:DestroyTopSpeedEffects()

    if self.UnitBeingTeleported and not self.UnitBeingTeleported.Dead then
        self.UnitBeingTeleported:Destroy()
        self.UnitBeingTeleported = nil
    end

    -- Notify instigator that you killed me.
    if instigator and IsUnit(instigator) then
        instigator:OnKilledUnit(self)
    end

    if self.DeathWeaponEnabled ~= false then
        self:DoDeathWeapon()
    end

    self:DisableShield()
    self:DisableUnitIntel('Killed')
    self:ForkThread(self.DeathThread, overkillRatio, instigator)
end

---
---@param unit Unit
---@param army number
---@param triggerOnGiven boolean
---@return Unit
function GiveUnitToArmy(unit, army, triggerOnGiven)
    -- Shared army mod will result in different players having the same army number
    if unit.Army == army then
        return unit
    end
    -- We need the brain to ignore army cap when transferring the unit
    -- do all necessary steps to set brain to ignore, then un-ignore if necessary the unit cap
    unit.IsBeingTransferred = true

    SetIgnoreArmyUnitCap(army, true)
    IgnoreRestrictions(true)

    local newUnit = ChangeUnitArmy(unit, army)
    local newBrain = ArmyBrains[army]
    if not newBrain.IgnoreArmyCaps then
        SetIgnoreArmyUnitCap(army, false)
    end
    IgnoreRestrictions(false)

    if triggerOnGiven then
        unit:OnGiven(newUnit)
    end

    return newUnit
end

-- When `unit` is killed, reclaimed, or captured it will call the `callback` function provided
---@param callback fun(self: Unit, source: Unit)
---@param unit Unit
function CreateUnitDestroyedTrigger(callback, unit)
    CreateUnitReclaimedTrigger(callback, unit)
    CreateUnitCapturedTrigger(callback, nil, unit)
    CreateUnitDeathTrigger(callback, unit)
end

CreateUnitGivenTrigger = TriggerFile.CreateUnitGivenTrigger
CreateUnitBuiltTrigger = TriggerFile.CreateUnitBuiltTrigger
CreateUnitCapturedTrigger = TriggerFile.CreateUnitCapturedTrigger
CreateUnitStartBeingCapturedTrigger = TriggerFile.CreateUnitStartBeingCapturedTrigger
CreateUnitStopBeingCapturedTrigger = TriggerFile.CreateUnitStopBeingCapturedTrigger
CreateUnitFailedBeingCapturedTrigger = TriggerFile.CreateUnitFailedBeingCapturedTrigger
CreateUnitStartCaptureTrigger = TriggerFile.CreateUnitStartCaptureTrigger
CreateUnitStopCaptureTrigger = TriggerFile.CreateUnitStopCaptureTrigger
CreateUnitFailedCaptureTrigger = TriggerFile.CreateUnitFailedCaptureTrigger
CreateUnitReclaimedTrigger = TriggerFile.CreateUnitReclaimedTrigger
CreateUnitStartReclaimTrigger = TriggerFile.CreateUnitStartReclaimTrigger
CreateUnitStopReclaimTrigger = TriggerFile.CreateUnitStopReclaimTrigger
CreateUnitVeterancyTrigger = TriggerFile.CreateUnitVeterancyTrigger
CreateGroupDeathTrigger = TriggerFile.CreateGroupDeathTrigger

-- When all units in `platoon` are destroyed, `callback` will be called
---@param callback fun(brain: AIBrain, platoon: Platoon)
---@param platoon Platoon
function CreatePlatoonDeathTrigger(callback, platoon)
    platoon:AddDestroyCallback(callback)
end

CreateSubGroupDeathTrigger = TriggerFile.CreateSubGroupDeathTrigger

-- Checks if units of `cat` are within the provided rectangle
---@param cat EntityCategory
---@param area Area | Rectangle
---@return boolean
function UnitsInAreaCheck(cat, area)
    if type(area) == 'string' then
        area = ScenarioUtils.AreaToRect(area)
    end
    local entities = GetUnitsInRect(area)
    if not entities then
        return false
    end
    for _, entity in entities do
        if EntityCategoryContains(cat, entity) then
            return true
        end
    end
    return false
end

-- Returns the number of `cat` units in `area` belonging to `brain`
---@param cat EntityCategory
---@param area Area | Rectangle
---@param brain AIBrain
---@return number
function NumCatUnitsInArea(cat, area, brain)
    if type(area) == 'string' then
        area = ScenarioUtils.AreaToRect(area)
    end

    local entities = GetUnitsInRect(area)
    local result = 0
    if entities then
        local filteredList = EntityCategoryFilterDown(cat, entities)

        for _, entity in filteredList do
            if entity:GetAIBrain() == brain then
                result = result + 1
            end
        end
    end

    return result
end

-- Returns the units in `area` of `cat` belonging to `brain`
---@param cat EntityCategory
---@param area Area | Rectangle
---@param brain AIBrain
---@return Unit[]
function GetCatUnitsInArea(cat, area, brain)
    if type(area) == 'string' then
        area = ScenarioUtils.AreaToRect(area)
    end

    local entities = GetUnitsInRect(area)
    local result = {}
    if entities then
        local filteredList = EntityCategoryFilterDown(cat, entities)

        for _, entity in filteredList do
            if entity:GetAIBrain() == brain then
                table.insert(result, entity)
            end
        end
    end

    return result
end

--- Goes through every unit in `group` and destroys them without explosions
---@param units Unit[]
function DestroyGroup(units)
    for _, unit in units do
        unit:Destroy()
    end
end

CreateUnitDistanceTrigger = TriggerFile.CreateUnitDistanceTrigger
CreateArmyStatTrigger = TriggerFile.CreateArmyStatTrigger
CreateThreatTriggerAroundPosition = TriggerFile.CreateThreatTriggerAroundPosition
CreateThreatTriggerAroundUnit = TriggerFile.CreateThreatTriggerAroundUnit
CreateArmyIntelTrigger = TriggerFile.CreateArmyIntelTrigger
CreateArmyUnitCategoryVeterancyTrigger = TriggerFile.CreateArmyUnitCategoryVeterancyTrigger
CreateUnitToPositionDistanceTrigger = TriggerFile.CreateUnitToPositionDistanceTrigger
CreateUnitToMarkerDistanceTrigger = CreateUnitToPositionDistanceTrigger -- got renamed for some reason
CreateUnitNearTypeTrigger = TriggerFile.CreateUnitNearTypeTrigger

-- platoon functions REQUIRE `squad` to be non-nil when present

-- Orders a platoon to move along a route
---@param platoon Platoon
---@param route (Marker | Vector)[]
---@param squad? string
function PlatoonMoveRoute(platoon, route, squad)
    for _, node in route do
        if type(node) == 'string' then
            node = ScenarioUtils.MarkerToPosition(node)
        end
        if squad then
            platoon:MoveToLocation(node, false, squad)
        else
            platoon:MoveToLocation(node, false)
        end
    end
end

--- Orders platoon to patrol a route
---@param platoon Platoon
---@param route (Marker | Vector)[]
---@param squad? string
function PlatoonPatrolRoute(platoon, route, squad)
    for _, node in route do
        if type(node) == 'string' then
            node = ScenarioUtils.MarkerToPosition(node)
        end
        if squad then
            platoon:Patrol(node, squad)
        else
            platoon:Patrol(node)
        end
    end
end

--- Orders a platoon to attack-move along a route
---@param platoon Platoon
---@param route (Marker | Vector)[]
---@param squad? string
function PlatoonAttackRoute(platoon, route, squad)
    for _, node in route do
        if type(node) == 'string' then
            node = ScenarioUtils.MarkerToPosition(node)
        end
        if squad then
            platoon:AggressiveMoveToLocation(node, squad)
        else
            platoon:AggressiveMoveToLocation(node)
        end
    end
end

--- Orders a platoon to move along a chain
---@param platoon Platoon
---@param chain MarkerChain
---@param squad? string
function PlatoonMoveChain(platoon, chain, squad)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        if squad then
            platoon:MoveToLocation(pos, false, squad)
        else
            platoon:MoveToLocation(pos, false)
        end
    end
end

--- Orders a platoon to patrol along a chain
---@param platoon Platoon
---@param chain MarkerChain
---@param squad? string
function PlatoonPatrolChain(platoon, chain, squad)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        if squad then
            platoon:Patrol(pos, squad)
        else
            platoon:Patrol(pos)
        end
    end
end

--- Orders a platoon to attack-move through a chain
---@param platoon Platoon
---@param chain MarkerChain
---@param squad? string
---@return SimCommand # the last attack-move command
function PlatoonAttackChain(platoon, chain, squad)
    local cmd = false
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        if squad then
            cmd = platoon:AggressiveMoveToLocation(pos, squad)
        else
            cmd = platoon:AggressiveMoveToLocation(pos)
        end
    end

    return cmd
end

--- Orders a group to patrol along a chain
---@param units Unit[]
---@param chain MarkerChain
function GroupPatrolChain(units, chain)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        IssuePatrol(units, pos)
    end
end

--- Orders a group to patrol a route
---@param units Unit[]
---@param route (Marker | Vector)[]
function GroupPatrolRoute(units, route)
    for _, node in route do
        if type(node) == 'string' then
            node = ScenarioUtils.MarkerToPosition(node)
        end
        IssuePatrol(units, node)
    end
end

--- Orders a group to patrol a route in formation
---@param units Unit[]
---@param chain MarkerChain
---@param formation string
function GroupFormPatrolChain(units, chain, formation)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        IssueFormPatrol(units, pos, formation, 0)
    end
end

--- Orders a group to attack-move a along a chain
---@param units Unit[]
---@param chain MarkerChain
function GroupAttackChain(units, chain)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        IssueAggressiveMove(units, pos)
    end
end

--- Orders a group to move along a chain
---@param units Unit[]
---@param chain MarkerChain
function GroupMoveChain(units, chain)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        IssueMove(units, pos)
    end
end

--- Makes `units` to have their work progress start at `0.0` and scale to `1.0` over `time`
---@param units Unit[]
---@param time number
function GroupProgressTimer(units, time)
    ForkThread(GroupProgressTimerThread, units, time)
end

---
---@param units Unit[]
---@param time number
function GroupProgressTimerThread(units, time)
    local currTime = 0
    while currTime < time do
        local prog = currTime / time
        for _, unit in units do
            if not unit.Dead then
                unit:SetWorkProgress(prog)
            end
        end
        WaitSeconds(1)
        currTime = currTime + 1
    end
end

---
---@param dialogueTable DialogueTable
---@param callback? fun()
---@param critical? boolean
---@param speaker? Unit
function Dialogue(dialogueTable, callback, critical, speaker)
    if not (speaker and speaker.Dead) then
        local dTable = table.deepcopy(dialogueTable)
        if callback then
            dTable.Callback = callback
        end
        if critical then
            dTable.Critical = critical
        end
        if ScenarioInfo.DialogueLock == nil then
            ScenarioInfo.DialogueLock = false
            ScenarioInfo.DialogueLockPosition = 0
            ScenarioInfo.DialogueQueue = {}
            ScenarioInfo.DialogueFinished = {}
        end
        table.insert(ScenarioInfo.DialogueQueue, dTable)
        if not ScenarioInfo.DialogueLock then
            ScenarioInfo.DialogueLock = true
            ForkThread(PlayDialogue)
        end
    end
end

---
function FlushDialogueQueue()
    if ScenarioInfo.DialogueQueue then
        for _, dialogue in ScenarioInfo.DialogueQueue do
            dialogue.Flushed = true
        end
    end
end

--- This function sends movie data to the sync table and saves it off for reloading in save games
---@param movieTable MovieTable
---@param text string
function SetupMFDSync(movieTable, text)
    DisplayVideoText(text)
    Sync.PlayMFDMovie = {movieTable[1], movieTable[2], movieTable[3], movieTable[4]}
    ScenarioInfo.DialogueFinished[movieTable[1]] = false

    local tempText = LOC(text)
    local tempData = {}
    local nameStart = tempText:find(']')
    if nameStart ~= nil then
        tempData.name = LOC("<LOC " .. tempText:sub(2, nameStart - 1) .. ">")
        tempData.text = tempText:sub(nameStart + 2)
    else
        tempData.name = "INVALID NAME"
        tempData.text = tempText
        LOG("ERROR: Unable to find name in string: " .. text .. " (" .. tempText .. ")")
    end
    -- `GetGameTime()` would be the perfect thing to use here--unfortunately, that's sim-side only
    local seconds = GetGameTimeSeconds()
    local MathFloor = math.floor
    local hours = MathFloor(seconds / 3600)
    seconds = seconds - hours * 3600
    local minutes = MathFloor(seconds / 60)
    seconds = seconds - minutes * 60
    tempData.time = ("%02d:%02d:%02d"):format(hours, minutes, seconds)
    if movieTable[4] == 'UEF' then
        tempData.color = 'ff00c1ff'
    elseif movieTable[4] == 'Cybran' then
        tempData.color = 'ffff0000'
    elseif movieTable[4] == 'Aeon' then
        tempData.color = 'ff89d300'
    else
        tempData.color = 'ffffffff'
    end

    AddTransmissionData(tempData)
    WaitForDialogue(movieTable[1])
end

---
---@param entryData Transmission
function AddTransmissionData(entryData)
    SimUIVars.SaveEntry(entryData)
end

--- The actual thread used by `Dialogue`
function PlayDialogue()
    while not table.empty(ScenarioInfo.DialogueQueue) do
        local dialogueTable = table.remove(ScenarioInfo.DialogueQueue, 1)
        if not dialogueTable then
            WARN('dialogueTable is nil, ScenarioInfo.DialogueQueue len is ' .. table.getn(ScenarioInfo.DialogueQueue))
        end
        if not dialogueTable.Flushed and (not ScenarioInfo.OpEnded or dialogueTable.Critical) then
            for _, dialogue in dialogueTable do
                if dialogue ~= nil and not dialogueTable.Flushed and (not ScenarioInfo.OpEnded or dialogueTable.Critical) then
                    local bank = dialogue.bank
                    local cue =  dialogue.cue
                    local delay = dialogue.delay
                    local duration = dialogue.duration
                    local text = dialogue.text
                    local vid = dialogue.vid
                    if not vid and bank and cue then
                        SyncVoice({Cue = cue, Bank = bank})
                        if not delay then
                            WaitSeconds(5)
                        end
                    end
                    if text and not vid then
                        DisplayMissionText(text)
                    end
                    if vid then
                        text = text or ""
                        local movieData = {}
                        if GetMovieDuration('/movies/' .. vid) == 0 then
                            movieData = {'/movies/AllyCom.sfd', bank, cue, dialogue.faction}
                        else
                            movieData = {'/movies/' .. vid, bank, cue, dialogue.faction}
                        end
                        SetupMFDSync(movieData, text)
                    end
                    if delay and delay > 0 then
                        WaitSeconds(delay)
                    end
                    if duration and duration > 0 then
                        WaitSeconds(duration)
                    end
                end
            end
        end
        if dialogueTable.Callback then
            ForkThread(dialogueTable.Callback)
        end
        WaitTicks(1)
    end
    ScenarioInfo.DialogueLock = false
end

---
---@param name string
function WaitForDialogue(name)
    while not ScenarioInfo.DialogueFinished[name] do
        WaitTicks(1)
    end
end

---
function PlayUnlockDialogue()
    if Random(1, 2) == 1 then
        SyncVoice({Bank = 'XGG', Cue = 'Computer_Computer_UnitRevalation_01370'})
    else
        SyncVoice({Bank = 'XGG', Cue = 'Computer_Computer_UnitRevalation_01372'})
    end
end

--- Given a head and taunt number, tells the UI to play the related taunt
---@param head number
---@param taunt number
function PlayTaunt(head, taunt)
    Sync.MPTaunt = {head, taunt}
end

---
---@param text string
function DisplayMissionText(text)
    if not Sync.MissionText then
        Sync.MissionText = {}
    end
    table.insert(Sync.MissionText, text)
end

---
---@param text string
function DisplayVideoText(text)
    if not Sync.VideoText then
        Sync.VideoText = {}
    end
    table.insert(Sync.VideoText, text)
end

--- Plays an NIS
---@param pathToMovie string
function PlayNIS(pathToMovie)
    if not Sync.NISVideo then
        Sync.NISVideo = pathToMovie
    end
end

---
---@param faction string
---@param callback fun()
function PlayEndGameMovie(faction, callback)
    if not Sync.EndGameMovie then
        Sync.EndGameMovie = faction
    end
    if callback then
        if not ScenarioInfo.DialogueFinished then
            ScenarioInfo.DialogueFinished = {}
        end
        ScenarioInfo.DialogueFinished['EndGameMovie'] = false
        ForkThread(EndGameWaitThread, callback)
    end
end

---
---@param callback fun()
function EndGameWaitThread(callback)
    while not ScenarioInfo.DialogueFinished['EndGameMovie'] do
        WaitTicks(1)
    end
    callback()
    ScenarioInfo.DialogueFinished['EndGameMovie'] = false
end

--- Plays an XACT sound if needed--currently all VOs are videos
---@param voSound SoundBlueprint
function PlayVoiceOver(voSound)
    SyncVoice(voSound)
end

--- Sets enhancement restrictions from the names of the enhancements you do not want the player to build
---@param enhancements string[]
function RestrictEnhancements(enhancements)
    local restrict = {}
    for _, enh in enhancements do
        restrict[enh] = true
    end

    SimUIVars.SaveEnhancementRestriction(restrict)
    import("/lua/enhancementcommon.lua").RestrictList(restrict)
    Sync.EnhanceRestrict = restrict
end

--- Returns if all units in the group are dead
---@param units Unit[]
---@return boolean
function GroupDeathCheck(units)
    for _, unit in units do
        if not unit.Dead then
            return false
        end
    end
    return true
end

--- Returns if the list is entirely truthy
---@param list unknown
---@return boolean
function CheckObjectives(list)
    for _, val in list do
        if not val then
            return false
        end
    end
    return true
end

---
---@param brain string
---@param unit string
---@param effect string
---@param name? string | true # if `true`, uses the brain's nickname
---@param pauseAtDeath? boolean
---@param deathTrigger? fun(self: Unit)
---@param enhancements? string[]
---@return CommandUnit
function SpawnCommander(brain, unit, effect, name, pauseAtDeath, deathTrigger, enhancements)
    local ACU = ScenarioUtils.CreateArmyUnit(brain, unit)
    local bp = ACU:GetBlueprint()
    local bonesToHide = bp.WarpInEffect.HideBones
    local delay = 0

    local function CreateEnhancements(unit, enhancements, delay)
        if delay then
            WaitSeconds(delay)
        end

        for _, enhancement in enhancements do
            unit:CreateEnhancement(enhancement)
        end
    end

    local function GateInEffect(unit, effect, bonesToHide)
        if effect == 'Gate' then
            delay = 0.75
            ForkThread(FakeGateInUnit, unit, nil, bonesToHide)
        elseif effect == 'Warp' then
            delay = 2.1
            unit:PlayCommanderWarpInEffect(bonesToHide)
        else
            WARN('*WARNING: Invalid effect type: ' .. effect .. '. Available types: Gate, Warp.')
        end
    end

    if enhancements and effect then
        -- Don't hide upgrade bones that we want add on the command unit
        for _, enh in enhancements do
            if bp.Enhancements[enh].ShowBones then
                for _, bone in bp.Enhancements[enh].ShowBones do
                    table.removeByValue(bonesToHide, bone)
                end
            end
        end

        GateInEffect(ACU, effect, bonesToHide)
        -- Creating upgrades needs to be delayed until the effect plays, else the upgrade bone would show up before the rest of the unit
        ForkThread(CreateEnhancements, ACU, enhancements, delay)
    elseif enhancements then
        CreateEnhancements(ACU, enhancements)
    elseif effect then
        GateInEffect(ACU, effect)
    end

    -- If true is passed as argument then use default name
    if name == true then
        ACU:SetCustomName(GetArmyBrain(brain).Nickname)
    elseif type(name) == 'string' then
        ACU:SetCustomName(name)
    end

    if pauseAtDeath then
        PauseUnitDeath(ACU)
    end

    if deathTrigger then
        CreateUnitDeathTrigger(deathTrigger, ACU)
    end

    return ACU
end

--- Run teleport effect then delete unit if told to do so
---@param unit Unit
---@param killUnit? boolean
function FakeTeleportUnit(unit, killUnit)
    IssueStop({unit})
    IssueToUnitClearCommands(unit)
    unit.CanBeKilled = false

    unit:PlayTeleportChargeEffects(unit:GetPosition(), unit:GetOrientation())
    unit:PlayUnitSound('GateCharge')
    WaitSeconds(2)

    unit:CleanupTeleportChargeEffects()
    unit:PlayTeleportOutEffects()
    unit:PlayUnitSound('GateOut')
    WaitSeconds(1)

    if killUnit then
        unit:Destroy()
    end
end

--- Run teleport effect then delete unit if told to do so
---@param units Unit
---@param killUnits? boolean
function FakeTeleportUnits(units, killUnits)
    IssueStop(units)
    IssueClearCommands(units)
    local buildingUnits = {}
    for _, unit in units do
        if not IsDestroyed(unit) then
            unit.CanBeKilled = false
            -- if an SCU is currently gating in, it's already getting teleport effects
            if unit:GetFractionComplete() < 1 then
                buildingUnits[unit] = true
            else
                unit:PlayTeleportChargeEffects(unit:GetPosition(), unit:GetOrientation())
                unit:PlayUnitSound('GateCharge')
            end
        end
    end

    WaitSeconds(2)

    for _, unit in units do
        if not IsDestroyed(unit) then
            if not buildingUnits[unit] then
                unit:CleanupTeleportChargeEffects()
                unit:PlayUnitSound('GateOut')
            end
            unit:PlayTeleportOutEffects()
        end
    end

    WaitSeconds(1)

    if killUnits then
        for _, unit in units do
            if not IsDestroyed(unit) then
                unit:Destroy()
            end
        end
    end
end

---
---@param unit Unit
---@param callback fun()
---@param bonesToHide Bone[]
function FakeGateInUnit(unit, callback, bonesToHide)
    local bp = unit:GetBlueprint()

    if EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, unit) then
        unit:HideBone(0, true)
        unit:SetUnSelectable(true)
        unit:SetBusy(true)
        unit:PlayUnitSound('CommanderArrival')
        unit:CreateProjectile('/effects/entities/UnitTeleport03/UnitTeleport03_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(0.75)

        local shieldMesh = bp.Display.WarpInEffect.PhaseShieldMesh
        if shieldMesh then
            unit:SetMesh(shieldMesh, true)
        end

        unit:ShowBone(0, true)

        for _, bone in bonesToHide or bp.Display.WarpInEffect.HideBones do
            unit:HideBone(bone, true)
        end

        unit:SetUnSelectable(false)
        unit:SetBusy(false)

        local totalBones = unit:GetBoneCount() - 1
        for _, v in import("/lua/effecttemplates.lua").UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(unit, bone, unit.Army, v)
            end
        end

        if shieldMesh then
            WaitSeconds(2)
            unit:SetMesh(bp.Display.MeshBlueprint, true)
        end
    else
        LOG ('debug:non commander')
        unit:PlayTeleportChargeEffects(unit:GetPosition(), unit:GetOrientation())
        unit:PlayUnitSound('GateCharge')
        WaitSeconds(2)
        unit:CleanupTeleportChargeEffects()
    end

    if callback then
        callback()
    end
end

--- Upgrades unit--for use with engineers, factories, radars, and other single upgrade path units.
--- Commander enhancements are too complicated for this.
---@param unit Unit
function UpgradeUnit(unit)
    local upgradeBP = unit:GetBlueprint().General.UpgradesTo
    IssueStop({unit})
    IssueToUnitClearCommands(unit)
    IssueUpgrade({unit}, upgradeBP)
end

--- Triggers a help text prompt to appear in the UI.
--- See `/modules/ui/help/helpstrings.lua` for a list of valid Help Prompt IDs.
---@param show string
function HelpPrompt(show)
    if not Sync.HelpPrompt then
        Sync.HelpPrompt = show
    end
end

-- Adds a scenario restriction for specified army and notify the UI/sim
---@param army Army
---@param categories EntityCategory
function AddRestriction(army, categories)
    if type(categories) ~= 'userdata' then
        WARN('ScenarioFramework.AddRestriction() called with invalid category expression "' .. CategoryToString(categories) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ')
    else
        SimUIVars.SaveTechRestriction(categories)
        AddBuildRestriction(army, categories)

        -- Add scenario restriction to game restrictions
        Game.AddRestriction(categories, army)
        Sync.Restrictions = Game.GetRestrictions()
    end
end

-- Removes a scenario restriction for specified army and notify the UI/sim
---@param army Army
---@param categories EntityCategory
---@param isSilent? boolean
function RemoveRestriction(army, categories, isSilent)
    if type(categories) ~= 'userdata' then
        WARN('ScenarioFramework.RemoveRestriction() called with invalid category expression "' .. CategoryToString(categories) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ')
    else
        SimUIVars.SaveTechAllowance(categories)
        if not isSilent then
            if not Sync.NewTech then Sync.NewTech = {} end
            table.insert(Sync.NewTech, EntityCategoryGetUnitList(categories))
        end
        RemoveBuildRestriction(army, categories)

        -- Remove scenario restriction from game restrictions
        Game.RemoveRestriction(categories, army)
        Sync.Restrictions = Game.GetRestrictions()

        ---@type AIBrain
        local brain = ArmyBrains[army]
        if brain then
            brain:ReEvaluateHQSupportFactoryRestrictions()
        end
    end
end

--- Toggles whether or not to ignore all restrictions.
--- This function is useful when trying to transfer restricted units between armies, e.g.  
--- ```
--- ScenarioFramework.IgnoreRestrictions(true)
--- ScenarioFramework.GiveUnitToArmy(unit, army)
--- ScenarioFramework.IgnoreRestrictions(false)
--- ```
---@param isIgnored boolean
function IgnoreRestrictions(isIgnored)
    Game.IgnoreRestrictions(isIgnored)
    Sync.Restrictions = Game.GetRestrictions()
end

---@class FactoriesAvailable
---@field T1Air FactoryUnit[]
---@field T2Air FactoryUnit[]
---@field T3Air FactoryUnit[]
---@field T1Land FactoryUnit[]
---@field T2Land FactoryUnit[]
---@field T3Land FactoryUnit[]
---@field T1Naval FactoryUnit[]
---@field T2Naval FactoryUnit[]
---@field T3Naval FactoryUnit[]

-- Returns lists of idle factories by category, optionally in a radius around a point.
-- This allows you to know which factories can build and which can't.
---@param brain AIBrain
---@param point? Marker | Vector
---@param radius? number
---@return FactoriesAvailable
function GetFactories(brain, point, radius)
    if type(point) == 'string' then
        point = ScenarioUtils.MarkerToPosition(point)
    end

    local available = {}
    if point then
        available = brain:GetAvailableFactories(point, radius)
    else
        available = brain:GetAvailableFactories()
    end

    local retTable = {
        T1Air = {}, T2Air = {}, T3Air = {},
        T1Land = {}, T2Land = {}, T3Land = {},
        T1Naval = {}, T2Naval = {}, T3Naval = {},
    }
    for _, v in available do
        if not v:IsUnitState('Building') and (v:GetNumBuildOrders(categories.ALLUNITS) == 0) then
            if EntityCategoryContains(categories.TECH1 * categories.AIR, v) then
                table.insert(retTable.T1Air, v)
            elseif EntityCategoryContains(categories.TECH2 * categories.AIR, v) then
                table.insert(retTable.T2Air, v)
            elseif EntityCategoryContains(categories.TECH3 * categories.AIR, v) then
                table.insert(retTable.T3Air, v)
            elseif EntityCategoryContains(categories.TECH1 * categories.LAND, v) then
                table.insert(retTable.T1Land, v)
            elseif EntityCategoryContains(categories.TECH2 * categories.LAND, v) then
                table.insert(retTable.T2Land, v)
            elseif EntityCategoryContains(categories.TECH3 * categories.LAND, v) then
                table.insert(retTable.T3Land, v)
            elseif EntityCategoryContains(categories.TECH1 * categories.NAVAL, v) then
                table.insert(retTable.T1Naval, v)
            elseif EntityCategoryContains(categories.TECH2 * categories.NAVAL, v) then
                table.insert(retTable.T2Naval, v)
            elseif EntityCategoryContains(categories.TECH3 * categories.NAVAL, v) then
                table.insert(retTable.T3Naval, v)
            end
        end
    end

    return retTable
end

--- Creates a visible area for `army` at `location` of `radius` size.
--- If `lifetime` is 0, the entity lasts forever, otherwise, for `lifetime` seconds.
--- Returns a `VizMarker` so you can destroy it later if you want.
---@param radius number
---@param location Marker | Vector
---@param lifetime number
---@param army AIBrain
---@return VizMarker
function CreateVisibleAreaLocation(radius, location, lifetime, army)
    if type(location) == 'string' then
        location = ScenarioUtils.MarkerToPosition(location)
    end
    local spec = {
        X = location[1],
        Z = location[3],
        Radius = radius,
        LifeTime = lifetime,
        Army = army:GetArmyIndex(),
    }
    return VizMarker(spec)
end

--- Creates a visible area for `army` at `atUnit` of `radius` size.
--- If `lifetime` is 0, the entity lasts forever, otherwise, for `lifetime` seconds.
--- Returns a `VizMarker` so you can destroy it later if you want.
---@param radius number
---@param atUnit Unit
---@param lifetime number
---@param army AIBrain
---@return VizMarker
function CreateVisibleAreaAtUnit(radius, atUnit, lifetime, army)
    local pos = atUnit:GetPosition()
    local spec = {
        X = pos[1],
        Z = pos[3],
        Radius = radius,
        LifeTime = lifetime,
        Army = army:GetArmyIndex(),
    }
    return VizMarker(spec)
end


--- Creates a visible area for `army` at `x`,`z` of `radius` size.
--- If `lifetime` is 0, the entity lasts forever, otherwise, for `lifetime` seconds.
--- Returns a `VizMarker` so you can destroy it later if you want.
---@param radius number
---@param x number
---@param z number
---@param lifetime number
---@param army number
---@return VizMarker
function CreateVisibleArea(radius, x, z, lifetime, army)
    local spec = {
        X = x,
        Z = z,
        Radius = radius,
        LifeTime = lifetime,
        Army = army,
    }
    return VizMarker(spec)
end

-- Sets the playable area for an operation to `rect`. Can be an area name or rectangle.
---@param rect Area | Rectangle
---@param voFlag? boolean # defaults to `true`
function SetPlayableArea(rect, voFlag)
    if voFlag == nil then
        voFlag = true
    end

    if type(rect) == 'string' then
        rect = ScenarioUtils.AreaToRect(rect)
    end

    local x0 = rect.x0 - math.mod(rect.x0 , 4)
    local y0 = rect.y0 - math.mod(rect.y0 , 4)
    local x1 = rect.x1 - math.mod(rect.x1, 4)
    local y1 = rect.y1 - math.mod(rect.y1, 4)

    LOG(string.format('Debug: SetPlayableArea before round : %s, %s %s, %s', rect.x0, rect.y0, rect.x1, rect.y1))
    LOG(string.format('Debug: SetPlayableArea after round : %s, %s %s, %s', x0, y0, x1, y1))

    ScenarioInfo.MapData.PlayableRect = {x0, y0, x1, y1}
    rect.x0 = x0
    rect.x1 = x1
    rect.y0 = y0
    rect.y1 = y1

    SetPlayableRect(x0, y0, x1, y1)
    if voFlag then
        ForkThread(PlayableRectCameraThread, rect)
        SyncVoice({Cue = 'Computer_Computer_MapExpansion_01380', Bank = 'XGG'})
    end

    import("/lua/simsync.lua").SyncPlayableRect(rect)
    Sync.NewPlayableArea = {x0, y0, x1, y1}
    ForkThread(GenerateOffMapAreas)
end

--- unused
function PlayableRectCameraThread(rect)
--    local cam = import("/lua/simcamera.lua").SimCamera('WorldCamera')
--    LockInput()
--    cam:UseGameClock()
--    cam:SyncPlayableRect(rect)
--    cam:MoveTo(rect, 1)
--    cam:WaitFor()
--    UnLockInput()
end

--- Sets platoon to only be built once
---@param platoon Platoon
function BuildOnce(platoon)
    local aiBrain = platoon:GetBrain()
    aiBrain:PBMSetPriority(platoon, 0)
end

--- TODO: Stop mission scripts from using this function, then remove it.
---@deprecated
function AddObjective(type, complete, title, description, image, progress, target)
    Objectives.AddObjective(type, complete, title, description, image, progress, target)
end

--- TODO: Stop mission scripts from using this function, then remove it.
---@deprecated
function UpdateObjective(title, updateField, newData, objTag)
    Objectives.UpdateObjective(title, updateField, newData, objTag)
end

--- Moves the camera to the specified area in 1 second
---@param area Rectangle
function StartCamera(area)
    local cam = SimCamera('WorldCamera')

    cam:ScaleMoveVelocity(0.03)
    cam:MoveTo(area, 1)
    cam:WaitFor()
    UnlockInput()
end

--- Sets an army color to Aeon
---@param army number
function SetAeonColor(army)
    SetArmyColor(army, 41, 191, 41)
end

--- Sets an army color to Aeon ally
---@param army number
function SetAeonAllyColor(army)
    SetArmyColor(army, 165, 200, 102)
end

--- Sets an army color to Aeon neutral
---@param army number
function SetAeonNeutralColor(army)
    SetArmyColor(army, 16, 86, 16)
end

--- Sets an army color to Cybran
---@param army number
function SetCybranColor(army)
    SetArmyColor(army, 128, 39, 37)
end

--- Sets an army color to Cybran ally
---@param army number
function SetCybranAllyColor(army)
    SetArmyColor(army, 219, 74, 58)
end

--- Sets an army color to Cybran neutral
---@param army number
function SetCybranNeutralColor(army)
    SetArmyColor(army, 165, 9, 1) -- 84, 13, 13
end

--- Sets an army color to UEF
---@param army number
function SetUEFColor(army)
    SetArmyColor(army, 41, 40, 140)
end

--- Sets an army color to UEF ally
---@param army number
function SetUEFAllyColor(army)
    SetArmyColor(army, 71, 114, 148)
end

--- Sets an army color to UEF neutral
---@param army number
function SetUEFNeutralColor(army)
    SetArmyColor(army, 16, 16, 86)
end

--- Sets an army color to Coalition
---@param army number
function SetCoalitionColor(army)
    SetArmyColor(army, 80, 80, 240)
end

--- Sets an army color to neutral
---@param army number
function SetNeutralColor(army)
    SetArmyColor(army, 211, 211, 180)
end

--- Sets an army color to Aeon player
---@param army number
function SetAeonPlayerColor(army)
    SetArmyColor(army, 36, 182, 36)
end

--- Sets an army color to evil Aeon
---@param army number
function SetAeonEvilColor(army)
    SetArmyColor(army, 159, 216, 2)
end

--- Sets an army color to Aeon ally 1
---@param army number
function SetAeonAlly1Color(army)
    SetArmyColor(army, 16, 86, 16)
end

--- Sets an army color to Aeon ally 2
---@param army number
function SetAeonAlly2Color(army)
    SetArmyColor(army, 123, 255, 125)
end

--- Sets an army color to Cybran player
---@param army number
function SetCybranPlayerColor(army)
    SetArmyColor(army, 231, 3, 3)
end

--- Sets an army color to evil Cybran
---@param army number
function SetCybranEvilColor(army)
    SetArmyColor(army, 225, 70, 0)
end

--- Sets an army color to Cybran ally
---@param army number
function SetCybranAllyColor(army)
    SetArmyColor(army, 130, 33, 30)
end

--- Sets an army color to UEF player
---@param army number
function SetUEFPlayerColor(army)
    SetArmyColor(army, 41, 41, 225)
end

--- Sets an army color to UEF ally 1
---@param army number
function SetUEFAlly1Color(army)
    SetArmyColor(army, 81, 82, 241)
end

--- Sets an army color to UEF ally 2
---@param army number
function SetUEFAlly2Color(army)
    SetArmyColor(army, 133, 148, 255)
end

--- Sets an army color to Seraphim
---@param army number
function SetSeraphimColor(army)
    SetArmyColor(army, 167, 150, 2)
end

--- Sets army color to Loyalist
---@param army number
function SetLoyalistColor(army)
    SetArmyColor(army, 0, 100, 0)
end

---
---@param aiBrain AIBrain
---@param name string
function AMPlatoonCounter(aiBrain, name)
    local platoonCount = aiBrain.AttackData.PlatoonCount
    local count = platoonCount[name]
    if not count then
        platoonCount[name] = 0
        return 0
    end
    return count
end

---
---@param platoon Platoon
---@param landingChain MarkerChain
---@param attackChain MarkerChain
---@param instant? boolean
---@param moveChain? MarkerChain
function PlatoonAttackWithTransports(platoon, landingChain, attackChain, instant, moveChain)
    ForkThread(PlatoonAttackWithTransportsThread, platoon, landingChain, attackChain, instant, moveChain)
end
function PlatoonAttackWithTransportsThread(platoon, landingChain, attackChain, instant, moveChain)
    local aiBrain = platoon:GetBrain()
    local allUnits = platoon:GetPlatoonUnits()
    local startPos = platoon:GetPlatoonPosition()
    local units = {}
    local transports = {}
    for _, unit in allUnits do
        if EntityCategoryContains(categories.TRANSPORTATION, unit) then
            table.insert(transports, unit)
        else
            table.insert(units, unit)
        end
    end

    local landingLocs = ScenarioUtils.ChainToPositions(landingChain)
    local landingLocation = table.random(landingLocs)

    if instant then
        AttachUnitsToTransports(units, transports)
        if moveChain and not import("/lua/scenarioplatoonai.lua").MoveAlongRoute(platoon, ScenarioUtils.ChainToPositions(moveChain)) then
            return
        end
        IssueTransportUnload(transports, landingLocation)
        local attached = true
        while attached do
            WaitSeconds(3)
            local allDead = true
            for _, v in transports do
                if not v.Dead then
                    allDead = false
                    break
                end
            end
            if allDead then
                return
            end
            attached = false
            for _, unit in units do
                if not unit.Dead and unit:IsUnitState('Attached') then
                    attached = true
                    break
                end
            end
        end
    else
        if not import("/lua/ai/aiutilities.lua").UseTransports(units, transports, landingLocation) then
            return
        end
    end

    local attackLocs = ScenarioUtils.ChainToPositions(attackChain)
    for _, loc in attackLocs do
        IssuePatrol(units, loc)
    end

    if instant then
        IssueMove(transports, startPos)
        aiBrain:AssignUnitsToPlatoon('Army_Pool', transports, 'Unassigned', 'None')
    end
end

--- Automatically attaches `units` to attach points on `transports`
---@param units Unit[]
---@param transports BaseTransport[]
function AttachUnitsToTransports(units, transports)
    local locUnits = {}
    for i, unit in units do
        locUnits[i] = unit
    end
    local transportBones = {}
    local numTransports = table.getn(transports)
    for k, unit in transports do
        local lrg, med, sml = {}, {}, {}
        transportBones[k] = {
            Lrg = lrg,
            Med = med,
            Sml = sml,
        }
        for i = 1, unit:GetBoneCount() do
            local boneName = unit:GetBoneName(i)
            if boneName ~= nil then
                if string.find(boneName, 'Attachpoint_Lrg') then
                    table.insert(lrg, boneName)
                elseif string.find(boneName, 'Attachpoint_Med') then
                    table.insert(med, boneName)
                elseif string.find(boneName, 'Attachpoint') then
                    table.insert(sml, boneName)
                end
            end
        end
    end
    local sortedGroup = {}
    for i = 1, table.getn(locUnits) do
        local highest = 0
        local key, value
        for k, unit in locUnits do
            local transportClass = unit.Blueprint.Transport.TransportClass
            if not transportClass then
                if 1 > highest then
                    highest = 1
                    value = unit
                    key = k
                end
            else
                if transportClass > highest then
                    highest = transportClass
                    value = unit
                    key = k
                end
            end
        end
        sortedGroup[i] = value
        table.remove(locUnits, key)
    end
    locUnits = sortedGroup
    for _, unit in locUnits do
        if not unit:IsUnitState('Attached') then
            -- Attach locUnits and remove bones when locUnits attached
            local transportClass = unit.Blueprint.Transport.TransportClass
            local notInserted = true
            local attachBone = -1
            if unit:IsValidBone('AttachPoint', false) then
                attachBone = 'AttachPoint'
            end
            local i = 1
            if transportClass == 3 then
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Lrg) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Lrg, 1)
                        transports[i]:OnTransportAttach(bone, unit)
                        unit:AttachBoneTo(attachBone, transports[i], bone)
                        local bonePos = transports[i]:GetPosition(bone)
                        for j = 1, 2 do
                            local lowDist = 100
                            local key
                            for kbone, vbone in transportBones[i].Med do
                                local dist = VDist3(transports[i]:GetPosition(vbone), bonePos)
                                if dist < lowDist then
                                    lowDist = dist
                                    key = kbone
                                end
                            end
                            table.remove(transportBones[i].Med, key)
                        end
                        for j = 1, 4 do
                            local lowDist = 100
                            local key
                            for kbone, vbone in transportBones[i].Sml do
                                local dist = VDist3(transports[i]:GetPosition(vbone), bonePos)
                                if dist < lowDist then
                                    lowDist = dist
                                    key = kbone
                                end
                            end
                            table.remove(transportBones[i].Sml, key)
                        end
                    end
                    i = i + 1
                end
            elseif transportClass == 2 then
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Med) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Med, 1)
                        transports[i]:OnTransportAttach(bone, unit)
                        unit:AttachBoneTo(attachBone, transports[i], bone)
                        local bonePos = transports[i]:GetPosition(bone)
                        for j = 1, 2 do
                            local lowDist = 100
                            local key
                            for kbone, vbone in transportBones[i].Sml do
                                local dist = VDist3(transports[i]:GetPosition(vbone), bonePos)
                                if dist < lowDist then
                                    lowDist = dist
                                    key = kbone
                                end
                            end
                            table.remove(transportBones[i].Sml, key)
                        end
                    end
                    i = i + 1
                end
            else -- transportClass == 1
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Sml) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Sml, 1)
                        transports[i]:OnTransportAttach(bone, unit)
                        unit:AttachBoneTo(attachBone, transports[i], bone)
                    end
                    i = i + 1
                end
            end
        end
    end
end

--- Take a table of markers, and return the marker with the largest number of target units in a specified radius around it
---@param attackingBrain AIBrain
---@param targetBrain AIBrain
---@param relationship string
---@param attackLocations Vector[]
---@param pointRadius number
---@return Vector
function DetermineBestAttackLocation(attackingBrain, targetBrain, relationship, attackLocations, pointRadius)
    local highestUnitCountFound = 0
    local targetBrainUnitCount = 0
    local foundUnits = nil
    local attackLocation = nil

    for _, location in attackLocations do
        foundUnits = attackingBrain:GetUnitsAroundPoint(categories.ALLUNITS, location, pointRadius, relationship)

        for _, unit in foundUnits do
            if unit:GetAIBrain() == targetBrain then
                targetBrainUnitCount = targetBrainUnitCount + 1
            end
        end
        if targetBrainUnitCount > highestUnitCountFound or attackLocation == nil then
            highestUnitCountFound = targetBrainUnitCount
            attackLocation = location
        end
        targetBrainUnitCount = 0
    end

    return attackLocation
end


GetRandomEntry = table.random

---
---@param brain AIBrain
---@param area (Area) | (Area | Rectangle)[]
---@param category? EntityCategory # defaults to `STRUCTURE + ENGINEER`
function KillBaseInArea(brain, area, category)
    local rect = area
    local units
    if type(area) == 'table' then
        units = {}
        local unitCount = 0
        for _, subArea in area do
            if type(subArea) == 'string' then
                rect = ScenarioUtils.AreaToRect(subArea)
            else
                rect = subArea
            end
            for _, unit in GetUnitsInRect(rect) do
                unitCount = unitCount + 1
                units[unitCount] = unit
            end
        end
    else
        -- what could the other option be at this point?
        if type(area) == 'string' then
            rect = ScenarioUtils.AreaToRect(area)
        end
        units = GetUnitsInRect(rect)
    end
    if not category then
        category = categories.STRUCTURE + categories.ENGINEER
    end
    local filteredUnits = {}
    if units then
        for _, unit in units do
            if not unit.Dead and unit:GetAIBrain() == brain and EntityCategoryContains(category, unit) then
                table.insert(filteredUnits, unit)
            end
        end
        ForkThread(KillBaseInAreaThread, filteredUnits)
    end
end

--- Kills units, spread out for up to 12 seconds in 6 tick intervals
---@param units Unit[]
function KillBaseInAreaThread(units)
    local waitNum = math.floor(table.getn(units) / 20)
    for num, unit in units do
        if not unit.Dead then
            unit:Kill()
        end
        if waitNum > 0 and num >= waitNum and math.mod(waitNum, num) == 0 then
            WaitTicks(6)
        end
    end
end

---
---@param area Area
---@param callback? fun()
---@param duration? number
function StartOperationJessZoom(area, callback, duration)
    ForkThread(StartOperationJessZoomThread, area, callback, duration)
end
function StartOperationJessZoomThread(area, callback, duration)
    Cinematics.EnterNISMode()
    duration = duration or 3
    Cinematics.CameraMoveToRectangle(ScenarioUtils.AreaToRect(area), duration)
    Cinematics.ExitNISMode()
    if callback then
        callback()
    end
end

--- Ends the operation in safety, setting enemy alliances to neutral, and making all commanders
--- and `units` to be invulnerable
---@param units Unit[]
function EndOperationSafety(units)
    ScenarioInfo.OpEnded = true
    ResetUITimer() -- turn off any timer going

    for i, brain in ArmyBrains do
        for k, enemy in ArmyBrains do
            if not IsAlly(i, k) then
                SetAlliance(brain.Name, enemy.Name, 'Neutral')
            end
        end
        for _, unit in brain:GetListOfUnits(categories.COMMAND, false) do
            unit.CanTakeDamage = false
            unit.CanBeKilled = false
        end
    end
    if units and not table.empty(units) then
        for _, unit in units do
            if not unit.Dead then
                unit.CanTakeDamage = false
                unit.CanBeKilled = false
            end
        end
    end
end

---
---@param unit Unit
---@param track? boolean
---@param time? number
function MidOperationCamera(unit, track, time)
    ForkThread(OperationCameraThread, unit:GetPosition(), unit:GetHeading(), false, track, unit, time, time)
end

---
---@param unit Unit
---@param track? boolean
---@param time? number
function EndOperationCamera(unit, track, time)
    local faction
    if EntityCategoryContains(categories.COMMAND, unit) then
        local categories = unit.Blueprint.CategoriesHash
        if categories.UEF then
            faction = 1
        elseif categories.AEON then
            faction = 2
        elseif categories.CYBRAN then
            faction = 3
        elseif categories.SERAPHIM then
            faction = 4
        end
    end
    ForkThread(OperationCameraThread, unit:GetPosition(), unit:GetHeading(), faction, track, unit, time, time)
end

---
---@param location Vector
function EndOperationCameraLocation(location)
    ForkThread(OperationCameraThread, location, 0)
end

---
---@param location Vector
---@param heading number
---@param faction? number
---@param track? boolean
---@param trackUnit? Unit
---@param unlock? boolean 
---@param unlockTime? number
function OperationCameraThread(location, heading, faction, track, trackUnit, unlock, unlockTime)
    local cam = import("/lua/simcamera.lua").SimCamera('WorldCamera')
    LockInput()
    cam:UseGameClock()
    WaitTicks(1)
    -- Track the unit; not totally working properly yet
    if track and trackUnit then
        local zoomVar = 50
        local pitch = 0.4
        if EntityCategoryContains(categories.uaa0310, trackUnit) then
            zoomVar = 150
            pitch = 0.3
        end
        local pos = trackUnit:GetPosition()
        local marker = {
            orientation = VECTOR3(heading, 0.5, 0),
            position = {pos[1], pos[2] - 15, pos[3]},
            zoom = zoomVar,
        }

        cam:NoseCam(trackUnit, pitch, zoomVar, 1)
    elseif faction then
        -- Only do the 2.5 second wait if a faction is given; that means its a commander
        local marker
        marker = {
            orientation = VECTOR3(heading + 3.14149, 0.2, 0),
            position = {location[1], location[2] + 1, location[3]},
            zoom = 15,
        }
        cam:SnapToMarker(marker)
        WaitSeconds(2.5)

        if faction == 1 then -- UEF
            marker = {
                orientation = {heading + 3.14149, 0.38, 0 },
                position = {location[1], location[2] + 7.5, location[3]},
                zoom = 58,
            }
        elseif faction == 2 then -- Aaeon
            marker = {
                orientation = {heading + 3.14149, 0.45, 0},
                position = location,
                zoom = 50,
            }
        elseif faction == 3 then -- Cybran
            marker = {
                orientation = {heading + 3.14149, 0.45, 0},
                position = {location[1], location[2] + 5, location[3]},
                zoom = 45,
            }
        else
            marker = {
                orientation = {heading + 3.14149, 0.38, 0},
                position = location,
                zoom = 45,
            }
        end
        cam:SnapToMarker(marker)
        cam:Spin(0.03)
    end
    if unlock then
        WaitSeconds(unlockTime)
        -- Matt 11/27/06. This is functional now, but the snap is pretty harsh. Need someone else to look at it
        cam:RevertRotation()
        cam:UseSystemClock()
        UnlockInput()
    end
end

--- For mid-operation NIS's
---@param unit Unit
---@param blendTime number
---@param holdTime number
---@param orientationOffset Vector
---@param positionOffset Vector`
---@param zoom number
function MissionNISCamera(unit, blendTime, holdTime, orientationOffset, positionOffset, zoom)
    ForkThread(MissionNISCameraThread, unit, blendTime, holdTime, orientationOffset, positionOffset, zoom)
end
function MissionNISCameraThread(unit, blendTime, holdTime, orientationOffset, positionOffset, zoom)
    if not ScenarioInfo.NIS then
        ScenarioInfo.NIS = true
        local cam = import("/lua/simcamera.lua").SimCamera('WorldCamera')
        LockInput()
        cam:UseGameClock()
        WaitTicks(1)

        local position = unit:GetPosition()
        local heading = unit:GetHeading()
        local marker = {
            orientation = {heading + orientationOffset[1], orientationOffset[2], orientationOffset[3]},
            position = {
                position[1] + positionOffset[1],
                position[2] + positionOffset[2],
                position[3] + positionOffset[3]
            },
            zoom = zoom,
        }
        cam:MoveToMarker(marker, blendTime)
        WaitSeconds(holdTime)

        cam:RevertRotation()
        cam:UseSystemClock()
        UnlockInput()
        ScenarioInfo.NIS = false
    end
end

--- NIS Garbage
---@param unit UnitInfo | Unit
---@param camInfo CamInfo
function OperationNISCamera(unit, camInfo)
    if camInfo.markerCam then
        ForkThread(OperationNISCameraThread, unit, camInfo)
    else
        local unitInfo = {Position = unit:GetPosition(), Heading = unit:GetHeading()}
        ForkThread(OperationNISCameraThread, unitInfo, camInfo)
    end
end

--- CDR Death (pass `hold` only if it's a mid-operation death)--resets death pausin
---@param unit Unit
---@param holdTime? number
function CDRDeathNISCamera(unit, holdTime)
    PauseUnitDeathActive = true
    local camInfo = {
        blendTime = 1,
        holdTime = holdTime,
        orientationOffset = {math.pi, 0.7, 0 },
        positionOffset = {0, 1, 0 },
        zoomVal = 65,
        vizRadius = 10,
    }
    if not camInfo.holdTime then
        camInfo.blendTime = 2.5
        camInfo.spinSpeed = 0.03
        camInfo.overrideCam = true
    end
    local unitInfo = {Position = unit:GetPosition(), Heading = unit:GetHeading()}
    ForkThread(OperationNISCameraThread, unitInfo, camInfo)
end

--- For op intro (currently not used)
---@param unit Unit
function IntroductionNISCamera(unit)
    local unitInfo = {Position = unit:GetPosition(), Heading = unit:GetHeading()}
    ForkThread(OperationNISCameraThread, unitInfo, camInfo)
end

---@class UnitInfo
---@field Position Vector
---@field Heading Vector

---@class CamInfo
---@field blendTime number (seconds) how long the camera will spend interpolating from play camera to the NIS destination
---@field holdTime number (seconds) NIS duration after blendTime. if "nil", signals an "end of op" camera
---@field orientationOffset Vector (radians) offsets the orientation of the camera in radians (x = heading, y = pitch, z = roll)
---@field positionOffset Vector (ogrids) offsets the camera from the marker (y = up)
---@field zoomVal number (?) sets the distance from the marker
---@field spinSpeed number (ogrids/sec?) sets a rate the camera will rotate around it's marker (positive = counterclockwise)
---@field markerCam boolean allows the NIS to use a marker rather than a unit
---@field resetCam boolean disables the interpolation at the end of the NIS, needed for NISs that appear outside of the playable area.
---@field overrideCam boolean allows an NIS to interrupt an NIS that is currently playing (typically used for end of operation cameras)
---@field playableAreaIn Area
---@field playableAreaOut Area
---@field vizRadius number (ogrids)

---------------
--   NIS Thread
---------------
--- Applies `camInfo` settings onto `unitInfo`. Will unpause unit deaths when finished (or is already busy).
---@param unitInfo UnitInfo | Vector # can be `Vector` when `camInfo.markerCam` is set
---@param camInfo CamInfo
function OperationNISCameraThread(unitInfo, camInfo)
    if not ScenarioInfo.NIS or camInfo.overrideCam then
        local cam = import("/lua/simcamera.lua").SimCamera('WorldCamera')

        local position, heading, vizmarker
        -- Setup camera information
        if camInfo.markerCam then
            position = unitInfo
            heading = 0
        else
            position = unitInfo.Position
            heading = unitInfo.Heading
        end

        ScenarioInfo.NIS = true

        LockInput()
        cam:UseGameClock()
        Sync.NISMode = 'on'

        if camInfo.vizRadius then
            local spec = {
                X = position[1],
                Z = position[3],
                Radius = camInfo.vizRadius,
                LifeTime = -1,
                Omni = false,
                Vision = true,
                Army = 1, -- TODO: First army is always Player, this will do until the system is reworked to fully support multiplayer in campaign
            }
            vizmarker = VizMarker(spec)
            WaitTicks(3) -- This seems to be needed to prevent them from popping in

        end

        if camInfo.playableAreaIn then
            SetPlayableArea(camInfo.playableAreaIn, false)
        end
        WaitTicks(1)

        local marker = {
            orientation = {
                heading + camInfo.orientationOffset[1],
                camInfo.orientationOffset[2],
                camInfo.orientationOffset[3]
            },
            position = {
                position[1] + camInfo.positionOffset[1],
                position[2] + camInfo.positionOffset[2],
                position[3] + camInfo.positionOffset[3]
            },
            zoom = camInfo.zoomVal,
        }

        -- Run the Camera
        cam:MoveToMarker(marker, camInfo.blendTime)
        WaitSeconds(camInfo.blendTime)

        -- Hold camera in place if desired
        if camInfo.spinSpeed and camInfo.holdTime then
            cam:HoldRotation()
        end

        -- Spin the Camera
        if camInfo.spinSpeed then
            cam:Spin(camInfo.spinSpeed)
        end

        -- Release the camera if it's not the end of the Op
        if camInfo.holdTime then
            WaitSeconds(camInfo.holdTime)

            if camInfo.resetCam then
                cam:Reset()
            else
                cam:RevertRotation()
            end
            UnlockInput()
            cam:UseSystemClock()
            Sync.NISMode = 'off'

            ScenarioInfo.NIS = false
        end

        -- cleanup
        if camInfo.playableAreaOut then
            SetPlayableArea(camInfo.playableAreaOut, false)
        end
        if vizmarker then
            vizmarker:Destroy()
        end

    end
    PauseUnitDeathActive = false
end

---
function OnPostLoad()
    local dialogFinished = ScenarioInfo.DialogueFinished
    if dialogFinished then
        for k, _ in dialogFinished do
            dialogFinished[k] = true
        end
    end
end

--- Sets all `units` that are in `army` to be able to take damage and be killed. Flags if they weren't able
--- to previously: `UndamagableFlagSet` for CanTakeDamage and `UnKillableFlagSet` for CanBeKilled.
---@param army number
---@param units Unit[]
function FlagUnkillableSelect(army, units)
    for _, unit in units do
        if not unit.Dead and unit:GetAIBrain():GetArmyIndex() == army then
            if not unit.CanTakeDamage then
                unit.UndamagableFlagSet = true
            end
            if not unit.CanBeKilled then
                unit.UnKillableFlagSet = true
            end
            unit.CanTakeDamage = false
            unit.CanBeKilled = false
        end
    end
end

--- Sets all units that are in `army` to be able to take damage and be killed, expect for a list of
--- exceptions. Flags if they weren't able to previously, regardless of if they were an exception:
--- `UndamagableFlagSet` for CanTakeDamage and `UnKillableFlagSet` for CanBeKilled.
function FlagUnkillable(army, exceptions)
    local units = ArmyBrains[army]:GetListOfUnits(categories.ALLUNITS, false)
    for _, unit in units do
        if not unit.CanTakeDamage then
            unit.UndamagableFlagSet = true
        end
        if not unit.CanBeKilled then
            unit.UnKillableFlagSet = true
        end
        unit.CanTakeDamage = false
        unit.CanBeKilled = false
    end
    if exceptions then
        for _, unit in exceptions do
            -- Only process units that weren't already set
            if not unit.UnKillableFlagSet then
                unit.CanBeKilled = true
            end
            if not unit.UndamagableFlagSet then
                unit.CanTakeDamage = true
            end
        end
    end
end

--- Reverts all units in `army` that had their `UnKillableFlagSet` or `UndamagableFlagSet`
---@param army number
function UnflagUnkillable(army)
    local units = ArmyBrains[army]:GetListOfUnits(categories.ALLUNITS, false)
    for _, unit in units do
        -- Only revert units that weren't already set
        if not unit.UnKillableFlagSet then
            unit.CanBeKilled = true
        end
        if not unit.UndamagableFlagSet then
            unit.CanTakeDamage = true
        end
        unit.UnKillableFlagSet = nil
        unit.UndamagableFlagSet = nil
    end
end

function EngineerBuildUnits(army, unitName, ...)
    local engUnit = ScenarioUtils.CreateArmyUnit(army, unitName)
    local aiBrain = engUnit:GetAIBrain()
    for k, v in arg do
        if k ~= 'n' then
            local unitData = ScenarioUtils.FindUnit(v, Scenario.Armies[army].Units)
            if not unitData then
                WARN('*WARNING: Invalid unit name ' .. v)
            end
            if unitData and aiBrain:CanBuildStructureAt(unitData.type, unitData.Position) then
                aiBrain:BuildStructure(engUnit, unitData.type, {unitData.Position[1], unitData.Position[3], 0}, false)
            end
        end
    end

    return engUnit
end

function ClearIntel(position, radius)
    local minX = position[1] - radius
    local maxX = position[1] + radius
    local minZ = position[3] - radius
    local maxZ = position[3] + radius
    FlushIntelInRect(minX, minZ, maxX, maxZ)
end

--- Generates the off-map areas for the anti-off mapping function
function GenerateOffMapAreas()
    local extent = 100

    local playablearea
    if  ScenarioInfo.MapData.PlayableRect then
        playablearea = ScenarioInfo.MapData.PlayableRect
    else
        playablearea = {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
    end

    local x0 = playablearea[1]
    local y0 = playablearea[2]
    local x1 = playablearea[3]
    local y1 = playablearea[4]

    local offMapAreaAbove = Rect(x0 - extent, y0 - extent, x1 + extent, y0)
    local offMapAreaBelow = Rect(x0 - extent, y1, x1 + extent, y1 + extent)
    local offMapAreaLeft  = Rect(x0 - extent, y0, x0, y1)
    local offMapAreaRight = Rect(x1, y0, x1 + extent, y1)

    ScenarioInfo.OffMapAreas = {offMapAreaAbove, offMapAreaBelow, offMapAreaLeft, offMapAreaRight}
    ScenarioInfo.PlayableArea = playablearea
end

--- Checks for offmap human air units every 11 ticks and sends them to the nearest spot inside the map
function AntiOffMapMainThread()
    local WaitTicks = WaitTicks
    local GetUnitsInRect = GetUnitsInRect
    local MoveOnMapThread = MoveOnMapThread
    local IsHumanUnit = IsHumanUnit
    GenerateOffMapAreas()

    while ScenarioInfo.OffMapPreventionThreadAllowed do
        WaitTicks(11)
        for _, offMapArea in ScenarioInfo.OffMapAreas do
            local units = GetUnitsInRect(offMapArea)
            if units then
                for _, unit in units do
                    -- This is to make sure that we only do this check for air units
                    if not unit.OffMapThread and EntityCategoryContains(categories.AIR, unit) then
                        -- This is to make it so it only impacts player armies, not AI or civilian or mission map armies
                        if IsHumanUnit(unit) then
                            unit.OffMapThread = unit:ForkThread(MoveOnMapThread)
                        else
                            -- So that we don't bother checking each AI unit more than once
                            unit.OffMapThread = true
                        end
                    end
                end
            end
        end
    end
end
-- This is for bad units who choose to go off map, shame on them
function MoveOnMapThread(unit)
    unit.OffMapTime = 0
    unit.OnMapTime = 0
    unit.AllowedOffMapTime = GetAllowedOffMapTime(unit)
    while not unit.Dead do
        if IsUnitInPlayableArea(unit) then
            unit.OnMapTime = unit.OnMapTime + 1
            if unit.OnMapTime > 5 then
                break
            end
        else
            unit.OffMapTime = unit.OffMapTime + 1
            if unit.OffMapTime > unit.AllowedOffMapTime then
                MoveOnMap(unit)
            end
        end
        WaitSeconds(1)
    end
    unit.OffMapTime = 0
    unit.OnMapTime = 0
    unit.OffMapThread = nil
end

--- Clears a unit's orders and issues a move order to the closest point on the map
---@param unit Unit
function MoveOnMap(unit)
    local position = unit:GetPosition()
    local playableArea = ScenarioInfo.PlayableArea
    local nearestPoint = {position[1], position[2], position[3]}

    if position[1] < playableArea[1] then
        nearestPoint[1] = playableArea[1] + 5
    elseif position[1] > playableArea[3] then
        nearestPoint[1] = playableArea[3] - 5
    end

    if position[3] < playableArea[2] then
        nearestPoint[3] = playableArea[2] + 5
    elseif position[3] > playableArea[4] then
        nearestPoint[3] = playableArea[4] - 5
    end

    IssueToUnitClearCommands(unit)
    IssueToUnitMove(unit, nearestPoint)
end

--- Returns if the unit's army is human
---@param unit Unit
---@return boolean
function IsHumanUnit(unit)
    for _, army in ScenarioInfo.ArmySetup do
        if army.ArmyIndex == unit.Army then
            return army.Human
        end
    end
    return false
end

--- Returns if the unit is in the playable area
---@param unit Unit
---@return boolean
function IsUnitInPlayableArea(unit)
    local playableArea = ScenarioInfo.PlayableArea
    local position = unit:GetPosition()
    return
        position[1] > playableArea[1] and position[1] < playableArea[3] and
        position[3] > playableArea[2] and position[3] < playableArea[4]
end

--- Gets the amount of time the unit is allowed to be offmap before losing orders
---@param unit Unit
---@return number
function GetAllowedOffMapTime(unit)
    local airspeed = unit.Blueprint.Air.MaxAirspeed
    local value = airspeed

    if EntityCategoryContains(categories.BOMBER, unit) then
        value = airspeed / 5
    elseif EntityCategoryContains(categories.TRANSPORTATION, unit) then
        value = 2
    end

    for i = 1, unit:GetWeaponCount() do
        local wep = unit:GetWeapon(i)
        -- let chasing units have a little leeway
        if wep.Label ~= 'DeathWeapon' and wep.Label ~= 'DeathImpact' and wep:GetCurrentTarget() then
            value = airspeed * 2
        end
    end

    return value
end