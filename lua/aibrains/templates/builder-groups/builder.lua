
-- upvalued for performance
local import = import
local unpack = unpack

local TableDeepCopy = table.deepcopy

---@class AIBuilderCondition
---@field [1] function
---@field [2] table

---@class AIBuilder
---@field Conditions AIBuilderCondition[]       # Converted conditions from the builder template
---@field Data table                            # Converted data from the builder template
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
        self.Priority = template.Priority

        -- cache evaluation
        self.EvaluatedAtTick = -1
        self.EvaluatedStatus = false

        -- copy over and convert conditions
        ---@type AIBuilderCondition[]
        local conditions = { }
        if template.Conditions then
            for k, data in template.Conditions do
                -- pre-import the function
                ---@type function
                local func = import(data[1])[2]

                -- re-create the condition
                conditions[k] = { func, data[3] }
            end
        end

        self.Conditions = conditions

        -- TODO PERFORMANCE: is this _really _ required here?
        -- copy over and convert builder data
        if template.Data then
            local data = TableDeepCopy(template.Data)
            data.Brain = brain
            data.Base = base
            self.Data = data
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
            for _, condition in self.Conditions do
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
    GetPriority = function(self)
        return self.Priority
    end,

    --- Retrieves the builder template
    ---@param self AIBuilder
    ---@return AIBuilderTemplate
    GetTemplate = function(self)
        return self.Template
    end,

    --- Retrieves the (converted) builder data
    ---@param self AIBuilder
    ---@return AIBuilderTemplate
    GetData = function(self)
        return self.Data
    end,

    --- Retrieves the identifier of the builder template
    ---@param self AIBuilder
    ---@return string
    GetIdentifier = function(self)
        return self.Template.Identifier
    end,

    ---- Retrieves the type of the builder template
    ---@param self AIBuilder
    ---@return BuilderType
    GetType = function(self)
        return self.Template.Type
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
