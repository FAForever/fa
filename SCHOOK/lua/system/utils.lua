#=========================================================================================================
# StringJoin returns items as a single string, seperated by the delimiter
#=========================================================================================================

function StringJoin(items, delimiter)
  local str = "";
  for k,v in items do
    str = str .. v .. delimiter
  end
  return str
end


#=========================================================================================================
# StringJoin divides a single string, by the delimiter, into many string - and returns them in a table
#=========================================================================================================

function StringSplit(str, pat)
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


#=========================================================================================================
# StringStartsWith returns true if the string starts with the specified value
#=========================================================================================================

function StringStartsWith(stringToMatch, valueToSeek)
   return string.sub(stringToMatch,1,valueToSeek:len())==valueToSeek
end
