local AddBeatFunction = import("/lua/ui/game/gamemain.lua").AddBeatFunction
local RemoveBeatFunction = import("/lua/ui/game/gamemain.lua").RemoveBeatFunction
local FireState = import("/lua/game.lua").FireState

--Upvalues for performance
local GameTick = GameTick
local VDist2 = VDist2

FLIGHT = {
    uab2108 = {27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 29, 31, 31, 32, 32, 33, 34, 36, 37, 38, 38, 38, 39, 41, 42, 43, 43, 44, 45, 46, 47, 48, 49, 50, 50, 50, 53, 56, 57, 58, 59, 60, 61, 62, 80, 98, 99, 100, 100, 100, 102, 105, 106, 107, 107, 107, 112, 118, 118, 118, 118, 119, 119, 120, 120, 120, 121, 122, 122, 123, 122, 122, 123, 125, 126, 127, 127, 128, 129, 130, 130, 131, 131, 132, 133, 134, 135, 136, 136, 136, 137, 138, 137, 137, 138, 139, 139, 140, 140, 141, 142, 143, 144, 145, 145, 146, 146, 147, 147, 148, 148, 149, 150, 151, 152, 153, 154, 155, 155, 155, 156, 157, 157, 158, 158, 159, 160, 161, 162, 163, 163, 164, 165, 166, 167, 168, 168, 169, 169, 170, 170, 171, 172, 173, 173, 174, 175, 177, 177, 178, 178, 179, 179, 180, 181, 182, 183, 184, 185, 186, 186, 187, 188, 189, 189, 189, 190, 192, 193, 194, 194, 194, 195, 196, 196, 197, 198, 200, 200, 200, 201, 203, 203, 204, 204, 205, 206, 208, 208, 209, 210, 211, 211, 212, 213, 214, 214, 214, 215, 217, 218, 220, 219, 219, 220, 222, 222, 223, 224, 225, 226, 228, 228, 228, 229, 230, 231, 233, 233, 234, 234, 235, 236, 237, 237, 237, 238, 240, 241, 242, 242, 243, 244, 245, 245, 246, 247, 248, 248, 249, 250, 252, 252, 253, 253, 254, 255, 257, 258},
    ueb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
    urb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
    xsb2108 = {24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 25, 26, 26, 27, 27, 28, 29, 30, 30, 31, 32, 33, 33, 34, 35, 36, 36, 37, 38, 39, 39, 40, 41, 42, 45, 48, 50, 53, 53, 54, 55, 57, 68, 80, 81, 83, 89, 96, 96, 97, 97, 98, 98, 99, 99, 100, 101, 103, 103, 104, 105, 106, 109, 113, 113, 114, 114, 115, 115, 115, 115, 116, 116, 117, 117, 118, 118, 119, 119, 120, 121, 122, 122, 123, 123, 124, 124, 125, 126, 127, 127, 128, 128, 129, 129, 130, 130, 131, 131, 132, 133, 134, 134, 135, 135, 136, 137, 138, 138, 139, 139, 140, 141, 142, 142, 143, 144, 145, 145, 146, 146, 147, 148, 149, 149, 150, 151, 152, 152, 153, 154, 155, 155, 156, 157, 158, 158, 159, 160, 161, 161, 162, 163, 164, 164, 165, 166, 167, 167, 168, 169, 170, 170, 171, 172, 173, 173, 174, 175, 176, 176, 177, 178, 179, 179, 180, 181, 182, 183, 184, 184, 185, 186, 187, 187, 188, 189, 190, 190, 191, 192, 193, 194, 195, 195, 196, 197, 198, 198, 199, 200, 201, 201, 202, 203, 204, 205, 206, 206, 207, 208, 209, 209, 210, 211, 212, 213, 214, 214, 215, 216, 217, 217, 218, 219, 220, 221, 222, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230, 230, 231, 232, 233, 234, 235, 235, 236, 237, 238, 238, 239, 240, 241, 242, 243, 243, 244, 245, 246, 247},
}

READY = {
    uab2108 = 30, --36
    ueb2108 = 20, --25
    urb2108 = 14, --20
    xsb2108 = 9, --15
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

local watcherCache = {}

local CalculateTickOnTarget = function(launcher)

    local targetPos = launcher:GetCommandQueue()[1].position
    local pos = launcher:GetPosition()
    local range = VDist2(pos[1], pos[3], targetPos[1], targetPos[3])
    local unitId = launcher:GetUnitId()

    --make sure we're in range
    if FLIGHT[unitId][math.floor(range)] then
        launcher.tickOnTarget = GameTick() + READY[unitId] + LAUNCH[unitId] + FLIGHT[unitId][math.floor(range)]
    else
        launcher.tickOnTarget = false
    end
end

local SortByTickOnTarget = function(launchers, reverse)
    table.sort(
        launchers,
        function(a,b)
            if reverse then a,b = b,a end
            if not a.tickOnTarget then
                return false
            elseif not b.tickOnTarget then
                return true
            end
            return a.tickOnTarget < b.tickOnTarget
        end
    )
end

WatcherBeat = function()
    --if there are no more watchers in the cache, remove the beat function
    if next(watcherCache) == nil then
        RemoveBeatFunction(WatcherBeat)
        return
    end
    if not SessionIsPaused() then
        for watcher in watcherCache do
            watcher:WatchBeat()
        end
    end
end

local SynchronizedStrikeWatcher = Class() {

    __init = function(self, launcherCache)

        --initialize our thread specific variables
        self.watchCache = {}
        self.index = 1
        
        local totalDelay = 0
        local firstReadyDelay
        local oldTickOnTarget
        
        firstReadyDelay = READY[launcherCache[1]:GetUnitId()]
        oldTickOnTarget = launcherCache[1].tickOnTarget + firstReadyDelay

        --shallow copy our launchers to the watchCache and attach a waitTick value
        for _, launcher in ipairs(launcherCache) do
            launcher.waitTicks = oldTickOnTarget - launcher.tickOnTarget
            table.insert(self.watchCache, launcher)
            totalDelay = totalDelay + oldTickOnTarget - launcher.tickOnTarget

            --do a check in case of mixed launchers; a launcher may need proportionally more time to get ready
            if totalDelay < READY[launcher:GetUnitId()] then
                firstReadyDelay = READY[launcher:GetUnitId()] - totalDelay
            end
            oldTickOnTarget = launcher.tickOnTarget
        end

        --clear the launcher cache
        launcherCache = {}

        --add the firstReadyDelay to the first launcher's waitTick value
        self.currentLauncher = self.watchCache[1]
        self.currentLauncher.waitTicks = 0
        self.watchCache[2].waitTicks = self.watchCache[2].waitTicks + firstReadyDelay
    end,

    WatchBeat = function(self)
        --subtract 1 from the waitTick value of the current launcher step
        self.currentLauncher.waitTicks = self.currentLauncher.waitTicks - 1
        
        --see if we're at or below 0, if so, set the next launcher to fire
        --while loop to catch any launchers that may have the same launch time
        while self.currentLauncher.waitTicks <= 0 do
            self.currentLauncher.waitTicks = nil
            if not self.currentLauncher:IsDead() then
                SetFireState({self.currentLauncher}, FireState.GROUND_FIRE)
            end
            self.index = self.index + 1
            self.currentLauncher = self.watchCache[self.index]
            --if our index exceeds the length of the watchCache, we're done
            if self.index > table.getn(self.watchCache) then
                watcherCache[self] = nil
                break
            end
        end
    end,
}

local PreProcessLaunchers = function(command, launcherCache)
    for _, launcher in command.Units do
        --range/distance check
        if table.getn(launcher:GetCommandQueue()) == 1 and 
           launcher:GetMissileInfo()[command.CommandType:lower() .. 'SiloStorageCount'] > 0 then
            CalculateTickOnTarget(launcher)
        else
            launcher.tickOnTarget = false
        end

        --add launcher to the launcherCache and set to hold fire
        if launcher.tickOnTarget then
            SetFireState({launcher}, FireState.HOLD_FIRE)
            table.insert(launcherCache, launcher)
        end
        SortByTickOnTarget(launcherCache, true)
    end
end


SynchronizedStrike = function(command)

    local launcherCache = {}
    --calc tickOnTarget for relevant launchers and add them to the launcherCache
    PreProcessLaunchers(command, launcherCache)

    --if there are no launchers in the cache, we're done
    if not next(launcherCache) then
        return
    end

    --check if this is the first watcher in the cache, if so add the beat function
    if next(watcherCache) == nil then
        AddBeatFunction(WatcherBeat)
    end

    --add watcher to the watcherCache
    local watcher = SynchronizedStrikeWatcher(launcherCache)
    watcherCache[watcher] = true
end