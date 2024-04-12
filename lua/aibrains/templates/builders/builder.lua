
-- upvalued for performance
local import = import
local unpack = unpack

local TableDeepCopy = table.deepcopy

---@class AIBuilderCondition
---@field [1] function
---@field [2] table

---@class AIBuilder
---@field BuilderConditions AIBuilderCondition[]       # Converted conditions from the builder template
---@field BuilderData AIBuilderData                            # Converted data from the builder template
---@field DisabledUntilTick number      # Allows us to temporarily disable builders
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



        -- copy over and convert conditions
        ---@type AIBuilderCondition[]
        self.BuilderConditions = template.BuilderConditions or { }

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
    ---@param platoon AIPlatoon
    ---@param tick number
    ---@return boolean
    EvaluateBuilderConditions = function(self, brain, base, platoon, tick)
        if self.DisabledUntilTick > tick then
            return false
        else
            local status = true
            for _, condition in self.BuilderConditions do
                local func = condition[1]
                local input = condition[2]
                if input then
                    status = status and func(brain, base, platoon, unpack(input))
                else
                    status = status and func(brain, base, platoon)
                end
            end

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
