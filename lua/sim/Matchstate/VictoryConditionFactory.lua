--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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

---@param victoryConditionType VictoryCondition
---@return AbstractVictoryCondition
GetVictoryConditionInstance = function(victoryConditionType)

    -- we load the modules in-line so that they are only loaded when used
    if victoryConditionType == 'demoralization' then
        return import('/lua/sim/Matchstate/DecapitationCondition.lua').CreateDecapitationCondition()
    elseif victoryConditionType == 'demoralization' then
        return import('/lua/sim/Matchstate/UnitCondition.lua').CreateUnitCondition(categories.COMMAND)
    elseif victoryConditionType == 'domination' then
        return import('/lua/sim/Matchstate/UnitCondition.lua').CreateUnitCondition(categories.STRUCTURE + categories.ENGINEER - categories.WALL)
    elseif victoryConditionType == 'eradication' then
        return import('/lua/sim/Matchstate/UnitCondition.lua').CreateUnitCondition(categories.ALLUNITS - categories.WALL)
    elseif victoryConditionType == 'sandbox' then
        return import('/lua/sim/Matchstate/SandboxCondition.lua').CreateSandBoxCondition()
    end

    -- default to sandbox
    WARN("Unknown victory condition type: " .. victoryConditionType)
    return import('/lua/sim/Matchstate/SandboxCondition.lua').CreateSandBoxCondition()
end
