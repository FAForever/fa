local pairs = pairs
local tableGetSize = table.getsize
local ForkThread = ForkThread
local WaitSeconds, WaitTicks = WaitSeconds, WaitTicks

local nextId = 1

---@alias ObjectiveGroupResultCallback fun(result: boolean)

---Tracks a group of objectives and calls the callback when the group has completed successfully or failed.
---@class ObjectiveGroup
---@field Name string
---@field Objectives table<string, Objective>
---@field NumRequired? integer
---@field OnComplete? ObjectiveGroupResultCallback
---@overload fun(name?: string, callback?: ObjectiveGroupResultCallback, numRequired?: integer): ObjectiveGroup
local OG = {
    ---Flag to indicate the objective group is in progress 
    Active = true,
    ---Number of objectives that have completed successfully.
    NumCompleted = 0,
    ---Number of objectives that have failed.
    NumFailed = 0,
    ---Delay in seconds before the OnComplete callback is called.
    ResultDelay = 0,
}
---@param name string
---@param callback? ObjectiveGroupResultCallback
---@param numRequired? integer
---@protected
function OG:__init(name, callback, numRequired)
    if not name then
        name = "ObjectiveGroup" .. nextId
        nextId = nextId + 1
    end

    self.Name = name
    if callback then
        self.OnComplete = callback
    end
    if numRequired then
        self.NumRequired = numRequired
    end
    self.Objectives = {}
end
---Throws error if the objective group isnt active anymore.
---@protected
function OG:CheckActive()
    if not self.Active then
        error(string.format("ObjectiveGroup: `%s` is no longer active.", self.Name), 3)
    end
end
---@param objective Objective
---@param result boolean Result of the finished objective
---@param data any Any data passed from the objective result
---@protected
function OG:OnObjectiveResult(objective, result, data)
    if not (self.Active and self.Objectives[objective.Tag]) then
        return
    end

    if result then
        self.NumCompleted = self.NumCompleted + 1
    else
        self.NumFailed = self.NumFailed + 1
    end

    local total = tableGetSize(self.Objectives)
    local required = self.NumRequired or total

    LOG(string.format("ObjectiveGroup: `%s` OnProgress (%d/%d)", self.Name, self.NumCompleted, required))

    -- Check if we've finished enough objectives
    if self.NumCompleted >= required then
        self:OnResult(true)
    -- Not all objectives have not been added yet.
    elseif total < required then
        return
    -- Check if there's enough objectives left.
    elseif total - self.NumFailed < required then
        self:OnResult(false)
    end
end
---Adds a new objective to track to this group. It does NOT change the number of required objective (if it was specified).
---
---It is possible to add objective that is no longer active.
---@param objective Objective
function OG:AddObjective(objective)
    self:CheckActive()

    if self.Objectives[objective.Tag] then
        error(string.format("ObjectiveGroup: `%s` trying to add duplicate objective: %s - %s", self.Name, objective.Tag, objective.Title), 2)
    end

    self.Objectives[objective.Tag] = objective

    if objective.Active then
        objective:AddResultCallback(function(result, data)
            self:OnObjectiveResult(objective, result, data)
        end)
    else
        self:OnObjectiveResult(objective, objective.Complete)
    end
end
---Removes the objective from this group. It does NOT change the number of required objective (if it was specified).
---@param objective Objective
function OG:RemoveObjective(objective)
    if not self.Objectives[objective.Tag] or not objective.Active then
        WARN(string.format("ObjectiveGroup: `%s`: Failed to remove untracked or inactive objective: %s - %s", self.Name, objective.Tag, objective.Title))
        return
    end

    self.Objectives[objective.Tag] = nil
end
---@param result boolean
---@protected
function OG:OnResult(result)
    if not self.Active then return end

    self.Active = false
    if not self.OnComplete then return end
    -- Delay the callback by `ResultDelay` or at least one tick, this ensures that the individual objective's callbacks are always fired first
    ForkThread(function()
        if self.ResultDelay > 0 then
            WaitSeconds(self.ResultDelay)
        else
            WaitTicks(1)
        end
        self.OnComplete(result)
    end)
end
---Manually ends all objectives in the group
---@param success boolean
function OG:ManualResult(success)
    self:CheckActive()

    for _, objective in pairs(self.Objectives) do
        if objective.Active then
            objective:ManualResult(success)
        end
    end
end

ObjectiveGroup = ClassSimple(OG)
