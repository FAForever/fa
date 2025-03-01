--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
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

---@type integer
local OnPauseClientIndex = -1

---@type number
local OnPauseTimestamp = 0

---@type number
local ResumeThreshold = 10 -- seconds

---@return integer  # The index of the client, like the parameter `pausedBy` of OnPause
---@return Client?  # The data of the client
local function FindLocalClient()
    local allClients = GetSessionClients()
    for k = 1, table.getn(allClients) do
        local client = allClients[k]
        if client["local"] then
            return k, client
        end
    end

    return -1, nil
end

--- Called from `gamemain.lua` when the simulation pauses for all clients.
---@param pausedBy integer  # The index of the client in the clients list (that you get via `GetSessionClients`)
---@param timeoutsRemaining number
function OnPause(pausedBy, timeoutsRemaining)
    -- keep track of who paused and when
    OnPauseClientIndex = pausedBy
    OnPauseTimestamp = GetSystemTimeSeconds()
end

--- Called by the engine when the simulation resumed for all clients.
function OnResume()
    OnPauseClientIndex = -1
    OnPauseTimestamp = 0
end

-- Called immediately by the engine on the machine that initiated the pause. This function is called only by the client that is initiating the (un)pause.
function OnUserPause(pause)
end

local oldSessionRequestPause = _G.SessionRequestPause
_G.SessionRequestPause = function()
    -- makes no sense to request a pause on top of a pause
    if SessionIsPaused() then
        return
    end

    oldSessionRequestPause()
end

local oldSessionResume = _G.SessionResume
---@return 'Accepted' | 'Declined'
_G.SessionResume = function()
    local localClientIndex, clientData = FindLocalClient()
    local timeDifference = GetSystemTimeSeconds() - OnPauseTimestamp

    -- conditions that allow an immediate resume of the session
    if SessionIsReplay() or
        not SessionIsMultiplayer() or
        OnPauseClientIndex == localClientIndex or -- feature: the person who initiated the pause can resume at any time
        timeDifference > ResumeThreshold -- feature: any person can resume after the pause lasted past the threshold
    then
        SessionSendChatMessage({ SendResumedBy = true })
        oldSessionResume()
        return 'Accepted'
    else
        -- inform other clients
        SessionSendChatMessage(import('/lua/ui/game/clientutils.lua').GetAll(), {
            to = 'all',
            text = string.format('Wants to resume the game but has to wait %d seconds', ResumeThreshold - timeDifference),
            Chat = true,
        })

        return 'Declined'
    end
end
