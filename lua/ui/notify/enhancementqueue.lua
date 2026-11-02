-- This file contains the functions needed to keep track of ACU upgrade queueing

local SetIgnoreSelection = import("/lua/ui/game/gamemain.lua").SetIgnoreSelection

--- Queue for enhancements. The currently upgrading enhancement is index 1.
---@alias EnhancementQueue table<EntityId, Enhancement[] | EnhQueueData[]>
local enhancementQueue = {}

---@param units UserUnit
---@param enhancement Enhancement
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

---@return EnhancementQueue
function getEnhancementQueue()
    return enhancementQueue
end

--- Removes the currently upgrading enhancement from the unit's enhancement queue
---@param unit UserUnit
function removeEnhancement(unit)
    local id = unit:GetEntityId()
    if enhancementQueue[id] and not table.empty(enhancementQueue[id]) then
        table.remove(enhancementQueue[id], 1)
    end
end

--- Removes all queued enhancements for the units
---@param units UserUnit[]
function clearEnhancements(units)
    for _, unit in units do
        local id = unit:GetEntityId()
        if enhancementQueue[id] then
            enhancementQueue[id] = {}
        end
    end
end

---@param unit UserUnit
---@return boolean
function currentlyUpgrading(unit)
    local currentCommand = unit:GetCommandQueue()[1]
    local queue = enhancementQueue[unit:GetEntityId()][1]

    return currentCommand.type == 'Script' and queue and not string.find(queue.ID, 'Remove') -- ex: "StabilitySuppressantRemove"
end

--- Returns buildable categories for the selection updated based on queued tech suite enhancements
---@param originalBuildables EntityCategory
---@param selection UserUnit[]
---@return EntityCategory
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

        SetIgnoreSelection(true)
        UISelectionByCategory("RESEARCH " .. faction, false, false, false, false)
        local hqs = GetSelectedUnits()
        if table.empty(hqs) then
            newBuildableCategories = newBuildableCategories - categories.SUPPORTFACTORY
        else
            local categories = categories
            local factionCategory = categories[faction]
            local supportFactories = newBuildableCategories - categories.SUPPORTFACTORY

            ---@param hq UserUnit
            for _, hq in hqs do
                local bp = hq:GetBlueprint()
                local hashedCategories = bp.CategoriesHash
                local supportCategory = categories.SUPPORTFACTORY * factionCategory

                if hashedCategories["TECH3"] then
                    supportCategory = supportCategory * (categories.TECH3 + categories.TECH2)
                elseif hashedCategories["TECH2"] then
                    supportCategory = supportCategory * categories.TECH2
                end

                if hashedCategories["LAND"] then
                    supportFactories = supportFactories + supportCategory * categories.LAND
                end
                if hashedCategories["AIR"] then
                    supportFactories = supportFactories + supportCategory * categories.AIR
                end
                if hashedCategories["NAVAL"] then
                    supportFactories = supportFactories + supportCategory * categories.NAVAL
                end
            end
            newBuildableCategories = newBuildableCategories * supportFactories
        end

        SelectUnits(selection)
        SetIgnoreSelection(false)
    end

    return newBuildableCategories
end
