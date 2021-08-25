
function EachIterationNothing()

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    for k = 1, 100000 do

    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end

function EachIterationString()

    local function ToCall()
    end

    local start = GetSystemTimeSecondsOnlyForProfileUse()

    local string = "to-test-this-long-string"
    for k = 1, 100000 do
        local test = string .. k 
    end

    local final = GetSystemTimeSecondsOnlyForProfileUse()

    return final - start

end