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

-- upvalue scope for performance
local TableGetn = table.getn
local StringFormat = string.format

--- Interrupts the pathfinding of the given units. This has various interesting side effects as the 'done with pathfinding' signal is used in various commands. As a few examples:
--- - For engineers that are building they can start building from further away (but still within the build range)
--- - For engineers that are on a patrol or an attack move the engineer can start reclaiming from further away 
--- - For engineers that are assisting they can start assisting immediately if the target is in range (instead of moving into formation)
--- - For transports that are unloading units are deattached immediately when aborting the move command
---@param units Unit[]
---@param doPrint boolean           # if true, prints information about the order
function AbortNavigation(units, doPrint)
    local unitCount = TableGetn(units)

    if unitCount == 0 then
        return
    end

    for k = 1, unitCount do
        local unit = units[k]
        if not IsDestroyed(unit) then
            local navigator = unit:GetNavigator()
            navigator:AbortMove()
        end
    end

    local brain = units[1]:GetAIBrain()
    if doPrint and (GetFocusArmy() == brain:GetArmyIndex()) then
        print(StringFormat("Interrupted pathfinding for %s unit(s)", unitCount))
    end
end
