----****************************************************************************
---- UserMusic
---- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
----
----****************************************************************************

----****************************************************************************
---- Config options
----****************************************************************************

-- List of battle cues to cycle through
local BattleCues = {
    Sound({Cue = 'Battle', Bank = 'Music'}),
}

-- List of peace cues to cycle through
local PeaceCues = {
    Sound({ Cue = 'Base_Building', Bank = 'Music' }),
}

-- How many battle events do we receive before switching to battle music
local BattleEventThreshold = 20

-- Current count of battle events
local BattleEventCounter = 0

-- How many ticks can elapse between NotifyBattle events before we reset the
-- BattlceEventCounter (only used in peace time)
local BattleCounterReset = 30 -- 3 seconds

-- How many ticks of battle inactivity until we switch back to peaceful music
local PeaceTimer = 200 -- 20 seconds

----****************************************************************************
---- Internal
----****************************************************************************

-- The last tick in which we got a battle notification
local LastBattleNotify = 0

-- Current music loop if music is active
local Music = false

-- Watcher thread
local musicThread = nil


-- Tick when battle started, or 0 if at peace
local BattleStart = 0

local BattleCueIndex = 1
local PeaceCueIndex = 1

local currentMusic = nil
local battleWatch = nil
local paused = GetVolume("Music") == 0
local nomusicSwitchSet = HasCommandLineArg("/nomusic")

function NotifyBattle()
    if nomusicSwitchSet then return end -- nomusic set - save threading
    local tick = GameTick()
    local prevNotify = LastBattleNotify
    LastBattleNotify = tick

    --LOG("*** NotifyBattle, tick=" .. repr(tick))

    if BattleStart == 0 then
        if tick - prevNotify > BattleCounterReset then
            BattleEventCounter = 1
        else
            BattleEventCounter = BattleEventCounter + 1
            if BattleEventCounter > BattleEventThreshold then
                StartBattleMusic()
            end
        end
    end
end

function StartBattleMusic()
    if nomusicSwitchSet then return end -- nomusic set - save threading
    BattleStart = GameTick()
    PlayMusic(BattleCues[BattleCueIndex], 0) -- immediately
    BattleCueIndex = math.mod(BattleCueIndex,table.getn(BattleCues)) + 1

    if battleWatch then KillThread(battleWatch) end
    battleWatch = ForkThread(
        function ()
            while GameTick() - LastBattleNotify < PeaceTimer do
                WaitSeconds(1)
            end

            StartPeaceMusic()
        end
)
end

function StartPeaceMusic()
    if nomusicSwitchSet then return end -- nomusic set - save threading
    BattleStart = 0
    BattleEventCounter = 0
    LastBattleNotify = GameTick()

    PlayMusic(PeaceCues[PeaceCueIndex], 3)
    PeaceCueIndex = math.mod(PeaceCueIndex, table.getsize(PeaceCues)) + 1
end

function PlayMusic(cue, delay)
    if(musicThread) then KillThread(musicThread) end

    musicThread = ForkThread(
        function()
            local delay = delay or 0

            if currentMusic then
                StopSound(currentMusic, delay == 0)
                if delay > 0 then
                    WaitFor(currentMusic)
                    WaitSeconds(delay)
                end

                currentMusic = nil
            end


            currentMusic = PlaySound(cue)
            if paused then
                WaitSeconds(1)
                PauseSound("Music", true)
            end
        end)
end

function PauseMusic(pause)
    if pause ~= paused then
        PauseSound("Music", pause)
        paused = pause
    end
end

function SetMusicVolume(v)
    if v == 0 then
        PauseMusic(true)
    else
        PauseMusic(false)
    end

    SetVolume("Music", v)
end
