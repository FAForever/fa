
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

--- Distributes the orders of the unit in the selection that is closest to the mouse location
---@param clearCommands boolean
DistributeOrders = function(clearCommands)
    local mouse = GetMouseWorldPos()
    local selection = GetSelectedUnits()
    if mouse[1] and mouse[3] and selection and (not table.empty(selection)) then

        -- we only support distributing the orders of non-factory units. Factories
        -- use separate orders that would make the logic of this function much
        -- more complicated
        local validUnits = EntityCategoryFilterOut(categories.FACTORY, selection)

        if table.empty(validUnits) then
            print("No orders to distribute")
            return
        end

        -- find nearest unit
        local nearestUnit = validUnits[1]
        local shortestDistance = 4096 * 4096
        for k, unit in validUnits do
            local position = unit:GetPosition()
            local dx = position[1] - mouse[1]
            local dz = position[3] - mouse[3]
            local distance = dx * dx + dz * dz

            if distance < shortestDistance then
                nearestUnit = unit
                shortestDistance = distance
            end
        end

        -- determine if there are orders to distribute
        local queue = nearestUnit:GetCommandQueue()
        local queueCount = table.getn(queue)
        if queueCount > 0 then
            print(string.format("Distributing orders"))
            SimCallback({ Func = 'DistributeOrders', Args = { Target = nearestUnit:GetEntityId(), ClearCommands = clearCommands or false } }, true)
        else
            print("No orders to distribute")
        end
    else
        print("No orders to distribute")
    end
end

--- Distributes the orders of the unit that the mouse is hovering over
---@param clearCommands boolean
DistributeOrdersOfMouseContext = function(clearCommands)
    local target = GetRolloverInfo().userUnit
    if target then
        local orderCount = table.getn(target:GetCommandQueue())
        if orderCount > 0 then
            print(string.format("Distributing orders"))
            SimCallback({ Func = 'DistributeOrders', Args = { Target = target:GetEntityId() }, ClearCommands = clearCommands or false }, true)
        else
            print("No orders to distribute")
        end
    end
end