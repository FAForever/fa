
-- summary of the results

-- Array01       = 0.00512
-- Array02       = 0.00830
-- Array04       = 0.01464
-- Array08       = 0.02685
-- Array16       = 0.0512

-- ArrayCached01 = 0.00341
-- ArrayCached02 = 0.00610
-- ArrayCached04 = 0.008300
-- ArrayCached08 = 0.012939
-- ArrayCached16 = 0.02099

-- The speed up of just caching is astounding - even in the situation where we cache it for a 
-- single use. When we look at the byte code we see the following pattern:
-- Array:       GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD, GETTABLE, ADD
-- ArrayCached: GETTABLE, GETTABLE, GETTABLE, GETTABLE, ADD, ADD, ADD, ADD

-- I can not confirm it, but I suspect the get table is optimized to quickly get several 
-- elements in succession. This may be just the cacheline of the CPU, but we see a similar 
-- behavior with the hashed part of a table.

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00512

function Array01()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00830

function Array02()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.01464

function Array04()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.02685

function Array08()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.0512

function Array16()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
        
        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]

        sum = sum + element[1]
        sum = sum + element[2]
        sum = sum + element[3]
        sum = sum + element[4]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00341

function ArrayCached01()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.00610

function ArrayCached02()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.008300

function ArrayCached04()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.012939

function ArrayCached08()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

-- ran by: (Jip) Willem Wijnia
-- hardware: AMD Ryzen 3600 6-core
-- time: 0.02099

function ArrayCached16()

    local element = { 1, 2, 3, 4 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 

        local el1 = element[1]
        local el2 = element[2]
        local el3 = element[3]
        local el4 = element[4]

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4

        sum = sum + el1
        sum = sum + el2
        sum = sum + el3
        sum = sum + el4
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end