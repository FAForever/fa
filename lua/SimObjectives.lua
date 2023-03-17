-----------------------------------------------------------------
-- File     :  /lua/SimObjectives.lua
-- Summary  : Sim side objectives
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias ObjectiveType 'primary' | 'secondary' | 'Bonus'
---@alias ObjectiveStatus 'complete' | 'incomplete'
---@alias ArmyStatistic "Units_Active" | "Units_Killed" | "Units_History" | "Enemies_Killed" | "Economy_TotalProduced_Energy" | "Economy_TotalConsumed_Energy" | "Economy_Income_Energy" | "Economy_Output_Energy" | "Economy_Stored_Energy" | "Economy_Reclaimed_Energy" | "Economy_MaxStorage_Energy" | "Economy_PeakStorage_Energy" | "Economy_TotalProduced_Mass" | "Economy_TotalConsumed_Mass" | "Economy_Income_Mass" | "Economy_Output_Mass" | "Economy_Stored_Mass" | "Economy_Reclaimed_Mass" | "Economy_MaxStorage_Mass" | "Economy_PeakStorage_Mass",

---@class Objective
---@field Tag string                    # Unique identifier used to sync between sim <-> UI
---@field Active boolean                # Flag to indicate the objective is in progress 
---@field Complete boolean              # Flag to indicate success or failure
---@field Hidden boolean                # Flag to indicate hiding the objective from screen 
---@field Decals table<string, Decal>   # Table of decals associated with the objective
---@field IconOverrides string[]        # Array of strings to override the strategical icon
---@field VizMarkers VizMarker[]        # Array of visibility markers associated with the objective
---@field UnitMarkers ObjectiveArrow[]  # Array of unit markers associated with the objective
---@field Decal Decal                   # A single decal
---@field NextTargetTag any             # ???
---@field PositionUpdateThreads any     # ???
---@field Title string                  # Title of the object, supports strings with LOC
---@field Description string            # Description of the object, supports strings with LOC
---@field SimStartTime number           # Set when the objective starts
---@field AddProgressCallback function  # Adds a progression callback
---@field AddResultCallback function    # Adds a completion callback

-- SUPPORTED OBJECTIVE TYPES:
-- Kill
-- Capture
-- KillOrCapture
-- Reclaim
-- ReclaimProp
-- Locate
-- SpecificUnitsInArea
-- CategoriesInArea
-- ArmyStatCompare
-- UnitStatCompare
-- CategoryStatCompare
-- Protect
-- Timer
-- Unknown
-- Camera

local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local Triggers = import("/lua/scenariotriggers.lua")
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker
local objNum = 0 -- Used to create unique tags for objectives
local DecalLOD = 4000
local objectiveDecal = '/env/utility/decals/objective_debug_albedo.dds'
local SavedList = {}

-- Return one of the human players in a game, using this instead of GetFocusArmy()
-- to get a deterministic army index in coop.
local playerArmy
function GetPlayerArmy()
    if not playerArmy then
        for _, v in ArmyBrains do
            if v.BrainType == 'Human' then
                playerArmy = v:GetArmyIndex()
                break
            end
        end
    end
    return playerArmy
end

-- Camera objective by roates
-- Creates markers that satisfy the objective when they are all inside of the camera viewport
-- Camera(objectiveType, completeState, title, description, positionTable)

-- objectiveType = 'primary' or 'bonus' etc...
-- completeState = 'complete' or 'incomplete'
-- title = title string table from map's string file
-- description = description string table from map's string file
-- positionTable = table of position tables where markers will be created. {{x1, y1, z1}, {x2, y2, z2}} format
function Camera(objectiveType, completeState, title, description, positionTable)
    local numMarkers = 0
    local curMarkers = 0
    local objective = AddObjective(objectiveType, completeState, title, description, nil, positionTable)

    local RemoveMarker = function(mark)
        mark:Destroy()
        curMarkers = curMarkers + 1

        UpdateObjective(title, 'Progress', '('..curMarkers..'/'..numMarkers..')', objective.Tag)
        objective:OnProgress(curMarkers, numMarkers)

        if curMarkers == numMarkers then
            objective.Active = false
            UpdateObjective(title, 'complete', 'complete', objective.Tag)
            objective:OnResult(true)
        end
    end

    for i, v in positionTable do
        numMarkers = numMarkers + 1
        local newMark = import("/lua/simcameramarkers.lua").AddCameraMarker(v)
        newMark:AddCallback(RemoveMarker)
    end

    objective:OnProgress(curMarkers, numMarkers)
    UpdateObjective(title, 'Progress', '('..curMarkers..'/'..numMarkers..')', objective.Tag)

    return objective
end

-- ControlGroup
-- Complete when specified units matching the target blueprint types are in
-- a control group. We don't care exactly which units they are (pre-built or
-- newly constructed), as long as the requirements are ment. We just check
-- the area for what units are in control groups and look at the blueprints (and optionally
-- match the army, use -1 for don't care).
-- Target = {
-- Requirements = {
--  {Category=<cat1>, CompareOp=<op>, Value=<x>, [ArmyIndex=<index>]},
--  {Category=<cat2>, CompareOp=<op>, Value=<y>, [ArmyIndex=<index>]},
--  {Category=<cat3>, CompareOp=<op>, Value=<z>, [ArmyIndex=<index>]},
-- }
-- }
-- op is one of: '<=', '>=', '<', '>', or '=='
function ControlGroup(Type, Complete, Title, Description, Target)

    local image = GetActionIcon('group')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local lastReqsMet = -1

    -- Call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    local function WatchGroups(requirements)
        local totalReqs = table.getn(requirements)
        while objective.Active do
            local reqsMet = 0

            for i, requirement in requirements do
                local units = ScenarioInfo.ControlGroupUnits
                local cnt = 0
                if units then
                    for _, unit in units do
                        if not requirement.ArmyIndex or (requirement.ArmyIndex == unit.Army) then
                            if EntityCategoryContains(requirement.Category, unit) then
                                if not unit.Marked and objective.MarkUnits then
                                    unit.Marked = true
                                    local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                                    local arrow = ObjectiveArrow {AttachTo = unit}
                                    objective:AddUnitTarget(unit)
                                end
                                cnt = cnt + 1
                            end
                        end
                    end
                end
                if not requirement.CompareFunc then
                    requirement.CompareFunc = GetCompareFunc(requirement.CompareOp)
                end
                if requirement.CompareFunc(cnt, requirement.Value) then
                    reqsMet = reqsMet +1
                end
            end

            if lastReqsMet ~= reqsMet then
                local progress = string.format('(%s/%s)', reqsMet, totalReqs)
                UpdateObjective(Title, 'Progress', progress, objective.Tag)
                objective:OnProgress(reqsMet, totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(10)
        end
    end
    UpdateObjective(Title, 'Progress', '(0/0)', objective.Tag)
    ForkThread(WatchGroups, Target.Requirements)

    return objective
end

-- CreateGroup
-- Takes list of objective tables which are produced by the objective creation
-- functions such as Kill, Protect, Capture, etc.
-- UserCallback is executed when all objectives in the list are complete
function CreateGroup(name, userCallback, numRequired)
    local objectiveGroup =  {
        Name = name,
        Active = true,
        Objectives = {},
        NumRequired = numRequired,
        NumCompleted = 0,
        AddObjective = function(self, objective) end, -- Defined later
        RemoveObjective = function(self, objective) end, -- Defined later
        OnComplete = userCallback,
    }

    local function OnResult(result)
        if not objectiveGroup.Active then
            return
        end

        if result then
            objectiveGroup.NumCompleted = objectiveGroup.NumCompleted + 1
        end

        if objectiveGroup.NumRequired then
            if objectiveGroup.NumCompleted < objectiveGroup.NumRequired then
                return
            end
        else
            if objectiveGroup.Objectives then
                for _, v in objectiveGroup.Objectives do
                    if v.Active then
                        return
                    end
                end
            end
        end

        objectiveGroup.Active = false
        objectiveGroup.OnComplete()
    end

    objectiveGroup.AddObjective = function(self, objective)
        table.insert(self.Objectives, objective)
        objective:AddResultCallback(OnResult)
    end

    objectiveGroup.RemoveObjective = function(self, objective)
        table.removeByValue(self.Objectives, objective)
    end

    return objectiveGroup
end

--- Adds a kill objective
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to kill
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | FlashVisible          | Flag to give a short visibility burst
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Kill(Type, Complete, Title, Description, Target)
    Target.killed = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon('kill')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    -- Call ManualResult
    objective.ManualResult = function(self, result)
        objective.Active = false
        objective:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, objective.Tag)
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        Target.killed = Target.killed + 1

        local progress = string.format('(%s/%s)', Target.killed, Target.total)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
        objective:OnProgress(Target.killed, Target.total)

        if Target.killed == Target.total then
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
            objective.Active = false
            objective:OnResult(true, unit)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, (Target.MarkUnits == nil) or Target.MarkUnits)
        CreateTriggers(newUnit, objective, true) -- Reclaiming is same as killing for our purposes
    end

    for _, unit in Target.Units do
        if not unit.Dead then
            -- Mark the units unless MarkUnits == false
            if Target.MarkUnits == nil or Target.MarkUnits then
                local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                local arrow = ObjectiveArrow {AttachTo = unit}
            end
            if Target.FlashVisible then
                FlashViz(unit)
            end
            CreateTriggers(unit, objective, true) -- Reclaiming is same as killing for our purposes
        else
            objective.OnUnitKilled(unit)
        end
    end

    local progress = string.format('(%s/%s)', Target.killed, Target.total)
    UpdateObjective(Title, 'Progress', progress, objective.Tag)

    return objective
end

--- Adds a capture objective
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to capture
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | FlashVisible          | Flag to give a short visibility burst
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Capture(Type, Complete, Title, Description, Target)
    Target.captured = 0
    Target.total = table.getn(Target.Units)
    local required = Target.NumRequired or Target.total
    local returnUnits = {}

    local image = GetActionIcon('capture')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    objective.OnUnitCaptured = function(unit, captor)
        table.insert(returnUnits, unit)
        if not objective.Active then
            return
        end

        Target.captured = Target.captured + 1
        local progress = string.format('(%s/%s)', Target.captured, required)
        objective:OnProgress(Target.captured, required)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
        if Target.captured >= required then
            objective.Active = false
            objective:OnResult(true, returnUnits)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        Target.total = Target.total - 1
        if Target.total < required then
            objective.Active = false
            objective:OnResult(false)
            UpdateObjective(Title, 'complete', 'failed', objective.Tag)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, (Target.MarkUnits == nil) or Target.MarkUnits)
        CreateTriggers(newUnit, objective, true) -- Reclaiming is same as killing for our purposes
    end

    for _, unit in Target.Units do
        if not unit.Dead then
            -- Mark the units unless MarkUnits == false
            if Target.MarkUnits == nil or Target.MarkUnits then
                local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                local arrow = ObjectiveArrow {AttachTo = unit}
            end

            CreateTriggers(unit, objective, true) -- Reclaiming is same as killing for our purposes

            if Target.FlashVisible then
                FlashViz(unit)
            end
        else
            objective.OnUnitKilled(unit)
        end
    end

    local progress = string.format('(%s/%s)', Target.captured, required)
    UpdateObjective(Title, 'Progress', progress, objective.Tag)

    return objective
end

--- Adds a kill or capture objective
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to kill or capture
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | FlashVisible          | Flag to give a short visibility burst
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function KillOrCapture(Type, Complete, Title, Description, Target)
    local KilledOrCaptured = 0
    local Total = table.getn(Target.Units)
    local PercentRequired = Target.PercentRequired or 100
    local NumRequired = math.ceil(Total * (PercentRequired / 100))

    local image = GetActionIcon('KillOrCapture')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    objective.UpdateProgress = function()
        local progress
        if Target.PercentProgress then
            progress = string.format('(%s%%/%s%%)', math.floor(((Total - (Total - KilledOrCaptured)) / Total) * 100), PercentRequired)
        elseif Target.ShowProgress == nil or Target.ShowProgress then
            progress = string.format('(%s/%s)', KilledOrCaptured, NumRequired)
        end
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
    end

    -- Keep track of captured units so subsequent kills dont get counted
    local captured = {}

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        for _, v in captured do
            if v == unit then
                -- Ignore units already captured
                return
            end
        end

        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, NumRequired)
        objective:UpdateProgress()
        if KilledOrCaptured == NumRequired then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitCaptured = function(unit)
        if not objective.Active then
            return
        end
        table.insert(captured, unit)
        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, NumRequired)
        objective:UpdateProgress()
        if KilledOrCaptured == NumRequired then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitReclaimed = function(unit)
        if not objective.Active then
            return
        end

        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, NumRequired)
        objective:UpdateProgress()
        if KilledOrCaptured == NumRequired then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        for _, cUnit in captured do
            if cUnit == unit then
                table.insert(captured, newUnit)
                break
            end
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, (Target.MarkUnits == nil) or Target.MarkUnits)
        CreateTriggers(newUnit, objective)
    end

    for _, unit in Target.Units do
        if not unit.Dead then
            -- Mark the units unless MarkUnits == false
            if Target.MarkUnits == nil or Target.MarkUnits then
                local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                local arrow = ObjectiveArrow {AttachTo = unit}
            end

            if Target.FlashVisible then
                FlashViz(unit)
            end

            CreateTriggers(unit, objective)
        else
            objective.OnUnitKilled(unit)
        end
    end
    objective:UpdateProgress()

    return objective
end

--- Adds a reclaim objective for units
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to reclaim
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | FlashVisible          | Flag to give a short visibility burst
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Reclaim(Type, Complete, Title, Description, Target)
    Target.reclaimed = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon("reclaim")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    objective.OnUnitReclaimed  = function(unit)
        if not objective.Active then
            return
        end

        Target.reclaimed = Target.reclaimed + 1
        local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
        objective:OnProgress(Target.reclaimed, Target.total)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
        if Target.reclaimed == Target.total then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        objective.Active = false
        objective:OnResult(false)
        UpdateObjective(Title, 'complete', 'failed', objective.Tag)
    end

    -- If the unit is captured it can still be reclaimed to complete the
    -- objective, so track the new unit created on a capture.
    objective.OnUnitCaptured = function(newUnit, captor)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, nil, newUnit, true)
        CreateTriggers(newUnit, objective)
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, true)
        CreateTriggers(newUnit, objective)
    end

    for _, unit in Target.Units do
        local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
        local arrow = ObjectiveArrow {AttachTo = unit}
        CreateTriggers(unit, objective)
    end

    local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
    UpdateObjective(Title, 'Progress', progress, objective.Tag)

    return objective
end

--- Adds a reclaim objective for props
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Wrecks                | Table of props to reclaim
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
function ReclaimProp(Type, Complete, Title, Description, Target)
    Target.reclaimed = 0
    Target.total = table.getn(Target.Wrecks)

    local image = GetActionIcon("reclaim")
    local objective = AddObjective(Type, Complete, Title, Description, image)

    -- Call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    local function OnPropKilled(unit)
        objective.Active = false
        objective:OnResult(false)
        UpdateObjective(Title, 'complete', 'failed', objective.Tag)
    end

    local function OnPropReclaimed(unit)
        if not objective.Active then
            return
        end

        Target.reclaimed = Target.reclaimed + 1
        local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
        objective:OnProgress(Target.reclaimed, Target.total)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
        if Target.reclaimed == Target.total then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    for _, wreck in Target.Wrecks do
        -- Mark the units if MarkUnits == true
        if Target.MarkUnits then
            local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
            local arrow = ObjectiveArrow {AttachTo = unit}
        end
        Triggers.CreatePropReclaimedTrigger(OnPropReclaimed, wreck)
        Triggers.CreatePropKilledTrigger(OnPropKilled, wreck)
    end

    local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
    UpdateObjective(Title, 'Progress', progress, objective.Tag)

    return objective
end

--- Adds a locate objective, instructing the player to scout and trace down the units
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to reclaim
--- | Wrecks                | Table of props to reclaim
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Locate(Type, Complete, Title, Description, Target)
    Target.located = 0
    Target.total = table.getn(Target.Units)
    local isLocated = {}

    local image = GetActionIcon("locate")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.OnUnitLocated = function(unit)
        if isLocated[unit] or not objective.Active then
            return
        end
        Target.located = Target.located + 1
        isLocated[unit] = true
        local progress = string.format('(%s/%s)', Target.located, Target.total)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
        objective:OnProgress(Target.located, Target.total)
        if Target.located == Target.total then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective(Title, 'complete', "complete", objective.Tag)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if isLocated[unit] or not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, false)
        isLocated[newUnit] = CreateIntelTriggers(newUnit, objective, isLocated[unit])
    end

    for _, unit in Target.Units do
        CreateIntelTriggers(unit, objective)
    end

    local progress = string.format('(%s/%s)', Target.located, Target.total)
    UpdateObjective(Title, 'Progress', progress, objective.Tag)

    return objective
end

--- Adds an objective to have a specific set of units in an area
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to reclaim
--- | Area                  | String reference to an area
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function SpecificUnitsInArea(Type, Complete, Title, Description, Target)
    local image = GetActionIcon('Move')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local total = table.getn(Target.Units)
    local numRequired = Target.NumRequired or total
    Target.Count = 0

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    local function WatchArea(units, rect)
        while objective.Active do
            local cnt = 0
            for _, unit in units do
                if not unit.Dead then
                    if ScenarioUtils.InRect(unit:GetPosition(), rect) then
                        cnt = cnt + 1
                    end
                end
            end

            if cnt ~= Target.Count then
                Target.Count = cnt
                local progress = string.format('(%s/%s)', Target.Count, numRequired)
                objective:OnProgress(Target.Count, numRequired)
                if Target.ShowProgress then
                    UpdateObjective(Title, 'Progress', progress, objective.Tag)
                end
            end

            if cnt >= numRequired then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(5)
        end
    end

    local rect = ScenarioUtils.AreaToRect(Target.Area)
    local w = rect.x1 - rect.x0
    local h = rect.y1 - rect.y0
    local x = rect.x0 + (w / 2.0)
    local z = rect.y0 + (h / 2.0)

    if Target.MarkArea then
        objective.Decals[Target.Area] = CreateObjectiveDecal(x, z, w, h)
    end

    local watchThread = ForkThread(WatchArea, Target.Units, rect)

    objective.OnUnitKilled = function(unit)
        total = total - 1
        if objective.Active and total < numRequired then
            objective.Active = false
            objective:OnResult(false)
            UpdateObjective(Title, 'complete', 'failed', objective.Tag)
            KillThread(watchThread)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, Target.MarkUnits)
        CreateTriggers(newUnit, objective, true)
    end

    for _, unit in Target.Units do
        CreateTriggers(unit, objective, true)
    end

    if Target.ShowProgress then
        local progress = string.format('(%s/%s)', Target.Count, numRequired)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
    end

    return objective
end

--- Adds an objective to have a specific set of categories in an area
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to reclaim
--- | Requirements          | Table of requirements, see the 'Requirements data' table
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | MarkArea              | Flag to mark the areas that need to match the requirements using a decal
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
--- | ShowFaction           | ???
---
--- | Requirements data     | description   |
--- | --------------------- | ------------- |
--- | Area                  | String reference to an area
--- | Category              | Category of units that add to the count
--- | ArmyIndex             | Army of units that add to the count, can also be a table to support multiple armies
--- | CompareOp             | Compare operator to add flexibility: '<=', '>=', '<', '>', or '=='
--- | Value                 | Second argument to the compare operator (where the first is the number of units with the matching categories in the area)
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Action string             # Action icon to use, see `GetActionIcon`
---@param Target table              # Objective data, see the description
---@return Objective
function CategoriesInArea(Type, Complete, Title, Description, Action, Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local lastReqsMet = 0

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    local function WatchArea(requirements)
        local totalReqs = table.getn(requirements)
        while objective.Active do
            local reqsMet = 0

            for i, requirement in requirements do
                local units = GetUnitsInRect(requirement.Rect)
                local cnt = 0
                local ArmiesList = CreateArmiesList(requirement.Armies)
                if units then
                    for _, unit in units do
                        if not unit.Dead and not unit:IsBeingBuilt() then
                            if not (requirement.ArmyIndex or requirement.Armies) or (requirement.ArmyIndex == unit.Army) or ArmiesList[unit.Army] then
                                if EntityCategoryContains(requirement.Category, unit) then
                                    if not unit.Marked and objective.MarkUnits then
                                        unit.Marked = true
                                        local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                                        local arrow = ObjectiveArrow {AttachTo = unit}
                                        objective:AddUnitTarget(unit)
                                    end
                                    cnt = cnt + 1
                                end
                            end
                        end
                    end
                end
                if requirement.CompareFunc(cnt, requirement.Value) then
                    reqsMet = reqsMet +1
                end
            end

            if lastReqsMet ~= reqsMet then
                local progress = string.format('(%s/%s)', reqsMet, totalReqs)
                UpdateObjective(Title, 'Progress', progress, objective.Tag)
                objective:OnProgress(reqsMet, totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(10)
        end
    end

    for _, requirement in Target.Requirements do
        local rect = ScenarioUtils.AreaToRect(requirement.Area)

        local w = rect.x1 - rect.x0
        local h = rect.y1 - rect.y0
        local x = rect.x0 + (w / 2.0)
        local z = rect.y0 + (h / 2.0)

        if Target.MarkArea and not objective.Decals[requirement.Area] then
            local decal = CreateObjectiveDecal(x, z, w, h)
            objective.Decals[requirement.Area] = decal
        elseif Target.FlashVisible then
            FlashViz(requirement.Area)
        end

        if Target.MarkUnits then
            objective.MarkUnits = true
        end

        local reqRef = requirement
        reqRef.Rect = rect
        reqRef.CompareFunc = GetCompareFunc(requirement.CompareOp)
    end

    UpdateObjective(Title, 'Progress', string.format('(0/%d)', table.getsize(Target.Requirements)), objective.Tag)
    ForkThread(WatchArea, Target.Requirements)

    return objective
end

function CreateArmiesList(armies)
    if not armies then
        return {}
    end

    local armiesList = {}
    for _, armyName in armies do
        if type(armyName) ~= 'string' then
            error('SimObjectives error: Armies in requirements need to be of type string, provided type: ' .. type(armyName))
        end
        if armyName == 'HumanPlayers' then
            local tblArmy = ListArmies()
            for iArmy, strArmy in pairs(tblArmy) do
                if ScenarioInfo.ArmySetup[strArmy].Human then
                    armiesList[ScenarioInfo.ArmySetup[strArmy].ArmyIndex] = true
                end
            end
        elseif ScenarioInfo.ArmySetup[armyName] then
            armiesList[ScenarioInfo.ArmySetup[armyName].ArmyIndex] = true
        else
            error('SimObjectives error: Army doesnt exist: ' .. armyName)
        end
    end

    return armiesList
end

--- Adds an army stat objective, used to compare number of total units, resources, etc
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Army                  | Army to compare with
--- | StatName              | Statistic of army to compare with, see the alias `ArmyStatistic`
--- | CompareOp             | Compare operator, one of the following: '<=', '>=', '<', '>', or '=='. Be careful with '==' as the check interval is only two times a second
--- | Value                 | Second argument to the compare operator (where the first is the number of value of the army statistics)
--- | Category              | Optional category argument when comparing unit statistics
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function ArmyStatCompare(Type, Complete, Title, Description, Action, Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local armyBrainsList = MakeListFromTarget(Target)

    local function WatchStat(statName, aibrains, compareFunc, value, category)
        local oldVal

        while objective.Active do
            local result = false
            local testVal = 0

            for brain, _ in aibrains do
                if category then
                    testVal = testVal + brain:GetBlueprintStat(statName, category)
                else
                    testVal = testVal + brain:GetArmyStat(statName, value).Value
                end
            end

            if Target.ShowProgress then
                if testVal ~= oldVal then
                    local progress = string.format('(%s/%s)', testVal, value)
                    UpdateObjective(Title, 'Progress', progress, objective.Tag)
                    oldVal = testVal
                end
            end

            result = compareFunc(testVal, value)
            if result then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread(WatchStat, Target.StatName, armyBrainsList, op, Target.Value, Target.Category)
    end

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    return objective
end

function MakeListFromTarget(Target)
    local resultList = {}
    if Target.Army then
        resultList[GetArmyBrain(Target.Army)] = true
    end

    if Target.Armies then
        local tblArmy = ListArmies()
        for _, armyName in Target.Armies do
            if armyName == "HumanPlayers" then
                for iArmy, strArmy in pairs(tblArmy) do
                    if ScenarioInfo.ArmySetup[strArmy].Human then
                        resultList[GetArmyBrain(iArmy)] = true
                    end
                end
            else
                for iArmy, strArmy in pairs(tblArmy) do
                    if strArmy == armyName then
                        resultList[GetArmyBrain(iArmy)] = true
                    end
                end
            end

        end
    end
    return resultList
end

--- Adds an unit stat objective, used to compare number statistics of a given unit
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Unit                  | Unit to compare statistics with
--- | StatName              | Statistic of the unit to compare with, uses `unit.GetStat` to retrieve the statistic
--- | CompareOp             | Compare operator, one of the following: '<=', '>=', '<', '>', or '=='. Be careful with '==' as the check interval is only two times a second
--- | Value                 | Second argument to the compare operator (where the first is the number of value of the army statistics)
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function UnitStatCompare(Type, Complete, Title, Description, Action, Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    local function WatchStat(statName, unit, compareFunc, value)
        while objective.Active do
            if compareFunc(unit:GetStat(statName, value).Value, value) then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread(WatchStat, Target.StatName, Target.Unit, op, Target.Value)
    end

    return objective
end

--- Adds an unit stat objective but only for the units that meet the categories set, used to compare number statistics of a given unit
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Arm,y                 | Army to search for units
--- | Category              | Optional category argument when comparing unit statistics
--- | StatName              | Statistic of the unit to compare with, uses `unit.GetStat` to retrieve the statistic
--- | CompareOp             | Compare operator, one of the following: '<=', '>=', '<', '>', or '=='. Be careful with '==' as the check interval is only two times a second
--- | Value                 | Second argument to the compare operator (where the first is the number of value of the army statistics)
--- | Hidden                | Flag to hide the objective from the UI
--- | ShowProgress          | Flag to update the description of the objective in the UI
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function CategoryStatCompare(Type, Complete, Title, Description, Action, Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local armyBrainsList = MakeListFromTarget(Target)

    local function WatchStat(statName, aibrains, category, compareFunc, value)
        while objective.Active do
            for brain, _ in aibrains do
                local unitsInCategory = brain:GetListOfUnits(category, false)
                if unitsInCategory then
                    for _, unit in unitsInCategory do
                        if compareFunc(unit:GetStat(statName, value).Value, value) then
                            objective.Active = false
                            objective:OnResult(true)
                            UpdateObjective(Title, 'complete', 'complete', objective.Tag)
                            return
                        end
                    end
                end
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread(WatchStat, Target.StatName, armyBrainsList, Target.Category, op, Target.Value)
    end

    return objective
end

--- Adds a protect objective to protect a table of units. Completes when the timer finishes
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units to reclaim
--- | NumRequired           | Number of units required for the objective to pass
--- | MarkUnits             | Flag to to mark the units with an objective arrow the units are marked with an objective arrow
--- | Hidden                | Flag to hide the objective from the UI
--- | FlashVisible          | Flag to give a short visibility burst
--- | ShowProgress          | Flag to update the description of the objective in the UI
--- | Timer                 | Time to indicate how long you need to protect the units
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Protect(Type, Complete, Title, Description, Target)

    local image = GetActionIcon("protect")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local total = table.getn(Target.Units)
    local max = total
    local numRequired = Target.NumRequired or total
    local timer = nil

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end

        total = total - 1
        objective:OnProgress(total, numRequired)

        if Target.ShowProgress then
            local progress = string.format('(%s/%s)', total, numRequired)
            UpdateObjective(Title, 'Progress', progress, objective.Tag)
        elseif Target.PercentProgress then
            local progress = string.format('(%s%%)', math.ceil(total / max * 100))
            UpdateObjective(Title, 'Progress', progress, objective.Tag)
        end

        if objective.Active and total < numRequired then
            objective.Active = false
            objective:OnResult(false, unit)
            UpdateObjective(Title, 'complete', 'failed', objective.Tag)
            Sync.ObjectiveTimer = 0
            if timer then
                KillThread(timer)
            end
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, false)
        CreateTriggers(newUnit, objective, true)
    end

    local function onTick(newTime)
        UpdateObjective(Title, 'timer', {Time = newTime}, objective.Tag)
    end

    local function OnExpired()
        if objective.Active then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective(Title, 'complete', 'complete', objective.Tag)
        end
        Sync.ObjectiveTimer = 0
    end

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    if Target.Timer then
        timer = import("/lua/scenariotriggers.lua").CreateTimerTrigger(
            OnExpired,
            Target.Timer,
            true,
            true,
            onTick
       )
    end

    for _, unit in Target.Units do
        if not unit.Dead then
            CreateTriggers(unit, objective, true)
        else
            objective.OnUnitKilled(unit)
        end
    end

    if Target.ShowProgress then
        local progress = string.format('(%s/%s)', total, numRequired)
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
    elseif Target.PercentProgress then
        local progress = string.format('(%s%%)', math.ceil(total / max * 100))
        UpdateObjective(Title, 'Progress', progress, objective.Tag)
    end

    return objective
end

--- Adds a timer objective
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | ShowProgress          | Flag to update the description of the objective in the UI
--- | Timer                 | Time to indicate how long you need to protect the units
--- | ExpireResult          | Either 'complete' or 'failed'
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Timer(Type, Complete, Title, Description, Target)
    local image = GetActionIcon("timer")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local timer = nil

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
        Sync.ObjectiveTimer = 0
        KillThread(timer)
    end

    local function onTick(newTime)
        UpdateObjective(Title, 'timer', {Time = newTime}, objective.Tag)
    end

    local function OnExpired()
        objective.Active = false
        if Target.ExpireResult == 'complete' then
            objective:OnResult(true)
            UpdateObjective(Title, 'complete', 'complete', objective.Tag)
        else
            objective:OnResult(false)
            UpdateObjective(Title, 'complete', 'failed', objective.Tag)
        end
        Sync.ObjectiveTimer = 0
    end

    timer = import("/lua/scenariotriggers.lua").CreateTimerTrigger(
        OnExpired,
        Target.Timer,
        false,
        true,
        onTick
    )

    return objective
end

--- Adds an unknown objective
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@return Objective
function Unknown(Type, Complete, Title, Description)
    local objective = AddObjective(Type, Complete, Title, Description)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, self.Tag)
    end

    return objective
end

--- Adds a basic objective that allows you to quickly mark units and areas
--- | Objective data        | Description   |
--- | --------------------- | ------------- |
--- | Units                 | Table of units 
--- | MarkUnits             | Flag to mark the units with an objective arrow
--- | Area                  | String reference of an area
--- | MarkArea              | Flag to mark the area with an objective decal
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@param Target table              # Objective data, see the description
---@return Objective
function Basic(Type, Complete, Title, Description, Image, Target)
    local objective = AddObjective(Type, Complete, Title, Description, Image, Target)

    objective.ManualResult = function(self, result)
        objective.Active = false
        objective:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective(Title, 'complete', resultStr, objective.Tag)
    end

    objective.AddBasicUnitTarget = function(self, unit)
        objective:AddUnitTarget(unit)
        local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
        local arrow = ObjectiveArrow {AttachTo = unit}
        table.insert(objective.UnitMarkers, arrow)
    end

    objective.AddTarget = function(self, target)
        if target.Area then
            local rect = ScenarioUtils.AreaToRect(target.Area)

            local w = rect.x1 - rect.x0
            local h = rect.y1 - rect.y0
            local x = rect.x0 + (w / 2.0)
            local z = rect.y0 + (h / 2.0)

            if target.MarkArea then
                objective.Decals[target.Area] = CreateObjectiveDecal(x, z, w, h)
            end
            if Target.FlashVisible then
                FlashViz(target.Area)
            end
        end
        if target.Areas and target.MarkArea then
            for _, v in target.Areas do
                local rect = ScenarioUtils.AreaToRect(v)

                local w = rect.x1 - rect.x0
                local h = rect.y1 - rect.y0
                local x = rect.x0 + (w / 2.0)
                local z = rect.y0 + (h / 2.0)

                objective.Decals[v] = CreateObjectiveDecal(x, z, w, h)
                if Target.FlashVisible then
                    FlashViz(v)
                end
            end
        end
        if target.Units then
            if target.MarkUnits then
                for _, unit in target.Units do
                    if not unit.Dead then
                        local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
                        local arrow = ObjectiveArrow {AttachTo = unit}
                        table.insert(objective.UnitMarkers, arrow)
                        if target.AlwaysVisible then
                            SetupVizMarker(self, unit)
                        end
                        if Target.FlashVisible then
                            FlashViz(unit)
                        end
                    end
                end
            end
        end
    end

    if Target then
        objective:AddTarget(Target)
    end

    return objective
end


-- Adds and tracks an objective, should not be used directly
---@param Type ObjectiveType
---@param Complete Objective
---@param Title string
---@param Description string
---@param ActionImage string
---@param Target table
---@param IsLoading boolean
---@param loadedTag string
---@return Objective
function AddObjective(Type,         -- 'primary', 'bonus', etc
                      Complete,     -- 'complete', 'incomplete'
                      Title,        -- e.g. "Destroy Radar Stations"
                      Description,  -- e.g. "A reason why you need to destroy the radar stations"
                      ActionImage,        -- '/textures/ui/common/missions/mission1.dds'
                      Target,       -- Can be one of:
                                    -- Units = {unit1, unit2, ...}
                                    -- Areas = {'areaName1', 'areaName2', ...}
                      IsLoading,    -- Are we loading a saved game?
                      loadedTag     -- If IsLoading is specified, whats the tag?
    )

    if not Sync.ObjectivesTable then
        Sync.ObjectivesTable = {}
    end

    local tag

    if IsLoading then
        tag = loadedTag
    else
        tag = 'Objective' .. objNum
        objNum = objNum + 1
        table.insert(SavedList, {AddArgs = {Type, Complete, Title, Description, ActionImage, Target, true, tag, n=8}, Tag=tag})
    end

    ---@type Objective
    local objective = {
        -- Used to synchronize sim objectives with user side objectives
        Tag = tag,

        -- Whether the objective is in progress or not and does not indicate success or failure.
        Active = true,

        -- success or failure.
        Complete = false,

        -- Hide the objective from the screen
        Hidden = Target.Hidden,

        -- Decal table, keyd by area names
        Decals = {},

        -- Unit arrow table
        UnitMarkers = {},

        -- Visibility markers that we manage
        VizMarkers = {},

        -- Single decal
        Decal = false,

        -- Strategic icon overrides
        IconOverrides = {},

        -- For tracking targets
        NextTargetTag = 0,
        PositionUpdateThreads = {},

        Title = Title,
        Description = Description,

        SimStartTime = GetGameTimeSeconds(),

        -- Called on success or failure
        ResultCallbacks = {},
        AddResultCallback = function(self, cb)
            table.insert(self.ResultCallbacks, cb)
        end,

        -- Some objective types can provide progress updates (not success/fail)
        ProgressCallbacks = {},
        AddProgressCallback = function(self, cb)
            table.insert(self.ProgressCallbacks, cb)
        end,

        -- Dont override these if you want notification. Call Add???Callback
        -- intead
        OnResult = function(self, success, data)
            self.Complete = success

            -- Destroy decals
            for _, v in self.Decals do v:Destroy() end

            -- Destroy unit marker things
            for _, v in self.UnitMarkers do
                v:Destroy()
            end

            -- Revert strategic icons
            for _, v in self.IconOverrides do
                if not v:BeenDestroyed() then
                    v:SetStrategicUnderlay("")
                end
            end

            -- Destroy visibility markers
            for _, v in self.VizMarkers do
                v:Destroy()
            end

            if self.PositionUpdateThreads then
                for k, v in self.PositionUpdateThreads do
                    if v then
                        KillThread(self.PositionUpdateThreads[k])
                        self.PositionUpdateThreads[k] = false
                    end
                end
            end

            for _, v in self.ResultCallbacks do v(success, data) end
        end,

        OnProgress = function(self, current, total)
            for _, v in self.ProgressCallbacks do v(current, total) end
        end,

        -- Call this to manually fail the objective
        Fail = function(self)
            self.Active = false
            self:OnResult(false)
            UpdateObjective(self.Title, 'complete', 'failed', self.Tag)
        end,

        AddUnitTarget = function(self, unit) end, -- defined below
        AddAreaTarget = function(self, area) end, -- defined below
    }

    -- Takes a unit that is an objective target and uses its recon detect
    -- event to notify the objectives that we have a blip for the unit.
    local function SetupNotify(obj, unit, targetTag)
        -- Add a detectedBy callback to notify the user layer when our recon
        -- on the target comes in and out.
        local detectedByCB = function(cbunit, armyindex)
            if not obj.Active then
                return
            end

            -- now if weve been detected by the focus army ...
            if armyindex == GetPlayerArmy() then
                -- get the blip that is associated with the unit
                local blip = cbunit:GetBlip(armyindex)

                -- Only provide the target position to the user layer if
                -- the blip IsSeenEver() (i.e. has been identified).
                obj.PositionUpdateThreads[targetTag] = ForkThread(
                    function()
                        while obj.Active do
                            WaitTicks(10)
                            if blip:BeenDestroyed() then
                                return
                            end

                            if blip:IsSeenEver(armyindex) then
                                UpdateObjective(Title,
                                                'Target',
                                                {
                                                    Type = 'Position',
                                                    Value = blip:GetPosition(),
                                                    BlueprintId = blip:GetBlueprint().BlueprintId,
                                                    TargetTag=targetTag
                                                },
                                                obj.Tag)

                                -- If it's not mobile we can exit the thread since
                                -- the blip won't move.
                                if not unit.Dead and not unit:BeenDestroyed() and not EntityCategoryContains(categories.MOBILE, unit) then
                                    return
                                end
                            end
                        end
                    end
               )

                local destroyCB = function(cbblip)
                    if not obj.Active then
                        return
                    end

                    if obj.PositionUpdateThreads[targetTag] then
                        KillThread(obj.PositionUpdateThreads[targetTag])
                        obj.PositionUpdateThreads[targetTag] = false
                    end

                    -- When the blip is destroyed, tell objectives we dont
                    -- have a blip anymore. This doesnt necessarily mean the
                    -- unit is killed, we simply lost the blip.
                    UpdateObjective(Title,
                                    'Target',
                                    {
                                        Type = 'Position',
                                        Value = nil,
                                        BlueprintId = nil,
                                        TargetTag=targetTag,
                                    },
                                    obj.Tag)
                end
                -- When the blip is destroyed, have it call this callback
                -- function (defined above)
                blip:AddDestroyHook(destroyCB)
            end
        end
        -- When the unit is detected by an army, have it call this callback
        -- function (defined above)
        unit:AddDetectedByHook(detectedByCB)

        -- See if we can detect the unit right now
        local blip = unit:GetBlip(GetPlayerArmy())
        if blip then
            detectedByCB(unit, GetPlayerArmy())
        end
    end

    -- Take an objective target unit that is owned by the focus army
    -- Info passed to user layer to handle zoom to button and chiclet image
    function SetupFocusNotify(obj, unit, targetTag)
        obj.PositionUpdateThreads[targetTag] = ForkThread(
            function()
                while obj.Active do
                    if unit:BeenDestroyed() then
                        return
                    end

                    UpdateObjective(Title, 'Target',
                                    {
                                        Type = 'Position',
                                        Value = unit:GetPosition(),
                                        BlueprintId = unit:GetBlueprint().BlueprintId,
                                        TargetTag=targetTag
                                    },
                                    obj.Tag)

                    -- If it's not mobile we can exit the thread since the unit won't move.
                    if not unit.Dead and not unit:BeenDestroyed() and not EntityCategoryContains(categories.MOBILE, unit) then
                        return
                    end

                    WaitTicks(10)
                end
            end
       )

        local destroyCB = function()
            if not obj.Active then
                return
            end

            if obj.PositionUpdateThreads[targetTag] then
                KillThread(obj.PositionUpdateThreads[targetTag])
                obj.PositionUpdateThreads[targetTag] = false
            end

            -- when the blip is destroyed, tell objectives we dont
            -- have a blip anymore. This doesnt necessarily mean the
            -- unit is killed, we simply lost the blip.
            UpdateObjective(Title, 'Target',
                            {
                                Type = 'Position',
                                Value = nil,
                                BlueprintId = nil,
                                TargetTag=targetTag,
                            },
                            obj.Tag)
        end
        -- When the unit is destroyed have it call this callback
        -- function (defined above)
        Triggers.CreateUnitDeathTrigger(destroyCB, unit)
    end

    function SetupVizMarker(objective, object)
        if IsEntity(object) then
            local pos = object:GetPosition()
            local spec = {
                X = pos[1],
                Z = pos[2],
                Radius = 8,
                LifeTime = -1,
                Omni = false,
                Vision = true,
                Army = GetPlayerArmy(),
            }
            local vizmarker = VizMarker(spec)
            object.Trash:Add(vizmarker)
            vizmarker:AttachBoneTo(-1, object, -1)
        else
            local rect = ScenarioUtils.AreaToRect(Target.Area)
            local width = rect.x1 - rect.x0
            local height = rect.y1 - rect.y0
            local spec = {
                X = rect.x0 + width/2,
                Z = rect.y0 + height/2,
                Radius = math.max(width, height),
                LifeTime = -1,
                Omni = false,
                Vision = true,
                Army = GetPlayerArmy(),
            }
            local vizmarker = VizMarker(spec)
            table.insert(objective.VizMarkers, vizmarker);
        end
    end

    function FlashViz (object)
        if IsEntity(object) then
            local pos = object:GetPosition()
            local spec = {
                X = pos[1],
                Z = pos[2],
                Radius = 2,
                LifeTime = 1.00,
                Omni = false,
                Vision = true,
                Radar = false,
                Army = GetPlayerArmy(),
            }
            local vizmarker = VizMarker(spec)
            object.Trash:Add(vizmarker)
            vizmarker:AttachBoneTo(-1, object, -1)
        else
            local rect = ScenarioUtils.AreaToRect(object)
            local width = rect.x1 - rect.x0
            local height = rect.y1 - rect.y0
            local spec = {
                X = rect.x0 + width/2,
                Z = rect.y0 + height/2,
                Radius = math.max(width, height),
                LifeTime = 0.01,
                Omni = false,
                Vision = true,
                Radar = false,
                Army = GetPlayerArmy(),
            }
            local vizmarker = VizMarker(spec)
        end
    end

    local userTargets = {}
    if Target.ShowFaction then
        if Target.ShowFaction == 'Cybran' then
            Target.Image = '/textures/ui/common/faction_icon-lg/cybran_ico.dds'
        elseif Target.ShowFaction == 'Aeon' then
            Target.Image = '/textures/ui/common/faction_icon-lg/aeon_ico.dds'
        elseif Target.ShowFaction == 'UEF' then
            Target.Image = '/textures/ui/common/faction_icon-lg/uef_ico.dds'
        elseif Target.ShowFaction == 'Seraphim' then
            Target.Image = '/textures/ui/common/faction_icon-lg/seraphim_ico.dds'
        end
    end

    if Target and Target.Requirements then
        for _, req in Target.Requirements do
            if req.Area then
                table.insert(userTargets, {Type = 'Area', Value = ScenarioUtils.AreaToRect(req.Area)})
            end
        end
    elseif Target and Target.Timer then
        userTargets = {Type = 'Timer', Time = Target.Timer}
    end

    if Target.Category then
        local bps = EntityCategoryGetUnitList(Target.Category)
        if not table.empty(bps) then
            table.insert(userTargets, {Type = 'Blueprint', BlueprintId = bps[1]})
        end
    end

    local userObjectiveData = {
        tag = tag,
        type = Type,
        complete = Complete,
        hidden = Target.Hidden,
        title = Title,
        description = Description,
        actionImage = ActionImage,
        targetImage = Target.Image,
        progress = "",
        targets = userTargets,
        loading = IsLoading,
        StartTime = objective.SimStartTime,
    }

    Sync.ObjectivesTable[tag] = userObjectiveData

    objective.AddUnitTarget = function(self, unit)
        self.NextTargetTag = self.NextTargetTag + 1
        if unit.Army == GetPlayerArmy() then
            SetupFocusNotify(self, unit, self.NextTargetTag)
        else
            SetupNotify(self, unit, self.NextTargetTag)
        end
        if Target.AlwaysVisible then
            SetupVizMarker(self, unit)
        end

        -- Mark the units unless MarkUnits == false
        if Target.MarkUnits == nil or Target.MarkUnits then
            if Type == 'primary' then
                unit:SetStrategicUnderlay('icon_objective_primary')
            elseif Type == 'secondary' then
                unit:SetStrategicUnderlay('icon_objective_secondary')
            elseif Type == 'bonus' then
                unit:SetStrategicUnderlay('icon_objective_bonus')
            end
            table.insert(self.IconOverrides, unit)
        end
    end

    objective.AddAreaTarget = function(self, area)
        self.NextTargetTag = self.NextTargetTag + 1
        UpdateObjective(Title,
                        'Target',
                        {
                            Type = 'Area',
                            Value = ScenarioUtils.AreaToRect(area),
                            TargetTag=self.NextTargetTag
                        },
                        self.Tag)

        if Target.AlwaysVisible then
            SetupVizMarker(self, area)
        end
    end

    if Target then
        if Target.Units then
            for _, v in Target.Units do
                if v and v.IsDead and not v.Dead then
                    objective:AddUnitTarget(v)
                end
            end
        end

        if Target.Unit and not Target.Unit.Dead then
            objective:AddUnitTarget(Target.Unit)
        end

        if Target.Areas then
            for _, v in Target.Areas do
                objective:AddAreaTarget(v)
            end
        end

        if Target.Area then
            objective:AddAreaTarget(Target.Area)
        end
    end

    return objective
end

function DeleteObjective(Objective, IsLoading)
    local userObjectiveUpdate = {
        tag = Objective.Tag,
        updateField = 'delete',
    }
    if not IsLoading then
        table.insert(SavedList, {DeleteArgs = userObjectiveUpdate})
    end
    table.insert(Sync.ObjectivesUpdateTable, userObjectiveUpdate)
end

-- Update legacy style objective using correct syntax
function UpdateBasicObjective(Objective, UpdateField, NewData)
    UpdateObjective(Objective.Title, UpdateField, NewData, Objective.Tag)
end

-- Updates an objective, referencing it by objective title
function UpdateObjective(Title, UpdateField, NewData, objTag, IsLoading, InTime)

    if objTag == 'Invalid' then
        return
    end

    if not Sync.ObjectivesUpdateTable then
        Sync.ObjectivesUpdateTable = {}
    end

    if type(objTag) ~= 'string' then
        error('SimObjectives error: Invalid type for objTag in UpdateObjective.  String expected but got '
        .. type(objTag), 2)
    end
    if type(UpdateField) ~= 'string' then
        error('SimObjectives error: Invalid type for UpdateField in UpdateObjective. String expected but got ' .. type(UpdateField), 2)
    end

    if not IsLoading then
        table.insert(SavedList, {UpdateArgs = {Title, UpdateField, NewData, objTag, true, GetGameTimeSeconds(), n=6}, Tag=objTag})
    end

    -- All fields are stored with lowercase names
    UpdateField = string.lower(UpdateField)
    if not (
        (UpdateField == 'type') or
        (UpdateField == 'complete') or
        (UpdateField == 'title') or
        (UpdateField == 'description') or
        (UpdateField == 'image') or
        (UpdateField == 'progress') or
        (UpdateField == 'target') or
        (UpdateField == 'timer') or
        (UpdateField == 'delete')
        )
        then
        error('Unknown UpdateField: ' .. UpdateField .. '.  Cannot process UpdateObjective request.', 2)
    else
        local userObjectiveUpdate = {
            title = Title,
            updateField = UpdateField,
            updateData = NewData,
            tag = objTag,
            loading = IsLoading,
        }
        if UpdateField == 'complete' then
            userObjectiveUpdate['time'] = InTime or GetGameTimeSeconds()
        end
        table.insert(Sync.ObjectivesUpdateTable, userObjectiveUpdate)
    end
end

function GetCompareFunc(op)
    function gt(a, b) return a > b end
    function lt(a, b) return a < b end
    function gte(a, b) return a >= b end
    function lte(a, b) return a <= b end
    function eq(a, b) return a == b end

    if op == '<=' then return lte end
    if op == '>=' then return gte end
    if op == '<' then return lt end
    if op == '>' then return gt end
    if op == '==' then return eq end

    WARN("Unsupported CompareOp '", op, "'")
end

function GetActionIcon(actionString)
    local action = string.lower(actionString)
    if action == "kill"     then return "/game/orders/attack_btn_up.dds"        end
    if action == "capture"  then return "/game/orders/convert_btn_up.dds"       end
    if action == "build"    then return "/game/orders/production_btn_up.dds"    end
    if action == "protect"  then return "/game/orders/guard_btn_up.dds"         end
    if action == "timer"    then return "/game/orders/guard_btn_up.dds"         end
    if action == "move"     then return "/game/orders/move_btn_up.dds"          end
    if action == "reclaim"  then return "/game/orders/reclaim_btn_up.dds"       end
    if action == "repair"   then return "/game/orders/repair_btn_up.dds"        end
    if action == "locate"   then return "/game/orders/omni_btn_up.dds"          end
    if action == "group"    then return "/game/orders/move_btn_up.dds"          end
    if action == "killorcapture" then return "/game/orders/attack_capture_btn_up.dds" end

    return ""
end

function IsComplete(obj)
    if obj then
        if obj.Complete then
            return true
        end
    end

    return false
end

function OnPostLoad()
    for _, v in SavedList do
        if v.AddArgs then
            AddObjective(unpack(v.AddArgs))
        elseif v.UpdateArgs then
            UpdateObjective(unpack(v.UpdateArgs))
        elseif v.DeleteArgs then
            DeleteObjective(v.DeleteArgs, true)
        end
    end
end

function CreateObjectiveDecal(x, z, w, h)
    return CreateDecal(Vector(x, 0, z), 0, objectiveDecal, '', 'Water Albedo', w, h, DecalLOD, 0, 1, 0)
end

function OnUnitGivenBase(objective, target, unit, newUnit, markUnits)
    local index = -1
    if unit then
        for i, v in target.Units do
            if v == unit then
                index = i
                break
            end
        end
    end
    if index > 0 then
        table.remove(target.Units, index)
    end
    table.insert(target.Units, newUnit)
    BasicUnitTarget(objective, newUnit, markUnits)
end

function BasicUnitTarget(objective, unit, markUnits)
    objective:AddUnitTarget(unit)
    if markUnits then
        local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
        local arrow = ObjectiveArrow {AttachTo = unit}
        table.insert(objective.UnitMarkers, arrow)
    end
end

function CreateTriggers(unit, objective, useOnKilledWhenReclaimed)
    if objective.OnUnitGiven then
        Triggers.CreateUnitGivenTrigger(objective.OnUnitGiven, unit)
    end
    if objective.OnUnitCaptured then
        Triggers.CreateUnitCapturedTrigger(nil, objective.OnUnitCaptured, unit)
    end
    if objective.OnUnitKilled then
        Triggers.CreateUnitDeathTrigger(objective.OnUnitKilled, unit)
    end
    if objective.OnUnitReclaimed then
        Triggers.CreateUnitReclaimedTrigger(objective.OnUnitReclaimed, unit)
    end
    if useOnKilledWhenReclaimed then
        Triggers.CreateUnitReclaimedTrigger(objective.OnUnitKilled, unit)
    end
end

function CreateIntelTriggers(unit, objective, isAlreadyLocated)
    local IntelTrigger = import("/lua/scenariotriggers.lua").CreateArmyIntelTrigger
    if objective.OnUnitGiven then
        Triggers.CreateUnitGivenTrigger(objective.OnUnitGiven, unit)
    end
    if objective.OnUnitLocated then
        if isAlreadyLocated then
            return true
        else
            IntelTrigger(objective.OnUnitLocated,
                        GetArmyBrain(GetPlayerArmy()),
                        'LOSNow',
                        unit,
                        true,
                        categories.ALLUNITS,
                        true,
                        unit:GetAIBrain())
            return false
        end
    end
end
