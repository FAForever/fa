---@declare-global

---@class AIBuilderCondition
---@field [1] FileReference
---@field [2] FunctionReference
---@field [3] FunctionParameters

---@alias AIBuilderType 'Any' | 'Land' | 'Air' | 'Sea' | 'Gate' 

---@class AIBuilderTemplate
---@field Conditions AIBuilderCondition[]
---@field Data table
---@field Identifier string
---@field Type AIBuilderType
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
    if not spec.Identifier then 
        WARN('Builder excluded for missing field "Identifier": ', reprs(spec))
        return
    end

    -- should have a priority
    if not spec.Priority then 
        WARN('Builder excluded for missing field "Priority": ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.Type then 
        WARN('Builder excluded for missing field "Type": ', reprs(spec))
        return
    end

    -- default value
    if not spec.Data then
        spec.Data = {}
    end

    -- overwrite any existing definitions
    if AIBuilderTemplates[spec.Identifier] then
        LOG(string.format('Overwriting builder: %s', spec.Identifier))
        for k,v in spec do
            AIBuilderTemplates[spec.Identifier][k] = v
        end

    -- first one, we become the definition
    else
        AIBuilderTemplates[spec.Identifier] = spec
    end

    return spec.Identifier
end
