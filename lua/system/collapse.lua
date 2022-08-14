-- a set of functions that remove objects from tables
-- the function passed in will take the item as input, and return true if it should be removed, false otherwise

-- given an array of items, collapses the array by removing destroyed items and shifting them down
function collapseArray(objectArray, isDestroyedFunc)
    local arraySize = table.getn(objectArray)
    local removeTable = {}
    for index = 1, arraySize do
        if isDestroyedFunc(objectArray[index]) then
            table.insert(removeTable, index)
        end
    end

    for k,index in removeTable do
        table.remove(objectArray, index)
    end
end

-- given a table of items, collapses the array by removing entries, but not changing keys
function collapseTable(objectTable, isDestroyedFunc)
    local removeTable = {}
    for k,v in objectTable do
        if isDestroyedFunc(v) then
            table.insert(removeTable, k)
        end
    end

    for k,v in removeTable do
        objectTable[v] = nil
    end
end

