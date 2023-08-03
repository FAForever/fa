
---@type boolean
local Debug = true

local LOG = function(msg)
    if Debug then
        SPEW(string.format("Generated templates: %s", tostring(msg)))
    end
end

-- convert all known templates
local Templates = import("/lua/ui/game/commands/generated-templates-data.lua")

---@type GenerativeBuildTemplate[]
local PredefinedTemplates = { }
for k, template in Templates do
    if type(template) == "table" then
        if template.TriggersOnHover then
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

---@param units UserUnit[]
---@return 'BUILTBYTIER1ENGINEER' | 'BUILTBYTIER2ENGINEER' | 'BUILTBYTIER3ENGINEER' | nil
local FindBuildableTech = function(units)
    local unitCount = table.getn(units)

    local tech3Count = table.getn(EntityCategoryFilterDown(categories.TECH3 * categories.ENGINEER, units))
    if tech3Count == unitCount then
        return 'BUILTBYTIER3ENGINEER'
    end

    local tech2Count = table.getn(EntityCategoryFilterDown(categories.TECH2 * categories.ENGINEER, units))
    if tech2Count == unitCount then
        return 'BUILTBYTIER2ENGINEER'
    end

    local tech1Count = table.getn(EntityCategoryFilterDown(categories.TECH1 * categories.ENGINEER, units))
    if tech1Count == unitCount then
        return 'BUILTBYTIER1ENGINEER'
    end

    return nil
end

Cycle = function()

    -- SavePreferences()

    local start = GetSystemTimeSeconds()
    local info = GetRolloverInfo()
    local userUnit = info.userUnit
    local blueprintId = info.blueprintId
    if info and blueprintId and userUnit then
        local selectedUnits = GetSelectedUnits()
        if selectedUnits then
            local selectedUnitCount = table.getn(selectedUnits)

            -- sanity check for only engineers in the selection
            local tech = FindBuildableTech(selectedUnits)
            if not tech then
                print("No templates for " .. tostring(tech))
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
                LOG("Reset by blueprint id!")
            end
            CycleTemplateId = blueprintId

            -- gather all templates that are applicable. We need to do this each time because the
            -- selection may have changed
            CycleTemplates = { }
            CycleTemplateCount = 0
            for k = 1, table.getn(PredefinedTemplates) do
                local generativeTemplate = PredefinedTemplates[k]

                -- basic validation provided by the author of the template
                if  EntityCategoryContains(generativeTemplate.TriggersOnHover, userUnit) and
                    EntityCategoryFilterOut(generativeTemplate.TriggersOnSelection, selectedUnits)
                then
                    -- copy the unit we're hovering over into the first unit in the template
                    if generativeTemplate.CopyUnit then
                        generativeTemplate.TemplateData[3][1] = info.blueprintId
                    end

                    -- replace the faction prefix and do advanced validation to check if we can actually build the unit
                    local allUnitsExist = true
                    local allUnitsBuildable = true
                    for l = 3, table.getn(generativeTemplate.TemplateData) do
                        local templateUnit = generativeTemplate.TemplateData[l]
                        local templateUnitBlueprintId = prefix .. templateUnit[1]:sub(3)
                        local templateUnitBlueprint = __blueprints[templateUnitBlueprintId]
                        if templateUnitBlueprint then
                            if templateUnitBlueprint.CategoriesHash[tech] then
                                templateUnit[1] = templateUnitBlueprintId
                            else
                                allUnitsBuildable = false
                            end
                        else
                            allUnitsExist = false
                        end
                    end

                    -- check if we can build all of the units
                    if allUnitsExist and allUnitsBuildable then
                        table.insert(CycleTemplates, generativeTemplate)
                        CycleTemplateCount = CycleTemplateCount + 1
                    end
                end
            end

            if CycleTemplateCount == 0 then
                print("No templates available")
                return
            end

            -- reset when exceeding number of templates
            local count = table.getn(CycleTemplates)
            if CycleTemplateStep > count then
                CycleTemplateStep = 1
                LOG("Reset by count!")
            end

            -- prepare the template
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
    end

    LOG("Time taken: " .. GetSystemTimeSeconds() - start)
end