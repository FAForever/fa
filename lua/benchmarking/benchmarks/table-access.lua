
-- EntriesBracketShort: 0.00109
-- EntriesBracketLong:  0.00109
-- EntriesDotShort:     0.00109
-- EntriesDotLong:      0.00109

-- conclusion: there is no difference.

function EntriesBracketShort()

    local data = { a = 1 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + data["a"]
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function EntriesBracketLong()

    local data = { ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong = 1}

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + data["ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong"] 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function EntriesDotShort()

    local data = { a = 1 }

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + data.a
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end

function EntriesDotLong()

    local data = { ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong = 1}

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local sum = 0
    for k = 1, 100000 do 
        sum = sum + data.ThisIsASuperLongEntryAndDoesThatMatterOrNotBecauseManThisStuffIsLong
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start
end