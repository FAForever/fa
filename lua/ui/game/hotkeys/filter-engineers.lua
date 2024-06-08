
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

function CalcTableLength(tbl)
    tbl_size = 0
    for _ in pairs(tbl) do tbl_size = tbl_size + 1 end
    return tbl_size
end

function GetMajorityFaction(units)
    local faction_categories = {categories.UEF, categories.CYBRAN, categories.AEON, categories.SERAPHIM}

    local units_factions = {}
    for i, faction_category in faction_categories do
        table.insert(units_factions,EntityCategoryFilterDown(faction_category, units))
    end

    local faction_nr = 0
    local nr_of_units = 0
    for i, u in units_factions do
        nr_of_units_for_that_faction = CalcTableLength(u)
        if nr_of_units_for_that_faction > nr_of_units then
            nr_of_units = nr_of_units_for_that_faction
            faction_nr = i
        end
    end

    return units_factions[faction_nr]
end

--- Filters your selection to the highest tech of engineers. All other engineers assist one of those engineers.
function SelectHighestEngineerAndAssist()
    local selection = GetSelectedUnits()

    if selection then

        local tech1 = EntityCategoryFilterDown(categories.TECH1 - categories.COMMAND, selection)
        local tech2 = EntityCategoryFilterDown(categories.TECH2 - categories.COMMAND, selection)
        local tech3_and_sACUs = EntityCategoryFilterDown((categories.SUBCOMMANDER + categories.TECH3) - categories.COMMAND, selection)

        local highest_tech_engies_and_sacus_of_majority_faction = nil
        if next(tech3_and_sACUs) then
            highest_tech_engies_and_sacus_of_majority_faction = GetMajorityFaction(tech3_and_sACUs)
        elseif next(tech2) then
            highest_tech_engies_and_sacus_of_majority_faction = GetMajorityFaction(tech2)
        elseif next(tech1) then
            highest_tech_engies_and_sacus_of_majority_faction = GetMajorityFaction(tech1)
        else
            -- do nothing
        end
        if highest_tech_engies_and_sacus_of_majority_faction then
            SimCallback({Func= 'SelectHighestEngineerAndAssist', Args = { TargetId = highest_tech_engies_and_sacus_of_majority_faction[1]:GetEntityId() }}, true)
            SelectUnits(highest_tech_engies_and_sacus_of_majority_faction)
        end
    end
end
