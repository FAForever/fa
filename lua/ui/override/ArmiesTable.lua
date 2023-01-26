---@class ArmiesTable
---@field armiesTable ArmyInfo[]
---@field numArmies number
---@field focusArmy number

---@class ArmyInfo
---@field armyIndex number
---@field civilian boolean
---@field color string
---@field faction number
---@field human boolean
---@field name string
---@field nickname string
---@field outOfGame boolean
---@field showScore boolean

-- keep a reference to the actual function
local GlobalGetArmiesTable = _G.GetArmiesTable

--- Allows UI elements to be updated when the cache is updated by adding a callback via Observable:AddObserver()
local Cached = GlobalGetArmiesTable()
Observable = import("/lua/shared/observable.lua").Create()
Observable:Set(Cached)

--- Interval for when we update the cache
local TickInterval = 2.0

--- A counter that keeps track of how often the interval was increased,
-- allows us to keep track of when we really want to reset it. As an example,
-- when FastInterval() is called again before ResetInterval() is.
local TickIntervalResetCounter = 0

--- A simple tick thread that updates the cache
local function TickThread()
    while true do 
        -- allows us to be more responsive on tick interval changes
        WaitSeconds(0.5 * TickInterval)
        WaitSeconds(0.5 * TickInterval)
        WaitSeconds(0.5 * TickInterval)
        WaitSeconds(0.5 * TickInterval)

        -- update the cache and inform observers
        Cached = GlobalGetArmiesTable()
        Observable:Set(Cached)
    end
end

--- Override global function to return our cache
_G.GetArmiesTable = function()
    return Cached
end

--- A getter to return the check interval
function GetInterval()
    return TickInterval
end

--- Increases the check interval to every 0.025 seconds or a framerate of 40.
function FastInterval()
    TickIntervalResetCounter = TickIntervalResetCounter + 1
    TickInterval = 0.025
end

--- Resets the interval to every 2.0 seconds or a framerate of 0.5.
function ResetInterval()
    TickIntervalResetCounter = TickIntervalResetCounter - 1
    if TickIntervalResetCounter == 0 then 
        TickInterval = 2.0
    end
end

ForkThread(TickThread)