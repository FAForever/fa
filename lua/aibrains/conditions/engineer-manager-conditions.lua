-----------------------------------------------------------------
-- Summary: Contains all builder conditions that directly
-- interface with the refactored engineer manager
--
-- All functions in this file are guaranteed to be efficient
-----------------------------------------------------------------

--- Compares (using `<`) the count to the number of engineers at a location type
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@return boolean
function LessEngineersThan(aiBrain, base, count)
    if base.EngineerManager.EngineerTotalCount() < count then
        return true
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers at a location type
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@return boolean
function MoreEngineersThan(aiBrain, base, count)
    if base.EngineerManager.EngineerTotalCount > count then
        return true
    end

    return false
end

--- Compares (using `<`) the count to the number of engineers of a given tech at a location type
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessEngineersByTech(aiBrain, base, count, tech)
    if base.EngineerManager.EngineerCount[tech] < count then
        return true
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers of a given tech at a location type
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreEngineersByTech(aiBrain, base, count, tech)
    if base.EngineerManager.EngineerCount[tech] > count then
        return true
    end

    return false
end

--- Compares (using `<`) the count to the number of engineers of a given tech at a location type. Similar to the 'some' operator, one tech is sufficient to pass
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param techs TechCategory[]
---@return boolean
function LessEngineersByTechList(aiBrain, base, count, techs)
    local engineerManager = base.EngineerManager
    for _, tech in techs do
        if engineerManager.EngineerCount[tech] < count then
            return true
        end
    end

    return false
end

--- Compares (using `>`) the count to the number of engineers of a given tech at a location type. Similar to the 'some' operator, one tech is sufficient to pass
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param techs TechCategory[]
---@return boolean
function LessEngineersByTechList(aiBrain, base, count, techs)
    local engineerManager = base.EngineerManager
    for _, tech in techs do
        if engineerManager.EngineerCount[tech] > count then
            return true
        end
    end

    return false
end
