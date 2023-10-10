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

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessHQFactoriesThan(aiBrain, base, platoon, tech, layer, count)
    return base.FactoryManager.FactoryCount['RESEARCH'][tech][layer] < count
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreHQFactoriesThan(aiBrain, base, platoon, tech, layer, count)
    return base.FactoryManager.FactoryCount['RESEARCH'][tech][layer] > count
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function LessSupportFactoriesThan(aiBrain, base, platoon, tech, layer, count)
    return base.FactoryManager.FactoryCount['SUPPORT'][tech][layer] < count
end

---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@param tech TechCategory
---@return boolean
function MoreSupportFactoriesThan(aiBrain, base, platoon, tech, layer, count)
    return base.FactoryManager.FactoryCount['SUPPORT'][tech][layer] > count
end

---@param aiBrain AIBrain
---@param base AIBase
---@param platoon AIPlatoon
function ResearchedTech2 (aiBrain, base, platoon)
    local unit = platoon:GetPlatoonUnits()[1]
    local blueprint = unit.Blueprint
    return (aiBrain:CountHQs(blueprint.FactionCategory, blueprint.LayerCategory, 'TECH2') + aiBrain:CountHQs(blueprint.FactionCategory, blueprint.LayerCategory, 'TECH3')) > 0
end

---@param aiBrain AIBrain
---@param base AIBase
---@param platoon AIPlatoon
function ResearchedTech3 (aiBrain, base, platoon)
    local unit = platoon:GetPlatoonUnits()[1]
    local blueprint = unit.Blueprint
    return aiBrain:CountHQs(blueprint.FactionCategory, blueprint.LayerCategory, 'TECH3') > 0
end