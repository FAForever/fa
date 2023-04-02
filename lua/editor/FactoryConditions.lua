
--- Returns true when there is no HQ factory of given layer and tech. Uses the 
---@param aiBrain AIBrain
---@param layer HqLayer
---@param tech HqTech
function NoHQ (aiBrain, layer, tech)
    local faction = aiBrain:GetFactionName()
    if aiBrain:CountHQs(faction, layer, tech) == 0 then
        return true
    end

    return false
end

--- Returns true when there is one or more headquarters of a given layer and tech
---@param aiBrain AIBrain
---@param layer HqLayer
---@param tech HqTech
function HasHQ (aiBrain, layer, tech)
    local faction = aiBrain:GetFactionName()
    if aiBrain:CountHQs(faction, layer, tech) > 0 then
        return true
    end

    return false
end

--- Returns true when there are not sufficient redundant head quarters
---@param aiBrain AIBrain
---@param layer HqLayer
---@param tech HqTech
function InsufficientRedundantHQs (aiBrain, layer, tech, ratio)
    local faction = aiBrain:GetFactionName()
    local countHQ = aiBrain:CountHQs(faction, layer, tech)
    local countSupport = aiBrain:GetListOfUnits(categories[faction] * categories[layer] * categories[tech], false, false)
    if countHQ / countSupport < ratio then
        return true
    end

    return false
end
