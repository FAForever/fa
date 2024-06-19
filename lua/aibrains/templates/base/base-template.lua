---@declare-global

---@class AIBaseTemplateManager
---@field BuilderGroupTemplates AIBuilderGroupTemplate[]                # List of names of builder groups
---@field BuilderGroupTemplatesNonCheating AIBuilderGroupTemplate[]     # List of names of builder groups when AI does not have `SallyShears` enabled

---@class AIBaseTemplate
---@field BaseTemplateName string   # Unique identifier to reference the base template
---@field EngineerManager AIBaseTemplateManager
---@field StructureManager AIBaseTemplateManager
---@field FactoryManager AIBaseTemplateManager

--- Register a base builder template, or override an existing base builder template
---@param spec AIBaseTemplate
---@return AIBaseTemplate?
AIBaseTemplate = function(spec)

    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Base builder template: ', repr(arg))
        return nil
    end

    -- required field
    if not spec.BaseTemplateName then
        WARN('Base builder template excluded for missing field "BaseTemplateName": ', reprs(spec))
        return nil
    end
    
    -- default value
    if not spec.EngineerManager then
        spec.EngineerManager = {}
    end

    -- default value
    if not spec.EngineerManager.BuilderGroupTemplates then
        spec.EngineerManager.BuilderGroupTemplates = {}
    end

    -- default value
    if not spec.EngineerManager.BuilderGroupTemplatesNonCheating then
        spec.EngineerManager.BuilderGroupTemplatesNonCheating = {}
    end

    -- default value
    if not spec.StructureManager then
        spec.StructureManager = {}
    end

    -- default value
    if not spec.StructureManager.BuilderGroupTemplates then
        spec.StructureManager.BuilderGroupTemplates = {}
    end

    -- default value
    if not spec.StructureManager.BuilderGroupTemplatesNonCheating then
        spec.StructureManager.BuilderGroupTemplatesNonCheating = {}
    end

    -- default value
    if not spec.FactoryManager then
        spec.FactoryManager = {}
    end

    -- default value
    if not spec.FactoryManager.BuilderGroupTemplates then
        spec.FactoryManager.BuilderGroupTemplates = {}
    end

    -- default value
    if not spec.FactoryManager.BuilderGroupTemplatesNonCheating then
        spec.FactoryManager.BuilderGroupTemplatesNonCheating = {}
    end

    return spec
end
