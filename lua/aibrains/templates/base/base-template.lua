---@declare-global

---@class AIBaseTemplate
---@field BaseTemplateName string           # Unique identifier to reference the base template
---@field BuilderGroupTemplates string[]    # List of names of builder groups
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
    if not spec.BaseTemplateName then
        WARN('Base builder template excluded for missing field "BaseTemplateName": ', reprs(spec))
        return
    end

    -- should have builders defined
    if not spec.BuilderGroupTemplates then
        WARN('Base builder template excluded for missing field "BuilderGrouptemplates": ', reprs(spec))
        return
    end

    -- overwrite any existing definitions
    if AIBaseTemplates[spec.BaseTemplateName] then
        SPEW(string.format('Overwriting base template: %s', spec.BaseTemplateName))
        for k,v in spec do
            AIBaseTemplates[spec.BaseTemplateName][k] = v
        end

    -- first one, we become the definition
    else
        AIBaseTemplates[spec.BaseTemplateName] = spec
    end

    return spec.BaseTemplateName
end
