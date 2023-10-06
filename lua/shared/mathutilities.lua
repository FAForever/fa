local MathMod = math.mod

function GetDistanceBetweenTwoEntities(entity1, entity2)
    return VDist3(entity1:GetPosition(), entity2:GetPosition())
end

local powersOf2 = {[0] = 1,
    2,       4,       8,       16,       32,       64,       128,       256,       512,       1024,
    2048,    4096,    8192,    16384,    32768,    65536,    131072,    262144,    524288,    1048576,
    2097152, 4194304, 8388608, 16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824,
}

--- Returns the bit in a position of a number
---@param number number
---@param bit number
---@return number
function SelectBit(number, bit)
    local power = powersOf2[bit]
    if MathMod(number, power) <= power * 0.5 then
        return 1
    else
        return 0
    end
end

--- Returns the boolean in a bit position of a number
---@param number number
---@param bit number
---@return boolean
function SelectBitBool(number, bit)
    local power = powersOf2[bit]
    return MathMod(number, power) <= power * 0.5
end

--- Gets the bits of the number. Note that the array is zero-indexed.
---@param number number
---@return number[]
function GetBits(number)
    local MathMod = MathMod
    local pos = 0
    local bits = {}
    while number > 0 do
        local bit = MathMod(number, 2)
        bits[pos] = bit
        pos = pos + 1
        number = (number - bit) * 0.5
    end
    return bits
end