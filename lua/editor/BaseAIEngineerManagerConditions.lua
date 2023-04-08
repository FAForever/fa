-----------------------------------------------------------------
-- Summary: Contains all builder conditions that directly
-- interface with the refactored engineer manager
--
-- All functions in this file are guaranteed to be efficient
-----------------------------------------------------------------

--- Compares (using `<`) the count to the number of engineers at a location type
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@return boolean
function LessEngineersThan(aiBrain, locationType, count)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    if engineerManager:GetNumUnits() < count then
        return true
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers at a location type
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@return boolean
function GreaterEngineersThan(aiBrain, locationType, count)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    if engineerManager:GetNumUnits() > count then
        return true
    end

    return false
end

--- Compares (using `<`) the count to the number of engineers of a given tech at a location type
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@param tech TechCategory
---@return boolean
function LessEngineersByTech(aiBrain, locationType, count, tech)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    if engineerManager:GetNumUnitsByTech(tech) < count then
        return true
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers of a given tech at a location type
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@param tech TechCategory
---@return boolean
function GreaterEngineersByTech(aiBrain, locationType, count, tech)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    if engineerManager:GetNumUnitsByTech(tech) > count then
        return true
    end

    return false
end

---@type { TECH1: TechCategory[], TECH2: TechCategory[], TECH3: TechCategory[] }
local lookUpBetterTech = {
    TECH1 = { 'TECH1', 'TECH2', 'TECH3', 'SUBCOMMANDER' },
    TECH2 = { 'TECH2', 'TECH3', 'SUBCOMMANDER' },
    TECH3 = { 'TECH3', 'SUBCOMMANDER' },
}

--- Compares (using `<`) the count to the number of engineers of a given tech at a location type. Similar to the 'some' operator, one tech is sufficient to pass
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@param techs TechCategory[]
---@return boolean
function LessEngineersByTechList(aiBrain, locationType, count, techs)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    for _, tech in techs do
        if engineerManager:GetNumUnitsByTech(tech) < count then
            return true
        end
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers of a given tech at a location type. Similar to the 'some' operator, one tech is sufficient to pass
---@param aiBrain BaseAIBrain
---@param locationType LocationType
---@param count number
---@param techs TechCategory[]
---@return boolean
function LessEngineersByTechList(aiBrain, locationType, count, techs)
    local engineerManager = aiBrain.BuilderManagers[locationType].EngineerManager --[[@as BaseAIEngineerManager]]
    for _, tech in techs do
        if engineerManager:GetNumUnitsByTech(tech) > count then
            return true
        end
    end

    return false
end
