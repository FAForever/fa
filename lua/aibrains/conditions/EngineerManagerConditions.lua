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

--- Compares (using `<`) the count to the number of engineers at a location type
---@param aiBrain AIBrain
---@param base AIBase
---@param count number
---@return boolean
function LessEngineersThan(aiBrain, base, platoon, count)
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
function MoreEngineersThan(aiBrain, base, platoon, count)
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
function LessEngineersByTech(aiBrain, base, platoon, count, tech)
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
function MoreEngineersByTech(aiBrain, base, platoon, count, tech)
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
function LessEngineersByTechList(aiBrain, base, platoon, count, techs)
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
function LessEngineersByTechList(aiBrain, base, platoon, count, techs)
    local engineerManager = base.EngineerManager
    for _, tech in techs do
        if engineerManager.EngineerCount[tech] > count then
            return true
        end
    end

    return false
end
