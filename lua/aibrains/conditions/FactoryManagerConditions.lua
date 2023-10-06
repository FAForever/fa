
-----------------------------------------------------------------
-- Summary: Contains all builder conditions that directly
-- interface with the factory manager
--
-- All functions in this file are efficient
-----------------------------------------------------------------

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessHQFactoriesByTech(aiBrain, base, count, tech)
    if base.FactoryManager.FactoryCount['RESEARCH'][tech] < count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreHQFactoriesByTech(aiBrain, base, count, tech)
    if base.FactoryManager.FactoryCount['RESEARCH'][tech] > count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessSupportFactoriesByTech(aiBrain, base, count, tech)
    if base.FactoryManager.FactoryCount['SUPPORT'][tech] < count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreSupportFactoriesByTech(aiBrain, base, count, tech)
    if base.FactoryManager.FactoryCount['SUPPORT'][tech] > count then
        return true
    end

    return false
end