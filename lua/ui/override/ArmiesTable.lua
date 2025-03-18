--******************************************************************************************************
--** Copyright (c) 2024  FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

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

local Prefs = import("/lua/user/prefs.lua")

---@type 'on' | 'allies-only' | 'off'
OptionShowPlayerNames = Prefs.GetFromCurrentProfile('options.options_show_player_names')

---@param armiesTable ArmiesTable
---@return ArmiesTable
local function PostprocessArmiesTable(armiesTable)
    local focusArmy = GetFocusArmy()

    if OptionShowPlayerNames == 'off' then
        for i, client in ipairs(armiesTable.armiesTable) do
            if (not client.civilian) then
                client.nickname = string.format('Player %d', i)
            end
        end
    elseif OptionShowPlayerNames == 'allies-only' then
        for i, client in ipairs(armiesTable.armiesTable) do
            if (not client.civilian) then
                if (focusArmy > 0 and IsEnemy(i, focusArmy)) then
                    client.nickname = string.format('Player %d', i)
                end
            end
        end
    end

    return armiesTable
end

-- keep a reference to the actual function
local GlobalGetArmiesTable = _G.GetArmiesTable

--- Allows UI elements to be updated when the cache is updated by adding a callback via Observable:AddObserver()
local Cached = PostprocessArmiesTable(GlobalGetArmiesTable())
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
        Cached = PostprocessArmiesTable(GlobalGetArmiesTable())
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
