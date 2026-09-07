--- The global `categories` table for entity categories allow set operations using add, sub, mul metamethods
--- 
--- By default each operation returns a new object with the result,
--- so that categories.LAND * categories.MOBILE ~= categories.LAND * categories.MOBILE
--- 
--- We can hook those meta methods and caches the results, significantly reducing object de/allocations.
--- 1h long mission test resuls:
--- - total lookups: 915 724
--- - hits:          907 963
--- - misses:        7 761
--- 99.15% hitrate
--- Average cache size ~195 entries
--- 
--- The test also indicated that the inner table of the cache should be pre-allocated with 4-hash size
--- which will cover ~95% cases

if not rawget(_G, "categories") then return end

local setmetatable = setmetatable
--local hits, misses = 0, 0

local weakV = {__mode = 'v'}
local weakK = {__mode = 'k'}

local mt = getmetatable(categories.ALLUNITS)
local cache_add = setmetatable({}, weakK)
local cache_sub = setmetatable({}, weakK)
local cache_mul = setmetatable({}, weakK)

local add = mt.__add
---@param a EntityCategory
---@param b EntityCategory
---@return EntityCategory
function mt.__add(a, b)
    local row = cache_add[a]
    if row then
        local res = row[b]
        if res then
            --hits = hits + 1
            return res
        end
    else
        row = setmetatable({&4 &0}, weakV) --preallocate for 4 hash entries
        cache_add[a] = row
    end

    --misses = misses + 1
    local res = add(a, b)
    row[b] = res
    return res
end

local sub = mt.__sub
---@param a EntityCategory
---@param b EntityCategory
---@return EntityCategory
function mt.__sub(a, b)
    local row = cache_sub[a]
    if row then
        local res = row[b]
        if res then
            --hits = hits + 1
            return res
        end
    else
        row = setmetatable({&4 &0}, weakV) --preallocate for 4 hash entries
        cache_sub[a] = row
    end

    --misses = misses + 1
    local res = sub(a, b)
    row[b] = res
    return res
end

local mul = mt.__mul
---@param a EntityCategory
---@param b EntityCategory
---@return EntityCategory
function mt.__mul(a, b)
    local row = cache_mul[a]
    if row then
        local res = row[b]
        if res then
            --hits = hits + 1
            return res
        end
    else
        row = setmetatable({&4 &0}, weakV) --preallocate for 4 hash entries
        cache_mul[a] = row
    end

    --misses = misses + 1
    local res = mul(a, b)
    row[b] = res
    return res
end

--[[

if not rawget(_G, "ForkThread") then return end

---Profiles the distribution of inner table sizes across powers of two.
---@return table<integer, integer> buckets Count of inner tables grouped by target power-of-two capacity
---@return integer peakSize Highest entry count recorded in a single inner table
local function getInnerTableHistogram(...)
    local buckets = {
        [0]  = 0, -- Empty shells
        [2]  = 0, -- 1-2 entries
        [4]  = 0, -- 3-4 entries
        [8]  = 0, -- 5-8 entries
        [16] = 0, -- 9-16 entries
        [32] = 0, -- 17-32 entries
        [64] = 0, -- 33-64 entries
        [128] = 0, -- 65+ entries
    }
    local peakSize = 0

    for k = 1, arg.n do
        local cache = arg[k]
        if cache then
            for _, row in pairs(cache) do
                local size = table.getsize(row)
                if size > peakSize then peakSize = size end

                if size == 0 then
                    buckets[0] = buckets[0] + 1
                elseif size <= 2 then
                    buckets[2] = buckets[2] + 1
                elseif size <= 4 then
                    buckets[4] = buckets[4] + 1
                elseif size <= 8 then
                    buckets[8] = buckets[8] + 1
                elseif size <= 16 then
                    buckets[16] = buckets[16] + 1
                elseif size <= 32 then
                    buckets[32] = buckets[32] + 1
                elseif size <= 64 then
                    buckets[64] = buckets[64] + 1
                else
                    buckets[128] = buckets[128] + 1
                end
            end
        end
    end

    return buckets, peakSize
end

---@param ... table<EntityCategory, EntityCategory>[]
---@return integer totalEntries
---@return integer minEntryCount
---@return integer maxEntryCount
---@return number avgEntryCount
local function get2DCacheSize(...)
    local total = 0
    local min = 999999999
    local max = 0
    local entries = 0
    for k = 1, arg.n do
        for _, row in pairs(arg[k]) do
            local size = table.getsize(row)
            if size > 0 then
                total = total + size
                entries = entries + 1
                min = math.min(min, size)
                max = math.max(max, size)
            end
        end
    end
    local avg = 0
    if entries > 0 then
        avg = total / entries
    else
        min = 0
    end
    return total, min, max, avg
end

ForkThread(function()
    local time = 10
    local lastH, lastM = hits, misses
    repeat
        WaitSeconds(time)

        local deltaH = hits - lastH
        local deltaM = misses - lastM
        local total = deltaH + deltaM
        local perTick = total / (time * 10)

        lastH, lastM = hits, misses

        local size, min, max, avg = get2DCacheSize(cache_add, cache_sub, cache_mul)
        local buckets, peak = getInnerTableHistogram(cache_add, cache_sub, cache_mul)

        LOG(string.format("Cache size: %d, min: %d, max: %d, avg: %.2f || totals: H: %d, M: %d || 10-sec avg: H: %d, M: %d  tick: %.2f",
            size, min, max, avg, hits, misses, deltaH, deltaM, perTick
        ))
        LOG(string.format(
            "Inner Table Stats | Peak: %d | [<=2]: %d | [<=4]: %d | [<=8]: %d | [<=16]: %d | [<=32]: %d | [>32]: %d | (Empty: %d)",
            peak, buckets[2], buckets[4], buckets[8], buckets[16], buckets[32], buckets[64] + buckets[128], buckets[0]
        ))
    until false
end)

--]]
