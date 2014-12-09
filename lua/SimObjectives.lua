#****************************************************************************
#**
#**  File     :  /lua/SimObjectives.lua
#**
#**  Summary  : Sim side objectives
#**
#**  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
##
## SUPPORTED OBJECTIVE TYPES:
##      Kill
##      Capture
##      KillOrCapture
##      Reclaim
##      Locate
##      SpecificUnitsInArea
##      CategoriesInArea
##      ArmyStatCompare
##      UnitStatCompare
##      CategoryStatCompare
##      Protect
##      Timer
##      Unknown
##
##      Camera
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local Triggers = import('/lua/scenariotriggers.lua')
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker
local objNum = 0 # Used to create unique tags for objectives
local DecalLOD = 4000

local objectiveDecal = '/env/utility/decals/objective_debug_albedo.dds'
local SavedList = {}

#
# Camera objective by roates
# Creates markers that satisfy the objective when they are all inside of the camera viewport
#
# Camera( objectiveType, completeState, title, description, positionTable)
#
# objectiveType = 'primary' or 'bonus' etc...
# completeState = 'complete' or 'incomplete'
# title = title string table from map's string file
# description = description string table from map's string file
# positionTable = table of position tables where markers will be created. { {x1, y1, z1}, {x2, y2, z2} } format
#
function Camera(objectiveType, completeState, title, description, positionTable)
    local numMarkers = 0
    local curMarkers = 0

    local objective = AddObjective(objectiveType, completeState, title, description, nil, positionTable)

    local RemoveMarker = function(mark)
        mark:Destroy()
        curMarkers = curMarkers + 1

        UpdateObjective( title, 'Progress', '('..curMarkers..'/'..numMarkers..')', objective.Tag )
        objective:OnProgress(curMarkers, numMarkers)

        if curMarkers == numMarkers then
            --Win an Internet
            objective.Active = false
            UpdateObjective( title, 'complete', 'complete', objective.Tag )
            objective:OnResult(true)
        end
    end

    for i,v in positionTable do
        numMarkers = numMarkers + 1

        local newMark = import('/lua/simcameramarkers.lua').AddCameraMarker(v)
        newMark:AddCallback(RemoveMarker)
    end

    objective:OnProgress(curMarkers, numMarkers)
    UpdateObjective( title, 'Progress', '('..curMarkers..'/'..numMarkers..')', objective.Tag )

    return objective
end


#
# ControlGroup
#   Complete when specified units matching the target blueprint types are in
# a control group. We don't care exactly which units they are (pre-built or
# newly constructed), as long as the requirements are ment. We just check
# the area for what units are in control groups and look at the blueprints (and optionally
# match the army, use -1 for don't care).
#
# Target = {
#   Requirements = {
#       {  Category=<cat1>, CompareOp=<op>, Value=<x>, [ArmyIndex=<index>]},
#       {  Category=<cat2>, CompareOp=<op>, Value=<y>, [ArmyIndex=<index>] },
#       ...
#       {  Category=<cat3>, CompareOp=<op>, Value=<z>, [ArmyIndex=<index>] },
#   }
# }
#
# -- op is one of: '<=', '>=', '<', '>', or '=='
#
function ControlGroup(Type,Complete,Title,Description,Target)

    local image = GetActionIcon('group')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local lastReqsMet = -1

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function WatchGroups(requirements)
        local totalReqs = table.getn(requirements)
        while objective.Active do
            local reqsMet = 0

            for i,requirement in requirements do
                local units = ScenarioInfo.ControlGroupUnits
                local cnt = 0
                if units then
                    for k,unit in units do
                        if not requirement.ArmyIndex or (requirement.ArmyIndex == unit:GetArmy()) then
                            if EntityCategoryContains(requirement.Category, unit) then
                                if not unit.Marked and objective.MarkUnits then
                                    unit.Marked = true
                                    local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                                    local arrow = ObjectiveArrow { AttachTo = unit }
                                    objective:AddUnitTarget(unit)
                                end
                                cnt = cnt+1
                            end
                        end
                    end
                    #LOG('debug: ControlGroup: reqsmet '..reqsMet..'count '.. cnt )
                end
                if not requirement.CompareFunc then
                    requirement.CompareFunc = GetCompareFunc(requirement.CompareOp)
                end
                if requirement.CompareFunc(cnt,requirement.Value) then
                    reqsMet = reqsMet +1
                end
            end

            if lastReqsMet != reqsMet then
                local progress = string.format('(%s/%s)', reqsMet, totalReqs)
                UpdateObjective( Title, 'Progress', progress, objective.Tag )
                objective:OnProgress(reqsMet,totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective( Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(10)
        end
    end

    UpdateObjective( Title, 'Progress', '(0/0)', objective.Tag )
    ForkThread( WatchGroups, Target.Requirements )

    return objective
end




#
# CreateGroup
#
#   Takes list of objective tables which are produced by the objective creation
# functions such as Kill, Protect, Capture, etc.
#
#   UserCallback is executed when all objectives in the list are complete
#
function CreateGroup( name, userCallback, numRequired )
    LOG('Creating objective group ',name)
    local objectiveGroup =  {
        Name = name,
        Active = true,
        Objectives = {},
        NumRequired = numRequired,
        NumCompleted = 0,
        AddObjective = function(self,objective) end, # defined later
        RemoveObjective = function(self,objective) end, # defined later
        OnComplete = userCallback,
    }

    local function OnResult(result)
        if not objectiveGroup.Active then
            LOG('ObjectiveGroup ',objectiveGroup.Name,' is not active.')
            return
        end

        if result then
            objectiveGroup.NumCompleted = objectiveGroup.NumCompleted + 1
        end

        if objectiveGroup.NumRequired then
            LOG('ObjectiveGroup ',objectiveGroup.Name,' Progress ',objectiveGroup.NumRequired, '/',objectiveGroup.NumCompleted)
            if objectiveGroup.NumCompleted < objectiveGroup.NumRequired then
                return
            end
        else
            if objectiveGroup.Objectives then
                for k,v in objectiveGroup.Objectives do
                    if v.Active then
                        return
                    end
                end
            end
        end

        # Complete!
        objectiveGroup.Active = false
        objectiveGroup.OnComplete()
    end

    objectiveGroup.AddObjective = function(self,objective)
        table.insert(self.Objectives,objective)
        objective:AddResultCallback(OnResult)
    end

    objectiveGroup.RemoveObjective = function(self,objective)
        table.removeByValue(self.Objectives,objective)
    end

    return objectiveGroup
end

#
# Kill
#   Kill units
function Kill(Type,Complete,Title,Description,Target)
    Target.killed = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon('kill')
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    # call ManualResult
    objective.ManualResult = function(self, result)
        objective.Active = false
        objective:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, objective.Tag)
    end

    local function OnUnitKilled(unit)
        Target.killed = Target.killed + 1

        local progress = string.format('(%s/%s)', Target.killed, Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        objective:OnProgress(Target.killed,Target.total)

        if Target.killed == Target.total then
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
            objective.Active = false
            objective:OnResult(true, unit)
        end
    end

    for k,unit in Target.Units do
        if not unit:IsDead() then
            # Mark the units unless MarkUnits == false
            if ( Target.MarkUnits == nil ) or Target.MarkUnits then
                local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                local arrow = ObjectiveArrow { AttachTo = unit }
            end
            if Target.FlashVisible then
                FlashViz( unit )
            end
            Triggers.CreateUnitDeathTrigger(OnUnitKilled, unit)
            Triggers.CreateUnitReclaimedTrigger(OnUnitKilled, unit) #same as killing for our purposes
        else
            OnUnitKilled(unit)
        end
    end

    local progress = string.format('(%s/%s)', Target.killed, Target.total)
    UpdateObjective( Title, 'Progress', progress, objective.Tag )

    return objective
end

#
# Capture
#   Capture units
#
# Target = {
#       Units = <units>,
#       NumRequired = <x>,
# }
#
function Capture(Type,Complete,Title,Description,Target)
    Target.captured = 0
    Target.total = table.getn(Target.Units)
    local required = Target.NumRequired or Target.total
    local returnUnits = {}

    local image = GetActionIcon('capture')
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function OnUnitCaptured(unit, captor)
        table.insert(returnUnits, unit)
        if not objective.Active then
            return
        end

        Target.captured = Target.captured + 1
        local progress = string.format('(%s/%s)', Target.captured, required)
        objective:OnProgress(Target.captured,required)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        if Target.captured >= required then
            objective.Active = false
            objective:OnResult(true, returnUnits)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end

    local function OnUnitKilled(unit)
        if not objective.Active then
            return
        end
        Target.total = Target.total - 1
        if Target.total < required then
            objective.Active = false
            objective:OnResult(false)
            UpdateObjective( Title, 'complete', 'failed', objective.Tag )
        end
    end

    for k,unit in Target.Units do
        if not unit:IsDead() then
            # Mark the units unless MarkUnits == false
            if ( Target.MarkUnits == nil ) or Target.MarkUnits then
                local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                local arrow = ObjectiveArrow { AttachTo = unit }
            end

            Triggers.CreateUnitCapturedTrigger(nil,OnUnitCaptured,unit)
            Triggers.CreateUnitDeathTrigger(OnUnitKilled, unit)
            Triggers.CreateUnitReclaimedTrigger(OnUnitKilled, unit) #same functionality as killed

            if Target.FlashVisible then
                FlashViz( unit )
            end
        else
            #treat as killed Matt 8.30.06
            OnUnitKilled(unit)
        end
    end

    local progress = string.format('(%s/%s)', Target.captured, required)
    UpdateObjective( Title, 'Progress', progress, objective.Tag )

    return objective
end

#
# Kill or Capture
#   Kill or Capture units
function KillOrCapture(Type,Complete,Title,Description,Target)
    Target.killed_or_captured = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon('KillOrCapture')
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    # keep track of captured units so subsequent kills don't get counted
    local captured = {}

    local function OnUnitKilled(unit)
        for k,v in captured do
            if v == unit then
                # ignore units already captured
                return
            end
        end


        Target.killed_or_captured = Target.killed_or_captured + 1
        local progress = string.format('(%s/%s)', Target.killed_or_captured, Target.total)
        objective:OnProgress(Target.killed_or_captured,Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        if Target.killed_or_captured == Target.total then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end

    local function OnUnitCaptured(unit)
        table.insert(captured,unit)
        Target.killed_or_captured = Target.killed_or_captured + 1
        local progress = string.format('(%s/%s)', Target.killed_or_captured, Target.total)
        objective:OnProgress(Target.killed_or_captured,Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        if Target.killed_or_captured == Target.total then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end


    local function OnUnitReclaimed(unit)
        if not objective.Active then
            return
        end

        Target.killed_or_captured = Target.killed_or_captured + 1
        local progress = string.format('(%s/%s)', Target.killed_or_captured, Target.total)
        objective:OnProgress(Target.killed_or_captured,Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        if Target.killed_or_captured == Target.total then
            objective.Active = false
            objective:OnResult(true, unit)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end

    for k,unit in Target.Units do
        if not unit:IsDead() then
            # Mark the units unless MarkUnits == false
            if ( Target.MarkUnits == nil ) or Target.MarkUnits then
                local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                local arrow = ObjectiveArrow { AttachTo = unit }
            end

            if Target.FlashVisible then
                FlashViz( unit )
            end

            # note: you won't get an OnKilled after an OnCaptured because once
            # captured it's actually a new unit with no callback.
            Triggers.CreateUnitCapturedTrigger(nil,OnUnitCaptured,unit)
            Triggers.CreateUnitDeathTrigger(OnUnitKilled, unit)
            Triggers.CreateUnitReclaimedTrigger(OnUnitReclaimed, unit)
        else
            OnUnitKilled(unit)
        end
    end

    local progress = string.format('(%s/%s)', Target.killed_or_captured, Target.total)
    UpdateObjective( Title, 'Progress', progress, objective.Tag )

    return objective
end

#
# Reclaim
#   Reclaim units
function Reclaim(Type,Complete,Title,Description,Target)
    Target.reclaimed = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon("reclaim")
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function OnUnitReclaimed(unit)
        if not objective.Active then
            return
        end

        Target.reclaimed = Target.reclaimed + 1
        local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
        objective:OnProgress(Target.reclaimed,Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        if Target.reclaimed == Target.total then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end

    local function OnUnitKilled(unit)
        objective.Active = false
        objective:OnResult(false)
        UpdateObjective( Title, 'complete', 'failed', objective.Tag )
    end

    # If the unit is captured it can still be reclaimed to complete the
    # objective, so track the new unit created on a capture.
    local function OnUnitCaptured(newUnit,captor)
        Triggers.CreateUnitCapturedTrigger(nil,OnUnitCaptured,newUnit)
        Triggers.CreateUnitDeathTrigger(OnUnitKilled, newUnit)
        Triggers.CreateUnitReclaimedTrigger(OnUnitReclaimed, newUnit)
        local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
        local arrow = ObjectiveArrow { AttachTo = newUnit }
    end

    for k,unit in Target.Units do
        local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
        local arrow = ObjectiveArrow { AttachTo = unit }
        Triggers.CreateUnitCapturedTrigger(nil,OnUnitCaptured,unit )
        Triggers.CreateUnitDeathTrigger(OnUnitKilled, unit )
        Triggers.CreateUnitReclaimedTrigger(OnUnitReclaimed, unit )
    end

    local progress = string.format('(%s/%s)', Target.reclaimed, Target.total)
    UpdateObjective( Title, 'Progress', progress, objective.Tag )

    return objective
end

#
# Locate
#   Locate units
function Locate(Type,Complete,Title,Description,Target)
    Target.located = 0
    Target.total = table.getn(Target.Units)

    local image = GetActionIcon("locate")
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    local function OnUnitLocated(unit)
        Target.located = Target.located + 1
        local progress = string.format('(%s/%s)', Target.located, Target.total)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
        objective:OnProgress(Target.located,Target.total)
        if Target.located == Target.total then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective( Title, 'complete', "complete", objective.Tag )
        end
    end

    for k,unit in Target.Units do
        local IntelTrigger = import('/lua/ScenarioTriggers.lua').CreateArmyIntelTrigger
        IntelTrigger(OnUnitLocated,
                    GetArmyBrain(1),
                    'LOSNow',
                    unit,
                    true,
                    categories.ALLUNITS,
                    true,
                    unit:GetAIBrain() )
    end

    local progress = string.format('(%s/%s)', Target.located, Target.total)
    UpdateObjective( Title, 'Progress', progress, objective.Tag )

    return objective
end

#
# SpecificUnitsInArea
#   Complete when specified units are in the target area. We don't care how
# they got there (cheat teleport, etc), we just check if they're in there
# ShowProgress, optional:
function SpecificUnitsInArea(Type,Complete,Title,Description,Target)
    local image = GetActionIcon('Move')
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)
    local total = table.getn(Target.Units)
    local numRequired = Target.NumRequired or total
    Target.Count = 0

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function WatchArea(units,rect)
        while objective.Active do
            local cnt = 0
            for k,unit in units do
                if not unit:IsDead() then
                    if ScenarioUtils.InRect( unit:GetPosition(), rect ) then
                        cnt = cnt + 1
                    end
                end
            end

            if cnt != Target.Count then
                Target.Count = cnt
                local progress = string.format('(%s/%s)', Target.Count, numRequired)
                objective:OnProgress(Target.Count,numRequired)
                if (Target.ShowProgress) then
                    UpdateObjective( Title, 'Progress', progress, objective.Tag)
                end
            end

            if cnt >= numRequired then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective( Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(5)
        end
    end

    local rect = ScenarioUtils.AreaToRect( Target.Area )

    local w = rect.x1 - rect.x0
    local h = rect.y1 - rect.y0
    local x = rect.x0 + ( w / 2.0 )
    local z = rect.y0 + ( h / 2.0 )

    if Target.MarkArea then
        objective.Decals[Target.Area] = CreateObjectiveDecal(x, z, w, h)
    end

    local watchThread = ForkThread( WatchArea, Target.Units, rect )

    local function OnUnitKilled(unit)
        total = total - 1
        if objective.Active and total < numRequired then
            objective.Active = false
            objective:OnResult(false)
            UpdateObjective( Title, 'complete', 'failed', objective.Tag)
            KillThread(watchThread)
        end
    end

    for k,v in Target.Units do
        Triggers.CreateUnitDeathTrigger(OnUnitKilled, v )
        Triggers.CreateUnitReclaimedTrigger(OnUnitKilled, v )
    end

    if (Target.ShowProgress) then
        local progress = string.format('(%s/%s)', Target.Count, numRequired)
        UpdateObjective( Title, 'Progress', progress, objective.Tag)
    end

    return objective
end

#
# CategoriesInArea
#   Complete when specified units matching the target blueprint types are in
# the target area. We don't care exactly which units they are (pre-built or
# newly constructed) or how they got there (cheat teleport, etc). We just check
# the area for what units are inside and look at the blueprints (and optionally
# match the army, use -1 for don't care).
#
# Target = {
#   Requirements = {
#       { Area = <areaName>, Category=<cat1>, CompareOp=<op>, Value=<x>, [ArmyIndex=<index>]},
#       { Area = <areaName>, Category=<cat2>, CompareOp=<op>, Value=<y>, [ArmyIndex=<index>] },
#       ...
#       { Area = <areaName>, Category=<cat3>, CompareOp=<op>, Value=<z>, [ArmyIndex=<index>] },
#   }
# }
#
# -- op is one of: '<=', '>=', '<', '>', or '=='
#
function CategoriesInArea(Type,Complete,Title,Description,Action,Target)

    local image = GetActionIcon(Action)
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)
    local lastReqsMet = 0

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function WatchArea(requirements)
        local totalReqs = table.getn(requirements)
        while objective.Active do
            local reqsMet = 0

            for i,requirement in requirements do
                local units = GetUnitsInRect(requirement.Rect)
                local cnt = 0
                if units then
                    for k,unit in units do
                        if not unit:IsDead() and not unit:IsBeingBuilt() then
                            if not requirement.ArmyIndex or (requirement.ArmyIndex == unit:GetArmy()) then
                                if EntityCategoryContains(requirement.Category, unit) then
                                    if not unit.Marked and objective.MarkUnits then
                                        unit.Marked = true
                                        local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                                        local arrow = ObjectiveArrow { AttachTo = unit }
                                        objective:AddUnitTarget(unit)
                                    end
                                    cnt = cnt+1
                                end
                            end
                        end
                    end
                    #LOG('debug: CategoriesInArea: reqsmet '..reqsMet..'count '.. cnt )
                end
                if requirement.CompareFunc(cnt,requirement.Value) then
                    reqsMet = reqsMet +1
                end
            end

            if lastReqsMet != reqsMet then
                local progress = string.format('(%s/%s)', reqsMet, totalReqs)
                UpdateObjective( Title, 'Progress', progress, objective.Tag )
                objective:OnProgress(reqsMet,totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective( Title, 'complete', 'complete', objective.Tag)
                return
            end
            WaitTicks(10)
        end
    end

    for k,requirement in Target.Requirements do
        local rect = ScenarioUtils.AreaToRect( requirement.Area )

        local w = rect.x1 - rect.x0
        local h = rect.y1 - rect.y0
        local x = rect.x0 + ( w / 2.0 )
        local z = rect.y0 + ( h / 2.0 )

        if Target.MarkArea and not objective.Decals[requirement.Area] then
            local decal = CreateObjectiveDecal(x, z, w, h)
            objective.Decals[requirement.Area] = decal
        elseif Target.FlashVisible then
            FlashViz( requirement.Area )
        end

        if Target.MarkUnits then
            objective.MarkUnits = true
        end

        local reqRef = requirement
        reqRef.Rect = rect
        reqRef.CompareFunc = GetCompareFunc(requirement.CompareOp)
    end

    UpdateObjective( Title, 'Progress', string.format('(0/%d)', table.getsize(Target.Requirements)), objective.Tag )
    ForkThread( WatchArea, Target.Requirements )

    return objective
end

#
# ArmyStatCompare
#   Army stat is compared <=, >=, >, <, or == to some value.
#
# Target = {
#       Army=<index>,
#       StatName=<name>,
#       CompareOp=<op>,   -- op is one of: '<=', '>=', '<', '>', or '=='
#       Value=<value>,
#       [Category=<category>], -- optional to compare to a blueprint stat
#       ShowProgress, optional: shows #/#. may not make sense for all compare types
# }
#
# Note: Be careful when using '==' as the stat is only checked every 5 ticks.
#
function ArmyStatCompare(Type,Complete,Title,Description,Action,Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    local function WatchStat(statName,brain,compareFunc,value,category)
        local oldVal

        while objective.Active do
            local result = false
            local testVal = 0

            if category then
                testVal = brain:GetBlueprintStat(statName,category)

            else
                testVal = brain:GetArmyStat(statName,value).Value
            end

            if (Target.ShowProgress) then
                if (testVal ~= oldVal) then
                    #LOG('*** progress! ', testVal, ' ', oldVal)
                    local progress = string.format('(%s/%s)', testVal, value)
                    UpdateObjective( Title, 'Progress', progress, objective.Tag )
                    oldVal = testVal
                end
            end

            result = compareFunc(testVal,value)

            if result then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective( Title, 'complete', 'complete', objective.Tag )
                return
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread( WatchStat, Target.StatName, GetArmyBrain(Target.Army), op, Target.Value, Target.Category )
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
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    return objective
end

#
# UnitStatCompare
#   A specified unit's stat is <=, >=, >, <, or == to some value.
#
# Target = {
#       Unit=<unit>,
#       StatName=<name>,
#       CompareOp=<op>,   -- op is one of: '<=', '>=', '<', '>', or '=='
#       Value=<value>,
# }
#
# Note: Be careful when using '==' as the stat is only checked every 5 ticks.
#
function UnitStatCompare(Type,Complete,Title,Description,Action,Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    local function WatchStat(statName,unit,compareFunc,value)
        while objective.Active do
            if compareFunc(unit:GetStat(statName,value).Value,value) then
                objective.Active = false
                objective:OnResult(true)
                UpdateObjective( Title, 'complete', 'complete', objective.Tag )
                return
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread( WatchStat, Target.StatName, Target.Unit, op, Target.Value )
    end

    return objective
end

#
# CategoryStatCompare
#   Some unit belonging to specified category has a stat <=, >=, >, <, or ==
# to some value.
#
# Target = {
#       Army=<index>,
#       Category=<unit>,
#       StatName=<name>,
#       CompareOp=<op>,   -- op is one of: '<=', '>=', '<', '>', or '=='
#       Value=<value>,
# }
#
# Note: Be careful when using '==' as the stat is only checked every 5 ticks.
#
function CategoryStatCompare(Type,Complete,Title,Description,Action,Target)
    local image = GetActionIcon(Action)
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    local function WatchStat(statName,brain,category,compareFunc,value)
        while objective.Active do
            local unitsInCategory = brain:GetListOfUnits(category,false)
            if unitsInCategory then
                for k,unit in unitsInCategory do
                    if compareFunc(unit:GetStat(statName,value).Value,value) then
                        objective.Active = false
                        objective:OnResult(true)
                        UpdateObjective( Title, 'complete', 'complete', objective.Tag )
                        return
                    end
                end
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread( WatchStat, Target.StatName, GetArmyBrain(Target.Army), Target.Category, op, Target.Value )
    end

    return objective
end

#
# Protect
#   Fails if # of units in list falls below NumRequired before the timer expires
# or, in the case of no timer, the objective is manually update to complete.
#
# Target = {
#       Units = {},
#       Timer = <seconds> or nil,   -- if nil, requires manual completion
#       NumRequired = <#>,          -- how many must survive
# }
function Protect(Type,Complete,Title,Description,Target)

    local image = GetActionIcon("protect")
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)
    local total = table.getn(Target.Units)
    local max = total
    local numRequired = Target.NumRequired or total
    local timer = nil

    local function OnUnitKilled(unit)
        if not objective.Active then
            return
        end

        total = total - 1
        objective:OnProgress( total, numRequired )

        if (Target.ShowProgress) then
            local progress = string.format('(%s/%s)', total, numRequired)
            UpdateObjective( Title, 'Progress', progress, objective.Tag )
        elseif (Target.PercentProgress) then
            #local progress = LOCF('<LOC A02_M01_OBJ_010_113>(%s%%/%s%%)',math.ceil( total / max * 100),math.ceil( numRequired / max * 100))
            local progress = string.format('(%s%%)',math.ceil( total / max * 100))
            UpdateObjective( Title, 'Progress', progress, objective.Tag )
        end

        if objective.Active and total < numRequired then
            objective.Active = false
            objective:OnResult(false,unit)
            UpdateObjective( Title, 'complete', 'failed', objective.Tag)
            Sync.ObjectiveTimer = 0
            if timer then
                KillThread(timer)
            end
        end
    end

    local function OnExpired()
        if objective.Active then
            objective.Active = false
            objective:OnResult(true)
            UpdateObjective( Title, 'complete', 'complete', objective.Tag)
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
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    if Target.Timer then
        timer = import('/lua/ScenarioTriggers.lua').CreateTimerTrigger(
            OnExpired,
            Target.Timer,
            true
        )
    end

    for k,v in Target.Units do
        Triggers.CreateUnitDeathTrigger(OnUnitKilled, v )
        Triggers.CreateUnitReclaimedTrigger(OnUnitKilled, v )
    end

    if (Target.ShowProgress) then
        local progress = string.format('(%s/%s)', total, numRequired)
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
    elseif (Target.PercentProgress) then
        #local progress = LOCF('<LOC A02_M01_OBJ_010_113>(%s%%/%s%%)',math.ceil( total / max * 100),math.ceil( numRequired / max * 100))
        local progress = string.format('(%s%%)',math.ceil( total / max * 100))
        UpdateObjective( Title, 'Progress', progress, objective.Tag )
    end

    return objective
end

#
# Timer
#   OnResult() is called when the timer expires. The result depends on whether
# ExpireResult is set to complete or failed.
#
# Target = {
#       Timer = <seconds>
#       ExpireResult = 'complete' or 'failed'
# }
function Timer(Type,Complete,Title,Description,Target)

    local image = GetActionIcon("timer")
    local objective = AddObjective(Type,Complete,Title,Description,image,Target)

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    local function onTick(newTime)
        UpdateObjective( Title, 'timer', {Time = newTime}, objective.Tag)
    end

    local function OnExpired()
        objective.Active = false
        if Target.ExpireResult == 'complete' then
            objective:OnResult(true)
            UpdateObjective( Title, 'complete', 'complete', objective.Tag)
        else
            objective:OnResult(false)
            UpdateObjective( Title, 'complete', 'failed', objective.Tag)
        end
        Sync.ObjectiveTimer = 0
    end

    import('/lua/ScenarioTriggers.lua').CreateTimerTrigger(
        OnExpired,
        Target.Timer,
        false,
        true,
        onTick
    )

    return objective
end

function Unknown(Type,Complete,Title,Description)
    local objective = AddObjective(Type,Complete,Title,Description)

    # call ManualResult
    objective.ManualResult = function(self, result)
        self.Active = false
        self:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, self.Tag )
    end

    return objective
end

function Basic(Type,Complete,Title,Description,Image,Target)
    local objective = AddObjective(Type,Complete,Title,Description,Image,Target)

    # call ManualResult
    objective.ManualResult = function(self, result)
        objective.Active = false
        objective:OnResult(result)
        local resultStr
        if result then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end
        UpdateObjective( Title, 'complete', resultStr, objective.Tag)
    end

    objective.AddBasicUnitTarget = function(self, unit)
        objective:AddUnitTarget( unit )
        local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
        local arrow = ObjectiveArrow { AttachTo = unit }
        table.insert( objective.UnitMarkers, arrow )
    end

    objective.AddTarget = function(self, target)
        if (target.Area) then
            local rect = ScenarioUtils.AreaToRect( target.Area )

            local w = rect.x1 - rect.x0
            local h = rect.y1 - rect.y0
            local x = rect.x0 + ( w / 2.0 )
            local z = rect.y0 + ( h / 2.0 )

            if target.MarkArea then
                objective.Decals[target.Area] = CreateObjectiveDecal(x, z, w, h)
            end
            if Target.FlashVisible then
                FlashViz( target.Area )
            end
        end
        if target.Areas and target.MarkArea then
            for k,v in target.Areas do
                local rect = ScenarioUtils.AreaToRect( v )

                local w = rect.x1 - rect.x0
                local h = rect.y1 - rect.y0
                local x = rect.x0 + ( w / 2.0 )
                local z = rect.y0 + ( h / 2.0 )

                objective.Decals[v] = CreateObjectiveDecal(x, z, w, h)
                if Target.FlashVisible then
                    FlashViz( v )
                end
            end
        end
        if (target.Units) then
            if (target.MarkUnits) then
                for k,unit in target.Units do
                    if not unit:IsDead() then
                        local ObjectiveArrow = import('objectiveArrow.lua').ObjectiveArrow
                        local arrow = ObjectiveArrow { AttachTo = unit }
                        table.insert( objective.UnitMarkers, arrow )
                        if target.AlwaysVisible then
                            SetupVizMarker(self, unit)
                        end
                        if Target.FlashVisible then
                            FlashViz( unit )
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


### Adds objective for the objectives screen
function AddObjective(Type,         # 'primary', 'bonus', etc
                      Complete,     # 'complete', 'incomplete'
                      Title,        # e.g. "Destroy Radar Stations"
                      Description,  # e.g. "A reason why you need to destroy the radar stations"
                      ActionImage,        # '/textures/ui/common/missions/mission1.dds'
                      Target,       # Can be one of:
                                    #   Units = { unit1, unit2, ... }
                                    #   Areas = { 'areaName1', 'areaName2', ... }
                      IsLoading,    # Are we loading a saved game?
                      loadedTag     # If IsLoading is specified, what's the tag?
                      )

    if Type == 'bonus' then
        return {Tag = 'Invalid'} # bonus objectives cut
    end

    if(not Sync.ObjectivesTable) then
        Sync.ObjectivesTable = {}
    end

    local tag

    if IsLoading then
        tag = loadedTag
    else
        tag = 'Objective' .. objNum
        objNum = objNum + 1
        table.insert( SavedList, {AddArgs = {Type,Complete,Title,Description,ActionImage,Target,true,tag,n=8},Tag=tag} )
    end

    #LOG("Debug: AddObjective: ", Title,":", Description, " (Tag=",tag,")")

    # Set up objective table to return.
    local objective = {
        # Used to synchronize sim objectives with user side objectives
        Tag = tag,

        # Whether the objective is in progress or not and does not indicate
        # success or failure.
        Active = true,

        # success or failure.
        Complete = false,

        # Decal table, key'd by area names
        Decals = {},

        # Unit arrow table
        UnitMarkers = {},

        # Visibility markers that we manage
        VizMarkers = {},

        # Single decal
        Decal = false,

        # Strategic icon overrides
        IconOverrides = {},

        # For tracking targets
        NextTargetTag = 0,
        PositionUpdateThreads = {},

        Title = Title,
        Description = Description,

        SimStartTime = GetGameTimeSeconds(),

        # Called on success or failure
        ResultCallbacks = {},
        AddResultCallback = function(self,cb)
            table.insert(self.ResultCallbacks,cb)
        end,

        # Some objective types can provide progress updates (not success/fail)
        ProgressCallbacks = {},
        AddProgressCallback = function(self,cb)
            table.insert(self.ProgressCallbacks,cb)
        end,

        # Don't override these if you want notification. Call Add???Callback
        # intead
        OnResult = function(self,success,data)

            self.Complete = success

            for k,v in self.ResultCallbacks do v(success,data) end

            # Destroy decals
            for k,v in self.Decals do v:Destroy() end

            # Destroy unit marker things
            for k,v in self.UnitMarkers do
                v:Destroy()
            end

            # Revert strategic icons
            for k,v in self.IconOverrides do
                if not v:BeenDestroyed() then
                    v:SetStrategicUnderlay("")
                end
            end

            # Destroy visibility markers
            for k,v in self.VizMarkers do
                v:Destroy()
            end

            if self.PositionUpdateThreads then
                for k,v in self.PositionUpdateThreads do
                    if v then
                        KillThread(self.PositionUpdateThreads[k])
                        self.PositionUpdateThreads[k] = false
                    end
                end
            end
        end,

        OnProgress = function(self,current,total)
            for k,v in self.ProgressCallbacks do v(current,total) end
        end,

        # Call this to manually fail the objective
        Fail = function(self)
            self.Active = false
            self:OnResult(false)
            UpdateObjective(self.Title,'complete','failed',self.Tag)
        end,

        AddUnitTarget = function(self,unit) end, # defined below
        AddAreaTarget = function(self,area) end, # defined below
    }

    # Takes a unit that is an objective target and uses its recon detect
    # event to notify the objectives that we have a blip for the unit.
    local function SetupNotify(obj,unit,targetTag)
		if GetFocusArmy() == -1 then
			return
		end
        # Add a detectedBy callback to notify the user layer when our recon
        # on the target comes in and out.
        local detectedByCB = function(cbunit,armyindex)
            			
            if armyindex != 1 then
                return
            end
            
            if not obj.Active then
                return
            end
            LOG('detected by ',armyindex, ' focus = ',GetFocusArmy())
            # now if we've been detected by the focus army ...
            if armyindex == GetFocusArmy() then
                # get the blip that is associated with the unit
                local blip = cbunit:GetBlip(armyindex)

                # Only provide the target position to the user layer if
                # the blip IsSeenEver() (i.e. has been identified).
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
                                                obj.Tag )

                                # If it's not mobile we can exit the thread since
                                # the blip won't move.
                                if not unit:IsDead() and not unit:BeenDestroyed() and not EntityCategoryContains( categories.MOBILE, unit ) then
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
                        #LOG('killing thread')
                        KillThread( obj.PositionUpdateThreads[targetTag] )
                        obj.PositionUpdateThreads[targetTag] = false
                    end

                    # when the blip is destroyed, tell objectives we dont
                    # have a blip anymore. This doesn't necessarily mean the
                    # unit is killed, we simply lost the blip.
                    UpdateObjective(Title,
                                    'Target',
                                    {
                                        Type = 'Position',
                                        Value = nil,
                                        BlueprintId = nil,
                                        TargetTag=targetTag,
                                    },
                                    obj.Tag )
                end

                # When the blip is destroyed, have it call this callback
                # function (defined above)
                blip:AddDestroyHook(destroyCB)
            end
        end

        # When the unit is detected by an army, have it call this callback
        # function (defined above)
        unit:AddDetectedByHook(detectedByCB)

        # See if we can detect the unit right now
        local blip = unit:GetBlip(GetFocusArmy())
        if blip then
            detectedByCB(unit,GetFocusArmy())
        end
    end

    # Take an objective target unit that is owned by the focus army
    # Info passed to user layer to handle zoom to button and chiclet image
    function SetupFocusNotify(obj, unit, targetTag)
        obj.PositionUpdateThreads[targetTag] = ForkThread(
            function()
                while obj.Active do
                    if unit:BeenDestroyed() then
                        return
                    end

                    UpdateObjective(Title,
                                    'Target',
                                    {
                                        Type = 'Position',
                                        Value = unit:GetPosition(),
                                        BlueprintId = unit:GetBlueprint().BlueprintId,
                                        TargetTag=targetTag
                                    },
                                    obj.Tag )

                    # If it's not mobile we can exit the thread since
                    # the unit won't move.
                    if not unit:IsDead() and not unit:BeenDestroyed() and not EntityCategoryContains( categories.MOBILE, unit ) then
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
                #LOG('killing thread')
                KillThread( obj.PositionUpdateThreads[targetTag] )
                obj.PositionUpdateThreads[targetTag] = false
            end

            # when the blip is destroyed, tell objectives we dont
            # have a blip anymore. This doesn't necessarily mean the
            # unit is killed, we simply lost the blip.
            UpdateObjective(Title,
                            'Target',
                            {
                                Type = 'Position',
                                Value = nil,
                                BlueprintId = nil,
                                TargetTag=targetTag,
                            },
                            obj.Tag )
        end

        # When the unit is destroyed have it call this callback
        # function (defined above)
        Triggers.CreateUnitDeathTrigger(destroyCB, unit )
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
                Army = 1,
            }
            local vizmarker = VizMarker(spec)
            object.Trash:Add(vizmarker)
            vizmarker:AttachBoneTo(-1,object,-1)
        else
            local rect = ScenarioUtils.AreaToRect(Target.Area)
            local width = rect.x1 - rect.x0
            local height = rect.y1 - rect.y0
            local spec = {
                X = rect.x0 + width/2,
                Z = rect.y0 + height/2,
                Radius = math.max( width, height ),
                LifeTime = -1,
                Omni = false,
                Vision = true,
                Army = 1,
            }
            local vizmarker = VizMarker(spec)
            table.insert(objective.VizMarkers,vizmarker);
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
                Army = 1,
            }
            local vizmarker = VizMarker(spec)
            object.Trash:Add(vizmarker)
            vizmarker:AttachBoneTo(-1,object,-1)
        else
            local rect = ScenarioUtils.AreaToRect(object)
            local width = rect.x1 - rect.x0
            local height = rect.y1 - rect.y0
            local spec = {
                X = rect.x0 + width/2,
                Z = rect.y0 + height/2,
                Radius = math.max( width, height ),
                LifeTime = 0.01,
                Omni = false,
                Vision = true,
                Radar = false,
                Army = 1,
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
        end
    end

    if Target and Target.Requirements then
        for k,req in Target.Requirements do
            if req.Area then
                table.insert(userTargets, { Type = 'Area', Value = ScenarioUtils.AreaToRect(req.Area) })
            end
        end
    elseif Target and Target.Timer then
        userTargets = {Type = 'Timer', Time = Target.Timer}
    end

    if Target.Category then
        local bps = EntityCategoryGetUnitList(Target.Category)
        if table.getn(bps) > 0 then
            table.insert(userTargets, { Type = 'Blueprint', BlueprintId = bps[1] })
        end
    end

    local userObjectiveData = {
        tag = tag,
        type = Type,
        complete = Complete,
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

    objective.AddUnitTarget = function(self,unit)
        self.NextTargetTag = self.NextTargetTag + 1
        if unit:GetArmy() == GetFocusArmy() then
            --it's our unit
            if GetFocusArmy() == 1 then
                SetupFocusNotify(self,unit,self.NextTargetTag)
            end
        else
            --it's someone else unit
            SetupNotify(self,unit,self.NextTargetTag)
        end
        if Target.AlwaysVisible then
            SetupVizMarker(self,unit)
        end

        table.insert(self.IconOverrides,unit)

        # Mark the units unless MarkUnits == false
        if ( Target.MarkUnits == nil ) or Target.MarkUnits then
            if Type == 'primary' then
                unit:SetStrategicUnderlay('icon_objective_primary')
            elseif Type == 'secondary' then
                unit:SetStrategicUnderlay('icon_objective_secondary')
            end
        end
    end

    objective.AddAreaTarget = function(self,area)
        self.NextTargetTag = self.NextTargetTag + 1
        UpdateObjective(Title,
                        'Target',
                        {
                            Type = 'Area',
                            Value = ScenarioUtils.AreaToRect(area),
                            TargetTag=self.NextTargetTag
                        },
                        self.Tag )

        if Target.AlwaysVisible then
            SetupVizMarker(self,area)
        end
    end

    if Target then
        if Target.Units then
            for k,v in Target.Units do
                if v and v.IsDead and not v:IsDead() then
                    objective:AddUnitTarget(v)
                end
            end
        end

        if Target.Unit then
            if Target.Unit.IsDead and not Target.Unit:IsDead() then
                objective:AddUnitTarget(Target.Unit)
            end
        end

        if Target.Areas then
            for k,v in Target.Areas do
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
        table.insert( SavedList, {DeleteArgs = userObjectiveUpdate} )
    end
    table.insert(Sync.ObjectivesUpdateTable, userObjectiveUpdate)
end

### Update legacy style objective using correct syntax
function UpdateBasicObjective(Objective, UpdateField, NewData)
    UpdateObjective(Objective.Title, UpdateField, NewData, Objective.Tag)
end
### Updates an objective, referencing it by objective title
function UpdateObjective(Title, UpdateField, NewData, objTag, IsLoading, InTime)

    if objTag == 'Invalid' then
        return
    end

    if(not Sync.ObjectivesUpdateTable) then
        Sync.ObjectivesUpdateTable = {}
    end

    if type(objTag) ~= 'string' then
        error('SimObjectives error: Invalid type for objTag in UpdateObjective.  String expected but got '
        .. type(objTag), 2)
    end
    if type(UpdateField) ~= 'string' then
        error('SimObjectives error: Invalid type for UpdateField in UpdateObjective. String expected but got ' .. type(UpdateField), 2)
    end
    #if type(Title) ~= 'string' then
    #    error('SimObjectives error: Invalid type for Title in UpdateObjective. String expected but got ' .. type(Title), 2)
    #end

    if not IsLoading then
        table.insert( SavedList, {UpdateArgs = {Title,UpdateField,NewData,objTag,true, GetGameTimeSeconds(),n=6},Tag=objTag} )
    end

    # All fields are stored with lowercase names
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
        error( 'Unknown UpdateField: ' .. UpdateField .. '.  Cannot process UpdateObjective request.', 2 )
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

function GetCompareFunc( op )
    function gt(a,b) return a > b end
    function lt(a,b) return a < b end
    function gte(a,b) return a >= b end
    function lte(a,b) return a <= b end
    function eq(a,b) return a == b end

    if op == '<=' then return lte end
    if op == '>=' then return gte end
    if op == '<' then return lt end
    if op == '>' then return gt end
    if op == '==' then return eq end

    WARN("Unsupported CompareOp '",op,"'")
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

     # todo: make 'kill or capture' icon?
    if action == "killorcapture" then return "/game/orders/attack_btn_up.dds" end

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
    for k,v in SavedList do
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
    return CreateDecal(Vector(x,0,z), 0, objectiveDecal, '', 'Water Albedo', w, h, DecalLOD, 0, 1, 0)
end