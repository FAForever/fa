---@declare-global

---@class AIBaseTemplate
---@field Identifier string                         # Unique identifier to reference the base template
---@field BuilderGroupTemplates string[]            # List of names of builder groups
---@field BuilderGroupTemplatesNonCheating string[] # List of names of builder groups when AI does not have `SallyShears` enabled

---@type table<string, AIBaseTemplate>
AIBaseTemplates = {}

--- Register a base builder template, or override an existing base builder template
---@param spec AIBaseTemplate
---@return string
AIBaseTemplate = function(spec)

    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Base builder template: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.Identifier then
        WARN('Base builder template excluded for missing field "Identifier": ', reprs(spec))
        return
    end

    -- should have builders defined
    if not spec.BuilderGroupTemplates then
        WARN('Base builder template excluded for missing field "BuilderGrouptemplates": ', reprs(spec))
        return
    end

    -- overwrite any existing definitions
    if AIBaseTemplates[spec.Identifier] then
        SPEW(string.format('Overwriting base template: %s', spec.Identifier))
        for k,v in spec do
            AIBaseTemplates[spec.Identifier][k] = v
        end

    -- first one, we become the definition
    else
        AIBaseTemplates[spec.Identifier] = spec
    end

    LOG(spec.Identifier)
    return spec.Identifier
end
