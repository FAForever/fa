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

---@class Client
---@field authorizedCommandSources number[]
---@field connected boolean
---@field ejectedBy number[]
---@field local boolean
---@field name string
---@field ping number
---@field quiet number
---@field uid string

local Prefs = import("/lua/user/prefs.lua")

---@type 'on' | 'allies-only' | 'off'
OptionShowPlayerNames = Prefs.GetFromCurrentProfile('options.options_show_player_names') or 'on'

---@param clients Client[]
---@return Client[]
local function PostprocessClients(clients)
    local focusArmy = GetFocusArmy()

    if OptionShowPlayerNames == 'off' then
        for i, client in ipairs(clients) do
            if (i != focusArmy) then
                client.name = string.format('Player %d', i)
            end
        end
    elseif OptionShowPlayerNames == 'allies-only' then
        for i, client in ipairs(clients) do
            if i != focusArmy and (focusArmy > 0 and IsEnemy(i, focusArmy)) then
                client.name = string.format('Player %d', i)
            end
        end
    end

    return clients
end

-- keep a reference to the actual function
local GlobalGetSessionClients = _G.GetSessionClients

--- Allows UI elements to be updated when the cache is updated by adding a callback via Observable:AddObserver()
---@type Client[]
local Cached = PostprocessClients(GlobalGetSessionClients())

Observable = import("/lua/shared/observable.lua").Create()
Observable:Set(Cached)

--- Override global function to return our cache
---@return Client[]
_G.GetSessionClients = function()
    return Cached
end

--- A simple tick thread that updates the cache
local function TickThread()
    while true do
        -- allows us to be more responsive on tick interval changes
        WaitSeconds(0.1)
        -- update the cache and inform observers
        Cached = PostprocessClients(GlobalGetSessionClients())
        Observable:Set(Cached)
    end
end

ForkThread(TickThread)

-------------------------------------------------------------------------------
--#region Deprecated functionality

--- Interval for when we update the cache
local TickInterval = 2.0

--- A counter that keeps track of how often the interval was increased,
-- allows us to keep track of when we really want to reset it. As an example,
-- when FastInterval() is called again before ResetInterval() is.
local TickIntervalResetCounter = 0

---@deprecated
function GetInterval()
    return TickInterval
end

---@deprecated
function FastInterval()
    TickIntervalResetCounter = TickIntervalResetCounter + 1
    TickInterval = 0.025
end

---@deprecated
function ResetInterval()
    TickIntervalResetCounter = TickIntervalResetCounter - 1
    if TickIntervalResetCounter == 0 then
        TickInterval = 2.0
    end
end

-------------------------------------------------------------------------------
