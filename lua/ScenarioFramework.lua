-----------------------------------------------------------------
-- File       : /lua/scenarioFramework.lua
-- Authors    : John Comes, Drew Staltman
-- Summary    : Functions for use in the scenario scripts.
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@class Dialogue : BpSound
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


local Cinematics = import('/lua/cinematics.lua')
local Objectives = import('/lua/SimObjectives.lua')
local ScenarioPlatoonAI = import('/lua/ScenarioPlatoonAI.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local SimCamera = import('/lua/SimCamera.lua').SimCamera
local SimUIVars = import('/lua/sim/SimUIState.lua')
local TriggerFile = import('/lua/scenariotriggers.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker


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

    import('/lua/sim/matchstate.lua').CallEndGame() -- We need this here to populate the score screen

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
--- Creates a UI timer that fires `callback` after `seconds`.
--- You can have the function repeat `repeatNum` times which will fire every `seconds`.
---@param callback function
---@param seconds number
---@param name string
---@param display boolean
---@param onTickSecond fun(seconds: number)
---@return thread
function CreateTimerTrigger(callback, seconds, name, display, onTickSecond)
    timerThread = TriggerFile.CreateTimerTrigger(callback, seconds, name, display, onTickSecond)
    return timerThread
end

--- Stops the timer set by `CreateTimerTrigger`
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
            IssueClearCommands({self})
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
function UnitsInAreaCheck(cat, rectangle)
    if type(rectangle) == 'string' then
        rectangle = ScenarioUtils.AreaToRect(rectangle)
    end
    local entities = GetUnitsInRect(rectangle)
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

-- Orders a platoon to move along a route
---@param platoon Platoon
---@param route (Marker | Vector)[]
---@param squad? string
function PlatoonMoveRoute(platoon, route, squad)
    for _, node in route do
        if type(node) == 'string' then
            node = ScenarioUtils.MarkerToPosition(node)
        end
        platoon:MoveToLocation(node, false, squad)
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
        platoon:Patrol(node, squad)
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
        platoon:AggressiveMoveToLocation(node, squad)
    end
end

--- Orders a platoon to move along a chain
---@param platoon Platoon
---@param chain MarkerChain
---@param squad? string
function PlatoonMoveChain(platoon, chain, squad)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        platoon:MoveToLocation(pos, false, squad)
    end
end

--- Orders a platoon to patrol along a chain
---@param platoon Platoon
---@param chain MarkerChain
---@param squad? string
function PlatoonPatrolChain(platoon, chain, squad)
    for _, pos in ScenarioUtils.ChainToPositions(chain) do
        platoon:Patrol(pos, squad)
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
        cmd = platoon:AggressiveMoveToLocation(pos, squad)
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
    local nameStart = string.find(tempText, ']')
    if nameStart ~= nil then
        tempData.name = LOC("<LOC "..string.sub(tempText, 2, nameStart - 1)..">")
        tempData.text = string.sub(tempText, nameStart + 2)
    else
        tempData.name = "INVALID NAME"
        tempData.text = tempText
        LOG("ERROR: Unable to find name in string: " .. text .. " (" .. tempText .. ")")
    end
    -- local timeSecs = GetGameTimeSeconds()
    -- local hours = math.floor(timeSecs / 3600)
    -- local minutes = math.mod(timeSecs, math.floor(timeSecs / 60), 60)
    -- local seconds = math.mod(timeSecs, 60)
    -- tempData.time = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    tempData.time = GetGameTime()
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
                        table.insert(Sync.Voice, {Cue = cue, Bank = bank})
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
        table.insert(Sync.Voice, {Bank = 'XGG', Cue = 'Computer_Computer_UnitRevalation_01370'})
    else
        table.insert(Sync.Voice, {Bank = 'XGG', Cue = 'Computer_Computer_UnitRevalation_01372'})
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
---@param voSound BpSound
function PlayVoiceOver(voSound)
    table.insert(Sync.Voice, voSound)
end

--- Sets enhancement restrictions from the names of the enhancements you do not want the player to build
---@param enhancements string[]
function RestrictEnhancements(enhancements)
    local restrict = {}
    for _, enh in enhancements do
        restrict[enh] = true
    end

    SimUIVars.SaveEnhancementRestriction(restrict)
    import('/lua/enhancementcommon.lua').RestrictList(restrict)
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
---@param list boolean[]
---@return boolean
function CheckObjectives(list)
    for _, val in list do
        if not val then
            return false
        end
    end
    return true
end

function SpawnCommander(brain, unit, effect, name, PauseAtDeath, DeathTrigger, enhancements)
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

    -- If true is passed as parameter then it uses default name.
    if name == true then
        ACU:SetCustomName(GetArmyBrain(brain).Nickname)
    elseif type(name) == 'string' then
        ACU:SetCustomName(name)
    end

    if PauseAtDeath then
        PauseUnitDeath(ACU)
    end

    if DeathTrigger then
        CreateUnitDeathTrigger(DeathTrigger, ACU)
    end

    return ACU
end

-- FakeTeleportUnitThread
-- Run teleport effect then delete unit
function FakeTeleportUnit(unit, killUnit)
    IssueStop({unit})
    IssueClearCommands({unit})
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

function FakeGateInUnit(unit, callbackFunction, bonesToHide)
    local bp = unit:GetBlueprint()

    if EntityCategoryContains(categories.COMMAND + categories.SUBCOMMANDER, unit) then
        unit:HideBone(0, true)
        unit:SetUnSelectable(true)
        unit:SetBusy(true)
        unit:PlayUnitSound('CommanderArrival')
        unit:CreateProjectile('/effects/entities/UnitTeleport03/UnitTeleport03_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(0.75)

        local psm = bp.Display.WarpInEffect.PhaseShieldMesh
        if psm then
            unit:SetMesh(psm, true)
        end

        unit:ShowBone(0, true)

        for _, v in bonesToHide or bp.Display.WarpInEffect.HideBones do
            unit:HideBone(v, true)
        end

        unit:SetUnSelectable(false)
        unit:SetBusy(false)

        local totalBones = unit:GetBoneCount() - 1
        for _, v in import('/lua/EffectTemplates.lua').UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(unit, bone, unit.Army, v)
            end
        end

        if psm then
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

    if callbackFunction then
        callbackFunction()
    end
end

-- Upgrades unit - for use with engineers, factories, radar, and other single upgrade path units.
-- Commander upgrades are too complicated for this
function UpgradeUnit(unit)
    local upgradeBP = unit:GetBlueprint().General.UpgradesTo
    IssueStop({unit})
    IssueClearCommands({unit})
    IssueUpgrade({unit}, upgradeBP)
end

-- Triggers a help text prompt to appear in the UI
-- See /modules/ui/help/helpstrings.lua for a list of valid Help Prompt IDs
function HelpPrompt(show)
    if not Sync.HelpPrompt then
        Sync.HelpPrompt = show
    end
end

-- Function for converting categories to string
local ToString = import('/lua/sim/CategoryUtils.lua').ToString
local Game = import('/lua/game.lua')

-- Adds scenario restriction for specified army and notify the UI/sim
-- e.g. AddRestriction(1, categories.TECH2) -> restricts all T2 units for army 1
-- e.g. AddRestriction('ARMY_1', categories.TECH2) -> restricts all T2 units for army 1
function AddRestriction(army, categories)

    if type(categories) ~= 'userdata' then
        WARN('ScenarioFramework.AddRestriction() called with invalid category expression "' .. ToString(categories) .. '" '
          .. 'instead of category expression, e.g. categories.LAND ')
    else
        SimUIVars.SaveTechRestriction(categories)
        AddBuildRestriction(army, categories)

        -- Add scenario restriction to game restrictions
        Game.AddRestriction(categories, army)
        Sync.Restrictions = Game.GetRestrictions()
    end
end
-- Removes scenario restriction for specified army and notify the UI/sim
-- e.g. RemoveRestriction('ARMY_1', categories.TECH2) -> removes T2 units restriction for army 1
function RemoveRestriction(army, categories, isSilent)

    if type(categories) ~= 'userdata' then
        WARN('ScenarioFramework.RemoveRestriction() called with invalid category expression "' .. ToString(categories) .. '" '
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
    end
end

-- Toggles whether or not to ignore all restrictions
-- this function is useful when trying to transfer restricted units between armies
--[[ e.g.
--  ScenarioFramework.IgnoreRestrictions(true)
--  ScenarioFramework.GiveUnitToArmy(unit, armyIndex)
--  ScenarioFramework.IgnoreRestrictions(false)
--]]
function IgnoreRestrictions(isIgnored)
    Game.IgnoreRestrictions(isIgnored)
    Sync.Restrictions = Game.GetRestrictions()
end

-- Returns lists of factories by category
-- <point> and <radius> are optional
-- this allows you to know which factories can build and which can't
-- useful if you want to track what factories can do what
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

-- Creates a visible area for <vizArmy> at <vizLocation> of <vizRadius> size.
-- If vizLifetime is 0, the entity lasts forever.  Otherwise for <vizLifetime> seconds.
-- Function returns an entity so you can destroy it later if you want
function CreateVisibleAreaLocation(vizRadius, vizLocation, vizLifetime, vizArmy)
    if type(vizLocation) == 'string' then
        vizLocation = ScenarioUtils.MarkerToPosition(vizLocation)
    end
    local spec = {
        X = vizLocation[1],
        Z = vizLocation[3],
        Radius = vizRadius,
        LifeTime = vizLifetime,
        Army = vizArmy:GetArmyIndex(),
    }
    local vizEntity = VizMarker(spec)

    return vizEntity
end

function CreateVisibleAreaAtUnit(vizRadius, vizUnit, vizLifetime, vizArmy)
    local pos = vizUnit:GetPosition()
    local spec = {
        X = pos[1],
        Z = pos[3],
        Radius = vizRadius,
        LifeTime = vizLifetime,
        Army = vizArmy:GetArmyIndex(),
    }
    local vizEntity = VizMarker(spec)

    return vizEntity
end

-- Similar to the above function except it takes in an {X, Z} location rather
-- Than an {X, Y, Z} position
function CreateVisibleArea(vizRadius, vizX, vizZ, vizLifetime, vizArmy)
    local spec = {
        X = vizX,
        Z = vizZ,
        Radius = vizRadius,
        LifeTime = vizLifetime,
        Army = vizArmy,
    }
    local vizEntity = VizMarker(spec)

    return vizEntity
end

-- Sets the playable area for an operation to rect size.
-- this function allows you to use ScenarioUtilities function AreaToRect for the rectangle.
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
        table.insert(Sync.Voice, {Cue = 'Computer_Computer_MapExpansion_01380', Bank = 'XGG'})
    end

    import('/lua/SimSync.lua').SyncPlayableRect(rect)
    Sync.NewPlayableArea = {x0, y0, x1, y1}
    ForkThread(GenerateOffMapAreas)
end

function PlayableRectCameraThread(rect)
--    local cam = import('/lua/simcamera.lua').SimCamera('WorldCamera')
--    LockInput()
--    cam:UseGameClock()
--    cam:SyncPlayableRect(rect)
--    cam:MoveTo(rect, 1)
--    cam:WaitFor()
--    UnLockInput()
end

-- Sets platoon to only be built once
function BuildOnce(platoon)
    local aiBrain = platoon:GetBrain()
    aiBrain:PBMSetPriority(platoon, 0)
end

-- TODO: Stop mission scripts from using this function, then remove it.
function AddObjective(Type, Complete, Title, Description, Image, Progress, Target)
    Objectives.AddObjective(Type, Complete, Title, Description, Image, Progress, Target)
end

-- TODO: Stop mission scripts from using this function, then remove it.
function UpdateObjective(Title, UpdateField, NewData, objTag)
    Objectives.UpdateObjective(Title, UpdateField, NewData, objTag)
end

-- Moves the camera to the specified area in 1 second
function StartCamera(area)
    local cam = SimCamera('WorldCamera')

    cam:ScaleMoveVelocity(0.03)
    cam:MoveTo(area, 1)
    cam:WaitFor()
    UnlockInput()
end

-- Sets an army color to a factional, or factional-ally, color given by art
-- Aeon
function SetAeonColor(number)
    SetArmyColor(number, 41, 191, 41)
end

function SetAeonAllyColor(number)
    SetArmyColor(number, 165, 200, 102)
end

function SetAeonNeutralColor(number)
    SetArmyColor(number, 16, 86, 16)
end

-- Cybran
function SetCybranColor(number)
    SetArmyColor(number, 128, 39, 37)
end

function SetCybranAllyColor(number)
    SetArmyColor(number, 219, 74, 58)
end

function SetCybranNeutralColor(number)
    SetArmyColor(number, 165, 9, 1) -- 84, 13, 13
end
-- UEF
function SetUEFColor(number)
    SetArmyColor(number, 41, 40, 140)
end;

function SetUEFAllyColor(number)
    SetArmyColor(number, 71, 114, 148)
end

function SetUEFNeutralColor(number)
    SetArmyColor(number, 16, 16, 86)
end

function SetCoalitionColor(number)
    SetArmyColor(number, 80, 80, 240)
end

-- Neutral
function SetNeutralColor(number)
    SetArmyColor(number, 211, 211, 180)
end

-- SC:FA colors
-- Aeon
function SetAeonPlayerColor(number)
    SetArmyColor(number, 36, 182, 36)
end

function SetAeonEvilColor(number)
    SetArmyColor(number, 159, 216, 2)
end

function SetAeonAlly1Color(number)
    SetArmyColor(number, 16, 86, 16)
end

function SetAeonAlly2Color(number)
    SetArmyColor(number, 123, 255, 125)
end
-- Cybran
function SetCybranPlayerColor(number)
    SetArmyColor(number, 231, 3, 3)
end

function SetCybranEvilColor(number)
    SetArmyColor(number, 225, 70, 0)
end

function SetCybranAllyColor(number)
    SetArmyColor(number, 130, 33, 30)
end

-- UEF
function SetUEFPlayerColor(number)
    SetArmyColor(number, 41, 41, 225)
end

function SetUEFAlly1Color(number)
    SetArmyColor(number, 81, 82, 241)
end

function SetUEFAlly2Color(number)
    SetArmyColor(number, 133, 148, 255)
end

-- Seraphim
function SetSeraphimColor(number)
    SetArmyColor(number, 167, 150, 2)
end

-- Loyalist
function SetLoyalistColor(number)
    SetArmyColor(number, 0, 100, 0)
end

function AMPlatoonCounter(aiBrain, name)
    if not aiBrain.AttackData.PlatoonCount[name] then
        aiBrain.AttackData.PlatoonCount[name] = 0
    end
    return aiBrain.AttackData.PlatoonCount[name]
end

function PlatoonAttackWithTransports(platoon, landingChain, attackChain, instant, moveChain)
    ForkThread(PlatoonAttackWithTransportsThread, platoon, landingChain, attackChain, instant, moveChain)
end

function PlatoonAttackWithTransportsThread(platoon, landingChain, attackChain, instant, moveChain)
    local aiBrain = platoon:GetBrain()
    local allUnits = platoon:GetPlatoonUnits()
    local startPos = platoon:GetPlatoonPosition()
    local units = {}
    local transports = {}
    for _, v in allUnits do
        if EntityCategoryContains(categories.TRANSPORTATION, v) then
            table.insert(transports, v)
        else
            table.insert(units, v)
        end
    end

    local landingLocs = ScenarioUtils.ChainToPositions(landingChain)
    local landingLocation = landingLocs[Random(1, table.getn(landingLocs))]

    if instant then
        AttachUnitsToTransports(units, transports)
        if moveChain and not ScenarioPlatoonAI.MoveAlongRoute(platoon, ScenarioUtils.ChainToPositions(moveChain)) then
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
            for num, unit in units do
                if not unit.Dead and unit:IsUnitState('Attached') then
                    attached = true
                    break
                end
            end
        end
    else
        if not import('/lua/ai/aiutilities.lua').UseTransports(units, transports, landingLocation) then
            return
        end
    end

    local attackLocs = ScenarioUtils.ChainToPositions(attackChain)
    for _, v in attackLocs do
        IssuePatrol(units, v)
    end

    if instant then
        IssueMove(transports, startPos)
        aiBrain:AssignUnitsToPlatoon('Army_Pool', transports, 'Unassigned', 'None')
    end
end

-- Automatically attaches <units> to attach points on <transports>
function AttachUnitsToTransports(units, transports)
    local locUnits = {}
    for _, v in units do
        table.insert(locUnits, v)
    end
    local transportBones = {}
    local numTransports = table.getn(transports)
    for k, unit in transports do
        transportBones[k] = {
            Lrg = {},
            Med = {},
            Sml = {},
        }
        for i = 1, unit:GetBoneCount() do
            if unit:GetBoneName(i) ~= nil then
                if string.find(unit:GetBoneName(i), 'Attachpoint_Lrg') then
                    table.insert(transportBones[k].Lrg, unit:GetBoneName(i))
                elseif string.find(unit:GetBoneName(i), 'Attachpoint_Med') then
                    table.insert(transportBones[k].Med, unit:GetBoneName(i))
                elseif string.find(unit:GetBoneName(i), 'Attachpoint') then
                    table.insert(transportBones[k].Sml, unit:GetBoneName(i))
                end
            end
        end
    end
    local sortedGroup = {}
    for i = 1, table.getn(locUnits) do
        local highest = 0
        local key, value
        for k, v in locUnits do
            local bp = v:GetBlueprint()
            if not bp.Transport.TransportClass then
                if 1 > highest then
                    highest = 1
                    value = v
                    key = k
                end
            else
                if bp.Transport.TransportClass > highest then
                    highest = bp.Transport.TransportClass
                    value = v
                    key = k
                end
            end
        end
        sortedGroup[i] = value
        table.remove(locUnits, key)
    end
    locUnits = sortedGroup
    for _, v in locUnits do
        if not v:IsUnitState('Attached') then
            -- Attach locUnits and remove bones when locUnits attached
            local bp = v:GetBlueprint()
            local notInserted = true
            local attachBone = -1
            if v:IsValidBone('AttachPoint', false) then
                attachBone = 'AttachPoint'
            end
            local i = 1
            if bp.Transport.TransportClass == 3 then
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Lrg) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Lrg, 1)
                        transports[i]:OnTransportAttach(bone, v)
                        v:AttachBoneTo(attachBone, transports[i], bone)
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
            elseif bp.Transport.TransportClass == 2 then
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Med) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Med, 1)
                        transports[i]:OnTransportAttach(bone, v)
                        v:AttachBoneTo(attachBone, transports[i], bone)
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
            else
                while notInserted and i <= numTransports do
                    if not table.empty(transportBones[i].Sml) then
                        notInserted = false
                        local bone = table.remove(transportBones[i].Sml, 1)
                        transports[i]:OnTransportAttach(bone, v)
                        v:AttachBoneTo(attachBone, transports[i], bone)
                    end
                    i = i + 1
                end
            end
        end
    end
end

-- Take a table of markers, and return the marker with the largest number of target units in a specified radius around it.
-- ex: attackLocation = ScenarioFramework.DetermineBestAttackLocation(ArmyBrains[Aeon], ArmyBrains[Player], 'enemy', ScenarioUtils.ChainToPositions('Attack_Grid'), 64)
function DetermineBestAttackLocation(attackingBrain, targetBrain, relationship, tableOfAttackLocations, pointRadius)
    local highestUnitCountFound = 0
    local targetBrainUnitCount = 0
    local foundUnits = nil
    local attackLocation = nil

    for locationsCount, position in tableOfAttackLocations do
        foundUnits = attackingBrain:GetUnitsAroundPoint(categories.ALLUNITS, position, pointRadius, relationship)

        for throwawayCounter, unit in foundUnits do
            if unit:GetAIBrain() == targetBrain then
                targetBrainUnitCount = targetBrainUnitCount + 1
            end
        end
        if targetBrainUnitCount > highestUnitCountFound or attackLocation == nil then
            highestUnitCountFound = targetBrainUnitCount
            attackLocation = position
        end
        targetBrainUnitCount = 0
    end

    return attackLocation
end

-- Returns a random entry from a table.
-- ex: takeoff_Spot = ScenarioFramework.GetRandomEntry(ScenarioUtils.ChainToPositions('Offscreen_Launch_Points'))
function GetRandomEntry(tableOfData)
    return tableOfData[Random(1, table.getn(tableOfData))]
end

function KillBaseInArea(brain, area, category)
    local rect = area
    local unitTable = {}
    if type(area) == 'table' then
        for _, subArea in area do
            if type(subArea) == 'string' then
                rect = ScenarioUtils.AreaToRect(subArea)
            else
                rect = subArea
            end
            for _, unit in GetUnitsInRect(rect) do
                table.insert(unitTable, unit)
            end
        end
    else
        if type(area) == 'string' then
            rect = ScenarioUtils.AreaToRect(area)
        end
        unitTable = GetUnitsInRect(rect)
    end
    if not category then
        category = categories.STRUCTURE + categories.ENGINEER
    end
    local filteredUnits = {}
    if unitTable then
        for num, unit in unitTable do
            if not unit.Dead and unit:GetAIBrain() == brain and EntityCategoryContains(category, unit) then
                table.insert(filteredUnits, unit)
            end
        end
        ForkThread(KillBaseInAreaThread, filteredUnits)
    end
end

function KillBaseInAreaThread(unitTable)
    local numUnits = table.getn(unitTable)
    local waitNum = math.floor(numUnits / 20)
    for num, unit in unitTable do
        if not unit.Dead then
            unit:Kill()
        end
        if waitNum > 0 and num >= waitNum and math.mod(waitNum, num) == 0 then
            WaitTicks(6)
        end
    end
end

function StartOperationJessZoom(areaName, callbackFunction, duration)
    ForkThread(StartOperationJessZoomThread, areaName, callbackFunction, duration)
end

function StartOperationJessZoomThread(areaName, callbackFunction, duration)
    Cinematics.EnterNISMode()
    duration = duration or 3
    Cinematics.CameraMoveToRectangle(ScenarioUtils.AreaToRect(areaName), duration)
    Cinematics.ExitNISMode()
    if callbackFunction then
        callbackFunction()
    end
end

function EndOperationSafety(units)
    ScenarioInfo.OpEnded = true
    ResetUITimer() -- Turn off any timer going (per Ted)

    for k, v in ArmyBrains do
        for subk, subv in ArmyBrains do
            if not IsAlly(k, subk) then
                SetAlliance(v.Name, subv.Name, 'Neutral')
            end
        end
        for subk, subv in v:GetListOfUnits(categories.COMMAND, false) do
            subv.CanTakeDamage = false
            subv.CanBeKilled = false
        end
        if units and not table.empty(units) then
            for subk, subv in units do
                if not subv.Dead then
                    subv.CanTakeDamage = false
                    subv.CanBeKilled = false
                end
            end
        end
    end
end

function MidOperationCamera(unit, track, time)
    ForkThread(OperationCameraThread, unit:GetPosition(), unit:GetHeading(), false, track, unit , true, time)
end

function EndOperationCamera(unit, track)
    local faction = false
    if EntityCategoryContains(categories.COMMAND, unit) then
        local bp = unit:GetBlueprint()
        if bp.CategoriesHash.UEF then
            faction = 1
        elseif bp.CategoriesHash.AEON then
            faction = 2
        elseif bp.CategoriesHash.CYBRAN then
            faction = 3
        elseif bp.CategoriesHash.SERAPHIM then
            faction = 4
        end
    end
    ForkThread(OperationCameraThread, unit:GetPosition(), unit:GetHeading(), faction, track, unit , false)
end

function EndOperationCameraLocation(location)
    ForkThread(OperationCameraThread, location, 0, false, false, false, false)
end

function OperationCameraThread(location, heading, faction, track, unit, unlock, time)
    local cam = import('/lua/simcamera.lua').SimCamera('WorldCamera')
    LockInput()
    cam:UseGameClock()
    WaitTicks(1)
    -- Track the unit; not totally working properly yet
    if track and unit then
        local zoomVar = 50
        local pitch = .4
        if EntityCategoryContains(categories.uaa0310, unit) then
            zoomVar = 150
            pitch = .3
        end
        local pos = unit:GetPosition()
        local marker = {
            orientation = VECTOR3(heading, .5, 0),
            position = {pos[1], pos[2] - 15, pos[3] },
            zoom = zoomVar,
        }

        cam:NoseCam(unit, pitch, zoomVar, 1)
    else
        -- Only do the 2.5 second wait if a faction is given; that means its a commander
        if faction then
            local marker = {
                orientation = VECTOR3(heading + 3.14149, .2, 0),
                position = {location[1], location[2] + 1, location[3] },
                zoom = FLOAT(15),
            }
            cam:SnapToMarker(marker)
            WaitSeconds(2.5)
        end
        if faction == 1 then -- UEF
            marker = {
                orientation = {heading + 3.14149, .38, 0 },
                position = {location[1], location[2] + 7.5, location[3] },
                zoom = 58,
            }
        elseif faction == 2 then -- Aaeon
            marker = {
                orientation = VECTOR3(heading + 3.14149, .45, 0),
                position = {location[1], location[2], location[3] },
                zoom = FLOAT(50),
            }
        elseif faction == 3 then -- Cybran
            marker = {
                orientation = VECTOR3(heading + 3.14149, .45, 0),
                position = {location[1], location[2] + 5, location[3] },
                zoom = FLOAT(45),
            }
        else
            marker = {
                orientation = VECTOR3(heading + 3.14149, .38, 0),
                position = location,
                zoom = 45,
            }
        end
        cam:SnapToMarker(marker)
        cam:Spin(.03)
    end
    if unlock then
        WaitSeconds(time)
        -- Matt 11/27/06. This is functional now, but the snap is pretty harsh. Need someone else to look at it
        cam:RevertRotation()
        cam:UseSystemClock()
        UnlockInput()
    end
end

-- For mid-operation NISs
function MissionNISCamera(unit, blendtime, holdtime, orientationoffset, positionoffset, zoomval)
    ForkThread(MissionNISCameraThread, unit, blendtime, holdtime, orientationoffset, positionoffset, zoomval)
end

function MissionNISCameraThread(unit, blendtime, holdtime, orientationoffset, positionoffset, zoomval)
    if not ScenarioInfo.NIS then
        ScenarioInfo.NIS = true
        local cam = import('/lua/simcamera.lua').SimCamera('WorldCamera')
        LockInput()
        cam:UseGameClock()
        WaitTicks(1)

        local position = unit:GetPosition()
        local heading = unit:GetHeading()
        local marker = {
            orientation = VECTOR3(heading + orientationoffset[1], orientationoffset[2], orientationoffset[3]),
            position = {position[1] + positionoffset[1], position[2] + positionoffset[2], position[3] + positionoffset[3] },
            zoom = FLOAT(zoomval),
        }
        cam:MoveToMarker(marker, blendtime)
        WaitSeconds(holdtime)
        cam:RevertRotation()
        cam:UseSystemClock()
        UnlockInput()
        ScenarioInfo.NIS = false
    end
end

-- NIS Garbage
function OperationNISCamera(unit, camInfo)
    if camInfo.markerCam then
        ForkThread(OperationNISCameraThread, unit, camInfo)
    else
        local unitInfo = {Position = unit:GetPosition(), Heading = unit:GetHeading() }
        ForkThread(OperationNISCameraThread, unitInfo, camInfo)
    end
end

-- CDR Death (pass hold only if it's a mid-operation death)
function CDRDeathNISCamera(unit, hold)
    PauseUnitDeathActive = true
    local camInfo = {
        blendTime = 1,
        holdTime = hold,
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

-- For op intro (currently not used)
function IntroductionNISCamera(unit)
    local unitInfo = {Position = unit:GetPosition(), Heading = unit:GetHeading()}
    ForkThread(OperationNISCameraThread, unitInfo, camInfo)
end

---------------
--   NIS Thread
---------------
--   camInfo {
--   blendTime(seconds) - how long the camera will spend interpolating from play camera to the NIS destination
--   holdTime(seconds) - NIS duration after blendTime. if "nil", signals an "end of op" camera
--   orientationOffset(radians) - offsets the orientation of the camera in radians (x = heading, y = pitch, z = roll)
--   positionOffset(ogrids) - offsets the camera from the marker (y = up)
--   zoomVal(?) - sets the distance from the marker
--   spinSpeed(ogrids/sec?) - sets a rate the camera will rotate around it's marker (positive = counterclockwise)
--   markerCam(bool) - allows the NIS to use a marker rather than a unit
--   resetCam(bool) - disables the interpolation at the end of the NIS, needed for NISs that appear outside of the playable area.
--   overrideCam(bool) - allows an NIS to interrupt an NIS that is currently playing (typically used for end of operation cameras)
--   playableAreaIn(area marker
--   playableAreaOut(area marker)
--   vizRadius(ogrids)
--   }
function OperationNISCameraThread(unitInfo, camInfo)
    if not ScenarioInfo.NIS or camInfo.overrideCam then
        local cam = import('/lua/simcamera.lua').SimCamera('WorldCamera')

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
            orientation = VECTOR3(heading + camInfo.orientationOffset[1], camInfo.orientationOffset[2], camInfo.orientationOffset[3]),
            position = {position[1] + camInfo.positionOffset[1], position[2] + camInfo.positionOffset[2], position[3] + camInfo.positionOffset[3]},
            zoom = FLOAT(camInfo.zoomVal),
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

function OnPostLoad()
    if ScenarioInfo.DialogueFinished then
        for k, v in ScenarioInfo.DialogueFinished do
            ScenarioInfo.DialogueFinished[k] = true
        end
    end
end

function FlagUnkillableSelect(armyNumber, units)
    for _, v in units do
        if not v.Dead and v:GetAIBrain():GetArmyIndex() == armyNumber then
            if not v.CanTakeDamage then
                v.UndamagableFlagSet = true
            end
            if not v.CanBeKilled then
                v.UnKillableFlagSet = true
            end
            v.CanTakeDamage = false
            v.CanBeKilled = false
        end
    end
end

function FlagUnkillable(armyNumber, exceptions)
    local units = ArmyBrains[armyNumber]:GetListOfUnits(categories.ALLUNITS, false)
    for _, v in units do
        if not v.CanTakeDamage then
            v.UndamagableFlagSet = true
        end
        if not v.CanBeKilled then
            v.UnKillableFlagSet = true
        end
        v.CanTakeDamage = false
        v.CanBeKilled = false
    end
    if exceptions then
        for _, v in exceptions do
            -- Only process units that weren't already set
            if not v.UnKillableFlagSet then
                v.CanBeKilled = true
            end
            if not v.UndamagableFlagSet then
                v.CanTakeDamage = true
            end
        end
    end
end

function UnflagUnkillable(armyNumber)
    local units = ArmyBrains[armyNumber]:GetListOfUnits(categories.ALLUNITS, false)
    for _, v in units do
        -- Only revert units that weren't already set
        if not v.UnKillableFlagSet then
            v.CanBeKilled = true
        end
        if not v.UndamagableFlagSet then
            v.CanTakeDamage = true
        end
        v.KilledFlagSet = nil
        v.DamageFlagSet = nil
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

-- Below is for anti-off mapping function
function GenerateOffMapAreas()
    local playablearea = {}
    local OffMapAreas = {}

    if  ScenarioInfo.MapData.PlayableRect then
        playablearea = ScenarioInfo.MapData.PlayableRect
    else
        playablearea = {0, 0, ScenarioInfo.size[1], ScenarioInfo.size[2]}
    end

    local x0 = playablearea[1]
    local y0 = playablearea[2]
    local x1 = playablearea[3]
    local y1 = playablearea[4]

    -- This is a rectangle above the playable area that is longer, left to right, than the playable area
    local OffMapArea1 = {}
    OffMapArea1.x0 = (x0 - 100)
    OffMapArea1.y0 = (y0 - 100)
    OffMapArea1.x1 = (x1 + 100)
    OffMapArea1.y1 = y0

    -- This is a rectangle below the playable area that is longer, left to right, than the playable area
    local OffMapArea2 = {}
    OffMapArea2.x0 = (x0 - 100)
    OffMapArea2.y0 = (y1)
    OffMapArea2.x1 = (x1 + 100)
    OffMapArea2.y1 = (y1 + 100)

    -- This is a rectangle to the left of the playable area, that is the same height (up to down) as the playable area
    local OffMapArea3 = {}
    OffMapArea3.x0 = (x0 - 100)
    OffMapArea3.y0 = y0
    OffMapArea3.x1 = x0
    OffMapArea3.y1 = y1

    -- This is a rectangle to the right of the playable area, that is the same height (up to down) as the playable area
    local OffMapArea4 = {}
    OffMapArea4.x0 = x1
    OffMapArea4.y0 = y0
    OffMapArea4.x1 = (x1 + 100)
    OffMapArea4.y1 = y1

    OffMapAreas = {OffMapArea1, OffMapArea2, OffMapArea3, OffMapArea4}

    ScenarioInfo.OffMapAreas = OffMapAreas
    ScenarioInfo.PlayableArea = playablearea
end

function AntiOffMapMainThread()

    WaitTicks(11)
    GenerateOffMapAreas()
    local WaitTicks = coroutine.yield
    local OffMapAreas = {}
    local UnitsThatAreOffMap = {}

    while ScenarioInfo.OffMapPreventionThreadAllowed == true do
        OffMapAreas = ScenarioInfo.OffMapAreas
        NewUnitsThatAreOffMap = {}

        for index, OffMapArea in OffMapAreas do
            local UnitsThatAreInOffMapRect = GetUnitsInRect(OffMapArea)
                if UnitsThatAreInOffMapRect then
                    for index, UnitThatIsOffMap in  UnitsThatAreInOffMapRect do
                        if not UnitThatIsOffMap.IAmOffMapThread then
                            table.insert(NewUnitsThatAreOffMap, UnitThatIsOffMap)
                        end
                    end
                else
            end
            WaitTicks(11)
        end

        WaitTicks(11)
        local NumberOfUnitsOffMap = table.getn(NewUnitsThatAreOffMap)
        for index, NewUnitThatIsOffMap in NewUnitsThatAreOffMap do
            if not NewUnitThatIsOffMap.IAmOffMap then
                NewUnitThatIsOffMap.IAmOffMap = true
            end
            -- This is to make sure that we only do this check for air units
            if not NewUnitThatIsOffMap.IAmOffMapThread and EntityCategoryContains(categories.AIR, NewUnitThatIsOffMap) then
                -- This is to make it so it only impacts player armies, not AI or civilian or mission map armies
                if IsHumanUnit(NewUnitThatIsOffMap) then
                    NewUnitThatIsOffMap.IAmOffMapThread = NewUnitThatIsOffMap:ForkThread(IAmOffMap)
                else
                    -- So that we don't bother checking each AI unit more than once
                    NewUnitThatIsOffMap.IAmOffMapThread = true
                end
            end
        end

        NewUnitsThatAreOffMap = nil
    end
end

function IsHumanUnit(self)
    for _, Army in ScenarioInfo.ArmySetup do
        if Army.ArmyIndex == self.Army then
            if Army.Human == true then
                return true
            else
                return false
            end
        end
    end
end

function IsUnitInPlayableArea(unit)
    local playableArea = ScenarioInfo.PlayableArea
    local position = unit:GetPosition()
    if  position[1] > playableArea[1] and position[1] < playableArea[3] and  position[3] > playableArea[2] and position[3] < playableArea[4] then
        return true
    else
        return false
    end
end

-- This is for bad units who choose to go off map, shame on them
function IAmOffMap(self)
    self.TimeIHaveBeenOffMap = 0
    self.TimeIHaveBeenOnMap = 0
    self.TimeIAmAllowedToBeOffMap = GetTimeIAmAllowedToBeOffMap(self)
    while not self.Dead do
        if IsUnitInPlayableArea(self) then
            self.TimeIHaveBeenOnMap = (self.TimeIHaveBeenOnMap + 1)

            if self.TimeIHaveBeenOnMap > 5 then
                self:ForkThread(KillIAmOffMapThread)
            end
        else
            self.TimeIHaveBeenOffMap = (self.TimeIHaveBeenOffMap + 1)
        end

        if self.TimeIHaveBeenOffMap > self.TimeIAmAllowedToBeOffMap then
            self:ForkThread(IAmABadUnit)

        end
        WaitSeconds(1)
    end
end

function IAmABadUnit(self)
    local position = self:GetPosition()
    local playableArea = ScenarioInfo.PlayableArea
    local NearestOnPlayableAreaPointToMe = {}
    NearestOnPlayableAreaPointToMe[2] = position[2]

    if position[1] > playableArea[1] and position[1] < playableArea[3] then
        NearestOnPlayableAreaPointToMe[1] = position[1]
    elseif position[1] < playableArea[1] then
        NearestOnPlayableAreaPointToMe[1] = (playableArea[1] + 5)
    elseif position[1] > playableArea[3] then
        NearestOnPlayableAreaPointToMe[1] = (playableArea[3] - 5)
    end

    if position[3] > playableArea[2] and position[3] < playableArea[4] then
        NearestOnPlayableAreaPointToMe[3] = position[3]
    elseif position[3] < playableArea[2] then
        NearestOnPlayableAreaPointToMe[3] = (playableArea[2] + 5)
    elseif position[3] > playableArea[4] then
        NearestOnPlayableAreaPointToMe[3] = (playableArea[4] - 5)
    end

    IssueClearCommands({self})
    IssueMove({self}, position)
end

function GetTimeIAmAllowedToBeOffMap(self)
    local airspeed = self:GetBlueprint().Air.MaxAirspeed
    local value = airspeed

    if EntityCategoryContains(categories.BOMBER, self) then
        value = airspeed / 5
    elseif EntityCategoryContains(categories.TRANSPORTATION, self) then
        value = 2
    end

    for i = 1, self:GetWeaponCount() do
        local wep = self:GetWeapon(i)
        if wep.Label ~= 'DeathWeapon' and wep.Label ~= 'DeathImpact' then
            if wep:GetCurrentTarget()  then
                value = airspeed * 2
            end

        end
    end

    return value
end

function KillIAmOffMapThread(self)
    KillThread(self.IAmOffMapThread)
    self.IAmOffMapThread = nil
    self.TimeIHaveBeenOffMap = 0
    self.TimeIHaveBeenOnMap = 0
end
