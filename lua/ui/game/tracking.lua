--*****************************************************************************
--* File: lua/modules/ui/game/trackingindicator.lua
--* Summary: In Game Tracking indicator
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local Tabs = import("/lua/ui/game/tabs.lua")
local modeID = false

local ACQUIRE_TIMEOUT = 3
local TRACKING_TOLERANCE_SQ = 25

local splitScreenTrackingActive = false
local splitScreenTrackingAcquired = false
local splitScreenTrackedUnit
local splitScreenTrackingStartedAt = 0
local splitScreenTrackingWatcherStarted = false

function OnTrackUnit(camera,tracking)
    if camera == "WorldCamera" then
        if tracking and not modeID then
            modeID = Tabs.AddModeText("<LOC TRACKING_0000>Tracking")
        elseif not tracking and modeID then
            Tabs.RemoveModeText(modeID)
            modeID = false
        end
    end
end

function ClearModeText()
    if modeID then
        Tabs.RemoveModeText(modeID)
        modeID = false
    end
end

local function SetSplitScreenTrackingIndicator(tracking)
    OnTrackUnit("WorldCamera", tracking)
end

local function StopSplitScreenTrackingIndicator()
    if splitScreenTrackingActive then
        splitScreenTrackingActive = false
        splitScreenTrackingAcquired = false
        splitScreenTrackedUnit = nil
        SetSplitScreenTrackingIndicator(false)
    end
end

local function HasSplitScreen()
    return import("/lua/ui/game/borders.lua").mapSplitState
end

local function UpdateSplitScreenTrackingIndicator()
    if not splitScreenTrackingActive then
        return
    end

    if not HasSplitScreen() or not splitScreenTrackedUnit or splitScreenTrackedUnit:IsDead() then
        StopSplitScreenTrackingIndicator()
        return
    end

    local camera = GetCamera("WorldCamera2")
    if not camera then
        StopSplitScreenTrackingIndicator()
        return
    end

    local focus = camera:GetFocusPosition()
    local position = splitScreenTrackedUnit:GetInterpolatedPosition()
    local dx = focus[1] - position[1]
    local dz = focus[3] - position[3]
    local distanceSq = dx * dx + dz * dz

    if distanceSq <= TRACKING_TOLERANCE_SQ then
        splitScreenTrackingAcquired = true
    elseif splitScreenTrackingAcquired or GetGameTimeSeconds() - splitScreenTrackingStartedAt >= ACQUIRE_TIMEOUT then
        StopSplitScreenTrackingIndicator()
    end
end

local function StartSplitScreenTrackingWatcher()
    if splitScreenTrackingWatcherStarted then
        return
    end

    splitScreenTrackingWatcherStarted = true
    import("/lua/ui/game/gamemain.lua").AddBeatFunction(
        UpdateSplitScreenTrackingIndicator,
        false,
        "SplitScreenTracking"
    )
end

--- Toggles tracking of the selected unit in the split screen view.
function ToggleSplitScreenTracking()
    if not HasSplitScreen() then
        StopSplitScreenTrackingIndicator()
        return
    end

    if splitScreenTrackingActive then
        ConExecute("UI_TrackUnit WorldCamera2")
        StopSplitScreenTrackingIndicator()
        return
    end

    local selection = GetSelectedUnits()
    splitScreenTrackedUnit = selection and selection[1]
    if not splitScreenTrackedUnit or splitScreenTrackedUnit:IsDead() then
        return
    end

    splitScreenTrackingActive = true
    splitScreenTrackingAcquired = false
    splitScreenTrackingStartedAt = GetGameTimeSeconds()
    StartSplitScreenTrackingWatcher()
    ConExecute("UI_TrackUnit WorldCamera2")
    SetSplitScreenTrackingIndicator(true)
end
