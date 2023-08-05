
---@type boolean
local Debug = true

local oldSpew = _G.SPEW
local SPEW = function(msg)
    if Debug then
        oldSpew(string.format("Generated templates: %s", tostring(msg)))
    end
end

-- convert all known templates
local Templates = import("/lua/ui/game/commands/generated-templates-data.lua")

---@type GenerativeBuildTemplate[]
local PredefinedTemplates = { }
for k, template in Templates do
    if type(template) == "table" then
        if template.TriggersOnHover or template.TriggersOnEmptySpace then
            table.insert(PredefinedTemplates, template)
            LOG(string.format("Found template: %s with name %s", tostring(k), tostring(template.Name)))
        end
    end
end

SPEW(string.format("Found %d predefined templates", table.getn(PredefinedTemplates)))

---@type GenerativeBuildTemplate[]
local CycleTemplates = { }

---@type BlueprintId
local CycleTemplateId = ''

---@type number
local CycleTemplateStep = 1

---@type number
local CycleTemplateCount = 1

-- reset the state when command mode ends and we were trying to do something
local CommandMode = import("/lua/ui/game/commandmode.lua")
CommandMode.AddEndBehavior(
    function()
        if CycleTemplateId != '' then
            CycleTemplateId = ''
            CycleTemplateStep = 1
            ClearBuildTemplates()
        end
    end,
    'CycleTemplates'
)

--- Retrieves the faction prefix of the provided units
---@param units UserUnit[]
---@return 'ua' | 'ue' | 'ur' | 'xs' | nil
local FindFactionPrefix = function(units)
    local hasUEF = table.getn(EntityCategoryFilterDown(categories.UEF, units)) > 0
    local hasAeon = table.getn(EntityCategoryFilterDown(categories.AEON, units)) > 0
    local hasCybran = table.getn(EntityCategoryFilterDown(categories.CYBRAN, units)) > 0
    local hasSeraphim = table.getn(EntityCategoryFilterDown(categories.SERAPHIM, units)) > 0

    if hasUEF and not (hasAeon or hasCybran or hasSeraphim) then
        return 'ue'
    end

    if hasAeon and not (hasUEF or hasCybran or hasSeraphim) then
        return 'ua'
    end

    if hasCybran and not (hasUEF or hasAeon or hasSeraphim) then
        return 'ur'
    end

    if hasSeraphim and not (hasUEF or hasAeon or hasCybran) then
        return 'xs'
    end

    return nil
end

--- Validates the template in-place, returns whether the process succeeded
---@param generativeTemplate GenerativeBuildTemplate
---@param buildableUnits table<BlueprintId, boolean>
---@param prefix 'ua' | 'ue' | 'ur' | 'xs'
---@return boolean
local function ValidateTemplate(generativeTemplate, buildableUnits, prefix)
    local allUnitsExist = true
    local allUnitsBuildable = true
    for l = 3, table.getn(generativeTemplate.TemplateData) do
        local templateUnit = generativeTemplate.TemplateData[l]
        local templateUnitBlueprintId = prefix .. templateUnit[1]:sub(3)
        local templateUnitBlueprint = __blueprints[templateUnitBlueprintId]
        if templateUnitBlueprint then
            if buildableUnits[templateUnitBlueprintId] then
                templateUnit[1] = templateUnitBlueprintId
            else
                allUnitsBuildable = false
            end
        else
            allUnitsExist = false
        end
    end

    return allUnitsExist and allUnitsBuildable
end

---@param a GenerativeBuildTemplate
---@param b GenerativeBuildTemplate
local function SortTemplates(a, b)
    return a.Name < b.Name
end

Cycle = function()

    local start = GetSystemTimeSeconds()

    local info = GetRolloverInfo()
    local userUnit = info.userUnit
    local blueprintId = info.blueprintId
    if not info then
        blueprintId = "EmptySpace"
    end

    local selectedUnits = GetSelectedUnits()
    if selectedUnits then
        local selectedUnitCount = table.getn(selectedUnits)
        local _, _, buildableCategories = GetUnitCommandData(selectedUnits)
        local buildableUnits = table.hash(EntityCategoryGetUnitList(buildableCategories))

        -- sanity check if we can build anything at all
        if table.empty(buildableUnits) then
            print("No templates available")
            return
        end

        -- sanity check for only engineers of the same faction
        local prefix = FindFactionPrefix(selectedUnits)
        if not prefix then
            print("No templates for " .. prefix)
            return
        end

        -- reset when hovering over a new unit type
        if CycleTemplateId != blueprintId then
            CycleTemplateStep = 1
            SPEW("Reset by blueprint id!")
        end
        CycleTemplateId = blueprintId

        -- gather all templates that are applicable. We need to do this each time because the
        -- selection may have changed
        CycleTemplates = { }
        CycleTemplateCount = 0
        for k = 1, table.getn(PredefinedTemplates) do
            -- check if we can build the template
            local generativeTemplate = PredefinedTemplates[k]
            local valid = ValidateTemplate(generativeTemplate, buildableUnits, prefix)
            if valid then
                if  -- check of template meets contextual conditions
                    (userUnit and generativeTemplate.TriggersOnHover and EntityCategoryContains(generativeTemplate.TriggersOnHover, userUnit)) or
                    (not userUnit and generativeTemplate.TriggersOnEmptySpace)
                then
                    table.insert(CycleTemplates, generativeTemplate)
                    CycleTemplateCount = CycleTemplateCount + 1
                end
            end
        end

        -- inform the user and bail out
        if CycleTemplateCount == 0 then
            print("No templates available")
            return
        end

        -- sort the templates on some criteria to make order consistent
        table.sort(CycleTemplates, SortTemplates)

        -- reset when exceeding number of templates
        local count = table.getn(CycleTemplates)
        if CycleTemplateStep > count then
            CycleTemplateStep = 1
            SPEW("Reset by count!")
        end

        local template = CycleTemplates[CycleTemplateStep]
        if template then
            -- start the template command mode
            import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(true)
            import("/lua/ui/game/commandmode.lua").StartCommandMode('build', {name = template.TemplateData[3][1]})
            import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(false)
            SetActiveBuildTemplate(template.TemplateData)

            -- tell the user the name of the template
            print(string.format("(%d/%d) %s", CycleTemplateStep, CycleTemplateCount, tostring(template.Name)))
        end

        CycleTemplateStep = CycleTemplateStep + 1
    end

    SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
end