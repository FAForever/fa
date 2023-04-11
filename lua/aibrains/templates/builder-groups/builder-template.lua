---@declare-global

---@class AIBuilderCondition
---@field [1] FileReference
---@field [2] FunctionReference
---@field [3] FunctionParameters

---@alias AIBuilderType 'Any' | 'Land' | 'Air' | 'Sea' | 'Gate' 

---@class AIBuilderTemplate
---@field BuilderConditions AIBuilderCondition[]
---@field BuilderData table
---@field BuilderName string
---@field BuilderType AIBuilderType
---@field Priority number
---@field PriorityFunction fun(brain: AIBrain, base: AIBase)
---@field PlatoonTemplate? string
---@field PlatoonAIFunction? { [1]: FileName, [2]: string }
---@field PlatoonAIPlan? string
---@field PlatoonAddPlans? string[]
---@field InstanceCount number

-- Global list of all builders found in the game
---@type table<string, AIBuilderTemplate>
AIBuilderTemplates = {}

--- Register a base builder template, or override an existing base builder template
---@param spec AIBuilderTemplate
---@return string
AIBuilderTemplate = function(spec)
    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.BuilderName then 
        WARN('Builder excluded for missing field "BuilderName": ', reprs(spec))
        return
    end

    -- should have a priority
    if not spec.Priority then 
        WARN('Builder excluded for missing field "Priority": ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.BuilderType then 
        WARN('Builder excluded for missing field "BuilderType": ', reprs(spec))
        return
    end

    -- default value
    if not spec.BuilderData then
        spec.BuilderData = {}
    end

    -- overwrite any existing definitions
    if AIBuilderTemplates[spec.BuilderName] then
        LOG(string.format('Overwriting builder: %s', spec.BuilderName))
        for k,v in spec do
            AIBuilderTemplates[spec.BuilderName][k] = v
        end

    -- first one, we become the definition
    else
        AIBuilderTemplates[spec.BuilderName] = spec
    end

    return spec.BuilderName
end
