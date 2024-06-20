
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

-- upvalue scope for performance
local SelectUnits = SelectUnits
local SimCallback = SimCallback
local GetSelectedUnits = GetSelectedUnits
local EntityCategoryFilterDown = EntityCategoryFilterDown

local TableInsert = table.insert
local TableGetn = table.getn
local TableEmpty = table.empty

local GetFactions = import('/lua/factions.lua').GetFactions

-- cached for performance
local CategoriesTech3EngineersAndSACUs = (categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER) - (categories.FIELDENGINEER + categories.COMMAND)
local CategoriesTech2Engineers = categories.ENGINEER * categories.TECH2 - (categories.FIELDENGINEER + categories.COMMAND)
local CategoriesFieldEngineers = categories.FIELDENGINEER - categories.COMMAND
local CategoriesTech1Engineers = categories.ENGINEER * categories.TECH1 - (categories.FIELDENGINEER + categories.COMMAND)

--- Get the faction category for each faction, including custom factions.
--- Equivalent to {categories.UEF, categories.CYBRAN, categories.AEON, categories.SERAPHIM} for the base game.
function GetFactionCategories()
    local factionCategories = {}

    for _, faction in GetFactions() do
        TableInsert(factionCategories, categories[faction['Category']])
    end

    return factionCategories
end

local factionCategories = GetFactionCategories()

--- Filter units down to the of the majority faction among them.
---@param units UserUnit[]
---@return UserUnit[]
function GetMajorityFaction(units)
    local majorityFactionUnits = {}
    local majorityFactionUnitCount = 0

    for _, factionCategory in factionCategories do
        local factionUnits = EntityCategoryFilterDown(factionCategory, units)
        local factionUnitCount = TableGetn(factionUnits)
        if factionUnitCount > majorityFactionUnitCount then
            majorityFactionUnits = factionUnits
            majorityFactionUnitCount = factionUnitCount
        end
    end

    return majorityFactionUnits
end

--- Filter your selection to the highest tech engineers of the majority faction for that tech level.
--- All other units assist one of those engineers.
function SelectHighestEngineerAndAssist()
    local selection = GetSelectedUnits()

    if selection then
        local tech3EngineersAndSACUs = EntityCategoryFilterDown(CategoriesTech3EngineersAndSACUs, selection)
        local tech2Engineers = EntityCategoryFilterDown(CategoriesTech2Engineers, selection)
        local fieldEngineers = EntityCategoryFilterDown(CategoriesFieldEngineers, selection)
        local tech1Engineers = EntityCategoryFilterDown(CategoriesTech1Engineers, selection)

        local highestTechEngiesAndSacusOfMajorityFaction
        if not TableEmpty(tech3EngineersAndSACUs) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech3EngineersAndSACUs)
        elseif not TableEmpty(tech2Engineers) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech2Engineers)
        elseif not TableEmpty(fieldEngineers) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(fieldEngineers)
        elseif not TableEmpty(tech1Engineers) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech1Engineers)
        end

        if highestTechEngiesAndSacusOfMajorityFaction then
            SimCallback({Func= 'SelectHighestEngineerAndAssist', Args = { TargetId = highestTechEngiesAndSacusOfMajorityFaction[1]:GetEntityId() }}, true)
            SelectUnits(highestTechEngiesAndSacusOfMajorityFaction)
        end
    end
end
