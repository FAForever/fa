---@declare-global

---@alias BaseBuilderTemplateNamesBase 'ChallengeExpansion' | 'ChallengeMain' | 'ChallengeNaval' | 'NavalExpansionLarge' | 'NavalExpansionSmall' | 'NormalMain' | 'NormalNaval' | 'RushExpansionAirFull' | 'RushExpansionAirSmall' | 'RushExpansionBalancedFull' | 'RushExpansionBalancedSmall' | 'RushExpansionLandFull' | 'RushExpansionLandSmall' | 'RushExpansionNaval' | 'RushMainAir' | 'RushMainBalanced' | 'RushMainLand' | 'RushMainNaval' | 'SetonsCustom' | 'TechExpansion' | 'TechExpansionSmall' | 'TechMain' | 'TechSmallMap' | 'TurtleExpansion' | 'TurtleMain'
---@alias BaseBuilderTemplateNamesSorian 'SorianExpansionAirFull' | 'SorianExpansionBalancedFull' | 'SorianExpansionBalancedSmall' | 'SorianExpansionTurtleFull' | 'SorianExpansionWaterFull' | 'SorianMainAir' | 'SorianMainBalanced' | 'SorianMainRush' | 'SorianMainTurtle' | 'SorianMainWater' | 'SorianNavalExpansionLarge' | 'SorianNavalExpansionSmall' | 
---@alias BaseBuilderTemplateNames BaseBuilderTemplateNamesBase | BaseBuilderTemplateNamesSorian | string

---@alias BaseBuilderTemplate string

---@class BaseBuilderTemplateFactoryCount
---@field Land number
---@field Air number
---@field Sea number

---@class BaseBuilderTemplateEngineerCount
---@field Tech1 number
---@field Tech2 number
---@field Tech3 number
---@field SCU number

---@class BaseBuilderTemplateMassToFactoryValues
---@field T1Value number
---@field T2Value number
---@field T3Value number

---@class BaseBuilderTemplateSettings
---@field FactoryCount BaseBuilderTemplateFactoryCount
---@field EngineersCount BaseBuilderTemplateEngineerCount
---@field MassToFactoryValues BaseBuilderTemplateMassToFactoryValues

---@class BaseBuilderTemplateSpec
---@field BaseTemplateName BaseBuilderTemplateNames
---@field Builders table<BuilderGroupNames>
---@field NonCheatBuilders table<BuilderGroupNames>
---@field BaseSettings BaseBuilderTemplateSettings
---@field ExpansionFunction fun(aiBrain: AIBrain, location: Position, markerType: string)
---@field FirstBaseFunction fun(aiBrain: AIBrain)?

-- Global list of all BaseBuilderTemplates found in the system.
---@type table<string, BaseBuilderTemplateSpec>
BaseBuilderTemplates = {}

--- Register a base builder template, or override an existing base builder template
---@param spec BaseBuilderTemplateSpec
---@return string
BaseBuilderTemplate = function(spec)

    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Base builder template: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.BaseTemplateName then 
        WARN('Base builder template excluded for missing BaseTemplateName in its specification: ', reprs(spec))
        return
    end

    -- should have builders defined
    if not spec.Builders then
        WARN('Base builder template excluded for missing Builders in its specification: ', reprs(spec))
        return
    end

    -- should have an expansion function defined
    if not spec.ExpansionFunction then
        WARN('Base builder template excluded for missing ExpansionFunction in its specification: ', reprs(spec))
        return
    end

    -- should have base settings defined
    if not spec.BaseSettings then
        WARN('Base builder template excluded for missing BaseSettings in its specification: ', reprs(spec))
        return
    end

    -- overwrite any existing definitions
    if BaseBuilderTemplates[spec.BaseTemplateName] then
        LOG(string.format('Overwriting base builder template: %s', spec.BaseTemplateName))
        for k,v in spec do
            BaseBuilderTemplates[spec.BaseTemplateName][k] = v
        end

    -- first one, we become the definition
    else
        BaseBuilderTemplates[spec.BaseTemplateName] = spec
    end

    return spec.BaseTemplateName
end
