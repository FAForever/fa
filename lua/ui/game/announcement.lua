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

--- Create an announcement UI for sending general messages to the user
---@param text UnlocalizedString # title text
---@param goalControl? Control The control where the announcement appears out of.
---@param secondaryText? UnlocalizedString # body text
function CreateAnnouncement(text, goalControl, secondaryText)
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

    -- lazy load the module
    local SmallAnnouncement = import("/lua/ui/game/announcement/SmallAnnouncement.lua").SmallAnnouncement

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
