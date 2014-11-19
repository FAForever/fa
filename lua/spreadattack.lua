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
 ["Move"]               = "Move",
 ["Attack"]             = "Attack",
 ["AggressiveMove"]     = "AggressiveMove",
 ["FormMove"]           = "Move",                -- Form actions currently not supported
 ["FormAttack"]         = "Attack",              -- Form actions currently not supported
 ["FormAggressiveMove"] = "AggressiveMove",      -- Form actions currently not supported
}

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
  if not( TranslatedOrder[command.CommandType] ) then
    return
  end
  
  local Order = {
    CommandType = "",
    Position    = {},
    Target      = nil,
  }

  -- Fill in the Order table for the current order given
  Order.CommandType = TranslatedOrder[command.CommandType]
  Order.Position    = command.Target.Position
  Order.Target      = command.Target.EntityId
  
  -- Add this order to each individual unit.
  for _,unit in ipairs(command.Units) do

    -- Initialise the orders table, if needed.
    if not( ShadowOrders[unit:GetEntityId()] ) then
      ShadowOrders[unit:GetEntityId()] = {}
    end
    table.insert(ShadowOrders[unit:GetEntityId()],Order)
  end

end -- function MakeShadowCopyorders(command)


--------------------------
-- Function SpreadAttack()
--------------------------

-- This function rearranges all attack orders randomly for every unit.
function SpreadAttack()

  -- Get the currently selected units.
  local curSelection = GetSelectedUnits()

  if not ( curSelection ) then
    return
  end

  -- Switch the orders for each unit.
  for _,unit in ipairs(curSelection) do
    local unitorders = ShadowOrders[unit:GetEntityId()]

    -- Only mix orders if this unit has any orders to mix.
    if not( unitorders ) and not( unitorders[1] ) then 
      continue
    end
  
    -- Find all consecutive Attack orders, and only mix those.
    local beginAttack,endAttack,counter = nil,nil,1

    while unitorders[counter] ~= nil  do

      beginAttack = nil
      -- Search for the first entry of an Attack order.
      while beginAttack == nil and unitorders[counter] ~= nil do
        if unitorders[counter].CommandType == "Attack" then
          beginAttack = counter
        end
        counter = counter + 1
      end

      endAttack = beginAttack
      -- Search for the last entry of an Attack order in this series.
      while unitorders[counter] ~= nil do
        if unitorders[counter].CommandType == "Attack" then
          endAttack = counter
          counter = counter + 1
        else
          break
        end
      end
      
      -- Skip if there was no Attack found, or only one attack (can't swap one command).
      if beginAttack == nil or endAttack == beginAttack then
        break
      end

      -- Swap each order with a random other order.
      for i = beginAttack,endAttack do
        local randomorder = math.random(beginAttack,endAttack)
        if randomorder ~= i then
          unitorders[i],unitorders[randomorder] = unitorders[randomorder],unitorders[i]
        end
      end


      -- Repeat this loop and search for more Attack series.
    end
  
    -- All Attack orders have been mixed, now it's time to reassign those orders.
    -- Since giving orders is a Sim-side command, use a SimCallback function.
    SimCallback( { Func = "GiveOrders",
                   Args = { unit_orders = unitorders,
                            unit_id     = unit:GetEntityId(),
                            From = GetFocusArmy()}, 
                 }, false )

    -- Handle the next unit.
  end


end -- Function SpreadAttack()


----------------------------
-- Function GiveOrders(Data)
----------------------------

-- This function re-issues all shadow orders to the selected units.
-- Since the orders herein are Sim-side commands, this function needs to be called through a SimCallback.
function GiveOrders(Data)
    if OkayToMessWithArmy(Data.From) then --Check for cheats/exploits
        local unit = GetEntityById(Data.unit_id)
        -- Skip units with no valid shadow orders.
        if not( Data.unit_orders ) or not( Data.unit_orders[1] ) then
            return
        end

        -- All orders will be re-issued, so all existing orders have to be cleared first.
        IssueClearCommands( { unit } )

        -- Re-issue all orders.
        for _,order in ipairs(Data.unit_orders) do

            -- Currently supported 3 orders are: Attack, Move and AggressiveMove
            if order.CommandType == "Attack" then
                local victim = GetEntityById(order.Target)
                IssueAttack( { unit },victim)
            end

            if order.CommandType == "Move" then
                IssueMove( { unit },order.Position)
            end

            if order.CommandType == "AggressiveMove" then
                IssueAggressiveMove( { unit },order.Position)
            end
        end
    end

end -- function GiveOrders(Data,Units)
