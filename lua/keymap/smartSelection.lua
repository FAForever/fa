-- example usage: select all idle air units, excluding transports and bombers
-- smartSelect("AIR MOBILE +idle -TRANSPORTATION -BOMBER")

-- to bind this as a hotkey in your game.prefs make an action like this:
-- UI_Lua import("/lua/keymap/smartSelection.lua").smartSelect("AIR MOBILE +idle -TRANSPORTATION -BOMBER")


-- sets selection as per string expression
function smartSelect(strExpression)
  
  -- some of these calls crash game if bad category name, so wrap in pcall
  local success, value = pcall(function() 
	local expression = compile(strExpression)
	LOG(repr(expression))  
	setSelection(expression)
	return expression
  end)

  if success == false then
     LOG("smartSelect failed: " .. strExpression)
  end
end


-- sets selection as per compiled expression
function setSelection(expression)
  local others = join(expression.others, " ")
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
  result.others = {};
  result.negatives = {}

  local tokens = strSplit(strExpression, "%s")
  for k,v in tokens do
   
    -- tokens with minus symbol are "negative"
    if startsWith(v, "-") then
       local withoutSymbol = string.sub(v,2)
       table.insert(result.negatives, withoutSymbol)
   
    -- everything else is an "other". This includes categories (eg: AIR) and modifiers (eg: +idle)
    else
       table.insert(result.others, v)
    end

  end
  return result
end


-- join strings together
function join(items, delimiter)
   local str = "";
   for k,v in items do
     str = str .. v .. delimiter
   end
   return str
end


-- split strings - from internet
function strSplit(str, pat)
   local t = {}  
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= str:len() then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


-- does string start with value - from internet
function startsWith(stringToMatch, valueToSeek)
   return string.sub(stringToMatch,1,valueToSeek:len())==valueToSeek
end


smartSelect("AIR -TRANSPORTATION MOBILE +idle")
