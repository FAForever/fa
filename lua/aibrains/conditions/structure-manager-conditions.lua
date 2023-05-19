
-----------------------------------------------------------------
-- Summary: Contains all builder conditions that directly
-- interface with the factory manager
--
-- All functions in this file are efficient
-----------------------------------------------------------------

local TableGetSize = table.getsize

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessStructuresByTech(aiBrain, base, count, tech)
    if base.StructureManager.Structures[tech] < count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreStructuresByTech(aiBrain, base, count, tech)
    if base.StructureManager.Structures[tech] > count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessStructuresBeingbuiltByTech(aiBrain, base, count, tech)
    if base.StructureManager.StructureBeingBuiltCount[tech] < count then
        return true
    end

    return false
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreStructuresBeingbuiltByTech(aiBrain, base, count, tech)
    if base.StructureManager.StructureBeingBuiltCount[tech] > count then
        return true
    end

    return false
end
