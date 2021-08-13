
-- FunctionCall: 0.00332
-- ThreadCall: 0.12336
-- NoCall: 0.00054

-- A disclaimer to these results is that the fork thread doesn't actually do the work, the call only 
-- allocates a new thread and that starts doing the work after the current thread is finished. Therefore 
-- the real work is not part of the benchmark. All that we are seeing here are the costs to launch 
-- a new thread.

function FunctionCall()

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        AddToSum()
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function ThreadCall()

    local sum = 0
    local function AddToSum()
        sum = sum + 1
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        ForkThread(AddToSum)
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function NoCall()

    local sum = 0

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do 
        sum = sum + 1
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end