------------------------------------------------------------------------
-- File           : /mod/TestCommandHook/spreadattack.lua             --
-- Author         : Magic Power                                       --
-- Summary  : Hooks an ingame key and spreads the attack orders given --
------------------------------------------------------------------------

local TableGetN = table.getn

-- This table contains a shadow copy of a subset of the real orders.
ShadowOrders = {}

-----------------------------------------
-- Function MakeShadowCopyOrders(command)
-----------------------------------------

-- Global variables needed for this function:

-- Some orders need to be changed for them to work when garbling orders.
-- Note that the Stop command is handled implicitly by the clear bit being set.
TranslatedOrder = {
    ["AggressiveMove"]     = "AggressiveMove",
    ["Attack"]             = "Attack",
    ["Capture"]            = "Capture",
    ["Guard"]              = "Guard",
    ["Move"]               = "Move",
    ["Nuke"]               = "Nuke",
    ["OverCharge"]         = "OverCharge",
    ["Patrol"]             = "Patrol",
    ["Reclaim"]            = "Reclaim",
    ["Repair"]             = "Repair",
    ["Tactical"]           = "Tactical",
    ["FormAggressiveMove"] = "AggressiveMove",      -- Form actions currently not supported
    ["FormAttack"]         = "Attack",              -- Form actions currently not supported
    ["FormMove"]           = "Move",                -- Form actions currently not supported
    ["FormPatrol"]         = "Patrol",              -- Form actions currently not supported
}

-- This function makes a shadow copy of the orders given to the units.
-- Due to it's use, only a subset of the orders will be kept.
function MakeShadowCopyOrders(command)

    -- If the order has the Clear bit set, then all previously issued orders will be removed first,
    -- even if the specific order will not be handled below.
    -- This conveniently also handles the Stop order (= clear all orders).
    if command.Clear == true then
        for _,unit in ipairs(command.Units) do
            ShadowOrders[unit:GetEntityId()] = {}
        end
    end

    -- Skip handling the order if it does not belong to the given subset.
    if not TranslatedOrder[command.CommandType] then
        return
    end

    local Order = {
        CommandType = TranslatedOrder[command.CommandType],
        Position = command.Target.Position,
        EntityId = nil,
    }
    if command.Target.Type == "Entity" then
        Order.EntityId = command.Target.EntityId
    end

    -- Add this order to each individual unit.
    for _,unit in ipairs(command.Units) do

        -- Initialise the orders table, if needed.
        if not ShadowOrders[unit:GetEntityId()]  then
            ShadowOrders[unit:GetEntityId()] = {}
        end
        table.insert(ShadowOrders[unit:GetEntityId()],Order)
    end

end -- function MakeShadowCopyorders(command)


---------------------------
-- Function FixOrders(unit)
---------------------------

-- This function tries to fix a unit's moved or deleted shadow orders
-- based on its current command queue.
-- It can only get ability names and positions of current orders,
-- so it can't retarget orders with a changed entity target.
function FixOrders(unit)

    -- The factory exclusion is because GetCommandQueue doesn't work right for them.
    -- This means we can't fix orders for Fatboy, Megalith, Tempest, or carriers.
    if not unit or unit:IsInCategory("FACTORY") then
        return
    end

    local unitOrders = ShadowOrders[unit:GetEntityId()]
    if not unitOrders  or not unitOrders[1] then
        return
    end

    local queue = unit:GetCommandQueue()
    local filteredQueue = {}
    for _,command in ipairs(queue) do
        local Order = {
            CommandType = TranslatedOrder[command.type],
            Position = command.position,
        }
        if Order.CommandType then
            table.insert(filteredQueue, Order)
        end
    end

    local numOrders = TableGetN(unitOrders)

    -- We can't trust the shadow orders if commands were added without getting a copy.
    if numOrders < TableGetN(filteredQueue) then
        WARN("Spreadattack: Command queue is longer than the shadow order list.")
        return
    end

    -- First check for entire blocks of orders that have been deleted.
    local orderIndex = 1
    local queueIndex = 1
    local orderType = false
    local lastBlockType = false
    while orderIndex <= numOrders do
        orderType = unitOrders[orderIndex].CommandType
        local nextOrderIndex = orderIndex + 1
        while unitOrders[nextOrderIndex].CommandType == orderType do
            nextOrderIndex = nextOrderIndex + 1
        end

        if orderType == lastBlockType then
            orderIndex = nextOrderIndex
            continue
        end

        local nextQueueIndex = queueIndex
        while filteredQueue[nextQueueIndex].CommandType == orderType do
            nextQueueIndex = nextQueueIndex + 1
        end

         if nextQueueIndex == queueIndex then
            -- Block not found.
            for i = nextOrderIndex - 1, orderIndex, -1 do
                table.remove(unitOrders, i)
                numOrders = numOrders - 1
            end
            nextOrderIndex = orderIndex
        else
            lastBlockType = orderType
        end

        orderIndex = nextOrderIndex
        queueIndex = nextQueueIndex
    end

    -- Now fix the orders within each block of the same type.
    orderIndex = 1
    queueIndex = 1
    while orderIndex <= numOrders do
        orderType = unitOrders[orderIndex].CommandType
        local nextOrderIndex = orderIndex + 1
        local numEntityTargets = 0
        while unitOrders[nextOrderIndex].CommandType == orderType do
            if unitOrders[nextOrderIndex].EntityId then
                numEntityTargets = numEntityTargets + 1
            end
            nextOrderIndex = nextOrderIndex + 1
        end

        local nextQueueIndex = queueIndex
        while filteredQueue[nextQueueIndex].CommandType == orderType do
            nextQueueIndex = nextQueueIndex + 1
        end

        -- Check if orders were removed from the queue and try to identify them.
        local numDeletedOrders = nextOrderIndex - orderIndex - (nextQueueIndex - queueIndex)
        if numDeletedOrders ~= 0 then

            if numEntityTargets == 0 then
                -- With only position targets it doesn't matter which orders we delete.
                while numDeletedOrders > 0 do
                    table.remove(unitOrders, nextOrderIndex - 1)
                    numOrders = numOrders - 1
                    nextOrderIndex = nextOrderIndex - 1
                    numDeletedOrders = numDeletedOrders - 1
                end
                -- Fix the positions of any moved orders.
                for i = 0, nextOrderIndex - orderIndex - 1, 1 do
                    if not unitOrders[i + orderIndex].EntityId then
                        unitOrders[i + orderIndex].Position = filteredQueue[i + queueIndex].Position
                    end
                end
            else
                -- This part is only for the most complex situations and shouldn't be needed often in practice.
                -- Here we go through the block of orders and try to determine which to remove. Priority for removal:
                -- 1. Entity targets with a valid current position that don't match any command position (could have changed target)
                -- 2. position targets that don't match any command position (could have moved)
                -- 3. Entity targets with unknown current position that don't match any command position (could have moved or changed)
                local Matches = {}
                local lastMatchIndex = 0
                local lastMatchQueueIndex = queueIndex - 1
                local lastMatchAlignment = orderIndex - queueIndex
                for i = orderIndex, nextOrderIndex - 1, 1 do
                    local match = false
                    local priority = 2
                    local position = unitOrders[i].Position
                    if unitOrders[i].EntityId then
                        priority = 3
                        local target = GetUnitById(unitOrders[i].EntityId)
                        if target then
                            position = target:GetPosition()
                            priority = 1
                        end
                    end
                    for j = lastMatchQueueIndex + 1, nextQueueIndex - 1, 1 do
                        if VDist3Sq(position, filteredQueue[j].Position) <= 0.0001 then
                            -- If the shadow orders and command queue have the same number of entries since the last match,
                            -- mark any mismatches in between as matches since no orders were removed.
                            if i - j == lastMatchAlignment and j > lastMatchQueueIndex + 1 then
                                for k = 1, j - lastMatchQueueIndex - 1, 1 do
                                    Matches[k + lastMatchIndex].Priority = false
                                    Matches[k + lastMatchIndex].Match = k + lastMatchQueueIndex
                                end
                            else
                                lastMatchAlignment = i - j
                            end
                            match = j
                            priority = false
                            lastMatchQueueIndex = j
                            lastMatchIndex = TableGetN(Matches) + 1
                            break
                        end
                    end
                    table.insert(Matches, {Match = match, Priority = priority})
                end

                -- Delete unmatched commands by priority.
                for priority = 1, 3, 1 do
                    if numDeletedOrders <= 0 then
                        break
                    end
                    for i = TableGetN(Matches), 1, -1 do
                        if Matches[i].Priority == priority then
                            table.remove(Matches, i)
                            table.remove(unitOrders, i + orderIndex - 1)
                            numOrders = numOrders - 1
                            nextOrderIndex = nextOrderIndex - 1
                            numDeletedOrders = numDeletedOrders - 1
                            if numDeletedOrders <= 0 then
                                break
                            end
                        end
                    end
                end

                -- Fix the positions of any moved orders.
                local positionIndex = Matches[1].Match or queueIndex
                for i = 0, nextOrderIndex - orderIndex - 1, 1 do
                    if not unitOrders[i + orderIndex].EntityId then
                        if not Matches[i + 1].Match then
                            Matches[i + 1].Match = positionIndex
                        end
                        unitOrders[i + orderIndex].Position = filteredQueue[Matches[i + 1].Match].Position
                    end
                    positionIndex = (Matches[i + 1].Match or positionIndex) + 1
                end
            end

        else
            -- No orders were deleted so just fix any moved orders with position targets.
            for i = 0, nextOrderIndex - orderIndex - 1, 1 do
                if not unitOrders[i + orderIndex].EntityId then
                    unitOrders[i + orderIndex].Position = filteredQueue[i + queueIndex].Position
                end
            end
        end

        orderIndex = nextOrderIndex
        queueIndex = nextQueueIndex
    end
end


--------------------------
-- Function SpreadAttack()
--------------------------

-- This function rearranges all targeted orders randomly for every unit.
function SpreadAttack()

    -- Get the currently selected units.
    local curSelection = GetSelectedUnits()

    if not curSelection then
        return
    end

    -- Switch the orders for each unit.
    for index,unit in ipairs(curSelection) do
        FixOrders(unit)
        local unitOrders = ShadowOrders[unit:GetEntityId()]

        -- Only mix orders if this unit has any orders to mix.
        if not unitOrders or not unitOrders[1] then
            continue
        end

        -- Find all consecutive mixable orders, and only mix those.
        local beginAction,endAction,action,counter,actionAlwaysMixed = nil,nil,nil,1,false
        local alwaysMix = {"Attack", "Nuke", "Tactical"}

        while unitOrders[counter] ~= nil  do
            beginAction = nil
            -- Search for the first entry of a mixable order.
            while beginAction == nil and unitOrders[counter] ~= nil do
                for _,v in ipairs(alwaysMix) do
                    if unitOrders[counter].CommandType == v then
                        beginAction = counter
                        action = unitOrders[counter].CommandType
                        actionAlwaysMixed = true
                        break
                    elseif unitOrders[counter].EntityId then
                        beginAction = counter
                        action = unitOrders[counter].CommandType
                        actionAlwaysMixed = false
                    end
                end
                counter = counter + 1
            end

            endAction = beginAction
            -- Search for the last entry of a mixable order in this series.
            while unitOrders[counter] ~= nil do
                if unitOrders[counter].CommandType == action and (actionAlwaysMixed or unitOrders[counter].EntityId) then
                    endAction = counter
                    counter = counter + 1
                else
                    break
                end
            end

            -- Skip if there was no mixable order found, or only one order (can't swap one command).
            if beginAction == nil or endAction == beginAction then
                break
            end

            -- Rearrange the first few mixable orders (equal to the number of targets) so that the targets are uniformly distributed on the first pass.
            -- For example, 3 units attacking 8 units (? denotes random target):
            -- Unit 1: 1, 4, 7, ?, ?, ?, ?, ?
            -- Unit 2: 2, 5, 8, ?, ?, ?, ?, ?
            -- Unit 3: 3, 6, ?, ?, ?, ?, ?, ?
            local unitCount = TableGetN(curSelection)
            local numOrders = endAction - beginAction + 1
            -- "and 1 or 0" is lua's ugly alternative to the ternary operator. Same as (...) ? 1 : 0
            local stableTargetNum = math.floor(numOrders / unitCount) + ((math.mod(numOrders, unitCount) >= index) and 1 or 0)
            for i = 0, stableTargetNum - 1 do
                -- For if the targets outnumber the units targeting them.
                local targetBlock = i * unitCount
                unitOrders[i + beginAction],unitOrders[targetBlock + beginAction + index - 1]
                        = unitOrders[targetBlock + beginAction + index - 1],unitOrders[i + beginAction]
            end
            beginAction = beginAction + stableTargetNum

            -- Randomize the remaining mixable orders.
            for i = beginAction,endAction do
                local randomorder = math.random(beginAction,endAction)
                if randomorder ~= i then
                    unitOrders[i],unitOrders[randomorder] = unitOrders[randomorder],unitOrders[i]
                end
            end

            -- Repeat this loop and search for more mixable order series.
        end

        -- All targeted orders have been mixed, now it's time to reassign those orders.
        -- Since giving orders is a Sim-side command, use a SimCallback function.
        SimCallback( {
                Func = "GiveOrders",
                Args = {
                    unit_orders = unitOrders,
                    unit_id     = unit:GetEntityId(),
                    From = GetFocusArmy()
                }
            }, false)

        -- Handle the next unit.
    end

end -- Function SpreadAttack()


----------------------------
-- Function GiveOrders(Data)
----------------------------

local IssueOrderFunctions = nil

-- This function re-issues all shadow orders to the selected units.
-- Since the orders herein are Sim-side commands, this function needs to be called through a SimCallback.
function GiveOrders(Data)
    -- Doing this here ensures it's done in sim code instead of UI code.
    if not IssueOrderFunctions then
        IssueOrderFunctions = {
         ["Attack"]             = IssueAttack,
         ["Move"]               = IssueMove,
         ["Guard"]              = IssueGuard,
         ["Tactical"]           = IssueTactical,
         --["AggressiveMove"]     = IssueAggressiveMove,
         --["Capture"]            = IssueCapture,
         --["Nuke"]               = IssueNuke,
         --["OverCharge"]         = IssueOverCharge,
         --["Patrol"]             = IssuePatrol,
         --["Repair"]             = IssueRepair,
         --["Reclaim"]            = IssueReclaim,
        }
    end

    if OkayToMessWithArmy(Data.From) then --Check for cheats/exploits
        local unit = GetEntityById(Data.unit_id)

        -- add guard if unit died
        if unit and not unit.Dead then 
            
            -- Skip units with no valid shadow orders.
            if not Data.unit_orders or not Data.unit_orders[1] then
                return
            end

            if unit:GetBlueprint().CategoriesHash.BOMBER then
                for key, order in Data.unit_orders or {} do
                    if order.CommandType == "Move" then
                        local bomberPosition = unit:GetPosition()

                        --reject all move orders that are closer than 20
                        if VDist2(bomberPosition[1], bomberPosition[3], order.Position[1], order.Position[3]) < 20 then
                            table.remove (Data.unit_orders, key)
                        end
                    end
                end
            end

            -- All orders will be re-issued, so all existing orders have to be cleared first.
            IssueClearCommands({ unit })

            -- Re-issue all orders.
            for _,order in ipairs(Data.unit_orders) do
                local Function = IssueOrderFunctions[order.CommandType]
                if not Function then
                    continue
                end

                local target = order.Position
                if order.EntityId then
                    target = GetEntityById(order.EntityId)
                end
                if target then
                    Function({ unit }, target)
                end
            end
        end
    end
end -- function GiveOrders(Data)
