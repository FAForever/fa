------------------------------------------------------------------------
--                                                                    --
-- File           : /mod/TestCommandHook/spreadattack.lua             --
-- Author         : Magic Power                                       --
--                                                                    --
-- Summary  : Hooks an ingame key and spreads the attack orders given --
--                                                                    --
------------------------------------------------------------------------

local shadow = import('/lua/shadoworders.lua')
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
        shadow.FixOrders(unit)
        local unitOrders = shadow.ShadowOrders[unit:GetEntityId()]

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
            local unitCount = table.getn(curSelection)
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
