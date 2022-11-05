-- This file contains the functions needed to keep track of ACU upgrade queueing

local SetIgnoreSelection = import("/lua/ui/game/gamemain.lua").SetIgnoreSelection

local enhancementQueue = {}

function enqueueEnhancement(units, enhancement)
    if not units[1] then return end

    local enhancements = units[1]:GetBlueprint().Enhancements

    if enhancements[enhancement] then
        for _, unit in units do
            local id = unit:GetEntityId()
            if not enhancementQueue[id] then
                enhancementQueue[id] = {}
            end

            table.insert(enhancementQueue[id], enhancements[enhancement])
        end
        import("/lua/ui/game/construction.lua").updateCommandQueue()
    end
end

function getEnhancementQueue()
    return enhancementQueue
end

function removeEnhancement(unit)
    local id = unit:GetEntityId()
    if enhancementQueue[id] and not table.empty(enhancementQueue[id]) then
        table.remove(enhancementQueue[id], 1)
    end
end

function clearEnhancements(units)
    for _, unit in units do
        local id = unit:GetEntityId()
        if enhancementQueue[id] then
            enhancementQueue[id] = {}
        end
    end
end

function currentlyUpgrading(unit)
    local currentCommand = unit:GetCommandQueue()[1]
    local queue = enhancementQueue[unit:GetEntityId()][1]

    return currentCommand.type == 'Script' and queue and not string.find(queue.ID, 'Remove')
end

function ModifyBuildablesForACU(originalBuildables, selection)
    local newBuildableCategories
    local upgradingACUFound = false
    local faction

    for unitIndex, unit in selection do
        local currentBuildableCategories
        local bp = unit:GetBlueprint()

        if unit:IsInCategory('COMMAND') then
            local techUpgrading = 0

            for _, enhancement in enhancementQueue[unit:GetEntityId()] or {} do
                if enhancement.ID == 'AdvancedEngineering' and techUpgrading < 2 then
                    techUpgrading = 2
                elseif enhancement.ID == 'T3Engineering' then
                    techUpgrading = 3
                end
            end

            local buildCat = bp.Economy.BuildableCategory
            currentBuildableCategories = ParseEntityCategory(buildCat[1])

            if techUpgrading >= 2 then
                currentBuildableCategories = currentBuildableCategories + ParseEntityCategory(buildCat[2])
                faction = string.upper(bp.General.FactionName)
                upgradingACUFound = true
            end
            if techUpgrading == 3 then
                currentBuildableCategories = currentBuildableCategories + ParseEntityCategory(buildCat[3])
            end
        else
            for categoryIndex, category in bp.Economy.BuildableCategory do
                if categoryIndex == 1 then
                    currentBuildableCategories = ParseEntityCategory(category)
                else
                    currentBuildableCategories = currentBuildableCategories + ParseEntityCategory(category)
                end
            end
        end

        if unitIndex == 1 then
            newBuildableCategories = currentBuildableCategories
        elseif currentBuildableCategories and newBuildableCategories then
            newBuildableCategories = newBuildableCategories * currentBuildableCategories
        else
            upgradingACUFound = false
            break
        end
    end

    if upgradingACUFound == false then
        newBuildableCategories = originalBuildables
    else
        local restrictedUnits = import("/lua/ui/lobby/restrictedunitsdata.lua").restrictedUnits
        for _, generalCategory in SessionGetScenarioInfo().Options.RestrictedCategories or {} do
            for _, category in restrictedUnits[generalCategory].categories or {} do
                newBuildableCategories = newBuildableCategories - ParseEntityCategory(category)
            end
        end

        local factionCategory = ParseEntityCategory(faction)
        SetIgnoreSelection(true)

        -- LAND
        UISelectionByCategory('LAND RESEARCH TECH3 ' .. faction, false, false, false, false)
        if not GetSelectedUnits() then
            newBuildableCategories = newBuildableCategories - (categories.LAND * categories.SUPPORTFACTORY * categories.TECH3 * factionCategory)
            UISelectionByCategory('LAND RESEARCH TECH2 ' .. faction, false, false, false, false)
            if not GetSelectedUnits() then
                newBuildableCategories = newBuildableCategories - (categories.LAND * categories.SUPPORTFACTORY * categories.TECH2 * factionCategory)
            end
        end

        -- AIR
        UISelectionByCategory('AIR RESEARCH TECH3 ' .. faction, false, false, false, false)
        if not GetSelectedUnits() then
            newBuildableCategories = newBuildableCategories - (categories.AIR * categories.SUPPORTFACTORY * categories.TECH3 * factionCategory)
            UISelectionByCategory('AIR RESEARCH TECH2 ' .. faction, false, false, false, false)
            if not GetSelectedUnits() then
                newBuildableCategories = newBuildableCategories - (categories.AIR * categories.SUPPORTFACTORY * categories.TECH2 * factionCategory)
            end
        end

        -- Naval
        UISelectionByCategory('NAVAL RESEARCH TECH3 ' .. faction, false, false, false, false)
        if not GetSelectedUnits() then
            newBuildableCategories = newBuildableCategories - (categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH3 * factionCategory)
            UISelectionByCategory('NAVAL RESEARCH TECH2 ' .. faction, false, false, false, false)
            if not GetSelectedUnits() then
                newBuildableCategories = newBuildableCategories - (categories.NAVAL * categories.SUPPORTFACTORY * categories.TECH2 * factionCategory)
            end
        end

        SelectUnits(selection)
        SetIgnoreSelection(false)
    end

    return newBuildableCategories
end
