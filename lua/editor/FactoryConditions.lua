
-- TODO: there should be some generic conversion for this
local mapFactionIndex = {
    "UEF",
    "AEON",
    "CYBRAN",
    "SERAPHIM",
    "NOMADS"
}

--- Returns true when there is no HQ factory of given layer and tech. Uses the 
---@param aiBrain AIBrain
---@param layer HqLayer
---@param tech HqTech
function NoHeadquarters (aiBrain, layer, tech)
    local faction = mapFactionIndex[aiBrain:GetFactionIndex()] --[[@as HqFaction]]
    if aiBrain.HQs[faction][layer][tech] == 0 then
        return true
    end

    return false
end

--- Returns true when there are not sufficient redundant head quarters
---@param aiBrain AIBrain
---@param layer HqLayer
---@param tech HqTech
function InsufficientRedundantHeadquarters (aiBrain, layer, tech, ratio)
    local faction = mapFactionIndex[aiBrain:GetFactionIndex()] --[[@as HqFaction]]
    local countHQ = aiBrain.HQs[faction][layer][tech] == 0
    local countSupport = aiBrain:GetListOfUnits(categories[faction] * categories[layer] * categories[tech], false, false)
    if countHQ / countSupport < ratio then
        return true
    end

    return false
end
