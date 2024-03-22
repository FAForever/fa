--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

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
local RawTemplates = import("/lua/ui/game/hotkeys/context-based-templates-data.lua")

---@type ContextBasedTemplate[]
local Templates = {}

for k, template in RawTemplates do
    if type(template) == "table" then
        if template.TriggersOnUnit or template.TriggersOnLand or template.TriggersOnMassDeposit or
            template.TriggersOnHydroDeposit or template.TriggersOnWater or template.TriggersOnBuilding then
            if template.TemplateSortingOrder then
                TableInsert(Templates, template)
                SPEW(StringFormat("Found template: %s with name %s", tostring(k), tostring(template.Name)))
            end
        end
    end
end

SPEW(StringFormat("Found %d templates", table.getn(Templates)))

--#endregion

-------------------------------------------------------------------------------
--#region Utility functions to work with blueprints

--- Converts the blueprint id to a different faction
---@param blueprintId BlueprintId
---@param prefix 'ua' | 'ue' | 'ur' | 'xs' | 'xn'
---@return BlueprintId
local function ConvertBlueprintId(blueprintId, prefix)
    local templateUnitBlueprintId = prefix .. blueprintId:sub(3)

    -- Because the support factories originate from mods they do not adhere to the
    -- standard blueprint convention for factions; very annoying ^^
    local isSupportFactory = blueprintId:sub(1, 1) == 'z'
    if isSupportFactory then
        templateUnitBlueprintId = 'z' .. prefix:sub(2, 2) .. blueprintId:sub(3)
    end

    -- Same here but then for units that are part of the Forged Alliance expansion; they
    -- do not adhere to blueprint standards; still annoying ^^
    local isExpansion = blueprintId:sub(1, 1) == 'x' and blueprintId:sub(1, 2) ~= 'xs'
    if isExpansion then
        templateUnitBlueprintId = 'x' .. prefix:sub(2, 2) .. blueprintId:sub(3)
    end

    return templateUnitBlueprintId
end

--- Converts the blueprint id to the preferred faction. If that blueprint is not buildable then it will try to find a blueprint that is buildable by lowering the tech and/or upgrade level
---@param blueprintId BlueprintId
---@param buildableUnits table<BlueprintId, boolean>
---@param prefix 'ua' | 'ue' | 'ur' | 'xs' | 'xn'
---@return BlueprintId?
local function FindBuildableBlueprintId(blueprintId, buildableUnits, prefix)
    local convertedBlueprintId = ConvertBlueprintId(blueprintId, prefix)

    -- This is where we check and validate the 

    local blueprint = __blueprints[convertedBlueprintId]
    if blueprint then
        if buildableUnits[convertedBlueprintId] then
            return blueprintId
        end

        local blueprintFromId = blueprint.General.UpgradesFrom
        if blueprintFromId and buildableUnits[blueprintFromId] then
            return blueprintFromId
        end

        local blueprintBaseId = blueprint.General.UpgradesFromBase
        if blueprintBaseId and buildableUnits[blueprintBaseId] then
            return blueprintBaseId
        end
    end

    -- we can't build it
    return nil
end

--#endregion

-------------------------------------------------------------------------------
--#region Template caching

---@type ContextBasedTemplate
local SingletonTemplate = { 
    Name = 'singleton',
    TemplateData = { 0, 0, { 'dummy', 0, 0, 0 } }
}

---@type BuildQueue
local Cachedtemplate = { 0, 0 }

---@type BuildTemplateBuilding[]
local TemplateEntries = { }

---@param index number
---@return BuildTemplateBuilding
local function GetTemplateEntry(index)
    local template = TemplateEntries[index]
    if not template then
        template = { 'dummy', 0, 0, 0 }
        TemplateEntries[index] = template
    end

    return template
end

---@param template ContextBasedTemplate
---@param cache BuildQueue
---@return BuildQueue
local function ConvertTemplate(template, buildableUnits, prefix, cache)
    local templateData = template.TemplateData

    -- clear the cache
    for k = 3, table.getn(cache) do
        cache[k] = nil
    end

    -- width/height
    cache[1] = templateData[1]
    cache[2] = templateData[2]

    -- the first entry is special as we allow to change it
    cache[3] = GetTemplateEntry(1)
    cache[3][1] = FindBuildableBlueprintId(templateData[3][1], buildableUnits, prefix)
    cache[3][2] = templateData[3][2]
    cache[3][3] = templateData[3][3]
    cache[3][4] = templateData[3][4]

    -- all the other entries can only change faction
    for k = 4, TableGetn(templateData) do
        ---@type BuildTemplateBuilding
        local templateBuilding = templateData[k]
        local templateUnitBlueprintId = ConvertBlueprintId(templateBuilding[1], prefix)
        if templateUnitBlueprintId then
            local entry = GetTemplateEntry(k)
            entry[1] = templateUnitBlueprintId
            entry[2] = templateBuilding[2]
            entry[3] = templateBuilding[3]
            entry[4] = templateBuilding[4]
            cache[k] = entry
        end
    end
    return cache
end

--#endregion

---@type ContextBasedTemplate[]
local ContextBasedTemplates = {}

---@type number
local ContextBasedTemplateStep = 0

---@type number
local ContextBasedTemplateCount = 0

-- reset the state when command mode ends and we were trying to do something
local CommandMode = import("/lua/ui/game/commandmode.lua")
CommandMode.AddEndBehavior(
    function(mode, data)
        if not table.empty(ContextBasedTemplates) then
            ContextBasedTemplates = {}
            ContextBasedTemplateStep = 0
            ClearBuildTemplates()
        end
    end,
    'ContextBasedTemplates'
)

--- Validates the template in-place, returns whether the process succeeded
---@param template ContextBasedTemplate
---@param buildableUnits table<BlueprintId, boolean>
---@param prefix 'ua' | 'ue' | 'ur' | 'xs' | 'xn'
---@return boolean
local function ValidateTemplate(template, buildableUnits, prefix)

    -- check the first entry separate as we're allowed to change it
    local transformableBlueprintId = template.TemplateData[3][1]
    local transformedBlueprintId = FindBuildableBlueprintId(transformableBlueprintId, buildableUnits, prefix)
    if not transformedBlueprintId then
        return false
    end

    -- check the remainder by just converting the faction
    for l = 4, TableGetn(template.TemplateData) do
        local templateUnitBlueprintId = ConvertBlueprintId(template.TemplateData[l][1], prefix)
        if not buildableUnits[templateUnitBlueprintId] then
            return false
        end
    end

    return true
end

---@param buildableUnits table<BlueprintId, boolean>
---@param prefix string
local function FilterTemplatesByMouseContext(buildableUnits, prefix)
    -- deposit scan radius depending on zoom level to make it easier to place extractors while zoomed out
    local radius = 2
    local camera = GetCamera('WorldCamera')
    if camera then
        local zoom = camera:GetZoom()
        if zoom > 200 then
            radius = radius * zoom * 0.005
        end
    end

    local position = GetMouseWorldPos()
    local elevation = GetMouseTerrainElevation()
    local massDeposits = TableGetn(GetDepositsAroundPoint(position[1], position[3], radius, 1))
    local hydroDeposits = TableGetn(GetDepositsAroundPoint(position[1], position[3], 2 + radius, 2))
    local noDeposits = (massDeposits == 0) and (hydroDeposits == 0)
    local onLand = elevation + 0.1 >= position[2]

    for k = 1, TableGetn(Templates) do
        local template = Templates[k]
        local valid = ValidateTemplate(template, buildableUnits, prefix)
        if valid then
            if -- check conditions based on the context of the mouse
            ((not template.TriggersOnUnit) and (not template.TriggersOnBuilding)) and
                ((not template.TriggersOnMassDeposit) or (massDeposits > 0)) and
                ((not template.TriggersOnHydroDeposit) or (hydroDeposits > 0)) and
                ((not template.TriggersOnLand) or noDeposits and onLand) and
                ((not template.TriggersOnWater) or noDeposits and (not onLand))
            then
                TableInsert(ContextBasedTemplates, template)
                ContextBasedTemplateCount = ContextBasedTemplateCount + 1
            end
        end
    end

    -- no templates to use, default to those that trigger on land or water
    if ContextBasedTemplateCount == 0 then
        for k = 1, TableGetn(Templates) do
            local template = Templates[k]
            local valid = ValidateTemplate(template, buildableUnits, prefix)
            if valid then
                if -- check conditions based on the context of the mouse
                (template.TriggersOnLand and onLand) or
                    (template.TriggersOnWater and (not onLand))
                then
                    TableInsert(ContextBasedTemplates, template)
                    ContextBasedTemplateCount = ContextBasedTemplateCount + 1
                end
            end
        end
    end
end

---@param buildableUnits table<BlueprintId, boolean>
---@param prefix string
---@return boolean
local function FilterTemplatesByUnitContext(buildableUnits, prefix)
    -- try and retrieve blueprint id from command mode
    local commandMode = import("/lua/ui/game/commandmode.lua").GetCommandMode()
    local blueprintId = commandMode[2].name
    local fromCommandMode = (blueprintId and true) or false

    -- try and retrieve blueprint id from highlight command
    if not blueprintId then
        local highlightCommand = GetHighlightCommand()
        if highlightCommand and highlightCommand.blueprintId then
            blueprintId = highlightCommand.blueprintId
        end
    end

    -- try and retrieve blueprint id from rollover info
    if not blueprintId then
        local info = GetRolloverInfo()
        if info.userUnit then
            blueprintId = info.blueprintId
        end
    end

    -- if still not available then give up and bail out
    if not blueprintId then
        return false
    end

    -- we have a blueprint that is not from the command mode. If we do include it
    -- then we're cycling through the same blueprint twice
    if not fromCommandMode then
        local buildableBlueprintId = FindBuildableBlueprintId(blueprintId, buildableUnits, prefix)

        if buildableBlueprintId then
            SingletonTemplate.Name = LOC(__blueprints[buildableBlueprintId].Description)
            SingletonTemplate.TemplateData[3][1] = buildableBlueprintId
            TableInsert(ContextBasedTemplates, SingletonTemplate)
            ContextBasedTemplateCount = ContextBasedTemplateCount + 1
        end
    end

    -- add templates that match the unit that we're hovering over
    for k = 1, TableGetn(Templates) do
        local template = Templates[k]
        local trigger = template.TriggersOnUnit or template.TriggersOnBuilding

        if trigger and EntityCategoryContains(trigger, blueprintId) then
            -- replace the dummy blueprint id with the actual blueprint id
            template.TemplateData[3][1] = template.TemplateBlueprintId or blueprintId
            local valid = ValidateTemplate(template, buildableUnits, prefix)

            if valid then
                TableInsert(ContextBasedTemplates, template)
                ContextBasedTemplateCount = ContextBasedTemplateCount + 1
            end
        end
    end

    return ContextBasedTemplateCount > 0
end

--- Provides a sense of order to the chosen templates
---@param a ContextBasedTemplate
---@param b ContextBasedTemplate
local function SortTemplates(a, b)
    return a.TemplateSortingOrder < b.TemplateSortingOrder
end

--- Enables us to cycle the templates depending on the context that the mouse provides
Cycle = function()

    local start = GetSystemTimeSeconds()

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
        local factionOfSelection = selectedUnits[1]:GetBlueprint().FactionCategory
        if factionOfSelection and factionOfSelection == "UEF" then
            prefix = 'ue'
        elseif factionOfSelection and factionOfSelection == "AEON" then
            prefix = 'ua'
        elseif factionOfSelection and factionOfSelection == "CYBRAN" then
            prefix = 'ur'
        elseif factionOfSelection and factionOfSelection == "SERAPHIM" then
            prefix = 'xs'
        elseif factionOfSelection and factionOfSelection == "NOMADS" then
            prefix = 'xn'
        end

        -- only recompute the templates when we left command mode
        if ContextBasedTemplateStep == 0 then
            ContextBasedTemplates = {}
            ContextBasedTemplateCount = 0

            -- first try to filter by command mode
            local applies = FilterTemplatesByUnitContext(buildableUnits, prefix)
            if not applies then
                FilterTemplatesByMouseContext(buildableUnits, prefix)
            end
        end

        -- absolutely nothing available
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
            import("/lua/ui/game/commandmode.lua").StartCommandMode('build', { name = template.TemplateData[3][1] })
            import("/lua/ui/game/commandmode.lua").SetIgnoreSelection(false)

            -- only turn it into a build template when we have more than 1 unit in it
            if TableGetn(template.TemplateData) > 3 then
                local convertedTemplate = ConvertTemplate(template, buildableUnits, prefix, Cachedtemplate)
                SetActiveBuildTemplate(convertedTemplate)
            else
                ClearBuildTemplates()
            end

            print(StringFormat("(%d/%d) %s", index, ContextBasedTemplateCount, tostring(template.Name)))
        end

        ContextBasedTemplateStep = ContextBasedTemplateStep + 1
    end

    SPEW("Time taken: " .. GetSystemTimeSeconds() - start)
end
