--******************************************************************************************************
--** Copyright (c) 2025  Willem 'Jip' Wijnia
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

local Group = import("/lua/maui/group.lua").Group

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

--- A utility function that determines when announcements should be skipped
---@return boolean
local function ShouldSkipAnnouncement()
    -- early exit: don't show announcements when the score dialog is open
    local scoreModule = import("/lua/ui/dialogs/score.lua")
    if scoreModule.dialog then
        return true
    end

    return false
end

--- Create an announcement with a title.
---@param titleText UnlocalizedString
---@param goalControl? Control          # if defined, the announcement visually expands and contracts to this control.
CreateTitleAnnouncement = function(titleText, goalControl)
    if ShouldSkipAnnouncement() then
        return
    end

    local frame = GetFrame(0) --[[@as Frame]]

    -- create a dummy goal control if we don't have one
    if not goalControl then
        goalControl = CreateDefaultGoalControl(frame)
    end

    -- abort all existing announcements
    for k, announcement in Announcements do
        if not IsDestroyed(announcement) then
            announcement:AbortAnnouncement()
        end
    end

    -- lazy load the module
    local SmallAnnouncement = import("/lua/ui/game/announcement/SmallAnnouncement.lua").SmallAnnouncement

    -- create the announcement
    ---@type UIAbstractAnnouncement
    local announcement = SmallAnnouncement(frame, titleText)
    announcement:Animate(goalControl, 1.4)
    Announcements:Add(announcement)

    -- feature: immediately hide announcements when game UI is hidden
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        announcement:Hide()
    end
end

--- Create an announcement with a title and some text.
---@param titleText UnlocalizedString
---@param bodyText UnlocalizedString
---@param goalControl? Control          # if defined, the announcement visually expands and contracts to this control.
CreateTitleTextAnnouncement = function(titleText, bodyText, goalControl)
    if ShouldSkipAnnouncement() then
        return
    end

    local frame = GetFrame(0) --[[@as Frame]]

    -- create a dummy goal control if we don't have one
    if not goalControl then
        goalControl = CreateDefaultGoalControl(frame)
    end

    -- abort all existing announcements
    for k, announcement in Announcements do
        if not IsDestroyed(announcement) then
            announcement:AbortAnnouncement()
        end
    end

    -- lazy load the module
    local TitleTextAnnouncement = import("/lua/ui/game/announcement/TitleTextAnnouncement.lua").TitleTextAnnouncement

    -- create the announcement
    ---@type UIAbstractAnnouncement
    local announcement = TitleTextAnnouncement(frame, titleText, bodyText)
    announcement:Animate(goalControl, 2.2)
    Announcements:Add(announcement)

    -- feature: immediately hide announcements when game UI is hidden
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        announcement:Hide()
    end
end

--- A general function to create an announcement UI for sending general messages to the user.
---
--- Exists for backwards compatibility.
---@param titleText UnlocalizedString
---@param bodyText? UnlocalizedString
---@param goalControl? Control          # if defined, the announcement visually expands and contracts to this control.
function CreateAnnouncement(titleText, bodyText, goalControl)
    if type(bodyText) == "string" then
        return import("/lua/ui/game/announcement.lua").CreateTitleTextAnnouncement (titleText, bodyText, goalControl)
    else
        return import("/lua/ui/game/announcement.lua").CreateTitleAnnouncement(titleText, goalControl)
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

-------------------------------------------------------------------------------
--#region Debug functionality

--- Creates a title announcement for debugging.
DebugTitleAnnouncement = function()
    CreateAnnouncement("Title because X is defeated")
end

--- Creates a title text announcement for debugging.
DebugTitleTextAnnouncement = function()
    CreateAnnouncement("Title", "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
end

--#endregion
