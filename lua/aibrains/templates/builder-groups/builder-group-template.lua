---@declare-global

---@alias AIBuilderGroupManager 'EngineeManager' | 'FactoryManager' | 'StructureManager'

---@class AIBuilderGroupTemplate
---@field BuilderGroupName string
---@field BuilderTemplates AIBuilderTemplate[]

--- Register a builder group, or override an existing builder group
---@param spec AIBuilderGroupTemplate
---@return AIBuilderGroupTemplate?
function AIBuilderGroupTemplate(spec)
    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder group: ', repr(arg))
        return
    end

    -- required field
    if not spec.BuilderGroupName then
        WARN('Builder group excluded for missing "BuilderGroupName": ', reprs(spec))
        return
    end

    -- required field
    if not spec.BuilderTemplates then
        WARN('Builder group excluded for missing "BuilderTemplates": ', reprs(spec))
        return
    end

    return spec
end
