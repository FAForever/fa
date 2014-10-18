------------------------------------------------------------------------
--                                                                    --
-- File           : /mod/TestCommandHook/spreadattack.lua             --
-- Author         : Magic Power                                       --
--                                                                    --
-- Summary  : Hooks an ingame key and spreads the attack orders given --
--                                                                    --
------------------------------------------------------------------------


-- This table contains a shadow copy of a subset of the real orders.
ShadowOrders = {}


-----------------------------------------
-- Function MakeShadowCopyOrders(command)
-----------------------------------------

-- Global variables needed for this function:

-- Some orders need to be changed for them to work when garbling orders.
-- Note that the Stop command is handled implicitly by the clear bit being set.
TranslatedOrder = {
    ["Move"]                    = "Move",
    ["Attack"]                  = "Attack",
    ["AggressiveMove"]          = "AggressiveMove",
    ["FormMove"]                = "Move",                -- Form actions currently not supported
    ["FormAttack"]              = "Attack",              -- Form actions currently not supported
    ["FormAggressiveMove"]      = "AggressiveMove",      -- Form actions currently not supported
    ['OverCharge']              = 'OverCharge',
    ["BuildMobile"]             = "BuildMobile",
    ["TransportUnloadUnits"]    = "TransportUnloadUnits",
    ["Reclaim"]                 = "Reclaim",
}

function orderHash(order)
    return order.CommandType .. order.Blueprint .. "x" .. order.Target.Position[1] .. "z" .. order.Target.Position[2] .. "y" .. order.Target.Position[3]
end

-- This function makes a shadow copy of the orders given to the units.
-- Due to it's use, only a subset of the orders will be kept.
function MakeShadowCopyOrders(command)
    -- The following subset of order is kept:
    -- - Move
    -- - Stop               : Special, it will not be shadow copied, but it's clear orders command will be executed
    -- - Attack
    -- - AggressiveMove
    -- - FormMove           : These orders are copied, but will be renamed to normal Move orders
    -- - FormAttack         : These orders are copied, but will be renamed to normal Attack orders
    -- - FormAggressiveMove : These orders are copied, but will be renamed to normal AggressiveMove orders

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
        CommandType = "",
        Target      = nil,
    }


    -- Fill in the Order table for the current order given
    Order.CommandType = TranslatedOrder[command.CommandType]
    Order.Blueprint   = command.Blueprint
    Order.Target      = command.Target
    Order.Hash      = orderHash(Order)

    -- Add this order to each individual unit.
    for _,unit in ipairs(command.Units) do
        -- Initialise the orders table, if needed.
        if not ShadowOrders[unit:GetEntityId()] then
            ShadowOrders[unit:GetEntityId()] = {}
        end
        table.insert(ShadowOrders[unit:GetEntityId()],Order)
    end
end -- function MakeShadowCopyorders(command)

function getNearestOrder(position, orders)
    local best = nil

    for id, o in orders do
        if(best == nil or VDist3(position, o.Target.Position) < VDist3(position, orders[best].Target.Position)) then
            best = id
        end
    end

    return best
end

function distributeOrders(all_orders, units)
    local final = {}
    local orders = {}
    local positions = {}
    local done = {}
    local n_orders = table.getsize(all_orders)
    local n_units = table.getsize(units)

    if n_orders == 0 then
        return {}
    end

    orders = table.copy(all_orders)

    while table.getsize(done) < 2 do
        for _, b in units do
            local id = b:GetEntityId()
            local best = nil
            local best_id = nil

            if table.getsize(orders) == 0 then
                orders = table.copy(all_orders)
                done[1] = true
            end

            if not final[id] then
                final[id] = {}
            end

            if not positions[id] then
                positions[id] = b:GetPosition()
            end

            best_id = getNearestOrder(positions[id], orders)
            if best_id then
                table.insert(final[id], orders[best_id])
                positions[id] = orders[best_id].Position
                orders[best_id] = nil
            end
        end

        done[2] = true
    end

    return final
end

function SpreadAttack()
    local selected = GetSelectedUnits() or {}
    local builders = {}
    local orders = {}
    local queue = {}

    for _, u in selected do
        local unit_orders = ShadowOrders[u:GetEntityId()]

        if unit_orders then
            for _, o in unit_orders do
                local hash = o.Hash

                if not orders[hash] then
                    orders[hash] = o
                end
            end
        end

        builders[u:GetEntityId()] = u
    end

    local final = distributeOrders(orders, builders)

    SimCallback({   Func = "GiveOrders",
                    Args = {final=final},
                }, false)

    UnitOrders = {}
end

function GiveOrders(Data)
    local final = Data.final
    local all_units = {}

    for id, orders in final do
        local unit = GetEntityById(id)
        table.insert(all_units, unit)
        IssueClearCommands({unit})
    end

    for id, orders in final do
        local unit = GetEntityById(id)

        for _, o in orders do
            local target

            if o.Target.Type == "Position" then
                target = o.Target.Position
            elseif o.Target.Type == "Entity" then
                target = GetEntityById(o.Target.EntityId)
            end

            if(not target) then
                return
            end

            if o.CommandType == "BuildMobile" then
                IssueBuildMobile({unit}, o.Target.Position, o.Blueprint, {})
            else
                _G['Issue'.. o.CommandType]({unit}, target)
            end
        end
    end
end
