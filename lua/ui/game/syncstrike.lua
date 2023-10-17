--******************************************************************************************************
--** Copyright (c) 2023  clyf
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

local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction
local RemoveBeatFunction = import("/lua/ui/game/gamemain.lua").RemoveBeatFunction
local FireState = import("/lua/game.lua").FireState

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Reticle = import('/lua/ui/controls/reticle.lua').Reticle

-- Upvalue scope for performance
local GameTick = GameTick
local VDist2 = VDist2

local TableInsert = table.insert
local TableGetn = table.getn
local TableEmpty = table.empty

FLIGHT = {
    uab2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
    ueb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
    urb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
    xsb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
}

READY = {
    uab2108 = 36,
    ueb2108 = 25,
    urb2108 = 20,
    xsb2108 = 15,
}

LAUNCH = {
    uab2108 = 1,
    ueb2108 = 16,
    urb2108 = 1,
    xsb2108 = 16,
}

RELOAD = {
    uab2108 = 57,
    ueb2108 = 45,
    urb2108 = 31,
    xsb2108 = 35,
}

CYCLE = {
    uab2108 = 94,
    ueb2108 = 86,
    urb2108 = 52,
    xsb2108 = 66,
}

---@type table<number, { fire: UserUnit[], hold: UserUnit }>
local watchArray = {}

local syncCache = {}
local syncIndex = 1

---@param launcher UserUnit
---@return number | false
local CalculateTicksToTarget = function(launcher)

    local targetPos = launcher:GetCommandQueue()[1].position
    local pos = launcher:GetPosition()
    local range = VDist2(pos[1], pos[3], targetPos[1], targetPos[3])
    local unitId = launcher:GetUnitId()

    --make sure we're in range
    if FLIGHT[unitId][math.floor(range)] then
        --we can add support for multiple queued syncronized strikes here
        return CYCLE[unitId] * (TableGetn(launcher:GetCommandQueue())-1) + READY[unitId] + LAUNCH[unitId] + FLIGHT[unitId][math.floor(range)]
    else
        return false
    end
end

WatcherBeat = function()

    LOG('WatcherBeat:' .. GameTick())
    local tick = GameTick()
    --see if the current game tick is in the watchArray
    --launchers in the fire table will get set to GROUND_FIRE
    --if they have another sync strike in their order queue, they'll also be added to the hold fire table twenty ticks later
    --launchers in the hold fire table will get set to HOLD_FIRE
    if watchArray[tick] then
        LOG('watchArray tick found!')
        LOG('there are ' .. TableGetn(watchArray[tick].fire) .. ' launchers to set to fire this tick')
        for _, launcher in watchArray[tick].fire do
            LOG('setting launcher to fire:' .. launcher:GetEntityId())
            SetFireState({launcher}, FireState.GROUND_FIRE)
            launcher.syncCount = launcher.syncCount - 1
            if launcher.syncCount > 0 then
                if not watchArray[tick+20] then
                    watchArray[tick+20] = {fire={},hold={}}
                end
                TableInsert(watchArray[tick+20].hold,launcher)
            else
                launcher.syncCount = nil
            end
        end

        for _, launcher in watchArray[tick].hold do
            SetFireState({launcher}, FireState.HOLD_FIRE)
        end

        watchArray[tick] = nil

    end

    --if there are no more ticks to watch for in the cache, remove the beat function
    if TableEmpty(watchArray) then
        RemoveBeatFunction(WatcherBeat)
    end

end

--passes all launchers that are:
--1. in range
--2. have missiles
--3. only have one command in the queue
--to the launcher cache, then returns
local PreProcessLaunchers = function(subSyncCache)
    local maxTicksToTarget = 0
    local launcherCache = {}
    for launcher in subSyncCache.launchers do
        --range/distance check
        if launcher:GetMissileInfo()[subSyncCache.type .. 'SiloStorageCount'] > 0 then
            launcher.ticksToTarget = CalculateTicksToTarget(launcher)
        else
            launcher.ticksToTarget = false
        end

        --add launcher to the launcherCache and set to hold fire
        if launcher.ticksToTarget then
            if launcher.syncCount then
                --for a launcher that is already in the system, we won't mess with the fire state
                launcher.syncCount = launcher.syncCount + 1
            else
                --otherwise, initialize the firestate and set to hold fire
                SetFireState({launcher}, FireState.HOLD_FIRE)
                launcher.syncCount = 1
            end
            
            TableInsert(launcherCache, launcher)

            --update maxTicksToTarget
            if launcher.ticksToTarget > maxTicksToTarget then
                maxTicksToTarget = launcher.ticksToTarget
            end
        end
    end
    return launcherCache, maxTicksToTarget
end

local SynchronizedStrike = function(subSyncCache)

    --calc tickOnTarget for relevant launchers and add them to the launcherCache
    --obtain impactTick from the return maxTicksToTargetValue
    local launcherCache, maxTicksToTarget = PreProcessLaunchers(subSyncCache)
    local impactTick = GameTick() + maxTicksToTarget

    --if there are no launchers in the cache, we're done
    if TableEmpty(launcherCache) then
        return
    end

    --if our watchArray has been empty up to this point, we'll need a beat function
    if TableEmpty(watchArray) then
        AddBeatFunction(WatcherBeat)
    end

    --populate our watchArray with the correct values
    --format is watchArray[GameTick] = {fire={...},hold={...}}
    --where the beat function will check the keys for the game tick, and apply the firestate changes to the launchers if so
    for _, launcher in launcherCache do
        local fireStateChangeTick = impactTick - launcher.ticksToTarget + READY[launcher:GetUnitId()]
        if not watchArray[fireStateChangeTick] then
            watchArray[fireStateChangeTick] = {fire={},hold={}}
        end
        TableInsert(watchArray[fireStateChangeTick].fire, launcher)
    end

    --call our beat function, because it might get missed this tick
    WatcherBeat()
end

ReleaseSyncStrike = function()
    -- releases the sync strike on top of the stack
    SynchronizedStrike(syncCache[syncIndex])
    table.remove(syncCache, 1)
    syncIndex = syncIndex - 1
end

-- administrative overhead here to stage launchers that are passed from OnTacticalCommandIssued
SynchronizedStrikeInprocess = function(command)
    local inprocessingCache = {}
    if TableEmpty(syncCache) then
        TableInsert(syncCache, {type='',launchers={}})
        syncIndex = 1
    end

    for _, launcher in command.Units do
        TableInsert(inprocessingCache, launcher)
        if syncCache[syncIndex].launchers[launcher] or command.CommandType ~= syncCache[syncIndex].type then
            TableInsert(syncCache, {type='',launchers={}})
            syncIndex = syncIndex + 1
        end
    end

    syncCache[syncIndex].type = command.CommandType:lower()
    for _, launcher in inprocessingCache do
        syncCache[syncIndex].launchers[launcher] = true
    end

    -- this will release whatever order comes in automatically
    -- for testing
    ReleaseSyncStrike()
end

local function AnimateSyncText(text)
    while not text:IsHidden() do
        text:SetColor('Red')
        WaitSeconds(.1)
        text:SetColor('White')
        WaitSeconds(.1)
    end
end

TacticalReticle = ClassUI(Reticle) {

    SetLayout = function(self)
        self.syncText = UIUtil.CreateText(self, "SYNC", 16, UIUtil.bodyFont, true)
        LayoutHelpers.RightOf(self.syncText, self, 4)
        self.syncText:SetColor('Red')
    end,

    UpdateDisplay = function(self, mouseWorldPos)
        if self.onMap and IsKeyDown("CONTROL") then
            if self.syncText:IsHidden() then
                self.syncText:Show()
                self.animThread = ForkThread(AnimateSyncText, self.syncText)
                self.Trash:Add(self.animThread)
            end
        else
            if not self.syncText:IsHidden() then
                self.syncText:Hide()
                if self.animThread then
                    self.animThread:Destroy()
                end
            end
        end
    end,
}