---@declare-global

---@alias AIBuilderLayer 'LAND' | 'NAVAL' | 'AIR'
---@alias AIBuilderTech 'TECH1' | 'TECH2' | 'TECH3' | 'EXPERIMENTAL'
---@alias AIBuilderFactions 'ANY' | 'AEON' | 'CYBRAN' | 'SERAPHIM' | 'UEF'
---@alias AIBuilderTypes 'GATE' | ('TECH1' | 'TECH1LAND' | 'TECH1AIR' | 'TECH1NAVAL') | ('TECH2' | 'TECH2LAND' | 'TECH2AIR' | 'TECH2NAVAL') | ('TECH3'  | 'TECH3LAND'  | 'TECH3AIR'  | 'TECH3NAVAL') | ('EXPERIMENTAL' | 'EXPERIMENTALLAND' | 'EXPERIMENTALAIR' | 'EXPERIMENTALNAVAL')


---@class AIBuilderTemplateCondition
---@field [1] FileReference         # File reference
---@field [2] FunctionReference     # Function reference
---@field [3] FunctionParameters    # Function parameters

---@class AIBuilderCondition
---@field [1] function 
---@field [2] table

---@class AIBuilderData
--- Used by the structure manager. Indicates to use the `UpgradeTo` field of the blueprint of the structure
---@field UseUpgradeToBlueprintField boolean
--- used by the structure manager. Indicates a specific blueprint to upgrade to, the second character is replaced with the faction of the structure: `uab0302` would become `ueb0302` for the UEF tech 3 land factory
---@field UpgradeToFactionReplace string
--- categories used for various tasks
---@field Categories EntityCategory

---@class AIBuilderTemplate
---@field BuilderConditions AIBuilderTemplateCondition[]
---@field BuilderData AIBuilderData
---@field BuilderDisabled boolean
---@field BuilderInstanceCount number
---@field BuilderInstances table
---@field BuilderName string
---@field BuilderType string                        # Used to filter builders for a given unit
---@field BuilderFaction FactionCategory | nil    # Used to quickly reject builders for a given unit
---@field BuilderLayer LayerCategory | nil         # Used to quickly reject builders for a given unit
---@field BuilderTech TechCategory | nil           # Used to quickly reject builders for a given unit
---@field BuilderPriority number
---@field BuilderPriorityFunction? fun(brain: AIBrain, base: AIBase)

--- Checks the validity of a builder template
---@param spec AIBuilderTemplate
---@return AIBuilderTemplate
AIBuilderTemplate = function(spec)
    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder: ', repr(arg))
        return nil
    end

    -- required field
    if not spec.BuilderManager then
        WARN('Builder excluded for missing field "BuilderManager": ', reprs(spec))
        return nil
    end

    -- required field
    if not spec.BuilderName then
        WARN('Builder excluded for missing field "BuilderName": ', reprs(spec))
        return nil
    end

    -- required field
    if not spec.BuilderPriority then
        WARN('Builder excluded for missing field "BuilderPriority": ', reprs(spec))
        return nil
    end

    -- required field
    if not spec.BuilderPriority then
        WARN('Builder excluded for missing field "BuilderPriority": ', reprs(spec))
        return nil
    end

    -- default value
    if not spec.BuilderConditions then
        spec.BuilderConditions = {}
    end

    for k, builderCondition in spec.BuilderConditions do
        if type(builderCondition[1]) != "function" then
            WARN('Builder excluded for a condition without a function: ', reprs(spec))
            return nil
        end

        if not ((type(builderCondition[2]) == "table") or (type(builderCondition[2]) == "nil")) then
            WARN('Builder excluded for a condition with invalid input: ', reprs(spec))
            return nil
        end
    end

    -- default value
    if not spec.BuilderData then
        spec.BuilderData = {}
    end

    -- default value
    if not spec.BuilderInstanceCount then
        spec.BuilderInstanceCount = -1
    end

    -- default value
    if not spec.BuilderInstances then
        spec.BuilderInstances = {}
    end

    -- default value
    if spec.BuilderDisabled == nil then
        spec.BuilderDisabled = false
    end

    return spec
end
