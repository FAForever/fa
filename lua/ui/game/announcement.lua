--*****************************************************************************
--* File: lua/modules/ui/game/announcement.lua
--* Author: Ted Snook
--* Summary: Announcement UI for sending general messages to the user
--*
--* Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************
local Group = import("/lua/maui/group.lua").Group

local SmallAnnouncement = import("/lua/ui/game/announcement/SmallAnnouncement.lua").SmallAnnouncement

---@type TrashBag | UIAbstractAnnouncement[]
local Announcements = TrashBag()

--- Creates the default goal control that originates from the top of the screen, in the center.
---@param frame Frame
local function CreateDefaultGoalControl(frame)
    goalControl = Group(frame)
    goalControl.Left:Set(function() return frame.Left() + 0.49 * frame.Right() end)
    goalControl.Right:Set(function() return frame.Left() + 0.51 * frame.Right() end)
    goalControl.Top:Set(function() return frame.Top() end);
    goalControl.Height:Set(0)

    return goalControl
end

--- Create an announcement UI for sending general messages to the user
---@param text UnlocalizedString # title text
---@param goalControl? Control The control where the announcement appears out of.
---@param secondaryText? UnlocalizedString # body text
---@param onFinished? function
function CreateAnnouncement(text, goalControl, secondaryText, onFinished)
    -- early exit: don't show announcements when the score dialog is open
    local scoreModule = import("/lua/ui/dialogs/score.lua")
    if scoreModule.dialog then
        return
    end

    local frame = GetFrame(0) --[[@as Frame]]

    -- create a dummy goal control if we don't have one
    if not goalControl then
        goalControl = CreateDefaultGoalControl(frame)
    end

    -- abort all existing announcements
    for k, announcement in Announcements do
        announcement:AbortAnnouncement()
    end

    -- create the announcement
    ---@type UIAbstractAnnouncement
    local announcement = SmallAnnouncement(frame, text)
    announcement:Animate(goalControl)
    Announcements:Add(announcement)

    -- feature: immediately hide announcements when game UI is hidden
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        announcement:Hide()
    end
end

--- Instantly hides the current announcement
function Contract()
    for k, announcement in Announcements do
        if not IsDestroyed(announcement) then
            announcement:Hide()
        end
    end
end

--- Instantly shows the current announcement
function Expand()
    for k, announcement in Announcements do
        if not IsDestroyed(announcement) then
            announcement:Show()
        end
    end
end
