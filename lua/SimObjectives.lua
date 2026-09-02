-----------------------------------------------------------------
-- File     :  /lua/SimObjectives.lua
-- Summary  : Sim side objectives
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias ObjectiveType 'primary' | 'secondary' | 'bonus'
---@alias ObjectiveStatus 'complete' | 'incomplete'
---@alias ArmyStatistic "Units_Active" | "Units_Killed" | "Units_History" | "Enemies_Killed" | "Economy_TotalProduced_Energy" | "Economy_TotalConsumed_Energy" | "Economy_Income_Energy" | "Economy_Output_Energy" | "Economy_Stored_Energy" | "Economy_Reclaimed_Energy" | "Economy_MaxStorage_Energy" | "Economy_PeakStorage_Energy" | "Economy_TotalProduced_Mass" | "Economy_TotalConsumed_Mass" | "Economy_Income_Mass" | "Economy_Output_Mass" | "Economy_Stored_Mass" | "Economy_Reclaimed_Mass" | "Economy_MaxStorage_Mass" | "Economy_PeakStorage_Mass",
---@alias ObjectiveAction "Kill" | "Capture" | "Build" | "Protect" | "Timer" | "Move" | "Reclaim" | "Repair" | "Locate" | "Group" | "KillOrCapture"
---@alias ObjectiveFactionIcon "Aeon" | "Cybran" | "UEF" | "Seraphim"
---@alias ObjectiveExpireResult "complete" | "failed"
---@alias ObjectiveProgressCallback fun(current: number, required: number) Function is is called when objective progress changes
---@alias ObjectiveResultCallback fun(success: boolean, data?: any) Function that is called when objective ends, each objective can pass different data

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
local ObjectiveArrow = import("/lua/objectivearrow.lua").ObjectiveArrow
local ObjectiveGroup = import("/lua/sim/objectives/ObjectiveGroup.lua").ObjectiveGroup

local objNum = 0 -- Used to create unique tags for objectives
local DecalLOD = 4000
local objectiveDecal = '/env/utility/decals/objective_debug_albedo.dds'
local SavedList = {}

local mobileAirCategories = categories.AIR * categories.MOBILE

local actionIcons = {
    kill = "/game/orders/attack_btn_up.dds",
    capture = "/game/orders/convert_btn_up.dds",
    build = "/game/orders/production_btn_up.dds",
    protect = "/game/orders/guard_btn_up.dds",
    timer = "/game/orders/guard_btn_up.dds",
    move = "/game/orders/move_btn_up.dds",
    reclaim = "/game/orders/reclaim_btn_up.dds",
    repair = "/game/orders/repair_btn_up.dds",
    locate = "/game/orders/omni_btn_up.dds",
    group = "/game/orders/move_btn_up.dds",
    killorcapture = "/game/orders/attack_capture_btn_up.dds",
}

local targetFactionIcons = {
    Cybran = "/textures/ui/common/faction_icon-lg/cybran_ico.dds",
    Aeon = "/textures/ui/common/faction_icon-lg/aeon_ico.dds",
    UEF = "/textures/ui/common/faction_icon-lg/uef_ico.dds",
    Seraphim = "/textures/ui/common/faction_icon-lg/seraphim_ico.dds",
}

---Returns path to icon associated with objective action
---@param actionString ObjectiveAction
---@return string iconPath Empty string when action is not found.
function GetActionIcon(actionString)
    local action = string.lower(actionString)
    return actionIcons[action] or ""
end

local compareFunctions = {
    ["<="] = function(a, b) return a <= b end,
    [">="] = function(a, b) return a >= b end,
    ["<"]  = function(a, b) return a < b end,
    [">"]  = function(a, b) return a > b end,
    ["=="] = function(a, b) return a == b end,
    ["~="] = function(a, b) return a ~= b end,
}

---Returns function that compares two elements
---@param operation "<=" | ">=" | "<" | ">" | "==" | "~="
---@return fun(a, b): boolean
function GetCompareFunc(operation)
    local fn = compareFunctions[operation]
    if not fn then
        WARN("GetCompareFunc: Unsupported compare operation '", operation, "', defaulting to '<'")
        return compareFunctions["<"]
    end
    return fn
end

---Creates objective target decal with specified dimensions
---@param x number
---@param z number
---@param w number
---@param h number
---@return moho.CDecalHandle
function CreateObjectiveDecal(x, z, w, h)
    return CreateDecal(Vector(x, 0, z), 0, objectiveDecal, '', 'Water Albedo', w, h, DecalLOD, 0, 1, 0)
end

---@type integer
local playerArmy
---Return one of the human players in a game, using this instead of GetFocusArmy() to get a deterministic army index in coop.
---@return integer
local function getPlayerArmy()
    if not playerArmy then
        for _, v in ipairs(ArmyBrains) do
            if v.BrainType == 'Human' then
                playerArmy = v:GetArmyIndex()
                break
            end
        end
    end
    return playerArmy
end

local humanArmies
---List of army index to army brain
---@return table<integer, AIBrain>
local function getHumanArmies()
    if not humanArmies then
        humanArmies = {}
        local isCoop = ScenarioInfo.type == 'campaign_coop'
        for _, brain in pairs(ArmyBrains) do
            -- In campaign, if an AI mod is being used to provide an AI 'player', then this should also be included
            -- otherwise it can render some missions impossible to complete
            if brain.Human or (isCoop and StringStarts(brain.Name, "Player")) then
                humanArmies[brain.Army] = brain
            end
        end
    end
    return humanArmies
end

---@param data table
---@return table<integer, AIBrain>
local function makeArmyList(data)
    local armies = {}
    if data.Army then
        local brain = GetArmyBrain(data.Army)
        armies[brain.Army] = brain
    end

    if data.ArmyIndex then
        local brain = GetArmyBrain(data.ArmyIndex)
        armies[brain.Army] = brain
    end

    if data.Armies then
        for _, armyName in data.Armies do
            if armyName == "HumanPlayers" then
                for _, brain in pairs(getHumanArmies()) do
                    armies[brain.Army] = brain
                end
            else
                local brain = GetArmyBrain(armyName)
                armies[brain.Army] = brain
            end
        end
    end
    return armies
end

---Returns true if objective exists and is completed.
---@param objective? Objective
---@return boolean
function IsComplete(objective)
    if not objective then
        return false
    end
    return objective.Complete
end

---@param objective Objective
---@param unit Unit
---@param markUnits boolean
function BasicUnitTarget(objective, unit, markUnits)
    objective:AddUnitTarget(unit, markUnits)
end

function OnUnitGivenBase(objective, target, unit, newUnit, markUnits)
    if unit then
        table.removeByValue(target.Units, unit)
    end

    table.insert(target.Units, newUnit)
    BasicUnitTarget(objective, newUnit, markUnits)
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
    if objective.OnUnitGiven then
        Triggers.CreateUnitGivenTrigger(objective.OnUnitGiven, unit)
    end
    if objective.OnUnitLocated then
        if isAlreadyLocated then
            return true
        else
            Triggers.CreateArmyIntelTrigger(objective.OnUnitLocated, GetArmyBrain(getPlayerArmy()), 'LOSNow', unit, true, categories.ALLUNITS, true, unit:GetAIBrain())
            return false
        end
    end
end

---@param objective Objective
---@param IsLoading? boolean
function DeleteObjective(objective, IsLoading)
    local userObjectiveUpdate = {
        tag = objective.Tag,
        updateField = 'delete',
    }
    if not IsLoading then
        table.insert(SavedList, {DeleteArgs = userObjectiveUpdate})
    end
    table.insert(Sync.ObjectivesUpdateTable, userObjectiveUpdate)
end

local allowedUpdateFields = {
    ["type"] = true,
    ["complete"] = true,
    ["title"] = true,
    ["description"] = true,
    ["image"] = true,
    ["progress"] = true,
    ["target"] = true,
    ["timer"] = true,
    ["delete"] = true,
}

---Updates an objective, referencing it by objective title
---@param title string
---@param updateField string
---@param newData table|string
---@param objTag string
---@param isLoading? boolean
---@param inTime? integer
function UpdateObjective(title, updateField, newData, objTag, isLoading, inTime)
    if objTag == 'Invalid' then
        return
    end

    if not Sync.ObjectivesUpdateTable then
        Sync.ObjectivesUpdateTable = {}
    end

    if type(objTag) ~= 'string' then
        error('SimObjectives error: Invalid type for objTag in UpdateObjective.  String expected but got ' .. type(objTag), 2)
    elseif type(updateField) ~= 'string' then
        error('SimObjectives error: Invalid type for UpdateField in UpdateObjective. String expected but got ' .. type(updateField), 2)
    end

    if not isLoading then
        table.insert(SavedList, {UpdateArgs = {title, updateField, newData, objTag, true, GetGameTimeSeconds(), n=6}, Tag=objTag})
    end

    -- All fields are stored with lowercase names
    updateField = string.lower(updateField)
    if not allowedUpdateFields[updateField] then
        error('Unknown UpdateField: ' .. updateField .. '.  Cannot process UpdateObjective request.', 2)
    else
        local userObjectiveUpdate = {
            title = title,
            updateField = updateField,
            updateData = newData,
            tag = objTag,
            loading = isLoading,
        }
        if updateField == 'complete' then
            userObjectiveUpdate['time'] = inTime or GetGameTimeSeconds()
        end
        table.insert(Sync.ObjectivesUpdateTable, userObjectiveUpdate)
    end
end

-- Update legacy style objective using correct syntax
function UpdateBasicObjective(Objective, UpdateField, NewData)
    UpdateObjective(Objective.Title, UpdateField, NewData, Objective.Tag)
end

---@class ObjectiveTargetBase
---@field ShowProgress? boolean Defaults to `true` to show the progress in the UI.
---@field Timer? integer Time in seconds after which the objective will end. Set `ExpireResult` to complete of fail the objective.
---@field ExpireResult? ObjectiveExpireResult Requires `Timer` to be set.

---@class ObjectiveTargetRequirements
---@field Area string
---@field Category EntityCategory
---@field CompareOp CompareType
---@field Value number
---@field ArmyIndex integer
---@field Armies string[]

---@class ObjectiveTarget : ObjectiveTargetBase
---@field Area? string
---@field Areas? string[]
---@field MarkArea? boolean
---@field MarkUnits? boolean
---@field FlashVisible? boolean
---@field AlwaysVisible? boolean
---@field PercentProgress? boolean Show the progress in UI in percent. Defaults to false.
---@field Unit? Unit
---@field Units? Unit[]
---@field Hidden? boolean Objective will not be displayed in the UI.
---@field ShowFaction? ObjectiveFactionIcon Faction icon will be used as the objective icon.
---@field Category? EntityCategory
---@field NumRequired? integer Specific amount required, if not provided it can be calculated from provided `Units`. `PercentRequired` can be used as well.
---@field PercentRequired? number Alternative to `NumRequired`
---@field Requirements? ObjectiveTargetRequirements

---Base objective class
---@class Objective
---@field Tag string Unique identifier used to sync between sim <-> UI
---@field Type ObjectiveType Primary = required to be completed, secondary = optional, bonus = often hidden for extra challenge
---@field Title string Title of the object, supports strings with LOC
---@field Description string Description of the object, supports strings with LOC
---@field Hidden boolean Flag to indicate hiding the objective from screen 
---@field SimStartTime number Set when the objective starts
---@field Decals table<string, moho.CDecalHandle> Dictionary of objective decals associated with the target area names
---@field UnitMarkers ObjectiveArrow[] Array of unit markers (yellow bouncing arrow) associated with the objective
---@field VizMarkers VizMarker[] Array of visibility markers associated with the objective
---@field IconOverrides Unit[] Array of units with added objective strategic icon overlay
---@field PositionUpdateThreads table<integer, thread> Threads for updating target's position for UI and icon based on available intel
---@field ProgressCallbacks ObjectiveProgressCallback[] List of functions to call when the objective progress changes
---@field ResultCallbacks ObjectiveResultCallback[] List of functions to call when the objective is completed
---@overload fun(tag: string, title: string, description: string, objType: ObjectiveType, status: ObjectiveStatus, hidden?: boolean, target?: ObjectiveTarget): Objective
local Objective = ClassSimple {
    ---Flag to indicate the objective is in progress 
    Active = true,
    ---Flag to indicate success or failure
    Complete = false,
    -- Display progress in the UI
    ShowProgress = true,
    -- Display the progress in % instead.
    PercentProgress = false,
    -- ID for tracking targets
    NextTargetTag = 0,
    ---@type thread|nil Timer to finish the objective
    Timer = nil,

    ---@param self Objective
    ---@param tag string
    ---@param objType ObjectiveType
    ---@param status ObjectiveStatus
    ---@param title string
    ---@param description string
    ---@param hidden? boolean
    ---@param target? ObjectiveTarget
    __init = function(self, tag, objType, status, title, description, hidden, target)
        self.Tag = tag
        self.Type = objType
        self.Title = title
        self.Description = description
        self.Hidden = hidden or false
        self.SimStartTime = GetGameTimeSeconds()

        self.Decals = {}
        self.UnitMarkers = {}
        self.VizMarkers = {}
        self.IconOverrides = {}
        self.PositionUpdateThreads = {}
        self.ProgressCallbacks = {}
        self.ResultCallbacks = {}

        if target then
            self:AddTarget(target)
        end
        if status == "complete" then
            self.Active = false
            self.Complete = true
        end
    end,

    ---Adds a function to call when objective ends
    ---@param self Objective
    ---@param cb ObjectiveResultCallback
    AddResultCallback = function(self, cb)
        table.insert(self.ResultCallbacks, cb)
    end,

    ---Removes a function from the list of callbacks to call when objective ends
    ---@param self Objective
    ---@param cb ObjectiveResultCallback
    RemoveResultCallback = function(self, cb)
        table.removeByValue(self.ResultCallbacks, cb)
    end,

    ---Adds a function to call when objective progress changes
    ---@param self Objective
    ---@param cb ObjectiveProgressCallback
    AddProgressCallback = function(self, cb)
        table.insert(self.ProgressCallbacks, cb)
    end,

    ---Removes a function from the list of callbacks to call when objective progress changes
    ---@param self Objective
    ---@param cb ObjectiveProgressCallback
    RemoveProgressCallback = function(self, cb)
        table.removeByValue(self.ProgressCallbacks, cb)
    end,

    ---Pushes the progress update to the UI if `ShowProgress` is enabled.
    ---@param self Objective
    ---@param current number
    ---@param required number
    ---@param total? number Required for the perctange display if its not the same as `required`
    UpdateProgress = function(self, current, required, total)
        if not self.ShowProgress then return end

        local progress
        if self.PercentProgress then
            if not total or total == required then
                progress = string.format('(%s%%)', math.ceil(current / required * 100))
            else
                local percentRequired = math.ceil(required / total * 100)
                progress = string.format('(%s%%/%s%%)', math.floor(current / total * 100), percentRequired)
            end
        else
            progress = string.format('(%d/%d)', current, required)
        end

        UpdateObjective(self.Title, 'Progress', progress, self.Tag)
    end,

    ---Called when objective progress changes, updates the UI and runs progress callbacks
    ---@param self Objective
    ---@param current number
    ---@param required number
    ---@param total? integer
    OnProgress = function(self, current, required, total)
        if not self.Active then return end

        self:UpdateProgress(current, required, total)

        for _, v in ipairs(self.ProgressCallbacks) do
            v(current, required)
        end
    end,

    ---Dont override these if you want notification. Call Add???Callback intead
    ---@param self Objective
    ---@param success boolean
    ---@param data? any
    OnResult = function(self, success, data)
        if not self.Active then return end

        self.Active = false
        self.Complete = success

        local resultStr
        if success then
            resultStr = 'complete'
        else
            resultStr = 'failed'
        end

        UpdateObjective(self.Title, 'complete', resultStr, self.Tag)

        for _, v in pairs(self.Decals) do
            v:Destroy()
        end

        for _, v in pairs(self.UnitMarkers) do
            v:Destroy()
        end

        -- Revert strategic icons
        for _, v in pairs(self.IconOverrides) do
            if not v:BeenDestroyed() then
                v:SetStrategicUnderlay("")
            end
        end

        for _, v in pairs(self.VizMarkers) do
            v:Destroy()
        end

        for _, v in pairs(self.PositionUpdateThreads) do
            v:Destroy()
        end

        if self.Timer then
            self:DestroyTimer()
        end

        for _, v in ipairs(self.ResultCallbacks) do
            v(success, data)
        end

        self.Decals = nil
        self.UnitMarkers = nil
        self.IconOverrides = nil
        self.VizMarkers = nil
        self.PositionUpdateThreads = nil
        self.ResultCallbacks = nil
        self.ProgressCallbacks = nil
    end,

    ---Call this to manually end the objective
    ---@param self Objective
    ---@param success boolean
    ManualResult = function(self, success)
        self:OnResult(success)
    end,

    ---Creates a timer that is end the objective when expired.
    ---@param self Objective
    ---@param time integer In seconds
    ---@param expireResult? ObjectiveExpireResult Defaults to `failed`
    AddTimer = function(self, time, expireResult)
        if self.Timer then return end

        local function onTick(newTime)
            UpdateObjective(self.Title, 'timer', {Time = newTime}, self.Tag)
        end

        local function onExpired()
            self:OnResult(expireResult == 'complete')
        end

        self.Timer = Triggers.CreateTimerTrigger(onExpired, time, nil, true, onTick)
    end,

    ---Cancels the timer running on the objective
    ---
    ---If called before the timer runs out, the timer will just be removed without ending the objective.
    ---@param self Objective
    DestroyTimer = function(self)
        if not self.Timer then return end

        Sync.ObjectiveTimer = 0
        self.Timer:Destroy()
        self.Timer = nil
    end,

    ---Creates a new visual marker that is destroyed when objective ends.
    ---@param self Objective
    ---@param x number
    ---@param z number
    ---@param radius number
    ---@param lifetime? number In seconds, defaults to `-1` infinite
    ---@return VizMarker
    CreateVisualMarker = function(self, x, z, radius, lifetime)
        lifetime = lifetime or -1
        local specs = {
            X = x,
            Z = z,
            Radius = radius,
            LifeTime = lifetime,
            Omni = false,
            Vision = true,
            Army = getPlayerArmy(),
        }
        ---@type VizMarker
        local vizmarker = VizMarker(specs)
        if lifetime > 0 then
            table.insert(self.VizMarkers, vizmarker)
        end

        return vizmarker
    end,

    ---Creates a marker that attached to the `unit` and provides `Vision` intel.
    ---
    ---This marker is destroyed when the objective ends or when the unit dies.
    ---@param self Objective
    ---@param unit Unit
    ---@param radius? number Defaults to 8
    ---@param lifetime? number In seconds, defaults to `-1` infinite
    AddUnitVisualMarker = function(self, unit, radius, lifetime)
        local pos = unit:GetPosition()
        radius = radius or 8
        local vizmarker = self:CreateVisualMarker(pos[1], pos[3], radius, lifetime)
        unit.Trash:Add(vizmarker)
        vizmarker:AttachBoneTo(-1, unit, -1)
    end,

    ---Creates a maker that provides `Visual` intel over specified `area`.
    ---
    ---This marker is destroyed when the objective ends.
    ---@param self Objective
    ---@param area string
    ---@param lifetime? number In seconds, defaults to `-1` infinite
    AddAreaVisualMarker = function(self, area, lifetime)
        local rect = ScenarioUtils.AreaToRect(area)
        local width = rect.x1 - rect.x0
        local height = rect.y1 - rect.y0
        local x = rect.x0 + width / 2
        local z = rect.y0 + height / 2
        local radius = math.max(width, height)

        self:CreateVisualMarker(x, z, radius, lifetime)
    end,

    GetTargetDestroyedNotifyCallback = function(self, targetTag)
        return function()
            if not self.Active then
                return
            end

            if self.PositionUpdateThreads[targetTag] then
                KillThread(self.PositionUpdateThreads[targetTag])
                self.PositionUpdateThreads[targetTag] = nil
            end

            -- When the blip is destroyed, tell objectives we dont
            -- have a blip anymore. This doesnt necessarily mean the
            -- unit is killed, we simply lost the blip.
            local data = {
                Type = 'Position',
                Value = nil,
                BlueprintId = nil,
                TargetTag = targetTag,
            }
            UpdateObjective(self.Title, 'Target', data, self.Tag)
        end
    end,

    ---Takes a unit that is an objective target and uses its recon detect
    ---event to notify the objectives that we have a blip for the unit.
    ---@param self Objective
    ---@param unit Unit
    ---@param targetTag integer
    SetupNotify = function(self, unit, targetTag)
        ---Add a detectedBy callback to notify the user layer when our recon on the target comes in and out.
        ---@param cbunit Unit
        ---@param armyindex integer
        local detectedByCB = function(cbunit, armyindex)
            if not self.Active or armyindex ~= getPlayerArmy() then
                return
            end

            -- get the blip that is associated with the unit
            local blip = cbunit:GetBlip(armyindex)
            if not blip then return end

            -- Only provide the target position to the user layer if
            -- the blip IsSeenEver() (i.e. has been identified).
            self.PositionUpdateThreads[targetTag] = ForkThread(function()
                while self.Active do
                    WaitTicks(10)
                    if blip:BeenDestroyed() then
                        return
                    end

                    if blip:IsSeenEver(armyindex) then
                        local data = {
                            Type = 'Position',
                            Value = blip:GetPosition(),
                            BlueprintId = blip:GetBlueprint().BlueprintId,
                            TargetTag = targetTag
                        }
                        UpdateObjective(self.Title, 'Target', data, self.Tag)

                        -- If it's not mobile we can exit the thread since
                        -- the blip won't move.
                        if not unit.Dead and not unit:BeenDestroyed() and not EntityCategoryContains(categories.MOBILE, unit) then
                            return
                        end
                    end
                end
            end)

            blip:AddDestroyHook(self:GetTargetDestroyedNotifyCallback(targetTag))
        end
        -- When the unit is detected by an army, have it call this callback
        -- function (defined above)
        unit:AddDetectedByHook(detectedByCB)

        -- See if we can detect the unit right now
        local blip = unit:GetBlip(getPlayerArmy())
        if blip then
            detectedByCB(unit, getPlayerArmy())
        end
    end,

    ---Take an objective target unit that is owned by the focus army
    ---Info passed to user layer to handle zoom to button and chiclet image
    ---@param self Objective
    ---@param unit Unit
    ---@param targetTag integer
    SetupFocusNotify = function(self, unit, targetTag)
        self.PositionUpdateThreads[targetTag] = ForkThread(function()
            while self.Active do
                if unit:BeenDestroyed() then
                    return
                end

                local data = {
                    Type = 'Position',
                    Value = unit:GetPosition(),
                    BlueprintId = unit:GetBlueprint().BlueprintId,
                    TargetTag = targetTag
                }
                UpdateObjective(self.Title, 'Target', data, self.Tag)

                -- If it's not mobile we can exit the thread since the unit won't move.
                if not unit.Dead and not unit:BeenDestroyed() and not EntityCategoryContains(categories.MOBILE, unit) then
                    return
                end

                WaitTicks(10)
            end
        end)

        Triggers.CreateUnitDeathTrigger(self:GetTargetDestroyedNotifyCallback(), unit)
    end,

    ---@param self Objective
    ---@param unit Unit
    ---@param mark? boolean Adds strategic icon overlay and yellow arrow attached to the unit. Defaults to `true`
    ---@param flashVisible? boolean Reveals the area through FoW
    ---@param alwaysVisible? boolean Creates a visual marker over the area
    AddUnitTarget = function(self, unit, mark, flashVisible, alwaysVisible)
        self.NextTargetTag = self.NextTargetTag + 1

        if unit.Army == getPlayerArmy() then
            self:SetupFocusNotify(unit, self.NextTargetTag)
        else
            self:SetupNotify(unit, self.NextTargetTag)
        end

        if mark then
            if self.Type == 'primary' then
                unit:SetStrategicUnderlay('icon_objective_primary')
            elseif self.Type == 'secondary' then
                unit:SetStrategicUnderlay('icon_objective_secondary')
            elseif self.Type == 'bonus' then
                unit:SetStrategicUnderlay('icon_objective_bonus')
            end
            table.insert(self.IconOverrides, unit)

            -- Bouncing arrow on air units look weird, especially when falling down from the sky
            if not EntityCategoryContains(mobileAirCategories, unit) then
                local marker = ObjectiveArrow({AttachTo = unit})
                table.insert(self.UnitMarkers, marker)
            end
        end

        if flashVisible then
            self:AddUnitVisualMarker(unit, 2, 1)
        end

        if alwaysVisible then
            self:AddUnitVisualMarker(unit)
        end
    end,

    ---@param self Objective
    ---@param unit Unit
    ---@deprecated
    AddBasicUnitTarget = function(self, unit)
        self:AddUnitTarget(unit, true)
    end,

    ---@param self Objective
    ---@param area string
    ---@param decal? boolean Creates objectvie decal
    ---@param flashVisible? boolean Reveals the area through FoW
    ---@param alwaysVisible? boolean Creates a visual marker over the area
    AddAreaTarget = function(self, area, decal, flashVisible, alwaysVisible)
        self.NextTargetTag = self.NextTargetTag + 1
        local rect = ScenarioUtils.AreaToRect(area)

        local data = {
            Type = 'Area',
            Value = rect,
            TargetTag = self.NextTargetTag
        }
        UpdateObjective(self.Title, 'Target', data, self.Tag)

        if decal then
            local w = rect.x1 - rect.x0
            local h = rect.y1 - rect.y0
            local x = rect.x0 + (w / 2.0)
            local z = rect.y0 + (h / 2.0)
            self.Decals[area] = CreateObjectiveDecal(x, z, w, h)
        end
        if flashVisible then
            self:AddAreaVisualMarker(area, 0.01)
        end
        if alwaysVisible then
            self:AddAreaVisualMarker(area)
        end
    end,

    ---Adds a objective target and set up units / area specified
    ---@param self Objective
    ---@param target ObjectiveTarget
    AddTarget = function(self, target)
        local markArea = target.MarkArea
        -- Mark the units unless MarkUnits == false
        local markUnits = target.MarkUnits == nil or target.MarkUnits
        local flashVisible = target.FlashVisible
        local alwaysVisible = target.AlwaysVisible

        if target.Area then
            self:AddAreaTarget(target.Area, markArea, flashVisible, alwaysVisible)
        end

        if target.Areas then
            for _, area in pairs(target.Areas) do
                self:AddAreaTarget(area, markArea, flashVisible, alwaysVisible)
            end
        end

        if target.Requirements then
            for _, requirement in pairs(target.Requirements) do
                self:AddAreaTarget(requirement.Area, markArea, flashVisible, alwaysVisible)
            end
        end

        if target.Units then
            for _, unit in pairs(target.Units) do
                if unit.Dead then continue end

                self:AddUnitTarget(unit, markUnits, flashVisible, alwaysVisible)
            end
        end

        if target.Unit and not target.Unit.Dead then
            self:AddUnitTarget(target.Unit, markUnits, flashVisible, alwaysVisible)
        end

        if target.Timer then
            self:AddTimer(target.Timer, target.ExpireResult)
        end

        -- Hide progress only when it's specifically requested
        if target.ShowProgress == false then
            self.ShowProgress = false
        end

        if target.PercentProgress then
            self.PercentProgress = target.PercentProgress
        end
    end,
}

-- Adds and tracks an objective, should not be used directly
---@param type ObjectiveType
---@param complete ObjectiveStatus
---@param title string
---@param description string
---@param actionImage? string Path to texture '/textures/ui/common/missions/mission1.dds'
---@param target? ObjectiveTarget
---@param isLoading? boolean Are we loading a saved game?
---@param loadedTag? string If IsLoading is specified, whats the tag?
---@return Objective
function AddObjective(type, complete, title, description, actionImage, target, isLoading, loadedTag)
    if not Sync.ObjectivesTable then
        Sync.ObjectivesTable = {}
    end

    local hidden = target and target.Hidden
    local tag
    if isLoading then
        tag = loadedTag --[[@as string]]
    else
        tag = 'Objective' .. objNum
        objNum = objNum + 1
        table.insert(SavedList, {
            AddArgs = {type, complete, title, description, actionImage, target, true, tag, n = 8},
            Tag = tag
        })
    end

    local objective = Objective(tag, type, complete, title, description, hidden, target)

    local userTargets = {}
    if target then
        if target.ShowFaction then
            target.Image = targetFactionIcons[target.ShowFaction]
        end

        if target.Requirements then
            for _, req in ipairs(target.Requirements) do
                if req.Area then
                    table.insert(userTargets, {Type = 'Area', Value = ScenarioUtils.AreaToRect(req.Area)})
                end
            end
        elseif target.Timer then
            userTargets = {Type = 'Timer', Time = target.Timer}
        end

        if target.Category then
            local bps = EntityCategoryGetUnitList(target.Category)
            if not table.empty(bps) then
                table.insert(userTargets, {Type = 'Blueprint', BlueprintId = bps[1]})
            end
        end
    end

    local userObjectiveData = {
        tag = tag,
        type = type,
        complete = complete,
        hidden = hidden,
        title = title,
        description = description,
        actionImage = actionImage,
        targetImage = target and target.Image,
        progress = "",
        targets = userTargets,
        loading = isLoading,
        StartTime = objective.SimStartTime,
    }

    Sync.ObjectivesTable[tag] = userObjectiveData

    return objective
end

function OnPostLoad()
    for _, v in ipairs(SavedList) do
        if v.AddArgs then
            AddObjective(unpack(v.AddArgs))
        elseif v.UpdateArgs then
            UpdateObjective(unpack(v.UpdateArgs))
        elseif v.DeleteArgs then
            DeleteObjective(v.DeleteArgs, true)
        end
    end
end

---Creates markers that satisfy the objective when they are all inside of the camera viewport
---@param Type ObjectiveType
---@param Complete ObjectiveStatus
---@param Title string
---@param Description string
---@param Target Vector[] table of position tables where markers will be created. {{x1, y1, z1}, {x2, y2, z2}} format
---@return Objective
function Camera(Type, Complete, Title, Description, Target)
    local required = table.getn(Target)
    local current = 0
    local objective = AddObjective(Type, Complete, Title, Description, nil, Target)

    local RemoveMarker = function(mark)
        mark:Destroy()
        current = current + 1

        objective:OnProgress(current, required)

        if current == required then
            objective:OnResult(true)
        end
    end

    for _, v in pairs(Target) do
        local newMark = import("/lua/simcameramarkers.lua").AddCameraMarker(v)
        newMark:AddCallback(RemoveMarker)
    end

    objective:UpdateProgress(current, required)

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
    local image = GetActionIcon('Group')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local lastReqsMet = -1

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
                                if not unit.Marked and Target.MarkUnits then
                                    unit.Marked = true
                                    objective:AddUnitTarget(unit, true)
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
                objective:OnProgress(reqsMet, totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective:OnResult(true)
                return
            end
            WaitTicks(10)
        end
    end
    objective:UpdateProgress(0, 0)
    ForkThread(WatchGroups, Target.Requirements)

    return objective
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
    local current = 0
    local total = table.getn(Target.Units)
    local required = math.min(Target.NumRequired or total, total)

    local image = GetActionIcon('Kill')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.OnUnitKilled = function(unit)
        if not objective.Active then return end

        current = current + 1
        objective:OnProgress(current, required)

        if current >= required then
            objective:OnResult(true, unit)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then return end

        OnUnitGivenBase(objective, Target, unit, newUnit, (Target.MarkUnits == nil) or Target.MarkUnits)
        CreateTriggers(newUnit, objective, true) -- Reclaiming is same as killing for our purposes
    end

    for _, unit in Target.Units do
        if not unit.Dead then
            CreateTriggers(unit, objective, true) -- Reclaiming is same as killing for our purposes
        else
            objective.OnUnitKilled(unit)
        end
    end

    objective:UpdateProgress(current, required)

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
    local current = 0
    local total = table.getn(Target.Units)
    local required = Target.NumRequired or total
    local returnUnits = {}

    local image = GetActionIcon('Capture')
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.OnUnitCaptured = function(unit, captor)
        table.insert(returnUnits, unit)
        if not objective.Active then
            return
        end

        current = current + 1
        objective:OnProgress(current, required)
        if current >= required then
            objective:OnResult(true, returnUnits)
        end
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        total = total - 1
        if total < required then
            objective:OnResult(false)
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
            CreateTriggers(unit, objective, true) -- Reclaiming is same as killing for our purposes
        else
            objective.OnUnitKilled(unit)
        end
    end

    objective:UpdateProgress(current, required)

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

    -- Keep track of captured units so subsequent kills dont get counted
    local captured = {}

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        for _, v in captured do
            if v == unit then
                return
            end
        end

        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, Total, NumRequired)
        if KilledOrCaptured == NumRequired then
            objective:OnResult(true, unit)
        end
    end

    objective.OnUnitCaptured = function(unit)
        if not objective.Active then
            return
        end
        table.insert(captured, unit)
        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, Total, NumRequired)
        if KilledOrCaptured == NumRequired then
            objective:OnResult(true, unit)
        end
    end

    objective.OnUnitReclaimed = function(unit)
        if not objective.Active then
            return
        end

        KilledOrCaptured = KilledOrCaptured + 1
        objective:OnProgress(KilledOrCaptured, Total, NumRequired)
        if KilledOrCaptured == NumRequired then
            objective:OnResult(true, unit)
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
            CreateTriggers(unit, objective)
        else
            objective.OnUnitKilled(unit)
        end
    end
    objective:UpdateProgress(KilledOrCaptured, Total, NumRequired)

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
    local current = 0
    local required = table.getn(Target.Units)

    local image = GetActionIcon("Reclaim")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.OnUnitReclaimed  = function(unit)
        if not objective.Active then
            return
        end

        current = current + 1
        objective:OnProgress(current, required)
        if current == required then
            objective:OnResult(true)
        end
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end
        objective:OnResult(false)
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
        CreateTriggers(unit, objective)
    end

    objective:UpdateProgress(current, required)

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
    local current = 0
    local required = table.getn(Target.Wrecks)

    local image = GetActionIcon("Reclaim")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    local function OnPropKilled(unit)
        objective:OnResult(false)
    end

    local function OnPropReclaimed(unit)
        if not objective.Active then
            return
        end

        current = current + 1
        objective:OnProgress(current, required)
        if current == required then
            objective:OnResult(true)
        end
    end

    for _, wreck in Target.Wrecks do
        Triggers.CreatePropReclaimedTrigger(OnPropReclaimed, wreck)
        Triggers.CreatePropKilledTrigger(OnPropKilled, wreck)
    end

    objective:UpdateProgress(current, required)

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
    local current = 0
    local required = table.getn(Target.Units)
    local isLocated = {}

    local image = GetActionIcon("Locate")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    objective.OnUnitLocated = function(unit)
        if isLocated[unit] or not objective.Active then
            return
        end
        current = current + 1
        isLocated[unit] = true
        objective:OnProgress(current, required)
        if current == required then
            objective:OnResult(true)
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

    objective:UpdateProgress(current, required)

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
    local required = Target.NumRequired or total
    local current = 0

    ---@param units Unit[]
    ---@param rect Rectangle
    local function WatchArea(units, rect)
        while objective.Active do
            local cnt = 0
            for _, unit in pairs(units) do
                if not unit.Dead and ScenarioUtils.InRect(unit:GetPosition(), rect) then
                    cnt = cnt + 1
                end
            end

            if cnt ~= current then
                current = cnt
                objective:OnProgress(current, required)
            end

            if cnt >= required then
                objective:OnResult(true)
                return
            end
            WaitTicks(5)
        end
    end

    local rect = ScenarioUtils.AreaToRect(Target.Area)
    local watchThread = ForkThread(WatchArea, Target.Units, rect)

    objective.OnUnitKilled = function(unit)
        if not objective.Active then return end

        total = total - 1

        if total < required then
            objective:OnResult(false, unit)
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

    objective:UpdateProgress(current, required)

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

    local function WatchArea(requirements, markUnits)
        local totalReqs = table.getn(requirements)
        while objective.Active do
            local reqsMet = 0

            for _, requirement in pairs(requirements) do
                local armiesSpecified = requirement.ArmiesSpecified
                local armiesList = requirement.ArmiesList
                local cnt = 0
                local units = GetUnitsInRect(requirement.Rect)
                if not units then continue end

                for _, unit in pairs(units) do
                    if unit.Dead or unit:IsBeingBuilt() or (armiesSpecified and not armiesList[unit.Army]) or not EntityCategoryContains(requirement.Category, unit) then
                        continue
                    end

                    if not unit.Marked and markUnits then
                        unit.Marked = true
                        objective:AddUnitTarget(unit, true)
                    end
                    cnt = cnt + 1
                end

                if requirement.CompareFunc(cnt, requirement.Value) then
                    reqsMet = reqsMet + 1
                end
            end

            if lastReqsMet ~= reqsMet then
                objective:OnProgress(reqsMet, totalReqs)
                lastReqsMet = reqsMet
            end

            if reqsMet == totalReqs then
                objective:OnResult(true)
                return
            end
            WaitTicks(10)
        end
    end

    for _, requirement in pairs(Target.Requirements) do
        requirement.Rect = ScenarioUtils.AreaToRect(requirement.Area)
        requirement.ArmiesList = makeArmyList(requirement)
        requirement.ArmiesSpecified = not table.empty(requirement.ArmiesList)
        requirement.CompareFunc = GetCompareFunc(requirement.CompareOp)
    end

    objective:UpdateProgress(0, table.getsize(Target.Requirements))
    ForkThread(WatchArea, Target.Requirements, Target.MarkUnits)

    return objective
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
    local armyBrainsList = makeArmyList(Target)

    ---@param statName ArmyStatistic
    ---@param aibrains table<integer, AIBrain>
    ---@param compareFunc fun(a, b): boolean
    ---@param value number
    ---@param category EntityCategory
    local function WatchStat(statName, aibrains, compareFunc, value, category)
        local oldVal

        while objective.Active do
            local testVal = 0

            for _, brain in pairs(aibrains) do
                if category then
                    testVal = testVal + brain:GetBlueprintStat(statName, category)
                else
                    testVal = testVal + brain:GetArmyStat(statName--[[@as AIBrainBlueprintStatEconomy]], value).Value
                end
            end

            if testVal ~= oldVal then
                oldVal = testVal
                objective:OnProgress(testVal, value)
            end

            if compareFunc(testVal, value) then
                objective:OnResult(true)
                return
            end
            WaitTicks(5)
        end
    end

    local op = GetCompareFunc(Target.CompareOp)
    if op then
        ForkThread(WatchStat, Target.StatName, armyBrainsList, op, Target.Value, Target.Category)
    end

    return objective
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
                objective:OnResult(true)
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
    local armyBrainsList = makeArmyList(Target)

    ---@param statName string
    ---@param aibrains table<integer, AIBrain>
    ---@param category EntityCategory
    ---@param compareFunc fun(a, b): boolean
    ---@param value number
    local function WatchStat(statName, aibrains, category, compareFunc, value)
        while objective.Active do
            for _, brain in pairs(aibrains) do
                local unitsInCategory = brain:GetListOfUnits(category, false)
                if unitsInCategory then
                    for _, unit in pairs(unitsInCategory) do
                        if compareFunc(unit:GetStat(statName, value).Value, value) then
                            objective:OnResult(true)
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
---@param Target ObjectiveTarget    # Objective data, see the description
---@return Objective
function Protect(Type, Complete, Title, Description, Target)
    local image = GetActionIcon("Protect")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)
    local current = table.getn(Target.Units)
    local total = current
    local required = Target.NumRequired or current

    if not Target.ExpireResult then
        Target.ExpireResult = "complete"
    end

    objective.OnUnitKilled = function(unit)
        if not objective.Active then
            return
        end

        current = current - 1
        objective:OnProgress(current, required, total)

        if current < required then
            objective:OnResult(false, unit)
        end
    end

    objective.OnUnitGiven = function(unit, newUnit)
        if not objective.Active then
            return
        end
        OnUnitGivenBase(objective, Target, unit, newUnit, false)
        CreateTriggers(newUnit, objective, true)
    end

    for _, unit in pairs(Target.Units) do
        if not unit.Dead then
            CreateTriggers(unit, objective, true)
        else
            objective.OnUnitKilled(unit)
        end
    end

    if Target.ShowProgress then
        objective:UpdateProgress(current, required)
    elseif Target.PercentProgress then
        objective:UpdateProgress(current, required, total)
    end

    return objective
end

---@class ObjectiveTimerTarget
---@field Timer integer In seconds, after which the objective ends with specified `ExpireResult`
---@field ExpireResult? "complete" | "failed" How should the objective end when the timer expires. Defaults to `"failed"`

--- Adds a timer objective that finishes when the time runs out.
---@param Type ObjectiveType          # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus    # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string                # Title of the objective, supports strings with LOC
---@param Description string          # Description of the objective, supports strings with LOC
---@param Target ObjectiveTimerTarget # Objective data, see the description
---@return Objective
function Timer(Type, Complete, Title, Description, Target)
    local image = GetActionIcon("Timer")
    local objective = AddObjective(Type, Complete, Title, Description, image, Target)

    return objective
end

--- Adds an unknown objective that can be specified later by adding target
---@param Type ObjectiveType        # Type of objective, used for the strategic icon in the UI
---@param Complete ObjectiveStatus  # Completion status, usually this is 'incomplete' unless the player already completed it by chance
---@param Title string              # Title of the objective, supports strings with LOC
---@param Description string        # Description of the objective, supports strings with LOC
---@return Objective
function Unknown(Type, Complete, Title, Description)
    local objective = AddObjective(Type, Complete, Title, Description)

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
---@param Target? table             # Objective data, see the description
---@return Objective
function Basic(Type, Complete, Title, Description, Image, Target)
    local objective = AddObjective(Type, Complete, Title, Description, Image, Target)

    return objective
end

-- Tracks completion of any objective added to it. When all or `numRequired` of objectives complete, `callback` is fired.
---@param name? string Defaults to `"ObjectiveGroupX"` where X is the number of unnamed objective groups created so far.
---@param callback? function Function to call when the group is completed.
---@param numRequired? integer Number of objective completed to complete the group. If not provided, all objectives have to be completed.
---@return ObjectiveGroup
function CreateGroup(name, callback, numRequired)
    return ObjectiveGroup(name, callback, numRequired)
end
