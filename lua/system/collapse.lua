# a set of functions that remove objects from tables
# the function passed in will take the item as input, and return true if it should be removed, false otherwise

# given an array of items, collapses the array by removing destroyed items and shifting them down
local ipairs = ipairs
local tableInsert = table.insert
local tableRemove = table.remove
local next = next
local tableGetn = table.getn

function collapseArray(objectArray, isDestroyedFunc)
    local arraySize = tableGetn(objectArray)
    local removeTable = {}
    for index = 1, arraySize do
        if isDestroyedFunc(objectArray[index]) then
            tableInsert(removeTable, index)
        end
    end

    for k,index in removeTable do
        tableRemove(objectArray, index)
    end
end

# given a table of items, collapses the array by removing entries, but not changing keys
function collapseTable(objectTable, isDestroyedFunc)
    local removeTable = {}
    for k,v in objectTable do
        if isDestroyedFunc(v) then
            tableInsert(removeTable, k)
        end
    end

    for k,v in removeTable do
        objectTable[v] = nil
    end
end

