---@declare-global

---@alias PlatoonTemplateNamesBase ''
---@alias PlatoonTemplateNamesSorian ''
---@alias PlatoonTemplateNames PlatoonTemplateNamesBase | PlatoonTemplateNamesSorian | string

---@class PlatoonTemplateSquad
---@field [1] EntityCategory | string
---@field [2] number Minimal number of units
---@field [3] number Maximum number of units
---@field [4] PlatoonSquads Squad the units belong to
---@field [5] UnitFormations Formation to apply

---@class PlatoonTemplatePlanSpec
---@field Name string Unique identifier for the platoon template, used as a string reference
---@field Plan FunctionReference Name reference of the function to run that is part of the `Platoon` class
---@field GlobalSquads PlatoonTemplateSquad[]

---@class PlatoonTemplateFactionalSquad
---@field UEF PlatoonTemplateSquad?
---@field Cybran PlatoonTemplateSquad?
---@field Seraphim PlatoonTemplateSquad?
---@field Aeon PlatoonTemplateSquad?

---@class PlatoonTemplateFactionalSpec
---@field Name string Unique identifier for the platoon template, used as a string reference
---@field FactionSquads PlatoonTemplateFactionalSquad

-- There are two type of platoon definitions:
-- - One that applies to all factions, usually via categories and the function `EntityCategoryGetUnitList`
-- - One that applies to specific factions, usually via blueprint ids

---@alias PlatoonTemplateSpec PlatoonTemplatePlanSpec | PlatoonTemplateFactionalSpec

-- Global list of all buffs found in the system.
---@type table<string, PlatoonTemplateSpec>
PlatoonTemplates = {}

--- Register a platoon template, or override an existing platoon template
---@param spec PlatoonTemplateSpec
---@return string
PlatoonTemplate = function(spec)

    -- it should be a table
    if type(spec) ~= 'table' then
        LOG('Invalid Platoon template: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.Name then
        LOG('Platoon template excluded for missing Name in its specification: ', reprs(spec))
        return
    end

    -- should have either a global squad template, or factional squad templates
    if (not spec.GlobalSquads) and (not spec.FactionSquads) then
        LOG('Platoon template excluded for missing GlobalSquads and FactionSquads in its specification: ', reprs(spec))
        return
    end

    -- keep track of non-overridden factional squads
    local oldFactionSquads = false
    if InitialRegistration and PlatoonTemplates[spec.Name] then
        LOG(string.format('Overwriting platoon template: %s', spec.Name))
        oldFactionSquads = PlatoonTemplates[spec.Name]
    end

    PlatoonTemplates[spec.Name] = spec

    -- if there are old faction squads insert the ones that aren't being overridden
    if oldFactionSquads then
        for k,v in oldFactionSquads do
            if not PlatoonTemplates[spec.Name].FactionSquads[k] then
                PlatoonTemplates[spec.Name].FactionSquads[k] = v
            end
        end
    end

    return spec.Name
end