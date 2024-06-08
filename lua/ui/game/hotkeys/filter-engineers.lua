
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

--- Filters your selection to the units of the majority faction in your selection.
function GetMajorityFaction(units)
    local factionCategories = {categories.UEF, categories.CYBRAN, categories.AEON, categories.SERAPHIM}

    local factionsOfUnits = {}
    for _, factionCategory in factionCategories do
        table.insert(factionsOfUnits, EntityCategoryFilterDown(factionCategory, units))
    end

    local factionNr = 0
    local nrOfUnits = 0
    for i, u in factionsOfUnits do
        nrOfUnitsForThatFaction = table.getsize(u)
        if nrOfUnitsForThatFaction > nrOfUnits then
            nrOfUnits = nrOfUnitsForThatFaction
            factionNr = i
        end
    end

    return factionsOfUnits[factionNr]
end

--- Filters your selection to the highest tech of engineers. All other engineers assist one of those engineers.
function SelectHighestEngineerAndAssist()
    local selection = GetSelectedUnits()

    if selection then

        local tech3EngineersAndSACUs = EntityCategoryFilterDown((categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER) - categories.COMMAND, selection)
        local tech2Engineers = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH2 - categories.COMMAND, selection)
        local tech1Engineers = EntityCategoryFilterDown(categories.ENGINEER * categories.TECH1 - categories.COMMAND, selection)

        local highestTechEngiesAndSacusOfMajorityFaction = nil
        if next(tech3EngineersAndSACUs) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech3EngineersAndSACUs)
        elseif next(tech2Engineers) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech2Engineers)
        elseif next(tech1Engineers) then
            highestTechEngiesAndSacusOfMajorityFaction = GetMajorityFaction(tech1Engineers)
        else
            -- do nothing
        end
        if highestTechEngiesAndSacusOfMajorityFaction then
            SimCallback({Func= 'SelectHighestEngineerAndAssist', Args = { TargetId = highestTechEngiesAndSacusOfMajorityFaction[1]:GetEntityId() }}, true)
            SelectUnits(highestTechEngiesAndSacusOfMajorityFaction)
        end
    end
end
