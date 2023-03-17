-- example usage: select all idle air units, excluding transports and bombers
-- smartSelect("AIR MOBILE +idle -TRANSPORTATION -BOMBER")
-- to bind this as a hotkey in your game.prefs make an action like this:
-- UI_Lua import("/lua/keymap/smartselection.lua").smartSelect("AIR MOBILE +idle -TRANSPORTATION -BOMBER")

local utils = import("/lua/system/utils.lua")


-- sets selection as per string expression
function smartSelect(strExpression)

  -- some of these calls crash game if bad category name, so wrap in pcall
  local success, value = pcall(function()
    local expression = compile(strExpression)
    --LOG(repr(expression))
    setSelection(expression)
    return expression
  end)

  if success == false then
    LOG("smartSelect failed: " .. strExpression)
  end
end


-- sets selection as per compiled expression
function setSelection(expression)
  local others = utils.StringJoin(expression.others, " ")

  ConExecute("Ui_SelectByCategory " .. others)
  local units = GetSelectedUnits()

  for k,v in expression.negatives do
    if units ~= nil then
        units = EntityCategoryFilterOut(categories[v], units)
    end
  end

  SelectUnits(units)
end


-- convert a string expression into tokens
function compile(strExpression)
  local result = {}
  result.others = {}
  result.negatives = {}

  local tokens = utils.StringSplit(strExpression, " ") -- split by space
  for k,v in tokens do

    if utils.StringStartsWith(v, "-") then
      -- tokens with minus symbol are "negative"
      local withoutSymbol = string.sub(v,2)
      table.insert(result.negatives, withoutSymbol)

    else
      -- everything else is an "other". This includes categories (eg: AIR) and modifiers (eg: +idle)
       table.insert(result.others, v)
    end

  end

  return result
end
