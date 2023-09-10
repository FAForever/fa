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

local UnitQueueDataToCommand = import("/lua/sim/commands/shared.lua").UnitQueueDataToCommand
local PopulateLocation = import("/lua/sim/commands/shared.lua").PopulateLocation

---@type table
local dummyEmptyTable = {}

---@type { [1]: number, [2]: number, [3]: number }
local dummyVectorTable = {}

---@type { [1]: Unit }
local dummyUnitTable = {}

--- Copies the command queue of the target. Has a special snowflake implementation for build orders to prevent too many previews
---@param units Unit[]              # the units that we apply the copied orders to
---@param target Unit               # the unit that we read the queue of
---@param clearCommands boolean     # if true, copied orders are applied immediately
---@param doPrint boolean           # if true, prints the total distributed orders
CopyOrders = function(units, target, clearCommands, doPrint)

    ---------------------------------------------------------------------------
    -- defensive programming

    if table.empty(units) then
        return
    end

    if (not target) or (IsDestroyed(target)) then
        return
    end

    local brain = units[1]:GetAIBrain()

    ---------------------------------------------------------------------------
    -- retrieve the queue of the target

    local unitCount = table.getn(units)
    local queue = target:GetCommandQueue()

    ---------------------------------------------------------------------------
    -- clear existing orders

    if clearCommands then
        IssueClearCommands(units)
    end

    ---------------------------------------------------------------------------
    -- copy the orders

    local copiedOrders = 0

    for _, order in queue do
        local commandInfo = UnitQueueDataToCommand[order.commandType]
        local commandName = commandInfo.Type
        local issueOrder = commandInfo.Callback
        if issueOrder then
            if commandName == 'BuildMobile' then
                issueOrder(units, PopulateLocation(order, dummyVectorTable), order.blueprintId, dummyEmptyTable)
            else
                issueOrder(units, order.target or PopulateLocation(order, dummyVectorTable))
            end

            copiedOrders = copiedOrders + 1
        end
    end

    ---------------------------------------------------------------------------
    -- inform user and observers

    if doPrint and (GetFocusArmy() == brain:GetArmyIndex()) then
        print(string.format("Copied %d orders", tostring(copiedOrders)))
    end
end
