
---@param aiBrain AIBrain
---@param base AIBase
---@param platoon AIPlatoon
function CanBuildTech3 (aiBrain, base, platoon)
    local unit = platoon:GetPlatoonUnits()[1]
    local tech = unit.Blueprint.TechCategory
    return (tech == 'EXPERIMENTAL') or (tech == "TECH3")
end

---@param aiBrain AIBrain
---@param base AIBase
---@param platoon AIPlatoon
function CanBuildTech2 (aiBrain, base, platoon)
    local unit = platoon:GetPlatoonUnits()[1]
    local tech = unit.Blueprint.TechCategory
    return (tech == 'EXPERIMENTAL') or (tech == "TECH3") or (tech == "TECH2")
end


