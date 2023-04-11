---@declare-global

---@alias AIBuilderGroupManager 'EngineeManager' | 'FactoryManager' | 'StructureManager'

---@class AIBuilderGroupTemplate : string[]
---@field BuilderGroupName string
---@field ManagerName AIBuilderGroupManager

--- Global list of all builder groups
---@type table<string, AIBuilderGroupTemplate>
AIBuilderGroupTemplates = {}

--- Register a builder group, or override an existing builder group
---@param spec AIBuilderGroupTemplate
---@return string String reference to the builder group
function AIBuilderGroupTemplate(spec)
    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder group: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.BuilderGroupName then
        WARN('Builder group excluded for missing "BuilderGroupName": ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.ManagerName then
        WARN('Builder group excluded for missing "ManagerName": ', reprs(spec))
        return
    end

    -- overwrite any existing definitions
    if AIBuilderGroupTemplates[spec.BuilderGroupName] then
        SPEW(string.format('Overwriting builder group template: %s', spec.BuilderGroupName))
        for k, v in spec do
            AIBuilderGroupTemplates[spec.BuilderGroupName][k] = v
        end

        -- first one, we become the definition
    else
        AIBuilderGroupTemplates[spec.BuilderGroupName] = spec
    end

    return spec.BuilderGroupName
end
