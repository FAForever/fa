--*****************************************************************************
--* File: lua/ui/lobby/cpubenchmark.lua
--* Summary: CPU benchmark scoring and UI bar management.
--*          Extracted from lobby.lua for maintainability.
--*****************************************************************************

local Tooltip = import("/lua/ui/game/tooltip.lua")

-- Upvalues injected by lobby.lua via CPUBenchmark.Init()
local GUI
local lobbyComm
local localPlayerName
local localPlayerID
local gameInfo
local CPU_Benchmarks
local FindIDForName
local FindSlotForID
local FindObserverSlotForID
local refreshObserverList

function Init(deps)
    GUI                   = deps.GUI
    lobbyComm             = deps.lobbyComm
    localPlayerName       = deps.localPlayerName
    localPlayerID         = deps.localPlayerID
    gameInfo              = deps.gameInfo
    CPU_Benchmarks        = deps.CPU_Benchmarks
    FindIDForName         = deps.FindIDForName
    FindSlotForID         = deps.FindSlotForID
    FindObserverSlotForID = deps.FindObserverSlotForID
    refreshObserverList   = deps.refreshObserverList
end

------------------------------------------------------------
-- Bar colour config (unchanged from original)
------------------------------------------------------------
local greenBarMax  = 300
local yellowBarMax = 375
local scoreSkew1   = 0    -- shift all scores up/down (0 = no skew)
local scoreSkew2   = 1.0  -- scale coefficient         (1.0 = no skew)

local BenchTime

------------------------------------------------------------
-- Benchmark computation
------------------------------------------------------------

function CPUBenchmark()
    local totalTime  = 0
    local lastTime
    local currTime
    local countTime  = 0
    local TableInsert = table.insert
    local TableRemove = table.remove
    local h, i, j, k, l, m
    local n = {}

    for h = 1, 24, 1 do
        if not lobbyComm then return end

        lastTime = GetSystemTimeSeconds()
        for i = 1.0, 30.4, 0.0008 do
            j = i + i
            k = i * i
            l = k / j
            m = j - i
            j = math.pow(i, 4)
            l = -i
            m = {'1234567890', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', true}
            TableInsert(m, '1234567890')
            k = i < j
            k = i == j
            k = i <= j
            k = not k
            n[tostring(i)] = m
        end
        currTime  = GetSystemTimeSeconds()
        totalTime = totalTime + currTime - lastTime

        if totalTime > countTime then
            countTime = totalTime + .125
            coroutine.yield(1)
        end
    end
    BenchTime = math.ceil(totalTime * 100)
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

function CPU_AddControlTooltip(control, delay, slotNumber)
    local CPUText = function()
        local CPUInfo
        if GUI.slots[slotNumber].CPUSpeedBar.CPUActualValue then
            CPUInfo = GUI.slots[slotNumber].CPUSpeedBar.CPUActualValue
        else
            CPUInfo = LOC('<LOC lobui_0458>UnKnown')
        end
        return LOC('<LOC lobui_0459>CPU Rating: ') .. CPUInfo
    end
    local CPUBody = function()
        return LOC('<LOC lobui_0322>0=Fastest, 450=Slowest')
    end
    Tooltip.AddAutoUpdatedControlTooltip(control, CPUText, CPUBody, delay)
end

--- Returns a benchmark score, calculating a fresh one if needed.
-- @param force  Always recalculate when true.
function GetBenchmarkScore(force)
    local wait = 10
    local benchmark

    if force then
        wait = 0
    else
        benchmark = GetPreference('CPUBenchmark')
    end

    if not benchmark then
        benchmark = StressCPU(wait)
        SetPreference('CPUBenchmark', benchmark)
    end

    return benchmark
end

--- Runs the benchmark and broadcasts the result to other players.
-- @param force  Passed through to GetBenchmarkScore.
function UpdateBenchmark(force)
    local benchmark = GetBenchmarkScore(force)

    if benchmark then
        CPU_Benchmarks[localPlayerName] = benchmark
        lobbyComm:BroadcastData({ Type = 'CPUBenchmark', PlayerName = localPlayerName, Result = benchmark })
        if FindObserverSlotForID(localPlayerID) then
            refreshObserverList()
        else
            UpdateCPUBar(localPlayerName)
        end
    end
end

--- Runs three benchmark passes and returns the best score.
-- Handles UI countdown and resets the rerunBenchmark button.
-- @param waitTime  Seconds to wait before starting.
-- @return Best score, or nil if the lobby was exited mid-run.
function StressCPU(waitTime)
    GUI.rerunBenchmark:Disable()
    for i = waitTime, 1, -1 do
        GUI.rerunBenchmark.label:SetText(i..'s')
        WaitSeconds(1)
        if not lobbyComm then return end
    end

    local currentBestBenchmark = 10000
    GUI.rerunBenchmark.label:SetText('. . .')

    for i = 1, 3, 1 do
        BenchTime = 0
        CPUBenchmark()
        BenchTime = scoreSkew2 * BenchTime + scoreSkew1

        if not lobbyComm then return end

        if BenchTime < currentBestBenchmark then
            currentBestBenchmark = BenchTime
        end
    end

    GUI.rerunBenchmark:Enable()
    GUI.rerunBenchmark.label:SetText('')

    return currentBestBenchmark
end

function UpdateCPUBar(playerName)
    local playerId   = FindIDForName(playerName)
    local playerSlot = FindSlotForID(playerId)
    if playerSlot ~= nil then
        SetSlotCPUBar(playerSlot, gameInfo.PlayerOptions[playerSlot])
    end
end

function SetSlotCPUBar(slot, playerInfo)
    if GUI.slots[slot].CPUSpeedBar then
        GUI.slots[slot].CPUSpeedBar:Hide()
        if playerInfo and playerInfo.Human then
            local b = CPU_Benchmarks[playerInfo.PlayerName]
            if b then
                if b > GUI.slots[slot].CPUSpeedBar.barMax then
                    b = GUI.slots[slot].CPUSpeedBar.barMax
                end
                GUI.slots[slot].CPUSpeedBar:SetValue(b)
                GUI.slots[slot].CPUSpeedBar.CPUActualValue = b
                GUI.slots[slot].CPUSpeedBar:Show()
            end
        end
    end
end
