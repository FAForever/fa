
-- performance related imports
local type = type
local import = import
local print = print

local GetRolloverInfo = GetRolloverInfo
local GetSelectedUnits = GetSelectedUnits
local GetUnitCommandData = GetUnitCommandData
local EntityCategoryGetUnitList = EntityCategoryGetUnitList
local SetActiveBuildTemplate = SetActiveBuildTemplate
local ClearBuildTemplates = ClearBuildTemplates

local TableInsert = table.insert
local TableSort = table.sort
local TableGetn = table.getn
local TableEmpty = table.empty
local TableHash = table.hash

local StringFormat = string.format

-------------------------------------------------------------------------------
--#region Debugging

---@type boolean
local Debug = true

local oldSpew = _G.SPEW
local SPEW = function(msg)
    if Debug then
        oldSpew(StringFormat("Context based templates: %s", tostring(msg)))
    end
end

--#endregion

-------------------------------------------------------------------------------
--#region Template discovery

-- convert all known templates

---@type table
local RawTemplates = import("/lua/ui/game/commands/context-based-templates-data.lua")

---@type ContextBasedTemplate[]
local Templates = { }

for k, template in RawTemplates do
    if type(template) == "table" then
        if template.TriggersOnUnit or template.TriggersOnLand or template.TriggersOnMassDeposit or template.TriggersOnHydroDeposit or template.TriggersOnWater then
            TableInsert(Templates, template)
            SPEW(StringFormat("Found template: %s with name %s", tostring(k), tostring(template.Name)))
        end
    end
end

SPEW(StringFormat("Found %d templates", table.getn(Templates)))

--#endregion

---@type ContextBasedTemplate[]
local ContextBasedTemplates = { }

---@type number
local ContextBasedTemplateStep = 0

---@type number
local ContextBasedTemplateCount = 1

-- reset the state when command mode ends and we were trying to do something
local CommandMode = import("/lua/ui/game/commandmode.lua")
CommandMode.AddEndBehavior(
    function()
        if not table.empty(ContextBasedTemplates) then
            ContextBasedTemplateStep = 0
            ClearBuildTemplates()
        end
    end,
    'ContextBasedTemplates'
)

--- Validates the template in-place, returns whether the process succeeded
---@param template ContextBasedTemplate
---@param buildableUnits table<BlueprintId, boolean>
---@param prefix 'ua' | 'ue' | 'ur' | 'xs'
---@return boolean
local function ValidateTemplate(template, buildableUnits, prefix)
    local allUnitsExist = true
    local allUnitsBuildable = true
    for l = 3, TableGetn(template.TemplateData) do
        local templateUnit = template.TemplateData[l]
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

--- Provides a sense of order to the chosen templates
---@param a ContextBasedTemplate
---@param b ContextBasedTemplate
local function SortTemplates(a, b)
    return a.Name < b.Name
end

--- Enables us to cycle the templates depending on the context that the mouse provides
Cycle = function()

    local start = GetSystemTimeSeconds()

    local info = GetRolloverInfo()
    local userUnit = info.userUnit
    local blueprintId = info.blueprintId
    if not info then
        blueprintId = "EmptySpace"
    end
    local position = GetMouseWorldPos()
    local selectedUnits = GetSelectedUnits()
    if selectedUnits and not TableEmpty(selectedUnits) then
        local _, _, buildableCategories = GetUnitCommandData(selectedUnits)
        local buildableUnits = TableHash(EntityCategoryGetUnitList(buildableCategories))

        -- early exit
        if TableEmpty(buildableUnits) then
            print("No templates available")
            return
        end

        -- this is where we take the templates and fiddle with them:
        -- - we replace the unit IDs in the template so that it becomes faction independant
        -- - we filter the templates to only keep those that we want to place given the context, and that we can build given the selection of engineers

        -- a bit of a hack to retrieve the faction prefix
        local prefix = selectedUnits[1]:GetBlueprint().BlueprintId:sub(1, 2)

        local massDeposits = TableGetn(GetDepositsAroundPoint(position[1], position[3], 1.5, 1))
        local hydroDeposits = TableGetn(GetDepositsAroundPoint(position[1], position[3], 3.0, 2))
        local noDeposits = (massDeposits == 0) and (hydroDeposits == 0)

        ContextBasedTemplates = { }
        ContextBasedTemplateCount = 0
        for k = 1, TableGetn(Templates) do
            local template = Templates[k]
            local valid = ValidateTemplate(template, buildableUnits, prefix)
            if valid then
                if  -- check conditions based on the context of the mouse
                    ((not template.TriggersOnUnit) or (userUnit and EntityCategoryContains(template.TriggersOnUnit, userUnit))) and
                    ((not template.TriggersOnMassDeposit) or ((not userUnit) and (massDeposits > 0))) and
                    ((not template.TriggersOnHydroDeposit) or ((not userUnit) and (hydroDeposits > 0))) and
                    ((not template.TriggersOnLand) or ((not userUnit) and noDeposits)) and
                    ((not template.TriggersOnWater) or ((not userUnit) and noDeposits))
                then
                    TableInsert(ContextBasedTemplates, template)
                    ContextBasedTemplateCount = ContextBasedTemplateCount + 1
                end
            end
        end

        -- no templates to use, inform the user and bail out
        if ContextBasedTemplateCount == 0 then
            print("No templates available")
            return
        end

        -- sort the templates on some criteria to make order consistent
        TableSort(ContextBasedTemplates, SortTemplates)

        -- wrap around when exceeding number of templates
        local count = TableGetn(ContextBasedTemplates)
        local index = math.mod(ContextBasedTemplateStep, count) + 1

        -- start the command mode to allow us to build
        local template = ContextBasedTemplates[index]
        if template then
            import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(true)
            import("/lua/ui/game/commandmode.lua").StartCommandMode('build', {name = template.TemplateData[3][1]})
            import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(false)
            SetActiveBuildTemplate(template.TemplateData)

            print(StringFormat("(%d/%d) %s", index, ContextBasedTemplateCount, template.Name))
        end

        ContextBasedTemplateStep = ContextBasedTemplateStep + 1
    end

    SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
end
