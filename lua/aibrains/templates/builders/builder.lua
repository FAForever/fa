
-- upvalued for performance
local import = import
local unpack = unpack

local TableDeepCopy = table.deepcopy

---@class AIBuilderCondition
---@field [1] function
---@field [2] table

---@class AIBuilder
---@field BuilderConditions AIBuilderCondition[]       # Converted conditions from the builder template
---@field BuilderData table                            # Converted data from the builder template
---@field DisabledUntilTick number      # Allows us to temporarily disable builders
---@field EvaluatedAtTick number        # Allows us to cache evaluation results
---@field EvaluatedStatus boolean       # Allows us to cache evaluation results
---@field Priority number               # Priority of the builder, used for sorting
---@field Template AIBuilderTemplate    # Template that this builder originates from
AIBuilder = ClassSimple {

    ---@param self Builder
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param template AIBuilderTemplate
    ---@param locationType string
    Create = function(self, brain, base, template, locationType)
        self.Template = template
        self.Priority = template.BuilderPriority

        -- cache evaluation
        self.EvaluatedAtTick = -1
        self.EvaluatedStatus = false

        -- copy over and convert conditions
        ---@type AIBuilderCondition[]
        local conditions = { }
        self.BuilderConditions = conditions
        if template.BuilderConditions then
            for k, data in template.BuilderConditions do
                -- pre-import the function
                ---@type function
                local func = import(data[1])[data[2]]

                -- re-create the condition
                conditions[k] = { func, data[3] }
            end
        end

        -- TODO PERFORMANCE: is this _really _ required here?
        -- copy over and convert builder data
        if template.BuilderData then
            local data = TableDeepCopy(template.BuilderData)
            data.Brain = brain
            data.Base = base
            self.BuilderData = data
        end
    end,

    --------------------------------------------------------------------------------------
    -- builder interface

    --- Evaluates the builder conditions. This process is cached: if the builder has been 
    --- evaluated in the last five ticks then the cached result is returned.
    ---@param self AIBuilder
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param tick number
    ---@return boolean
    EvaluateBuilderConditions = function(self, brain, base, tick)
        if self.DisabledUntilTick > tick then
            return false
        elseif self.EvaluatedAtTick > tick - 5 then
            return self.EvaluatedStatus
        else
            local status = true
            for _, condition in self.BuilderConditions do
                if not condition[1](brain, base, unpack(condition[2])) then
                    status = false
                    break
                end
            end

            self.EvaluatedAtTick = tick
            self.EvaluatedStatus = status
            return status
        end
    end,

    --- Evaluates the builder priority. Returns true when the priority is adjusted
    ---@param self AIBuilder
    ---@return boolean          # flag to indicate priority changed
    EvaluateBuilderPriority = function(self, brain, base)
        local priorityFunction = self.Template.PriorityFunction
        if priorityFunction then
            local priority = priorityFunction(brain, base)
            if priority != self.Priority then
                self.Priority = priority
                return true
            end
        end

        return false
    end,

    --------------------------------------------------------------------------------------
    -- properties

    --- Retrieves the priority
    ---@param self AIBuilder
    ---@return number
    GetBuilderPriority = function(self)
        return self.Priority
    end,

    --- Retrieves the builder template
    ---@param self AIBuilder
    ---@return AIBuilderTemplate
    GetBuilderTemplate = function(self)
        return self.Template
    end,

    --- Retrieves the (converted) builder data
    ---@param self AIBuilder
    ---@return AIBuilderTemplate
    GetBuilderData = function(self)
        return self.BuilderData
    end,

    --- Retrieves the identifier of the builder template
    ---@param self AIBuilder
    ---@return string
    GetBuilderName = function(self)
        return self.Template.BuilderName
    end,

    ---- Retrieves the type of the builder template
    ---@param self AIBuilder
    ---@return BuilderType
    GetBuilderType = function(self)
        return self.Template.BuilderType
    end,

    --- Retrieves the identifier of the platoon template from the builder template
    ---@param self AIBuilder
    ---@return string
    GetPlatoonTemplate = function(self)
        return self.Template.PlatoonTemplate
    end,

    --- Retrieves the platoon AI function from the builder template
    ---@param self AIBuilder
    ---@return {[1]: FileName, [2]: string}?
    GetPlatoonAIFunction = function(self)
        return self.Template.PlatoonAIFunction
    end,

    --- Retrieves the platoon AI plan from the builder template
    ---@param self AIBuilder
    ---@return string?
    GetPlatoonAIPlan = function(self)
        return self.Template.PlatoonAIPlan
    end,
}

---@param brain AIBrain
---@param base AIBase
---@param template AIBuilderTemplate
---@return AIBuilder
function CreateBuilder(brain, base, template)
    local builder = AIBuilder()
    builder:Create(brain, base, template)
    return builder
end
