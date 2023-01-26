--*****************************************************************************
--* File: lua/modules/ui/game/trackingindicator.lua
--* Summary: In Game Tracking indicator
--*
--* Copyright � 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local Tabs = import("/lua/ui/game/tabs.lua")
local modeID = false

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