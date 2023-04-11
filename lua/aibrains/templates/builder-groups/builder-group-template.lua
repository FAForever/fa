---@declare-global

---@alias AIBuilderGroupManager 'EngineeManager' | 'FactoryManager' | 'StructureManager'

---@class AIBuilderGroupTemplate : string[]
---@field Identifier string
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
    if not spec.Identifier then
        WARN('Builder group excluded for missing "Identifier": ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.ManagerName then
        WARN('Builder group excluded for missing "ManagerName": ', reprs(spec))
        return
    end

    -- overwrite any existing definitions
    if AIBuilderGroupTemplates[spec.Identifier] then
        SPEW(string.format('Overwriting builder group template: %s', spec.Identifier))
        for k, v in spec do
            AIBuilderGroupTemplates[spec.Identifier][k] = v
        end

        -- first one, we become the definition
    else
        AIBuilderGroupTemplates[spec.Identifier] = spec
    end

    return spec.Identifier
end
